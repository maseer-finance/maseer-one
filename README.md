# MaseerOne

MaseerOne is a compliant tokenization framework built on a modular proxy architecture. Each deployment wraps a purchase token (`gem`) and issues an ERC-20 with compliance-gated minting, redemption, and transfer. All auxiliary contracts (oracle, market gate, treasury, compliance, conduit) sit behind upgradeable proxies and are referenced by the immutable MaseerOne token.

## Architecture

```
                                  MaseerOne (ERC-20 token)
                                  immutable references:
                    ┌──────┬──────┼──────┬──────┐
                    v      v      v      v      v
                   pip    act    adm    cop    flo
                 (price) (gate) (treas) (guard) (conduit)
                    |      |      |      |      |
               ┌────┘  ┌───┘  ┌──┘  ┌───┘  ┌───┘
               v       v      v     v      v
            Proxy   Proxy  Proxy  Proxy  Proxy
              |       |      |      |      |
              v       v      v      v      v
            Impl    Impl   Impl   Impl   Impl
```

Each proxy pair has **two independent authorization layers**:

- **Proxy wards** (`relyProxy`/`denyProxy`) control implementation upgrades via `file(address)`.
- **Implementation wards** (`rely`/`deny`) control configuration of the underlying logic.

Both use `keccak256("maseer.wards")` for implementation wards and `keccak256("maseer.proxy.wards")` for proxy wards, stored in custom computed slots to avoid storage layout collisions across delegatecall.

## Storage Model

All implementation contracts inherit `MaseerImplementation`, which stores state in `keccak256`-computed slots rather than sequential Solidity storage. This eliminates storage collision risk in the proxy pattern. Each implementation reserves `uint256[50] __gap` at slots 0-49 to isolate any Solidity-layout storage (e.g., the `bud` mapping in `MaseerPrice`) from the custom slot namespace.

## Compliance

Every user-facing function on MaseerOne passes through the `cop` (compliance) contract. The `pass(address)` check is enforced on:

| Function | Addresses checked |
|:---------|:------------------|
| `mint` | `msg.sender` |
| `redeem` | `msg.sender` |
| `exit` | `msg.sender` |
| `settle` | `msg.sender` |
| `smelt` | `msg.sender` |
| `issue` | `msg.sender` |
| `transfer` | `msg.sender`, `dst` |
| `approve` | `msg.sender`, `usr` |
| `transferFrom` | `msg.sender`, `src`, `dst` |
| `permit` | `msg.sender`, `owner`, `spender` |

Two compliance adapters are provided:

- **MaseerGuard** wraps sources exposing `getBlackListStatus(address) returns (bool)`.
- **MaseerGuardOZ** wraps sources exposing `isBanned(address) returns (bool)`.

Both invert the result: `pass = !blacklisted`. The `source` address is `immutable`, baked into the implementation bytecode, so it reads correctly through delegatecall.

## Minting

```
user calls mint(amt)
  -> reads oracle price via pip.read()
  -> adjusts for mint fee: ceil(price * (10000 + bpsin) / 10000)
  -> validates amt >= adjusted price (dust threshold)
  -> calculates tokens: (amt * 1e18) / adjusted_price
  -> checks totalSupply + tokens <= capacity
  -> transfers gem from user to MaseerOne
  -> mints tokens to user
```

The mint fee uses ceiling division (`divup`), rounding the cost per token **up** against the minter.

## Redemption

```
user calls redeem(amt)           # amt in tokens, minimum 1 WAD
  -> reads oracle price, adjusts for burn fee: ceil(price * (10000 - bpsout) / 10000)
  -> calculates gem claim: (amt * adjusted_price) / 1e18
  -> increments totalPending by claim amount
  -> assigns redemption ID, stores {amount, redeemer, date}
  -> burns tokens
  -> if cooldown == 0: immediately calls exit(id)
```

The burn fee also uses ceiling division, rounding the return per token **up** (favorable to the redeemer since the price factor `(10000 - bps)` is already a discount).

### Cooldown and Exit

When `cooldown > 0`, redeemers must wait before calling `exit(id)`. On exit:

- If the contract holds enough `gem`, the full claim is transferred.
- If the contract is underfunded, a **partial claim** is made for the available balance. The redemption record persists with the remaining amount, and the redeemer can call `exit` again later.
- `totalPending` is decremented by the amount actually paid out.

### Settlement

`settle()` calculates `gem.balanceOf(this) - totalPending` and transfers the surplus to `flo` (the output conduit). This ensures pending redemption claims are always reserved before excess liquidity is routed out.

For deployments without an external conduit, `flo` can point to the MaseerOne contract itself. In this case, `settle()` performs a self-transfer and the gems remain in the contract.

## Deployed Addresses

### CANA Holdings California Carbon Credits — Mainnet

| Contract Name | Contract Address |
|:--------------|:-----------------|
| MaseerOne | 0x01995a697752266d8e748738aaa3f06464b8350b |
| pip | 0xE7c5c484A61Cc93A638F67906a9900d94b40FDA7 |
| act | 0x3a0DE7A4678CA9341a63Ffe78041385EdA65B128 |
| adm | 0x00d2dc03B8207b2D261Bda5D149Dd7FcF3bdF8d7 |
| cop | 0x456e0074853cd23a3cDeA3A1Bb85575eD9b1a718 |
| flo | 0x12C8091a719125Bf08875635c3Ed738510C56141 |
| Detailed | |
| MaseerPriceImplementation | 0x53d076226cfcc9f2D18Af7e69dcA138145013677 |
| MaseerPriceProxy | 0xE7c5c484A61Cc93A638F67906a9900d94b40FDA7 |
| MaseerGateImplementation | 0x0A4C31CE6Fcca5948f4aBE6a7dF350A88993e249 |
| MaseerGateProxy | 0x3a0DE7A4678CA9341a63Ffe78041385EdA65B128 |
| MaseerTreasuryImplementation | 0x1c571c63D256cDC225bfFDc1d6602f3554F027AE |
| MaseerTreasuryProxy | 0x00d2dc03B8207b2D261Bda5D149Dd7FcF3bdF8d7 |
| MaseerGuardImplementation | 0x2848D47ae98bc9d862caAb91C1F236cef112dCCf |
| MaseerGuardProxy | 0x456e0074853cd23a3cDeA3A1Bb85575eD9b1a718 |
| MaseerConduitImplementation | 0x78FA7018cc9C48Ad732e49A491032eF47018d5fD |
| MaseerConduitProxy | 0x12C8091a719125Bf08875635c3Ed738510C56141 |
| MaseerPrecommit | 0x0f6f65fd822d3713c20e146ff66e4d83b050c31d |

### Wren Staked tGBP (wstGBP) — Mainnet

| Contract Name | Contract Address |
|:--------------|:-----------------|
| MaseerOne | 0x57c3571f10767e49c9d7b60feb6c67804783b7ae |
| pip | 0x6a79dce61a12aa4b75449e0b03746260765d07df |
| act | 0xb59cb4d3075a8ce5013c78e8bd7ada3fd1300f7f |
| adm | 0xa8f5be8457d6ed5c659647fa8d107c3f2086626a |
| cop | 0x794cf5948444b14105587455ebe96caace036d52 |
| flo | 0x57c3571f10767e49c9d7b60feb6c67804783b7ae |
| Detailed | |
| MaseerPriceImplementation | 0x44bfeb1110ba6091034dbaab450ef1e7469ff072 |
| MaseerPriceProxy | 0x6a79dce61a12aa4b75449e0b03746260765d07df |
| MaseerGateImplementation | 0x635dbb7841c27c74b6bdbf1bed548aae2c6c9d77 |
| MaseerGateProxy | 0xb59cb4d3075a8ce5013c78e8bd7ada3fd1300f7f |
| MaseerTreasuryImplementation | 0x192575eeb42644a8014eb545c69f5125e2437a56 |
| MaseerTreasuryProxy | 0xa8f5be8457d6ed5c659647fa8d107c3f2086626a |
| MaseerGuardOZImplementation | 0x3bb8ebb11816e1c20c3db57e2e7e5b421b159255 |
| MaseerGuardOZProxy | 0x794cf5948444b14105587455ebe96caace036d52 |

### CANA Holdings California Carbon Credits — Sepolia

| Contract Name | Contract Address |
|:--------------|:-----------------|
| MaseerOne | 0xbb221e978c5021047a151ee911adee534b06a2f0 |

## Contract Reference

### MaseerOne.sol

The primary ERC-20 token. Holds six immutable references set at construction:

| Field | Role | Interface |
|:------|:-----|:----------|
| `gem` | Purchase token (e.g., USDT, tGBP) | ERC-20 `transfer`, `transferFrom`, `balanceOf` |
| `pip` | Price oracle | `read() returns (uint256)` |
| `act` | Market gate | `mintable()`, `burnable()`, `cooldown()`, `capacity()`, `mintcost(uint256)`, `burncost(uint256)`, `terms()` |
| `adm` | Treasury / issuer registry | `issuer(address) returns (bool)` |
| `cop` | Compliance guard | `pass(address) returns (bool)` |
| `flo` | Output conduit | Receives surplus gems via `settle()` |

Privileged functions:

- `issue(uint256 amt)` — mint tokens without gem transfer (issuer-only via `adm`).
- `smelt(address usr, uint256 amt)` — burn tokens from a specified address (issuer-only).
- `smelt(uint256 amt)` — burn own tokens (any compliant user).

Transfer safety: `transfer` and `transferFrom` reject sends to `address(this)` and `address(0)`.

EIP-2612 `permit` is supported. Domain version is `"1"`. The domain separator is recomputed on chain fork.

### MaseerToken.sol

Abstract ERC-20 base with 18 decimals, EIP-2612 permit, and infinite-approval via `approve(address)`. Uses `WAD = 1e18` as the internal scaling constant. All balance arithmetic uses `unchecked` blocks where overflow is impossible.

### MaseerPrice.sol

Oracle price feed. Stores `price`, `name`, and `decimals` in custom slots.

| Function | Auth | Description |
|:---------|:-----|:------------|
| `read()` | none | Returns current price |
| `poke(uint256)` | `buds` | Update price (operator role) |
| `pause()` | `auth` | Set price to zero (emergency stop) |
| `kiss(address)` | `auth` | Grant `poke` rights |
| `diss(address)` | `auth` | Revoke `poke` rights |
| `file(bytes32, bytes32)` | `auth` | Set `price`, `name`, or `decimals` |

`decimals` is validated `<= 18` on write.

### MaseerGate.sol

Market timing, fees, and capacity. Controls when minting/burning is open, the basis-point fee for each direction, cooldown period, supply cap, and terms string.

| Function | Auth | Description |
|:---------|:-----|:------------|
| `setOpenMint(uint256)` | `auth` | Set mint window start (max +365 days) |
| `setHaltMint(uint256)` | `auth` | Set mint window end (max +365 days) |
| `setOpenBurn(uint256)` | `auth` | Set burn window start (max +365 days) |
| `setHaltBurn(uint256)` | `auth` | Set burn window end (max +365 days) |
| `setBpsin(uint256)` | `auth` | Set mint fee in basis points (0-10000) |
| `setBpsout(uint256)` | `auth` | Set burn fee in basis points (0-10000) |
| `setCooldown(uint256)` | `auth` | Set redemption cooldown (max 365 days) |
| `setCapacity(uint256)` | `auth` | Set supply cap |
| `setTerms(string)` | `auth` | Set terms (e.g., IPFS CID) |
| `pauseMarket()` | `auth` | Zero all mint/burn windows |
| `file(bytes32, uint256)` | `auth` | Unchecked batch setter (bypasses guards) |

`mintable()` returns `true` when `block.timestamp` is within `[openMint, haltMint]`. Same pattern for `burnable()`.

Fee math: `mintcost = ceil(price * (10000 + bpsin) / 10000)`, `burncost = ceil(price * (10000 - bpsout) / 10000)`.

### MaseerTreasury.sol

Issuer registry. Wards can grant or revoke the issuer role, which authorizes `issue()` and `smelt(address, uint256)` on MaseerOne.

| Function | Auth | Description |
|:---------|:-----|:------------|
| `bestow(address)` | `auth` | Grant issuer role |
| `depose(address)` | `auth` | Revoke issuer role |
| `issuer(address)` | none | Check if address is an issuer |

### MaseerGuard.sol / MaseerGuardOZ.sol

Compliance adapters. Both expose `pass(address) returns (bool)` and invert the result of an external blacklist source. The `source` is an `immutable` set at construction.

- **MaseerGuard**: calls `getBlackListStatus(address)` on the source.
- **MaseerGuardOZ**: calls `isBanned(address)` on the source.

### MaseerConduit.sol

Dual-gated token router for moving gems to off-chain servicers. Requires both operator authorization (`hope`/`nope`) on the sender and recipient whitelisting (`kiss`/`diss`) on the destination.

| Function | Auth | Description |
|:---------|:-----|:------------|
| `hope(address)` | `auth` | Grant operator rights |
| `nope(address)` | `auth` | Revoke operator rights |
| `kiss(address)` | `auth` | Whitelist recipient |
| `diss(address)` | `auth` | Remove recipient |
| `move(token, to)` | `operator` + `buds(to)` | Transfer full token balance |
| `move(token, to, amt)` | `operator` + `buds(to)` | Transfer specific amount |

### MaseerPrecommit.sol

Batch precommitment contract. Users pre-approve gem spend and register a `pact`. An executor later calls `exec` to process the mint on their behalf.

| Function | Auth | Description |
|:---------|:-----|:------------|
| `pact(uint256 amt)` | `pass` | Register intent to mint (min 1000 gem units) |
| `exec(uint256 idx)` | `pass` | Execute a registered pact |
| `exit()` | `pass` | Sweep remaining gems to conduit |

The constructor pre-approves `type(uint256).max` gems to MaseerOne.

### MaseerProxy.sol

Transparent proxy with assembly `delegatecall` fallback. Implementation address is stored at `keccak256("maseer.proxy.implementation")` and can be changed via `file(address)` by proxy wards. The constructor bootstraps both proxy-level and implementation-level wards for the deployer.

### MaseerImplementation.sol

Abstract base providing the ward auth system (`rely`/`deny`/`wards`) and generic slot-based storage helpers (`_setVal`/`_getVal` for `bytes32`, `uint256`, `address`, `bool`, `string`). All derived contracts use these helpers to read and write named storage slots.

## Setup and Deployment

### Prerequisites

Foundry (forge and cast)

Solidity compiler version ^0.8.28

Copy `.env.sample` to `.env` and replace variables.

### Compilation

```
make build
```

### Deployment

```
make dry-run           # mainnet dry run
make deploy            # mainnet broadcast + verify
make wstgbp-dry-run    # wstGBP dry run
make wstgbp-deploy     # wstGBP broadcast + verify
```

### Testing

```
make test
```

Tests requiring on-chain state (compliance checks, integration flows) need a fork URL configured in `.env`.

## License

This project is licensed under the Business Source License 1.1 (BUSL-1.1).
