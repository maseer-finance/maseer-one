# MaseerOne Token and Dependencies

## Overview

| Contract Name | Contract Address |
|:--------------|:-----------------|
| MaseerOne | 0x01995a697752266d8e748738aaa3f06464b8350b |
| pip | 0xE7c5c484A61Cc93A638F67906a9900d94b40FDA7 |
| act | 0x3a0DE7A4678CA9341a63Ffe78041385EdA65B128 |
| adm | 0x00d2dc03B8207b2D261Bda5D149Dd7FcF3bdF8d7 |
| cop | 0x456e0074853cd23a3cDeA3A1Bb85575eD9b1a718 |
| flo | 0x12C8091a719125Bf08875635c3Ed738510C56141 |
| Detailed | |
| MaseerPriceImplementation | 0xFD984da1fDd27103701fff1aA27CCBe361EC5344 |
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


## Contract Descriptions

### MaseerOne.sol

The primary token contract representing the MaseerOne token. It manages core ERC-20 functionalities, including minting, burning, transfers, and balance tracking.

### MaseerGate.sol

A control layer that facilitates the enabling and halting of minting and burning operations through defined storage slots, ensuring secure and controlled token supply management.

#### Required Interface

    * `function mintable() external view returns (bool);`
    * `function burnable() external view returns (bool);`
    * `function cooldown() external view returns (uint256);`
    * `function capacity() external view returns (uint256);`
    * `function mintcost(uint256) external view returns (uint256);`
    * `function burncost(uint256) external view returns (uint256);`

### MaseerToken.sol

Implements token-specific logic and interactions, ensuring compliance with ERC-20 standards and integrating with other system components.

### MaseerConduit.sol

Handles the flow of tokens to the off-chain servicer.

### MaseerImplementation.sol

The base proxy implementation contract providing shared logic and functionality for all Maseer implementations supporting the upgradeable architecture.

### MaseerPrice.sol

Manages token price feeds and oracles, ensuring accurate and real-time pricing information for the MaseerOne token.

#### Required interface

    * `function read() external view returns (uint256);`

### MaseerProxy.sol

Implements the proxy pattern to enable contract upgrades without disrupting the existing state or functionality, maintaining backward compatibility.

### MaseerGuard.sol

Provides security mechanisms such as access control, pausing, and emergency stops, protecting the token ecosystem from potential threats.

#### Required Interface

    * `function pass(address usr) external view returns (bool);`

## Setup and Deployment

### Prerequisites

Foundry (forge and cast)

Solidity compiler version ^0.8.28

Copy `.env.sample` to `.env` and replace variables.

### Installation

```
make install
```

### Compilation

```
make build
```

### Deployment

```
make clean && make
forge script scripts/MaseerOne.s.sol --broadcast --verify --rpc-url <ETH_RPC_URL>
```

### Testing

Run the test suite to ensure all contracts function correctly:

```
make test
```


## License

This project is licensed under the Business Source License 1.1 (BUSL-1.1).
