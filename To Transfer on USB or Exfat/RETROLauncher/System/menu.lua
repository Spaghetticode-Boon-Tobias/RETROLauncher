--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[------------------- v1.0/rev2 --------------------]]--

--[[Líneas para las funciones encargadas del menú principal de RETROLauncher.]]--
--- Líneas para dibujar elementos. ------------------------------------------------------
function dibujar_covers()
	if LISTAS.SCREENSHOT_FULL == false and #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
		-- Dibujar artes extras (Cover Flow). -------------------------------------------
		if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
			if CONTROL.CUSTOM_BACK == true then
				Graphics.drawRect(CONTROL.FLOW_ANCHO-5, CONTROL.FLOW_ALTO-5, CONTROL.FLOW_X+10, CONTROL.FLOW_Y+10, COLOR.NEGRO_T)
				Graphics.drawRect(CONTROL.FLOW_ANCHO_2-5, CONTROL.FLOW_ALTO_2-5, CONTROL.FLOW_X_2+10, CONTROL.FLOW_Y_2+10, COLOR.NEGRO_T)
			end
			dibujar_arte(LISTAS.COVER_ART2, LISTAS.EXISTE_COV2, LISTAS.COVER_DEFAULT, CONTROL.FLOW_ANCHO, CONTROL.FLOW_ALTO, CONTROL.FLOW_X, CONTROL.FLOW_Y, LISTAS.COV_1_X, LISTAS.COV_1_Y, LISTAS.COV_1_FIX, LISTAS.COV_1_FIX_Y, nil)
			dibujar_arte(LISTAS.COVER_ART3, LISTAS.EXISTE_COV3, LISTAS.COVER_DEFAULT, CONTROL.FLOW_ANCHO_2, CONTROL.FLOW_ALTO_2, CONTROL.FLOW_X_2, CONTROL.FLOW_Y_2, LISTAS.COV_2_X, LISTAS.COV_2_Y, LISTAS.COV_2_FIX, LISTAS.COV_2_FIX_Y, nil)
		end

		-- Dibujar arte extra. ----------------------------------------------------------
		if (CONTROL.ESTILO == 3 or CONTROL.ESTILO == 5 or CONTROL.ESTILO == 6 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_ART2 == true then
			dibujar_arte(LISTAS.SCREENSHOT, LISTAS.EXISTE_SCR, LISTAS.SCREENSHOT_DEFAULT, CONTROL.IMG_ANCHO_2, CONTROL.IMG_ALTO_2, CONTROL.IMG_X_2, CONTROL.IMG_Y_2, LISTAS.SCR_ART2_X, LISTAS.SCR_ART2_Y, LISTAS.SCR_FIX_ART2, LISTAS.SCR_FIX_Y_ART2, false)
		end
	end

	-- Dibujar fondo de lista. ----------------------------------------------------------
	if LISTAS.SCREENSHOT_FULL == false then
		if CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.CUSTOM_LIST == true then
			Graphics.drawRect(CONTROL.LISTA_ANCHO-3, CONTROL.LISTA_ALTO-3, CONTROL.LISTA_X+236+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
		elseif CONTROL.ESTILO ~= 2 and CONTROL.CUSTOM_LIST == true then
			Graphics.drawRect(CONTROL.LISTA_ANCHO-3, CONTROL.LISTA_ALTO-3, CONTROL.LISTA_X+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
		end
	end

	-- Dibujar listas. ------------------------------------------------------------------
	if #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
		generar_listas()
		Controles_Listas()
		cargar_art()
	elseif LISTAS.SCREENSHOT_FULL == false then
		empty_list()
	end

	-- Dibujar logo. --------------------------------------------------------------------
	if LISTAS.SCREENSHOT_FULL == false and CONTROL.CUSTOM_LOGO == true then
		Graphics.drawScaleImage(LISTAS.LOGO, CONTROL.LOGO_ANCHO, CONTROL.LOGO_ALTO, CONTROL.LOGO_X, CONTROL.LOGO_Y)
	end

	if LISTAS.SCREENSHOT_FULL == false and #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
		-- Dibujar indicadores. ---------------------------------------------------------
		if OPCIONES.GUI_LIMPIA_ON == 0 then
			dibujar_indicadores()
		end

		-- Dibujar cover / capturas / fondos. -------------------------------------------
		if CONTROL.CUSTOM_ART1 == true then
			if LISTAS.SCREENSHOT_ON == true then
				dibujar_arte(LISTAS.SCREENSHOT, LISTAS.EXISTE_SCR, LISTAS.SCREENSHOT_DEFAULT, CONTROL.IMG_ANCHO, CONTROL.IMG_ALTO, CONTROL.IMG_X, CONTROL.IMG_Y, LISTAS.SCR_X, LISTAS.SCR_Y, LISTAS.SCR_FIX, LISTAS.SCR_FIX_Y, true)
			else
				dibujar_arte(LISTAS.COVER_ART, LISTAS.EXISTE_COV, LISTAS.COVER_DEFAULT, CONTROL.IMG_ANCHO, CONTROL.IMG_ALTO, CONTROL.IMG_X, CONTROL.IMG_Y, LISTAS.COV_X, LISTAS.COV_Y, LISTAS.COV_FIX, LISTAS.COV_FIX_Y, true)
			end
			-- Indicador de soporte. Ademas del modo PS2 (manteniendo CIRCULO), se
			-- muestra "[ATA]" en CUALQUIER sistema cuando el juego proviene del disco
			-- interno exFAT montado por ata_bd.
			local medio = nil
			local juego_actual = nil
			if LISTAS.ROMS ~= nil then juego_actual = LISTAS.ROMS[LISTAS.INDICE] end

			if LISTAS.IDENTIDAD == 15 and Pads.check(PAD, PAD_CIRCLE) and juego_actual ~= nil then
				medio = "[USB]"
				local ext_t = string.lower(string.sub(juego_actual, -4))
				if ext_t == ".mx4" then
					medio = "[MX4SIO]"
				elseif ext_t == ".hdd" then
					medio = "[HDD]"
				elseif ext_t == ".mmc" then
					medio = "[MMCE]"
				elseif ext_t == ".udp" then
					medio = "[UDPBD]"
				end
			end

			if juego_actual ~= nil and ES_ATA ~= nil and ES_ATA(LISTAS.IDENTIDAD, juego_actual) then
				medio = "[ATA]"
			end

			if medio ~= nil then
				Graphics.drawRect((CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2))-50, (CONTROL.IMG_ALTO+CONTROL.IMG_Y)-20, 100, 22, COLOR.NEGRO)
				Font.ftPrint(CONTROL.fontARCA, (CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2)), (CONTROL.IMG_ALTO+CONTROL.IMG_Y)-18, 8, (CONTROL.IMG_ANCHO+CONTROL.IMG_X), 28, medio, COLOR.BLANCO_LISTA)
			end
		end

		-- Dibujar sprite. --------------------------------------------------------------
		if CONTROL.CUSTOM_SPRITE == true then
			dibujar_sprites(LISTAS.IDENTIDAD, CONTROL.SPRITE_ANCHO, CONTROL.SPRITE_ALTO, CONTROL.SPRITE_X, CONTROL.SPRITE_Y, 0.00, SPRITES.FLIP[1], SPRITES.FLIP[2], true)
		end
	end
end

--- Dibujar indicadores. ----------------------------------------------------------------
function dibujar_indicadores()
	-- Atajo L1+R1 (rejilla de sistemas). Solo con CIRCULO mantenido, y anclado a la
	-- posicion del logo del sistema, que el usuario puede mover desde las opciones:
	-- asi el indicador sigue el tema en vez de estar fijo en una esquina.
	if Pads.check(PAD, PAD_CIRCLE) and CONTROL.LOGO_ANCHO ~= nil then
		local ix = CONTROL.LOGO_ANCHO
		local iy = CONTROL.LOGO_ALTO - 24
		if iy < 2 then iy = CONTROL.LOGO_ALTO + (CONTROL.LOGO_Y or 0) + 4 end
		if ix < 2 then ix = 2 end
		if ix > 430 then ix = 430 end
		dibujar_indicador(ix, iy, "+", PAD_IMG.L1, 22, 22, 3, true)
		dibujar_indicador(ix + 30, iy, "System grid", PAD_IMG.R1, 22, 22, 3, true)
	end
	local message = {TEXT_M_PRI[2], TEXT_M_PRI[3], TEXT_M_PRI[4], TEXT_M_PRI[5], TEXT_M_PRI[6], TEXT_M_PRI[7], TEXT_M_PRI[8], TEXT_M_PRI[32], TEXT_M_PRI[34]}
	if CONTROL.ESTILO == 6 then
		message = {TEXT_GEN[7], TEXT_M_PRI[9], TEXT_M_PRI[10], TEXT_M_PRI[11], TEXT_M_PRI[12], TEXT_M_PRI[7], TEXT_M_PRI[31], TEXT_M_PRI[33], TEXT_M_PRI[34]}
	end

	-- Indicadores para cambio de sistemas. ---------------------------------------------
	if CONTROL.CUSTOM_BUTTON_L1 == true then
		Graphics.drawScaleImage(PAD_IMG.L1, CONTROL.X_BUTTON_L1, CONTROL.Y_BUTTON_L1+CONTROL.Y_FIX_PAL, 32, 32)
	end
	if CONTROL.CUSTOM_BUTTON_R1 == true then
		Graphics.drawScaleImage(PAD_IMG.R1, CONTROL.X_BUTTON_R1, CONTROL.Y_BUTTON_R1+CONTROL.Y_FIX_PAL, 32, 32)
	end

	-- Indicador de salida. -------------------------------------------------------------
	if CONTROL.CUSTOM_BUTTON_SEL == true then
		dibujar_indicador(CONTROL.X_BUTTON_SEL, CONTROL.Y_BUTTON_SEL, message[1], PAD_IMG.SELECT_S, 32, 32, 2, true)
	end

	-- Indicador de configuración. ------------------------------------------------------
	if CONTROL.CUSTOM_BUTTON_STA == true then
		dibujar_indicador(CONTROL.X_BUTTON_STA, CONTROL.Y_BUTTON_STA, message[2], PAD_IMG.START, 32, 32, 2, true)
	end

	-- Indicadores en listas. -----------------------------------------------------------
	if #LISTAS.ROMS >= 1 then
		-- Menu del juego. TRIANGULO ya no intercambia el arte -- eso es ahora una
		-- entrada del menu -- asi que el indicador dice "Menu" y no "Change art".
		-- Los rotulos de CIRCULO+TRIANGULO desaparecen tambien: esos ajustes estan
		-- dentro del menu, no hace falta anunciar una combinacion para llegar a ellos.
		if CONTROL.CUSTOM_BUTTON_T == true then
			dibujar_indicador(CONTROL.X_BUTTON_T, CONTROL.Y_BUTTON_T, "Game Menu", PAD_IMG.TRIANGLE, 25, 25, 1, true)
		end

		-- Arte a pantalla completa. ----------------------------------------------------
		if CONTROL.CUSTOM_BUTTON_S == true then
			dibujar_indicador(CONTROL.X_BUTTON_S, CONTROL.Y_BUTTON_S, message[4], PAD_IMG.SQUARE, 25, 25, 1, true)
		end

		-- Indicador de ejecución. ------------------------------------------------------
		if CONTROL.CUSTOM_BUTTON_X == true then
			if Pads.check(PAD, PAD_CIRCLE) and (LISTAS.IDENTIDAD == 1 or (LISTAS.IDENTIDAD >= 4 and LISTAS.IDENTIDAD <= 6) or LISTAS.IDENTIDAD == 13 or (LISTAS.IDENTIDAD == 15 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) == ".iso")) then
				dibujar_indicador(CONTROL.X_BUTTON_X, CONTROL.Y_BUTTON_X, message[8], PAD_IMG.CROSS, 25, 25, 1, true)
			else
				dibujar_indicador(CONTROL.X_BUTTON_X, CONTROL.Y_BUTTON_X, message[5], PAD_IMG.CROSS, 25, 25, 1, true)
			end
		end
	else
		-- Actualizar la lista. ---------------------------------------------------------
		if CONTROL.CUSTOM_BUTTON_R3 == true then
			dibujar_indicador(CONTROL.X_BUTTON_R3, CONTROL.Y_BUTTON_R3, message[6], PAD_IMG.R3, 25, 25, 1, true)
		end
	end
end

--- Dibujar listas vacías. --------------------------------------------------------------
function empty_list()
	if CONTROL.CUSTOM_BACK == true then
		if CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.CUSTOM_LIST == true then
			Graphics.drawRect(CONTROL.LISTA_ANCHO-3, CONTROL.LISTA_ALTO-3, CONTROL.LISTA_X+236+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
		elseif CONTROL.ESTILO ~= 2 and CONTROL.CUSTOM_LIST == true then
			Graphics.drawRect(CONTROL.LISTA_ANCHO-3, CONTROL.LISTA_ALTO-3, CONTROL.LISTA_X+6, CONTROL.LISTA_Y+6, COLOR.NEGRO_T)
		end
		if CONTROL.CUSTOM_ART1 == true then
			Graphics.drawRect(CONTROL.IMG_ANCHO-5, CONTROL.IMG_ALTO-5, CONTROL.IMG_X+10, CONTROL.IMG_Y+10, COLOR.NEGRO_T)
			Graphics.drawRect(CONTROL.IMG_ANCHO-5, CONTROL.IMG_ALTO-5, CONTROL.IMG_X+10, CONTROL.IMG_Y+10, COLOR.NEGRO_T)
		end
		if (CONTROL.ESTILO == 3 or CONTROL.ESTILO == 5 or CONTROL.ESTILO == 6 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_ART2 == true then
			Graphics.drawRect(CONTROL.IMG_ANCHO_2-5, CONTROL.IMG_ALTO_2-5, CONTROL.IMG_X_2+10, CONTROL.IMG_Y_2+10, COLOR.NEGRO_T)
			Graphics.drawRect(CONTROL.IMG_ANCHO_2-5, CONTROL.IMG_ALTO_2-5, CONTROL.IMG_X_2+10, CONTROL.IMG_Y_2+10, COLOR.NEGRO_T)
		end
		if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true then
			Graphics.drawRect(CONTROL.FLOW_ANCHO-5, CONTROL.FLOW_ALTO-5, CONTROL.FLOW_X+10, CONTROL.FLOW_Y+10, COLOR.NEGRO_T)
			Graphics.drawRect(CONTROL.FLOW_ANCHO_2-5, CONTROL.FLOW_ALTO_2-5, CONTROL.FLOW_X_2+10, CONTROL.FLOW_Y_2+10, COLOR.NEGRO_T)
			Graphics.drawRect(CONTROL.FLOW_ANCHO-5, CONTROL.FLOW_ALTO-5, CONTROL.FLOW_X+10, CONTROL.FLOW_Y+10, COLOR.NEGRO_T)
			Graphics.drawRect(CONTROL.FLOW_ANCHO_2-5, CONTROL.FLOW_ALTO_2-5, CONTROL.FLOW_X_2+10, CONTROL.FLOW_Y_2+10, COLOR.NEGRO_T)
		end
	end
	if (CONTROL.ESTILO == 2 or CONTROL.CUSTOM_LIST == false) and CONTROL.CUSTOM_ART1 == true then
		Font.ftPrint(CONTROL.fontARCA, CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2), CONTROL.IMG_ALTO+(CONTROL.IMG_Y//2)-44, 8, CONTROL.IMG_X, CONTROL.IMG_Y, TEXT_M_PRI[14], COLOR.BLANCO)
	elseif CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.CUSTOM_LIST == true then
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO+((CONTROL.LISTA_X+236)//2), CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//2)-20, 8, CONTROL.LISTA_X+236, CONTROL.LISTA_Y, TEXT_M_PRI[14], COLOR.BLANCO)
	elseif CONTROL.CUSTOM_LIST == true then
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO+(CONTROL.LISTA_X//2), CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//2)-30, 8, CONTROL.LISTA_X, CONTROL.LISTA_Y, TEXT_M_PRI[14], COLOR.BLANCO)
	end
	if OPCIONES.GUI_LIMPIA_ON == 0 then
		dibujar_indicadores()
	end
end

--- Mostrar error de ejecución. ---------------------------------------------------------
function error_run()
	local fx_inicio, fy_inicio, fx_final, fy_final = CONTROL.LISTA_ANCHO, CONTROL.LISTA_ALTO, CONTROL.LISTA_X, CONTROL.LISTA_Y
	local x_inicio, y_inicio, x_final, y_final = CONTROL.LISTA_ANCHO+(CONTROL.LISTA_X//2)-3, CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//4), CONTROL.LISTA_X, CONTROL.LISTA_Y
	if LISTAS.SCREENSHOT_FULL == true or ((CONTROL.LISTA_X <= 250 or CONTROL.LISTA_Y <= 118) and CONTROL.CUSTOM_LIST == true) or ((CONTROL.IMG_X <= 250 or CONTROL.IMG_Y <= 118) and CONTROL.CUSTOM_LIST == false) then
		fx_inicio, fy_inicio, fx_final, fy_final = 35, 14+CONTROL.Y_FIX_PAL, 570, 390
		x_inicio, y_inicio, x_final, y_final = 35+(570//2), (14+(390//2)-60)+CONTROL.Y_FIX_PAL, 570, 390
	elseif (CONTROL.ESTILO == 2 or CONTROL.CUSTOM_LIST == false) and CONTROL.CUSTOM_ART1 == true then
		fx_inicio, fy_inicio, fx_final, fy_final = CONTROL.IMG_ANCHO, CONTROL.IMG_ALTO, CONTROL.IMG_X, CONTROL.IMG_Y
		x_inicio, y_inicio, x_final, y_final = CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2)-1, CONTROL.IMG_ALTO+(CONTROL.IMG_Y//4), CONTROL.IMG_X, CONTROL.IMG_Y
	elseif CONTROL.ESTILO == 3 then
		if OPCIONES.GUI_LIMPIA_ON == 1 then
			x_inicio, y_inicio, x_final, fx_final = CONTROL.LISTA_ANCHO+((CONTROL.LISTA_X+236)//2)+2, CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//6), CONTROL.LISTA_X+236, CONTROL.LISTA_X+236
		else
			y_inicio = CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//6)
		end
	elseif CONTROL.ESTILO == 5 then
		y_inicio = CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//6)
	end
	local pausar = true
	JOYSTICK_LIMITE = control_FPS(1)
	dibujar()
	if LISTAS.SCREENSHOT_FULL == true or ((CONTROL.LISTA_X <= 250 or CONTROL.LISTA_Y <= 118) and CONTROL.CUSTOM_LIST == true) or ((CONTROL.IMG_X <= 250 or CONTROL.IMG_Y <= 118) and CONTROL.CUSTOM_LIST == false) then
		dibujar_fondos()
	end
	Graphics.drawRect(fx_inicio-2, fy_inicio-2, fx_final+4, fy_final+4, COLOR.BLANCO)
	Graphics.drawRect(fx_inicio, fy_inicio, fx_final, fy_final, COLOR.NEGRO)
	Font.ftPrint(CONTROL.fontARCA, x_inicio-2, y_inicio, 8, x_final, y_final, TEXT_M_PRI[15], COLOR.BLANCO)
	if LISTAS.IDENTIDAD <= 12 then
		-- "Games or RetroArch" no dice cual de los dos falta. Si existe() ha dejado el
		-- detalle -- "ROM not found", "No core for Atari Lynx" -- se dice eso.
		local mens = TEXT_M_PRI[16]
		if ERROR_DETALLE ~= nil and ERROR_DETALLE ~= "" then mens = ERROR_DETALLE end
		Font.ftPrint(CONTROL.fontARCA, x_inicio, y_inicio+19, 8, x_final, y_final, mens, COLOR.BLANCO)
	elseif LISTAS.IDENTIDAD == 13 then
		Font.ftPrint(CONTROL.fontARCA, x_inicio, y_inicio+19, 8, x_final, y_final, TEXT_M_PRI[17], COLOR.BLANCO)
	elseif LISTAS.IDENTIDAD == 14 then
		local mens_ps1 = TEXT_M_PRI[18]
		if string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) == ".cue" then mens_ps1 = TEXT_M_PRI[36] end
		-- Si existe() ha dejado un detalle, decir QUE falta y DONDE se esperaba,
		-- en vez del mensaje generico.
		if ERROR_DETALLE ~= nil and ERROR_DETALLE ~= "" then mens_ps1 = ERROR_DETALLE end
		Font.ftPrint(CONTROL.fontARCA, x_inicio, y_inicio+19, 8, x_final, y_final, mens_ps1, COLOR.BLANCO)
	elseif LISTAS.IDENTIDAD == 15 then
		Font.ftPrint(CONTROL.fontARCA, x_inicio, y_inicio+19, 8, x_final, y_final, TEXT_M_PRI[19], COLOR.BLANCO)
	end
	Font.ftPrint(CONTROL.fontARCA, x_inicio, y_inicio+38, 8, x_final, y_final, TEXT_M_PRI[20], COLOR.BLANCO)
	Font.ftPrint(CONTROL.fontARCA, x_inicio+8, y_inicio+59, 8, x_final, y_final, TEXT_GEN[4], COLOR.BLANCO)
	Graphics.drawScaleImage(PAD_IMG.TRIANGLE, x_inicio-49, y_inicio+59, 20, 20)
	refrescar(false)
	while pausar do
		capturar(JOYSTICK_LIMITE)
		if Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false then
			repro_sfx(S_CANCELAR, 1, true, nil)
			pausar = false
			JOYSTICK_LIMITE = control_FPS(1)
		end
	end
end

--- Líneas para ejecutar. ---------------------------------------------------------------
function run_game()
	repro_sfx(S_EJECUTAR, 1, false, nil)
	local alt = false
	-- Una ISO de PS2 no arranca nunca sin pasar por el menu de lanzamiento.
	--
	-- Una partida de PS2 se guarda en una tarjeta, y cual sea esa tarjeta decide si la
	-- partida sigue ahi manana. Lanzar primero y descubrir despues en que tarjeta se ha
	-- guardado no es una opcion: el menu se abre siempre, dice de que fichero sale la
	-- partida y con que lanzador arranca, y solo entonces se lanza.
	if LISTAS.IDENTIDAD == 15 and menu_lanzamiento ~= nil
	   and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) == ".iso" then
		if menu_lanzamiento(LISTAS.ROMS[LISTAS.INDICE]) == false then
			JOYSTICK_LIMITE = control_FPS(1)
			return
		end
		alt = LANZADOR_ES_OPL(LISTAS.ROMS[LISTAS.INDICE])
	elseif (((Pads.check(PAD, PAD_CROSS) and Pads.check(PAD, PAD_CIRCLE)) or OPCIONES.RUN_DEFAULT == 1) and (LISTAS.IDENTIDAD == 1 or (LISTAS.IDENTIDAD >= 4 and LISTAS.IDENTIDAD <= 6) or LISTAS.IDENTIDAD == 13)) then
		alt = alt_run(LISTAS.IDENTIDAD)
	end

	-- Verificar archivos. --------------------------------------------------------------
	local verificar = existe(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE], alt)
	if verificar == true then
		ejecutar_juego(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE], alt)
	elseif verificar == false and alt ~= nil then
		repro_sfx(S_CANCELAR, 3, false, nil)
		error_run()
		JOYSTICK_LIMITE = control_FPS(1)
	end
end

--- Líneas para controlar las listas. ---------------------------------------------------
function Controles_Listas()
	local move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = false, nil, false, 1, 1, true, false, false

	-- Salto de carácter. ---------------------------------------------------------------
	if (CONTROL.ESTILO ~= 2 and ((Pads.check(PAD, PAD_R2) and Pads.check(PAD, PAD_DOWN)) or (Left_X >= 90))) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and ((Pads.check(PAD, PAD_R2) and Pads.check(PAD, PAD_DOWN)) or (Left_Y >= 90))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras, CONTROL.ACT_FONTABC = true, false, true, 1, 1, true, true, true, true
	elseif (CONTROL.ESTILO ~= 2 and ((Pads.check(PAD, PAD_L2) and Pads.check(PAD, PAD_UP)) or (Left_X <= -90))) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and ((Pads.check(PAD, PAD_L2) and Pads.check(PAD, PAD_UP)) or (Left_Y <= -90))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras, CONTROL.ACT_FONTABC = true, true, true, 1, 1, false, true, true, true

	-- Movimiento lento. ----------------------------------------------------------------
	elseif (CONTROL.ESTILO ~= 2 and Pads.check(PAD, PAD_DOWN)) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and (Pads.check(PAD, PAD_RIGHT) or Pads.check(PAD, PAD_DOWN))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, false, true, 1, 1, true, false, true
	elseif (CONTROL.ESTILO ~= 2 and Pads.check(PAD, PAD_UP)) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and (Pads.check(PAD, PAD_LEFT) or Pads.check(PAD, PAD_UP))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, true, true, 1, 1, false, false, true

	-- Movimiento rápido. ---------------------------------------------------------------
	elseif (CONTROL.ESTILO ~= 2 and (Pads.check(PAD, PAD_RIGHT) or (Left_Y >= 90))) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and (Pads.check(PAD, PAD_R2) or (Left_X >= 90))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, false, true, 2, 1, true, false, true
	elseif (CONTROL.ESTILO ~= 2 and (Pads.check(PAD, PAD_LEFT) or (Left_Y <= -90))) or (((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and CONTROL.CUSTOM_FLOW == true) and (Pads.check(PAD, PAD_L2) or (Left_X <= -90))) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, true, true, 2, 1, false, false, true

	-- Salto de elementos. --------------------------------------------------------------
	elseif CONTROL.ESTILO ~= 2 and Pads.check(PAD, PAD_R2) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, false, true, 1, 11, true, false, false
	elseif CONTROL.ESTILO ~= 2 and Pads.check(PAD, PAD_L2) and CONTROL.JOYSTICK_ON == false then
		move, shake_type, shake_on, velociraptor, salto, suma, formato, extras = true, true, true, 1, 11, false, false, false

	-- Ejecutar juego. ------------------------------------------------------------------
	elseif Pads.check(PAD, PAD_CROSS) and CONTROL.JOYSTICK_ON == false then
		run_game()
	end

	-- Ejecutar movimientos. ------------------------------------------------------------
	if move == true then
		if formato == true then
			LISTAS.INDICE = letter_breaks(LISTAS.ROMS[LISTAS.INDICE], LISTAS.INDICE, suma)
		else
			LISTAS.INDICE = cambiar_valor(LISTAS.INDICE, 1, #LISTAS.ROMS, salto, suma)
		end
		if (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and extras == true and CONTROL.CUSTOM_FLOW == true then
			indices_extras()
		end
		JOYSTICK_LIMITE = control_FPS(velociraptor)
		LISTAS.SCROLL_TEX = 1
		reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
		LISTAS.SCREENSHOT_ON = false
		limpiar_art()
		LISTAS.MOSTRAR = 0-CONTROL.FPS
		if velociraptor == 1 then
			repro_sfx(S_MOVER, 1, shake_on, shake_type)
		end
	end

	-- Mostrar explorador para APPS. ----------------------------------------------------
	if LISTAS.IDENTIDAD == 13 and (Pads.check(PAD, PAD_CIRCLE) and Pads.check(PAD, PAD_TRIANGLE)) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		animaciones(nil, true)
		exporer_apps()

	-- Mostrar menú de configuración PS1. -----------------------------------------------
	elseif LISTAS.IDENTIDAD == 14 and (Pads.check(PAD, PAD_CIRCLE) and Pads.check(PAD, PAD_TRIANGLE)) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		if string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
			animaciones(nil, true)
			menu_pops(LISTAS.ROMS[LISTAS.INDICE])
		end

	-- Mostrar menú de configuración PS2. -----------------------------------------------
	elseif LISTAS.IDENTIDAD == 15 and (Pads.check(PAD, PAD_CIRCLE) and Pads.check(PAD, PAD_TRIANGLE)) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		if string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
			animaciones(nil, true)
			menu_neutrino(LISTAS.ROMS[LISTAS.INDICE])
		end

	-- Mostrar número de ROMs encontradas. ----------------------------------------------
	elseif Pads.check(PAD, PAD_CIRCLE) and LISTAS.SCREENSHOT_FULL == false then
		local text_con = TEXT_M_PRI[21] ..": "
		if LISTAS.IDENTIDAD == 13 then
			text_con = TEXT_M_PRI[22] ..": "
		end
		local fix_estilo = 28
		if ((CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and (CONTROL.CUSTOM_FLOW == true or CONTROL.CUSTOM_LIST == false)) or (CONTROL.ESTILO == 3 or CONTROL.ESTILO == 5) then
			fix_estilo = 24
		end
		Graphics.drawRect(CONTROL.LISTA_ANCHO-3, (CONTROL.LISTA_ALTO+CONTROL.LISTA_Y)-fix_estilo+1, CONTROL.LISTA_X+6, fix_estilo+1, COLOR.NEGRO)
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO+3, (CONTROL.LISTA_ALTO+CONTROL.LISTA_Y)-(fix_estilo-4), 0, CONTROL.LISTA_X-30, 25, text_con .. #LISTAS.ROMS, CAMBIOS_EMUS.COLOR_EMU)
	end
end

--- Mostrar salto de carácter. ----------------------------------------------------------
function abc()
	local x_inicio, y_inicio, fix_px = (CONTROL.LISTA_ANCHO+(CONTROL.LISTA_X//2))-3, CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//2)-52, 3
	if LISTAS.SCREENSHOT_FULL == true then
		x_inicio, y_inicio = 35+(570//2), (14+(390//2))+54
	elseif CONTROL.ESTILO == 7 and ((CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//2)-94 <= CONTROL.LISTA_ALTO and CONTROL.CUSTOM_LIST == true) or (CONTROL.IMG_Y <= 120 and CONTROL.CUSTOM_LIST == false)) then
		if CONTROL.CUSTOM_LIST == false then
			local acortar = CONTROL.IMG_Y//2
			if CONTROL.IMG_Y <= 88 then
				acortar = 26
			end
			x_inicio, y_inicio = CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2), (CONTROL.IMG_ALTO+CONTROL.IMG_Y)-acortar
		elseif CONTROL.CUSTOM_LIST == true then
			local acortar = CONTROL.LISTA_Y//2
			if CONTROL.LISTA_Y <= 88 then
				acortar = 26
			end
			x_inicio, y_inicio = CONTROL.LISTA_ANCHO+(CONTROL.LISTA_X//2), (CONTROL.LISTA_ALTO+CONTROL.LISTA_Y)-acortar
		end
	elseif (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and (CONTROL.CUSTOM_LIST == false or CONTROL.CUSTOM_FLOW == true) and CONTROL.CUSTOM_ART1 == true then
		x_inicio, y_inicio = CONTROL.IMG_ANCHO+(CONTROL.IMG_X//2), CONTROL.IMG_ALTO+(CONTROL.IMG_Y//2)+46
	elseif CONTROL.ESTILO == 3 or CONTROL.ESTILO == 5 then
		if OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.ESTILO == 3 then
			x_inicio = (CONTROL.LISTA_ANCHO+((CONTROL.LISTA_X+236)//2))
		end
		y_inicio = CONTROL.LISTA_ALTO+(CONTROL.LISTA_Y//2)
	end
	if OPCIONES.CAMBIO_FUENTE_ON ~= 1 then
		fix_px = 0
	end
	Graphics.drawRect(x_inicio-37, y_inicio-42+CONTROL.Y_FIX_PAL, 74, 68, COLOR.NEGRO)
	Font.ftPrint(CONTROL.fontABC, x_inicio+fix_px, y_inicio+CONTROL.Y_FIX_PAL, 8, 70, 70, string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, 1), COLOR.BLANCO)
end

--- Scroll de texto. --------------------------------------------------------------------
function create_scroll(limite)
	local n_text = ""
	if OPCIONES.SEE_INDEX == 1 then
		n_text = LISTAS.INDICE .."."
	end
	if CONTROL.ESPERA_CARGA_SCR == false then
		if OPCIONES.GUI_LIMPIA_ON == 1 and CONTROL.ESTILO == 3 then
			LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, n_text .. NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE]), 42)
		else
			LISTAS.SCROLL_TEX = scroll_texto(LISTAS.SCROLL_TEX, n_text .. NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE]), limite)
		end
	end
	if (LISTAS.IDENTIDAD == 15 or LISTAS.IDENTIDAD == 14) and string.match(string.sub(LISTAS.ROMS[LISTAS.INDICE], 1, 12), "%a+_%d+%.%d+%.") and LISTAS.SCROLL_TEX <= 13 then
		LISTAS.SCROLL_TEX = 13
	end
end

--- Dibuja elementos de la lista. -------------------------------------------------------
function mostrar_lista(pos_linea, elemento, n_ele)
	local largo, n_text = CONTROL.LISTA_X, ""
	if OPCIONES.SEE_INDEX == 1 then
		n_text = n_ele .."."
	end
	if CONTROL.ESTILO == 3 and OPCIONES.GUI_LIMPIA_ON == 1 then
		largo = CONTROL.LISTA_X+236
	end
	-- Prefijo de la lista: soporte y extension. El nombre se sigue mostrando sin su
	-- extension (CONTROL.EXTENSION la recorta), asi que la etiqueta es la unica
	-- forma de distinguir un ".zip" de una rom suelta.
	--   "[ATA]" : el juego viene del disco interno exFAT.
	--   "[ZIP]" : archivo comprimido. Los cores de RetroArch en PS2 no siempre
	--            saben abrirlos, aunque el launcher los liste.
	-- Solo con CIRCULO mantenido, como el indicador de soporte de PS2. Mostrarlo
	-- siempre alargaba el texto sin que "scroll_texto" lo supiera, y el desplazamiento
	-- del titulo seleccionado dejaba de arrancar.
	local function prefijo_lista(idx)
		if Pads.check(PAD, PAD_CIRCLE) == false then return "" end
		if LISTAS.ROMS == nil or LISTAS.ROMS[idx] == nil then return "" end
		local nom = LISTAS.ROMS[idx]
		local pre = ""

		-- APPS (identidad 13): la lista solo guarda el nombre, la ruta completa esta
		-- en LISTAS.DIR_FULL_APP. Se etiqueta segun la unidad de esa ruta.
		if LISTAS.IDENTIDAD == 13 and LISTAS.DIR_FULL_APP ~= nil
		   and LISTAS.DIR_FULL_APP[idx] ~= nil then
			local ruta = LISTAS.DIR_FULL_APP[idx]
			if ES_RAIZ_ATA ~= nil and ES_RAIZ_ATA(ruta) then
				pre = "[ATA]"
			elseif string.sub(string.lower(ruta), 1, 4) == "mass" then
				pre = "[USB]"
			elseif string.sub(string.lower(ruta), 1, 2) == "mc" then
				pre = "[MC]"
			elseif string.sub(string.lower(ruta), 1, 4) == "cdfs" then
				pre = "[CD]"
			end
		elseif ES_ATA ~= nil and ES_ATA(LISTAS.IDENTIDAD, nom) then
			pre = "[ATA]"
		end

		-- El scan anade un espacio al final para las extensiones de 3 letras.
		local limpio = nom
		while string.sub(limpio, -1) == " " do limpio = string.sub(limpio, 1, -2) end
		local punto = string.find(string.reverse(limpio), ".", 1, true)
		if punto ~= nil and punto >= 2 and punto <= 5 then
			pre = pre .. string.lower(string.sub(limpio, -punto))
		end

		if pre ~= "" then pre = pre .." " end
		return pre
	end

	if elemento ~= 0 then
		local fix_ini_name = 1
		if (LISTAS.IDENTIDAD == 15 or LISTAS.IDENTIDAD == 14) and string.match(string.sub(LISTAS.ROMS[elemento], 1, 12), "%a+_%d+%.%d+%.") then
			fix_ini_name = 13
		end
		-- Verde: la ROM ya esta en la llave, arrancarla no copia nada. Es un aviso de
		-- cuanto va a tardar el lanzamiento, que en USB 1.1 no es indiferente.
		local col = COLOR.BLANCO_LISTA
		if EN_CACHE_USB ~= nil and EN_CACHE_USB(LISTAS.IDENTIDAD, LISTAS.ROMS[elemento]) then
			if COLOR.VERDE_LISTA == nil then COLOR.VERDE_LISTA = Color.new(0, 128, 45) end
			col = COLOR.VERDE_LISTA
		end
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO+3, pos_linea, 0, largo-6, 25, n_text .. prefijo_lista(elemento) .. NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[elemento], fix_ini_name), col)
	else
		-- La linea seleccionada. Se distinguia SOLO por el color, y desde que un juego
		-- ya presente en la llave se pinta en verde eso dejo de bastar: dos colores
		-- distintos del blanco y ninguno quiere decir "aqui estoy". Una flecha lo dice
		-- sin depender de ningun color.
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO-9, pos_linea, 0, 14, 25, ">", CAMBIOS_EMUS.COLOR_EMU)
		Font.ftPrint(CONTROL.fontARCA, CONTROL.LISTA_ANCHO+3, pos_linea, 0, largo-6, 25, n_text .. prefijo_lista(LISTAS.INDICE) .. NOMBRE_VISIBLE(LISTAS.IDENTIDAD, LISTAS.ROMS[LISTAS.INDICE], LISTAS.SCROLL_TEX), CAMBIOS_EMUS.COLOR_EMU)
	end
end

--- Dibuja las listas. ------------------------------------------------------------------
function dibujar_lista(limite, extras, largo_extra)
	local max_lista = 0
	if LISTAS.SCREENSHOT_FULL == false then
		for contador = 0, limite, 1 do
			local espacio_linea = CONTROL.LISTA_ALTO+((contador)*24)
			if contador == 0 then
				mostrar_lista(espacio_linea, contador, LISTAS.INDICE)
			elseif (LISTAS.INDICE+contador) <= #LISTAS.ROMS then
				mostrar_lista(espacio_linea, (LISTAS.INDICE+contador), LISTAS.INDICE+contador)
			elseif max_lista <= LISTAS.INDICE-2 then
				-- La vuelta al principio de la lista.
				--
				-- La lista se dibuja desde el juego seleccionado hacia abajo, y al
				-- llegar al final vuelve al primero. Esta rama es esa vuelta, y estaba
				-- condicionada a "#LISTAS.ROMS >= limite+1": solo daba la vuelta si
				-- habia mas juegos que lineas en pantalla.
				--
				-- Con una lista mas corta que la pantalla, entonces, NADA de lo que
				-- estuviera antes del cursor se dibujaba. Con dos juegos de SNES y el
				-- cursor en el segundo, el primero simplemente no existia: la lista
				-- decia "2 found" y mostraba uno. Con el cursor en el primero se veian
				-- los dos, que es lo que hacia el asunto desconcertante.
				--
				-- El limite correcto no tiene que ver con el tamano de la pantalla sino
				-- con el cursor: se vuelve al principio hasta llegar al juego anterior
				-- al seleccionado, y ni uno mas. Asi se dibujan todos y ninguno dos
				-- veces, tanto si la lista cabe en pantalla como si no.
				max_lista = max_lista+1
				mostrar_lista(espacio_linea, max_lista, max_lista)
			end
			if extras == true then
				if contador == 2 then
					Graphics.drawRect(CONTROL.LISTA_ANCHO, espacio_linea-4, largo_extra, 24, Color.new(0, 0, 0, 30))
				end
				if contador == 3 then
					Graphics.drawRect(CONTROL.LISTA_ANCHO, espacio_linea-4, largo_extra, 24, Color.new(0, 0, 0, 45))
				end
				if contador == 4 then
					Graphics.drawRect(CONTROL.LISTA_ANCHO, espacio_linea-4, largo_extra, 24, Color.new(0, 0, 0, 60))
				end
				if contador == 5 then
					Graphics.drawRect(CONTROL.LISTA_ANCHO, espacio_linea-4, largo_extra, 24, Color.new(0, 0, 0, 70))
				end
			end
		end
	end
end

--- Líneas para mostrar listas. ---------------------------------------------------------
function generar_listas()
	-- Tiempos de scroll y arte. --------------------------------------------------------
	tiempo_de_scroll()
	tiempo_arte()

	-- Mostrar listas / estilo 1 / estilo 4 / estilo 6. ---------------------------------
	if CONTROL.ESTILO == 1 or CONTROL.ESTILO == 4 or CONTROL.ESTILO == 6 then
		create_scroll(OPCIONES.SCROLL_MIN)
		dibujar_lista(11, false, 0)

	-- Mostrar listas / estilo 2. -------------------------------------------------------
	elseif (CONTROL.ESTILO == 2 or CONTROL.ESTILO == 7) and (CONTROL.CUSTOM_FLOW == true or CONTROL.CUSTOM_LIST == false) then
		create_scroll(OPCIONES.SCROLL_MIN)
		if LISTAS.SCREENSHOT_FULL == false then
			local n_text, n_text_2, n_text_3 = "", "", ""
			if OPCIONES.SEE_INDEX == 1 then
				n_text, n_text_2, n_text_3 = LISTAS.INDICE ..".", LISTAS.INDICE2 ..".", LISTAS.INDICE3 .."."
			end
			if CONTROL.CUSTOM_FLOW == true then
				-- Mostrar arte / izquierda / estilo 2. ---------------------------------
				Graphics.drawRect(CONTROL.FLOW_ANCHO, (CONTROL.FLOW_ALTO+CONTROL.FLOW_Y)+10, CONTROL.FLOW_X, 25, COLOR.NEGRO_T)
				local fix_ini_name1 = 1
				if (LISTAS.IDENTIDAD == 15 or LISTAS.IDENTIDAD == 14) and string.match(string.sub(LISTAS.ROMS[LISTAS.INDICE2], 1, 12), "%a+_%d+%.%d+%.") then
					fix_ini_name1 = 13
				end
				Font.ftPrint(CONTROL.fontARCA, CONTROL.FLOW_ANCHO+5, (CONTROL.FLOW_ALTO+CONTROL.FLOW_Y)+12, 0, CONTROL.FLOW_X-10, 25, n_text_2 .. string.sub(LISTAS.ROMS[LISTAS.INDICE2], fix_ini_name1, -CONTROL.EXTENSION), COLOR.BLANCO_LISTA)

				-- Mostrar arte / derecha / estilo 2. -----------------------------------
				Graphics.drawRect(CONTROL.FLOW_ANCHO_2, (CONTROL.FLOW_ALTO_2+CONTROL.FLOW_Y_2)+10, CONTROL.FLOW_X_2, 25, COLOR.NEGRO_T)
				local fix_ini_name2 = 1
				if (LISTAS.IDENTIDAD == 15 or LISTAS.IDENTIDAD == 14) and string.match(string.sub(LISTAS.ROMS[LISTAS.INDICE3], 1, 12), "%a+_%d+%.%d+%.") then
					fix_ini_name2 = 13
				end
				Font.ftPrint(CONTROL.fontARCA, CONTROL.FLOW_ANCHO_2+5, (CONTROL.FLOW_ALTO_2+CONTROL.FLOW_Y_2)+12, 0, CONTROL.FLOW_X_2-10, 25, n_text_3 .. string.sub(LISTAS.ROMS[LISTAS.INDICE3], fix_ini_name2, -CONTROL.EXTENSION), COLOR.BLANCO_LISTA)
			end

			-- Mostrar arte / centro / estilo 2. ----------------------------------------
			Graphics.drawRect(CONTROL.IMG_ANCHO-31, (CONTROL.IMG_ALTO+CONTROL.IMG_Y)+14, CONTROL.IMG_X+62, 25, COLOR.NEGRO_T)
			Font.ftPrint(CONTROL.fontARCA, (CONTROL.IMG_ANCHO-31)+5, (CONTROL.IMG_ALTO+CONTROL.IMG_Y)+16, 0, (CONTROL.IMG_X+62)-5, 25, n_text .. string.sub(LISTAS.ROMS[LISTAS.INDICE], LISTAS.SCROLL_TEX, -CONTROL.EXTENSION), CAMBIOS_EMUS.COLOR_EMU)
		end

	-- Mostrar listas / estilo 3. -------------------------------------------------------
	elseif CONTROL.ESTILO == 3 then
		local largo = CONTROL.LISTA_X
		if OPCIONES.GUI_LIMPIA_ON == 1 then
			largo = CONTROL.LISTA_X+236
		end
		create_scroll(OPCIONES.SCROLL_MIN)
		dibujar_lista(5, true, largo)

	-- Mostrar listas / estilo 5. -------------------------------------------------------
	elseif CONTROL.ESTILO == 5 then
		create_scroll(OPCIONES.SCROLL_MIN-1)
		dibujar_lista(4, true, CONTROL.LISTA_X)

	-- Mostrar listas / estilo 7. -------------------------------------------------------
	elseif CONTROL.ESTILO == 7 and CONTROL.CUSTOM_FLOW == false and CONTROL.CUSTOM_LIST == true then
		create_scroll(OPCIONES.SCROLL_MIN)
		dibujar_lista(LISTAS.ELEMENTOS_LIST, false, 0)
	end
end

--- Dibujar y controlar RETROLauncher. --------------------------------------------------
function dibujar()
	-- Capturar controles. --------------------------------------------------------------
	capturar(JOYSTICK_LIMITE)

	-- Dibujar fondos. ------------------------------------------------------------------
	dibujar_fondos()
	if LISTAS.SCREENSHOT ~= nil and LISTAS.EXISTE_SCR == true and OPCIONES.SCREENSHOT_BACK_ON == 1 then
		Graphics.drawScaleImage(LISTAS.SCREENSHOT, -5, 0, CONTROL.ANCHO+5, CONTROL.ALTO_F, Color.new(128, 128, 128, OPCIONES.SCREENSHOT_BACK_TR))
	end

	-- Dibujar listas y arte. -----------------------------------------------------------
	dibujar_covers()

	-- L1 + R1 a la vez: rejilla de seleccion de sistema. -------------------------------
	-- SELECT, L3, R3, START, L2 y R2 ya estan ocupados en este menu, de ahi la
	-- combinacion. Cada gatillo por separado sigue encadenando los sistemas.
	if Pads.check(PAD, PAD_L1) and Pads.check(PAD, PAD_R1) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		LAST_MOVE[LISTAS.IDENTIDAD] = LISTAS.INDICE
		local elegido = selector_sistemas(dibujar_fondos)
		if elegido ~= nil and elegido ~= LISTAS.IDENTIDAD then
			ir_a_sistema(elegido)
			LISTAS.SCROLL_TEX = 1
			reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
			animaciones(true, false)
			LISTAS.SCREENSHOT_ON = false
			limpiar_art()
			LISTAS.MOSTRAR = 0-CONTROL.FPS
		end
		-- Bloqueo largo: evita que la pulsacion de salida de la rejilla se propague.
		JOYSTICK_LIMITE = control_FPS(1)-40

	-- Cambiar de sistema. --------------------------------------------------------------
	elseif (Pads.check(PAD, PAD_R1) or Pads.check(PAD, PAD_L1)) and CONTROL.JOYSTICK_ON == false then
		local disabled, side = false, true
		if Pads.check(PAD, PAD_L1) then
			disabled, side = true, false
		end
		LAST_MOVE[LISTAS.IDENTIDAD] = LISTAS.INDICE
		desactivados(disabled)
		if LAST_MOVE[LISTAS.IDENTIDAD] <= #LISTAS.ROMS then
			LISTAS.INDICE = LAST_MOVE[LISTAS.IDENTIDAD]
		else
			LISTAS.INDICE = 1
			LAST_MOVE[LISTAS.IDENTIDAD] = 1
		end
		indices_extras()
		repro_sfx(S_NETX, 1, true, disabled)
		JOYSTICK_LIMITE = control_FPS(2)
		LISTAS.SCROLL_TEX = 1
		reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
		animaciones(side, false)
		LISTAS.SCREENSHOT_ON = false
		limpiar_art()
		LISTAS.MOSTRAR = 0-CONTROL.FPS
	end

	-- Menu del juego. TRIANGULO abria solo el intercambio de arte; ahora abre una
	-- lista donde ese intercambio es una entrada mas, junto al borrado y a los
	-- ajustes del sistema en curso. Nada se pierde y todo queda a la vista.
	if Pads.check(PAD, PAD_TRIANGLE) and CONTROL.JOYSTICK_ON == false
	   and LISTAS.ROMS ~= nil and #LISTAS.ROMS >= 1 then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		menu_juego()
	end

	-- Mostrar arte a pantalla completa. ------------------------------------------------
	if Pads.check(PAD, PAD_SQUARE) and CONTROL.JOYSTICK_ON == false then
		if LISTAS.SCREENSHOT_FULL == false then
			LISTAS.SCREENSHOT_FULL = true
		else
			LISTAS.SCREENSHOT_FULL = false
		end
		JOYSTICK_LIMITE = control_FPS(1)
		repro_sfx(S_CANCELAR, 1, true, nil)
	end

	-- Dibujar arte a pantalla completa. ------------------------------------------------
	if LISTAS.SCREENSHOT_FULL == true then
		local mostar_extras = false
		local Right_m_X, Right_m_Y = Pads.getRightStick(0)
		if LISTAS.SCREENSHOT_ON == true and #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
			dibujar_arte(LISTAS.SCREENSHOT, LISTAS.EXISTE_SCR, LISTAS.SCREENSHOT_DEFAULT, 35, 14+CONTROL.Y_FIX_PAL, 570, 390, LISTAS.EX_FIX_S, LISTAS.EX_FIX_S_Y, (570-LISTAS.EX_FIX_S)//2, (390-LISTAS.EX_FIX_S_Y)//2, true)
			if (Right_m_X ~= 1 or Right_m_Y ~= 1) and LISTAS.EXISTE_SCR == true then
				mostar_extras = true
			end
		elseif #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
			dibujar_arte(LISTAS.COVER_ART, LISTAS.EXISTE_COV, LISTAS.COVER_DEFAULT, 35, 14+CONTROL.Y_FIX_PAL, 570, 390, LISTAS.EX_FIX_C, LISTAS.EX_FIX_C_Y, (570-LISTAS.EX_FIX_C)//2, (390-LISTAS.EX_FIX_C_Y)//2, true)
			if (Right_m_X ~= 1 or Right_m_Y ~= 1) and LISTAS.EXISTE_COV == true then
				mostar_extras = true
			end
		end

		-- Mostrar nombre del juego. ----------------------------------------------------
		if mostar_extras == false and #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
			local n_text = ""
			if OPCIONES.SEE_INDEX == 1 then
				n_text = LISTAS.INDICE .."."
			end
			Graphics.drawRect(165, 398+CONTROL.Y_FIX_PAL, 310, 20, COLOR.NEGRO)
			Font.ftPrint(CONTROL.fontARCA, 170, 398+CONTROL.Y_FIX_PAL, 0, 307, 2, n_text .. string.sub(LISTAS.ROMS[LISTAS.INDICE], LISTAS.SCROLL_TEX, -CONTROL.EXTENSION), CAMBIOS_EMUS.COLOR_EMU)
		end

		-- Dibujar indicadores de listas. -----------------------------------------------
		if mostar_extras == false then
			if OPCIONES.GUI_LIMPIA_ON == 0 and #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil then
				if CONTROL.CUSTOM_BUTTON_T == true then
					if Pads.check(PAD, PAD_CIRCLE) and (LISTAS.IDENTIDAD == 15 or LISTAS.IDENTIDAD == 14) 
					and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) ~= ".elf" then
						dibujar_indicador(44, 422, TEXT_M_PRI[8], PAD_IMG.TRIANGLE, 20, 20, 3, true)
					elseif Pads.check(PAD, PAD_CIRCLE) and LISTAS.IDENTIDAD == 13 then
						dibujar_indicador(44, 422, TEXT_M_PRI[34], PAD_IMG.TRIANGLE, 20, 20, 3, true)
					else
						dibujar_indicador(44, 422, TEXT_M_PRI[4], PAD_IMG.TRIANGLE, 20, 20, 3, true)
					end
				end
				if CONTROL.CUSTOM_BUTTON_S == true then
					dibujar_indicador(473, 422, TEXT_M_PRI[5], PAD_IMG.SQUARE, 20, 20, 3, true)
				end
				if CONTROL.CUSTOM_BUTTON_X == true then
					if Pads.check(PAD, PAD_CIRCLE) and (LISTAS.IDENTIDAD == 1 or (LISTAS.IDENTIDAD >= 4 and LISTAS.IDENTIDAD <= 6) or LISTAS.IDENTIDAD == 13 or (LISTAS.IDENTIDAD == 15 and string.lower(string.sub(LISTAS.ROMS[LISTAS.INDICE], -4)) == ".iso")) then
						dibujar_indicador(277, 422, TEXT_M_PRI[32], PAD_IMG.CROSS, 20, 20, 3, true)
					else
						dibujar_indicador(277, 422, TEXT_M_PRI[6], PAD_IMG.CROSS, 20, 20, 3, true)
					end
				end
			elseif OPCIONES.GUI_LIMPIA_ON == 0 then
				if CONTROL.CUSTOM_BUTTON_R3 == true then
					dibujar_indicador(255, 422, TEXT_M_PRI[7], PAD_IMG.R3, 20, 20, 3, true)
				end
			end
			if #LISTAS.ROMS <= 0 or LISTAS.ROMS == nil then
				if CONTROL.CUSTOM_BACK == true then
					Graphics.drawRect(35, 14+CONTROL.Y_FIX_PAL, 570, 390, COLOR.NEGRO_T)
					Graphics.drawRect(35, 14+CONTROL.Y_FIX_PAL, 570, 390, COLOR.NEGRO_T)
				end
				Font.ftPrint(CONTROL.fontARCA, 35+(570//2), (14+(390//2)-24)+CONTROL.Y_FIX_PAL, 8, 570, 390, TEXT_M_PRI[14], COLOR.BLANCO)
			end
		end
	end

	-- Dibujar salto de carácter. -------------------------------------------------------
	if #LISTAS.ROMS >= 1 and LISTAS.ROMS ~= nil and CONTROL.ACT_FONTABC == true and CONTROL.JOYSTICK_ON == true then
		abc()
	else
		CONTROL.ACT_FONTABC = false
	end

	-- Entrar en configuraciones. -------------------------------------------------------
	if Pads.check(PAD, PAD_START) then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		JOYSTICK_LIMITE = control_FPS(1)
		animaciones(nil, true)
		menu_config()
	end

	-- Ver controles de RETROLauncher. --------------------------------------------------
	if ((Pads.check(PAD, PAD_R3) or Pads.check(PAD, PAD_CIRCLE)) and Pads.check(PAD, PAD_L3)) and CONTROL.JOYSTICK_ON == false then
		JOYSTICK_LIMITE = control_FPS(1)
		ver_controles(false)
	end

	-- Refrescar lista actual. ----------------------------------------------------------
	if Pads.check(PAD, PAD_R3) and not Pads.check(PAD, PAD_L3) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_EJECUTAR, 1, false, nil)
		recargar_una(LISTAS.IDENTIDAD)
		LISTAS.ROMS = nil
		LISTAS.ROMS = PRE_CARGADAS[LISTAS.IDENTIDAD]
		LISTAS.INDICE = 1
		indices_extras()
		reset_tiempo_espera(-CONTROL.FPS-CONTROL.FPS)
		limpiar_art()
		LISTAS.MOSTRAR = 0-CONTROL.FPS
		JOYSTICK_LIMITE = control_FPS(1)
	end

	-- Reiniciar / Salir de RETROLauncher. ----------------------------------------------
	if ((Pads.check(PAD, PAD_L3) and not Pads.check(PAD, PAD_R3)) or Pads.check(PAD, PAD_SELECT)) and CONTROL.JOYSTICK_ON == false then
		repro_sfx(S_CANCELAR, 1, false, nil)
		local actual, pregunta, salir, lista_resp, text_prin = System.currentDirectory(), true, nil, {TEXT_GEN[11], TEXT_GEN[6]}, TEXT_M_PRI[23]
		if Pads.check(PAD, PAD_SELECT) then
			lista_resp, text_prin, salir = {TEXT_GEN[1], TEXT_GEN[6]}, TEXT_M_PRI[24], true
		end
		submenu_selector({}, 0, text_prin, 160, 202, true, (CONTROL.ANCHO//2), lista_resp, true, false, {}, nil)
		refrescar(false)
		while pregunta do
			capturar(JOYSTICK_LIMITE)
			if Pads.check(PAD, PAD_CROSS) then
				repro_sfx(S_EJECUTAR, 1, false, nil)
				if doesFileExist(actual .."/uLaunchELF/WLE.elf") and (OPCIONES.SALIDA_RETROLANCHER_ON ~= 0 or salir == nil) then
					app_alt(salir)
					System.loadELF(actual .."/uLaunchELF/WLE.elf", 0, actual .."/uLaunchELF/")
				elseif salir == true and OPCIONES.SALIDA_RETROLANCHER_ON ~= 0 then
					System.loadELF(OPCIONES.SALIDA_RETROLANCHER, 0, salida_texto_dir(OPCIONES.SALIDA_RETROLANCHER, false))
				elseif salir == true then
					System.exitToBrowser()
				else
					System.loadELF(actual .."/RETROLauncher.elf", 0, actual .."/System/system.lua")
				end
			elseif Pads.check(PAD, PAD_CIRCLE) or Pads.check(PAD, PAD_TRIANGLE) then
				repro_sfx(S_CANCELAR, 1, true, nil)
				pregunta = false
				JOYSTICK_LIMITE = control_FPS(1)
			end
			refrescar(true)
		end
	end

	-- SISTEMA TEST. --------------------------------------------------------------------
	--Font.ftPrint(CONTROL.fontARCA, 15, 0, 0, 0, 8, "RAM: ".. System.getFreeMemory(), COLOR.BLANCO)
	--Font.ftPrint(CONTROL.fontARCA, 15, 20, 0, 0, 8, "VRAM: ".. Screen.getFreeVRAM(), COLOR.BLANCO)
	--Font.ftPrint(CONTROL.fontARCA, 535, 0, 0, 0, 8, "FPS: ".. CONTROL.FPS, COLOR.BLANCO)
	--devs = System.listDevices()
	--for contador = 1, #devs, 1 do Font.ftPrint(CONTROL.fontARCA, 0, 10+((contador)*24), 0, 0, 8, devs[contador].name ..":", COLOR.BLANCO) end
	-------------------------------------------------------------------------------------
end
--[[------------------SPAGHETTICODE-------------------]]--