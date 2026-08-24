--[[-----------------------------------------------------------------------------------
RETROBOOT/boot.lua - arranque directo desde el disco interno exFAT, sin llave USB.

Uso: el lanzador (OSDMenu, FMCB, OSD-XMB...) lanza el ELF del disco
   massX:/RETROLauncher/RETROLauncher.elf
con UN ARGUMENTO:
   mc0:/RETROBOOT/boot.lua

Por que hace falta: Enceladus, al arrancar, recarga su propia pila USB (sin
ata_bd) y el disco del que venia desaparece. Pero si recibe un argumento,
ejecuta ESE script en lugar de su boot integrado - y la Memory Card siempre es
legible. Este script (3 KB) carga los drivers del disco desde mc0:/RETROBOOT/
(24 KB), espera a que el disco gire, y le cede el control.

Todo queda en mc0:/RETROBOOT/BOOT_LOG.txt, linea a linea.
-------------------------------------------------------------------------------------]]

if FREAD   == nil and O_RDONLY ~= nil then FREAD   = O_RDONLY end
if FCREATE == nil and O_CREAT  ~= nil then FCREATE = O_RDWR | O_CREAT | O_TRUNC end
if SET == nil then SET = 0 end
if Sif == nil and IOP ~= nil then Sif = IOP end

-- Rutas ABSOLUTAS en todas partes: el directorio corriente (el disco) es ilegible aun.
local BASE = "mc0:/RETROBOOT"
local MARCA = "/Roms/!Retrolauncher/internal-ata-disk.flag"

local LOG = "RETROBOOT (mc0) - journal\n=========================\n\n"
local function log(linea)
	LOG = LOG .. linea .. "\n"
	pcall(function()
		local f = System.openFile(BASE .."/BOOT_LOG.txt", FCREATE)
		System.writeFile(f, LOG, string.len(LOG))
		System.closeFile(f)
	end)
end

log("Lanzado con argumento; directorio corriente: ".. tostring(System.currentDirectory()))

if IOP == nil then
	log("ERROR: build 2024 de Enceladus, sin IOP.loadModuleBuffer.")
	error("RETROBOOT: build de Enceladus demasiado antigua")
end

-- El disco puede estar ya montado si el lanzador dejo ata_bd residente.
local visible = false
for n = 0, 5 do
	if doesFileExist("mass".. n ..":/RETROLauncher".. MARCA) then visible = true end
end

if visible then
	log("El disco ya esta montado: no se cargan IRX.")
else
	for _i, nombre in ipairs({"dev9_ns.irx", "ata_bd.irx"}) do
		local ruta = BASE .."/".. nombre
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

log("Esperando el disco interno...")
local cible = nil
for intento = 1, 20 do
	for n = 0, 5 do
		local raiz = "mass".. n ..":/RETROLauncher"
		if cible == nil and doesFileExist(raiz .."/System/system.lua")
		   and doesFileExist(raiz .. MARCA) then
			cible = raiz
			log("Disco encontrado (intento ".. intento .."): ".. cible)
		end
	end
	if cible ~= nil then break end
	log("  intento ".. intento .."/20")
	if System.sleep ~= nil then System.sleep(1) end
end

if cible == nil then
	log("ERROR: el disco interno no ha aparecido. Ver conexion/alimentacion.")
	error("RETROBOOT: disco interno no encontrado (mc0:/RETROBOOT/BOOT_LOG.txt)")
end

PREBOOT_IRX_HECHO = true
PREBOOT_ORIGEN = BASE
System.currentDirectory(cible)
log("currentDirectory: ".. tostring(System.currentDirectory()))
log("Cediendo el control a ".. cible .."/System/system.lua")
dofile(cible .."/System/system.lua")
