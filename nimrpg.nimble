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

# Package

version       = "0.1.0"
author        = "Jacob Moen"
description   = "RPG written in Nim, using Libtcod"
license       = "MIT"

bin = @["nimrpg"]

# Dependencies

requires "nim >= 0.17.0", "libtcod_nim >= 0.98"
