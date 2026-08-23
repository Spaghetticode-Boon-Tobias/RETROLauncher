--[[-----------------------------------------------------------------------------------
Pre-boot universal de RETROLauncher.

El script integrado en Enceladus ejecuta "System/index.lua" ANTES que
"System/system.lua". Este fichero es identico en todas las copias del programa
-instalacion completa en USB, instalacion completa en el disco interno, y el
mini-kit de la Memory Card- y decide en cada arranque cual instalacion gobierna.

Soportes cubiertos:
  USB FAT32 / USB exFAT   Enceladus los lee nativamente: se arranca aqui mismo.
  Memory Card             el mini-kit (ELF + este fichero + IRX) vive en mc0 y
                          encadena hacia la instalacion completa.
  Disco interno ATA exFAT Enceladus NO lo lee al arrancar (su pila BDM no
                          incluye ata_bd): imposible lanzar el ELF desde ahi.
                          Se llega via el mini-kit o via una instalacion USB.

Regla de eleccion de la instalacion que gobierna (PREFERIR_DISCO_INTERNO=true):
  1. el DISCO INTERNO, reconocido por su marcador
     "Roms/!Retrolauncher/internal-ata-disk.flag" - nunca por nombre de unidad.
     Se le esperan hasta 10 s (esta girando). Ajustes, partidas, VMC y journals
     viven en el; el USB solo arranca y aporta juegos secundarios.
  2. la LOCAL del soporte de arranque, si el disco no aparece;
  3. cualquier "massN:/RETROLauncher" completo, como ultimo recurso.

Todo queda en "RETROLauncher.log" junto al ELF, con la categoria PRE delante.
-------------------------------------------------------------------------------------]]

-- Capa de compatibilidad minima (identica a la de system.lua).
if FREAD   == nil and O_RDONLY ~= nil then FREAD   = O_RDONLY end
if FCREATE == nil and O_CREAT  ~= nil then FCREATE = O_RDWR | O_CREAT | O_TRUNC end
if SET == nil then SET = 0 end
if Sif == nil and IOP ~= nil then Sif = IOP end

local base = System.currentDirectory()

-- Un solo journal para todo el lanzador. Aqui se escribe ANTES que en system.lua, asi
-- que hay que conservar lo que hubiera: se lee una vez, se recorta por el principio y
-- pasa a ser el prefijo. system.lua hara lo mismo despues y encontrara estas lineas ya
-- dentro. Sin esto, el pre-boot vaciaria en cada encendido el historial de
-- lanzamientos, que es justo lo que hace falta cuando una prueba fallida devuelve el
-- control a uLaunchELF.
local RUTA_LOG = base .."/RETROLauncher.log"
local PREVIO = ""
pcall(function()
	if doesFileExist(RUTA_LOG) then
		local f = System.openFile(RUTA_LOG, FREAD)
		local tam = System.sizeFile(f)
		System.seekFile(f, 0, SET)
		local t = System.readFile(f, tam)
		System.closeFile(f)
		if t ~= nil then
			if string.len(t) > 24000 then
				t = "[...principio recortado...]\n".. string.sub(t, string.len(t) - 24000)
			end
			PREVIO = t
		end
	end
end)

local LOG = "\n--- pre-boot (System/index.lua) ---\n"

local function log(linea)
	LOG = LOG .. "PRE    " .. linea .. "\n"
	pcall(function()
		local f = System.openFile(RUTA_LOG, FCREATE)
		local t = PREVIO .. LOG
		System.writeFile(f, t, string.len(t))
		System.closeFile(f)
	end)
end

local MARCA = "/Roms/!Retrolauncher/internal-ata-disk.flag"

local function instalacion_completa(raiz)
	return doesFileExist(raiz .."/System/system.lua")
end

log("Soporte de arranque : ".. tostring(base))
log("Build de Enceladus  : ".. ((IOP ~= nil) and "2025+ (tabla IOP)" or "2024 (tabla Sif)"))

-- ¿El disco interno ya esta montado? Ocurre cuando el lanzador dejo ata_bd
-- residente, o en un rearranque en caliente. Cargarlo de nuevo seria fatal.
local disco_visible = false
for n = 0, 5 do
	if doesFileExist("mass".. n ..":/RETROLauncher".. MARCA) then disco_visible = true end
end

if IOP == nil then
	log("Build 2024: no se cargan IRX (Sif.loadModule cuelga en esta build).")
elseif disco_visible == true then
	log("El disco interno ya esta montado: no se recargan los IRX.")
else
	-- Cargar dev9 + ata_bd en la pila BDM de Enceladus. Orden obligatorio.
	for _i, nombre in ipairs({"dev9_ns.irx", "ata_bd.irx"}) do
		local ruta = base .."/IRX/".. nombre
		if doesFileExist(ruta) == false then
			log("-> ".. nombre .."  AUSENTE en IRX/, omitido")
		else
			log("-> ".. nombre)
			local ok, err = pcall(function()
				local fd = System.openFile(ruta, FREAD)
				local tam = System.sizeFile(fd)
				System.seekFile(fd, 0, SET)
				local datos = System.readFile(fd, tam)
				System.closeFile(fd)
				local id = IOP.loadModuleBuffer(datos, tam)
				LOG = LOG .."   ".. tostring(tam) .." bytes, ID = ".. tostring(id) .."\n"
			end)
			if ok == false then log("   ERROR: ".. tostring(err)) end
		end
	end
end

-- Politica de eleccion de la instalacion que gobierna.
--   true : el disco interno exFAT MANDA cuando esta presente. Ajustes, partidas,
--          VMC y journals viven en el; el USB queda como trampolin de arranque y
--          fuente secundaria de juegos. Se le dan hasta 10 segundos para girar.
--   false: comportamiento clasico, gobierna la instalacion local del arranque.
local PREFERIR_DISCO_INTERNO = true

local cible = nil
local local_ok = instalacion_completa(base)
log("Instalacion local completa: ".. tostring(local_ok))

if PREFERIR_DISCO_INTERNO then
	log("Politica: el disco interno gobierna si esta presente. Esperandolo...")
	local espera = local_ok and 10 or 20
	for intento = 1, espera do
		for n = 0, 5 do
			local raiz = "mass".. n ..":/RETROLauncher"
			if cible == nil and instalacion_completa(raiz) and doesFileExist(raiz .. MARCA) then
				cible = raiz
				log("Disco interno encontrado (intento ".. intento .."): ".. cible)
			end
		end
		if cible ~= nil then break end
		log("  intento ".. intento .."/".. espera ..", el disco aun no responde")
		if System.sleep ~= nil then System.sleep(1) end
	end
	if cible == nil then
		log("Disco interno ausente tras ".. espera .." s.")
	end
end

if cible == nil and local_ok then
	cible = base
	log("Gobierna la instalacion local: ".. cible)
end
if cible == nil then
	for n = 0, 5 do
		local raiz = "mass".. n ..":/RETROLauncher"
		if cible == nil and instalacion_completa(raiz) then
			cible = raiz
			log("Ultimo recurso, instalacion USB: ".. cible)
		end
	end
end

if cible == nil then
	log("")
	log("ERROR: ninguna instalacion completa encontrada, en ningun soporte.")
	log("Comprobar: el disco interno esta conectado y lleva el marcador en")
	log("Roms/!Retrolauncher/; o hay un RETROLauncher completo en un USB.")
	error("RETROLauncher: instalacion no encontrada (ver RETROLauncher.log)")
end

-- Estado compartido con system.lua: los IRX ya estan tratados aqui, y el
-- origen real del arranque queda registrado aunque se encadene a otro soporte.
PREBOOT_IRX_HECHO = true
PREBOOT_ORIGEN = base

if cible ~= base then
	System.currentDirectory(cible)
	log("currentDirectory   : ".. tostring(System.currentDirectory()))
end
log("Cediendo el control a ".. cible .."/System/system.lua")
dofile(cible .."/System/system.lua")
