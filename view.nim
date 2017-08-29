import libtcod

const
    # sample screen size
    SCREEN_WIDTH : int = 80
    SCREEN_HEIGHT : int = 50
    LIMIT_FPS : int = 20
  
  
var
  main_console: PConsole
  renderer = RENDERER_SDL
  key: TKey
  mouse: TMouse
  player_x = 0
  player_y = 0

type
  Character = ref object of RootObj
    x, y : int
    color : TColor
    symbol : char

var
  player : Character

method move(what : Character, dx : int, dy : int) =
  what.x += dx
  what.y += dy

method draw(what : Character) =
  console_set_default_foreground(main_console, what.color)
  console_put_char(main_console, what.x, what.y, what.symbol, BKGND_NONE)

method clear(what : Character) =
  console_put_char(main_console, what.x, what.y, ' ', BKGND_NONE)
  

proc init*(title : string, message: string) : void =
  console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, title, false)
  main_console = console_new(SCREEN_WIDTH, SCREEN_HEIGHT)
  sys_set_fps(LIMIT_FPS)

  player =  Character(x : 0, y : 0, color : RED, symbol : '@')

  console_clear(main_console)
  #discard console_print_rect_ex(main_console, SCREEN_WIDTH_2, 3, SCREEN_WIDTH, 0, BKGND_NONE, CENTER, message)
  
  
proc handle_input*() : bool =
  discard sys_check_for_event(EVENT_KEY_PRESS or EVENT_MOUSE, addr(key), addr(mouse))
  result = true
  case key.vk
  of K_ESCAPE:
    result = false
  of K_UP:
    player.move(0, -1)
  of K_DOWN:
    player.move(0, 1)
  of K_LEFT:
    player.move(-1, 0)
  of K_RIGHT:
    player.move(1, 0)
  else:
    result = true
    
proc main_loop*() : void =
  while not console_is_window_closed():
    player.draw()
    console_blit(main_console, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)
    console_flush()
    player.clear()
    
    if not handle_input():
      break;
