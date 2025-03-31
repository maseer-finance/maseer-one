// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MaseerOne} from "../src/MaseerOne.sol";
import {MaseerPrice} from "../src/MaseerPrice.sol";
import {MaseerGate} from "../src/MaseerGate.sol";
import {MaseerTreasury} from "../src/MaseerTreasury.sol";
import {MaseerGuard} from "../src/MaseerGuard.sol";
import {MaseerProxy} from "../src/MaseerProxy.sol";
import {MaseerConduit} from "../src/MaseerConduit.sol";
import {MaseerPrecommit} from "../src/MaseerPrecommit.sol";

import {MockUSDT} from "../test/Mocks/MockUSDT.sol";

contract MaseerOneScript is Script {
    MaseerOne public maseerOne;

    address public SIG_ONE = 0x6CFd1DC9DF04a7F9162eF6c9b381D42135E8B896;
    address public SIG_TWO = 0x99698A1538089f03e798FA265254d9d90F13824D;

    address public proxyAuth       = SIG_ONE;
    address public marketAuth      = SIG_ONE;
    address public treasuryAuth    = SIG_ONE;
    address public complianceAuth  = SIG_ONE;
    address public conduitAuth     = SIG_ONE;
    address public conduitOut      = SIG_ONE;

    address public oracleAuth      = SIG_TWO;

    string public constant NAME = "CANA Holdings California Carbon Credits";
    string public constant SYMBOL = "CANA";

    bytes32 public constant ORACLE_NAME     = "CANAUSDT";
    bytes32 public constant ORACLE_DECIMALS = bytes32(uint256(6));
    uint256 public          ORACLE_PRICE    = 1e6; // 1.0

    uint256 public          MARKET_CAPACITY = 1_000_000e18;
    uint256 public          MARKET_COOLDOWN = 5 days;
    uint256 public constant MARKET_BPSIN    = 200;
    uint256 public constant MARKET_BPSOUT   = 200;

    // Mainnet
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public MASEER_ORACLE_IMPLEMENTATION;
    address public MASEER_ORACLE_PROXY;

    address public MASEER_MARKET_IMPLEMENTATION;
    address public MASEER_MARKET_PROXY;

    address public MASEER_TREASURY_IMPLEMENTATION;
    address public MASEER_TREASURY_PROXY;

    address public MASEER_COMPLIANCE_IMPLEMENTATION;
    address public MASEER_COMPLIANCE_PROXY;

    address public MASEER_CONDUIT_IMPLEMENTATION;
    address public MASEER_CONDUIT_PROXY;

    address public MASEER_PRECOMMIT;

    // Sepolia
    address public SEPOLIA_AUTH = 0xB05502bf20342331F42A7B80Aa4bAB3F8cA86C0F;

    function run() public {
        vm.startBroadcast();

        if (getChainId() == 11155111) useSepoliaConfig();

        MASEER_ORACLE_IMPLEMENTATION = address(new MaseerPrice());
        MASEER_ORACLE_PROXY = address(new MaseerProxy(MASEER_ORACLE_IMPLEMENTATION));
        MASEER_MARKET_IMPLEMENTATION = address(new MaseerGate());
        MASEER_MARKET_PROXY = address(new MaseerProxy(MASEER_MARKET_IMPLEMENTATION));
        MASEER_TREASURY_IMPLEMENTATION = address(new MaseerTreasury());
        MASEER_TREASURY_PROXY = address(new MaseerProxy(MASEER_TREASURY_IMPLEMENTATION));
        MASEER_COMPLIANCE_IMPLEMENTATION = address(new MaseerGuard(USDT));
        MASEER_COMPLIANCE_PROXY = address(new MaseerProxy(MASEER_COMPLIANCE_IMPLEMENTATION));
        MASEER_CONDUIT_IMPLEMENTATION = address(new MaseerConduit());
        MASEER_CONDUIT_PROXY = address(new MaseerProxy(MASEER_CONDUIT_IMPLEMENTATION));

        maseerOne = new MaseerOne(
            USDT,
            MASEER_ORACLE_PROXY,
            MASEER_MARKET_PROXY,
            MASEER_TREASURY_PROXY,
            MASEER_COMPLIANCE_PROXY,
            MASEER_CONDUIT_PROXY,
            NAME,
            SYMBOL
        );

        MASEER_PRECOMMIT = address(new MaseerPrecommit(address(maseerOne)));

        // TODO: Configure Authorizations on proxies
        // MASEER_ORACLE_PROXY set wards and initial config
        MaseerPrice(MASEER_ORACLE_PROXY).file("name", ORACLE_NAME);
        MaseerPrice(MASEER_ORACLE_PROXY).file("decimals", ORACLE_DECIMALS);
        MaseerPrice(MASEER_ORACLE_PROXY).poke(ORACLE_PRICE);
        MaseerPrice(MASEER_ORACLE_PROXY).rely(oracleAuth);
        MaseerProxy(MASEER_ORACLE_PROXY).relyProxy(proxyAuth);

        // MASEER_MARKET_PROXY set wards and initial config
        MaseerGate(MASEER_MARKET_PROXY).setCooldown(MARKET_COOLDOWN);
        MaseerGate(MASEER_MARKET_PROXY).setCapacity(MARKET_CAPACITY);
        MaseerGate(MASEER_MARKET_PROXY).setBpsin(MARKET_BPSIN);
        MaseerGate(MASEER_MARKET_PROXY).setBpsout(MARKET_BPSOUT);
        MaseerGate(MASEER_MARKET_PROXY).rely(marketAuth);
        MaseerProxy(MASEER_MARKET_PROXY).relyProxy(proxyAuth);

        // MASEER_TREASURY_PROXY set issuer
        MaseerTreasury(MASEER_TREASURY_PROXY).rely(treasuryAuth);
        MaseerTreasury(MASEER_TREASURY_PROXY).bestow(treasuryAuth);
        MaseerProxy(MASEER_TREASURY_PROXY).relyProxy(proxyAuth);

        // MASEER_COMPLIANCE_PROXY set wards
        MaseerGuard(MASEER_COMPLIANCE_PROXY).rely(complianceAuth);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).relyProxy(proxyAuth);

        // MASEER_CONDUIT_PROXY set wards and buds
        MaseerConduit(MASEER_CONDUIT_PROXY).hope(conduitAuth);
        MaseerConduit(MASEER_CONDUIT_PROXY).kiss(conduitOut);
        MaseerConduit(MASEER_CONDUIT_PROXY).kiss(address(maseerOne));
        MaseerConduit(MASEER_CONDUIT_PROXY).rely(conduitAuth);
        MaseerProxy(MASEER_CONDUIT_PROXY).relyProxy(proxyAuth);

        // Additional setup for Sepolia
        if (getChainId() == 11155111) setupSepoliaMarket();

        // Disable deployer auths
        MaseerPrice(MASEER_ORACLE_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_ORACLE_PROXY).denyProxy(msg.sender);
        MaseerGate(MASEER_MARKET_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_MARKET_PROXY).denyProxy(msg.sender);
        MaseerTreasury(MASEER_TREASURY_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_TREASURY_PROXY).denyProxy(msg.sender);
        MaseerGuard(MASEER_COMPLIANCE_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).denyProxy(msg.sender);
        MaseerConduit(MASEER_CONDUIT_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_CONDUIT_PROXY).denyProxy(msg.sender);

        vm.stopBroadcast();

        require(address(maseerOne) != address(0), "MaseerOne address is zero");
        console.log("MaseerOne address: ",    address(maseerOne));
        require(
            keccak256(abi.encodePacked(maseerOne.name())) ==
            keccak256(abi.encodePacked(NAME)),
            "MaseerOne name is not correct");
        console.log("MaseerOne name: ",       maseerOne.name());
        require(
            keccak256(abi.encodePacked(maseerOne.symbol())) ==
            keccak256(abi.encodePacked(SYMBOL)),
            "MaseerOne symbol is not correct");
        console.log("MaseerOne symbol: ",     maseerOne.symbol());
        require(maseerOne.decimals() == 18, "MaseerOne decimals is not correct");
        console.log("MaseerOne decimals: ",   maseerOne.decimals());
        require(maseerOne.totalSupply() == 0, "MaseerOne totalSupply is not correct");
        console.log("MaseerOne totalSupply: ",maseerOne.totalSupply());

    }

    function useSepoliaConfig() internal {
        USDT = 0xcAddB146B3f1A6A558eCD01380b81c2Faf9C8a10;
        (bool success, bytes memory data) = USDT.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, 100_000_000_000 * 1e6));
        (success, data) = USDT.call(abi.encodeWithSignature("mint(address,uint256)", SEPOLIA_AUTH, 100_000_000_000 * 1e6));
        data;
    }

    function setupSepoliaMarket() internal {
        MaseerGate(MASEER_MARKET_PROXY).setOpenMint(0);
        MaseerGate(MASEER_MARKET_PROXY).file("haltmint", type(uint256).max);
        require(MaseerGate(MASEER_MARKET_PROXY).mintable());
        MaseerGate(MASEER_MARKET_PROXY).setOpenBurn(0);
        MaseerGate(MASEER_MARKET_PROXY).file("haltburn", type(uint256).max);
        require(MaseerGate(MASEER_MARKET_PROXY).burnable());
        MARKET_CAPACITY = 1_000_000e18 * 1000;
        MaseerGate(MASEER_MARKET_PROXY).setCapacity(MARKET_CAPACITY);
        MARKET_COOLDOWN = 10 minutes;
        MaseerGate(MASEER_MARKET_PROXY).setCooldown(MARKET_COOLDOWN);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
