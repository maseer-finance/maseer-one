# MaseerOne Token and Dependencies

## Overview


## Contract Descriptions

### MaseerOne.sol

The primary token contract representing the MaseerOne token. It manages core ERC-20 functionalities, including minting, burning, transfers, and balance tracking.

### MaseerGate.sol

A control layer that facilitates the enabling and halting of minting and burning operations through defined storage slots, ensuring secure and controlled token supply management.

#### Required Interface

    * `function mintable() external view returns (bool);`
    * `function burnable() external view returns (bool);`
    * `function mintcost(uint256) external view returns (uint256);`
    * `function burncost(uint256) external view returns (uint256);`
    * `function cooldown() external view returns (uint256);`
    * `function capacity() external view returns (uint256);`

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
forge script scripts/Deploy.s.sol:DeployMaseer --broadcast --rpc-url <ETH_RPC_URL>
```

### Testing

Run the test suite to ensure all contracts function correctly:

```
make test
```


## License

This project is licensed under the Business Source License 1.1 (BUSL-1.1).
