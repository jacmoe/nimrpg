#
#   This file is part of the
#   _   _ _           _____  _____   _____ 
#  | \ | (_)         |  __ \|  __ \ / ____|
#  |  \| |_ _ __ ___ | |__) | |__) | |  __ 
#  | . ` | | '_ ` _ \|  _  /|  ___/| | |_ |
#  | |\  | | | | | | | | \ \| |    | |__| |
#  |_| \_|_|_| |_| |_|_|  \_\_|     \_____|
# 
#   project : https://github.com/jacmoe/nimrpg
#
#   Copyright 2017 Jacob Moen
#
import libtcod

const
  # window size
  SCREEN_WIDTH : int = 80
  SCREEN_HEIGHT : int = 50
  # map size
  MAP_WIDTH : int = 80
  MAP_HEIGHT : int = 45
  # dungeon generation
  ROOM_MAX_SIZE : int = 10
  ROOM_MIN_SIZE : int = 6
  MAX_ROOMS : int = 30
  # FOV
  FOV_ALGO : int = 0
  FOV_LIGHT_WALLS : bool = true
  TORCH_RADIUS : int = 10
  # 20 frames per second limit
  LIMIT_FPS : int = 20
  # colors
  COLOR_LIGHT_WALL : TColor = color_RGB(130, 110, 50)
  COLOR_DARK_WALL : TColor = color_RGB(0, 0, 100)
  COLOR_LIGHT_GROUND : TColor = color_RGB(200, 180, 50)
  COLOR_DARK_GROUND : TColor = color_RGB(50, 50, 150)
  

type
  # Rectangle on the map, used to represent a room
  Rect = ref object of RootObj
    x1, x2, y1, y2 : int

  # A tile of the map and its properties
  Tile = ref object of RootObj
    blocked : bool
    block_sight : bool

  # Generic object represented by a character on the screen
  # A Character can be: player, monster, item, stairs, ...
  Character = ref object of RootObj
    x, y : int
    color : TColor
    symbol : char

var
  main_console: PConsole
  key: TKey
  mouse: TMouse
  player : Character
  map : array[0..MAP_WIDTH, array[0..MAP_HEIGHT, Tile]]
  fov_recompute : bool

#########################################################################
# Rect
#########################################################################

proc newRect(x : int, y : int, w : int, h : int) : Rect =
  result = new Rect
  result.x1 = x
  result.y1 = y
  result.x2 = x + w
  result.y2 = y + h

method center(self: Rect) : tuple[x : int, y : int] =
  # returns the center of this rectangle
  var center_x = (self.x1 + self.x2) div 2
  var center_y = (self.y1 + self.y2) div 2
  result = (center_x, center_y)

method intersect(self : Rect, other : Rect) : bool =
  # returns true if this rectangle intersects with another one
  return (self.x1 <= other.x2 and self.x2 >= other.x1 and
          self.y1 <= other.y2 and self.y2 >= other.y1)

proc create_room(room : Rect) =
  # go through the tiles in the rectangle and make them passable
  for i in room.x1 + 1..room.x2:
    for j in room.y1 + 1..room.y2:
      map[i][j].blocked = false
      map[i][j].block_sight = false

proc create_h_tunnel(x1 : int, x2 : int, y : int) =
  #horizontal tunnel. min() and max() are used in case x1>x2
  for x in min(x1, x2)..(max(x1, x2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false

proc create_v_tunnel(y1 : int, y2 : int, x : int) =
  #vertical tunnel
  for y in min(y1, y2)..(max(y1, y2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false

#########################################################################
# Character
#########################################################################

method move(self : Character, dx : int, dy : int) =
  #move by the given amount, if the destination is not blocked
  if not map[self.x + dx][self.y + dy].blocked:
    self.x += dx
    self.y += dy

method draw(self : Character) =
  # draw the character that represents this object at its position
  console_set_default_foreground(main_console, self.color)
  console_put_char(main_console, self.x, self.y, self.symbol, BKGND_NONE)

method clear(self : Character) =
  console_put_char(main_console, self.x, self.y, ' ', BKGND_NONE)
  
#########################################################################
# Internal procs
#########################################################################

proc render_all() =
  # go through all tiles and set their background color
  for i in 0..<MAP_WIDTH:
    for j in 0..<MAP_HEIGHT:
      if map[i][j].block_sight:
        console_set_char_background(main_console, i, j, COLOR_DARK_WALL, BKGND_SET)
      else:
        console_set_char_background(main_console, i, j, COLOR_DARK_GROUND, BKGND_SET)
        
  player.draw()
  console_blit(main_console, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)

proc make_map =
  # fill map with "blocked" tiles
  for i in 0..<MAP_WIDTH:
    for j in 0..<MAP_HEIGHT:
      map[i][j] = Tile(blocked : true, block_sight: true)
  
  var rooms : seq[Rect] = @[]
  var num_rooms = 0

  for r in 0..<MAX_ROOMS:
    var w = random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    var h = random_get_int(nil, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    var x = random_get_int(nil, 0, MAP_WIDTH - w - 2)
    var y = random_get_int(nil, 0, MAP_HEIGHT - h - 2)

    var new_room = newRect(x, y, w, h)

    var failed = false
    for other_room in rooms:
      if new_room.intersect(other_room):
        failed = true
        break
    if not failed:
      # no intersection, so this room is valid
      # paint it to the map tiles
      create_room(new_room)
      # center coordinates of the new room
      var center_coords = new_room.center()

      if num_rooms == 0:
        # this is the first room, where the player starts at
        player.x = center_coords.x
        player.y = center_coords.y
      else:
        # all rooms after the first
        # reconnect with previous room with a tunnel
        
        var prev_center = rooms[num_rooms - 1].center()

        # toss a coin
        if random_get_int(nil, 0, 1) == 1:
          # first move horizontally, then vertically
          create_h_tunnel(prev_center.x, center_coords.x, prev_center.y)
          create_v_tunnel(prev_center.y, center_coords.y, center_coords.x)
        else:
          # first move vertically, then horizontally
          create_v_tunnel(prev_center.y, center_coords.y, center_coords.x)
          create_h_tunnel(prev_center.x, center_coords.x, prev_center.y)
      
      # finally, append the new room to the list
      rooms.add(new_room)
      num_rooms += 1

proc handle_input() : bool =
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

#########################################################################
# Exported procs
#########################################################################

proc init*(title : string, message: string) : void =
  console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, title, false)
  main_console = console_new(SCREEN_WIDTH, SCREEN_HEIGHT)
  sys_set_fps(LIMIT_FPS)

  player =  Character(x : 0, y : 0, color : RED, symbol : '@')

  make_map()

  console_clear(main_console)
  #discard console_print_rect_ex(main_console, SCREEN_WIDTH_2, 3, SCREEN_WIDTH, 0, BKGND_NONE, CENTER, message)
  
proc main_loop*() : void =
  while not console_is_window_closed():

    render_all()

    console_flush()
    player.clear()
    
    if not handle_input():
      break;
