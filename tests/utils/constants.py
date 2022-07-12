from enum import IntFlag

DAY = 86400
WEEK = 7 * DAY
YEAR = 31_556_952  # same value used in vault
MAX_INT = 2**256 - 1
MAX_BPS = 10_000
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


class ROLES(IntFlag):
    STRATEGY_MANAGER = 1
    DEBT_MANAGER = 2
    EMERGENCY_MANAGER = 4
