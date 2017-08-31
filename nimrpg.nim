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
import view, d20

init("NimRPG", "Testing...\n")
  
main_loop()
 
echo roll_dice(Dice.D8)

echo roll_dice(Dice.D20, 8)
