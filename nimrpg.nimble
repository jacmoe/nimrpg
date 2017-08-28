# Package

version       = "0.1.0"
author        = "Jacob Moen"
description   = "RPG written in Nim, using Libtcod"
license       = "MIT"

bin = @["nimrpg"]

# Dependencies

requires "nim >= 0.17.0", "libtcod_nim >= 0.98", "sysrandom >= 1.1.0"
