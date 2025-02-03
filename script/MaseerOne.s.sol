// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MaseerOne} from "../src/MaseerOne.sol";
import {MaseerPrice} from "../src/MaseerPrice.sol";
import {MaseerGate} from "../src/MaseerGate.sol";
import {MaseerGuard} from "../src/MaseerGuard.sol";
import {MaseerProxy} from "../src/MaseerProxy.sol";
import {MaseerConduit} from "../src/MaseerConduit.sol";

import {MockPip} from "../test/Mocks/MockPip.sol";
import {MockCop} from "../test/Mocks/MockCop.sol";

contract MaseerOneScript is Script {
    MaseerOne public maseerOne;

    address public proxyAuth;      // TODO
    address public oracleAuth;     // TODO
    address public marketAuth;     // TODO
    address public complianceAuth; // TODO
    address public conduitAuth;    // TODO
    address public conduitOut;     // TODO

    string public constant NAME = "Cana";
    string public constant SYMBOL = "CANA";

    bytes32 public constant ORACLE_NAME     = "CANAUSDT";
    bytes32 public constant ORACLE_DECIMALS = bytes32(uint256(6));
    uint256 public constant ORACLE_PRICE    = 1e6; // Temporary initial price

    uint256 public constant MARKET_CAP    = 1_000_000e18;
    uint256 public constant MARKET_DELAY  = 5 days;
    uint256 public constant MARKET_BPSIN  = 100;
    uint256 public constant MARKET_BPSOUT = 100;

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public MASEER_ORACLE_IMPLEMENTATION;
    address public MASEER_ORACLE_PROXY;

    address public MASEER_MARKET_IMPLEMENTATION;
    address public MASEER_MARKET_PROXY;

    address public MASEER_COMPLIANCE_IMPLEMENTATION;
    address public MASEER_COMPLIANCE_PROXY;

    address public MASEER_CONDUIT_IMPLEMENTATION;
    address public MASEER_CONDUIT_PROXY;

    function run() public {
        vm.startBroadcast();

        MASEER_ORACLE_IMPLEMENTATION = address(new MaseerPrice());
        MASEER_ORACLE_PROXY = address(new MaseerProxy(MASEER_ORACLE_IMPLEMENTATION));
        MASEER_MARKET_IMPLEMENTATION = address(new MaseerGate());
        MASEER_MARKET_PROXY = address(new MaseerProxy(MASEER_MARKET_IMPLEMENTATION));
        MASEER_COMPLIANCE_IMPLEMENTATION = address(new MaseerGuard(USDT));
        MASEER_COMPLIANCE_PROXY = address(new MaseerProxy(MASEER_COMPLIANCE_IMPLEMENTATION));
        MASEER_CONDUIT_IMPLEMENTATION = address(new MaseerConduit());
        MASEER_CONDUIT_PROXY = address(new MaseerProxy(MASEER_CONDUIT_IMPLEMENTATION));

        maseerOne = new MaseerOne(
            USDT,
            MASEER_ORACLE_PROXY,
            MASEER_MARKET_PROXY,
            MASEER_COMPLIANCE_PROXY,
            MASEER_CONDUIT_PROXY,
            NAME,
            SYMBOL
        );


        // TODO: Configure Authorizations on proxies
        // MASEER_ORACLE_PROXY set wards and initial config
        MaseerPrice(MASEER_ORACLE_PROXY).file("name", ORACLE_NAME);
        MaseerPrice(MASEER_ORACLE_PROXY).file("decimals", ORACLE_DECIMALS);
        MaseerPrice(MASEER_ORACLE_PROXY).poke(ORACLE_PRICE);
        MaseerPrice(MASEER_ORACLE_PROXY).rely(oracleAuth);
        MaseerPrice(MASEER_ORACLE_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_ORACLE_PROXY).relyProxy(proxyAuth);
        MaseerProxy(MASEER_ORACLE_PROXY).denyProxy(msg.sender);

        // MASEER_MARKET_PROXY set wards and initial config
        MaseerGate(MASEER_MARKET_PROXY).setDelay(MARKET_DELAY);
        MaseerGate(MASEER_MARKET_PROXY).setCap(MARKET_CAP);
        MaseerGate(MASEER_MARKET_PROXY).setBpsin(MARKET_BPSIN);
        MaseerGate(MASEER_MARKET_PROXY).setBpsout(MARKET_BPSOUT);
        MaseerGate(MASEER_MARKET_PROXY).rely(marketAuth);
        MaseerGate(MASEER_MARKET_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_MARKET_PROXY).relyProxy(proxyAuth);
        MaseerProxy(MASEER_MARKET_PROXY).denyProxy(msg.sender);

        // MASEER_COMPLIANCE_PROXY set wards
        MaseerGuard(MASEER_COMPLIANCE_PROXY).rely(complianceAuth);
        MaseerGuard(MASEER_COMPLIANCE_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).relyProxy(proxyAuth);
        MaseerProxy(MASEER_COMPLIANCE_PROXY).denyProxy(msg.sender);

        // MASEER_CONDUIT_PROXY set wards and buds
        MaseerConduit(MASEER_CONDUIT_PROXY).hope(conduitAuth);
        MaseerConduit(MASEER_CONDUIT_PROXY).kiss(conduitOut);
        MaseerConduit(MASEER_CONDUIT_PROXY).rely(conduitAuth);
        MaseerConduit(MASEER_CONDUIT_PROXY).deny(msg.sender);
        MaseerProxy(MASEER_CONDUIT_PROXY).relyProxy(proxyAuth);
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
}
