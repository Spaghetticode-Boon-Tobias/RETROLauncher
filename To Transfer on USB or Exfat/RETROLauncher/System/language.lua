--[[------------------SPAGHETTICODE-------------------]]--
--[[█▀█ ██▀ ▀█▀ █▀█ █▀█ █    ▄▄ ▄ ▄ ▄▄▄ ▄▄▄ █▄▄ ▄▄  ▄▄]]--
--[[█▀▄ █▄▄  █  █▀▄ █▄█ █▄▄ ▀▄█ █▄█ █ █ █▄▄ █ █ ██▄ █ ]]--
--[[------------------- v1.0/rev2 --------------------]]--

--[[Líneas para los idiomas de RETROLauncher.]]--
--- Crear listas de textos. -------------------------------------------------------------
function lang_select()
	local actual = System.currentDirectory()
	TEXT_GEN = {}
	TEXT_M_PS2 = {}
	TEXT_M_EXP = {}
	TEXT_M_CON = {}
	TEXT_SPR_T = {}
	TEXT_LAY_T = {}
	TEXT_M_STI = {}
	TEXT_M_PRI = {}
	TEXT_M_REL = {}
	TEXT_POPS_DESCR = {}
	TEXT_M_PS1 = {}
	local pre_spa = doesFileExist(actual .."/System/Defaults/SPA")
	local pre_por = doesFileExist(actual .."/System/Defaults/POR")
	local pre_eng = doesFileExist(actual .."/System/Defaults/ENG")
	if (pre_spa == true and pre_por == true) or (pre_eng == true and pre_por == true) or (pre_spa == true and pre_eng == true)
	or (pre_spa == false and pre_por == false and pre_eng == false) then
		if doesFileExist(actual .."/System/Defaults/SPA") then
			System.rename(actual .."/System/Defaults/SPA", actual .."/System/Defaults/ENG")
		end
		if doesFileExist(actual .."/System/Defaults/POR") then
			System.rename(actual .."/System/Defaults/POR", actual .."/System/Defaults/ENG")
		end
		if doesFileExist(actual .."/System/Defaults/ENG") == false then
			local pre_eng_create = System.openFile(actual .."/System/Defaults/ENG", FCREATE)
			System.closeFile(pre_eng_create)
		end
	end

	-------------------------------------------------------------------------------------
	-- Español. -------------------------------------------------------------------------
	if doesFileExist(actual .."/System/Defaults/SPA") then
		-- Nota. ------------------------------------------------------------------------
		-- Evite utilizar palabras o frases que excedan el límite de caracteres de los originales, para evitar textos fuera de cuadro.
		-- ...? - Es una pregunta que puede variar, por lo que finaliza en otra parte del código, en estos casos omita el carácter "?" al final.
		-- \n - Es un salto de línea, por lo que no debe existir espacio entre ellos y la palabra que les sigue.
		-- \" - Se utiliza para escapar de un carácter especial utilizado por el código que podría causar conflictos.

		-- Textos de uso general. -------------------------------------------------------
		TEXT_GEN = {
			"Salir"; -- 1
			"No"; -- 2
			"Sí"; -- 3
			"Atrás"; -- 4
			"Elegir"; -- 5
			"Cancelar"; -- 6
			"Salir"; -- 7
			"Cambiar"; -- 8
			"No"; -- 9
			"Sí"; -- 10
			"Reiniciar"; -- 11
			"Guardar"; -- 12
			"Encendido"; -- 13
			"Apagado"; -- 14
		};

		-- Menú de configuraciones para juegos de PS1. ----------------------------------
		TEXT_M_PS1 = {
			"Instalar archivo \"CHEATS.TXT\""; -- 1
			"Buscando archivos \"CHEATS.TXT\""; -- 2
			"Descripción"; -- 3
			"Control de códigos"; -- 4
			"¿Guardar códigos seleccionados"; -- 5 ...?
			"Guardando códigos"; -- 6
			"Instalando parches"; -- 7
			"Buscando parches"; -- 8
			"Cargando configuraciones del juego"; -- 9
			"Limpiando configuraciones del juego"; -- 10
			"Parches de uso general encontrados"; -- 11
			"Se reemplazarán los parches con el mismo nombre."; -- 12
			"Parches de juegos encontrados"; -- 13
			"Se eliminarán todos los parches anteriores."; -- 14
			"Instalar parche"; -- 15
			"Nombre del parche que se instalará"; -- 16
			"Instalar"; -- 17
			"¿Instalar parches seleccionados"; -- 18 ...?
			"Instalar parches para juegos específicos"; -- 19
			"Instalar parches generales"; -- 20
			"Configuraciones extras"; -- 21
			"Limpiar configuraciones del juego"; -- 22
			"Seleccionar el tipo de configuración"; -- 23
			"Solo parches"; -- 24
			"Solo códigos"; -- 25
			"Todas las configuraciones"; -- 26
			"¿Limpiar configuraciones seleccionadas"; -- 27 ...?
			"Limpiar"; -- 28
			"\"CHEATS.TXT\" de juegos encontrados"; -- 29
			"Se eliminará el \"CHEATS.TXT\" anterior."; -- 30
			"¿Instalar \"CHEATS.TXT\" seleccionado"; -- 31 ...?
			"\"CHEATS.TXT\" del juego que se instalará"; -- 32
			"Instalando \"CHEATS.TXT\""; -- 33
		};

		-- Descripciones para las opciones de POPStarter. -------------------------------
		TEXT_POPS_DESCR = {
			-- Descripción de los códigos para POPStarter. ------------------------------
			"Desactiva el motor de trucos y solo lo\nactiva después de que POPS abandone el OSD\nde PS1. Debe estar siempre activado."; -- 1
			"Habilita el mapeo de textura suave al\ninicio."; -- 2
			"Configura el retardo USB del contenedor PFS.\nPara dispositivos USB que tienen problemas\nal ejecutar \"POPStarter\"."; -- 3
			"Fuerza la activación del parcheador PAL y\naplica el código de región a Europa.\nÚtil para VCD PAL sin un texto de licencia\nválido en el sector de arranque."; -- 4
			"Desactiva el parcheador POPStarters PAL.\nNo está diseñado para convertir juegos NTSC\na PAL."; -- 5
			"Centra la pantalla verticalmente. No hay un\nvalor predeterminado; depende del juego; hay\nque experimentar. Cuanto mayor sea el valor,\nmás se desplaza la pantalla hacia abajo."; -- 6
			"Centra la pantalla horizontalmente. El valor\npredeterminado es 640; un valor inferior a\n640 moverá la pantalla a la izquierda; un\nvalor superior a 640, a la derecha."; -- 7
			"Extiende la pantalla horizontalmente.\nEl valor predeterminado es 2559; auméntalo\npara extender la pantalla a la derecha y\ndisminúyelo para estrecharla a la izquierda."; -- 8
			"Reduce/expande el ancho del área de\nvisualización. El valor máximo es 2560;\nredúzcalo para recortar la pantalla a la\nderecha."; -- 9
			"Activar las líneas de escaneo. Los juegos se\nven con este tipo de líneas, propias de los\nantiguos televisores y monitores de tubo."; -- 10
			"El control permanece en modo digital.\nHabilita la compatibilidad con joysticks en\njuegos que no lo admiten de forma nativa."; -- 11
			"El control permanece en modo analógico.\nHabilita la compatibilidad con joysticks en\njuegos que no lo admiten de forma nativa."; -- 12
			"Ayuda con televisores HDTV que no admiten\nresoluciones entrelazadas por componentes.\nNo compatible con algunos televisores CRT."; -- 13
			"Silenciar los sonidos y la música basados en\nVAB/VAG/VB+VH en los juegos. Puede ser útil\npara juegos antiguos que generan efectos de\nsonido distorsionados o ruidos molestos."; -- 14
			"Abre el menú IGR.\nCombinación:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 15
			"Abre el menú IGR.\nCombinación:\nSELECT + START"; -- 16
			"Abre el menú IGR.\nCombinación:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 17
			"La combinación \"IGR\" finaliza POPS\n(no hay menú \"IGR\").\nCombinación:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 18
			"La combinación \"IGR\" finaliza POPS\n(no hay menú \"IGR\").\nCombinación:\nSELECT + START"; -- 19
			"La combinación \"IGR\" finaliza POPS\n(no hay menú \"IGR\").\nCombinación:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 20
			"Desactiva el menú IGR."; -- 21
			"Carga una palabra mágica LibCrypt nula en el\nregistro cop0.\nPuede ser necesario en algunos discos con\nprotección LibCrypt defectuosa."; -- 22
			"Permite el hack de pantalla ancha de POPS\nGTE y fuerza la relación de aspecto 16:9.\nNo se adapta a elementos como HUD, textos,\nni fondos 2D (este hack no está terminado)."; -- 23
			"Igual que WIDESCREEN, pero con un campo de\nvisión más amplio.\nNo se adapta a elementos como HUD, textos,\nni fondos 2D (este hack no está terminado)."; -- 24
			"Igual que WIDESCREEN, pero con una relación\nde aspecto de 3×16:9.\nNo se adapta a elementos como HUD, textos,\nni fondos 2D (este hack no está terminado)."; -- 25
			"Fuerza 480p. No es compatible con XPOS,\nYPOS, DWSTRETCH ni DWCROP.\nEvite usarlo, no es fiable."; -- 26
			"habilitar solamente \"Virtual Memory Card 1\"."; -- 27
			"habilitar solamente \"Virtual Memory Card 0\"."; -- 28
			"Impide que POPStarter active correcciones\ndel juego. Es posible que este comando no\nfuncione en algunos juegos."; -- 29
			"Ayuda a restaurar la música y las voces en\nvarios juegos.\nDesactívala si usas parches \".bin\"."; -- 30
			"Una variante del modo 0×01, con un segundo\ntruco para no romper el MDECoding de FMVs\n(fue diseñado para la serie Colony Wars).\nDesactívala si usas parches \".bin\"."; -- 31
			"Se puede utilizar si el modo 0×01 no\nproporciona los resultados esperados.\nDesactívala si usas parches \".bin\"."; -- 32
			"Corrige ralentizaciones, parpadeos y muchos\notros fallos.\nDesactívala si usas parches \".bin\"."; -- 33
			"Hecho para arreglar las escenas de corte del\nResident Evil: Director’s Cut (PAL).\nDesactívala si usas parches \".bin\"."; -- 34
			"Desactiva el shell OSD del BIOS integrado\ndel emulador, lo que hace que se ejecuten\nalgunos juegos que se congelan al iniciarse.\nDesactívala si usas parches \".bin\"."; -- 35
			-- Descripción de los parches para POPStarter. ------------------------------
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / +4 de brillo / DQA, DQB"; -- 36
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / Brillo normal / DQA, DQB"; -- 37
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / -4 de brillo / DQA, DQB"; -- 38
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / -16 de brillo / DQA, DQB"; -- 39
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / DQA, DQB"; -- 40
			"Posiblemente solucione juegos con problemas\n3D/2D.\nHack / IR0"; -- 41
			"Posiblemente solucione juegos con problemas\n3D/2D.\nEl más compatible y recomendado."; -- 42
			"Corrige fallos a nivel del recompilador en\nmuy pocos casos, solo cuando el problema es\nuna mala actualización del código en la\ncaché de instrucciones del recompilador."; -- 43
			"Estos mods evitan fallos de audio.\nSe recomienda usar \"SPU_IRQ_ON_STABLE\", ya\nque es el más estable; el audio se omitirá,\npor lo que no lo oirás."; -- 44
			"Esto aplica overclocking al emulador,\ncompatible con PAL y NTSC.\nPrecaución: Valores superiores a +40 pueden\ncausar problemas de guardado."; -- 45
			"Sin overclocking de GPU.\nRequerido para algunas combinaciones de\noverclocking de CPU."; -- 46
			"Puede que solucione algunos problemas, pero\nsu uso debe compensarse con overclocking.\nSe recomienda que la frecuencia de la GPU\nsea un 20% inferior a la de la CPU."; -- 47
			"Deshabilitar el Dithering, este es un filtro\nespecial utilizado en los juegos de PS1."; -- 48
			"Sin descripción."; -- 49
		};

		-- Menú de configuraciones para juegos de PS2. ----------------------------------
		TEXT_M_PS2 = {
			"Buscando configuración del juego"; -- 1
			"Usar tarjeta de memoria virtual"; -- 2
			"Sin tarjeta de memoria virtual"; -- 3
			"Modos de compatibilidad"; -- 4
			"IOP: Fast Reads"; -- 5
			"Dummy"; -- 6
			"IOP: Sync Reads"; -- 7
			"EE : Unhook Syscalls"; -- 8
			"IOP: Emulate DVD-DL"; -- 9
			"IOP: Fix game buffer overrun"; -- 10
			"Modo sintetizador gráfico"; -- 11
			"Modo de vídeo forzado"; -- 12
			"Modo de compatibilidad"; -- 13
			"No usado"; -- 14
			"Guardar configuración del juego"; -- 15
			"OPL"; -- 16
			"Neutrino"; -- 17
			"VMC no encontrada"; -- 18
			"Guardando la configuración del juego"; -- 19
			"Accurate Reads"; -- 20
			"Synchronous Reads"; -- 21
			"Unhook Syscalls"; -- 22
			"Skip videos"; -- 23
			"Emulate DVD-DL"; -- 24
			"Disable IGR"; -- 25
			"Ajuste horizontal"; -- 26
			"Ajuste vertical"; -- 27
			"¿Guardar configuración?"; -- 28
			"ADVERTENCIA:\nSe recomienda que configure sus juegos dentro de\n\"OPL\", ya que puede haber conflictos entre las\ndiferentes versiones de \"OPL\" y sus archivos de\nconfiguración."; -- 29
		};

		-- Menú de explorador. ----------------------------------------------------------
		TEXT_M_EXP = {
			"La carpeta está vacía o los archivos no son compatibles"; -- 1
			"No hay archivos válidos"; -- 2
			"Elementos"; -- 3
		};

		-- Menú de configuraciones para RETROLauncher. ----------------------------------
		TEXT_M_CON = {
			"Efecto RGB"; -- 1
			"Color sobre los fondos"; -- 2
			"Fijar un color sobre el fondo"; -- 3
			"Rojo"; -- 4
			"Verde"; -- 5
			"Azul"; -- 6
			"Estilo de lista"; -- 7
			"Fuente de texto"; -- 8
			"Fondo de pantalla"; -- 9
			"GUI limpia"; -- 10
			"Forzar la recolección de basura"; -- 11
			"Salida personalizada"; -- 12
			"Directorio"; -- 13
			"Rutas completas en menú de APPS"; -- 14
			"Sonidos en el menú"; -- 15
			"Volumen del sonido"; -- 16
			"Capturas de pantalla como fondos"; -- 17
			"Modo de vídeo"; -- 18
			"Vibración en el menú"; -- 19
			"Directorios adicionales"; -- 20
			"Restablecer todos los ajustes"; -- 21
			"Créditos"; -- 22
			"Guardar configuración"; -- 23
			"Página 1"; -- 24
			"Página 2"; -- 25
			"Cambios no guardados. ¿Deseas salir?"; -- 26
			"Todos los cambios realizados se perderán."; -- 27
			"Seleccionar dispositivo de búsqueda"; -- 28
			"Buscar"; -- 29
			"Ajustar ancho"; -- 30
			"Ajustar altura"; -- 31
			"Ajustar fondos del texto"; -- 32
			"Ajustar el desplazamiento del texto"; -- 33
			"Aumente o disminuya el número mínimo de desplazamientos hasta que el número \"0\" sea visible junto al cuadro de color"; -- 34
			"Configurar la fuente de texto"; -- 35
			"Encaja el texto en los recuadros oscuros"; -- 36
			"Intente colocar el \"0\" en el cuadro de color"; -- 37
			"Intenta que la barra oscura cubra el texto"; -- 38
			"Ejemplo de texto fijo"; -- 39
			"Restablecer"; -- 40
			"Establecer"; -- 41
			"¿Liberar el resto de listas?"; -- 42
			"Si se activa, el movimiento será más fluido"; -- 43
			"a costa de pausas al cambiar de sistemas."; -- 44
			"¿Deshabilitar \"wLaunchELF\"?"; -- 45
			"Espere, por favor"; -- 46
			"¿Música de fondo en bucle?"; -- 47
			"Usar solo si RetroArch presenta cortes de audio"; -- 48
			"o si no posee otro medio para cambiar de formato"; -- 49
			"¿Restablecer"; -- 50 ...?
			"¿Borrar partidas guardadas?"; -- 51
			"¿Cambiar el modo de video a"; -- 52 ...?
			"¿Restablecer todas las configuraciones?"; -- 53
			"Estándar"; -- 54
			"(habilitar colores de depuración)"; -- 55
			"Simple"; -- 56
			"Cover art"; -- 57
			"Full art"; -- 58
			"Big cover"; -- 59
			"Big art"; -- 60
			"Big list"; -- 61
			"Custom"; -- 62
			"Nivel de zoom"; -- 63
			"Activar sistemas"; -- 64
			"Transparencia"; -- 65
			"Sin transparencia"; -- 66
			"Seleccionar aplicación"; -- 67
			"Seleccionar versión de OPL"; -- 68
			"(configuración del usuario)"; -- 69
			"Eliminar partidas guardadas"; -- 70
			"Restableciendo"; -- 71
			"Cambiando la configuración de video"; -- 72
			"Cargando listas de juegos y configuraciones"; -- 73
			"Restableciendo todas las configuraciones"; -- 74
			"W"; -- 75 Ejemplo para configuración de fuente.
			"M"; -- 76 Ejemplo para configuración de fuente.
			"Columnas"; -- 77
			"Filas"; -- 78
			"Número de animaciones"; -- 79
			"¿Renombrar imagen para su autoconfiguración"; -- 80 ...?
			"Nombre actual"; -- 81
			"Nuevo nombre"; -- 82
			"Configuración de POPStarter"; -- 83
			"\"IGR\" direcciona hacia \"OSDSYS\""; -- 84
			"Desactivar \"Dithering\" en los juegos"; -- 85
			"Instalar traducción en \"IGR\""; -- 86
			"Configurar animación de capas"; -- 87
			"Tipo de animación"; -- 88
			"Velocidad de animación"; -- 89
			"Multiplicador de velocidad"; -- 90
			"Tipo de transparencia"; -- 91
			"Nivel de transparencia"; -- 92
			"Velocidad de transparencia"; -- 93
			"Tipo de rotación"; -- 94
			"Velocidad de rotación"; -- 95
			"Capas afectadas"; -- 96
			"Girar a la\nderecha"; -- 97
			"Girar a la\nizquierda"; -- 98
			"Alternar\ndirección"; -- 99
			"Transparencia\nfija"; -- 100
			"Alternar\nmínimo/máximo"; -- 101
			"Alternar\nmitad/máximo"; -- 102
			"Alternar capas\nmínimo/máximo"; -- 103
			"Alternar capas\nmitad/máximo"; -- 104
			"¿Mostrar índices de juegos?"; -- 105
			"Configuración de sprites"; -- 106
			"Activar sprites en menú"; -- 107
			"Sprite correspondiente a"; -- 108
			"Tipo de animación"; -- 109
			"Velocidad de animación"; -- 110
			"Transparencias en animación"; -- 111
			"Rotaciones en animación"; -- 112
			"Reflejar sprites"; -- 113
			"Blanco"; -- 114
			"Tamaño del radio"; -- 115
			"Seleccionar menú de configuración"; -- 116
			"Editor de estilo"; -- 117
			"Configuración de sprites"; -- 118
			"Transparencia de los screenshots"; -- 119
			"Mostrar siempre el menú de ejecución alternativo"; -- 120
			"Color de las sombras detrás de los elementos"; -- 121
		};

		-- Nombre de los estilos de animación para los sprites. -------------------------
		TEXT_SPR_T = {
			"Sprite\nfijo"; -- 1
			"Mover a la\nderecha\nsobre el eje\nhorizontal"; -- 2
			"Mover a la\nizquierda\nsobre el eje\nhorizontal"; -- 3
			"Mover a la\nderecha\nsobre el eje\nhorizontal\n+zigzag\nsobre el eje\nvertical\n(corto)"; -- 4
			"Mover a la\nizquierda\nsobre el eje\nhorizontal\n+zigzag\nsobre el eje\nvertical\n(corto)"; -- 5
			"Mover a la\nderecha\nsobre el eje\nhorizontal\n+zigzag\nsobre el eje\nvertical\n(largo)"; -- 6
			"Mover a la\nizquierda\nsobre el eje\nhorizontal\n+zigzag\nsobre el eje\nvertical\n(largo)"; -- 7
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(corto)"; -- 8
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(medio)"; -- 9
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(largo)"; -- 10
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(corto)\n+zigzag\nsobre el eje\nvertical"; -- 11
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(medio)\n+zigzag\nsobre el eje\nvertical"; -- 12
			"Mover de\nderecha a\nizquierda\nsobre el eje\nhorizontal\n(largo)\n+zigzag\nsobre el eje\nvertical"; -- 13
			"Bajar\nsobre el eje\nvertical"; -- 14
			"Subir\nsobre el eje\nvertical"; -- 15
			"Bajar\nsobre el eje\nvertical\n+zigzag\nsobre el eje\nhorizontal\n(corto)"; -- 16
			"Subir\nsobre el eje\nvertical\n+zigzag\nsobre el eje\nhorizontal\n(corto)"; -- 17
			"Bajar\nsobre el eje\nvertical\n+zigzag\nsobre el eje\nhorizontal\n(largo)"; -- 18
			"Subir\nsobre el eje\nvertical\n+zigzag\nsobre el eje\nhorizontal\n(largo)"; -- 19
			"Subir y\nbajar\nsobre el eje\nvertical\n(corto)"; -- 20
			"Subir y\nbajar\nsobre el eje\nvertical\n(medio)"; -- 21
			"Subir y\nbajar\nsobre el eje\nvertical\n(largo)"; -- 22
			"Subir y\nbajar\nsobre el eje\nvertical\n(corto)\n+zigzag\nsobre el eje\nhorizontal"; -- 23
			"Subir y\nbajar\nsobre el eje\nvertical\n(medio)\n+zigzag\nsobre el eje\nhorizontal"; -- 24
			"Subir y\nbajar\nsobre el eje\nvertical\n(largo)\n+zigzag\nsobre el eje\nhorizontal"; -- 25
			"Aceleración\nal bajar a\nla derecha"; -- 26
			"Aceleración\nal bajar a\nla izquierda"; -- 27
			"Aceleración\nal subir a\nla derecha"; -- 28
			"Aceleración\nal subir a\nla izquierda"; -- 29
			"Aceleración\nde derecha\na izquierda"; -- 30
			"Aceleración\nde izquierda\na derecha"; -- 31
			"Aceleración\nde derecha\na izquierda\n+cambio\nsobre el eje\nvertical"; -- 32
			"Aceleración\nde izquierda\na derecha\n+cambio\nsobre el eje\nvertical"; -- 33
			"Desacelerar\nde derecha\na izquierda"; -- 34
			"Desacelerar\nde izquierda\na derecha"; -- 35
			"Aceleración\nal bajar a\nla izquierda"; -- 36
			"Aceleración\nal subir a\nla izquierda"; -- 37
			"Aceleración\nal bajar a\nla derecha"; -- 38
			"Aceleración\nal subir a\nla derecha"; -- 39
			"Aceleración\nal bajar"; -- 40
			"Aceleración\nal subir"; -- 41
			"Aceleración\nal bajar\n+cambio\nsobre el eje\nhorizontal"; -- 42
			"Aceleración\nal subir\n+cambio\nsobre el eje\nhorizontal"; -- 43
			"Desacelerar\nal bajar"; -- 44
			"Desacelerar\nal subir"; -- 45
			"Flotar\nen diagonal\nversión 1"; -- 46
			"Flotar\nen diagonal\nversión 2"; -- 47
			"Diagonal\nabajo\nderecha"; -- 48
			"Diagonal\nabajo\nizquierda"; -- 49
			"Diagonal\narriba\nderecha"; -- 50
			"Diagonal\narriba\nizquierda"; -- 51
			"Recorrer\nel marco de\nla pantalla\nen sentido\nhorario"; -- 52
			"Recorrer\nel marco de\nla pantalla\nen sentido\nantihorario"; -- 53
			"Dar vueltas\nen círculos\nen sentido\nhorario\n(corto)"; -- 54
			"Dar vueltas\nen círculos\nen sentido\nantihorario\n(corto)"; -- 55
			"Dar vueltas\nen círculos\nen sentido\nhorario\n(medio)"; -- 56
			"Dar vueltas\nen círculos\nen sentido\nantihorario\n(medio)"; -- 57
			"Dar vueltas\nen círculos\nen sentido\nhorario\na pantalla\ncompleta"; -- 58
			"Dar vueltas\nen círculos\nen sentido\nantihorario\na pantalla\ncompleta"; -- 59
			"Rebotar en\nlos marcos\nde la\npantalla"; -- 60
			"Hacer zoom\n(corto)"; -- 61
			"Hacer zoom\n(medio)"; -- 62
			"Controlar\nsprite con\nel stick\nderecho"; -- 63
			"Fijar\nnivel de\ntransparencia"; -- 64
			"Alternar\nentre el\nmínimo y\nel máximo"; -- 65
			"Alternar\nentre la\nmitad y\nel máximo"; -- 66
			"Reflejar\nel eje\nhorizontal\nde forma\nautomática\ny acorde al\nmovimiento"; -- 67
			"Reflejar\nel eje\nvertical\nde forma\nautomática\ny acorde al\nmovimiento"; -- 68
			"Reflejar\nambos ejes\nde forma\nautomática\ny acorde al\nmovimiento"; -- 69
			"Reflejar\nel eje\nhorizontal\nde forma\nmanual\na través\ndel stick\nderecho"; -- 70
			"Reflejar\nel eje\nvertical\nde forma\nmanual\na través\ndel stick\nderecho"; -- 71
			"Reflejar\nambos ejes\nde forma\nmanual\na través\ndel stick\nderecho"; -- 72
			"Fijar\nreflejo\nen eje\nhorizontal"; -- 73
			"Fijar\nreflejo\nen eje\nvertical"; -- 74
			"Fijar\nreflejo en\nambos ejes"; -- 75
			"Coloque el\nnúmero de\ncolumnas\nque contiene\nla imagen\n(vertical)"; -- 76
			"Coloque el\nnúmero de\nfilas\nque contiene\nla imagen\n(horizontal)"; -- 77
		};

		-- Nombre de los estilos de animación para las capas. ---------------------------
		TEXT_LAY_T = {
			"Capas fijas"; -- 1
			"Derecha\nhorizontal v1"; -- 2
			"Izquierda\nhorizontal v1"; -- 3
			"Zigzag derecha\nvertical"; -- 4
			"Zigzag izquierda\nvertical"; -- 5
			"Derecha\nfrontal v1"; -- 6
			"Izquierda\nfrontal v1"; -- 7
			"Zigzag centro\nhorizontal v1"; -- 8
			"Derecha\nhorizontal v2"; -- 9
			"Izquierda\nhorizontal v2"; -- 10
			"Izquierda\nfrontal v2"; -- 11
			"Derecha\nfrontal v2"; -- 12
			"Derecha\nfrontal v3"; -- 13
			"Izquierda\nfrontal v3"; -- 14
			"Derecha\npanorámica v1"; -- 15
			"Izquierda\npanorámica v1"; -- 16
			"Derecha\npanorámica v2"; -- 17
			"Izquierda\npanorámica v2"; -- 18
			"Entrecruzar\nhorizontal"; -- 19
			"Zigzag centro\nhorizontal v2"; -- 20
			"Abajo\nvertical v1"; -- 21
			"Arriba\nvertical v1"; -- 22
			"Zigzag abajo\nhorizontal"; -- 23
			"Zigzag arriba\nhorizontal"; -- 24
			"Arriba\nfrontal v1"; -- 25
			"Abajo\nfrontal v1"; -- 26
			"Zigzag centro\nvertical v1"; -- 27
			"Abajo\nvertical v2"; -- 28
			"Arriba\nvertical v2"; -- 29
			"Arriba\nfrontal v2"; -- 30
			"Abajo\nfrontal v2"; -- 31
			"Abajo\nfrontal v3"; -- 32
			"Arriba\nfrontal v3"; -- 33
			"Abajo\npanorámica v1"; -- 34
			"Arriba\npanorámica v1"; -- 35
			"Abajo\npanorámica v2"; -- 36
			"Arriba\npanorámica v2"; -- 37
			"Entrecruzar\nvertical"; -- 38
			"Zigzag centro\nvertical v2"; -- 39
			"Derecha\nremolino"; -- 40
			"Izquierda\nremolino"; -- 41
			"Zoom 3-4\nPíxel zoom"; -- 42
			"Zoom 1-2\nPíxel zoom"; -- 43
			"Zoom 2-3\nPíxel zoom"; -- 44
			"Zoom 1-4\nPíxel zoom"; -- 45
			"Zoom 1-3-4\nPíxel zoom"; -- 46
			"Zoom 1-2-3\nPíxel zoom"; -- 47
			"Zoom 2-3-4\nPíxel zoom"; -- 48
			"Zoom 1-2-4\nPíxel zoom"; -- 49
			"Zoom 1-2-3-4\nPíxel zoom"; -- 50
			"Zoom 3-4 v2\nPíxel zoom"; -- 51
			"Zoom 1-2 v2\nPíxel zoom"; -- 52
			"Zoom 2-3 v2\nPíxel zoom"; -- 53
			"Zoom 1-4 v2\nPíxel zoom"; -- 54
			"Zoom 1-3-4 v2\nPíxel zoom"; -- 55
			"Zoom 1-2-3 v2\nPíxel zoom"; -- 56
			"Zoom 2-3-4 v2\nPíxel zoom"; -- 57
			"Zoom 1-2-4 v2\nPíxel zoom"; -- 58
			"Zoom 1-2-3-4 v2\nPíxel zoom"; -- 59
			"Derecha\nhorizontal v3"; -- 60
			"Izquierda\nhorizontal v3"; -- 61
			"Abajo\nvertical v3"; -- 62
			"Arriba\nvertical v3"; -- 63
		};

		-- Menú editor de estilos. ------------------------------------------------------
		TEXT_M_STI = {
			"Ejemplo de nombre de juego.zip"; -- 1
			"Centro / Ejemplo de nombre de juego.zip"; -- 2
			"Derecho / Ejemplo de nombre de juego.zip"; -- 3
			"Izquierdo / Ejemplo de nombre de juego.zip"; -- 4
			"Nº de juegos"; -- 5
			"Salir"; -- 6
			"Configuraciones"; -- 7
			"Cambiar arte"; -- 8
			"Ampliar arte"; -- 9
			"Ejecutar"; -- 10
			"Actualizar"; -- 11
			"Lista"; -- 12
			"Arte"; -- 13
			"Arte extra"; -- 14
			"Cover flow"; -- 15
			"Logo"; -- 16
			"Botón Cruz"; -- 17
			"Botón Triángulo"; -- 18
			"Botón Cuadrado"; -- 19
			"Botón L1"; -- 20
			"Botón R1"; -- 21
			"Botón R3"; -- 22
			"Botón START"; -- 23
			"Botón SELECT"; -- 24
			"Tipo de transición"; -- 25
			"Velocidad"; -- 26
			"Restaurar todo"; -- 27
			"Guardar estilo"; -- 28
			"Salir del editor"; -- 29
			"Bloquear"; -- 30
			"Guías"; -- 31
			"Posición"; -- 32
			"Tamaño"; -- 33
			"Pixels"; -- 34
			"Restaurar"; -- 35
			"Siguiente"; -- 36
			"Anterior"; -- 37
			"Ayuda"; -- 38
			"Elementos"; -- 39
			"Guardar"; -- 40
			"Menú"; -- 41
			"Pixels"; -- 42
			"Activar elementos"; -- 43
			"Sombra"; -- 44
			"Opciones adicionales"; -- 45
			"¿Restablecer todos los elementos?"; -- 46
			"¿Guardar cambios?"; -- 47
			"Al guardar, si existe una configuración previa\nse creará una copia de seguridad de la misma\n(reemplazando la última copia existente)."; -- 48
		};

		-- Menú principal. --------------------------------------------------------------
		TEXT_M_PRI = {
			"-Cargando Arte-"; -- 1
			"Salir"; -- 2
			"Configuraciones"; -- 3
			"Cambiar arte"; -- 4
			"Ampliar arte"; -- 5
			"Ejecutar"; -- 6
			"Actualizar"; -- 7
			"Configurar"; -- 8
			"Menú"; -- 9
			"Arte"; -- 10
			"Zoom"; -- 11
			"Jugar"; -- 12
			"Cargando"; -- 13
			"Sin elementos"; -- 14
			"¡Error!"; -- 15
			"¡Juegos o RetroArch"; -- 16
			"¡Aplicación O ELF"; -- 17
			"¡POPS O Binarios"; -- 18
			"¡Neutrino/OPL O ISO"; -- 19
			"No encontrados!"; -- 20
			"Nº de juegos"; -- 21
			"Nº de APPS"; -- 22
			"¿Reiniciar RETROLauncher?"; -- 23
			"¿Salir de RETROLauncher?"; -- 24
			"¡ADVERTENCIA!"; -- 25
			"Todas las opciones de RetroArch se restablecerán"; -- 26
			"Cargando Arte"; -- 27
			"¿Dónde desea crear el ejecutable del juego?"; -- 28
			"Directorio \"POPS\""; -- 29
			"Directorio \"APPS\""; -- 30
			"Configurar"; -- 31
			"Alternativo"; -- 32
			"Variante"; -- 33
			"Explorador"; -- 34
			"Seleccione el dispositivo a examinar"; -- 35
			"¡Ember o Bios/CUE"; -- 36
		};

		-- Menú de reubicación. ---------------------------------------------------------
		TEXT_M_REL = {
			"ADVERTENCIA\nEste programa se creó para ejecutarse desde el\nprimer puerto (USB) de PS2.\nVuelva a conectar el USB al primer puerto y\nreinicie el programa."; -- 1
			"ADVERTENCIA\nDispositivo de almacenamiento USB detectado en\nel segundo puerto (USB).\nDesconecte el USB del segundo puerto y reinicie\nel programa."; -- 2
			"El directorio actual no coincide\nCon su configuración.\n¿Quieres reubicar las configuraciones\nen este directorio?\n¡ADVERTENCIA!\nLas opciones de RetroArch se restablecerán"; -- 3
			"Reubicar"; -- 4
			"Reubicando"; -- 5
			"Reubicando todos los ajustes"; -- 6
		};

	-------------------------------------------------------------------------------------
	-- Português. -----------------------------------------------------------------------
	elseif doesFileExist(actual .."/System/Defaults/POR") then
		-- Nota. ------------------------------------------------------------------------
		-- Evite usar palavras ou frases que excedam o limite de caracteres dos originais, para evitar que o texto ultrapasse os limites do quadro.
		-- ...? - É uma pergunta que pode variar, então termina em outra parte do código; nesses casos, omita o caractere "?" no final.
		-- \n - É uma quebra de linha, portanto não deve haver espaço entre elas e a palavra seguinte.
		-- \" - É utilizado para escapar um caractere especial usado pelo código que pode causar conflitos.

		-- Textos de uso geral. ---------------------------------------------------------
		TEXT_GEN = {
			"Sair"; -- 1
			"Não"; -- 2
			"Sim"; -- 3
			"Volte"; -- 4
			"Escolher"; -- 5
			"Cancelar"; -- 6
			"Sair"; -- 7
			"Mudar"; -- 8
			"Não"; -- 9
			"Sim"; -- 10
			"Reiniciar"; -- 11
			"Salvar"; -- 12
			"Ligado"; -- 13
			"Desligado"; -- 14
		};

		-- Menu de configurações para jogos de PS1. -------------------------------------
		TEXT_M_PS1 = {
			"Instalar arquivo \"CHEATS.TXT\""; -- 1
			"Procurando por arquivos \"CHEATS.TXT\""; -- 2
			"Descrição"; -- 3
			"Controle de código"; -- 4
			"Salvar códigos selecionados"; -- 5 ...?
			"Salvando os códigos"; -- 6
			"Instalando patches"; -- 7
			"Procurando patches"; -- 8
			"Carregando as configurações do jogo"; -- 9
			"Limpando as configurações do jogo"; -- 10
			"Patches de uso geral encontrados"; -- 11
			"Patches com o mesmo nome serão substituídos."; -- 12
			"Patches de jogo encontrados"; -- 13
			"Todos os patches anteriores serão removidos."; -- 14
			"Instalar patch"; -- 15
			"Nome do patch a ser instalado"; -- 16
			"Instalar"; -- 17
			"Instalar patches selecionados"; -- 18 ...?
			"Instalar patches para jogos específicos"; -- 19
			"Instalar patches gerais"; -- 20
			"Configurações extras"; -- 21
			"Limpar as configurações do jogo"; -- 22
			"Selecione o tipo de configuração"; -- 23
			"Somente patches"; -- 24
			"Somente códigos"; -- 25
			"Todas as configurações"; -- 26
			"Limpar configurações selecionadas"; -- 27 ...?
			"Limpar"; -- 28
			"\"CHEATS.TXT\" de jogos encontrados"; -- 29
			"O anterior \"CHEATS.TXT\" será excluído."; -- 30
			"Instalar \"CHEATS.TXT\" selecionado"; -- 31 ...?
			"\"CHEATS.TXT\" do jogo a ser instalado"; -- 32
			"Instalando \"CHEATS.TXT\""; -- 33
		};

		-- Descrições das opções do POPStarter. -----------------------------------------
		TEXT_POPS_DESCR = {
			-- Descrição dos códigos para POPStarter. -----------------------------------
			"Desativa o mecanismo de trapaça e só o\nativa após o POPS sair do PS1 OSD.\nDeve estar sempre ligado."; -- 1
			"Habilita o mapeamento de textura suave na\ninicialização."; -- 2
			"Configura o atraso USB do wrapper PFS.\nPara dispositivos USB que apresentam\nproblemas ao executar o \"POPStarter\"."; -- 3
			"Força a ativação do patcher PAL e aplica o\npatch do código de região para Euro. Útil\npara VCDs PAL que não possuem um texto de\nlicença válido em seu setor de inicialização."; -- 4
			"Desativa o patcher PAL do POPStarters.\nNão foi projetado para converter jogos NTSC\npara PAL."; -- 5
			"Centraliza a tela verticalmente. Não há\nvalor padrão, depende do jogo, você precisa\nexperimentar. Quanto maior o valor, mais a\ntela se move para baixo."; -- 6
			"Centraliza a tela horizontalmente. O valor\npadrão é 640; valores menores que 640 movem\na tela para a esquerda; valores maiores que\n640 movem a tela para a direita."; -- 7
			"Estende a tela horizontalmente. O valor\npadrão é 2559; aumente para esticar a tela\npara a direita e diminua para estreitá-la\npara a esquerda."; -- 8
			"Reduz/expande a largura da área de exibição.\nO valor máximo é 2560; diminua-o para cortar\na tela à direita."; -- 9
			"Habilita o gerador de scanlines. Os jogos\nsão exibidos com esse tipo de linhas que as\nantigas TVs e monitores de tubo tinham."; -- 10
			"O controle permanece no Modo Digital.\nHabilita o suporte a joystick para jogos\nque não o suportam nativamente."; -- 11
			"O controle permanece no Modo Analógico.\nHabilita o suporte a joysticks para jogos\nque não o suportam nativamente."; -- 12
			"Ajuda com TVs de alta definição que não\nsuportam resoluções entrelaçadas via\ncomponente. Não é compatível com algumas\nTVs de tubo (CRT)."; -- 13
			"Silencia sons/músicas baseados em\nVAB/VAG/VB+VH em jogos. Pode ser útil para\njogos antigos que emitem efeitos sonoros ou\nruídos distorcidos."; -- 14
			"Abre o menu IGR.\nCombinação:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 15
			"Abre o menu IGR.\nCombinação:\nSELECT + START"; -- 16
			"Abre o menu IGR.\nCombinação:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 17
			"A combinação \"IGR\" encerra o POPS\n(não há menu \"IGR\").\nCombinação:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 18
			"A combinação \"IGR\" encerra o POPS\n(não há menu \"IGR\").\nCombinação:\nSELECT + START"; -- 19
			"A combinação \"IGR\" encerra o POPS\n(não há menu \"IGR\").\nCombinação:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 20
			"Desativa o menu IGR."; -- 21
			"Carrega uma palavra mágica LibCrypt nula no\nregistrador cop0. Pode ser necessário em\nalguns discos que apresentam problemas na\nproteção LibCrypt."; -- 22
			"Habilita o hack de tela ampla POPS GTE e\nforça 16:9. Não lida com coisas como HUDs,\ntextos, menus, fundos 2D (este hack não\nestá concluído)."; -- 23
			"Semelhante ao WIDESCREEN, mas com um campo\nde visão mais amplo. Não lida com coisas\ncomo HUDs, textos, menus, fundos 2D (este\nhack não está concluído)."; -- 24
			"Igual ao WIDESCREEN, com proporção de\naspecto 3×16:9. Não lida com coisas como\nHUDs, textos, menus, fundos 2D (este hack\nnão está concluído)."; -- 25
			"Force 480p. Não compatível com XPOS, YPOS,\nDWSTRETCH ou DWCROP. Evite usá-lo, pois não\né confiável."; -- 26
			"Use somente \"Virtual Memory Card 1\"."; -- 27
			"Use somente \"Virtual Memory Card 0\"."; -- 28
			"Impede que o POPStarter ative correções de\njogo. Este comando pode não funcionar em\nalguns jogos."; -- 29
			"Ajuda a restaurar músicas/vozes em vários\njogos.\nDesabilite se estiver usando patches \".bin\"."; -- 30
			"Uma variante do modo 0×01, com um segundo\nhack para não quebrar o MDECoding dos FMVs\n(foi projetado para a série Colony Wars).\nDesabilite se estiver usando patches \".bin\"."; -- 31
			"Pode ser usado se o modo 0×01 não fornecer\nos resultados esperados.\nDesabilite se estiver usando patches \".bin\"."; -- 32
			"Corrige lentidão, oscilações e muitas outras\nfalhas.\nDesabilite se estiver usando patches \".bin\"."; -- 33
			"Feito para corrigir as cutscenes do\nResident Evil: Director’s Cut (PAL).\nDesabilite se estiver usando patches \".bin\"."; -- 34
			"Desativa o shell OSD do BIOS integrado do\nemulador, fazendo com que alguns jogos que\ntravam na inicialização sejam executados.\nDesabilite se estiver usando patches \".bin\"."; -- 35
			-- Descrição dos patches para o POPStarter. ---------------------------------
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / +4 de brilho / DQA, DQB"; -- 36
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / Brilho normal / DQA, DQB"; -- 37
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / -4 de brilho / DQA, DQB"; -- 38
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / -16 de brilho / DQA, DQB"; -- 39
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / DQA, DQB"; -- 40
			"Possivelmente corrige jogos com problemas\n3D/2D.\nHack / IR0"; -- 41
			"Possivelmente corrige jogos com problemas\n3D/2D.\nA opção mais compatível e recomendada."; -- 42
			"Corrige falhas no nível do recompilador em\nraríssimos casos, apenas quando o problema é\numa atualização incorreta do código no cache\nde instruções do recompilador."; -- 43
			"Esses mods evitam falhas de áudio.\nRecomenda-se usar \"SPU_IRQ_ON_STABLE\",\npois é o mais estável; o áudio será pulado,\nentão você não o ouvirá."; -- 44
			"Isso aplica overclocks ao emulador,\nsuportando PAL e NTSC.\nAtenção: Valores acima de +40 podem causar\nproblemas de salvamento."; -- 45
			"Sem overclocking da GPU. Necessário para\nalgumas combinações de overclocking da CPU."; -- 46
			"Pode corrigir algumas partes do jogo, mas\nseu uso deve ser compensado por overclock.\nRecomenda-se que o clock da GPU seja 20%\nmenor que o clock da CPU."; -- 47
			"Desabilite o Dithering, este é um filtro\nespecial usado em jogos de PS1."; -- 48
			"Sem descrição."; -- 49
		};

		-- Menu de configurações para jogos de PS2. -------------------------------------
		TEXT_M_PS2 = {
			"Procurando configurações de jogo"; -- 1
			"Use o cartão de memória virtual"; -- 2
			"Sem cartão de memória virtual"; -- 3
			"Modos de compatibilidade"; -- 4
			"IOP: Fast Reads"; -- 5
			"Dummy"; -- 6
			"IOP: Sync Reads"; -- 7
			"EE : Unhook Syscalls"; -- 8
			"IOP: emulate DVD-DL"; -- 9
			"IOP: Fix game buffer overrun"; -- 10
			"Modo sintetizador gráfico"; -- 11
			"Forçar modo de vídeo"; -- 12
			"Modo de compatibilidade"; -- 13
			"Não utilizado"; -- 14
			"Salvar configurações do jogo"; -- 15
			"OPL"; -- 16
			"Neutrino"; -- 17
			"VMC não encontrado"; -- 18
			"Salvando as configurações do jogo"; -- 19
			"Accurate Reads"; -- 20
			"Synchronous Reads"; -- 21
			"Unhook Syscalls"; -- 22
			"Skip videos"; -- 23
			"Emulate DVD-DL"; -- 24
			"Disable IGR"; -- 25
			"Ajuste horizontal"; -- 26
			"Ajuste vertical"; -- 27
			"Salvar configurações?"; -- 28
			"AVISO:\nÉ recomendado que você configure seus jogos\ndentro do \"OPL\", pois pode haver conflitos entre\ndiferentes versões do \"OPL\" e seus arquivos de\nconfiguração."; -- 29
		};

		-- Menu do navegador. -----------------------------------------------------------
		TEXT_M_EXP = {
			"A pasta está vazia ou os arquivos não são compatíveis"; -- 1
			"Não há arquivos válidos"; -- 2
			"Itens"; -- 3
		};

		-- Menu de configurações para RETROLauncher. ------------------------------------
		TEXT_M_CON = {
			"Efeito RGB"; -- 1
			"Cor nos fundos"; -- 2
			"Definir uma cor de fundo"; -- 3
			"Vermelho"; -- 4
			"Verde"; -- 5
			"Azul"; -- 6
			"Estilo de lista"; -- 7
			"Fonte do texto"; -- 8
			"Papel de parede"; -- 9
			"GUI limpa"; -- 10
			"Coleta forçada de lixo"; -- 11
			"Saída personalizada"; -- 12
			"Diretório"; -- 13
			"Rotas completas no menu do APPS"; -- 14
			"Sons no menu"; -- 15
			"Volume de som"; -- 16
			"Capturas de tela como fundos"; -- 17
			"Modo de vídeo"; -- 18
			"Vibração no menu"; -- 19
			"Diretórios adicionais"; -- 20
			"Reiniciar todas as configurações"; -- 21
			"Créditos"; -- 22
			"Salvar configurações"; -- 23
			"Página 1"; -- 24
			"Página 2"; -- 25
			"Alterações não salvas. você quer sair?"; -- 26
			"Todas as alterações feitas serão perdidas."; -- 27
			"Selecione o dispositivo de pesquisa"; -- 28
			"Procurar"; -- 29
			"Ajustar largura"; -- 30
			"Ajustar altura"; -- 31
			"Ajuste os fundos de texto"; -- 32
			"Ajustar deslocamento de texto"; -- 33
			"Aumente ou diminua o deslocamento até que o número \"0\" fique visível ao lado da caixa colorida"; -- 34
			"Definir a fonte do texto"; -- 35
			"Ajustar texto em caixas escuras"; -- 36
			"Tente colocar o \"0\" na caixa de cores"; -- 37
			"Tente fazer a barra escura cobrir o texto"; -- 38
			"Exemplo de texto fixo"; -- 39
			"Restaurar"; -- 40
			"Estabelecer"; -- 41
			"Liberar o resto das listas?"; -- 42
			"Se ativado, o movimento será mais suave"; -- 43
			"mas haverá pausas ao alternar os sistemas."; -- 44
			"Desativar \"wLaunchELF\"?"; -- 45
			"Por favor aguarde"; -- 46
			"Música de fundo em loop?"; -- 47
			"Utilizar se o RetroArch tiver cortes de áudio ou"; -- 48
			"se você não tem os meios para alterar o formato"; -- 49
			"Restaurar"; -- 50 ...?
			"Apagar jogos salvos?"; -- 51
			"Alterar o modo de vídeo para"; -- 52 ...?
			"Reiniciar todas as configurações?"; -- 53
			"Padrão"; -- 54
			"(ativar cores de depuração)"; -- 55
			"Simple"; -- 56
			"Cover art"; -- 57
			"Full art"; -- 58
			"Big cover"; -- 59
			"Big art"; -- 60
			"Big list"; -- 61
			"Custom"; -- 62
			"Nível de zoom"; -- 63
			"Ativar sistemas"; -- 64
			"Transparência"; -- 65
			"Sem transparência"; -- 66
			"Selecione o aplicativo"; -- 67
			"Selecione a versão OPL"; -- 68
			"(configuração do usuário)"; -- 69
			"Apagar jogos salvos"; -- 70
			"Restaurando"; -- 71
			"Alterando as configurações de vídeo"; -- 72
			"Carregando listas de jogos e configurações"; -- 73
			"Reiniciando todas as configurações"; -- 74
			"W"; -- 75 Exemplo de configuração de fonte.
			"M"; -- 76 Exemplo de configuração de fonte.
			"Colunas"; -- 77
			"Linhas"; -- 78
			"Número de animações"; -- 79
			"Renomear imagem para configuração automática"; -- 80 ...?
			"Nome atual"; -- 81
			"Novo nome"; -- 82
			"Configuração do POPStarter"; -- 83
			"\"IGR\" sai para \"OSDSYS\""; -- 84
			"Desativar \"Dithering\" em jogos"; -- 85
			"Instalar tradução em \"IGR\""; -- 86
			"Configurar animação de camada"; -- 87
			"Tipo de animação"; -- 88
			"Velocidade da animação"; -- 89
			"Multiplicador de quadros"; -- 90
			"Tipo de transparência"; -- 91
			"Nível de transparência"; -- 92
			"Velocidade de transparência"; -- 93
			"Tipo de rotação"; -- 94
			"Velocidade de rotação"; -- 95
			"Camadas afetadas"; -- 96
			"Gire para a\ndireita"; -- 97
			"Gire para a\nesquerda"; -- 98
			"Mudando de\ndireção"; -- 99
			"Transparência\nfixa"; -- 100
			"Alternar\nmínimo/máximo"; -- 101
			"Alternar\nmitad/máximo"; -- 102
			"Alternar camadas\nmínimo/máximo"; -- 103
			"Alternar camadas\nmitad/máximo"; -- 104
			"Exibir índices de jogos?"; -- 105
			"Configuração de sprites"; -- 106
			"Ative os sprites no menu"; -- 107
			"Sprite correspondente ao"; -- 108
			"Tipo de animação"; -- 109
			"Velocidade da animação"; -- 110
			"Transparências na animação"; -- 111
			"Rotações na animação"; -- 112
			"Espelhar sprite"; -- 113
			"Branco"; -- 114
			"Tamanho do raio"; -- 115
			"Selecione o menu de configurações"; -- 116
			"Editor de estilo"; -- 117
			"Configuração do sprite"; -- 118
			"Transparência das capturas de tela"; -- 119
			"Exibir sempre o menu de execução alternativo."; -- 120
			"Cor das sombras atrás dos elementos"; -- 121
		};

		-- Nomes dos estilos de animação para os sprites. -------------------------------
		TEXT_SPR_T = {
			"Sprite\nfixo"; -- 1
			"Mova-se para\na direita\nno eixo\nhorizontal"; -- 2
			"Mova-se para\na esquerda\nno eixo\nhorizontal"; -- 3
			"Mova-se para\na direita\nno eixo\nhorizontal\n+zigzague\nno eixo\nvertical\n(curto)"; -- 4
			"Mova-se para\na esquerda\nno eixo\nhorizontal\n+zigzague\nno eixo\nvertical\n(curto)"; -- 5
			"Mova-se para\na direita\nno eixo\nhorizontal\n+zigzague\nno eixo\nvertical\n(longo)"; -- 6
			"Mova-se para\na esquerda\nno eixo\nhorizontal\n+zigzague\nno eixo\nvertical\n(longo)"; -- 7
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(curto)"; -- 8
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(metade)"; -- 9
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(longo)"; -- 10
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(curto)\n+zigzague\nno eixo\nvertical"; -- 11
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(metade)\n+zigzague\nno eixo\nvertical"; -- 12
			"Mova-se da\ndireita para\na esquerda\nno eixo\nhorizontal\n(longo)\n+zigzague\nno eixo\nvertical"; -- 13
			"Descer\nno eixo\nvertical"; -- 14
			"Subir\nno eixo\nvertical"; -- 15
			"Descer\nno eixo\nvertical\n+zigzague\nno eixo\nhorizontal\n(curto)"; -- 16
			"Subir\nno eixo\nvertical\n+zigzague\nno eixo\nhorizontal\n(curto)"; -- 17
			"Descer\nno eixo\nvertical\n+zigzague\nno eixo\nhorizontal\n(longo)"; -- 18
			"Subir\nno eixo\nvertical\n+zigzague\nno eixo\nhorizontal\n(longo)"; -- 19
			"Subir e\ndescer\nno eixo\nvertical\n(curto)"; -- 20
			"Subir e\ndescer\nno eixo\nvertical\n(metade)"; -- 21
			"Subir e\ndescer\nno eixo\nvertical\n(longo)"; -- 22
			"Subir e\ndescer\nno eixo\nvertical\n(curto)\n+zigzague\nno eixo\nhorizontal"; -- 23
			"Subir e\ndescer\nno eixo\nvertical\n(metade)\n+zigzague\nno eixo\nhorizontal"; -- 24
			"Subir e\ndescer\nno eixo\nvertical\n(longo)\n+zigzague\nno eixo\nhorizontal"; -- 25
			"Aceleração\nao descer\npara a\ndireita"; -- 26
			"Aceleração\nao descer\npara a\nesquerda"; -- 27
			"Aceleração\nao subir\npela direita"; -- 28
			"Aceleração\nao subir\npela esquerda"; -- 29
			"Aceleração\nda direita\npara a\nesquerda"; -- 30
			"Aceleração\nda esquerda\npara a\ndireita"; -- 31
			"Aceleração\nda direita\npara a\nesquerda\n+mudança\nno eixo\nvertical"; -- 32
			"Aceleração\nda esquerda\npara a\ndireita\n+mudança\nno eixo\nvertical"; -- 33
			"Desacelerar\nda direita\npara a\nesquerda"; -- 34
			"Desacelerar\nda esquerda\npara a\ndireita"; -- 35
			"Aceleração\nao descer\npara a\nesquerda"; -- 36
			"Aceleração\nao subir\npela\nesquerda"; -- 37
			"Aceleração\nao descer\npara a\ndireita"; -- 38
			"Aceleração\nao subir\npela\nderecha"; -- 39
			"Aceleração\nem descida"; -- 40
			"Aceleração\nna ascensão"; -- 41
			"Aceleração\nem descida\n+mudança\nno eixo\nhorizontal"; -- 42
			"Aceleração\nna ascensão\n+mudança\nno eixo\nhorizontal"; -- 43
			"Desacelerar\nna descida"; -- 44
			"Desacelerar\nao acender"; -- 45
			"Flutuar\nna diagonal\nversão 1"; -- 46
			"Flutuar\nna diagonal\nversão 2"; -- 47
			"Diagonal\ninferior\ndireita"; -- 48
			"Diagonal\ninferior\nesquerda"; -- 49
			"Diagonal\nsuperior\ndireita"; -- 50
			"Diagonal\nsuperior\nesquerda"; -- 51
			"Percorra\no quadro\nno sentido\nhorário"; -- 52
			"Percorra\no quadro\nno sentido\nanti-horário"; -- 53
			"Dando voltas\nem círculos\nno sentido\nhorário\n(curto)"; -- 54
			"Dando voltas\nem círculos\nno sentido\nanti-horário\n(curto)"; -- 55
			"Dando voltas\nem círculos\nno sentido\nhorário\n(metade)"; -- 56
			"Dando voltas\nem círculos\nno sentido\nanti-horário\n(metade)"; -- 57
			"Dando voltas\nem círculos\nno sentido\nhorário\nem tela\ncheia"; -- 58
			"Dando voltas\nem círculos\nno sentido\nanti-horário\nem tela\ncheia"; -- 59
			"Rebater\nna tela"; -- 60
			"Aumentar\no tamanho\n(curto)"; -- 61
			"Aumentar\no tamanho\n(metade)"; -- 62
			"Controle o\nsprite com\no analógico\ndireito"; -- 63
			"Manter a\ntransparencia"; -- 64
			"Alternar\nentre mínimo\ne máximo"; -- 65
			"Alternar\nentre metade\ne o máximo"; -- 66
			"Espelhar\no eixo\nhorizontal\nde acordo\ncom o\nmovimento"; -- 67
			"Espelhar\no eixo\nvertical\nde acordo\ncom o\nmovimento"; -- 68
			"Espelhar\nambos os\neixos\nde acordo\ncom o\nmovimento"; -- 69
			"Espelhar\no eixo\nhorizontal\nmanualmente\ncom o\nanalógico\ndireito"; -- 70
			"Espelhar\no eixo\nvertical\nmanualmente\ncom o\nanalógico\ndireito"; -- 71
			"Espelhar\nambos os\neixos\nmanualmente\ncom o\nanalógico\ndireito"; -- 72
			"Manter o\nreflexo\nno eixo\nhorizontal"; -- 73
			"Manter o\nreflexo\nno eixo\nvertical"; -- 74
			"Manter\nreflexos\nem ambos\nos eixos"; -- 75
			"Digite o\nnúmero de\ncolunas que\ncontêm a\nimagem\n(vertical)"; -- 76
			"Digite o\nnúmero de\nlinhas que\ncontêm a\nimagem\n(horizontal)"; -- 77
		};

		-- Nomes dos estilos de animação para as camadas. -------------------------------
		TEXT_LAY_T = {
			"Camadas fixas"; -- 1
			"Direita\nhorizontal v1"; -- 2
			"Esquerda\nhorizontal v1"; -- 3
			"Direita\nziguezaguear"; -- 4
			"Esquerda\nziguezaguear"; -- 5
			"Direita\nfrontal v1"; -- 6
			"Esquerda\nfrontal v1"; -- 7
			"Ziguezaguear\nhorizontal v1"; -- 8
			"Direita\nhorizontal v2"; -- 9
			"Esquerda\nhorizontal v2"; -- 10
			"Esquerda\nfrontal v2"; -- 11
			"Direita\nfrontal v2"; -- 12
			"Direita\nfrontal v3"; -- 13
			"Esquerda\nfrontal v3"; -- 14
			"Direita\npanorâmico v1"; -- 15
			"Esquerda\npanorâmico v1"; -- 16
			"Direita\npanorâmico v2"; -- 17
			"Esquerda\npanorâmico v2"; -- 18
			"Cruzamento\nhorizontal"; -- 19
			"Ziguezaguear\nhorizontal v2"; -- 20
			"Baixo\nvertical v1"; -- 21
			"Cima\nvertical v1"; -- 22
			"Baixo\nziguezaguear"; -- 23
			"Cima\nziguezaguear"; -- 24
			"Cima\nfrontal v1"; -- 25
			"Baixo\nfrontal v1"; -- 26
			"Ziguezaguear\nvertical v1"; -- 27
			"Baixo\nvertical v2"; -- 28
			"Cima\nvertical v2"; -- 29
			"Cima\nfrontal v2"; -- 30
			"Baixo\nfrontal v2"; -- 31
			"Baixo\nfrontal v3"; -- 32
			"Cima\nfrontal v3"; -- 33
			"Baixo\npanorâmico v1"; -- 34
			"Cima\npanorâmico v1"; -- 35
			"Baixo\npanorâmico v2"; -- 36
			"Cima\npanorâmico v2"; -- 37
			"Cruzamento\nvertical"; -- 38
			"Ziguezaguear\nvertical v2"; -- 39
			"Direita\nredemoinho"; -- 40
			"Esquerda\nredemoinho"; -- 41
			"Zoom 3-4\nPixel zoom"; -- 42
			"Zoom 1-2\nPixel zoom"; -- 43
			"Zoom 2-3\nPixel zoom"; -- 44
			"Zoom 1-4\nPixel zoom"; -- 45
			"Zoom 1-3-4\nPixel zoom"; -- 46
			"Zoom 1-2-3\nPixel zoom"; -- 47
			"Zoom 2-3-4\nPixel zoom"; -- 48
			"Zoom 1-2-4\nPixel zoom"; -- 49
			"Zoom 1-2-3-4\nPixel zoom"; -- 50
			"Zoom 3-4 v2\nPixel zoom"; -- 51
			"Zoom 1-2 v2\nPixel zoom"; -- 52
			"Zoom 2-3 v2\nPixel zoom"; -- 53
			"Zoom 1-4 v2\nPixel zoom"; -- 54
			"Zoom 1-3-4 v2\nPixel zoom"; -- 55
			"Zoom 1-2-3 v2\nPixel zoom"; -- 56
			"Zoom 2-3-4 v2\nPixel zoom"; -- 57
			"Zoom 1-2-4 v2\nPixel zoom"; -- 58
			"Zoom 1-2-3-4 v2\nPixel zoom"; -- 59
			"Direita\nhorizontal v3"; -- 60
			"Esquerda\nhorizontal v3"; -- 61
			"Baixo\nvertical v3"; -- 62
			"Cima\nvertical v3"; -- 63
		};

		-- Menu do editor de estilo. ----------------------------------------------------
		TEXT_M_STI = {
			"Exemplo de nome de jogo.zip"; -- 1
			"Centro / Exemplo de nome de jogo.zip"; -- 2
			"Direita / Exemplo de nome de jogo.zip"; -- 3
			"Esquerda / Exemplo de nome de jogo.zip"; -- 4
			"Nº de jogos"; -- 5
			"Sair"; -- 6
			"Configurar"; -- 7
			"Mudar a arte"; -- 8
			"Tela cheia"; -- 9
			"Executar"; -- 10
			"Atualizar"; -- 11
			"Lista"; -- 12
			"Arte"; -- 13
			"Arte extra"; -- 14
			"Cover flow"; -- 15
			"Logotipo"; -- 16
			"Botão de Cruz"; -- 17
			"Botão Triângulo"; -- 18
			"Botão Quadrado"; -- 19
			"Botão L1"; -- 20
			"Botão R1"; -- 21
			"Botão R3"; -- 22
			"Botão START"; -- 23
			"Botão SELECT"; -- 24
			"Tipo de transição"; -- 25
			"Velocidade"; -- 26
			"Restaurar tudo"; -- 27
			"Salve o estilo"; -- 28
			"Sair do menu de edição"; -- 29
			"Bloquear"; -- 30
			"Guias"; -- 31
			"Posição"; -- 32
			"Tamanho"; -- 33
			"Pixels"; -- 34
			"Restaurar"; -- 35
			"Próximo"; -- 36
			"Anterior"; -- 37
			"Ajuda"; -- 38
			"Elementos"; -- 39
			"Salvar"; -- 40
			"Menu"; -- 41
			"Pixels"; -- 42
			"Ativar elementos"; -- 43
			"Sombra"; -- 44
			"Opções adicionais"; -- 45
			"Reiniciar todos os itens?"; -- 46
			"Salvar alterações?"; -- 47
			"Ao salvar, se existir uma configuração anterior\nserá criada uma cópia de segurança dela\n(substituindo a última cópia existente)."; -- 48
		};

		-- Menu principal. --------------------------------------------------------------
		TEXT_M_PRI = {
			"-Carregando Arte-"; -- 1
			"Sair"; -- 2
			"Configurações"; -- 3
			"Mudar a arte"; -- 4
			"Tela cheia"; -- 5
			"Executar"; -- 6
			"Atualizar"; -- 7
			"Configurar"; -- 8
			"Menu"; -- 9
			"Arte"; -- 10
			"Zoom"; -- 11
			"Jogar"; -- 12
			"Carregando"; -- 13
			"Sem elementos"; -- 14
			"Erro!"; -- 15
			"Jogos ou RetroArch"; -- 16
			"Aplicativo ou ELF"; -- 17
			"POPS ou Binários"; -- 18
			"Neutrino/OPL ou ISO"; -- 19
			"Não encontrado!"; -- 20
			"Nº de jogos"; -- 21
			"Nº de APPS"; -- 22
			"Reiniciar o RETROLauncher?"; -- 23
			"Sair do RETROLauncher?"; -- 24
			"AVISO!"; -- 25
			"Todas as opções de RetroArch serão reiniciadas"; -- 26
			"-Carregando-"; -- 27
			"Onde você quer criar o executable do jogo?"; -- 28
			"Diretório \"POPS\""; -- 29
			"Diretório \"APPS\""; -- 30
			"Configurar"; -- 31
			"Alternativa"; -- 32
			"Variante"; -- 33
			"Explorador"; -- 34
			"Selecione o dispositivo a ser examinado"; -- 35
			"Ember ou Bios/CUE"; -- 36
		};

		-- Menu de Realocação. ----------------------------------------------------------
		TEXT_M_REL = {
			"AVISO\nEste programa foi projetado para ser executado\na partir da primeira porta (USB) do PS2.\nReconecte o USB à primeira porta e\nreinicie o programa."; -- 1
			"AVISO\nDispositivo de armazenamento USB detectado na\nsegunda porta USB.\ndesconecte o dispositivo USB da segunda porta\ne reinicie o programa."; -- 2
			"O diretório atual não corresponde\nà sua configuração.\nDeseja realocar as configurações\npara este diretório?\nAVISO!\nAs opções de RetroArch serão reiniciadas"; -- 3
			"Realocar"; -- 4
			"Realocando"; -- 5
			"Realocando todas as configurações"; -- 6
		};

	-------------------------------------------------------------------------------------
	-- English. -------------------------------------------------------------------------
	else
		if doesFileExist(actual .."/System/Defaults/ENG") == false then
			local lang_arc = System.openFile(actual .."/System/Defaults/ENG", FCREATE)
			System.closeFile(lang_arc)
		end
		-- Note. ------------------------------------------------------------------------
		-- Avoid using words or phrases that exceed the character limit of the originals, to avoid text outside the frame.
		-- ...? - It is a question that can vary, so it ends in another part of the code; in these cases, omit the "?" character at the end.
		-- \n - It's a line break, so there should be no space between them and the word that follows them.
		-- \" - It is used to escape a special character used by the code that could cause conflicts.

		-- General use texts. -----------------------------------------------------------
		TEXT_GEN = {
			"Quit"; -- 1
			"Off"; -- 2
			"On"; -- 3
			"Back"; -- 4
			"Select"; -- 5
			"Cancel"; -- 6
			"Exit"; -- 7
			"Change"; -- 8
			"No"; -- 9
			"Yes"; -- 10
			"Reset"; -- 11
			"Save"; -- 12
			"Enabled"; -- 13
			"Disabled"; -- 14
		};

		-- Settings menu for PS1 games. -------------------------------------------------
		TEXT_M_PS1 = {
			"Install \"CHEATS.TXT\" file"; -- 1
			"Searching for \"CHEATS.TXT\" files"; -- 2
			"Description"; -- 3
			"Code control"; -- 4
			"Save selected codes"; -- 5 ...?
			"Saving codes"; -- 6
			"Installing patches"; -- 7
			"Looking for patches"; -- 8
			"Loading game settings"; -- 9
			"Cleaning game settings"; -- 10
			"General use patches found"; -- 11
			"Patches with the same name will be replaced."; -- 12
			"Game patches found"; -- 13
			"All previous patches will be removed."; -- 14
			"Install patch"; -- 15
			"Name of the patch to be installed"; -- 16
			"Install"; -- 17
			"Install selected patches"; -- 18 ...?
			"Install patches for specific games"; -- 19
			"Install general patches"; -- 20
			"Extra settings"; -- 21
			"Clear game settings"; -- 22
			"Select the configuration type"; -- 23
			"Only patches"; -- 24
			"Only codes"; -- 25
			"All configurations"; -- 26
			"Clear selected settings"; -- 27 ...?
			"Clean"; -- 28
			"\"CHEATS.TXT\" of games found"; -- 29
			"The previous \"CHEATS.TXT\" will be deleted."; -- 30
			"Install \"CHEATS.TXT\" selected"; -- 31 ...?
			"\"CHEATS.TXT\" of the game to be installed"; -- 32
			"Installing \"CHEATS.TXT\""; -- 33
		};

		-- Descriptions for POPStarter options. -----------------------------------------
		TEXT_POPS_DESCR = {
			-- Description of codes for POPStarter. -------------------------------------
			"Disables the cheat engine and only activate\nit after POPS has left the PS1 OSD.\nShould be always ON."; -- 1
			"Enables the smooth texture mapping at\nstartup."; -- 2
			"Sets up the PFS wrapper USB delay.\nFor USB devices that have problems running\n\"POPStarter\"."; -- 3
			"Forces the activation of the PAL patcher\nand patches the region code to Euro.\nUseful for PAL VCDs that don’t have a valid\nlicense text in their bootsector."; -- 4
			"Disables POPStarters PAL patcher.\nNot meant to convert NTSC games to PAL."; -- 5
			"Centers the screen vertically.\nNo default value, depends on the game, you\nhave to experiment. The higher the value\nis, the more the screen moves down."; -- 6
			"Centers the screen horizontally.\nDefault value is 640; value lower than 640\nwill move the screen on the left, value\nhigher than 640 will move it to the right."; -- 7
			"Stretches the display horizontally to\nyour screen. Default value is 2559;\nincrease it to stretch the screen on the\nright, decrease it for the left."; -- 8
			"Reduces/expands the display area width.\nMaximum value is 2560; decrease it to crop\nthe screen on the right."; -- 9
			"Enables the scanlines generator.\nThe games are seen with this type of lines\nthat the old TVs and tube monitors had."; -- 10
			"The control remains in Digital Mode.\nEnables joystick support for games that\ndoesn’t support it natively."; -- 11
			"The control remains in Analog Mode.\nEnables joystick support for games that\ndoesn’t support it natively."; -- 12
			"Helps with the HDTVs that can’t deal with\nthe interlaced resolutions thru component.\nNot compatible with some CRT TVs."; -- 13
			"Mute VAB/VAG/VB+VH based sounds/music on\ngames. May be useful for these old games\nwhich output distorted SFX, wrong audio\nsamples or noises."; -- 14
			"Opens the IGR menu.\nCombination:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 15
			"Opens the IGR menu.\nCombination:\nSELECT + START"; -- 16
			"Opens the IGR menu.\nCombination:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 17
			"The \"IGR\" combination ends POPS\n(there is no \"IGR\" menu).\nCombination:\nL1 + L2 + R1 + R2 + X + DOWN"; -- 18
			"The \"IGR\" combination ends POPS\n(there is no \"IGR\" menu).\nCombination:\nSELECT + START"; -- 19
			"The \"IGR\" combination ends POPS\n(there is no \"IGR\" menu).\nCombination:\nL1 + L2 + R1 + R2 + SELECT + START"; -- 20
			"Disables the IGR menu."; -- 21
			"Loads a null LibCrypt magic word into the\ncop0 register. May be needed by some discs\nthat have a messed up LibCrypt protection."; -- 22
			"Enables POPS GTE widescreen hack and\nforces 16:9. Does not deal with stuff like\nHUDs, texts/fonts, menus, 2D backgrounds\n(This hack is not finished)."; -- 23
			"Same as WIDESCREEN, but wider field of\nvision. Does not deal with stuff like HUDs,\ntexts/fonts, menus, 2D backgrounds\n(This hack is not finished)."; -- 24
			"Same as WIDESCREEN, with 3×16:9 aspect\nratio. Does not deal with stuff like HUDs,\ntexts/fonts, menus, 2D backgrounds\n(This hack is not finished)."; -- 25
			"Force 480p. Not compatible with XPOS, YPOS,\nDWSTRETCH, or DWCROP.\nAvoid using it, it's unreliable."; -- 26
			"Use only \"Virtual Memory Card 1\"."; -- 27
			"Use only \"Virtual Memory Card 0\"."; -- 28
			"Prevents POPStarter from activating game\nfixes. This command may not work in some\ngames."; -- 29
			"Helps restoring the music/voices in several\ngames.\nDisable if using \".bin\" patches."; -- 30
			"A variant of mode 0×01, with a second hack\nfor not breaking the MDECoding of FMVs\n(was designed for the Colony Wars series).\nDisable if using \".bin\" patches."; -- 31
			"Can be used if the mode 0×01 doesn’t\nprovide the expected results.\nDisable if using \".bin\" patches."; -- 32
			"Fixes slowdowns, flickering, and many other\nglitches.\nDisable if using \".bin\" patches."; -- 33
			"Made for fixing the cutscenes of the\nResident Evil: Director’s Cut (PAL).\nDisable if using \".bin\" patches."; -- 34
			"Disables the OSD shell of the\nemulator’s built-in BIOS, making some games\nthat freeze on startup run.\nDisable if using \".bin\" patches."; -- 35
			-- Description of patches for POPStarter. -----------------------------------
			"Possibly fixes games with 3D/2D issues.\nHack / +4 brightness / DQA, DQB"; -- 36
			"Possibly fixes games with 3D/2D issues.\nHack / Normal brightness / DQA, DQB"; -- 37
			"Possibly fixes games with 3D/2D issues.\nHack / -4 brightness / DQA, DQB"; -- 38
			"Possibly fixes games with 3D/2D issues.\nHack / -16 brightness / DQA, DQB"; -- 39
			"Possibly fixes games with 3D/2D issues.\nHack / DQA, DQB"; -- 40
			"Possibly fixes games with 3D/2D issues.\nHack / IR0"; -- 41
			"Possibly fixes games with 3D/2D issues.\nThe most compatible and recommended."; -- 42
			"Fixes crashes at the Recompiler level\ninvery few cases, only when the problem is\nbad updating of the code in the recompiler\ninstruction cache."; -- 43
			"These mods prevent audio glitches.\nIt's recommended to use \"SPU_IRQ_ON_STABLE\",\nas it's the most stable; the audio will be\nskipped, so you won't hear it."; -- 44
			"This applies overclocks to the emulator,\nsupporting both PAL and NTSC.\nCaution:\nValues above +40 may cause save issues."; -- 45
			"No GPU overclocking. Required for some CPU\noverclocking combinations."; -- 46
			"It may fix some sections of the game, but\nits use should be compensated by\noverclocking. It is recommended that the\nGPU clock be 20% lower than the CPU clock."; -- 47
			"Disable Dithering, this is a special filter\nused in PS1 games."; -- 48
			"No description."; -- 49
		};

		-- Settings menu for PS2 games. -------------------------------------------------
		TEXT_M_PS2 = {
			"Search for game settings"; -- 1
			"Use virtual memory card"; -- 2
			"No virtual memory card"; -- 3
			"Compatibility modes"; -- 4
			"IOP: Fast Reads"; -- 5
			"Dummy"; -- 6
			"IOP: Sync Reads"; -- 7
			"EE : Unhook Syscalls"; -- 8
			"IOP: Emulate DVD-DL"; -- 9
			"IOP: Fix game buffer overrun"; -- 10
			"Graphics synthesizer mode"; -- 11
			"Force video mode"; -- 12
			"Compatibility mode"; -- 13
			"Unused"; -- 14
			"Save game settings"; -- 15
			"OPL"; -- 16
			"Neutrino"; -- 17
			"Virtual memory card not found"; -- 18
			"Saving game settings"; -- 19
			"Accurate Reads"; -- 20
			"Synchronous Reads"; -- 21
			"Unhook Syscalls"; -- 22
			"Skip videos"; -- 23
			"Emulate DVD-DL"; -- 24
			"Disable IGR"; -- 25
			"Horizontal adjustment"; -- 26
			"Vertical adjustment"; -- 27
			"Save settings?"; -- 28
			"WARNING:\nIt is recommended that you configure your games\nwithin \"OPL\", as there may be conflicts between\ndifferent versions of \"OPL\" and their\nconfiguration files."; -- 29
		};

		-- Browser menu. ----------------------------------------------------------------
		TEXT_M_EXP = {
			"The folder is empty or the files are not supported"; -- 1
			"No valid files"; -- 2
			"Items"; -- 3
		};

		-- Settings menu for RETROLauncher. ---------------------------------------------
		TEXT_M_CON = {
			"RGB Effect"; -- 1
			"Color in backgrounds"; -- 2
			"Fixed color in backgrounds"; -- 3
			"Red"; -- 4
			"Green"; -- 5
			"Blue"; -- 6
			"List style"; -- 7
			"Font type"; -- 8
			"Change the background"; -- 9
			"Clean GUI"; -- 10
			"Force garbage collection"; -- 11
			"Custom APP/ELF output"; -- 12
			"Directory"; -- 13
			"See full route in the APPS menu"; -- 14
			"Sound in the menu"; -- 15
			"Sound volume"; -- 16
			"Screenshot as background"; -- 17
			"Video mode"; -- 18
			"Vibration in menu"; -- 19
			"Extra directories"; -- 20
			"Reset all settings"; -- 21
			"Credits"; -- 22
			"Save settings"; -- 23
			"Page 1"; -- 24
			"Page 2"; -- 25
			"Unsaved changes. Do you want to exit?"; -- 26
			"All changes made will be lost upon reboot."; -- 27
			"Select search device"; -- 28
			"Search"; -- 29
			"Set width"; -- 30
			"Set height"; -- 31
			"Set text background"; -- 32
			"Set the start of the text scroll"; -- 33
			"Increase or decrease the minimum number of scrolls until the number \"0\" is visible next to the right frame of the color box."; -- 34
			"Text font setting"; -- 35
			"Try to fit all the text into the dark boxes"; -- 36
			"Try placing the \"0\" in the color box"; -- 37
			"Try to make the dark bar cover the text"; -- 38
			"Fixed text example"; -- 39
			"Default values"; -- 40
			"Set values"; -- 41
			"Release rest of lists?"; -- 42
			"When enabled, list movement will be smoother"; -- 43
			"at the cost of pauses in system changes."; -- 44
			"Disable \"wLaunchELF\"?"; -- 45
			"Please wait"; -- 46
			"Background music loop?"; -- 47
			"Use only if RetroArch has audio cuts or if"; -- 48
			"you have no other means to change the format"; -- 49
			"Reset"; -- 50 ...?
			"Deleting saved states?"; -- 51
			"Change video mode to"; -- 52 ...?
			"Reset all settings?"; -- 53
			"Standard"; -- 54
			"(enable debug colors)"; -- 55
			"Simple"; -- 56
			"Cover art"; -- 57
			"Full art"; -- 58
			"Big cover"; -- 59
			"Big art"; -- 60
			"Big list"; -- 61
			"Custom"; -- 62
			"Zoom level"; -- 63
			"Activate systems"; -- 64
			"Transparency"; -- 65
			"Transparency off"; -- 66
			"Select application"; -- 67
			"Select OPL version"; -- 68
			"(set by user)"; -- 69
			"Deleting saved states"; -- 70
			"Restarting"; -- 71
			"Changing video settings"; -- 72
			"Loading game lists and settings"; -- 73
			"Restarting all settings"; -- 74
			"W"; -- 75 Example for font configuration.
			"M"; -- 76 Example for font configuration.
			"Columns"; -- 77
			"Rows"; -- 78
			"Number of animations"; -- 79
			"Rename image for auto-configuration"; -- 80 ...?
			"Current name"; -- 81
			"New name"; -- 82
			"POPStarter setup"; -- 83
			"\"IGR\" exits to \"OSDSYS\""; -- 84
			"Disable \"Dithering\" in games"; -- 85
			"Install translation in \"IGR\""; -- 86
			"Configure layer animation"; -- 87
			"Type of animation"; -- 88
			"Animation speed"; -- 89
			"Speed multiplier"; -- 90
			"Type of transparency"; -- 91
			"Level of transparency"; -- 92
			"Transparency speed"; -- 93
			"Type of rotation"; -- 94
			"Rotation speed"; -- 95
			"Affected layers"; -- 96
			"Turn right"; -- 97
			"Turn left"; -- 98
			"Alternate\ndirection"; -- 99
			"Fixed\ntransparency"; -- 100
			"Alternate\nminimum/maximum"; -- 101
			"Alternate\nhalf/maximum"; -- 102
			"Alternate layers\nminimum/maximum"; -- 103
			"Alternate layers\nhalf/maximum"; -- 104
			"Show game indexes?"; -- 105
			"Sprite configuration"; -- 106
			"Enable sprites in the menu"; -- 107
			"Sprite corresponding to"; -- 108
			"Type of animation"; -- 109
			"Animation speed"; -- 110
			"Transparencies in animation"; -- 111
			"Rotations in animation"; -- 112
			"Flip sprites"; -- 113
			"White"; -- 114
			"Radius size"; -- 115
			"Select settings menu"; -- 116
			"Style editor"; -- 117
			"Sprite configuration"; -- 118
			"Transparency of screenshots"; -- 119
			"Always show the alternative execution menu"; -- 120
			"Color of the shadows behind the elements"; -- 121
		};

		-- Nombre de los estilos de animación para los sprites. -------------------------
		TEXT_SPR_T = {
			"Still\nsprite"; -- 1
			"Move right\non the\nhorizontal\naxis"; -- 2
			"Move left\non the\nhorizontal\naxis"; -- 3
			"Move right\non the\nhorizonta\naxis\n+zigzag on\nthe vertical\naxis (short)"; -- 4
			"Move left\non the\nhorizontal\naxis\n+zigzag on\nthe vertical\naxis (short)"; -- 5
			"Move right\non the\nhorizontal\naxis\n+zigzag on\nthe vertical\naxis (long)"; -- 6
			"Move left\non the\nhorizontal\naxis\n+zigzag on\nthe vertical\naxis (long)"; -- 7
			"Move from\nright to\nleft on the\nhorizontal\naxis (short)"; -- 8
			"Move from\nright to\nleft on the\nhorizontal\naxis (half)"; -- 9
			"Move from\nright to\nleft on the\nhorizontal\naxis (long)"; -- 10
			"Move from\nright to\nleft on the\nhorizontal\naxis (short)\n+zigzag on\nthe vertical\naxis"; -- 11
			"Move from\nright to\nleft on the\nhorizontal\naxis (half)\n+zigzag on\nthe vertical\naxis"; -- 12
			"Move from\nright to\nleft on the\nhorizontal\naxis (long)\n+zigzag on\nthe vertical\naxis"; -- 13
			"Go down on\nthe vertical\naxis"; -- 14
			"Climb on the\nvertical axis"; -- 15
			"Go down on\nthe vertical\naxis\n+zigzag\non the\nhorizontal\naxis (short)"; -- 16
			"Climb on the\nvertical axis\n+zigzag\non the\nhorizontal\naxis (short)"; -- 17
			"Go down on\nthe vertical\naxis\n+zigzag\non the\nhorizontal\naxis (long)"; -- 18
			"Climb on the\nvertical axis\n+zigzag\non the\nhorizontal\naxis (long)"; -- 19
			"Going up\nand down on\nthe vertical\naxis (short)"; -- 20
			"Going up\nand down on\nthe vertical\naxis (half)"; -- 21
			"Going up\nand down on\nthe vertical\naxis (long)"; -- 22
			"Going up\nand down on\nthe vertical\naxis (short)\n+zigzag\non the\nhorizontal\naxis"; -- 23
			"Going up\nand down on\nthe vertical\naxis (half)\n+zigzag\non the\nhorizontal\naxis"; -- 24
			"Going up\nand down on\nthe vertical\naxis (long)\n+zigzag\non the\nhorizontal\naxis"; -- 25
			"Acceleration\nwhen going\ndown to the\nright"; -- 26
			"Acceleration\nwhen going\ndown to the\nleft"; -- 27
			"Acceleration\nwhen going\nup the right"; -- 28
			"Acceleration\nwhen going\nup on the\nleft"; -- 29
			"Acceleration\nfrom right\nto left"; -- 30
			"Acceleration\nfrom left\nto right"; -- 31
			"Acceleration\nfrom right\nto left\n+change in\nthe vertical\naxis"; -- 32
			"Acceleration\nfrom left\nto right\n+change in\nthe vertical\naxis"; -- 33
			"Decelerate\nfrom right\nto left"; -- 34
			"Decelerate\nfrom left\nto right"; -- 35
			"Acceleration\nwhen going\ndown to the\nleft"; -- 36
			"Acceleration\nwhen going\nup on the\nleft"; -- 37
			"Acceleration\nwhen going\ndown to the\nright"; -- 38
			"Acceleration\nwhen going\nup the right"; -- 39
			"Acceleration\non downhill"; -- 40
			"Acceleration\non the\nupwards"; -- 41
			"Acceleration\non downhill\n+change\nin the\nhorizontal\naxis"; -- 42
			"Acceleration\non the\nupwards\n+change\nin the\nhorizontal\naxis"; -- 43
			"Slow\ndownwards"; -- 44
			"Slow down\nwhen going\nup"; -- 45
			"Floating\ndiagonal\nversion 1"; -- 46
			"Floating\ndiagonal\nversion 2"; -- 47
			"Diagonal\ndown right"; -- 48
			"Diagonal\ndown left"; -- 49
			"Diagonal\nupper right"; -- 50
			"Diagonal\nupper left"; -- 51
			"Move around\nthe screen\nclockwise"; -- 52
			"Move around\nthe screen\ncounter\nclockwise"; -- 53
			"Going around\nin circles\nclockwise\n(short)"; -- 54
			"Going around\nin circles\ncounter\nclockwise\n(short)"; -- 55
			"Going around\nin circles\nclockwise\n(half)"; -- 56
			"Going around\nin circles\ncounter\nclockwise\n(half)"; -- 57
			"Going around\nin circles\nclockwise in\nfull screen"; -- 58
			"Going around\nin circles\ncounter\nclockwise in\nfull screen"; -- 59
			"Bounce\naround\nthe screen"; -- 60
			"Zoom in\n(short)"; -- 61
			"Zoom in\n(half)"; -- 62
			"Control\nsprite\nwith the\nright stick"; -- 63
			"Set level of\ntransparency"; -- 64
			"Alternate\nbetween\nminimum and\nmaximum"; -- 65
			"Alternate\nbetween\nhalf and\nmaximum"; -- 66
			"Reflect the\nhorizontal\naxis\naccording to\nthe movement"; -- 67
			"Reflect the\nvertical\naxis\naccording to\nthe movement"; -- 68
			"Reflect\nboth axes\naccording to\nthe movement"; -- 69
			"Manually\nreflect the\nhorizontal\naxis through\nthe right\nstick"; -- 70
			"Manually\nreflect the\nvertical\naxis through\nthe right\nstick"; -- 71
			"Manually\nreflect both\naxes via the\nright stick"; -- 72
			"Fix the\nreflex\non the\nhorizontal\naxis"; -- 73
			"Fix the\nreflex\non the\nvertical\naxis"; -- 74
			"Fix the\nreflex\non both axes"; -- 75
			"Enter the\nnumber of\ncolumns that\ncontain\nthe image\n(vertical)"; -- 76
			"Enter the\nnumber of\nrows\ncontaining\nthe image\n(horizontal)"; -- 77
		};

		-- Names of the animation styles for the layers. --------------------------------
		TEXT_LAY_T = {
			"Fixed layers"; -- 1
			"Right\nhorizontal v1"; -- 2
			"Left\nhorizontal v1"; -- 3
			"Right zigzag\nvertical"; -- 4
			"Left zigzag\nvertical"; -- 5
			"Right\nfrontal"; -- 6
			"Left\nfrontal"; -- 7
			"Center zigzag\nhorizontal v1"; -- 8
			"Right\nhorizontal v2"; -- 9
			"Left\nhorizontal v2"; -- 10
			"Left\nfrontal v2"; -- 11
			"Right\nfrontal v2"; -- 12
			"Right\nfrontal v3"; -- 13
			"Left\nfrontal v3"; -- 14
			"Right\npanoramic v1"; -- 15
			"Left\npanoramic v1"; -- 16
			"Right\npanoramic v2"; -- 17
			"Left\npanoramic v2"; -- 18
			"Cross\nhorizontal"; -- 19
			"Center zigzag\nhorizontal v2"; -- 20
			"Down\nvertical v1"; -- 21
			"Up\nvertical v1"; -- 22
			"Down zigzag\nhorizontal"; -- 23
			"Up zigzag\nhorizontal"; -- 24
			"Up\nfrontal v1"; -- 25
			"Down\nfrontal v1"; -- 26
			"Center zigzag\nvertical v1"; -- 27
			"Down\nvertical v2"; -- 28
			"Up\nvertical v2"; -- 29
			"Up\nfrontal v2"; -- 30
			"Down\nfrontal v2"; -- 31
			"Up\nfrontal v3"; -- 32
			"Down\nfrontal v3"; -- 33
			"Panoramic\ndown v1"; -- 34
			"Panoramic\nup v1"; -- 35
			"Panoramic\ndown v2"; -- 36
			"Panoramic\nup v2"; -- 37
			"Cross\nvertical"; -- 38
			"Center zigzag\nvertical v2"; -- 39
			"Right\nwhirl"; -- 40
			"Left\nwhirl"; -- 41
			"Zoom 3-4\nPixel zoom"; -- 42
			"Zoom 1-2\nPixel zoom"; -- 43
			"Zoom 2-3\nPixel zoom"; -- 44
			"Zoom 1-4\nPixel zoom"; -- 45
			"Zoom 1-3-4\nPixel zoom"; -- 46
			"Zoom 1-2-3\nPixel zoom"; -- 47
			"Zoom 2-3-4\nPixel zoom"; -- 48
			"Zoom 1-2-4\nPixel zoom"; -- 49
			"Zoom 1-2-3-4\nPixel zoom"; -- 50
			"Zoom 3-4 v2\nPixel zoom"; -- 51
			"Zoom 1-2 v2\nPixel zoom"; -- 52
			"Zoom 2-3 v2\nPixel zoom"; -- 53
			"Zoom 1-4 v2\nPixel zoom"; -- 54
			"Zoom 1-3-4 v2\nPixel zoom"; -- 55
			"Zoom 1-2-3 v2\nPixel zoom"; -- 56
			"Zoom 2-3-4 v2\nPixel zoom"; -- 57
			"Zoom 1-2-4 v2\nPixel zoom"; -- 58
			"Zoom 1-2-3-4 v2\nPixel zoom"; -- 59
			"Right\nhorizontal v3"; -- 60
			"Left\nhorizontal v3"; -- 61
			"Down\nvertical v3"; -- 62
			"Up\nvertical v3"; -- 63
		};

		-- Style editor menu. -----------------------------------------------------------
		TEXT_M_STI = {
			"Example of game name.zip"; -- 1
			"Center / Example of game name.zip"; -- 2
			"Right / Example of game name.zip"; -- 3
			"Left / Example of game name.zip"; -- 4
			"Found games"; -- 5
			"Press to exit"; -- 6
			"Press to config"; -- 7
			"Change art"; -- 8
			"Full screen"; -- 9
			"Run game"; -- 10
			"Update list"; -- 11
			"List"; -- 12
			"Art"; -- 13
			"Extra art"; -- 14
			"Cover flow"; -- 15
			"Logo"; -- 16
			"Cross button"; -- 17
			"Triangle button"; -- 18
			"Square button"; -- 19
			"L1 button"; -- 20
			"R1 button"; -- 21
			"R3 button"; -- 22
			"START button"; -- 23
			"SELECT button"; -- 24
			"Transition type"; -- 25
			"Transition speed"; -- 26
			"Restore all items"; -- 27
			"Save style"; -- 28
			"Exit edit menu"; -- 29
			"Lock item"; -- 30
			"Line guide"; -- 31
			"Position"; -- 32
			"Resize"; -- 33
			"Pixels"; -- 34
			"Restore"; -- 35
			"Next item"; -- 36
			"Prev item"; -- 37
			"Help"; -- 38
			"Menu item"; -- 39
			"Save style"; -- 40
			"Menu"; -- 41
			"Pixels"; -- 42
			"Activate elements"; -- 43
			"Shadow"; -- 44
			"Extra options"; -- 45
			"Reset all elements?"; -- 46
			"Save changes?"; -- 47
			"When saving, if a previous configuration\nexists, a backup of it will be created\n(replacing the last backup if it exists)."; -- 48
		};

		-- Main menu. -------------------------------------------------------------------
		TEXT_M_PRI = {
			"-Loading Art-"; -- 1
			"Press to exit"; -- 2
			"Press to config"; -- 3
			"Change art"; -- 4
			"Full screen"; -- 5
			"Run game"; -- 6
			"Update list"; -- 7
			"Game settings"; -- 8
			"Menu"; -- 9
			"Art"; -- 10
			"Zoom"; -- 11
			"Play"; -- 12
			"Loading"; -- 13
			"No games found"; -- 14
			"Error!"; -- 15
			"Games or RetroArch"; -- 16
			"Application or ELF"; -- 17
			"POPS or Binaries"; -- 18
			"Neutrino/OPL or ISO"; -- 19
			"Not found!"; -- 20
			"Found games"; -- 21
			"Found APPS"; -- 22
			"Reset RETROLauncher?"; -- 23
			"Quit RETROLauncher?"; -- 24
			"WARNING!"; -- 25
			"All RetroArch options will reset"; -- 26
			"-Loading Art-"; -- 27
			"Where to create the game executable?"; -- 28
			"Directory \"POPS\""; -- 29
			"Directory \"APPS\""; -- 30
			"Game setup"; -- 31
			"Alternative"; -- 32
			"Variant"; -- 33
			"Explorer"; -- 34
			"Select the device to examine"; -- 35
			"Ember or Bios/CUE"; -- 36
		};

		-- Relocation Menu. -------------------------------------------------------------
		TEXT_M_REL = {
			"WARNING\nThis program was created to run from the first\nport (USB) of PS2.\nPlease, reconnect the USB to the first port and\nrestart the program."; -- 1
			"WARNING\nA device was detected on the second port (USB).\nPlease, disconnect the USB from the second port\nand restart the program."; -- 2
			"The current directory does not match\nyour configuration.\nDo you want to relocate the\nconfigurations to this directory?\nWARNING!\nAll RetroArch Options will reset"; -- 3
			"Relocate"; -- 4
			"Relocating"; -- 5
			"Relocating all settings"; -- 6
		};
	end
end

--- Define las imágenes usadas para cada idioma. ----------------------------------------
function img_lang(name, tipo)
	local actual = System.currentDirectory()
	if doesFileExist(actual .."/System/Defaults/SPA") and doesFileExist(actual .."/System/Medias/Default/COVER_DEFAULTSPA.png") and doesFileExist(actual .."/System/Medias/Default/SCREENSHOT_DEFAULTSPA.png") then
		if tipo == true then
			name = "COVER_DEFAULTSPA"
		else
			name = "SCREENSHOT_DEFAULTSPA"
		end
	elseif doesFileExist(actual .."/System/Defaults/POR") and doesFileExist(actual .."/System/Medias/Default/COVER_DEFAULTPOR.png") and doesFileExist(actual .."/System/Medias/Default/SCREENSHOT_DEFAULTPOR.png") then
		if tipo == true then
			name = "COVER_DEFAULTPOR"
		else
			name = "SCREENSHOT_DEFAULTPOR"
		end
	end
	return name
end
--[[------------------SPAGHETTICODE-------------------]]--