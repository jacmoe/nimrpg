#[
   This file is part of the
   _   _ _           _____  _____   _____ 
  | \ | (_)         |  __ \|  __ \ / ____|
  |  \| |_ _ __ ___ | |__) | |__) | |  __ 
  | . ` | | '_ ` _ \|  _  /|  ___/| | |_ |
  | |\  | | | | | | | | \ \| |    | |__| |
  |_| \_|_|_| |_| |_|_|  \_\_|     \_____|
 
   project : https://github.com/jacmoe/nimrpg

   Copyright 2017 Jacob Moen
]#
import libtcod, math

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
  MAX_ROOM_MONSTERS : int = 3
  # FOV
  FOV_ALGO : TFOVAlgorithm = FOV_BASIC
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
    explored : bool

  Fighter = ref object of RootObj
    max_hp, hp, defense, power : int
    owner : ref RootObj

  AI = ref object of RootObj
    owner : ref RootObj

  # Generic object represented by a character on the screen
  # A Thing can be: player, monster, item, stairs, ...
  Thing = ref object of RootObj
    x, y : int
    color : TColor
    symbol : char
    name : string
    blocks : bool
    fighter : Fighter
    ai : AI

  BasicMonster = ref object of AI

  PlayState = enum
    PLAYING

  PlayerAction = enum
    NONE,
    EXIT,
    DIDNT_TAKE_TURN

var
  main_console: PConsole
  key: TKey
  mouse: TMouse
  player : Thing
  map : array[0..MAP_WIDTH, array[0..MAP_HEIGHT, Tile]]
  fov_map : PMap
  fov_recompute : bool
  rooms : seq[Rect] = @[]
  things : seq[Thing] = @[]
  random : PRandom
  game_state : PlayState
  player_action : PlayerAction

#########################################################################
# Rect
#########################################################################

proc newRect(x : int, y : int, w : int, h : int) : Rect =
  Rect(x1 : x, y1 : y, x2 : x + w, y2 : y + h)

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
  for x in room.x1 + 1..room.x2:
    for y in room.y1 + 1..room.y2:
      map[x][y].blocked = false
      map[x][y].block_sight = false
      map[x][y].explored = false

proc create_h_tunnel(x1 : int, x2 : int, y : int) =
  #horizontal tunnel. min() and max() are used in case x1>x2
  for x in min(x1, x2)..(max(x1, x2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false
    map[x][y].explored = false

proc create_v_tunnel(y1 : int, y2 : int, x : int) =
  #vertical tunnel
  for y in min(y1, y2)..(max(y1, y2) + 1):
    map[x][y].blocked = false
    map[x][y].block_sight = false
    map[x][y].explored = false

#########################################################################
# Thing
#########################################################################

proc newThing(x : int, y : int, symbol : char, name : string, color : TColor, blocks : bool, fighter : Fighter = nil, ai : AI = nil) : Thing =
  result = new Thing
  result.x = x
  result.y = y
  result.symbol = symbol
  result.name = name
  result.color = color
  result.blocks = blocks
  result.fighter = fighter
  if fighter != nil:
    fighter.owner = result
    result.ai = ai
  if ai != nil:
    ai.owner = result

method move(self : Thing, dx : int, dy : int) =
  #move by the given amount, if the destination is not blocked
  if not map[self.x + dx][self.y + dy].blocked:
    self.x += dx
    self.y += dy

method move_towards(self: Thing, target_x : int, target_y : int) =
  # vector from this object to the target, and distance
  var dx = float(target_x - self.x)
  var dy = float(target_y - self.y)
  var distance = sqrt(dx^2 + dy^2)


method draw(self : Thing) =
  # draw the character that represents this object at its position
  if map_is_in_fov(fov_map, self.x, self.y):
    # only draw if it's visible to the player
    console_set_default_foreground(main_console, self.color)
    console_put_char(main_console, self.x, self.y, self.symbol, BKGND_NONE)

method clear(self : Thing) =
  console_put_char(main_console, self.x, self.y, ' ', BKGND_NONE)
  
#########################################################################
# AI
#########################################################################
method take_turn(self : BasicMonster) =
  var monster = Thing(self.owner)
  if map_is_in_fov(fov_map, monster.x, monster.y):
    if monster.distance_to(player) >= 2:
      monster.move_towards(player.x, player.y)
    elif player.fighter.hp > 0:
      echo("The attack of the ", monster.name, " bounces off your shiny metal armor!")


#########################################################################
# Internal procs
#########################################################################

proc render_all() =
  if fov_recompute:
    # recompute FOV if needed
    fov_recompute = false
    map_compute_fov(fov_map, player.x, player.y, TORCH_RADIUS, FOV_LIGHT_WALLS, FOV_ALGO)
    # go through all tiles and set their background color
    for i in 0..MAP_WIDTH:
      for j in 0..MAP_HEIGHT:
        var visible = map_is_in_fov(fov_map, i, j)
        var wall = map[i][j].block_sight
        if not visible:
          if map[i][j].explored:
            if wall:
              console_set_char_background(main_console, i, j, COLOR_DARK_WALL, BKGND_SET)
            else:
              console_set_char_background(main_console, i, j, COLOR_DARK_GROUND, BKGND_SET)
        else:
          if wall:
            console_set_char_background(main_console, i, j, COLOR_LIGHT_WALL, BKGND_SET)
          else:
            console_set_char_background(main_console, i, j, COLOR_LIGHT_GROUND, BKGND_SET)
          map[i][j].explored = true
        
  for thing in things:
    thing.draw()

  console_blit(main_console, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, nil, 0, 0, 1.0, 1.0)

proc is_blocked(x : int, y : int) : bool =
  result = false
  # first test the map tile
  if map[x][y].blocked:
    result = true
  # now check for any blocking things
  for thing in things:
    if thing.blocks and thing.x == x and thing.y == y:
      result = true

proc place_things(room : Rect) =
  var num_monsters = random_get_int(random, 0, MAX_ROOM_MONSTERS)

  for i in 0..num_monsters:
    # choose random spot for this monster
    var x, y = 0
    var still_searching = true

    # get random monster position and make sure it is not the same as the player position:
    while still_searching:
      x = random_get_int(random, room.x1, room.x2)
      y = random_get_int(random, room.y1, room.y2)
      # stop the search if random position is not blocked
      if not is_blocked(x, y):
        break

    var monster : Thing

    if random_get_int(random, 0, 100) < 80:
      # 80 % chance of getting an orc
      var fighter_component = Fighter(hp : 10, defense : 0, power : 3)
      var ai_component = BasicMonster()
      monster = Thing(x : x, y : y, symbol : 'o', color : DESATURATED_GREEN, name : "Orc", blocks : true, fighter : fighter_component, ai : ai_component)
    else:
      # create a troll
      var fighter_component = Fighter(hp : 16, defense : 1, power : 4)
      var ai_component = BasicMonster()
      monster = Thing(x : x, y : y, symbol : 'T', color : DARKER_GREEN, name : "Troll", blocks : true, fighter : fighter_component, ai : ai_component)

    things.add(monster)

proc make_map =
  # fill map with "blocked" tiles
  for i in 0..MAP_WIDTH:
    for j in 0..MAP_HEIGHT:
      map[i][j] = Tile(blocked : true, block_sight: true)
  
  var num_rooms : int = 0

  for r in 0..<MAX_ROOMS:
    var w = random_get_int(random, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    var h = random_get_int(random, ROOM_MIN_SIZE, ROOM_MAX_SIZE)
    var x = random_get_int(random, 0, MAP_WIDTH - w - 1)
    var y = random_get_int(random, 0, MAP_HEIGHT - h - 1)

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
      
      # add some things to the room
      place_things(new_room)
      # finally, append the new room to the list
      rooms.add(new_room)
      num_rooms += 1

proc player_move_or_attack(dx : int, dy : int) =
  # the coordinates the player is moving to/attacking
  var x = player.x + dx
  var y = player.y + dy

  # try to find an attackable object there
  var target : Thing = nil
  for thing in things:
    if thing.x == x and thing.y == y:
      target = thing
      break

  # attack if target is found, move otherwise
  if target != nil:
    echo("The ", target.name, " laughs at your puny effort to attack it!")
  else:
    player.move(dx, dy)
    fov_recompute = true

proc handle_input() : PlayerAction =
  discard sys_wait_for_event(EVENT_KEY_PRESS or EVENT_MOUSE, addr(key), addr(mouse), true)
  result = NONE
  case key.vk
  of K_ESCAPE:
    result = EXIT
  else:
    result = NONE

  if game_state == PLAYING and result == NONE:
    case key.vk
    of K_UP:
      player_move_or_attack(0, -1)
    of K_DOWN:
      player_move_or_attack(0, 1)
    of K_LEFT:
      player_move_or_attack(-1, 0)
    of K_RIGHT:
      player_move_or_attack(1, 0)
    else:
      result = DIDNT_TAKE_TURN

#########################################################################
# Exported procs
#########################################################################

proc init*(title : string) : void =
  console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, title, false)
  main_console = console_new(SCREEN_WIDTH, SCREEN_HEIGHT)
  sys_set_fps(LIMIT_FPS)

  random = random_new()

  var fighter_component = Fighter(hp : 30, defense : 2, power : 5)
  var ai_component = BasicMonster()
  player =  Thing(x : 0, y : 0, color : RED, symbol : '@', name : "Hero", blocks : true, fighter : fighter_component, ai : ai_component)
  
  things.add(player)

  make_map()

  # create FOV map
  fov_map = map_new(MAP_WIDTH, MAP_HEIGHT)
  for y in 0..MAP_HEIGHT:
    for x in 0..MAP_WIDTH:
      map_set_properties(fov_map, x, y, not map[x][y].block_sight, not map[x][y].blocked)

  fov_recompute = true
  player_action = NONE
  game_state = PLAYING

  console_clear(main_console)
  #discard console_print_rect_ex(main_console, SCREEN_WIDTH_2, 3, SCREEN_WIDTH, 0, BKGND_NONE, CENTER, message)
  
proc main_loop*() : void =
  while not console_is_window_closed():

    render_all()

    console_flush()
    
    for thing in things:
      thing.clear()
    
    player_action = handle_input()

    if player_action == EXIT:
      break;
  
    # let monsters take their turn
    if game_state == PLAYING and player_action == DIDNT_TAKE_TURN:
      for thing in things:
        if thing != player:
          echo("The ", thing.name, " growls!")

  random_delete(random)
