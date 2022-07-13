import ape


def test_sweep__with_asset_token_and_no_dust__reverts(gov, asset, vault):
    with ape.reverts("no dust"):
        vault.sweep(asset.address, sender=gov)


def test_sweep__with_asset_token__withdraws_airdrop_only(
    gov,
    asset,
    vault,
    strategy,
    mint_and_deposit_into_vault,
    airdrop_asset,
    add_debt_to_strategy,
):
    vault_balance = 10**22
    debt = vault_balance // 10
    asset_airdrop = vault_balance // 10
    mint_and_deposit_into_vault(vault, gov, vault_balance)
    assert vault.totalAssets() == vault_balance

    # airdrop extra assets to vault (e.g. user accidentally sends to vault)
    airdrop_asset(gov, asset, vault, asset_airdrop)
    assert asset.balanceOf(vault) == (vault_balance + asset_airdrop)
    # vault balance doesn't change from airdrops
    assert vault.totalAssets() == vault_balance

    # add debt to strategy to check debt is accounted for
    add_debt_to_strategy(gov, strategy, vault, debt)

    tx = vault.sweep(asset.address, sender=gov)
    event = list(tx.decode_logs(vault.Sweep))

    assert len(event) == 1
    assert event[0].token == asset.address
    assert event[0].amount == asset_airdrop

    assert asset.balanceOf(gov) == asset_airdrop
    assert asset.balanceOf(vault) == (vault_balance - debt)
    assert vault.totalAssets() == vault_balance


def test_sweep__with_token__withdraws_token(
    gov,
    mock_token,
    vault,
    strategy,
    mint_and_deposit_into_vault,
    airdrop_asset,
    add_debt_to_strategy,
):
    # create vault with strategy and debt allocated
    vault_balance = 10**22
    debt = vault_balance // 10
    mock_token_airdop = vault_balance // 10
    mint_and_deposit_into_vault(vault, gov, vault_balance)
    add_debt_to_strategy(gov, strategy, vault, debt)

    # airdrop random token to vault
    airdrop_asset(gov, mock_token, vault, mock_token_airdop)

    tx = vault.sweep(mock_token.address, sender=gov)
    event = list(tx.decode_logs(vault.Sweep))

    assert len(event) == 1
    assert event[0].token == mock_token.address
    assert event[0].amount == mock_token_airdop

    assert mock_token.balanceOf(gov) == mock_token_airdop
    assert mock_token.balanceOf(vault) == 0
    assert vault.totalAssets() == vault_balance
