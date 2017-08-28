import libtcod, os, parseutils, math

const
  # sample screen size
  SCREEN_WIDTH = 80
  SCREEN_HEIGHT = 50
  LIMIT_FPS = 20


var
  sample_console: PConsole
  renderer = RENDERER_SDL
  key: TKey
  mouse: TMouse


console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, "libtcod sample", false, renderer)

sys_set_fps(LIMIT_FPS)

console_set_default_foreground(nil, GREY)

console_clear(sample_console)

while not console_is_window_closed():
  console_put_char(sample_console, 1, 1, '@', BKGND_NONE)
  console_flush()
  discard sys_check_for_event(EVENT_KEY_PRESS or EVENT_MOUSE, addr(key), addr(mouse))
  if key.vk == K_ESCAPE: break
