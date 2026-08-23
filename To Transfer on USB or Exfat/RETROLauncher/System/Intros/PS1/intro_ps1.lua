--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[----------------------v1.0------------------------]]--

--- Realizar animaciones de encendido para PlayStation 1. -------------------------------
function ps1_startup()
	local ps1_logo_1 = Graphics.loadImage(verif_img("System/Intros/PS1/PS1_INTRO1.png"))
	local ps1_logo_2 = Graphics.loadImage(verif_img("System/Intros/PS1/PS1_INTRO2.png"))
	local ps1_sfx = verificar_sonidos(ps1_sfx, "System/Intros/PS1/PS1.adp")
	local largo_x, alto_y, limite = (Graphics.getImageWidth(ps1_logo_2)/5), (Graphics.getImageHeight(ps1_logo_2)/5), Graphics.getImageHeight(ps1_logo_2)
	local img_X, img_Y, ani_frame, frame_speed, num_filas, num_columnas = 0, 0, 0, 4, 5, 5
	local dark_front_on, dark_front = true, 128
	local white_front_on, white_front = true, 128
	local ini_ani, ini_ani_cont = false, 0
	local pos_x, pos_y, esc_x, esc_y = ((CONTROL.ANCHO//2)-(364//2)), ((CONTROL.ALTO_F//2)-((272+CONTROL.Y_FIX_PAL)//2)-10), 364, (272+CONTROL.Y_FIX_PAL)

	-- Reproducir sonido de inicio para PlayStation 1. ----------------------------------
	Sound.setADPCMVolume(1, 0)
	Sound.setADPCMVolume(2, 0)
	Sound.setADPCMVolume(3, 60)
	if ps1_sfx ~= nil then Sound.playADPCM(3, ps1_sfx) end

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

		-- Controla color blanco. -------------------------------------------------------
		if white_front_on == false then 
			if white_front >= 2 then white_front = white_front-2 else white_front = 0 end 
		end
		if ini_ani_cont >= 50 then white_front_on = false end
		if ini_ani == false and dark_front_on == false then ini_ani_cont = ini_ani_cont+2 end

		-- Controla color negro. --------------------------------------------------------
		if dark_front >= 2 and dark_front_on == true then 
			dark_front = dark_front-2
		elseif dark_front <= 1 and dark_front_on == true and ini_ani == false then 
			dark_front = 0
			dark_front_on = false
			ini_ani = true
		end
		if ini_ani_cont >= 625 and dark_front <= 126 and ini_ani == false and dark_front_on == false then dark_front = dark_front+2 end
		if ini_ani_cont <= (625+126) and ini_ani == false and dark_front_on == false then ini_ani_cont = ini_ani_cont+2 end

		-- Dibujar las animaciones en pantalla. -----------------------------------------
		Screen.clear(Color.new(128, 128, 128))
		Graphics.drawScaleImage(ps1_logo_1, 0, 0, CONTROL.ANCHO, CONTROL.ALTO_F)
		Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO_F, Color.new(128, 128, 128, white_front))
		Graphics.drawImageExtended(ps1_logo_2, pos_x+(esc_x/2), pos_y+(esc_y/2), img_X, img_Y, img_X+largo_x, img_Y+alto_y, esc_x, esc_y, 0)
		Graphics.drawRect(0, 0, CONTROL.ANCHO, CONTROL.ALTO_F, Color.new(0, 0, 0, dark_front))
		Screen.flip()

		-- Controla salida. -------------------------------------------------------------
		if ini_ani_cont >= ((625+1)+126) and dark_front >= 128 and ini_ani == false and dark_front_on == false then pause = false end
	end
end
--[[------------------SPAGHETTICODE-------------------]]--