# MaseerOne Token and Dependencies

## Overview

| Contract Name | Contract Address |
|:--------------|:-----------------|
| MaseerOne | 0x1a88e0a996c0c024e8b14f88b28a1e20863307ab |
| pip | 0x7267dc183d5259ac33fd80322e62fc052efdad66 |
| act | 0xd5b61ee60e89c4c068bc8f9628d0a36d8ed1e08c |
| adm | 0xb9a83116abd6bf3476fc5819deeb91f63cafdca2 |
| cop | 0xb946b4c20522d23cccae926aceef6fc302f56609 |
| flo | 0x9e0924075bb6696e70f638336ee36e3bd9a130c7 |
|:--------------|:-----------------|
| Detailed | |
|:--------------|:-----------------|
| MaseerPriceImplementation | 0x8d259b827728f126920b60745f2c3fd4e220782d |
| MaseerPriceProxy | 0x7267dc183d5259ac33fd80322e62fc052efdad66 |
| MaseerGateImplementation | 0xa5cb218db3c128adfb326b262232ce58396ee63a |
| MaseerGateProxy | 0xd5b61ee60e89c4c068bc8f9628d0a36d8ed1e08c |
| MaseerTreasuryImplementation | 0x5ac573bd64022e88452421786f536b7084286faa |
| MaseerTreasuryProxy | 0xb9a83116abd6bf3476fc5819deeb91f63cafdca2 |
| MaseerGuardImplementation | 0x0853b0570df010b8da89915782533fba0a1185a0 |
| MaseerGuardProxy | 0xb946b4c20522d23cccae926aceef6fc302f56609 |
| MaseerConduitImplementation | 0xb10d74543e0eb81dcc1d8e76da6c524b68dd4c80 |
| MaseerConduitProxy | 0x9e0924075bb6696e70f638336ee36e3bd9a130c7 |
| MaseerPrecommit | 0x1fa926b0f325bd4930e4fd0d7d291c7dcc1fdb67 |


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
