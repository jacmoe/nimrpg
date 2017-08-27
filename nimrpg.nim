import libtcod, os, parseutils, math

const
  # sample screen size
  SAMPLE_SCREEN_WIDTH = 46
  SAMPLE_SCREEN_HEIGHT = 20


var
  sample_console: PConsole
  renderer = RENDERER_SDL


console_init_root(80, 50, "libtcod sample", false, renderer)

console_set_default_foreground(nil, GREY)

console_clear(sample_console)

console_put_char(sample_console, 0, 0, 'a', BKGND_NONE)

console_flush()

while not console_is_window_closed():
  console_put_char(sample_console, 0, 0, 'b', BKGND_NONE)
  console_flush()



