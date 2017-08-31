import libtcod

const
  # window size
  SCREEN_WIDTH : int = 80
  SCREEN_HEIGHT : int = 50
  # map size
  MAP_WIDTH = 80
  MAP_HEIGHT = 45
  # 20 frames per second limit
  LIMIT_FPS : int = 20
  
  
var
  main_console: PConsole
  renderer = RENDERER_SDL
  key: TKey
  mouse: TMouse
  player_x = 0
  player_y = 0

type
  Rect = ref object of RootObj
    x1, x2, y1, y2 : int

  Tile = ref object of RootObj
    blocked : bool
    block_sight : bool

  Character = ref object of RootObj
    x, y : int
    color : TColor
    symbol : char

var
  player : Character
  map : array[0..MAP_WIDTH, array[0..MAP_HEIGHT, Tile]]
  color_dark_wall : TColor = color_RGB(0, 0, 100)
  color_dark_ground : TColor = color_RGB(50, 50, 150)

proc newRect(x : int, y : int, w : int, h : int) : Rect =
  result = new Rect
  result.x1 = x
  result.y1 = y
  result.x2 = x + w
  result.y2 = y + h

proc create_room(room : Rect) =
  # go through the tiles in the rectangle and make them passable
  for i in room.x1 + 1..room.x2:
    for j in room.y1 + 1..room.y2:
      map[i][j].blocked = false
      map[i][j].block_sight = false

proc create_h_tunnel(x1 : int, x2 : int, y : int) =
  for x in min(x1, x2)..(max(x1, x2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false

proc create_v_tunnel(y1 : int, y2 : int, x : int) =
  for y in min(y1, y2)..(max(y1, y2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false

proc make_map =
  # fill map with "blocked" tiles
  for i in 0..<MAP_WIDTH:
    for j in 0..<MAP_HEIGHT:
      map[i][j] = Tile(blocked : true, block_sight: true)
  
  # create two rooms
  var room1  = newRect(20, 15, 10, 15)
  var room2 = newRect(50, 15, 10, 15)
  create_room(room1)
  create_room(room2)
  create_h_tunnel(25, 55, 23)

method move(self : Character, dx : int, dy : int) =
  if not map[self.x + dx][self.y + dy].blocked:
    self.x += dx
    self.y += dy

method draw(self : Character) =
  console_set_default_foreground(main_console, self.color)
  console_put_char(main_console, self.x, self.y, self.symbol, BKGND_NONE)

method clear(self : Character) =
  console_put_char(main_console, self.x, self.y, ' ', BKGND_NONE)
  

proc init*(title : string, message: string) : void =
  console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, title, false)
  main_console = console_new(SCREEN_WIDTH, SCREEN_HEIGHT)
  sys_set_fps(LIMIT_FPS)

  player =  Character(x : 0, y : 0, color : RED, symbol : '@')

  make_map()

  player.x = 25
  player.y = 23

  console_clear(main_console)
  #discard console_print_rect_ex(main_console, SCREEN_WIDTH_2, 3, SCREEN_WIDTH, 0, BKGND_NONE, CENTER, message)
  
  
proc handle_input*() : bool =
  discard sys_wait_for_event(EVENT_KEY_PRESS or EVENT_MOUSE, addr(key), addr(mouse), true)
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

proc render_all() =
  # go through all tiles and set their background color
  for i in 0..<MAP_WIDTH:
    for j in 0..<MAP_HEIGHT:
      if map[i][j].block_sight:
        console_set_char_background(main_console, i, j, color_dark_wall, BKGND_SET)
      else:
        console_set_char_background(main_console, i, j, color_dark_ground, BKGND_SET)
        
  player.draw()
  console_blit(main_console, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)


proc main_loop*() : void =
  while not console_is_window_closed():

    render_all()

    console_flush()
    player.clear()
    
    if not handle_input():
      break;
