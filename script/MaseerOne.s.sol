// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MaseerOne} from "../src/MaseerOne.sol";
import {MaseerGate} from "../src/MaseerGate.sol";

import {MockPip} from "../test/Mocks/MockPip.sol";
import {MockCop} from "../test/Mocks/MockCop.sol";

contract CounterScript is Script {
    MaseerOne public maseerOne;

    string public NAME = "MaseerOne";
    string public SYMBOL = "M1";

    // Mainnet
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // TODO: Use Maseer Oracle proxy
    address public MASEER_ORACLE;

    // TODO: Use Maseer Market proxy
    address public MASEER_MARKET;

    // TODO: Use Maseer Compliance proxy
    address public MASEER_COMPLIANCE;

    function setUp() public {
    }

    function run() public {
        vm.startBroadcast();

        // TODO - Use real contracts once available
        MASEER_ORACLE = address(new MockPip());
        MASEER_MARKET = address(new MaseerGate());
        MASEER_COMPLIANCE = address(new MockCop());

        maseerOne = new MaseerOne(USDT, MASEER_ORACLE, MASEER_MARKET, MASEER_COMPLIANCE, NAME, SYMBOL);

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
