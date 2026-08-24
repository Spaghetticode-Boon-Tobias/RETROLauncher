--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[------------------- v1.0/rev2 --------------------]]--

--[[Líneas para las funciones de RETROLauncher.]]--
--- Refrescar pantalla. -----------------------------------------------------------------
function refrescar(solo_audio)
	if solo_audio == false then
		Screen.flip()
	end
	if OPCIONES.LIMITADOR_RAM_ON == 1 then
		collectgarbage("collect")
	end
	if OPCIONES.SOUND_ON == 1 and S_MUSICA ~= nil then
		Sound.playADPCM(2, S_MUSICA)
	end
end

--- Dibuja los fondos de pantalla. ------------------------------------------------------
function dibujar_fondos()
	RGB(OPCIONES.RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON, CAMBIOS_EMUS.TRAS)
	Screen.clear(CAMBIOS_EMUS.COLOR_EMU_BACK)
	if OPCIONES.FONDO_RGB_ON == 1 and (OPCIONES.FONDO_RGB_FIJO_ON == 0 or (OPCIONES.FONDO_RGB_FIJO_ON == 1 and CAMBIOS_EMUS.TRAS == 0)) then
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, true, CAMBIOS_EMUS.COLOR_EMU_BACK)
		else
			Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, CAMBIOS_EMUS.COLOR_EMU_BACK)
		end
	elseif OPCIONES.FONDO_RGB_ON == 1 and OPCIONES.FONDO_RGB_FIJO_ON == 1 then
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, false, CAMBIOS_EMUS.COLOR_EMU_BACK)
		else
			Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F)
		end
		Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO_F, CAMBIOS_EMUS.COLOR_EMU_BACK)
	else
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, false, CAMBIOS_EMUS.COLOR_EMU_BACK)
		else
			Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F)
		end
	end
end

--- Controla los tiempos de captura y pausa para los controles. -------------------------
function capturar(limite)
	if CONTROL.JOYSTICK_ON == false or limite >= CONTROL.FPS//3 then
		PAD = Pads.get(0)
		Left_X, Left_Y = Pads.getLeftStick(0)
		JOYSTICK_LIMITE = 0
		CONTROL.JOYSTICK_ON = false
		if CONTROL.ACT_FONTABC == true then
			CONTROL.ACT_FONTABC = false
		end
		Pads.rumble(0, 0, 0)
		OPCIONES.VIBRATION = false
		OPCIONES.VIBRATION_MODE = nil
	end
	if CONTROL.JOYSTICK_ON == true then
		PAD = 0
		Left_X, Left_Y = 1, 1
		JOYSTICK_LIMITE = JOYSTICK_LIMITE+1
		if OPCIONES.VIBRATION_ON == 1 and OPCIONES.VIBRATION == true and limite <= -4 then
			local shake_left, shake_rigth = 80, 80
			if OPCIONES.VIBRATION_MODE == true then
				shake_left, shake_rigth = 90, 80
			elseif OPCIONES.VIBRATION_MODE == false then
				shake_left, shake_rigth = 80, 90
			end
			Pads.rumble(0, shake_left, shake_rigth)
		else
			Pads.rumble(0, 0, 0)
		end
	end
end

--- La palanca esta REALMENTE movida. ---------------------------------------------------
--- En varios sitios se pregunta "Left_Y ~= 1" para saber si el usuario ha tocado la
--- palanca. Ese 1 viene de capturar(), que hace "Left_X, Left_Y = 1, 1" cuando la
--- lectura ya se ha consumido; es un centinela, no la posicion de reposo.
---
--- La posicion de reposo es 0. Todo el programa lo da por hecho -- compara siempre
--- contra -90 y 90 --, asi que "~= 1" es CIERTO con la palanca quieta, y es cierto en
--- todos los fotogramas.
---
--- Donde eso solo elegia la velocidad de repeticion no se notaba. Donde abre una rama
--- de un "elseif", se lleva por delante todo lo que viene detras: en el submenu de
--- elementos del editor de temas, la rama de "moverse" se disparaba sola en cada
--- fotograma -- de ahi el sonido de seleccion sin fin -- y CRUZ y R1 no llegaban nunca
--- a sus ramas, de ahi que no se pudiera encender ni apagar nada.
function PALANCA(valor)
	if valor == nil then return false end
	return valor <= -90 or valor >= 90
end

--- Cambia los tiempos de captura de los controles, de acuerdo a los FPS. ---------------
function control_FPS(vel)
	CONTROL.JOYSTICK_ON = true
	if vel == 1 then
		return 0-CONTROL.FPS//3
	elseif vel == 2 then
		if CONTROL.FPS <= 3 then
			return CONTROL.FPS
		elseif CONTROL.FPS <= 8 then
			return 0+CONTROL.FPS//3
		elseif CONTROL.FPS >= 9 then
			return CONTROL.FPS//4
		end
	end
end

--- Controlar la reproducción de sonidos y vibración al realizar movimientos. -----------
function repro_sfx(sonido, canal, vibrar, lado_vibrar)
	if OPCIONES.SOUND_ON == 1 and sonido ~= nil then
		-- La voz sale del sonido, no del numero que se pasa aqui: los 166 sitios que
		-- llaman a esta funcion pasan "1", y una sola voz no puede reproducir dos
		-- sonidos a la vez. Ver SFX_CANALES en system.lua.
		Sound.playADPCM(SFX_VOZ(sonido, canal), sonido)
	end
	OPCIONES.VIBRATION = vibrar
	OPCIONES.VIBRATION_MODE = lado_vibrar
end

--- Controla el zoom sobre el arte. -----------------------------------------------------
function zoom(multiplicador, ratio_x, ratio_y)
	local Right_X, Right_Y = Pads.getRightStick(0)
	if Right_Y <= -1 then
		Right_Y = -Right_Y
	elseif Right_Y == 1 then
		Right_Y = 0
	end
	if Right_X == 1 then
		Right_X = 0
	end
	local Right_XY = (Right_Y*multiplicador)//2
	if ratio_y ~= 0 then
		Right_XY = (Right_XY*ratio_x)//ratio_y
	end
	return (Right_X*multiplicador)//2, (Right_Y*multiplicador)//2, Right_XY
end

--- Retarda la carga de imágenes. -------------------------------------------------------
function tiempo_arte()
	if LISTAS.MOSTRAR <= LISTAS.ART_LIMITE+1 then
		LISTAS.MOSTRAR = LISTAS.MOSTRAR+1
	else
		LISTAS.MOSTRAR = LISTAS.ART_LIMITE+2
	end
end

--- Cambia los índices de las imágenes extra. -------------------------------------------
function indices_extras()
	if LISTAS.INDICE >= 2 then
		LISTAS.INDICE2 = LISTAS.INDICE-1
	else
		LISTAS.INDICE2 = #LISTAS.ROMS
	end
	if LISTAS.INDICE <= #LISTAS.ROMS-1 then
		LISTAS.INDICE3 = LISTAS.INDICE+1
	else
		LISTAS.INDICE3 = 1
	end
end

--- Libera las imágenes de memoria. -----------------------------------------------------
function limpiar_art()
	if LISTAS.COVER_ART ~= nil then
		Graphics.freeImage(LISTAS.COVER_ART)
		LISTAS.COVER_ART = nil
	end
	if LISTAS.SCREENSHOT ~= nil then
		Graphics.freeImage(LISTAS.SCREENSHOT)
		LISTAS.SCREENSHOT = nil
	end
	if LISTAS.COVER_ART2 ~= nil then
		Graphics.freeImage(LISTAS.COVER_ART2)
		LISTAS.COVER_ART2 = nil
	end
	if LISTAS.COVER_ART3 ~= nil then
		Graphics.freeImage(LISTAS.COVER_ART3)
		LISTAS.COVER_ART3 = nil
	end
	LISTAS.COVER_DIR = " "; LISTAS.COVER_DIR_ALT = " "; LISTAS.SCREENSHOT_DIR = " "; LISTAS.SCREENSHOT_DIR_ALT = " ";
	LISTAS.COVER_DIR2 = " "; LISTAS.COVER_DIR2_ALT = " "; LISTAS.COVER_DIR3 = " "; LISTAS.COVER_DIR3_ALT = " ";
end

--- Buscar y cargar imágenes en memoria. ------------------------------------------------
function cargar_art()
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local nombre = string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, -CONTROL.EXTENSION)
	local nombre2 = " "
	local nombre3 = " "
	if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
		nombre2 = string.sub(LISTAS.ROMS[LISTAS.INDICE2], 1, -CONTROL.EXTENSION)
		nombre3 = string.sub(LISTAS.ROMS[LISTAS.INDICE3], 1, -CONTROL.EXTENSION)
	end

	-- Generar ubicaciones para la búsqueda. --------------------------------------------
	local sistemas_nombre = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear"; "Nintendo Famicom"; "Nintendo Game Boy";
	"Nintendo Game Boy Color"; "Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "Neo Geo Pocket";
	"Nintendo Super Famicom"; "APPS"; "PlayStation"; "PlayStation 2";};
	if LISTAS.MOSTRAR == 1 and (LISTAS.IDENTIDAD >= 1 and LISTAS.IDENTIDAD <= 15) then
		if OPCIONES.APPS_MENU_FULL_PATH == 1 and LISTAS.IDENTIDAD == 12 then
			nombre = salida_texto_dir(string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, -CONTROL.EXTENSION), true)
			if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
				nombre2 = salida_texto_dir(string.sub(LISTAS.ROMS[LISTAS.INDICE2], 1, -CONTROL.EXTENSION), true)
				nombre3 = salida_texto_dir(string.sub(LISTAS.ROMS[LISTAS.INDICE3], 1, -CONTROL.EXTENSION), true)
			end
		end

		-- Ubicaciones para covers, screenshot y covers flow. ---------------------------
		if CONTROL.CUSTOM_ART1 == true then
			LISTAS.COVER_DIR = RUTA_MEDIA("cover", LISTAS.IDENTIDAD, sistemas_nombre[LISTAS.IDENTIDAD], LISTAS.ROMS[LISTAS.INDICE], nombre)
			LISTAS.SCREENSHOT_DIR = RUTA_MEDIA("screenshot", LISTAS.IDENTIDAD, sistemas_nombre[LISTAS.IDENTIDAD], LISTAS.ROMS[LISTAS.INDICE], nombre)
		end
		if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
			LISTAS.COVER_DIR2 = RUTA_MEDIA("cover", LISTAS.IDENTIDAD, sistemas_nombre[LISTAS.IDENTIDAD], LISTAS.ROMS[LISTAS.INDICE2], nombre2)
			LISTAS.COVER_DIR3 = RUTA_MEDIA("cover", LISTAS.IDENTIDAD, sistemas_nombre[LISTAS.IDENTIDAD], LISTAS.ROMS[LISTAS.INDICE3], nombre3)
		end

		-- Ubicaciones para la carpeta "ART". -------------------------------------------
		if LISTAS.IDENTIDAD == 13 or LISTAS.IDENTIDAD == 14 then
			if LISTAS.IDENTIDAD == 14 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
				nombre = "XX.".. nombre
			end
			if CONTROL.CUSTOM_ART1 == true then
				LISTAS.COVER_DIR_ALT = RUTA_ART(nombre ..".elf_COV.png")
				LISTAS.SCREENSHOT_DIR_ALT = RUTA_ART(nombre ..".elf_SCR.png")
			end
			if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
				if LISTAS.IDENTIDAD == 14 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE2], -4)) ~= ".elf" then
					nombre2 = "XX.".. nombre2
				end
				if LISTAS.IDENTIDAD == 14 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE3], -4)) ~= ".elf" then
					nombre3 = "XX.".. nombre3
				end
				LISTAS.COVER_DIR2_ALT = RUTA_ART(nombre2 ..".elf_COV.png")
				LISTAS.COVER_DIR3_ALT = RUTA_ART(nombre3 ..".elf_COV.png")
			end
		elseif LISTAS.IDENTIDAD == 15 then
			if CONTROL.CUSTOM_ART1 == true then
				LISTAS.COVER_DIR_ALT = RUTA_ART(string.sub(nombre, 1, 11) .."_COV.png")
				LISTAS.SCREENSHOT_DIR_ALT = RUTA_ART(string.sub(nombre, 1, 11) .."_SCR.png")
			end
			if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
				LISTAS.COVER_DIR2_ALT = RUTA_ART(string.sub(nombre2, 1, 11) .."_COV.png")
				LISTAS.COVER_DIR3_ALT = RUTA_ART(string.sub(nombre3, 1, 11) .."_COV.png")
			end
		end
	end

	-- Realizar la búsqueda y carga de imágenes. ----------------------------------------
	if LISTAS.MOSTRAR == LISTAS.ART_LIMITE then
		Pads.rumble(0, 0, 0)
		-- Carga de covers. -------------------------------------------------------------
		if doesFileExist(LISTAS.COVER_DIR) then
			log_art("cover  cargando", LISTAS.COVER_DIR)
			LISTAS.COVER_ART = Graphics.loadImage(LISTAS.COVER_DIR)
			log_art("cover  ok       ", LISTAS.COVER_DIR)
			LISTAS.EXISTE_COV = true
		elseif LISTAS.IDENTIDAD >= 13 and LISTAS.IDENTIDAD <= 15 and doesFileExist(LISTAS.COVER_DIR_ALT) then
			log_art("cover  cargando", LISTAS.COVER_DIR_ALT)
			LISTAS.COVER_ART = Graphics.loadImage(LISTAS.COVER_DIR_ALT)
			log_art("cover  ok       ", LISTAS.COVER_DIR_ALT)
			LISTAS.EXISTE_COV = true
		else
			LISTAS.COVER_ART = nil
			LISTAS.EXISTE_COV = false
		end

		-- Carga de screenshot. ---------------------------------------------------------
		if doesFileExist(LISTAS.SCREENSHOT_DIR) then
			log_art("screen cargando", LISTAS.SCREENSHOT_DIR)
			LISTAS.SCREENSHOT = Graphics.loadImage(LISTAS.SCREENSHOT_DIR)
			log_art("screen ok      ", LISTAS.SCREENSHOT_DIR)
			LISTAS.EXISTE_SCR = true
		elseif LISTAS.IDENTIDAD >= 13 and LISTAS.IDENTIDAD <= 15 and doesFileExist(LISTAS.SCREENSHOT_DIR_ALT) then
			log_art("screen cargando", LISTAS.SCREENSHOT_DIR_ALT)
			LISTAS.SCREENSHOT = Graphics.loadImage(LISTAS.SCREENSHOT_DIR_ALT)
			log_art("screen ok      ", LISTAS.SCREENSHOT_DIR_ALT)
			LISTAS.EXISTE_SCR = true
		else
			LISTAS.SCREENSHOT = nil
			LISTAS.EXISTE_SCR = false
		end

		-- Carga de covers flow. --------------------------------------------------------
		if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
			if doesFileExist(LISTAS.COVER_DIR2) then
				LISTAS.COVER_ART2 = Graphics.loadImage(LISTAS.COVER_DIR2)
				LISTAS.EXISTE_COV2 = true
			elseif LISTAS.IDENTIDAD >= 13 and LISTAS.IDENTIDAD <= 15 and doesFileExist(LISTAS.COVER_DIR2_ALT) then
				LISTAS.COVER_ART2 = Graphics.loadImage(LISTAS.COVER_DIR2_ALT)
				LISTAS.EXISTE_COV2 = true
			else
				LISTAS.COVER_ART2 = nil
				LISTAS.EXISTE_COV2 = false
			end
			if doesFileExist(LISTAS.COVER_DIR3) then
				LISTAS.COVER_ART3 = Graphics.loadImage(LISTAS.COVER_DIR3)
				LISTAS.EXISTE_COV3 = true
			elseif LISTAS.IDENTIDAD >= 13 and LISTAS.IDENTIDAD <= 15 and doesFileExist(LISTAS.COVER_DIR3_ALT) then
				LISTAS.COVER_ART3 = Graphics.loadImage(LISTAS.COVER_DIR3_ALT)
				LISTAS.EXISTE_COV3 = true
			else
				LISTAS.COVER_ART3 = nil
				LISTAS.EXISTE_COV3 = false
			end
		end
	end
	ajustar_art()
end

--- Corrige la relación de aspecto y centra las imágenes. -------------------------------
function ajustar_art()
	-- Realizar cálculos para corregir la relación de aspecto. --------------------------
	local function fix_art_edit(tama_x, tama_y, x, y, full_art)
		local x_prin, y_prin, x_fix, y_fix, full_x_fix, full_y_fix = tama_x, tama_y, 0, 0, 570, 390
		local eiuqal, ymot = (tama_y*x)/y, (tama_x*y)/x
		if eiuqal <= tama_x then
			x_prin, y_prin, x_fix, y_fix = eiuqal, tama_y, (tama_x-eiuqal)//2, 0
		elseif ymot <= tama_y then
			x_prin, y_prin, x_fix, y_fix = tama_x, ymot, 0, (tama_y-ymot)//2
		end
		if full_art == true then
			if (390*x)/y <= 570 then
				full_x_fix, full_y_fix = (390*x)/y, 390
			elseif (570*y)/x <= 390 then
				full_x_fix, full_y_fix = 570, (570*y)/x
			end
			return x_prin, y_prin, x_fix, y_fix, full_x_fix, full_y_fix
		else
			return x_prin, y_prin, x_fix, y_fix
		end
	end

	-- Relación de aspecto para cover. --------------------------------------------------
	if CONTROL.CUSTOM_ART1 == true then
		local x = Graphics.getImageWidth(LISTAS.COVER_DEFAULT)
		local y = Graphics.getImageHeight(LISTAS.COVER_DEFAULT)
		if LISTAS.COVER_ART ~= nil and LISTAS.EXISTE_COV == true then
			x = Graphics.getImageWidth(LISTAS.COVER_ART)
			y = Graphics.getImageHeight(LISTAS.COVER_ART)
		end
		LISTAS.COV_X, LISTAS.COV_Y, LISTAS.COV_FIX, LISTAS.COV_FIX_Y, LISTAS.EX_FIX_C, LISTAS.EX_FIX_C_Y = fix_art_edit(CONTROL.IMG_X, CONTROL.IMG_Y, x, y, true)
	end

	-- Relación de aspecto para screenshot. ---------------------------------------------
	if CONTROL.CUSTOM_ART1 == true or CONTROL.CUSTOM_ART2 == true then
		local x = Graphics.getImageWidth(LISTAS.SCREENSHOT_DEFAULT)
		local y = Graphics.getImageHeight(LISTAS.SCREENSHOT_DEFAULT)
		if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true then
			x = Graphics.getImageWidth(LISTAS.SCREENSHOT)
			y = Graphics.getImageHeight(LISTAS.SCREENSHOT)
		end
		LISTAS.SCR_X, LISTAS.SCR_Y, LISTAS.SCR_FIX, LISTAS.SCR_FIX_Y, LISTAS.EX_FIX_S, LISTAS.EX_FIX_S_Y = fix_art_edit(CONTROL.IMG_X, CONTROL.IMG_Y, x, y, true)
		LISTAS.SCR_ART2_X, LISTAS.SCR_ART2_Y, LISTAS.SCR_FIX_ART2, LISTAS.SCR_FIX_Y_ART2 = fix_art_edit(CONTROL.IMG_X_2, CONTROL.IMG_Y_2, x, y, false)
	end

	-- Relación de aspecto para cover flow. ---------------------------------------------
	if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
		-- Relación de aspecto para cover flow 1. ---------------------------------------
		local x = Graphics.getImageWidth(LISTAS.COVER_DEFAULT)
		local y = Graphics.getImageHeight(LISTAS.COVER_DEFAULT)
		if LISTAS.COVER_ART2 ~= nil and LISTAS.EXISTE_COV2 == true then
			x = Graphics.getImageWidth(LISTAS.COVER_ART2)
			y = Graphics.getImageHeight(LISTAS.COVER_ART2)
		end
		LISTAS.COV_1_X, LISTAS.COV_1_Y, LISTAS.COV_1_FIX, LISTAS.COV_1_FIX_Y = fix_art_edit(CONTROL.FLOW_X, CONTROL.FLOW_Y, x, y, false)

		-- Relación de aspecto para cover flow 2. ---------------------------------------
		local x2 = Graphics.getImageWidth(LISTAS.COVER_DEFAULT)
		local y2 = Graphics.getImageHeight(LISTAS.COVER_DEFAULT)
		if LISTAS.COVER_ART3 ~= nil and LISTAS.EXISTE_COV3 == true then
			x2 = Graphics.getImageWidth(LISTAS.COVER_ART3)
			y2 = Graphics.getImageHeight(LISTAS.COVER_ART3)
		end
		LISTAS.COV_2_X, LISTAS.COV_2_Y, LISTAS.COV_2_FIX, LISTAS.COV_2_FIX_Y = fix_art_edit(CONTROL.FLOW_X_2, CONTROL.FLOW_Y_2, x2, y2, false)
	end
end

--- Dibuja el arte en pantalla. ---------------------------------------------------------
function dibujar_arte(img_juego, existe, img_default, pos_x, pos_y, img_ancho, img_alto, asp_x, asp_y, asp_fix_x, asp_fix_y, act_zoom)
	if img_juego ~= nil and existe == true then
		local Right_X, Right_Y, Right_XY = 0, 0, 0
		if act_zoom == true then
			Right_X, Right_Y, Right_XY = zoom(LISTAS.ART_ZOOM, asp_x, asp_y)
		end
		if CONTROL.CUSTOM_BACK == true and act_zoom ~= nil then
			Graphics.drawRect(pos_x-5-(Right_XY//2)-(Right_X//2), pos_y-5-(Right_Y//2), img_ancho+10+Right_XY, img_alto+10+Right_Y, COLOR.NEGRO_T)
		end
		Graphics.drawScaleImage(img_juego, pos_x+asp_fix_x-(Right_XY//2)-(Right_X//2), pos_y+asp_fix_y-(Right_Y//2), asp_x+Right_XY, asp_y+Right_Y)
	else
		if CONTROL.CUSTOM_BACK == true and act_zoom ~= nil then
			Graphics.drawRect(pos_x-5, pos_y-5, img_ancho+10, img_alto+10, COLOR.NEGRO_T)
		end
		if LISTAS.MOSTRAR <= LISTAS.ART_LIMITE then
			local texto_m = TEXT_M_PRI[1]
			if img_ancho <= 214 and img_ancho >= 135 then texto_m = TEXT_M_PRI[13]
			elseif img_ancho <= 134 then texto_m = " " end
			Font.ftPrint(CONTROL.fontARCA, pos_x+(img_ancho//2), pos_y+(img_alto//2)-20, 8, img_ancho, img_alto, texto_m, COLOR.BLANCO)
		else
			if OPCIONES.FONDO_RGB_FIJO_ON == 1 and CAMBIOS_EMUS.TRAS ~= 0 then
				Graphics.drawScaleImage(img_default, pos_x+asp_fix_x, pos_y+asp_fix_y, asp_x, asp_y)
				if CONTROL.CUSTOM_BACK == true then
					Graphics.drawRect(pos_x, pos_y, img_ancho, img_alto, CAMBIOS_EMUS.COLOR_EMU_BACK)
				end
			else
				Graphics.drawScaleImage(img_default, pos_x+asp_fix_x, pos_y+asp_fix_y, asp_x, asp_y, CAMBIOS_EMUS.COLOR_EMU_BACK)
			end
		end
	end
end

--- Calcular sombras tras los textos. ---------------------------------------------------
function calcular_sombras(texto)
	local result = (OPCIONES.FONT_SHADOW*OPCIONES.FONT_PIXEL_X*(string.len(texto)/2)/3)
	return result
end

--- Dibujar indicadores en pantalla. ----------------------------------------------------
function dibujar_indicador(pos_x, pos_y, texto, img_boton, img_size_x, img_size_y, fix, sombra)
	local fix_x, fix_y, color = {30, 36, 27, 27, 25}, {3, 6, 0, 7, 0}, COLOR.BLANCO
	if fix >= 6 then
		fix = fix-5
		color = CAMBIOS_EMUS.COLOR_EMU
	end
	if sombra == true then
		Graphics.drawRect(pos_x, pos_y+CONTROL.Y_FIX_PAL, calcular_sombras(texto), 20, COLOR.NEGRO_T)
	end
	Graphics.drawScaleImage(img_boton, pos_x-fix_x[fix], pos_y-fix_y[fix]+CONTROL.Y_FIX_PAL, img_size_x, img_size_y)
	Font.ftPrint(CONTROL.fontARCA, pos_x+3, pos_y+1+CONTROL.Y_FIX_PAL, 0, 0, 25, texto, color)
end

--- Saltar de carácter en las listas. ---------------------------------------------------
function letter_breaks(inicial, pos, lado)
	local inicial_act = string.lower(string.sub(inicial, 1, 1))
	if (LISTAS.IDENTIDAD == 14 or LISTAS.IDENTIDAD == 15) and string.match(inicial, "%a+_%d+%.%d+%.") then
		inicial_act = string.lower(string.sub(inicial, 13, 13))
	end
	local inicio_bus, final_bus, minimo_bus = #LISTAS.ROMS, 1, 1
	if lado == false then
		inicio_bus, final_bus, minimo_bus = 1, -1, #LISTAS.ROMS
	end
	for n = pos, inicio_bus, final_bus do
		if (LISTAS.IDENTIDAD == 14 or LISTAS.IDENTIDAD == 15) and string.match(LISTAS.ROMS[n], "%a+_%d+%.%d+%.") then
			if string.lower(string.sub(LISTAS.ROMS[n], 13, 13)) ~= inicial_act or n == inicio_bus then
				pos = n
				if n == inicio_bus then
					pos = minimo_bus
				end
				return pos
			end
		elseif string.lower(string.sub(LISTAS.ROMS[n], 1, 1)) ~= inicial_act or n == inicio_bus then
			pos = n
			if n == inicio_bus then
				pos = minimo_bus
			end
			return pos
		end
	end
end

--- Controlar el cambio entre sistemas activados y desactivados. ------------------------
--- Salta directamente a un sistema concreto (usado por la rejilla). -------------------
function ir_a_sistema(id)
	if id == nil or id == LISTAS.IDENTIDAD then return end
	if OPCIONES.LIBERAR_LISTAS == 1 then
		PRE_CARGADAS[LISTAS.IDENTIDAD] = {}
	end
	LISTAS.IDENTIDAD = id
	LISTAS.ROMS = nil
	if OPCIONES.LIBERAR_LISTAS == 1 then
		recargar_una(LISTAS.IDENTIDAD)
	end
	LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
	indices_extras()
	rest_sprites(CONTROL.CUSTOM_SPRITE)
	if LISTAS.ROMS ~= nil and LAST_MOVE[LISTAS.IDENTIDAD] <= #LISTAS.ROMS then
		LISTAS.INDICE = LAST_MOVE[LISTAS.IDENTIDAD]
	else
		LISTAS.INDICE = 1
		LAST_MOVE[LISTAS.IDENTIDAD] = 1
	end
end

--- Rejilla de seleccion de sistema (L1+R1). Devuelve la identidad o nil. -------------
--- Solo muestra los sistemas activados en SISTEMAS.*_ON, con su logo.
function selector_sistemas(fondos)
	local claves = {"MEGADRIVE", "MASTERSYSTEM", "GAMEGEAR", "FAMICOM", "GAMEBOY", "GAMEBOYCOLOR",
		"GAMEBOYADVANCE", "ATARI2600", "ATARILYNX", "SEGASG1000", "NEOGEOPOCKET", "SUPERFAMICOM",
		"APPS", "PLAYSTATION", "PLAYSTATION2"}
	local nombres = {"Sega Megadrive", "Sega Master System", "Sega Game Gear", "Nintendo Famicom",
		"Nintendo Game Boy", "Nintendo Game Boy Color", "Nintendo Game Boy Advance", "Atari 2600",
		"Atari Lynx", "Sega SG-1000", "Neo Geo Pocket", "Nintendo Super Famicom",
		"APPS", "PlayStation", "PlayStation 2"}
	local activos = {SISTEMAS.MEGADRIVE_ON, SISTEMAS.MASTERSYSTEM_ON, SISTEMAS.GAMEGEAR_ON,
		SISTEMAS.FAMICOM_ON, SISTEMAS.GAMEBOY_ON, SISTEMAS.GAMEBOYCOLOR_ON, SISTEMAS.GAMEBOYADVANCE_ON,
		SISTEMAS.ATARI2600_ON, SISTEMAS.ATARILYNX_ON, SISTEMAS.SEGASG1000_ON, SISTEMAS.NEOGEOPOCKET_ON,
		SISTEMAS.SUPERFAMICOM_ON, SISTEMAS.APPS_ON, SISTEMAS.PLAYSTATION_ON, SISTEMAS.PLAYSTATION2_ON}

	local lista = {}
	for i = 1, 15 do
		if activos[i] == 1 then table.insert(lista, i) end
	end
	if #lista == 0 then return nil end

	-- Posicionarse sobre el sistema actual. ------------------------------------------
	local sel = 1
	for i = 1, #lista do
		if lista[i] == LISTAS.IDENTIDAD then sel = i end
	end

	local COLS, CW, CH, GX, GY = 5, 118, 86, 6, 8
	local X0 = (640 - (COLS*CW + (COLS-1)*GX)) // 2
	local Y0 = 78 + CONTROL.Y_FIX_PAL
	local elegido, abierto = nil, true
	JOYSTICK_LIMITE = control_FPS(1)-20

	while abierto do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		fondos()

		Graphics.drawRect(10, 16+CONTROL.Y_FIX_PAL, 619, 419, COLOR.NEGRO_T)
		Graphics.drawRect(-5, 22+CONTROL.Y_FIX_PAL, 650, 25, COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, 320, 28+CONTROL.Y_FIX_PAL, 8, 600, 25, "SELECT SYSTEM", COLOR.BLANCO)

		for i = 1, #lista do
			local col = (i-1) % COLS
			local fila = (i-1) // COLS
			local x = X0 + col*(CW+GX)
			local y = Y0 + fila*(CH+GY)
			if i == sel then
				Graphics.drawRect(x-3, y-3, CW+6, CH+6, CAMBIOS_EMUS.COLOR_EMU)
			end
			Graphics.drawRect(x, y, CW, CH, COLOR.NEGRO)
			local img = LOGOS[claves[lista[i]]]
			if img ~= nil then
				Graphics.drawScaleImage(img, x+5, y+5, CW-10, CH-10)
			end
		end

		Graphics.drawRect(-5, 394+CONTROL.Y_FIX_PAL, 650, 26, COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, 320, 400+CONTROL.Y_FIX_PAL, 8, 620, 25, nombres[lista[sel]], COLOR.BLANCO_LISTA)
		refrescar(false)

		if CONTROL.JOYSTICK_ON == false then
			if Pads.check(PAD, PAD_CROSS) then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				elegido, abierto = lista[sel], false
				-- Bloquear el pad al salir: sin esto, la misma pulsacion de CRUZ se
				-- propaga al menu principal y lanza el juego seleccionado.
				JOYSTICK_LIMITE = control_FPS(1)-40
			elseif Pads.check(PAD, PAD_TRIANGLE) then
				repro_sfx(S_CANCELAR, 1, false, nil)
				abierto = false
				JOYSTICK_LIMITE = control_FPS(1)-40
			elseif Pads.check(PAD, PAD_LEFT) or Left_X <= -90 then
				repro_sfx(S_MOVER, 1, false, nil)
				sel = cambiar_valor(sel, 1, #lista, 1, false)
				JOYSTICK_LIMITE = control_FPS(1)-6
			elseif Pads.check(PAD, PAD_RIGHT) or Left_X >= 90 then
				repro_sfx(S_MOVER, 1, false, nil)
				sel = cambiar_valor(sel, 1, #lista, 1, true)
				JOYSTICK_LIMITE = control_FPS(1)-6
			elseif Pads.check(PAD, PAD_UP) or Left_Y <= -90 then
				repro_sfx(S_MOVER, 1, false, nil)
				if sel - COLS >= 1 then sel = sel - COLS end
				JOYSTICK_LIMITE = control_FPS(1)-6
			elseif Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 then
				repro_sfx(S_MOVER, 1, false, nil)
				if sel + COLS <= #lista then sel = sel + COLS end
				JOYSTICK_LIMITE = control_FPS(1)-6
			end
		end
	end
	return elegido
end

function desactivados(lado)
	local buscar = true
	local sistemas_on = {SISTEMAS.MEGADRIVE_ON; SISTEMAS.MASTERSYSTEM_ON; SISTEMAS.GAMEGEAR_ON; SISTEMAS.FAMICOM_ON; SISTEMAS.GAMEBOY_ON;
	SISTEMAS.GAMEBOYCOLOR_ON; SISTEMAS.GAMEBOYADVANCE_ON; SISTEMAS.ATARI2600_ON; SISTEMAS.ATARILYNX_ON; SISTEMAS.SEGASG1000_ON;
	SISTEMAS.NEOGEOPOCKET_ON; SISTEMAS.SUPERFAMICOM_ON; SISTEMAS.APPS_ON; SISTEMAS.PLAYSTATION_ON; SISTEMAS.PLAYSTATION2_ON;};
	if OPCIONES.LIBERAR_LISTAS == 1 then
		PRE_CARGADAS[LISTAS.IDENTIDAD] = {}
	end
	while buscar do
		if lado == true then
			LISTAS.IDENTIDAD = cambiar_valor(LISTAS.IDENTIDAD, 1, #PRE_CARGADAS, 1, false)
		elseif lado == false then
			LISTAS.IDENTIDAD = cambiar_valor(LISTAS.IDENTIDAD, 1, #PRE_CARGADAS, 1, true)
		end
		if sistemas_on[LISTAS.IDENTIDAD] == 1 then
			buscar = false
		elseif lado == nil then
			LISTAS.INDICE = 1
			lado = false
		end
	end
	LISTAS.ROMS = nil
	if OPCIONES.LIBERAR_LISTAS == 1 then
		recargar_una(LISTAS.IDENTIDAD)
	end
	LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
	indices_extras()
	rest_sprites(CONTROL.CUSTOM_SPRITE)
end

--- Restaurar posiciones y valores de sprites. ------------------------------------------
function rest_sprites(custom)
	SPRITES.X = 0
	SPRITES.Y = 0
	SPRITES.ANI_FRAME = 0
	if custom == true then
		SPRITES.MOVE_X, SPRITES.MOVE_Y = CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO
		SPRITES.TRAN_ALT_SPRITE, SPRITES.MOVE_ALT_X, SPRITES.MOVE_ALT_Y = false, false, false
		SPRITES.SPIN_SPRITE, SPRITES.ANG_SPRITE = 0.00, 0.00
		SPRITES.TRAN_SPRITE, SPRITES.ZOOM_SPRITE, SPRITES.SPIN_SPRITE_ALT = 128, {0, false}, false
		SPRITES.FLIP[1], SPRITES.FLIP[2] = 0, 0
	end
end

--- Realizar movimiento de scroll en textos largos. -------------------------------------
function scroll_texto(scroll, texto, limite)
	if string.len(texto) >= limite and scroll <= (string.len(texto)-1) then
		scroll = scroll+1
		if string.byte(texto, scroll) >= 128 and scroll <= string.len(texto) then
			for proximo = scroll, string.len(texto) do
				if string.byte(texto, proximo) <= 127 then
					scroll = proximo
					reset_tiempo_espera(0)
					break
				elseif proximo == string.len(texto) then
					scroll = 1
					reset_tiempo_espera(0-CONTROL.FPS)
					break
				end
			end
		else
			reset_tiempo_espera(0)
		end
	else
		scroll = 1
		reset_tiempo_espera(0-CONTROL.FPS)
	end
	return scroll
end

--- Determina las pausas durante el movimiento de scroll en textos largos. --------------
function tiempo_de_scroll()
	if CONTROL.ESPERA_CARGA_SCR == true then
		CONTROL.PAUSA_SCR_TEX = CONTROL.PAUSA_SCR_TEX+1
	end
	if CONTROL.PAUSA_SCR_TEX >= CONTROL.FPS//3 or CONTROL.ESPERA_CARGA_SCR == false then
		CONTROL.PAUSA_SCR_TEX = 0
		CONTROL.ESPERA_CARGA_SCR = false
	end
end

--- Determina las pausas antes del scroll en textos largos. -----------------------------
function reset_tiempo_espera(numero)
	CONTROL.ESPERA_CARGA_SCR = true
	CONTROL.PAUSA_SCR_TEX = numero
end

--- Realiza saltos de elementos (en ruleta) dentro de un rango predeterminado. ----------
function cambiar_valor(numero_actual, numero_minimo, numero_maximo, salto, aumentar)
	if aumentar == true then
		if numero_actual+salto <= numero_maximo then
			numero_actual = numero_actual+salto
		else
			numero_actual = numero_minimo
		end
		return numero_actual
	elseif aumentar == false then
		if numero_actual-salto >= numero_minimo then
			numero_actual = numero_actual-salto
		else
			numero_actual = numero_maximo
		end
		return numero_actual
	end
end

--- Tipos de animaciones al cambiar de emuladores. --------------------------------------
function animaciones(lado, intro)
	Pads.rumble(0, 0, 0)
	local trans_especial, mostrar_ant = false, false
	if lado == nil then
		lado, trans_especial, mostrar_ant = true, true, true
	end
	local saibot = true
	local cambio_ani = false
	local pre_time = JOYSTICK_LIMITE
	JOYSTICK_LIMITE = control_FPS(1)

	-- Determinar las posiciones de los elementos en pantalla. --------------------------
	local lista_objetos_min = {CONTROL.IMG_ANCHO; CONTROL.LISTA_ANCHO; CONTROL.LOGO_ANCHO; CONTROL.IMG_ANCHO_2; CONTROL.FLOW_ANCHO;
	CONTROL.FLOW_ANCHO_2; CONTROL.SPRITE_ANCHO;};
	local lista_objetos_max = {(CONTROL.IMG_ANCHO+CONTROL.IMG_X); (CONTROL.LISTA_ANCHO+CONTROL.LISTA_X); (CONTROL.LOGO_ANCHO+CONTROL.LOGO_X);
	(CONTROL.IMG_ANCHO_2+CONTROL.IMG_X_2); (CONTROL.FLOW_ANCHO+CONTROL.FLOW_X); (CONTROL.FLOW_ANCHO_2+CONTROL.FLOW_X_2);
	(CONTROL.SPRITE_ANCHO+CONTROL.SPRITE_X);};
	if CONTROL.CUSTOM_ANIM == 2 or CONTROL.CUSTOM_ANIM == 3 then
		lista_objetos_min = {CONTROL.IMG_ALTO; CONTROL.LISTA_ALTO; CONTROL.LOGO_ALTO; CONTROL.IMG_ALTO_2; CONTROL.FLOW_ALTO;
		CONTROL.FLOW_ALTO_2; CONTROL.SPRITE_ALTO;};
		lista_objetos_max = {(CONTROL.IMG_ALTO+CONTROL.IMG_Y); (CONTROL.LISTA_ALTO+CONTROL.LISTA_Y); (CONTROL.LOGO_ALTO+CONTROL.LOGO_Y);
		(CONTROL.IMG_ALTO_2+CONTROL.IMG_Y_2); (CONTROL.FLOW_ALTO+CONTROL.FLOW_Y); (CONTROL.FLOW_ALTO_2+CONTROL.FLOW_Y_2);
		(CONTROL.SPRITE_ALTO+CONTROL.SPRITE_Y);};
	end
	table.sort(lista_objetos_min)
	table.sort(lista_objetos_max)
	local minimo, maximo, lista_objetos_min, lista_objetos_max = lista_objetos_min[1], lista_objetos_max[#lista_objetos_max], {}, {}
	local actual = minimo
	if CONTROL.CUSTOM_ANIM >= 4 or trans_especial == true then
		actual = 0
	else
		color_emu(LISTAS.IDENTIDAD, OPCIONES.FONDO_RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON)
	end
	if CONTROL.CUSTOM_ANIM == 15 and trans_especial == false then
		cargar_logo(LISTAS.IDENTIDAD)
		color_emu(LISTAS.IDENTIDAD, OPCIONES.FONDO_RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON)
		saibot = false
	end
	while saibot do
		-- Animación estilo 1. ----------------------------------------------------------
		if lado == true and CONTROL.CUSTOM_ANIM == 1 and trans_especial == false then
			if actual > minimo and cambio_ani == true then
				actual = actual-CONTROL.ANIM_VELOCIDAD
			elseif cambio_ani == true then
				actual = 0
				saibot = false
			elseif actual+maximo > 0-CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = actual-CONTROL.ANIM_VELOCIDAD
			elseif actual+maximo <= 0-CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = CONTROL.ANCHO+CONTROL.ANIM_VELOCIDAD
				cargar_logo(LISTAS.IDENTIDAD)
				cambio_ani = true
			end
		elseif lado == false and CONTROL.CUSTOM_ANIM == 1 and trans_especial == false then
			if actual+CONTROL.ANIM_VELOCIDAD < minimo-CONTROL.ANIM_VELOCIDAD and cambio_ani == true then
				actual = actual+CONTROL.ANIM_VELOCIDAD
			elseif cambio_ani == true then
				actual = 0
				saibot = false
			elseif actual < CONTROL.ANCHO+CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = actual+CONTROL.ANIM_VELOCIDAD
			elseif actual >= CONTROL.ANCHO+CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = (-(minimo+maximo))-CONTROL.ANIM_VELOCIDAD
				cargar_logo(LISTAS.IDENTIDAD)
				cambio_ani = true
			end

		-- Animación estilo 2 / estilo 3. -----------------------------------------------
		elseif lado == true and (CONTROL.CUSTOM_ANIM == 2 or CONTROL.CUSTOM_ANIM == 3) and trans_especial == false then
			if actual >= minimo and cambio_ani == true then
				actual = actual-CONTROL.ANIM_VELOCIDAD
			elseif cambio_ani == true then
				actual = 0
				saibot = false
			elseif actual+maximo > 0-CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = actual-CONTROL.ANIM_VELOCIDAD
			elseif actual+maximo <= 0-CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = CONTROL.ALTO+CONTROL.ANIM_VELOCIDAD
				cargar_logo(LISTAS.IDENTIDAD)
				cambio_ani = true
			end
		elseif lado == false and (CONTROL.CUSTOM_ANIM == 2 or CONTROL.CUSTOM_ANIM == 3) and trans_especial == false then
			if actual+CONTROL.ANIM_VELOCIDAD <= minimo and cambio_ani == true then
				actual = actual+CONTROL.ANIM_VELOCIDAD
			elseif cambio_ani == true then
				actual = 0
				saibot = false
			elseif actual < CONTROL.ALTO+CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = actual+CONTROL.ANIM_VELOCIDAD
			elseif actual >= CONTROL.ALTO+CONTROL.ANIM_VELOCIDAD and cambio_ani == false then
				actual = (-(minimo+maximo))-CONTROL.ANIM_VELOCIDAD
				cargar_logo(LISTAS.IDENTIDAD)
				cambio_ani = true
			end

		-- Animaciones del estilo 4 al estilo 15. ---------------------------------------
		elseif CONTROL.CUSTOM_ANIM >= 4 or trans_especial == true then
			if actual >= 1 and cambio_ani == true then
				actual = actual-(CONTROL.ANIM_VELOCIDAD//10)
			elseif cambio_ani == true then
				actual = 0
				saibot = false
			elseif actual < 42 and cambio_ani == false then
				actual = actual+(CONTROL.ANIM_VELOCIDAD//10)
			elseif actual >= 42 and cambio_ani == false then
				actual = 42
				if intro == true then
					saibot = false
					break
				end
				cargar_logo(LISTAS.IDENTIDAD)
				color_emu(LISTAS.IDENTIDAD, OPCIONES.FONDO_RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON)
				cambio_ani = true
				mostrar_ant = false
			end
		end

		-- Mostrar todo en pantalla. ----------------------------------------------------
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()
		if mostrar_ant == false then
			-- Posicionar elementos. ----------------------------------------------------
			local representar = {actual+CONTROL.IMG_ANCHO; actual+CONTROL.LISTA_ANCHO; actual+CONTROL.LOGO_ANCHO; actual+CONTROL.IMG_ANCHO_2;
			actual+CONTROL.FLOW_ANCHO; actual+CONTROL.FLOW_ANCHO_2; CONTROL.IMG_ALTO; CONTROL.LISTA_ALTO; CONTROL.LOGO_ALTO; CONTROL.IMG_ALTO_2;
			CONTROL.FLOW_ALTO; CONTROL.FLOW_ALTO_2; actual+CONTROL.SPRITE_ANCHO; CONTROL.SPRITE_ALTO;};
			if CONTROL.CUSTOM_ANIM == 2 then
				representar = {CONTROL.IMG_ANCHO; CONTROL.LISTA_ANCHO; CONTROL.LOGO_ANCHO; CONTROL.IMG_ANCHO_2; CONTROL.FLOW_ANCHO; CONTROL.FLOW_ANCHO_2;
				actual+CONTROL.IMG_ALTO; actual+CONTROL.LISTA_ALTO; actual+CONTROL.LOGO_ALTO; actual+CONTROL.IMG_ALTO_2; actual+CONTROL.FLOW_ALTO;
				actual+CONTROL.FLOW_ALTO_2; CONTROL.SPRITE_ANCHO; actual+CONTROL.SPRITE_ALTO;};
			elseif CONTROL.CUSTOM_ANIM == 3 then
				representar = {actual+CONTROL.IMG_ANCHO; actual+CONTROL.LISTA_ANCHO; actual+CONTROL.LOGO_ANCHO; actual+CONTROL.IMG_ANCHO_2;
				actual+CONTROL.FLOW_ANCHO; actual+CONTROL.FLOW_ANCHO_2; actual+CONTROL.IMG_ALTO; actual+CONTROL.LISTA_ALTO; actual+CONTROL.LOGO_ALTO;
				actual+CONTROL.IMG_ALTO_2; actual+CONTROL.FLOW_ALTO; actual+CONTROL.FLOW_ALTO_2; actual+CONTROL.SPRITE_ANCHO; actual+CONTROL.SPRITE_ALTO;};
			elseif CONTROL.CUSTOM_ANIM >= 4 or trans_especial == true then
				representar = {CONTROL.IMG_ANCHO; CONTROL.LISTA_ANCHO; CONTROL.LOGO_ANCHO; CONTROL.IMG_ANCHO_2; CONTROL.FLOW_ANCHO; CONTROL.FLOW_ANCHO_2;
				CONTROL.IMG_ALTO; CONTROL.LISTA_ALTO; CONTROL.LOGO_ALTO; CONTROL.IMG_ALTO_2; CONTROL.FLOW_ALTO; CONTROL.FLOW_ALTO_2; CONTROL.SPRITE_ANCHO;
				CONTROL.SPRITE_ALTO;};
			end

			-- Dibujar elementos. -------------------------------------------------------
			if CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.CUSTOM_LIST == true then
				Graphics.drawRect(representar[2]-3, representar[8]-3, CONTROL.LISTA_X+236+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
			elseif CONTROL.ESTILO ~= 2 and CONTROL.CUSTOM_LIST == true then
				Graphics.drawRect(representar[2]-3, representar[8]-3, CONTROL.LISTA_X+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
			end
			if CONTROL.CUSTOM_BACK == true then
				if CONTROL.CUSTOM_ART1 == true then
					Graphics.drawRect(representar[1]-5, representar[7]-5, CONTROL.IMG_X+10, CONTROL.IMG_Y+10, COLOR.NEGRO_T)
				end
				if (CONTROL.ESTILO == 3 or CONTROL.ESTILO == 5 or CONTROL.ESTILO == 6 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_ART2 == true then
					Graphics.drawRect(representar[4]-5, representar[10]-5, CONTROL.IMG_X_2+10, CONTROL.IMG_Y_2+10, COLOR.NEGRO_T)
				end
				if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
					Graphics.drawRect(representar[5]-5, representar[11]-5, CONTROL.FLOW_X+10, CONTROL.FLOW_Y+10, COLOR.NEGRO_T)
					Graphics.drawRect(representar[6]-5, representar[12]-5, CONTROL.FLOW_X_2+10, CONTROL.FLOW_Y_2+10, COLOR.NEGRO_T)
				end
			end

			-- Dibujar logo. ------------------------------------------------------------
			if CONTROL.CUSTOM_LOGO == true then
				Graphics.drawScaleImage(LISTAS.LOGO, representar[3], representar[9], CONTROL.LOGO_X, CONTROL.LOGO_Y)
			end

			-- Dibujar sprite. ----------------------------------------------------------
			if CONTROL.CUSTOM_SPRITE == true and cambio_ani == true then
				if SPRITES.MOVE[LISTAS.IDENTIDAD] <= 50 or ( SPRITES.MOVE[LISTAS.IDENTIDAD] >= 53 and SPRITES.MOVE[LISTAS.IDENTIDAD] <= 56) or SPRITES.MOVE[LISTAS.IDENTIDAD] == 59 or SPRITES.MOVE[LISTAS.IDENTIDAD] == 62 then
					SPRITES.MOVE_X, SPRITES.MOVE_Y = representar[13], representar[14]
				end
				dibujar_sprites(LISTAS.IDENTIDAD, representar[13], representar[14], CONTROL.SPRITE_X, CONTROL.SPRITE_Y, 0.00, SPRITES.FLIP[1], SPRITES.FLIP[2], true)
			end
		end

		-- Dibujar elementos extras. ----------------------------------------------------
		if CONTROL.CUSTOM_ANIM == 4 or trans_especial == true then
			local suma_x, suma_y = 0, 0
			for contador = 40, CONTROL.ALTO+40, 40 do
				for contador2 = -8, CONTROL.ANCHO+40, 40 do
					suma_x = contador2
					Graphics.drawRect(suma_x-(actual//2)+4, suma_y-(actual//2)+4, actual+4, actual+4, Color.new(0, 0, 0, (actual*3)))
				end
				suma_y = contador
			end
		end
		if CONTROL.CUSTOM_ANIM == 6 and trans_especial == false then
			Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO, Color.new(0, 0, 0, (actual*3)))
		elseif CONTROL.CUSTOM_ANIM == 5 and trans_especial == false then
			Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO, Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B, (actual*3)))
		end
		if (CONTROL.CUSTOM_ANIM >= 7 and CONTROL.CUSTOM_ANIM <= 10) and trans_especial == false then
			if CONTROL.CUSTOM_ANIM == 7 or CONTROL.CUSTOM_ANIM == 9 then
				local x_mov, radio = actual*15, actual
				if CONTROL.CUSTOM_ANIM == 9 then
					radio = 0
				end
				for contador = 0, CONTROL.ANCHO, 100 do
					Graphics.drawCircle(0+x_mov, contador, 16+radio, Color.new(0, 0, 0, (actual*3)))
					Graphics.drawCircle(contador, 0+x_mov, 16+radio, Color.new(0, 0, 0, (actual*3)))
					Graphics.drawCircle(CONTROL.ANCHO-x_mov, contador, 16+radio, Color.new(0, 0, 0, (actual*3)))
					Graphics.drawCircle(contador, CONTROL.ALTO-x_mov, 16+radio, Color.new(0, 0, 0, (actual*3)))
				end
			end
			if CONTROL.CUSTOM_ANIM == 8 or CONTROL.CUSTOM_ANIM == 9 then
				local list_x = {CONTROL.ANCHO, 80, 140, 180, 30, 500, 600, 10, 610, 220}
				local list_y = {CONTROL.ALTO, 80, 200, 320, 40, 70, 30, CONTROL.ALTO, 340, 30}
				local list_circle = {15, 1, 2, 10, 4, 5, 3, 9, 2, 1}
				for num = 1, #list_circle, 1 do
					Graphics.drawCircle(list_x[num], list_y[num], actual*list_circle[num], Color.new(0, 0, 0, (actual*3)))
				end
			end
			if CONTROL.CUSTOM_ANIM == 10 then
				local suma_x, suma_y = 0, 0
				for contador = 0, CONTROL.ALTO+50, 50 do
					for contador2 = 25, CONTROL.ANCHO, 50 do
						suma_x = contador2
						Graphics.drawCircle(suma_x, suma_y, actual, Color.new(0, 0, 0, (actual*3)))
					end
					suma_y = contador
				end
			end
		end
		if (CONTROL.CUSTOM_ANIM == 11 or CONTROL.CUSTOM_ANIM == 12) and trans_especial == false then
			local inicio, final, salto, valor = 0, CONTROL.ANCHO, 16, actual//2
			if CONTROL.CUSTOM_ANIM == 12 then
				final = CONTROL.ALTO
				if lado == false then
					inicio, final, salto, valor = CONTROL.ALTO, -1, -16, -actual//2
				end
			else
				if lado == false then
					inicio, final, salto, valor = CONTROL.ANCHO, -1, -16, -actual//2
				end
			end
			for contador = inicio, final, salto do
				if CONTROL.CUSTOM_ANIM == 11 then
					Graphics.drawRect(contador, 0, valor, CONTROL.ALTO, Color.new(0, 0, 0, (actual*3)))
				else
					Graphics.drawRect(0, contador, CONTROL.ANCHO, valor, Color.new(0, 0, 0, (actual*3)))
				end
			end
		end
		if (CONTROL.CUSTOM_ANIM == 13 or CONTROL.CUSTOM_ANIM == 14) and trans_especial == false then
			if CONTROL.CUSTOM_ANIM == 13 then
				local zoom_x, zoom_y = CONTROL.LOGO_X*actual/6, CONTROL.LOGO_Y*actual/6
				Graphics.drawScaleImage(LISTAS.LOGO, (CONTROL.ANCHO//2)-(zoom_x//2), (CONTROL.ALTO//2)-(zoom_y//2), zoom_x, zoom_y)
			elseif CONTROL.CUSTOM_ANIM == 14 then
				local zoom_x, zoom_y, flip_1, flip_2 = CONTROL.SPRITE_X*actual/6, CONTROL.SPRITE_Y*actual/6, 0, 0
				if SPRITES.AUTO_MOVE_SPRITE[LISTAS.IDENTIDAD] == 7 or SPRITES.AUTO_MOVE_SPRITE[LISTAS.IDENTIDAD] == 9 then
					flip_1 = 1
				end
				if SPRITES.AUTO_MOVE_SPRITE[LISTAS.IDENTIDAD] == 8 or SPRITES.AUTO_MOVE_SPRITE[LISTAS.IDENTIDAD] == 9 then
					flip_2 = 1
				end
				dibujar_sprites(LISTAS.IDENTIDAD, (CONTROL.ANCHO//2)-(zoom_x//2), (CONTROL.ALTO//2)-(zoom_y//2), zoom_x, zoom_y, 0.00, flip_1, flip_2, false)
			end
		end
		refrescar(false)
	end
	if CONTROL.CUSTOM_ANIM == 15 and trans_especial == false then
		JOYSTICK_LIMITE = control_FPS(1)
	else
		CONTROL.JOYSTICK_ON, JOYSTICK_LIMITE = true, pre_time
	end
end

--- Determina los colores predeterminados de cada emulador. -----------------------------
function color_emu(identidad, act_rgb_fondo, act_color_fondo)
	local EMU_1 = 128
	local EMU_2 = 128
	local EMU_3 = 128
	local R = 128
	local G = 128
	local B = 128
	local MAX = 0
	local MIN = 0
	local RGB = 0
	local ACTUAL = 128
	local BLANCO_1 = 74
	local BLANCO_2 = 74
	local BLANCO_3 = 74

	-- Colores para Sega Megadrive. -----------------------------------------------------
	if identidad == 1 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 128; EMU_2 = 128; EMU_3 = 128;
		R = 128; G = 128; B = 128;
		MAX = 128; MIN = 118; RGB = 4; ACTUAL = 128;
		BLANCO_1 = 74; BLANCO_2 = 74; BLANCO_3 = 74;

	-- Colores para Sega Master System. -------------------------------------------------
	elseif identidad == 2 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 60; EMU_3 = 128;
		R = 0; G = 50; B = 128;
		MAX = 70; MIN = 50; RGB = 2; ACTUAL = 50;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Sega Game Gear. -----------------------------------------------------
	elseif identidad == 3 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 90; EMU_3 = 100;
		R = 0; G = 90; B = 100;
		MAX = 120; MIN = 90; RGB = 2; ACTUAL = 90;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Nintendo Famicom. ---------------------------------------------------
	elseif identidad == 4 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 128; EMU_2 = 25; EMU_3 = 25;
		R = 128; G = 1; B = 1;
		MAX = 26; MIN = 1; RGB = 4; ACTUAL = 1;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Nintendo Game Boy. --------------------------------------------------
	elseif identidad == 5 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 128; EMU_3 = 20;
		R = 0; G = 100; B = 0;
		MAX = 120; MIN = 100; RGB = 2; ACTUAL = 100;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Nintendo Game Boy Color. --------------------------------------------
	elseif identidad == 6 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 110; EMU_2 = 110; EMU_3 = 5;
		R = 108; G = 108; B = 0;
		MAX = 128; MIN = 108; RGB = 2; ACTUAL = 108;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Nintendo Game Boy Advance. ------------------------------------------
	elseif identidad == 7 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 118; EMU_2 = 25; EMU_3 = 118;
		R = 100; G = 0; B = 100;
		MAX = 120; MIN = 100; RGB = 5; ACTUAL = 100;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Atari 2600. ---------------------------------------------------------
	elseif identidad == 8 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 120; EMU_2 = 80; EMU_3 = 0;
		R = 128; G = 42; B = 0;
		MAX = 64; MIN = 42; RGB = 2; ACTUAL = 42;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Atari Lynx. ---------------------------------------------------------
	elseif identidad == 9 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 128; EMU_2 = 128; EMU_3 = 58;
		R = 128; G = 128; B = 74;
		MAX = 94; MIN = 74; RGB = 3; ACTUAL = 74;
		BLANCO_1 = 84; BLANCO_2 = 84; BLANCO_3 = 84;

	-- Colores para Sega SG 1000. -------------------------------------------------------
	elseif identidad == 10 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 120; EMU_3 = 80;
		R = 0; G = 100; B = 50;
		MAX = 70; MIN = 50; RGB = 3; ACTUAL = 50;
		BLANCO_1 = 74; BLANCO_2 = 74; BLANCO_3 = 74;

	-- Colores para Neo Geo Pocket. -----------------------------------------------------
	elseif identidad == 11 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 128; EMU_2 = 30; EMU_3 = 70;
		R = 128; G = 0; B = 40;
		MAX = 60; MIN = 40; RGB = 3; ACTUAL = 40;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para Nintendo Super Famicom. ---------------------------------------------
	elseif identidad == 12 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 108; EMU_2 = 25; EMU_3 = 108;
		R = 100; G = 50; B = 100;
		MAX = 120; MIN = 100; RGB = 5; ACTUAL = 100;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para APPS. ---------------------------------------------------------------
	elseif identidad == 13 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 100; EMU_3 = 128;
		R = 0; G = 100; B = 128;
		MAX = 128; MIN = 100; RGB = 2; ACTUAL = 100;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para PlayStation 1. ------------------------------------------------------
	elseif identidad == 14 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 60; EMU_3 = 128;
		R = 0; G = 60; B = 128;
		MAX = 80; MIN = 60; RGB = 2; ACTUAL = 60;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores para PlayStation 2. ------------------------------------------------------
	elseif identidad == 15 and act_rgb_fondo == 1 and act_color_fondo == 0 then
		EMU_1 = 0; EMU_2 = 80; EMU_3 = 128;
		R = 0; G = 80; B = 128;
		MAX = 100; MIN = 80; RGB = 2; ACTUAL = 80;
		BLANCO_1 = 128; BLANCO_2 = 128; BLANCO_3 = 128;

	-- Colores personalizados. ----------------------------------------------------------
	elseif act_color_fondo == 1 then
		EMU_1 = OPCIONES.R; EMU_2 = OPCIONES.G; EMU_3 = OPCIONES.B;
		R = OPCIONES.R; G = OPCIONES.G; B = OPCIONES.B;
		MAX = 0; MIN = 0; RGB = 0; ACTUAL = 0;
		BLANCO_1 = OPCIONES.COLOR_LISTA_B ; BLANCO_2 = OPCIONES.COLOR_LISTA_B; BLANCO_3 = OPCIONES.COLOR_LISTA_B;

	-- Sin colores. ---------------------------------------------------------------------
	elseif act_rgb_fondo == 0 then
		EMU_1 = 128; EMU_2 = 128; EMU_3 = 128;
		R = 128; G = 128; B = 128;
		MAX = 0; MIN = 0; RGB = 0; ACTUAL = 128;
		BLANCO_1 = 74; BLANCO_2 = 74; BLANCO_3 = 74;
	end

	-- Aplicar colores. -----------------------------------------------------------------
	CAMBIOS_EMUS.COLOR_EMU = Color.new(EMU_1, EMU_2, EMU_3)
	CAMBIOS_EMUS.R = R; CAMBIOS_EMUS.G = G; CAMBIOS_EMUS.B = B;
	CAMBIOS_EMUS.COLOR_MAX = MAX; CAMBIOS_EMUS.COLOR_MIN = MIN; CAMBIOS_EMUS.RGB_COLOR = RGB;
	CAMBIOS_EMUS.COLOR_ACTUAL = ACTUAL;
	COLOR.BLANCO_LISTA = Color.new(BLANCO_1, BLANCO_2, BLANCO_3)
end

--- Realiza el efecto de cambio de colores del fondo. -----------------------------------
function RGB(rgb_on, act_color_fondo, transparencia)
	if CAMBIOS_EMUS.CAM_COLOR_ACTUAL == true and act_color_fondo == 0 and rgb_on == 1 then
		if CAMBIOS_EMUS.COLOR_ACTUAL <= CAMBIOS_EMUS.COLOR_MAX then
			CAMBIOS_EMUS.COLOR_ACTUAL = CAMBIOS_EMUS.COLOR_ACTUAL+1
		else
			CAMBIOS_EMUS.CAM_COLOR_ACTUAL = false
		end
	elseif CAMBIOS_EMUS.CAM_COLOR_ACTUAL == false and act_color_fondo == 0 and rgb_on == 1 then
		if CAMBIOS_EMUS.COLOR_ACTUAL >= CAMBIOS_EMUS.COLOR_MIN then
			CAMBIOS_EMUS.COLOR_ACTUAL = CAMBIOS_EMUS.COLOR_ACTUAL-1
		else
			CAMBIOS_EMUS.CAM_COLOR_ACTUAL = true
		end
	end
	if (CAMBIOS_EMUS.RGB_COLOR == 0 or rgb_on == 0) and act_color_fondo == 0 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B)
	elseif (CAMBIOS_EMUS.RGB_COLOR == 0 or rgb_on == 0) and act_color_fondo == 1 then
		if transparencia == 0 then
			CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B)
		else
			CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B, transparencia)
		end
	elseif CAMBIOS_EMUS.RGB_COLOR == 1 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B)
	elseif CAMBIOS_EMUS.RGB_COLOR == 2 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.B)
	elseif CAMBIOS_EMUS.RGB_COLOR == 3 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.COLOR_ACTUAL)
	elseif CAMBIOS_EMUS.RGB_COLOR == 4 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.R, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL)
	elseif CAMBIOS_EMUS.RGB_COLOR == 5 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.G, CAMBIOS_EMUS.COLOR_ACTUAL)
	elseif CAMBIOS_EMUS.RGB_COLOR == 6 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.B)
	elseif CAMBIOS_EMUS.RGB_COLOR == 7 then
		CAMBIOS_EMUS.COLOR_EMU_BACK = Color.new(CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL)
	end
end

--- Determina qué logo cargar de acuerdo al emulador. -----------------------------------
function cargar_logo(identidad)
	if identidad == 1 then
		LISTAS.LOGO = LOGOS.MEGADRIVE
	elseif identidad == 2 then
		LISTAS.LOGO = LOGOS.MASTERSYSTEM
	elseif identidad == 3 then
		LISTAS.LOGO = LOGOS.GAMEGEAR
	elseif identidad == 4 then
		LISTAS.LOGO = LOGOS.FAMICOM
	elseif identidad == 5 then
		LISTAS.LOGO = LOGOS.GAMEBOY
	elseif identidad == 6 then
		LISTAS.LOGO = LOGOS.GAMEBOYCOLOR
	elseif identidad == 7 then
		LISTAS.LOGO = LOGOS.GAMEBOYADVANCE
	elseif identidad == 8 then
		LISTAS.LOGO = LOGOS.ATARI2600
	elseif identidad == 9 then
		LISTAS.LOGO = LOGOS.ATARILYNX
	elseif identidad == 10 then
		LISTAS.LOGO = LOGOS.SEGASG1000
	elseif identidad == 11 then
		LISTAS.LOGO = LOGOS.NEOGEOPOCKET
	elseif identidad == 12 then
		LISTAS.LOGO = LOGOS.SUPERFAMICOM
	elseif identidad == 13 then
		LISTAS.LOGO = LOGOS.APPS
	elseif identidad == 14 then
		LISTAS.LOGO = LOGOS.PLAYSTATION
	elseif identidad == 15 then
		LISTAS.LOGO = LOGOS.PLAYSTATION2
	else
		LISTAS.LOGO = LOGOS.DEFAULT
	end
end

--- Realizar animaciones de los sprites. ------------------------------------------------
function dibujar_sprites(sistema, pos_x, pos_y, esc_x, esc_y, angulo, voltear_x, voltear_y, mover)
	local largo_x, alto_y, fix = SPRITES.WIDTH_X[sistema], SPRITES.HEIGHT_Y[sistema], 0
	local frame_speed, num_filas, num_columnas = 4, SPRITES.N_ROWS[sistema], SPRITES.N_COLUMNS[sistema]
	local color_sprite, zoom_x_fix, zoom_y_fix = Color.new(128, 128, 128), 0, 0
	-- Controlar la velocidad en las animaciones. ---------------------------------------
	if CONTROL.FPS >= 28 then
		frame_speed = 5
	elseif CONTROL.FPS >= 10 then
		frame_speed = CONTROL.FPS//6
	elseif CONTROL.FPS <= 9 then
		frame_speed = 1
	end

	-- Cambiar las animaciones. ---------------------------------------------------------
	if SPRITES.ANI_FRAME >= 1 then
		SPRITES.ANI_FRAME = SPRITES.ANI_FRAME-1
	else
		SPRITES.ANI_FRAME = frame_speed
	end

	-- Recorrer las animaciones. --------------------------------------------------------
	if SPRITES.X == (largo_x*num_columnas)-largo_x and SPRITES.ANI_FRAME == frame_speed then
		SPRITES.Y = cambiar_valor(SPRITES.Y, 0, (alto_y*num_filas)-alto_y, alto_y, true)
		SPRITES.X = cambiar_valor(SPRITES.X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
	elseif SPRITES.ANI_FRAME == frame_speed then
		SPRITES.X = cambiar_valor(SPRITES.X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
	end

	-- Voltear horizontalmente. ---------------------------------------------------------
	local x_flip = 0
	if voltear_x == 1 then
		x_flip = largo_x-1
		largo_x = (-largo_x)+1
	end

	-- Voltear verticalmente. -----------------------------------------------------------
	local y_flip = 0
	if voltear_y == 1 then
		y_flip = alto_y-1
		alto_y = (-alto_y)+1
	end

	-- Movimientos de sprites. ----------------------------------------------------------
	if (SPRITES.MOVE[sistema] >= 1 or SPRITES.TRAN_SPRITE_ON[sistema] >= 1 or SPRITES.SPIN_SPRITE_ON[sistema] >= 1 or SPRITES.AUTO_MOVE_SPRITE[sistema] >= 1) and mover == true then
		-- Define las animaciones de sprites. -------------------------------------------
		local veloc = SPRITES.SPEED_SPRITE[sistema]
		local sprite_pos_x, sprite_pos_y, sprite_tam_x, sprite_tam_y = SPRITES.MOVE_X, SPRITES.MOVE_Y, CONTROL.SPRITE_X, CONTROL.SPRITE_Y
		local sprite_ant_x, sprite_ant_y, limit_x, limit_y = pos_x, pos_y, CONTROL.ANCHO, CONTROL.ALTO_F
		if (SPRITES.MOVE[sistema] >= 13 and SPRITES.MOVE[sistema] <= 24) or (SPRITES.MOVE[sistema] >= 35 and SPRITES.MOVE[sistema] <= 44) then
			sprite_pos_x, sprite_pos_y, sprite_tam_x, sprite_tam_y = SPRITES.MOVE_Y, SPRITES.MOVE_X, CONTROL.SPRITE_Y, CONTROL.SPRITE_X
			sprite_ant_x, sprite_ant_y, limit_x, limit_y = pos_y, pos_x, CONTROL.ALTO_F, CONTROL.ANCHO
		end
		local function animar_sprite(pos, mini, maxi, tama, velocidad, invertir, ruleta, control)
			if (pos > maxi and invertir == false) or (pos < mini and invertir == true) then
				if invertir == false and (ruleta == true) then
					if ruleta == true then
						pos = mini-velocidad
					end
				elseif invertir == true and (ruleta == true) then
					if ruleta == true then
						pos = maxi+velocidad
					end
				elseif invertir == false and ruleta == false then
					control = true
				elseif invertir == true and ruleta == false then
					control = false
				end
			else
				pos = pos+velocidad
			end
			return pos, control
		end

		-- Realizar animaciones de sprites. ---------------------------------------------
		-- Animaciones de sprites generales. --------------------------------------------
		if (SPRITES.MOVE[sistema] >= 1 and SPRITES.MOVE[sistema] <= 24) or (SPRITES.MOVE[sistema] >= 45 and SPRITES.MOVE[sistema] <= 50) then
			local inv_move_1, inv_move_2, min_x, max_x, min_y, max_y = false, false, 0-sprite_tam_x, limit_x, 0-sprite_tam_y, limit_y
			local ruleta_act_1, ruleta_act_2, veloc_1, veloc_2 = true, true, veloc, veloc
			local wanted = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0}
			local tipo = 13
			if SPRITES.MOVE[sistema] >= 1 and SPRITES.MOVE[sistema] <= 12 then
				tipo = SPRITES.MOVE[sistema]
			elseif SPRITES.MOVE[sistema] >= 13 and SPRITES.MOVE[sistema] <= 24 then
				tipo = SPRITES.MOVE[sistema]-12
			end
			-- Invertir desplazamiento. -------------------------------------------------
			if (wanted[tipo] == 2 or wanted[tipo] == 4 or wanted[tipo] == 6 or SPRITES.MOVE[sistema] == 48 or SPRITES.MOVE[sistema] == 50) or (((wanted[tipo] >= 7 and wanted[tipo] <= 12) or SPRITES.MOVE[sistema] == 45 or SPRITES.MOVE[sistema] == 46) and SPRITES.MOVE_ALT_X == true) then
				inv_move_1, veloc_1 = true, -veloc_1
			end
			if SPRITES.MOVE[sistema] == 49 or SPRITES.MOVE[sistema] == 50 or (((wanted[tipo] >= 3 and wanted[tipo] <= 6) or (wanted[tipo] >= 10 and wanted[tipo] <= 12) or SPRITES.MOVE[sistema] == 45 or SPRITES.MOVE[sistema] == 46) and SPRITES.MOVE_ALT_Y == true) then
				inv_move_2, veloc_2 = true, -veloc_2
			end

			-- Desplazamiento en el eje x. ----------------------------------------------
			if wanted[tipo] >= 7 and wanted[tipo] <= 12 then
				ruleta_act_1 = false
				local caminata = 100
				if wanted[tipo] == 8 or wanted[tipo] == 11 then
					caminata = 160
				end
				min_x, max_x = (sprite_ant_x+(sprite_tam_x/2))-caminata, (sprite_ant_x-(sprite_tam_x/2))+caminata
				if min_x <= 0 or wanted[tipo] == 9 or wanted[tipo] == 12 then
					min_x = 0
				end
				if max_x >= limit_x-sprite_tam_x or wanted[tipo] == 9 or wanted[tipo] == 12 then
					max_x = limit_x-sprite_tam_x
				end
			end
			if SPRITES.MOVE[sistema] == 45 or SPRITES.MOVE[sistema] == 46 then
				ruleta_act_1, ruleta_act_2 = false, false
				local tam_final = (sprite_tam_x+sprite_tam_y)/2
				min_x, max_x = (pos_x)-(tam_final/3), (pos_x)+(tam_final/3)
				min_y, max_y = (pos_y)-(tam_final/3), (pos_y)+(tam_final/3)
				veloc_1, veloc_2 = veloc_1/2, veloc_2/2
			end
			sprite_pos_x, SPRITES.MOVE_ALT_X = animar_sprite(sprite_pos_x, min_x, max_x, sprite_tam_x, veloc_1, inv_move_1, ruleta_act_1, SPRITES.MOVE_ALT_X)

			-- Desplazamiento en el eje y. ----------------------------------------------
			if wanted[tipo] == 3 or wanted[tipo] == 4 then
				ruleta_act_2 = false
				min_y, max_y = sprite_ant_y-(sprite_tam_y/2), sprite_ant_y+(sprite_tam_y/2)
			elseif wanted[tipo] == 5 or wanted[tipo] == 6 then
				ruleta_act_2 = false
				min_y, max_y = 0, limit_y-sprite_tam_y
			elseif SPRITES.MOVE[sistema] >= 47 and SPRITES.MOVE[sistema] <= 50 then
				veloc_2 = veloc_2/2
			elseif wanted[tipo] >= 10 and wanted[tipo] <= 12 then
				ruleta_act_2 = false
				min_y, max_y = (sprite_ant_y-(sprite_tam_y/2))+(sprite_tam_y/3), (sprite_ant_y+(sprite_tam_y/2))-(sprite_tam_y/3)
			end
			if (wanted[tipo] >= 3 and wanted[tipo] <= 6) or (wanted[tipo] >= 10 and wanted[tipo] <= 12) or (SPRITES.MOVE[sistema] >= 45 and SPRITES.MOVE[sistema] <= 50) then
				sprite_pos_y, SPRITES.MOVE_ALT_Y = animar_sprite(sprite_pos_y, min_y, max_y, sprite_tam_y, veloc_2, inv_move_2, ruleta_act_2, SPRITES.MOVE_ALT_Y)
			end
			if SPRITES.MOVE[sistema] == 45 then
				SPRITES.MOVE_ALT_Y = SPRITES.MOVE_ALT_X
			elseif SPRITES.MOVE[sistema] == 46 then
				if SPRITES.MOVE_ALT_X == true then SPRITES.MOVE_ALT_Y = false else SPRITES.MOVE_ALT_Y = true end
			end

		-- Animación de velocidad. ------------------------------------------------------
		elseif SPRITES.MOVE[sistema] >= 25 and SPRITES.MOVE[sistema] <= 44 then
			local inv_move_1, veloc_1, veloc_2, reset_x, reset_y, aumento, divisor = false, veloc, veloc, 0-(50+sprite_tam_x), 0-(sprite_tam_y/2), 0, limit_x
			local wanted = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
			local tipo = SPRITES.MOVE[sistema]-24
			if SPRITES.MOVE[sistema] >= 35 then
				tipo = SPRITES.MOVE[sistema]-34
			end
			-- Invertir desplazamiento. -------------------------------------------------
			if wanted[tipo] == 2 or wanted[tipo] == 4 or wanted[tipo] == 6 or wanted[tipo] == 8 or wanted[tipo] == 10 then
				inv_move_1, veloc_1, reset_x = true, -veloc_1, limit_x+50
			end

			-- Calcular aumento y disminución de velocidad. -----------------------------
			if wanted[tipo] == 3 or wanted[tipo] == 4 then
				reset_y = limit_y-(sprite_tam_y/2)
			elseif (wanted[tipo] == 7 or wanted[tipo] == 8) and SPRITES.MOVE_ALT_Y == true then
				sprite_pos_y = sprite_pos_y+sprite_tam_y
				if sprite_pos_y >= limit_y-(sprite_tam_y/2) then
					sprite_pos_y = 0
				end
			elseif (wanted[tipo] == 9 or wanted[tipo] == 10) then
				divisor = divisor/2
			end
			for plus = 1, 20 do
				if (sprite_pos_x <= (divisor/20)*plus and inv_move_1 == false) or (sprite_pos_x >= (limit_x-sprite_tam_x)-((divisor/20)*plus) and inv_move_1 == true) then
					aumento = plus
					if (wanted[tipo] == 9 or wanted[tipo] == 10) then
						aumento = 21-(aumento+1)
					end
					break
				end
			end

			-- Invertir valor del aumento. ----------------------------------------------
			if wanted[tipo] == 2 or wanted[tipo] == 4 or wanted[tipo] == 6 or wanted[tipo] == 8 or wanted[tipo] == 10 then
				aumento = -aumento
			end
			SPRITES.MOVE_ALT_Y = false

			-- Desplazamiento en el eje x. ----------------------------------------------
			if (sprite_pos_x <= limit_x+50 and inv_move_1 == false) or (sprite_pos_x >= 0-(50+sprite_tam_x) and inv_move_1 == true) then
				sprite_pos_x = sprite_pos_x+(veloc_1+aumento)
			elseif (sprite_pos_x >= limit_x+50 and inv_move_1 == false) or (sprite_pos_x <= 0-(50+sprite_tam_x) and inv_move_1 == true) then
				sprite_pos_x = reset_x
				SPRITES.MOVE_ALT_X = false
				if wanted[tipo] >= 1 and wanted[tipo] <= 4 then
					sprite_pos_y = reset_y
				elseif wanted[tipo] == 7 or wanted[tipo] == 8 then
					SPRITES.MOVE_ALT_Y = true
				end
			end

			-- Desplazamiento en el eje y. ----------------------------------------------
			if wanted[tipo] >= 1 and wanted[tipo] <= 4 then
				local alternar = (limit_x/2)-(sprite_tam_x/2)
				if (sprite_pos_x <= alternar and inv_move_1 == false) or (sprite_pos_x >= alternar and inv_move_1 == true) then
					if wanted[tipo] == 3 or wanted[tipo] == 4 then
						sprite_pos_y = sprite_pos_y-(veloc_2*2)
					else
						sprite_pos_y = sprite_pos_y+(veloc_2*2)
					end
				else
					if wanted[tipo] == 3 or wanted[tipo] == 4 then
						sprite_pos_y = sprite_pos_y+(veloc_2/2)*2
					else
						sprite_pos_y = sprite_pos_y-(veloc_2/2)*2
					end
				end
			end

		-- Animación de marco. ----------------------------------------------------------
		elseif SPRITES.MOVE[sistema] == 51 or SPRITES.MOVE[sistema] == 52 then
			local inv_move_1, min_x, max_x, min_y, max_y, flip = false, 0, limit_x, 0, limit_y, 1
			if SPRITES.MOVE[sistema] == 52 then
				inv_move_1 = true
			end
			if veloc == 1 then
				flip = 0.99
			end
			if inv_move_1 == false then
				if sprite_pos_x <= max_x-sprite_tam_x-veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_x = sprite_pos_x+veloc
				elseif sprite_pos_x >= max_x-sprite_tam_x-veloc and sprite_pos_y <= max_y-sprite_tam_y-veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_x = max_x-sprite_tam_x-(flip)
					sprite_pos_y = sprite_pos_y+veloc
				elseif sprite_pos_y >= max_y-sprite_tam_y-veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_y = max_y-sprite_tam_y-(flip)
					SPRITES.MOVE_ALT_X = true
				elseif sprite_pos_x >= min_x+veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_x = sprite_pos_x-veloc
				elseif sprite_pos_x <= min_x+veloc and sprite_pos_y >= min_y+veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_x = min_x+(flip)
					sprite_pos_y = sprite_pos_y-veloc
				elseif sprite_pos_y <= min_y+veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_y = min_y+(flip)
					SPRITES.MOVE_ALT_X = false
				end
			elseif inv_move_1 == true then
				if sprite_pos_x >= min_x+veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_x = sprite_pos_x-veloc
				elseif sprite_pos_x <= min_x+veloc and sprite_pos_y <= max_y-sprite_tam_y-veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_x = min_x+(flip)
					sprite_pos_y = sprite_pos_y+veloc
				elseif sprite_pos_y >= max_y-sprite_tam_y-veloc and SPRITES.MOVE_ALT_X == false then
					sprite_pos_y = max_y-sprite_tam_y-(flip)
					SPRITES.MOVE_ALT_X = true
				elseif sprite_pos_x <= max_x-sprite_tam_x-veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_x = sprite_pos_x+veloc
				elseif sprite_pos_x >= max_x-sprite_tam_x-veloc and sprite_pos_y >= min_y+veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_x = max_x-sprite_tam_x-(flip)
					sprite_pos_y = sprite_pos_y-veloc
				elseif sprite_pos_y <= min_y+veloc and SPRITES.MOVE_ALT_X == true then
					sprite_pos_y = min_y+(flip)
					SPRITES.MOVE_ALT_X = false
				end
			end

		-- Animación en círculos. -------------------------------------------------------
		elseif SPRITES.MOVE[sistema] >= 53 and SPRITES.MOVE[sistema] <= 58 then
			local maximo, veloc_c = sprite_tam_y, "0.00".. veloc
			if veloc >= 1 and veloc <= 9 then
				veloc_c = "0.00".. veloc
			elseif veloc >= 10 and veloc <= 18 then
				veloc_c = "0.0".. veloc-9
			elseif veloc >= 19 and veloc <= 27 then
				veloc_c = "0.1".. veloc
			elseif veloc >= 28 and veloc <= 36 then
				veloc_c = "0.2".. veloc
			elseif veloc >= 37 and veloc <= 45 then
				veloc_c = "0.3".. veloc
			elseif veloc >= 46 and veloc <= 54 then
				veloc_c = "0.4".. veloc
			elseif veloc >= 55 and veloc <= 62 then
				veloc_c = "0.5".. veloc
			end
			if sprite_tam_x >= sprite_tam_y then
				maximo = sprite_tam_x
			end
			local pos_x, pos_y, inv_move_1, radio = sprite_ant_x, sprite_ant_y, false, (maximo/2)
			if SPRITES.MOVE[sistema] == 54 or SPRITES.MOVE[sistema] == 56 or SPRITES.MOVE[sistema] == 58 then
				inv_move_1 = true
			end
			if SPRITES.MOVE[sistema] == 55 or SPRITES.MOVE[sistema] == 56 then
				radio = (maximo/2)+26
			elseif SPRITES.MOVE[sistema] == 57 or SPRITES.MOVE[sistema] == 58 then
				pos_x, pos_y, radio = CONTROL.ANCHO//2-(sprite_tam_x//2), CONTROL.ALTO_F//2-(sprite_tam_y//2), (CONTROL.ALTO_F//2)-(maximo//2)
			end
			if inv_move_1 == false and SPRITES.ANG_SPRITE+tonumber(veloc_c) <= 6.27 then
				SPRITES.ANG_SPRITE = SPRITES.ANG_SPRITE+tonumber(veloc_c)
			elseif inv_move_1 == false then
				SPRITES.ANG_SPRITE = 0.00
			end
			if inv_move_1 == true and SPRITES.ANG_SPRITE-tonumber(veloc_c) >= 0.00 then
				SPRITES.ANG_SPRITE = SPRITES.ANG_SPRITE-tonumber(veloc_c)
			elseif inv_move_1 == true then
				SPRITES.ANG_SPRITE = 6.27
			end
			sprite_pos_x = pos_x+radio*math.cos(SPRITES.ANG_SPRITE)
			sprite_pos_y = pos_y+radio*math.sin(SPRITES.ANG_SPRITE)

		-- Animación rebotando. ---------------------------------------------------------
		elseif SPRITES.MOVE[sistema] == 59 then
			if sprite_pos_x <= limit_x-sprite_tam_x and SPRITES.MOVE_ALT_X == false then
				sprite_pos_x = sprite_pos_x+veloc
			elseif SPRITES.MOVE_ALT_X == false then
				sprite_pos_x = limit_x-sprite_tam_x
				SPRITES.MOVE_ALT_X = true
			elseif sprite_pos_x >= 0 and SPRITES.MOVE_ALT_X == true then
				sprite_pos_x = sprite_pos_x-veloc
			elseif SPRITES.MOVE_ALT_X == true then
				sprite_pos_x = 0
				SPRITES.MOVE_ALT_X = false
			end
			if sprite_pos_y <= limit_y-sprite_tam_y and SPRITES.MOVE_ALT_Y == false then
				sprite_pos_y = sprite_pos_y+veloc
			elseif SPRITES.MOVE_ALT_Y == false then
				sprite_pos_y = limit_y-sprite_tam_y
				SPRITES.MOVE_ALT_Y = true
			elseif sprite_pos_y >= 0 and SPRITES.MOVE_ALT_Y == true then
				sprite_pos_y = sprite_pos_y-veloc
			elseif SPRITES.MOVE_ALT_Y == true then
				sprite_pos_y = 0
				SPRITES.MOVE_ALT_Y = false
			end

		-- Animación de zoom. -----------------------------------------------------------
		elseif SPRITES.MOVE[sistema] == 60 or SPRITES.MOVE[sistema] == 61 then
			local z_max = sprite_tam_x+(sprite_tam_x/2)
			if SPRITES.MOVE[sistema] == 61 then
				z_max = sprite_tam_x*2
			end
			if SPRITES.ZOOM_SPRITE[1]+veloc <= z_max and SPRITES.ZOOM_SPRITE[2] == false then
				SPRITES.ZOOM_SPRITE[1] = SPRITES.ZOOM_SPRITE[1]+veloc
			elseif SPRITES.ZOOM_SPRITE[2] == false then
				SPRITES.ZOOM_SPRITE[1] = SPRITES.ZOOM_SPRITE[1]+veloc
				SPRITES.ZOOM_SPRITE[2] = true
			elseif SPRITES.ZOOM_SPRITE[1]-veloc >= veloc and SPRITES.ZOOM_SPRITE[2] == true then
				SPRITES.ZOOM_SPRITE[1] = SPRITES.ZOOM_SPRITE[1]-veloc
			elseif SPRITES.ZOOM_SPRITE[2] == true then
				SPRITES.ZOOM_SPRITE[1] = SPRITES.ZOOM_SPRITE[1]-veloc
				SPRITES.ZOOM_SPRITE[2] = false
			end
			local zoom_fix = -(SPRITES.ZOOM_SPRITE[1]/2)
			zoom_x_fix, zoom_y_fix, esc_x, esc_y = zoom_fix/2, zoom_fix/2, esc_x+SPRITES.ZOOM_SPRITE[1]/2, esc_y+SPRITES.ZOOM_SPRITE[1]/2

		-- Controlar animación de sprites (stick derecho). ------------------------------
		elseif SPRITES.MOVE[sistema] == 62 then
			local Right_X_spr, Right_Y_spr = Pads.getRightStick(0)
			if Right_X_spr >= 2 then
				sprite_pos_x = cambiar_valor(sprite_pos_x, 0-sprite_tam_x, limit_x, veloc, true)
			elseif Right_X_spr <= -2 then
				sprite_pos_x = cambiar_valor(sprite_pos_x, 0-sprite_tam_x, limit_x, veloc, false)
			end
			if Right_Y_spr >= 2 then
				sprite_pos_y = cambiar_valor(sprite_pos_y, 0-sprite_tam_y, limit_y, veloc, true)
			elseif Right_Y_spr <= -2 then
				sprite_pos_y = cambiar_valor(sprite_pos_y, 0-sprite_tam_y, limit_y, veloc, false)
			end
		end

		-- Aplicar las posiciones en las animaciones. -----------------------------------
		local pos_flip_x, pos_flip_y = sprite_pos_x, sprite_pos_y
		if (SPRITES.MOVE[sistema] >= 13 and SPRITES.MOVE[sistema] <= 24) or (SPRITES.MOVE[sistema] >= 35 and SPRITES.MOVE[sistema] <= 44) then
			pos_flip_x, pos_flip_y = sprite_pos_y, sprite_pos_x
		end
		if (SPRITES.AUTO_MOVE_SPRITE[sistema] == 1 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 3) then
			if pos_flip_x > SPRITES.MOVE_X then
				SPRITES.FLIP[1] = 0
			elseif pos_flip_x < SPRITES.MOVE_X then
				SPRITES.FLIP[1] = 1
			end
		end
		if (SPRITES.AUTO_MOVE_SPRITE[sistema] == 2 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 3) then
			if pos_flip_y > SPRITES.MOVE_Y then
				SPRITES.FLIP[2] = 1
			elseif pos_flip_y < SPRITES.MOVE_Y then
				SPRITES.FLIP[2] = 0
			end
		end
		if SPRITES.AUTO_MOVE_SPRITE[sistema] >= 4 and SPRITES.AUTO_MOVE_SPRITE[sistema] <= 9 then
			local Right_X_spr, Right_Y_spr = Pads.getRightStick(0)
			if Right_X_spr > 2 and (SPRITES.AUTO_MOVE_SPRITE[sistema] == 4 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 6) then
				SPRITES.FLIP[1] = 0
			elseif Right_X_spr < -2 and (SPRITES.AUTO_MOVE_SPRITE[sistema] == 4 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 6) then
				SPRITES.FLIP[1] = 1
			elseif SPRITES.AUTO_MOVE_SPRITE[sistema] == 7 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 9 then
				SPRITES.FLIP[1] = 1
			end
			if Right_Y_spr > 2 and (SPRITES.AUTO_MOVE_SPRITE[sistema] == 5 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 6) then
				SPRITES.FLIP[2] = 1
			elseif Right_Y_spr < -2 and (SPRITES.AUTO_MOVE_SPRITE[sistema] == 5 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 6) then
				SPRITES.FLIP[2] = 0
			elseif SPRITES.AUTO_MOVE_SPRITE[sistema] == 8 or SPRITES.AUTO_MOVE_SPRITE[sistema] == 9 then
				SPRITES.FLIP[2] = 1
			end
		end
		if (SPRITES.MOVE[sistema] >= 1 and SPRITES.MOVE[sistema] <= 12) or (SPRITES.MOVE[sistema] >= 25 and SPRITES.MOVE[sistema] <= 34) or (SPRITES.MOVE[sistema] >= 45 and SPRITES.MOVE[sistema] <= 62) then
			SPRITES.MOVE_X, pos_x = sprite_pos_x, sprite_pos_x
			SPRITES.MOVE_Y, pos_y = sprite_pos_y, sprite_pos_y
		elseif (SPRITES.MOVE[sistema] >= 13 and SPRITES.MOVE[sistema] <= 24) or (SPRITES.MOVE[sistema] >= 35 and SPRITES.MOVE[sistema] <= 44) then
			SPRITES.MOVE_X, pos_x = sprite_pos_y, sprite_pos_y
			SPRITES.MOVE_Y, pos_y = sprite_pos_x, sprite_pos_x
		end

		-- Aplicar las rotaciones en los sprites. ---------------------------------------
		if SPRITES.SPIN_SPRITE_ON[sistema] >= 1 and SPRITES.SPIN_SPRITE_ON[sistema] <= 62 then
			local inv_move_1, spr_rota, zig_sprite, limi_r1_spr, limi_r2_spr = false, "0.00".. SPRITES.SPIN_SPRITE_ON[sistema], false, 0.52, 5.76
			if SPRITES.SPIN_SPRITE_ON[sistema] >= 1 and  SPRITES.SPIN_SPRITE_ON[sistema] <= 9 then
				spr_rota, inv_move_1 = "0.00".. SPRITES.SPIN_SPRITE_ON[sistema], false
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 10 and SPRITES.SPIN_SPRITE_ON[sistema] <= 18 then
				spr_rota, inv_move_1 = "0.0".. SPRITES.SPIN_SPRITE_ON[sistema]-9, false
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 19 and SPRITES.SPIN_SPRITE_ON[sistema] <= 27 then
				spr_rota, inv_move_1 = "0.1".. SPRITES.SPIN_SPRITE_ON[sistema]-18, false
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 28 and SPRITES.SPIN_SPRITE_ON[sistema] <= 36 then
				spr_rota, inv_move_1 = "0.00".. SPRITES.SPIN_SPRITE_ON[sistema]-27, true
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 37 and SPRITES.SPIN_SPRITE_ON[sistema] <= 45 then
				spr_rota, inv_move_1 = "0.0".. SPRITES.SPIN_SPRITE_ON[sistema]-36, true
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 46 and  SPRITES.SPIN_SPRITE_ON[sistema] <= 54 then
				spr_rota, inv_move_1 = "0.1".. SPRITES.SPIN_SPRITE_ON[sistema]-45, true
			elseif SPRITES.SPIN_SPRITE_ON[sistema] >= 55 and  SPRITES.SPIN_SPRITE_ON[sistema] <= 62 then
				spr_rota, zig_sprite, inv_move_1 = "0.1".. SPRITES.SPIN_SPRITE_ON[sistema]-54, true, SPRITES.SPIN_SPRITE_ALT
			end
			if inv_move_1 == false and SPRITES.SPIN_SPRITE+tonumber(spr_rota) <= 6.27 then
				SPRITES.SPIN_SPRITE = SPRITES.SPIN_SPRITE+tonumber(spr_rota)
				if (SPRITES.SPIN_SPRITE >= limi_r1_spr and SPRITES.SPIN_SPRITE <= (limi_r1_spr+0.9)) and zig_sprite == true then
					SPRITES.SPIN_SPRITE_ALT, SPRITES.SPIN_SPRITE = true, (limi_r1_spr-0.01)
				end
			elseif inv_move_1 == false then
				SPRITES.SPIN_SPRITE = 0.00
			end
			if inv_move_1 == true and SPRITES.SPIN_SPRITE-tonumber(spr_rota) >= 0.00 then
				SPRITES.SPIN_SPRITE = SPRITES.SPIN_SPRITE-tonumber(spr_rota)
				if (SPRITES.SPIN_SPRITE <= limi_r2_spr and SPRITES.SPIN_SPRITE >= (limi_r2_spr-0.9)) and zig_sprite == true then
					SPRITES.SPIN_SPRITE_ALT, SPRITES.SPIN_SPRITE = false, (limi_r2_spr+0.01)
				end
			elseif inv_move_1 == true then
				SPRITES.SPIN_SPRITE = 6.27
			end
			angulo = SPRITES.SPIN_SPRITE
		else
			angulo = 0.00
		end

		-- Aplicar las transparencias en los sprites. -----------------------------------
		if SPRITES.TRAN_SPRITE_ON[sistema] >= 1 and SPRITES.TRAN_SPRITE_ON[sistema] <= 24 then
			local spr_tras, alternar, t_veloc = 0, false, 1
			if SPRITES.TRAN_SPRITE_ON[sistema] >= 1 and SPRITES.TRAN_SPRITE_ON[sistema] <= 8 then
				spr_tras, alternar = SPRITES.TRAN_SPRITE_ON[sistema], false
			elseif SPRITES.TRAN_SPRITE_ON[sistema] >= 9 and SPRITES.TRAN_SPRITE_ON[sistema] <= 16 then
				spr_tras, alternar = SPRITES.TRAN_SPRITE_ON[sistema]-8, true
			elseif SPRITES.TRAN_SPRITE_ON[sistema] >= 17 and SPRITES.TRAN_SPRITE_ON[sistema] <= 24 then
				spr_tras, alternar = SPRITES.TRAN_SPRITE_ON[sistema]-16, nil
			end
			local max_tras_spr, min_tras_spr = 128, 0
			if spr_tras <= 7 then
				max_tras_spr = (16*spr_tras)
			end
			if alternar == nil then
				min_tras_spr = max_tras_spr//2
			end
			if alternar == false then
				SPRITES.TRAN_SPRITE = max_tras_spr
			elseif alternar == true or alternar == nil and SPRITES.ANI_FRAME == frame_speed then
				if SPRITES.TRAN_SPRITE >= min_tras_spr+t_veloc and SPRITES.TRAN_ALT_SPRITE == true then
					SPRITES.TRAN_SPRITE = SPRITES.TRAN_SPRITE-t_veloc
				elseif SPRITES.TRAN_ALT_SPRITE == true then
					SPRITES.TRAN_SPRITE = min_tras_spr
					SPRITES.TRAN_ALT_SPRITE = false
				end
				if SPRITES.TRAN_SPRITE <= max_tras_spr-t_veloc and SPRITES.TRAN_ALT_SPRITE == false then
					SPRITES.TRAN_SPRITE = SPRITES.TRAN_SPRITE+t_veloc
				elseif SPRITES.TRAN_ALT_SPRITE == false then
					SPRITES.TRAN_SPRITE = max_tras_spr
					SPRITES.TRAN_ALT_SPRITE = true
				end
			end
			color_sprite = Color.new(128, 128, 128, SPRITES.TRAN_SPRITE)
		end
	end

	-- Dibujar las animaciones en pantalla. ---------------------------------------------
	if CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.CUSTOM_LIST == true then
		fix = 242
	end
	Graphics.drawImageExtended(SPRITES[SPRITES.SPRITE_SYS[sistema]], (pos_x+fix+(esc_x/2))+zoom_x_fix, (pos_y+(esc_y/2))+zoom_y_fix, SPRITES.X+x_flip, SPRITES.Y+y_flip, (SPRITES.X+x_flip)+largo_x, (SPRITES.Y+y_flip)+alto_y, esc_x, esc_y, angulo, color_sprite)
end

--- Realizar animaciones de los sprites en fondos. --------------------------------------
function fondo_sprites(img, pos_x, pos_y, esc_x, esc_y, angulo, color, def_color)
	local largo_x, alto_y = SPRITES.FONDO_WIDTH_X, SPRITES.FONDO_HEIGHT_Y
	local frame_speed_f, num_filas, num_columnas = 4, SPRITES.FONDO_N_ROWS, SPRITES.FONDO_N_COLUMNS
	-- Controlar la velocidad en las animaciones. ---------------------------------------
	if CONTROL.FPS >= 28 then
		frame_speed_f = 5
	elseif CONTROL.FPS >= 10 then
		frame_speed_f = CONTROL.FPS//6
	elseif CONTROL.FPS <= 9 then
		frame_speed_f = 1
	end

	-- Cambiar las animaciones. ---------------------------------------------------------
	if SPRITES.FONDO_ANI_FRAME >= 1 then
		SPRITES.FONDO_ANI_FRAME = SPRITES.FONDO_ANI_FRAME-1
	else
		SPRITES.FONDO_ANI_FRAME = frame_speed_f
	end

	-- Animación por sprites. -----------------------------------------------------------
	if SPRITES.LAYER == false then
		-- Recorrer las animaciones. ----------------------------------------------------
		if SPRITES.FOND_X == (largo_x*num_columnas)-largo_x and SPRITES.FONDO_ANI_FRAME == frame_speed_f then
			SPRITES.FOND_Y = cambiar_valor(SPRITES.FOND_Y, 0, (alto_y*num_filas)-alto_y, alto_y, true)
			SPRITES.FOND_X = cambiar_valor(SPRITES.FOND_X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
		elseif SPRITES.FONDO_ANI_FRAME == frame_speed_f then
			SPRITES.FOND_X = cambiar_valor(SPRITES.FOND_X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
		end

		-- Dibujar las animaciones en pantalla. -----------------------------------------
		if color == true or color == nil then
			Graphics.drawImageExtended(img, pos_x+(esc_x/2), pos_y+(esc_y/2), SPRITES.FOND_X, SPRITES.FOND_Y, SPRITES.FOND_X+largo_x, SPRITES.FOND_Y+alto_y, esc_x, esc_y, angulo, def_color)
		else
			Graphics.drawImageExtended(img, pos_x+(esc_x/2), pos_y+(esc_y/2), SPRITES.FOND_X, SPRITES.FOND_Y, SPRITES.FOND_X+largo_x, SPRITES.FOND_Y+alto_y, esc_x, esc_y, angulo)
		end

	-- Animación por capas. -------------------------------------------------------------
	elseif SPRITES.LAYER == true then
		-- Define las animaciones de las capas. -----------------------------------------
		esc_x = esc_x-5
		local list_rgb = {CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B}
		if CAMBIOS_EMUS.RGB_COLOR == 1 and color == true then
			list_rgb = {CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.G, CAMBIOS_EMUS.B}
		elseif CAMBIOS_EMUS.RGB_COLOR == 2 and color == true then
			list_rgb = {CAMBIOS_EMUS.R, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.B}
		elseif CAMBIOS_EMUS.RGB_COLOR == 3 and color == true then
			list_rgb = {CAMBIOS_EMUS.R, CAMBIOS_EMUS.G, CAMBIOS_EMUS.COLOR_ACTUAL}
		elseif CAMBIOS_EMUS.RGB_COLOR == 4 and color == true then
			list_rgb = {CAMBIOS_EMUS.R, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL}
		elseif CAMBIOS_EMUS.RGB_COLOR == 5 and color == true then
			list_rgb = {CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.G, CAMBIOS_EMUS.COLOR_ACTUAL}
		elseif CAMBIOS_EMUS.RGB_COLOR == 6 and color == true then
			list_rgb = {CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.B}
		elseif CAMBIOS_EMUS.RGB_COLOR == 7 and color == true then
			list_rgb = {CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL, CAMBIOS_EMUS.COLOR_ACTUAL}
		elseif color == false then
			list_rgb = {128, 128, 128}
		elseif color == nil then
			list_rgb = {0, 80, 120}
		end
		local cuadro_1 = {0, largo_x, 0, alto_y, 0.00, Color.new(list_rgb[1], list_rgb[2], list_rgb[3], 128)}
		local cuadro_2 = {largo_x, (largo_x*2), 0, alto_y, 0.00, Color.new(list_rgb[1], list_rgb[2], list_rgb[3], 128)}
		local cuadro_3 = {0, largo_x, alto_y, (alto_y*2), 0.00, Color.new(list_rgb[1], list_rgb[2], list_rgb[3], 128)}
		local cuadro_4 = {largo_x, (largo_x*2), alto_y, (alto_y*2), 0.00, Color.new(list_rgb[1], list_rgb[2], list_rgb[3], 128)}
		if SPRITES.TRAN_LEVEL <= 0 then
			SPRITES.TRAN_LEVEL = 1
		end
		if SPRITES.TRAN_SPEED <= 0 then
			SPRITES.TRAN_SPEED = 1
		end
		if SPRITES.SPIN_SPEED <= 0 then
			SPRITES.SPIN_SPEED = 1
		end
		if SPRITES.LAYER_MULTI <= 0 then
			SPRITES.LAYER_MULTI = 1
		end
		local regulador = SPRITES.LAYER_SPEED
		local lay_vel, lay_vel2 = 0, 0
		if SPRITES.LAYER_SPEED <= 0 then
			regulador = 0
		elseif SPRITES.LAYER_SPEED >= 1 and SPRITES.LAYER_SPEED <= 9 then
			regulador = tonumber("0.".. SPRITES.LAYER_SPEED)
			lay_vel, lay_vel2 = tonumber(string.format("%.2f", SPRITES.LAYER_MULTI*regulador)), 0.1
			if regulador ~= 0.1 then
				lay_vel2 = tonumber(string.format("%.2f", regulador/2))
			end
		elseif SPRITES.LAYER_SPEED >= 10 and SPRITES.LAYER_SPEED <= 62 then
			regulador = SPRITES.LAYER_SPEED-9
			lay_vel, lay_vel2 = SPRITES.LAYER_MULTI*regulador, 1
			if regulador ~= 1 then
				lay_vel2 = (regulador//2)
			end
		end
		local x_fix1, x_fix2, x_fix3, x_fix4 = esc_x, esc_x, esc_x, esc_x
		local y_fix1, y_fix2, y_fix3, y_fix4 = esc_y, esc_y, esc_y, esc_y
		local pos_lay_1, pos_lay_2, pos_lay_3, pos_lay_4, pos_lay_limite = SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4, esc_x
		local pos_lay_ex1, pos_lay_ex2, pos_lay_ex3, pos_lay_ex4 = SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4
		if (SPRITES.LAYER_TYPE >= 20 and SPRITES.LAYER_TYPE <= 38) then
			pos_lay_1, pos_lay_2, pos_lay_3, pos_lay_4, pos_lay_limite = SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4, esc_y
			pos_lay_ex1, pos_lay_ex2, pos_lay_ex3, pos_lay_ex4 = SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4
		elseif SPRITES.LAYER_TYPE == 59 or SPRITES.LAYER_TYPE == 60 then
			pos_lay_ex3, pos_lay_ex4, pos_lay_1, pos_lay_2, pos_lay_limite = SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.BACK_X, SPRITES.LAYER_X_4, esc_x
		elseif SPRITES.LAYER_TYPE == 61 or SPRITES.LAYER_TYPE == 62 then
			pos_lay_ex3, pos_lay_ex4, pos_lay_1, pos_lay_2, pos_lay_limite = SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.BACK_Y, SPRITES.LAYER_Y_4, esc_y
		end

		-- Cálculos de posicionamientos extras. -----------------------------------------
		local function ani_lay(pos1, pos2, pos_limite, invertir, veloc, nueva_pos)
			if ((pos1 >= pos_limite and invertir == false) or (pos1 <= -pos_limite and invertir == true)) or (((pos1 >= pos_limite and invertir == false) or (pos1 <= -pos_limite and invertir == true)) and veloc == nil) then
				if invertir == false then
					pos1 = pos2-nueva_pos
				elseif invertir == true then
					pos1 = pos2+nueva_pos
				end
			elseif veloc ~= nil then
				pos1 = pos1+veloc
			end
			return pos1
		end
		local function snake_fx()
			if SPRITES.LAYER_TYPE == 3 or SPRITES.LAYER_TYPE == 4 or SPRITES.LAYER_TYPE == 22 or SPRITES.LAYER_TYPE == 23 then
				local vel_sna = (SPRITES.LAYER_MULTI*regulador)
				if SPRITES.ALTERNATE == true then
					pos_lay_ex1, pos_lay_ex2 = pos_lay_ex1+vel_sna, pos_lay_ex2-vel_sna
				elseif SPRITES.ALTERNATE == false then
					pos_lay_ex1, pos_lay_ex2 = pos_lay_ex1-vel_sna, pos_lay_ex2+vel_sna
				end
				if pos_lay_ex1 <= -28 then
					SPRITES.ALTERNATE = true
				elseif pos_lay_ex1 >= 28 then
					SPRITES.ALTERNATE = false
				end
			elseif SPRITES.LAYER_TYPE == 7 or SPRITES.LAYER_TYPE == 26 then
				if SPRITES.ALTERNATE == false and pos_lay_1 >= pos_lay_limite/2 then
					SPRITES.ALTERNATE = true
				elseif SPRITES.ALTERNATE == true and pos_lay_1 <= (-pos_lay_limite)/2 then
					SPRITES.ALTERNATE = false
				end
			end
		end

		-- Realizar las animaciones. ----------------------------------------------------
		-- Animaciones generales. -------------------------------------------------------
		if (SPRITES.LAYER_TYPE >= 1 and SPRITES.LAYER_TYPE <= 13) or (SPRITES.LAYER_TYPE >= 20 and SPRITES.LAYER_TYPE <= 32) or (SPRITES.LAYER_TYPE >= 59 and SPRITES.LAYER_TYPE <= 62) then
			local inv_reve, reve = true, false
			local wanted = {0; 1; 0; 1; 0; 1; 0; 0; 1; 0; 1; 0; 1; 0; 1; 0; 0; 0; 0; 0; 1; 0; 1; 0; 1; 0; 0; 1; 0; 1; 0;
							1; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 0; 1;};
			local wanted2 = {0; 0; 0; 0; 1; 1; 0; 0; 0; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 0; 1; 1; 0;
							0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 1; 1;};
			if (SPRITES.ALTERNATE == true and (SPRITES.LAYER_TYPE == 7 or SPRITES.LAYER_TYPE == 26)) or (lay_vel >= 0.1 and wanted[SPRITES.LAYER_TYPE] == 1) then
				lay_vel, lay_vel2, inv_reve, reve = -lay_vel, -lay_vel2, false, true
			end
			pos_lay_1 = ani_lay(pos_lay_1, pos_lay_2, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			pos_lay_2 = ani_lay(pos_lay_2, pos_lay_1, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			pos_lay_1 = ani_lay(pos_lay_1, pos_lay_2, pos_lay_limite, reve, nil, pos_lay_limite)
			pos_lay_2 = ani_lay(pos_lay_2, pos_lay_1, pos_lay_limite, reve, nil, pos_lay_limite)
			if wanted2[SPRITES.LAYER_TYPE] == 1 then
				if SPRITES.LAYER_TYPE == 10 or SPRITES.LAYER_TYPE == 11 or SPRITES.LAYER_TYPE == 29 or SPRITES.LAYER_TYPE == 30 or (SPRITES.LAYER_TYPE >= 59 and SPRITES.LAYER_TYPE <= 62) then
					pos_lay_ex3 = ani_lay(pos_lay_ex3, pos_lay_ex4, pos_lay_limite, inv_reve, -lay_vel2, pos_lay_limite)
					pos_lay_ex4 = ani_lay(pos_lay_ex4, pos_lay_ex3, pos_lay_limite, inv_reve, -lay_vel2, pos_lay_limite)
					pos_lay_ex3 = ani_lay(pos_lay_ex3, pos_lay_ex4, pos_lay_limite, inv_reve, nil, pos_lay_limite)
					pos_lay_ex4 = ani_lay(pos_lay_ex4, pos_lay_ex3, pos_lay_limite, inv_reve, nil, pos_lay_limite)
				else
					pos_lay_ex3 = ani_lay(pos_lay_ex3, 0, pos_lay_limite, inv_reve, -lay_vel2, pos_lay_limite)
				end
			elseif SPRITES.LAYER_TYPE == 12 or SPRITES.LAYER_TYPE == 13 or SPRITES.LAYER_TYPE == 31 or SPRITES.LAYER_TYPE == 32 then
				pos_lay_ex3 = pos_lay_1
			end
			snake_fx()
			if pos_lay_1 == pos_lay_2 then
				pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4 = 0, pos_lay_limite, 0, 0
				if SPRITES.LAYER_TYPE == 3 or SPRITES.LAYER_TYPE == 4 or SPRITES.LAYER_TYPE == 22 or SPRITES.LAYER_TYPE == 23 then
					pos_lay_ex1, pos_lay_ex2 = 0, 0
				elseif SPRITES.LAYER_TYPE == 10 or SPRITES.LAYER_TYPE == 11 or SPRITES.LAYER_TYPE == 29 or SPRITES.LAYER_TYPE == 30 then
					pos_lay_ex4 = pos_lay_limite
				elseif SPRITES.LAYER_TYPE >= 59 and SPRITES.LAYER_TYPE <= 62 then
					pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4 = 0, pos_lay_limite, 0, pos_lay_limite
				end
			end

		-- Animación panorámica. --------------------------------------------------------
		elseif (SPRITES.LAYER_TYPE >= 14 and SPRITES.LAYER_TYPE <= 17) or (SPRITES.LAYER_TYPE >= 33 and SPRITES.LAYER_TYPE <= 36) then
			local reve = false
			if SPRITES.LAYER_TYPE == 15 or SPRITES.LAYER_TYPE == 17 or SPRITES.LAYER_TYPE == 34 or SPRITES.LAYER_TYPE == 36 then
				lay_vel, reve = -lay_vel, true
			end
			pos_lay_ex3 = ani_lay(pos_lay_ex3, pos_lay_1+lay_vel, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			if SPRITES.LAYER_TYPE == 16 or SPRITES.LAYER_TYPE == 17 or SPRITES.LAYER_TYPE == 35 or SPRITES.LAYER_TYPE == 36 then
				pos_lay_ex4 = ani_lay(pos_lay_ex4, pos_lay_ex3, pos_lay_limite, reve, lay_vel, pos_lay_limite)
				pos_lay_2 = ani_lay(pos_lay_2, pos_lay_ex4, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			else
				pos_lay_2 = ani_lay(pos_lay_2, pos_lay_ex3, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			end
			pos_lay_1 = ani_lay(pos_lay_1, pos_lay_2, pos_lay_limite, reve, lay_vel, pos_lay_limite)
			if pos_lay_1 == pos_lay_2 and reve == true then
				pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4 = pos_lay_ex3-pos_lay_limite, pos_lay_ex3-pos_lay_limite, 0, pos_lay_ex3-pos_lay_limite
			elseif pos_lay_1 == pos_lay_2 and reve == false then
				pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4 = pos_lay_limite, pos_lay_limite, 0, pos_lay_limite
			end

		-- Animación de entrecruzar la pantalla completa. -------------------------------
		elseif (SPRITES.LAYER_TYPE == 18 or SPRITES.LAYER_TYPE == 37) then
			if pos_lay_1 >= pos_lay_limite+lay_vel then
				pos_lay_1, pos_lay_2 = -pos_lay_limite, pos_lay_limite
			else
				pos_lay_1, pos_lay_2 = pos_lay_1+lay_vel, pos_lay_2-lay_vel
			end

		-- Animación de entrecruzar media pantalla. -------------------------------------
		elseif (SPRITES.LAYER_TYPE == 19 or SPRITES.LAYER_TYPE == 38) then
			if ((pos_lay_1 >= pos_lay_limite/6 and SPRITES.ALTERNATE == false) or (pos_lay_1 <= -(pos_lay_limite/6) and SPRITES.ALTERNATE == true)) then
				if SPRITES.ALTERNATE == true then
					SPRITES.ALTERNATE = false
				else
					SPRITES.ALTERNATE = true
				end
			else
				if SPRITES.ALTERNATE == false then
					pos_lay_1, pos_lay_2 = pos_lay_1+lay_vel, pos_lay_2-lay_vel
				elseif SPRITES.ALTERNATE == true then
					pos_lay_1, pos_lay_2 = pos_lay_1-lay_vel, pos_lay_2+lay_vel
				end
			end

		-- Animación de remolino. -------------------------------------------------------
		elseif (SPRITES.LAYER_TYPE == 39 or SPRITES.LAYER_TYPE == 40) then
			local veloc_c, hori, veti, radio = "0.00".. lay_vel, false, false, (20*SPRITES.LAYER_MULTI)
			local pos_x1, pos_x2, pos_y = (CONTROL.ANCHO/2), (CONTROL.ANCHO/2), 0
			if SPRITES.LAYER_SPEED >= 1 and SPRITES.LAYER_SPEED <= 9 then
				veloc_c, hori, veti = "0.00".. SPRITES.LAYER_SPEED, false, false
			elseif SPRITES.LAYER_SPEED >= 10 and SPRITES.LAYER_SPEED <= 18 then
				veloc_c, hori, veti = "0.0".. SPRITES.LAYER_SPEED-9, false, false
			elseif SPRITES.LAYER_SPEED >= 19 and SPRITES.LAYER_SPEED <= 27 then
				veloc_c, hori, veti = "0.1".. SPRITES.LAYER_SPEED-18, false, false
			elseif SPRITES.LAYER_SPEED >= 28 and SPRITES.LAYER_SPEED <= 36 then
				veloc_c, hori, veti, pos_x1, pos_x2 = "0.0".. SPRITES.LAYER_SPEED-27, true, false, 0-radio, 0+radio
			elseif SPRITES.LAYER_SPEED >= 37 and SPRITES.LAYER_SPEED <= 45 then
				veloc_c, hori, veti, pos_x1, pos_x2 = "0.".. SPRITES.LAYER_SPEED-36, true, false, 0-radio, 0+radio
			elseif SPRITES.LAYER_SPEED >= 46 and SPRITES.LAYER_SPEED <= 54 then
				veloc_c, hori, veti, pos_x1, pos_x2 = "0.0".. SPRITES.LAYER_SPEED-45, false, true, 0, 0
			elseif SPRITES.LAYER_SPEED >= 55 and SPRITES.LAYER_SPEED <= 62 then
				veloc_c, hori, veti, pos_x1, pos_x2 = "0.".. SPRITES.LAYER_SPEED-54, false, true, 0, 0
			end
			if SPRITES.LAYER_TYPE == 39 then
				if SPRITES.ANG[1]+tonumber(veloc_c) <= 6.27 then
					SPRITES.ANG[1] = SPRITES.ANG[1]+tonumber(veloc_c)
					SPRITES.ANG[2] = SPRITES.ANG[2]+tonumber(veloc_c)
				else
					SPRITES.ANG[1] = 0.00
					SPRITES.ANG[2] = 3.14
				end
			elseif SPRITES.LAYER_TYPE == 40 then
				if SPRITES.ANG[1]-tonumber(veloc_c) >= 0.00 then
					SPRITES.ANG[1] = SPRITES.ANG[1]-tonumber(veloc_c)
					SPRITES.ANG[2] = SPRITES.ANG[2]-tonumber(veloc_c)
				else
					SPRITES.ANG[1] = 6.27
					SPRITES.ANG[2] = 3.14
				end
			end
			if veti == false and (hori == true or hori == false) then
				pos_lay_1 = pos_x1+radio*math.cos(SPRITES.ANG[1])
				pos_lay_2 = pos_x2+radio*math.cos(SPRITES.ANG[2])
			end
			if hori == false and (veti == true or veti == false) then
				pos_lay_ex1 = pos_y+radio*math.sin(SPRITES.ANG[1])
				pos_lay_ex2 = pos_y+radio*math.sin(SPRITES.ANG[2])
			end
			if hori == false and veti == false then
				pos_lay_1 = pos_lay_1-CONTROL.ANCHO/2
				pos_lay_2 = pos_lay_2-CONTROL.ANCHO/2
			end

		-- Animación de zoom. -----------------------------------------------------------
		elseif SPRITES.LAYER_TYPE >= 41 and SPRITES.LAYER_TYPE <= 58 then
			local z_max = 50*SPRITES.LAYER_MULTI
			if SPRITES.ZOOM[1]+regulador <= z_max and SPRITES.ZOOM[2] == false then
				SPRITES.ZOOM[1] = SPRITES.ZOOM[1]+regulador
			elseif SPRITES.ZOOM[2] == false then
				SPRITES.ZOOM[1] = SPRITES.ZOOM[1]+regulador
				SPRITES.ZOOM[2] = true
			elseif SPRITES.ZOOM[1]-regulador >= regulador and SPRITES.ZOOM[2] == true then
				SPRITES.ZOOM[1] = SPRITES.ZOOM[1]-regulador
			elseif SPRITES.ZOOM[2] == true then
				SPRITES.ZOOM[1] = SPRITES.ZOOM[1]-regulador
				SPRITES.ZOOM[2] = false
			end
			local z_tipo, z_act, z_fix = 1, false, -(SPRITES.ZOOM[1]/2)
			if SPRITES.LAYER_TYPE >= 41 and SPRITES.LAYER_TYPE <= 49 then
				z_tipo, z_act = SPRITES.LAYER_TYPE-40, false
			elseif SPRITES.LAYER_TYPE >= 50 and SPRITES.LAYER_TYPE <= 58 then
				z_tipo, z_act = SPRITES.LAYER_TYPE-49, true
			end
			local z_lay_1 = {0, 1, 0, 1, 1, 1, 0, 1, 1}
			local z_lay_2 = {0, 1, 1, 0, 0, 1, 1, 1, 1}
			local z_lay_3 = {1, 0, 1, 0, 1, 1, 1, 0, 1}
			local z_lay_4 = {1, 0, 0, 1, 1, 0, 1, 1, 1}
			if z_lay_1[z_tipo] == 1 then
				if (SPRITES.LAYER_TYPE == 53 or SPRITES.LAYER_TYPE == 57 or SPRITES.LAYER_TYPE == 58) and z_act == true then
					pos_lay_ex3, pos_lay_3, x_fix1, y_fix1 = z_fix/2, z_fix/2, esc_x+SPRITES.ZOOM[1]/2, esc_y+SPRITES.ZOOM[1]/2
				else
					pos_lay_ex3, pos_lay_3, x_fix1, y_fix1 = z_fix, z_fix, esc_x+SPRITES.ZOOM[1], esc_y+SPRITES.ZOOM[1]
				end
			end
			if z_lay_2[z_tipo] == 1 then
				if (SPRITES.LAYER_TYPE == 51 or SPRITES.LAYER_TYPE == 55) and z_act == true then
					pos_lay_ex4, pos_lay_4, x_fix2, y_fix2 = z_fix/2, z_fix/2, esc_x+SPRITES.ZOOM[1]/2, esc_y+SPRITES.ZOOM[1]/2
				else
					pos_lay_ex4, pos_lay_4, x_fix2, y_fix2 = z_fix, z_fix, esc_x+SPRITES.ZOOM[1], esc_y+SPRITES.ZOOM[1]
				end
			end
			if z_lay_3[z_tipo] == 1 then
				if (SPRITES.LAYER_TYPE == 52 or SPRITES.LAYER_TYPE == 56 or SPRITES.LAYER_TYPE == 58) and z_act == true then
					pos_lay_2, pos_lay_ex2, x_fix3, y_fix3 = z_fix/2, z_fix/2, esc_x+SPRITES.ZOOM[1]/2, esc_y+SPRITES.ZOOM[1]/2
				else
					pos_lay_2, pos_lay_ex2, x_fix3, y_fix3 = z_fix, z_fix, esc_x+SPRITES.ZOOM[1], esc_y+SPRITES.ZOOM[1]
				end
			end
			if z_lay_4[z_tipo] == 1 then
				if (SPRITES.LAYER_TYPE == 50 or SPRITES.LAYER_TYPE == 54 or SPRITES.LAYER_TYPE == 58) and z_act == true then
					pos_lay_1, pos_lay_ex1, x_fix4, y_fix4 = z_fix/2, z_fix/2, esc_x+SPRITES.ZOOM[1]/2, esc_y+SPRITES.ZOOM[1]/2
				else
					pos_lay_1, pos_lay_ex1, x_fix4, y_fix4 = z_fix, z_fix, esc_x+SPRITES.ZOOM[1], esc_y+SPRITES.ZOOM[1]
				end
			end
		end

		-- Aplicar las posiciones en las animaciones. -----------------------------------
		if (SPRITES.LAYER_TYPE >= 1 and SPRITES.LAYER_TYPE <= 19) or SPRITES.LAYER_TYPE == 39 or SPRITES.LAYER_TYPE == 40 then
			SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4 = pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4
			SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2 = pos_lay_ex1, pos_lay_ex2
			SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
		elseif SPRITES.LAYER_TYPE >= 20 and SPRITES.LAYER_TYPE <= 38 then
			SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4 = pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4
			SPRITES.LAYER_X_1, SPRITES.LAYER_X_2 = pos_lay_ex1, pos_lay_ex2
			SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
		elseif SPRITES.LAYER_TYPE >= 41 and SPRITES.LAYER_TYPE <= 58 then
			SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.BACK_X = pos_lay_1, pos_lay_2, pos_lay_ex3, pos_lay_ex4
			SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.BACK_Y = pos_lay_ex1, pos_lay_ex2, pos_lay_3, pos_lay_4
		elseif SPRITES.LAYER_TYPE == 59 or SPRITES.LAYER_TYPE == 60 then
			SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.BACK_X, SPRITES.LAYER_X_4 = pos_lay_ex3, pos_lay_ex4, pos_lay_1, pos_lay_2
		elseif SPRITES.LAYER_TYPE == 61 or SPRITES.LAYER_TYPE == 62 then
			SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.BACK_Y, SPRITES.LAYER_Y_4 = pos_lay_ex3, pos_lay_ex4, pos_lay_1, pos_lay_2
		elseif SPRITES.LAYER_TYPE == 0 then
			SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4 = 0, 0, 0, 0
			SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4 = 0, 0, 0, 0
			SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
		end

		-- Aplicar las rotaciones en las animaciones. -----------------------------------
		if SPRITES.SPIN_TYPE >= 1 and SPRITES.SPIN_TYPE <= 30 then
			-- Determinar velocidad de giro. --------------------------------------------
			local v_r_final, ro_l_act, limi_r1, limi_r2, v_r_final, t_rota = 0.01, false, 0.52, 5.76, "0.00".. SPRITES.SPIN_SPEED, SPRITES.SPIN_TYPE
			if SPRITES.SPIN_SPEED <= 9 then
				v_r_final = "0.00".. SPRITES.SPIN_SPEED
			elseif SPRITES.SPIN_SPEED >= 10 and SPRITES.SPIN_SPEED <= 18 then
				v_r_final = "0.0".. SPRITES.SPIN_SPEED-9
			elseif SPRITES.SPIN_SPEED >= 19 and SPRITES.SPIN_SPEED <= 27 then
				v_r_final = "0.1".. SPRITES.SPIN_SPEED-18
			elseif SPRITES.SPIN_SPEED >= 28 and SPRITES.SPIN_SPEED <= 36 then
				v_r_final, ro_l_act, limi_r1, limi_r2 = "0.0".. SPRITES.SPIN_SPEED-27, true, 0.52, 5.76
			elseif SPRITES.SPIN_SPEED >= 37 and SPRITES.SPIN_SPEED <= 45 then
				v_r_final, ro_l_act, limi_r1, limi_r2 = "0.0".. SPRITES.SPIN_SPEED-36, true, 3.05, 0.09
			elseif SPRITES.SPIN_SPEED >= 46 and SPRITES.SPIN_SPEED <= 54 then
				v_r_final, ro_l_act, limi_r1, limi_r2 = "0.0".. SPRITES.SPIN_SPEED-45, true, 1.57, 4.71
			elseif SPRITES.SPIN_SPEED >= 55 and SPRITES.SPIN_SPEED <= 62 then
				v_r_final, ro_l_act, limi_r1, limi_r2 = "0.0".. SPRITES.SPIN_SPEED-54, true, 6.18, 0.09
			end
			if SPRITES.SPIN_TYPE <= 15 then
				if ro_l_act == false then
					SPRITES.ALTERNATE_R = false
				end
			elseif SPRITES.SPIN_TYPE >= 16 and SPRITES.SPIN_TYPE <= 30 then
				if ro_l_act == false then
					SPRITES.ALTERNATE_R = true
				end
				t_rota = t_rota-15
			end

			-- Realizar las rotaciones de capas. ----------------------------------------
			if SPRITES.ALTERNATE_R == false and SPRITES.SPIN+tonumber(v_r_final) <= 6.27 then
				SPRITES.SPIN = SPRITES.SPIN+tonumber(v_r_final)
				if (SPRITES.SPIN >= limi_r1 and SPRITES.SPIN <= (limi_r1+0.9)) and ro_l_act == true then
					SPRITES.ALTERNATE_R, SPRITES.SPIN = true, (limi_r1-0.01)
				end
			elseif SPRITES.ALTERNATE_R == false then
				SPRITES.SPIN = 0.00
			end
			if SPRITES.ALTERNATE_R == true and SPRITES.SPIN-tonumber(v_r_final) >= 0.00 then
				SPRITES.SPIN = SPRITES.SPIN-tonumber(v_r_final)
				if (SPRITES.SPIN <= limi_r2 and SPRITES.SPIN >= (limi_r2-0.9)) and ro_l_act == true then
					SPRITES.ALTERNATE_R, SPRITES.SPIN = false, (limi_r2+0.01)
				end
			elseif SPRITES.ALTERNATE_R == true then
				SPRITES.SPIN = 6.27
			end
			local r_lay_1 = {1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1}
			local r_lay_2 = {0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1}
			local r_lay_3 = {0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1}
			local r_lay_4 = {0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1}
			if r_lay_1[t_rota] == 1 then cuadro_1[5] = SPRITES.SPIN end
			if r_lay_2[t_rota] == 1 then cuadro_2[5] = SPRITES.SPIN end
			if r_lay_3[t_rota] == 1 then cuadro_3[5] = SPRITES.SPIN end
			if r_lay_4[t_rota] == 1 then cuadro_4[5] = SPRITES.SPIN end
		end

		-- Aplicar las transparencias en las animaciones. -------------------------------
		if SPRITES.TRAN_TYPE >= 1 and SPRITES.TRAN_TYPE <= 20 then
			-- Cambiar los niveles de transparencia y alternar entre las capas. ---------
			local function tras_apli(mini, maxi, n_capa, n_vel_t, alterna)
				if SPRITES.TRAN_ALT[n_capa] == true then
					if SPRITES.TRAN[n_capa] <= maxi-n_vel_t then
						SPRITES.TRAN[n_capa] = SPRITES.TRAN[n_capa]+n_vel_t;
					else
						SPRITES.TRAN[n_capa], SPRITES.TRAN_ALT[n_capa] = maxi, false
					end
				elseif SPRITES.TRAN_ALT[n_capa] == false and SPRITES.TRAN[n_capa] <= maxi then
					if SPRITES.TRAN[n_capa] >= mini+n_vel_t then
						SPRITES.TRAN[n_capa] = SPRITES.TRAN[n_capa]-n_vel_t
					else
						SPRITES.TRAN[n_capa], SPRITES.TRAN_ALT[n_capa] = mini, true
					end
				elseif SPRITES.TRAN_ALT[n_capa] == false and SPRITES.TRAN[n_capa] > maxi then
					SPRITES.TRAN[n_capa] = maxi
				end
				if alterna == true and SPRITES.ACTIVATE_ALTER_T == true then
					if SPRITES.TRAN_TYPE >= 16 and SPRITES.TRAN_TYPE <= 20 then
						if SPRITES.TRAN_TYPE == 16 or SPRITES.TRAN_TYPE == 17 or SPRITES.TRAN_TYPE == 20 then
							SPRITES.TRAN_ALT[1], SPRITES.TRAN[1] = true, mini
						end
						if SPRITES.TRAN_TYPE == 16 or SPRITES.TRAN_TYPE == 20 or SPRITES.TRAN_TYPE == 17 or SPRITES.TRAN_TYPE == 19 then
							SPRITES.TRAN_ALT[3], SPRITES.TRAN[3] = false, maxi
						end
						if SPRITES.TRAN_TYPE == 16 or SPRITES.TRAN_TYPE == 20 or SPRITES.TRAN_TYPE == 18 or SPRITES.TRAN_TYPE == 19 then
							if SPRITES.TRAN_TYPE == 18 then
								SPRITES.TRAN_ALT[4], SPRITES.TRAN[4] = true, mini
							else
								SPRITES.TRAN_ALT[4], SPRITES.TRAN[4] = false, maxi
							end
						end
						if SPRITES.TRAN_TYPE == 18 or SPRITES.TRAN_TYPE == 19 or SPRITES.TRAN_TYPE == 20 then
							if SPRITES.TRAN_TYPE == 20 or SPRITES.TRAN_TYPE == 19 then
								SPRITES.TRAN_ALT[2], SPRITES.TRAN[2] = true, mini
							else
								SPRITES.TRAN_ALT[2], SPRITES.TRAN[2] = false, maxi
							end
						end
					else
						SPRITES.TRAN_ALT[1], SPRITES.TRAN[1] = true, mini
						SPRITES.TRAN_ALT[2], SPRITES.TRAN[2] = false, maxi
						SPRITES.TRAN_ALT[3], SPRITES.TRAN[3] = true, mini
						SPRITES.TRAN_ALT[4], SPRITES.TRAN[4] = false, maxi
					end
					SPRITES.ACTIVATE_ALTER_T = false
				end
			end

			-- Determinar el tipo de transparencia. -------------------------------------
			local niv_tras, velo_tras, t_capas_act, act_tras_min = 8, 1, false, false
			if SPRITES.TRAN_LEVEL <= 8 then
				niv_tras, SPRITES.ALTERNATE_T = SPRITES.TRAN_LEVEL, false
			elseif SPRITES.TRAN_LEVEL >= 9 and SPRITES.TRAN_LEVEL <= 16 then
				niv_tras, SPRITES.ALTERNATE_T = SPRITES.TRAN_LEVEL-8, true
			elseif SPRITES.TRAN_LEVEL >= 17 and SPRITES.TRAN_LEVEL <= 24 then
				niv_tras, SPRITES.ALTERNATE_T, t_capas_act, act_tras_min = SPRITES.TRAN_LEVEL-16, true, false, true
			elseif SPRITES.TRAN_LEVEL >= 25 and SPRITES.TRAN_LEVEL <= 32 then
				niv_tras, SPRITES.ALTERNATE_T, t_capas_act, act_tras_min = SPRITES.TRAN_LEVEL-24, true, true, false
			elseif SPRITES.TRAN_LEVEL >= 33 and SPRITES.TRAN_LEVEL <= 40 then
				niv_tras, SPRITES.ALTERNATE_T, t_capas_act, act_tras_min = SPRITES.TRAN_LEVEL-32, true, true, true
			end

			-- Determinar la velocidad y rangos de transparencia. -----------------------
			if SPRITES.TRAN_SPEED <= 16 then
				velo_tras = SPRITES.TRAN_SPEED
			else
				velo_tras = 1
			end
			local max_tras_l, min_tras_l = 128, 0
			if niv_tras <= 7 then
				max_tras_l = (16*niv_tras)
			end
			if act_tras_min == true then
				min_tras_l = max_tras_l//2
			end
			local trasp_lay_1 = {1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1}
			local trasp_lay_2 = {0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1}
			local trasp_lay_3 = {0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1}
			local trasp_lay_4 = {0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1}
			if t_capas_act == false and SPRITES.ALTERNATE_T == false then
				SPRITES.TRAN[1], SPRITES.TRAN[2], SPRITES.TRAN[3], SPRITES.TRAN[4] = max_tras_l, max_tras_l, max_tras_l, max_tras_l
			elseif SPRITES.ALTERNATE_T == true and SPRITES.FONDO_ANI_FRAME == frame_speed_f then
				if trasp_lay_1[SPRITES.TRAN_TYPE] == 1 then tras_apli(min_tras_l, max_tras_l, 1, velo_tras, t_capas_act) end
				if trasp_lay_2[SPRITES.TRAN_TYPE] == 1 then tras_apli(min_tras_l, max_tras_l, 2, velo_tras, t_capas_act) end
				if trasp_lay_3[SPRITES.TRAN_TYPE] == 1 then tras_apli(min_tras_l, max_tras_l, 3, velo_tras, t_capas_act) end
				if trasp_lay_4[SPRITES.TRAN_TYPE] == 1 then tras_apli(min_tras_l, max_tras_l, 4, velo_tras, t_capas_act) end
			end
			if trasp_lay_1[SPRITES.TRAN_TYPE] == 1 then
				cuadro_1[6] = Color.new(list_rgb[1], list_rgb[2], list_rgb[3], SPRITES.TRAN[1])
			end
			if trasp_lay_2[SPRITES.TRAN_TYPE] == 1 then
				cuadro_2[6] = Color.new(list_rgb[1], list_rgb[2], list_rgb[3], SPRITES.TRAN[2])
			end
			if trasp_lay_3[SPRITES.TRAN_TYPE] == 1 then
				cuadro_3[6] = Color.new(list_rgb[1], list_rgb[2], list_rgb[3], SPRITES.TRAN[3])
			end
			if trasp_lay_4[SPRITES.TRAN_TYPE] == 1 then
				cuadro_4[6] = Color.new(list_rgb[1], list_rgb[2], list_rgb[3], SPRITES.TRAN[4])
			end
		end

		-- Dibujar las animaciones en pantalla (capa 2). --------------------------------
		Graphics.drawImageExtended(img, 0+(x_fix2/2)+SPRITES.BACK_X, 0+(y_fix2/2)+SPRITES.BACK_Y, cuadro_2[1], cuadro_2[3], cuadro_2[2], cuadro_2[4], x_fix2, y_fix2, cuadro_2[5], cuadro_2[6])
		if SPRITES.LAYER_TYPE >= 59 and SPRITES.LAYER_TYPE <= 62 then
			Graphics.drawImageExtended(img, 0+(x_fix2/2)+SPRITES.LAYER_X_4, 0+(y_fix2/2)+SPRITES.LAYER_Y_4, cuadro_2[1], cuadro_2[3], cuadro_2[2], cuadro_2[4], x_fix2, y_fix2, cuadro_2[5], cuadro_2[6])
		end

		-- Dibujar las animaciones en pantalla (capa 3). --------------------------------
		Graphics.drawImageExtended(img, 0+(x_fix3/2)+SPRITES.LAYER_X_2, 0+(y_fix3/2)+SPRITES.LAYER_Y_2, cuadro_3[1], cuadro_3[3], cuadro_3[2], cuadro_3[4], x_fix3, y_fix3, cuadro_3[5], cuadro_3[6])
		if SPRITES.LAYER_TYPE == 8 or SPRITES.LAYER_TYPE == 9 or SPRITES.LAYER_TYPE == 27 or SPRITES.LAYER_TYPE == 28 then
			Graphics.drawImageExtended(img, 0+(x_fix3/2)+SPRITES.LAYER_X_1, 0+(y_fix3/2)+SPRITES.LAYER_Y_1, cuadro_3[1], cuadro_3[3], cuadro_3[2], cuadro_3[4], x_fix3, y_fix3, cuadro_3[5], cuadro_3[6])
		end

		-- Dibujar las animaciones en pantalla (capa 4). --------------------------------
		Graphics.drawImageExtended(img, 0+(x_fix4/2)+SPRITES.LAYER_X_1, 0+(y_fix4/2)+SPRITES.LAYER_Y_1, cuadro_4[1], cuadro_4[3], cuadro_4[2], cuadro_4[4], x_fix4, y_fix4, cuadro_4[5], cuadro_4[6])
		if SPRITES.LAYER_TYPE == 8 or SPRITES.LAYER_TYPE == 9 or SPRITES.LAYER_TYPE == 27 or SPRITES.LAYER_TYPE == 28 then
			Graphics.drawImageExtended(img, 0+(x_fix4/2)+SPRITES.LAYER_X_2, 0+(y_fix4/2)+SPRITES.LAYER_Y_2, cuadro_4[1], cuadro_4[3], cuadro_4[2], cuadro_4[4], x_fix4, y_fix4, cuadro_4[5], cuadro_4[6])
		end

		-- Dibujar las animaciones en pantalla (capa 2 junto a capa 1). -----------------
		if SPRITES.LAYER_TYPE == 10 or SPRITES.LAYER_TYPE == 11 or SPRITES.LAYER_TYPE == 29 or SPRITES.LAYER_TYPE == 30 or (SPRITES.LAYER_TYPE >= 14 and SPRITES.LAYER_TYPE <= 17) or (SPRITES.LAYER_TYPE >= 33 and SPRITES.LAYER_TYPE <= 36) then
			Graphics.drawImageExtended(img, 0+(x_fix2/2)+SPRITES.LAYER_X_4, 0+(y_fix2/2)+SPRITES.LAYER_Y_4, cuadro_2[1], cuadro_2[3], cuadro_2[2], cuadro_2[4], x_fix2, y_fix2, cuadro_2[5], cuadro_2[6])
		end

		-- Dibujar las animaciones en pantalla (capa 1). --------------------------------
		Graphics.drawImageExtended(img, 0+(x_fix1/2)+SPRITES.LAYER_X_3, 0+(y_fix1/2)+SPRITES.LAYER_Y_3, cuadro_1[1], cuadro_1[3], cuadro_1[2], cuadro_1[4], x_fix1, y_fix1, cuadro_1[5], cuadro_1[6])
	end
end

--- Realizar animación para la ejecución de juegos. -------------------------------------
function black_blur()
	local multi_n_vel, actual_n_vel, centrar_img_x, centrar_img_y = 3, 4, CONTROL.IMG_ANCHO, CONTROL.IMG_ALTO
	local pant_x, pant_y = (CONTROL.ANCHO//2)-(CONTROL.IMG_X//2), (CONTROL.ALTO_F//2)-(CONTROL.IMG_Y//2)
	for actual_n = 0, 128, actual_n_vel do
		CONTROL.FPS = Screen.getFPS(1)
		dibujar_fondos()
		if LISTAS.SCREENSHOT_FULL == false then
			if (centrar_img_x <= pant_x+(actual_n_vel*multi_n_vel) and centrar_img_x >= pant_x-(actual_n_vel*multi_n_vel)) then
				centrar_img_x = pant_x
			elseif not (centrar_img_x >= pant_x+(actual_n_vel*multi_n_vel) and centrar_img_x <= pant_x-(actual_n_vel*multi_n_vel)) then
				if centrar_img_x >= pant_x+(actual_n_vel*multi_n_vel) then
					centrar_img_x = centrar_img_x-(actual_n_vel*multi_n_vel)
				elseif centrar_img_x <= pant_x-(actual_n_vel*multi_n_vel) then
					centrar_img_x = centrar_img_x+(actual_n_vel*multi_n_vel)
				end
			end
			if (centrar_img_y <= pant_y+(actual_n_vel*multi_n_vel) and centrar_img_y >= pant_y-(actual_n_vel*multi_n_vel)) then
				centrar_img_y = pant_y
			elseif not (centrar_img_y >= pant_y+(actual_n_vel*multi_n_vel) and centrar_img_y <= pant_y-(actual_n_vel*multi_n_vel)) then
				if centrar_img_y >= pant_y+(actual_n_vel*multi_n_vel) then
					centrar_img_y = centrar_img_y-(actual_n_vel*multi_n_vel)
				elseif centrar_img_y <= pant_y-(actual_n_vel*multi_n_vel) then
					centrar_img_y = centrar_img_y+(actual_n_vel*multi_n_vel)
				end
			end
			local Right_XY = ((actual_n*actual_n_vel)*LISTAS.ART_ZOOM)//2
			if LISTAS.COV_Y ~= 0 then
				Right_XY = (Right_XY*LISTAS.COV_X)//LISTAS.COV_Y
			end
			local Right_Y = ((actual_n*actual_n_vel)*LISTAS.ART_ZOOM)//2
			if LISTAS.COVER_ART ~= nil and LISTAS.EXISTE_COV == true then
				Graphics.drawScaleImage(LISTAS.COVER_ART, centrar_img_x+LISTAS.COV_FIX-(Right_XY//2), centrar_img_y+LISTAS.COV_FIX_Y-(Right_Y//2), LISTAS.COV_X+Right_XY, LISTAS.COV_Y+Right_Y)
			else
				if OPCIONES.FONDO_RGB_FIJO_ON == 1 and CAMBIOS_EMUS.TRAS ~= 0 then
					Graphics.drawScaleImage(LISTAS.COVER_DEFAULT, centrar_img_x+LISTAS.COV_FIX-(Right_XY//2), centrar_img_y+LISTAS.COV_FIX_Y-(Right_Y//2), LISTAS.COV_X+Right_XY, LISTAS.COV_Y+Right_Y)
					if CONTROL.CUSTOM_BACK == true then
						Graphics.drawRect(centrar_img_x+LISTAS.COV_FIX-(Right_XY//2), centrar_img_y+LISTAS.COV_FIX_Y-(Right_Y//2), LISTAS.COV_X+Right_XY, LISTAS.COV_Y+Right_Y, CAMBIOS_EMUS.COLOR_EMU_BACK)
					end
				else
					Graphics.drawScaleImage(LISTAS.COVER_DEFAULT, centrar_img_x+LISTAS.COV_FIX-(Right_XY//2), centrar_img_y+LISTAS.COV_FIX_Y-(Right_Y//2), LISTAS.COV_X+Right_XY, LISTAS.COV_Y+Right_Y, CAMBIOS_EMUS.COLOR_EMU_BACK)
				end
			end
		end
		Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO, Color.new(0, 0, 0, actual_n))
		Screen.flip()
	end
end

--- Realizar animación para las introducciones a los menús. -----------------------------
function intro_menu(cambio_ani, n_ani)
	if n_ani >= 1+(CONTROL.ANIM_VELOCIDAD//10) and cambio_ani == true then
		n_ani = n_ani-(CONTROL.ANIM_VELOCIDAD//10)
	elseif cambio_ani == true then
		n_ani = 0
		cambio_ani = false
	end
	local suma_x, suma_y = 0, 0
	for contador = 40, CONTROL.ALTO+40, 40 do
		for contador2 = -8, CONTROL.ANCHO+40, 40 do
			suma_x = contador2
			Graphics.drawRect(suma_x-(n_ani//2)+4, suma_y-(n_ani//2)+4, n_ani+4, n_ani+4, Color.new(0, 0, 0, (n_ani*3)))
		end
		suma_y = contador
	end
	return cambio_ani, n_ani
end

--- Dibujar los submenús con múltiples opciones. ----------------------------------------
--- "colores" es opcional y va al final para no tocar a las otras llamadas: una tabla
--- paralela a "submenu_lista" con el color de cada linea. Sin ella, todo como antes.
function submenu_selector(submenu_lista, submenu_actual, text_prin, pos_ini, pos_end, centrado, pos_cen, lista_resp, tipo_act, cargando, extra_list, pos_ext, colores)
	pos_end = (pos_end-pos_ini)+32
	if cargando == false then
		local p_end_res = ((pos_ini+pos_end)-32)+CONTROL.Y_FIX_PAL
		local x_menu, x_cent = (CONTROL.ANCHO//2), 8
		local fix_a, fix_b = (OPCIONES.FONT_PIXEL_X)*(string.len(lista_resp[1])), (OPCIONES.FONT_PIXEL_X)*(string.len(lista_resp[2]))
		if fix_b >= fix_a then fix_a = fix_b end
		local resp_pos_1, resp_pos_2 = ((CONTROL.ANCHO//2)-(fix_a))-3, ((CONTROL.ANCHO//2)+(fix_a//2))-3
		if centrado == false then
			x_menu, x_cent = pos_cen, 0
		end
		Graphics.drawRect(0, (pos_ini)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, pos_end, COLOR.BLANCO)
		Graphics.drawRect(0, (pos_ini+2)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, (pos_end-4), COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (pos_ini+10)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, text_prin, COLOR.BLANCO)
		if #submenu_lista >= 1 then
			for mostrar = 1, #submenu_lista do
				local espacio_linea = (pos_ini+12)+((mostrar)*24)+CONTROL.Y_FIX_PAL
				local col_act, col_ina = COLOR.BLANCO, COLOR.GRIS
				if colores ~= nil and colores[mostrar] ~= nil then
					col_act, col_ina = colores[mostrar], colores[mostrar]
				end
				if submenu_actual == mostrar or submenu_actual == nil then
					Font.ftPrint(CONTROL.fontARCA, x_menu, espacio_linea, x_cent, CONTROL.ANCHO, 25, submenu_lista[mostrar], col_act)
					if pos_ext ~= nil and #extra_list == #submenu_lista then
						Font.ftPrint(CONTROL.fontARCA, pos_ext, espacio_linea, 0, CONTROL.ANCHO, 25, extra_list[mostrar], COLOR.BLANCO)
					end
				else
					Font.ftPrint(CONTROL.fontARCA, x_menu, espacio_linea, x_cent, CONTROL.ANCHO, 25, submenu_lista[mostrar], col_ina)
					if pos_ext ~= nil and #extra_list == #submenu_lista then
						Font.ftPrint(CONTROL.fontARCA, pos_ext, espacio_linea, 0, CONTROL.ANCHO, 25, extra_list[mostrar], col_ina)
					end
				end
			end
		end
		if tipo_act == true then
			Graphics.drawScaleImage(PAD_IMG.CROSS, resp_pos_1-25, p_end_res, 20, 20)
			Graphics.drawScaleImage(PAD_IMG.CIRCLE, resp_pos_2-25, p_end_res, 20, 20)
		elseif tipo_act == false then
			Graphics.drawScaleImage(PAD_IMG.SQUARE, resp_pos_1-25, p_end_res, 20, 20)
			Graphics.drawScaleImage(PAD_IMG.TRIANGLE, resp_pos_2-25, p_end_res, 20, 20)
		end
		Font.ftPrint(CONTROL.fontARCA, resp_pos_1, p_end_res, 0, 160, 25, lista_resp[1], COLOR.BLANCO)
		Font.ftPrint(CONTROL.fontARCA, resp_pos_2, p_end_res, 0, 160, 25, lista_resp[2], COLOR.BLANCO)
	elseif cargando == true then
		Graphics.drawRect(0, (pos_ini)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, pos_end, COLOR.BLANCO)
		Graphics.drawRect(0, (pos_ini+2)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, (pos_end-4), COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (pos_ini+(pos_end//2)-17)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, text_prin, COLOR.BLANCO)
		refrescar(false)
		System.sleep(1)
	end
end

--- Ver los controles en pantalla. ------------------------------------------------------
function ver_controles(tipo)
	repro_sfx(S_EJECUTAR, 1, false, nil)
	local help_texto, help_texto2, help_texto3 = "HELP", "HELPSPA", "HELPPOR"
	if tipo == true then
		help_texto, help_texto2, help_texto3 = "HELP_EDIT", "HELP_EDITSPA", "HELP_EDITPOR"
	end
	if doesFileExist("System/Defaults/SPA") then
		help_texto = help_texto2
	elseif doesFileExist("System/Defaults/POR") then
		help_texto = help_texto3
	end
	if doesFileExist("System/Medias/Default/".. help_texto ..".png") then
		local yoshi, help, multi = true, Graphics.loadImage(verif_img("System/Medias/Default/".. help_texto ..".png")), 2
		while yoshi do
			capturar(JOYSTICK_LIMITE)
			Screen.clear(CAMBIOS_EMUS.COLOR_EMU)
			local Right_X, Right_Y, Right_XY = zoom(LISTAS.ART_ZOOM*multi, CONTROL.ANCHO, CONTROL.ALTO_F)
			local Left_X, Left_Y = Pads.getLeftStick(0)
			local x_pos, y_pos = 0-(Right_XY//2)-(Right_X//2)+(-Left_X), 0-(Right_Y//2)+(-Left_Y)
			Graphics.drawScaleImage(help, x_pos, y_pos, CONTROL.ANCHO+Right_XY, CONTROL.ALTO_F+Right_Y)
			if Right_X == 0 and Right_Y == 0 and Left_X == 1 and Left_Y == 1 then
				Graphics.drawRect(5, CONTROL.ALTO_F-23, calcular_sombras("RETROLauncher v1.0 / rev 2"), 20, COLOR.NEGRO_T)
				Font.ftPrint(CONTROL.fontARCA, 8, CONTROL.ALTO_F-22, 0, 640, 88, "RETROLauncher v1.0 / rev 2", COLOR.BLANCO)
				dibujar_indicador(558, (CONTROL.ALTO_F-23)-CONTROL.Y_FIX_PAL, TEXT_GEN[7], PAD_IMG.TRIANGLE, 20, 20, 3, true)
			end
			refrescar(false)
			if Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
				yoshi = false
				repro_sfx(S_CANCELAR, 1, false, nil)
			elseif (Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1)) and CONTROL.JOYSTICK_ON == false then
				if Pads.check(PAD, PAD_R1) then
					multi = cambiar_valor(multi, 1, 3, 1, true)
				elseif Pads.check(PAD, PAD_L1) then
					multi = cambiar_valor(multi, 1, 3, 1, false)
				end
				JOYSTICK_LIMITE = control_FPS(1)
			end
		end
		Graphics.freeImage(help)
		JOYSTICK_LIMITE = control_FPS(1)-10
	end
end

--- Menú de configuración PS1. ----------------------------------------------------------
function menu_pops(nombre_vcd)
	Pads.rumble(0, 0, 0)
	local creditos = "Configurations based on POPStarter documentation created by ShaolinAssassin and POPStarter patches created by Hugopocked."
	local cambio_ani, n_ani = true, 45
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local nombre_game = string.sub(nombre_vcd, 1, -5)
	local pops_u = POPS_DE(nombre_vcd)   -- unidad cuyo POPS/ contiene este juego
	local parches_indi_enc, parches_indi, ubicar, tipo, selec_act, selec_opt = {}, nil, " ", nil, true, 1
	LISTAS.SCROLL_TEX = 1
	reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
	local estatus_game = System.listDirectory(pops_u .."/POPS/".. nombre_game)

	-- Crear directorios faltantes. -----------------------------------------------------
	if estatus_game == nil then
		System.createDirectory(pops_u .."/POPS/".. nombre_game)
	end
	if System.listDirectory(pops_u .."/POPS/Hugopocked Fixes") == nil then
		System.createDirectory(pops_u .."/POPS/Hugopocked Fixes")
	end
	if System.listDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS General Fixes") == nil then
		System.createDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS General Fixes")
	end
	if System.listDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS Game Fixes") == nil then
		System.createDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS Game Fixes")
	end

	-- Dibujar los submenús con múltiples opciones. -------------------------------------
	local function sub_menu_multi(sub_menu_lista, sub_menu_actual, nombre_game, text_prin, p_ini, p_end, centrado, p_cen, most_fondos, lista_resp, tipo_act, modo_alt)
		p_end = (p_end-p_ini)+32
		local x_menu, x_cent, p_end_res = (CONTROL.ANCHO//2), 8, ((p_ini+p_end)-32)+CONTROL.Y_FIX_PAL
		if centrado == false then
			x_menu, x_cent = p_cen, 0
		end
		if most_fondos == true then
			dibujar_fondos()
			if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
				Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
			end
		end
		Graphics.drawScaleImage(LISTAS.LOGO, (CONTROL.ANCHO//2)-(240//2), 0+CONTROL.Y_FIX_PAL, 240, 72)
		if modo_alt == true then
			Graphics.drawRect(12, 74+CONTROL.Y_FIX_PAL, 615, 343, COLOR.NEGRO_T)
			Graphics.drawRect(12, 74+CONTROL.Y_FIX_PAL, 615, 74, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 77+CONTROL.Y_FIX_PAL, 8, 600, 25, "-".. TEXT_M_PRI[8] .."-", COLOR.BLANCO)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 101+CONTROL.Y_FIX_PAL, 8, 600, 8, nombre_game, CAMBIOS_EMUS.COLOR_EMU)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 126+CONTROL.Y_FIX_PAL, 8, 600, 8, "-".. text_prin .."-", COLOR.BLANCO)
			if OPCIONES.GUI_LIMPIA_ON == 0 then
				local x_gui_pos = {40, 186, 322, 515}
				local img_gui = {PAD_IMG.CROSS, PAD_IMG.START, PAD_IMG.SQUARE, PAD_IMG.CIRCLE}
				for mostrar_gui = 1, #x_gui_pos do
					local fix_x, fix_y = 0, 0
					if tipo == nil and mostrar_gui == 2 then
						fix_x, fix_y = 10, 5
					end
					if (mostrar_gui ~= 2 and mostrar_gui ~= 3) or (tipo == nil and mostrar_gui == 2) or (((sub_menu_actual <= #sub_menu_lista and tipo == nil) or tipo == true) and mostrar_gui == 3) then
						Graphics.drawRect(x_gui_pos[mostrar_gui], 422+CONTROL.Y_FIX_PAL, calcular_sombras(lista_resp[mostrar_gui]), 20, COLOR.NEGRO_T)
						Graphics.drawScaleImage(img_gui[mostrar_gui], x_gui_pos[mostrar_gui]-(25+fix_x), 422-fix_y+CONTROL.Y_FIX_PAL, (20+fix_x), (20+fix_x))
						Font.ftPrint(CONTROL.fontARCA, x_gui_pos[mostrar_gui]+3, 422+CONTROL.Y_FIX_PAL, 0, 0, 25, lista_resp[mostrar_gui], COLOR.BLANCO)
					end
				end
				img_gui = nil
			end
		elseif tipo_act ~= nil and modo_alt == false then
			Graphics.drawRect(0, (p_ini)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, p_end, COLOR.BLANCO)
			Graphics.drawRect(0, (p_ini+2)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, (p_end-4), COLOR.NEGRO)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (p_ini+10)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, nombre_game, CAMBIOS_EMUS.COLOR_EMU)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (p_ini+38)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, text_prin, COLOR.BLANCO)
			for mostrar = 1, #sub_menu_lista do
				local espacio_linea = (p_ini+40)+((mostrar)*24)+CONTROL.Y_FIX_PAL
				if sub_menu_actual == mostrar then
					Font.ftPrint(CONTROL.fontARCA, x_menu, espacio_linea, x_cent, CONTROL.ANCHO, 25, sub_menu_lista[sub_menu_actual], COLOR.BLANCO)
				else
					Font.ftPrint(CONTROL.fontARCA, x_menu, espacio_linea, x_cent, CONTROL.ANCHO, 25, sub_menu_lista[mostrar], COLOR.GRIS)
				end
			end
			if tipo_act == true then
				Graphics.drawScaleImage(PAD_IMG.CROSS, 224-35, p_end_res, 20, 20)
				Graphics.drawScaleImage(PAD_IMG.CIRCLE, 380-35, p_end_res, 20, 20)
			elseif tipo_act == false then
				Graphics.drawScaleImage(PAD_IMG.SQUARE, 224-35, p_end_res, 20, 20)
				Graphics.drawScaleImage(PAD_IMG.TRIANGLE, 380-35, p_end_res, 20, 20)
			end
			Font.ftPrint(CONTROL.fontARCA, 214, p_end_res, 0, 160, 25, lista_resp[1], COLOR.BLANCO)
			Font.ftPrint(CONTROL.fontARCA, 370, p_end_res, 0, 160, 25, lista_resp[2], COLOR.BLANCO)
		elseif tipo_act == nil and modo_alt == false then
			Graphics.drawRect(0, (p_ini)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, p_end, COLOR.BLANCO)
			Graphics.drawRect(0, (p_ini+2)+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, (p_end-4), COLOR.NEGRO)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (p_ini+(p_end//2)-17)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, text_prin, COLOR.BLANCO)
			refrescar(false)
		end
	end

	-- Menú de configuración de "CHEATS.TXT". -------------------------------------------
	local function def_cheats(new, conf_load)
		local set_num_conf = {""; "", 1; ""; ""; 10; 640; 2559; 2560; ""; ""; ""; ""; "";
		""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; ""; "";}
		local lista_comparar_config = {"$SAFEMODE"; "SMOOTH"; "USBDELAY_"; "FORCEPAL"; "NOPAL"; "YPOS_"; "XPOS_"; "DWSTRETCH_"; "DWCROP_";
		"SCANLINES"; "D2LS"; "D2LS_ALT"; "HDTVFIX"; "MUTE_VAB"; "IGR0"; "IGR1"; "IGR2"; "IGR3"; "IGR4"; "IGR5"; "NOIGR"; "FAKELC"; "WIDESCREEN";
		"ULTRA_WIDESCREEN"; "EYEFINITY"; "480p"; "NOVMC0"; "NOVMC1"; "UNDO_GAME_FIXES"; "COMPATIBILITY_0x01"; "COMPATIBILITY_0x02";
		"COMPATIBILITY_0x03"; "COMPATIBILITY_0x04"; "COMPATIBILITY_0x05"; "COMPATIBILITY_0x06";}
		local new_cheats_config = {"$SAFEMODE"; "SMOOTH"; "USBDELAY_"; "FORCEPAL"; "NOPAL"; "YPOS_"; "XPOS_"; "DWSTRETCH_"; "DWCROP_";
		"SCANLINES"; "D2LS"; "D2LS_ALT"; "HDTVFIX"; "MUTE_VAB"; "IGR0"; "IGR1"; "IGR2"; "IGR3"; "IGR4"; "IGR5"; "NOIGR"; "FAKELC"; "WIDESCREEN";
		"ULTRA_WIDESCREEN"; "EYEFINITY"; "480p"; "NOVMC0"; "NOVMC1"; "UNDO_GAME_FIXES"; "COMPATIBILITY_0x01"; "COMPATIBILITY_0x02";
		"COMPATIBILITY_0x03"; "COMPATIBILITY_0x04"; "COMPATIBILITY_0x05"; "COMPATIBILITY_0x06";}
		local descriptions_cheats = {TEXT_POPS_DESCR[1]; TEXT_POPS_DESCR[2]; TEXT_POPS_DESCR[3]; TEXT_POPS_DESCR[4]; TEXT_POPS_DESCR[5];
		TEXT_POPS_DESCR[6]; TEXT_POPS_DESCR[7]; TEXT_POPS_DESCR[8]; TEXT_POPS_DESCR[9]; TEXT_POPS_DESCR[10]; TEXT_POPS_DESCR[11];
		TEXT_POPS_DESCR[12]; TEXT_POPS_DESCR[13]; TEXT_POPS_DESCR[14]; TEXT_POPS_DESCR[15]; TEXT_POPS_DESCR[16]; TEXT_POPS_DESCR[17];
		TEXT_POPS_DESCR[18]; TEXT_POPS_DESCR[19]; TEXT_POPS_DESCR[20]; TEXT_POPS_DESCR[21]; TEXT_POPS_DESCR[22]; TEXT_POPS_DESCR[23];
		TEXT_POPS_DESCR[24]; TEXT_POPS_DESCR[25]; TEXT_POPS_DESCR[26]; TEXT_POPS_DESCR[27]; TEXT_POPS_DESCR[28]; TEXT_POPS_DESCR[29];
		TEXT_POPS_DESCR[30]; TEXT_POPS_DESCR[31]; TEXT_POPS_DESCR[32]; TEXT_POPS_DESCR[33]; TEXT_POPS_DESCR[34]; TEXT_POPS_DESCR[35];}
		local other_cheats, hexa_code, text_codi_ext, text_codi_pops = {}, "%x%x%x%x%x%x%x%x%s%x%x%x%x", "EXTRA CODES", "POPSTARTER CODES"
		if conf_load ~= nil and #conf_load >= 1 then
			for cont = 1, #lista_comparar_config do
				local presente = false
				for cont2 = 1, #conf_load do
					if string.match(conf_load[cont2], lista_comparar_config[cont]) then
						new_cheats_config[cont] = conf_load[cont2]
						presente = true
						break
					end
				end
				if presente == false then
					new_cheats_config[cont] = lista_comparar_config[cont] .. set_num_conf[cont]
				elseif presente == true and (cont == 3 or (cont >= 6 and cont <= 9)) then
					local pos_n = string.find(new_cheats_config[cont], "_")
					set_num_conf[cont] = tonumber(string.sub(new_cheats_config[cont], pos_n+1))
				end
			end
			for cont = 1, #conf_load do
				local presente = false
				for cont2 = 1, #lista_comparar_config do
					if string.match(conf_load[cont], lista_comparar_config[cont2]) then
						presente = true
						break
					end
				end
				if presente == false and not string.match("// ".. text_codi_ext .." //", conf_load[cont]) and not string.match("// ".. text_codi_pops .." //", conf_load[cont]) and not string.match(conf_load[cont], "SAFEMODE") then
					table.insert(other_cheats, conf_load[cont])
				end
			end
		end
		if new == true or conf_load == nil or #conf_load <= 0 then
			for cont = 1, #lista_comparar_config do
				new_cheats_config[cont] = lista_comparar_config[cont] .. set_num_conf[cont]
			end
		end
		if #other_cheats >= 1 then
			table.insert(new_cheats_config, "/-----------/ ".. text_codi_ext .." /-----------/")
			for cont = 1, #other_cheats do
				table.insert(new_cheats_config, other_cheats[cont])
			end
		end
		if new == true then
			for cont = 1, #new_cheats_config do
				if string.match(new_cheats_config[cont], "%$") and not string.match(new_cheats_config[cont], "SAFEMODE") then
					new_cheats_config[cont] = string.sub(new_cheats_config[cont], 2)
				end
			end
		end
		table.insert(new_cheats_config, "/---------/ ".. text_codi_pops .." /---------/")
		local cheats_menu = true
		local selec_cheat = 1
		while cheats_menu do
			CONTROL.FPS = Screen.getFPS(1)
			capturar(JOYSTICK_LIMITE)
			tiempo_de_scroll()

			-- Mostrar todo en pantalla. ------------------------------------------------
			local lista_resp = {TEXT_GEN[8], TEXT_GEN[12], TEXT_M_PS1[3], TEXT_GEN[6]}
			sub_menu_multi(lista_comparar_config, selec_cheat, nombre_game, TEXT_M_PS1[4], 74, 422, true, 0, true, lista_resp, nil, true)
			if CONTROL.ESPERA_CARGA_SCR == false then
				LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, new_cheats_config[selec_cheat], 38)
			end
			local max_lista = 0
			for contador_1 = 0, 10 do
				local espacio_linea = 152+((contador_1)*24)+CONTROL.Y_FIX_PAL
				if contador_1 == 0 then
					Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 552, 25, string.sub(new_cheats_config[selec_cheat], LISTAS.SCROLL_TEX), CAMBIOS_EMUS.COLOR_EMU)
					local acti = TEXT_GEN[2]
					if string.match(new_cheats_config[selec_cheat], "%$") then
						acti = TEXT_GEN[3]
					end
					if selec_cheat >= #lista_comparar_config+1 and not string.match(new_cheats_config[selec_cheat], hexa_code) then
						acti = " "
					end
					Font.ftPrint(CONTROL.fontARCA, 578, espacio_linea, 0, 0, 8, "".. acti, CAMBIOS_EMUS.COLOR_EMU)
				elseif (selec_cheat+contador_1) <= #new_cheats_config then
					Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 552, 25, new_cheats_config[selec_cheat+contador_1], COLOR.BLANCO_LISTA)
					local acti = TEXT_GEN[2]
					if string.match(new_cheats_config[selec_cheat+contador_1], "%$") then
						acti = TEXT_GEN[3]
					end
					if selec_cheat+contador_1 >= #lista_comparar_config+1 and not string.match(new_cheats_config[selec_cheat+contador_1], hexa_code) then
						acti = " "
					end
					Font.ftPrint(CONTROL.fontARCA, 578, espacio_linea, 0, 0, 8, "".. acti, COLOR.BLANCO_LISTA)
				elseif max_lista <= #new_cheats_config-1 and #new_cheats_config >= 11 then
					max_lista = max_lista+1
					Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 552, 25, new_cheats_config[max_lista], COLOR.BLANCO_LISTA)
					local acti = TEXT_GEN[2]
					if string.match(new_cheats_config[max_lista], "%$") then
						acti = TEXT_GEN[3]
					end
					Font.ftPrint(CONTROL.fontARCA, 578, espacio_linea, 0, 0, 8, "".. acti, COLOR.BLANCO_LISTA)
				end
			end
			if selec_cheat <= #lista_comparar_config and Pads.check(PAD, PAD_SQUARE) then
				Graphics.drawRect(20, 182+CONTROL.Y_FIX_PAL, 600, 104, COLOR.BLANCO)
				Graphics.drawRect(24, 186+CONTROL.Y_FIX_PAL, 592, 96, COLOR.NEGRO)
				Font.ftPrint(CONTROL.fontARCA, 35, 192+CONTROL.Y_FIX_PAL, 0, 615, 96, descriptions_cheats[selec_cheat], CAMBIOS_EMUS.COLOR_EMU)
			end
			if new == false then
				refrescar(false)
			end

			-- Moverse por las opciones del menú. ---------------------------------------
			if (((Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90)) or ((Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT) or Left_X ~= 1) and (selec_cheat == 3 or (selec_cheat >= 6 and selec_cheat <= 9)))) and CONTROL.JOYSTICK_ON == false then
				local min_s, max_s = 1, 3
				if selec_cheat == 6 then
					min_s, max_s = 1, 100
				elseif selec_cheat == 7 then
					min_s, max_s = 540, 740
				elseif selec_cheat == 8 then
					min_s, max_s = 2000, 3000
				elseif selec_cheat == 9 then
					min_s, max_s = 2160, 2560
				end
				if (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
					selec_cheat = cambiar_valor(selec_cheat, 1, #new_cheats_config, 1, true)
					if selec_cheat == #new_cheats_config then
						selec_cheat = 1
					elseif #other_cheats >= 1 and selec_cheat == #lista_comparar_config+1 and #lista_comparar_config+2 <= #new_cheats_config then
						selec_cheat = selec_cheat+1
					end
				elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
					selec_cheat = cambiar_valor(selec_cheat, 1, #new_cheats_config, 1, false)
					if selec_cheat == #new_cheats_config then
						selec_cheat = selec_cheat-1
					elseif #other_cheats >= 1 and selec_cheat == #lista_comparar_config+1 then
						selec_cheat = #lista_comparar_config
					end
				elseif Pads.check(PAD, PAD_LEFT) or Left_X <= -90 then
					set_num_conf[selec_cheat] = cambiar_valor(set_num_conf[selec_cheat], min_s, max_s, 1, false)
					local pos_n = string.find(new_cheats_config[selec_cheat], "_")
					new_cheats_config[selec_cheat] = string.sub(new_cheats_config[selec_cheat], 1, pos_n) .. set_num_conf[selec_cheat]
				elseif Pads.check(PAD, PAD_RIGHT) or Left_X >= 90 then
					set_num_conf[selec_cheat] = cambiar_valor(set_num_conf[selec_cheat], min_s, max_s, 1, true)
					local pos_n = string.find(new_cheats_config[selec_cheat], "_")
					new_cheats_config[selec_cheat] = string.sub(new_cheats_config[selec_cheat], 1, pos_n) .. set_num_conf[selec_cheat]
				end
				LISTAS.SCROLL_TEX = 1
				reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
				local kabal = 1 if (Left_Y ~= 1 or Left_X ~= 1) then
					kabal = 2
				end
				if kabal == 1 then
					repro_sfx(S_MOVER, 1, true, nil)
				end
				JOYSTICK_LIMITE = control_FPS(kabal)
			elseif Pads.check(PAD, PAD_CROSS) and selec_cheat ~= 1 and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				if selec_cheat <= #lista_comparar_config or (selec_cheat >= #lista_comparar_config+1 and string.match(new_cheats_config[selec_cheat], hexa_code)) then
					if string.match(new_cheats_config[selec_cheat], "%$") then
						new_cheats_config[selec_cheat] = string.sub(new_cheats_config[selec_cheat], 2)
					else
						new_cheats_config[selec_cheat] = "$".. new_cheats_config[selec_cheat]
					end
					if selec_cheat == 4 and string.match(new_cheats_config[5], "%$") then
						new_cheats_config[5] = string.sub(new_cheats_config[5], 2)
					elseif selec_cheat == 5 and string.match(new_cheats_config[4], "%$") then
						new_cheats_config[4] = string.sub(new_cheats_config[4], 2)
					elseif selec_cheat == 11 and string.match(new_cheats_config[12], "%$") then
						new_cheats_config[12] = string.sub(new_cheats_config[12], 2)
					elseif selec_cheat == 12 and string.match(new_cheats_config[11], "%$") then
						new_cheats_config[11] = string.sub(new_cheats_config[11], 2)
					elseif selec_cheat >= 15 and selec_cheat <= 21 then
						for change = 15, 21 do
							if change ~= selec_cheat and string.match(new_cheats_config[change], "%$") then
								new_cheats_config[change] = string.sub(new_cheats_config[change], 2)
							end
						end
					elseif selec_cheat >= 23 and selec_cheat <= 25 then
						for change = 23, 25 do
							if change ~= selec_cheat and string.match(new_cheats_config[change], "%$") then
								new_cheats_config[change] = string.sub(new_cheats_config[change], 2)
							end
						end
					elseif (selec_cheat >= 30 and selec_cheat <= 32) or selec_cheat == 34 then
						for change = 30, 34 do
							if change ~= selec_cheat and change ~= 33 and string.match(new_cheats_config[change], "%$") then
								new_cheats_config[change] = string.sub(new_cheats_config[change], 2)
							end
						end
					end
				end
				JOYSTICK_LIMITE = control_FPS(1)
			elseif (Pads.check(PAD, PAD_START) and CONTROL.JOYSTICK_ON == false) or new == true then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				local pregunta, confirmar_cheat = true, false
				if new == false then
					while pregunta do
						CONTROL.FPS = Screen.getFPS(1)
						capturar(JOYSTICK_LIMITE)
						local lista_resp = {TEXT_GEN[12], TEXT_GEN[6]}
						sub_menu_multi({}, 1, nombre_game, TEXT_M_PS1[5] .."?", 160, 226, true, 0, true, lista_resp, false, false)
						refrescar(false)
						if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
							repro_sfx(S_EJECUTAR, 1, false, nil)
							confirmar_cheat, cheats_menu, pregunta = true, false, false
						elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
							repro_sfx(S_CANCELAR, 1, false, nil)
							pregunta = false
						end
					end
				end
				if (confirmar_cheat == true or new == true) and System.listDirectory(pops_u .."/POPS/".. nombre_game) ~= nil then
					if new == false then
						sub_menu_multi({}, 1, nombre_game, TEXT_M_PS1[6] .."... ".. TEXT_M_CON[46], 160, 226, true, 0, true, lista_resp, nil, false)
					end
					if #other_cheats >= 1 then
						new_cheats_config[#lista_comparar_config+1] = "// ".. text_codi_ext .." //"
					end
					table.remove(new_cheats_config, #new_cheats_config)
					for cont = #lista_comparar_config, 2, -1 do
						if not string.match(new_cheats_config[cont], "%$") then
							table.remove(new_cheats_config, cont)
						end
					end
					table.insert(new_cheats_config, 1, "// ".. text_codi_pops .." //")
					local config_f = ""
					for create = 1, #new_cheats_config do
						local salto_linea = "\r\n"
						if create == #new_cheats_config then
							salto_linea = ""
						end
						config_f = config_f .. new_cheats_config[create] .. salto_linea
					end
					if doesFileExist(pops_u .."/POPS/".. nombre_game .."/CHEATS.TXT") then
						System.removeFile(pops_u .."/POPS/".. nombre_game .."/CHEATS.TXT")
					end
					local final_cheats = System.openFile(pops_u .."/POPS/".. nombre_game .."/CHEATS.TXT", FCREATE)
					System.writeFile(final_cheats, config_f, string.len(config_f))
					System.closeFile(final_cheats)
					cheats_menu = false
					JOYSTICK_LIMITE = control_FPS(1)-20
					estatus_game = System.listDirectory(pops_u .."/POPS/".. nombre_game)
					System.sleep(1)
				end
			elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_CANCELAR, 1, false, nil)
				cheats_menu = false
				JOYSTICK_LIMITE = control_FPS(1)-20
			end
		end
	end

	-- Cargar configuraciones desde "CHEATS.TXT". ---------------------------------------
	local function cargar_cheats_txt(rest)
		local lista_config = {}
		if doesFileExist(pops_u .."/POPS/".. nombre_game .."/CHEATS.TXT") then
			local cheats_txt = System.openFile(pops_u .."/POPS/".. nombre_game .."/CHEATS.TXT", FREAD)
			System.seekFile(cheats_txt, 0, SET)
			local size_config = System.sizeFile(cheats_txt)
			local temp = System.readFile(cheats_txt, size_config)
			System.closeFile(cheats_txt)
			lista_config = sub_string(temp, "[^\r\n]+", lista_config, false)
			def_cheats(rest, lista_config)
		else
			def_cheats(rest, nil)
		end
	end

	-- Instalar parches para POPStarter. ------------------------------------------------
	local function instalar_parches(tipo_de_inst, dir_orig, cheats_ins)
		local dir_pops_game = pops_u .."/POPS/".. nombre_game
		if tipo_de_inst == false or tipo_de_inst == nil then
			local prev_parches = System.listDirectory(dir_pops_game)
			if prev_parches ~= nil then
				for cont = 1, #prev_parches do
					if (string.lower(string.sub(prev_parches[cont].name, -4)) == ".bin" and cheats_ins == false) or (prev_parches[cont].name == "CHEATS.TXT" and cheats_ins == true) then
						System.removeFile(dir_pops_game .."/".. prev_parches[cont].name)
					end
				end
			end
		end
		if tipo_de_inst ~= nil then
			local nuev_parches = System.listDirectory(dir_orig)
			if nuev_parches ~= nil then
				for cont = 1, #nuev_parches do
					if (string.lower(string.sub(nuev_parches[cont].name, -4)) == ".bin" and cheats_ins == false) or (nuev_parches[cont].name == "CHEATS.TXT" and cheats_ins == true) then
						System.copyFile(dir_orig .."/".. nuev_parches[cont].name, dir_pops_game .."/".. nuev_parches[cont].name)
					end
				end
			end
		end
		estatus_game = System.listDirectory(pops_u .."/POPS/".. nombre_game)
	end

	-- Buscar parches para POPStarter. --------------------------------------------------
	local function menu_pops_paches(cheats_ins)
		parches_indi_enc = {}
		parches_indi = nil
		local text_parche, text_adver = " ", " "
		if tipo == true then
			parches_indi = System.listDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS General Fixes")
			ubicar = pops_u .."/POPS/Hugopocked Fixes/POPS General Fixes/"
			text_parche, text_adver = TEXT_M_PS1[11], TEXT_M_PS1[12]
		elseif tipo == false then
			parches_indi = System.listDirectory(pops_u .."/POPS/Hugopocked Fixes/POPS Game Fixes")
			ubicar = pops_u .."/POPS/Hugopocked Fixes/POPS Game Fixes/"
			text_parche, text_adver = TEXT_M_PS1[13], TEXT_M_PS1[14]
			if cheats_ins == true then
				text_parche, text_adver = TEXT_M_PS1[29], TEXT_M_PS1[30]
			end
		end
		if parches_indi ~= nil and (tipo == true or tipo == false) then
			for cont_1 = 1, #parches_indi do
				if parches_indi[cont_1].directory == true then
					local conf_bin2 = System.listDirectory(ubicar .. parches_indi[cont_1].name)
					if conf_bin2 ~= nil then
						for cont_2 = 1, #conf_bin2 do
							if (string.lower(string.sub(conf_bin2[cont_2].name, -4)) == ".bin" and cheats_ins == false) or (conf_bin2[cont_2].name == "CHEATS.TXT" and cheats_ins == true) then
								table.insert(parches_indi_enc, ubicar .. parches_indi[cont_1].name)
								break
							elseif conf_bin2[cont_2].directory == true then
								local conf_bin3 = System.listDirectory(ubicar .. parches_indi[cont_1].name .."/".. conf_bin2[cont_2].name)
								for cont_3 = 1, #conf_bin3 do
									if (string.lower(string.sub(conf_bin3[cont_3].name, -4)) == ".bin" and cheats_ins == false) or (conf_bin2[cont_2].name == "CHEATS.TXT" and cheats_ins == true) then
										table.insert(parches_indi_enc, ubicar .. parches_indi[cont_1].name .."/".. conf_bin2[cont_2].name)
										break
									end
								end
							end
						end
					end
				end
			end
			if parches_indi_enc ~= nil and #parches_indi_enc >= 1 then
				table.sort(parches_indi_enc, orden_alfabetico)
				local lista_comparar_fix = {"%[DQA,DQB,default%]INTPL,RTPS,IRGB,%[ORGB div7Ch%]"; "%[DQA,DQB,default%]INTPL,RTPS,IRGB,%[ORGB div80h%]";
				"%[DQA,DQB,default%]INTPL,RTPS,IRGB,%[ORGB div84h%]"; "%[DQA,DQB,default%]INTPL,RTPS,IRGB,%[ORGB div90h%]";
				"%[DQA,DQB,hack%]INTPL,RTPS,IRGB,%[ORGB div84h%]"; "%[IR0%=zero%]INTPL,RTPS,IRGB,%[ORGB div84h%]"; "INTPL,RTPS,IRGB,%[ORGB div84h%]";
				"Renew CodeCache Scan"; "SPU_IRQ_"; "CPU_Clock"; "GPU Timing_Fix 0"; "GPU Timing_OverclockFix"; "GPU Dithering Off"; ".*";}
				local descriptions_fix = {TEXT_POPS_DESCR[36]; TEXT_POPS_DESCR[37]; TEXT_POPS_DESCR[38]; TEXT_POPS_DESCR[39]; TEXT_POPS_DESCR[40];
				TEXT_POPS_DESCR[41]; TEXT_POPS_DESCR[42]; TEXT_POPS_DESCR[43]; TEXT_POPS_DESCR[44]; TEXT_POPS_DESCR[45]; TEXT_POPS_DESCR[46];
				TEXT_POPS_DESCR[47]; TEXT_POPS_DESCR[48]; TEXT_POPS_DESCR[49]; }
				local menu_conf_ps1, selector = true, 1
				while menu_conf_ps1 do
					CONTROL.FPS = Screen.getFPS(1)
					capturar(JOYSTICK_LIMITE)
					tiempo_de_scroll()

					-- Mostrar todo en pantalla. ----------------------------------------
					local lista_resp = {TEXT_M_PS1[15], TEXT_GEN[12], TEXT_M_PS1[3], TEXT_GEN[6]}
					if cheats_ins == true then
						lista_resp[1] = TEXT_M_PS1[1]
					end
					local submenu_conf = {}
					sub_menu_multi(submenu_conf, selector, nombre_game, text_parche, 74, 422, true, 0, true, lista_resp, nil, true)
					if CONTROL.ESPERA_CARGA_SCR == false then
						LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, salida_texto_dir(parches_indi_enc[selector], true), 44)
					end
					local max_lista = 0
					for contador_l = 0, 10 do
						local espacio_linea = 152+((contador_l)*24)+CONTROL.Y_FIX_PAL
						if contador_l == 0 then
							Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, string.sub(salida_texto_dir(parches_indi_enc[selector], true), LISTAS.SCROLL_TEX), CAMBIOS_EMUS.COLOR_EMU)
						elseif (selector+contador_l) <= #parches_indi_enc then
							Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, salida_texto_dir(parches_indi_enc[selector+contador_l], true), COLOR.BLANCO_LISTA)
						elseif max_lista <= #parches_indi_enc-1 and #parches_indi_enc >= 11 then
							max_lista = max_lista+1
							Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, salida_texto_dir(parches_indi_enc[max_lista], true), COLOR.BLANCO_LISTA)
						end
					end
					if Pads.check(PAD, PAD_SQUARE) and tipo == true and cheats_ins == false then
						for buscar = 1, #lista_comparar_fix do
							if string.match(salida_texto_dir(parches_indi_enc[selector], true), lista_comparar_fix[buscar]) then
								Graphics.drawRect(20, 182+CONTROL.Y_FIX_PAL, 600, 104, COLOR.BLANCO)
								Graphics.drawRect(24, 186+CONTROL.Y_FIX_PAL, 592, 96, COLOR.NEGRO)
								Font.ftPrint(CONTROL.fontARCA, 35, 192+CONTROL.Y_FIX_PAL, 0, 615, 96, descriptions_fix[buscar], CAMBIOS_EMUS.COLOR_EMU)
								break
							end
						end
					end
					refrescar(false)

					-- Moverse por las opciones del menú. -------------------------------
					if ((Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90)) and CONTROL.JOYSTICK_ON == false then
						if (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selector = cambiar_valor(selector, 1, #parches_indi_enc, 1, true)
						elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selector = cambiar_valor(selector, 1, #parches_indi_enc, 1, false)
						end
						LISTAS.SCROLL_TEX = 1
						reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
						local kabal = 1 if Left_Y ~= 1 then
							kabal = 2
						end
						if kabal == 1 then
							repro_sfx(S_MOVER, 1, true, nil)
						end
						JOYSTICK_LIMITE = control_FPS(kabal)
					elseif Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						local confir, pregunta = false, true
						LISTAS.SCROLL_TEX = 1
						reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
						local lista_text_sele = {TEXT_M_PS1[16], TEXT_M_PS1[18], TEXT_M_PS1[7]}
						if cheats_ins == true then
							lista_text_sele = {TEXT_M_PS1[32], TEXT_M_PS1[31], TEXT_M_PS1[33]}
						end
						while pregunta do
							CONTROL.FPS = Screen.getFPS(1)
							capturar(JOYSTICK_LIMITE)
							tiempo_de_scroll()
							if CONTROL.ESPERA_CARGA_SCR == false then
								LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, salida_texto_dir(parches_indi_enc[selector], true), 44)
							end
							local sub_menu_lista = {text_adver, lista_text_sele[1] ..":", string.sub(salida_texto_dir(parches_indi_enc[selector], true), LISTAS.SCROLL_TEX)}
							local lista_resp = {TEXT_M_PS1[17], TEXT_GEN[6]}
							sub_menu_multi(sub_menu_lista, 1, nombre_game, lista_text_sele[2] .."?", 160, 298, true, 0, true, lista_resp, false, false)
							refrescar(false)
							if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
								repro_sfx(S_EJECUTAR, 1, false, nil)
								confir = true
								menu_conf_ps1 = false
								pregunta = false
							elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
								repro_sfx(S_CANCELAR, 1, false, nil)
								LISTAS.SCROLL_TEX = 1
								reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
								pregunta = false
							end
						end
						if confir == true then
							sub_menu_multi({}, 1, nombre_game, lista_text_sele[3] .."... ".. TEXT_M_CON[46], 160, 298, true, 0, true, {}, nil, false)
							instalar_parches(tipo, parches_indi_enc[selector], cheats_ins)
							System.sleep(1)
						end
						JOYSTICK_LIMITE = control_FPS(1)-20
					elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						menu_conf_ps1 = false
						JOYSTICK_LIMITE = control_FPS(1)-20
					end
				end
			end
		end
	end

	-- Selector de configuraciones para POPStarter. -------------------------------------
	local function menu_pops_ini()
		while selec_act do
			CONTROL.FPS = Screen.getFPS(1)
			capturar(JOYSTICK_LIMITE)
			tiempo_de_scroll()

			-- Mostrar todo en pantalla. ------------------------------------------------
			local submenu_conf = {TEXT_M_PS1[19], TEXT_M_PS1[20], TEXT_M_PS1[1], TEXT_M_PS1[21], TEXT_M_PS1[22]}
			local lista_resp = {TEXT_GEN[5], TEXT_GEN[6]}
			sub_menu_multi(submenu_conf, selec_opt, nombre_game, TEXT_M_PS1[23], 74, 264, true, 0, true, lista_resp, false, false)
			if estatus_game ~= nil then
				local x_ms, y_ms = 22, 1
				Graphics.drawRect(12, 304+CONTROL.Y_FIX_PAL, 615, 111, COLOR.NEGRO_T)
				for mostrar = 1, #estatus_game do
					if mostrar >= 21 then
						break
					end
					local espacio_linea = 288+((y_ms)*24)+CONTROL.Y_FIX_PAL
					Font.ftPrint(CONTROL.fontARCA, x_ms, espacio_linea, 0, 140, 25, string.sub(estatus_game[mostrar].name, 1, -5), COLOR.BLANCO)
					y_ms = y_ms+1
					if (mostrar == 4 or mostrar == 8 or mostrar == 12) then
						x_ms, y_ms = x_ms+150, 1
					end
				end
			end
			if CONTROL.ESPERA_CARGA_SCR == false then
				LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, creditos, 44)
			end
			Graphics.drawRect(12, 422+CONTROL.Y_FIX_PAL, 615, 22, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, 22, 424+CONTROL.Y_FIX_PAL, 0, 600, 25, string.sub(creditos, LISTAS.SCROLL_TEX), COLOR.BLANCO)
			if cambio_ani == true then
				cambio_ani, n_ani = intro_menu(cambio_ani, n_ani)
			end
			refrescar(false)

			-- Moverse por las opciones del menú. ---------------------------------------
			if cambio_ani == false then
			if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				local text_carga = TEXT_M_PS1[8] .."..."
				if selec_opt == 1 then
					tipo = false
				elseif selec_opt == 2 then
					tipo = true
				elseif selec_opt == 3 then
					tipo, text_carga = false, TEXT_M_PS1[2] .."..."
				elseif selec_opt == 4 then
					tipo, text_carga = nil, TEXT_M_PS1[9] .."..."
				elseif selec_opt == 5 then
					tipo, text_carga = nil, TEXT_M_PS1[10] .."..."
				end
				LISTAS.SCROLL_TEX = 1
				reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
				JOYSTICK_LIMITE = control_FPS(1)-15
				if tipo ~= nil and selec_opt ~= 5 then
					sub_menu_multi({}, 1, nombre_game, text_carga, 160, 298, true, 0, true, {}, nil, false)
					System.sleep(2)
					if selec_opt == 3 then
						menu_pops_paches(true)
					else
						menu_pops_paches(false)
					end
				elseif tipo == nil and selec_opt ~= 5 then
					sub_menu_multi({}, 1, nombre_game, text_carga, 160, 298, true, 0, true, {}, nil, false)
					System.sleep(2)
					cargar_cheats_txt(false)
				elseif tipo == nil and selec_opt == 5 then
					local confirmar_limp, pregunta3, selector_lim = false, true, 1
					while pregunta3 do
						CONTROL.FPS = Screen.getFPS(1)
						capturar(JOYSTICK_LIMITE)
						local submenu_conf = {TEXT_M_PS1[24], TEXT_M_PS1[25], TEXT_M_PS1[26]}
						local lista_resp = {TEXT_M_PS1[28], TEXT_GEN[6]}
						sub_menu_multi(submenu_conf, selector_lim, nombre_game, TEXT_M_PS1[27] .."?", 160, 298, true, 0, true, lista_resp, true, false)
						refrescar(false)
						if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
							repro_sfx(S_EJECUTAR, 1, false, nil)
							confirmar_limp = true
							pregunta3 = false
						elseif ((Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90)) and CONTROL.JOYSTICK_ON == false then
							repro_sfx(S_MOVER, 1, false, nil)
							if (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
								selector_lim = cambiar_valor(selector_lim, 1, #submenu_conf, 1, true)
							elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
								selector_lim = cambiar_valor(selector_lim, 1, #submenu_conf, 1, false)
							end
							JOYSTICK_LIMITE = control_FPS(1)
						elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
							repro_sfx(S_CANCELAR, 1, false, nil)
							pregunta3 = false
							JOYSTICK_LIMITE = control_FPS(1)
						end
					end
					if confirmar_limp == true and System.listDirectory(pops_u .."/POPS/".. nombre_game) ~= nil then
						sub_menu_multi({}, 1, nombre_game, text_carga, 160, 298, true, 0, true, {}, nil, false)
						if selector_lim == 1 then
							instalar_parches(nil, "", false); System.sleep(2)
						elseif selector_lim == 2 then
							cargar_cheats_txt(true)
						elseif selector_lim == 3 then
							instalar_parches(nil, "", false)
							cargar_cheats_txt(true)
						end
					end
				end
				LISTAS.SCROLL_TEX = 1
				reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
			elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and CONTROL.JOYSTICK_ON == false then
				if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
					selec_opt = cambiar_valor(selec_opt, 1, #submenu_conf, 1, false)
				elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
					selec_opt = cambiar_valor(selec_opt, 1, #submenu_conf, 1, true)
				end
				local kabal = 1 if Left_Y ~= 1 then
					kabal = 2
				end
				if kabal == 1 then
					repro_sfx(S_MOVER, 1, true, nil)
				end
				JOYSTICK_LIMITE = control_FPS(kabal)
			elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_CANCELAR, 1, false, nil)
				selec_act = false
				JOYSTICK_LIMITE = control_FPS(1)-16
			end
			end
		end
	end
	menu_pops_ini()
	animaciones(nil, false)
end

--- Menú de configuración PS2 (OPL). ----------------------------------------------------
function opl_config(nombre_iso, ps2_menu, dir_iso)
	Pads.rumble(0, 0, 0)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)

	-- Buscar y cargar configuraciones existentes (OPL). --------------------------------
	local menu_opl, lista_config, lista_config_new, selector = true, {}, {}, 1
	local VMCD_o, MODE_o, GSM_o = nil, nil, nil
	submenu_selector({}, nil, TEXT_M_PS2[1], 160, 214, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
	local nombre_juego, id_iso = id_opl(dir_iso, nombre_iso, false)
	local lista_comparar_config = {"$VMC_0=", "$Compatibility=", "$EnableGSM=", "$GSMVMode=", "$GSMXOffset=", "$GSMYOffset="}
	if id_iso ~= nil and doesFileExist(device .."/CFG/".. id_iso ..".cfg") then
		local opl_cfg = System.openFile(device .."/CFG/".. id_iso ..".cfg", FREAD)
		System.seekFile(opl_cfg, 0, SET)
		local size_config = System.sizeFile(opl_cfg)
		local temp = System.readFile(opl_cfg, size_config)
		System.closeFile(opl_cfg)
		lista_config = sub_string(temp, "[^\r\n]+", lista_config, false)
		if lista_config ~= nil and #lista_config >= 1 then
			for cont = 1, #lista_comparar_config do
				local presente = false
				for cont2 = 1, #lista_config do
					if string.match(lista_config[cont2], lista_comparar_config[cont]) then
						table.insert(lista_config_new, lista_config[cont2])
						presente = true
						break
					end
				end
				if presente == false then
					lista_config_new[cont] = "nil"
				end
			end
		end
	elseif id_iso ~= nil then
		lista_config_new = lista_comparar_config
	else
		menu_opl = false
	end

	-- Cargar configuración de "VMC" (OPL). ---------------------------------------------
	if menu_opl == true then
		if string.match(lista_config_new[1], "$VMC_%d=.+") then
			VMCD_o = lista_config_new[1]
		else
			VMCD_o = nil
		end
	end
	local VMC_encontradas = buscar_VMC(1)
	local selector_VMC = 1
	if #VMC_encontradas <= 0 then
		selector_VMC = 0
	elseif #VMC_encontradas >= 1 and VMCD_o ~= nil then
		for contador = 1, #VMC_encontradas do
			if string.lower(VMC_encontradas[contador]) == string.lower(device .."/VMC/".. string.sub(VMCD_o, 8) ..".bin") then
				selector_VMC = contador
				break
			end
		end
	end
	local encontrado_vmcd = 0
	if VMCD_o ~= nil then
		encontrado_vmcd = 1
	end

	-- Cargar modos de compatibilidad (OPL). --------------------------------------------
	local m_l = {1, 2, 4, 8, 16, 32}
	local modo_1, modo_2, modo_3, modo_4, modo_5, modo_6 = 0, 0, 0, 0, 0, 0
	if menu_opl == true then
		if string.match(lista_config_new[2], "$Compatibility=%d+") then
			MODE_o = lista_config_new[2]
		else
			MODE_o = nil
		end
	end
	if MODE_o ~= nil then
		local resultado, encontrado = tonumber(string.sub(lista_config_new[2], 16)), false
		for m1 = 0, 1 do
			modo_1 = m1
			if m1 == 1 then m_l[1] = 1 else m_l[1] = 0 end
			for m2 = 0, 1 do
				modo_2 = m2
				if m2 == 1 then m_l[2] = 2 else m_l[2] = 0 end
				for m3 = 0, 1 do
					modo_3 = m3
					if m3 == 1 then m_l[3] = 4 else m_l[3] = 0 end
					for m4 = 0, 1 do
						modo_4 = m4
						if m4 == 1 then m_l[4] = 8 else m_l[4] = 0 end
						for m5 = 0, 1 do
							modo_5 = m5
							if m5 == 1 then m_l[5] = 16 else m_l[5] = 0 end
							for m6 = 0, 1 do
								modo_6 = m6
								if m6 == 1 then m_l[6] = 32 else m_l[6] = 0 end
								if m_l[1]+m_l[2]+m_l[3]+m_l[4]+m_l[5]+m_l[6] == resultado then
									encontrado = true
								end
								if encontrado == true then break end
							end
							if encontrado == true then break end
						end
						if encontrado == true then break end
					end
					if encontrado == true then break end
				end
				if encontrado == true then break end
			end
			if encontrado == true then break end
		end
		m_l = {1, 2, 4, 8, 16, 32}
	end

	-- Cargar modos de "GMS" (OPL). -----------------------------------------------------
	local gsm_x_fix, gsm_y_fix = 0, 0
	if menu_opl == true then
		if string.match(lista_config_new[3], "$EnableGSM=1") then
			if string.match(lista_config_new[4], "$GSMVMode=%d+") then
				GSM_o = tonumber(string.sub(lista_config_new[4], 11))
			else
				GSM_o = 0
			end
			if string.match(lista_config_new[5], "$GSMXOffset=%-?%d+") then
				gsm_x_fix = tonumber(string.sub(lista_config_new[5], 13))
			else
				gsm_x_fix = 0
			end
			if string.match(lista_config_new[6], "$GSMYOffset=%-?%d+") then
				gsm_y_fix = tonumber(string.sub(lista_config_new[6], 13))
			else
				gsm_y_fix = 0
			end
		else
			GSM_o = nil
		end
	end
	local activar_gsm, selector_gsm = 0, 0
	if GSM_o ~= nil then
		activar_gsm, selector_gsm = 1, GSM_o
	end

	-- Nombres de las opciones del menú y sus estados (OPL). ----------------------------
	local menus_nombres = {TEXT_M_PS2[2]; TEXT_M_PS2[3]; "-".. TEXT_M_PS2[4] .."-"; TEXT_M_PS2[20]; TEXT_M_PS2[21]; TEXT_M_PS2[22];
	TEXT_M_PS2[23]; TEXT_M_PS2[24]; TEXT_M_PS2[25]; TEXT_M_PS2[11]; " "; TEXT_M_PS2[26]; TEXT_M_PS2[27];};
	local gsm_nombres = {"NTSC"; "NTSC Non interlaced"; "PAL"; "PAL Non interlaced"; "PAL 60Hz"; "PAL 60Hz Non interlaced";
	"PS1 NTSC (HDTV 480P 60Hz)"; "PS1 PAL (HDTV 576P 50Hz)"; "HDTV 480P 60Hz"; "HDTV 576P 50Hz"; "HDTV 720P 60Hz"; "HDTV 1080i 60Hz";
	"HDTV 1080i 60Hz NON INTERLACED"; "VGA 640x480p 60hz"; "VGA 640x480p 72hz"; "VGA 640x480p 75hz"; "VGA 640x480p 85hz";
	"VGA 640x992i 60hz"; "VGA 800x600p 56hz"; "VGA 800x600p 60hz"; "VGA 800x600p 72hz"; "VGA 800x600p 75hz"; "VGA 800x600p 85hz";
	"VGA 1024x768p 60hz"; "VGA 1024x768p 70hz"; "VGA 1024x768p 75hz"; "VGA 1024x768p 85hz"; "VGA 1260x1024p 60hz"; "VGA 1260x1024p 75hz";};
	local menus_valores = {encontrado_vmcd, selector_VMC, 0, modo_1, modo_2, modo_3, modo_4, modo_5, modo_6, activar_gsm, selector_gsm, gsm_x_fix, gsm_y_fix}

	-- Ejecutar y controlar menú de configuración PS2 (OPL). ----------------------------
	while menu_opl do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)

		-- Mostrar todo en pantalla (OPL). ----------------------------------------------
		dibujar_fondos()
		if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
			Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
		end
		Graphics.drawScaleImage(LISTAS.LOGO, (CONTROL.ANCHO//2)-(240//2), 0+CONTROL.Y_FIX_PAL, 240, 72)
		Graphics.drawRect(12, 67+CONTROL.Y_FIX_PAL, 615, 350, COLOR.NEGRO_T)
		Graphics.drawRect(12, 67+CONTROL.Y_FIX_PAL, 615, 43, COLOR.NEGRO_T)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 70+CONTROL.Y_FIX_PAL, 8, 540, 25, "-".. TEXT_M_PRI[8] .." ".. TEXT_M_PS2[16] .."-", COLOR.BLANCO)
		Font.ftPrint(CONTROL.fontARCA, 22, 90+CONTROL.Y_FIX_PAL, 0, 600, 8, nombre_iso, COLOR.BLANCO)
		for contador = 1, #menus_nombres do
			local espacio_linea = 90+((contador)*23)+CONTROL.Y_FIX_PAL
			-- Las dos primeras lineas eran el ajuste de VMC de Boon, y se rellenaban
			-- aqui en cada fotograma. La tarjeta se elige ahora en el menu de
			-- lanzamiento; tener un segundo sitio que decia otra cosa sobre lo mismo
			-- es justo lo que hacia el conjunto incomprensible. Se quedan en blanco en
			-- vez de borrarse, para no correr la numeracion de todo lo que viene
			-- detras.
			menus_nombres[1] = " "
			menus_nombres[2] = " "
			-- Y el VALOR de la linea 1 tambien, que es lo que quedaba a la vista.
			--
			-- El menu de Neutrino pone menus_valores[1] a 0 al entrar; el de OPL no lo
			-- hacia, asi que se quedaba con lo que trajera la configuracion guardada.
			-- Con el rotulo en blanco pero el valor en 1, la linea salia vacia y con
			-- "activado" a la derecha, sin nada que dijera de que. A 0 desaparece el
			-- rotulo y ademas deja de escribirse la linea "$VMC_0=" al generar la
			-- configuracion de OPL, mas abajo.
			menus_valores[1] = 0
			local acti, fix_m = TEXT_GEN[13], 498
			if contador == 1 or contador == 2 then
				acti = " "
			elseif contador == 11 then
				acti, fix_m = gsm_nombres[menus_valores[contador]+1], 22
			elseif contador >= 12 then
				if menus_valores[contador] >= 1 then
					acti = "+".. tostring(menus_valores[contador])
				else
					acti = tostring(menus_valores[contador])
				end
			elseif menus_valores[contador] == 0 then
				acti = TEXT_GEN[14]
			end
			if contador == 10 then
				Graphics.drawRect(12, espacio_linea-2, 615, 23, COLOR.NEGRO_T)
			end
			if contador == selector and contador ~= 3 then
				Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, menus_nombres[selector], CAMBIOS_EMUS.COLOR_EMU)
				Font.ftPrint(CONTROL.fontARCA, fix_m, espacio_linea, 0, 0, 25, acti, CAMBIOS_EMUS.COLOR_EMU)
			elseif contador ~= selector and contador ~= 3 then
				Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, menus_nombres[contador], COLOR.BLANCO_LISTA)
				Font.ftPrint(CONTROL.fontARCA, fix_m, espacio_linea, 0, 0, 25, acti, COLOR.BLANCO_LISTA)
			elseif contador == 3 then
				Graphics.drawRect(12, espacio_linea-2, 615, 23, COLOR.NEGRO_T)
				Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), espacio_linea, 8, 0, 20, menus_nombres[contador], COLOR.BLANCO)
			end
		end
		Graphics.drawScaleImage(PAD_IMG.R1, (CONTROL.ANCHO//2)+(240//2)+(72-35), 70-5+CONTROL.Y_FIX_PAL, 34, 28)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2)+(240//2)+(72+3), 70+CONTROL.Y_FIX_PAL, 0, 0, 25, TEXT_M_PS2[17], COLOR.BLANCO)
		if OPCIONES.GUI_LIMPIA_ON == 0 then
			dibujar_indicador(515, 422, TEXT_GEN[6], PAD_IMG.TRIANGLE, 20, 20, 5, true)
			dibujar_indicador(42, 422, TEXT_M_PS2[15], PAD_IMG.START, 22, 35, 4, true)
		end
		refrescar(false)

		-- Moverse por las opciones del menú (OPL). -------------------------------------
		if ((Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90)) and CONTROL.JOYSTICK_ON == false then
			if selector == 2 and (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
				selector = selector+2
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
				selector = cambiar_valor(selector, 1, #menus_nombres, 1, true)
			elseif selector == 4 and (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
				selector = selector-2
			elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
				selector = cambiar_valor(selector, 1, #menus_nombres, 1, false)
			end
			local kabal = 1 if Left_Y ~= 1 then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_MOVER, 1, true, nil)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)

		-- Cambiar configuraciones (OPL). -----------------------------------------------
		elseif Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, true)
			elseif selector == 2 and #VMC_encontradas <= 0 then
				selector_VMC = 0
			elseif selector == 11 then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, 28, 1, true)
			elseif selector >= 12 and selector <= 13 then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], -100, 100, 1, true)
			else
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, 1, 1, true)
			end
			JOYSTICK_LIMITE = control_FPS(1)
		elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90)) and CONTROL.JOYSTICK_ON == false and ((selector >= 11 and selector <= 13) or selector == 2) then
			if selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, true)
			elseif selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, false)
			elseif selector == 2 and #VMC_encontradas <= 0 then
				selector_VMC = 0
			elseif selector == 11 and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, 28, 1, true)
			elseif selector == 11 and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, 28, 1, false)
			elseif selector >= 12 and selector <= 13 and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], -100, 100, 1, true)
			elseif selector >= 12 and selector <= 13 and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				menus_valores[selector] = cambiar_valor(menus_valores[selector], -100, 100, 1, false)
			end
			local kabal = 1 if Left_X ~= 1 then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_EJECUTAR, 1, true, nil)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)

		-- Guardar configuraciones (OPL). -----------------------------------------------
		elseif Pads.check(PAD, PAD_START) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)

			-- Confirmar guardado (OPL). ------------------------------------------------
			local pregunta, confirmar, submenu_lista = true, false, {}
			JOYSTICK_LIMITE = control_FPS(1)
			submenu_lista = sub_string(TEXT_M_PS2[29], "[^\n]+", submenu_lista, false)
			while pregunta do
				CONTROL.FPS = Screen.getFPS(1)
				capturar(JOYSTICK_LIMITE)
				submenu_selector(submenu_lista, nil, TEXT_M_PS2[28], 138, 298, false, 14, {TEXT_GEN[12], TEXT_GEN[6]}, true, false, {}, nil)
				refrescar(false)
				if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
					pregunta = false
					confirmar = true
				elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
					pregunta = false
					confirmar = false
				end
			end

			if confirmar == true then
				-- Mensaje de guardado (OPL). -------------------------------------------
				submenu_selector({}, nil, TEXT_M_PS2[19] .."...", 138, 298, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)

				-- Borrar las configuraciones existentes (OPL). -------------------------
				if doesFileExist(device .."/CFG/".. id_iso ..".cfg") then
					System.removeFile(device .."/CFG/".. id_iso ..".cfg")
				end
				local ps2_config_final = lista_config
				for cont = 1, #lista_comparar_config do
					for cont2 = 1, #ps2_config_final do
						if string.match(ps2_config_final[cont2], lista_comparar_config[cont]) then
							table.remove(ps2_config_final, cont2)
							break
						end
					end
				end

				-- Generar configuración de "VMC" (OPL). --------------------------------
				if menus_valores[1] == 1 and #VMC_encontradas >= 1 then
					lista_config_new[1] = "$VMC_0=".. string.sub(VMC_encontradas[selector_VMC], 11, -5)
				else
					lista_config_new[1] = "nil"
				end

				-- Generar configuración de compatibilidad (OPL). -----------------------
				if menus_valores[4] == 1 then m_l[1] = 1 else m_l[1] = 0 end
				if menus_valores[5] == 1 then m_l[2] = 2 else m_l[2] = 0 end
				if menus_valores[6] == 1 then m_l[3] = 4 else m_l[3] = 0 end
				if menus_valores[7] == 1 then m_l[4] = 8 else m_l[4] = 0 end
				if menus_valores[8] == 1 then m_l[5] = 16 else m_l[5] = 0 end
				if menus_valores[9] == 1 then m_l[6] = 32 else m_l[6] = 0 end
				local modo_c_final = m_l[1]+m_l[2]+m_l[3]+m_l[4]+m_l[5]+m_l[6]
				if modo_c_final >= 1 then
					lista_config_new[2] = "$Compatibility=".. tostring(modo_c_final)
				else
					lista_config_new[2] = "nil"
				end

				-- Generar configuración de "GSM" (OPL). --------------------------------
				if menus_valores[10] == 1 then
					lista_config_new[3] = "$EnableGSM=1"
					if menus_valores[11] >= 1 then
						lista_config_new[4] = "$GSMVMode=".. tostring(menus_valores[11])
					else
						lista_config_new[4] = "nil"
					end
					if menus_valores[12] ~= 0 then
						lista_config_new[5] = "$GSMXOffset=".. tostring(menus_valores[12])
					else
						lista_config_new[5] = "nil"
					end
					if menus_valores[13] ~= 0 then
						lista_config_new[6] = "$GSMYOffset=".. tostring(menus_valores[13])
					else
						lista_config_new[6] = "nil"
					end
				else
					lista_config_new[3] = "nil"
					lista_config_new[4] = "nil"
					lista_config_new[5] = "nil"
					lista_config_new[6] = "nil"
				end
				local source1, source2, pos_s = false, false, 1
				for cont = 1, #ps2_config_final do
					if string.match(ps2_config_final[cont], "$ConfigSource=1") then
						source1 = true
					end
					if string.match(ps2_config_final[cont], "$GSMSource=1") then
						source2, pos_s = true, cont
					end
				end
				if source1 == false then table.insert(ps2_config_final, "$ConfigSource=1") end
				if source2 == false and menus_valores[10] == 1 then table.insert(ps2_config_final, "$GSMSource=1") end
				if source2 == true and menus_valores[10] == 0 then table.remove(ps2_config_final, pos_s) end

				-- Crear el archivo de configuración del juego (OPL). -------------------
				for cont = 1, #lista_config_new do
					if lista_config_new[cont] ~= "nil" then
						table.insert(ps2_config_final, lista_config_new[cont])
					end
				end
				if ps2_config_final ~= nil and #ps2_config_final >= 1 then
					local config_ps2 = System.openFile(device .."/CFG/".. id_iso ..".cfg", FCREATE)
					local ps2_data = ""
					for cont = 1, #ps2_config_final do
						if cont == 1 then
							ps2_data = ps2_config_final[cont] .."\r\n"
						else
							ps2_data = ps2_data .. ps2_config_final[cont] .."\r\n"
						end
					end
					System.writeFile(config_ps2, ps2_data, string.len(ps2_data))
					System.closeFile(config_ps2)
				end
				ps2_menu = false
				menu_opl = false
				JOYSTICK_LIMITE = control_FPS(1)-16
			else
				JOYSTICK_LIMITE = control_FPS(1)
			end

		-- Abrir menú de configuración para Neutrino. -----------------------------------
		elseif Pads.check(PAD, PAD_R1) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			menu_opl = false
			ps2_menu = true
			JOYSTICK_LIMITE = control_FPS(1)

		-- Cancelar configuración y salir del menú (OPL). -------------------------------
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			menu_opl = false
			ps2_menu = false
			JOYSTICK_LIMITE = control_FPS(1)-16
		end
	end
	return ps2_menu
end

--- Menú de configuración PS2 (Neutrino). -----------------------------------------------
function menu_neutrino(nombre_iso)
	Pads.rumble(0, 0, 0)
	local cambio_ani, n_ani = true, 45
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local selector, ps2_menu, mode_menu = 1, true, false
	local dir_iso = nil
	if doesFileExist(device .."/DVD/".. nombre_iso) == true then
		dir_iso = device .."/DVD/"
	elseif doesFileExist(device .."/CD/".. nombre_iso) == true then
		dir_iso = device .."/CD/"
	end

	-- Buscar archivos de configuración del juego (Neutrino). ---------------------------
	OPCIONES.PREGUNTAR_PS2 = true
	local VMCD, MODE, GSM, SOPORTE = ejecutar_iso(nombre_iso)
	OPCIONES.PREGUNTAR_PS2 = false

	-- Cargar configuración de "VMC" (Neutrino). ----------------------------------------
	local tipo = 1
	if string.lower(string.sub(nombre_iso, -4)) == ".iso" then
		tipo, mode_menu = 1, true
	elseif string.lower(string.sub(nombre_iso, -4)) == ".mx4" then
		tipo = 2
	elseif string.lower(string.sub(nombre_iso, -4)) == ".hdd" then
		tipo = 3
	elseif string.lower(string.sub(nombre_iso, -4)) == ".mmc" then
		tipo = 4
	elseif string.lower(string.sub(nombre_iso, -4)) == ".udp" then
		tipo = 5
	end
	local VMC_encontradas = buscar_VMC(tipo)
	local selector_VMC = 1
	if #VMC_encontradas <= 0 then
		selector_VMC = 0
	elseif #VMC_encontradas >= 1 and VMCD ~= nil then
		for contador = 1, #VMC_encontradas do
			if string.lower(VMC_encontradas[contador]) == string.lower(string.sub(VMCD, 6)) then
				selector_VMC = contador
			end
		end
	end
	local encontrado_vmcd = 0
	if VMCD ~= nil then
		encontrado_vmcd = 1
	end

	-- Cargar modos de compatibilidad (Neutrino). ---------------------------------------
	local modo_0, modo_1, modo_2, modo_3, modo_5, modo_7 = 0, 0, 0, 0, 0, 0
	if MODE ~= nil then
		if string.match(MODE, "0") == "0" then
			modo_0 = 1
		end
		if string.match(MODE, "1") == "1" then
			modo_1 = 1
		end
		if string.match(MODE, "2") == "2" then
			modo_2 = 1
		end
		if string.match(MODE, "3") == "3" then
			modo_3 = 1
		end
		if string.match(MODE, "5") == "5" then
			modo_5 = 1
		end
		if string.match(MODE, "7") == "7" then
			modo_7 = 1
		end
	end

	-- Cargar modos de "GMS" (Neutrino). ------------------------------------------------
	local gsm_modes = {0, 0}
	local gsm_text_force = {TEXT_GEN[14], "240p/288p", "480p/576p", "1080i x 1", "1080i x 2", "1080i x 3"}
	local gsm_text_mode = {TEXT_GEN[14], "Field Flipping / 1", "Field Flipping / 2", "Field Flipping / 3"}
	if GSM ~= nil then
		if string.match(GSM, "=fp1") == "=fp1" then
			gsm_modes[1] = 1
		elseif string.match(GSM, "=fp2") == "=fp2" then
			gsm_modes[1] = 2
		elseif string.match(GSM, "=1080ix1") == "=1080ix1" then
			gsm_modes[1] = 3
		elseif string.match(GSM, "=1080ix2") == "=1080ix2" then
			gsm_modes[1] = 4
		elseif string.match(GSM, "=1080ix3") == "=1080ix3" then
			gsm_modes[1] = 5
		end
		if string.match(GSM, ":1") == ":1" then
			gsm_modes[2] = 1
		elseif string.match(GSM, ":2") == ":2" then
			gsm_modes[2] = 2
		elseif string.match(GSM, ":3") == ":3" then
			gsm_modes[2] = 3
		end
	end

	-- Cargar soporte de medios (Neutrino). ---------------------------------------------
	local sopor_m = 1
	local sopor_m_text = {" ", "+NET", "+HDD"}
	if SOPORTE ~= nil then
		if string.match(SOPORTE, "-net") then
			sopor_m = 2
		elseif string.match(SOPORTE, "-hdd") then
			sopor_m = 3
		end
	end

	-- Nombres de las opciones del menú y sus estados (Neutrino). -----------------------
	local menus_nombres = {TEXT_M_PS2[2]; TEXT_M_PS2[3]; "-".. TEXT_M_PS2[4] .."-"; TEXT_M_PS2[5]; TEXT_M_PS2[6]; TEXT_M_PS2[7]; TEXT_M_PS2[8];
	TEXT_M_PS2[9]; TEXT_M_PS2[10]; "-".. TEXT_M_PS2[11] .."-"; TEXT_M_PS2[12] ..":"; TEXT_M_PS2[13] ..":";};
	local menus_valores = {encontrado_vmcd, selector_VMC, 0, modo_0, modo_1, modo_2, modo_3, modo_5, modo_7, 0, gsm_modes[1], gsm_modes[2]}

	-- Las dos primeras lineas eran el ajuste de tarjeta virtual de este menu. Se
	-- desactivan: la tarjeta se elige en el menu del juego (TRIANGULO), donde se ve la
	-- ruta completa del fichero. Tener dos sitios para decidir lo mismo, cada uno con
	-- su forma de guardarlo, es lo que hacia el conjunto incomprensible.
	-- No se BORRAN las entradas para no correr toda la numeracion del controlador que
	-- viene despues; se vacian y se anula su valor, asi no hacen nada.
	menus_nombres[1] = " "
	menus_nombres[2] = " "
	menus_valores[1] = 0
	menus_valores[2] = 0

	-- Ejecutar y controlar menú de configuración PS2 (Neutrino). -----------------------
	while ps2_menu do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)

		-- Mostrar todo en pantalla (Neutrino). -----------------------------------------
		dibujar_fondos()
		if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
			Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
		end
		Graphics.drawScaleImage(LISTAS.LOGO, (CONTROL.ANCHO//2)-(240//2), 0+CONTROL.Y_FIX_PAL, 240, 72)
		Graphics.drawRect(12, 67+CONTROL.Y_FIX_PAL, 615, 350, COLOR.NEGRO_T)
		Graphics.drawRect(12, 67+CONTROL.Y_FIX_PAL, 615, 43, COLOR.NEGRO_T)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 70+CONTROL.Y_FIX_PAL, 8, 540, 25, "-".. TEXT_M_PRI[8] .." ".. TEXT_M_PS2[17] .."-", COLOR.BLANCO)
		Font.ftPrint(CONTROL.fontARCA, 22, 90+CONTROL.Y_FIX_PAL, 0, 600, 8, nombre_iso, COLOR.BLANCO)
		if mode_menu == true and dir_iso ~= nil then
			Graphics.drawScaleImage(PAD_IMG.R1, (CONTROL.ANCHO//2)+(240//2)+(138-35), 70-5+CONTROL.Y_FIX_PAL, 34, 28)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2)+(240//2)+(138+3), 70+CONTROL.Y_FIX_PAL, 0, 0, 25, TEXT_M_PS2[16], COLOR.BLANCO)
		end
		if string.lower(string.sub(nombre_iso, -4)) == ".hdd" or string.lower(string.sub(nombre_iso, -4)) == ".udp" then
			Graphics.drawScaleImage(PAD_IMG.L1, (47-35), 70-5+CONTROL.Y_FIX_PAL, 34, 28)
			Font.ftPrint(CONTROL.fontARCA, (47+3), 70+CONTROL.Y_FIX_PAL, 0, 0, 25, sopor_m_text[sopor_m], COLOR.BLANCO)
		end
		if OPCIONES.GUI_LIMPIA_ON == 0 then
			dibujar_indicador(515, 422, TEXT_GEN[6], PAD_IMG.TRIANGLE, 20, 20, 5, true)
			dibujar_indicador(42, 422, TEXT_M_PS2[15], PAD_IMG.START, 22, 35, 4, true)
		end
		for contador = 1, #menus_nombres do
			local acti, x_fix = TEXT_GEN[13], 0
			if menus_valores[contador] == 0 then
				acti = TEXT_GEN[14]
			end
			if contador == 2 or contador == 3 or contador == 10 then
				acti = " "
			end
			if contador == 11 then
				acti = gsm_text_force[menus_valores[11]+1]
			elseif contador == 12 then
				acti = gsm_text_mode[menus_valores[12]+1]
			end
			if contador >= 11 and contador <= 13 then
				x_fix = 120
			end
			-- Las dos primeras lineas eran el ajuste de VMC de Boon, y se rellenaban
			-- aqui en cada fotograma. La tarjeta se elige ahora en el menu de
			-- lanzamiento; tener un segundo sitio que decia otra cosa sobre lo mismo
			-- es justo lo que hacia el conjunto incomprensible. Se quedan en blanco en
			-- vez de borrarse, para no correr la numeracion de todo lo que viene
			-- detras.
			menus_nombres[1] = " "
			menus_nombres[2] = " "
			local espacio_linea = 90+((contador)*23)+CONTROL.Y_FIX_PAL
			if contador == selector and contador ~= 3 and contador ~= 10 then
				Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, menus_nombres[selector], CAMBIOS_EMUS.COLOR_EMU)
				Font.ftPrint(CONTROL.fontARCA, 498-x_fix, espacio_linea, 0, 0, 25, acti, CAMBIOS_EMUS.COLOR_EMU)
			elseif contador ~= selector and contador ~= 3 and contador ~= 10 then
				Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 600, 25, menus_nombres[contador], COLOR.BLANCO_LISTA)
				Font.ftPrint(CONTROL.fontARCA, 498-x_fix, espacio_linea, 0, 0, 25, acti, COLOR.BLANCO_LISTA)
			elseif contador == 3 or contador == 10 then
				Graphics.drawRect(12, espacio_linea-2, 615, 23, COLOR.NEGRO_T)
				Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), espacio_linea, 8, 0, 20, menus_nombres[contador], COLOR.BLANCO)
			end
		end
		if cambio_ani == true then
			cambio_ani, n_ani = intro_menu(cambio_ani, n_ani)
		end
		refrescar(false)

		-- Moverse por las opciones del menú (Neutrino). --------------------------------
		if cambio_ani == false then
		if ((Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90)) and CONTROL.JOYSTICK_ON == false then
			if (selector == 2 or selector == 9) and (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
				selector = selector+2
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
				selector = cambiar_valor(selector, 1, #menus_nombres, 1, true)
			elseif (selector == 4 or selector == 11) and (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
				selector = selector-2
			elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
				selector = cambiar_valor(selector, 1, #menus_nombres, 1, false)
			end
			local kabal = 1 if Left_Y ~= 1 then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_MOVER, 1, true, nil)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)

		-- Controlar selector de "VMC" / "GSM" (Neutrino). -----------------------------
		elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90)) and CONTROL.JOYSTICK_ON == false and ((selector >= 11 and selector <= 12) or selector == 2) then
			if selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, true)
			elseif selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, false)
			elseif selector == 2 and #VMC_encontradas <= 0 then
				selector_VMC = 0
			elseif selector >= 11 and selector <= 12 and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				local limite_gsm = 5
				if selector == 12 then
					limite_gsm = 3
				end
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, limite_gsm, 1, true)
			elseif selector >= 11 and selector <= 12 and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				local limite_gsm = 5
				if selector == 12 then
					limite_gsm = 3
				end
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, limite_gsm, 1, false)
			end
			local kabal = 1 if Left_X ~= 1 then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_EJECUTAR, 1, true, nil)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)

		-- Cambiar configuraciones (Neutrino). ------------------------------------------
		elseif Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if selector >= 11 and selector <= 12 then
				local limite_gsm = 5
				if selector == 12 then
					limite_gsm = 3
				end
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, limite_gsm, 1, true)
			elseif selector == 2 and #VMC_encontradas >= 1 and menus_valores[1] == 1 then
				selector_VMC = cambiar_valor(selector_VMC, 1, #VMC_encontradas, 1, true)
			elseif selector == 2 and #VMC_encontradas <= 0 then
				selector_VMC = 0
			else
				menus_valores[selector] = cambiar_valor(menus_valores[selector], 0, 1, 1, true)
			end
			JOYSTICK_LIMITE = control_FPS(1)

		-- Cambiar configuración de soporte para medios (Neutrino). ---------------------
		elseif Pads.check(PAD, PAD_L1) and (string.lower(string.sub(nombre_iso, -4)) == ".hdd" or string.lower(string.sub(nombre_iso, -4)) == ".udp") and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if string.lower(string.sub(nombre_iso, -4)) == ".hdd" and sopor_m == 1 then 
				sopor_m = 2
			elseif string.lower(string.sub(nombre_iso, -4)) == ".udp" and sopor_m == 1 then 
				sopor_m = 3
			elseif sopor_m ~= 1 then
				sopor_m = 1
			end
			JOYSTICK_LIMITE = control_FPS(1)

		-- Guardar configuraciones (Neutrino). ------------------------------------------
		elseif Pads.check(PAD, PAD_START) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)

			-- Mensaje de guardado (Neutrino). ------------------------------------------
			submenu_selector({}, nil, TEXT_M_PS2[19] .."...", 160, 188, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)

			-- Borrar las configuraciones existentes (Neutrino). ------------------------
			if doesFileExist(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_iso, 1, -5) ..".cfg") then
				System.removeFile(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_iso, 1, -5) ..".cfg")
			end
			local ps2_config_final = {"nil", "nil", "nil", "nil"}

			-- Borrar las configuraciones de versiones previas (Neutrino). --------------
			local conf_del = {".vmcd", ".mode", ".mgsm"}
			for limpiar = 1, #conf_del, 1 do
				if doesFileExist(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar]) then
					System.removeFile(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar])
				end
				if doesFileExist(actual .."/Roms/ps2-isos/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar]) then
					System.removeFile(actual .."/Roms/ps2-isos/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar])
				end
				if doesFileExist(device .."/DVD/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar]) then
					System.removeFile(device .."/DVD/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar])
				end
				if doesFileExist(device .."/CD/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar]) then
					System.removeFile(device .."/CD/".. string.sub(nombre_iso, 1, -5) .. conf_del[limpiar])
				end
			end

			-- Generar configuración de "VMC" (Neutrino). -------------------------------
			if menus_valores[1] == 1 and #VMC_encontradas >= 1 then
				ps2_config_final[1] = "-mc0=".. VMC_encontradas[selector_VMC]
			end

			-- Generar configuración de compatibilidad (Neutrino). ----------------------
			local modos_on = "-gc="
			local crear_modos = false
			local modos_final = {"0", "1", "2", "3", "5", "7"}
			for mc = 4, 9, 1 do
				if menus_valores[mc] == 1 then
					modos_on = modos_on .. modos_final[mc-3]
					crear_modos = true
				end
			end
			if crear_modos == true then
				ps2_config_final[2] = modos_on
			end

			-- Generar configuración de "GSM" (Neutrino). -------------------------------
			local gsm_on = "-gsm="
			if menus_valores[11] > 0 then
				if menus_valores[11] == 1 then
					gsm_on = gsm_on .."fp1"
				elseif menus_valores[11] == 2 then
					gsm_on = gsm_on .."fp2"
				elseif menus_valores[11] == 3 then
					gsm_on = gsm_on .."1080ix1"
				elseif menus_valores[11] == 4 then
					gsm_on = gsm_on .."1080ix2"
				elseif menus_valores[11] == 5 then
					gsm_on = gsm_on .."1080ix3"
				end
			end
			if menus_valores[12] > 0 then
				if menus_valores[12] == 1 then
					gsm_on = gsm_on ..":1"
				elseif menus_valores[12] == 2 then
					gsm_on = gsm_on ..":2"
				elseif menus_valores[12] == 3 then
					gsm_on = gsm_on ..":3"
				end
			end
			if gsm_on ~= "-gsm=" then
				ps2_config_final[3] = gsm_on
			end

			-- Generar configuración de soporte para medios (Neutrino). -----------------
			if sopor_m >= 2 and sopor_m <= 3 then
				ps2_config_final[4] = tostring(sopor_m-1)
			else
				ps2_config_final[4] = "nil"
			end

			-- Crear el archivo de configuración del juego (Neutrino). ------------------
			if not (ps2_config_final[1] == "nil" and ps2_config_final[2] == "nil" and ps2_config_final[3] == "nil" and ps2_config_final[4] == "nil") then
				local config_ps2 = System.openFile(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_iso, 1, -5) ..".cfg", FCREATE)
				local ps2_data = ps2_config_final[1] .."\r\n".. ps2_config_final[2] .."\r\n".. ps2_config_final[3] .."\r\n".. ps2_config_final[4]
				System.writeFile(config_ps2, ps2_data, string.len(ps2_data))
				System.closeFile(config_ps2)
			end
			ps2_menu = false
			JOYSTICK_LIMITE = control_FPS(1)-16

		-- Abrir menú de configuración para OPL. ----------------------------------------
		elseif Pads.check(PAD, PAD_R1) and CONTROL.JOYSTICK_ON == false then
			if string.lower(string.sub(nombre_iso, -4)) == ".iso" and dir_iso ~= nil then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)
				ps2_menu = opl_config(nombre_iso, ps2_menu, dir_iso)
			else
				repro_sfx(S_CANCELAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)
			end

		-- Cancelar configuración y salir del menú (Neutrino). --------------------------
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			ps2_menu = false
			JOYSTICK_LIMITE = control_FPS(1)-16
		end
		end
	end
	animaciones(nil, false)
	CONTROL.FPS = Screen.getFPS(1)
	capturar(JOYSTICK_LIMITE)
end

--- Busca y guarda "VMC" de PS2. --------------------------------------------------------
function buscar_VMC(tipo)
	local exten = ".bin"
	if tipo == 2 then
		exten = ".mx4"
	elseif tipo == 3 then
		exten = ".hdd"
	elseif tipo == 4 then
		exten = ".mmc"
	elseif tipo == 5 then
		exten = ".udp"
	end
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local Device_VMCs = System.listDirectory(device .."/VMC")
	local VMC_encontradas = {}
	if Device_VMCs ~= nil then
		for contador = 1, #Device_VMCs do
			if Device_VMCs[contador].directory == false and string.lower(string.sub(Device_VMCs[contador].name, -4)) == exten then
				table.insert(VMC_encontradas, device .."/VMC/".. Device_VMCs[contador].name)
			end
		end
	end
	return VMC_encontradas
end

--- Busca el nombre del juego DVD PS2. --------------------------------------------------
function obtener_nombre_DVD(nombre_id, exten)
	local ext = "    "
	if exten == true then
		ext = ".elf"
	end
	local nombre = "PS2 DISK: ".. nombre_id .. ext
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/System/Defaults/PS2_IDs.cfg") then
		local carga_id = System.openFile(actual .."/System/Defaults/PS2_IDs.cfg", FREAD)
		System.seekFile(carga_id, 0, SET)
		local size = System.sizeFile(carga_id)
		local temp_tex = System.readFile(carga_id, size)
		System.closeFile(carga_id)
		for linea in string.gmatch(temp_tex, nombre_id .."=.+\n") do
			local salto = string.find(linea, "=")
			local fin = string.find(linea, "\n")
			local extra = string.find(linea, "\r\n")
			if salto ~= nil and fin ~= nil and extra ~= nil then
				nombre = (string.sub(linea, salto+1, fin-2) .. ext)
			elseif salto ~= nil and fin ~= nil and extra == nil then
				nombre = (string.sub(linea, salto+1, fin-1) .. ext)
			end
		end
	end
	return nombre
end

--- Explorador y ejecutor de APPS. ------------------------------------------------------
function exporer_apps()
	local cambio_ani, n_ani = true, 45
	local lista_resp, selec_disp, pregunta, device = {TEXT_M_CON[29], TEXT_GEN[7]}, 1, true, salida_texto_dir(System.currentDirectory(), nil)
	while pregunta do
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()
		local submenu_lista = {"mc0:", "mc1:", device}
		-- Unidades BDM detectadas al arrancar (disco interno exFAT via ata_bd). --------
		if BDM_DEVICES ~= nil then
			for i_bdm = 1, #BDM_DEVICES do
				table.insert(submenu_lista, BDM_DEVICES[i_bdm])
			end
		end
		-- El bandeau tiene altura fija: cada linea ocupa 24 px. Con las unidades BDM
		-- anadidas hay que agrandarlo, si no el contenido desborda y la fila de botones
		-- (calculada desde el borde inferior) queda desplazada.
		local extra_bdm = #submenu_lista - 3
		if extra_bdm < 0 then extra_bdm = 0 end
		submenu_selector(submenu_lista, selec_disp, TEXT_M_PRI[35], 160-(extra_bdm*12), 273+(extra_bdm*12), true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
		if cambio_ani == true then
			cambio_ani, n_ani = intro_menu(cambio_ani, n_ani)
			JOYSTICK_LIMITE = control_FPS(1)-16
		end
		refrescar(false)
		if cambio_ani == false then
		if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			marcar_directorio(nil, selec_disp, dibujar_fondos)
			JOYSTICK_LIMITE = control_FPS(1)-16
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				selec_disp = cambiar_valor(selec_disp, 1, #submenu_lista, 1, false)
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				selec_disp = cambiar_valor(selec_disp, 1, #submenu_lista, 1, true)
			end
			JOYSTICK_LIMITE = control_FPS(1)
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			JOYSTICK_LIMITE = control_FPS(1)
			pregunta = false
		end
		end
	end
	animaciones(nil, false)
end

--- Determina el directorio de la aplicación. -------------------------------------------
function salida_texto_dir(texto, archivo)
	if archivo == true or archivo == false or type(archivo) == "number" then
		local final_dir = string.reverse(texto)
		local borrar, borrar2 = string.find(final_dir, "/", 2, false), 1
		if type(archivo) == "number" then
			borrar2 = string.find(final_dir, "/", borrar+1, false)
			if borrar2 == nil and borrar ~= nil then
				borrar2 = borrar-1
			end
		end
		final_dir = string.reverse(final_dir)
		if type(archivo) == "number" and borrar ~= nil and borrar2 ~= nil then
			final_dir = string.sub(final_dir, -borrar2+1, -borrar)
		elseif type(archivo) == "boolean" and borrar ~= nil and archivo == false then
			final_dir = string.sub(final_dir, 1, -borrar)
		elseif type(archivo) == "boolean" and borrar ~= nil and archivo == true then
			final_dir = string.sub(final_dir, -borrar+1)
		end
		return final_dir
	elseif archivo == nil then
		local final_dir = texto
		local borrar = string.find(final_dir, ":", 1, false)
		if borrar ~= nil then
			final_dir = string.sub(final_dir, 1, borrar)
		end
		return final_dir
	end
end

--- Busca el nombre de APPS (SAS) en el archivo ".cfg". ---------------------------------
function obtener_nombre_SAS(archivo_cfg, nombre_APP)
	local nombre = nombre_APP
	if doesFileExist(archivo_cfg) then
		local carga_cfg = System.openFile(archivo_cfg, FREAD)
		System.seekFile(carga_cfg, 0, SET)
		local size = System.sizeFile(carga_cfg)
		local temp_tex = System.readFile(carga_cfg, size)
		System.closeFile(carga_cfg)
		for linea in string.gmatch(temp_tex, "title=.+") do
			local salto = string.find(linea, "\n")
			if salto ~= nil then
				if string.sub(linea, salto-1, salto) == "\r\n" then
					nombre = (string.sub(linea, 7, salto-2) .."    ")
				else
					nombre = (string.sub(linea, 7, salto-1) .."    ")
				end
			else
				nombre = (string.sub(linea, 7) .."    ")
			end
		end
	end
	return nombre
end

--- Precargar las listas de cada sistema. -----------------------------------------------
function recargar_todas()
	local crea = {}
	local sistemas_on = {SISTEMAS.MEGADRIVE_ON; SISTEMAS.MASTERSYSTEM_ON; SISTEMAS.GAMEGEAR_ON; SISTEMAS.FAMICOM_ON; SISTEMAS.GAMEBOY_ON;
	SISTEMAS.GAMEBOYCOLOR_ON; SISTEMAS.GAMEBOYADVANCE_ON; SISTEMAS.ATARI2600_ON; SISTEMAS.ATARILYNX_ON; SISTEMAS.SEGASG1000_ON; SISTEMAS.NEOGEOPOCKET_ON;
	SISTEMAS.SUPERFAMICOM_ON; SISTEMAS.APPS_ON; SISTEMAS.PLAYSTATION_ON; SISTEMAS.PLAYSTATION2_ON;};
	for contador = 1, 15, 1 do
		local nueva = {}
		if sistemas_on[contador] == 1 then
			-- Cada sistema rastrea sus carpetas en TODAS las unidades. Es, con
			-- diferencia, lo mas caro del arranque, y hasta ahora la pantalla decia
			-- "Loading lists and settings" durante todo el rato sin distinguirlos.
			local nom = "system ".. tostring(contador)
			if ROMS_DIR ~= nil and ROMS_DIR[contador] ~= nil then nom = ROMS_DIR[contador] end
			-- Sin linea de "empezando": crear_listas ya anuncia "ATA scan <nom>" y
			-- "USB scan <nom>" al abrir cada fuente. Una linea menos por sistema, y
			-- cada linea cuesta una reescritura del journal y dos repintados.
			nueva = crear_listas(contador, nueva)
			CARGA_PASO(nom .."  ".. tostring(#nueva) .." found  (".. tostring(contador) .."/15)")
		end
		table.insert(crea, nueva)
	end
	PRE_CARGADAS = crea
	LISTAS.IDENTIDAD = 1
end

--- Recarga un sistema determinado. -----------------------------------------------------
--- Lista de tarjetas para un juego. Se abre con CRUZ desde el menu del juego. --------
--- Se muestran las que EXISTEN, con su ruta entera, y despues una entrada "(NEW)" por
--- unidad para crear una que no existe todavia. Nada se crea al recorrer la lista:
--- solo al pulsar CRUZ sobre una entrada "(NEW)".
--- Devuelve la ruta elegida, o nil si se cancela.
--- Se abre desde el menu de lanzamiento, sobre la linea "VMC file".
---
--- De entrada solo se ven las tarjetas DE ESTE JUEGO, que es lo que se busca el 99%
--- de las veces. Las demas no desaparecen: hay una linea "See all VMC files" que las
--- trae, y siguen saliendo detras de las del juego. Una carpeta con cien partidas de
--- otros juegos no ayuda a encontrar la de Dark Cloud.
---
--- La ultima linea crea una tarjeta nueva. El numero del final se mueve con
--- IZQUIERDA / DERECHA -- no con arriba / abajo, que aqui hacen falta para recorrer
--- la lista, y en el resto del programa izquierda/derecha es siempre "cambiar el
--- valor de esta linea".
function VMC_LISTA_ELEGIR(nombre_iso)
	local id = VMC_ID(nombre_iso)
	if id == nil then return nil end

	-- Una sola lectura de las carpetas: recorrer la lista no debe volver al disco.
	local cand, propias = VMC_CANDIDATAS(id)
	local unidades = VMC_UNIDADES()
	local ver_todo, num = false, 1
	local rutas, etiquetas = {}, {}

	local function nombre_nuevo()
		return VMC_NOMBRE_NUEVO(nombre_iso, num) or (id .."-".. num ..".bin")
	end

	local function construir()
		rutas, etiquetas = {}, {}
		local tope = propias
		if ver_todo == true then tope = #cand end
		for i = 1, tope do
			rutas[#rutas + 1] = cand[i]
			if i <= propias then etiquetas[#etiquetas + 1] = "* ".. cand[i]
			else etiquetas[#etiquetas + 1] = "  ".. cand[i] end
		end
		if propias == 0 and ver_todo == false then
			rutas[#rutas + 1] = "-"
			etiquetas[#etiquetas + 1] = "  no card found for ".. id
		end
		if #cand > propias then
			rutas[#rutas + 1] = "TOGGLE"
			if ver_todo == true then
				etiquetas[#etiquetas + 1] = "[ Show only cards for ".. id .." ]"
			else
				etiquetas[#etiquetas + 1] = "[ See all VMC files ]  (".. (#cand - propias) .." more)"
			end
		end
		for i = 1, #unidades do
			rutas[#rutas + 1] = "NEW:".. unidades[i]
			etiquetas[#etiquetas + 1] = "[ Create on ".. unidades[i] .." <-> ]  ".. nombre_nuevo()
		end
	end

	local function refrescar_nuevas()
		for i = 1, #rutas do
			if string.sub(rutas[i], 1, 4) == "NEW:" then
				etiquetas[i] = "[ Create on ".. string.sub(rutas[i], 5) .." <-> ]  ".. nombre_nuevo()
			end
		end
	end

	construir()
	if #etiquetas == 0 then return nil end

	local VENTANA = 7
	local sel, abierto, elegida = 1, true, nil
	JOYSTICK_LIMITE = control_FPS(1)
	while abierto do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()

		local ini = sel - (VENTANA // 2)
		if ini > #etiquetas - VENTANA + 1 then ini = #etiquetas - VENTANA + 1 end
		if ini < 1 then ini = 1 end
		local vista, cursor = {}, 1
		for i = ini, ini + VENTANA - 1 do
			if etiquetas[i] ~= nil then
				vista[#vista + 1] = etiquetas[i]
				if i == sel then cursor = #vista end
			end
		end
		submenu_selector(vista, cursor, "-VMC for ".. id .."   ".. sel .."/".. #etiquetas .."-",
			56, 344, true, CONTROL.ANCHO // 2,
			{TEXT_GEN[5], TEXT_GEN[6]}, true, false, {}, nil)
		refrescar(false)

		local r = rutas[sel]

		if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if r == "TOGGLE" then
				ver_todo = (ver_todo == false)
				construir()
				if sel > #etiquetas then sel = #etiquetas end
				JOYSTICK_LIMITE = control_FPS(1)
			elseif r == "-" then
				JOYSTICK_LIMITE = control_FPS(1)
			elseif string.sub(r, 1, 4) == "NEW:" then
				elegida = VMC_CREAR(string.sub(r, 5), nombre_nuevo())
				abierto = false
			else
				elegida = r
				abierto = false
			end
		elseif (Pads.check(PAD, PAD_TRIANGLE) or Pads.check(PAD, PAD_CIRCLE))
		       and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			abierto = false
		elseif string.sub(r, 1, 4) == "NEW:" and CONTROL.JOYSTICK_ON == false
		       and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
			repro_sfx(S_MOVER, 1, false, nil)
			num = cambiar_valor(num, 1, 99, 1, false)
			refrescar_nuevas()
			JOYSTICK_LIMITE = control_FPS(1)
		elseif string.sub(r, 1, 4) == "NEW:" and CONTROL.JOYSTICK_ON == false
		       and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
			repro_sfx(S_MOVER, 1, false, nil)
			num = cambiar_valor(num, 1, 99, 1, true)
			refrescar_nuevas()
			JOYSTICK_LIMITE = control_FPS(1)
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, false)
			JOYSTICK_LIMITE = control_FPS(1)
		elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, true)
			JOYSTICK_LIMITE = control_FPS(1)
		end
	end
	JOYSTICK_LIMITE = control_FPS(1)
	return elegida
end

--- Menu de lanzamiento de un juego de PS2. ---------------------------------------------
--- Se abre SIEMPRE antes de arrancar una ISO, desde CRUZ en la lista o desde el menu
--- del juego. Un juego de PS2 no se lanza a ciegas: aqui se ve, antes de arrancar, en
--- que tarjeta se va a guardar la partida, de que fichero sale, y con que lanzador.
--- Devuelve true si hay que lanzar, false si se ha cancelado.
function menu_lanzamiento(nombre_iso)
	if nombre_iso == nil then return false end
	VMC_CFG_LEER()
	LANZADOR_LEER()
	local id = VMC_ID(nombre_iso)

	-- Estado de partida, tal y como quedo la ultima vez. VMC.cfg es la memoria del
	-- "last vmc for this game": una linea "<ID>=<ruta>".
	local usar_vmc = true
	if id == nil or VMC_JUEGOS[id] == "none" then usar_vmc = false end

	local elegida = nil
	if id ~= nil then
		local v = VMC_JUEGOS[id]
		if v ~= nil and v ~= "none" and doesFileExist(v) then
			elegida = v
		else
			-- Ninguna eleccion guardada: se propone la primera tarjeta DE ESTE JUEGO.
			local cand, propias = VMC_CANDIDATAS(id)
			if propias >= 1 then elegida = cand[1] end
		end
	end

	local function et_tarjeta()
		if usar_vmc == false then return "Memory card : Real PS2 card" end
		return "Memory card : VMC card"
	end
	local function et_fichero()
		if usar_vmc == false then return "VMC file    : -" end
		if elegida == nil then return "VMC file    : none yet   (X to pick or create)" end
		return "VMC file    : ".. elegida
	end
	local function et_lanzador()
		if LANZADOR_ES_OPL(nombre_iso) then return "Launch with : OPL" end
		return "Launch with : Neutrino"
	end

	local etiquetas = {et_tarjeta(), et_fichero(), et_lanzador(), "Start game", "Cancel"}
	local I_TARJETA, I_FICHERO, I_LANZADOR, I_START, I_CANCEL = 1, 2, 3, 4, 5

	local function repintar()
		etiquetas[I_TARJETA] = et_tarjeta()
		etiquetas[I_FICHERO] = et_fichero()
		etiquetas[I_LANZADOR] = et_lanzador()
	end

	local function guardar()
		if id == nil then return end
		if usar_vmc == false then
			VMC_JUEGOS[id] = "none"
		elseif elegida ~= nil then
			VMC_JUEGOS[id] = elegida
		else
			VMC_JUEGOS[id] = nil
		end
		VMC_CFG_GUARDAR()
	end

	local sel, abierto, lanzar = 1, true, false
	JOYSTICK_LIMITE = control_FPS(1)
	while abierto do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()
		submenu_selector(etiquetas, sel,
			"-Launch ".. NOMBRE_VISIBLE(15, nombre_iso, 1) .."-",
			56, 344, true, CONTROL.ANCHO // 2,
			{TEXT_GEN[5], TEXT_GEN[6]}, true, false, {}, nil)
		refrescar(false)

		if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if sel == I_FICHERO and usar_vmc == true then
				local escogida = VMC_LISTA_ELEGIR(nombre_iso)
				if escogida ~= nil then elegida = escogida end
				repintar()
				JOYSTICK_LIMITE = control_FPS(1)
			elseif sel == I_START then
				-- Con "VMC card" pero sin fichero no se arranca: seria una partida
				-- que se pierde al apagar, sin que nada lo hubiera dicho. El cursor
				-- se va a la linea que falta.
				if usar_vmc == true and elegida == nil then
					sel = I_FICHERO
					JOYSTICK_LIMITE = control_FPS(1)
				else
					guardar()
					lanzar = true
					abierto = false
				end
			elseif sel == I_CANCEL then
				abierto = false
			else
				JOYSTICK_LIMITE = control_FPS(1)
			end
		elseif (Pads.check(PAD, PAD_TRIANGLE) or Pads.check(PAD, PAD_CIRCLE))
		       and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			abierto = false
		elseif sel == I_TARJETA and CONTROL.JOYSTICK_ON == false
		       and (Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT)
		            or Left_X <= -90 or Left_X >= 90) then
			repro_sfx(S_MOVER, 1, false, nil)
			usar_vmc = (usar_vmc == false)
			repintar()
			JOYSTICK_LIMITE = control_FPS(1)
		elseif sel == I_LANZADOR and CONTROL.JOYSTICK_ON == false
		       and (Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT)
		            or Left_X <= -90 or Left_X >= 90) then
			repro_sfx(S_MOVER, 1, false, nil)
			if LANZADOR_ES_OPL(nombre_iso) then
				LANZADOR_JUEGOS[nombre_iso] = nil
			else
				LANZADOR_JUEGOS[nombre_iso] = "opl"
			end
			LANZADOR_GUARDAR()
			repintar()
			JOYSTICK_LIMITE = control_FPS(1)
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, false)
			JOYSTICK_LIMITE = control_FPS(1)
		elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, true)
			JOYSTICK_LIMITE = control_FPS(1)
		end
	end
	JOYSTICK_LIMITE = control_FPS(1)
	return lanzar
end

--- Menu del juego seleccionado. TRIANGULO en la lista. ---------------------------------
--- Antes, TRIANGULO intercambiaba caratula y captura, y era la unica cosa que hacia.
--- Las demas acciones por juego estaban repartidas en combinaciones que nada anunciaba
--- -- CIRCULO+TRIANGULO abria los ajustes de PS1, de PS2 o el explorador de APPS segun
--- el sistema. Nadie las encuentra por casualidad.
--- Ahora TRIANGULO abre esta lista: el intercambio de arte sigue ahi, acompanado de lo
--- que aplique al sistema en curso, y del borrado. Las combinaciones antiguas siguen
--- funcionando para quien las conozca.
function menu_juego()
	if LISTAS.ROMS == nil or LISTAS.ROMS[LISTAS.INDICE] == nil then return end
	local etiquetas, acciones = {}, {}

	local function anadir(texto, accion)
		etiquetas[#etiquetas + 1] = texto
		acciones[#acciones + 1] = accion
	end

	if LISTAS.MOSTRAR >= LISTAS.ART_LIMITE then
		local cual = "cover"
		if LISTAS.SCREENSHOT_ON == false then cual = "screenshot" end
		anadir("Show ".. cual, function()
			LISTAS.SCREENSHOT_ON = (LISTAS.SCREENSHOT_ON == false)
		end)
	end

	if LISTAS.IDENTIDAD == 13 then
		anadir("File browser", function() animaciones(nil, true); exporer_apps() end)
	elseif LISTAS.IDENTIDAD == 14 then
		if string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
			anadir("PS1 settings", function()
				animaciones(nil, true); menu_pops(LISTAS.ROMS[LISTAS.INDICE]) end)
		end
	elseif LISTAS.IDENTIDAD == 15 then
		if string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
			anadir("PS2 settings", function()
				animaciones(nil, true); menu_neutrino(LISTAS.ROMS[LISTAS.INDICE]) end)
		end
	end

	-- Lanzar. Todo lo que hay que decidir antes de arrancar una ISO de PS2 -- tarjeta
	-- de memoria, fichero VMC y lanzador -- vive en el menu de lanzamiento, que es el
	-- mismo que abre CRUZ desde la lista.
	--
	-- Aqui habia ademas una linea "VMC" y otra "How to launch". Eran la misma decision
	-- dicha en dos sitios, cada uno con su forma de guardarla, y ninguno de los dos
	-- aparecia al lanzar el juego: se elegia a ciegas y se descubria despues.
	if LISTAS.IDENTIDAD == 15
	   and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) == ".iso" then
		anadir("Launch this game...", function() run_game() end)
	end

	-- El borrado va en ultimo lugar, lejos del cursor al abrir el menu.
	if RUTA_JUEGO_ACTUAL() ~= nil then
		anadir("Delete this game", borrar_juego_actual)
	end

	if #etiquetas == 0 then return end

	local sel, abierto = 1, true
	JOYSTICK_LIMITE = control_FPS(1)
	while abierto do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()
		-- Panel alto y fijo, no ajustado al numero de entradas.
		--
		-- Antes se calculaba "170 - n*12" arriba y "150 + n*12" abajo, lo que da una
		-- altura de n*24-20 para un contenido que ocupa n*24+12: el texto se salia por
		-- abajo y los botones de respuesta caian encima de la ultima linea. Con un
		-- panel de 56 a 344 todo cabe hasta once entradas, el fondo negro cubre lo que
		-- haya detras, y "select / cancel" quedan abajo y no en medio del texto.
		submenu_selector(etiquetas, sel,
			"-".. NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE], 1) .."-",
			56, 344, true, CONTROL.ANCHO // 2,
			{TEXT_GEN[5], TEXT_GEN[6]}, true, false, {}, nil)
		refrescar(false)

		if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			abierto = false
			JOYSTICK_LIMITE = control_FPS(1)
			acciones[sel]()
		elseif (Pads.check(PAD, PAD_TRIANGLE) or Pads.check(PAD, PAD_CIRCLE))
		       and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			abierto = false
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, false)
			JOYSTICK_LIMITE = control_FPS(1)
		elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			sel = cambiar_valor(sel, 1, #etiquetas, 1, true)
			JOYSTICK_LIMITE = control_FPS(1)
		end
	end
	JOYSTICK_LIMITE = control_FPS(1)
end

--- Ruta REAL del fichero del juego seleccionado, para poder borrarlo. ----------------
--- Cada sistema guarda su origen de forma distinta, de ahi el reparto.
--- Devuelve nil cuando no se puede establecer con certeza: mas vale no ofrecer el
--- borrado que borrar el fichero equivocado.
function RUTA_JUEGO_ACTUAL()
    local identidad = LISTAS.IDENTIDAD
    local nombre = LISTAS.ROMS[LISTAS.INDICE]
    if nombre == nil then return nil end

    if identidad == 13 then
        -- APPS: la lista solo guarda el nombre, la ruta esta aparte.
        if LISTAS.DIR_FULL_APP ~= nil then return LISTAS.DIR_FULL_APP[LISTAS.INDICE] end
        return nil
    end

    local clave = tostring(identidad) .."|".. nombre
    if ORIGEN_DIR ~= nil and ORIGEN_DIR[clave] ~= nil then
        return ORIGEN_DIR[clave] .. nombre
    end
    if identidad <= 12 then
        local dir_sistemas = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear";
        "Nintendo Famicom"; "Nintendo Game Boy"; "Nintendo Game Boy Color";
        "Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000";
        "Neo Geo Pocket"; "Nintendo Super Famicom";}
        return RUTA_ROM(identidad, dir_sistemas[identidad], nombre)
    end
    return nil
end

--- Borrar el juego seleccionado, con confirmacion. -----------------------------------
--- SELECT + CUADRADO en la lista. Se muestra la ruta COMPLETA antes de preguntar: es
--- la unica forma de que el usuario vea que se va a borrar el fichero que cree, y no
--- otro con el mismo nombre en otra unidad.
--- La respuesta por defecto es NO, y se exige mantener SELECT: un borrado no debe
--- poder ocurrir por un boton pulsado sin querer.
function borrar_juego_actual()
    local nombre = LISTAS.ROMS[LISTAS.INDICE]
    if nombre == nil then return false end
    local ruta = RUTA_JUEGO_ACTUAL()

    local titulo = "Delete this game?"
    local lineas = {}
    if ruta == nil then
        titulo = "Cannot delete"
        lineas = {NOMBRE_VISIBLE(LISTAS.IDENTIDAD, nombre, 1),
                  "the file location is not known for this system"}
    else
        lineas = {NOMBRE_VISIBLE(LISTAS.IDENTIDAD, nombre, 1), salida_texto_dir(ruta, true)}
        local tam = ROM_TAMANO(ruta)
        if tam ~= nil then
            lineas[#lineas + 1] = string.format("%.2f GB - this cannot be undone",
                                                tam / (1024 * 1024 * 1024))
        end
    end

    local confirmar, salir = false, false
    JOYSTICK_LIMITE = control_FPS(1)
    while salir == false do
        CONTROL.FPS = Screen.getFPS(1)
        capturar(JOYSTICK_LIMITE)
        dibujar_fondos()
        local respuestas = {"DELETE", "cancel"}
        if ruta == nil then respuestas = {" ", "cancel"} end
        submenu_selector(lineas, nil, "-".. titulo .."-", 96, 300, true,
                         CONTROL.ANCHO // 2, respuestas, false, false, {}, nil)
        refrescar(false)
        -- CUADRADO para confirmar, no CRUZ: CRUZ es la tecla con la que se ha
        -- llegado hasta aqui desde el menu, y dejarla confirmar convertiria dos
        -- pulsaciones seguidas en un borrado.
        if ruta ~= nil and Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
            confirmar, salir = true, true
        elseif Pads.check(PAD, PAD_TRIANGLE) or Pads.check(PAD, PAD_CIRCLE) then
            salir = true
        end
    end
    JOYSTICK_LIMITE = control_FPS(1)
    if confirmar == false then
        repro_sfx(S_CANCELAR, 1, false, nil)
        return false
    end

    local ok = pcall(System.removeFile, ruta)
    ok = ok and (doesFileExist(ruta) == false)
    boot_log("BORRA  ".. tostring(ruta) .." -> ".. tostring(ok))
    boot_escribir()
    if ok == false then
        repro_sfx(S_CANCELAR, 1, false, nil)
        return false
    end
    repro_sfx(S_EJECUTAR, 1, false, nil)

    -- Que el juego desaparezca de la lista sin tener que reiniciar. El indice puede
    -- quedar mas alla del final si era el ultimo.
    media_indice_olvidar()
    CORES_CACHE = {}
    recargar_una(LISTAS.IDENTIDAD)
    LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
    if LISTAS.INDICE > #LISTAS.ROMS then LISTAS.INDICE = #LISTAS.ROMS end
    if LISTAS.INDICE < 1 then LISTAS.INDICE = 1 end
    indices_extras()
    return true
end

function recargar_una(identidad)
	PRE_CARGADAS[identidad] = crear_listas(identidad, PRE_CARGADAS[identidad])
	LISTAS.IDENTIDAD = identidad
end

--- Buscar y guardar fuentes de texto. --------------------------------------------------
function buscar_fuentes()
	local actual = System.currentDirectory()
	local buscar_fuentes = System.listDirectory(RUTA_GLOBAL("Font"))
	OPCIONES.FUENTES_ENCONTRADAS = {}
	table.insert(OPCIONES.FUENTES_ENCONTRADAS, actual .."/System/Medias/Font/PublicPixel.ttf")
	if buscar_fuentes ~= nil then
		for contador = 1, #buscar_fuentes do
			if buscar_fuentes[contador].directory == false and (string.lower(string.sub(buscar_fuentes[contador].name, -4)) == ".ttf" or string.lower(string.sub(buscar_fuentes[contador].name, -4)) == ".otf") then
				table.insert(OPCIONES.FUENTES_ENCONTRADAS, RUTA_GLOBAL("Font") .."/".. buscar_fuentes[contador].name)
			end
		end
	end
end

--- Busca y establece los fondos de pantalla. -------------------------------------------
function buscar_fondos(cambio_de_fondo, selec_fondo)
	local actual = System.currentDirectory()
	local buscar_fondos = System.listDirectory(RUTA_GLOBAL("Background"))
	OPCIONES.FONDO_ENCONTRADOS = {}
	table.insert(OPCIONES.FONDO_ENCONTRADOS, actual .."/".. verif_img("System/Medias/Default/FONDO.png"))
	table.insert(OPCIONES.FONDO_ENCONTRADOS, actual .."/".. verif_img("System/Medias/Default/FONDO_2x2_ANI.png"))
	table.insert(OPCIONES.FONDO_ENCONTRADOS, actual .."/".. verif_img("System/Medias/Default/FONDO_X4101101_LAY.png"))
	if buscar_fondos ~= nil then
		for contador = 1, #buscar_fondos do
			if buscar_fondos[contador].directory == false and string.lower(string.sub(buscar_fondos[contador].name, -4)) == ".png" then
				table.insert(OPCIONES.FONDO_ENCONTRADOS, RUTA_GLOBAL("Background") .."/".. buscar_fondos[contador].name)
			end
		end
	end
	if cambio_de_fondo == true and selec_fondo ~= nil then
		if selec_fondo <= #OPCIONES.FONDO_ENCONTRADOS and selec_fondo >= 1 then
			Graphics.freeImage(LISTAS.FONDO)
			LISTAS.FONDO = Graphics.loadImage(OPCIONES.FONDO_ENCONTRADOS[selec_fondo])
			if string.lower(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -8)) == "_ani.png" then
				SPRITES.FONDO_ANI, SPRITES.LAYER = true, false
				if string.match(string.lower(OPCIONES.FONDO_ENCONTRADOS[selec_fondo]), "%d.%d_ani%.png", -11) then
					local col, fil = string.find(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], "%d.%d", -11)
					SPRITES.FONDO_N_COLUMNS = tonumber(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], col, col))
					SPRITES.FONDO_N_ROWS = tonumber(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], fil, fil))
				else
					SPRITES.FONDO_N_COLUMNS = 4
					SPRITES.FONDO_N_ROWS = 4
				end
				SPRITES.FONDO_WIDTH_X = (Graphics.getImageWidth(LISTAS.FONDO)/SPRITES.FONDO_N_COLUMNS)
				SPRITES.FONDO_HEIGHT_Y = (Graphics.getImageHeight(LISTAS.FONDO)/SPRITES.FONDO_N_ROWS)
			elseif string.lower(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -8)) == "_lay.png" then
				if string.match(string.lower(OPCIONES.FONDO_ENCONTRADOS[selec_fondo]), "_[%w#][%w#][%w#][%w#][%w#][%w#][%w#][%w#]_lay%.png", -17) then
					SPRITES.LAYER_TYPE = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -16, -16), 62)
					SPRITES.LAYER_SPEED = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -15, -15), 62)
					SPRITES.LAYER_MULTI = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -14, -14), 16)
					SPRITES.TRAN_TYPE = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -13, -13), 20)
					SPRITES.TRAN_LEVEL = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -12, -12), 40)
					SPRITES.TRAN_SPEED = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -11, -11), 16)
					SPRITES.SPIN_TYPE = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -10, -10), 30)
					SPRITES.SPIN_SPEED = cha_res(string.sub(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], -9, -9), 62)
				else
					SPRITES.LAYER_TYPE, SPRITES.LAYER_SPEED, SPRITES.LAYER_MULTI = cha_res("0", 41), cha_res("1", 40), cha_res("1", 16)
					SPRITES.TRAN_TYPE, SPRITES.TRAN_LEVEL, SPRITES.TRAN_SPEED = cha_res("0", 20), cha_res("0", 40), cha_res("0", 16)
					SPRITES.SPIN_TYPE, SPRITES.SPIN_SPEED = cha_res("0", 30), cha_res("0", 62)
				end
				SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4 = 0, 0, 0, 0
				SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4 = 0, 0, 0, 0
				SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
				SPRITES.TRAN, SPRITES.SPIN = {128, 128, 128, 128}, 0.00
				SPRITES.TRAN_ALT, SPRITES.ZOOM, SPRITES.ANG = {false, false, false, false}, {0, false}, {0.00, 3.14}
				SPRITES.ALTERNATE, SPRITES.ALTERNATE_R, SPRITES.ALTERNATE_T, SPRITES.ACTIVATE_ALTER_T = false, false, false, true
				SPRITES.FONDO_ANI, SPRITES.LAYER = true, true
				SPRITES.FONDO_N_COLUMNS, SPRITES.FONDO_N_ROWS = 2, 2
				SPRITES.FONDO_WIDTH_X = (Graphics.getImageWidth(LISTAS.FONDO)/SPRITES.FONDO_N_COLUMNS)
				SPRITES.FONDO_HEIGHT_Y = (Graphics.getImageHeight(LISTAS.FONDO)/SPRITES.FONDO_N_ROWS)
			else
				SPRITES.FONDO_ANI = false
				SPRITES.LAYER = false
				SPRITES.LAYER_TYPE = 1
			end
			OPCIONES.CAMBIO_FONDO_ON = selec_fondo
		else
			OPCIONES.CAMBIO_FONDO_ON = 1
			OPCIONES.FONDO_ENCONTRADOS = {}
		end
	end
end

--- Buscar y guardar directorios / Buscar y guardar aplicaciones. -----------------------
function buscar_directorio(dir, disp)
	if dir == true and OPCIONES.SALIDA_RETROLANCHER ~= nil then
		local buscar_directorios = System.listDirectory(OPCIONES.SALIDA_RETROLANCHER)
		if buscar_directorios ~= nil then
			OPCIONES.SALIDA_DIR_ACTUALES = {}
			table.insert(OPCIONES.SALIDA_DIR_ANTERIORES, OPCIONES.SALIDA_RETROLANCHER)
			for contador = 1, #buscar_directorios do
				if buscar_directorios[contador].directory == true and string.sub(buscar_directorios[contador].name, -1) ~= "." and string.sub(buscar_directorios[contador].name, -2) ~= ".." then
					table.insert(OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES[#OPCIONES.SALIDA_DIR_ANTERIORES] .. buscar_directorios[contador].name .."/")
				elseif buscar_directorios[contador].directory == false and string.lower(string.sub(buscar_directorios[contador].name, -4)) == ".elf" then
					table.insert(OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES[#OPCIONES.SALIDA_DIR_ANTERIORES] .. buscar_directorios[contador].name)
				end
			end
		end
	elseif dir == false then
		if #OPCIONES.SALIDA_DIR_ANTERIORES >= 2 then
			table.remove(OPCIONES.SALIDA_DIR_ANTERIORES, #OPCIONES.SALIDA_DIR_ANTERIORES)
		end
		local buscar_directorios = System.listDirectory(OPCIONES.SALIDA_DIR_ANTERIORES[#OPCIONES.SALIDA_DIR_ANTERIORES])
		OPCIONES.SALIDA_DIR_ACTUALES = {}
		if buscar_directorios ~= nil then
			for contador = 1, #buscar_directorios do
				if buscar_directorios[contador].directory == true then
					table.insert(OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES[#OPCIONES.SALIDA_DIR_ANTERIORES] .. buscar_directorios[contador].name .."/")
				elseif buscar_directorios[contador].directory == false and string.lower(string.sub(buscar_directorios[contador].name, -4)) == ".elf" then
					table.insert(OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES[#OPCIONES.SALIDA_DIR_ANTERIORES] .. buscar_directorios[contador].name)
				end
			end
		end
	elseif dir == nil then
		local device = salida_texto_dir(System.currentDirectory(), nil)
		if disp == 0 then
			OPCIONES.SALIDA_RETROLANCHER = "PS2 SYSTEM MENU"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
		elseif disp == 1 then
			OPCIONES.SALIDA_RETROLANCHER = "mc0:/"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
		elseif disp == 2 then
			OPCIONES.SALIDA_RETROLANCHER = "mc1:/"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
		elseif disp == 3 then
			OPCIONES.SALIDA_RETROLANCHER = device .."/"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
		elseif disp >= 4 and BDM_DEVICES ~= nil and BDM_DEVICES[disp-3] ~= nil then
			OPCIONES.SALIDA_RETROLANCHER = BDM_DEVICES[disp-3] .."/"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
		end
	end
	if #OPCIONES.SALIDA_DIR_ACTUALES >= 1 then
		table.sort(OPCIONES.SALIDA_DIR_ACTUALES, orden_alfabetico)
	end
end

--- Muestra mini explorador de directorios. ---------------------------------------------
function marcar_directorio(tipo, busqueda, fondos)
	Pads.rumble(0, 0, 0)
	local device, scroll_dir, selector, cachucho = salida_texto_dir(System.currentDirectory(), nil), 1, 1, true
	local prev, prev_on, prev_opl = OPCIONES.SALIDA_RETROLANCHER, OPCIONES.SALIDA_RETROLANCHER_ON, OPCIONES.OPL_ELF
	buscar_directorio(nil, busqueda)
	buscar_directorio(true, busqueda)
	JOYSTICK_LIMITE = control_FPS(1)-20
	while cachucho do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		tiempo_de_scroll()

		-- Mostrar todo en pantalla. ----------------------------------------------------
		fondos()
		Graphics.drawRect(12, 28+CONTROL.Y_FIX_PAL, 615, 375, COLOR.NEGRO_T)
		Graphics.drawRect(-5, 22+CONTROL.Y_FIX_PAL, 650, 25, COLOR.NEGRO)
		if #OPCIONES.SALIDA_DIR_ACTUALES >= 1 then
			if CONTROL.ESPERA_CARGA_SCR == false then
				scroll_dir = scroll_texto(scroll_dir, salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector], false), 44)
				if string.len(salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector], true)) >= 44 then
					LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector], true), 44)
				end
			end
			local mostrar_lista = 0
			for contador = 0, 12, 1 do
				local espacio_linea, valor = 62+((contador)*25)+CONTROL.Y_FIX_PAL, selector
				if contador == 0 then
					Graphics.drawRect(12+3, espacio_linea-3, 608, 25, COLOR.NEGRO_T)
					Font.ftPrint(CONTROL.fontARCA, 36, espacio_linea, 0, 588, 8, string.sub(salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector], true), LISTAS.SCROLL_TEX), CAMBIOS_EMUS.COLOR_EMU)
				elseif (selector+contador) <= #OPCIONES.SALIDA_DIR_ACTUALES then
					Font.ftPrint(CONTROL.fontARCA, 36, espacio_linea, 0, 588, 8, salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector+contador], true), COLOR.BLANCO_LISTA)
					valor = selector+contador
				else
					valor = nil
				end
				if valor ~= nil then
					Graphics.drawRect(16, espacio_linea+6, 12, 9, Color.new(0, 0, 0))
					if string.lower(string.sub(OPCIONES.SALIDA_DIR_ACTUALES[valor], -4)) == ".elf" then
						Graphics.drawRect(19, espacio_linea+5, 10, 7, Color.new(0, 128, 0))
					else
						Graphics.drawRect(19, espacio_linea+5, 10, 7, Color.new(128, 128, 0))
					end
				end
			end
			Font.ftPrint(CONTROL.fontARCA, 22, 25+CONTROL.Y_FIX_PAL, 0, 601, 8, string.sub(salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[selector], false), scroll_dir), COLOR.BLANCO)
			Graphics.drawRect(12, 422+CONTROL.Y_FIX_PAL, 615, 22, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, 36, 422+2+CONTROL.Y_FIX_PAL, 0, 588, 8, "/".. string.sub(salida_texto_dir(OPCIONES.SALIDA_DIR_ACTUALES[1], 0), 1, -2) ..": ".. #OPCIONES.SALIDA_DIR_ACTUALES .." ".. TEXT_M_EXP[3], COLOR.GRIS)
		else
			if CONTROL.ESPERA_CARGA_SCR == false then
				LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, TEXT_M_EXP[1], 44)
			end
			Font.ftPrint(CONTROL.fontARCA, 22, 65+CONTROL.Y_FIX_PAL, 0, 598, 8, string.sub(TEXT_M_EXP[1], LISTAS.SCROLL_TEX), CAMBIOS_EMUS.COLOR_EMU)
			Font.ftPrint(CONTROL.fontARCA, 22, 25+CONTROL.Y_FIX_PAL, 0, 601, 8, TEXT_M_EXP[2], COLOR.BLANCO)
		end
		Graphics.drawRect(-5, 392+CONTROL.Y_FIX_PAL, 650, 25, COLOR.NEGRO)
		dibujar_indicador(95, 395, TEXT_GEN[6], PAD_IMG.TRIANGLE, 25, 25, 1, false)
		dibujar_indicador(295, 395, TEXT_GEN[5], PAD_IMG.CROSS, 25, 25, 1, false)
		dibujar_indicador(495, 395, TEXT_GEN[4], PAD_IMG.CIRCLE, 25, 25, 1, false)
		refrescar(false)

		-- Controlar menú explorador. ---------------------------------------------------
		-- Ejecuta o guarda la aplicación. / Cambiar de directorios. --------------------
		if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if #OPCIONES.SALIDA_DIR_ANTERIORES >= 1 then
					OPCIONES.SALIDA_RETROLANCHER = OPCIONES.SALIDA_DIR_ACTUALES[selector]
			elseif #OPCIONES.SALIDA_DIR_ANTERIORES <= 0 then
					buscar_directorio(nil, busqueda)
			end
			buscar_directorio(true, busqueda)
			selector, scroll_dir, LISTAS.SCROLL_TEX = 1, 1, 1
			reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
			if OPCIONES.SALIDA_RETROLANCHER ~= nil and string.lower(string.sub(OPCIONES.SALIDA_RETROLANCHER, -4)) == ".elf" then
				if tipo == true then
					OPCIONES.OPL_ELF = OPCIONES.SALIDA_RETROLANCHER
					OPCIONES.SALIDA_RETROLANCHER = prev
					OPCIONES.SALIDA_RETROLANCHER_ON = prev_on
					guardar_directorio_elf(true)
					cargar_directorio_elf(true)
				elseif tipo == false then
					OPCIONES.OPL_ELF = prev_opl
					OPCIONES.SALIDA_RETROLANCHER_ON = busqueda
				elseif tipo == nil then
					System.loadELF(OPCIONES.SALIDA_RETROLANCHER, 0, salida_texto_dir(OPCIONES.SALIDA_RETROLANCHER, false))
				end
				cachucho = false
			end
			JOYSTICK_LIMITE = control_FPS(1)-5

		-- Regresar al directorio previo. -----------------------------------------------
		elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			if #OPCIONES.SALIDA_DIR_ANTERIORES >= 1 then
				buscar_directorio(false, busqueda)
			else
				buscar_directorio(nil, busqueda)
				buscar_directorio(true, busqueda)
			end
			JOYSTICK_LIMITE = control_FPS(1)-5
			selector, scroll_dir, LISTAS.SCROLL_TEX = 1, 1, 1
			reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)

		-- Desplazarse por los elementos encontrados. -----------------------------------
		elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and #OPCIONES.SALIDA_DIR_ACTUALES >= 1 and CONTROL.JOYSTICK_ON == false then
			local jump = 1
			if Pads.check(PAD, PAD_R2) or Pads.check(PAD, PAD_L2) or Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1) then
				jump = 5
			end
			if (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				selector = cambiar_valor(selector, 1, #OPCIONES.SALIDA_DIR_ACTUALES, jump, true)
			elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				selector = cambiar_valor(selector, 1, #OPCIONES.SALIDA_DIR_ACTUALES, jump, false)
			end
			local kabal = 1 if Left_Y ~= 1 or Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT) then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_MOVER, 1, true, nil)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)
			scroll_dir, LISTAS.SCROLL_TEX = 1, 1
			reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)

		-- Cancelar búsqueda y restaurar directorios previamente configurados. ----------
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			OPCIONES.OPL_ELF = prev_opl
			OPCIONES.SALIDA_RETROLANCHER = prev
			OPCIONES.SALIDA_RETROLANCHER_ON = prev_on
			cachucho = false
		end
	end
	Pads.rumble(0, 0, 0)
end

--- Muestra, cambia y guarda las configuraciones. ---------------------------------------
function menu_config()
	Pads.rumble(0, 0, 0)
	local cambio_ani, n_ani = true, 45

	-- Guardar configuraciones previas. -------------------------------------------------
	local anterior_conf = {OPCIONES.RGB_ON; OPCIONES.FONDO_RGB_ON; OPCIONES.FONDO_RGB_FIJO_ON; OPCIONES.R; OPCIONES.G; OPCIONES.B;
	CONTROL.ESTILO; SISTEMAS.MEGADRIVE_ON; SISTEMAS.MASTERSYSTEM_ON; SISTEMAS.GAMEGEAR_ON; SISTEMAS.FAMICOM_ON; SISTEMAS.GAMEBOY_ON;
	SISTEMAS.GAMEBOYCOLOR_ON; SISTEMAS.GAMEBOYADVANCE_ON; SISTEMAS.ATARI2600_ON; SISTEMAS.ATARILYNX_ON; SISTEMAS.SEGASG1000_ON;
	SISTEMAS.NEOGEOPOCKET_ON; SISTEMAS.SUPERFAMICOM_ON; SISTEMAS.APPS_ON; SISTEMAS.PLAYSTATION_ON; SISTEMAS.PLAYSTATION2_ON;
	OPCIONES.CAMBIO_FUENTE_ON; OPCIONES.CAMBIO_FONDO_ON; OPCIONES.GUI_LIMPIA_ON; OPCIONES.LIMITADOR_RAM_ON; OPCIONES.SALIDA_RETROLANCHER_ON;
	OPCIONES.SALIDA_RETROLANCHER; OPCIONES.APPS_MENU_FULL_PATH; OPCIONES.SOUND_ON; OPCIONES.SOUND_VOLUME; OPCIONES.SCREENSHOT_BACK_ON;
	OPCIONES.VIBRATION_ON; OPCIONES.DIR_EXTRAS_ON; CAMBIOS_EMUS.TRAS; OPCIONES.LIBERAR_LISTAS; OPCIONES.FONT_PIXEL_X; OPCIONES.FONT_PIXEL_Y;
	OPCIONES.FONT_SHADOW; OPCIONES.SCROLL_MIN; OPCIONES.SPRITE_ON; OPCIONES.SEE_INDEX; OPCIONES.COLOR_LISTA_B; OPCIONES.SCREENSHOT_BACK_TR;
	OPCIONES.RUN_DEFAULT, COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4]};

	-- Variables para controlar configuraciones. ----------------------------------------
	color_emu(LISTAS.IDENTIDAD, OPCIONES.FONDO_RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON)
	local lista_config = {OPCIONES.RGB_ON; OPCIONES.FONDO_RGB_ON; OPCIONES.FONDO_RGB_FIJO_ON; OPCIONES.R; OPCIONES.G;
	OPCIONES.B; CONTROL.ESTILO; SISTEMAS.MEGADRIVE_ON; SISTEMAS.MASTERSYSTEM_ON; SISTEMAS.GAMEGEAR_ON; SISTEMAS.FAMICOM_ON;
	SISTEMAS.GAMEBOY_ON; SISTEMAS.GAMEBOYCOLOR_ON; SISTEMAS.GAMEBOYADVANCE_ON; SISTEMAS.ATARI2600_ON; SISTEMAS.ATARILYNX_ON;
	SISTEMAS.SEGASG1000_ON; SISTEMAS.NEOGEOPOCKET_ON; SISTEMAS.SUPERFAMICOM_ON; SISTEMAS.APPS_ON; SISTEMAS.PLAYSTATION_ON;
	SISTEMAS.PLAYSTATION2_ON; OPCIONES.CAMBIO_FUENTE_ON; OPCIONES.CAMBIO_FONDO_ON; OPCIONES.GUI_LIMPIA_ON; OPCIONES.LIMITADOR_RAM_ON;
	OPCIONES.SALIDA_RETROLANCHER_ON; OPCIONES.SALIDA_RETROLANCHER; OPCIONES.APPS_MENU_FULL_PATH; OPCIONES.SOUND_ON;
	OPCIONES.SOUND_VOLUME; OPCIONES.SCREENSHOT_BACK_ON; OPCIONES.VIDEO_MODE; OPCIONES.VIBRATION_ON; OPCIONES.DIR_EXTRAS_ON; 0; 0; 0;};
	local lista_texto_config = {TEXT_M_CON[1]; TEXT_M_CON[2]; TEXT_M_CON[3]; TEXT_M_CON[4]; TEXT_M_CON[5]; TEXT_M_CON[6];
	TEXT_M_CON[7]; "Megadrive"; "Master System"; "Game Gear"; "Famicom"; "Game Boy"; "Game Boy Color"; "Game Boy Advance";
	"Atari 2600"; "Atari Lynx"; "SEGA SG-1000"; "Neo Geo Pocket"; "Super Famicom"; "APPS"; "PlayStation"; "PlayStation 2";
	TEXT_M_CON[8]; TEXT_M_CON[9]; TEXT_M_CON[10]; TEXT_M_CON[11]; TEXT_M_CON[12]; TEXT_M_CON[13]; TEXT_M_CON[14]; TEXT_M_CON[15];
	TEXT_M_CON[16]; TEXT_M_CON[17]; TEXT_M_CON[18]; TEXT_M_CON[19]; TEXT_M_CON[20]; "Language: English"; TEXT_M_CON[21]; TEXT_M_CON[22];};
	local noob, conf_numero, clean, reinicio, indi_rest_RL, selector, cambio_realizado, page = true, true, false, false, 0, 1, false, TEXT_M_CON[24]

	-- Opciones actuales de idioma. -----------------------------------------------------
	if doesFileExist("System/Defaults/SPA") then
		lista_texto_config[36] = "Lenguaje: Español"
	elseif doesFileExist("System/Defaults/POR") then
		lista_texto_config[36] = "Linguagem: Português"
	end

	-- Opciones actuales de audio. ------------------------------------------------------
	local mus_on = TEXT_GEN[14]
	if doesFileExist("System/Medias/Sound/Background/music.adp") then
		mus_on = TEXT_GEN[13]
	elseif doesFileExist("System/Medias/Sound/Background/music0.adp") then
		mus_on = TEXT_GEN[14]
	else
		mus_on = TEXT_M_PRI[15]
	end
	local volume = OPCIONES.SOUND_VOLUME

	-- Opciones actuales de colores y transparencias. -----------------------------------
	local cc_back_1, cc_back_2, cc_back_3, cc_back_4 = COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4]
	local color_demo = Color.new(OPCIONES.R, OPCIONES.G, OPCIONES.B, CAMBIOS_EMUS.TRAS)
	local prev_back_tras = OPCIONES.SCREENSHOT_BACK_TR
	if CAMBIOS_EMUS.TRAS == 0 then
		color_demo = Color.new(OPCIONES.R, OPCIONES.G, OPCIONES.B)
	end
	local tras_demo = CAMBIOS_EMUS.TRAS

	-- Opciones actuales de salida. -----------------------------------------------------
	local selec_dir, local_disp, menu_run = OPCIONES.SALIDA_RETROLANCHER_ON, salida_texto_dir(System.currentDirectory(), nil), OPCIONES.RUN_DEFAULT
	lista_texto_config[28] = OPCIONES.SALIDA_RETROLANCHER
	local function cambiar_medio()
		OPCIONES.SALIDA_RETROLANCHER_ON = selec_dir
		buscar_directorio(nil, OPCIONES.SALIDA_RETROLANCHER_ON)
		lista_config[28] = OPCIONES.SALIDA_RETROLANCHER
		lista_texto_config[28] = OPCIONES.SALIDA_RETROLANCHER
	end

	-- Opciones actuales de fuente de texto. --------------------------------------------
	local on_index = OPCIONES.SEE_INDEX
	buscar_fuentes()
	local selec_fuente = 1
	if OPCIONES.CAMBIO_FUENTE_ON <= #OPCIONES.FUENTES_ENCONTRADAS then
		selec_fuente = OPCIONES.CAMBIO_FUENTE_ON
	end
	local font_x, font_Y, font_shadow, font_scroll = OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y, OPCIONES.FONT_SHADOW, OPCIONES.SCROLL_MIN
	local function cambia_fuente()
		if selec_fuente <= #OPCIONES.FUENTES_ENCONTRADAS and selec_fuente >= 1 then
			Font.ftUnload(CONTROL.fontARCA)
			Font.ftUnload(CONTROL.fontABC)
			CONTROL.fontARCA = Font.ftLoad(OPCIONES.FUENTES_ENCONTRADAS[selec_fuente])
			CONTROL.fontABC = Font.ftLoad(OPCIONES.FUENTES_ENCONTRADAS[selec_fuente])
			if selec_fuente == 1 then
				OPCIONES.FONT_SHADOW, font_shadow = 5, 5
			else
				OPCIONES.FONT_SHADOW, font_shadow = 0, 0
			end
			Font.ftSetPixelSize(CONTROL.fontARCA, font_x, font_Y)
			Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
			OPCIONES.CAMBIO_FUENTE_ON = selec_fuente
		end
	end

	-- Opciones actuales de fondos de pantalla. -----------------------------------------
	local estilo_lista, ini_sprite = CONTROL.ESTILO, OPCIONES.SPRITE_ON
	buscar_fondos(nil, nil)
	local selec_fondo = 1
	if OPCIONES.CAMBIO_FONDO_ON <= #OPCIONES.FONDO_ENCONTRADOS then
		selec_fondo = OPCIONES.CAMBIO_FONDO_ON
	end
	local function m_dibujar_fondos()
		RGB(lista_config[1], lista_config[3], tras_demo)
		Screen.clear(CAMBIOS_EMUS.COLOR_EMU_BACK)
		if lista_config[2] == 1 and (lista_config[3] == 0 or (lista_config[3] == 1 and tras_demo == 0)) then
			if SPRITES.FONDO_ANI == true then
				fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, true, CAMBIOS_EMUS.COLOR_EMU_BACK)
			else
				Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, CAMBIOS_EMUS.COLOR_EMU_BACK)
			end
		elseif lista_config[3] == 1 and lista_config[2] == 1 then
			if SPRITES.FONDO_ANI == true then
				fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, false, CAMBIOS_EMUS.COLOR_EMU_BACK)
			else
				Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F)
			end
			Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO_F, color_demo)
		else
			if SPRITES.FONDO_ANI == true then
				fondo_sprites(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, 0.00, false, CAMBIOS_EMUS.COLOR_EMU_BACK)
			else
				Graphics.drawScaleImage(LISTAS.FONDO, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F)
			end
		end
	end

	-- Restaura opciones antes de salir. ------------------------------------------------
	local function rest()
		if doesFileExist(OPCIONES.SALIDA_RETROLANCHER) == false or string.lower(string.sub(OPCIONES.SALIDA_RETROLANCHER, -4)) ~= ".elf" then
			OPCIONES.SALIDA_RETROLANCHER_ON = anterior_conf[27]
			OPCIONES.SALIDA_RETROLANCHER = anterior_conf[28]
		end
		OPCIONES.R, OPCIONES.G, OPCIONES.B, OPCIONES.COLOR_LISTA_B = anterior_conf[4], anterior_conf[5], anterior_conf[6], anterior_conf[43]
	end

	-- Iniciar menú de configuración. ---------------------------------------------------
	while noob do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		tiempo_de_scroll()

		-- Controlar el mínimo de sistemas activos. -------------------------------------
		local rev2 = true
		for rev = 8, 22 do
			if lista_config[rev] == 1 then
				rev2 = false
				break
			end
		end
		if rev2 == true then
			lista_config[8] = 1
		end

		if cambio_ani == false then
		-- Salir de configuraciones. ----------------------------------------------------
		if Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
			local nueva_conf = {lista_config[1]; lista_config[2]; lista_config[3]; OPCIONES.R; OPCIONES.G; OPCIONES.B;
			estilo_lista; lista_config[8]; lista_config[9]; lista_config[10]; lista_config[11]; lista_config[12]; lista_config[13];
			lista_config[14]; lista_config[15]; lista_config[16]; lista_config[17]; lista_config[18]; lista_config[19]; lista_config[20];
			lista_config[21]; lista_config[22]; selec_fuente; selec_fondo; lista_config[25]; lista_config[26]; selec_dir; lista_texto_config[28];
			lista_config[29]; lista_config[30]; volume; lista_config[32]; lista_config[34]; lista_config[35]; tras_demo; OPCIONES.LIBERAR_LISTAS;
			font_x; font_Y; font_shadow; font_scroll; ini_sprite; on_index; OPCIONES.COLOR_LISTA_B; prev_back_tras, menu_run, cc_back_1, cc_back_2,
			cc_back_3, cc_back_4};
			cambio_realizado = false
			for chequeo = 1, #nueva_conf do
				if nueva_conf[chequeo] ~= anterior_conf[chequeo] then
					cambio_realizado = true
				end
			end
			if cambio_realizado == true then
				local pregunta = true
				local text_prin = TEXT_M_CON[26]
				local lista_resp = {TEXT_GEN[7], TEXT_GEN[6]}
				submenu_selector({TEXT_M_CON[27]}, nil, text_prin, 160, 224, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
				refrescar(false)
				JOYSTICK_LIMITE = control_FPS(1)-10
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						rest()
						noob = false
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						pregunta = false
					end
					refrescar(true)
				end
			else
				noob = false
			end
			repro_sfx(S_CANCELAR, 1, false, nil)
			JOYSTICK_LIMITE = control_FPS(1)-10
		end

		-- Ver controles de RETROLauncher. ----------------------------------------------
		if Pads.check(PAD, PAD_R3) or Pads.check(PAD, PAD_L3) and CONTROL.JOYSTICK_ON == false then
			JOYSTICK_LIMITE = control_FPS(1)
			ver_controles(false)
		end

		-- Sistemas de configuraciones extras. ------------------------------------------
		if Pads.check(PAD, PAD_SELECT) and CONTROL.JOYSTICK_ON == false and ((selector >= 4 and selector <= 23) or (selector == 24 and SPRITES.FONDO_ANI == true) or selector == 26 or selector == 29 or selector == 30 or selector == 32 or selector == 35) then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			-- Seleccionar configuración a editar con estilo personalizado. -------------
			local spr_menu = true
			if selector == 7 and estilo_lista == 7 then
				local lista_resp, pregunta, selec, submenu_lista = {TEXT_GEN[5], TEXT_GEN[4]}, true, 1, {TEXT_M_CON[117], TEXT_M_CON[118]}
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					submenu_selector(submenu_lista, selec, TEXT_M_CON[116], 160, 248, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					refrescar(false)
					if ((Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_MOVER, 1, false, nil)
						if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selec = cambiar_valor(selec, 1, 2, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selec = cambiar_valor(selec, 1, 2, 1, true)
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						if selec == 1 then
							spr_menu = false
						elseif selec == 2 then
							spr_menu = true
						end
						pregunta = false
						JOYSTICK_LIMITE = control_FPS(1)-20
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						spr_menu = nil
						pregunta = false
						JOYSTICK_LIMITE = control_FPS(1)
					end
				end
			end

			-- Configurar el color de sombras tras cada elemento. -----------------------
			if (selector >= 4 and selector <= 6) then
				local selec, pregunta = 1, true
				local nombres_conf = {TEXT_M_CON[4], TEXT_M_CON[5], TEXT_M_CON[6], TEXT_M_CON[65]}
				local lista_resp = {TEXT_GEN[12], TEXT_GEN[6]}
				local valores_actual = {cc_back_1, cc_back_2, cc_back_3, cc_back_4}
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					m_dibujar_fondos()
					Graphics.drawRect(12, 23+CONTROL.Y_FIX_PAL, 615, 400, Color.new(valores_actual[1], valores_actual[2], valores_actual[3], valores_actual[4]))
					submenu_selector(nombres_conf, selec, TEXT_M_CON[121], 100, 240, false, 22, lista_resp, false, false, valores_actual, 498)
					Graphics.drawRect(230, 137+CONTROL.Y_FIX_PAL, 210, 85, COLOR.BLANCO)
					Graphics.drawRect(235, 142+CONTROL.Y_FIX_PAL, 100, 75, COLOR.BLANCO)
					Graphics.drawRect(335, 142+CONTROL.Y_FIX_PAL, 100, 75, COLOR.NEGRO)
					Graphics.drawRect(235, 142+CONTROL.Y_FIX_PAL, 200, 75, Color.new(valores_actual[1], valores_actual[2], valores_actual[3], valores_actual[4]))
					refrescar(false)
					if ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and CONTROL.JOYSTICK_ON == false then
						if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selec = cambiar_valor(selec, 1, #valores_actual, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selec = cambiar_valor(selec, 1, #valores_actual, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							valores_actual[selec] = cambiar_valor(valores_actual[selec], 0, 128, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							valores_actual[selec] = cambiar_valor(valores_actual[selec], 0, 128, 1, true)
						end
						local kabal = 1 if Left_Y ~= 1 or Left_X ~= 1 then
							kabal = 2
						end
						if kabal == 1 then
							repro_sfx(S_MOVER, 1, true, nil)
						end
						JOYSTICK_LIMITE = control_FPS(kabal)
					elseif Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						cc_back_1, cc_back_2, cc_back_3, cc_back_4 = valores_actual[1], valores_actual[2], valores_actual[3], valores_actual[4]
						COLOR.NEGRO_T = Color.new(cc_back_1, cc_back_2, cc_back_3, cc_back_4)
						JOYSTICK_LIMITE = control_FPS(1)
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						JOYSTICK_LIMITE = control_FPS(1)
						pregunta = false
					end
				end

			-- Configurar estilo personalizado. -----------------------------------------
			elseif selector == 7 and estilo_lista == 7 and spr_menu == false then
				local reload = editor_tema()
				if CONTROL.ESTILO == 7 and reload == true then
					cargar_style(true)
				end

			-- Configurar sprites en los estilos predefinidos. --------------------------
			elseif selector == 7 and spr_menu == true then
				local selec, sistemas, pregunta, text_info = 1, LISTAS.IDENTIDAD, true, " "
				local lista_resp = {TEXT_M_CON[41], TEXT_GEN[4]}
				local nombres_sist = {"Megadrive"; "Master System"; "Game Gear"; "Famicom"; "Game Boy"; "Game Boy Color";
					"Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "NeoGeo Pocket"; "Super Famicom"; "APPS";
					"PlayStation"; "PlayStation 2";};
				local nombres_conf = {TEXT_M_CON[107] ..":"; TEXT_M_CON[108] .." \"".. nombres_sist[sistemas] .."\""; TEXT_M_CON[109] ..":";
					TEXT_M_CON[110] ..":"; TEXT_M_CON[111] ..":"; TEXT_M_CON[112] ..":"; TEXT_M_CON[113] ..":"; TEXT_M_CON[77] ..":";
					TEXT_M_CON[78] ..":"; TEXT_M_CON[79] ..":";};
				local pre_pos_x, pre_pos_y = CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO
				CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO = (CONTROL.ANCHO//2)-(74//2), 382-(100//2)+CONTROL.Y_FIX_PAL
				rest_sprites(true)
				local valores_actual = {ini_sprite, sistemas; SPRITES.MOVE[sistemas]; SPRITES.SPEED_SPRITE[sistemas];
					SPRITES.TRAN_SPRITE_ON[sistemas]; SPRITES.SPIN_SPRITE_ON[sistemas]; SPRITES.AUTO_MOVE_SPRITE[sistemas];
					SPRITES.N_COLUMNS[sistemas]; SPRITES.N_ROWS[sistemas]; (SPRITES.N_COLUMNS[sistemas]*SPRITES.N_ROWS[sistemas]);};
				local conf_min = {0, 1, 0, 1, 0, 0, 0, 1, 1}
				local conf_max = {1, 15, 62, 62, 24, 62, 9, 9, 9}
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local veloc = "\nx ".. valores_actual[4]
					if valores_actual[3] >= 53 and valores_actual[3] <= 58 then
						if valores_actual[4] >= 1 and valores_actual[4] <= 9 then
							veloc = "\nx 0.00".. valores_actual[4]
						elseif valores_actual[4] >= 10 and valores_actual[4] <= 18 then
							veloc = "\nx 0.0".. valores_actual[4]-9
						elseif valores_actual[4] >= 19 and valores_actual[4] <= 27 then
							veloc = "\nx 0.1".. valores_actual[4]
						elseif valores_actual[4] >= 28 and valores_actual[4] <= 36 then
							veloc = "\nx 0.2".. valores_actual[4]
						elseif valores_actual[4] >= 37 and valores_actual[4] <= 45 then
							veloc = "\nx 0.3".. valores_actual[4]
						elseif valores_actual[4] >= 46 and valores_actual[4] <= 54 then
							veloc = "\nx 0.4".. valores_actual[4]
						elseif valores_actual[4] >= 55 and valores_actual[4] <= 62 then
							veloc = "\nx 0.5".. valores_actual[4]
						end
					end
					local spr_trasp = TEXT_GEN[14]
					if valores_actual[5] >= 1 and valores_actual[5] <= 8 then
						spr_trasp = TEXT_SPR_T[64] .."\n".. ((16*valores_actual[5])*100)//128 .."%"
					elseif valores_actual[5] >= 9 and valores_actual[5] <= 16 then
						spr_trasp = TEXT_SPR_T[65] .."\n0% - ".. ((16*(valores_actual[5]-8))*100)//128 .."%"
					elseif valores_actual[5] >= 17 and valores_actual[5] <= 24 then
						spr_trasp = TEXT_SPR_T[66] .."\n".. (((16*(valores_actual[5]-16))*100)//128)//2 .."% - ".. ((16*(valores_actual[5]-16))*100)//128 .."%"
					end
					local spr_giro = TEXT_GEN[14]
					if valores_actual[6] >= 1 and valores_actual[6] <= 9 then
						spr_giro = TEXT_M_CON[97] .."\nx 0.00".. valores_actual[6]
					elseif valores_actual[6] >= 10 and valores_actual[6] <= 18 then
						spr_giro = TEXT_M_CON[97] .."\nx 0.0".. valores_actual[6]-9
					elseif valores_actual[6] >= 19 and valores_actual[6] <= 27 then
						spr_giro = TEXT_M_CON[97] .."\nx 0.1".. valores_actual[6]-18
					elseif valores_actual[6] >= 28 and valores_actual[6] <= 36 then
						spr_giro = TEXT_M_CON[98] .."\nx 0.00".. valores_actual[6]-27
					elseif valores_actual[6] >= 37 and valores_actual[6] <= 45 then
						spr_giro = TEXT_M_CON[98] .."\nx 0.0".. valores_actual[6]-36
					elseif valores_actual[6] >= 46 and valores_actual[6] <= 54 then
						spr_giro = TEXT_M_CON[98] .."\nx 0.1".. valores_actual[6]-45
					elseif valores_actual[6] >= 55 and valores_actual[6] <= 62 then
						spr_giro = TEXT_M_CON[99] .."\nx 0.1".. valores_actual[6]-54
					end
					local spr_refle = TEXT_GEN[14]
					if valores_actual[7] >= 1 and valores_actual[7] <= 9 then
						spr_refle = TEXT_SPR_T[66+valores_actual[7]]
					end
					text_info = TEXT_SPR_T[valores_actual[3]+1] .. veloc
					if selec == 5 then
						text_info = spr_trasp
					elseif selec == 6 then
						text_info = spr_giro
					elseif selec == 7 then
						text_info = spr_refle
					elseif selec == 8 then
						text_info = TEXT_SPR_T[76]
					elseif selec == 9 then
						text_info = TEXT_SPR_T[77]
					end
					local spr_on, pre_sys = valores_actual[1], valores_actual[2]
					if spr_on == 1 then
						valores_actual[1] = TEXT_GEN[13]
					else
						valores_actual[1] = TEXT_GEN[14]
					end
					valores_actual[2] = " "
					m_dibujar_fondos()
					submenu_selector(nombres_conf, selec, TEXT_M_CON[106], 20, 298, false, 20, lista_resp, false, false, valores_actual, 424)
					valores_actual[1] = spr_on
					valores_actual[2] =	pre_sys
					Graphics.drawRect(458, 110+CONTROL.Y_FIX_PAL, 2, 176, COLOR.BLANCO)
					Font.ftPrint(CONTROL.fontARCA, 470, 104+CONTROL.Y_FIX_PAL, 0, 200, 200, text_info, COLOR.BLANCO)
					if ini_sprite == 1 then
						dibujar_sprites(valores_actual[2], CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO, 74, 100, 0.00, SPRITES.FLIP[1], SPRITES.FLIP[2], true)
					end
					refrescar(false)
					if ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) or Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1)) and CONTROL.JOYSTICK_ON == false then
						if Pads.check(PAD, PAD_L1) then
							valores_actual[2] = cambiar_valor(valores_actual[2], conf_min[2], conf_max[2], 1, false)
						elseif Pads.check(PAD, PAD_R1) then
							valores_actual[2] = cambiar_valor(valores_actual[2], conf_min[2], conf_max[2], 1, true)
						elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selec = cambiar_valor(selec, 1, #valores_actual-1, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selec = cambiar_valor(selec, 1, #valores_actual-1, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							valores_actual[selec] = cambiar_valor(valores_actual[selec], conf_min[selec], conf_max[selec], 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							valores_actual[selec] = cambiar_valor(valores_actual[selec], conf_min[selec], conf_max[selec], 1, true)
						end
						if (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1) then
							if selec == 2 or Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1) then
								nombres_conf[2] = TEXT_M_CON[108] .." \"".. nombres_sist[valores_actual[2]] .."\""
								valores_actual = {valores_actual[1], valores_actual[2]; SPRITES.MOVE[valores_actual[2]];
								SPRITES.SPEED_SPRITE[valores_actual[2]]; SPRITES.TRAN_SPRITE_ON[valores_actual[2]];
								SPRITES.SPIN_SPRITE_ON[valores_actual[2]]; SPRITES.AUTO_MOVE_SPRITE[valores_actual[2]];
								SPRITES.N_COLUMNS[valores_actual[2]]; SPRITES.N_ROWS[valores_actual[2]];
								(SPRITES.N_COLUMNS[valores_actual[2]]*SPRITES.N_ROWS[valores_actual[2]]);};
							else
								valores_actual[10] = valores_actual[8]*valores_actual[9]
								ini_sprite = valores_actual[1]
								SPRITES.MOVE[valores_actual[2]] = valores_actual[3]
								SPRITES.SPEED_SPRITE[valores_actual[2]] = valores_actual[4]
								SPRITES.TRAN_SPRITE_ON[valores_actual[2]] = valores_actual[5]
								SPRITES.SPIN_SPRITE_ON[valores_actual[2]] = valores_actual[6]
								SPRITES.AUTO_MOVE_SPRITE[valores_actual[2]] = valores_actual[7]
								SPRITES.N_COLUMNS[valores_actual[2]] = valores_actual[8]
								SPRITES.N_ROWS[valores_actual[2]] = valores_actual[9]
								SPRITES.WIDTH_X[valores_actual[2]] = (Graphics.getImageWidth(SPRITES[SPRITES.SPRITE_SYS[valores_actual[2]]])/SPRITES.N_COLUMNS[valores_actual[2]])
								SPRITES.HEIGHT_Y[valores_actual[2]] = (Graphics.getImageHeight(SPRITES[SPRITES.SPRITE_SYS[valores_actual[2]]])/SPRITES.N_ROWS[valores_actual[2]])
							end
							rest_sprites(true)
						end
						local kabal = 1 if Left_Y ~= 1 or Left_X ~= 1 then
							kabal = 2
						end
						if kabal == 1 then
							repro_sfx(S_MOVER, 1, true, nil)
						end
						JOYSTICK_LIMITE = control_FPS(kabal)
					elseif Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						local actual = System.currentDirectory()
						local list_sprites, presente, prev_name = System.listDirectory(actual .."/System/Medias/Sprites"), false, " "
						local comparar = {"Megadrive_"; "MasterSystem_"; "GameGear_"; "Famicom_"; "GameBoy_"; "GameBoyColor_"; "GameBoyAdvance_";
						"Atari2600_"; "AtariLynx_"; "SegaSG1000_"; "NeoGeoPocket_"; "SuperFamicom_"; "Apps_"; "PlayStation_"; "PlayStation2_";}
						local new_name = comparar[valores_actual[2]] .. cha_res(nil, valores_actual[3]) .. cha_res(nil, valores_actual[4]) ..
						cha_res(nil, valores_actual[5]) .. cha_res(nil, valores_actual[6]) .. cha_res(nil, valores_actual[7]) .."_"..
						cha_res(nil, valores_actual[8]) .."x".. cha_res(nil, valores_actual[9]) ..".png"
						if list_sprites ~= nil then
							for cont = 1, #comparar do
								for cont2 = 1, #list_sprites do
									if string.match(string.lower(list_sprites[cont2].name), string.lower(comparar[valores_actual[2]] .."[%w#][%w#][%w#][%w#][%w#].%d.%d%.png")) and not (valores_actual[2] == 4 and string.match(list_sprites[cont2].name, "SuperFamicom_")) then
										prev_name = list_sprites[cont2].name
										presente = true
									end
									if presente == true then break end
								end
								if presente == true then break end
							end
						end
						if presente == true and new_name ~= prev_name then
							local conf = true
							while conf do
								CONTROL.FPS = Screen.getFPS(1)
								capturar(JOYSTICK_LIMITE)
								m_dibujar_fondos()
								local submenu_lista = {nombres_conf[2], TEXT_M_CON[81] ..":", prev_name, TEXT_M_CON[82] ..":", new_name}
								local lista_resp2 = {TEXT_GEN[8], TEXT_GEN[6]}
								submenu_selector(submenu_lista, nil, TEXT_M_CON[80] .."?", 160, 318, true, (CONTROL.ANCHO//2), lista_resp2, true, false, {}, nil)
								if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
									submenu_selector({}, nil, TEXT_M_CON[46], 160, 318, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
									repro_sfx(S_EJECUTAR, 1, false, nil)
									submenu_selector({}, nil, TEXT_M_CON[46], 160, 318, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
									System.rename(actual .."/System/Medias/Sprites/".. prev_name, actual .."/System/Medias/Sprites/".. new_name)
									conf = false
								elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
									repro_sfx(S_CANCELAR, 1, false, nil)
									conf = false
								end
								refrescar(false)
							end
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						TEML(false)
						CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO = pre_pos_x, pre_pos_y
						rest_sprites(true)
						pregunta = false
						JOYSTICK_LIMITE = control_FPS(1)
					end
				end

			-- Restauración individual de sistemas. -------------------------------------
			elseif (selector >= 8 and selector <= 19) then
				local pregunta = true
				Pads.rumble(0, 0, 0)
				local lista_indi_rest_RL = {11, 10, 9, 4, 5, 7, 6, 1, 2, 12, 3, 8}
				local lista_indi_rest = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear"; "Nintendo Famicom"; "Nintendo Game Boy";
				"Nintendo Game Boy Color"; "Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "Neo Geo Pocket";
				"Nintendo Super Famicom";};
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local eliminar_partidas = TEXT_GEN[9]
					if clean == true then
						eliminar_partidas = TEXT_GEN[10]
					end
					local submenu_lista = {"-".. TEXT_M_CON[51] .."-", eliminar_partidas}
					local text_prin = "-".. TEXT_M_CON[50] .." ".. lista_indi_rest[selector-7] .."?-"
					local lista_resp = {TEXT_GEN[11], TEXT_GEN[6]}
					submenu_selector(submenu_lista, nil, text_prin, 160, 245, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					Graphics.drawScaleImage(PAD_IMG.L1, CONTROL.ANCHO//2-64, 214+CONTROL.Y_FIX_PAL, 30, 30)
					Graphics.drawScaleImage(PAD_IMG.R1, CONTROL.ANCHO//2+32, 214+CONTROL.Y_FIX_PAL, 30, 30)
					if (Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1)) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_NETX, 1, false, nil)
						if clean == false then
							clean = true
						else
							clean = false
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_SQUARE) then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						rest()
						noob, reinicio, pregunta = false, true, false
						indi_rest_RL = lista_indi_rest_RL[selector-7]
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta, clean = false, false
						indi_rest_RL = 0
						JOYSTICK_LIMITE = control_FPS(1)
					end
					refrescar(false)
				end

			-- Configuraciones extras de APPS. ------------------------------------------
			elseif selector == 20 then
				local actual, pregunta, estado = System.currentDirectory(), true, "WLE: "
				-- El ELF cambia de nombre en cada version de uLaunchELF: se busca por
				-- extension, no por nombre.
				local _, wle_n, wle_off = RUTA_WLE(true)
				if wle_n == nil then
					estado = TEXT_M_PRI[17] .." ".. TEXT_M_PRI[20]
				elseif wle_off == true then
					estado = "WLE: ".. TEXT_GEN[14]
				else
					estado = "WLE: ".. TEXT_GEN[13]
				end
				while pregunta do
					CONTROL.FPS = Screen.getFPS(1)
					capturar(JOYSTICK_LIMITE)
					submenu_selector({estado}, nil, TEXT_M_CON[45], 160, 226, true, CONTROL.ANCHO//2, {TEXT_GEN[8], TEXT_GEN[6]}, false, false, {}, nil)
					refrescar(false)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 226, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						local _, nom, apagado = RUTA_WLE(true)
						if nom == nil then
							estado = TEXT_M_PRI[17] .." ".. TEXT_M_PRI[20]
						elseif apagado == true then
							-- Quitar el "_" del principio: vuelve a la lista.
							System.rename("uLaunchELF/".. nom, "uLaunchELF/".. string.sub(nom, 2))
							estado = "WLE: ".. TEXT_GEN[13]
						else
							System.rename("uLaunchELF/".. nom, "uLaunchELF/_".. nom)
							estado = "WLE: ".. TEXT_GEN[14]
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
				end

			-- Configuraciones extras de POPStarter. ------------------------------------
			elseif selector == 21 then
				local pregunta, selec_opt, device, actual = true, 1, salida_texto_dir(System.currentDirectory(), nil), System.currentDirectory()
				local lang = "ENG"
				if doesFileExist(actual .."/System/Defaults/SPA") then
					lang = "SPA"
				elseif doesFileExist(actual .."/System/Defaults/POR") then
					lang = "POR"
				end
				local estados_pops = {2, 2, 2}
				if doesFileExist(POPS_RAIZ .."/POPS/PATCH_9.BIN") == true then
					estados_pops[1] = 3
				end
				if doesFileExist(POPS_RAIZ .."/POPS/TROJAN_9.BIN") == true then
					estados_pops[2] = 3
				end
				while pregunta do
					CONTROL.FPS = Screen.getFPS(1)
					capturar(JOYSTICK_LIMITE)
					local text_prin = TEXT_M_CON[83]
					local submenu_lista = {TEXT_M_CON[84] ..": ".. TEXT_GEN[estados_pops[1]], TEXT_M_CON[85] ..": ".. TEXT_GEN[estados_pops[2]], TEXT_M_CON[86] .." (".. lang .."): ".. TEXT_GEN[estados_pops[3]]}
					local lista_resp = {TEXT_M_CON[41], TEXT_GEN[6]}
					submenu_selector(submenu_lista, selec_opt, text_prin, 160, 274, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					refrescar(false)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 274, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						if estados_pops[1] == 2 then
							if doesFileExist(POPS_RAIZ .."/POPS/PATCH_9.BIN") == true then
								System.removeFile(POPS_RAIZ .."/POPS/PATCH_9.BIN")
							end
						elseif estados_pops[1] == 3 then
							if doesFileExist(POPS_RAIZ .."/POPS/PATCH_9.BIN") == false and doesFileExist(actual .."/POPStarter/PATCH_9.BIN") then
								System.copyFile(actual .."/POPStarter/PATCH_9.BIN", POPS_RAIZ .."/POPS/PATCH_9.BIN")
							end
						end
						if estados_pops[2] == 2 then
							if doesFileExist(POPS_RAIZ .."/POPS/TROJAN_9.BIN") == true then
								System.removeFile(POPS_RAIZ .."/POPS/TROJAN_9.BIN")
							end
						elseif estados_pops[2] == 3 then
							if doesFileExist(POPS_RAIZ .."/POPS/TROJAN_9.BIN") == false and doesFileExist(actual .."/POPStarter/TROJAN_9.BIN") then
								System.copyFile(actual .."/POPStarter/TROJAN_9.BIN", POPS_RAIZ .."/POPS/TROJAN_9.BIN")
							end
						end
						if estados_pops[3] == 3 then
							if doesFileExist(actual .."/POPStarter/".. lang .."/IGR_BG.TM2") and doesFileExist(actual .."/POPStarter/".. lang .."/IGR_NO.TM2") and doesFileExist(actual .."/POPStarter/".. lang .."/IGR_YES.TM2") and System.listDirectory(POPS_RAIZ .."/POPS") ~= nil then
								System.copyFile(actual .."/POPStarter/".. lang .."/IGR_BG.TM2", POPS_RAIZ .."/POPS/IGR_BG.TM2")
								System.copyFile(actual .."/POPStarter/".. lang .."/IGR_NO.TM2", POPS_RAIZ .."/POPS/IGR_NO.TM2")
								System.copyFile(actual .."/POPStarter/".. lang .."/IGR_YES.TM2", POPS_RAIZ .."/POPS/IGR_YES.TM2")
							end
						end
						pregunta = false
						JOYSTICK_LIMITE = control_FPS(1)
					elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_MOVER, 1, false, nil)
						if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selec_opt = cambiar_valor(selec_opt, 1, 3, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selec_opt = cambiar_valor(selec_opt, 1, 3, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selec_opt == 1 then
							estados_pops[1] = cambiar_valor(estados_pops[1], 2, 3, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selec_opt == 1 then
							estados_pops[1] = cambiar_valor(estados_pops[1], 2, 3, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selec_opt == 2 then
							estados_pops[2] = cambiar_valor(estados_pops[2], 2, 3, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selec_opt == 2 then
							estados_pops[2] = cambiar_valor(estados_pops[2], 2, 3, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selec_opt == 3 then
							estados_pops[3] = cambiar_valor(estados_pops[3], 2, 3, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selec_opt == 3 then
							estados_pops[3] = cambiar_valor(estados_pops[3], 2, 3, 1, true)
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
				end

			-- Configurar directorio de OPL. --------------------------------------------
			elseif selector == 22 then
				local pregunta, selec_disp, scroll_opl, device = true, 1, 1, salida_texto_dir(System.currentDirectory(), nil)
				local text_prin = TEXT_M_CON[28]
				local lista_resp = {TEXT_M_CON[29], TEXT_GEN[4]}
				JOYSTICK_LIMITE = control_FPS(1)-20
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					tiempo_de_scroll()
					m_dibujar_fondos()
					if CONTROL.ESPERA_CARGA_SCR == false then
						scroll_opl = scroll_texto(scroll_opl, OPCIONES.OPL_ELF, 44)
					end
					-- Soportes disponibles + unidades BDM detectadas (disco interno exFAT). --
					local submenu_lista = {"mc0:", "mc1:", device}
					if BDM_DEVICES ~= nil then
						for i_bdm = 1, #BDM_DEVICES do
							table.insert(submenu_lista, BDM_DEVICES[i_bdm])
						end
					end
					local n_disp = #submenu_lista
					table.insert(submenu_lista, string.sub(OPCIONES.OPL_ELF, scroll_opl))
					-- Mismo ajuste de altura: 3 soportes de base + la linea de la ruta.
					local extra_bdm = #submenu_lista - 4
					if extra_bdm < 0 then extra_bdm = 0 end
					submenu_selector(submenu_lista, selec_disp, text_prin, 160-(extra_bdm*12), 297+(extra_bdm*12), true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					refrescar(false)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						marcar_directorio(true, selec_disp, m_dibujar_fondos)
						JOYSTICK_LIMITE = control_FPS(1)
					elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_MOVER, 1, false, nil)
						if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							selec_disp = cambiar_valor(selec_disp, 1, n_disp, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							selec_disp = cambiar_valor(selec_disp, 1, n_disp, 1, true)
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_CANCELAR, 1, false, nil)
						JOYSTICK_LIMITE = control_FPS(1)
						pregunta = false
					end
				end

			-- Configurar fuente de texto. ----------------------------------------------
			elseif selector == 23 then
				local pix_txt = {TEXT_M_CON[30] ..": ", TEXT_M_CON[31] ..": ", TEXT_M_CON[32] ..": ", TEXT_M_CON[33] ..": "}
				local example_text = {TEXT_M_CON[34], ""}
				local pix_option = {font_x, font_Y, font_shadow, font_scroll}
				local CONFT = Font.ftLoad("System/Medias/Font/PublicPixel.ttf")
				Font.ftSetPixelSize(CONTROL.fontARCA, pix_option[1], pix_option[2])
				Font.ftSetPixelSize(CONFT, 17, 16)
				Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
				local selector_pix = 1
				local scroll_test = 1
				local largo_actual = CONTROL.LISTA_X
				if largo_actual >= 578 then
					largo_actual = 578
				end
				local pregunta = true
				while pregunta do
					CONTROL.FPS = Screen.getFPS(1)
					capturar(JOYSTICK_LIMITE)
					tiempo_de_scroll()
					m_dibujar_fondos()
					Graphics.drawRect(10, 16+CONTROL.Y_FIX_PAL, 619, 419, COLOR.BLANCO)
					Graphics.drawRect(12, 18+CONTROL.Y_FIX_PAL, 615, 415, COLOR.NEGRO)
					Font.ftPrint(CONFT, (CONTROL.ANCHO//2), 25+CONTROL.Y_FIX_PAL, 8, 601, 20, "-".. TEXT_M_CON[35] .."-", COLOR.BLANCO)

					-- Ejemplo de cuadros de texto. -------------------------------------
					Font.ftPrint(CONFT, (CONTROL.ANCHO//2), 53+CONTROL.Y_FIX_PAL, 8, 601, 112, "-".. TEXT_M_CON[36] .."-", COLOR.GRIS)
					Graphics.drawRect(358, 80+CONTROL.Y_FIX_PAL, 250, 40, COLOR.GRIS)
					Graphics.drawRect(396, 92+CONTROL.Y_FIX_PAL, 174, 18, Color.new(40, 40, 40))
					Font.ftPrint(CONTROL.fontARCA, (358+250//2), 92+CONTROL.Y_FIX_PAL, 8, 250, 25, TEXT_M_PRI[1], COLOR.BLANCO)
					Graphics.drawRect(30, 80+CONTROL.Y_FIX_PAL, 250, 40, COLOR.GRIS)
					Graphics.drawRect(68, 92+CONTROL.Y_FIX_PAL, 174, 18, Color.new(40, 40, 40))
					Font.ftPrint(CONTROL.fontARCA, 30+38, 92+CONTROL.Y_FIX_PAL, 0, 174, 25, TEXT_M_PRI[27], COLOR.BLANCO)

					-- Ejemplo de listas y scroll. --------------------------------------
					if CONTROL.ESPERA_CARGA_SCR == false then
						scroll_test = scroll_texto(scroll_test, example_text[1], pix_option[4])
					end
					if pix_option[4]+4 ~= string.len(example_text[2]) then
						example_text[2] = ""
						for tex_sc = 1, pix_option[4]-3 do
							example_text[2] = example_text[2] .. TEXT_M_CON[75]
						end
						example_text[2] = example_text[2] .."-0-.zip"
					end
					Font.ftPrint(CONFT, (CONTROL.ANCHO//2), 127+CONTROL.Y_FIX_PAL, 8, 601, 25, "-".. TEXT_M_CON[37] .."-", COLOR.GRIS)
					Graphics.drawRect(30, 154+CONTROL.Y_FIX_PAL, largo_actual, 25, COLOR.GRIS)
					Graphics.drawRect(30+largo_actual-28, 154+CONTROL.Y_FIX_PAL, 28, 22, Color.new(20, 100, 20))
					Font.ftPrint(CONTROL.fontARCA, 35, 155+CONTROL.Y_FIX_PAL, 0, largo_actual, 25, example_text[2], COLOR.BLANCO)
					Graphics.drawRect(30, 182+CONTROL.Y_FIX_PAL, 578, 18, COLOR.GRIS)
					Font.ftPrint(CONTROL.fontARCA, 35, 183+CONTROL.Y_FIX_PAL, 0, 573, 20, string.sub(example_text[1], scroll_test), COLOR.BLANCO)

					-- Ejemplo de sombras tras los textos. ------------------------------
					Font.ftPrint(CONFT, (CONTROL.ANCHO//2), 209+CONTROL.Y_FIX_PAL, 8, 597, 112, "-".. TEXT_M_CON[38] .."-", COLOR.GRIS)
					Graphics.drawRect(30, 239+CONTROL.Y_FIX_PAL, (pix_option[3]*pix_option[1]*(string.len(TEXT_M_CON[39])/2)/3), 20, Color.new(40, 40, 40))
					Graphics.drawRect(30, 261+CONTROL.Y_FIX_PAL, (pix_option[3]*pix_option[1]*(string.len(TEXT_M_PRI[5])/2)/3), 20, Color.new(40, 40, 40))
					Graphics.drawRect(30, 283+CONTROL.Y_FIX_PAL, (pix_option[3]*pix_option[1]*(string.len(TEXT_M_PRI[6])/2)/3), 20, Color.new(40, 40, 40))
					Font.ftPrint(CONTROL.fontARCA, 33, 240+CONTROL.Y_FIX_PAL, 0, 615, 405, TEXT_M_CON[39], COLOR.BLANCO)
					Font.ftPrint(CONTROL.fontARCA, 33, 262+CONTROL.Y_FIX_PAL, 0, 615, 405, TEXT_M_PRI[5], COLOR.BLANCO)
					Font.ftPrint(CONTROL.fontARCA, 33, 284+CONTROL.Y_FIX_PAL, 0, 615, 405, TEXT_M_PRI[6], COLOR.BLANCO)

					-- Ejemplos de salto de carácter. -----------------------------------
					Graphics.drawRect(493, 281, 74, 68, Color.new(40, 40, 40))
					Font.ftPrint(CONTROL.fontABC, 530, 323, 8, 70, 70, TEXT_M_CON[76], COLOR.BLANCO)

					-- Opciones de ajustes. ---------------------------------------------
					local espacio_linea2 = 291+((0)*20)+CONTROL.Y_FIX_PAL
					for contador = 1, #pix_option, 1 do
						espacio_linea = 291+((contador)*20)+CONTROL.Y_FIX_PAL
						if contador == selector_pix then
							Graphics.drawRect(30-2, espacio_linea-2, (5*16*(string.len(pix_txt[contador] .. pix_option[contador])/2)/3)+4, 23, Color.new(128, 128, 128))
							Graphics.drawRect(30, espacio_linea, (5*16*(string.len(pix_txt[contador] .. pix_option[contador])/2)/3), 19, Color.new(30, 30, 30))
							Font.ftPrint(CONFT, 30, espacio_linea, 0, 630, 405, pix_txt[contador] .. pix_option[contador], COLOR.BLANCO)
						else
							Font.ftPrint(CONFT, 30, espacio_linea, 0, 630, 405, pix_txt[contador] .. pix_option[contador], COLOR.GRIS)
						end
					end
					Graphics.drawScaleImage(PAD_IMG.CIRCLE, 30, 402+CONTROL.Y_FIX_PAL, 25, 25)
					Font.ftPrint(CONFT, 65, 405+CONTROL.Y_FIX_PAL, 0, 0, 8, TEXT_M_CON[40], COLOR.BLANCO)
					Graphics.drawScaleImage(PAD_IMG.SQUARE, 273, 402+CONTROL.Y_FIX_PAL, 25, 25)
					Font.ftPrint(CONFT, 308, 405+CONTROL.Y_FIX_PAL, 0, 0, 8, TEXT_M_CON[41], COLOR.BLANCO)
					Graphics.drawScaleImage(PAD_IMG.TRIANGLE, 478, 402+CONTROL.Y_FIX_PAL, 25, 25)
					Font.ftPrint(CONFT, 513, 405+CONTROL.Y_FIX_PAL, 0, 0, 8, TEXT_GEN[6], COLOR.BLANCO)

					-- Control de ajustes. ----------------------------------------------
					if (Pads.check(PAD, PAD_UP) or Pads.check(PAD, PAD_DOWN) or Left_Y ~= 1) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_MOVER, 1, false, nil)
						if Pads.check(PAD, PAD_UP) or Left_Y <= -90 then
							selector_pix = cambiar_valor(selector_pix, 1, 4, 1, false)
						elseif Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 then
							selector_pix = cambiar_valor(selector_pix, 1, 4, 1, true)
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif (Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT) or Left_X ~= 1) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						local minimo_mov, max_mov = 2, 32
						if selector_pix == 3 then
							minimo_mov, max_mov = 0, 32
						elseif selector_pix == 4 then
							minimo_mov, max_mov = 10, 150
						end
						if Pads.check(PAD, PAD_LEFT) or Left_X <= -90 then
							pix_option[selector_pix] = cambiar_valor(pix_option[selector_pix], minimo_mov, max_mov, 1, false)
						elseif Pads.check(PAD, PAD_RIGHT) or Left_X >= 90 then
							pix_option[selector_pix] = cambiar_valor(pix_option[selector_pix], minimo_mov, max_mov, 1, true)
						end
						Font.ftSetPixelSize(CONTROL.fontARCA, pix_option[1], pix_option[2])
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_CIRCLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pix_option[1], pix_option[2], pix_option[3], pix_option[4] = 16, 16, 5, 24
						Font.ftSetPixelSize(CONTROL.fontARCA, pix_option[1], pix_option[2])
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_SQUARE) then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						font_x, font_Y, font_shadow, font_scroll = pix_option[1], pix_option[2], pix_option[3], pix_option[4]
						Font.ftSetPixelSize(CONTROL.fontARCA, font_x, font_Y)
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						Font.ftSetPixelSize(CONTROL.fontARCA, font_x, font_Y)
						pregunta = false
					end
					refrescar(false)
				end
				Font.ftUnload(CONFT)

			-- Configurar fondo animado. ------------------------------------------------
			elseif selector == 24 and SPRITES.FONDO_ANI == true then
				local actual, pregunta, selec_opt = System.currentDirectory(), true, 1
				local ex_conf = {SPRITES.FONDO_N_COLUMNS; SPRITES.FONDO_N_ROWS; SPRITES.LAYER_TYPE; SPRITES.LAYER_SPEED; SPRITES.LAYER_MULTI;
				SPRITES.TRAN_TYPE; SPRITES.TRAN_LEVEL; SPRITES.TRAN_SPEED; SPRITES.SPIN_TYPE; SPRITES.SPIN_SPEED;};
				local tipo_conf_sel, opcio_conf, opcio_limit, opcio_limit_min = 2, {SPRITES.FONDO_N_COLUMNS, SPRITES.FONDO_N_ROWS}, {4, 4}, {1,1}
				local names_conf = {TEXT_M_CON[77], TEXT_M_CON[78]}
				local pos_fix_pre = {160, 116, 162, 170, 244, 238, 390}
				local act_lay_1 = {0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1}
				local act_lay_2 = {0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1}
				local act_lay_3 = {0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1}
				local act_lay_4 = {0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1}
				local lista_resp = {TEXT_M_CON[41], TEXT_GEN[6]}
				if SPRITES.LAYER == true then
					tipo_conf_sel = 8
					opcio_conf = {SPRITES.LAYER_TYPE; SPRITES.LAYER_SPEED; SPRITES.LAYER_MULTI; SPRITES.TRAN_TYPE; SPRITES.TRAN_LEVEL;
					SPRITES.TRAN_SPEED; SPRITES.SPIN_TYPE; SPRITES.SPIN_SPEED;};
					opcio_limit = {62, 62, 16, 20, 40, 16, 30, 62}
					opcio_limit_min = {0, 1, 1, 0, 1, 1, 0, 1}
					names_conf = {TEXT_M_CON[88]; TEXT_M_CON[89]; TEXT_M_CON[90]; TEXT_M_CON[91]; TEXT_M_CON[92]; TEXT_M_CON[93]; TEXT_M_CON[94]; TEXT_M_CON[95];};
					pos_fix_pre = {100, 254, 102, 110, 330, 20, 380}
				end
				while pregunta do
					CONTROL.FPS = Screen.getFPS(1)
					capturar(JOYSTICK_LIMITE)
					m_dibujar_fondos()
					local title_menu = TEXT_M_CON[87]
					if SPRITES.LAYER == false then
						title_menu = TEXT_M_CON[79] ..": ".. (opcio_conf[1]*opcio_conf[2])
					end
					if not (Pads.check(PAD, PAD_CIRCLE) and SPRITES.LAYER == true) or (SPRITES.LAYER == false and SPRITES.FONDO_ANI == true) then
					submenu_selector(names_conf, selec_opt, title_menu, pos_fix_pre[1], pos_fix_pre[5], false, pos_fix_pre[6], lista_resp, false, false, opcio_conf, pos_fix_pre[7])

					-- Vista previa para la configuración de las capas. -----------------
					if SPRITES.LAYER == true then
						dibujar_indicador(CONTROL.ANCHO-78, pos_fix_pre[5]-1, TEXT_M_STI[41], PAD_IMG.CIRCLE, 20, 20, 5, false)
						if opcio_conf[1] >= 41 and opcio_conf[1] <= 58 then
							names_conf[3] = TEXT_M_CON[63]
						elseif opcio_conf[1] >= 39 and opcio_conf[1] <= 40 then
							names_conf[3] = TEXT_M_CON[115]
						else
							names_conf[3] = TEXT_M_CON[90]
						end
						local valor_mos_t, valor_mos_r = opcio_conf[4], opcio_conf[7]
						local text_info, text_velo, multiplicador = " ", "0.01", opcio_conf[3]
						if opcio_conf[7] >= 16 then
							valor_mos_r = valor_mos_r-15
						end
						if selec_opt >= 1 and selec_opt <= 3 then
							text_info = TEXT_LAY_T[opcio_conf[1]+1]
							if opcio_conf[1] >= 41 and opcio_conf[1] <= 58 then
								multiplicador = 1
								text_info = text_info ..": ".. 50*opcio_conf[3]
							elseif opcio_conf[1] >= 39 and opcio_conf[1] <= 40 then
								multiplicador = 1
								text_info = text_info .." /R:".. 20*opcio_conf[3]
							end
							if (opcio_conf[2] >= 1 and opcio_conf[2] <= 9) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.3f", (tonumber("0.00".. opcio_conf[2]))*multiplicador)
							elseif (opcio_conf[2] >= 10 and opcio_conf[2] <= 18) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.0".. opcio_conf[2]-9))*multiplicador)
							elseif (opcio_conf[2] >= 28 and opcio_conf[2] <= 36) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.0".. opcio_conf[2]-27))*multiplicador)
							elseif (opcio_conf[2] >= 46 and opcio_conf[2] <= 54) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.0".. opcio_conf[2]-45))*multiplicador)
							elseif (opcio_conf[2] >= 19 and opcio_conf[2] <= 27) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.".. opcio_conf[2]-18))*multiplicador)
							elseif (opcio_conf[2] >= 37 and opcio_conf[2] <= 45) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.".. opcio_conf[2]-36))*multiplicador)
							elseif (opcio_conf[2] >= 55 and opcio_conf[2] <= 62) and (opcio_conf[1] == 39 or opcio_conf[1] == 40) then
								text_velo = string.format("x %.2f", (tonumber("0.".. opcio_conf[2]-54))*multiplicador)
							elseif opcio_conf[2] >= 1 and opcio_conf[2] <= 9 then
								text_velo = string.format("x %.2f", (tonumber("0.".. opcio_conf[2]))*multiplicador)
							elseif opcio_conf[2] >= 10 then
								text_velo = "x ".. (opcio_conf[2]-9)*multiplicador ..".00"
							end
						elseif selec_opt >= 4 and selec_opt <= 6 then
							if opcio_conf[5] <= 8 then
								text_velo = ((16*opcio_conf[5])*100)//128 .."%"
								text_info = TEXT_M_CON[100]
							elseif opcio_conf[5] >= 9 and opcio_conf[5] <= 16 then
								text_velo = "0% - ".. ((16*(opcio_conf[5]-8))*100)//128 .."%"
								text_info = TEXT_M_CON[101]
							elseif opcio_conf[5] >= 17 and opcio_conf[5] <= 24 then
								text_velo = (((16*(opcio_conf[5]-16))*100)//128)//2 .."% - ".. ((16*(opcio_conf[5]-16))*100)//128 .."%"
								text_info = TEXT_M_CON[102]
							elseif opcio_conf[5] >= 25 and opcio_conf[5] <= 32 then
								text_velo = "0% - ".. ((16*(opcio_conf[5]-24))*100)//128 .."%"
								text_info = TEXT_M_CON[103]
							elseif opcio_conf[5] >= 33 and opcio_conf[5] <= 40 then
								text_velo = (((16*(opcio_conf[5]-32))*100)//128)//2 .."% - ".. ((16*(opcio_conf[5]-32))*100)//128 .."%"
								text_info = TEXT_M_CON[104]
							end
							if opcio_conf[4] == 0 then
								text_velo = "0%"
							end
						elseif selec_opt >= 7 and selec_opt <= 8 then
							text_info = TEXT_M_CON[97]
							if opcio_conf[7] >= 16 then
								text_info = TEXT_M_CON[98]
							end
							if opcio_conf[8] <= 9 then
								text_velo = "x 0.00".. opcio_conf[8]
							elseif opcio_conf[8] >= 10 and opcio_conf[8] <= 18 then
								text_velo = "x 0.0".. opcio_conf[8]-9
							elseif opcio_conf[8] >= 19 and opcio_conf[8] <= 27 then
								text_velo = "x 0.1".. opcio_conf[8]-18
							elseif opcio_conf[8] >= 28 and opcio_conf[8] <= 36 then
								text_velo = "x 0.0".. opcio_conf[8]-27
								text_info = TEXT_M_CON[99] .." 30°"
							elseif opcio_conf[8] >= 37 and opcio_conf[8] <= 45 then
								text_velo = "x 0.0".. opcio_conf[8]-36
								text_info = TEXT_M_CON[99] .." 180°"
							elseif opcio_conf[8] >= 46 and opcio_conf[8] <= 54 then
								text_velo = "x 0.0".. opcio_conf[8]-45
								text_info = TEXT_M_CON[99] .." 90°"
							elseif opcio_conf[8] >= 55 and opcio_conf[8] <= 62 then
								text_velo = "x 0.0".. opcio_conf[8]-54
								text_info = TEXT_M_CON[99] .." 360°"
							end
							if opcio_conf[7] == 0 then text_velo = "x 0.00" end
						end
						local largo_x, alto_y = SPRITES.FONDO_WIDTH_X, SPRITES.FONDO_HEIGHT_Y
						local cuadro_1 = {0, largo_x, 0, alto_y, 0, Color.new(128, 128, 128, 128)}
						local cuadro_2 = {largo_x, (largo_x*2), 0, alto_y, 0, Color.new(128, 128, 128, 128)}
						local cuadro_3 = {0, largo_x, alto_y, (alto_y*2), 0, Color.new(128, 128, 128, 128)}
						local cuadro_4 = {largo_x, (largo_x*2), alto_y, (alto_y*2), 0, Color.new(128, 128, 128, 128)}
						if act_lay_1[valor_mos_t+1] == 1 then cuadro_1[6] = Color.new(128, 128, 128, SPRITES.TRAN[1]) end
						if act_lay_2[valor_mos_t+1] == 1 then cuadro_2[6] = Color.new(128, 128, 128, SPRITES.TRAN[2]) end
						if act_lay_3[valor_mos_t+1] == 1 then cuadro_3[6] = Color.new(128, 128, 128, SPRITES.TRAN[3]) end
						if act_lay_4[valor_mos_t+1] == 1 then cuadro_4[6] = Color.new(128, 128, 128, SPRITES.TRAN[4]) end
						if act_lay_1[valor_mos_r+1] == 1 then cuadro_1[5] = SPRITES.SPIN end
						if act_lay_2[valor_mos_r+1] == 1 then cuadro_2[5] = SPRITES.SPIN end
						if act_lay_3[valor_mos_r+1] == 1 then cuadro_3[5] = SPRITES.SPIN end
						if act_lay_4[valor_mos_r+1] == 1 then cuadro_4[5] = SPRITES.SPIN end
						local x_l, y_l = 60, 42
						Graphics.drawImageExtended(LISTAS.FONDO, (435+(x_l/2))+x_l, 158+(y_l/2)+CONTROL.Y_FIX_PAL, cuadro_2[1], cuadro_2[3], cuadro_2[2], cuadro_2[4], x_l, y_l, cuadro_2[5], cuadro_2[6])
						Graphics.drawImageExtended(LISTAS.FONDO, 430+(x_l/2), (163+(y_l/2))+y_l+CONTROL.Y_FIX_PAL, cuadro_3[1], cuadro_3[3], cuadro_3[2], cuadro_3[4], x_l, y_l, cuadro_3[5], cuadro_3[6])
						Graphics.drawImageExtended(LISTAS.FONDO, (435+(x_l/2))+x_l, (163+(y_l/2))+y_l+CONTROL.Y_FIX_PAL, cuadro_4[1], cuadro_4[3], cuadro_4[2], cuadro_4[4], x_l, y_l, cuadro_4[5], cuadro_4[6])
						Graphics.drawImageExtended(LISTAS.FONDO, 430+(x_l/2), 158+(y_l/2)+CONTROL.Y_FIX_PAL, cuadro_1[1], cuadro_1[3], cuadro_1[2], cuadro_1[4], x_l, y_l, cuadro_1[5], cuadro_1[6])
						Graphics.drawRect(414, 136+CONTROL.Y_FIX_PAL, 2, 190, COLOR.BLANCO)
						Font.ftPrint(CONTROL.fontARCA, 430, 134+CONTROL.Y_FIX_PAL, 0, 210, 25, TEXT_M_CON[96], COLOR.BLANCO)
						Font.ftPrint(CONTROL.fontARCA, 430, 254+CONTROL.Y_FIX_PAL, 0, 210, 25, text_velo, COLOR.BLANCO)
						Font.ftPrint(CONTROL.fontARCA, 430, 278+CONTROL.Y_FIX_PAL, 0, 210, 25, text_info, COLOR.BLANCO)
					end

					-- Control de ajustes. ----------------------------------------------
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						local nombre_img = salida_texto_dir(OPCIONES.FONDO_ENCONTRADOS[selec_fondo], true)
						local nombre_new = nombre_img
						local mismo_nombre = ""
						if SPRITES.LAYER == false then
							mismo_nombre = string.match(string.lower(nombre_img), opcio_conf[1] .."%a".. opcio_conf[2] .."_ani%.png", -11)
						elseif SPRITES.LAYER == true then
							mismo_nombre = string.match(nombre_img, "_".. cha_res(nil, opcio_conf[1]) .. cha_res(nil, opcio_conf[2]) ..
							cha_res(nil, opcio_conf[3]) .. cha_res(nil, opcio_conf[4]) .. cha_res(nil, opcio_conf[5]) .. cha_res(nil, opcio_conf[6]) ..
							cha_res(nil, opcio_conf[7]) .. cha_res(nil, opcio_conf[8]) .."_[Ll][Aa][Yy]%.[Pp][Nn][Gg]", -17)
						end
						if ((SPRITES.LAYER == false and not mismo_nombre) or (SPRITES.LAYER == true and not mismo_nombre)) and not (selec_fondo >= 1 and selec_fondo <= 3) then
							if SPRITES.LAYER == false then
								if string.match(string.lower(nombre_img), "%d.%d_ani.png", -11) then
									nombre_new = string.sub(nombre_img, 1, -12) .. opcio_conf[1] .."x".. opcio_conf[2] .."_ANI.png"
								else
									nombre_new = string.sub(nombre_img, 1, -9) .." ".. opcio_conf[1] .."x".. opcio_conf[2] .."_ANI.png"
								end
							elseif SPRITES.LAYER == true then
								if string.match(string.lower(nombre_img), "_[%w#][%w#][%w#][%w#][%w#][%w#][%w#][%w#]_lay%.png", -17) then
									nombre_new = string.sub(nombre_img, 1, -17) .. cha_res(nil, opcio_conf[1]) .. cha_res(nil, opcio_conf[2]) ..
									cha_res(nil, opcio_conf[3]) .. cha_res(nil, opcio_conf[4]) .. cha_res(nil, opcio_conf[5]) ..
									cha_res(nil, opcio_conf[6]) .. cha_res(nil, opcio_conf[7]) .. cha_res(nil, opcio_conf[8]) .."_LAY.png"
								else
									nombre_new = string.sub(nombre_img, 1, -9) .."_".. cha_res(nil, opcio_conf[1]) .. cha_res(nil, opcio_conf[2]) ..
									cha_res(nil, opcio_conf[3]) .. cha_res(nil, opcio_conf[4]) .. cha_res(nil, opcio_conf[5]) ..
									cha_res(nil, opcio_conf[6]) .. cha_res(nil, opcio_conf[7]) .. cha_res(nil, opcio_conf[8]) .."_LAY.png"
								end
							end
							local pregunta_2 = true
							while pregunta_2 do
								CONTROL.FPS = Screen.getFPS(1)
								capturar(JOYSTICK_LIMITE)
								m_dibujar_fondos()
								local submenu_lista = {TEXT_M_CON[81] ..":", nombre_img, TEXT_M_CON[82] ..":", nombre_new}
								local lista_resp = {TEXT_GEN[8], TEXT_GEN[6]}
								submenu_selector(submenu_lista, nil, TEXT_M_CON[80] .."?", 160, 294, true, (CONTROL.ANCHO//2), lista_resp, true, false, {}, nil)
								if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
									repro_sfx(S_EJECUTAR, 1, false, nil)
									submenu_selector({}, nil, TEXT_M_CON[46], 160, 294, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
									-- Los fondos viven bajo "Roms/!Retrolauncher/Background". RUTA_GLOBAL lo
									-- resuelve, con "Multimedia/Others" como respaldo historico; la ruta fija
									-- que habia aqui se saltaba ese respaldo y el renombrado no ocurria.
									local dir_fondos = RUTA_GLOBAL("Background")
									if dir_fondos ~= nil and doesFileExist(dir_fondos .."/".. nombre_img) then
										System.rename(dir_fondos .."/".. nombre_img, dir_fondos .."/".. nombre_new)
									end
									buscar_fondos(nil, nil)
									if #OPCIONES.FONDO_ENCONTRADOS >= 1 and OPCIONES.FONDO_ENCONTRADOS ~= nil then
										for cont = 1, #OPCIONES.FONDO_ENCONTRADOS, 1 do
											if salida_texto_dir(OPCIONES.FONDO_ENCONTRADOS[cont], true) == nombre_new then
												selec_fondo = cont
											end
										end
										buscar_fondos(true, selec_fondo)
									end
									pregunta_2 = false
								elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
									repro_sfx(S_CANCELAR, 1, false, nil)
									pregunta_2 = false
								end
								refrescar(false)
							end
						end
						pregunta = false
						JOYSTICK_LIMITE = control_FPS(1)
					elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90)) and CONTROL.JOYSTICK_ON == false then
						if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
							selec_opt = cambiar_valor(selec_opt, 1, tipo_conf_sel, 1, false)
						elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
							selec_opt = cambiar_valor(selec_opt, 1, tipo_conf_sel, 1, true)
						elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							opcio_conf[selec_opt] = cambiar_valor(opcio_conf[selec_opt], opcio_limit_min[selec_opt], opcio_limit[selec_opt], 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							opcio_conf[selec_opt] = cambiar_valor(opcio_conf[selec_opt], opcio_limit_min[selec_opt], opcio_limit[selec_opt], 1, true)
						end
						if (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							if SPRITES.LAYER == false then
								SPRITES.FONDO_N_COLUMNS, SPRITES.FONDO_N_ROWS = opcio_conf[1], opcio_conf[2]
								SPRITES.FONDO_WIDTH_X = (Graphics.getImageWidth(LISTAS.FONDO)/opcio_conf[1])
								SPRITES.FONDO_HEIGHT_Y = (Graphics.getImageHeight(LISTAS.FONDO)/opcio_conf[2])
							elseif SPRITES.LAYER == true then
								SPRITES.LAYER_TYPE, SPRITES.LAYER_SPEED, SPRITES.LAYER_MULTI = opcio_conf[1], opcio_conf[2], opcio_conf[3]
								SPRITES.TRAN_TYPE, SPRITES.TRAN_LEVEL, SPRITES.TRAN_SPEED = opcio_conf[4], opcio_conf[5], opcio_conf[6]
								SPRITES.SPIN_TYPE, SPRITES.SPIN_SPEED = opcio_conf[7], opcio_conf[8]
								SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4 = 0, 0, 0, 0
								SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4 = 0, 0, 0, 0
								SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
								SPRITES.TRAN, SPRITES.SPIN = {128, 128, 128, 128}, 0.00
								SPRITES.TRAN_ALT, SPRITES.ZOOM, SPRITES.ANG = {false, false, false, false}, {0, false}, {0.00, 3.14}
								SPRITES.ALTERNATE, SPRITES.ALTERNATE_R, SPRITES.ALTERNATE_T, SPRITES.ACTIVATE_ALTER_T = false, false, false, true
							end
						end
						local kabal = 1 if Left_Y ~= 1 or Left_X ~= 1 then
							kabal = 2
						end
						if kabal == 1 then
							repro_sfx(S_MOVER, 1, true, nil)
						end
						JOYSTICK_LIMITE = control_FPS(kabal)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						SPRITES.FONDO_N_COLUMNS, SPRITES.FONDO_N_ROWS = ex_conf[1], ex_conf[2]
						SPRITES.FONDO_WIDTH_X = (Graphics.getImageWidth(LISTAS.FONDO)/SPRITES.FONDO_N_COLUMNS)
						SPRITES.FONDO_HEIGHT_Y = (Graphics.getImageHeight(LISTAS.FONDO)/SPRITES.FONDO_N_ROWS)
						SPRITES.LAYER_TYPE, SPRITES.LAYER_SPEED, SPRITES.LAYER_MULTI = ex_conf[3], ex_conf[4], ex_conf[5]
						SPRITES.TRAN_TYPE, SPRITES.TRAN_LEVEL, SPRITES.TRAN_SPEED = ex_conf[6], ex_conf[7], ex_conf[8]
						SPRITES.SPIN_TYPE, SPRITES.SPIN_SPEED = ex_conf[9], ex_conf[10]
						SPRITES.LAYER_X_1, SPRITES.LAYER_X_2, SPRITES.LAYER_X_3, SPRITES.LAYER_X_4 = 0, 0, 0, 0
						SPRITES.LAYER_Y_1, SPRITES.LAYER_Y_2, SPRITES.LAYER_Y_3, SPRITES.LAYER_Y_4 = 0, 0, 0, 0
						SPRITES.BACK_X, SPRITES.BACK_Y = 0, 0
						SPRITES.TRAN, SPRITES.SPIN = {128, 128, 128, 128}, 0.00
						SPRITES.TRAN_ALT, SPRITES.ZOOM, SPRITES.ANG = {false, false, false, false}, {0, false}, {0.00, 3.14}
						SPRITES.ALTERNATE, SPRITES.ALTERNATE_R, SPRITES.ALTERNATE_T, SPRITES.ACTIVATE_ALTER_T = false, false, false, true
						pregunta = false
					end
					end
					refrescar(false)
				end

			-- Configurar la carga de lista única. --------------------------------------
			elseif selector == 26 then
				local lis_free = TEXT_GEN[14]
				if OPCIONES.LIBERAR_LISTAS == 1 then
					lis_free = TEXT_GEN[13]
				end
				local pregunta = true
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local lista_resp = {TEXT_GEN[8], TEXT_GEN[4]}
					local submenu_lista = {TEXT_M_CON[43], TEXT_M_CON[44], lis_free}
					submenu_selector(submenu_lista, nil, "-".. TEXT_M_CON[42] .."-", 160, 272, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 272, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						if OPCIONES.LIBERAR_LISTAS == 0 then
							OPCIONES.LIBERAR_LISTAS = 1
							lis_free = TEXT_GEN[13]
							PRE_CARGADAS = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
							recargar_una(LISTAS.IDENTIDAD)
						else
							OPCIONES.LIBERAR_LISTAS = 0
							lis_free = TEXT_GEN[14]
							local ante_l = LISTAS.IDENTIDAD
							PRE_CARGADAS = {}
							recargar_todas()
							LISTAS.IDENTIDAD = ante_l
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
					refrescar(false)
				end

			-- Activar la selección de aplicación al ejecutar juegos. -------------------
			elseif selector == 29 then
				local pregunta = true
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local lista_resp = {TEXT_GEN[8], TEXT_GEN[4]}
					local index_text = TEXT_GEN[14]
					if menu_run == 1 then
						index_text = TEXT_GEN[13]
					end
					submenu_selector({index_text}, nil, "-".. TEXT_M_CON[120] .."-", 160, 226, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						menu_run = cambiar_valor(menu_run, 0, 1, 1, true)
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
					refrescar(false)
				end

			-- Configurar música de fondo. ----------------------------------------------
			elseif selector == 30 then
				local pregunta = true
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local lista_resp = {TEXT_GEN[8], TEXT_GEN[4]}
					submenu_selector({mus_on}, nil, "-".. TEXT_M_CON[47] .."-", 160, 226, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 226, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						if doesFileExist("System/Medias/Sound/Background/music.adp") then
							mus_on = TEXT_GEN[14]
							System.rename("System/Medias/Sound/Background/music.adp", "System/Medias/Sound/Background/music0.adp")
							Sound.freeADPCM(S_MUSICA)
							S_MUSICA = nil
							Sound.setADPCMVolume(2, 0)
						elseif doesFileExist("System/Medias/Sound/Background/music0.adp") then
							mus_on = TEXT_GEN[13]
							System.rename("System/Medias/Sound/Background/music0.adp", "System/Medias/Sound/Background/music.adp")
							S_MUSICA = verificar_sonidos(MUSICA, "System/Medias/Sound/Background/music.adp")
							set_volume()
						else
							mus_on = TEXT_M_PRI[15]
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
					refrescar(false)
				end

			-- Cambiar nivel de transparencia sobre los screenshots de fondo. -----------
			elseif selector == 32 and lista_config[32] == 1 then
				local pregunta = true
				local prev_tras = prev_back_tras
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					m_dibujar_fondos()
					if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true then
						Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, prev_back_tras))
					else
						Graphics.drawScaleImage(LISTAS.COVER_DEFAULT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, prev_back_tras))
					end
					local lista_resp = {TEXT_GEN[12], TEXT_GEN[6]}
					local index_text = "<- %".. (prev_back_tras*100)//128 .." ->"
					submenu_selector({index_text}, nil, "-".. TEXT_M_CON[119] .."-", 160, 226, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90)) and CONTROL.JOYSTICK_ON == false then
						if (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							prev_back_tras = cambiar_valor(prev_back_tras, 1, 128, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							prev_back_tras = cambiar_valor(prev_back_tras, 1, 128, 1, true)
						end
						local kabal = 1 if Left_X ~= 1 then
							kabal = 2
						end
						if kabal == 1 then
							repro_sfx(S_MOVER, 1, false, nil)
						end
						JOYSTICK_LIMITE = control_FPS(kabal)
					elseif Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						JOYSTICK_LIMITE = control_FPS(1)
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						prev_back_tras = prev_tras
						pregunta = false
					end
					refrescar(false)
				end

			-- Mostrar índice junto a nombre de juego. ----------------------------------
			elseif selector == 35 then
				local pregunta = true
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local lista_resp = {TEXT_GEN[8], TEXT_GEN[4]}
					local index_text = TEXT_GEN[14]
					if on_index == 1 then
						index_text = TEXT_GEN[13]
					end
					submenu_selector({index_text}, nil, "-".. TEXT_M_CON[105] .."-", 160, 226, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 226, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						on_index = cambiar_valor(on_index, 0, 1, 1, true)
						-- Efecto inmediato Y guardado aparte. El valor viajaba hasta
						-- "nueva_conf" y de ahi a la casilla 42 de System.cfg, y
						-- despues de activarlo esa casilla seguia a 0. System.cfg son
						-- cuarenta y nueve numeros separados por espacios, releidos por
						-- posicion, y una de esas casillas guarda una RUTA: basta con
						-- que contenga un digito de mas o de menos para que todo lo que
						-- viene detras se lea corrido. No es sitio para un interruptor.
						OPCIONES.SEE_INDEX = on_index
						SEE_INDEX_GUARDAR(on_index)
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
					refrescar(false)
				end
			end
			JOYSTICK_LIMITE = control_FPS(1)
		end

		-- Cambio entre páginas de configuración. ---------------------------------------
		if Pads.check(PAD, PAD_L1) or Pads.check(PAD, PAD_R1) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_NETX, 1, true, nil)
			if conf_numero == true then
				conf_numero = false
				selector = 23
				page = TEXT_M_CON[25]
			else
				conf_numero = true
				selector = 1
				page = TEXT_M_CON[24]
			end
			JOYSTICK_LIMITE = control_FPS(1)
		end

		-- Cambiar y guardar los estados de configuración. ------------------------------
		if Pads.check(PAD, PAD_CROSS) and (selector <= 3 or selector >= 7) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, true, nil)
			if selector ~= 7 and selector ~= 23 and selector ~= 24 and selector ~= 27 and selector ~= 28 and selector ~= 31 and selector ~= 33 and selector <= 35 then
				-- Activa / Desactiva las opciones. -------------------------------------
				if lista_config[selector] == 0 then
					lista_config[selector] = 1
				elseif lista_config[selector] == 1 then
					lista_config[selector] = 0
				end

				-- Activa / Desactiva los directorios completos en APPS. ----------------
				if selector == 29 then
					OPCIONES.APPS_MENU_FULL_PATH = lista_config[29]
					OPCIONES.DIR_EXTRAS_ON = lista_config[35]
					PRE_CARGADAS[13] = crear_listas(13, PRE_CARGADAS[13])
					desactivados(nil)
				end

				-- Activa / Desactiva los directorios extras para APPS y PS2. -----------
				if selector == 35 then
					OPCIONES.APPS_MENU_FULL_PATH = lista_config[29]
					OPCIONES.DIR_EXTRAS_ON = lista_config[35]
					PRE_CARGADAS[13] = crear_listas(13, PRE_CARGADAS[13])
					PRE_CARGADAS[15] = crear_listas(15, PRE_CARGADAS[15])
					desactivados(nil)
				end

			-- Cambia el estilo de la lista. --------------------------------------------
			elseif selector == 7 then
				estilo_lista = cambiar_valor(estilo_lista, 1, 7, 1, true)

			-- Cambia la fuente de texto. -----------------------------------------------
			elseif selector == 23 then
				selec_fuente = cambiar_valor(selec_fuente, 1, #OPCIONES.FUENTES_ENCONTRADAS, 1, true)
				cambia_fuente()

			-- Cambia el fondo de pantalla. ---------------------------------------------
			elseif selector == 24 then
				selec_fondo = cambiar_valor(selec_fondo, 1, #OPCIONES.FONDO_ENCONTRADOS, 1, true)
				buscar_fondos(true, selec_fondo)

			-- Seleccionar dónde se buscará la salida de RETROLauncher. -----------------
			elseif selector == 27 then
				selec_dir = cambiar_valor(selec_dir, 0, 3, 1, true)
				cambiar_medio()

			-- Cambia la salida de RETROLauncher. ---------------------------------------
			elseif selector == 28 then
				if selec_dir ~= 0 then
					marcar_directorio(false, selec_dir, m_dibujar_fondos)
					selec_dir = OPCIONES.SALIDA_RETROLANCHER_ON
					lista_config[28] = OPCIONES.SALIDA_RETROLANCHER
					lista_texto_config[28] = OPCIONES.SALIDA_RETROLANCHER
				end

			-- Cambia el modo de video y reconfigura las opciones de RetroArch. ---------
			elseif selector == 33 then
				local pregunta = true
				Pads.rumble(0, 0, 0)
				local mode_act, prev = 1, lista_config[33]
				if lista_config[33] == 1 then
					mode_act = 2
				end
				local mode_vi_tex = {"NTSC", "PAL"}
				local submenu_lista = {TEXT_M_PRI[25], TEXT_M_CON[48], TEXT_M_CON[49] ..".", TEXT_M_PRI[26] .."."}
				local text_prin = "-".. TEXT_M_CON[52] .." ".. mode_vi_tex[mode_act] .."?-"
				local lista_resp = {TEXT_GEN[8], TEXT_GEN[6]}
				submenu_selector(submenu_lista, nil, text_prin, 160, 294, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
				refrescar(false)
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					if Pads.check(PAD, PAD_SQUARE) then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						lista_config[33] = cambiar_valor(lista_config[33], 0, 1, 1, true)
						if lista_config[33] == 0 then
							Screen.setMode(NTSC, 640, 448, CT24, INTERLACED, FIELD)
							CONTROL.ALTO_F = 448
							CONTROL.Y_FIX_PAL = 0
							OPCIONES.VIDEO_MODE = 0
						elseif lista_config[33] == 1 then
							Screen.setMode(PAL, 640, 512, CT24, INTERLACED, FIELD)
							CONTROL.ALTO_F = 512
							CONTROL.Y_FIX_PAL = 32
							OPCIONES.VIDEO_MODE = 1
						end
						OPCIONES.VIDEO_MODE = lista_config[33]
						rest()
						noob = false
						reinicio = true
						pregunta = false
						clean = false
						indi_rest_RL = 20
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						lista_config[33] = prev
						clean = false
						pregunta = false
						indi_rest_RL = 0
					end
					refrescar(true)
				end

			-- Configurar lenguaje de RETROLauncher. ------------------------------------
			elseif selector == 36 then
				local actual, pregunta, selec_lang = System.currentDirectory(), true, 1
				if doesFileExist(actual .."/System/Defaults/SPA") then
					selec_lang = 2
				elseif doesFileExist(actual .."/System/Defaults/POR") then
					selec_lang = 3
				end
				local lenguaje_pre = {"Change language?", "¿Cambiar de idioma?", "Alterar idioma?"}
				local lenguaje = {"English", "Español", "Português"}
				local lenguaje_op1 = {"Change", "Cambiar", "Mudar"}
				local lenguaje_op2 = {"Cancel", "Cancelar", "Cancelar"}
				local lenguaje_name = {"ENG", "SPA", "POR"}
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local submenu_lista = {"<- ".. lenguaje[selec_lang] .." ->"}
					local lista_resp = {lenguaje_op1[selec_lang], lenguaje_op2[selec_lang]}
					submenu_selector(submenu_lista, nil, lenguaje_pre[selec_lang], 160, 224, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						if doesFileExist(actual .."/System/Defaults/SPA") and selec_lang ~= 2 then
							System.rename(actual .."/System/Defaults/SPA", actual .."/System/Defaults/".. lenguaje_name[selec_lang])
							lang_select()
						elseif doesFileExist(actual .."/System/Defaults/POR") and selec_lang ~= 3 then
							System.rename(actual .."/System/Defaults/POR", actual .."/System/Defaults/".. lenguaje_name[selec_lang])
							lang_select()
						elseif doesFileExist(actual .."/System/Defaults/ENG") and selec_lang ~= 1 then
							System.rename(actual .."/System/Defaults/ENG", actual .."/System/Defaults/".. lenguaje_name[selec_lang])
							lang_select()
						end
						submenu_selector({}, nil, TEXT_M_CON[46], 160, 224, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
						Graphics.freeImage(LISTAS.COVER_DEFAULT)
						Graphics.freeImage(LISTAS.SCREENSHOT_DEFAULT)
						LISTAS.COVER_DEFAULT = Graphics.loadImage(verif_img("System/Medias/Default/".. img_lang("COVER_DEFAULT", true) ..".png"));
						LISTAS.SCREENSHOT_DEFAULT = Graphics.loadImage(verif_img("System/Medias/Default/".. img_lang("SCREENSHOT_DEFAULT", false) ..".png"));
						pregunta = false
						rest()
						noob = false
						JOYSTICK_LIMITE = control_FPS(1)
					elseif ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90)) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_MOVER, 1, false, nil)
						if (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
							selec_lang = cambiar_valor(selec_lang, 1, 3, 1, false)
						elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
							selec_lang = cambiar_valor(selec_lang, 1, 3, 1, true)
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
					end
					refrescar(false)
				end

			-- Reinicia todas las configuraciones. --------------------------------------
			elseif selector == 37 then
				local pregunta = true
				Pads.rumble(0, 0, 0)
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					local eliminar_partidas = TEXT_GEN[9]
					if clean == true then
						eliminar_partidas = TEXT_GEN[10]
					end
					local submenu_lista = {"-".. TEXT_M_CON[51] .."-", eliminar_partidas}
					local text_prin = "-".. TEXT_M_CON[53] .."-"
					local lista_resp = {TEXT_GEN[11], TEXT_GEN[6]}
					submenu_selector(submenu_lista, nil, text_prin, 160, 245, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					Graphics.drawScaleImage(PAD_IMG.L1, CONTROL.ANCHO//2-64, 214+CONTROL.Y_FIX_PAL, 30, 30)
					Graphics.drawScaleImage(PAD_IMG.R1, CONTROL.ANCHO//2+32, 214+CONTROL.Y_FIX_PAL, 30, 30)
					if Pads.check(PAD, PAD_R1) and CONTROL.JOYSTICK_ON == false then
						repro_sfx(S_NETX, 1, false, nil)
						if clean == false then
							clean = true
						else
							clean = false
						end
						JOYSTICK_LIMITE = control_FPS(1)
					elseif Pads.check(PAD, PAD_SQUARE) then
						repro_sfx(S_EJECUTAR, 1, false, nil)
						noob = false
						reinicio = true
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
						clean = false
						JOYSTICK_LIMITE = control_FPS(1)
					end
					refrescar(false)
				end

			-- Muestra los créditos. ----------------------------------------------------
			elseif selector == 38 then
				creditos(m_dibujar_fondos)
			end

			-- Desactiva "RGB" si la personalización está activada. ---------------------
			if (lista_config[2] == 0 or lista_config[3] == 1) and lista_config[1] == 1 then
				lista_config[1] = 0
			end

			-- Aplica los cambios de colores al estilo. ---------------------------------
			if lista_config[3] == 1 then
				color_emu(0, lista_config[2], lista_config[3])
			elseif lista_config[3] == 0 then
				color_emu(LISTAS.IDENTIDAD, lista_config[2], lista_config[3])
			end
			if (selector <= 3 or selector >= 1) and lista_config[1] == 0 and lista_config[2] == 0 and lista_config[3] == 0 then
				color_emu(0, lista_config[2], lista_config[3])
			elseif (selector <= 3 or selector >= 1) and lista_config[1] == 0 and lista_config[2] == 1 and lista_config[3] == 0 then
				color_emu(LISTAS.IDENTIDAD, lista_config[2], lista_config[3])
			end

			-- Activa / Desactiva los sonidos y la vibración. ---------------------------
			OPCIONES.SOUND_ON = lista_config[30]
			OPCIONES.VIBRATION_ON = lista_config[34]
			JOYSTICK_LIMITE = control_FPS(1)
		end

		-- Guardar todas las configuraciones. -------------------------------------------
		if Pads.check(PAD, PAD_START) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, true, nil)
			Pads.rumble(0, 0, 0)
			OPCIONES.RGB_ON = lista_config[1]
			OPCIONES.FONDO_RGB_ON = lista_config[2]
			OPCIONES.FONDO_RGB_FIJO_ON = lista_config[3]
			CONTROL.ESTILO = estilo_lista
			definir_estilos()
			SISTEMAS.MEGADRIVE_ON = lista_config[8]
			if SISTEMAS.MEGADRIVE_ON == 0 then
				PRE_CARGADAS[1] = {}
			end
			SISTEMAS.MASTERSYSTEM_ON = lista_config[9]
			if SISTEMAS.MASTERSYSTEM_ON == 0 then
				PRE_CARGADAS[2] = {}
			end
			SISTEMAS.GAMEGEAR_ON = lista_config[10]
			if SISTEMAS.GAMEGEAR_ON == 0 then
				PRE_CARGADAS[3] = {}
			end
			SISTEMAS.FAMICOM_ON = lista_config[11]
			if SISTEMAS.FAMICOM_ON == 0 then
				PRE_CARGADAS[4] = {}
			end
			SISTEMAS.GAMEBOY_ON = lista_config[12]
			if SISTEMAS.GAMEBOY_ON == 0 then
				PRE_CARGADAS[5] = {}
			end
			SISTEMAS.GAMEBOYCOLOR_ON = lista_config[13]
			if SISTEMAS.GAMEBOYCOLOR_ON == 0 then
				PRE_CARGADAS[6] = {}
			end
			SISTEMAS.GAMEBOYADVANCE_ON = lista_config[14]
			if SISTEMAS.GAMEBOYADVANCE_ON == 0 then
				PRE_CARGADAS[7] = {}
			end
			SISTEMAS.ATARI2600_ON = lista_config[15]
			if SISTEMAS.ATARI2600_ON == 0 then
				PRE_CARGADAS[8] = {}
			end
			SISTEMAS.ATARILYNX_ON = lista_config[16]
			if SISTEMAS.ATARILYNX_ON == 0 then
				PRE_CARGADAS[9] = {}
			end
			SISTEMAS.SEGASG1000_ON = lista_config[17]
			if SISTEMAS.SEGASG1000_ON == 0 then
				PRE_CARGADAS[10] = {}
			end
			SISTEMAS.NEOGEOPOCKET_ON = lista_config[18]
			if SISTEMAS.NEOGEOPOCKET_ON == 0 then
				PRE_CARGADAS[11] = {}
			end
			SISTEMAS.SUPERFAMICOM_ON = lista_config[19]
			if SISTEMAS.SUPERFAMICOM_ON == 0 then
				PRE_CARGADAS[12] = {}
			end
			SISTEMAS.APPS_ON = lista_config[20]
			if SISTEMAS.APPS_ON == 0 then
				PRE_CARGADAS[13] = {}
			end
			SISTEMAS.PLAYSTATION_ON = lista_config[21]
			if SISTEMAS.PLAYSTATION_ON == 0 then
				PRE_CARGADAS[14] = {}
			end
			SISTEMAS.PLAYSTATION2_ON = lista_config[22]
			if SISTEMAS.PLAYSTATION2_ON == 0 then
				PRE_CARGADAS[15] = {}
			end
			OPCIONES.CAMBIO_FUENTE_ON = selec_fuente
			OPCIONES.FUENTES_ENCONTRADAS = {}
			OPCIONES.CAMBIO_FONDO_ON = selec_fondo
			OPCIONES.FONDO_ENCONTRADOS = {}
			OPCIONES.GUI_LIMPIA_ON = lista_config[25]
			OPCIONES.LIMITADOR_RAM_ON = lista_config[26]
			if doesFileExist(OPCIONES.SALIDA_RETROLANCHER) and string.lower(string.sub(OPCIONES.SALIDA_RETROLANCHER, -4)) == ".elf" then
				OPCIONES.SALIDA_RETROLANCHER_ON = selec_dir
				guardar_directorio_elf(false)
			else
				OPCIONES.SALIDA_RETROLANCHER_ON = 0
				OPCIONES.SALIDA_RETROLANCHER = "PS2 SYSTEM MENU"
				guardar_directorio_elf(false)
			end
			OPCIONES.APPS_MENU_FULL_PATH = lista_config[29]
			OPCIONES.SOUND_ON = lista_config[30]
			OPCIONES.SOUND_VOLUME = volume
			OPCIONES.SCREENSHOT_BACK_ON = lista_config[32]
			if OPCIONES.SCREENSHOT_BACK_ON == 0 then 
				OPCIONES.SCREENSHOT_BACK_TR = 128
			elseif OPCIONES.SCREENSHOT_BACK_ON == 1 then
				OPCIONES.SCREENSHOT_BACK_TR = prev_back_tras
			end
			OPCIONES.VIDEO_MODE = lista_config[33]
			OPCIONES.VIBRATION_ON = lista_config[34]
			OPCIONES.VIBRATION = false
			OPCIONES.VIBRATION_MODE = nil
			OPCIONES.DIR_EXTRAS_ON = lista_config[35]
			OPCIONES.SEE_INDEX = on_index
			-- Tambien por esta via: el interruptor se guarda tanto si se pulsa como si
			-- se confirma el menu entero. Su fichero propio es la unica fuente fiable.
			SEE_INDEX_GUARDAR(on_index)
			CAMBIOS_EMUS.TRAS = tras_demo
			if OPCIONES.VIDEO_MODE == 1 then
				CONTROL.ALTO_F = 512
				CONTROL.ALTO = 544
				CONTROL.Y_FIX_PAL = 32
			else
				CONTROL.ALTO_F = 448
				CONTROL.ALTO = 480
				CONTROL.Y_FIX_PAL = 0
			end
			CONTROL.LISTA_ALTO = CONTROL.LISTA_ALTO + CONTROL.Y_FIX_PAL
			CONTROL.IMG_ALTO = CONTROL.IMG_ALTO + CONTROL.Y_FIX_PAL
			CONTROL.LOGO_ALTO = CONTROL.LOGO_ALTO + CONTROL.Y_FIX_PAL
			CONTROL.IMG_ALTO_2 = CONTROL.IMG_ALTO_2 + CONTROL.Y_FIX_PAL
			CONTROL.FLOW_ALTO = CONTROL.FLOW_ALTO + CONTROL.Y_FIX_PAL
			CONTROL.FLOW_ALTO_2 = CONTROL.FLOW_ALTO_2 + CONTROL.Y_FIX_PAL
			CONTROL.SPRITE_ALTO = CONTROL.SPRITE_ALTO + CONTROL.Y_FIX_PAL
			if ini_sprite == 1 and CONTROL.ESTILO ~= 7 then
				CONTROL.CUSTOM_SPRITE = true
			end
			OPCIONES.SPRITE_ON = ini_sprite
			OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y, OPCIONES.FONT_SHADOW, OPCIONES.SCROLL_MIN = font_x, font_Y, font_shadow, font_scroll
			Font.ftSetPixelSize(CONTROL.fontARCA, OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y)
			Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
			OPCIONES.RUN_DEFAULT = menu_run
			COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4] = cc_back_1, cc_back_2, cc_back_3, cc_back_4
			desactivados(nil)
			guardar_opciones()
			cambio_realizado = false
			noob = false
		end

		-- Controlar el movimiento vertical por las opciones de configuración. ----------
		if (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_R2)) or (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_L2)) and CONTROL.JOYSTICK_ON == false then
			if Pads.check(PAD, PAD_R2) and conf_numero == true then
				selector = cambiar_valor(selector, 1, 22, 4, true)
			elseif Pads.check(PAD, PAD_R2) and conf_numero == false then
				selector = cambiar_valor(selector, 23, #lista_config, 4, true)
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and conf_numero == true then
				selector = cambiar_valor(selector, 1, 22, 1, true)
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and conf_numero == false then
				selector = cambiar_valor(selector, 23, #lista_config, 1, true)
			elseif Pads.check(PAD, PAD_L2) and conf_numero == true then
				selector = cambiar_valor(selector, 1, 22, 4, false)
			elseif Pads.check(PAD, PAD_L2) and conf_numero == false then
				selector = cambiar_valor(selector, 23, #lista_config, 4, false)
			elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and conf_numero == true then
				selector = cambiar_valor(selector, 1, 22, 1, false)
			elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and conf_numero == false then
				selector = cambiar_valor(selector, 23, #lista_config, 1, false)
			end

			-- vibración y cambio de velocidades. ---------------------------------------
			local shake_type = false
			if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
				shake_type = true
			end
			local kabal = 1 if Left_Y ~= 1 then
				kabal = 2
			end
			if kabal == 1 then
				repro_sfx(S_MOVER, 1, true, shake_type)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)
		end

		-- Controlar el movimiento horizontal por las opciones de configuración. --------
		if ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90)) and ((selector >= 4 and selector <= 24) or selector == 27 or selector == 31) and CONTROL.JOYSTICK_ON == false then
			-- Realizar cambios en el volumen. ------------------------------------------
			if (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 31 then
				volume = cambiar_valor(volume, 1, 100, 1, false)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 31 then
				volume = cambiar_valor(volume, 1, 100, 1, true)

			-- Cambia la fuente de texto.------------------------------------------------
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 23 then
				selec_fuente = cambiar_valor(selec_fuente, 1, #OPCIONES.FUENTES_ENCONTRADAS, 1, false)
				cambia_fuente()
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 23 then
				selec_fuente = cambiar_valor(selec_fuente, 1, #OPCIONES.FUENTES_ENCONTRADAS, 1, true)
				cambia_fuente()

			-- Cambia el fondo de pantalla.----------------------------------------------
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 24 then
				selec_fondo = cambiar_valor(selec_fondo, 1, #OPCIONES.FONDO_ENCONTRADOS, 1, false)
				buscar_fondos(true, selec_fondo)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 24 then
				selec_fondo = cambiar_valor(selec_fondo, 1, #OPCIONES.FONDO_ENCONTRADOS, 1, true)
				buscar_fondos(true, selec_fondo)

			-- Cambia la salida de RETROLauncher. ---------------------------------------
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 27 then
				selec_dir = cambiar_valor(selec_dir, 0, 3, 1, false)
				cambiar_medio()
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 27 then
				selec_dir = cambiar_valor(selec_dir, 0, 3, 1, true)
				cambiar_medio()

			-- Realizar cambios en los colores. -----------------------------------------
			elseif Pads.check(PAD, PAD_SQUARE) and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and lista_config[3] == 1 and selector >= 4 and selector <= 6 then
				tras_demo = cambiar_valor(tras_demo, 0, 120, 1, false)
			elseif Pads.check(PAD, PAD_SQUARE) and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and lista_config[3] == 1 and selector >= 4 and selector <= 6 then
				tras_demo = cambiar_valor(tras_demo, 0, 120, 1, true)
			elseif Pads.check(PAD, PAD_TRIANGLE) and (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and lista_config[3] == 1 and selector >= 4 and selector <= 6 then
				OPCIONES.COLOR_LISTA_B = cambiar_valor(OPCIONES.COLOR_LISTA_B, 50, 128, 1, false)
			elseif Pads.check(PAD, PAD_TRIANGLE) and (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and lista_config[3] == 1 and selector >= 4 and selector <= 6 then
				OPCIONES.COLOR_LISTA_B = cambiar_valor(OPCIONES.COLOR_LISTA_B, 50, 128, 1, true)
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 4 then
				OPCIONES.R = cambiar_valor(OPCIONES.R, 0, 128, 1, false)
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 5 then
				OPCIONES.G = cambiar_valor(OPCIONES.G, 11, 128, 1, false)
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 6 then
				OPCIONES.B = cambiar_valor(OPCIONES.B, 11, 128, 1, false)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 4 then
				OPCIONES.R = cambiar_valor(OPCIONES.R, 0, 128, 1, true)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 5 then
				OPCIONES.G = cambiar_valor(OPCIONES.G, 11, 128, 1, true)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 6 then
				OPCIONES.B = cambiar_valor(OPCIONES.B, 11, 128, 1, true)

			-- Realizar cambios de estilos. ---------------------------------------------
			elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector == 7 then
				estilo_lista = cambiar_valor(estilo_lista, 1, 7, 1, false)
			elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector == 7 then
				estilo_lista = cambiar_valor(estilo_lista, 1, 7, 1, true)

			-- Realizar salto lateral en sistemas. --------------------------------------
			elseif (selector >= 8 and selector <= 22) and (selector <= 14 and selector >= 8) then
				selector = selector+8
			elseif (selector >= 8 and selector <= 22) and (selector <= 22 and selector >= 16) then
				selector = selector-8
			elseif selector == 15 then
				selector = selector+7
			end

			-- Aplicar modificaciones / volumen / colores. ------------------------------
			if selector == 31 then
				OPCIONES.SOUND_VOLUME = volume
				set_volume()
			elseif selector >= 4 and selector <= 6 then
				if tras_demo == 0 then
					color_demo = Color.new(OPCIONES.R, OPCIONES.G, OPCIONES.B)
				else
					color_demo = Color.new(OPCIONES.R, OPCIONES.G, OPCIONES.B, tras_demo)
				end
				if lista_config[3] == 1 then
					color_emu(0, lista_config[2], lista_config[3])
				end
			end

			-- Vibración y cambio de velocidades. ---------------------------------------
			local shake_type = true
			if (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				shake_type = false
			end
			local kabal = 1 if Left_X ~= 1 and selector ~= 23 and selector ~= 24 then
				kabal = 2
			end
			if selector ~= 7 and selector ~= 23 and selector ~= 24 and kabal == 1 then
				repro_sfx(S_MOVER, 1, true, shake_type)
			elseif selector == 7 or selector == 23 or selector == 24 and kabal == 1 then
				repro_sfx(S_EJECUTAR, 1, true, shake_type)
			end
			JOYSTICK_LIMITE = control_FPS(kabal)
		end
		end

		-- Mostrar todo en pantalla. ----------------------------------------------------
		Screen.clear(CAMBIOS_EMUS.COLOR_EMU_BACK)
		m_dibujar_fondos()
		local ajuste_m = 5
		Graphics.drawRect(12, (28-ajuste_m)+CONTROL.Y_FIX_PAL, 615, 423, COLOR.NEGRO_T)

		-- Muestra y determina el estado de cada página. --------------------------------
		local page_long = calcular_sombras(page)
		Graphics.drawScaleImage(PAD_IMG.L1, (CONTROL.ANCHO//2)-104, (-1)+CONTROL.Y_FIX_PAL, 30, 26)
		Graphics.drawScaleImage(PAD_IMG.R1, (CONTROL.ANCHO//2)+74, (-1)+CONTROL.Y_FIX_PAL, 30, 26)
		Graphics.drawRect((CONTROL.ANCHO//2)-(page_long//2), 2+CONTROL.Y_FIX_PAL, page_long, 20, COLOR.NEGRO_T)
		Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), 3+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, page, COLOR.BLANCO_LISTA)
		local contador, ini = 1, 1
		if conf_numero == true then
			ini = 1
		else
			ini = 23
		end

		-- Controla el scroll. ----------------------------------------------------------
		if CONTROL.ESPERA_CARGA_SCR == false then
			LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, lista_texto_config[28], 44)
		end

		-- Muestra las opciones y su estado. --------------------------------------------
		for estado = ini, #lista_config do
			-- Define el estado. --------------------------------------------------------
			local text_especial = {TEXT_M_CON[54]; "MC0:", "MC1:"; local_disp; TEXT_M_CON[56]; TEXT_M_CON[57]; TEXT_M_CON[58]; TEXT_M_CON[59];
			TEXT_M_CON[60]; TEXT_M_CON[61]; TEXT_M_CON[62];};
			local acti = TEXT_GEN[13]
			if lista_config[estado] == 0 then
				acti = TEXT_GEN[14]
			end
			if estado == 7 and conf_numero == true then
				acti = text_especial[estilo_lista+4]
			elseif estado >= 8 and estado <= 22 and conf_numero == true then
				if lista_config[estado] == 0 then
					acti = TEXT_GEN[2]
				else
					acti = TEXT_GEN[3]
				end
			elseif estado == 27 and conf_numero == false then
				acti = text_especial[selec_dir+1]
			elseif estado == 33 and conf_numero == false then
				if lista_config[estado] == 0 then
					acti = "NTSC"
				else
					acti = "PAL"
				end
			end

			-- Muestra todas las opciones de la página y su estado. ---------------------
			local espacio_linea = ((8-ajuste_m)+(contador)*25)+CONTROL.Y_FIX_PAL
			if estado <= 7 or estado >= 23 then
				local color_mos = COLOR.BLANCO_LISTA
				if estado == selector then
					color_mos = CAMBIOS_EMUS.COLOR_EMU
					Graphics.drawRect(12+5, espacio_linea-3, 610-7, 25, COLOR.NEGRO_T)
				end
				if estado == 28 then
					Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 601, 8, "".. string.sub(lista_texto_config[estado], LISTAS.SCROLL_TEX), color_mos)
				else
					Font.ftPrint(CONTROL.fontARCA, 22, espacio_linea, 0, 0, 8, "".. lista_texto_config[estado], color_mos)
				end
				if estado >= 4 and estado <= 6 then
					Graphics.drawRect(558, (119-ajuste_m)+CONTROL.Y_FIX_PAL, 45, 45, color_demo)
					if estado == 4 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. OPCIONES.R, color_mos)
					elseif estado == 5 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. OPCIONES.G, color_mos)
					elseif estado == 6 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. OPCIONES.B, color_mos)
					end
				else
					if estado == 7 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. acti, color_mos)
					elseif estado == 23 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. selec_fuente, color_mos)
					elseif estado == 24 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. selec_fondo, color_mos)
					elseif estado == 27 or estado == 33 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. acti, color_mos)
					elseif estado == 31 then
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, "".. volume, color_mos)
					elseif estado == 28 or (estado >= 36 and estado <= 38) then
						Font.ftPrint(CONTROL.fontARCA, 16, espacio_linea, 0, 0, 8, "", color_mos)
					else
						Font.ftPrint(CONTROL.fontARCA, 498, espacio_linea, 0, 0, 8, acti, color_mos)
					end
				end
				if estado == selector and ((estado >= 4 and estado <= 7) or estado == 23 or (estado == 24 and SPRITES.FONDO_ANI == true) or estado == 26 or estado == 29 or estado == 30 or (estado == 32 and lista_config[32] == 1) or estado == 35) then
					local fix_sel = 0
					if estado == 7 and estilo_lista ~= 7 and ini_sprite == 1 then
						fix_sel = 40
					end
					Graphics.drawScaleImage(PAD_IMG.SELECT_S, 464-fix_sel, espacio_linea, 20, 20)
				end
			else
				Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO//2), (206-ajuste_m)+CONTROL.Y_FIX_PAL, 8, CONTROL.ANCHO, 25, "- ".. TEXT_M_CON[64] .." -", COLOR.BLANCO_LISTA)
				local color_mos = COLOR.BLANCO_LISTA
				local x_recta, y_recta_fix, x_name, x_act, x_img = 17, 21, 22, 261, 232
				if estado >= 16 then
					x_recta, y_recta_fix, x_name, x_act, x_img = 332, -179, 337, 576, 547
				end
				if estado == selector then
					color_mos = CAMBIOS_EMUS.COLOR_EMU
					Graphics.drawRect(x_recta, espacio_linea-3+(y_recta_fix), 293-7, 25, COLOR.NEGRO_T)
					Font.ftPrint(CONTROL.fontARCA, x_name, espacio_linea+(y_recta_fix), 0, 0, 8, "".. lista_texto_config[estado], CAMBIOS_EMUS.COLOR_EMU)
					Font.ftPrint(CONTROL.fontARCA, x_act, espacio_linea+(y_recta_fix), 0, 0, 8, "".. acti, CAMBIOS_EMUS.COLOR_EMU)
					Graphics.drawScaleImage(PAD_IMG.SELECT_S, x_img, espacio_linea+(y_recta_fix), 20, 20)
				else
					Font.ftPrint(CONTROL.fontARCA, x_name, espacio_linea+(y_recta_fix), 0, 0, 8, "".. lista_texto_config[estado], COLOR.BLANCO_LISTA)
					Font.ftPrint(CONTROL.fontARCA, x_act, espacio_linea+(y_recta_fix), 0, 0, 8, "".. acti, COLOR.BLANCO_LISTA)
				end
			end
			if estado == 7 and estilo_lista ~= 7 and ini_sprite == 1 and conf_numero == true then
				dibujar_sprites(LISTAS.IDENTIDAD, 454, (espacio_linea-20), 30, 40, 0.00, SPRITES.FLIP[1], SPRITES.FLIP[2], false)
			end
			contador = contador+1
		end

		-- Dibuja una pequeña muestra de los efectos en el cambio de colores. -----------
		if conf_numero == true then
			if lista_config[3] == 1 and tras_demo ~= 0 then
				Graphics.drawRect(199-2, (108-ajuste_m)-2+CONTROL.Y_FIX_PAL, 244+4, 70+4, COLOR.NEGRO_T)
				Graphics.drawScaleImage(LOGOS.DEFAULT_DEMO, 199, (108-ajuste_m)+CONTROL.Y_FIX_PAL, 244, 70)
				Graphics.drawRect(199, (108-ajuste_m)+CONTROL.Y_FIX_PAL, 244, 70, color_demo)
			else
				Graphics.drawScaleImage(LOGOS.DEFAULT_DEMO, 199, (108-ajuste_m)+CONTROL.Y_FIX_PAL, 244, 70, CAMBIOS_EMUS.COLOR_EMU)
			end
			if lista_config[3] == 1 and selector >= 4 and selector <= 6 then
				local color_mos, text_tras = COLOR.BLANCO_LISTA, (TEXT_M_CON[65] .." ".. tras_demo)
				if tras_demo == 0 then
					text_tras = TEXT_M_CON[66]
				end
				local PAD_indi, fix1, fix2 = Pads.get(0), 5, 5
				if Pads.check(PAD_indi, PAD_SQUARE) then
					fix1 = 10
				elseif Pads.check(PAD_indi, PAD_TRIANGLE) then
					fix2 = 10
				end
				Graphics.drawRect(12+5, (184-ajuste_m)-3+CONTROL.Y_FIX_PAL, 610-7, 25, COLOR.NEGRO)
				dibujar_indicador(126, 178, text_tras, PAD_IMG.SQUARE, 20, 20, fix1, false)
				dibujar_indicador(404, 178, TEXT_M_CON[114] .." ".. OPCIONES.COLOR_LISTA_B, PAD_IMG.TRIANGLE, 20, 20, fix2, false)
			end
		end
		dibujar_indicador(54, 425, TEXT_M_CON[23], PAD_IMG.START, 32, 32, 2, false)
		dibujar_indicador(412, 425, TEXT_GEN[8], PAD_IMG.CROSS, 20, 20, 5, false)
		dibujar_indicador(550, 425, TEXT_GEN[7], PAD_IMG.CIRCLE, 20, 20, 5, false)
		if cambio_ani == true then
			cambio_ani, n_ani = intro_menu(cambio_ani, n_ani)
			JOYSTICK_LIMITE = control_FPS(1)-18
		end
		refrescar(false)
	end
	if reinicio == false then
		animaciones(nil, false)
	elseif reinicio == true then
		reiniciar_conf(clean, indi_rest_RL)
		if indi_rest_RL ~= 0 and indi_rest_RL ~= 20 then
			animaciones(nil, false)
		end
	end
	JOYSTICK_LIMITE = control_FPS(1)-16
	limpiar_art()
	LISTAS.MOSTRAR = 0
end

--- Obtener el valor de un carácter. ----------------------------------------------------
function cha_res(character, limit)
	local resultado = 0
	local character_list = {"1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "a"; "b"; "c"; "d"; "e"; "f"; "g"; "h"; "i";
	"j"; "k"; "l"; "m"; "n"; "o"; "p"; "q"; "r"; "s"; "t"; "u"; "v"; "w"; "x"; "y"; "z"; "A"; "B"; "C"; "D"; "E"; "F";
	"G"; "H"; "I"; "J"; "K"; "L"; "M"; "N"; "O"; "P"; "Q"; "R"; "S"; "T"; "U"; "V"; "W"; "X"; "Y"; "Z"; "#";};
	if character ~= nil then
		if limit >= #character_list+1 then
			limit = #character_list
		end
		for decimal = 1, limit do
			if string.match(character, character_list[decimal]) then
				resultado = decimal
				break
			end
		end
	elseif character == nil then
		if limit ~= 0 then
			resultado = character_list[limit]
		end
	end
	return resultado
end

--- Dividir un texto por un carácter determinado. ---------------------------------------
function sub_string(texto, c_divisor, l_resultado, tipo)
	if tipo == true then
		for linea in string.gmatch(texto, c_divisor) do
			table.insert(l_resultado, tonumber(linea))
		end
	elseif tipo == false then
		for linea in string.gmatch(texto, c_divisor) do
			table.insert(l_resultado, tostring(linea))
		end
	end
	return l_resultado
end

--- Ordena las listas ignorando mayúsculas. ---------------------------------------------
function orden_alfabetico(a, b)
	return a:lower() < b:lower()
end

--- Ordena las listas para PS1 y PS2. ---------------------------------------------------
function orden_alfabetico_PS(a, b)
	local consiA, consiB = false, false
	if string.match(a, "%a+_%d+%.%d+%.") then
		consiA = true
	end
	if string.match(b, "%a+_%d+%.%d+%.") then
		consiB = true
	end
	if consiA == true and consiB == true then
		return string.lower(a:sub(13)) < string.lower(b:sub(13))
	elseif consiA == true and consiB == false then
		return string.lower(a:sub(13)) < b:lower()
	elseif consiA == false and consiB == true then
		return a:lower() < string.lower(b:sub(13))
	else
		return a:lower() < b:lower()
	end
end

--- Crea las listas de juegos y aplicaciones para cada sistema. -------------------------
function crear_listas(identidad, lista)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local encontrados = {}
	-- Reconstruir una lista es el unico momento en que el contenido de las carpetas
	-- de medios ha podido cambiar: se olvida el indice y se vuelve a construir solo.
	media_indice_olvidar()

	-- Búsquedas para cores de RetroArch. -----------------------------------------------
	if identidad <= 12 then
		-- Lista de sistemas. -----------------------------------------------------------
		local dir_sistemas = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear"; "Nintendo Famicom"; "Nintendo Game Boy";
		"Nintendo Game Boy Color"; "Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "Neo Geo Pocket"; "Nintendo Super Famicom";};

		-- Lista de extensiones. --------------------------------------------------------
		local name_exten = {{".zip", ".bin", ".gen", ".smd", ".md"}; {".zip", ".sms"}; {".zip", ".gg"};
		{".zip", ".nes", ".fds", ".unf"}; {".zip", ".gb"}; {".zip", ".gbc"}; {".gba", ".bin"}; {".zip", ".a26", ".bin"};
		{".zip", ".lnx", ".lyx"}; {".zip", ".sg"}; {".zip", ".ngc", ".ngp", ".npc"}; {".zip", ".sfc", ".smc"};};
		local exten = name_exten[identidad]
		local exten_mini = true
		local temp_ext2 = ""
		if identidad ~= 1 and identidad ~= 3 and identidad ~= 5 and identidad ~= 10 then
			exten_mini = false
		end

		-- Realizar búsquedas. ----------------------------------------------------------
		-- Busqueda acumulada. Ademas de la estructura propia de RETROLauncher
		-- ("Roms/Roms <sistema>"), se aceptan los nombres al estilo EmulationStation
		-- / Batocera ("roms/snes", "roms/nes"...), tanto dentro de la carpeta del
		-- launcher como en la raiz de cada unidad.
		local dirs = {}
		for i_raiz = 1, #RAICES do
			table.insert(dirs, RAICES[i_raiz] .."/Roms/".. ROMS_DIR[identidad])
		end
		if ES_ALIAS ~= nil and ES_ALIAS[identidad] ~= nil then
			local unidades = {}
			local pos_u = string.find(actual, ":", 1, true)
			if pos_u ~= nil then table.insert(unidades, string.sub(actual, 1, pos_u)) end
			if BDM_DEVICES ~= nil then
				for i_u = 1, #BDM_DEVICES do table.insert(unidades, BDM_DEVICES[i_u]) end
			end
			-- Carpetas contenedoras aceptadas. "Games" es la que usa este fork,
			-- "roms" la de Batocera / Recalbox en la raiz de la unidad.
			local contenedores = {"Games", "roms", "Roms"}
			for a_i = 1, #ES_ALIAS[identidad] do
				local alias = ES_ALIAS[identidad][a_i]
				for c_i = 1, #contenedores do
					for i_raiz = 1, #RAICES do
						table.insert(dirs, RAICES[i_raiz] .."/".. contenedores[c_i] .."/".. alias)
					end
					for i_u = 1, #unidades do
						table.insert(dirs, unidades[i_u] .."/".. contenedores[c_i] .."/".. alias)
					end
				end
			end

			-- "Games/Roms <sistema>": misma carpeta contenedora, nombre largo.
			for i_raiz = 1, #RAICES do
				table.insert(dirs, RAICES[i_raiz] .."/Games/".. ROMS_DIR[identidad])
			end
		end

		local vistos = {}
		-- De donde sale cada juego. Un sistema puede tener ROMs en el disco Y en la
		-- llave, y "scanning snes" a secas no lo distinguia. Pero "dirs" tiene una
		-- treintena de entradas por sistema -- cada alias, cada contenedor, cada
		-- unidad -- y anunciarlas una por una daba quinientas lineas de journal por
		-- arranque, cada una reescribiendo el fichero entero y repintando la pantalla
		-- dos veces. De ahi el arranque interminable. Se anuncia UNA vez por fuente.
		local dicho = {}
		for i_dir = 1, #dirs do
			local fuente = "USB"
			if ES_RAIZ_ATA(dirs[i_dir]) then fuente = "ATA" end
			if dicho[fuente] == nil then
				dicho[fuente] = true
				-- La consola delante y el soporte detras: "SNES - Exfat". Se lee la
				-- columna entera de un vistazo, que es lo que no pasaba con
				-- "ATA scan snes" -- todas las lineas empezaban igual.
				local sistema = string.upper(tostring(ROMS_DIR[identidad]))
				if fuente == "ATA" then
					CARGA_PASO(sistema .." - Exfat", "exfat")
				else
					CARGA_PASO(sistema .." - USB", "usb")
				end
			end
			local buscar = System.listDirectory(dirs[i_dir])
			if buscar ~= nil then
				cargar_titulos(dirs[i_dir], identidad)
				-- Los titulos de los juegos del disco exFAT se escriben en la carpeta
				-- canonica del USB, porque el PC no siempre tiene acceso al disco.
				if MEDIA_ALIAS[identidad] ~= nil then
					for i_r = 1, #RAICES do
						cargar_titulos(RAICES[i_r] .."/Roms/".. MEDIA_ALIAS[identidad], identidad)
					end
				end
				local db_juegos = {}
				for contador = 1, #buscar do
					if buscar[contador].directory == false then
						local temp_ext = string.lower(string.sub(buscar[contador].name, -4))
						if exten_mini == true then
							temp_ext2 = string.lower(string.sub(buscar[contador].name, -3))
						end
						for test = 1, #exten do
							local nom = nil
							if temp_ext == exten[test] then
								nom = buscar[contador].name
							elseif exten_mini == true and temp_ext2 == exten[test] then
								nom = buscar[contador].name .." "
							end
							if nom ~= nil and vistos[nom] == nil then
								vistos[nom] = true
								table.insert(encontrados, nom)
								ORIGEN[tostring(identidad) .."|".. nom] = dirs[i_dir]
								ORIGEN_DIR[tostring(identidad) .."|".. nom] = dirs[i_dir] .."/"
								table.insert(db_juegos, {fichero = nom,
									titulo = NOMBRE_VISIBLE(identidad, nom)})
							end
						end
					end
				end
				exfatdb_dir(identidad, dir_sistemas[identidad], dirs[i_dir], db_juegos)
			end
		end
		exfatdb_escribir()
		if encontrados ~= nil and #encontrados >= 1 then
			lista = encontrados
			table.sort(lista, orden_alfabetico)
			return lista
		else
			lista = {}
			return lista
		end

	-- Búsquedas para APPS. -------------------------------------------------------------
	elseif identidad == 13 then
		-- Lista de directorios. --------------------------------------------------------
		local buscar_directorio = {device .."/APPS", "mc0:/APPS", "mc1:/APPS", actual .."/Roms/APPS", "cdfs:", "mc0:", "mc1:", device}
		if BUSCAR_CDVD == false then buscar_directorio[5] = nil end
		-- Los indices 6, 7 y 8 son las RAICES de mc0:, mc1: y del disco, y de cada una
		-- se entra un nivel en toda carpeta que haya. Ver APPS_RAIZ_ON en system.lua.
		if APPS_RAIZ_ON ~= true then
			buscar_directorio[6] = nil
			buscar_directorio[7] = nil
			buscar_directorio[8] = nil
		end
		if OPCIONES.DIR_EXTRAS_ON == 0 then
			buscar_directorio[1] = nil
			buscar_directorio[2] = nil
			buscar_directorio[3] = nil
			buscar_directorio[6] = nil
			buscar_directorio[7] = nil
			buscar_directorio[8] = nil
		end

		-- Realizar búsqueda. -----------------------------------------------------------
		lista = {}
		LISTAS.DIR_FULL_APP = {}
		-- "#" sobre una tabla con agujeros -- y aqui se ponen a nil varios indices -- no
		-- esta definido en Lua: puede devolver 4 y saltarse el resto. Se recorre a 8.
		for buscar_apps = 1, 8 do
			if buscar_directorio[buscar_apps] ~= nil then
				CARGA_PASO("APPS: listing ".. buscar_directorio[buscar_apps])
				local buscar = System.listDirectory(buscar_directorio[buscar_apps])
				if buscar ~= nil then
					CARGA_PASO("APPS: listing ".. buscar_directorio[buscar_apps]
					           .."  ".. tostring(#buscar) .." entries")
					for contador = 1, #buscar do
						local recursiva = nil
						if buscar[contador].directory == false and (string.lower(string.sub(buscar[contador].name, -4)) == ".elf" or (buscar_apps == 5 and string.match(buscar[contador].name, "%a+_%d+.%d+") == buscar[contador].name)) then
							if buscar_apps == 5 and string.match(buscar[contador].name, "%a+_%d+.%d+") == buscar[contador].name then
								table.insert(encontrados, obtener_nombre_DVD(buscar[contador].name, false))
								table.insert(LISTAS.DIR_FULL_APP, buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							else
								table.insert(encontrados, buscar[contador].name)
								table.insert(LISTAS.DIR_FULL_APP, buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							end
						elseif buscar[contador].directory == true then
							if (buscar_apps == 1 or buscar_apps == 4) and (string.lower(buscar[contador].name) ~= "retrolauncher") then
								recursiva = System.listDirectory(buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							elseif (buscar_apps == 2 or buscar_apps == 3) and (string.sub(buscar[contador].name, -1) ~= "."
								and string.sub(buscar[contador].name, -2) ~= ".." and string.lower(buscar[contador].name) ~= "retrolauncher") then
								recursiva = System.listDirectory(buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							elseif (buscar_apps == 6 or buscar_apps == 7) and (string.match(buscar[contador].name, ".+_.+")
								and string.sub(buscar[contador].name, -1) ~= "." and string.sub(buscar[contador].name, -2) ~= ".." ) then
								recursiva = System.listDirectory(buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							elseif buscar_apps == 8 and string.lower(buscar[contador].name) ~= "retrolauncher"
								and string.lower(buscar[contador].name) ~= "sys-conf" and string.lower(buscar[contador].name) ~= "boot"
									and string.lower(buscar[contador].name) ~= "pops" and string.lower(buscar[contador].name) ~= "apps" then
								recursiva = System.listDirectory(buscar_directorio[buscar_apps] .."/".. buscar[contador].name)
							end
						end
						if recursiva ~= nil then
							CARGA_PASO("APPS:   into ".. buscar[contador].name
							           .."  ".. tostring(#recursiva) .." entries")
							for contador2 = 1, #recursiva do
								if recursiva[contador2].directory == false and string.lower(string.sub(recursiva[contador2].name, -4)) == ".elf" and string.lower(string.sub(recursiva[contador2].name, 1, 3)) ~= "xx." and string.lower(string.sub(recursiva[contador2].name, 1, 3)) ~= "sb." then
									if doesFileExist(buscar_directorio[buscar_apps] .."/".. buscar[contador].name .."/title.cfg") then
										table.insert(encontrados, obtener_nombre_SAS(buscar_directorio[buscar_apps] .."/".. buscar[contador].name .."/title.cfg", recursiva[contador2].name))
									else
										table.insert(encontrados, recursiva[contador2].name)
									end
									table.insert(LISTAS.DIR_FULL_APP, buscar_directorio[buscar_apps] .."/".. buscar[contador].name .."/".. recursiva[contador2].name)
								end
							end
						end
					end
				end
			end
		end
		if encontrados ~= nil and #encontrados >= 1 then
			if OPCIONES.APPS_MENU_FULL_PATH == 1 then
				lista = LISTAS.DIR_FULL_APP
			else
				lista = encontrados
			end
			return lista
		else
			lista = {}
			LISTAS.DIR_FULL_APP = {}
			return lista
		end

	-- Búsquedas para PlayStation 1. ----------------------------------------------------
	elseif identidad == 14 then
		-- Realizar búsqueda. -----------------------------------------------------------
		-- "POPS/" en la raiz de CADA unidad, no solo en POPS_RAIZ: puede haber juegos
		-- en el POPS de la llave y en el del disco interno a la vez.
		local vistos_vcd = {}
		local unidades_pops = POPS_UNIDADES()
		for i_u = 1, #unidades_pops do
			local buscar = System.listDirectory(unidades_pops[i_u] .."/POPS")
			if buscar ~= nil then
				local db_pops = {}
				for contador = 1, #buscar do
					local nom = buscar[contador].name
					local ps1_name = string.lower(string.sub(nom, -4))
					if buscar[contador].directory == false and ps1_name == ".vcd"
					   and vistos_vcd[string.lower(nom)] == nil then
						vistos_vcd[string.lower(nom)] = true
						table.insert(encontrados, nom)
						ORIGEN["14|".. nom] = unidades_pops[i_u]
						table.insert(db_pops, {fichero = nom,
							titulo = NOMBRE_VISIBLE(14, nom)})
					elseif ps1_name == ".elf" and string.lower(string.sub(nom, 1, 3)) ~= "xx." and string.lower(nom) ~= "popstarter.elf" and string.lower(nom) ~= "pops.elf" and string.lower(nom) ~= "popstarter.kelf"
					   and vistos_vcd[string.lower(nom)] == nil then
						vistos_vcd[string.lower(nom)] = true
						table.insert(encontrados, nom)
						ORIGEN["14|".. nom] = unidades_pops[i_u]
					end
				end
				exfatdb_dir(14, "PlayStation", unidades_pops[i_u] .."/POPS", db_pops,
					"POPS")
			end
		end
		-- Segunda biblioteca de .VCD: "<raiz>/Roms/psx-pops(vcd)". Los de "POPS/" tienen
		-- prioridad. Al lanzarlos se trasladan a "POPS/", que es donde POPStarter los
		-- busca y donde crea la tarjeta de memoria del juego.
		for i_raiz = 1, #RAICES do
			local buscar_vcd = System.listDirectory(RAICES[i_raiz] .. POPS_SUB)
			if buscar_vcd ~= nil then
				local db_vcd = {}
				for contador = 1, #buscar_vcd do
					local nom = buscar_vcd[contador].name
					if buscar_vcd[contador].directory == false
					   and string.lower(string.sub(nom, -4)) == ".vcd"
					   and vistos_vcd[string.lower(nom)] == nil then
						vistos_vcd[string.lower(nom)] = true
						table.insert(encontrados, nom)
						ORIGEN["14|".. nom] = RAICES[i_raiz]
						table.insert(db_vcd, {fichero = nom,
							titulo = NOMBRE_VISIBLE(14, nom)})
					end
				end
				exfatdb_dir(14, "PlayStation", RAICES[i_raiz] .. POPS_SUB, db_vcd,
					"psx-pops(vcd)")
			end
		end
		-- Scan Ember: independiente de POPS y sobre TODAS las raices. -----------------
		local vistos_ps1 = {}
		for i_raiz = 1, #RAICES do
			local sub = "/Roms/psx-ember(bin and cue)"
			local buscar2 = System.listDirectory(RAICES[i_raiz] .. sub)
			if buscar2 ~= nil and doesFileExist(RUTA_BIOS("psx-ember.elf", RAICES[i_raiz] .. sub .."/ember.elf")) then
				local db_ps1 = {}
				for contador = 1, #buscar2 do
					local ps1_name = string.lower(string.sub(buscar2[contador].name, -4))
					if buscar2[contador].directory == false and ps1_name == ".cue"
					   and vistos_ps1[buscar2[contador].name] == nil then
						vistos_ps1[buscar2[contador].name] = true
						table.insert(encontrados, buscar2[contador].name)
						ORIGEN["14|".. buscar2[contador].name] = RAICES[i_raiz]
						table.insert(db_ps1, {fichero = buscar2[contador].name,
							titulo = NOMBRE_VISIBLE(14, buscar2[contador].name)})
					end
				end
				exfatdb_dir(14, "PlayStation", RAICES[i_raiz] .. sub, db_ps1,
					"psx-ember(bin and cue)")
			end
		end
		-- Titulos reales de PS1: los dos formatos comparten la lista, asi que se leen
		-- los "titles.txt" de las dos carpetas y en todas las raices.
		for i_raiz = 1, #RAICES do
			cargar_titulos(RAICES[i_raiz] .."/Roms/psx-ember(bin and cue)", 14)
			cargar_titulos(RAICES[i_raiz] .. POPS_SUB, 14)
		end
		exfatdb_escribir()
		if encontrados ~= nil and #encontrados >= 1 then
			lista = encontrados
			table.sort(lista, orden_alfabetico_PS)
			return lista
		else
			lista = {}
			return lista
		end

	-- Búsquedas para PlayStation 2. ----------------------------------------------------
	elseif identidad == 15 then
		-- Lista de directorios. --------------------------------------------------------
		-- Raices adicionales (disco interno exFAT), antes del bucle principal. --------
		local vistos_ps2 = {}
		-- Directorios extra a explorar: "<raiz>/Roms/ISOs PlayStation 2" y, en las
		-- unidades ATA, tambien "<unidad>/DVD" y "<unidad>/CD" como en el USB.
		local dirs_extra = {}
		for i_raiz = 2, #RAICES do
			table.insert(dirs_extra, RAICES[i_raiz] .."/Roms/ps2-isos/")
		end
		if OPCIONES.DIR_EXTRAS_ON ~= 0 then
			for i_u = 1, #BDM_DEVICES do
				if BDM_ATA[BDM_DEVICES[i_u]] == true then
					table.insert(dirs_extra, BDM_DEVICES[i_u] .."/DVD/")
					table.insert(dirs_extra, BDM_DEVICES[i_u] .."/CD/")
				end
			end
		end

		for i_d = 1, #dirs_extra do
			local extra = System.listDirectory(dirs_extra[i_d])
			if extra ~= nil then
				local db_ps2 = {}
				for c = 1, #extra do
					local e = string.lower(string.sub(extra[c].name, -4))
					if extra[c].directory == false and (e == ".iso" or e == ".hdd" or e == ".mx4" or e == ".mmc" or e == ".udp")
					   and vistos_ps2[extra[c].name] == nil then
						vistos_ps2[extra[c].name] = true
						table.insert(encontrados, extra[c].name)
						ORIGEN["15|".. extra[c].name] = dirs_extra[i_d]
						ORIGEN_DIR["15|".. extra[c].name] = dirs_extra[i_d]
						table.insert(db_ps2, {fichero = extra[c].name,
							titulo = NOMBRE_VISIBLE(15, extra[c].name)})
					end
				end
				exfatdb_dir(15, "PlayStation 2", dirs_extra[i_d], db_ps2, "ps2-isos")
			end
		end

		local buscar_directorio = {actual .."/Roms/ps2-isos", device .."/DVD", device .."/CD", "cdfs:"}
		if BUSCAR_CDVD == false then buscar_directorio[4] = nil end
		if OPCIONES.DIR_EXTRAS_ON == 0 then
			buscar_directorio[2] = nil
			buscar_directorio[3] = nil
		end

		-- Realizar búsqueda. -----------------------------------------------------------
		for buscar_ps2 = 1, #buscar_directorio do
			if buscar_directorio[buscar_ps2] ~= nil then
				local buscar = System.listDirectory(buscar_directorio[buscar_ps2])
				if buscar ~= nil then
					local db_ps2b = {}
					for contador = 1, #buscar do
						local ps2_name = string.lower(string.sub(buscar[contador].name, -4))
						if buscar[contador].directory == false and (buscar_ps2 ~= 4 and ps2_name == ".iso") or ((buscar_ps2 == 2 or buscar_ps2 == 3) and ps2_name == ".mx4" or ps2_name == ".hdd" or ps2_name == ".mmc" or ps2_name == ".udp") or (buscar_ps2 == 4 and string.match(buscar[contador].name, "%a+_%d+.%d+") == buscar[contador].name) then
							if buscar_ps2 == 4 then
								table.insert(encontrados, buscar[contador].name ..".".. obtener_nombre_DVD(buscar[contador].name, true))
							else
								if vistos_ps2[buscar[contador].name] == nil then
									vistos_ps2[buscar[contador].name] = true
									table.insert(encontrados, buscar[contador].name)
									ORIGEN_DIR["15|".. buscar[contador].name] = buscar_directorio[buscar_ps2] .."/"
									-- ES_ATA lee ORIGEN, no ORIGEN_DIR: sin esta linea un
									-- ISO del disco interno no llevaba su etiqueta [ATA] en
									-- la lista, y el journal escribia "desde disco interno
									-- (ATA) : false" para un juego que si venia de ahi.
									ORIGEN["15|".. buscar[contador].name] = buscar_directorio[buscar_ps2]
									table.insert(db_ps2b, {fichero = buscar[contador].name,
										titulo = NOMBRE_VISIBLE(15, buscar[contador].name)})
								end
							end
						end
					end
					exfatdb_dir(15, "PlayStation 2", buscar_directorio[buscar_ps2], db_ps2b, "ps2-isos")
				end
			end
		end
		exfatdb_escribir()
		if encontrados ~= nil and #encontrados >= 1 then
			lista = encontrados
			table.sort(lista, orden_alfabetico_PS)
			return lista
		else
			lista = {}
			return lista
		end
	else
		lista = {}
		return lista
	end
end

--- Obtener parámetros para lanzar juegos con OPL. --------------------------------------
function id_opl(directorio_iso, game_name, n_load)
	local id_name = nil
	if string.match(game_name, "%a+_%d+%.%d+%.") then
		id_name = string.upper(string.sub(game_name, 1, 11))
	elseif string.lower(string.sub(game_name, -4)) == ".iso" then
		if n_load == true then
			submenu_selector({}, nil, TEXT_M_CON[46], 160, 247, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
		end
		local iso_r = System.openFile(directorio_iso .. game_name, FREAD)
		System.seekFile(iso_r, 0, SET)
		local temp_dir_r = System.readFile(iso_r, 1500000)
		System.closeFile(iso_r)
		local start_n, end_n = string.find(temp_dir_r, "%a%a%a%a_%d%d%d%.%d%d")
		if start_n ~= nil then
			id_name = string.upper(string.sub(temp_dir_r, start_n, end_n))
		end
	end
	local nombre_iso = string.sub(game_name, 1, -4) .."iso"
	return nombre_iso, id_name
end

--- Mostrar selector de aplicaciones alternativas. --------------------------------------
function alt_run(identidad)
	local actual = System.currentDirectory()
	local default_text = {"PicoDrive/RetroArch v1.19.1"; " "; " "; "FCEultra/RetroArch v1.19.1"; "Gambatte/RetroArch v1.20.0"; "Gambatte/RetroArch v1.20.0";
	"gpSP/RetroArch v1.20.0"; " "; " "; " "; " "; "Snes9x 2002/RetroArch v1.20.0"; "wLaunchELF ISR v4.43x"; " "; "Neutrino v1.8.0-55-g7f85091";};
	local alt_text = {"PicoDrive/RetroArch v1.15.0"; " "; " "; "QuickNES/RetroArch v1.21.0"; "TGB Dual/RetroArch v1.19.1"; "TGB Dual/RetroArch v1.19.1";
	" "; " "; " "; " "; " "; " "; "Enceladus"; " "; "OPL";};
	local run, selec_alt, pregunta = nil, 1, true
	JOYSTICK_LIMITE = control_FPS(1)-20
	if (identidad == 15 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".iso") then
		run, pregunta = false, false
	end
	while pregunta do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()
		if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
			Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
		end
		local lista_resp = {TEXT_M_PRI[12], TEXT_GEN[4]}
		local submenu_lista = {default_text[identidad], alt_text[identidad]}
		if identidad == 15 and selec_alt == 1 and Pads.check(PAD, PAD_CIRCLE) then
			submenu_lista[1] = submenu_lista[1] .." ".. TEXT_M_CON[55]
		end
		submenu_selector(submenu_lista, selec_alt, TEXT_M_CON[67], 160, 247, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
		if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			if selec_alt == 2 then
				run = true
			else
				run = false
			end
			JOYSTICK_LIMITE = control_FPS(1)
			pregunta = false
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				selec_alt = cambiar_valor(selec_alt, 1, 2, 1, false)
			elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
				selec_alt = cambiar_valor(selec_alt, 1, 2, 1, true)
			end
			JOYSTICK_LIMITE = control_FPS(1)
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			JOYSTICK_LIMITE = control_FPS(1)-10
			run = nil
			pregunta = false
		end
		refrescar(false)
	end

	-- Buscar y seleccionar versiones de OPL. -------------------------------------------
	if run == true and identidad == 15 then
		local encontrados, externo = {}, false
		if not string.match(string.lower(OPCIONES.OPL_ELF), "/opl/") and doesFileExist(OPCIONES.OPL_ELF) then
			table.insert(encontrados, salida_texto_dir(OPCIONES.OPL_ELF, true) .." ".. TEXT_M_CON[69])
			externo = true
		end
		local buscar_versiones_opl = System.listDirectory(actual .."/OPL")
		if buscar_versiones_opl ~= nil then
			for contador = 1, #buscar_versiones_opl do
				if buscar_versiones_opl[contador].directory == false and string.lower(string.sub(buscar_versiones_opl[contador].name, -4)) == ".elf" then
					table.insert(encontrados, buscar_versiones_opl[contador].name)
				end
			end
		end
		local selec_opl = 1
		if (#encontrados >= 2) or (externo == false and #encontrados == 1 and not string.match(string.lower(encontrados[1]), "opnps2ld%.elf")) then
			local pregunta = true
			JOYSTICK_LIMITE = control_FPS(1)-20
			while pregunta do
				CONTROL.FPS = Screen.getFPS(1)
				capturar(JOYSTICK_LIMITE)
				dibujar_fondos()
				if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
					Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
				end
				local lista_resp = {TEXT_M_PRI[12], TEXT_GEN[4]}
				local submenu_lista = {encontrados[selec_opl]}
				submenu_selector(submenu_lista, nil, TEXT_M_CON[68], 160, 223, true, CONTROL.ANCHO//2, lista_resp, true, false, {}, nil)
				refrescar(false)
				if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
					repro_sfx(S_EJECUTAR, 1, false, nil)
					if (selec_opl ~= 1 and externo == true) or externo == false then
						OPCIONES.OPL_ELF = actual .."/OPL/".. encontrados[selec_opl]
					end
					pregunta = false
				elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
					repro_sfx(S_MOVER, 1, false, nil)
					if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
						selec_opl = cambiar_valor(selec_opl, 1, #encontrados, 1, false)
					elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
						selec_opl = cambiar_valor(selec_opl, 1, #encontrados, 1, true)
					end
					JOYSTICK_LIMITE = control_FPS(1)
				elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
					repro_sfx(S_CANCELAR, 1, false, nil)
					JOYSTICK_LIMITE = control_FPS(1)-10
					run = nil
					pregunta = false
				end
			end
		elseif #encontrados == 1 and string.match(string.lower(encontrados[1]), "opnps2ld%.elf") and externo == false then
			OPCIONES.OPL_ELF = actual .."/OPL/".. encontrados[1]
		end
	end
	return run
end

--- Verifica los juegos y aplicaciones necesarias para cada sistema. --------------------
function existe(identidad, nombre_juego, alternativo)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)

	-- Comprobar la existencia de archivos necesarios. ----------------------------------
	if identidad <= 12 and alternativo ~= nil then
		ERROR_DETALLE = nil
		-- Lista de sistemas. -----------------------------------------------------------
		local dir_sistemas = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear"; "Nintendo Famicom"; "Nintendo Game Boy"; "Nintendo Game Boy Color";
		"Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "Neo Geo Pocket"; "Nintendo Super Famicom";};

		-- Lista de aplicaciones. -------------------------------------------------------
		local name_cores = {"picodrive_libretro_ps2.elf"; "picodrive_libretro_ps2.elf"; "picodrive_libretro_ps2.elf"; "fceumm_libretro_ps2.elf";
		"gambatte_libretro_ps2.elf"; "gambatte_libretro_ps2.elf"; "gpsp_libretro_ps2.elf"; "stella2014_libretro_ps2.elf"; "handy_libretro_ps2.elf";
		"picodrive_libretro_ps2.elf"; "race_libretro_ps2.elf"; "snes9x2002_libretro_ps2.elf";};

		-- Lista de aplicaciones alternativas. ------------------------------------------
		local name_cores_alt = {"picodrive_libretro_ps2_alt.elf"; " "; " "; "quicknes_libretro_ps2.elf"; "tgbdual_libretro_ps2.elf";
		"tgbdual_libretro_ps2.elf"; " "; " "; " "; " "; " "; " ";};

		-- Todos los cores estan ya en "LibretroPS2Files/cores": RUTA_CORE los resuelve
		-- sobre cualquier raiz, asi que basta con darle el nombre del fichero. Antes
		-- habia aqui un "directorio especial" por sistema, para TempGBA y SNESticle,
		-- que no eran cores libretro sino ELF autonomos. Ya no estan.
		-- La ROM tiene que estar. Eso no se discute.
		if doesFileExist(RUTA_ROM(identidad, dir_sistemas[identidad], nombre_juego)) == false then
			ERROR_DETALLE = "ROM not found"
			return false
		end
		-- Y tiene que haber AL MENOS UN core que sirva para este sistema en la
		-- instalacion maestra. Aqui se exigia un core concreto, el de la tabla de mas
		-- arriba, y se le buscaba ademas en la instalacion de la llave -- que solo
		-- lleva el core del ultimo juego lanzado. Con lo cual el disco podia tener los
		-- sesenta cores y la respuesta seguia siendo "Games or RetroArch not found".
		-- Si el core previsto no esta pero hay otro que declara la extension, ese vale:
		-- es exactamente lo que elegir_core hara dos lineas despues.
		local defecto = name_cores[identidad]
		if alternativo == true then defecto = name_cores_alt[identidad] end
		local rutas = CORES_DEL_SISTEMA(identidad, RUTA_CORE_MAESTRO(defecto, defecto))
		if #rutas >= 1 then return true end
		ERROR_DETALLE = "No core for ".. dir_sistemas[identidad]
		return false

	-- Comprobar la existencia de archivos necesarios (APPS). ---------------------------
	elseif identidad == 13 and alternativo ~= nil then
		if doesFileExist(LISTAS.DIR_FULL_APP[LISTAS.INDICE]) and RUTA_WLE(false) ~= nil and alternativo == false then
			return true
		elseif doesFileExist(LISTAS.DIR_FULL_APP[LISTAS.INDICE]) then
			return true
		else
			return false
		end

	-- Comprobar la existencia de archivos necesarios (PlayStation 1). ------------------
	elseif identidad == 14 and alternativo ~= nil then
		local exten = string.lower(string.sub(nombre_juego, -4))
		if exten == ".elf" then
			return true
		-- La guia oficial de POPStarter es tajante: en modo USB el emulador es UN
		-- solo fichero, "POPS_IOX.PAK". "IOPRP252.IMG" pertenece al modo HDD, y
		-- exigirlo rechazaba montajes USB perfectamente validos.
		elseif exten == ".vcd" and RUTA_VCD(nombre_juego) ~= nil and doesFileExist(POPS_DE(nombre_juego) .."/POPS/POPS_IOX.PAK") then
			return true
		elseif exten == ".cue" and doesFileExist(RUTA("/Roms/psx-ember(bin and cue)/".. nombre_juego))
		and doesFileExist(RUTA_BIOS("psx-ember.elf", ""))
		and doesFileExist(RUTA_BIOS("bios.bin", "")) then
			return true
		else
			-- Detalle del fallo: que falta exactamente y donde se esperaba. -----------
			local faltan = {}
			if exten == ".vcd" then
				local base = POPS_DE(nombre_juego) .."/POPS/"
				local req = {"POPS_IOX.PAK"}
				-- El .VCD vale tanto en "POPS/" como en la biblioteca "psx-pops(vcd)".
				if RUTA_VCD(nombre_juego) == nil then table.insert(req, 1, nombre_juego) end
				for i = 1, #req do
					if doesFileExist(base .. req[i]) == false then
						table.insert(faltan, req[i])
					end
				end
				ERROR_DETALLE = detalle_falta("POPS", base, faltan)
			elseif exten == ".cue" then
				local base = RAIZ("/Roms/psx-ember(bin and cue)/".. nombre_juego) .."/Roms/psx-ember(bin and cue)/"
				if doesFileExist(base .. nombre_juego) == false then
					table.insert(faltan, nombre_juego)
				end
				-- Ember y su bios viven en "Bios/", no junto a la ROM: si faltan hay
				-- que decirlo, antes se mostraba un error mudo.
				if doesFileExist(RUTA_BIOS("psx-ember.elf", "")) == false then
					table.insert(faltan, "Bios/psx-ember.elf")
				end
				if doesFileExist(RUTA_BIOS("bios.bin", "")) == false then
					table.insert(faltan, "Bios/bios.bin")
				end
				ERROR_DETALLE = detalle_falta("Ember", base, faltan)
			end
			return false
		end

	-- Comprobar la existencia de archivos necesarios (PlayStation 2). ------------------
	elseif identidad == 15 and alternativo ~= nil then
		local elf_lauch = actual .."/Neutrino/neutrino.elf"
		if alternativo == true then
			elf_lauch = OPCIONES.OPL_ELF
		end
		-- La ISO puede estar en "<raiz>/Roms/ISOs PlayStation 2" o en el "DVD"/"CD" de
		-- una unidad ATA. El scan memorizo el directorio real en ORIGEN_DIR.
		local ruta_iso = RUTA("/Roms/ps2-isos/".. nombre_juego)
		if ORIGEN_DIR ~= nil and ORIGEN_DIR["15|".. nombre_juego] ~= nil then
			ruta_iso = ORIGEN_DIR["15|".. nombre_juego] .. nombre_juego
		end
		if doesFileExist(ruta_iso) and doesFileExist(elf_lauch) then
			OPCIONES.OPL_DIR = "RETRO"
			return true
		elseif doesFileExist(device .."/DVD/".. nombre_juego) and doesFileExist(elf_lauch) and OPCIONES.DIR_EXTRAS_ON == 1 then
			OPCIONES.OPL_DIR = "DVD"
			return true
		elseif doesFileExist(device .."/CD/".. nombre_juego) and doesFileExist(elf_lauch) and OPCIONES.DIR_EXTRAS_ON == 1 then
			OPCIONES.OPL_DIR = "CD"
			return true
		elseif BUSCAR_CDVD == true and doesFileExist("cdfs:/".. string.sub(nombre_juego, 1, 11)) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--- Buscar y cargar configuraciones de PS2. ---------------------------------------------
function load_ps2_cfg(nombre_juego)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	local vmc, modos, GSM, soporte, lista_config = "nil", "nil", "nil", "nil", {}
	if doesFileExist(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_juego, 1, -5) ..".cfg") then
		local carga_cfg = System.openFile(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_juego, 1, -5) ..".cfg", FREAD)
		System.seekFile(carga_cfg, 0, SET)
		local size_config = System.sizeFile(carga_cfg)
		local temp = System.readFile(carga_cfg, size_config)
		System.closeFile(carga_cfg)
		lista_config = sub_string(temp, "[^\r\n]+", lista_config, false)
		local lista_comparar_config = {"-mc%d=.+", "-gc=%d+", "-gsm=.+", "%d"}
		if lista_config ~= nil and (#lista_config >= 1 and #lista_config <= 4) then
			for cont = 1, #lista_comparar_config do
				local presente = false
				for cont2 = 1, #lista_config do
					if string.match(lista_config[cont2], lista_comparar_config[cont]) then
						presente = true
						break
					end
				end
				if presente == false then
					lista_config[cont] = "nil"
				end
			end
		else
			lista_config = {vmc, modos, GSM, soporte}
		end
		if lista_config[1] == "nil" and lista_config[2] == "nil" and lista_config[3] == "nil" and lista_config[4] == "nil" then
			System.removeFile(actual .."/Roms/ISOs PlayStation 2/Configs/".. string.sub(nombre_juego, 1, -5) ..".cfg")
		end
	else
		lista_config = {vmc, modos, GSM, soporte}
	end
	return lista_config
end

--- Ejecuta las ISO de PlayStation 2. ---------------------------------------------------
function ejecutar_iso(nombre)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)
	-- Cargar configuraciones de PS2. ---------------------------------------------------
	local ps2_config = load_ps2_cfg(nombre)
	local vmc, modos, GSM, soporte = nil, nil, nil, nil

	-- Cargar configuraciones de "VMC". -------------------------------------------------
	if ps2_config[1] ~= nil and string.match(ps2_config[1], "-mc%d=.+") then
		-- El ".vmcd" de este menu ya no se lee: la tarjeta sale de VMC.cfg, que es el
		-- unico sitio donde se decide. Un fichero que sobrevive de antes no debe poder
		-- imponer una tarjeta que el menu del juego no muestra.
		vmc = nil
	else
		vmc = nil
	end

	-- Cargar modos de compatibilidad. --------------------------------------------------
	if ps2_config[2] ~= nil and string.match(ps2_config[2], "-gc=%d+") then
		modos = ps2_config[2]
	else
		modos = nil
	end

	-- Cargar configuraciones de "GSM". -------------------------------------------------
	if ps2_config[3] ~= nil and string.match(ps2_config[3], "-gsm=.+") then
		GSM = ps2_config[3]
	else
		GSM = nil
	end

	-- Cargar soporte de medios. --------------------------------------------------------
	if ps2_config[4] ~= nil and string.match(ps2_config[4], "1") then
		soporte = "-net"
	elseif ps2_config[4] ~= nil and string.match(ps2_config[4], "2") then
		soporte = "-hdd"
	else
		soporte = nil
	end

	-- Preparar comandos para ejecutar el juego. ----------------------------------------
	if OPCIONES.PREGUNTAR_PS2 == false then
		-- Verificar GSM. ---------------------------------------------------------------
		if GSM == nil then
			GSM = "-gsm="
		end

		-- Definir el directorio donde se encuentra el juego. ---------------------------
		local selector_device = 1
		-- La ISO puede estar en el USB o en el disco interno: resolver la raiz real. --
		local raiz_iso = RAIZ("/Roms/ps2-isos/".. nombre)
		local name_device = {raiz_iso, device, "mmce:"}
		local selector_dir = 1
		local dir_iso = {"/Roms/ps2-isos/", "/DVD/", "/CD/"}
		if doesFileExist(raiz_iso .."/Roms/ps2-isos/".. nombre) then
			selector_dir = 1
			selector_device = 1
		elseif doesFileExist(device .."/DVD/".. nombre) then
			selector_dir = 2
			selector_device = 2
		elseif doesFileExist(device .."/CD/".. nombre) then
			selector_dir = 3
			selector_device = 2
		end

		-- Definir el medio desde donde se lanzará el juego. ----------------------------
		local nombre_final = nombre
		local selector_bsd = 1
		local name_bsd = {"usb", "mx4sio", "ata", "mmce", "udpbd"}
		if string.lower(string.sub(nombre, -4)) == ".mx4" then
			nombre_final = string.sub(nombre, 1, -5) ..".iso"
			selector_bsd = 2
		elseif string.lower(string.sub(nombre, -4)) == ".hdd" then
			nombre_final = string.sub(nombre, 1, -5) ..".iso"
			selector_bsd = 3
		elseif string.lower(string.sub(nombre, -4)) == ".mmc" then
			nombre_final = string.sub(nombre, 1, -5) ..".iso"
			selector_bsd = 4
			selector_device = 3
		elseif string.lower(string.sub(nombre, -4)) == ".udp" then
			nombre_final = string.sub(nombre, 1, -5) ..".iso"
			selector_bsd = 5
		end
		if selector_bsd ~= 1 and vmc ~= nil then
			vmc = string.sub(vmc, 1, -5) .. ".bin"
		end
		if (soporte == "-net" and selector_bsd == 3) or (soporte == "-hdd" and selector_bsd == 5) then
			name_bsd[selector_bsd] = name_bsd[selector_bsd] .. soporte
		end

		-- Si la ISO esta en el disco interno exFAT, forzar el driver ATA. -------------
		if selector_device == 1 and ES_RAIZ_ATA(raiz_iso) then
			selector_bsd = 3
			if string.lower(string.sub(nombre_final, -4)) ~= ".iso" then
				nombre_final = string.sub(nombre_final, 1, -5) ..".iso"
			end
		end

		-- Lanzar el juego. -------------------------------------------------------------
		local directorio_iso = name_device[selector_device] .. dir_iso[selector_dir]
		-- Si el scan memorizo el directorio real (DVD/CD de una unidad ATA, etc.),
		-- tiene prioridad sobre la deduccion por device.
		if ORIGEN_DIR ~= nil and ORIGEN_DIR["15|".. nombre] ~= nil then
			directorio_iso = ORIGEN_DIR["15|".. nombre]
			if ES_RAIZ_ATA(directorio_iso) then selector_bsd = 3 end
		end
		-- El nombre REAL de la unidad, del lado de Enceladus, ANTES de reescribirlo.
		-- Todo lo que este programa cree o copie tiene que usar este; solo los
		-- argumentos que se le pasan a Neutrino llevan el nombre reescrito.
		local unidad_real = "mass:"
		local pfx_real = string.find(directorio_iso, ":", 1, true)
		if pfx_real ~= nil then unidad_real = string.sub(directorio_iso, 1, pfx_real) end

		-- Con "-bsd=ata" Neutrino solo carga ata_bd: el disco interno es la UNICA
		-- unidad de bloque y se monta como "mass:". Hay que reescribir el prefijo.
		if selector_bsd == 3 then
			local pfx = string.find(directorio_iso, ":", 1, true)
			if pfx ~= nil then directorio_iso = "mass:".. string.sub(directorio_iso, pfx+1) end
		end

		-- VMC automatica por juego, salvo que ya haya una tarjeta manual fijada.
		--
		-- Aqui estaba el fallo que devolvia al menu de la PS2. La tarjeta se creaba
		-- con el prefijo YA reescrito, "mass:", pero quien la crea es este programa,
		-- bajo Enceladus, donde "mass:" es el PRIMER dispositivo BDM -- la llave USB.
		-- Resultado: los 8 MB de la tarjeta se escribian en la llave (de ahi que
		-- parpadeara), y a Neutrino se le pasaba "-mc0=mass:/VMC/..." que con
		-- -bsd=ata apunta al disco interno, donde el fichero no existe. Neutrino no
		-- podia abrir la tarjeta y salia.
		-- Se crea en la unidad real y solo despues se reescribe el prefijo.
		local vmc_auto = nil
		if vmc == nil then
			vmc = VMC_AUTO(nombre, unidad_real)
			if vmc ~= nil and selector_bsd == 3 then
				local pv = string.find(vmc, ":", 1, true)
				if pv ~= nil then vmc = "-mc0=mass:".. string.sub(vmc, pv+1) end
			end
			vmc_auto = vmc
		end
		log_lanzamiento("PS2  Neutrino", {
			"juego        : ".. tostring(nombre),
			"iso final    : ".. tostring(nombre_final),
			"directorio   : ".. tostring(directorio_iso),
			"-bsd=        : ".. tostring(name_bsd[selector_bsd]),
			"desde disco interno (ATA) : ".. tostring(ES_ATA(15, nombre)),
			"",
			log_existe("neutrino.elf", actual .."/Neutrino/neutrino.elf"),
			"",
			"argumento -dvd= : ".. tostring(directorio_iso) .. tostring(nombre_final),
			"VMC por juego   : ".. tostring(vmc_auto) .."  (ID: ".. tostring(VMC_ID(nombre)) ..")",
			"NOTA: con -bsd=ata el disco interno es la unica unidad y Neutrino la ve",
			"como mass:, de ahi la reescritura del prefijo.",
		})
		if modos == nil and vmc == nil then
			if Pads.check(PAD, PAD_CIRCLE) == false then
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			else
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, "-dbc", GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			end
		elseif modos == nil and vmc ~= nil then
			if Pads.check(PAD, PAD_CIRCLE) == false then
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, vmc, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			else
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, "-dbc", vmc, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			end
		elseif modos ~= nil and vmc == nil then
			if Pads.check(PAD, PAD_CIRCLE) == false then
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, modos, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			else
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, "-dbc", modos, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			end
		elseif modos ~= nil and vmc ~= nil then
			if Pads.check(PAD, PAD_CIRCLE) == false then
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, vmc, modos, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			else
				System.loadELF(actual .."/Neutrino/neutrino.elf", 0, "-dbc", vmc, modos, GSM, "-bsd=".. name_bsd[selector_bsd], "-dvd=".. directorio_iso .. nombre_final)
			end
		end

	-- Devuelve las configuraciones encontradas al menú de configuración de PS2. --------
	elseif OPCIONES.PREGUNTAR_PS2 == true then
		return vmc, modos, GSM, soporte
	end
end

--- Cores compatibles con un sistema, en cache: leer decenas de ".info" en cada
--- lanzamiento seria lento, y su contenido no cambia mientras el programa corre.
CORES_CACHE = {}

--- Selector de core de RetroArch. ------------------------------------------------------
--- Se muestra al lanzar, con el core previsto para el sistema ya seleccionado, y SOLO
--- si hay mas de un candidato: si el sistema no tiene alternativa no estorba a nadie.
--- La lista se filtra por plataforma cruzando las extensiones reales del sistema con
--- las que cada core declara en "LibretroPS2Files/info/<core>.info".
--- Devuelve la ruta elegida, o nil si se cancela.
--- Los cores que sirven para un sistema, en la instalacion MAESTRA. -------------------
--- Maestra y no la de la llave: la llave solo lleva el core del juego en curso, asi que
--- preguntarle que hay disponible responde siempre "uno". Aqui se responde con los
--- sesenta del disco, filtrados por las extensiones que cada uno declara en su ".info".
--- Devuelve dos tablas paralelas: rutas y nombres para mostrar.
function CORES_DEL_SISTEMA(identidad, ruta_defecto)
	local cache = CORES_CACHE[identidad]
	if cache ~= nil then return cache.rutas, cache.nombres end

	local rutas, nombres, vistos = {}, {}, {}
	local function anadir(ruta)
		local n = nombre_fichero(ruta)
		if n == "" or n == " " then return end
		if vistos[string.lower(n)] ~= nil then return end
		if doesFileExist(ruta) == false then return end
		vistos[string.lower(n)] = true
		table.insert(rutas, ruta)
		table.insert(nombres, string.sub(n, 1, -5))
	end

	anadir(ruta_defecto)
	local dir_ra = RUTA_LIBRETRO_MAESTRA()
	if dir_ra ~= nil then
		local dir = dir_ra .."/cores"
		local c = System.listDirectory(dir)
		if c ~= nil then
			for j = 1, #c do
				if c[j].directory == false and string.lower(string.sub(c[j].name, -4)) == ".elf"
				   and CORE_SIRVE(dir .."/".. c[j].name, identidad) then
					anadir(dir .."/".. c[j].name)
				end
			end
		end
	end
	CORES_CACHE[identidad] = {rutas = rutas, nombres = nombres}
	return rutas, nombres
end

function elegir_core(ruta_defecto, identidad)
	local rutas, nombres = CORES_DEL_SISTEMA(identidad, ruta_defecto)
	-- Sin alternativas reales no hay nada que preguntar. Pero "el unico que hay" y "el
	-- que venia por defecto" no son lo mismo: "ruta_defecto" es un nombre de fichero a
	-- secas cuando RUTA_CORE no ha sabido resolverlo, y devolverlo entonces era mandar
	-- a lanzar un ELF que no existe. Si hay exactamente uno, se usa ESE.
	if #rutas == 1 then return rutas[1] end
	if #rutas == 0 then return ruta_defecto end

	-- La lista puede tener decenas de entradas y el bandeau no se desplaza solo:
	-- se muestra una ventana de siete alrededor del cursor.
	local VENTANA = 7
	local sel, elegir = 1, true
	JOYSTICK_LIMITE = control_FPS(1)-30
	while elegir do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()

		local ini = sel - (VENTANA // 2)
		if ini < 1 then ini = 1 end
		if ini > #rutas - VENTANA + 1 then ini = #rutas - VENTANA + 1 end
		if ini < 1 then ini = 1 end
		-- Verde = ese core ya esta en la llave, elegirlo no copia nada. Blanco = habra
		-- que copiarlo, y en USB 1.1 un core son varios segundos.
		-- El cursor se marca con una flecha y no solo con el color: desde que un core
		-- ya presente en la llave se pinta en verde, el color ya no dice donde estas.
		local vista, cursor, colores = {}, 1, {}
		for i = ini, ini + VENTANA - 1 do
			if nombres[i] ~= nil then
				local marca = "   "
				if i == sel then marca = ">  " end
				table.insert(vista, marca .. nombres[i])
				if CORE_EN_LLAVE(nombre_fichero(rutas[i])) then
					if COLOR.VERDE_LISTA == nil then COLOR.VERDE_LISTA = Color.new(0, 128, 45) end
					colores[#vista] = COLOR.VERDE_LISTA
				end
				if i == sel then cursor = #vista end
			end
		end
		local extra = #vista - 3
		if extra < 0 then extra = 0 end
		submenu_selector(vista, cursor, "CORE  ".. sel .."/".. #rutas,
			160-(extra*12), 273+(extra*12), true, CONTROL.ANCHO//2,
			{TEXT_GEN[5], TEXT_GEN[6]}, false, false, {}, nil, colores)
		refrescar(false)

		if Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_EJECUTAR, 1, false, nil)
			return rutas[sel]
		elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_MOVER, 1, false, nil)
			if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
				sel = cambiar_valor(sel, 1, #rutas, 1, false)
			else
				sel = cambiar_valor(sel, 1, #rutas, 1, true)
			end
			JOYSTICK_LIMITE = control_FPS(1)
		elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, false, nil)
			elegir = false
		end
	end
	return nil
end

--- Ejecuta cada juego con su respectiva aplicación. ------------------------------------
function ejecutar_juego(identidad, nombre_juego, alternativo)
	local actual = System.currentDirectory()
	local device = salida_texto_dir(actual, nil)

	-- Ejecutar los sistemas de RetroArch. ----------------------------------------------
	if identidad <= 12 then
		-- Lista de sistemas. -----------------------------------------------------------
		local dir_sistemas = {"Sega Megadrive"; "Sega Master System"; "Sega Game Gear"; "Nintendo Famicom"; "Nintendo Game Boy"; "Nintendo Game Boy Color";
		"Nintendo Game Boy Advance"; "Atari 2600"; "Atari Lynx"; "Sega SG-1000"; "Neo Geo Pocket"; "Nintendo Super Famicom";};

		-- Lista de aplicaciones. -------------------------------------------------------
		local name_cores = {"picodrive_libretro_ps2.elf"; "picodrive_libretro_ps2.elf"; "picodrive_libretro_ps2.elf"; "fceumm_libretro_ps2.elf";
		"gambatte_libretro_ps2.elf"; "gambatte_libretro_ps2.elf"; "gpsp_libretro_ps2.elf"; "stella2014_libretro_ps2.elf"; "handy_libretro_ps2.elf";
		"picodrive_libretro_ps2.elf"; "race_libretro_ps2.elf"; "snes9x2002_libretro_ps2.elf";};

		-- Lista de aplicaciones alternativas. ------------------------------------------
		local name_cores_alt = {"picodrive_libretro_ps2_alt.elf"; " "; " "; "quicknes_libretro_ps2.elf"; "tgbdual_libretro_ps2.elf";
		"tgbdual_libretro_ps2.elf"; " "; " "; " "; " "; " "; " ";};

		-- Ejecutar juego. --------------------------------------------------------------
		-- El orden importa y cada paso se anuncia, porque cuando algo falla aqui lo
		-- unico que se veia era "Games or RetroArch not found", que no dice nada:
		--   1. que cores sirven para este sistema
		--   2. cual se usa
		--   3. esta ya en la llave?
		--   4. si no, se copia
		--   5. se lanza
		guardar()
		local nucleo = name_cores[identidad]
		if alternativo == true then nucleo = name_cores_alt[identidad] end

		-- 1 y 2. Los cores del sistema, y el que se usa. -------------------------------
		LANZA_PASO("Checking cores for ".. dir_sistemas[identidad])
		-- En la MAESTRA: es la que tiene todos los cores. La de la llave se consulta
		-- despues, cuando ya se sabe cual hace falta.
		local ruta_core = RUTA_CORE_MAESTRO(nucleo, nucleo)
		-- Eleccion de core al lanzar, solo para la ejecucion normal.
		if alternativo ~= true then
			local elegido = elegir_core(ruta_core, identidad)
			if elegido == nil then return end
			ruta_core = elegido
		end
		if doesFileExist(ruta_core) == false then
			-- Ni el core por defecto ni ninguna alternativa existen en la instalacion.
			boot_log("LANZA  ningun core para ".. dir_sistemas[identidad] .." (buscado: ".. tostring(nucleo) ..")")
			boot_escribir()
			LANZA_PASO("No core for ".. dir_sistemas[identidad])
			System.sleep(3)
			return
		end
		LANZA_PASO("Core: ".. nombre_fichero(ruta_core))
		black_blur()
		local ruta_rom  = RUTA_ROM(identidad, dir_sistemas[identidad], nombre_juego)
		-- Reglas que el lanzador impone a RetroArch: carpetas de partidas y modo de
		-- video. Se reescriben en cada arranque, asi que no hay forma de que se
		-- queden desfasadas.
		-- Si la instalacion de RetroArch esta en el disco interno, el core no sabra
		-- leerla: se pone en la llave lo que ESTE juego necesita, y nada mas.
		-- 3 y 4. En la llave: comprobar, y copiar solo lo que falte. -------------------
		LANZA_PASO("Checking ".. nombre_fichero(ruta_core) .." on USB")
		local base_ra = LIBRETRO_PREPARAR_PARA(nombre_fichero(ruta_core))
		if base_ra ~= nil then ruta_core = RUTA_CORE(nombre_fichero(ruta_core), ruta_core) end
		if doesFileExist(ruta_core) == false then
			boot_log("LANZA  el core no ha llegado a su destino: ".. tostring(ruta_core))
			boot_escribir()
			LANZA_PASO("Core not ready: ".. nombre_fichero(ruta_core))
			System.sleep(3)
			return
		end
		local lee_ata_core = CORE_LEE_ATA(ruta_core)
		FORZAR_CONF_RETROARCH(OPCIONES.VIDEO_MODE ~= 0, lee_ata_core)
		-- "Bios/" es "system_directory": no hay copia que hacer salvo si el core no
		-- puede leer el disco donde esta.
		BIOS_LIBRETRO(lee_ata_core)
		-- Los cores montan su propia pila de dispositivos, SIN ata_bd: una ROM en el
		-- disco interno exFAT les es invisible. Se transborda a un soporte legible.
		local transbordo = "no hace falta"
		local lee_ata = CORE_LEE_ATA(ruta_core)
		local saves_ida = 0
		if ES_RAIZ_ATA(ruta_rom) and lee_ata == false then
			local consola = CARPETA_DE_RUTA(ruta_rom)
			LANZA_PASO("Copying ROM")
			local nueva, donde = ROM_TRANSBORDO(ruta_rom, nombre_juego)
			transbordo = tostring(donde)
			if string.find(tostring(donde), "cache", 1, true) ~= nil then
				LANZA_REEMPLAZAR("ROM already on USB")
				LANZA_VERDE[#LANZA_LINEAS] = true
				LANZA_PINTAR()
			end
			if nueva ~= nil then
				-- La partida de este juego viaja con la ROM. Sin esto el juego
				-- arrancaria en blanco y machacaria lo guardado en el disco. Son dos
				-- listados -- "Saves/<consola>" y "SaveStates/<consola>" -- y solo se
				-- copian los ficheros que empiezan por el nombre de ESTE juego.
				saves_ida = SAVES_DESPLEGAR(DEV_DE_RUTA(nueva), consola, SIN_EXTENSION(nombre_juego))
				if saves_ida > 0 then
					LANZA_PASO("Saves: ".. tostring(saves_ida) .." file(s)")
				end
				ruta_rom = nueva
			end
		elseif ES_RAIZ_ATA(ruta_rom) then
			transbordo = "innecesario: este core lee el disco interno"
		end
		-- El core recibe el juego en argv[1]: Enceladus pone la ruta del ELF en argv[0]
		-- y encadena los argumentos variadicos a partir de argv[1], que es exactamente
		-- lo que lee "frontend_ps2_get_env" para fijar "content_path". Lo que hay que
		-- traducir es el NOMBRE DE LA UNIDAD, porque RetroArch reinicia el IOP y monta
		-- su propia pila, donde los nombres no son los de Enceladus:
		--   ROM en un USB ............ Enceladus "mass0:"  ->  core "mass:"
		--   ROM en el disco interno .. Enceladus "mass0:"  ->  core "ata0:"
		--   ROM en la Memory Card .... "mc0:" en los dos lados, no se toca
		-- El caso del disco interno solo vale si el core lleva el parche ata_bd; si no,
		-- la ROM ya se ha transbordado mas arriba y esta en otra unidad.
		local rom_arg = ruta_rom
		if ES_RAIZ_ATA(ruta_rom) and lee_ata == true then
			rom_arg = RUTA_ATA_CORE(ruta_rom)
		else
			local pos_dev = string.find(ruta_rom, ":", 1, true)
			if pos_dev ~= nil then
				local dev = string.sub(ruta_rom, 1, pos_dev-1)
				-- SOLO para "massN:". Aplicarlo a "mc0:" daria "mc:", y la ROM
				-- transbordada a la Memory Card seria imposible de abrir.
				if string.lower(string.sub(dev, 1, 4)) == "mass" then
					while string.len(dev) > 0 and string.match(string.sub(dev, -1), "%d") ~= nil do
						dev = string.sub(dev, 1, -2)
					end
					rom_arg = dev ..":".. string.sub(ruta_rom, pos_dev+1)
				end
			end
		end
		log_lanzamiento("RETROARCH  ".. dir_sistemas[identidad], {
			"identidad   : ".. tostring(identidad),
			"juego       : ".. tostring(nombre_juego),
			"alternativo : ".. tostring(alternativo),
			"desde disco interno (ATA) : ".. tostring(ES_ATA(identidad, nombre_juego)),
			"",
			log_existe("core", ruta_core),
			log_existe("rom ", ruta_rom),
			"argv[1]     : ".. tostring(rom_arg),
			"",
			"IOP_REBOOT_CORES : ".. tostring(IOP_REBOOT_CORES),
			"core lee ATA    : ".. tostring(lee_ata) .."  (lista CORES_ATA en system.lua)",
			"transbordo      : ".. tostring(transbordo),
			"partidas llevadas : ".. tostring(saves_ida) .."  (vuelven solas al arrancar el lanzador)",
		})
		LANZA_PASO("Launching ".. tostring(nombre_juego))
		-- Preferir "raboot.elf" cuando esta disponible: es el bootstrap oficial de
		-- las nightlies, y funciona donde la llamada directa al core falla.
		local raboot = RUTA_RABOOT()
		if raboot ~= nil and PREPARAR_RABOOT(raboot, ruta_core) then
			log_lanzamiento("RETROARCH via raboot  ".. dir_sistemas[identidad], {
				"juego : ".. tostring(nombre_juego),
				"",
				log_existe("raboot", raboot),
				log_existe("core  ", ruta_core),
				log_existe("rom   ", ruta_rom),
				"",
				log_existe("salamander", RUTA_SALAMANDER(raboot)),
				"Verificado por relectura: contiene el core de arriba.",
				"Poner RABOOT_ON a false para volver a la llamada directa.",
			})
			System.loadELF(raboot, IOP_REBOOT_CORES, rom_arg)
		end
		System.loadELF(ruta_core, IOP_REBOOT_CORES, rom_arg)

	-- Ejecutar APPS. -------------------------------------------------------------------
	elseif identidad == 13 then
		guardar()
		black_blur()
		local wle = RUTA_WLE(false)
		if wle ~= nil and alternativo == false then
			app_alt(false)
			log_lanzamiento("APPS  wLaunchELF", {log_existe("elf", wle)})
			System.loadELF(wle, 0, actual .."/uLaunchELF/")
		else
			log_lanzamiento("APPS  ELF externo", {log_existe("elf", LISTAS.DIR_FULL_APP[LISTAS.INDICE])})
			System.loadELF(LISTAS.DIR_FULL_APP[LISTAS.INDICE], 0, salida_texto_dir(LISTAS.DIR_FULL_APP[LISTAS.INDICE], false))
		end

	-- Ejecutar sistema de PlayStation 1. -----------------------------------------------
	elseif identidad == 14 then
		guardar()
		local nombre_temp = string.sub(nombre_juego, 1, -5)
		local nombre_temp_2 = nombre_temp
		if string.len(nombre_temp_2) >= 13 and string.match(string.sub(nombre_temp_2, 1, 12), "%a+_%d+%.%d+%.") then
			nombre_temp_2 = string.sub(nombre_temp_2, 13)
		end
		-- Unidad de trabajo de POPStarter: la que tenga el juego en su "POPS/", que no
		-- es forzosamente POPS_RAIZ. El ELF, el .VCD y la tarjeta de memoria deben
		-- compartir unidad, de ahi que todo lo de abajo pase por aqui.
		local pops_u = POPS_DE(nombre_juego)
		-- Misma cautela que con Ember: reiniciar el IOP descarga "ata_bd".
		local reboot_pops = IOP_REBOOT_POPS
		if ES_RAIZ_ATA(pops_u) then reboot_pops = 0 end
		if string.lower(string.sub(nombre_juego, -4)) == ".cue" then
			local raiz_ps1 = RAIZ("/Roms/psx-ember(bin and cue)/".. nombre_juego)
			local carpeta_ps1 = raiz_ps1 .."/Roms/psx-ember(bin and cue)"
			-- Ember se lanza DESDE la carpeta de los juegos y recibe solo el nombre
			-- del fichero, como en el original: resuelve el .cue relativo a su
			-- directorio, no acepta una ruta completa.
			local ember = EMBER_EN(carpeta_ps1)
			-- Un IOP limpio se lleva por delante "ata_bd", y con el, el disco interno.
			-- Si el juego vive ahi NO se puede reiniciar: Ember dejaria de ver su
			-- propia carpeta. Se reinicia solo cuando el juego esta en el arranque.
			local reboot_ember = IOP_REBOOT_EMBER
			if ES_RAIZ_ATA(carpeta_ps1) then reboot_ember = 0 end
			log_lanzamiento("PS1  Ember", {
				"juego : ".. tostring(nombre_juego),
				"raiz  : ".. tostring(raiz_ps1),
				"desde disco interno (ATA) : ".. tostring(ES_ATA(14, nombre_juego)),
				"",
				log_existe("ember.elf", carpeta_ps1 .."/ember.elf"),
				log_existe("bios.bin ", carpeta_ps1 .."/bios.bin"),
				log_existe("cue      ", carpeta_ps1 .."/".. nombre_juego),
				"",
				"argumento : ".. tostring(nombre_juego) .."  (nombre desnudo)",
				"reinicio del IOP : ".. tostring(reboot_ember) .."  (ajuste: ".. tostring(IOP_REBOOT_EMBER) ..")",
			})
			if ember == nil then
				ERROR_DETALLE = detalle_falta("Ember", carpeta_ps1 .."/", {"ember.elf"})
				return
			end
			System.loadELF(ember, reboot_ember, nombre_juego)
		elseif string.lower(string.sub(nombre_juego, -4)) == ".elf" then
			log_lanzamiento("PS1  ELF en POPS", {log_existe("elf", pops_u .."/POPS/".. nombre_juego)})
			System.loadELF(pops_u .."/POPS/".. nombre_juego, 0, pops_u .."/POPS/")
		elseif VCD_A_POPS(nombre_juego) and doesFileExist(pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF") then
			PARCHE_USB_DELAY(pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF")
			log_lanzamiento("PS1  POPStarter (atajo en APPS)", {
				"juego     : ".. tostring(nombre_juego),
				"unidad    : ".. tostring(pops_u),
				"desde disco interno (ATA) : ".. tostring(ES_ATA(14, nombre_juego)),
				"",
				log_existe("atajo ", pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF"),
				log_existe("vcd   ", pops_u .."/POPS/".. nombre_juego),
				log_existe("iox   ", pops_u .."/POPS/POPS_IOX.PAK"),
				log_existe("ioprp ", pops_u .."/POPS/IOPRP252.IMG"),
				log_existe("POPS.ELF", pops_u .."/POPS/POPS.ELF"),
				log_existe("POPS.PAK", pops_u .."/POPS/POPS.PAK"),
				"",
				POPSTARTER_DRIVERS_MC(),
				"",
				"delay USB en el atajo (byte 0x413, tras el parche) : ".. tostring(LEE_USB_DELAY(pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF")) .."  (ajuste: ".. tostring(POPS_USB_DELAY) ..")",
				"",
				"POPStarter necesita el atajo, el .VCD y su tarjeta de memoria en la",
				"MISMA unidad. En exFAT hacen falta ademas los drivers BDMAssault en",
				"la Memory Card, y no hay constancia de que soporte un disco ATA.",
			})
			black_blur()
			if doesFileExist(actual .."/System/Intros/PS1/intro_ps1.lua") then
				require("System/Intros/PS1/intro_ps1")
				ps1_startup()
			end
			System.loadELF(pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF", reboot_pops, pops_u .."/APPS/".. nombre_temp_2 .."/", "--nr")
		elseif doesFileExist(pops_u .."/POPS/XX.".. nombre_temp ..".ELF") then
			PARCHE_USB_DELAY(pops_u .."/POPS/XX.".. nombre_temp ..".ELF")
			log_lanzamiento("PS1  POPStarter (atajo en POPS)", {
				"juego     : ".. tostring(nombre_juego),
				"unidad    : ".. tostring(pops_u),
				"desde disco interno (ATA) : ".. tostring(ES_ATA(14, nombre_juego)),
				"",
				log_existe("atajo ", pops_u .."/POPS/XX.".. nombre_temp ..".ELF"),
				log_existe("vcd   ", pops_u .."/POPS/".. nombre_juego),
				log_existe("iox   ", pops_u .."/POPS/POPS_IOX.PAK"),
				log_existe("ioprp ", pops_u .."/POPS/IOPRP252.IMG"),
				log_existe("POPS.ELF", pops_u .."/POPS/POPS.ELF"),
				log_existe("POPS.PAK", pops_u .."/POPS/POPS.PAK"),
				"",
				POPSTARTER_DRIVERS_MC(),
				"",
				"reinicio del IOP : ".. tostring(reboot_pops) .."  (ajuste: ".. tostring(IOP_REBOOT_POPS) ..")",
				"delay USB en el atajo (byte 0x413, tras el parche) : ".. tostring(LEE_USB_DELAY(pops_u .."/POPS/XX.".. nombre_temp ..".ELF")) .."  (ajuste: ".. tostring(POPS_USB_DELAY) ..")",
			})
			black_blur()
			if doesFileExist(actual .."/System/Intros/PS1/intro_ps1.lua") then
				require("System/Intros/PS1/intro_ps1")
				ps1_startup()
			end
			System.loadELF(pops_u .."/POPS/XX.".. nombre_temp ..".ELF", reboot_pops, pops_u .."/POPS/", "--nr")
		else
			JOYSTICK_LIMITE = control_FPS(1)-30
			local pregunta, selector_dir = true, 1
			while pregunta do
				CONTROL.FPS = Screen.getFPS(1)
				capturar(JOYSTICK_LIMITE)
				dibujar_fondos()
				local submenu_lista = {TEXT_M_PRI[29], TEXT_M_PRI[30]}
				local lista_resp = {TEXT_GEN[5], TEXT_GEN[6]}
				submenu_selector(submenu_lista, selector_dir, "-".. TEXT_M_PRI[28] .."-", 160, 247, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
				if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
					repro_sfx(S_EJECUTAR, 1, false, nil)
					submenu_selector({}, nil, TEXT_M_CON[46], 160, 247, true, CONTROL.ANCHO//2, {}, false, true, {}, nil)
					if selector_dir == 1 then
						if doesFileExist(actual .."/POPStarter/POPSTARTER.ELF") then
							System.copyFile(actual .."/POPStarter/POPSTARTER.ELF", pops_u .."/POPS/XX.".. nombre_temp ..".ELF")
						else
							error("No found \"".. actual .."/POPStarter/POPSTARTER.ELF\"")
						end
						ejecutar_juego(14, nombre_juego, false)
					elseif selector_dir == 2 then
						if doesFileExist(actual .."/POPStarter/POPSTARTER.ELF") then
							if System.listDirectory(pops_u .."/APPS") == nil then
								System.createDirectory(pops_u .."/APPS")
							end
							if System.listDirectory(pops_u .."/APPS/".. nombre_temp_2) == nil then
								System.createDirectory(pops_u .."/APPS/".. nombre_temp_2)
							end
							System.copyFile(actual .."/POPStarter/POPSTARTER.ELF", pops_u .."/APPS/".. nombre_temp_2 .."/XX.".. nombre_temp ..".ELF")
							local data_pops = "title=".. nombre_temp_2 .."\r\nboot=XX.".. nombre_temp ..".ELF\r\n"
							local title_create = System.openFile(pops_u .."/APPS/".. nombre_temp_2 .."/title.cfg", FCREATE)
							System.writeFile(title_create, data_pops, string.len(data_pops))
							System.closeFile(title_create)
						else
							error("No found \"".. actual .."/POPStarter/POPSTARTER.ELF\"")
						end
						ejecutar_juego(14, nombre_juego, false)
					end
				elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and CONTROL.JOYSTICK_ON == false then
					repro_sfx(S_MOVER, 1, false, nil)
					if (Pads.check(PAD, PAD_UP) or Left_Y <= -90 or Pads.check(PAD, PAD_LEFT) or Left_X <= -90) then
						selector_dir = cambiar_valor(selector_dir, 1, 2, 1, false)
					elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90 or Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) then
						selector_dir = cambiar_valor(selector_dir, 1, 2, 1, true)
					end
					JOYSTICK_LIMITE = control_FPS(1)
				elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
					pregunta = false
				end
				refrescar(false)
			end
		end

	-- Ejecutar sistema de PlayStation 2. -----------------------------------------------
	elseif identidad == 15 then
		guardar()
		if OPCIONES.OPL_DIR ~= "RETRO" and alternativo == true then
			local nombre_iso, id_name = id_opl(device .."/".. OPCIONES.OPL_DIR .."/", nombre_juego, true)
			if id_name ~= nil then
				black_blur()
				if doesFileExist(actual .."/System/Intros/PS2/intro_ps2.lua") then
					require("System/Intros/PS2/intro_ps2")
					ps2_startup()
				end
				System.loadELF(OPCIONES.OPL_ELF, 0, nombre_iso, id_name, OPCIONES.OPL_DIR, "bdm")
			else
				ejecutar_juego(15, nombre_juego, false)
			end
		else
			black_blur()
			if string.lower(string.sub(nombre_juego, -4)) == ".elf" then
				log_lanzamiento("PS2  ELF en el lector CD/DVD", {log_existe("elf", "cdfs:/".. string.sub(nombre_juego, 1, 11))})
				System.loadELF("cdfs:/".. string.sub(nombre_juego, 1, 11), 0, "cdfs:/")
			else
				if doesFileExist(actual .."/System/Intros/PS2/intro_ps2.lua") then
					require("System/Intros/PS2/intro_ps2")
					ps2_startup()
				end
				ejecutar_iso(nombre_juego)
			end
		end
	end
end

--- Crear archivo "LAUNCHELF.CNF" para lanzar aplicaciones con WLE. ---------------------
function app_alt(salida)
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/uLaunchELF/LAUNCHELF.CNF") then
		System.removeFile(actual .."/uLaunchELF/LAUNCHELF.CNF")
	end
	local apps_l = LISTAS.DIR_FULL_APP[LISTAS.INDICE]
	local title_app_l = "RETROLauncher"
	if LISTAS.ROMS[LISTAS.INDICE] ~= nil then
		title_app_l = string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, -CONTROL.EXTENSION)
	end
	if OPCIONES.APPS_MENU_FULL_PATH == 1 and LISTAS.ROMS[LISTAS.INDICE] ~= nil then
		title_app_l = salida_texto_dir(string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, -CONTROL.EXTENSION), true)
	end
	if salida == true then
		apps_l = OPCIONES.SALIDA_RETROLANCHER
		title_app_l = string.sub(salida_texto_dir(OPCIONES.SALIDA_RETROLANCHER, true), 1, -CONTROL.EXTENSION)
	elseif salida == nil then
		apps_l = actual .."/RETROLauncher.elf"
		title_app_l = "RETROLauncher"
	end
	local config_wlc = {"CNF_version = 3"; "LK_auto_E1 = ".. apps_l; "LK_Circle_E1 = ".. actual .."/RETROLauncher.elf"; "LK_Cross_E1 = ".. apps_l;
	"LK_Square_E1 = MISC/About uLE"; "LK_Triangle_E1 = MISC/PS2Browser"; "LK_L1_E1 = "; "LK_R1_E1 = "; "LK_L2_E1 = ";
	"LK_R2_E1 = "; "LK_L3_E1 = "; "LK_R3_E1 = "; "LK_Start_E1 = "; "LK_Select_E1 = "; "LK_Left_E1 = "; "LK_Right_E1 = ";
	"Misc = MISC/"; "Misc_PS2Disc = PS2Disc"; "Misc_FileBrowser = FileBrowser"; "Misc_PS2Browser = PS2Browser";
	"Misc_PS2Net = PS2Net"; "Misc_PS2PowerOff = PS2PowerOff"; "Misc_HddManager = HddManager"; "Misc_TextEditor = TextEditor";
	"Misc_JpgViewer = JpgViewer"; "Misc_Configure = Configure"; "Misc_Load_CNFprev = Load CNF--"; "Misc_Load_CNFnext = Load CNF++";
	"Misc_Set_CNF_Path = Set CNF_Path"; "Misc_Load_CNF = Load CNF"; "Misc_ShowFont = ShowFont"; "Misc_Debug_Info = Debug Info";
	"Misc_About_uLE = About uLE"; "Misc_Show_Build_Info = BuildInfo"; "Misc_OSDSYS = OSDSYS"; "GUI_Col_1_ABGR = 00A04000";
	"GUI_Col_2_ABGR = 00FFFFFF"; "GUI_Col_3_ABGR = 00FFFFFF"; "GUI_Col_4_ABGR = 00FFA0A0"; "GUI_Col_5_ABGR = 0000FFFF";
	"GUI_Col_6_ABGR = 0000FF00"; "GUI_Col_7_ABGR = 00404040"; "GUI_Col_8_ABGR = 00808080"; "SKIN_FILE = "; "GUI_SKIN_FILE = ";
	"SKIN_Brightness = 50"; "TV_mode = 0"; "Screen_Offset_X = 0"; "Screen_Offset_Y = 0"; "Popup_Opaque = 1"; "Menu_Frame = 0";
	"Show_Menu = 0"; "LK_auto_Timer = 0"; "Menu_Hide_Paths = 1"; "Menu_Pages = 1"; "GUI_Swap_Keys = 0"; "NET_HOSTwrite = 0";
	"Menu_Title = RETROLauncher"; "Init_Delay = 0"; "USBKBD_USED = 0"; "USBKBD_FILE = "; "KBDMAP_FILE = "; "Menu_Show_Titles = 1";
	"PathPad_Lock = 0"; "CNF_Path = "; "LANG_FILE = "; "FONT_FILE = "; "JpgView_Timer = 5"; "JpgView_Trans = 2"; "JpgView_Full = 0";
	"PSU_HugeNames = 0"; "PSU_DateNames = 0"; "PSU_NoOverwrite = 0"; "FB_NoIcons = 0"; "LK_Circle_Title = RETROLauncher";
	"LK_Cross_Title = ".. title_app_l; "LK_Square_Title = About uLE"; "PathPad_Lock = 0";};
	local LCHELF_COF = ""
	for crear = 1, #config_wlc do
		LCHELF_COF = LCHELF_COF .. config_wlc[crear] .."\r\n"
	end
	local LCHELF = System.openFile(actual .."/uLaunchELF/LAUNCHELF.CNF", FCREATE)
	System.writeFile(LCHELF, LCHELF_COF, string.len(LCHELF_COF))
	System.closeFile(LCHELF)
end

--- Determina el volumen de los sonidos y la música. ------------------------------------
function set_volume()
	SFX_VOLUMEN(OPCIONES.SOUND_VOLUME)
	Sound.setADPCMVolume(3, OPCIONES.SOUND_VOLUME)
	if OPCIONES.SOUND_VOLUME >= 10 then
		Sound.setADPCMVolume(2, OPCIONES.SOUND_VOLUME-9)
	else
		Sound.setADPCMVolume(2, 0)
	end
end

--- Muestra barra de progreso. ----------------------------------------------------------
function pantalla_reiniciar_conf(FONDO, estado, limpiar, indi_rest)
	-- Durante el arranque manda la lista de pasos, y solo ella. Las dos se pintaban
	-- por turnos -- pantalla de progreso, panel negro, pantalla de progreso -- y el
	-- resultado era un parpadeo sin sentido. Fuera del arranque CARGA_FONDO ya es nil
	-- y esta pantalla vuelve a funcionar, que es la que usa "reiniciar configuracion".
	if CARGA_FONDO ~= nil then return end
	Screen.clear(COLOR.NEGRO)
	local res_x, res_y_tex, res_y = 640, 0, 448
	if doesFileExist("System/Defaults/PAL") then
		res_x, res_y_tex, res_y = 640, 34, 512
	end
	if OPCIONES.FONDO_RGB_ON == 1 and (OPCIONES.FONDO_RGB_FIJO_ON == 0 or (OPCIONES.FONDO_RGB_FIJO_ON == 1 and CAMBIOS_EMUS.TRAS == 0)) then
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, res_x+5, res_y, 0.00, nil, Color.new(0, 80, 120))
		else
			Graphics.drawScaleImage(FONDO, -5, 0, res_x+5, res_y, Color.new(0, 80, 120))
		end
	elseif OPCIONES.FONDO_RGB_ON == 1 and OPCIONES.FONDO_RGB_FIJO_ON == 1 then
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, res_x+5, res_y, 0.00, false, Color.new(0, 80, 120))
		else
			Graphics.drawScaleImage(FONDO, -5, 0, res_x+5, res_y)
		end
		Graphics.drawRect(0, 0, res_x+5, res_y, Color.new(0, 80, 120, CAMBIOS_EMUS.TRAS))
	else
		if SPRITES.FONDO_ANI == true then
			fondo_sprites(LISTAS.FONDO, -5, 0, res_x+5, res_y, 0.00, false, Color.new(0, 80, 120))
		else
			Graphics.drawScaleImage(FONDO, -5, 0, res_x+5, res_y)
		end
	end
	Graphics.drawScaleImage(LISTAS.LOADING, 0, 0, res_x, res_y)
	Graphics.drawRect(-5, 278-3+res_y_tex, 650, 25, COLOR.NEGRO)
	local lista_indi_rest = {"Atari 2600"; "Atari Lynx"; "Neo Geo Pocket"; "Nintendo Famicom"; "Nintendo Game Boy"; "Nintendo Game Boy Advance";
	"Nintendo Game Boy Color"; "Nintendo Super Famicom"; "Sega Game Gear"; "Sega Master System"; "Sega Megadrive"; "Sega SG-1000";};
	if limpiar == true then
		Font.ftPrint(CONTROL.fontARCA, (640//2), 278+res_y_tex, 8, 640, 25, "- ".. TEXT_M_CON[70] .." -", COLOR.BLANCO)
	elseif indi_rest ~= 0 and indi_rest ~= 20 and indi_rest ~= 21 and limpiar == false then
		Font.ftPrint(CONTROL.fontARCA, (640//2), 278+res_y_tex, 8, 640, 25, "-".. TEXT_M_CON[71] .." ".. lista_indi_rest[indi_rest] .."-", COLOR.BLANCO)
	elseif indi_rest == 20 and limpiar == false then
		Font.ftPrint(CONTROL.fontARCA, (640//2), 278+res_y_tex, 8, 640, 25, "-".. TEXT_M_CON[72] .."-", COLOR.BLANCO)
	elseif indi_rest == 21 and limpiar == false then
		Font.ftPrint(CONTROL.fontARCA, (640//2), 278+res_y_tex, 8, 640, 25, "-".. TEXT_M_CON[73] .."-", COLOR.BLANCO)
	else
		Font.ftPrint(CONTROL.fontARCA, (640//2), 278+res_y_tex, 8, 640, 25, "-".. TEXT_M_CON[74] .."-", COLOR.BLANCO)
	end
	Font.ftPrint(CONTROL.fontARCA, (640//2), 304+res_y_tex, 8, 640, 25, "█████████████████████████", COLOR.BLANCO)
	if estado ~= 0 then
		Font.ftPrint(CONTROL.fontARCA, (640//2), 304+res_y_tex, 8, 640, 25, string.sub("█████████████████████████", 1, estado), Color.new(0, 80, 120))
	end
	refrescar(false)
end

--- Guardar último juego y sistema usado. -----------------------------------------------
function guardar()
	local actual = System.currentDirectory()
	local config = ("".. LISTAS.IDENTIDAD .." ".. LISTAS.INDICE .." ".. LAST_MOVE[1] .." ".. LAST_MOVE[2] .." ".. LAST_MOVE[3] .." ".. LAST_MOVE[4] ..
	" ".. LAST_MOVE[5] .." ".. LAST_MOVE[6] .." ".. LAST_MOVE[7] .." ".. LAST_MOVE[8] .." ".. LAST_MOVE[9] .." ".. LAST_MOVE[10] .." ".. LAST_MOVE[11] ..
	" ".. LAST_MOVE[12] .." ".. LAST_MOVE[13] .." ".. LAST_MOVE[14] .." ".. LAST_MOVE[15] ..
	"                                                                                                    ")
	if doesFileExist(actual .."/System/Config/Config.cfg") then
		local carga_de_config = System.openFile("System/Config/Config.cfg", FRDWR)
		System.writeFile(carga_de_config, config .." ", string.len(config))
		System.closeFile(carga_de_config)
	else
		if doesFileExist(actual .."/System/Defaults/Config.cfg") then
			System.copyFile(actual .."/System/Defaults/Config.cfg", "System/Config/Config.cfg")
			guardar()
		else
			error("No found ".. actual .."/System/Defaults/Config.cfg")
		end
	end
end

--- Carga el directorio de salida seleccionado. -----------------------------------------
function cargar_directorio_elf(tipo)
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/System/Config/Path_OPL.cfg") and tipo == true then
		local carga_de_dir = System.openFile(actual .."/System/Config/Path_OPL.cfg", FREAD)
		System.seekFile(carga_de_dir, 0, SET)
		local size = System.sizeFile(carga_de_dir)
		local temp_dir = System.readFile(carga_de_dir, size)
		System.closeFile(carga_de_dir)
		if doesFileExist(temp_dir) then
			OPCIONES.OPL_ELF = temp_dir
			return true
		else
			OPCIONES.OPL_ELF = actual .."/OPL/OPNPS2LD.ELF"
			return false
		end
	elseif doesFileExist(actual .."/System/Config/Path_file.cfg") and tipo == false then
		local carga_de_dir = System.openFile(actual .."/System/Config/Path_file.cfg", FREAD)
		System.seekFile(carga_de_dir, 0, SET)
		local size = System.sizeFile(carga_de_dir)
		local temp_dir = System.readFile(carga_de_dir, size)
		System.closeFile(carga_de_dir)
		if temp_dir ~= "PS2 SYSTEM MENU" and doesFileExist(temp_dir) then
			OPCIONES.SALIDA_RETROLANCHER = temp_dir
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
			return true
		else
			OPCIONES.SALIDA_RETROLANCHER = "PS2 SYSTEM MENU"
			OPCIONES.SALIDA_DIR_ACTUALES, OPCIONES.SALIDA_DIR_ANTERIORES = {}, {}
			return false
		end
	elseif tipo ~= nil then
		guardar_directorio_elf(tipo)
		cargar_directorio_elf(tipo)
	end
end

--- Guardar el directorio de salida seleccionado. ---------------------------------------
function guardar_directorio_elf(tipo)
	local actual = System.currentDirectory()
	local dir = OPCIONES.SALIDA_RETROLANCHER
	local archivo = actual .."/System/Config/Path_file.cfg"
	if tipo == true then
		dir = OPCIONES.OPL_ELF
		archivo = actual .."/System/Config/Path_OPL.cfg"
	end
	if doesFileExist(archivo) then
		System.removeFile(archivo)
	end
	local guarda_dir = System.openFile(archivo, FCREATE)
	System.writeFile(guarda_dir, dir, string.len(dir))
	System.closeFile(guarda_dir)
end

--- Guardar opciones. -------------------------------------------------------------------
function guardar_opciones()
	local actual = System.currentDirectory()
	local config = ("".. OPCIONES.RGB_ON .." ".. OPCIONES.FONDO_RGB_ON .." ".. OPCIONES.FONDO_RGB_FIJO_ON .." ".. OPCIONES.R .." ".. OPCIONES.G ..
	" ".. OPCIONES.B .." ".. CONTROL.ESTILO .." ".. SISTEMAS.MEGADRIVE_ON .." ".. SISTEMAS.MASTERSYSTEM_ON .." ".. SISTEMAS.GAMEGEAR_ON ..
	" ".. SISTEMAS.FAMICOM_ON .." ".. SISTEMAS.GAMEBOY_ON .." ".. SISTEMAS.GAMEBOYCOLOR_ON .." ".. SISTEMAS.GAMEBOYADVANCE_ON ..
	" ".. SISTEMAS.ATARI2600_ON .." ".. SISTEMAS.ATARILYNX_ON .." ".. SISTEMAS.SEGASG1000_ON .." ".. SISTEMAS.NEOGEOPOCKET_ON ..
	" ".. SISTEMAS.SUPERFAMICOM_ON .." ".. SISTEMAS.APPS_ON .." ".. SISTEMAS.PLAYSTATION_ON .." ".. OPCIONES.CAMBIO_FUENTE_ON ..
	" ".. OPCIONES.CAMBIO_FONDO_ON .." ".. OPCIONES.GUI_LIMPIA_ON .." ".. OPCIONES.LIMITADOR_RAM_ON .." ".. OPCIONES.SALIDA_RETROLANCHER_ON ..
	" ".. OPCIONES.APPS_MENU_FULL_PATH .." ".. OPCIONES.SOUND_ON .." ".. OPCIONES.SOUND_VOLUME .." ".. OPCIONES.SCREENSHOT_BACK_ON ..
	" ".. OPCIONES.VIDEO_MODE .." ".. OPCIONES.VIBRATION_ON .." ".. SISTEMAS.PLAYSTATION2_ON .." ".. OPCIONES.DIR_EXTRAS_ON .." ".. CAMBIOS_EMUS.TRAS ..
	" ".. OPCIONES.LIBERAR_LISTAS .." ".. OPCIONES.FONT_PIXEL_X .." ".. OPCIONES.FONT_PIXEL_Y .." ".. OPCIONES.FONT_SHADOW .." ".. OPCIONES.SCROLL_MIN ..
	" ".. OPCIONES.SPRITE_ON .." ".. OPCIONES.SEE_INDEX .." ".. OPCIONES.COLOR_LISTA_B .." ".. OPCIONES.SCREENSHOT_BACK_TR .." ".. OPCIONES.RUN_DEFAULT ..
	" ".. COLOR.CC_BACK[1] .." ".. COLOR.CC_BACK[2] .." ".. COLOR.CC_BACK[3] .." ".. COLOR.CC_BACK[4] ..
	"                                                                                                    ")
	if doesFileExist(actual .."/System/Config/System.cfg") then
		local carga_de_opciones = System.openFile("System/Config/System.cfg", FRDWR)
		System.writeFile(carga_de_opciones, config, string.len(config))
		System.closeFile(carga_de_opciones)
	else
		if doesFileExist(actual .."/System/Defaults/System.cfg") then
			System.copyFile(actual .."/System/Defaults/System.cfg", "System/Config/System.cfg")
			guardar_opciones()
		else
			error("No found ".. actual .."/System/Defaults/System.cfg")
		end
	end
end

--- Cargar último juego y sistema usado / Cargar opciones guardadas. --------------------
function cargar_config()
	-- Define y guarda las opciones por defecto. ----------------------------------------
	local function default_config()
		pantalla_reiniciar_conf(LISTAS.FONDO, 34, false, 21)
		OPCIONES.RGB_ON = 1
		OPCIONES.FONDO_RGB_ON = 1
		OPCIONES.FONDO_RGB_FIJO_ON = 0
		OPCIONES.R = 0
		OPCIONES.G = 80
		OPCIONES.B = 120
		CONTROL.ESTILO = 1
		definir_estilos()
		SISTEMAS.MEGADRIVE_ON = 1
		SISTEMAS.MASTERSYSTEM_ON = 1
		SISTEMAS.GAMEGEAR_ON = 1
		SISTEMAS.FAMICOM_ON = 1
		SISTEMAS.GAMEBOY_ON = 1
		SISTEMAS.GAMEBOYCOLOR_ON = 1
		SISTEMAS.GAMEBOYADVANCE_ON = 1
		SISTEMAS.ATARI2600_ON = 1
		SISTEMAS.ATARILYNX_ON = 1
		SISTEMAS.SEGASG1000_ON = 1
		SISTEMAS.NEOGEOPOCKET_ON = 1
		SISTEMAS.SUPERFAMICOM_ON = 0
		SISTEMAS.APPS_ON = 1
		SISTEMAS.PLAYSTATION_ON = 1
		OPCIONES.CAMBIO_FUENTE_ON = 1
		OPCIONES.CAMBIO_FONDO_ON = 1
		OPCIONES.GUI_LIMPIA_ON = 0
		OPCIONES.LIMITADOR_RAM_ON = 0
		OPCIONES.SALIDA_RETROLANCHER_ON = 0
		OPCIONES.APPS_MENU_FULL_PATH = 0
		OPCIONES.SOUND_ON = 0
		OPCIONES.SOUND_VOLUME = 65
		set_volume()
		OPCIONES.SCREENSHOT_BACK_ON = 0
		OPCIONES.SCREENSHOT_BACK_TR = 128
		if doesFileExist("System/Defaults/PAL") then
			OPCIONES.VIDEO_MODE = 1
		else
			OPCIONES.VIDEO_MODE = 0
		end
		OPCIONES.VIBRATION_ON = 0
		OPCIONES.VIBRATION = false
		OPCIONES.VIBRATION_MODE = nil
		SISTEMAS.PLAYSTATION2_ON = 1
		OPCIONES.DIR_EXTRAS_ON = 1
		CAMBIOS_EMUS.TRAS = 74
		OPCIONES.LIBERAR_LISTAS = 0
		OPCIONES.FONT_PIXEL_X = 16
		OPCIONES.FONT_PIXEL_Y = 16
		OPCIONES.FONT_SHADOW = 5
		OPCIONES.SCROLL_MIN = 24
		OPCIONES.SPRITE_ON = 0
		OPCIONES.SEE_INDEX = 0
		OPCIONES.COLOR_LISTA_B = 74
		SPRITES.FONDO_N_COLUMNS = 4
		SPRITES.FONDO_N_ROWS = 4
		OPCIONES.RUN_DEFAULT = 0
		COLOR.CC_BACK = {0, 0, 0, 85}
		COLOR.NEGRO_T = Color.new(COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4])
		guardar_opciones()
	end
	local function list_default_config()
		LISTAS.IDENTIDAD = 1
		if OPCIONES.LIBERAR_LISTAS == 1 then
			PRE_CARGADAS = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
			recargar_una(LISTAS.IDENTIDAD)
		end
		LISTAS.ROMS = nil
		LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
		LISTAS.INDICE = 1
		indices_extras()
		LAST_MOVE = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		guardar()
	end
	local function activ_opt(resultado, valor, maxi, mini)
		if valor <= maxi and valor >= mini then
			resultado = valor
		end
		return resultado
	end

	-- Cargar opciones guardadas. -------------------------------------------------------
	local actual = System.currentDirectory()
	CARGA_PASO("reading System/Config/System.cfg")
	pantalla_reiniciar_conf(LISTAS.FONDO, 20, false, 21)
	if doesFileExist(actual .."/System/Config/System.cfg") then
		local carga_de_config2 = System.openFile(actual .."/System/Config/System.cfg", FREAD)
		System.seekFile(carga_de_config2, 0, SET)
		local size_config2 = System.sizeFile(carga_de_config2)
		local temp2 = System.readFile(carga_de_config2, size_config2)
		System.closeFile(carga_de_config2)
		local lista_config2 = {}
		lista_config2 = sub_string(temp2, "%d+", lista_config2, true)
		if #lista_config2 == 43 then
			table.insert(lista_config2, 128)
			table.insert(lista_config2, 0)
			table.insert(lista_config2, 0)
			table.insert(lista_config2, 0)
			table.insert(lista_config2, 0)
			table.insert(lista_config2, 85)
		end
		if lista_config2 ~= nil and #lista_config2 == 49 then
			pantalla_reiniciar_conf(LISTAS.FONDO, 34, false, 21)
			OPCIONES.RGB_ON = activ_opt(OPCIONES.RGB_ON, lista_config2[1], 1, 0)
			OPCIONES.FONDO_RGB_ON = activ_opt(OPCIONES.FONDO_RGB_ON, lista_config2[2], 1, 0)
			OPCIONES.FONDO_RGB_FIJO_ON = activ_opt(OPCIONES.FONDO_RGB_FIJO_ON, lista_config2[3], 1, 0)
			OPCIONES.R = activ_opt(OPCIONES.R, lista_config2[4], 128, 0)
			OPCIONES.G = activ_opt(OPCIONES.G, lista_config2[5], 128, 0)
			OPCIONES.B = activ_opt(OPCIONES.B, lista_config2[6], 128, 0)
			CONTROL.ESTILO = activ_opt(CONTROL.ESTILO, lista_config2[7], 7, 1)
			definir_estilos()
			SISTEMAS.MEGADRIVE_ON = activ_opt(SISTEMAS.MEGADRIVE_ON, lista_config2[8], 1, 0)
			SISTEMAS.MASTERSYSTEM_ON = activ_opt(SISTEMAS.MASTERSYSTEM_ON, lista_config2[9], 1, 0)
			SISTEMAS.GAMEGEAR_ON = activ_opt(SISTEMAS.GAMEGEAR_ON, lista_config2[10], 1, 0)
			SISTEMAS.FAMICOM_ON = activ_opt(SISTEMAS.FAMICOM_ON, lista_config2[11], 1, 0)
			SISTEMAS.GAMEBOY_ON = activ_opt(SISTEMAS.GAMEBOY_ON, lista_config2[12], 1, 0)
			SISTEMAS.GAMEBOYCOLOR_ON = activ_opt(SISTEMAS.GAMEBOYCOLOR_ON, lista_config2[13], 1, 0)
			SISTEMAS.GAMEBOYADVANCE_ON = activ_opt(SISTEMAS.GAMEBOYADVANCE_ON, lista_config2[14], 1, 0)
			SISTEMAS.ATARI2600_ON = activ_opt(SISTEMAS.ATARI2600_ON, lista_config2[15], 1, 0)
			SISTEMAS.ATARILYNX_ON = activ_opt(SISTEMAS.ATARILYNX_ON, lista_config2[16], 1, 0)
			SISTEMAS.SEGASG1000_ON = activ_opt(SISTEMAS.SEGASG1000_ON, lista_config2[17], 1, 0)
			SISTEMAS.NEOGEOPOCKET_ON = activ_opt(SISTEMAS.NEOGEOPOCKET_ON, lista_config2[18], 1, 0)
			SISTEMAS.SUPERFAMICOM_ON = activ_opt(SISTEMAS.SUPERFAMICOM_ON, lista_config2[19], 1, 0)
			SISTEMAS.APPS_ON = activ_opt(SISTEMAS.APPS_ON, lista_config2[20], 1, 0)
			SISTEMAS.PLAYSTATION_ON = activ_opt(SISTEMAS.PLAYSTATION_ON, lista_config2[21], 1, 0)
			if lista_config2[22] ~= 1 and lista_config2[22] >= 2 then
				buscar_fuentes()
				if lista_config2[22] <= #OPCIONES.FUENTES_ENCONTRADAS then
					Font.ftUnload(CONTROL.fontARCA)
					Font.ftUnload(CONTROL.fontABC)
					CONTROL.fontARCA = Font.ftLoad(OPCIONES.FUENTES_ENCONTRADAS[lista_config2[22]])
					CONTROL.fontABC = Font.ftLoad(OPCIONES.FUENTES_ENCONTRADAS[lista_config2[22]])
					OPCIONES.CAMBIO_FUENTE_ON = lista_config2[22]
				else
					OPCIONES.CAMBIO_FUENTE_ON = 1
					OPCIONES.FUENTES_ENCONTRADAS = {}
				end
			end
			if lista_config2[23] ~= 1 and lista_config2[23] >= 2 then
				buscar_fondos(true, lista_config2[23])
			end
			OPCIONES.GUI_LIMPIA_ON = activ_opt(OPCIONES.GUI_LIMPIA_ON, lista_config2[24], 1, 0)
			OPCIONES.LIMITADOR_RAM_ON = activ_opt(OPCIONES.LIMITADOR_RAM_ON, lista_config2[25], 1, 0)
			if lista_config2[26] <= 3 and lista_config2[26] >= 0 then
				if lista_config2[26] >= 1 and cargar_directorio_elf(false) == true then
					OPCIONES.SALIDA_RETROLANCHER_ON = lista_config2[26]
				else
					OPCIONES.SALIDA_RETROLANCHER_ON = 0
				end
			end
			OPCIONES.APPS_MENU_FULL_PATH = activ_opt(OPCIONES.APPS_MENU_FULL_PATH, lista_config2[27], 1, 0)
			OPCIONES.SOUND_ON = activ_opt(OPCIONES.SOUND_ON, lista_config2[28], 1, 0)
			OPCIONES.SOUND_VOLUME = activ_opt(OPCIONES.SOUND_VOLUME, lista_config2[29], 100, 0)
			set_volume()
			OPCIONES.SCREENSHOT_BACK_ON = activ_opt(OPCIONES.SCREENSHOT_BACK_ON, lista_config2[30], 1, 0)
			if lista_config2[31] <= 1 and lista_config2[31] >= 0 then
				OPCIONES.VIDEO_MODE = lista_config2[31]
				if OPCIONES.VIDEO_MODE == 0 and doesFileExist("System/Defaults/PAL") then
					Screen.setMode(NTSC, 640, 448, CT24, INTERLACED, FIELD)
					System.rename("System/Defaults/PAL", "System/Defaults/NTSC")
				elseif OPCIONES.VIDEO_MODE == 1 and doesFileExist("System/Defaults/NTSC") then
					Screen.setMode(PAL, 640, 512, CT24, INTERLACED, FIELD)
					System.rename("System/Defaults/NTSC", "System/Defaults/PAL")
					CONTROL.ALTO_F = 512
					CONTROL.ALTO = 544
					CONTROL.Y_FIX_PAL = 32
				elseif OPCIONES.VIDEO_MODE == 1 then
					CONTROL.ALTO_F = 512
					CONTROL.ALTO = 544
					CONTROL.Y_FIX_PAL = 32
				else
					CONTROL.ALTO_F = 448
					CONTROL.Y_FIX_PAL = 0
				end
				CONTROL.LISTA_ALTO = CONTROL.LISTA_ALTO + CONTROL.Y_FIX_PAL
				CONTROL.IMG_ALTO = CONTROL.IMG_ALTO + CONTROL.Y_FIX_PAL
				CONTROL.LOGO_ALTO = CONTROL.LOGO_ALTO + CONTROL.Y_FIX_PAL
				CONTROL.IMG_ALTO_2 = CONTROL.IMG_ALTO_2 + CONTROL.Y_FIX_PAL
				CONTROL.FLOW_ALTO = CONTROL.FLOW_ALTO + CONTROL.Y_FIX_PAL
				CONTROL.FLOW_ALTO_2 = CONTROL.FLOW_ALTO_2 + CONTROL.Y_FIX_PAL
				CONTROL.SPRITE_ALTO = CONTROL.SPRITE_ALTO + CONTROL.Y_FIX_PAL
			end
			OPCIONES.VIBRATION_ON = activ_opt(OPCIONES.VIBRATION_ON, lista_config2[32], 1, 0)
			OPCIONES.VIBRATION = false
			OPCIONES.VIBRATION_MODE = nil
			SISTEMAS.PLAYSTATION2_ON = activ_opt(SISTEMAS.PLAYSTATION2_ON, lista_config2[33], 1, 0)
			OPCIONES.DIR_EXTRAS_ON = activ_opt(OPCIONES.DIR_EXTRAS_ON, lista_config2[34], 1, 0)
			CAMBIOS_EMUS.TRAS = activ_opt(CAMBIOS_EMUS.TRAS, lista_config2[35], 128, 0)
			OPCIONES.LIBERAR_LISTAS = activ_opt(OPCIONES.LIBERAR_LISTAS, lista_config2[36], 1, 0)
			OPCIONES.FONT_PIXEL_X = activ_opt(OPCIONES.FONT_PIXEL_X, lista_config2[37], 32, 1)
			OPCIONES.FONT_PIXEL_Y = activ_opt(OPCIONES.FONT_PIXEL_Y, lista_config2[38], 32, 1)
			OPCIONES.FONT_SHADOW = activ_opt(OPCIONES.FONT_SHADOW, lista_config2[39], 32, 0)
			OPCIONES.SCROLL_MIN = activ_opt(OPCIONES.SCROLL_MIN, lista_config2[40], 100, 10)
			if lista_config2[41] <= 1 and lista_config2[41] >= 0 then
				OPCIONES.SPRITE_ON = lista_config2[41]
				if OPCIONES.SPRITE_ON == 1 and CONTROL.ESTILO ~= 7 then
					CONTROL.CUSTOM_SPRITE = true
				end
			end
			OPCIONES.SEE_INDEX = activ_opt(OPCIONES.SEE_INDEX, lista_config2[42], 1, 0)
			OPCIONES.COLOR_LISTA_B = activ_opt(OPCIONES.COLOR_LISTA_B, lista_config2[43], 128, 50)
			if OPCIONES.SCREENSHOT_BACK_ON == 1 then
				OPCIONES.SCREENSHOT_BACK_TR = activ_opt(OPCIONES.SCREENSHOT_BACK_TR, lista_config2[44], 128, 1)
			elseif OPCIONES.SCREENSHOT_BACK_ON == 0 then
				OPCIONES.SCREENSHOT_BACK_TR = 128
			end
			OPCIONES.RUN_DEFAULT = activ_opt(OPCIONES.RUN_DEFAULT, lista_config2[45], 1, 0)
			COLOR.CC_BACK[1] = activ_opt(COLOR.CC_BACK[1], lista_config2[46], 128, 0)
			COLOR.CC_BACK[2] = activ_opt(COLOR.CC_BACK[2], lista_config2[47], 128, 0)
			COLOR.CC_BACK[3] = activ_opt(COLOR.CC_BACK[3], lista_config2[48], 128, 0)
			COLOR.CC_BACK[4] = activ_opt(COLOR.CC_BACK[4], lista_config2[49], 128, 0)
			COLOR.NEGRO_T = Color.new(COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4])
		else
			default_config()
		end
	else
		default_config()
	end
	CARGA_PASO("locating OPL")
	cargar_directorio_elf(true)
	pantalla_reiniciar_conf(LISTAS.FONDO, 44, false, 21)
	CARGA_PASO("checking RetroArch availability")
	-- Antes de recargar_todas, que es quien recorre los quince sistemas: si no hay
	-- forma de arrancar un core, los doce libretro se apagan y ni se rastrean.
	LIBRETRO_APAGAR_SI_IMPOSIBLE()
	if LIBRETRO_SISTEMAS_OFF == true then
		CARGA_PASO("libretro OFF: ".. tostring(LIBRETRO_SISTEMAS_MOTIVO))
	end
	CARGA_PASO("building game lists")
	recargar_todas()
	CARGA_PASO("game lists built")
	pantalla_reiniciar_conf(LISTAS.FONDO, 64, false, 21)

	-- Cargar último juego y sistema usado. ---------------------------------------------
	if doesFileExist(actual .."/System/Config/Config.cfg") then
		local carga_de_config = System.openFile(actual .."/System/Config/Config.cfg", FREAD)
		System.seekFile(carga_de_config, 0, SET)
		local size_config = System.sizeFile(carga_de_config)
		local temp = System.readFile(carga_de_config, size_config)
		System.closeFile(carga_de_config)
		local lista_config = {}
		lista_config = sub_string(temp, "%d+", lista_config, true)
		if lista_config ~= nil and #lista_config == 17 then
			LISTAS.IDENTIDAD = lista_config[1]
			if OPCIONES.LIBERAR_LISTAS == 1 then
				PRE_CARGADAS = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
				recargar_una(LISTAS.IDENTIDAD)
			end
			LISTAS.ROMS = nil
			LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
			if lista_config[2] <= #LISTAS.ROMS then
				LISTAS.INDICE = lista_config[2]
				indices_extras()
			else
				LISTAS.INDICE = 1
				indices_extras()
			end
			LAST_MOVE = {lista_config[3]; lista_config[4]; lista_config[5]; lista_config[6]; lista_config[7]; lista_config[8]; lista_config[9];
			lista_config[10]; lista_config[11]; lista_config[12]; lista_config[13]; lista_config[14]; lista_config[15]; lista_config[16]; lista_config[17];};
		else
			list_default_config()
		end
	else
		list_default_config()
	end
	pantalla_reiniciar_conf(LISTAS.FONDO, 74, false, 21)
	CARGA_PASO("applying settings")
	-- El interruptor del numero de orden manda sobre lo que diga System.cfg.
	local si = SEE_INDEX_LEER()
	if si ~= nil then OPCIONES.SEE_INDEX = si end
	desactivados(nil)
	indices_extras()
	color_emu(LISTAS.IDENTIDAD, OPCIONES.FONDO_RGB_ON, OPCIONES.FONDO_RGB_FIJO_ON)
	Font.ftSetPixelSize(CONTROL.fontARCA, OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y)
	Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
	CARGA_PASO("loading animations")
	animaciones(nil, false)
	CARGA_PASO("configuration loaded")
end

--- Identidad de cada sistema a partir de su nombre. ------------------------------------
--- Sirve para llegar a ES_ALIAS, que lista TODOS los nombres de carpeta aceptados para
--- ese sistema: "megadrive", pero tambien "genesis" y "md". RetroArch agrupa las
--- partidas por la carpeta del contenido, asi que un juego que este en "Roms/genesis"
--- guarda en "Saves/genesis": hay que barrer todos los alias, no solo el canonico.
--- Antes se agrupaba por core, y limpiar la Megadrive borraba tambien Master System,
--- Game Gear y SG-1000, que comparten PicoDrive. Por carpeta el reparto es exacto.
IDENTIDAD_DE_SISTEMA = {
	["Sega Megadrive"] = 1,  ["Sega Master System"] = 2,  ["Sega Game Gear"] = 3,
	["Nintendo Famicom"] = 4, ["Nintendo Game Boy"] = 5,  ["Nintendo Game Boy Color"] = 6,
	["Nintendo Game Boy Advance"] = 7, ["Atari 2600"] = 8, ["Atari Lynx"] = 9,
	["Sega SG-1000"] = 10,   ["Neo Geo Pocket"] = 11,     ["Nintendo Super Famicom"] = 12,
}

--- Borra los ficheros de un directorio, sin tocar los subdirectorios. -----------------
function BORRAR_FICHEROS(ruta)
	local lista = System.listDirectory(ruta)
	if lista == nil then return end
	for i = 1, #lista do
		if lista[i].directory == false then
			System.removeFile(ruta .."/".. lista[i].name)
		end
	end
end

--- Elimina "Save states" y "Save RAM" (SRM) creados por RetroArch. --------------------
--- Viven en "Saves/<consola>/" y "SaveStates/<consola>/", en la raiz del lanzador.
--- Con "emulador" a nil se barre todo, incluida la raiz de cada uno, que es donde caen
--- las partidas si el usuario desactiva la ordenacion.
function limpiar_retroarch(emulador)
	local actual = System.currentDirectory()
	local carpetas = {"Saves", "SaveStates"}
	local consolas = nil
	if emulador ~= nil then
		local id = IDENTIDAD_DE_SISTEMA[emulador]
		if id ~= nil and ES_ALIAS ~= nil then consolas = ES_ALIAS[id] end
	end
	for c = 1, #carpetas do
		local raiz = actual .."/".. carpetas[c]
		if consolas ~= nil then
			for n = 1, #consolas do
				BORRAR_FICHEROS(raiz .."/".. consolas[n])
			end
		else
			BORRAR_FICHEROS(raiz)
			local lista = System.listDirectory(raiz)
			if lista ~= nil then
				for i = 1, #lista do
					local nom = lista[i].name
					if lista[i].directory == true and nom ~= "." and nom ~= ".." then
						BORRAR_FICHEROS(raiz .."/".. nom)
					end
				end
			end
		end
	end
end

--- Crea los directorios que RetroArch espera encontrar. -------------------------------
--- Todo cuelga de "LibretroPS2Files/retroarch/". "emulador" ya no interviene: la
--- configuracion es unica y RetroArch separa por core, no por sistema.
--- "System.createDirectory" no crea los padres, de ahi el orden de la lista.
function directorios_faltantes(emulador, core)
	local base = RUTA_LIBRETRO()
	if base == nil then return end
	local necesarios = {
		"/retroarch",
		"/retroarch/config",
		"/retroarch/config/remaps",
		"/retroarch/savefiles",
		"/retroarch/savestates",
		"/retroarch/system",
		"/retroarch/logs",
		"/retroarch/temp",
	}
	if core ~= nil and core ~= " " and core ~= "" then
		necesarios[#necesarios + 1] = "/retroarch/config/".. core
		necesarios[#necesarios + 1] = "/retroarch/config/remaps/".. core
	end
	for i = 1, #necesarios do
		if System.listDirectory(base .. necesarios[i]) == nil then
			System.createDirectory(base .. necesarios[i])
		end
	end
end


--- Reinicia la configuracion de RetroArch. -------------------------------------------
--- No hay copia de fabrica que restaurar, y es deliberado: la unica configuracion es
--- "retroarch/retroarch.cfg". Reiniciar es entonces BORRARLO, junto con los ajustes por
--- core. RetroArch se reescribe uno entero con sus propios valores la primera vez que
--- guarda, y FORZAR_CONF_RETROARCH vuelve a imponer encima las claves del lanzador --
--- carpetas, tri de partidas, modo de video -- al lanzar el siguiente juego.
---
--- Lo que se pierde son los ajustes por core que traia el proyecto (relacion de
--- aspecto de la Game Gear, configuracion vertical de la Lynx...). Es el precio de no
--- mantener dos ficheros con el mismo papel, que acaban siempre por no coincidir.
--- "pal" se conserva en la firma por compatibilidad con las llamadas existentes.
function restaurar_conf_retroarch(pal)
	local base = RUTA_LIBRETRO()
	if base == nil then
		boot_log("CONF   LibretroPS2Files no encontrado, nada que reiniciar")
		return false
	end

	local cfg = base .."/retroarch/retroarch.cfg"
	if doesFileExist(cfg) then
		pcall(System.removeFile, cfg)
		boot_log("CONF   borrado ".. cfg .." : RetroArch lo rehara")
	end
	BORRAR_ARBOL(base .."/retroarch/config")

	-- Las carpetas si se recrean: RetroArch no crea las que le faltan, se limita a no
	-- escribir en ellas.
	directorios_faltantes(nil, nil)
	boot_escribir()
	return true
end

--- Preparacion de RetroArch en la llave, EN EL MOMENTO DE LANZAR. --------------------
--- Un core oficial no sabe leer el disco interno: al arrancar hace SifIopReset, el IOP
--- se vacia y ese disco deja de existir para el. Su instalacion tiene que estar en un
--- soporte que sobreviva al reset.
---
--- Copiarla entera al arrancar el lanzador era mala idea: 75 MB, y aunque se hiciera
--- de fondo el menu se arrastraba. Y sobre todo era trabajo hecho por adelantado para
--- juegos que quiza no se lanzan nunca.
---
--- Aqui se hace al pulsar sobre un juego, y solo lo que ESE juego necesita: su core,
--- su ".info", y la configuracion. Un megabyte y medio, una vez por core. La segunda
--- vez que se lanza un juego de esa consola ya no hay nada que copiar.
LIBRETRO_AUTO_USB = true
COPIA_TITULO = "Preparing RetroArch on the USB stick"
COPIA_HECHOS = 0
COPIA_TOTAL = 0

--- "fceumm_libretro_ps2.elf" -> "fceumm_libretro.info" -------------------------------
--- El ".info" declara las extensiones que acepta el core, que es lo que decide si se
--- ofrece para un sistema. Sin el, el selector de core se queda vacio.
function CORE_A_INFO(nombre)
	if nombre == nil then return nil end
	if string.len(nombre) < 9 or string.sub(nombre, -8) ~= "_ps2.elf" then return nil end
	return string.sub(nombre, 1, -9) ..".info"
end

--- Pantalla de progreso: fondo negro, letras blancas. -------------------------------
function LIBRETRO_PANTALLA(titulo, linea, hechos, total)
	Screen.clear(COLOR.NEGRO)
	Font.ftPrint(CONTROL.fontARCA, 320, 170 + CONTROL.Y_FIX_PAL, 8, 600, 25, titulo, COLOR.BLANCO)
	Font.ftPrint(CONTROL.fontARCA, 320, 210 + CONTROL.Y_FIX_PAL, 8, 600, 25, linea, COLOR.BLANCO)
	if total ~= nil and total > 0 then
		Font.ftPrint(CONTROL.fontARCA, 320, 260 + CONTROL.Y_FIX_PAL, 8, 600, 25,
			tostring((hechos * 100) // total) .." %    ".. tostring(hechos) .." / ".. tostring(total), COLOR.BLANCO)
	end
	Screen.flip()
end

--- Un paso del lanzamiento: a la pantalla y al log. ----------------------------------
--- Los pasos previos al arranque de un core -- buscar el core, elegirlo, comprobarlo en
--- la llave, copiarlo -- eran mudos, y cuando uno fallaba lo unico que se veia era
--- "Games or RetroArch not found". Que no dice cual de los cuatro ha fallado.
LANZA_LINEAS = {}
LANZA_VERDE = {}
LANZA_VERDE_COL = nil

--- Repinta la pantalla de lanzamiento, CENTRADA. --------------------------------------
--- Estaba alineada a la izquierda, en x=60 y despues en x=90, y una tele recorta ese
--- borde: se perdia el principio de cada linea. Centrada -- x=320, que es lo que hace
--- LIBRETRO_PANTALLA -- no depende de cuanto recorte la pantalla, y las lineas son
--- cortas de todas formas.
function LANZA_PINTAR()
	if LANZA_VERDE_COL == nil then LANZA_VERDE_COL = Color.new(0, 128, 45) end
	pcall(function()
		for pasada = 1, 2 do
			Screen.clear(COLOR.NEGRO)
			local y = 120 + CONTROL.Y_FIX_PAL
			for i = 1, #LANZA_LINEAS do
				local col = COLOR.BLANCO
				if LANZA_VERDE[i] == true then col = LANZA_VERDE_COL end
				Font.ftPrint(CONTROL.fontARCA, 320, y, 8, 600, 22, LANZA_LINEAS[i], col)
				y = y + 26
			end
			if pasada == 1 then Screen.flip() end
		end
	end)
end

--- Un paso. "verde" para lo que ya estaba en su sitio y no hay que copiar. ------------
function LANZA_PASO(texto, verde)
	LANZA_LINEAS[#LANZA_LINEAS + 1] = tostring(texto)
	LANZA_VERDE[#LANZA_LINEAS] = (verde == true)
	while #LANZA_LINEAS > 8 do
		table.remove(LANZA_LINEAS, 1)
		table.remove(LANZA_VERDE, 1)
	end
	boot_log("LANZA  ".. tostring(texto))
	boot_escribir()
	LANZA_PINTAR()
end

--- Sustituye la ultima linea en vez de anadir una. Para el progreso de una copia, que
--- si no llenaria la pantalla y el journal con una linea por cada 256 KB.
function LANZA_REEMPLAZAR(texto)
	if #LANZA_LINEAS == 0 then return LANZA_PASO(texto) end
	LANZA_LINEAS[#LANZA_LINEAS] = tostring(texto)
	LANZA_VERDE[#LANZA_LINEAS] = false
	LANZA_PINTAR()
end

--- El gancho que llama COPIAR_CON_PROGRESO entre trozo y trozo. -----------------------
function COPIA_PROGRESO(etiqueta, hechos, total)
	LANZA_REEMPLAZAR("Copying ".. tostring(etiqueta) .."  "
		.. tostring(hechos // 1024) .." / ".. tostring(total // 1024) .." KB")
end

--- Copia un fichero si falta o si no coincide el tamano. Devuelve true si copio. -----
function COPIA_SI_HACE_FALTA(origen, destino, etiqueta)
	if doesFileExist(origen) == false then return false end
	local a = ROM_TAMANO(origen)
	if doesFileExist(destino) then
		local b = ROM_TAMANO(destino)
		if a ~= nil and a == b then return false end
	end
	COPIA_HECHOS = COPIA_HECHOS + 1
	LIBRETRO_PANTALLA(COPIA_TITULO, etiqueta, COPIA_HECHOS, COPIA_TOTAL)
	pcall(System.copyFile, origen, destino)
	return true
end


--- Deja listo en la llave lo que hace falta para lanzar ESTE core. -------------------
--- Devuelve la carpeta que hay que usar, o nil si no se ha podido preparar nada.
function LIBRETRO_PREPARAR_PARA(nombre_core)
	LIBRETRO_FORZADO = nil
	if LIBRETRO_AUTO_USB ~= true then return RUTA_LIBRETRO() end
	-- El ORIGEN de la copia es la maestra: es la unica que tiene el core que se pide.
	-- Con RUTA_LIBRETRO aqui, en cuanto existia una copia en la llave se copiaba desde
	-- ella hacia ella misma, y el core que faltaba seguia faltando.
	local casa = RUTA_LIBRETRO_MAESTRA()
	if casa == nil then return nil end
	-- Ya esta donde el core sabra leerla: nada que preparar.
	if ES_RAIZ_ATA(casa) == false then return casa end

	-- Destino: una llave USB. La tarjeta de memoria no sirve, son 8 MB.
	local destinos = ROM_DESTINOS()
	local dev = nil
	for i = 1, #destinos do
		if dev == nil and string.lower(string.sub(destinos[i], 1, 4)) == "mass" then
			dev = destinos[i]
		end
	end
	if dev == nil then
		boot_log("RETROARCH  sin llave USB: este juego no puede arrancar.")
		boot_escribir()
		LIBRETRO_PANTALLA(COPIA_TITULO, "No USB stick: this game cannot start", 0, nil)
		System.sleep(3)
		return nil
	end

	-- En "<llave>/RETROLauncher/LibretroPS2Files", el mismo sitio que en el disco.
	-- Estuvo bajo "TempUSB/" para que RUTA_LIBRETRO no la eligiera como instalacion
	-- maestra -- solo lleva un core -- pero eso ya lo resuelve RUTA_LIBRETRO_MAESTRA,
	-- que reconoce la maestra por estar junto al lanzador.
	local destino = dev .."/".. CARPETA_LANZADOR .."/LibretroPS2Files"

	COPIA_HECHOS = 0
	COPIA_TOTAL = 0

	CREAR_CADENA(dev, CARPETA_LANZADOR .."/LibretroPS2Files")
	CREAR_CADENA(destino, "cores")
	CREAR_CADENA(destino, "info")

	-- TODAS las carpetas que la configuracion nombra. Se crean SIEMPRE y ANTES que
	-- nada, y se comprueba que existan de verdad.
	--
	-- Aqui estuvo la pantalla negra, y es culpa mia. Al quitar la copia del arbol de
	-- "retroarch/" deje la llave con "retroarch.cfg" y "config/" y nada mas. RetroArch
	-- ABRE los ficheros de sus carpetas pero NO crea las carpetas: sin "temp/" -- que
	-- es "cache_directory" -- no puede descomprimir el .zip de la ROM, y muere sin
	-- dibujar. Sin "logs/" tampoco escribe su propio log, que es exactamente por lo
	-- que la carpeta de logs estaba vacia y no habia nada que leer.
	-- Crear un directorio es gratis; no crearlo cuesta un arranque entero.
	local esqueleto = {"retroarch", "retroarch/config", "retroarch/config/remaps",
		"retroarch/system", "retroarch/logs", "retroarch/temp",
		"retroarch/savefiles", "retroarch/savestates", "retroarch/assets",
		"retroarch/cheats", "retroarch/database", "retroarch/database/rdb",
		"retroarch/downloads", "retroarch/overlays", "retroarch/thumbnails",
		"retroarch/playlists", "retroarch/playlists/builtin"}
	local faltan = ""
	for i = 1, #esqueleto do
		CREAR_CADENA(destino, esqueleto[i])
		if System.listDirectory(destino .."/".. esqueleto[i]) == nil then
			faltan = faltan .." ".. esqueleto[i]
		end
	end
	if faltan ~= "" then
		boot_log("RETROARCH  NO se han podido crear:".. faltan)
		boot_escribir()
		LANZA_PASO("Cannot create folders on USB")
	end

	-- "retroarch.cfg" se MACHACA, sin mirar si coincide. RetroArch reescribe el suyo
	-- cada vez que sale, en la llave: sin esto la copia de la llave se aleja del
	-- fichero del proyecto en cuanto se toca un ajuste desde el menu del core, y lo
	-- que se edita en el PC no llega nunca. El disco manda.
	LANZA_PASO("Writing retroarch.cfg")
	if doesFileExist(casa .."/retroarch/retroarch.cfg") then
		pcall(System.copyFile, casa .."/retroarch/retroarch.cfg",
		      destino .."/retroarch/retroarch.cfg")
	end
	-- Los ajustes por core, por la misma razon. Son una docena de ficheros de texto.
	COPIAR_ARBOL(casa .."/retroarch/config", destino .."/retroarch/config", 0)

	-- "raboot.elf" tambien. El lanzador no lo usa -- llama al core directamente -- pero
	-- con el en la llave, RetroArch se puede abrir desde uLaunchELF sin pasar por
	-- RETROLauncher, que es como se comprueba una instalacion cuando algo va mal.
	-- Son 300 KB y se copia una sola vez.
	if doesFileExist(casa .."/raboot.elf") and doesFileExist(destino .."/raboot.elf") == false then
		COPIAR_CON_PROGRESO(casa .."/raboot.elf", destino .."/raboot.elf", "raboot.elf")
	end

	-- El core del juego y su ".info", nada mas.
	COPIA_TOTAL = 2
	local core_origen = casa .."/cores/".. nombre_core
	local core_destino = destino .."/cores/".. nombre_core
	local ya_esta = (doesFileExist(core_destino)
		and ROM_TAMANO(core_destino) ~= nil
		and ROM_TAMANO(core_destino) == ROM_TAMANO(core_origen))
	if ya_esta == true then
		LANZA_PASO("Core already on USB", true)
	else
		LANZA_PASO("Copying core")
		COPIAR_CON_PROGRESO(core_origen, core_destino, "core")
	end
	local info = CORE_A_INFO(nombre_core)
	if info ~= nil then
		COPIA_SI_HACE_FALTA(casa .."/info/".. info, destino .."/info/".. info, info)
	end

	if doesFileExist(destino .."/cores/".. nombre_core) == false then
		boot_log("RETROARCH  no se ha podido poner ".. nombre_core .." en ".. destino)
		boot_escribir()
		LIBRETRO_PANTALLA(COPIA_TITULO, "Could not copy ".. nombre_core, 0, nil)
		System.sleep(3)
		return nil
	end

	if COPIA_HECHOS > 0 then
		boot_log("RETROARCH  ".. tostring(COPIA_HECHOS) .." fichero(s) preparados en ".. destino)
		boot_escribir()
	end
	-- A partir de aqui, TODO -- config, BIOS, partidas -- apunta a la llave.
	LIBRETRO_FORZADO = destino
	return destino
end

--- Reinicia todas las configuraciones. -------------------------------------------------
function reiniciar_conf(limpiar, indi_rest)
	Pads.rumble(0, 0, 0)
	local actual = System.currentDirectory()
	local FONDO_LOAD = Graphics.loadImage(verif_img("System/Medias/Default/FONDO.png"))
	pantalla_reiniciar_conf(FONDO_LOAD, 0, limpiar, indi_rest)
	local dir_mode_video = "NTSC"
	if OPCIONES.VIDEO_MODE ~= 0 then
		dir_mode_video = "PAL"
	end
	if indi_rest == 0 or indi_rest == 20 then
		if OPCIONES.VIDEO_MODE == 0 and doesFileExist("System/Defaults/PAL") then
			System.rename("System/Defaults/PAL", "System/Defaults/NTSC")
		elseif OPCIONES.VIDEO_MODE == 1 and doesFileExist("System/Defaults/NTSC") then
			System.rename("System/Defaults/NTSC", "System/Defaults/PAL")
		end
	end
	if indi_rest == 0 then
		OPCIONES.RGB_ON = 1
		OPCIONES.FONDO_RGB_ON = 1
		OPCIONES.FONDO_RGB_FIJO_ON = 0
		OPCIONES.R = 0
		OPCIONES.G = 80
		OPCIONES.B = 120
		CONTROL.ESTILO = 1
		definir_estilos()
		SISTEMAS.MEGADRIVE_ON = 1
		SISTEMAS.MASTERSYSTEM_ON = 1
		SISTEMAS.GAMEGEAR_ON = 1
		SISTEMAS.FAMICOM_ON = 1
		SISTEMAS.GAMEBOY_ON = 1
		SISTEMAS.GAMEBOYCOLOR_ON = 1
		SISTEMAS.GAMEBOYADVANCE_ON = 1
		SISTEMAS.ATARI2600_ON = 1
		SISTEMAS.ATARILYNX_ON = 1
		SISTEMAS.SEGASG1000_ON = 1
		SISTEMAS.NEOGEOPOCKET_ON = 1
		SISTEMAS.SUPERFAMICOM_ON = 0
		SISTEMAS.APPS_ON = 1
		SISTEMAS.PLAYSTATION_ON = 1
		Font.ftUnload(CONTROL.fontARCA)
		Font.ftUnload(CONTROL.fontABC)
		CONTROL.fontARCA = Font.ftLoad("System/Medias/Font/PublicPixel.ttf")
		CONTROL.fontABC = Font.ftLoad("System/Medias/Font/PublicPixel.ttf")
		OPCIONES.CAMBIO_FUENTE_ON = 1
		Graphics.freeImage(LISTAS.FONDO)
		LISTAS.FONDO = Graphics.loadImage(verif_img("System/Medias/Default/FONDO.png"))
		SPRITES.FONDO_ANI = false
		SPRITES.FONDO_N_COLUMNS = 4
		SPRITES.FONDO_N_ROWS = 4
		SPRITES.LAYER = false
		SPRITES.LAYER_TYPE = 1
		OPCIONES.CAMBIO_FONDO_ON = 1
		OPCIONES.GUI_LIMPIA_ON = 0
		OPCIONES.LIMITADOR_RAM_ON = 0
		OPCIONES.SALIDA_RETROLANCHER_ON = 0
		OPCIONES.SALIDA_RETROLANCHER = "PS2 SYSTEM MENU"
		OPCIONES.SALIDA_DIR_ACTUALES = {}
		OPCIONES.SALIDA_DIR_ANTERIORES = {}
		OPCIONES.APPS_MENU_FULL_PATH = 0
		OPCIONES.SOUND_ON = 0
		OPCIONES.SOUND_VOLUME = 65
		set_volume()
		OPCIONES.SCREENSHOT_BACK_ON = 0
		OPCIONES.SCREENSHOT_BACK_TR = 128
		OPCIONES.VIBRATION_ON = 0
		OPCIONES.VIBRATION = false
		OPCIONES.VIBRATION_MODE = nil
		SISTEMAS.PLAYSTATION2_ON = 1
		OPCIONES.DIR_EXTRAS_ON = 1
		CAMBIOS_EMUS.TRAS = 74
		OPCIONES.LIBERAR_LISTAS = 0
		OPCIONES.FONT_PIXEL_X = 16
		OPCIONES.FONT_PIXEL_Y = 16
		OPCIONES.FONT_SHADOW = 5
		OPCIONES.SCROLL_MIN = 24
		OPCIONES.SPRITE_ON = 0
		CONTROL.CUSTOM_SPRITE = false
		OPCIONES.SEE_INDEX = 0
		OPCIONES.COLOR_LISTA_B = 74
		OPCIONES.RUN_DEFAULT = 0
		COLOR.CC_BACK = {0, 0, 0, 85}
		COLOR.NEGRO_T = Color.new(COLOR.CC_BACK[1], COLOR.CC_BACK[2], COLOR.CC_BACK[3], COLOR.CC_BACK[4])
		Font.ftSetPixelSize(CONTROL.fontARCA, OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y)
		Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
		if doesFileExist("System/Medias/Sound/Background/music.adp") then
			System.rename("System/Medias/Sound/Background/music.adp", "System/Medias/Sound/Background/music0.adp")
			Sound.freeADPCM(S_MUSICA)
			S_MUSICA = nil
		end
	end

	-- Limpiar partidas guardadas por RetroArch. ----------------------------------------
	if limpiar == true then
		pantalla_reiniciar_conf(FONDO_LOAD, 5, true, indi_rest)
		if indi_rest == 0 or indi_rest == 1 then
			limpiar_retroarch("Atari 2600")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 10, true, indi_rest)
		if indi_rest == 0 or indi_rest == 2 then
			limpiar_retroarch("Atari Lynx")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 15, true, indi_rest)
		if indi_rest == 0 or indi_rest == 3 then
			limpiar_retroarch("Neo Geo Pocket")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 20, true, indi_rest)
		if indi_rest == 0 or indi_rest == 4 then
			limpiar_retroarch("Nintendo Famicom")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 25, true, indi_rest)
		if indi_rest == 0 or indi_rest == 5 then
			limpiar_retroarch("Nintendo Game Boy")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 30, true, indi_rest)
		if indi_rest == 0 or indi_rest == 6 then
			limpiar_retroarch("Nintendo Game Boy Advance")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 35, true, indi_rest)
		if indi_rest == 0 or indi_rest == 7 then
			limpiar_retroarch("Nintendo Game Boy Color")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 40, true, indi_rest)
		if indi_rest == 0 or indi_rest == 8 then
			limpiar_retroarch("Nintendo Super Famicom")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 45, true, indi_rest)
		if indi_rest == 0 or indi_rest == 9 then
			limpiar_retroarch("Sega Game Gear")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 50, true, indi_rest)
		if indi_rest == 0 or indi_rest == 10 then
			limpiar_retroarch("Sega Master System")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 55, true, indi_rest)
		if indi_rest == 0 or indi_rest == 11 then
			limpiar_retroarch("Sega Megadrive")
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 60, true, indi_rest)
		if indi_rest == 0 or indi_rest == 12 then
			limpiar_retroarch("Sega SG-1000")
		end
		if indi_rest == 0 then
			-- Sin ordenacion por core las partidas caen en la raiz: hay que barrerla.
			limpiar_retroarch(nil)
		end
		pantalla_reiniciar_conf(FONDO_LOAD, 75, true, indi_rest)
	end

	-- Restaura la configuracion de RetroArch. ------------------------------------------
	-- Aqui habia doce bloques casi identicos, uno por sistema, que copiaban doce
	-- "retroarch.cfg" hacia "System/RetroarchPS2/<sistema>/retroarch/". Esos doce
	-- ficheros no se diferenciaban entre si mas que en veinte rutas absolutas
	-- ("mass:/RETROLauncher/...") -- que RetroArch recalcula solo a partir de su propio
	-- directorio, asi que estorbaban en cuanto la carpeta cambiaba de sitio o de
	-- unidad -- y en un punado de claves de video y audio.
	-- Hoy hay un solo "retroarch.cfg", en "LibretroPS2Files/retroarch/", y esas claves
	-- viajan como override de core ("config/<Core>/<Core>.cfg") o de carpeta de
	-- contenido ("config/PicoDrive/gamegear.cfg"), que es el mecanismo previsto por
	-- RetroArch para justamente esto.
	pantalla_reiniciar_conf(FONDO_LOAD, 1, false, indi_rest)
	if indi_rest == 0 or indi_rest == 20 or (indi_rest >= 1 and indi_rest <= 12) then
		restaurar_conf_retroarch(OPCIONES.VIDEO_MODE ~= 0)
	end
	pantalla_reiniciar_conf(FONDO_LOAD, 68, false, indi_rest)


	-- Restaura las configuraciones. ----------------------------------------------------
	pantalla_reiniciar_conf(FONDO_LOAD, 72, false, indi_rest)
	if indi_rest == 0 then
		if doesFileExist(actual .."/System/Defaults/Path_file.cfg") then
			System.copyFile(actual .."/System/Defaults/Path_file.cfg", actual .."/System/Config/Path_file.cfg")
		end
		if doesFileExist(actual .."/System/Defaults/Config.cfg") then
			System.copyFile(actual .."/System/Defaults/Config.cfg", actual .."/System/Config/Config.cfg")
		end
		if doesFileExist(actual .."/System/Defaults/System.cfg") then
			System.copyFile(actual .."/System/Defaults/System.cfg", actual .."/System/Config/System.cfg")
		end
		if doesFileExist(actual .."/System/Defaults/Path_OPL.cfg") then
			System.copyFile(actual .."/System/Defaults/Path_OPL.cfg", actual .."/System/Config/Path_OPL.cfg")
		end
	end

	-- Restaura variables. --------------------------------------------------------------
	pantalla_reiniciar_conf(FONDO_LOAD, 73, false, indi_rest)
	if indi_rest == 0 or indi_rest == 20 then
		guardar_opciones()
		pantalla_reiniciar_conf(FONDO_LOAD, 75, false, indi_rest)
		cargar_config()
		cargar_directorio_elf(false)
		cargar_directorio_elf(true)
	end
	Graphics.freeImage(FONDO_LOAD)
end

--- Carga sprites y define su tamaño. ---------------------------------------------------
function TEML(cargar_img)
	local actual = System.currentDirectory()
	local list_sprites = System.listDirectory(actual .."/System/Medias/Sprites")
	local comparar = {"Megadrive_"; "MasterSystem_"; "GameGear_"; "Famicom_"; "GameBoy_"; "GameBoyColor_"; "GameBoyAdvance_";
	"Atari2600_"; "AtariLynx_"; "SegaSG1000_"; "NeoGeoPocket_"; "SuperFamicom_"; "Apps_"; "PlayStation_"; "PlayStation2_";}
	local final = {"Megadrive_01000_4x4.png"; "MasterSystem_01000_4x4.png"; "GameGear_01000_4x4.png"; "Famicom_01000_4x4.png"; "GameBoy_01000_4x4.png";
	"GameBoyColor_01000_4x4.png"; "GameBoyAdvance_01000_4x4.png"; "Atari2600_01000_4x4.png"; "AtariLynx_01000_4x4.png"; "SegaSG1000_01000_4x4.png";
	"NeoGeoPocket_01000_4x4.png"; "SuperFamicom_01000_4x4.png"; "Apps_01000_4x4.png"; "PlayStation_01000_4x4.png"; "PlayStation2_01000_4x4.png";}
	if list_sprites ~= nil then
		for cont = 1, #comparar do
			local presente = false
			for cont2 = 1, #list_sprites do
				if string.match(string.lower(list_sprites[cont2].name), string.lower(comparar[cont] .."[%w#][%w#][%w#][%w#][%w#].%d.%d%.png")) and not (cont == 4 and string.match(list_sprites[cont2].name, "SuperFamicom_")) then
					SPRITES.MOVE[cont] = cha_res(string.sub(list_sprites[cont2].name, -13, -13), 62)
					SPRITES.SPEED_SPRITE[cont] = cha_res(string.sub(list_sprites[cont2].name, -12, -12), 62)
					SPRITES.TRAN_SPRITE_ON[cont] = cha_res(string.sub(list_sprites[cont2].name, -11, -11), 24)
					SPRITES.SPIN_SPRITE_ON[cont] = cha_res(string.sub(list_sprites[cont2].name, -10, -10), 62)
					SPRITES.AUTO_MOVE_SPRITE[cont] = cha_res(string.sub(list_sprites[cont2].name, -9, -9), 9)
					SPRITES.N_COLUMNS[cont] = tonumber(string.sub(list_sprites[cont2].name, -7, -7))
					SPRITES.N_ROWS[cont] = tonumber(string.sub(list_sprites[cont2].name, -5, -5))
					final[cont] = list_sprites[cont2].name
					presente = true
				end
			end
			if presente == false then
				SPRITES.MOVE[cont] = 0
				SPRITES.SPEED_SPRITE[cont] = 1
				SPRITES.TRAN_SPRITE_ON[cont] = 0
				SPRITES.SPIN_SPRITE_ON[cont] = 0
				SPRITES.AUTO_MOVE_SPRITE[cont] = 0
				SPRITES.N_COLUMNS[cont] = 1
				SPRITES.N_ROWS[cont] = 1
			end
			final[cont] = "System/Medias/Sprites/".. final[cont]
		end
	else
		for cont = 1, #final do final[cont] = "System/Medias/Sprites/".. final[cont] end
	end
	for carga = 1, 15 do
		if cargar_img == true then
			SPRITES[SPRITES.SPRITE_SYS[carga]] = Graphics.loadImage(verif_img(final[carga]))
		end
		SPRITES.WIDTH_X[carga] = (Graphics.getImageWidth(SPRITES[SPRITES.SPRITE_SYS[carga]])/SPRITES.N_COLUMNS[carga])
		SPRITES.HEIGHT_Y[carga] = (Graphics.getImageHeight(SPRITES[SPRITES.SPRITE_SYS[carga]])/SPRITES.N_ROWS[carga])
	end
end

--- Definir las posiciones y configuración de cada estilo. ------------------------------
function definir_estilos()
	if CONTROL.ESTILO == 1 then
		CONTROL.IMG_ANCHO = 358; CONTROL.IMG_X = 250; CONTROL.IMG_ALTO = 92; CONTROL.IMG_Y = 193;
		CONTROL.IMG_ANCHO_2 = 358; CONTROL.IMG_X_2 = 250; CONTROL.IMG_ALTO_2 = 92; CONTROL.IMG_Y_2 = 193;
		CONTROL.LISTA_ANCHO = 30; CONTROL.LISTA_X = 310; CONTROL.LISTA_ALTO = 90; CONTROL.LISTA_Y = 290;
		CONTROL.LOGO_ANCHO = 194; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 358; CONTROL.FLOW_X = 250; CONTROL.FLOW_ALTO = 92; CONTROL.FLOW_Y = 193;
		CONTROL.FLOW_ANCHO_2 = 358; CONTROL.FLOW_X_2 = 250; CONTROL.FLOW_ALTO_2 = 92; CONTROL.FLOW_Y_2 = 193;
		CONTROL.X_BUTTON_X = 388; CONTROL.Y_BUTTON_X = 353; CONTROL.X_BUTTON_T = 388; CONTROL.Y_BUTTON_T = 297;
		CONTROL.X_BUTTON_S = 388; CONTROL.Y_BUTTON_S = 325; CONTROL.X_BUTTON_L1 = 144; CONTROL.Y_BUTTON_L1 = 28;
		CONTROL.X_BUTTON_R1 = 464; CONTROL.Y_BUTTON_R1 = 28; CONTROL.X_BUTTON_R3 = 388; CONTROL.Y_BUTTON_R3 = 297;
		CONTROL.X_BUTTON_STA = 423; CONTROL.Y_BUTTON_STA = 410; CONTROL.X_BUTTON_SEL = 45; CONTROL.Y_BUTTON_SEL = 410;
		CONTROL.CUSTOM_ANIM = 1; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = false;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 286; CONTROL.SPRITE_X = 69; CONTROL.SPRITE_ALTO = 288; CONTROL.SPRITE_Y = 92;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 2 then
		CONTROL.IMG_ANCHO = 197; CONTROL.IMG_X = 246; CONTROL.IMG_ALTO = 96; CONTROL.IMG_Y = 231;
		CONTROL.IMG_ANCHO_2 = 197; CONTROL.IMG_X_2 = 246; CONTROL.IMG_ALTO_2 = 96; CONTROL.IMG_Y_2 = 231;
		CONTROL.LISTA_ANCHO = 169; CONTROL.LISTA_X = 302; CONTROL.LISTA_ALTO = 341; CONTROL.LISTA_Y = 50;
		CONTROL.LOGO_ANCHO = 194; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 12; CONTROL.FLOW_X = 168; CONTROL.FLOW_ALTO = 115; CONTROL.FLOW_Y = 182;
		CONTROL.FLOW_ANCHO_2 = 460; CONTROL.FLOW_X_2 = 168; CONTROL.FLOW_ALTO_2 = 115; CONTROL.FLOW_Y_2 = 182;
		CONTROL.X_BUTTON_X = 273; CONTROL.Y_BUTTON_X = 398; CONTROL.X_BUTTON_T = 44; CONTROL.Y_BUTTON_T = 398;
		CONTROL.X_BUTTON_S = 475; CONTROL.Y_BUTTON_S = 398; CONTROL.X_BUTTON_L1 = 144; CONTROL.Y_BUTTON_L1 = 28;
		CONTROL.X_BUTTON_R1 = 464; CONTROL.Y_BUTTON_R1 = 28; CONTROL.X_BUTTON_R3 = 260; CONTROL.Y_BUTTON_R3 = 398;
		CONTROL.X_BUTTON_STA = 423; CONTROL.Y_BUTTON_STA = 424; CONTROL.X_BUTTON_SEL = 45; CONTROL.Y_BUTTON_SEL = 424;
		CONTROL.CUSTOM_ANIM = 2; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = false; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = false;
		CONTROL.CUSTOM_FLOW = true; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 477; CONTROL.SPRITE_X = 48; CONTROL.SPRITE_ALTO = 337; CONTROL.SPRITE_Y = 54;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 3 then
		CONTROL.IMG_ANCHO = 48; CONTROL.IMG_X = 250; CONTROL.IMG_ALTO = 92; CONTROL.IMG_Y = 193;
		CONTROL.IMG_ANCHO_2 = 340; CONTROL.IMG_X_2 = 250; CONTROL.IMG_ALTO_2 = 92; CONTROL.IMG_Y_2 = 193;
		CONTROL.LISTA_ANCHO = 46; CONTROL.LISTA_X = 310; CONTROL.LISTA_ALTO = 300; CONTROL.LISTA_Y = 137;
		CONTROL.LOGO_ANCHO = 194; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 48; CONTROL.FLOW_X = 250; CONTROL.FLOW_ALTO = 92; CONTROL.FLOW_Y = 193;
		CONTROL.FLOW_ANCHO_2 = 48; CONTROL.FLOW_X_2 = 250; CONTROL.FLOW_ALTO_2 = 92; CONTROL.FLOW_Y_2 = 193;
		CONTROL.X_BUTTON_X = 399; CONTROL.Y_BUTTON_X = 353; CONTROL.X_BUTTON_T = 399; CONTROL.Y_BUTTON_T = 297;
		CONTROL.X_BUTTON_S = 399; CONTROL.Y_BUTTON_S = 325; CONTROL.X_BUTTON_L1 = 144; CONTROL.Y_BUTTON_L1 = 28;
		CONTROL.X_BUTTON_R1 = 464; CONTROL.Y_BUTTON_R1 = 28; CONTROL.X_BUTTON_R3 = 399; CONTROL.Y_BUTTON_R3 = 297;
		CONTROL.X_BUTTON_STA = 399; CONTROL.Y_BUTTON_STA = 407; CONTROL.X_BUTTON_SEL = 399; CONTROL.Y_BUTTON_SEL = 379;
		CONTROL.CUSTOM_ANIM = 2; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = true;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 300; CONTROL.SPRITE_X = 60; CONTROL.SPRITE_ALTO = 362; CONTROL.SPRITE_Y = 75;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 4 then
		CONTROL.IMG_ANCHO = 333; CONTROL.IMG_X = 295; CONTROL.IMG_ALTO = 92; CONTROL.IMG_Y = 228;
		CONTROL.IMG_ANCHO_2 = 333; CONTROL.IMG_X_2 = 295; CONTROL.IMG_ALTO_2 = 92; CONTROL.IMG_Y_2 = 228;
		CONTROL.LISTA_ANCHO = 10; CONTROL.LISTA_X = 310; CONTROL.LISTA_ALTO = 90; CONTROL.LISTA_Y = 290;
		CONTROL.LOGO_ANCHO = 194; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 333; CONTROL.FLOW_X = 295; CONTROL.FLOW_ALTO = 92; CONTROL.FLOW_Y = 228;
		CONTROL.FLOW_ANCHO_2 = 333; CONTROL.FLOW_X_2 = 295; CONTROL.FLOW_ALTO_2 = 92; CONTROL.FLOW_Y_2 = 228;
		CONTROL.X_BUTTON_X = 273; CONTROL.Y_BUTTON_X = 391; CONTROL.X_BUTTON_T = 44; CONTROL.Y_BUTTON_T = 391;
		CONTROL.X_BUTTON_S = 475; CONTROL.Y_BUTTON_S = 391; CONTROL.X_BUTTON_L1 = 144; CONTROL.Y_BUTTON_L1 = 28;
		CONTROL.X_BUTTON_R1 = 464; CONTROL.Y_BUTTON_R1 = 28; CONTROL.X_BUTTON_R3 = 260; CONTROL.Y_BUTTON_R3 = 391;
		CONTROL.X_BUTTON_STA = 423; CONTROL.Y_BUTTON_STA = 415; CONTROL.X_BUTTON_SEL = 45; CONTROL.Y_BUTTON_SEL = 415;
		CONTROL.CUSTOM_ANIM = 1; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = false;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 257; CONTROL.SPRITE_X = 64; CONTROL.SPRITE_ALTO = 297; CONTROL.SPRITE_Y = 83;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 5 then
		CONTROL.IMG_ANCHO = 12; CONTROL.IMG_X = 295; CONTROL.IMG_ALTO = 20; CONTROL.IMG_Y = 228;
		CONTROL.IMG_ANCHO_2 = 332; CONTROL.IMG_X_2 = 295; CONTROL.IMG_ALTO_2 = 20; CONTROL.IMG_Y_2 = 228;
		CONTROL.LISTA_ANCHO = 10; CONTROL.LISTA_X = 299; CONTROL.LISTA_ALTO = 263; CONTROL.LISTA_Y = 115;
		CONTROL.LOGO_ANCHO = 352; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 280; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 12; CONTROL.FLOW_X = 295; CONTROL.FLOW_ALTO = 20; CONTROL.FLOW_Y = 228;
		CONTROL.FLOW_ANCHO_2 = 12; CONTROL.FLOW_X_2 = 295; CONTROL.FLOW_ALTO_2 = 20; CONTROL.FLOW_Y_2 = 228;
		CONTROL.X_BUTTON_X = 273; CONTROL.Y_BUTTON_X = 391; CONTROL.X_BUTTON_T = 44; CONTROL.Y_BUTTON_T = 391;
		CONTROL.X_BUTTON_S = 475; CONTROL.Y_BUTTON_S = 391; CONTROL.X_BUTTON_L1 = 324; CONTROL.Y_BUTTON_L1 = 252;
		CONTROL.X_BUTTON_R1 = 602; CONTROL.Y_BUTTON_R1 = 252; CONTROL.X_BUTTON_R3 = 260; CONTROL.Y_BUTTON_R3 = 391;
		CONTROL.X_BUTTON_STA = 423; CONTROL.Y_BUTTON_STA = 415; CONTROL.X_BUTTON_SEL = 45; CONTROL.Y_BUTTON_SEL = 415;
		CONTROL.CUSTOM_ANIM = 2; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = true;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 263; CONTROL.SPRITE_X = 66; CONTROL.SPRITE_ALTO = 291; CONTROL.SPRITE_Y = 87;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 6 then
		CONTROL.IMG_ANCHO = 345; CONTROL.IMG_X = 270; CONTROL.IMG_ALTO = 10; CONTROL.IMG_Y = 208;
		CONTROL.IMG_ANCHO_2 = 345; CONTROL.IMG_X_2 = 270; CONTROL.IMG_ALTO_2 = 230; CONTROL.IMG_Y_2 = 208;
		CONTROL.LISTA_ANCHO = 22; CONTROL.LISTA_X = 310; CONTROL.LISTA_ALTO = 90; CONTROL.LISTA_Y = 290;
		CONTROL.LOGO_ANCHO = 52; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 345; CONTROL.FLOW_X = 270; CONTROL.FLOW_ALTO = 10; CONTROL.FLOW_Y = 208;
		CONTROL.FLOW_ANCHO_2 = 345; CONTROL.FLOW_X_2 = 270; CONTROL.FLOW_ALTO_2 = 10; CONTROL.FLOW_Y_2 = 208;
		CONTROL.X_BUTTON_X = 52; CONTROL.Y_BUTTON_X = 386; CONTROL.X_BUTTON_T = 202; CONTROL.Y_BUTTON_T = 386;
		CONTROL.X_BUTTON_S = 52; CONTROL.Y_BUTTON_S = 417; CONTROL.X_BUTTON_L1 = 17; CONTROL.Y_BUTTON_L1 = 60;
		CONTROL.X_BUTTON_R1 = 305; CONTROL.Y_BUTTON_R1 = 60; CONTROL.X_BUTTON_R3 = 52; CONTROL.Y_BUTTON_R3 = 386;
		CONTROL.X_BUTTON_STA = 152; CONTROL.Y_BUTTON_STA = 417; CONTROL.X_BUTTON_SEL = 264; CONTROL.Y_BUTTON_SEL = 417;
		CONTROL.CUSTOM_ANIM = 1; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = true;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		CONTROL.SPRITE_ANCHO = 282; CONTROL.SPRITE_X = 66; CONTROL.SPRITE_ALTO = 298; CONTROL.SPRITE_Y = 83;
		CONTROL.CUSTOM_SPRITE = false;
	elseif CONTROL.ESTILO == 7 then
		cargar_style(false)
	end
end

--- Muestra los créditos. ---------------------------------------------------------------
function creditos(fondo)
	local res_x, res_y_tex, res_y = CONTROL.ANCHO, CONTROL.Y_FIX_PAL, CONTROL.ALTO_F
	local function cargar_creditos()
		fondo()
		Graphics.drawRect(-10, -10, res_x+20, res_y+20, COLOR.NEGRO_T)
		Font.ftPrint(CONTROL.fontARCA, 0+(res_x//2), (0+(res_y//2))-30, 8, res_x, res_y, TEXT_M_CON[46], COLOR.BLANCO)
		refrescar(false)
		System.sleep(1)
	end
	cargar_creditos()
	local ENCELADUS = Graphics.loadImage(verif_img("System/Medias/Credits/ENCELADUS.png"))
	local RETROARCH = Graphics.loadImage(verif_img("System/Medias/Credits/RETROARCH.png"))
	local GPSP = Graphics.loadImage(verif_img("System/Medias/Credits/GPSP.png"))
	local POPSTARTER = Graphics.loadImage(verif_img("System/Medias/Credits/POPSTARTER.png"))
	local NEUTRINO = Graphics.loadImage(verif_img("System/Medias/Credits/NEUTRINO.png"))
	local WLAUNCHELF = Graphics.loadImage(verif_img("System/Medias/Credits/WLAUNCHELF_ISR.png"))
	local OPL = Graphics.loadImage(verif_img("System/Medias/Credits/OPL.png"))
	local SNESTICLE = Graphics.loadImage(verif_img("System/Medias/Credits/SNESTATION.png"))
	local SPAGHETTICODE = Graphics.loadImage(verif_img("System/Medias/Credits/SPAGHETTICODE.png"))
	local RETROLAUNCHER = Graphics.loadImage(verif_img("System/Medias/Credits/RETROLAUNCHER.png"))
	local CREDITOS_IMG = {ENCELADUS, RETROARCH, GPSP, POPSTARTER, NEUTRINO, WLAUNCHELF, OPL, OPL, SNESTICLE, SPAGHETTICODE, RETROLAUNCHER, RETROLAUNCHER}
	local CREDITOS_TXT = {"Enceladus is an enhanced Lua environment for\ncreating homebrew software for the PS2.\nDanielSant0s X: "..
	"https://x.com/danadsees\n\nProject Link:\nhttps://github.com/DanielSant0s/Enceladus\nLicense: Distributed under GNU GPL-3.0 License.";
	"RetroArch port created by RetroArch contributor\nfjtrujy (Francisco J. Trujillo).\nfjtrujy X: https://x.com/fjtrujy\n\nRetroArch "..
	"Link:\nhttps://www.retroarch.com\n\nLicenses: There is software behind RetroArch\nthat is protected by Non-Commercial licenses.\n"..
	"It is important to respect the wishes of the\ndevelopers and people behind the respective\nprojects.\n"..
	"https://docs.libretro.com/development/licenses/";
	"gpSP is a GBA emulator ported to PS2\nby developer belek666.\n\nbelek666 GitHub: https://github.com/belek666\n\nGpSP - "..
	"PS2 link: https://www.psx-place.com/\nresources/gpsp-by-belek666.687/";
	"POPStarter is a launcher which lets you play\nyour PS1 games in combination with PS1 emulator\nfor PS2.\n\n"..
	"POPStarter v13 was created by developer krHACKen.\nPOPStarter Link: https://\nwww.psx-place.com/threads/popstarter.19139/\n\n"..
	"Configuration patches taken from Hugopocked.\nHugopocked Fixes Link: https://www.psx-place.com\n"..
	"/threads/hugopocked-fixes-for-popstarter.39750/";
	"Neutrino is a small, fast and modular PS2 device\nemulator that maximizes compatibility and\nperformance. "..
	"Neutrino was created by developer\nMaximus32 (Rick Gaiser).\n\nNeutrino Link:\nhttps://github.com/rickgaiser/neutrino\n\n"..
	"License: Academic Free License \"AFL\" v. 3.0";
	"wLaunchELF ISR is an open source file manager\nand executable launcher for the PS2 console.\n"..
	"wLaunchELF 4.43x_ISR was created by developer\nisrapps (Matías Israelson) and is a wLaunchELF\nmod.\n\n"..
	"israpps (Matías Israelson):\nhttps://israpps.github.io\nwLaunchELF 4.43x_ISR Project Link:\n"..
	"https://github.com/israpps/wLaunchELF_ISR\n\nwLaunchELF Project Link:\nhttps://github.com/ps2homebrew/wLaunchELF\n"..
	"License: Academic Free License \"AFL\" v. 2.0\nwLaunchELF / project by AKuHAK and SP193.\n"..
	"uLaunchELF / project by E P and dlanor.\nLaunchELF / project by Mirakichi.\nAnd to all the developers who contributed to uLE.";
	"OPL is a 100% open source game and application\nloader for PS2 and PS3 devices, created by\n"..
	"Ifcaro and jimmikaelkael in conjunction with a\nhuge community of developers who are constantly\nimproving it.\n\n"..
	"OPL Project Link:\nhttps://github.com/ps2homebrew/Open-PS2-Loader\n\nLicense:\nCopyright 2013, Ifcaro & jimmikaelkael Licensed\n"..
	"under Academic Free License version 3.0.";
	"Open PS2 Loader by Ps2homebrew Team:\n"..
	"BatRastard - belek666 - crazyc - dlanor\ndoctorxyz - hominem.te.esse - Ifcaro - izdubar\n"..
	"jimmikaelkael - KrahJohlito - kr_ps2\nMaximus32 - misfire - polo35 - reprep - SP193\n"..
	"volca - icyson55 - algol - Berion - El_Patas\nEP - gledson999 - jolek - lee4 - LocalH\n"..
	"RandQalan - ShaolinAssassin - yoshi314 - zero35\nMarcus R. Brown - Eric Young - fjtrujy\nand the anonymous\n\n"..
	"Support Forums: psx-place.com";
	"SNESticle is a SNES emulator that was ported\nby its creator, Icer Addis (Sardu), to several\nplatforms, including PS2.\n"..
	"Source code: https://github.com/iaddis/SNESticle\nLicense: MIT License Copyright 2022 Icer Addis\n\n"..
	"RadShell is a command line client for PS2\ncreated by developer RadAd, that allows the\nautomation of basic tasks within PS2.\n\n"..
	"BDM Assault is a PS2 homebrew project created\nby israpps (Matias Israelson) that aims to\n"..
	"bring USB EXFAT support to older closed-source\nhomebrew applications that can load external\n"..
	"USB controllers.\nProject: https://github.com/israpps/BDMAssault";
	"Thanks to public education for the support \nduring my technical training.\nSpaghetticode / LC - Mendoza - Argentina / 2026";
	"Original background created by < e s c p > Art\nLicense: This Image is licensed under the\nCreative Commons Zero v1.0 Universal.\n"..
	"Free images by https://www.artapixel.com\n\nFont \"Public Pixel\" Designed by GGBotNet.\n"..
	"GGBotNet X: https://twitter.com/ggbotnet\nPublic Pixel Link: https://www.ggbot.net/fonts/\n"..
	"License: This Font Software is licensed under\nthe Creative Commons Zero v1.0 Universal.\n"..
	"CC0 1.0 Link: https://\ncreativecommons.org/publicdomain/zero/1.0/\n";
	"A special thank you to the entire \"PSX-PLACE\"\ncommunity for providing support and visibility\nto the program.\n"..
	"We also thank all YouTube channels along with\ntheir communities for spreading and improving\n"..
	"RETROLauncher with their supportive messages\nand constructive feedback.\n\nThanks for using RETROLauncher.    Boon Tobias"}
	local color_img = 129
	local color_tex = 128
	local cambio = true
	local cambio_t = true
	local pasaje = false
	local estado = 1
	local lista_pos_imgY = {6, 26, 38, 0, 78, 8, 34, 34, 0, 21, 8, 8}
	local lista_pos_imgX = {(640//2)-(600//2), 0, 0, (640//2)-(444//2), 0, (640//2)-(436//2), 0, 0, (640//2)-(469//2), 0, (640//2)-(592//2), (640//2)-(592//2)}
	local lista_pos_tex = {309+res_y_tex, 185+res_y_tex, 240+res_y_tex, 233+res_y_tex, 260+res_y_tex, 99+res_y_tex, 190+res_y_tex, 190+res_y_tex, 138+res_y_tex, 360+res_y_tex, 210+res_y_tex, 234+res_y_tex}
	local lista_pos_img_x = {600, 640, 640, 444, 640, 436, 640, 640, 469, 640, 592, 592}
	local lista_pos_img_y = {297+res_y_tex, 150+res_y_tex, 169+res_y_tex, 228+res_y_tex, 123+res_y_tex, 86+res_y_tex, 131+res_y_tex, 131+res_y_tex, 138+res_y_tex, 301+res_y_tex, 200+res_y_tex, 200+res_y_tex}
	local autocambio, velo_cam = 0, 1
	local mostrar_sob = false
	local TheLastLive = true
	while TheLastLive do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)

		-- Controla los créditos. -------------------------------------------------------
		if Pads.check(PAD, PAD_TRIANGLE) then
			TheLastLive = false
		elseif pasaje == false then
			if color_img >= 1 and cambio == true then
				color_img = color_img-velo_cam
			elseif color_img <= 0 and cambio == true then
				color_img = 0
			elseif color_img <= 127 and cambio == false then
				color_img = color_img+velo_cam
			elseif color_img >= 128 and cambio == false then
				color_img = 128
				cambio = true
				estado = estado+1
			end
			if color_tex >= 1 and cambio_t == true and color_img == 0 then
				color_tex = color_tex-velo_cam
			elseif color_tex <= 0 and cambio_t == true and color_img == 0 then
				color_tex = 0
				cambio_t = false
				pasaje = true
			elseif color_tex <= 127 and cambio_t == false and color_img == 0 then
				color_tex = color_tex+velo_cam
			elseif color_tex >= 128 and cambio_t == false and color_img == 0 then
				color_tex = 128
				cambio_t = true
				cambio = false
			end
			if color_img >= 128 then
				color_img = 128
			end
			if color_tex >= 128 then
				color_tex = 128
			end
			if color_img <= 0 then
				color_img = 0
			end
			if color_tex <= 0 then
				color_tex = 0
			end
			if estado == 7 and color_img == 0 and color_tex == 128 then
				mostrar_sob = true
			elseif estado == 8 and color_img == 0 and color_tex == 0 then
				mostrar_sob = false
			elseif estado == 11 and color_img == 0 and color_tex == 128 then
				mostrar_sob = true
			elseif estado == 12 and color_img == 0 and color_tex == 0 then
				mostrar_sob = false
			end
		elseif pasaje == true and autocambio >= 256 then
			pasaje = false
			autocambio = 0
		elseif pasaje == true then
			autocambio = autocambio+velo_cam
		end
		if PAD ~= 0 then
			velo_cam = 4
		else
			velo_cam = 1
		end

		-- Mostrar todo en pantalla. ----------------------------------------------------
		fondo()
		Graphics.drawRect(-10, -10, res_x+20, res_y+20, COLOR.NEGRO_T)
		if estado <= #CREDITOS_IMG then
			Graphics.drawScaleImage(CREDITOS_IMG[estado], lista_pos_imgX[estado]-5, lista_pos_imgY[estado], lista_pos_img_x[estado]+5, lista_pos_img_y[estado], Color.new(128, 128, 128, 128-color_img))
			if mostrar_sob == true then
				Graphics.drawScaleImage(CREDITOS_IMG[estado], lista_pos_imgX[estado]-5, lista_pos_imgY[estado], lista_pos_img_x[estado]+5, lista_pos_img_y[estado])
			end
			Font.ftPrint(CONTROL.fontARCA, 5, lista_pos_tex[estado], 0, res_x, res_y, CREDITOS_TXT[estado], Color.new(128, 128, 128, 128-color_tex))
		else
			TheLastLive = false
		end
		refrescar(false)
	end
	Graphics.freeImage(ENCELADUS)
	Graphics.freeImage(POPSTARTER)
	Graphics.freeImage(NEUTRINO)
	Graphics.freeImage(WLAUNCHELF)
	Graphics.freeImage(SNESTICLE)
	Graphics.freeImage(OPL)
	Graphics.freeImage(RETROARCH)
	Graphics.freeImage(GPSP)
	Graphics.freeImage(RETROLAUNCHER)
	Graphics.freeImage(SPAGHETTICODE)
	CREDITOS_IMG = nil
	cargar_creditos()
end

--[[Líneas para las funciones encargadas del editor de estilos.]]--
--- Dibuja en pantalla la vista previa de todos los elementos. --------------------------
function dibujar_demo(selector_elementos, elementos_pos_new, elementos_tam_new, cambio_tama_pos, fijar, largo_lista, estado_elementos_new, lis_ext)
	-- Vista previa del arte relacionado con cover flow. --------------------------------
	if estado_elementos_new[4] == true then
		if CONTROL.CUSTOM_BACK == true then
			Graphics.drawRect(elementos_pos_new[7]-5, elementos_pos_new[8]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[7]+10, elementos_tam_new[8]+10, COLOR.NEGRO_T)
			Graphics.drawRect((CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7]))-5, elementos_pos_new[8]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[7]+10, elementos_tam_new[8]+10, COLOR.NEGRO_T)
		end
		dibujar_arte(LISTAS.COVER_ART, LISTAS.EXISTE_COV, LISTAS.COVER_DEFAULT, elementos_pos_new[7], elementos_pos_new[8]+CONTROL.Y_FIX_PAL, elementos_tam_new[7], elementos_tam_new[8], lis_ext[9], lis_ext[10], lis_ext[11], lis_ext[12], nil)
		dibujar_arte(LISTAS.COVER_ART, LISTAS.EXISTE_COV, LISTAS.COVER_DEFAULT, (CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7])), elementos_pos_new[8]+CONTROL.Y_FIX_PAL, elementos_tam_new[7], elementos_tam_new[8], lis_ext[9], lis_ext[10], lis_ext[11], lis_ext[12], nil)
	end

	-- Vista previa del arte extra. -----------------------------------------------------
	if estado_elementos_new[3] == true then
		dibujar_arte(LISTAS.SCREENSHOT, LISTAS.EXISTE_SCR, LISTAS.SCREENSHOT_DEFAULT, elementos_pos_new[5], elementos_pos_new[6]+CONTROL.Y_FIX_PAL, elementos_tam_new[5], elementos_tam_new[6], lis_ext[5], lis_ext[6], lis_ext[7], lis_ext[8], false)
	end

	-- Vista previa del fondo de lista. -------------------------------------------------
	if estado_elementos_new[1] == true then
		Graphics.drawRect(elementos_pos_new[1]-3, elementos_pos_new[2]-3+CONTROL.Y_FIX_PAL, elementos_tam_new[1]+6, elementos_tam_new[2]+6, COLOR.NEGRO_T)
	end

	-- Vista previa de las listas de juegos. --------------------------------------------
	--
	-- Con los nombres REALES del sistema en curso, no trece veces la misma palabra de
	-- ejemplo. Aqui se esta colocando una lista y decidiendo su ancho: nombres todos
	-- del mismo largo no dicen nada sobre lo que se va a ver, y un titulo de verdad
	-- ensena enseguida donde se corta. Si no hay lista cargada se cae en los de antes.
	local function nombre_ejemplo(n)
		if LISTAS.ROMS ~= nil and #LISTAS.ROMS > 0 and LISTAS.INDICE ~= nil then
			local idx = ((LISTAS.INDICE + n - 2) % #LISTAS.ROMS) + 1
			if LISTAS.ROMS[idx] ~= nil then
				return NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[idx], 1)
			end
		end
		return n ..".".. TEXT_M_STI[1]
	end

	local lista_ejemplo = {}
	if estado_elementos_new[4] == false and estado_elementos_new[1] == true then
		for agregar = 1, largo_lista do table.insert(lista_ejemplo, nombre_ejemplo(agregar)) end
		local espacio_linea = elementos_pos_new[2]+((0)*24)+CONTROL.Y_FIX_PAL
		for contador = 1, largo_lista, 1 do
			if contador == 1 then
				Font.ftPrint(CONTROL.fontARCA, elementos_pos_new[1]+3, espacio_linea, 0, elementos_tam_new[1]-6, 25, lista_ejemplo[contador], CAMBIOS_EMUS.COLOR_EMU)
			else
				Font.ftPrint(CONTROL.fontARCA, elementos_pos_new[1]+3, espacio_linea, 0, elementos_tam_new[1]-6, 25, lista_ejemplo[contador], COLOR.BLANCO_LISTA)
			end
			espacio_linea = elementos_pos_new[2]+((contador)*24)+CONTROL.Y_FIX_PAL
		end

	-- Vista previa de las listas de juegos en cover flow. ------------------------------
	elseif estado_elementos_new[4] == true or estado_elementos_new[1] == false then
		lista_ejemplo = {nombre_ejemplo(1), nombre_ejemplo(2), nombre_ejemplo(3)}
		if estado_elementos_new[4] == true then
			-- Vista previa / izquierda. ------------------------------------------------
			Graphics.drawRect(elementos_pos_new[7], (elementos_pos_new[8]+elementos_tam_new[8])+10+CONTROL.Y_FIX_PAL, elementos_tam_new[7], 25, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, elementos_pos_new[7]+5, (elementos_pos_new[8]+elementos_tam_new[8])+12+CONTROL.Y_FIX_PAL, 0, elementos_tam_new[7]-10, 25, string.sub(lista_ejemplo[3], 1, -CONTROL.EXTENSION), COLOR.BLANCO_LISTA)

			-- Vista previa / derecha. --------------------------------------------------
			Graphics.drawRect((CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7])), (elementos_pos_new[8]+elementos_tam_new[8])+10+CONTROL.Y_FIX_PAL, elementos_tam_new[7], 25, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7]))+5, (elementos_pos_new[8]+elementos_tam_new[8])+12+CONTROL.Y_FIX_PAL, 0, elementos_tam_new[7]-10, 25, string.sub(lista_ejemplo[2], 1, -CONTROL.EXTENSION), COLOR.BLANCO_LISTA)
		end

		-- Vista previa / centro. -------------------------------------------------------
		Graphics.drawRect(elementos_pos_new[3]-31, (elementos_pos_new[4]+elementos_tam_new[4])+14+CONTROL.Y_FIX_PAL, elementos_tam_new[3]+62, 25, COLOR.NEGRO_T)
		Font.ftPrint(CONTROL.fontARCA, (elementos_pos_new[3]-31)+5, (elementos_pos_new[4]+elementos_tam_new[4])+16+CONTROL.Y_FIX_PAL, 0, (elementos_tam_new[3]+62)-5, 25, string.sub(lista_ejemplo[1], 1, -CONTROL.EXTENSION), CAMBIOS_EMUS.COLOR_EMU)
	end

	-- Vista previa de juegos encontrados. ----------------------------------------------
	if selector_elementos ~= 1 then
		local text_con = TEXT_M_STI[5] ..": "
		local fix_estilo = 29
		if (estado_elementos_new[4] == true or estado_elementos_new[1] == false) then
			fix_estilo = 24
		end
		Graphics.drawRect(elementos_pos_new[1]-3, (elementos_pos_new[2]+elementos_tam_new[2])-fix_estilo+1+CONTROL.Y_FIX_PAL, elementos_tam_new[1]+6, fix_estilo+1, COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, elementos_pos_new[1]+3, (elementos_pos_new[2]+elementos_tam_new[2])-(fix_estilo-4)+CONTROL.Y_FIX_PAL, 0, elementos_tam_new[1]-30, 25, text_con .. #lista_ejemplo, CAMBIOS_EMUS.COLOR_EMU)
	end

	-- Vista previa de indicadores. -----------------------------------------------------
	local message = {TEXT_M_STI[6], TEXT_M_STI[7], TEXT_M_STI[8], TEXT_M_STI[9], TEXT_M_STI[10], TEXT_M_STI[11]}

	-- Vista previa de indicador para actualizar la lista. ------------------------------
	-- Se dibujaba SOLO mientras estaba seleccionado, asi que R3 podia estar en ON y no
	-- aparecer por ninguna parte: no habia forma de verlo ni de colocarlo respecto a
	-- los demas. Como todos los otros indicadores: si esta encendido, se ve.
	if estado_elementos_new[11] == true then
		dibujar_indicador(elementos_pos_new[21], elementos_pos_new[22], message[6], PAD_IMG.R3, 25, 25, 1, true)
	end

	-- Vista previa de indicadores para cambio de sistemas. -----------------------------
	if estado_elementos_new[9] == true then
		Graphics.drawScaleImage(PAD_IMG.L1, elementos_pos_new[17], elementos_pos_new[18]+CONTROL.Y_FIX_PAL, 32, 32)
	end
	if estado_elementos_new[10] == true then
		Graphics.drawScaleImage(PAD_IMG.R1, elementos_pos_new[19], elementos_pos_new[18]+CONTROL.Y_FIX_PAL, 32, 32)
	end

	-- Vista previa de indicador de salida. ---------------------------------------------
	if estado_elementos_new[13] == true then
		dibujar_indicador(elementos_pos_new[25], elementos_pos_new[26], message[1], PAD_IMG.SELECT_S, 32, 32, 2, true)
	end

	-- Vista previa del indicador de configuración. -------------------------------------
	if estado_elementos_new[12] == true then
		dibujar_indicador(elementos_pos_new[23], elementos_pos_new[24], message[2], PAD_IMG.START, 32, 32, 2, true)
	end
	do
		-- Los tres indicadores de abajo tampoco dependen ya de cual este seleccionado:
		-- desaparecian todos en cuanto se tocaba R3, que era justo el momento en que
		-- hacia falta verlos para no ponerlo encima de ellos.
		-- Vista previa: indicador del menu del juego. ----------------------------------
		-- El rotulo tiene que ser el MISMO que en el menu real: aqui seguia diciendo
		-- "Cambiar arte", que es lo que TRIANGULO hacia antes.
		if estado_elementos_new[7] == true then
			dibujar_indicador(elementos_pos_new[13], elementos_pos_new[14], "Game Menu", PAD_IMG.TRIANGLE, 25, 25, 1, true)
		end

		-- Vista previa: indicadores / arte a pantalla completa. ------------------------
		if estado_elementos_new[8] == true then
			dibujar_indicador(elementos_pos_new[15], elementos_pos_new[16], message[4], PAD_IMG.SQUARE, 25, 25, 1, true)
		end

		-- Vista previa: indicadores / ejecución. ---------------------------------------
		if estado_elementos_new[6] == true then
			dibujar_indicador(elementos_pos_new[11], elementos_pos_new[12], message[5], PAD_IMG.CROSS, 25, 25, 1, true)
		end
	end

	-- Vista previa de portadas / capturas / fondos. ------------------------------------
	if estado_elementos_new[2] == true then
		dibujar_arte(LISTAS.COVER_ART, LISTAS.EXISTE_COV, LISTAS.COVER_DEFAULT, elementos_pos_new[3], elementos_pos_new[4]+CONTROL.Y_FIX_PAL, elementos_tam_new[3], elementos_tam_new[4], lis_ext[1], lis_ext[2], lis_ext[3], lis_ext[4], false)
	end

	-- Vista previa del logo. -----------------------------------------------------------
	if estado_elementos_new[5] == true then
		Graphics.drawScaleImage(LISTAS.LOGO, elementos_pos_new[9], elementos_pos_new[10]+CONTROL.Y_FIX_PAL, elementos_tam_new[9], elementos_tam_new[10])
	end

	-- Vista previa del sprite. ---------------------------------------------------------
	if estado_elementos_new[14] == true then
		dibujar_sprites(LISTAS.IDENTIDAD, elementos_pos_new[27], elementos_pos_new[28]+CONTROL.Y_FIX_PAL, elementos_tam_new[11], elementos_tam_new[12], 0.00, SPRITES.FLIP[1], SPRITES.FLIP[2], false)
	end

	-- Marca sobre el elemento seleccionado. --------------------------------------------
	local color_selector = Color.new(0, 128, 0, 90)
	if cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) then
		color_selector = Color.new(0, 0, 128, 90)
	end
	if fijar[selector_elementos] == true then
		color_selector = Color.new(128, 0, 0, 90)
	end
	if selector_elementos == 1 and estado_elementos_new[1] == true then
		Graphics.drawRect(elementos_pos_new[1]-3, elementos_pos_new[2]-3+CONTROL.Y_FIX_PAL, elementos_tam_new[1]+6, elementos_tam_new[2]+6, color_selector)
	elseif selector_elementos == 2 and estado_elementos_new[2] == true then
		Graphics.drawRect(elementos_pos_new[3]-5, elementos_pos_new[4]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[3]+10, elementos_tam_new[4]+10, color_selector)
	elseif selector_elementos == 3 and estado_elementos_new[3] == true then
		Graphics.drawRect(elementos_pos_new[5]-5, elementos_pos_new[6]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[5]+10, elementos_tam_new[6]+10, color_selector)
	elseif selector_elementos == 4 and estado_elementos_new[4] == true then
		Graphics.drawRect(elementos_pos_new[7]-5, elementos_pos_new[8]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[7]+10, elementos_tam_new[8]+10, color_selector)
		Graphics.drawRect((CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7]))-5, elementos_pos_new[8]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[7]+10, elementos_tam_new[8]+10, color_selector)
	elseif selector_elementos == 5 and estado_elementos_new[5] == true then
		Graphics.drawRect(elementos_pos_new[9]-5, elementos_pos_new[10]-5+CONTROL.Y_FIX_PAL, elementos_tam_new[9]+10, elementos_tam_new[10]+10, color_selector)
	elseif selector_elementos == 6 and estado_elementos_new[6] == true then
		Graphics.drawRect(elementos_pos_new[11]-30, elementos_pos_new[12]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 7 and estado_elementos_new[7] == true then
		Graphics.drawRect(elementos_pos_new[13]-30, elementos_pos_new[14]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 8 and estado_elementos_new[8] == true then
		Graphics.drawRect(elementos_pos_new[15]-30, elementos_pos_new[16]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 9 and estado_elementos_new[9] == true then
		Graphics.drawRect(elementos_pos_new[17], elementos_pos_new[18]+CONTROL.Y_FIX_PAL+4, 32, 24, color_selector)
	elseif selector_elementos == 10 and estado_elementos_new[10] == true then
		Graphics.drawRect(elementos_pos_new[19], elementos_pos_new[18]+CONTROL.Y_FIX_PAL+4, 32, 24, color_selector)
	elseif selector_elementos == 11 and estado_elementos_new[11] == true then
		Graphics.drawRect(elementos_pos_new[21]-30, elementos_pos_new[22]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 12 and estado_elementos_new[12] == true then
		Graphics.drawRect(elementos_pos_new[23]-30, elementos_pos_new[24]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 13 and estado_elementos_new[13] == true then
		Graphics.drawRect(elementos_pos_new[25]-30, elementos_pos_new[26]-3+CONTROL.Y_FIX_PAL, 25, 25, color_selector)
	elseif selector_elementos == 14 and estado_elementos_new[14] == true then
		Graphics.drawRect(elementos_pos_new[27]-1, elementos_pos_new[28]-1+CONTROL.Y_FIX_PAL, elementos_tam_new[11]+2, elementos_tam_new[12]+2, color_selector)
	end
end

--- Líneas para configurar el estilo personalizado. -------------------------------------
function editor_tema()
	JOYSTICK_LIMITE = control_FPS(1)
	local actual = System.currentDirectory()
	local FONT_CNF = Font.ftLoad("System/Medias/Font/PublicPixel.ttf")
	Font.ftSetPixelSize(FONT_CNF, 17, 16)

	-- Corrige la relación de aspecto en el editor de estilos). -------------------------
	local function fix_art_edit(tama_x, tama_y, img)
		local x_prin, y_prin, x_fix, y_fix = tama_x, tama_y, 0, 0
		local x, y = Graphics.getImageWidth(img), Graphics.getImageHeight(img)
		local eiuqal, ymot = (tama_y*x)/y, (tama_x*y)/x
		if eiuqal <= tama_x then
			x_prin, y_prin, x_fix, y_fix = eiuqal, tama_y, (tama_x-eiuqal)//2, 0
		elseif ymot <= tama_y then
			x_prin, y_prin, x_fix, y_fix = tama_x, ymot, 0, (tama_y-ymot)//2
		end
		return x_prin, y_prin, x_fix, y_fix
	end

	-- Cambio entre elementos activados y desactivados. ---------------------------------
	local function estado(selector_X_Y, selector_elementos, lado, estado_elementos_new)
		-- Busca el siguiente elemento ACTIVO. Si no hay ninguno, se para.
		--
		-- Sin ese limite la consola se congela, y no hace falta nada raro para llegar
		-- ahi: basta con desactivar todos los elementos desde el editor. El bucle solo
		-- sabia salir al encontrar un elemento a true, asi que con todos a false daba
		-- vueltas para siempre, sin dibujar ni leer el mando. Es exactamente lo que
		-- pasa al entrar en "active elements" y apagarlos.
		local buscar = true
		local vueltas = 0
		local limite = (#estado_elementos_new * 2) + 2
		while buscar do
			vueltas = vueltas + 1
			if vueltas > limite then
				-- Ninguno activo: se deja el que estaba y se sale.
				break
			end
			if lado == true then
				selector_elementos = cambiar_valor(selector_elementos, 1, #estado_elementos_new, 1, true)
			elseif lado == false then
				selector_elementos = cambiar_valor(selector_elementos, 1, #estado_elementos_new, 1, false)
			end
			if estado_elementos_new[selector_elementos] == true then
				buscar = false
			elseif lado == nil then
				selector_elementos = 1
				lado = true
			end
		end
		selector_X_Y = selector_elementos+(selector_elementos-1)
		return selector_X_Y, selector_elementos
	end

	-- Dibujar líneas de guía en pantalla. ----------------------------------------------
	local function reglas(X, Y, cuadricula, selector_elementos, estado)
		if selector_elementos == 1 or selector_elementos == 14 then
			X, Y = X-3, Y-3
		elseif selector_elementos >= 2 and selector_elementos <= 5 then
			X, Y = X-5, Y-5
		elseif (selector_elementos >= 6 and selector_elementos <= 8) or (selector_elementos >= 11 and selector_elementos <= 13) then
			X, Y = X-30, Y-3
		elseif selector_elementos == 9 or selector_elementos == 10 then
			Y = Y+4
		end
		if estado == false then
			Graphics.drawLine(X, Y+CONTROL.Y_FIX_PAL, CONTROL.ANCHO, Y+CONTROL.Y_FIX_PAL, COLOR.BLANCO)
			Graphics.drawLine(X, Y+CONTROL.Y_FIX_PAL, -10, Y+CONTROL.Y_FIX_PAL, COLOR.BLANCO)
			Graphics.drawLine(X, Y+CONTROL.Y_FIX_PAL, X, CONTROL.ALTO_F, COLOR.BLANCO)
			Graphics.drawLine(X, Y+CONTROL.Y_FIX_PAL, X, -10, COLOR.BLANCO)
			if cuadricula == 2 or cuadricula == 4 then
				local size_X, size_Y = 40, 32
				for ancho = -size_X, CONTROL.ANCHO+(size_X*2), size_X do
					Graphics.drawLine(ancho, -size_Y, ancho, CONTROL.ALTO_F+size_Y, Color.new(80, 80, 80))
				end
				for alto = -size_Y, CONTROL.ALTO_F+(size_Y*2), size_Y do
					Graphics.drawLine(-size_X, alto, CONTROL.ANCHO+size_X, alto, Color.new(80, 80, 80))
				end
			end
		elseif estado == true then
			return X, Y+CONTROL.Y_FIX_PAL
		end
	end

	-- Reparar problema en acceso a valores nulos en listas. ----------------------------
	local function parche(numero)
		local fix = numero
		if fix == 27 then
			fix = 11
		end
		return fix
	end

	-- Estados previos de activación de elementos. --------------------------------------
	local estado_elementos_ant = {CONTROL.CUSTOM_LIST; CONTROL.CUSTOM_ART1; CONTROL.CUSTOM_ART2; CONTROL.CUSTOM_FLOW;
	CONTROL.CUSTOM_LOGO; CONTROL.CUSTOM_BUTTON_X; CONTROL.CUSTOM_BUTTON_T; CONTROL.CUSTOM_BUTTON_S; CONTROL.CUSTOM_BUTTON_L1;
	CONTROL.CUSTOM_BUTTON_R1; CONTROL.CUSTOM_BUTTON_R3; CONTROL.CUSTOM_BUTTON_STA; CONTROL.CUSTOM_BUTTON_SEL;
	CONTROL.CUSTOM_SPRITE;};

	-- Nuevos estados de activación de elementos. ---------------------------------------
	local selector_elementos = 1
	local estado_elementos_new = {CONTROL.CUSTOM_LIST; CONTROL.CUSTOM_ART1; CONTROL.CUSTOM_ART2; CONTROL.CUSTOM_FLOW;
	CONTROL.CUSTOM_LOGO; CONTROL.CUSTOM_BUTTON_X; CONTROL.CUSTOM_BUTTON_T; CONTROL.CUSTOM_BUTTON_S; CONTROL.CUSTOM_BUTTON_L1;
	CONTROL.CUSTOM_BUTTON_R1; CONTROL.CUSTOM_BUTTON_R3; CONTROL.CUSTOM_BUTTON_STA; CONTROL.CUSTOM_BUTTON_SEL; CONTROL.CUSTOM_SPRITE;};

	-- Lista con los nombres de objetos y opciones extras. ------------------------------
	local nombres_opciones = {TEXT_M_STI[12]; TEXT_M_STI[13]; TEXT_M_STI[14]; TEXT_M_STI[15]; TEXT_M_STI[16]; TEXT_M_STI[17];
	TEXT_M_STI[18]; TEXT_M_STI[19]; TEXT_M_STI[20]; TEXT_M_STI[21]; TEXT_M_STI[22]; TEXT_M_STI[23]; TEXT_M_STI[24];
	TEXT_M_STI[25]; TEXT_M_STI[26]; TEXT_M_STI[27]; TEXT_M_STI[28]; TEXT_M_STI[29];};
	local nombres_acciones = {TEXT_M_STI[30]; TEXT_M_STI[31]; TEXT_M_STI[32]; TEXT_M_STI[33]; TEXT_M_STI[34];
	TEXT_M_STI[35]; TEXT_M_STI[36]; TEXT_M_STI[37]; TEXT_M_STI[38]; TEXT_M_STI[39]; TEXT_M_STI[40];};

	-- Lista para fijar el estado de elementos durante la edición. ----------------------
	local fijar = {false, false, false, false, false, false, false, false, false, false, false, false, false, false}

	-- Configuración de restauración completa. ------------------------------------------
	local restaura_estado = {true; true; false; false; true; true; true; true; true; true; true; true; true; false;};
	local restaura_pos = {30; 90; 358; 92; 358; 92; 30; 92; 194; 5; 273; 391; 44; 391; 475; 391; 144; 28; 464; 28; 260; 391; 423; 415; 45; 415; 286; 288;};
	local restaura_tam = {310; 290; 250; 193; 250; 193; 160; 103; 252; 76; 69; 92;};

	-- Posiciones y tamaños previos. ----------------------------------------------------
	local elementos_pos_ant = {
	CONTROL.LISTA_ANCHO; CONTROL.LISTA_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.IMG_ANCHO; CONTROL.IMG_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.IMG_ANCHO_2; CONTROL.IMG_ALTO_2-CONTROL.Y_FIX_PAL;
	CONTROL.FLOW_ANCHO; CONTROL.FLOW_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.LOGO_ANCHO; CONTROL.LOGO_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.X_BUTTON_X; CONTROL.Y_BUTTON_X;
	CONTROL.X_BUTTON_T; CONTROL.Y_BUTTON_T;
	CONTROL.X_BUTTON_S; CONTROL.Y_BUTTON_S;
	CONTROL.X_BUTTON_L1; CONTROL.Y_BUTTON_L1;
	CONTROL.X_BUTTON_R1; CONTROL.Y_BUTTON_R1;
	CONTROL.X_BUTTON_R3; CONTROL.Y_BUTTON_R3;
	CONTROL.X_BUTTON_STA; CONTROL.Y_BUTTON_STA;
	CONTROL.X_BUTTON_SEL; CONTROL.Y_BUTTON_SEL;
	CONTROL.SPRITE_ANCHO; CONTROL.SPRITE_ALTO-CONTROL.Y_FIX_PAL;};
	local elementos_tam_ant = {
	CONTROL.LISTA_X; CONTROL.LISTA_Y;
	CONTROL.IMG_X; CONTROL.IMG_Y;
	CONTROL.IMG_X_2; CONTROL.IMG_Y_2;
	CONTROL.FLOW_X; CONTROL.FLOW_Y;
	CONTROL.LOGO_X; CONTROL.LOGO_Y;
	CONTROL.SPRITE_X; CONTROL.SPRITE_Y;};

	-- Nuevas posiciones y tamaños. -----------------------------------------------------
	local selector_X_Y = 1
	local elementos_pos_new = {
	CONTROL.LISTA_ANCHO; CONTROL.LISTA_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.IMG_ANCHO; CONTROL.IMG_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.IMG_ANCHO_2; CONTROL.IMG_ALTO_2-CONTROL.Y_FIX_PAL;
	CONTROL.FLOW_ANCHO; CONTROL.FLOW_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.LOGO_ANCHO; CONTROL.LOGO_ALTO-CONTROL.Y_FIX_PAL;
	CONTROL.X_BUTTON_X; CONTROL.Y_BUTTON_X;
	CONTROL.X_BUTTON_T; CONTROL.Y_BUTTON_T;
	CONTROL.X_BUTTON_S; CONTROL.Y_BUTTON_S;
	CONTROL.X_BUTTON_L1; CONTROL.Y_BUTTON_L1;
	CONTROL.X_BUTTON_R1; CONTROL.Y_BUTTON_R1;
	CONTROL.X_BUTTON_R3; CONTROL.Y_BUTTON_R3;
	CONTROL.X_BUTTON_STA; CONTROL.Y_BUTTON_STA;
	CONTROL.X_BUTTON_SEL; CONTROL.Y_BUTTON_SEL;
	CONTROL.SPRITE_ANCHO; CONTROL.SPRITE_ALTO-CONTROL.Y_FIX_PAL;};
	local elementos_tam_new = {
	CONTROL.LISTA_X; CONTROL.LISTA_Y;
	CONTROL.IMG_X; CONTROL.IMG_Y;
	CONTROL.IMG_X_2; CONTROL.IMG_Y_2;
	CONTROL.FLOW_X; CONTROL.FLOW_Y;
	CONTROL.LOGO_X; CONTROL.LOGO_Y;
	CONTROL.SPRITE_X; CONTROL.SPRITE_Y;};

	-- Largo de la lista de juegos. -----------------------------------------------------
	local largo_lista = LISTAS.ELEMENTOS_LIST
	local anterior_anim, anterior_anim_vel = CONTROL.CUSTOM_ANIM, CONTROL.ANIM_VELOCIDAD
	local cov_x_asp, cov_y_asp, cov_x_fix, cov_y_fix = fix_art_edit(elementos_tam_new[3], elementos_tam_new[4], LISTAS.COVER_DEFAULT)
	local scr_x_asp, scr_y_asp, scr_x_fix, scr_y_fix = fix_art_edit(elementos_tam_new[5], elementos_tam_new[6], LISTAS.SCREENSHOT_DEFAULT)
	local flo_x_asp, flo_y_asp, flo_x_fix, flo_y_fix = fix_art_edit(elementos_tam_new[7], elementos_tam_new[8], LISTAS.COVER_DEFAULT)
	local lis_ext = {cov_x_asp; cov_y_asp; cov_x_fix; cov_y_fix; scr_x_asp; scr_y_asp; scr_x_fix; scr_y_fix; flo_x_asp; flo_y_asp; flo_x_fix; flo_y_fix;}
	local function set_aspect()
		cov_x_asp, cov_y_asp, cov_x_fix, cov_y_fix = fix_art_edit(elementos_tam_new[3], elementos_tam_new[4], LISTAS.COVER_DEFAULT)
		scr_x_asp, scr_y_asp, scr_x_fix, scr_y_fix = fix_art_edit(elementos_tam_new[5], elementos_tam_new[6], LISTAS.SCREENSHOT_DEFAULT)
		flo_x_asp, flo_y_asp, flo_x_fix, flo_y_fix = fix_art_edit(elementos_tam_new[7], elementos_tam_new[8], LISTAS.COVER_DEFAULT)
		lis_ext = {cov_x_asp; cov_y_asp; cov_x_fix; cov_y_fix; scr_x_asp; scr_y_asp; scr_x_fix; scr_y_fix; flo_x_asp; flo_y_asp; flo_x_fix; flo_y_fix;}
	end

	-- Elementos para controlar el menú. ------------------------------------------------
	local submenu = false
	local hud = false
	local selector_submenu = 1
	local velocidad = 1
	local act_reglas = 0
	local cambio_tama_pos = false
	local salida = false
	local editar = true
	local change_detector = false
	selector_X_Y, selector_elementos = estado(selector_X_Y, selector_elementos, nil, estado_elementos_new)

	-- Iniciar la edición del estilo personalizado. -------------------------------------
	while editar do
		CONTROL.FPS = Screen.getFPS(1)
		capturar(JOYSTICK_LIMITE)
		dibujar_fondos()

		-- Determina el largo de la lista de juegos según su tamaño. --------------------
		if estado_elementos_new[1] == true then
			largo_lista = elementos_tam_new[2]//24
		else
			largo_lista = 1
		end

		-- Dibujar sobre fondo cuando las lineas de guia estan activadas. ---------------
		if act_reglas >= 1 and act_reglas <= 2 then
			Graphics.drawRect(-10, -10, CONTROL.ANCHO+20, CONTROL.ALTO_F+20, Color.new(20, 20, 20, 100))
		elseif act_reglas >= 3 then
			Graphics.drawRect(-10, -10, CONTROL.ANCHO+20, CONTROL.ALTO_F+20, Color.new(0, 40, 70))
		end

		-- Dibujar vistas previas de todos los elementos. -------------------------------
		dibujar_demo(selector_elementos, elementos_pos_new, elementos_tam_new, cambio_tama_pos, fijar, largo_lista, estado_elementos_new, lis_ext)

		-- Dibujar líneas de guía. ------------------------------------------------------
		if act_reglas >= 1 then
			reglas(elementos_pos_new[selector_X_Y], elementos_pos_new[selector_X_Y+1], act_reglas, selector_elementos, false)
		end

		-- Reubicar la ayuda en pantalla. -----------------------------------------------
		local hud_Y, hud_X, hud_alto, fix_hud, r_pos_Y = 0, 0, 102, 0, 102
		local tex_x, tex_y = reglas(elementos_pos_new[selector_X_Y], elementos_pos_new[selector_X_Y+1], act_reglas, selector_elementos, true)
		if hud == false then
			hud_alto, fix_hud, r_pos_Y = 42, 52, 42
		end
		if (elementos_pos_new[selector_X_Y] <= CONTROL.ANCHO//2 and cambio_tama_pos == false) or ((selector_elementos <= 5 or selector_elementos == 14) and elementos_pos_new[selector_X_Y]+elementos_tam_new[parche(selector_X_Y)] <= CONTROL.ANCHO//2 and cambio_tama_pos == true) then
			hud_X = CONTROL.ANCHO-(CONTROL.ANCHO//2)+fix_hud
		end
		if (elementos_pos_new[selector_X_Y+1] <= CONTROL.ALTO_F//2 and cambio_tama_pos == false) or ((selector_elementos <= 5 or selector_elementos == 14) and elementos_pos_new[selector_X_Y+1]+elementos_tam_new[parche(selector_X_Y)+1] <= CONTROL.ALTO_F//2 and cambio_tama_pos == true) then
			hud_Y = CONTROL.ALTO_F-(hud_alto)-2
			r_pos_Y = hud_Y-25
		end

		-- Dibujar la ayuda en pantalla. ------------------------------------------------
		if hud == true and submenu == false then
			Graphics.drawRect(hud_X, hud_Y, CONTROL.ANCHO//2, hud_alto, Color.new(117, 117, 117))
			Graphics.drawRect(hud_X+2, hud_Y+2, (CONTROL.ANCHO//2)-4, hud_alto-4, Color.new(20, 20, 20))
			Graphics.drawScaleImage(PAD_IMG.L1, hud_X+1, hud_Y, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+29, hud_Y+3, 0, CONTROL.ANCHO//2, 20, nombres_acciones[8], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.R1, hud_X+160, hud_Y, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+188, hud_Y+3, 0, CONTROL.ANCHO//2, 20, nombres_acciones[7], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.SQUARE, hud_X+6, hud_Y+23, 16, 16)
			Font.ftPrint(FONT_CNF, hud_X+28, hud_Y+21, 0, CONTROL.ANCHO//2, 20, nombres_acciones[9], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.SELECT_S, hud_X+161, hud_Y+18, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+188, hud_Y+21, 0, CONTROL.ANCHO//2, 20, nombres_acciones[10], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.CROSS, hud_X+6, hud_Y+44, 16, 16)
			Font.ftPrint(FONT_CNF, hud_X+28, hud_Y+43, 0, CONTROL.ANCHO//2, 20, nombres_acciones[1], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.R3, hud_X+160, hud_Y+41, 24, 22)
			Font.ftPrint(FONT_CNF, hud_X+188, hud_Y+43, 0, CONTROL.ANCHO//2, 20, nombres_acciones[6], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.L2, hud_X+1, hud_Y+60, 25, 25)
			if cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) then
				Font.ftPrint(FONT_CNF, hud_X+29, hud_Y+63, 0, CONTROL.ANCHO//2, 20, nombres_acciones[3], COLOR.BLANCO)
			else
				Font.ftPrint(FONT_CNF, hud_X+29, hud_Y+63, 0, CONTROL.ANCHO//2, 20, nombres_acciones[4], COLOR.BLANCO)
			end
			Graphics.drawScaleImage(PAD_IMG.R2, hud_X+160, hud_Y+60, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+188, hud_Y+63, 0, CONTROL.ANCHO//2, 20, nombres_acciones[5] ..":".. velocidad, COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.TRIANGLE, hud_X+6, hud_Y+83, 16, 16)
			Font.ftPrint(FONT_CNF, hud_X+28, hud_Y+81, 0, CONTROL.ANCHO//2, 20, nombres_acciones[2], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.START, hud_X+161, hud_Y+78, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+188, hud_Y+81, 0, CONTROL.ANCHO//2, 20, nombres_acciones[11], COLOR.BLANCO)
			if act_reglas >= 1 then
				Graphics.drawRect(hud_X, r_pos_Y, CONTROL.ANCHO//2, 25, Color.new(117, 117, 117))
				Graphics.drawRect(hud_X+2, r_pos_Y+2, (CONTROL.ANCHO//2)-4, 25-4, Color.new(20, 20, 20))
				Font.ftPrint(FONT_CNF, hud_X+28, r_pos_Y+3, 0, CONTROL.ANCHO//2, 20, "X: ".. tex_x, COLOR.BLANCO)
				Font.ftPrint(FONT_CNF, hud_X+140, r_pos_Y+3, 0, CONTROL.ANCHO//2, 20, "Y: ".. tex_y, COLOR.BLANCO)
			end
		elseif hud == false and submenu == false then
			Graphics.drawRect(hud_X, hud_Y, (CONTROL.ANCHO//2)-52, hud_alto, Color.new(117, 117, 117))
			Graphics.drawRect(hud_X+2, hud_Y+2, (CONTROL.ANCHO//2)-56, hud_alto-4, Color.new(20, 20, 20))
			Graphics.drawScaleImage(PAD_IMG.SQUARE, hud_X+6, hud_Y+5, 16, 16)
			Font.ftPrint(FONT_CNF, hud_X+28, hud_Y+3, 0, CONTROL.ANCHO//2, 20, nombres_acciones[9], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.START, hud_X+112, hud_Y, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+140, hud_Y+3, 0, CONTROL.ANCHO//2, 20, TEXT_GEN[12], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.SELECT_S, hud_X+6, hud_Y+17, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+28, hud_Y+19, 0, CONTROL.ANCHO//2, 20, TEXT_M_STI[41], COLOR.BLANCO)
			Graphics.drawScaleImage(PAD_IMG.R2, hud_X+112, hud_Y+16, 25, 25)
			Font.ftPrint(FONT_CNF, hud_X+140, hud_Y+19, 0, CONTROL.ANCHO//2, 20, TEXT_M_STI[42] ..":".. velocidad, COLOR.BLANCO)
			if act_reglas >= 1 then
				Graphics.drawRect(hud_X, r_pos_Y, (CONTROL.ANCHO//2)-52, 25, Color.new(117, 117, 117))
				Graphics.drawRect(hud_X+2, r_pos_Y+2, (CONTROL.ANCHO//2)-56, 25-4, Color.new(20, 20, 20))
				Font.ftPrint(FONT_CNF, hud_X+28, r_pos_Y+3, 0, CONTROL.ANCHO//2, 20, "X: ".. tex_x, COLOR.BLANCO)
				Font.ftPrint(FONT_CNF, hud_X+140, r_pos_Y+3, 0, CONTROL.ANCHO//2, 20, "Y: ".. tex_y, COLOR.BLANCO)
			end
		end

		-- Controlar el menú de edición. ------------------------------------------------
		if submenu == false then
			-- Mostrar submenú de elementos. --------------------------------------------
			if Pads.check(PAD, PAD_SELECT) and CONTROL.JOYSTICK_ON == false then
				submenu = true
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Guardar configuración. ---------------------------------------------------
			elseif Pads.check(PAD, PAD_START) and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				local aplicar = guardar_style(estado_elementos_new, elementos_pos_new, elementos_tam_new, largo_lista, FONT_CNF)
				if aplicar == true then
					for actualiza = 1, #elementos_pos_new do
						elementos_pos_ant[actualiza] = elementos_pos_new[actualiza]
					end
					for actualiza2 = 1, #elementos_tam_new do
						elementos_tam_ant[actualiza2] = elementos_tam_new[actualiza2]
					end
					for actualiza3 = 1, #estado_elementos_new do
						estado_elementos_ant[actualiza3] = estado_elementos_new[actualiza3]
					end
					anterior_anim, anterior_anim_vel = CONTROL.CUSTOM_ANIM, CONTROL.ANIM_VELOCIDAD
					change_detector = true
				end
				JOYSTICK_LIMITE = control_FPS(1)

			-- Salir del editor. --------------------------------------------------------
			elseif Pads.check(PAD, PAD_CIRCLE) and CONTROL.JOYSTICK_ON == false then
				salida = true
				JOYSTICK_LIMITE = control_FPS(1)

			-- Cambiar entre los elementos en pantalla. ---------------------------------
			elseif (Pads.check(PAD, PAD_L1) or Pads.check(PAD, PAD_R1)) and CONTROL.JOYSTICK_ON == false then
				local lado_elemento = false
				if Pads.check(PAD, PAD_R1) then
					lado_elemento = true
				end
				selector_X_Y, selector_elementos = estado(selector_X_Y, selector_elementos, lado_elemento, estado_elementos_new)
				cambio_tama_pos = false
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Intercambiar menú de ayuda en pantalla. ----------------------------------
			elseif Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
				if hud == false then
					hud = true
				else
					hud = false
				end
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Activar / desactivar las líneas de guía en pantalla. ---------------------
			elseif Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
				act_reglas = cambiar_valor(act_reglas, 0, 4, 1, true)
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Fijar un elemento para evitar su edición. --------------------------------
			elseif Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
				if fijar[selector_elementos] == false then
					fijar[selector_elementos] = true
				else
					fijar[selector_elementos] = false
				end
				repro_sfx(S_EJECUTAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Restaura el elemento a su última posición guardada. ----------------------
			elseif Pads.check(PAD, PAD_R3) and CONTROL.JOYSTICK_ON == false and fijar[selector_elementos] == false then
				elementos_pos_new[selector_X_Y] = elementos_pos_ant[selector_X_Y]
				elementos_pos_new[selector_X_Y+1] = elementos_pos_ant[selector_X_Y+1]
				if (selector_elementos <= 5 or selector_elementos == 14) then
					elementos_tam_new[parche(selector_X_Y)] = elementos_tam_ant[parche(selector_X_Y)]
					elementos_tam_new[parche(selector_X_Y)+1] = elementos_tam_ant[parche(selector_X_Y)+1]
				end
				set_aspect()
				repro_sfx(S_CANCELAR, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Ver controles del editor. ------------------------------------------------
			elseif Pads.check(PAD, PAD_L3) and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				ver_controles(true)

			-- Cambia las posiciones y tamaños de los elementos. ------------------------
			elseif (Pads.check(PAD, PAD_DOWN) or Pads.check(PAD, PAD_UP) or Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT) or PALANCA(Left_Y) or PALANCA(Left_X) or Pads.check(PAD, PAD_L2) or Pads.check(PAD, PAD_R2)) and CONTROL.JOYSTICK_ON == false then
				-- Cambiar el salto de píxeles. -----------------------------------------
				if Pads.check(PAD, PAD_R2) then
					velocidad = cambiar_valor(velocidad, 1, 10, 1, true)
				end

				-- Intercambiar entre cambio de posición o tamaño. ----------------------
				if Pads.check(PAD, PAD_L2) and cambio_tama_pos == false and (selector_elementos <= 5 or selector_elementos == 14) then
					cambio_tama_pos = true
				elseif Pads.check(PAD, PAD_L2) and cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) then
					cambio_tama_pos = false
				end

				-- Realizar los movimientos de posicionamiento y redimensión. -----------
				if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) and fijar[selector_elementos] == false then
					elementos_tam_new[parche(selector_X_Y)+1] = cambiar_valor(elementos_tam_new[parche(selector_X_Y)+1], 48, ((CONTROL.ALTO_F-CONTROL.Y_FIX_PAL)-elementos_pos_new[selector_X_Y+1]), velocidad, false)
				elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) and fijar[selector_elementos] == false then
					elementos_tam_new[parche(selector_X_Y)+1] = cambiar_valor(elementos_tam_new[parche(selector_X_Y)+1], 48, ((CONTROL.ALTO_F-CONTROL.Y_FIX_PAL)-elementos_pos_new[selector_X_Y+1]), velocidad, true)
				elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) and fijar[selector_elementos] == false then
					elementos_tam_new[parche(selector_X_Y)] = cambiar_valor(elementos_tam_new[parche(selector_X_Y)], 48, (CONTROL.ANCHO-elementos_pos_new[selector_X_Y]), velocidad, false)
				elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and cambio_tama_pos == true and (selector_elementos <= 5 or selector_elementos == 14) and fijar[selector_elementos] == false then
					elementos_tam_new[parche(selector_X_Y)] = cambiar_valor(elementos_tam_new[parche(selector_X_Y)], 48, (CONTROL.ANCHO-elementos_pos_new[selector_X_Y]), velocidad, true)
				elseif (Pads.check(PAD, PAD_UP) or Left_Y <= -90) and fijar[selector_elementos] == false then
					elementos_pos_new[selector_X_Y+1] = cambiar_valor(elementos_pos_new[selector_X_Y+1], 0, (CONTROL.ALTO_F-(CONTROL.Y_FIX_PAL*2)), velocidad, false)
				elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) and fijar[selector_elementos] == false then
					elementos_pos_new[selector_X_Y+1] = cambiar_valor(elementos_pos_new[selector_X_Y+1], 0, (CONTROL.ALTO_F-(CONTROL.Y_FIX_PAL*2)), velocidad, true)
				elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and fijar[selector_elementos] == false then
					elementos_pos_new[selector_X_Y] = cambiar_valor(elementos_pos_new[selector_X_Y], 0, CONTROL.ANCHO, velocidad, false)
				elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and fijar[selector_elementos] == false then
					elementos_pos_new[selector_X_Y] = cambiar_valor(elementos_pos_new[selector_X_Y], 0, CONTROL.ANCHO, velocidad, true)
				end
				if cambio_tama_pos == true then
					set_aspect()
				end
				local kabal = 1 if (PALANCA(Left_Y) or PALANCA(Left_X)) and not (Pads.check(PAD, PAD_R2) or Pads.check(PAD, PAD_L2)) then
					kabal = 2
				end
				if Pads.check(PAD, PAD_R2) or Pads.check(PAD, PAD_L2) then
					repro_sfx(S_EJECUTAR, 1, false, nil)
				elseif kabal == 1 then
					repro_sfx(S_MOVER, 1, false, nil)
				end
				JOYSTICK_LIMITE = control_FPS(kabal)
			end

		-- Muestra submenú de elementos. ------------------------------------------------
		else
			-- Dibujar las opciones del submenú y su estado. ----------------------------
			Graphics.drawRect((CONTROL.ANCHO//2), 0, 320, CONTROL.ALTO_F, Color.new(117, 117, 117))
			Graphics.drawRect((CONTROL.ANCHO//2)+2, 2, 316, CONTROL.ALTO_F-4, Color.new(20, 20, 20))
			Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+160, 12+CONTROL.Y_FIX_PAL, 8, 320, 21, "-".. TEXT_M_STI[43] .."-", COLOR.BLANCO)
			local espacio_linea = 12+((0)*21)+CONTROL.Y_FIX_PAL
			local art_shadow, art_sprite = TEXT_GEN[3], TEXT_GEN[2]
			if CONTROL.CUSTOM_BACK == false then
				art_shadow = TEXT_GEN[2]
			end
			if estado_elementos_new[14] == true then
				art_sprite = TEXT_GEN[3]
			end
			for elementos = 1, 13 do
				espacio_linea = 12+((elementos)*21)+CONTROL.Y_FIX_PAL
				local estado_on = TEXT_GEN[2]
				if estado_elementos_new[elementos] == true then
					estado_on = TEXT_GEN[3]
				end
				if selector_submenu == elementos then
					Graphics.drawRect((CONTROL.ANCHO//2)+9, espacio_linea-2, 302, 23, COLOR.BLANCO)
					Graphics.drawRect((CONTROL.ANCHO//2)+11, espacio_linea, 298, 19, Color.new(30, 30, 30))
					Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+13, espacio_linea, 0, 320, 21, nombres_opciones[elementos], COLOR.BLANCO)
					Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea, 0, 320, 21, estado_on, COLOR.BLANCO)
				else
					Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+13, espacio_linea, 0, 320, 21, nombres_opciones[elementos], COLOR.GRIS)
					Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea, 0, 320, 21, estado_on, COLOR.GRIS)
				end
				if elementos == 1 then
					Graphics.drawScaleImage(PAD_IMG.R1, CONTROL.ANCHO-234, espacio_linea-3, 25, 25)
					Font.ftPrint(FONT_CNF, CONTROL.ANCHO-204, espacio_linea, 0, 320, 21, "SPRITE ".. art_sprite, Color.new(30, 30, 30))
				end
				if elementos == 2 then
					Graphics.drawScaleImage(PAD_IMG.R1, CONTROL.ANCHO-234, espacio_linea-3, 25, 25)
					Font.ftPrint(FONT_CNF, CONTROL.ANCHO-204, espacio_linea, 0, 320, 21, TEXT_M_STI[44] .." ".. art_shadow, Color.new(30, 30, 30))
				end
			end
			Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+160, 304+CONTROL.Y_FIX_PAL, 8, 320, 21, "-".. TEXT_M_STI[45] .."-", COLOR.BLANCO)
			local espacio_linea2 = 33+((0)*21)+CONTROL.Y_FIX_PAL
			for elementos = 14, #nombres_opciones do
				espacio_linea2 = 33+((elementos)*21)+CONTROL.Y_FIX_PAL
				if selector_submenu == elementos then
					Graphics.drawRect((CONTROL.ANCHO//2)+9, espacio_linea2-2, 302, 23, COLOR.BLANCO)
					Graphics.drawRect((CONTROL.ANCHO//2)+11, espacio_linea2, 298, 19, Color.new(30, 30, 30))
					Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+13, espacio_linea2, 0, 320, 21, nombres_opciones[elementos], COLOR.BLANCO)
					if elementos == 14 then
						Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea2, 0, 320, 21, CONTROL.CUSTOM_ANIM, COLOR.BLANCO)
					elseif elementos == 15 then
						Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea2, 0, 320, 21, CONTROL.ANIM_VELOCIDAD, COLOR.BLANCO)
					end
				else
					Font.ftPrint(FONT_CNF, (CONTROL.ANCHO//2)+13, espacio_linea2, 0, 320, 21, nombres_opciones[elementos], COLOR.GRIS)
					if elementos == 14 then
						Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea2, 0, 320, 21, CONTROL.CUSTOM_ANIM, COLOR.GRIS)
					elseif elementos == 15 then
						Font.ftPrint(FONT_CNF, CONTROL.ANCHO-52, espacio_linea2, 0, 320, 21, CONTROL.ANIM_VELOCIDAD, COLOR.GRIS)
					end
				end
			end

			-- Salir del submenú. -------------------------------------------------------
			if (Pads.check(PAD, PAD_SELECT) or Pads.check(PAD, PAD_TRIANGLE) or Pads.check(PAD, PAD_CIRCLE)) and CONTROL.JOYSTICK_ON == false then
				submenu = false
				repro_sfx(S_EJECUTAR, 1, false, nil)
				selector_X_Y, selector_elementos = estado(selector_X_Y, selector_elementos, nil, estado_elementos_new)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Moverse entre los elementos del submenú. ---------------------------------
			elseif (Pads.check(PAD, PAD_DOWN) or Pads.check(PAD, PAD_UP) or PALANCA(Left_Y)) and CONTROL.JOYSTICK_ON == false then
				if (Pads.check(PAD, PAD_UP) or Left_Y <= -90) then
					selector_submenu = cambiar_valor(selector_submenu, 1, #nombres_opciones, 1, false)
				elseif (Pads.check(PAD, PAD_DOWN) or Left_Y >= 90) then
					selector_submenu = cambiar_valor(selector_submenu, 1, #nombres_opciones, 1, true)
				end
				repro_sfx(S_MOVER, 1, false, nil)
				JOYSTICK_LIMITE = control_FPS(1)

			-- Activa y desactiva las sombras tras el arte. -----------------------------
			elseif Pads.check(PAD, PAD_R1) and estado_elementos_new[2] == true and selector_submenu == 2 and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				if CONTROL.CUSTOM_BACK == true then
					CONTROL.CUSTOM_BACK = false
				else
					CONTROL.CUSTOM_BACK = true
				end
				JOYSTICK_LIMITE = control_FPS(1)

			-- Activa y desactiva los sprites. ------------------------------------------
			elseif Pads.check(PAD, PAD_R1) and selector_submenu == 1 and CONTROL.JOYSTICK_ON == false then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				if estado_elementos_new[14] == true then
					estado_elementos_new[14] = false
				else
					estado_elementos_new[14] = true
				end
				JOYSTICK_LIMITE = control_FPS(1)

			-- Cambiar el estado de los elementos del submenú. --------------------------
			elseif (Pads.check(PAD, PAD_CROSS) or Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_RIGHT) or PALANCA(Left_X)) and CONTROL.JOYSTICK_ON == false then
				-- Activar / desactivar elemento. ---------------------------------------
				repro_sfx(S_EJECUTAR, 1, false, nil)
				if ((Pads.check(PAD, PAD_LEFT) or Left_X <= -90) or (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) or Pads.check(PAD, PAD_CROSS)) and selector_submenu <= 13 then
					if estado_elementos_new[selector_submenu] == false then
						estado_elementos_new[selector_submenu] = true
					else
						estado_elementos_new[selector_submenu] = false
					end

				-- Vista previa de la animación de transición. --------------------------
				elseif Pads.check(PAD, PAD_CROSS) and selector_submenu == 14 then
					Pads.rumble(0, 0, 0)
					animaciones(true, false)

				-- Cambiar entre las animaciones de transición disponibles. -------------
				elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector_submenu == 14 then
					CONTROL.CUSTOM_ANIM = cambiar_valor(CONTROL.CUSTOM_ANIM, 1, 15, 1, false)
				elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector_submenu == 14 then
					CONTROL.CUSTOM_ANIM = cambiar_valor(CONTROL.CUSTOM_ANIM, 1, 15, 1, true)

				-- Cambiar la velocidad de las animaciones de transición. ---------------
				elseif (Pads.check(PAD, PAD_LEFT) or Left_X <= -90) and selector_submenu == 15 then
					CONTROL.ANIM_VELOCIDAD = cambiar_valor(CONTROL.ANIM_VELOCIDAD, 10, 50, 1, false)
				elseif (Pads.check(PAD, PAD_RIGHT) or Left_X >= 90) and selector_submenu == 15 then
					CONTROL.ANIM_VELOCIDAD = cambiar_valor(CONTROL.ANIM_VELOCIDAD, 10, 50, 1, true)

				-- Reiniciar todas las posiciones y tamaños a los de por defecto. -------
				elseif Pads.check(PAD, PAD_CROSS) and selector_submenu == 16 then
					local confirmar = false
					local pregunta_res = true
					local lista_resp = {TEXT_GEN[11], TEXT_GEN[6]}
					submenu_selector({}, nil, "- ".. TEXT_M_STI[46] .." -", 160, 202, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
					refrescar(false)
					while pregunta_res do
						capturar(JOYSTICK_LIMITE)
						if Pads.check(PAD, PAD_SQUARE) then
							confirmar = true
							pregunta_res = false
							repro_sfx(S_EJECUTAR, 1, false, nil)
						elseif Pads.check(PAD, PAD_TRIANGLE) then
							confirmar = false
							pregunta_res = false
							repro_sfx(S_CANCELAR, 1, false, nil)
						end
						refrescar(true)
					end
					if confirmar == true then
						for restaura = 1, #elementos_pos_new do
							elementos_pos_new[restaura] = restaura_pos[restaura]
						end
						for restaura2 = 1, #elementos_tam_new do
							elementos_tam_new[restaura2] = restaura_tam[restaura2]
						end
						for restaura3 = 1, #estado_elementos_new do
							estado_elementos_new[restaura3] = restaura_estado[restaura3]
						end
						largo_lista = LISTAS.ELEMENTOS_LIST
						CONTROL.CUSTOM_ANIM, CONTROL.ANIM_VELOCIDAD = anterior_anim, anterior_anim_vel
						CONTROL.CUSTOM_BACK = true
						set_aspect()
					end

				-- Guardar configuración. -----------------------------------------------
				elseif Pads.check(PAD, PAD_CROSS) and selector_submenu == 17 then
					repro_sfx(S_EJECUTAR, 1, false, nil)
					local aplicar = guardar_style(estado_elementos_new, elementos_pos_new, elementos_tam_new, largo_lista, FONT_CNF)
					if aplicar == true then
						for actualiza = 1, #elementos_pos_new do
							elementos_pos_ant[actualiza] = elementos_pos_new[actualiza]
						end
						for actualiza2 = 1, #elementos_tam_new do
							elementos_tam_ant[actualiza2] = elementos_tam_new[actualiza2]
						end
						for actualiza3 = 1, #estado_elementos_new do
							estado_elementos_ant[actualiza3] = estado_elementos_new[actualiza3]
						end
						anterior_anim, anterior_anim_vel = CONTROL.CUSTOM_ANIM, CONTROL.ANIM_VELOCIDAD
						change_detector = true
					end

				-- Salir del editor. ----------------------------------------------------
				elseif Pads.check(PAD, PAD_CROSS) and selector_submenu == 18 then
					salida = true
				end
				JOYSTICK_LIMITE = control_FPS(1)
			end
		end

		-- Confirmar la salida del editor. ----------------------------------------------
		if salida == true then
			repro_sfx(S_CANCELAR, 1, false, nil)
			local cambio_realizado = false
			for chequeo1 = 1, #estado_elementos_new do
				if estado_elementos_new[chequeo1] ~= estado_elementos_ant[chequeo1] then
					cambio_realizado = true
				end
			end
			for chequeo2 = 1, #elementos_pos_new do
				if elementos_pos_new[chequeo2] ~= elementos_pos_ant[chequeo2] then
					cambio_realizado = true
				end
			end
			for chequeo3 = 1, #elementos_tam_new do
				if elementos_tam_new[chequeo3] ~= elementos_tam_ant[chequeo3] then
					cambio_realizado = true
				end
			end
			if CONTROL.CUSTOM_ANIM ~= anterior_anim or CONTROL.ANIM_VELOCIDAD ~= anterior_anim_vel then
				cambio_realizado = true
			end
			if cambio_realizado == true then
				local pregunta = true
				local lista_resp = {TEXT_GEN[7], TEXT_GEN[6]}
				submenu_selector({TEXT_M_CON[27]}, nil, TEXT_M_CON[26], 160, 226, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
				refrescar(false)
				while pregunta do
					capturar(JOYSTICK_LIMITE)
					if Pads.check(PAD, PAD_SQUARE) then
						CONTROL.CUSTOM_ANIM, CONTROL.ANIM_VELOCIDAD = anterior_anim, anterior_anim_vel
						editar = false
						pregunta = false
					elseif Pads.check(PAD, PAD_TRIANGLE) then
						repro_sfx(S_CANCELAR, 1, false, nil)
						pregunta = false
						salida = false
					end
					refrescar(true)
				end
			else
				editar = false
			end
			JOYSTICK_LIMITE = control_FPS(1)
		end

		-- Asegura que al menos una representación de listas esté activa. ---------------
		if estado_elementos_new[4] == true or estado_elementos_new[1] == false then
			estado_elementos_new[1] = false
			estado_elementos_new[2] = true
			elementos_pos_new[1], elementos_pos_new[2] = elementos_pos_new[3]-28, (elementos_pos_new[4]+elementos_tam_new[4])+14
			elementos_tam_new[1], elementos_tam_new[2] = elementos_tam_new[3]+(28*2), 50
		end
		refrescar(false)
	end
	-- Limpiar y restaurar tamaños en fuentes de texto. ---------------------------------
	Font.ftUnload(FONT_CNF)
	Font.ftSetPixelSize(CONTROL.fontARCA, OPCIONES.FONT_PIXEL_X, OPCIONES.FONT_PIXEL_Y)
	Font.ftSetPixelSize(CONTROL.fontABC, 70, 70)
	return change_detector
end

--- Líneas para cargar el estilo personalizado. -----------------------------------------
function cargar_style(fix_pal)
	-- Define y guarda las opciones por defecto. ----------------------------------------
	local function custom_style_default()
		CONTROL.IMG_ANCHO = 358; CONTROL.IMG_X = 250; CONTROL.IMG_ALTO = 92; CONTROL.IMG_Y = 193;
		CONTROL.IMG_ANCHO_2 = 358; CONTROL.IMG_X_2 = 250; CONTROL.IMG_ALTO_2 = 92; CONTROL.IMG_Y_2 = 193;
		CONTROL.LISTA_ANCHO = 30; CONTROL.LISTA_X = 310; CONTROL.LISTA_ALTO = 90; CONTROL.LISTA_Y = 290;
		CONTROL.LOGO_ANCHO = 194; CONTROL.LOGO_X = 252; CONTROL.LOGO_ALTO = 5; CONTROL.LOGO_Y = 76;
		CONTROL.FLOW_ANCHO = 30; CONTROL.FLOW_X = 160; CONTROL.FLOW_ALTO = 92; CONTROL.FLOW_Y = 103;
		CONTROL.FLOW_ANCHO_2 = 30; CONTROL.FLOW_X_2 = 160; CONTROL.FLOW_ALTO_2 = 92; CONTROL.FLOW_Y_2 = 103;
		CONTROL.X_BUTTON_X = 273; CONTROL.Y_BUTTON_X = 391; CONTROL.X_BUTTON_T = 44; CONTROL.Y_BUTTON_T = 391;
		CONTROL.X_BUTTON_S = 475; CONTROL.Y_BUTTON_S = 391; CONTROL.X_BUTTON_L1 = 144; CONTROL.Y_BUTTON_L1 = 28;
		CONTROL.X_BUTTON_R1 = 464; CONTROL.Y_BUTTON_R1 = 28; CONTROL.X_BUTTON_R3 = 260; CONTROL.Y_BUTTON_R3 = 391;
		CONTROL.X_BUTTON_STA = 423; CONTROL.Y_BUTTON_STA = 415; CONTROL.X_BUTTON_SEL = 45; CONTROL.Y_BUTTON_SEL = 415;
		CONTROL.CUSTOM_ANIM = 1; CONTROL.ANIM_VELOCIDAD = 29;
		CONTROL.CUSTOM_LIST = true; CONTROL.CUSTOM_ART1 = true; CONTROL.CUSTOM_ART2 = false;
		CONTROL.CUSTOM_FLOW = false; CONTROL.CUSTOM_LOGO = true; CONTROL.CUSTOM_BUTTON_X = true;
		CONTROL.CUSTOM_BUTTON_T = true; CONTROL.CUSTOM_BUTTON_S = true; CONTROL.CUSTOM_BUTTON_L1 = true;
		CONTROL.CUSTOM_BUTTON_R1 = true; CONTROL.CUSTOM_BUTTON_R3 = true; CONTROL.CUSTOM_BUTTON_STA = true;
		CONTROL.CUSTOM_BUTTON_SEL = true; CONTROL.CUSTOM_BACK = true;
		LISTAS.ELEMENTOS_LIST = 11;
		CONTROL.SPRITE_ANCHO = 286; CONTROL.SPRITE_X = 69; CONTROL.SPRITE_ALTO = 288; CONTROL.SPRITE_Y = 92;
		CONTROL.CUSTOM_SPRITE = false;
	end
	local function activ_opt(valor)
		local resultado = false
		if valor == 1 then
			resultado = true
		end
		return resultado
	end

	-- Cargar opciones guardadas. -------------------------------------------------------
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/System/Config/style.cfg") then
		local carga_de_style = System.openFile(actual .."/System/Config/style.cfg", FREAD)
		System.seekFile(carga_de_style, 0, SET)
		local size_config = System.sizeFile(carga_de_style)
		local temp2 = System.readFile(carga_de_style, size_config)
		System.closeFile(carga_de_style)
		local lista_style = {}
		lista_style = sub_string(temp2, "%d+", lista_style, true)
		if lista_style ~= nil and #lista_style == 62 then
			CONTROL.IMG_ANCHO = lista_style[1]; CONTROL.IMG_X = lista_style[2];
			CONTROL.IMG_ALTO = lista_style[3]; CONTROL.IMG_Y = lista_style[4];
			CONTROL.IMG_ANCHO_2 = lista_style[5]; CONTROL.IMG_X_2 = lista_style[6];
			CONTROL.IMG_ALTO_2 = lista_style[7]; CONTROL.IMG_Y_2 = lista_style[8];
			CONTROL.LISTA_ANCHO = lista_style[9]; CONTROL.LISTA_X = lista_style[10];
			CONTROL.LISTA_ALTO = lista_style[11]; CONTROL.LISTA_Y = lista_style[12];
			CONTROL.LOGO_ANCHO = lista_style[13]; CONTROL.LOGO_X = lista_style[14];
			CONTROL.LOGO_ALTO = lista_style[15]; CONTROL.LOGO_Y = lista_style[16];
			CONTROL.FLOW_ANCHO = lista_style[17]; CONTROL.FLOW_X = lista_style[18];
			CONTROL.FLOW_ALTO = lista_style[19]; CONTROL.FLOW_Y = lista_style[20];
			CONTROL.FLOW_ANCHO_2 = lista_style[21]; CONTROL.FLOW_X_2 = lista_style[22];
			CONTROL.FLOW_ALTO_2 = lista_style[23]; CONTROL.FLOW_Y_2 = lista_style[24];
			CONTROL.X_BUTTON_X = lista_style[25]; CONTROL.Y_BUTTON_X = lista_style[26];
			CONTROL.X_BUTTON_T = lista_style[27]; CONTROL.Y_BUTTON_T = lista_style[28];
			CONTROL.X_BUTTON_S = lista_style[29]; CONTROL.Y_BUTTON_S = lista_style[30];
			CONTROL.X_BUTTON_L1 = lista_style[31]; CONTROL.Y_BUTTON_L1 = lista_style[32];
			CONTROL.X_BUTTON_R1 = lista_style[33]; CONTROL.Y_BUTTON_R1 = lista_style[34];
			CONTROL.X_BUTTON_R3 = lista_style[35]; CONTROL.Y_BUTTON_R3 = lista_style[36];
			CONTROL.X_BUTTON_STA = lista_style[37]; CONTROL.Y_BUTTON_STA = lista_style[38];
			CONTROL.X_BUTTON_SEL = lista_style[39]; CONTROL.Y_BUTTON_SEL = lista_style[40];
			if lista_style[41] <= 15 and lista_style[1] >= 1 then
				CONTROL.CUSTOM_ANIM = lista_style[41];
			else
				CONTROL.CUSTOM_ANIM = 1;
			end
			if lista_style[42] <= 50 and lista_style[1] >= 10 then
				CONTROL.ANIM_VELOCIDAD = lista_style[42];
			else
				CONTROL.ANIM_VELOCIDAD = 29;
			end
			CONTROL.CUSTOM_LIST = activ_opt(lista_style[43])
			CONTROL.CUSTOM_ART1 = activ_opt(lista_style[44])
			CONTROL.CUSTOM_ART2 = activ_opt(lista_style[45])
			CONTROL.CUSTOM_FLOW = activ_opt(lista_style[46])
			CONTROL.CUSTOM_LOGO = activ_opt(lista_style[47])
			CONTROL.CUSTOM_BUTTON_X = activ_opt(lista_style[48])
			CONTROL.CUSTOM_BUTTON_T = activ_opt(lista_style[49])
			CONTROL.CUSTOM_BUTTON_S = activ_opt(lista_style[50])
			CONTROL.CUSTOM_BUTTON_L1 = activ_opt(lista_style[51])
			CONTROL.CUSTOM_BUTTON_R1 = activ_opt(lista_style[52])
			CONTROL.CUSTOM_BUTTON_R3 = activ_opt(lista_style[53])
			CONTROL.CUSTOM_BUTTON_STA = activ_opt(lista_style[54])
			CONTROL.CUSTOM_BUTTON_SEL = activ_opt(lista_style[55])
			LISTAS.ELEMENTOS_LIST = lista_style[56];
			CONTROL.CUSTOM_BACK = activ_opt(lista_style[57])
			CONTROL.SPRITE_ANCHO = lista_style[58]; CONTROL.SPRITE_X = lista_style[59];
			CONTROL.SPRITE_ALTO = lista_style[60]; CONTROL.SPRITE_Y = lista_style[61];
			CONTROL.CUSTOM_SPRITE = activ_opt(lista_style[62])
		else
			custom_style_default()
		end
	else
		custom_style_default()
	end
	if fix_pal == true then
		CONTROL.LISTA_ALTO = CONTROL.LISTA_ALTO + CONTROL.Y_FIX_PAL
		CONTROL.IMG_ALTO = CONTROL.IMG_ALTO + CONTROL.Y_FIX_PAL
		CONTROL.LOGO_ALTO = CONTROL.LOGO_ALTO + CONTROL.Y_FIX_PAL
		CONTROL.IMG_ALTO_2 = CONTROL.IMG_ALTO_2 + CONTROL.Y_FIX_PAL
		CONTROL.FLOW_ALTO = CONTROL.FLOW_ALTO + CONTROL.Y_FIX_PAL
		CONTROL.FLOW_ALTO_2 = CONTROL.FLOW_ALTO_2 + CONTROL.Y_FIX_PAL
		CONTROL.SPRITE_ALTO = CONTROL.SPRITE_ALTO + CONTROL.Y_FIX_PAL
	end
end

--- Líneas para guardar el estilo personalizado. ----------------------------------------
function guardar_style(estado_elementos_new, elementos_pos_new, elementos_tam_new, largo_lista, FONT_CNF)
	local actual = System.currentDirectory()
	JOYSTICK_LIMITE = control_FPS(1)
	-- Confirmar el guardado. -----------------------------------------------------------
	local submenu_lista = {}
	submenu_lista = sub_string(TEXT_M_STI[48], "[^\n]+", submenu_lista, false)
	local lista_resp = {TEXT_GEN[12], TEXT_GEN[6]}
	submenu_selector(submenu_lista, nil, TEXT_M_STI[47], 160, 274, true, CONTROL.ANCHO//2, lista_resp, false, false, {}, nil)
	refrescar(false)
	local confirmar = false
	local pregunta = true
	while pregunta do
		capturar(JOYSTICK_LIMITE)
		if Pads.check(PAD, PAD_TRIANGLE) then
			pregunta = false
			repro_sfx(S_CANCELAR, 1, false, nil)
		elseif Pads.check(PAD, PAD_SQUARE) then
			confirmar = true
			pregunta = false
			repro_sfx(S_EJECUTAR, 1, false, nil)
		end
		refrescar(true)
	end

	-- Guardar la configuración. --------------------------------------------------------
	if confirmar == true then
		-- Reubicar posiciones de elementos desactivados. -------------------------------
		local n1, n2 = 1, 2
		if estado_elementos_new[1] == false then
			n1, n2 = 3, 4
		end
		if estado_elementos_new[2] == false then
			elementos_pos_new[3], elementos_pos_new[4] = elementos_pos_new[n1], elementos_pos_new[n2]
			elementos_tam_new[3], elementos_tam_new[4] = elementos_tam_new[n1], elementos_tam_new[n2]
		end
		if estado_elementos_new[3] == false then
			elementos_pos_new[5], elementos_pos_new[6] = elementos_pos_new[n1], elementos_pos_new[n2]
			elementos_tam_new[5], elementos_tam_new[6] = elementos_tam_new[n1], elementos_tam_new[n2]
		end
		if estado_elementos_new[4] == false then
			elementos_pos_new[7], elementos_pos_new[8] = elementos_pos_new[n1], elementos_pos_new[n2]
			elementos_tam_new[7], elementos_tam_new[8] = elementos_tam_new[n1], elementos_tam_new[n2]
		end
		if estado_elementos_new[5] == false then
			elementos_pos_new[9], elementos_pos_new[10] = elementos_pos_new[n1], elementos_pos_new[n2]
			elementos_tam_new[9], elementos_tam_new[10] = elementos_tam_new[n1], elementos_tam_new[n2]
		end

		-- Convertir a número los elementos con valor booleano. -------------------------
		local estado_binario = {}
		for booleano = 1, #estado_elementos_new do
			if estado_elementos_new[booleano] == true then
				table.insert(estado_binario, "1")
			else
				table.insert(estado_binario, "0")
			end
		end
		if CONTROL.CUSTOM_BACK == true then
			table.insert(estado_binario, "1")
		else
			table.insert(estado_binario, "0")
		end

		-- Crear archivo de configuración para el estilo personalizado. -----------------
		local style_conf_final = ("".. elementos_pos_new[3] .." ".. elementos_tam_new[3] .." ".. elementos_pos_new[4] .." ".. elementos_tam_new[4] ..
		" ".. elementos_pos_new[5] .." ".. elementos_tam_new[5] .." ".. elementos_pos_new[6] .." ".. elementos_tam_new[6] .." ".. elementos_pos_new[1] ..
		" ".. elementos_tam_new[1] .." ".. elementos_pos_new[2] .." ".. elementos_tam_new[2] .." ".. elementos_pos_new[9] .." ".. elementos_tam_new[9] ..
		" ".. elementos_pos_new[10] .." ".. elementos_tam_new[10] .." ".. elementos_pos_new[7] .." ".. elementos_tam_new[7] .." ".. elementos_pos_new[8] ..
		" ".. elementos_tam_new[8] .." ".. (CONTROL.ANCHO-(elementos_pos_new[7]+elementos_tam_new[7])) .." ".. elementos_tam_new[7] ..
		" ".. elementos_pos_new[8] .." ".. elementos_tam_new[8] .." ".. elementos_pos_new[11] .." ".. elementos_pos_new[12] .." ".. elementos_pos_new[13] ..
		" ".. elementos_pos_new[14] .." ".. elementos_pos_new[15] .." ".. elementos_pos_new[16] .." ".. elementos_pos_new[17] .." ".. elementos_pos_new[18] ..
		" ".. elementos_pos_new[19] .." ".. elementos_pos_new[18] .." ".. elementos_pos_new[21] .." ".. elementos_pos_new[22] .." ".. elementos_pos_new[23] ..
		" ".. elementos_pos_new[24] .." ".. elementos_pos_new[25] .." ".. elementos_pos_new[26] .." ".. CONTROL.CUSTOM_ANIM .." ".. CONTROL.ANIM_VELOCIDAD ..
		" ".. estado_binario[1] .." ".. estado_binario[2] .." ".. estado_binario[3] .." ".. estado_binario[4] .." ".. estado_binario[5] ..
		" ".. estado_binario[6] .." ".. estado_binario[7] .." ".. estado_binario[8] .." ".. estado_binario[9] .." ".. estado_binario[10] ..
		" ".. estado_binario[11] .." ".. estado_binario[12] .." ".. estado_binario[13] .." ".. largo_lista-1 .." ".. estado_binario[15] ..
		" ".. elementos_pos_new[27] .." ".. elementos_tam_new[11] .." ".. elementos_pos_new[28] .." ".. elementos_tam_new[12] .." ".. estado_binario[14] ..
		"                                                                                                    ")

		-- Guardar archivo nuevo y crear respaldo del anterior. -------------------------
		if doesFileExist(actual .."/System/Config/style.cfg") then
			if doesFileExist(actual .."/System/Config/style_old.cfg") then
				System.removeFile(actual .."/System/Config/style_old.cfg")
			end
			System.rename(actual .."/System/Config/style.cfg", actual .."/System/Config/style_old.cfg")
		end
		local crear_style = System.openFile(actual .."/System/Config/style.cfg", FCREATE)
		System.writeFile(crear_style, style_conf_final, string.len(style_conf_final))
		System.closeFile(crear_style)
	end
	return confirmar
end
--[[------------------SPAGHETTICODE-------------------]]--