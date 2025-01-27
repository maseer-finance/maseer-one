// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MaseerOne} from "../src/MaseerOne.sol";

contract CounterScript is Script {
    MaseerOne public maseerOne;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        maseerOne = new MaseerOne("Test Token", "MTEST");

        vm.stopBroadcast();
    }
}
