// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {MaseerOne} from "../src/MaseerOne.sol";
import {MaseerPrice} from "../src/MaseerPrice.sol";
import {MaseerGate} from "../src/MaseerGate.sol";
import {MaseerTreasury} from "../src/MaseerTreasury.sol";
import {MaseerGuardOZ} from "../src/MaseerGuardOZ.sol";
import {MaseerProxy} from "../src/MaseerProxy.sol";



contract MaseerOnetGBPScript is Script {
    MaseerOne public maseerOne;

    address public SIG_ONE   = 0xb56F413dbCe352cfd71f221029CFC84580133F66; // set signatory 1

    address public proxyAuth       = SIG_ONE;
    address public marketAuth      = SIG_ONE;
    address public oracleAuth      = SIG_ONE;
    // address public treasuryAuth    = SIG_ONE;  // No external mint/burn controls
    address public complianceAuth  = SIG_ONE;
    address public oracleUpdater   = SIG_ONE;

    string public constant NAME    = "Wrapped Staked tGBP";  // set token name
    string public constant SYMBOL  = "tGBP";

    string public constant TERMS   = "";      // set IPFS CID for terms

    bytes32 public constant ORACLE_NAME     = "wstGBPtGBP";
    bytes32 public constant ORACLE_DECIMALS = bytes32(uint256(18));
    uint256 public          ORACLE_PRICE    = 1 * 10**18; // set initial oracle price

    uint256 public          MARKET_CAPACITY = type(uint256).max;   // set market capacity
    uint256 public          MARKET_COOLDOWN = 7 days;              // set initial cooldown period
    uint256 public constant MARKET_BPSIN    = 0;                   // set mint fee bps
    uint256 public constant MARKET_BPSOUT   = 25;                  // set burn fee bps

    // Mainnet
    address public TGBP = 0x27f6c8289550fCE67f6B50BeD1F519966aFE5287; // set stablecoin address

    address public MASEER_ORACLE_IMPLEMENTATION;
    address public MASEER_ORACLE_PROXY;

    address public MASEER_MARKET_IMPLEMENTATION;
    address public MASEER_MARKET_PROXY;

    address public MASEER_TREASURY_IMPLEMENTATION;
    address public MASEER_TREASURY_PROXY;

    address public MASEER_COMPLIANCE_IMPLEMENTATION;
    address public MASEER_COMPLIANCE_PROXY;

    // No Conduit. Exit back to MaseerOne for all external interactions
    // address public MASEER_CONDUIT_IMPLEMENTATION;
    // address public MASEER_CONDUIT_PROXY;

    address public DEPLOYER;

    function run() public {
        vm.startBroadcast();

        DEPLOYER = tx.origin;
        console.log("Deployer address: ", DEPLOYER);

        // Pre-calculate MaseerOne address using deployer nonce.
        // 8 deployments precede MaseerOne (4 implementations + 4 proxies).
        uint64 nonce = vm.getNonce(DEPLOYER);
        address predictedMaseerOne = vm.computeCreateAddress(DEPLOYER, nonce + 8);

        MASEER_ORACLE_IMPLEMENTATION = address(new MaseerPrice());
        MASEER_ORACLE_PROXY = address(new MaseerProxy(MASEER_ORACLE_IMPLEMENTATION));
        MASEER_MARKET_IMPLEMENTATION = address(new MaseerGate());
        MASEER_MARKET_PROXY = address(new MaseerProxy(MASEER_MARKET_IMPLEMENTATION));
        MASEER_TREASURY_IMPLEMENTATION = address(new MaseerTreasury());
        MASEER_TREASURY_PROXY = address(new MaseerProxy(MASEER_TREASURY_IMPLEMENTATION));
        MASEER_COMPLIANCE_IMPLEMENTATION = address(new MaseerGuardOZ(TGBP));
        MASEER_COMPLIANCE_PROXY = address(new MaseerProxy(MASEER_COMPLIANCE_IMPLEMENTATION));

        maseerOne = new MaseerOne(
            TGBP,
            MASEER_ORACLE_PROXY,
            MASEER_MARKET_PROXY,
            MASEER_TREASURY_PROXY,
            MASEER_COMPLIANCE_PROXY,
            predictedMaseerOne, // Exit back to MaseerOne (no conduit)
            NAME,
            SYMBOL
        );
        require(address(maseerOne) == predictedMaseerOne, "MaseerOne address prediction mismatch");

        // MASEER_ORACLE_PROXY set wards and initial config
        MaseerPrice(MASEER_ORACLE_PROXY).file("name", ORACLE_NAME);
        MaseerPrice(MASEER_ORACLE_PROXY).file("decimals", ORACLE_DECIMALS);
        MaseerPrice(MASEER_ORACLE_PROXY).file("price", bytes32(ORACLE_PRICE));
        MaseerPrice(MASEER_ORACLE_PROXY).kiss(oracleUpdater);
        MaseerPrice(MASEER_ORACLE_PROXY).rely(oracleAuth);
        MaseerProxy(MASEER_ORACLE_PROXY).relyProxy(proxyAuth);

        // MASEER_MARKET_PROXY set wards and initial config
        MaseerGate(MASEER_MARKET_PROXY).setCooldown(MARKET_COOLDOWN);
        MaseerGate(MASEER_MARKET_PROXY).setCapacity(MARKET_CAPACITY);
        MaseerGate(MASEER_MARKET_PROXY).setBpsin(MARKET_BPSIN);
        MaseerGate(MASEER_MARKET_PROXY).setBpsout(MARKET_BPSOUT);
        MaseerGate(MASEER_MARKET_PROXY).setTerms(TERMS);
        MaseerGate(MASEER_MARKET_PROXY).setOpenMint(0);
        MaseerGate(MASEER_MARKET_PROXY).file("haltmint", type(uint256).max);
        MaseerGate(MASEER_MARKET_PROXY).setOpenBurn(0);
        MaseerGate(MASEER_MARKET_PROXY).file("haltburn", type(uint256).max);
        MaseerGate(MASEER_MARKET_PROXY).rely(marketAuth);
        MaseerProxy(MASEER_MARKET_PROXY).relyProxy(proxyAuth);

        // MASEER_TREASURY_PROXY set issuer
        MaseerProxy(MASEER_TREASURY_PROXY).relyProxy(proxyAuth);

        // MASEER_COMPLIANCE_PROXY set wards
        MaseerGuardOZ(MASEER_COMPLIANCE_PROXY).rely(complianceAuth);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).relyProxy(proxyAuth);

        // Disable deployer auths
        MaseerPrice(MASEER_ORACLE_PROXY).deny(DEPLOYER);
        MaseerProxy(MASEER_ORACLE_PROXY).denyProxy(DEPLOYER);
        MaseerGate(MASEER_MARKET_PROXY).deny(DEPLOYER);
        MaseerProxy(MASEER_MARKET_PROXY).denyProxy(DEPLOYER);
        MaseerTreasury(MASEER_TREASURY_PROXY).deny(DEPLOYER);
        MaseerProxy(MASEER_TREASURY_PROXY).denyProxy(DEPLOYER);
        MaseerGuardOZ(MASEER_COMPLIANCE_PROXY).deny(DEPLOYER);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).denyProxy(DEPLOYER);
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

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
