--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[------------------- v1.0/rev2 --------------------]]--

--- Capa de compatibilidad Enceladus 2024 <-> 2025+ ------------------------------------
--- La build de 2024 incluida en RETROLauncher define FREAD/FWRITE/FCREATE, SET/CUR/END,
--- la tabla "Sif" y System.rename. Las versiones recientes las han sustituido por
--- O_RDONLY/O_WRONLY/O_CREAT..., la tabla "IOP" y System.moveFile.
--- Este bloque NO hace nada en la build antigua: solo rellena lo que falte.
if FREAD   == nil and O_RDONLY ~= nil then FREAD   = O_RDONLY end
if FWRITE  == nil and O_WRONLY ~= nil then FWRITE  = O_WRONLY end
if FRDWR   == nil and O_RDWR   ~= nil then FRDWR   = O_RDWR   end   -- usada por guardar()
if FCREATE == nil and O_CREAT  ~= nil then FCREATE = O_RDWR | O_CREAT | O_TRUNC end
if SET == nil then SET = 0 end
if CUR == nil then CUR = 1 end
if END == nil then END = 2 end
if Sif == nil and IOP ~= nil then Sif = IOP end
if System.rename == nil and System.moveFile ~= nil then System.rename = System.moveFile end

--- Normaliza el prefijo de unidad de una ruta. ---------------------------------------
--- "mass:/X" y "mass0:/X" designan lo mismo, pero el nombre depende de QUIEN lanza el
--- programa: desde el OSD o FMCB se obtiene "mass:", desde uLaunchELF "mass0:".
--- Sin esto, el launcher cree que la instalacion ha cambiado de sitio y propone
--- reubicar las configuraciones (perdiendo los ajustes de RetroArch) a cada cambio
--- de metodo de arranque.
function NORM_DEV(ruta)
	if ruta == nil then return "" end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return string.lower(ruta) end
	local dev = string.sub(ruta, 1, pos-1)
	while string.len(dev) > 0 and string.match(string.sub(dev, -1), "%d") ~= nil do
		dev = string.sub(dev, 1, -2)
	end
	return string.lower(dev ..":".. string.sub(ruta, pos+1))
end

--- Quita la numeracion del prefijo de unidad y DEJA EL RESTO INTACTO. ----------------
--- "mass0:/POPS/Juego.VCD" -> "mass:/POPS/Juego.VCD".
--- No confundir con NORM_DEV, que ademas pasa todo a minusculas porque sirve para
--- comparar rutas; aqui eso destrozaria el nombre del fichero.
--- Hace falta porque Enceladus 2025 monta los dispositivos como "mass0:", "mass1:",
--- mientras que el homebrew anterior a BDM -POPStarter v13, Neutrino, RetroArch-
--- solo conoce "mass:". La build de 2024 sobre la que se escribio RETROLauncher
--- reportaba "mass:", y de ahi que aquello funcionara sin tocar nada.
function DEV_SIN_NUM(ruta)
	if ruta == nil then return nil end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return ruta end
	local dev = string.sub(ruta, 1, pos-1)
	while string.len(dev) > 0 and string.match(string.sub(dev, -1), "%d") ~= nil do
		dev = string.sub(dev, 1, -2)
	end
	return dev ..":".. string.sub(ruta, pos+1)
end

--- Cores capaces de leer el disco interno ATA. ---------------------------------------
--- El mismo disco tiene DOS nombres, segun quien mire:
---     Enceladus, con su propia pila BDM ....... mass0:
---     un core de RetroArch .................... ata0:
--- No es un capricho. "ps2atad.c" da al disco ATA el nombre "ata" ("g_ata_bd[i].path"),
--- y el "bdmfs_fatfs" actual registra un dispositivo iomanX por cada nombre distinto,
--- tratando "mass" aparte. El USB no declara nombre y se queda en "mass". El
--- "bdmfs_fatfs" que lleva Enceladus es anterior y mete todo en "mass". De ahi los dos
--- nombres para el mismo disco.
--- Solo los cores compilados con el parche saben de "ata0:". Para los demas -las 57
--- nightlies oficiales- el disco interno sigue sin existir, y hay que transbordar la
--- ROM a un soporte que si lean. De ahi esta lista: lo que no esta en ella se
--- transborda, que es el comportamiento seguro.
--- Al recompilar mas cores, anadirlos aqui.
--- A false: NINGUN core lee el disco interno, todo pasa por el transbordo. Es lo
--- correcto con las nightlies oficiales, que no llevan ata_bd. Poner a true solo si
--- se usan cores recompilados con el parche, y listarlos en CORES_ATA.
CORES_ATA_ON = false
CORES_ATA = {
	"fceumm_libretro_ps2.elf",
	"gambatte_libretro_ps2.elf",
	"picodrive_libretro_ps2.elf",
	"snes9x2002_libretro_ps2.elf",
}

function CORE_LEE_ATA(ruta_core)
	if CORES_ATA_ON ~= true or ruta_core == nil then return false end
	local n = string.lower(nombre_fichero(ruta_core))
	for i = 1, #CORES_ATA do
		if n == string.lower(CORES_ATA[i]) then return true end
	end
	return false
end

--- Nombre del disco interno tal como lo vera el core. ---------------------------------
--- Comprobado en consola: con una llave USB conectada, el disco interno sale en
--- "mass1:"; sin llave, en "mass0:". No es azar, es el orden en que RetroArch carga
--- los drivers en "init_drivers()": primero usbmass_bd, luego mx4sio, y ata_bd al
--- final. Los volumenes BDM se numeran por orden de conexion, asi que el indice del
--- disco interno es exactamente el numero de unidades USB que haya delante.
--- El lanzador ya sabe cuantas hay: BDM_DEVICES menos las marcadas en BDM_ATA.
---
--- Existe tambien un nombre estable, "ata0:", que un bdmfs_fatfs reciente registra a
--- partir de "bd->path". Es mejor cuando funciona, porque no depende de cuantas llaves
--- haya conectadas. Poner ATA_DEV_CORE = "ata0:" para usarlo; nil para calcular.
ATA_DEV_CORE = nil

function DEV_ATA_PARA_CORE()
	if ATA_DEV_CORE ~= nil then return ATA_DEV_CORE end
	local usb = 0
	local propio = ""
	local pos = string.find(System.currentDirectory(), ":", 1, true)
	if pos ~= nil then propio = string.sub(System.currentDirectory(), 1, pos) end
	if propio ~= "" and BDM_ATA[propio] ~= true then usb = usb + 1 end
	if BDM_DEVICES ~= nil then
		for i = 1, #BDM_DEVICES do
			if BDM_ATA[BDM_DEVICES[i]] ~= true and BDM_DEVICES[i] ~= propio then
				usb = usb + 1
			end
		end
	end
	return "mass".. tostring(usb) ..":"
end

--- Traduce una ruta del disco interno al nombre que usara el core. --------------------
function RUTA_ATA_CORE(ruta)
	if ruta == nil then return nil end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return ruta end
	return DEV_ATA_PARA_CORE() .. string.sub(ruta, pos+1)
end

--- Nombre de dispositivo tal como lo vera un core de RetroArch. ---------------------
--- Solo hay que quitar el numero a "massN:": RetroArch reinicia el IOP y monta su
--- propia pila, donde el USB se llama "mass:" sin numero. Pero "mc0:" se llama "mc0:"
--- en los dos lados, y "mc:" no existe: aplicar DEV_SIN_NUM a ciegas producia
--- "mc:/RETROLauncher/Saves", una ruta que RetroArch descarta por no ser un directorio,
--- y las partidas volvian a caer dentro de su propia carpeta.
function DEV_PARA_CORE(ruta)
	if ruta == nil then return nil end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return ruta end
	local dev = string.sub(ruta, 1, pos-1)
	if string.lower(string.sub(dev, 1, 4)) ~= "mass" then return ruta end
	return DEV_SIN_NUM(ruta)
end

--- Deteccion de la build: la tabla global "IOP" solo existe en Enceladus reciente. ----
ENCELADUS_MODERNO = (IOP ~= nil)

--- Intenta cargar módulos "IRX". -------------------------------------------------------
--- Solo se intenta en la build reciente. En el ELF de 2024-10-20 incluido en
--- RETROLauncher, "Sif.loadModule" cuelga la consola en CUALQUIER llamada:
--- probado con las formas de 1 y de 3 argumentos, y hasta con un fichero que ni
--- siquiera es un IRX valido. Se congela antes de la inicializacion de video,
--- sin ningun mensaje en pantalla.
IRX_CARGA_ACTIVA = ENCELADUS_MODERNO

--- Orden impuesto: "ata_bd.irx" importa la libreria "dev9", asi que el driver dev9
--- tiene que estar cargado ANTES. System.listDirectory no garantiza ningun orden.
---   dev9_ns.irx : driver dev9 (hardware del adaptador de red).
---   ata_bd.irx  : expone el disco interno a la pila BDM. Importa "dev9" y "bdm".
--- No hace falta nada mas. "poweroff.irx" solo servia para satisfacer un import de
--- "ps2dev9.irx", abandonado en favor de la version de Neutrino, y "_test_dummy.irx"
--- era el testigo de diagnostico.
IRX_ORDEN = {"dev9_ns.irx", "ata_bd.irx"}

--- No cargar: ya los carga Enceladus, o son restos de diagnostico.
IRX_IGNORAR = {"usbd.irx", "usbhdfsd.irx", "bdm.irx", "bdmfs_fatfs.irx", "usbmass_bd.irx",
	"iomanx.irx", "filexio.irx", "dev9_hidden.irx", "ps2dev9.irx", "poweroff.irx",
	"_test_dummy.irx"}

BDM_DEVICES = {}
BDM_ATA = {}   -- unidades que son el disco interno ATA, no un USB

--- =====================================================================================
--- UN journal: "RETROLauncher.log", junto al ELF. ------------------------------------
--- Habia cuatro -- BOOT_LOG, LAUNCH_LOG, MEDIA_LOG, PREBOOT_LOG -- y no se leia
--- ninguno entero: lo que hace falta es el ORDEN de los sucesos, y repartidos en
--- cuatro ficheros el orden se pierde. Ahora todo va a uno, con una categoria por
--- linea, que es lo que separaba los ficheros y cabe en seis caracteres:
---
---   PRE     el pre-boot (System/index.lua), antes de que exista nada de esto
---   BOOT    soporte de arranque, IRX, unidades, raices
---   CARGA   los pasos del arranque, los mismos que se ven en pantalla
---   CONF    lo que se le impone a "retroarch.cfg"
---   SAVES   el puente de partidas disco <-> llave
---   LANZA   la secuencia de lanzamiento de un juego, y el volcado previo al loadELF
---   ART     la ultima imagen abierta (ver ART_LOG_ON)
---
--- Escribe desde la primera linea de codigo. Durante la fase critica cada linea
--- reescribe el fichero entero (BOOT_FLUSH): si la consola se congela, la ultima
--- linea escrita nombra al culpable. Si el fichero no llega ni a existir, el cuelgue
--- es ANTERIOR a Lua -- conflicto de drivers en el arranque de Enceladus -- y ningun
--- script puede verlo.
--- El destino se resuelve una vez: junto al ELF si acepta escrituras; si no, mc0:, y
--- en ultimo recurso mc1:. Asi el journal existe aunque el soporte de arranque
--- resulte ilegible a mitad de camino.
BOOT_LOG_ON = true
BOOT_FLUSH = true
BOOT_LOG_DESTINO = nil

--- Cuanto historial de sesiones anteriores se conserva por delante. -------------------
--- No es un lujo: un lanzamiento fallido devuelve el control a uLaunchELF, y sin
--- historial la prueba siguiente borraria la unica traza de la anterior. Se recorta por
--- el principio, porque lo interesante es siempre lo ultimo.
--- Y no mas: cada volcado reescribe el fichero ENTERO, historial incluido. Con 24 KB y
--- setenta volcados por arranque eso son casi dos megas escritos en exFAT antes de ver
--- el menu. Ocho mil caracteres son dos o tres sesiones, que es lo que hace falta.
LOG_HISTORIAL_MAX = 8000
LOG_PREVIO = ""
BOOT_LOG_TXT = ""

if true then
	-- Lo que hubiera de antes, recortado, pasa a ser el prefijo del fichero.
	local ruta = System.currentDirectory() .."/RETROLauncher.log"
	pcall(function()
		if doesFileExist(ruta) then
			local f = System.openFile(ruta, FREAD)
			local tam = System.sizeFile(f)
			System.seekFile(f, 0, SET)
			local t = System.readFile(f, tam)
			System.closeFile(f)
			if t ~= nil then
				if string.len(t) > LOG_HISTORIAL_MAX then
					t = "[...principio recortado...]\n".. string.sub(t, string.len(t) - LOG_HISTORIAL_MAX)
				end
				LOG_PREVIO = t
			end
		end
	end)
	local sello = ""
	pcall(function() sello = "  ".. os.date("%Y-%m-%d %H:%M:%S") end)
	BOOT_LOG_TXT = "\n============================================================\n"
		.."ARRANQUE".. sello .."\n"
		.."============================================================\n"
	if LOG_PREVIO == "" then
		LOG_PREVIO = "RETROLauncher - journal\n=======================\n"
			.."Una linea por suceso, categoria delante. BOOT_LOG_ON a false en\n"
			.."System/system.lua lo desactiva por completo.\n"
	end
end

--- La ultima imagen abierta. No se acumula: se sustituye. -----------------------------
--- Antes esto reescribia un fichero en CADA caratula cargada, o sea en cada movimiento
--- por la lista. Ahora es una linea que vive al final del journal y se pisa a si misma.
ART_ULTIMA = nil

function boot_escribir()
	if BOOT_LOG_ON ~= true then return end
	pcall(function()
		local texto = LOG_PREVIO .. BOOT_LOG_TXT
		if ART_ULTIMA ~= nil then texto = texto .."ART    ".. ART_ULTIMA .."\n" end
		if BOOT_LOG_DESTINO == nil then
			local cand = {System.currentDirectory() .."/RETROLauncher.log",
				"mc0:/RETROLauncher.log", "mc1:/RETROLauncher.log"}
			for i = 1, #cand do
				local ok = pcall(function()
					local f = System.openFile(cand[i], FCREATE)
					System.writeFile(f, texto, string.len(texto))
					System.closeFile(f)
				end)
				if ok == true and doesFileExist(cand[i]) then
					BOOT_LOG_DESTINO = cand[i]
					break
				end
			end
			if BOOT_LOG_DESTINO == nil then return end
			-- Los cuatro ficheros de antes, ya inutiles.
			local viejos = {"BOOT_LOG.txt", "LAUNCH_LOG.txt", "MEDIA_LOG.txt",
			                "BDM_REPORT.txt", "PREBOOT_LOG.txt"}
			for i = 1, #viejos do
				local v = System.currentDirectory() .."/".. viejos[i]
				if doesFileExist(v) then pcall(System.removeFile, v) end
			end
			return
		end
		local f = System.openFile(BOOT_LOG_DESTINO, FCREATE)
		System.writeFile(f, texto, string.len(texto))
		System.closeFile(f)
	end)
end

function boot_log(linea)
	if BOOT_LOG_ON ~= true then return end
	BOOT_LOG_TXT = BOOT_LOG_TXT .. linea .. "\n"
	if BOOT_FLUSH == true then boot_escribir() end
end

--- Alias historicos: parte del codigo llama todavia irx_log / irx_escribir. -----------
irx_log = boot_log
irx_escribir = boot_escribir

--- Identidad del soporte de arranque. -------------------------------------------------
--- El comportamiento depende de DESDE DONDE se ha lanzado el programa:
---   mc0:/mc1:    Memory Card.
---   massN:       BDM: un USB o el disco interno ATA. Se distinguen por el marcador.
---   hdd0:/pfs:   HDD interno con particiones APA (stack nativo, otro mundo).
---   host:        PCSX2 / ps2link.
--- El marcador "Roms/!Retrolauncher/internal-ata-disk.flag" se escribe desde el PC en
--- el disco interno. Hace falta porque la deteccion dinamica ("la unidad aparecio al
--- cargar ata_bd") no ve nada aparecer cuando se arranca DESDE el propio disco: en
--- ese caso los drivers ya estaban residentes, cargados por el lanzador.
MARCA_ATA = "/Roms/!Retrolauncher/internal-ata-disk.flag"

BOOT_DEV = ""            -- "mass0:", "mc0:", "hdd0:"...
BOOT_TIPO = "desconocido"
BOOT_ES_ATA = false      -- true si el programa arranca desde el disco interno

if true then
	local dir = System.currentDirectory()
	local pos = string.find(dir, ":", 1, true)
	if pos ~= nil then BOOT_DEV = string.sub(dir, 1, pos) end
	local base = string.lower(BOOT_DEV)
	if base == "mc0:" or base == "mc1:" then
		BOOT_TIPO = "Memory Card"
	elseif string.sub(base, 1, 4) == "mass" then
		if doesFileExist(dir .. MARCA_ATA) then
			BOOT_TIPO = "disco interno ATA en exFAT (marcador presente)"
			BOOT_ES_ATA = true
		else
			BOOT_TIPO = "BDM: USB (o disco interno sin marcador)"
		end
	elseif string.sub(base, 1, 3) == "hdd" or string.sub(base, 1, 3) == "pfs" then
		BOOT_TIPO = "HDD interno APA (stack nativo)"
	elseif base == "host:" then
		BOOT_TIPO = "host (PCSX2 / ps2link)"
	elseif base == "cdfs:" then
		BOOT_TIPO = "disco optico"
	end
	local build = "2024 (tabla Sif, sin tabla IOP)"
	if ENCELADUS_MODERNO then build = "2025+ (tabla IOP presente)" end
	-- La primera pregunta que hay que poder responder al abrir el log: de donde
	-- viene el ELF. Cambia todo lo demas -- si hace falta el argumento de arranque,
	-- si RetroArch podra leerse a si mismo, si hay que transbordar las ROMs.
	if BOOT_ES_ATA == true then
		boot_log("ARRANCADO DESDE : DISCO INTERNO exFAT  (".. BOOT_DEV ..")")
	else
		boot_log("ARRANCADO DESDE : LLAVE USB / soporte externo  (".. BOOT_DEV ..")")
	end
	boot_log("Soporte de arranque : ".. BOOT_DEV .."  -> ".. BOOT_TIPO)
	boot_log("currentDirectory    : ".. dir)
	boot_log("Build de Enceladus  : ".. build)
	boot_log("Marcador ATA buscado: ".. dir .. MARCA_ATA)
	boot_log("")
end

--- Sondeo de las unidades y clasificacion USB / ATA. ----------------------------------
--- "antes" es la foto de las unidades tomada ANTES de cargar ata_bd: una unidad que
--- no estaba y ahora esta ha sido montada por ata_bd, luego es el disco interno.
--- La otra via es el marcador, que funciona aunque los drivers ya fuesen residentes.
function sondear_bdm(antes)
	local actual = System.currentDirectory()
	local propio = ""
	local pos = string.find(actual, ":", 1, false)
	if pos ~= nil then propio = string.sub(actual, 1, pos) end
	boot_log("")
	boot_log("Unidades detectadas (propio = ".. propio ..") :")
	for n = -1, 5 do
		local unidad = "mass:"
		if n >= 0 then unidad = "mass".. n ..":" end
		-- En la build 2025 "mass:" es un ALIAS de "mass0:": sondear los dos duplica
		-- la unidad en BDM_DEVICES y de ahi en las raices de busqueda. Solo se mira
		-- "mass:" cuando "mass0:" no existe (build 2024).
		local contenido = nil
		if unidad == "mass:" and System.listDirectory("mass0:") ~= nil then
			boot_log("  mass:   alias de mass0: en esta build, omitido")
		else
			contenido = System.listDirectory(unidad)
		end
		if contenido ~= nil then
			local texto = "  ".. unidad .."  OK  (".. #contenido .." entradas)"
			for i = 1, math.min(#contenido, 30) do
				local marca = "   "
				if contenido[i].directory == true then marca = " d " end
				texto = texto .."\n      ".. marca .. contenido[i].name
			end
			if antes[unidad] ~= true then
				BDM_ATA[unidad] = true
				texto = texto .."\n      -> ATA (montada por ata_bd, NO es un USB)"
			elseif doesFileExist(unidad .."/RETROLauncher".. MARCA_ATA) then
				BDM_ATA[unidad] = true
				texto = texto .."\n      -> ATA (marcador del disco interno presente)"
			elseif unidad == BOOT_DEV and BOOT_ES_ATA == true then
				BDM_ATA[unidad] = true
				texto = texto .."\n      -> ATA (es el soporte de arranque)"
			else
				texto = texto .."\n      -> USB"
			end
			boot_log(texto)
			if unidad ~= propio then table.insert(BDM_DEVICES, unidad) end
		else
			boot_log("  ".. unidad .."  no montada")
		end
	end
	local mcs = {"mc0:", "mc1:"}
	for i = 1, #mcs do
		if System.listDirectory(mcs[i] .."/") ~= nil then
			boot_log("  ".. mcs[i] .."   OK (Memory Card)")
		else
			boot_log("  ".. mcs[i] .."   no accesible")
		end
	end
end

function irx_load()
	local actual = System.currentDirectory()

	-- Foto de las unidades antes de tocar nada.
	local antes = {}
	for n = -1, 5 do
		local u = "mass:"
		if n >= 0 then u = "mass".. n ..":" end
		if System.listDirectory(u) ~= nil then antes[u] = true end
	end

	-- El pre-boot (System/index.lua) ya ha cargado -o decidido no cargar- los IRX.
	-- Recargar un driver ya registrado cuelga la consola, asi que aqui solo se
	-- sondean las unidades.
	if PREBOOT_IRX_HECHO == true then
		boot_log("Pre-boot detectado (System/index.lua), origen: ".. tostring(PREBOOT_ORIGEN))
		boot_log("Los IRX ya fueron tratados alli: no se recargan.")
		sondear_bdm(antes)
		return
	end

	-- Arranque DESDE el disco interno: dev9 y ata_bd estan forzosamente residentes,
	-- cargados por el lanzador (wLaunchELF ISR u otro) - sin ellos este fichero no se
	-- habria podido leer. Registrar un driver dos veces cuelga la consola
	-- ("BDM: ERROR: Already registered!"), asi que aqui NO se carga nada.
	if BOOT_ES_ATA == true then
		boot_log("Arranque desde el disco interno: NO se carga ningun IRX.")
		boot_log("dev9/ata_bd ya estan residentes (los cargo el lanzador); recargarlos")
		boot_log("colgaria la consola.")
		BDM_ATA[BOOT_DEV] = true
		sondear_bdm(antes)
		return
	end

	-- Build 2024: Sif.loadModule cuelga la consola en CUALQUIER llamada. Probado con
	-- las formas de 1 y 3 argumentos y hasta con un fichero que no es un IRX: se
	-- congela antes de la inicializacion de video, sin mensaje.
	if IRX_CARGA_ACTIVA ~= true then
		boot_log("Build 2024: no se cargan IRX (Sif.loadModule cuelga en esta build).")
		boot_log("Sin ata_bd no hay disco interno, salvo que el lanzador lo dejase cargado.")
		sondear_bdm(antes)
		return
	end

	local hecho = {}
	boot_log("Carga de modulos IRX desde IRX/ :")
	for i = 1, #IRX_IGNORAR do hecho[IRX_IGNORAR[i]] = "ignorar" end

	-- IMPORTANTE: NO usar Sif.loadModule(ruta). Esa funcion hace que el IOP resuelva
	-- la ruta con su modulo LOADFILE, que usa el viejo "ioman". Pero "mass:" lo aporta
	-- bdmfs_fatfs, que se registra en "iomanX". El IOP no sabe abrir la ruta y la
	-- llamada RPC nunca vuelve: la consola se congela. Comprobado con cualquier
	-- fichero, incluso uno que no es un IRX, y en las builds de 2024 y de 2025.
	-- Solucion: leer el fichero desde el EE y enviar los bytes con loadModuleBuffer.
	local function cargar(nombre)
		local ruta = actual .."/IRX/".. nombre
		boot_log("-> ".. nombre)

		local okl, datos, tam = pcall(function()
			local fd = System.openFile(ruta, FREAD)
			local size = System.sizeFile(fd)
			System.seekFile(fd, 0, SET)
			local buf = System.readFile(fd, size)
			System.closeFile(fd)
			return buf, size
		end)

		if okl == false or datos == nil then
			boot_log("   ERROR de lectura: ".. tostring(datos))
			return
		end
		-- Parentesis obligatorios: string.byte("") no devuelve NINGUN valor (ni
		-- siquiera nil) y tostring() sin argumento es un error de ejecucion.
		boot_log("   leidos ".. tostring(tam) .." bytes, primer byte = ".. tostring((string.byte(datos, 1))) .." (127 = ELF valido)")

		local okc, ID = pcall(Sif.loadModuleBuffer, datos, tam)
		boot_log("   loadModuleBuffer ok=".. tostring(okc) .."  ID=".. tostring(ID))
	end

	for i = 1, #IRX_ORDEN do
		if doesFileExist(actual .."/IRX/".. IRX_ORDEN[i]) then
			cargar(IRX_ORDEN[i])
			hecho[string.lower(IRX_ORDEN[i])] = "hecho"
		end
	end

	local buscar_irx = System.listDirectory(actual.. "/IRX")
	if buscar_irx ~= nil and #buscar_irx >= 1 then
		for elementos = 1, #buscar_irx do
			local nombre = buscar_irx[elementos].name
			local clave = string.lower(nombre)
			if string.lower(string.sub(nombre, -4)) == ".irx" then
				if hecho[clave] == "ignorar" then
					boot_log("-- ignorado ".. nombre)
				elseif hecho[clave] == nil then
					cargar(nombre)
				end
			end
		end
	end

	if System.sleep ~= nil then System.sleep(1) end
	sondear_bdm(antes)
end
irx_load()

--- Raices de busqueda de juegos ("append" USB + disco interno). -----------------------
--- RAICES[1] es SIEMPRE el soporte de arranque. Se anaden las unidades ATA que
--- contengan un directorio con el mismo nombre que el del launcher.
--- Ejemplo: arranque en "mass:/RETROLauncher", disco interno en "mass1:" con un
--- "mass1:/RETROLauncher" => se buscan los juegos en los dos.
RAICES = { System.currentDirectory() }

--- Nombre de la carpeta del lanzador, sea cual sea. Se guarda porque otras partes
--- necesitan construir la misma ruta en otro soporte, y dar por hecho que se llama
--- "RETROLauncher" fallaria en cuanto alguien la renombrase.
CARPETA_LANZADOR = "RETROLauncher"

if true then
	local actual = System.currentDirectory()
	local nombre_carpeta = actual
	local corte = string.find(string.reverse(actual), "/", 1, true)
	if corte ~= nil then nombre_carpeta = string.sub(actual, -corte+1) end
	CARPETA_LANZADOR = nombre_carpeta
	-- TODA unidad BDM con un directorio homonimo, sea ATA o USB. La restriccion "solo
	-- ATA" era correcta cuando el arranque venia siempre del USB; al arrancar DESDE el
	-- disco interno la situacion se invierte, y es la llave USB la que hay que sumar.
	for i = 1, #BDM_DEVICES do
		local candidata = BDM_DEVICES[i] .."/".. nombre_carpeta
		if System.listDirectory(candidata) ~= nil then
			table.insert(RAICES, candidata)
		end
	end
	local resumen = "\nRaices de busqueda:\n"
	for i = 1, #RAICES do resumen = resumen .."  ".. i ..". ".. RAICES[i] .."\n" end
	boot_log(resumen)
end

--- Unidad donde vive el directorio "POPS". Puede estar en el soporte de arranque o
--- en el disco interno exFAT. Se prefiere la que contenga los binarios de POPStarter
--- ("POPS_IOX.PAK"), luego cualquiera que exista, y en ultimo recurso el arranque.
POPS_RAIZ = nil

if true then
	local cand = {}
	local pos = string.find(System.currentDirectory(), ":", 1, true)
	if pos ~= nil then table.insert(cand, string.sub(System.currentDirectory(), 1, pos)) end
	for i = 1, #BDM_DEVICES do table.insert(cand, BDM_DEVICES[i]) end

	for i = 1, #cand do
		if POPS_RAIZ == nil and doesFileExist(cand[i] .."/POPS/POPS_IOX.PAK") then
			POPS_RAIZ = cand[i]
		end
	end
	if POPS_RAIZ == nil then
		for i = 1, #cand do
			if POPS_RAIZ == nil and System.listDirectory(cand[i] .."/POPS") ~= nil then
				POPS_RAIZ = cand[i]
			end
		end
	end
	if POPS_RAIZ == nil and #cand >= 1 then POPS_RAIZ = cand[1] end
	if POPS_RAIZ == nil then POPS_RAIZ = "mass:" end
end

boot_log("POPS_RAIZ = ".. tostring(POPS_RAIZ))

--- Chequeo de la configuracion de POPStarter. ----------------------------------------
--- Los drivers USB de recambio (BDMAssault) SOLO sirven en la Memory Card:
--- "mc0:/POPSTARTER/usbd.irx" y "usbhdfsd.irx". Al arrancar, POPStarter aun no sabe
--- leer el USB -es justo lo que intenta montar- asi que un POPSTARTER/ en la llave
--- es letra muerta. Aqui se listan los nombres EXACTOS, porque ademas es sensible a
--- mayusculas.
if true then
	boot_log("")
	boot_log("Chequeo POPStarter (drivers de recambio):")
	for _i, mc in ipairs({"mc0:", "mc1:"}) do
		local c = System.listDirectory(mc .."/POPSTARTER")
		if c == nil then
			boot_log("  ".. mc .."/POPSTARTER/  no existe")
		else
			local linea = "  ".. mc .."/POPSTARTER/  (".. #c .." entradas)"
			local vistos = {}
			for i = 1, #c do
				if c[i].directory == false then
					linea = linea .."\n      ".. c[i].name .."  (".. tostring(c[i].size) .." bytes)"
					vistos[string.lower(c[i].name)] = c[i].name
				end
			end
			for _j, esperado in ipairs({"usbd.irx", "usbhdfsd.irx"}) do
				local real = vistos[esperado]
				if real == nil then
					linea = linea .."\n      FALTA ".. esperado
				elseif real ~= esperado then
					linea = linea .."\n      OJO: '".. real .."' deberia llamarse '".. esperado .."' (minusculas)"
				end
			end
			boot_log(linea)
		end
	end
	local pos_b = string.find(System.currentDirectory(), ":", 1, true)
	if pos_b ~= nil then
		local raiz_boot = string.sub(System.currentDirectory(), 1, pos_b)
		if System.listDirectory(raiz_boot .."/POPSTARTER") ~= nil then
			boot_log("  AVISO: existe ".. raiz_boot .."/POPSTARTER/ - ahi NO sirve de nada.")
			boot_log("  POPStarter solo puede leer esos drivers desde la Memory Card.")
		end
	end
end

boot_log("")
boot_log("Fin del arranque del sistema. Lo que sigue se anade sin flush por linea.")
BOOT_FLUSH = false
boot_escribir()

--- Primera raiz donde exista la ruta relativa dada (empieza por "/"). ------------------
function RAIZ(rel)
	for i = 1, #RAICES do
		if doesFileExist(RAICES[i] .. rel) then return RAICES[i] end
	end
	return RAICES[1]
end

--- PlayStation 1 / POPStarter. --------------------------------------------------------
--- POPStarter lee siempre el .VCD y escribe la tarjeta de memoria virtual en
--- "<unidad>/POPS/<nombre del juego>/", este donde este su ELF (por eso funciona el
--- montaje con el ELF en "APPS/"). Aun asi se admite "<raiz>/Roms/psx-pops(vcd)/" como
--- biblioteca, para no tener que separar los juegos del resto: el fichero se traslada a
--- "POPS/" la primera vez que se lanza. Dentro de la misma unidad es un renombrado,
--- instantaneo sea cual sea el tamano; entre unidades distintas hay que copiar.
POPS_SUB = "/Roms/psx-pops(vcd)"

--- Unidades que pueden tener una carpeta "POPS" en su raiz: el soporte de arranque
--- y cada unidad BDM. La misma coleccion se usa para buscar y para lanzar.
function POPS_UNIDADES()
	local u = {}
	local actual = System.currentDirectory()
	local pos = string.find(actual, ":", 1, true)
	if pos ~= nil then table.insert(u, string.sub(actual, 1, pos)) end
	if BDM_DEVICES ~= nil then
		for i = 1, #BDM_DEVICES do
			local rep = false
			for j = 1, #u do if u[j] == BDM_DEVICES[i] then rep = true end end
			if rep == false then table.insert(u, BDM_DEVICES[i]) end
		end
	end
	return u
end

--- Unidad cuyo "POPS/" contiene ese fichero. POPStarter exige que el .VCD, su ELF
--- y la tarjeta de memoria esten en la MISMA unidad, asi que lanzar con POPS_RAIZ
--- fallaba cuando el juego vivia en el otro soporte.
function POPS_DE(nombre)
	if nombre ~= nil then
		local u = POPS_UNIDADES()
		for i = 1, #u do
			if doesFileExist(u[i] .."/POPS/".. nombre) then return u[i] end
		end
	end
	return POPS_RAIZ
end

--- Ruta real del .VCD: primero "POPS/" de cada unidad, luego la biblioteca de cada
--- raiz. nil si no esta en ninguna parte.
function RUTA_VCD(nombre)
	local u = POPS_UNIDADES()
	for i = 1, #u do
		if doesFileExist(u[i] .."/POPS/".. nombre) then
			return u[i] .."/POPS/".. nombre
		end
	end
	for i = 1, #RAICES do
		if doesFileExist(RAICES[i] .. POPS_SUB .."/".. nombre) then
			return RAICES[i] .. POPS_SUB .."/".. nombre
		end
	end
	return nil
end

--- Lleva el .VCD a "POPS/" si todavia no esta ahi. Devuelve true si al final si esta.
function VCD_A_POPS(nombre)
	local destino = POPS_RAIZ .."/POPS/".. nombre
	if doesFileExist(destino) then return true end
	local origen = RUTA_VCD(nombre)
	if origen == nil then return false end
	-- Comparacion de unidad SIN normalizar: "mass0:" y "mass1:" son discos distintos.
	local function unidad(p)
		local pos = string.find(p, ":", 1, true)
		if pos == nil then return "" end
		return string.lower(string.sub(p, 1, pos))
	end
	if unidad(origen) == unidad(destino) and System.rename ~= nil then
		pcall(System.rename, origen, destino)
	end
	if doesFileExist(destino) == false then
		pcall(System.copyFile, origen, destino)
	end
	return doesFileExist(destino)
end

--- Inventario de lo que el launcher ve en cada raiz. Se anade al journal. ------
--- Poner INVENTARIO_ON a false cuando ya no haga falta.
INVENTARIO_ON = false

function inventario()
	if INVENTARIO_ON ~= true then return end
	local sistemas = {"Sega Megadrive", "Sega Master System", "Sega Game Gear", "Nintendo Famicom",
		"Nintendo Game Boy", "Nintendo Game Boy Color", "Nintendo Game Boy Advance", "Atari 2600",
		"Atari Lynx", "Sega SG-1000", "Neo Geo Pocket", "Nintendo Super Famicom"}

	local function listar(etiqueta, ruta)
		local c = System.listDirectory(ruta)
		if c == nil then
			irx_log("    ".. etiqueta .."  ->  NO EXISTE   (".. ruta ..")")
			return
		end
		local ficheros = 0
		for i = 1, #c do
			if c[i].directory == false then ficheros = ficheros + 1 end
		end
		local t = "    ".. etiqueta .."  ->  ".. ficheros .." fichero(s)   (".. ruta ..")"
		local n = 0
		for i = 1, #c do
			if c[i].directory == false and string.sub(c[i].name, 1, 1) ~= "." then
				n = n + 1
				if n <= 25 then t = t .."\n         ".. c[i].name end
			end
		end
		if n > 25 then t = t .."\n         ... y ".. (n-25) .." mas" end
		irx_log(t)
	end

	irx_log("")
	irx_log("=====================================================================")
	irx_log("INVENTARIO: lo que RETROLauncher encuentra en cada raiz")
	irx_log("=====================================================================")

	for i = 1, #RAICES do
		local r = RAICES[i]
		local etiqueta_raiz = "USB / soporte de arranque"
		if ES_RAIZ_ATA(r) then etiqueta_raiz = "DISCO INTERNO exFAT (ATA)" end
		irx_log("")
		irx_log("RAIZ ".. i ..": ".. r .."   [".. etiqueta_raiz .."]")
		for s = 1, #sistemas do
			listar(sistemas[s], r .."/Roms/Roms ".. sistemas[s])
		end
		listar("PS1 (CUEs + ember)", r .."/Roms/CUEs PlayStation 1")
		listar("PS2 (ISOs)",         r .."/Roms/ISOs PlayStation 2")
		listar("APPS",               r .."/Roms/APPS")
	end

	-- Directorios a nivel de unidad (fuera de la carpeta del launcher). --------------
	local unidades = {}
	local pos = string.find(System.currentDirectory(), ":", 1, true)
	if pos ~= nil then table.insert(unidades, string.sub(System.currentDirectory(), 1, pos)) end
	for i = 1, #BDM_DEVICES do table.insert(unidades, BDM_DEVICES[i]) end

	for i = 1, #unidades do
		local u = unidades[i]
		local etiqueta_u = "USB"
		if BDM_ATA[u] == true then etiqueta_u = "DISCO INTERNO exFAT (ATA)" end
		irx_log("")
		irx_log("UNIDAD ".. u .."   [".. etiqueta_u .."]")
		listar("DVD",  u .."/DVD")
		listar("CD",   u .."/CD")
		listar("POPS", u .."/POPS")
		listar("APPS", u .."/APPS")
	end
	irx_log("")
	irx_log("Fin del inventario.")
	irx_escribir()
end

--- Journal de lancement. Ecrit dans RETROLauncher.log juste avant chaque loadELF, pour
--- qu'un ecran noir laisse une trace exploitable au prochain demarrage.
--- Mettre LAUNCH_LOG_ON a false pour desactiver.
LAUNCH_LOG_ON = true

--- Reinicio del IOP antes de lanzar un core de RetroArch. ----------------------------
--- 0 = no reiniciar.   1 = reiniciar antes de entregar el ELF.
---
--- Estuvo en 0 mucho tiempo, con este razonamiento: RetroArch reinicia el IOP el
--- mismo nada mas arrancar ("reset_IOP()" en frontend_ps2_init), asi que hacerlo dos
--- veces no aportaba nada. Era cierto... mientras el IOP no llevase nada especial.
---
--- Ahora si lleva algo: el pre-boot ("System/index.lua") carga dev9_ns y ata_bd para
--- que el lanzador vea el disco interno. Al entregar el core sin reiniciar, RetroArch
--- se encuentra un ata_bd ya residente y un bus ATA ya tomado, y vuelve a cargar el
--- suyo encima. Sintoma: pantalla negra, y ni una linea en el log de RetroArch -
--- muere antes de poder escribir.
---
--- La prueba que lo senala: el MISMO core, con el MISMO juego en el disco interno,
--- arranca perfectamente cuando se lanza a mano desde uLaunchELF, que si reinicia el
--- IOP. Solo falla por la via del lanzador.
---
--- PROBADO EN CONSOLA, Y ES QUE NO: con 1 la pantalla se queda negra y la consola
--- vuelve al menu del sistema. Ese retorno al menu es la firma de un ELF que muere o
--- que no llega a cargarse, no de un cuelgue. Enceladus NO lee el ELF antes de
--- reiniciar el IOP: se queda sin drivers para leerlo. Vuelve a 0.
--- (Con 0 el sintoma es otro: pantalla negra que se queda, sin volver al menu. Son
--- dos fallos distintos, y solo el segundo sigue abierto.)
IOP_REBOOT_CORES = 0

--- Tamano maximo del historial. Al pasarlo se recorta por el PRINCIPIO, nunca por el
--- final: lo interesante es siempre lo ultimo. A ~700 bytes por entrada esto guarda
--- Una entrada de lanzamiento, en el journal unico. ----------------------------------
--- Tenia fichero propio, LAUNCH_LOG.txt, con su propio historial y su propia marca de
--- sesion. Las dos cosas las hace ya el nucleo del journal, asi que aqui solo queda
--- formatear el bloque y mandarlo por boot_log con la categoria delante.
LAUNCH_LOG_ON = true

function log_lanzamiento(titulo, campos)
	if LAUNCH_LOG_ON ~= true then return end
	boot_log("")
	boot_log("LANZA  ------------------------------------------------------")
	boot_log("LANZA  ".. tostring(titulo))
	for i = 1, #campos do
		boot_log("LANZA    ".. tostring(campos[i]))
	end
	if MEDIA_DIAG ~= nil and #MEDIA_DIAG >= 1 then
		boot_log("LANZA    caratula, rutas probadas en orden:")
		for i = 1, #MEDIA_DIAG do boot_log("LANZA      ".. tostring(MEDIA_DIAG[i])) end
	end
	-- Esto sale justo antes de un loadELF, que no vuelve nunca. Si es la ultima
	-- entrada del fichero, el fallo esta en el ELF que nombra.
	boot_escribir()
end

--- Verifica que un fichero existe y lo describe para el journal. ---------------------
function log_existe(etiqueta, ruta)
	local marca = "NO EXISTE"
	if ruta ~= nil and doesFileExist(ruta) then marca = "ok" end
	return etiqueta .." [".. marca .."] : ".. tostring(ruta)
end

--- Origen de cada juego encontrado: ORIGEN["identidad|nombre"] = raiz. ---------------
--- Busqueda en el lector CD/DVD ("cdfs:"). -------------------------------------------
--- Spaghetticode (autor del proyecto) reporta que el programa se cuelga si se lanza
--- desde un wLaunchELF que ya haya cargado el modulo CD/DVD (consola Slim), y que el
--- problema desaparece si se omite todo lo relacionado con la busqueda en el lector.
--- false = no tocar el lector. true = comportamiento original.
BUSCAR_CDVD = false

--- Nombres de carpeta al estilo EmulationStation / Batocera, por sistema. ------------
--- Se aceptan ademas de la estructura propia "Roms/Roms <sistema>", tanto en
--- "<raiz>/roms/<alias>" como en "<unidad>/roms/<alias>" (disposicion Batocera).
ES_ALIAS = {
	{"megadrive", "genesis", "md"},
	{"mastersystem", "sms"},
	{"gamegear", "gg"},
	{"nes", "famicom", "fds"},
	{"gb", "gameboy"},
	{"gbc", "gameboycolor"},
	{"gba", "gameboyadvance"},
	{"atari2600"},
	{"lynx", "atarilynx"},
	{"sg1000", "sg-1000"},
	{"ngp", "ngpc", "neogeopocket"},
	{"snes", "sfc", "supernintendo"},
}

--- Ruta real de una ROM: el directorio memorizado durante el scan si existe, si no
--- la estructura propia resuelta sobre las raices.
function RUTA_ROM(identidad, sistema, nombre)
	local clave = tostring(identidad) .."|".. nombre
	if ORIGEN_DIR ~= nil and ORIGEN_DIR[clave] ~= nil then
		return ORIGEN_DIR[clave] .. nombre
	end
	return RUTA("/Roms/Roms ".. sistema .."/".. nombre)
end

--- Titulos reales de los juegos. TITULOS["identidad|fichero"] = titulo. -------------
--- Los genera el script "HelperScripts/MediaCopier.py" en un "titles.txt" por
--- carpeta, a partir del gamelist.xml de Batocera / Recalbox / EmulationStation.
--- Formato de cada linea: nombre_de_fichero|Titulo del juego
TITULOS = {}
TITULOS_LEIDOS = {}

function cargar_titulos(directorio, identidad)
	if directorio == nil then return end
	if TITULOS_LEIDOS[directorio] == true then return end
	TITULOS_LEIDOS[directorio] = true

	local ruta = directorio .."/titles.txt"
	if doesFileExist(ruta) == false then return end
	pcall(function()
		local fd = System.openFile(ruta, FREAD)
		local tam = System.sizeFile(fd)
		System.seekFile(fd, 0, SET)
		local datos = System.readFile(fd, tam)
		System.closeFile(fd)
		for linea in string.gmatch(datos, "[^\r\n]+") do
			local corte = string.find(linea, "|", 1, true)
			if corte ~= nil then
				local fichero = string.sub(linea, 1, corte-1)
				local titulo  = string.sub(linea, corte+1)
				if fichero ~= "" and titulo ~= "" then
					TITULOS[tostring(identidad) .."|".. fichero] = titulo
				end
			end
		end
	end)
end

--- Nombre a mostrar: el titulo real si se conoce, si no el nombre de fichero
--- recortado de su extension como hace el programa de origen.
function NOMBRE_VISIBLE(identidad, nombre, desde)
	if nombre == nil then return "" end
	local t = TITULOS[tostring(identidad) .."|".. nombre]
	if t == nil then
		local limpio = nombre
		while string.sub(limpio, -1) == " " do limpio = string.sub(limpio, 1, -2) end
		t = string.sub(limpio, 1, -CONTROL.EXTENSION)
	end
	if desde ~= nil and desde > 1 then return string.sub(t, desde) end
	return t
end

--- Base de datos de lo que la consola ve realmente: "exfatdb.json", junto al ELF. ----
--- Se rellena a medida que se recorren los sistemas y se reescribe en cada cambio.
--- Sirve sobre todo para ajustar los scripts del PC: es la unica fuente fiable de
--- lo que la PS2 encuentra, con los nombres de unidad tal como ella los ve.
EXFATDB_ON = true
EXFATDB = {}
EXFATDB_SUCIA = false

--- Escapa una cadena para JSON. -----------------------------------------------------
function json_txt(s)
	s = tostring(s)
	s = string.gsub(s, "\\", "\\\\")
	s = string.gsub(s, "\"", "\\\"")
	s = string.gsub(s, "[\r\n\t]", " ")
	return "\"".. s .."\""
end

--- Registra un directorio explorado y su contenido. ---------------------------------
--- "clave" permite agrupar bajo otro nombre que el de ROMS_DIR[identidad]: PS1 usa
--- una sola identidad para dos formatos ("psx-ember(bin and cue)" y "psx-pops(vcd)").
function exfatdb_dir(identidad, sistema, directorio, entradas, clave)
	if EXFATDB_ON ~= true or directorio == nil then return end
	local reg = EXFATDB[directorio]
	if reg == nil then
		reg = {
			identidad = identidad,
			sistema   = sistema,
			clave     = clave,
			ata       = ES_RAIZ_ATA(directorio),
			juegos    = {},
		}
		EXFATDB[directorio] = reg
	end
	-- FUSIONAR, no sustituir. Un mismo directorio aparece varias veces en la lista
	-- de busqueda: con su nombre propio y otra vez como alias EmulationStation. En
	-- la segunda pasada los juegos ya estan en "vistos", asi que la lista llega
	-- vacia; sustituir el registro borraba todo lo encontrado en la primera.
	for i = 1, #entradas do
		reg.juegos[entradas[i].fichero] = entradas[i].titulo
	end
	EXFATDB_SUCIA = true
end

--- Vuelca el fichero. ---------------------------------------------------------------
--- Agrupado por soporte ("USB" / "ATA") y por sistema, no por directorio: en un
--- sistema de ficheros que ignora mayusculas, "Roms/nes" y "roms/nes" son la misma
--- carpeta y aparecian dos veces. Aqui se fusionan, y los juegos repetidos tambien.
function exfatdb_escribir()
	if EXFATDB_ON ~= true or EXFATDB_SUCIA ~= true then return end
	EXFATDB_SUCIA = false
	pcall(function()
		-- Reagrupar: soporte -> sistema -> conjunto de ficheros.
		local grupo = {USB = {}, ATA = {}}
		for ruta, info in pairs(EXFATDB) do
			local soporte = "USB"
			if info.ata == true then soporte = "ATA" end
			local clave = info.clave or ROMS_DIR[info.identidad]
			if clave == nil then clave = tostring(info.sistema) end
			if grupo[soporte][clave] == nil then grupo[soporte][clave] = {} end
			local destino = grupo[soporte][clave]
			for fichero, titulo in pairs(info.juegos) do
				destino[fichero] = titulo
			end
		end

		local function bloque(soporte, sangria)
			local sistemas = {}
			for k, _v in pairs(grupo[soporte]) do table.insert(sistemas, k) end
			table.sort(sistemas)
			local s = ""
			for i = 1, #sistemas do
				local ficheros = {}
				for f, _t in pairs(grupo[soporte][sistemas[i]]) do
					table.insert(ficheros, f)
				end
				table.sort(ficheros)
				-- "POPS" vive en la raiz de la unidad, no bajo "roms/".
			local etiqueta = "roms/".. sistemas[i]
			if sistemas[i] == "POPS" then etiqueta = "POPS" end
			s = s .. sangria .."  ".. json_txt(etiqueta) ..": [\n"
				for j = 1, #ficheros do
					s = s .. sangria .."    ".. json_txt(ficheros[j])
					if j < #ficheros then s = s .."," end
					s = s .."\n"
				end
				s = s .. sangria .."  ]"
				if i < #sistemas then s = s .."," end
				s = s .."\n"
			end
			return s
		end

		--- Unidad asociada a cada soporte, para poder reconstruir la ruta completa.
		local u_usb, u_ata = "", ""
		local pos = string.find(System.currentDirectory(), ":", 1, true)
		if pos ~= nil then u_usb = string.sub(System.currentDirectory(), 1, pos) end
		for i = 1, #BDM_DEVICES do
			if BDM_ATA[BDM_DEVICES[i]] == true and u_ata == "" then
				u_ata = BDM_DEVICES[i]
			end
		end

		local t = "{\n"
		t = t .."  \"generado_por\": \"RETROLauncher fork - exFAT HDD\",\n"
		t = t .."  \"nota\": \"Rutas relativas a la carpeta del launcher en cada unidad. "
		t = t .."Solo aparecen los sistemas abiertos en el menu desde el ultimo arranque.\",\n"
		t = t .."  \"launcher\": ".. json_txt(System.currentDirectory()) ..",\n"
		t = t .."  \"USB\": {\n"
		t = t .."    \"unidad\": ".. json_txt(u_usb) ..",\n"
		t = t .."    \"juegos\": {\n".. bloque("USB", "    ") .."    }\n"
		t = t .."  },\n"
		t = t .."  \"ATA\": {\n"
		t = t .."    \"unidad\": ".. json_txt(u_ata) ..",\n"
		t = t .."    \"juegos\": {\n".. bloque("ATA", "    ") .."    }\n"
		t = t .."  }\n}\n"

		local f = System.openFile(System.currentDirectory() .."/exfatdb.json", FCREATE)
		System.writeFile(f, t, string.len(t))
		System.closeFile(f)
	end)
end

--- Carpeta de medios por identidad, incluidos los sistemas sin alias EmulationStation
--- (APPS, PS1, PS2). Es el nombre usado bajo "Roms/<aqui>/media/".
--- Arranque de RetroArch a traves de "raboot.elf". ----------------------------------
--- DESCARTADO, y el motivo esta en el codigo de RetroArch. "raboot.elf" es el
--- Salamander, y en "frontend/drivers/platform_ps2.c" el bloque que pasa el juego al
--- core esta dentro de un "#ifndef IS_SALAMANDER": el Salamander llama al core con
--- CERO argumentos. Nunca podra arrancar una ROM, solo abrir el menu de RetroArch.
--- Ademas reescribe "retroarch-salamander.cfg" con su propia eleccion, borrando la
--- nuestra. Se deja el camino por si sirve para depurar, apagado.
RABOOT_ON = false

--- Devuelve la ruta de raboot.elf si esta disponible, si no nil. ---------------------
function RUTA_RABOOT()
	if RABOOT_ON ~= true or RAICES == nil then return nil end
	for i = 1, #RAICES do
		local base = RUTA_LIBRETRO()
		local cand = RAICES[i] .."/LibretroPS2Files/raboot.elf"
		if base ~= nil then cand = base .."/raboot.elf" end
		if doesFileExist(cand) then return cand end
	end
	return nil
end

--- Escribe el core elegido en el salamander que lee raboot. -------------------------
--- Ruta del salamander que corresponde a un raboot.elf dado. -------------------------
function RUTA_SALAMANDER(ruta_raboot)
	if ruta_raboot == nil then return nil end
	-- "raboot.elf" son 10 caracteres: hay que quitar 10, no 11. Con -12 se comia
	-- tambien la barra y el fichero se escribia en una ruta inexistente, en silencio.
	local base = string.sub(ruta_raboot, 1, string.len(ruta_raboot) - 10)
	return base .."retroarch/retroarch-salamander.cfg"
end

--- Escribe el core elegido en el salamander que lee raboot. -------------------------
--- Se relee despues: si el contenido no es el esperado, se devuelve false y el
--- lanzamiento cae en la llamada directa en vez de arrancar el core anterior.
function PREPARAR_RABOOT(ruta_raboot, ruta_core)
	if ruta_raboot == nil or ruta_core == nil then return false end
	local cfg = RUTA_SALAMANDER(ruta_raboot)
	local linea = "libretro_path = \"".. ruta_core .."\"\n"
	pcall(function()
		local f = System.openFile(cfg, FCREATE)
		System.writeFile(f, linea, string.len(linea))
		System.closeFile(f)
	end)
	local leido = nil
	pcall(function()
		local f = System.openFile(cfg, FREAD)
		local tam = System.sizeFile(f)
		System.seekFile(f, 0, SET)
		leido = System.readFile(f, tam)
		System.closeFile(f)
	end)
	return leido ~= nil and string.find(leido, ruta_core, 1, true) ~= nil
end

--- Cores RetroArch. -----------------------------------------------------------------
--- "LibretroPS2Files/cores/" recibe una nightly descomprimida tal cual, y es
--- el UNICO sitio donde se buscan los cores. Las copias por sistema que habia en
--- "System/RetroarchPS2/<sistema>/cores/" estan borradas: eran los mismos diez ficheros
--- repetidos trece veces, 36 MB.
--- Se busca en TODAS las raices, asi que la carpeta puede estar en el disco exFAT.
--- "ruta_original" se conserva como respaldo por si alguien reintroduce esas copias.
--- uLaunchELF, cualquiera que sea el nombre del ELF. ---------------------------------
--- Cada version se distribuye con un nombre distinto -- "WLE.ELF", "WLE-R3Z.ELF",
--- "WLE-R3Z-DS34.ELF"... -- asi que buscarlo por nombre fijo se rompe en cuanto el
--- usuario actualiza. Se coge el primer ".elf" de la carpeta.
--- Un nombre que empieza por "_" esta desactivado a proposito: es la marca que usa el
--- menu para esconder la aplicacion de la lista sin borrarla.
--- Devuelve (ruta, nombre, desactivado) o nil.
function RUTA_WLE(incluir_desactivado)
	local dir = System.currentDirectory() .."/uLaunchELF"
	local lista = System.listDirectory(dir)
	if lista == nil then return nil end
	local reserva, reserva_n = nil, nil
	for i = 1, #lista do
		local n = lista[i].name
		if lista[i].directory == false and string.lower(string.sub(n, -4)) == ".elf" then
			if string.sub(n, 1, 1) == "_" then
				if reserva == nil then reserva, reserva_n = dir .."/".. n, n end
			else
				return dir .."/".. n, n, false
			end
		end
	end
	if incluir_desactivado == true and reserva ~= nil then
		return reserva, reserva_n, true
	end
	return nil
end

--- Carpetas del modulo RetroArch. ----------------------------------------------------
---
---   LibretroPS2Files/
---     cores/  info/  raboot.elf       la nightly, descomprimida tal cual
---     retroarch/retroarch.cfg         LA configuracion. Una. No hay copia de fabrica.
---     retroarch/config/<Core>/        los ajustes por core
---
--- Hubo aqui una carpeta "DefaultCFGs/" que guardaba un segundo "retroarch.cfg" del
--- que se reconstruia el primero. Se ha quitado: dos ficheros con el mismo papel es
--- una ocasion de que difieran, y no hacia falta. Una nightly no trae "retroarch/", y
--- si falta, RetroArch se escribe el suyo con sus propios valores -- que es justamente
--- lo que una copia de fabrica intentaba imitar. El lanzador solo tiene que reimponer
--- encima sus claves, y eso lo hace en cada arranque de juego.
---
--- RetroArch encuentra sus carpetas solo: al arrancar, un core toma su propio
--- directorio y SUBE UN NIVEL ("path_parent_dir" en "frontend/drivers/platform_ps2.c"),
--- asi que la carpeta que contiene "cores/" es su raiz. Da igual como se llame.
--- Donde puede estar la nightly, en orden de preferencia. Se acepta tanto
--- descomprimida en su propia subcarpeta como directamente en LibretroPS2Files.
LIBRETRO_SUBS = {"/LibretroPS2Files", "/LibretroPS2Files/UnzippedFileHere"}

--- La raiz de RetroArch: la carpeta que contiene "cores/". ---------------------------
--- PRIORIDAD AL SOPORTE QUE EL CORE PODRA LEER. Un core arranca haciendo SifIopReset:
--- el ELF ya esta en RAM, pero el IOP se vacia y el disco interno deja de existir para
--- el. Si sus "cores/", "info/" y "retroarch/" estan en ese disco, se queda sin nada
--- que leer y muere antes de dibujar el primer fotograma. Ni siquiera "raboot.elf"
--- sobrevive: no encuentra los cores y sale.
--- Es un problema conocido, no una particularidad de este fork: el autor de PSBBN da
--- el mismo rodeo en su issue #448 -- el ELF donde se quiera, TODO lo demas en el USB.
--- Por eso se busca primero en un soporte que no sea el disco ATA, y solo se cae al
--- disco interno si no hay otra cosa (donde funcionara con cores parcheados, y solo
--- con ellos).
--- Instalacion impuesta para este lanzamiento, si ha habido que preparar una. --------
LIBRETRO_FORZADO = nil

--- Y el resultado del ultimo rastreo, para no repetirlo. ------------------------------
--- Esto NO es una optimizacion cosmetica. Cada rastreo lista "cores/" en hasta seis
--- sitios, y esa carpeta lleva una decena de ELF de varios MB: sobre exFAT via BDM
--- cuesta segundos. Se llamaba tres veces solo durante el arranque -- LIBRETRO_REPARAR,
--- el diagnostico, y la pantalla de carga -- y el resultado no puede cambiar entre
--- ellas. La pantalla parecia colgada porque, sencillamente, lo estaba esperando.
--- "" quiere decir "ya se busco y no habia nada", que es distinto de "aun no se ha
--- buscado": sin esa distincion, el caso "no hay RetroArch" repetiria el rastreo entero
--- en cada llamada, que es justamente el mas caro de todos.
LIBRETRO_CACHE = nil

function RUTA_LIBRETRO()
	if LIBRETRO_FORZADO ~= nil then return LIBRETRO_FORZADO end
	if LIBRETRO_CACHE == "" then return nil end
	if LIBRETRO_CACHE ~= nil then return LIBRETRO_CACHE end
	if RAICES == nil then return nil end   -- aun sin unidades: no se guarda nada
	-- Tres pasadas: primero una instalacion completa fuera del disco interno, que es
	-- la unica que un core sabra leer; luego una completa donde sea; y en ultimo
	-- lugar cualquier cosa que tenga cores, para al menos poder decir algo.
	for pasada = 1, 3 do
		for i = 1, #RAICES do
			local es_ata = ES_RAIZ_ATA(RAICES[i] .."/x")
			if pasada ~= 1 or es_ata == false then
				for k = 1, #LIBRETRO_SUBS do
					local cand = RAICES[i] .. LIBRETRO_SUBS[k]
					if System.listDirectory(cand .."/cores") ~= nil then
						if pasada == 3 or LIBRETRO_COMPLETO(cand) == true then
							LIBRETRO_CACHE = cand
							return cand
						end
					end
				end
			end
		end
	end
	LIBRETRO_CACHE = ""
	return nil
end

--- Una instalacion sirve solo si esta COMPLETA. --------------------------------------
--- Tener la carpeta no basta: una copia a medias -- cortada a mitad de un despliegue,
--- o de una version anterior del arbol -- ganaria la eleccion y bloquearia para
--- siempre el despliegue que deberia repararla. Se exige lo minimo indispensable: los
--- cores, y la configuracion.
function LIBRETRO_COMPLETO(base)
	if base == nil then return false end
	if System.listDirectory(base .."/cores") == nil then return false end
	if doesFileExist(base .."/retroarch/retroarch.cfg") == false then return false end
	return true
end

--- Monta la carpeta "retroarch/" que RetroArch exige. --------------------------------
--- El contrato con el usuario es simple: descomprimir una nightly dentro de
--- "LibretroPS2Files/" -- raboot.elf, cores/, info/ -- y que funcione. Todo lo demas
--- lo pone el lanzador aqui.
---
--- Y hace falta ponerlo, porque una nightly NO trae la carpeta "retroarch/", mientras
--- que RetroArch la exige y no admite discusion: "create_path_names()" toma el
--- directorio del core, sube un nivel y busca "retroarch/retroarch.cfg" ahi. Esa ruta
--- esta compilada dentro del binario. Es el unico anclaje rigido de todo el montaje;
--- el resto de carpetas si se pueden mover, porque el lanzador las escribe despues en
--- la configuracion ("libretro_directory", "system_directory"...).
---
--- Aqui no se copia nada: solo se crean las carpetas que faltan. El "retroarch.cfg"
--- no se restaura de ningun molde -- si no esta, lo escribe FORZAR_CONF_RETROARCH con
--- las claves del lanzador, y RetroArch completa el resto con sus propios valores la
--- primera vez que guarda.
function LIBRETRO_REPARAR()
	local base = RUTA_LIBRETRO()
	if base == nil then return false end

	local necesarias = {"/retroarch", "/retroarch/config", "/retroarch/config/remaps",
		"/retroarch/system", "/retroarch/logs", "/retroarch/temp",
		"/retroarch/savefiles", "/retroarch/savestates", "/retroarch/assets",
		"/retroarch/cheats", "/retroarch/playlists", "/retroarch/thumbnails",
		"/retroarch/downloads", "/retroarch/overlays", "/retroarch/database"}
	for i = 1, #necesarias do
		if System.listDirectory(base .. necesarias[i]) == nil then
			System.createDirectory(base .. necesarias[i])
		end
	end

	local cfg = base .."/retroarch/retroarch.cfg"
	if doesFileExist(cfg) == false then
		boot_log("CONF   sin ".. cfg .." : se escribira al lanzar el primer juego")
		boot_escribir()
	end
	return true
end

--- Donde caen NUESTRAS tres carpetas -- Bios, Saves, SaveStates. ----------------------
--- Normalmente junto al lanzador, que es donde el usuario las ve. Pero si el lanzador
--- corre desde el disco interno ATA y el core no lleva ata_bd, ese disco no existe para
--- el: entonces van al mismo sitio que la ROM transbordada, y el puente de partidas las
--- trae de vuelta al arrancar. Devuelve la raiz y, si el core SI lee ATA, el nombre que
--- ese disco tendra del otro lado del SifIopReset.
function RAIZ_DATOS(lee_ata)
	local actual = System.currentDirectory()
	if ES_RAIZ_ATA(actual .."/Saves") == false then return actual, nil end
	if lee_ata == true then return actual, DEV_ATA_PARA_CORE() end
	local destinos = ROM_DESTINOS()
	if #destinos >= 1 then
		CREAR_CADENA(destinos[1], string.sub(ROM_SHUTTLE_SUB, 2))
		return destinos[1] .. ROM_SHUTTLE_SUB, nil
	end
	return actual, nil
end

--- "Bios/" es la UNICA copia de referencia de cada BIOS. ------------------------------
--- Se le da a RetroArch como "system_directory", asi que no hay segunda copia que
--- mantener. Un solo caso la necesita: cuando el core no puede leer el disco donde esta
--- "Bios/", y entonces se deposita en la llave lo poco que RetroArch busca ahi.
BIOS_LIBRETRO_LISTA = {"gba_bios.bin"}

function BIOS_LIBRETRO(lee_ata)
	local raiz = RAIZ_DATOS(lee_ata)
	if raiz == System.currentDirectory() then return end   -- ya la lee donde esta
	local destino = raiz .."/Bios"
	if System.listDirectory(destino) == nil then
		System.createDirectory(destino)
		if System.listDirectory(destino) == nil then return end
	end
	for i = 1, #BIOS_LIBRETRO_LISTA do
		local fichero = BIOS_LIBRETRO_LISTA[i]
		if doesFileExist(destino .."/".. fichero) == false then
			local origen = RUTA_BIOS(fichero, "")
			if doesFileExist(origen) then
				pcall(System.copyFile, origen, destino .."/".. fichero)
				boot_log("BIOS   ".. fichero .." -> ".. destino .." : ".. tostring(doesFileExist(destino .."/".. fichero)))
			else
				boot_log("BIOS   ".. fichero .." AUSENTE en Bios/")
			end
			boot_escribir()
		end
	end
end

--- Se puede arrancar HOY un core de RetroArch? ---------------------------------------
--- Devuelve false y el motivo cuando no. Dos casos: no hay instalacion en ningun sitio,
--- o la hay pero en el disco interno y no hay llave USB donde transbordarla. La tarjeta
--- de memoria no cuenta: 8 MB no dan ni para un core.
function LIBRETRO_POSIBLE()
	-- "Hay instalacion?" se pregunta a la maestra; "podra leerla un core?" tambien,
	-- porque de ella se copia lo que acabe en la llave.
	local base = RUTA_LIBRETRO_MAESTRA()
	if base == nil then return false, "no RetroArch installation found" end
	if ES_RAIZ_ATA(base) == false then return true, base end
	local destinos = ROM_DESTINOS()
	for i = 1, #destinos do
		if string.lower(string.sub(destinos[i], 1, 4)) == "mass" then
			return true, base .." via ".. destinos[i]
		end
	end
	return false, "RetroArch on the internal drive and no USB stick"
end

--- Sin core posible, los doce sistemas libretro no se ofrecen. ------------------------
--- Mas vale una consola ausente que una consola que abre y devuelve "Games or
--- RetroArch not found" en cada juego.
LIBRETRO_SISTEMAS_OFF = false
LIBRETRO_SISTEMAS_MOTIVO = nil

function LIBRETRO_APAGAR_SI_IMPOSIBLE()
	local ok, motivo = LIBRETRO_POSIBLE()
	LIBRETRO_SISTEMAS_OFF = (ok ~= true)
	LIBRETRO_SISTEMAS_MOTIVO = motivo
	if ok == true then
		boot_log("SISTEMAS  libretro disponibles: ".. tostring(motivo))
		boot_escribir()
		return false
	end
	boot_log("SISTEMAS  libretro DESACTIVADOS: ".. tostring(motivo))
	boot_escribir()
	SISTEMAS.MEGADRIVE_ON = 0
	SISTEMAS.MASTERSYSTEM_ON = 0
	SISTEMAS.GAMEGEAR_ON = 0
	SISTEMAS.FAMICOM_ON = 0
	SISTEMAS.GAMEBOY_ON = 0
	SISTEMAS.GAMEBOYCOLOR_ON = 0
	SISTEMAS.GAMEBOYADVANCE_ON = 0
	SISTEMAS.ATARI2600_ON = 0
	SISTEMAS.ATARILYNX_ON = 0
	SISTEMAS.SEGASG1000_ON = 0
	SISTEMAS.NEOGEOPOCKET_ON = 0
	SISTEMAS.SUPERFAMICOM_ON = 0
	return true
end

--- Interruptores de diagnostico. -----------------------------------------------------
--- Pantalla negra al lanzar un juego? Poner uno de estos a false y volver a probar,
--- de uno en uno. No hace falta recompilar nada.
---   RETROARCH_FORZAR_ON     a false: no se toca "retroarch.cfg" en absoluto.
---   RETROARCH_FORZAR_VIDEO  a false: se fuerzan las carpetas, pero NO el modo de
---                           video. Un "current_resolution_id" que el televisor no
---                           acepta da exactamente una pantalla negra.
RETROARCH_FORZAR_ON = true
--- A false, y por una razon concreta. El bloque PAL escribe current_resolution_id=1,
--- video_refresh_rate=54.5 y vrr_runloop_enable=true. Esos valores vienen de las
--- configuraciones de Boon Tobias y NUNCA se han comprobado en hardware. Lo que si se
--- ha comprobado, en esta misma consola PAL y con un juego funcionando, es lo
--- contrario: current_resolution_id=0 y 59.940063, con "[PS2_GFX] New vmode: 0,
--- 704x576" en el log de RetroArch. Forzar un modo de video que la consola no produce
--- es una de las dos formas conocidas de acabar en pantalla negra.
--- A true vuelven a imponerse, si algun dia se comprueban.
RETROARCH_FORZAR_VIDEO = false

--- Ajustes que el lanzador impone a RetroArch antes de cada juego. --------------------
--- RetroArch guarda su configuracion al salir y el usuario puede tocarla desde el
--- menu: lo que hay aqui se reescribe en cada arranque. Para anadir un ajuste, basta
--- con meterlo en la tabla.
RETROARCH_FORZADO = {
	-- Las partidas viven FUERA del arbol de RetroArch, en "Saves/" y "SaveStates/".
	-- "in_content_dir" las pondria junto a la ROM; "sort_..._enable" las agruparia por
	-- core, y entonces PicoDrive mezclaria cuatro consolas Sega en una sola carpeta.
	-- Por carpeta de contenido sale "Saves/<consola>/", el mismo nombre que en "Roms/".
	{"savefiles_in_content_dir",          "false"},
	{"savestates_in_content_dir",         "false"},
	{"sort_savefiles_enable",             "false"},
	{"sort_savestates_enable",            "false"},
	{"sort_savefiles_by_content_enable",  "true"},
	{"sort_savestates_by_content_enable", "true"},

	-- 21 = "Square pixel": un pixel de la consola es un pixel de pantalla. Lo que
	-- venia por defecto era 22, "Core provided", que en PS2 deja la imagen estirada.
	-- Si lo que se queria era el "1:1" literal del menu de RetroArch, ese es el 5.
	-- Los overrides por core siguen mandando sobre esto, que es lo correcto: una
	-- Game Boy es 10:9 pase lo que pase.
	{"aspect_ratio_index", "21"},
}

--- Lo unico que separa una configuracion NTSC de una PAL. -----------------------------
--- Boot Tobias mantenia para esto veinticuatro "retroarch.cfg" completos, doce por modo
--- de video. La diferencia real son estas seis claves.
--- Aqui NO estan "aspect_ratio_index" ni "video_scale_integer", que si estaban antes.
--- No son propiedades del modo de video sino gustos del usuario: una Game Boy es 10:9
--- en NTSC como en PAL. Forzarlos deshacia en cada arranque lo que se hubiera elegido
--- en el menu de RetroArch. Su valor vive en retroarch/retroarch.cfg, que es el unico,
--- cada core lo afina con su override.
--- Hay una clave que tambien cambiaba, "video_vsync", pero no de forma uniforme: en PAL
--- valia "false" solo para Neo Geo Pocket, Game Boy, Game Boy Color y Super Famicom.
--- Eso es por sistema Y por modo a la vez, que no cabe en esta tabla.
RETROARCH_VIDEO = {
	NTSC = {
		{"video_refresh_rate",     "59.940063"},
		{"crt_video_refresh_rate", "59.940063"},
		{"current_resolution_id",  "0"},
		{"vrr_runloop_enable",     "false"},
	},
	PAL = {
		{"video_refresh_rate",     "54.500000"},
		{"crt_video_refresh_rate", "54.500000"},
		{"current_resolution_id",  "1"},
		{"vrr_runloop_enable",     "true"},
	},
}

--- Escribe todo lo anterior en el "retroarch.cfg" de RetroArch. -----------------------
function FORZAR_CONF_RETROARCH(pal, lee_ata)
	if RETROARCH_FORZAR_ON ~= true then
		boot_log("CONF   desactivado (RETROARCH_FORZAR_ON = false)")
		boot_escribir()
		return false
	end
	local base = RUTA_LIBRETRO()
	if base == nil then
		boot_log("CONF   carpeta de RetroArch no encontrada, sin ajustes que forzar")
		boot_escribir()
		return false
	end
	-- No hay copia de fabrica de la que sacarlo: si falta, se crea vacio y las claves
	-- de abajo lo llenan. RetroArch anade despues las suyas al guardar.
	local cfg = base .."/retroarch/retroarch.cfg"
	if doesFileExist(cfg) == false then
		if System.listDirectory(base .."/retroarch") == nil then
			System.createDirectory(base .."/retroarch")
		end
		pcall(function()
			local f = System.openFile(cfg, FCREATE)
			System.writeFile(f, "\n", 1)
			System.closeFile(f)
		end)
		boot_log("CONF   ".. cfg .." no existia, creado")
		if doesFileExist(cfg) == false then
			boot_log("CONF   imposible crearlo: soporte de solo lectura?")
			boot_escribir()
			return false
		end
	end

	-- Las partidas tienen que caer en un soporte que el core PUEDA leer. Si el
	-- lanzador corre desde el disco interno ATA y el core no lleva ata_bd, ese disco
	-- no existe para el: se usa entonces el mismo destino que el transbordo de ROMs.
	local raiz_saves, dev_saves = RAIZ_DATOS(lee_ata)
	if dev_saves ~= nil then
		boot_log("CONF   lanzador en disco ATA, core compatible: datos en ".. dev_saves)
	elseif raiz_saves ~= System.currentDirectory() then
		boot_log("CONF   lanzador en disco ATA, core sin ata_bd: datos en ".. raiz_saves)
	end

	-- Enceladus ve "mass0:"; RetroArch reinicia el IOP y llama al mismo USB "mass:".
	-- Pero "mc0:" se llama igual en los dos lados, y "mc:" no existe: por eso la
	-- traduccion solo toca "massN:".
	local function para_core(ruta)
		if ruta == nil then return nil end
		if dev_saves ~= nil and ES_RAIZ_ATA(ruta) then
			local pos = string.find(ruta, ":", 1, true)
			if pos ~= nil then return dev_saves .. string.sub(ruta, pos+1) end
		end
		return DEV_PARA_CORE(ruta)
	end

	-- Las tres carpetas que son NUESTRAS, no de RetroArch: van junto al lanzador y no
	-- dentro de su arbol. "Bios/" es la unica copia de referencia de los BIOS, asi que
	-- se le da como "system_directory" en vez de mantener una segunda copia.
	local quiero = {}
	local dirs = {{"savefile_directory",  raiz_saves .."/Saves"},
	              {"savestate_directory", raiz_saves .."/SaveStates"},
	              {"system_directory",    raiz_saves .."/Bios"}}
	for i = 1, #dirs do
		if System.listDirectory(dirs[i][2]) == nil then
			System.createDirectory(dirs[i][2])
		end
		quiero[dirs[i][1]] = para_core(dirs[i][2])
	end

	-- Las CARPETAS PROPIAS de RetroArch, escritas explicitamente. ----------------------
	-- Sin estas claves RetroArch las deduce de su propio directorio, y ahi esta la
	-- trampa: arrancado desde el disco interno ese directorio puede ser un nombre que
	-- existe pero cuya raiz no se lista, y entonces assets, config, system y savefiles
	-- apuntan todos a un sitio vacio. Se recalculan en cada arranque a partir de donde
	-- esta REALMENTE la carpeta, asi que mover el lanzador las corrige solo.
	local base_ra = para_core(base)
	if base_ra ~= nil then
		local carpetas = {
			{"libretro_directory",        "/cores"},
			{"libretro_info_path",        "/info"},
			{"rgui_config_directory",     "/retroarch/config"},
			{"input_remapping_directory", "/retroarch/config/remaps"},
			{"cheat_database_path",       "/retroarch/cheats"},
			{"content_database_path",     "/retroarch/database/rdb"},
			{"assets_directory",          "/retroarch/assets"},
			{"core_assets_directory",     "/retroarch/downloads"},
			{"playlist_directory",        "/retroarch/playlists"},
			{"thumbnails_directory",      "/retroarch/thumbnails"},
			{"cache_directory",           "/retroarch/temp"},
			{"log_dir",                   "/retroarch/logs"},
			{"overlay_directory",         "/retroarch/overlays"},
			-- Estas cinco no son carpetas sino ficheros, y RetroArch las guarda por
			-- separado: cambiar "playlist_directory" no las arrastra. Sin ponerlas
			-- aqui se quedan apuntando a donde estuviera la instalacion anterior.
			{"content_favorites_path",      "/retroarch/playlists/builtin/content_favorites.lpl"},
			{"content_history_path",        "/retroarch/playlists/builtin/content_history.lpl"},
			{"content_image_history_path",  "/retroarch/playlists/builtin/content_image_history.lpl"},
			{"content_music_history_path",  "/retroarch/playlists/builtin/content_music_history.lpl"},
			{"content_video_history_path",  "/retroarch/playlists/builtin/content_video_history.lpl"},
		}
		for i = 1, #carpetas do
			quiero[carpetas[i][1]] = base_ra .. carpetas[i][2]
		end
		boot_log("CONF   carpetas de RetroArch fijadas en ".. base_ra)
	end

	for i = 1, #RETROARCH_FORZADO do
		quiero[RETROARCH_FORZADO[i][1]] = RETROARCH_FORZADO[i][2]
	end
	local modo = "NTSC"
	if pal == true then modo = "PAL" end
	if RETROARCH_FORZAR_VIDEO == true then
		local vid = RETROARCH_VIDEO[modo]
		for i = 1, #vid do quiero[vid[i][1]] = vid[i][2] end
	else
		modo = modo .." (video NO forzado)"
	end

	local txt = nil
	pcall(function()
		local f = System.openFile(cfg, FREAD)
		local tam = System.sizeFile(f)
		System.seekFile(f, 0, SET)
		txt = System.readFile(f, tam)
		System.closeFile(f)
	end)
	if txt == nil then
		boot_log("CONF   ilegible: ".. cfg)
		boot_escribir()
		return false
	end

	-- El fichero ya termina en salto de linea. Sin quitarlo, el "txt..salto" de abajo
	-- anadiria una linea vacia en cada arranque.
	if string.sub(txt, -1) == "\n" then txt = string.sub(txt, 1, -2) end

	-- Una sola pasada por lineas: mas barato que un gsub por clave sobre 44 KB.
	local salida, vistas, cambios = {}, {}, 0
	for cruda in string.gmatch(txt .."\n", "([^\n]*)\n") do
		-- La variable de control de un "for" es constante desde Lua 5.4: hay que
		-- copiarla antes de tocarla. Y el fichero puede venir con finales CRLF.
		local linea = cruda
		if string.sub(linea, -1) == "\r" then linea = string.sub(linea, 1, -2) end
		local clave = string.match(linea, "^([%w_]+) = ")
		if clave ~= nil and quiero[clave] ~= nil then
			vistas[clave] = true
			local nueva = clave .. ' = "'.. quiero[clave] ..'"'
			if linea ~= nueva then cambios = cambios + 1 end
			salida[#salida + 1] = nueva
		else
			salida[#salida + 1] = linea
		end
	end
	for clave, valor in pairs(quiero) do
		if vistas[clave] ~= true then
			salida[#salida + 1] = clave .. ' = "'.. valor ..'"'
			cambios = cambios + 1
		end
	end

	if cambios == 0 then
		boot_log("CONF   ".. modo .." ya correcto  ".. tostring(quiero["savefile_directory"]))
		boot_escribir()
		return true
	end

	local nuevo = table.concat(salida, "\n") .."\n"
	local ok = false
	pcall(function()
		local f = System.openFile(cfg, FCREATE)
		System.writeFile(f, nuevo, string.len(nuevo))
		System.closeFile(f)
		ok = true
	end)
	boot_log("CONF   ".. modo .."  ".. tostring(cambios) .." clave(s) forzada(s), escrito=".. tostring(ok))
	boot_log("       ".. tostring(quiero["savefile_directory"]) .." , ".. tostring(quiero["savestate_directory"]))
	-- Esto sale justo antes de loadELF, que no vuelve nunca: si no se vuelca ahora,
	-- el diagnostico se pierde con el proceso.
	boot_escribir()
	return ok
end

--- La instalacion MAESTRA: la que tiene TODOS los cores. ------------------------------
--- Hay dos instalaciones y confundirlas era el error de fondo:
---
---   la maestra   junto al lanzador, con los 60 cores de la nightly. Dice QUE se
---                puede jugar. No hace falta que un core sepa leerla.
---   la de la llave  "<llave>/RETROLauncher/LibretroPS2Files", con EL core del juego
---                nada mas. Dice con que se ejecuta.
---
--- RUTA_LIBRETRO devuelve la segunda en cuanto existe, porque es la unica que un core
--- podra leer tras el SifIopReset. Preguntarle "tienes handy?" da que no, y el juego
--- se rechazaba antes de intentar nada -- que es el "Games or RetroArch not found" de
--- Lynx, GBA, GB, GBC y NES con los sesenta cores presentes en el disco.
function RUTA_LIBRETRO_MAESTRA()
	local propia = System.currentDirectory() .."/LibretroPS2Files"
	if System.listDirectory(propia .."/cores") ~= nil then return propia end
	if RAICES ~= nil then
		for i = 1, #RAICES do
			for k = 1, #LIBRETRO_SUBS do
				local cand = RAICES[i] .. LIBRETRO_SUBS[k]
				if System.listDirectory(cand .."/cores") ~= nil then return cand end
			end
		end
	end
	return RUTA_LIBRETRO()
end

--- Resuelve un core en la instalacion maestra. ---------------------------------------
function RUTA_CORE_MAESTRO(nombre_core, ruta_original)
	if nombre_core == nil or nombre_core == " " then return ruta_original end
	local base = RUTA_LIBRETRO_MAESTRA()
	if base ~= nil then
		local cand = base .."/cores/".. nombre_core
		if doesFileExist(cand) then return cand end
	end
	return ruta_original
end

function RUTA_CORE(nombre_core, ruta_original)
	if nombre_core == nil or nombre_core == " " then return ruta_original end
	-- Una sola instalacion, la que RUTA_LIBRETRO haya elegido: la que el core podra
	-- leer despues de reiniciar el IOP.
	local base = RUTA_LIBRETRO()
	if base ~= nil then
		local cand = base .."/cores/".. nombre_core
		if doesFileExist(cand) then return cand end
	end
	return ruta_original
end

--- Nombres de carpeta de este fork, bajo "Roms/". -----------------------------------
--- Rastreo de aplicaciones en la RAIZ de cada unidad. ---------------------------------
--- La lista de APPS se buscaba, ademas de en "APPS/" y "Roms/APPS", en la raiz misma
--- del disco, de la tarjeta mc0: y de mc1:, entrando UN NIVEL en cada carpeta que
--- encontrara alli. En un disco que ademas sirve para OPL eso significa listar "ART",
--- "THM", "CHT", "$RECYCLE.BIN" y "System Volume Information", que llevan miles de
--- ficheros cada una: el arranque se paraba ahi, en el sistema 13.
--- A false se buscan las aplicaciones solo donde tienen que estar: "APPS/" en cada
--- unidad, "mc0:/APPS", "mc1:/APPS" y "Roms/APPS". A true vuelve el rastreo completo.
APPS_RAIZ_ON = false

ROMS_DIR = {
	"megadrive", "mastersystem", "gamegear", "nes", "gb", "gbc", "gba",
	"atari2600", "lynx", "sg1000", "ngp", "snes",
	"APPS-Media", "psx-ember(bin and cue)", "ps2-isos",
}

--- Ficheros de sistema, agrupados en "Bios/" en la raiz del launcher. ---------------
--- Se conservan las ubicaciones historicas como respaldo.
function RUTA_BIOS(fichero, respaldo)
	local actual = System.currentDirectory()
	local cand = actual .."/Bios/".. fichero
	if doesFileExist(cand) then return cand end
	if respaldo ~= nil and doesFileExist(respaldo) then return respaldo end
	return cand
end

--- Nombre de fichero de una ruta. ---------------------------------------------------
function nombre_fichero(ruta)
	if ruta == nil then return "" end
	local i = string.len(ruta)
	while i > 0 and string.sub(ruta, i, i) ~= "/" do i = i - 1 end
	return string.sub(ruta, i+1)
end

--- Extensiones reales de cada sistema, para cruzarlas con las que declara cada core.
--- Faltan "zip" y "bin" a proposito: no distinguen nada. Ocho de los cores instalados
--- declaran "bin" (stella2014, gpsp, o2em, gearcoleco, freeintv, smsplus...), asi que
--- incluirlo daria por bueno casi cualquier core para casi cualquier sistema.
SISTEMA_EXTEN = {
	{"gen", "smd", "md"}, {"sms"}, {"gg"}, {"nes", "fds", "unf"},
	{"gb"}, {"gbc"}, {"gba"}, {"a26"}, {"lnx", "lyx"}, {"sg"},
	{"ngc", "ngp", "npc"}, {"sfc", "smc"},
}

--- Extensiones declaradas por un core, leidas de su ".info". ------------------------
--- "picodrive_libretro_ps2.elf" -> "info/picodrive_libretro.info".
function CORE_EXTENSIONES(ruta_core)
	local n = nombre_fichero(ruta_core)
	if string.len(n) < 9 or string.sub(n, -8) ~= "_ps2.elf" then return nil end
	local info = string.sub(n, 1, -9) ..".info"

	-- En la MAESTRA primero. La instalacion de la llave lleva un solo ".info", el del
	-- core del juego en curso: buscando ahi, todos los demas cores quedaban sin
	-- extensiones declaradas, CORE_SIRVE los daba por inutiles, y la lista de cores de
	-- cada sistema se quedaba vacia. Los sesenta cores del disco eran invisibles.
	local sitios = {}
	local maestra = RUTA_LIBRETRO_MAESTRA()
	if maestra ~= nil then table.insert(sitios, maestra) end
	if RAICES ~= nil then
		for i = 1, #RAICES do
			for k = 1, #LIBRETRO_SUBS do
				table.insert(sitios, RAICES[i] .. LIBRETRO_SUBS[k])
			end
		end
	end
	local base_ra = RUTA_LIBRETRO()
	if base_ra ~= nil then table.insert(sitios, base_ra) end

	for i = 1, #sitios do
		local p = sitios[i] .."/info/".. info
		if doesFileExist(p) then
			local txt = nil
			pcall(function()
				local f = System.openFile(p, FREAD)
				local tam = System.sizeFile(f)
				System.seekFile(f, 0, SET)
				txt = System.readFile(f, tam)
				System.closeFile(f)
			end)
			if txt ~= nil then
				return string.match(txt, "supported_extensions%s*=%s*\"([^\"]*)\"")
			end
		end
	end
	return nil
end

--- Un core sirve para un sistema si declara alguna de sus extensiones. --------------
function CORE_SIRVE(ruta_core, identidad)
	local exts = SISTEMA_EXTEN[identidad]
	if exts == nil then return true end
	local sup = CORE_EXTENSIONES(ruta_core)
	if sup == nil then return false end
	sup = "|".. string.lower(sup) .."|"
	for i = 1, #exts do
		if string.find(sup, "|".. exts[i] .."|", 1, true) ~= nil then return true end
	end
	return false
end

--- Despliegue de Ember junto a los juegos. -------------------------------------------
--- Ember resuelve el .cue RELATIVO a su propio directorio: el original le pasaba solo
--- el nombre del fichero y lo lanzaba desde la carpeta de los juegos. Al mover el
--- emulador a "Bios/" se rompio ese contrato, y Ember arrancaba en la pantalla del
--- BIOS por no encontrar el disco. Se restaura el montaje de origen: "ember.elf" y
--- "bios.bin" se colocan junto a los .cue, copiados desde "Bios/" la primera vez.
--- Son dos ficheros pequenos y una sola vez por carpeta.
--- Devuelve la ruta del ELF listo para lanzar, o nil.
function EMBER_EN(carpeta)
	if carpeta == nil then return nil end
	local elf = carpeta .."/ember.elf"
	local bios = carpeta .."/bios.bin"
	if doesFileExist(elf) == false then
		local origen = RUTA_BIOS("psx-ember.elf", "")
		if doesFileExist(origen) == false then return nil end
		pcall(System.copyFile, origen, elf)
	end
	if doesFileExist(bios) == false then
		local origen = RUTA_BIOS("bios.bin", "")
		if doesFileExist(origen) then pcall(System.copyFile, origen, bios) end
	end
	if doesFileExist(elf) then return elf end
	return nil
end

--- Retardo de acceso al USB de POPStarter. -------------------------------------------
--- POPStarter da por perdido el dispositivo si tarda en responder, y entonces escribe
--- "Opening mass:/POPS/... FAILED / No POPS directory ? / Increase the USB access
--- delay". El valor vive en un solo byte de su tabla de configuracion, offset 0x413,
--- y hay que parchearlo en CADA "XX.<juego>.ELF": cada atajo es un POPStarter
--- completo. De fabrica vale 3, poco para muchas llaves. 0 = no tocar nada.
--- Con los drivers modernos en la Memory Card la llave monta rapido: 20 basta y no
--- alarga el arranque. Subir hacia 60 solo si volviera el fallo de montaje.
POPS_USB_DELAY = 20

--- Lee el byte del retardo, para poder ESCRIBIRLO EN EL JOURNAL: sin esto no hay
--- forma de saber si el parche se aplico de verdad. nil = fichero ilegible.
function LEE_USB_DELAY(ruta)
	local valor = nil
	pcall(function()
		local f = System.openFile(ruta, FREAD)
		System.seekFile(f, 0x413, SET)
		local b = System.readFile(f, 1)
		System.closeFile(f)
		if b ~= nil and string.len(b) >= 1 then valor = string.byte(b, 1) end
	end)
	return valor
end

function PARCHE_USB_DELAY(ruta)
	if POPS_USB_DELAY == nil or POPS_USB_DELAY <= 0 then return end
	if ruta == nil or doesFileExist(ruta) == false then return end
	pcall(function()
		local f = System.openFile(ruta, FRDWR)
		-- Comprobacion de firma: los bytes que rodean al retardo. El primero varia
		-- entre builds (0x00 en la Rev 13 principal, 0xFF en las "USBDELAY" de la
		-- comunidad); el resto del marco es estable.
		System.seekFile(f, 0x410, SET)
		local marco = System.readFile(f, 8)
		local b1 = (marco ~= nil and string.len(marco) >= 8) and string.byte(marco, 1) or -1
		if marco == nil or string.len(marco) < 8
		   or (b1 ~= 0 and b1 ~= 0xFF)
		   or string.byte(marco, 2) ~= 0 or string.byte(marco, 3) ~= 0
		   or string.byte(marco, 5) ~= 0x40 or string.byte(marco, 8) ~= 1 then
			System.closeFile(f)
			return
		end
		System.seekFile(f, 0x413, SET)
		System.writeFile(f, string.char(POPS_USB_DELAY), 1)
		System.closeFile(f)
	end)
end

--- Drivers USB de recambio de POPStarter, en la Memory Card. -------------------------
--- Hallazgo comprobado en esta consola: POPStarter solo monta ciertas llaves si
--- encuentra "mc0:/POPSTARTER/usbd.irx" y "usbhdfsd.irx" (BDMAssault) - y los nombres
--- van en MINUSCULAS, con mayusculas no los ve y cae en sus drivers internos de 2019,
--- que fallan con "Opening mass:/POPS/... FAILED".
--- Esta funcion REPARA la instalacion antes de cada lanzamiento: crea el directorio,
--- copia los ficheros que falten (desde SYS-CONF de la propia tarjeta, o desde un
--- POPSTARTER/ en cualquier raiz) y corrige el nombre si la caja no es la esperada.
--- Devuelve un texto multilinea para el journal de lanzamiento.
function POPSTARTER_DRIVERS_MC()
	local dir = "mc0:/POPSTARTER"
	local lineas = {"Drivers de recambio en ".. dir .." (minusculas obligatorias):"}

	local function listar()
		local reales = {}
		local c = System.listDirectory(dir)
		if c ~= nil then
			for i = 1, #c do
				if c[i].directory == false then
					reales[string.lower(c[i].name)] = c[i].name
				end
			end
		end
		return reales, (c ~= nil)
	end

	local reales, existe = listar()
	if existe == false then
		pcall(System.createDirectory, dir)
		reales, existe = listar()
		table.insert(lineas, "  directorio creado: ".. tostring(existe))
	end

	for _i, nombre in ipairs({"usbd.irx", "usbhdfsd.irx"}) do
		local real = reales[nombre]
		if real == nombre then
			table.insert(lineas, "  ".. nombre .." : ok")
		elseif real ~= nil then
			-- Mala caja. Renombrar directamente puede fallar en mcman cuando solo
			-- cambia la caja, asi que se pasa por un nombre intermedio.
			pcall(System.copyFile, dir .."/".. real, dir .."/fix.tmp")
			pcall(System.removeFile, dir .."/".. real)
			if System.rename ~= nil then
				pcall(System.rename, dir .."/fix.tmp", dir .."/".. nombre)
			end
			if listar()[nombre] ~= nombre then
				pcall(System.copyFile, dir .."/fix.tmp", dir .."/".. nombre)
				pcall(System.removeFile, dir .."/fix.tmp")
			end
			local ahora = listar()[nombre]
			table.insert(lineas, "  ".. nombre .." : renombrado desde '".. real .."' -> ".. tostring(ahora == nombre))
		else
			-- Ausente: copiar desde la primera fuente que exista.
			local fuentes = {"mc0:/SYS-CONF/".. string.upper(nombre),
				"mc0:/SYS-CONF/".. nombre}
			local pos = string.find(System.currentDirectory(), ":", 1, true)
			if pos ~= nil then
				local raiz = string.sub(System.currentDirectory(), 1, pos)
				table.insert(fuentes, raiz .."/POPSTARTER/".. string.upper(nombre))
				table.insert(fuentes, raiz .."/POPSTARTER/".. nombre)
			end
			if RAICES ~= nil then
				for r = 1, #RAICES do
					-- Los dos IRX se reparten con el lanzador, en la carpeta "IRX/" de la
					-- raiz. Se conserva la ruta historica detras, por si alguien los tiene
					-- ya colocados a la vieja usanza.
					table.insert(fuentes, RAICES[r] .."/IRX/".. nombre)
					table.insert(fuentes, RAICES[r] .."/Bios/POPSTARTER/".. nombre)
				end
			end
			local hecho = false
			for f = 1, #fuentes do
				if hecho == false and doesFileExist(fuentes[f]) then
					pcall(System.copyFile, fuentes[f], dir .."/".. nombre)
					hecho = (listar()[nombre] == nombre)
					if hecho then
						table.insert(lineas, "  ".. nombre .." : copiado desde ".. fuentes[f])
					end
				end
			end
			if hecho == false then
				table.insert(lineas, "  ".. nombre .." : AUSENTE y sin fuente para copiarlo.")
				table.insert(lineas, "    Sin el, POPStarter usa sus drivers de 2019 y")
				table.insert(lineas, "    puede no montar la llave USB.")
			end
		end
	end
	return table.concat(lineas, "\n")
end

--- Transbordo de ROM para los cores de RetroArch. ------------------------------------
--- Los cores montan SU PROPIA pila de dispositivos al arrancar, y ahi no hay ata_bd:
--- "platform_ps2.c" solo inicializa memcard, usb, mx4sio, cdfs y el HDD nativo (APA).
--- Conclusion: una ROM que vive en el disco interno exFAT les es SIMPLEMENTE INVISIBLE.
--- No es un fallo del launcher ni de las rutas, es el alcance del port de RetroArch.
--- Solucion: copiar la ROM a un soporte que ellos si lean, por orden de preferencia
--- USB (rapido) y luego Memory Card (lenta y pequena, pero suficiente para 8/16 bits).
--- La copia se cachea: relanzar el mismo juego no vuelve a copiar.
--- Poner a false para desactivar el transbordo.
ROM_SHUTTLE_ON = true
--- Carpeta de paso en el soporte de transbordo. Misma forma que en el disco:
---   <soporte>/RETROLauncher/Roms/<consola>/<rom>
---   <soporte>/RETROLauncher/Saves/<consola>/<juego>.srm
---   <soporte>/RETROLauncher/SaveStates/<consola>/<juego>.state
---   <soporte>/RETROLauncher/Bios/
---   <soporte>/RETROLauncher/LibretroPS2Files/
---
--- O sea: EXACTAMENTE la misma estructura que en el disco interno. Hubo aqui una
--- carpeta "TempUSB/" en medio, y era un parche a un problema que ya no existe --
--- RUTA_LIBRETRO elegia la copia de trabajo como instalacion maestra, y esconderla
--- bajo otro nombre lo evitaba. Ahora la maestra se reconoce por estar junto al
--- lanzador (RUTA_LIBRETRO_MAESTRA), asi que la copia puede volver a su sitio y las
--- dos mitades del montaje se leen igual.
-- Del nombre REAL de la carpeta del lanzador, no del literal "RETROLauncher": si
-- alguien la renombra, el transbordo y la instalacion que se copia a su lado tienen
-- que seguir cayendo en el mismo sitio. CARPETA_LANZADOR se calcula al arrancar.
ROM_SHUTTLE_SUB = "/".. CARPETA_LANZADOR

function ROM_TAMANO(ruta)
	local tam = nil
	pcall(function()
		local f = System.openFile(ruta, FREAD)
		tam = System.sizeFile(f)
		System.closeFile(f)
	end)
	return tam
end

--- Soportes legibles por los cores, del mas rapido al mas lento. ---------------------
function ROM_DESTINOS()
	local out = {}
	local propio = ""
	local pos = string.find(System.currentDirectory(), ":", 1, true)
	if pos ~= nil then propio = string.sub(System.currentDirectory(), 1, pos) end
	-- El soporte de arranque, si no es el disco ATA (o sea: si es un USB).
	if propio ~= "" and BDM_ATA[propio] ~= true then table.insert(out, propio) end
	if BDM_DEVICES ~= nil then
		for i = 1, #BDM_DEVICES do
			if BDM_ATA[BDM_DEVICES[i]] ~= true and BDM_DEVICES[i] ~= propio then
				table.insert(out, BDM_DEVICES[i])
			end
		end
	end
	table.insert(out, "mc0:")
	table.insert(out, "mc1:")
	return out
end

--- Copia la ROM a un soporte legible. Devuelve (ruta_nueva, descripcion).
--- La Memory Card tiene 8 MB: una ROM de GBA no cabra, y hay que decirlo claro.
--- El numero de orden en la lista, guardado aparte. -----------------------------------
--- "System/Config/System.cfg" es una linea de cuarenta y nueve numeros releidos por
--- posicion, y una de las casillas guarda una RUTA. El lector extrae numeros con
--- "%d+": si esa ruta trae un digito de mas o de menos, TODO lo que viene detras se
--- lee corrido. Un interruptor de si/no no tiene por que depender de eso, asi que
--- vive en su propio fichero de un caracter.
function SEE_INDEX_FICHERO()
	return System.currentDirectory() .."/System/Config/SeeIndex.cfg"
end

function SEE_INDEX_LEER()
	local f = SEE_INDEX_FICHERO()
	if doesFileExist(f) == false then return nil end
	local v = nil
	pcall(function()
		local h = System.openFile(f, FREAD)
		System.seekFile(h, 0, SET)
		local t = System.readFile(h, System.sizeFile(h))
		System.closeFile(h)
		if t ~= nil and string.find(t, "1", 1, true) ~= nil then v = 1 else v = 0 end
	end)
	return v
end

function SEE_INDEX_GUARDAR(valor)
	pcall(function()
		local t = tostring(valor)
		local h = System.openFile(SEE_INDEX_FICHERO(), FCREATE)
		System.writeFile(h, t, string.len(t))
		System.closeFile(h)
	end)
end

--- Que ROMs estan YA en la llave. -----------------------------------------------------
--- Para pintarlas en verde en la lista: verde = no hay nada que copiar, arranca ya.
--- Una sola llamada a listDirectory por sistema, y solo cuando se cambia de sistema.
--- La carpeta guarda una ROM cada vez, asi que el indice es de un elemento.
CACHE_USB_IDX = nil
CACHE_USB_ID = nil

function CACHE_USB_REFRESCAR(identidad)
	CACHE_USB_ID = identidad
	CACHE_USB_IDX = {}
	-- Sin puente no hay copia que evitar: nada esta "en cache", todo arranca igual.
	if PUENTE_HACE_FALTA() == false then return end
	local consola = ROMS_DIR[identidad]
	if consola == nil then return end
	local destinos = ROM_DESTINOS()
	for i = 1, #destinos do
		local c = System.listDirectory(destinos[i] .. ROM_SHUTTLE_SUB .."/Roms/".. consola)
		if c ~= nil then
			for j = 1, #c do
				if c[j].directory == false then CACHE_USB_IDX[c[j].name] = true end
			end
		end
	end
end

--- Que cores estan YA en la llave. Mismo principio que EN_CACHE_USB, y un solo
--- listado: la carpeta lleva a lo sumo un punado de cores.
CORES_LLAVE_IDX = nil

function CORE_EN_LLAVE(nombre_core)
	if nombre_core == nil then return false end
	if CORES_LLAVE_IDX == nil then
		CORES_LLAVE_IDX = {}
		local destinos = ROM_DESTINOS()
		for i = 1, #destinos do
			if string.lower(string.sub(destinos[i], 1, 4)) == "mass" then
				local dir = destinos[i] .."/".. CARPETA_LANZADOR .."/LibretroPS2Files/cores"
				local c = System.listDirectory(dir)
				if c ~= nil then
					for j = 1, #c do
						if c[j].directory == false then CORES_LLAVE_IDX[c[j].name] = true end
					end
				end
			end
		end
	end
	return CORES_LLAVE_IDX[nombre_core] == true
end

function EN_CACHE_USB(identidad, nombre)
	if nombre == nil or identidad == nil or identidad > 12 then return false end
	if CACHE_USB_ID ~= identidad then CACHE_USB_REFRESCAR(identidad) end
	if CACHE_USB_IDX == nil then return false end
	-- El rastreo anade un espacio al final para las extensiones de tres letras.
	local limpio = nombre
	while string.sub(limpio, -1) == " " do limpio = string.sub(limpio, 1, -2) end
	return CACHE_USB_IDX[limpio] == true
end

--- Copia por trozos, con progreso. ----------------------------------------------------
--- "System.copyFile" no dice nada mientras trabaja, y en USB 1.1 -- 1 MB/s en el mejor
--- de los casos -- una ROM de Game Boy Advance son quince segundos de pantalla quieta,
--- indistinguibles de un cuelgue. Aqui se copia a trozos y se avisa entre trozo y
--- trozo. El trozo es grande a proposito: en USB 1.1 lo que cuesta es la latencia por
--- transferencia, no los bytes.
COPIA_TROZO = 262144

function COPIAR_CON_PROGRESO(origen, destino, etiqueta)
	local tam = ROM_TAMANO(origen)
	if tam == nil then return false end
	-- Por debajo de un trozo no hay nada que mostrar: copia directa.
	if tam <= COPIA_TROZO then
		local ok = pcall(System.copyFile, origen, destino)
		return ok == true and doesFileExist(destino)
	end
	local hechos = 0
	pcall(function()
		local fo = System.openFile(origen, FREAD)
		local fd = System.openFile(destino, FCREATE)
		System.seekFile(fo, 0, SET)
		while hechos < tam do
			local n = COPIA_TROZO
			if tam - hechos < n then n = tam - hechos end
			local datos = System.readFile(fo, n)
			if datos == nil then break end
			local largo = string.len(datos)
			if largo <= 0 then break end
			System.writeFile(fd, datos, largo)
			hechos = hechos + largo
			if COPIA_PROGRESO ~= nil then
				pcall(COPIA_PROGRESO, etiqueta, hechos, tam)
			end
		end
		System.closeFile(fd)
		System.closeFile(fo)
	end)
	return hechos >= tam
end

function ROM_TRANSBORDO(ruta_rom, nombre)
	if ROM_SHUTTLE_ON ~= true then return nil, "transbordo desactivado" end
	local tam = ROM_TAMANO(ruta_rom)
	if tam == nil then return nil, "ROM ilegible en el origen" end
	-- Nombre de la carpeta que contiene la ROM: "Roms/megadrive/juego.gen" -> "megadrive".
	-- La copia lo conserva porque RetroArch agrupa las partidas por ese nombre
	-- ("sort_savefiles_by_content_enable"). Sin esto, un juego transbordado guardaria
	-- en "Saves/RETROLauncher-TMP" en vez de "Saves/megadrive", y sus partidas
	-- quedarian separadas de las del mismo juego lanzado desde un USB.
	local consola = CARPETA_DE_RUTA(ruta_rom)

	local destinos = ROM_DESTINOS()
	for i = 1, #destinos do
		-- Bajo "Roms/", igual que en el disco. Estaban sueltas en la raiz de la
		-- carpeta de paso, mezcladas con Saves y SaveStates.
		local raiz_tmp = destinos[i] .. ROM_SHUTTLE_SUB .."/Roms"
		local sufijo = string.sub(ROM_SHUTTLE_SUB, 2) .."/Roms"
		if consola ~= nil then sufijo = sufijo .."/".. consola end
		pcall(CREAR_CADENA, destinos[i], sufijo)
		local dir = raiz_tmp
		if consola ~= nil then dir = raiz_tmp .."/".. consola end
		local contenido = System.listDirectory(dir)
		if contenido ~= nil then
			local dest = dir .."/".. nombre
			-- Cache: si ya esta ahi con el tamano correcto, no se recopia.
			if doesFileExist(dest) and ROM_TAMANO(dest) == tam then
				return dest, destinos[i] .." (ya en cache)"
			end
			-- Solo se guarda UNA ROM: se limpia lo anterior para no llenar el soporte.
			-- Hay que barrer TODAS las carpetas de consola, no solo la actual, o al
			-- cambiar de sistema se acumularian las ROMs anteriores. Ahora "raiz_tmp"
			-- es "Roms/", asi que aqui dentro solo hay ROMs: no hay nada que excluir.
			local previo = System.listDirectory(raiz_tmp)
			if previo ~= nil then
				for c = 1, #previo do
					local nom = previo[c].name
					if nom ~= "." and nom ~= ".." then
						if previo[c].directory == false then
							pcall(System.removeFile, raiz_tmp .."/".. nom)
						else
							local dentro = System.listDirectory(raiz_tmp .."/".. nom)
							if dentro ~= nil then
								for d = 1, #dentro do
									if dentro[d].directory == false then
										pcall(System.removeFile, raiz_tmp .."/".. nom .."/".. dentro[d].name)
									end
								end
							end
						end
					end
				end
			end
			COPIAR_CON_PROGRESO(ruta_rom, dest, "ROM")
			if doesFileExist(dest) and ROM_TAMANO(dest) == tam then
				return dest, destinos[i] .." (copiada, ".. tostring(tam) .." bytes)"
			end
			pcall(System.removeFile, dest)
		end
	end
	return nil, "ningun soporte legible con espacio (ROM de ".. tostring(tam) .." bytes)"
end

--- Puente de partidas entre el disco interno y el soporte de transbordo. -------------
--- Un core oficial no sabe leer el disco interno, asi que la ROM se le copia a la
--- llave USB. Sus partidas se escriben entonces TAMBIEN en la llave, y quedarian
--- desperdigadas ahi. El puente hace el viaje de vuelta:
---
---   antes de lanzar   la partida de ESTE juego sale del disco hacia la llave
---   el core juega     escribe en la llave, sin saber que hay un disco
---   al volver         el lanzador recoge todo lo escrito y lo devuelve al disco
---
--- Asi el disco sigue siendo el domicilio de las partidas y la llave solo un pasillo.
--- Sin el paso de ida, un juego arrancaria en blanco y machacaria lo guardado.
--- Todo esto solo se activa cuando el lanzador vive en el disco interno: en una llave
--- o en una tarjeta, las partidas ya estan donde el core las escribe.
SAVES_PUENTE_ON = true
SAVES_CARPETAS = {"Saves", "SaveStates"}

--- Crea una ruta completa, componente a componente. ---------------------------------
--- "System.createDirectory" no crea los padres, y la carpeta de paso tiene ahora dos
--- niveles ("RETROLauncher/Roms") mas la consola debajo.
function CREAR_CADENA(base, resto)
	if base == nil or resto == nil then return false end
	local ruta = base
	local desde = 1
	while true do
		local corte = string.find(resto, "/", desde, true)
		local trozo = nil
		if corte == nil then trozo = string.sub(resto, desde)
		else trozo = string.sub(resto, desde, corte-1) end
		if trozo ~= nil and trozo ~= "" then
			ruta = ruta .."/".. trozo
			if System.listDirectory(ruta) == nil then
				System.createDirectory(ruta)
				if System.listDirectory(ruta) == nil then return false end
			end
		end
		if corte == nil then break end
		desde = corte + 1
	end
	return true
end

--- Nombre de la carpeta que contiene un fichero: ".../Roms/gb/Tetris.zip" -> "gb". ---
function CARPETA_DE_RUTA(ruta)
	if ruta == nil then return nil end
	local fin = string.len(ruta)
	while fin > 0 and string.sub(ruta, fin, fin) ~= "/" do fin = fin - 1 end
	if fin <= 1 then return nil end
	local ini = fin - 1
	while ini > 0 and string.sub(ruta, ini, ini) ~= "/" do ini = ini - 1 end
	local n = string.sub(ruta, ini+1, fin-1)
	if n == "" or string.find(n, ":", 1, true) ~= nil then return nil end
	return n
end

--- Nombre de un fichero sin su extension: "Tetris (World).zip" -> "Tetris (World)". --
function SIN_EXTENSION(nombre)
	if nombre == nil then return nil end
	local punto = string.len(nombre)
	while punto > 0 and string.sub(nombre, punto, punto) ~= "." do punto = punto - 1 end
	if punto > 1 then return string.sub(nombre, 1, punto-1) end
	return nombre
end

--- Prefijo de unidad de una ruta: "mass0:/x/y" -> "mass0:". --------------------------
function DEV_DE_RUTA(ruta)
	if ruta == nil then return nil end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return nil end
	return string.sub(ruta, 1, pos)
end

--- Copia un arbol de ficheros, creando los directorios que falten. --------------------
--- "System.createDirectory" no crea los padres, de ahi la recursion en orden.
--- El limite de profundidad evita que un enlace raro cuelgue la consola.
function COPIAR_ARBOL(origen, destino, nivel)
	if nivel == nil then nivel = 0 end
	if nivel > 4 then return end
	local lista = System.listDirectory(origen)
	if lista == nil then return end
	if System.listDirectory(destino) == nil then
		System.createDirectory(destino)
	end
	for i = 1, #lista do
		local nom = lista[i].name
		if nom ~= "." and nom ~= ".." then
			if lista[i].directory == true then
				COPIAR_ARBOL(origen .."/".. nom, destino .."/".. nom, nivel + 1)
			else
				System.copyFile(origen .."/".. nom, destino .."/".. nom)
			end
		end
	end
end
--- Vacia un arbol de ficheros. El reverso de COPIAR_ARBOL. ---------------------------
--- Las carpetas se quedan, vacias: Enceladus expone "System.removeFile" pero no el
--- equivalente para directorios. No es un problema -- una carpeta vacia no estorba, y
--- "directorios_faltantes" cuenta justamente con que existan.
function BORRAR_ARBOL(ruta, nivel)
	if nivel == nil then nivel = 0 end
	if nivel > 4 then return end
	local lista = System.listDirectory(ruta)
	if lista == nil then return end
	for i = 1, #lista do
		local nom = lista[i].name
		if nom ~= "." and nom ~= ".." then
			if lista[i].directory == true then
				BORRAR_ARBOL(ruta .."/".. nom, nivel + 1)
			else
				pcall(System.removeFile, ruta .."/".. nom)
			end
		end
	end
end

--- Copia los ficheros de un directorio a otro. Devuelve cuantos. ---------------------
function COPIAR_PLANO(origen, destino, borrar)
	local lista = System.listDirectory(origen)
	if lista == nil then return 0 end
	if System.listDirectory(destino) == nil then System.createDirectory(destino) end
	if System.listDirectory(destino) == nil then return 0 end
	local n = 0
	for i = 1, #lista do
		if lista[i].directory == false then
			local ok = pcall(System.copyFile, origen .."/".. lista[i].name, destino .."/".. lista[i].name)
			if ok == true and doesFileExist(destino .."/".. lista[i].name) then
				n = n + 1
				if borrar == true then pcall(System.removeFile, origen .."/".. lista[i].name) end
			end
		end
	end
	return n
end

--- El lanzador vive en el disco interno? Solo entonces hace falta el puente. ----------
function PUENTE_HACE_FALTA()
	if SAVES_PUENTE_ON ~= true then return false end
	return ES_RAIZ_ATA(System.currentDirectory() .."/Saves")
end

--- IDA: saca del disco las partidas de un juego hacia el soporte de transbordo. ------
--- "consola" es la carpeta de ROMs ("gb", "nes"...), "base" el nombre del juego sin
--- extension. RetroArch nombra la partida como la ROM: "Tetris.zip" -> "Tetris.srm",
--- y los save states anaden un sufijo ("Tetris.state", "Tetris.state1"...). Por eso
--- se copia todo lo que EMPIEZA por el nombre del juego, no solo una extension.
function SAVES_DESPLEGAR(dev, consola, base)
	if PUENTE_HACE_FALTA() == false or dev == nil or base == nil then return 0 end
	local actual = System.currentDirectory()
	local n = 0
	for c = 1, #SAVES_CARPETAS do
		local origen = actual .."/".. SAVES_CARPETAS[c]
		local destino = dev .. ROM_SHUTTLE_SUB .."/".. SAVES_CARPETAS[c]
		if consola ~= nil then
			origen = origen .."/".. consola
			destino = destino .."/".. consola
		end
		local lista = System.listDirectory(origen)
		if lista ~= nil then
			local sufijo = string.sub(ROM_SHUTTLE_SUB, 2) .."/".. SAVES_CARPETAS[c]
			if consola ~= nil then sufijo = sufijo .."/".. consola end
			CREAR_CADENA(dev, sufijo)
			for i = 1, #lista do
				local nom = lista[i].name
				if lista[i].directory == false and string.sub(nom, 1, string.len(base)) == base then
					local ok = pcall(System.copyFile, origen .."/".. nom, destino .."/".. nom)
					if ok == true then n = n + 1 end
				end
			end
		end
	end
	return n
end

--- Ficheros sueltos: se les busca su consola antes de traerlos. -----------------------
--- "Zelda.state1" no dice de que sistema es, pero "Roms/<consola>/Zelda.*" si. Se
--- recorre ROMS_DIR buscando una ROM cuyo nombre sin extension coincida; si aparece,
--- la partida va a "<carpeta>/<consola>/", que es donde habria caido con la ordenacion
--- por contenido activa. Si no aparece, se queda en la raiz como antes.
function SAVES_RECOLOCAR(origen, casa)
	local lista = System.listDirectory(origen)
	if lista == nil then return 0 end
	local actual = System.currentDirectory()
	local n = 0
	for i = 1, #lista do
		if lista[i].directory == false then
			local nom = lista[i].name
			local base = SIN_EXTENSION(nom)
			local consola = nil
			-- Los estados anaden un sufijo al nombre completo de la ROM:
			-- "Zelda.zip" -> "Zelda.state1", asi que hay que quitar DOS extensiones.
			local base2 = SIN_EXTENSION(base)
			for c = 1, #ROMS_DIR do
				if consola == nil then
					local dir = actual .."/Roms/".. ROMS_DIR[c]
					local roms = System.listDirectory(dir)
					if roms ~= nil then
						for r = 1, #roms do
							if roms[r].directory == false then
								local rb = SIN_EXTENSION(roms[r].name)
								if rb == base or rb == base2 then consola = ROMS_DIR[c] end
							end
						end
					end
				end
			end
			local destino = casa
			if consola ~= nil then
				destino = casa .."/".. consola
				if System.listDirectory(destino) == nil then
					System.createDirectory(destino)
				end
			end
			local ok = pcall(System.copyFile, origen .."/".. nom, destino .."/".. nom)
			if ok == true and doesFileExist(destino .."/".. nom) then
				n = n + 1
				pcall(System.removeFile, origen .."/".. nom)
				if consola ~= nil then
					boot_log("SAVES  ".. nom .." -> ".. consola .."/ (estaba suelto)")
				end
			end
		end
	end
	return n
end

--- VUELTA: recoge lo que los cores han escrito en los soportes y lo devuelve al disco.
--- Se llama al arrancar el lanzador, que es justo cuando se vuelve de un juego.
--- La copia del soporte SIEMPRE gana: acaba de escribirla el core, y la API Lua de PS2
--- no expone la fecha de un fichero, asi que no hay otra forma de decidir.
function SAVES_RECUPERAR()
	if PUENTE_HACE_FALTA() == false then return 0 end
	local actual = System.currentDirectory()
	local destinos = ROM_DESTINOS()
	local total = 0
	for d = 1, #destinos do
		for c = 1, #SAVES_CARPETAS do
			local raiz = destinos[d] .. ROM_SHUTTLE_SUB .."/".. SAVES_CARPETAS[c]
			if System.listDirectory(raiz) ~= nil then
				local casa = actual .."/".. SAVES_CARPETAS[c]
				if System.listDirectory(casa) == nil then System.createDirectory(casa) end
				-- Sueltos en la raiz. Pasa cuando un override de core desactiva la
				-- ordenacion por carpeta de contenido -- es lo que le ocurrio a Zelda
				-- DX, cuyo ".srm" cayo en "Saves/gbc/" y sus estados en la raiz de
				-- "SaveStates/". En vez de traerlos sueltos al disco, se busca a que
				-- consola pertenece cada uno preguntando por la ROM en "Roms/", y se
				-- guardan donde deberian haber estado.
				total = total + SAVES_RECOLOCAR(raiz, casa)
				-- Y una carpeta por consola.
				local subs = System.listDirectory(raiz)
				if subs ~= nil then
					for i = 1, #subs do
						local nom = subs[i].name
						if subs[i].directory == true and nom ~= "." and nom ~= ".." then
							total = total + COPIAR_PLANO(raiz .."/".. nom, casa .."/".. nom, true)
						end
					end
				end
			end
		end
	end
	if total > 0 then
		boot_log("SAVES  ".. tostring(total) .." partida(s) devueltas al disco interno")
		boot_escribir()
	end
	return total
end

--- VMC (tarjeta de memoria virtual) por juego para PS2 / Neutrino. -------------------
--- Una sola tarjeta compartida -y peor, una de 64 MB- es justo lo que corrompe las
--- partidas: muchos juegos rechazan o danan tarjetas de mas de 8 MB, y una tarjeta
--- unica deja que un juego pise los datos de otro. La cura es una tarjeta de 8 MB POR
--- JUEGO, que ademas es lo que Neutrino espera (-mc0=<fichero>).
--- El launcher no sabe formatear una tarjeta PS2 en Lua (formato con ECC/FAT), asi que
--- lleva un molde vacio ya formateado, "Bios/vmc-template.bin" (8 MB raw), y lo COPIA
--- a "VMC/<ID>.bin" la primera vez que se lanza el juego. Neutrino la rellena luego.
--- Poner a false para volver al comportamiento clasico (tarjeta manual o real).
VMC_AUTO_ON = true

--- Con que se lanza cada ISO de PS2: Neutrino o OPL. ---------------------------------
--- Se guarda por juego en "System/Config/Launcher.cfg", una linea "<fichero>=opl".
--- Solo se anota lo que se aparta de la norma: sin linea, Neutrino.
---
--- La eleccion existia ya, pero habia que MANTENER CRUZ+CIRCULO al lanzar, o poner
--- RUN_DEFAULT a 1 para que preguntara en cada juego. Ninguna de las dos se descubre
--- sola, y una combinacion de botones no es un ajuste.
LANZADOR_JUEGOS = {}
LANZADOR_LEIDO = false

function LANZADOR_FICHERO()
	return System.currentDirectory() .."/System/Config/Launcher.cfg"
end

function LANZADOR_LEER()
	if LANZADOR_LEIDO == true then return end
	LANZADOR_LEIDO = true
	local f = LANZADOR_FICHERO()
	if doesFileExist(f) == false then return end
	pcall(function()
		local h = System.openFile(f, FREAD)
		System.seekFile(h, 0, SET)
		local t = System.readFile(h, System.sizeFile(h))
		System.closeFile(h)
		if t == nil then return end
		for linea in string.gmatch(t .."\n", "([^\n]*)\n") do
			local clave, valor = string.match(linea, "^([^=]+)=(.*)$")
			if clave ~= nil then
				valor = string.gsub(valor, "%s+$", "")
				if valor ~= "" then LANZADOR_JUEGOS[clave] = valor end
			end
		end
	end)
end

function LANZADOR_GUARDAR()
	pcall(function()
		local t = ""
		for juego, valor in pairs(LANZADOR_JUEGOS) do
			t = t .. juego .."=".. valor .."\n"
		end
		local h = System.openFile(LANZADOR_FICHERO(), FCREATE)
		System.writeFile(h, t, string.len(t))
		System.closeFile(h)
	end)
end

--- True si ESTE juego debe lanzarse con OPL en vez de Neutrino. -----------------------
function LANZADOR_ES_OPL(nombre)
	if nombre == nil then return false end
	LANZADOR_LEER()
	return LANZADOR_JUEGOS[nombre] == "opl"
end

--- Tarjeta virtual: UN solo ajuste, por juego, sin ambiguedad. -----------------------
--- "System/Config/VMC.cfg" guarda una linea por juego, "<ID>=<valor>", donde el valor
--- es una de estas tres cosas:
---
---   (ausente)               automatico -- se busca una tarjeta cuyo nombre empiece
---                           por el ID, en el VMC de CADA unidad montada; si no hay
---                           ninguna, se crea en la unidad de la ISO.
---   none                    ningun "-mc0=": Neutrino usa las tarjetas REALES.
---   mass1:/VMC/xxx.bin      esa tarjeta y ninguna otra.
---
--- Habia aqui un ajuste global "donde crear las tarjetas" ademas de esto, y un segundo
--- selector de fichero que duplicaba el de Boon. Tres formas de decidir la misma cosa,
--- ninguna de las cuales decia que fichero se iba a usar de verdad. Queda una.
VMC_JUEGOS = {}
VMC_CFG_LEIDO = false

function VMC_CFG_FICHERO()
	return System.currentDirectory() .."/System/Config/VMC.cfg"
end

function VMC_CFG_LEER()
	if VMC_CFG_LEIDO == true then return end
	VMC_CFG_LEIDO = true
	local f = VMC_CFG_FICHERO()
	if doesFileExist(f) == false then return end
	pcall(function()
		local h = System.openFile(f, FREAD)
		System.seekFile(h, 0, SET)
		local t = System.readFile(h, System.sizeFile(h))
		System.closeFile(h)
		if t == nil then return end
		for linea in string.gmatch(t .."\n", "([^\n]*)\n") do
			local clave, valor = string.match(linea, "^([^=]+)=(.*)$")
			if clave ~= nil then
				clave = string.gsub(clave, "%s+$", "")
				valor = string.gsub(valor, "%s+$", "")
				if valor ~= "" then VMC_JUEGOS[clave] = valor end
			end
		end
	end)
end

function VMC_CFG_GUARDAR()
	pcall(function()
		local t = ""
		for id, valor in pairs(VMC_JUEGOS) do
			t = t .. id .."=".. valor .."\n"
		end
		local h = System.openFile(VMC_CFG_FICHERO(), FCREATE)
		System.writeFile(h, t, string.len(t))
		System.closeFile(h)
	end)
end

--- Las unidades donde puede vivir una carpeta VMC. ------------------------------------
function VMC_UNIDADES()
	local out, vistos = {}, {}

	local function anadir(dev)
		if dev == nil or vistos[dev] == true then return end
		if string.lower(string.sub(dev, 1, 4)) ~= "mass" then return end
		vistos[dev] = true
		out[#out + 1] = dev
	end

	-- EL SOPORTE DE ARRANQUE PRIMERO, y es todo el problema que habia aqui.
	--
	-- "BDM_DEVICES" no contiene la unidad desde la que corre el lanzador: se llena con
	-- "if unidad ~= propio then table.insert(...)". Recorrerla sola dejaba fuera
	-- justamente el disco donde esta el lanzador -- y donde estan las tarjetas. De ahi
	-- que no se encontrara ninguna VMC, y que ni siquiera se ofreciera crearla en el
	-- disco interno. El resto del programa ya lo hacia bien: RUTA_ART anade la unidad
	-- propia antes de recorrer BDM_DEVICES.
	local actual = System.currentDirectory()
	local pos = string.find(actual, ":", 1, true)
	if pos ~= nil then anadir(string.sub(actual, 1, pos)) end

	if BDM_DEVICES ~= nil then
		for i = 1, #BDM_DEVICES do anadir(BDM_DEVICES[i]) end
	end
	return out
end

--- Las formas en que un mismo ID puede estar escrito en un nombre de fichero. --------
--- "SLES-51191" es la convencion de las tarjetas, "SLES_511.91" la de las ISO de OPL,
--- y por el camino aparecen las dos con el otro separador. Comparar con una sola forma
--- es lo que dejaba la lista vacia aunque la carpeta tuviera las tarjetas delante.
function VMC_ID_VARIANTES(id)
	if id == nil then return {} end
	local reg, num = string.match(id, "^(%a%a%a%a)%-(%d%d%d%d%d)")
	if reg == nil then return {string.lower(id)} end
	local n3, n2 = string.sub(num, 1, 3), string.sub(num, 4, 5)
	return {string.lower(reg .."-".. num),        -- SLES-51191
	        string.lower(reg .."_".. num),        -- SLES_51191
	        string.lower(reg .."_".. n3 ..".".. n2),   -- SLES_511.91
	        string.lower(reg .."-".. n3 ..".".. n2),   -- SLES-511.91
	        string.lower(reg .. num)}             -- SLES51191
end

--- TODAS las tarjetas de TODAS las unidades. -----------------------------------------
--- Las que parecen ser de este juego van primero; las demas van detras en vez de
--- desaparecer. Una lista vacia frente a una carpeta llena no informa de nada, y
--- ademas hay quien nombra sus tarjetas a mano, sin ningun ID.
--- Devuelve dos tablas: rutas, y si cada una corresponde al juego.
function VMC_CANDIDATAS(id)
	local propias, otras = {}, {}
	local variantes = VMC_ID_VARIANTES(id)
	local unidades = VMC_UNIDADES()
	for i = 1, #unidades do
		local dir = unidades[i] .."/VMC"
		local c = System.listDirectory(dir)
		if c ~= nil then
			for j = 1, #c do
				local n = c[j].name
				if c[j].directory == false and string.lower(string.sub(n, -4)) == ".bin" then
					local nlow = string.lower(n)
					local mio = false
					-- El ID puede estar en CUALQUIER parte del nombre, no solo al
					-- principio. "SCES-50295 Dark Cloud Data (Europe).bin" empieza por
					-- el ID, pero "Dark Cloud SCES-50295.bin" no, y es la misma partida.
					-- Comparar solo el principio dejaba fuera la mitad de las tarjetas
					-- nombradas a mano.
					for v = 1, #variantes do
						if string.find(nlow, variantes[v], 1, true) ~= nil then
							mio = true
						end
					end
					if mio then propias[#propias + 1] = dir .."/".. n
					else otras[#otras + 1] = dir .."/".. n end
				end
			end
		end
	end
	local todas = {}
	for i = 1, #propias do todas[#todas + 1] = propias[i] end
	for i = 1, #otras do todas[#todas + 1] = otras[i] end
	return todas, #propias
end

--- Crea una tarjeta vacia de 8 MB y devuelve su ruta, o nil. --------------------------
--- "fichero" es el nombre COMPLETO con su ".bin". Antes se recibia el ID y se le
--- pegaba la extension aqui, lo que impedia elegir el nombre desde el menu.
function VMC_CREAR(dev, fichero)
	if dev == nil or fichero == nil then return nil end
	local dir = dev .."/VMC"
	if System.listDirectory(dir) == nil then pcall(System.createDirectory, dir) end
	if System.listDirectory(dir) == nil then return nil end
	local dest = dir .."/".. fichero
	if doesFileExist(dest) then return dest end
	local molde = RUTA_BIOS("vmc-template.bin", "")
	if doesFileExist(molde) == false then return nil end
	pcall(System.copyFile, molde, dest)
	if doesFileExist(dest) then return dest end
	return nil
end

--- ID normalizado del juego a partir del nombre del fichero de la ISO. ----------------------------
--- "SCES_502.40.Extermination.iso" -> "SCES-50240", la convencion de OPL y de las
--- carpetas de guardado. nil si el nombre no lleva un ID reconocible.
function VMC_ID(nombre)
	if nombre == nil then return nil end
	local reg, n1, n2 = string.match(nombre, "^(%a%a%a%a)_(%d%d%d)%.(%d%d)")
	if reg ~= nil then return reg .."-".. n1 .. n2 end
	-- variante con guion o sin punto: "SLES-51044", "SLUS_20946"
	local reg2, num = string.match(nombre, "^(%a%a%a%a)[_%- ]?(%d%d%d%d%d)")
	if reg2 ~= nil then return reg2 .."-".. num end
	return nil
end

--- El ID tal y como lo escribe OPL: "SCES_502.95". ------------------------------------
--- Es la forma que llevan las ISO, y la que se usa para bautizar una tarjeta nueva, de
--- modo que el nombre del fichero se parezca al del juego que tiene al lado.
function VMC_ID_OPL(nombre)
	local id = VMC_ID(nombre)
	if id == nil then return nil end
	local reg, num = string.match(id, "^(%a%a%a%a)%-(%d%d%d%d%d)")
	if reg == nil then return id end
	return reg .."_".. string.sub(num, 1, 3) ..".".. string.sub(num, 4, 5)
end

--- El titulo que va detras del ID en el nombre de la ISO. -----------------------------
--- "SCES_502.95.Dark Cloud.iso" -> "Dark Cloud". Devuelve "" si no se reconoce nada,
--- y en ese caso la tarjeta se queda solo con el ID y el numero.
function VMC_TITULO(nombre)
	if nombre == nil then return "" end
	local t = nombre
	t = string.gsub(t, "%.[Ii][Ss][Oo]$", "")
	t = string.gsub(t, "^%a%a%a%a[_%- ]?%d%d%d%.?%d%d%.?", "")
	t = string.gsub(t, "^%s+", "")
	t = string.gsub(t, "%s+$", "")
	-- Fuera todo lo que no sea seguro en un nombre de fichero en exFAT.
	t = string.gsub(t, "[^%w%s%-_%(%)%[%]]", "")
	if string.len(t) > 40 then t = string.sub(t, 1, 40) end
	t = string.gsub(t, "%s+$", "")
	return t
end

--- Nombre propuesto para una tarjeta nueva: "SCES_502.95_Dark Cloud-1.bin". -----------
--- El numero del final lo mueve el usuario con arriba / abajo, para poder tener varias
--- partidas del mismo juego sin que una pise a la otra.
function VMC_NOMBRE_NUEVO(nombre, n)
	local idopl = VMC_ID_OPL(nombre)
	if idopl == nil then return nil end
	if n == nil or n < 1 then n = 1 end
	local titulo = VMC_TITULO(nombre)
	if titulo == "" then return idopl .."-".. n ..".bin" end
	return idopl .."_".. titulo .."-".. n ..".bin"
end

--- Devuelve el argumento "-mc0=<ruta>" para el juego, creando la tarjeta si falta.
--- "unidad_iso" es el prefijo de unidad donde Neutrino leera la ISO, para poner la
--- tarjeta en el MISMO soporte (con -bsd=ata todo es "mass:"). nil si no procede.
function VMC_AUTO(nombre, unidad_iso)
	if VMC_AUTO_ON ~= true then return nil end
	VMC_CFG_LEER()
	local id = VMC_ID(nombre)
	if id == nil then return nil end

	local elegido = VMC_JUEGOS[id]

	-- "none" quiere decir NINGUNA tarjeta, y tiene que ganar sobre todo lo demas.
	-- Aqui estaba el sinsentido: desactivar la tarjeta en el menu de Boon deja el
	-- juego sin ".vmcd", o sea sin eleccion manual, y esta funcion lo tomaba por
	-- "no ha elegido nada, le creo una". El juego arrancaba con una tarjeta que el
	-- usuario acababa de quitar.
	if elegido == "none" then return nil end

	-- Una ruta concreta, si sigue existiendo.
	if elegido ~= nil and doesFileExist(elegido) then
		return "-mc0=".. elegido
	end

	-- Automatico: la primera tarjeta que sea DE ESTE JUEGO.
	--
	-- VMC_CANDIDATAS devuelve ahora todos los ".bin" de las carpetas, para que la
	-- lista del menu no aparezca vacia delante de una carpeta llena. Pero aqui no se
	-- elige a ciegas: el segundo valor dice cuantas de las primeras llevan el ID del
	-- juego, y solo esas pueden usarse sin que el usuario lo haya pedido. Coger la
	-- primera de la carpeta seria arrancar con la partida de otro juego.
	local cand, propias = VMC_CANDIDATAS(id)
	if propias >= 1 then return "-mc0=".. cand[1] end

	-- Ninguna tarjeta, y ninguna eleccion: el juego arranca SIN "-mc0=".
	--
	-- Antes se creaba una aqui mismo, en silencio, la primera vez que se lanzaba un
	-- juego. Es justo lo que hacia el asunto incomprensible: aparecian tarjetas que
	-- nadie habia pedido, en una unidad que nadie habia elegido. Crear una es ahora
	-- una accion explicita del menu del juego, y solo eso.
	return nil
end

--- Reinicio del IOP para POPStarter y Ember: NUNCA. ----------------------------------
--- Confirmado en hardware real y por el autor del proyecto: "restarting the IOP
--- causes the .ELF file to be lost, resulting in the game immediately closing and
--- returning to the PS2 menu". El reset descarga los drivers USB y el cargador ya no
--- puede leer el propio ELF que debe lanzar -> vuelta al menu de la consola.
--- El valor 1 fue una hipotesis de diagnostico para los VCD; el culpable real era el
--- retardo de acceso USB de POPStarter (POPS_USB_DELAY), no el estado del IOP.
IOP_REBOOT_POPS = 0
IOP_REBOOT_EMBER = 0

MEDIA_ALIAS = {
	"megadrive", "mastersystem", "gamegear", "nes", "gb", "gbc", "gba",
	"atari2600", "lynx", "sg1000", "ngp", "snes",
	"APPS-Media", "psx-ember(bin and cue)", "ps2-isos",
}

--- Indice de las carpetas de medios. -------------------------------------------------
--- El manual avisa (pagina 46): "comprobar si una imagen existe en una carpeta de 500
--- elementos no es lo mismo que buscarla en una de mas de 1000". Cada cambio de
--- seleccion preguntaba por hasta seis rutas distintas, una llamada al sistema de
--- ficheros cada una, y este fork ha multiplicado las raices a explorar.
--- Aqui la carpeta se lista UNA vez y despues la comprobacion es una busqueda en
--- tabla, gratis. El indice se vacia al reconstruir una lista, que es cuando el
--- contenido puede haber cambiado.
MEDIA_INDICE = {}

function media_indice(directorio)
	local idx = MEDIA_INDICE[directorio]
	if idx ~= nil then return idx end
	idx = {}
	local c = System.listDirectory(directorio)
	if c ~= nil then
		for i = 1, #c do
			if c[i].directory == false then idx[c[i].name] = true end
		end
	end
	MEDIA_INDICE[directorio] = idx
	return idx
end

function media_indice_olvidar()
	MEDIA_INDICE = {}
end

--- Localizacion de caratulas y capturas. --------------------------------------------
--- Este fork busca PRIMERO junto a la propia ROM, lo que permite que los medios de
--- los juegos del disco exFAT vivan en el disco exFAT:
---   <carpeta de la rom>/media/covers/<fichero sin extension>.png
---   <carpeta de la rom>/media/screenshots/<fichero sin extension>.png
--- Si no hay nada, se usa la ubicacion historica del programa:
---   <launcher>/Multimedia/Covers/Covers <Sistema>/<fichero sin extension>.png
function RUTA_MEDIA(tipo, identidad, sistema, nombre, base)
	if nombre == nil then return "" end
	local carpeta = "covers"
	local clasico = "Covers/Covers "
	if tipo == "screenshot" then
		carpeta = "screenshots"
		clasico = "Screenshots/Screenshots "
	end

	-- 1. "Roms/<alias>/media/..." sobre cada raiz, EN ORDEN: RAICES[1] es siempre el
	--    soporte de arranque, asi que el USB gana. Un juego que vive en el disco
	--    exFAT usa la caratula del USB si esta ahi, lo que permite centralizar todas
	--    las imagenes en la llave sin duplicarlas en el disco.
	if tipo == "cover" then MEDIA_DIAG = {} end
	local function probar(dir, fichero)
		local hay = media_indice(dir)[fichero] == true
		if tipo == "cover" and #MEDIA_DIAG < 8 then
			table.insert(MEDIA_DIAG, (hay and "[ok]   " or "[FALTA] ") .. dir .."/".. fichero)
		end
		return hay
	end

	-- PS1 reune dos formatos bajo la misma identidad, y sus imagenes pueden estar en
	-- la carpeta de cualquiera de los dos. Se prueban ambas.
	local fichero = base ..".png"
	local alias = {MEDIA_ALIAS[identidad]}
	if identidad == 14 then table.insert(alias, "psx-pops(vcd)") end
	if RAICES ~= nil then
		for a = 1, #alias do
			if alias[a] ~= nil then
				for i = 1, #RAICES do
					local dir = RAICES[i] .."/Roms/".. alias[a] .."/media/".. carpeta
					if probar(dir, fichero) then return dir .."/".. fichero end
				end
			end
		end
	end

	-- 2. Junto a la propia ROM, este donde este.
	local orig = nil
	if ORIGEN_DIR ~= nil then orig = ORIGEN_DIR[tostring(identidad) .."|".. nombre] end
	if orig ~= nil then
		local dir = orig .."media/".. carpeta
		if probar(dir, fichero) then return dir .."/".. fichero end
	end

	-- 3. Ubicacion historica, por compatibilidad con instalaciones existentes.
	local dir = base_launcher() .."/Multimedia/".. clasico .. sistema
	probar(dir, fichero)
	return dir .."/".. fichero
end

--- Rutas probadas para la ultima caratula. Se vuelcan en el journal al lanzar,
--- que es la unica forma de ver desde el PC lo que la consola ha mirado de verdad.
MEDIA_DIAG = {}

--- Traza de la carga de imagenes. --------------------------------------------------
--- "Graphics.loadImage" puede colgar la consola con un PNG que no le gusta o que no
--- cabe en VRAM, y entonces no queda ni mensaje ni log. Aqui se escribe la ruta
--- ANTES de cargarla: si la consola se congela, el ultimo renglon del fichero nombra
--- la imagen culpable. Poner a false cuando ya no haga falta, escribe en cada
--- La ultima imagen abierta, como testigo de cuelgue. ---------------------------------
--- Si el journal termina en una linea ART que dice "cargando", la consola se colgo al
--- abrir esa imagen: convertirla o reducirla resuelve el caso.
--- ART_LOG_ON a false -- que es lo normal -- solo la guarda en memoria y la escribe
--- cuando algo mas provoque un volcado. A true la escribe en el acto, y entonces CADA
--- caratula reescribe el fichero entero: solo para cazar precisamente ese cuelgue.
ART_LOG_ON = false

function log_art(fase, ruta)
	ART_ULTIMA = tostring(fase) .." -> ".. tostring(ruta)
	if ART_LOG_ON == true then boot_escribir() end
end

--- Carpeta "ART" de OPL. Esta en la RAIZ de la unidad, NO dentro del launcher, y
--- upstream solo miraba en el soporte de arranque. Aqui se recorren tambien las
--- unidades BDM, para que "<disco exFAT>/ART" sirva a los juegos que viven ahi.
function RUTA_ART(fichero)
	local cand = {}
	local actual = System.currentDirectory()
	local pos = string.find(actual, ":", 1, true)
	if pos ~= nil then table.insert(cand, string.sub(actual, 1, pos)) end
	if BDM_DEVICES ~= nil then
		for i = 1, #BDM_DEVICES do table.insert(cand, BDM_DEVICES[i]) end
	end
	-- "ART" de OPL puede tener cientos de imagenes: se indexa como las demas.
	for i = 1, #cand do
		if media_indice(cand[i] .."/ART")[fichero] == true then
			return cand[i] .."/ART/".. fichero
		end
	end
	if #cand >= 1 then return cand[1] .."/ART/".. fichero end
	return actual .."/ART/".. fichero
end

--- Recursos globales (fondos, fuentes). Nueva ubicacion: "Roms/!Retrolauncher/",
--- junto al resto del contenido. Se conserva "Multimedia/Others" como respaldo.
function RUTA_GLOBAL(que)
	local actual = System.currentDirectory()
	local nuevo = actual .."/Roms/!Retrolauncher/".. que
	if System.listDirectory(nuevo) ~= nil then return nuevo end
	return actual .."/Multimedia/Others/".. que
end

--- Carpeta del launcher (soporte de arranque). --------------------------------------
function base_launcher()
	return System.currentDirectory()
end

ERROR_DETALLE = nil   -- detalle del ultimo fallo de "existe()"

--- El cuadro de error solo dispone de UNA linea entre el titulo y el pie. Aqui se
--- devuelve un texto corto (solo los nombres de fichero, truncado si hace falta) y
--- se vuelca la version completa, con la ruta, en el journal.
function detalle_falta(etiqueta, base, faltan)
	if faltan == nil or #faltan == 0 then
		log_lanzamiento(etiqueta .."  comprobacion fallida", {"directorio : ".. tostring(base), "(ningun fichero identificado como ausente)"})
		return "Check ".. etiqueta ..": path?"
	end

	local campos = {"directorio esperado : ".. tostring(base), ""}
	for i = 1, #faltan do
		table.insert(campos, "FALTA : ".. faltan[i])
	end
	log_lanzamiento(etiqueta .."  ficheros ausentes", campos)

	local corto = "Missing: ".. faltan[1]
	if #faltan >= 2 then corto = corto .." +".. (#faltan-1) end
	if string.len(corto) > 44 then corto = string.sub(corto, 1, 41) .."..." end
	return corto
end
ORIGEN = {}
ORIGEN_DIR = {}   -- directorio real donde se encontro el juego (PS2)

--- True si la ruta esta en una unidad montada por ata_bd (disco interno exFAT). ------
function ES_RAIZ_ATA(ruta)
	if ruta == nil then return false end
	local pos = string.find(ruta, ":", 1, true)
	if pos == nil then return false end
	return BDM_ATA[string.sub(ruta, 1, pos)] == true
end

--- True si el juego indicado proviene del disco interno. -----------------------------
function ES_ATA(identidad, nombre)
	if nombre == nil then return false end
	return ES_RAIZ_ATA(ORIGEN[tostring(identidad) .."|".. nombre])
end

--- Ruta completa resuelta sobre la primera raiz que la contenga. ----------------------
function RUTA(rel)
	return RAIZ(rel) .. rel
end

--- El inventario usa ES_RAIZ_ATA, asi que se llama DESPUES de definirla. -------------
inventario()

--- La carpeta "retroarch/" que RetroArch exige. Se monta AQUI, al arrancar el
--- lanzador, y no dentro de FORZAR_CONF_RETROARCH: asi sigue funcionando aunque se
--- desactiven los ajustes forzados, y el usuario solo tiene que descomprimir la
--- nightly en "LibretroPS2Files/" sin preguntarse nada mas.
LIBRETRO_REPARAR()

--- Diagnostico de la instalacion de RetroArch, al arrancar. --------------------------
--- Es la pregunta que decide si los juegos libretro van a funcionar, asi que conviene
--- que quede escrita antes de cualquier intento.
if true then
	local base_ra = RUTA_LIBRETRO()
	if base_ra == nil then
		boot_log("")
		boot_log("RETROARCH  NO ENCONTRADO. Ningun soporte lleva LibretroPS2Files/cores.")
		boot_log("           Los sistemas libretro no se ofreceran.")
	elseif ES_RAIZ_ATA(base_ra) == true then
		boot_log("")
		boot_log("RETROARCH  instalado en el DISCO INTERNO : ".. base_ra)
		boot_log("           AVISO: un core oficial no podra leerlo. Al arrancar hace")
		boot_log("           SifIopReset, el IOP se vacia y el disco interno deja de")
		boot_log("           existir para el: se queda sin cores, sin config y sin")
		boot_log("           assets, y muere antes de dibujar nada. Pantalla negra.")
		boot_log("           Solucion: mover LibretroPS2Files a una llave USB.")
		boot_log("           (Funciona tal cual con cores recompilados con ata_bd.)")
	else
		boot_log("")
		boot_log("RETROARCH  ".. base_ra .."  (soporte legible por los cores)")
	end
	boot_escribir()
end

--- Que hay en la llave, al arrancar. --------------------------------------------------
--- Cuando un core sale a pantalla negra la primera pregunta es siempre "que ha llegado
--- de verdad a la llave", y hasta ahora habia que apagar, sacarla y mirarla en el PC.
--- Aqui queda escrito. Son cuatro listados de carpetas pequenas: la raiz del lanzador
--- en la llave, los cores que hay, la ROM en cache y las partidas.
function INVENTARIO_LLAVE()
	local destinos = ROM_DESTINOS()
	for d = 1, #destinos do
		local dev = destinos[d]
		if string.lower(string.sub(dev, 1, 4)) == "mass" then
			local raiz = dev .."/".. CARPETA_LANZADOR
			local top = System.listDirectory(raiz)
			if top ~= nil then
				boot_log("")
				boot_log("LLAVE  ".. raiz)
				for i = 1, #top do
					local n = top[i].name
					if n ~= "." and n ~= ".." then
						if top[i].directory == true then boot_log("       d ".. n)
						else boot_log("         ".. n) end
					end
				end
				-- Los cores presentes: es lo que decide si un juego arrancara sin
				-- copiar nada, y lo primero que falta cuando algo va mal.
				local cores = System.listDirectory(raiz .."/LibretroPS2Files/cores")
				if cores == nil then
					boot_log("       LibretroPS2Files/cores : AUSENTE")
				else
					local n = 0
					for i = 1, #cores do
						if cores[i].directory == false then
							n = n + 1
							boot_log("       core : ".. cores[i].name)
						end
					end
					if n == 0 then boot_log("       LibretroPS2Files/cores : vacio") end
				end
				local cfg = raiz .."/LibretroPS2Files/retroarch/retroarch.cfg"
				boot_log("       retroarch.cfg : ".. tostring(doesFileExist(cfg)))
				-- Las carpetas de trabajo de RetroArch. No las crea el: si faltan,
				-- abre ficheros dentro de nada. "temp" es "cache_directory", donde se
				-- descomprime un .zip -- sin ella una ROM comprimida no arranca.
				local criticas = {"temp", "logs", "system", "savefiles", "savestates"}
				local ausentes = ""
				for i = 1, #criticas do
					if System.listDirectory(raiz .."/LibretroPS2Files/retroarch/".. criticas[i]) == nil then
						ausentes = ausentes .." ".. criticas[i]
					end
				end
				if ausentes == "" then
					boot_log("       retroarch/ carpetas de trabajo : todas presentes")
				else
					boot_log("       retroarch/ AUSENTES :".. ausentes)
				end
				-- La ROM en cache y las partidas que esperan la vuelta.
				local roms = System.listDirectory(raiz .."/Roms")
				if roms ~= nil then
					for i = 1, #roms do
						local c = roms[i].name
						if roms[i].directory == true and c ~= "." and c ~= ".." then
							local dentro = System.listDirectory(raiz .."/Roms/".. c)
							if dentro ~= nil then
								for j = 1, #dentro do
									if dentro[j].directory == false then
										boot_log("       rom  : ".. c .."/".. dentro[j].name)
									end
								end
							end
						end
					end
				end
			end
		end
	end
	boot_escribir()
end

INVENTARIO_LLAVE()

--- Vuelta del puente de partidas: se llama justo al arrancar, que es cuando se
--- vuelve de un juego. Necesita RAICES y BDM_DEVICES, de ahi que este aqui.
SAVES_RECUPERAR()

--- De donde ha arrancado el lanzador, en dos lineas para la pantalla de carga. -------
--- Solo eso. Aqui se decia ademas donde estaba RetroArch y si los juegos iban a
--- arrancar, y para saberlo habia que llamar a RUTA_LIBRETRO() -- un rastreo de varios
--- segundos, lanzado justo en el momento en que la pantalla ya no se refresca. El
--- diagnostico de RetroArch sigue estando, entero, en RETROLauncher.log, que es su sitio.
--- Estas dos lineas se leen de variables ya calculadas: no cuestan nada.
--- En ingles como el resto de la interfaz. MOSTRAR_ORIGEN a false para quitarlo.
MOSTRAR_ORIGEN = true

function ORIGEN_TEXTO()
	if BOOT_ES_ATA ~= true then
		return "Booted from USB / external media", tostring(BOOT_DEV)
	end
	return "Booted from INTERNAL exFAT drive", tostring(BOOT_DEV)
end

--- Pantalla de carga, repintable. ----------------------------------------------------
--- El texto "Loading lists and settings" esta dentro de LOADING.png, en la banda
--- y=247..282 de una imagen de 480 de alto. Se tapa con negro y se escribe encima el
--- paso en curso, para que un arranque que no llega al menu diga DONDE se ha parado en
--- vez de quedarse en una frase fija. Lo mismo va al journal, con volcado inmediato.
CARGA_FONDO, CARGA_LOADING, CARGA_FUENTE = nil, nil, nil
CARGA_RES_X, CARGA_RES_Y = 640, 448

--- Las ultimas lineas, no una sola. ---------------------------------------------------
--- Una banda con el paso en curso no dice nada cuando el arranque se para: se ve DONDE
--- se ha quedado pero no por donde habia pasado. Con una lista que se desplaza se lee
--- de un vistazo lo que ya esta hecho, y la ultima linea, marcada con ">", es
--- exactamente aquello que no ha terminado.
CARGA_LINEAS = {}

--- El texto va en los HUECOS de la imagen, sin taparla. --------------------------------
--- LOADING.png mide 640x480 y se dibuja a 640x448. Midiendo sus pixeles opacos, lo que
--- hay dibujado ocupa, ya en coordenadas de pantalla:
---
---     10..191   x  24..614   el logotipo
---    231..263   x 212..427   la palabra "LOADING"
---    331..440   x  12..628   los creditos: Neutrino, Enceladus, wLaunchELF,
---                            POPStarter, RetroArch y OPL, cada uno con su autor
---
--- De ahi que solo queden DOS franjas enteramente libres, y son estas:
---
---    194..226   entre el logotipo y "LOADING"
---    264..328   entre "LOADING" y los creditos
---
--- El panel negro de antes iba de 8 a 432 y se comia el principio del logotipo y la
--- columna izquierda de los creditos. Ni el titulo ni el nombre de quien ha escrito lo
--- que uno arranca merecen desaparecer detras de una lista de arranque.
---
--- Asi que la lista se reparte en esas dos franjas: el origen arriba y los pasos abajo
--- en dos columnas. Caben diez pasos en vez de veintidos -- el historico entero sigue
--- estando en RETROLauncher.log, que es su sitio; esto es solo por donde va.
CARGA_LINEA_ALTO = 12

CARGA_ORIGEN_BANDA_Y, CARGA_ORIGEN_BANDA_ALTO = 194, 32
CARGA_ORIGEN_Y = 198

CARGA_PASOS_BANDA_Y, CARGA_PASOS_BANDA_ALTO = 264, 64
CARGA_PASOS_Y = 268
CARGA_PASOS_FILAS = 5
CARGA_COLUMNAS = {20, 330}
CARGA_COL_ANCHO = 290

CARGA_MAX_LINEAS = CARGA_PASOS_FILAS * #CARGA_COLUMNAS

--- El soporte de cada paso, en paralelo con el texto: "exfat", "usb" o nil. ------------
CARGA_TIPOS = {}

function CARGA_PINTAR()
	if CARGA_FONDO == nil then return end
	Screen.clear(Color.new(0, 0, 0))
	Graphics.drawScaleImage(CARGA_FONDO, -5, 0, CARGA_RES_X+5, CARGA_RES_Y, Color.new(0, 80, 120))
	Graphics.drawScaleImage(CARGA_LOADING, 0, 0, CARGA_RES_X, CARGA_RES_Y)
	if CARGA_FUENTE == nil then return end
	pcall(function()
		local blanco = Color.new(255, 255, 255)
		local gris = Color.new(160, 160, 160)
		local negro = Color.new(0, 0, 0)

		-- Un panel estrecho a la izquierda, no la pantalla entera. Empieza en x=30 y
		-- no en 0 porque una tele recorta los bordes: pegado al canto no se lee. Y
		-- Llega hasta x=256. El "LOADING" de LOADING.png empieza en 212, asi que se
		-- le come el principio: es el precio de que las lineas quepan enteras, y una
		-- linea cortada no informa de nada. El cuerpo baja a 9 px por lo mismo.
		-- Amarillo el disco interno, cian la llave USB. Es la misma pareja de colores
		-- en todo el programa, para no tener que leer la palabra: de un vistazo se ve
		-- de donde sale cada sistema.
		local amarillo = Color.new(255, 205, 0)
		local cian = Color.new(0, 200, 255)

		-- Un velo oscuro SOLO sobre las dos franjas libres, para que el texto tenga
		-- contraste sin tapar nada de la imagen.
		local velo = Color.new(0, 0, 0, 150)
		Graphics.drawRect(0, CARGA_ORIGEN_BANDA_Y, CARGA_RES_X, CARGA_ORIGEN_BANDA_ALTO, velo)
		Graphics.drawRect(0, CARGA_PASOS_BANDA_Y, CARGA_RES_X, CARGA_PASOS_BANDA_ALTO, velo)

		Font.ftSetPixelSize(CARGA_FUENTE, 9, 9)

		if MOSTRAR_ORIGEN == true then
			local l1, l2 = ORIGEN_TEXTO()
			local col = cian
			if BOOT_ES_ATA == true then col = amarillo end
			Font.ftPrint(CARGA_FUENTE, 20, CARGA_ORIGEN_Y, 6, 600, CARGA_LINEA_ALTO, l1, col)
			Font.ftPrint(CARGA_FUENTE, 20, CARGA_ORIGEN_Y + CARGA_LINEA_ALTO, 6, 600,
				CARGA_LINEA_ALTO, l2, gris)
		end

		-- Los pasos, por columnas: se llena la primera de arriba abajo y se sigue en la
		-- siguiente.
		for i = 1, #CARGA_LINEAS do
			local col_n = ((i - 1) // CARGA_PASOS_FILAS) + 1
			local fila = (i - 1) % CARGA_PASOS_FILAS
			local x = CARGA_COLUMNAS[col_n]
			if x ~= nil then
				local tipo = CARGA_TIPOS[i]
				local marca, col = "  ", gris
				if i == #CARGA_LINEAS then marca, col = "> ", blanco end
				if tipo == "exfat" then col = amarillo
				elseif tipo == "usb" then col = cian end
				Font.ftPrint(CARGA_FUENTE, x, CARGA_PASOS_Y + (fila * CARGA_LINEA_ALTO), 6,
					CARGA_COL_ANCHO, CARGA_LINEA_ALTO, marca .. CARGA_LINEAS[i], col)
			end
		end
		Font.ftSetPixelSize(CARGA_FUENTE, 14, 14)
	end)
end

--- Un paso del arranque: al log (volcado ya) y a la pantalla. -------------------------
--- "tipo" pinta la linea: "exfat" en amarillo, "usb" en cian, nil en gris. -------------
function CARGA_PASO(texto, tipo)
	-- Solo durante el arranque. Varias de las funciones instrumentadas -- recargar_todas
	-- sobre todo -- se vuelven a llamar desde el menu, y sin esto el log creceria sin
	-- fin y cada refresco de lista repintaria la pantalla de carga sobre el menu.
	if CARGA_FONDO == nil then return end
	CARGA_LINEAS[#CARGA_LINEAS + 1] = tostring(texto)
	CARGA_TIPOS[#CARGA_LINEAS] = tipo
	while #CARGA_LINEAS > CARGA_MAX_LINEAS do
		table.remove(CARGA_LINEAS, 1)
		table.remove(CARGA_TIPOS, 1)
	end
	boot_log("CARGA  ".. tostring(texto))
	boot_escribir()
	-- Los dos buffers, para que lo que se ve sea lo mismo tras cualquier flip ajeno.
	pcall(function()
		CARGA_PINTAR()
		Screen.flip()
		CARGA_PINTAR()
	end)
end

function CARGA_FIN()
	-- Las imagenes se liberan; la FUENTE no. Y no es un descuido.
	--
	-- "Font.ftInit()" se llama dos veces: una aqui arriba, para poder escribir en la
	-- pantalla de carga, y otra dentro de la tabla CONTROL, que es la del programa
	-- original. CARGA_FUENTE se obtiene ANTES de esa segunda inicializacion, asi que
	-- descargarla aqui destruye una referencia que ya no pertenece al FreeType en
	-- curso -- y con ella se lleva el estado de "fontARCA" y "fontABC".
	--
	-- El sintoma no es un error sino un menu MUDO: el arranque llega hasta el final,
	-- el bucle principal corre, y ningun "Font.ftPrint" dibuja nada. Pantalla negra
	-- con el programa vivo detras. El journal termina en "entrando en el menu" y
	-- parece que todo ha ido bien, que es lo que lo hace dificil de encontrar.
	--
	-- Una cara de fuente sin liberar no cuesta casi nada. Un menu invisible, todo.
	pcall(function()
		if CARGA_FONDO ~= nil then Graphics.freeImage(CARGA_FONDO) end
		if CARGA_LOADING ~= nil then Graphics.freeImage(CARGA_LOADING) end
	end)
	CARGA_FUENTE, CARGA_FONDO, CARGA_LOADING = nil, nil, nil
end

--- Pantalla de carga y comprobación de directorio. -------------------------------------
if true then
	local res_x, res_y = 640, 448
	--- Reubicacion: eliminada. ----------------------------------------------------------
	--- Aqui se comparaba la ruta guardada en "System/Respaldo/RetroarchPS2/
	--- retroarch-salamander.cfg" con la ruta actual del lanzador, y si no coincidian se
	--- ejecutaba "System/relocation.lua", que reescribia veinticuatro "retroarch.cfg"
	--- -- doce sistemas por NTSC y PAL -- porque cada uno llevaba veinte rutas absolutas
	--- del tipo "mass:/RETROLauncher/System/RetroarchPS2/<sistema>/retroarch/...".
	--- Ya no queda ninguna ruta absoluta: RetroArch deduce todas sus carpetas de su
	--- propio directorio, asi que cambiar el lanzador de unidad o de carpeta no obliga
	--- a reescribir nada. La reubicacion, y las 2989 lineas que la implementaban, sobran.
	if doesFileExist("System/Defaults/PAL") == false and doesFileExist("System/Defaults/NTSC") == false then
		local VMODE = System.openFile("System/Defaults/NTSC", FCREATE)
		System.closeFile(VMODE)
	elseif doesFileExist("System/Defaults/PAL") then
		Screen.setMode(PAL, 640, 512, CT24, INTERLACED, FIELD)
		res_x, res_y = 640, 512
	end
	-- Nada de esto es local: la pantalla de carga tiene que poder repintarse desde
	-- cualquier punto del arranque para decir en que paso va. Se libera al final,
	-- justo antes de entrar en el menu.
	CARGA_RES_X, CARGA_RES_Y = res_x, res_y
	CARGA_FONDO = Graphics.loadImage("System/Medias/Default/FONDO.png")
	CARGA_LOADING = Graphics.loadImage("System/Medias/Default/LOADING.png")

	-- La fuente se carga UNA vez: la pantalla se repinta decenas de veces y no tiene
	-- sentido releer el TTF cada vez.
	-- Todo entre pcall: esto es informacion, no puede tumbar el arranque.
	CARGA_FUENTE = nil
	pcall(function()
		Font.ftInit()
		CARGA_FUENTE = Font.ftLoad("System/Medias/Font/PublicPixel.ttf")
		Font.ftSetPixelSize(CARGA_FUENTE, 14, 14)
	end)

	CARGA_PASO("loading screen ready")
	boot_log("BOOT   pantalla de carga pintada")
	boot_escribir()
	if doesFileExist("System/Medias/Sound/Background/music.adp") == true and doesFileExist("System/Medias/Sound/Background/music0.adp") == true then
		System.removeFile("System/Medias/Sound/Background/music.adp")
	end
end

--- Formato de audio. -------------------------------------------------------------------
Sound.setFormat(16, 48000, 3)

--- Carga y verificación de sonidos. ----------------------------------------------------
--- Y se apunta en el journal lo que ha cargado y cuanto pesa. -------------------------
--- Sound.loadADPCM no dice por que falla, y audsrv_load_adpcm falla EN SILENCIO cuando
--- SifAllocIopHeap no consigue el bloque: pide el fichero entero de una vez y el IOP
--- tiene 2 MB contando los modulos. Un fichero que cabe de sobra en la SPU2 puede no
--- cargar por eso -- una pista de 1,2 MB no cargo, y sin esta linea no hay manera de
--- distinguir "no hay fichero", "el fichero no cabe" y "el volumen esta a cero".
function verificar_sonidos(sonido, dir)
	local actual = System.currentDirectory()
	sonido = nil
	if doesFileExist(actual .."/".. dir) then
		local bytes = nil
		pcall(function()
			local h = System.openFile(actual .."/".. dir, FREAD)
			bytes = System.sizeFile(h)
			System.closeFile(h)
		end)
		sonido = Sound.loadADPCM(dir)
		if boot_log ~= nil then
			local estado = "handle nulo"
			if sonido ~= nil then estado = "handle ".. tostring(sonido) end
			boot_log("SONIDO ".. dir .."  ".. tostring(bytes) .." bytes  -> ".. estado)
		end
	end
	return sonido
end

--- Sonido preferido, con respaldo. -----------------------------------------------------
-- Los ficheros "2" son el juego de sonidos en uso. Los originales de Boon siguen
-- en la carpeta y se cargan solos si los "2" faltan, asi que borrar un fichero "2"
-- basta para volver al sonido de antes.
function sonido_preferido(sonido, preferido, respaldo)
	local elegido = verificar_sonidos(sonido, preferido)
	if elegido == nil then
		elegido = verificar_sonidos(sonido, respaldo)
	end
	return elegido
end

-- Carga de sonidos. --------------------------------------------------------------------
S_MOVER = sonido_preferido(S_MOVER, "System/Medias/Sound/Menu/move2.adp", "System/Medias/Sound/Menu/move.adp");
S_EJECUTAR = sonido_preferido(S_EJECUTAR, "System/Medias/Sound/Menu/run2.adp", "System/Medias/Sound/Menu/run.adp");
S_CANCELAR = sonido_preferido(S_CANCELAR, "System/Medias/Sound/Menu/back2.adp", "System/Medias/Sound/Menu/back.adp");
S_NETX = sonido_preferido(S_NETX, "System/Medias/Sound/Menu/next2.adp", "System/Medias/Sound/Menu/next.adp");
S_MUSICA = verificar_sonidos(S_MUSICA, "System/Medias/Sound/Background/music.adp");
if boot_log ~= nil and S_MUSICA == nil then
	-- El nombre importa: "music0.adp" es el nombre que tiene la pista cuando esta
	-- APAGADA, y es el unico que traia la instalacion. El programa solo busca
	-- "music.adp", asi que de fabrica no suena nada de fondo -- no porque falle, sino
	-- porque nunca estuvo encendida.
	boot_log("SONIDO  sin musica de fondo: falta System/Medias/Sound/Background/music.adp"
		.."  (music0.adp = pista apagada)")
end

--- Una voz SPU2 por sonido de menu. ----------------------------------------------------
--- Los cuatro sonidos se reproducian en la voz 1: los 166 sitios que llaman a repro_sfx
--- pasan "1". Y audsrv no mezcla dos sonidos en una voz -- audsrv_ch_play_adpcm mira el
--- bit ENDX de la voz pedida y, si todavia esta sonando, devuelve
--- -AUDSRV_ERR_NO_MORE_CHANNELS sin reproducir nada:
---
---     if (ch >= 0 && ch < 24) {
---         endx = sceSdGetSwitch(SD_CORE_1 | SD_SWITCH_ENDX);
---         if (!(endx & (1 << ch))) return -AUDSRV_ERR_NO_MORE_CHANNELS;
---
--- Con las muestras de origen, de 0,18 s, hacia falta moverse muy deprisa para notarlo.
--- Cuanto mas largas son las muestras, mas se pisan.
---
--- La voz 2 es la musica y la 3 las intros, asi que los sonidos del menu van de la 4 en
--- adelante. El volumen hay que ponerlo en TODAS: audsrv_adpcm_init deja las 24 voces a
--- 0x3fff, de modo que una voz a la que nadie le baja el volumen suena al maximo.
SFX_CANALES = {}
SFX_VOCES = {1, 4, 5, 6, 7}

function SFX_VOZ(sonido, canal)
	if sonido ~= nil and SFX_CANALES[sonido] ~= nil then return SFX_CANALES[sonido] end
	return canal
end

function SFX_VOLUMEN(volumen)
	for i = 1, #SFX_VOCES do
		pcall(Sound.setADPCMVolume, SFX_VOCES[i], volumen)
	end
end

if S_MOVER ~= nil then SFX_CANALES[S_MOVER] = 4 end
if S_EJECUTAR ~= nil then SFX_CANALES[S_EJECUTAR] = 5 end
if S_CANCELAR ~= nil then SFX_CANALES[S_CANCELAR] = 6 end
if S_NETX ~= nil then SFX_CANALES[S_NETX] = 7 end

--- Cargar variables y configuraciones. -------------------------------------------------
require("System/language")
lang_select()
require("System/menu")
require("System/funciones")
boot_log("BOOT   modulos cargados (language, menu, funciones)")
boot_escribir()

-- Guarda las listas / últimos movimientos / límite de captura. -------------------------
PRE_CARGADAS = {}
LAST_MOVE = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
JOYSTICK_LIMITE = 0

--- Carga y verificación de imágenes. ---------------------------------------------------
function verif_img(dir)
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/".. dir) == false then
		dir = "System/Medias/Default/ERROR.png"
	end
	return dir
end

CARGA_PASO("preloading console logos")
-- Precargar logos. ---------------------------------------------------------------------
LOGOS = {
	DEFAULT = Graphics.loadImage(verif_img("System/Medias/Logos/Default.png"));
	DEFAULT_DEMO = Graphics.loadImage(verif_img("System/Medias/Logos/Default_DEMO.png"));
	MEGADRIVE = Graphics.loadImage(verif_img("System/Medias/Logos/Megadrive.png"));
	MASTERSYSTEM = Graphics.loadImage(verif_img("System/Medias/Logos/MasterSystem.png"));
	GAMEGEAR = Graphics.loadImage(verif_img("System/Medias/Logos/GameGear.png"));
	FAMICOM = Graphics.loadImage(verif_img("System/Medias/Logos/Famicom.png"));
	GAMEBOY = Graphics.loadImage(verif_img("System/Medias/Logos/GameBoy.png"));
	GAMEBOYCOLOR = Graphics.loadImage(verif_img("System/Medias/Logos/GameBoyColor.png"));
	GAMEBOYADVANCE = Graphics.loadImage(verif_img("System/Medias/Logos/GameBoyAdvance.png"));
	ATARI2600 = Graphics.loadImage(verif_img("System/Medias/Logos/Atari2600.png"));
	ATARILYNX = Graphics.loadImage(verif_img("System/Medias/Logos/AtariLynx.png"));
	SEGASG1000 = Graphics.loadImage(verif_img("System/Medias/Logos/SegaSG1000.png"));
	NEOGEOPOCKET = Graphics.loadImage(verif_img("System/Medias/Logos/NeoGeoPocket.png"));
	SUPERFAMICOM = Graphics.loadImage(verif_img("System/Medias/Logos/SuperFamicom.png"));
	APPS = Graphics.loadImage(verif_img("System/Medias/Logos/Apps.png"));
	PLAYSTATION = Graphics.loadImage(verif_img("System/Medias/Logos/PlayStation.png"));
	PLAYSTATION2 = Graphics.loadImage(verif_img("System/Medias/Logos/PlayStation2.png"));
};

CARGA_PASO("preloading pad images")
-- Precargar imágenes de los pads. ------------------------------------------------------
PAD_IMG = {
	CIRCLE = Graphics.loadImage(verif_img("System/Medias/Pads/circle.png"));
	CROSS = Graphics.loadImage(verif_img("System/Medias/Pads/cross.png"));
	L1 = Graphics.loadImage(verif_img("System/Medias/Pads/L1.png"));
	R1 = Graphics.loadImage(verif_img("System/Medias/Pads/R1.png"));
	L2 = Graphics.loadImage(verif_img("System/Medias/Pads/L2.png"));
	R2 = Graphics.loadImage(verif_img("System/Medias/Pads/R2.png"));
	R3 = Graphics.loadImage(verif_img("System/Medias/Pads/R3.png"));
	SELECT_S = Graphics.loadImage(verif_img("System/Medias/Pads/select.png"));
	SQUARE = Graphics.loadImage(verif_img("System/Medias/Pads/square.png"));
	TRIANGLE = Graphics.loadImage(verif_img("System/Medias/Pads/triangle.png"));
	START = Graphics.loadImage(verif_img("System/Medias/Pads/start.png"));
};

CARGA_PASO("preloading sprites")
-- Precargar imágenes de los sprites. ---------------------------------------------------
SPRITES = {
	MEGADRIVE = nil;
	MASTERSYSTEM = nil;
	GAMEGEAR = nil;
	FAMICOM = nil;
	GAMEBOY = nil;
	GAMEBOYCOLOR = nil;
	GAMEBOYADVANCE = nil;
	ATARI2600 = nil;
	ATARILYNX = nil;
	SEGASG1000 = nil;
	NEOGEOPOCKET = nil;
	SUPERFAMICOM = nil;
	APPS = nil;
	PLAYSTATION = nil;
	PLAYSTATION2 = nil;
	SPRITE_SYS = {"MEGADRIVE"; "MASTERSYSTEM"; "GAMEGEAR"; "FAMICOM"; "GAMEBOY"; "GAMEBOYCOLOR";
				"GAMEBOYADVANCE"; "ATARI2600"; "ATARILYNX"; "SEGASG1000"; "NEOGEOPOCKET";
				"SUPERFAMICOM"; "APPS"; "PLAYSTATION"; "PLAYSTATION2"};
	HEIGHT_Y = {45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45};
	WIDTH_X = {40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40};
	N_COLUMNS = {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4};
	N_ROWS = {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4};
	X = 0;
	Y = 0;
	ANI_FRAME = 0;
	FLIP = {0, 0};
	FONDO_ANI = false;
	FONDO_HEIGHT_Y = 640;
	FONDO_WIDTH_X = 448;
	FONDO_N_COLUMNS = 4;
	FONDO_N_ROWS = 4;
	FOND_X = 0;
	FOND_Y = 0;
	FONDO_ANI_FRAME = 0;
	LAYER = false;
	LAYER_TYPE = 0;
	LAYER_SPEED = 1;
	TRAN_TYPE = 0;
	TRAN_LEVEL = 1;
	TRAN_SPEED = 1;
	TRAN = {128, 128, 128, 128};
	TRAN_ALT = {false, false, false, false};
	SPIN_TYPE = 0;
	SPIN = 0;
	SPIN_SPEED = 1;
	LAYER_MULTI = 1;
	BACK_X = 0;
	BACK_Y = 0;
	LAYER_X_1 = 0;
	LAYER_X_2 = 0;
	LAYER_X_3 = 0;
	LAYER_X_4 = 0;
	LAYER_Y_1 = 0;
	LAYER_Y_2 = 0;
	LAYER_Y_3 = 0;
	LAYER_Y_4 = 0;
	ALTERNATE = false;
	ALTERNATE_R = false;
	ALTERNATE_T = false;
	ACTIVATE_ALTER_T = false;
	ANG = {0.00, 3.14};
	ZOOM = {0, false};
	MOVE = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	AUTO_MOVE_SPRITE = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	MOVE_X = 0;
	MOVE_Y = 0;
	MOVE_ALT_X = false;
	MOVE_ALT_Y = false;
	SPIN_SPRITE_ON = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	SPIN_SPRITE = 0.00;
	SPIN_SPRITE_ALT = false;
	TRAN_SPRITE_ON = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	TRAN_SPRITE = 128;
	TRAN_ALT_SPRITE = false;
	ANG_SPRITE = 0.00;
	ZOOM_SPRITE = {0, false};
	SPEED_SPRITE = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
};
TEML(true)

CARGA_PASO("defining colours")
-- Define colores básicos. --------------------------------------------------------------
COLOR = {
	BLANCO = Color.new(128, 128, 128);
	BLANCO_LISTA = Color.new(128, 128, 128);
	NEGRO = Color.new(0, 0, 0);
	GRIS = Color.new(70, 70, 70);
	NEGRO_T = Color.new(0, 0, 0, 85);
	BLANCO_T = Color.new(128, 128, 128, 20);
	CC_BACK = {0, 0, 0, 85};
};

CARGA_PASO("defining options")
-- Define opciones y configuraciones. ---------------------------------------------------
OPCIONES = {
	RGB_ON = 1;
	FONDO_RGB_ON = 1;
	FONDO_RGB_FIJO_ON = 0;
	R = 0;
	G = 80;
	B = 120;
	CAMBIO_FUENTE_ON = 1;
	FUENTES_ENCONTRADAS = {};
	CAMBIO_FONDO_ON = 1;
	FONDO_ENCONTRADOS = {};
	GUI_LIMPIA_ON = 0;
	APPS_MENU_FULL_PATH = 0;
	LIMITADOR_RAM_ON = 0;
	SALIDA_RETROLANCHER_ON = 0;
	SALIDA_RETROLANCHER = "PS2 SYSTEM MENU";
	SALIDA_DIR_ACTUALES = {};
	SALIDA_DIR_ANTERIORES = {};
	SOUND_ON = 0;
	SCREENSHOT_BACK_ON = 0;
	SCREENSHOT_BACK_TR = 128;
	SOUND_VOLUME = 65;
	VIDEO_MODE = 0;
	VIBRATION_ON = 0;
	VIBRATION = false;
	VIBRATION_MODE = nil;
	DIR_EXTRAS_ON = 1;
	PREGUNTAR_PS2 = false;
	LIBERAR_LISTAS = 0;
	FONT_PIXEL_X = 16;
	FONT_PIXEL_Y = 16;
	FONT_SHADOW = 5;
	SCROLL_MIN = 24;
	OPL_ELF = "mass:/RETROLauncher/OPL/OPNPS2LD.ELF";
	OPL_DIR = "DVD";
	SPRITE_ON = 0;
	SEE_INDEX = 0;
	COLOR_LISTA_B = 74;
	RUN_DEFAULT = 0
};

CARGA_PASO("defining emulator states")
-- Define el estado de los emuladores (Activado / Desactivado). -------------------------
SISTEMAS = {
	MEGADRIVE_ON = 1;
	MASTERSYSTEM_ON = 1;
	GAMEGEAR_ON = 1;
	FAMICOM_ON = 1;
	GAMEBOY_ON = 1;
	GAMEBOYCOLOR_ON = 1;
	GAMEBOYADVANCE_ON = 1;
	ATARI2600_ON = 1;
	ATARILYNX_ON = 1;
	SEGASG1000_ON = 1;
	NEOGEOPOCKET_ON = 1;
	SUPERFAMICOM_ON = 1;
	APPS_ON = 1;
	PLAYSTATION_ON = 1;
	PLAYSTATION2_ON = 1;
};

CARGA_PASO("loading fonts")
-- Define las variables usadas para la ejecución del programa. --------------------------
CONTROL = {
	ANCHO = 640;
	ALTO = 480;
	ALTO_F = 448;
	Y_FIX_PAL = 0;
	SELECTOR = 1;
	ESTILO = 1;
	JOYSTICK_ON = false;
	TIME = Timer.new();
	TIEMPO = 0;
	ESPERA_CARGA_SCR = false;
	PAUSA_SCR_TEX = 0;
	EXTENSION = 5;
	FPS = Screen.getFPS(1);
	LISTA_ANCHO = 30; LISTA_X = 310; LISTA_ALTO = 90; LISTA_Y = 290;
	IMG_ANCHO = 358; IMG_X = 250; IMG_ALTO = 92; IMG_Y = 193;
	IMG_ANCHO_2 = 358; IMG_X_2 = 250; IMG_ALTO_2 = 92; IMG_Y_2 = 193;
	FLOW_ANCHO = 15; FLOW_X = 160; FLOW_ALTO = 358; FLOW_Y = 103;
	FLOW_ANCHO_2 = 358; FLOW_X_2 = 250; FLOW_ALTO_2 = 92; FLOW_Y_2 = 250;
	LOGO_ANCHO = 194; LOGO_X = 252; LOGO_ALTO = 5; LOGO_Y = 76;
	X_BUTTON_X = 0; Y_BUTTON_X = 0;
	X_BUTTON_T = 0; Y_BUTTON_T = 0;
	X_BUTTON_S = 0; Y_BUTTON_S = 0;
	X_BUTTON_L1 = 0; Y_BUTTON_L1 = 0;
	X_BUTTON_R1 = 0; Y_BUTTON_R1 = 0;
	X_BUTTON_R3 = 0; Y_BUTTON_R3 = 0;
	X_BUTTON_STA = 0; Y_BUTTON_STA = 0;
	X_BUTTON_SEL = 0; Y_BUTTON_SEL = 0;
	CUSTOM_ANIM = 1;
	ANIM_VELOCIDAD = 29;
	CUSTOM_LIST = true;
	CUSTOM_ART1 = true;
	CUSTOM_ART2 = false;
	CUSTOM_FLOW = false;
	CUSTOM_LOGO = true;
	CUSTOM_BUTTON_X = true;
	CUSTOM_BUTTON_T = true;
	CUSTOM_BUTTON_S = true;
	CUSTOM_BUTTON_L1 = true;
	CUSTOM_BUTTON_R1 = true;
	CUSTOM_BUTTON_R3 = true;
	CUSTOM_BUTTON_STA = true;
	CUSTOM_BUTTON_SEL = true;
	CUSTOM_BACK = true;
	SPRITE_ANCHO = 30; SPRITE_X = 80; SPRITE_ALTO = 30; SPRITE_Y = 100;
	CUSTOM_SPRITE = false;
	Font.ftInit();
	fontARCA = Font.ftLoad("System/Medias/Font/PublicPixel.ttf");
	fontABC = Font.ftLoad("System/Medias/Font/PublicPixel.ttf");
	ACT_FONTABC = false;
};

CARGA_PASO("preparing list images")
-- Define las variables usadas para la ejecución de las listas. -------------------------
LISTAS = {
	FONDO = Graphics.loadImage(verif_img("System/Medias/Default/FONDO.png"));
	LOADING = Graphics.loadImage(verif_img("System/Medias/Default/LOADING.png"));
	COVER_DEFAULT = Graphics.loadImage(verif_img("System/Medias/Default/".. img_lang("COVER_DEFAULT", true) ..".png"));
	SCREENSHOT_DEFAULT = Graphics.loadImage(verif_img("System/Medias/Default/".. img_lang("SCREENSHOT_DEFAULT", false) ..".png"));
	LOGO = LOGOS.DEFAULT;
	IDENTIDAD = 1;
	INDICE = 1;
	INDICE2 = 1;
	INDICE3 = 1;
	ROMS = {};
	DIR_FULL_APP = {};
	MOSTRAR = 0;
	ART_LIMITE = 8;
	SCREENSHOT_ON = false;
	SCREENSHOT_FULL = false;
	COVER_ART = nil;
	COVER_DIR = " "; COVER_DIR_ALT = " ";
	COVER_ART2 = nil;
	COVER_DIR2 = " "; COVER_DIR2_ALT = " ";
	COVER_ART3 = nil;
	COVER_DIR3 = " "; COVER_DIR3_ALT = " ";
	SCREENSHOT = nil;
	SCREENSHOT_DIR = " "; SCREENSHOT_DIR_ALT = " ";
	SCROLL_TEX = 1;
	EXISTE_COV = false;
	EXISTE_SCR = false;
	EXISTE_COV2 = false;
	EXISTE_COV3 = false;
	COV_X = 250; COV_Y = 193; COV_FIX = 0; COV_FIX_Y = 0;
	SCR_X = 250; SCR_Y = 193; SCR_FIX = 0; SCR_FIX_Y = 0;
	SCR_ART2_X = 250; SCR_ART2_Y = 193; SCR_FIX_ART2 = 0; SCR_FIX_Y_ART2 = 0;
	COV_1_X = 160; COV_1_Y = 103; COV_1_FIX = 0; COV_1_FIX_Y = 0;
	COV_2_X = 160; COV_2_Y = 103; COV_2_FIX = 0; COV_2_FIX_Y = 0;
	EX_FIX_S = 0; EX_FIX_S_Y = 0;
	EX_FIX_C = 0; EX_FIX_C_Y = 0;
	ELEMENTOS_LIST = 11;
	ART_ZOOM = 2;
};

CARGA_PASO("defining system colours")
-- Define los colores usados para cada sistema. -----------------------------------------
CAMBIOS_EMUS = {
	COLOR_EMU = Color.new(0, 0, 0);
	COLOR_EMU_BACK = Color.new(0, 80, 120);
	COLOR_ACTUAL = 0;
	COLOR_MAX = 0;
	COLOR_MIN = 0;
	RGB_COLOR = 1;
	CAM_COLOR_ACTUAL = false;
	R = 0;
	G = 80;
	B = 120;
	TRAS = 74;
};

--- Cargar variables y configuraciones. -------------------------------------------------
CARGA_PASO("reading configuration")
cargar_config()

--- Ejecutar RETROLauncher. -------------------------------------------------------------
-- El valor con el que se entra al menu, para no volver a preguntarse si el
-- interruptor guarda o no: aqui queda escrito, junto con lo que dice su fichero.
boot_log("BOOT   SEE_INDEX = ".. tostring(OPCIONES.SEE_INDEX)
	.."   SeeIndex.cfg = ".. tostring(SEE_INDEX_LEER()))
CARGA_PASO("entering menu")
boot_log("BOOT   listas construidas, entrando en el menu")
boot_escribir()
CARGA_FIN()
while true do
	dibujar()
	refrescar(false)
	CONTROL.FPS = Screen.getFPS(1)
end
--[[------------------SPAGHETTICODE-------------------]]--