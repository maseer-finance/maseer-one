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

    string public constant NAME = "Cana";
    string public constant SYMBOL = "CANA";

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public MASEER_ORACLE;
    address public MASEER_ORACLE_PROXY;

    address public MASEER_MARKET;
    address public MASEER_MARKET_PROXY;

    address public MASEER_COMPLIANCE;
    address public MASEER_COMPLIANCE_PROXY;

    address public MASEER_CONDUIT;
    address public MASEER_CONDUIT_PROXY;

    function run() public {
        vm.startBroadcast();

        MASEER_ORACLE = address(new MaseerPrice());
        MASEER_ORACLE_PROXY = address(new MaseerProxy(MASEER_ORACLE));
        MASEER_MARKET = address(new MaseerGate());
        MASEER_MARKET_PROXY = address(new MaseerProxy(MASEER_MARKET));
        MASEER_COMPLIANCE = address(new MaseerGuard(USDT));
        MASEER_COMPLIANCE_PROXY = address(new MaseerProxy(MASEER_COMPLIANCE));
        MASEER_CONDUIT = address(new MaseerConduit());
        MASEER_CONDUIT_PROXY = address(new MaseerProxy(MASEER_CONDUIT));

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
        // MASEER_MARKET_PROXY set wards and initial config
        // MASEER_COMPLIANCE_PROXY set wards
        // MASEER_CONDUIT_PROXY set wards and buds

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
