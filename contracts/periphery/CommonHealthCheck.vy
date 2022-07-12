# @version 0.3.4

from vyper.interfaces import ERC20

# INTERFACES #
interface IStrategy:
    def vault() -> address: view

# EVENTS #
event CommitHealthCheckManager:
    health_check_manager: address

event ApplyHealthCheckManager:
    health_check_manager: address

event DisableHealthCheckStatusUpdated:
    strategy: address
    is_disabled: bool

# STRUCTS #
struct Limits:
    profit_limit_ratio: uint256
    loss_limit_ratio: uint256
    active: bool


# CONSTANTS #
MAX_BPS: constant(uint256) = 10_000


# STORAGE #
health_check_manager: public(address)
future_health_check_manager: public(address)
strategy_limits: public(HashMap[address, Limits])

profit_limit_ratio: public(uint256)
loss_limit_ratio: public(uint256)
disabled_health_checks: public(HashMap[address, bool])


@external
def __init__():
    self.health_check_manager = msg.sender
    self.profit_limit_ratio = 100
    self.loss_limit_ratio = 1


@external
def set_default_profit_limit_ratio(profit_limit_ratio: uint256):
    assert msg.sender == self.health_check_manager, "not health check manager"
    assert profit_limit_ratio < MAX_BPS, "profit limit ratio out of bounds"
    self.profit_limit_ratio = profit_limit_ratio


@external
def set_default_loss_limit_ratio(loss_limit_ratio: uint256):
    assert msg.sender == self.health_check_manager, "not health check manager"
    assert loss_limit_ratio < MAX_BPS, "loss limit ratio out of bounds"
    self.loss_limit_ratio = loss_limit_ratio


@external
def set_disabled_health_check_state(strategy: address, is_disabled: bool):
    # health checks are enabled by default
    assert msg.sender == self.health_check_manager, "not health check manager"
    log DisableHealthCheckStatusUpdated(strategy, is_disabled)
    self.disabled_health_checks[strategy] = is_disabled


@external
def set_strategy_limits(strategy: address, profit_limit_ratio: uint256, loss_limit_ratio: uint256):
    assert msg.sender == self.health_check_manager, "not health check manager"
    assert profit_limit_ratio < MAX_BPS, "profit limit ratio out of bounds"
    assert loss_limit_ratio < MAX_BPS, "loss limit ratio out of bounds"
    self.strategy_limits[strategy] = Limits({
        profit_limit_ratio: profit_limit_ratio,
        loss_limit_ratio: loss_limit_ratio,
        active: True
    })


@external
def commit_health_check_manager(future_health_check_manager: address):
    assert msg.sender == self.health_check_manager, "not health check manager"
    self.future_health_check_manager = future_health_check_manager
    log CommitHealthCheckManager(future_health_check_manager)


@external
def apply_health_check_manager():
    assert msg.sender == self.health_check_manager, "not health check manager"
    assert self.future_health_check_manager != ZERO_ADDRESS, "future health check manager != zero address"
    future_health_check_manager: address = self.future_health_check_manager
    self.health_check_manager = future_health_check_manager
    log ApplyHealthCheckManager(future_health_check_manager)


@view
@external
def check(strategy: address, gain: uint256, loss: uint256, currentDebt: uint256) -> bool:
    limits: Limits = self.strategy_limits[strategy]
    # use default values if limits have not been set
    profit_limit_ratio: uint256 = self.profit_limit_ratio
    loss_limit_ratio: uint256 = self.loss_limit_ratio
    if limits.active:
        profit_limit_ratio = limits.profit_limit_ratio
        loss_limit_ratio = limits.loss_limit_ratio

    if (gain > ((currentDebt * profit_limit_ratio) / MAX_BPS)):
        return False
    if (loss > ((currentDebt * loss_limit_ratio) / MAX_BPS)):
        return False
    return True
