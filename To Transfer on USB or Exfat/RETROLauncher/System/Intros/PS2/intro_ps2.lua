--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[----------------------v1.0------------------------]]--

--- Realizar animaciones de encendido para PlayStation 2. -------------------------------
function ps2_startup()
	local ps2_logo = Graphics.loadImage(verif_img("System/Intros/PS2/PS2_INTRO.png"))
	local ps2_sfx = verificar_sonidos(ps2_sfx, "System/Intros/PS2/PS2.adp")
	local largo_x, alto_y, limite = (Graphics.getImageWidth(ps2_logo)/1), (Graphics.getImageHeight(ps2_logo)/6), Graphics.getImageHeight(ps2_logo)
	local img_X, img_Y, ani_frame, frame_speed, num_filas, num_columnas = 0, 0, 0, 4, 6, 1
	local mostrar_ani, ini_ani, ini_ani_cont = false, false, 0
	local pos_x, pos_y, esc_x, esc_y = ((CONTROL.ANCHO//2)-(360//2)), ((CONTROL.ALTO_F//2)-((130+CONTROL.Y_FIX_PAL)//2)-10), 360, (130+CONTROL.Y_FIX_PAL)

	local pause = true
	while pause do
		-- Controlar la velocidad en las animaciones. -----------------------------------
		CONTROL.FPS = Screen.getFPS(1)
		if CONTROL.FPS >= 28 and ini_ani == true then frame_speed = 3
		elseif CONTROL.FPS >= 10 then frame_speed = CONTROL.FPS//7
		elseif CONTROL.FPS <= 9 then frame_speed = 1 end

		-- Cambiar las animaciones. -----------------------------------------------------
		if ani_frame >= 1 and ini_ani == true then
			ani_frame = ani_frame-1
		else ani_frame = frame_speed end

		-- Recorrer las animaciones. ----------------------------------------------------
		if img_Y+alto_y == limite and ini_ani == true then
			ini_ani = false
			ini_ani_cont = 0
		elseif img_Y+alto_y <= (limite-1) and ini_ani == true then
			if img_X == (largo_x*num_columnas)-largo_x and ani_frame == frame_speed then
				img_Y = cambiar_valor(img_Y, 0, (alto_y*num_filas)-alto_y, alto_y, true)
				img_X = cambiar_valor(img_X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
			elseif ani_frame == frame_speed then
				img_X = cambiar_valor(img_X, 0, (largo_x*num_columnas)-largo_x, largo_x, true)
			end
		end

		-- Controla color negro. --------------------------------------------------------
		if ini_ani_cont <= (225) and mostrar_ani == true then ini_ani_cont = ini_ani_cont+2 end
		if ini_ani_cont <= 59 and mostrar_ani == false and ini_ani == false then ini_ani_cont = ini_ani_cont+2 end
		if ini_ani_cont >= 60 and mostrar_ani == false and ini_ani == false then 
			mostrar_ani, ini_ani, ini_ani_cont = true, true, 0
			-- Reproducir sonido de inicio para PlayStation 2. --------------------------
			Sound.setADPCMVolume(2, 0)
			SFX_VOLUMEN(0)
			Sound.setADPCMVolume(3, 60)
			if ps2_sfx ~= nil then Sound.playADPCM(3, ps2_sfx) end
		end

		-- Dibujar las animaciones en pantalla. -----------------------------------------
		Screen.clear(Color.new(0, 0, 0))
		if mostrar_ani == true then
			Graphics.drawImageExtended(ps2_logo, pos_x+(esc_x/2), pos_y+(esc_y/2), img_X, img_Y, img_X+largo_x, img_Y+alto_y, esc_x, esc_y, 0)
		end
		Screen.flip()

		-- Controla salida. -------------------------------------------------------------
		if ini_ani_cont >= (225+1) and ini_ani == false and mostrar_ani == true then pause = false end
	end
end
--[[------------------SPAGHETTICODE-------------------]]--