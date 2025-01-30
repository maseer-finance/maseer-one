// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

//import {console} from "forge-std/Test.sol";
import "../MaseerTestBase.t.sol";

import "../../script/MaseerOne.s.sol";

contract MaseerOneScriptTest is MaseerTestBase {

    MaseerOneScript public maseerOneScript;
    address public maseerOneDeploymentAddress;

    function setUp() public {
        maseerOneScript = new MaseerOneScript();
    }

    function testMaseerOneScript() public view {
        assertEq(maseerOneScript.NAME(), "Cana");
        assertEq(maseerOneScript.SYMBOL(), "CANA");
        assertEq(maseerOneScript.USDT(), 0xdAC17F958D2ee523a2206206994597C13D831ec7);
    }

    function testScriptDeployment() public {
        maseerOneScript.run();

        address deployed = address(maseerOneScript.maseerOne());
        assertTrue(deployed != address(0), "Script deployment failure");
    }

    function testScriptDeploymentFunctionality() public {

        maseerOneScript.run();

        assertTrue(maseerOneScript.MASEER_ORACLE() != address(0), "MASEER_ORACLE is zero");
        assertTrue(maseerOneScript.MASEER_ORACLE_PROXY() != address(0), "MASEER_ORACLE_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_MARKET() != address(0), "MASEER_MARKET is zero");
        assertTrue(maseerOneScript.MASEER_MARKET_PROXY() != address(0), "MASEER_MARKET_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_COMPLIANCE() != address(0), "MASEER_COMPLIANCE is zero");
        assertTrue(maseerOneScript.MASEER_COMPLIANCE_PROXY() != address(0), "MASEER_COMPLIANCE_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_CONDUIT() != address(0), "MASEER_CONDUIT is zero");
        assertTrue(maseerOneScript.MASEER_CONDUIT_PROXY() != address(0), "MASEER_CONDUIT_PROXY is zero");

        MaseerOne maseerOne = MaseerOne(maseerOneScript.maseerOne());

        assertEq(maseerOne.name(), "Cana");
        assertEq(maseerOne.symbol(), "CANA");


    }

}
