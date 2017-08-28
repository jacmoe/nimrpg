import libtcod

const
  # sample screen size
  SCREEN_WIDTH = 80
  SCREEN_WIDTH_2 = 40
  SCREEN_HEIGHT = 50
  LIMIT_FPS = 20


var
  main_console: PConsole
  renderer = RENDERER_SDL
  key: TKey
  mouse: TMouse


proc init() =
  console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, "NimRPG", false, renderer)
  sys_set_fps(LIMIT_FPS)
  console_set_default_foreground(nil, GREY)
  console_clear(main_console)


proc handle_input() : bool =
  discard sys_check_for_event(EVENT_KEY_PRESS or EVENT_MOUSE, addr(key), addr(mouse))
  case key.vk
  of K_ESCAPE:
    result = false
  else:
    result = true
  
proc main_loop() =
  while not console_is_window_closed():
    console_put_char(main_console, 1, 1, '@', BKGND_NONE)
    console_flush()

    if not handle_input():
      break;
  


init()
  
discard console_print_rect_ex(main_console, SCREEN_WIDTH_2, 3, SCREEN_WIDTH, 0, BKGND_NONE, CENTER, "Testing...\n")

main_loop()
