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
import sysrandom

type
    Dice* = enum
        D3 = 3, D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D16 = 16, D20 = 20

proc roll_dice*(dice : Dice = Dice.D20, times : int = 1) : uint32 =
    for i in 0..<times:
        result += (getRandom() mod ord(dice)) + 1
    closeRandom()
