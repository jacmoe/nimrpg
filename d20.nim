import sysrandom

type
    Dice* = enum
        D3 = 3, D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D16 = 16, D20 = 20

proc roll_dice*(dice : Dice = Dice.D20, times : int = 1) : uint32 =
    for i in 0..<times:
        result += (getRandom() mod ord(dice)) + 1
    closeRandom()
