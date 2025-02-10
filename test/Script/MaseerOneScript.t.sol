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

        assertTrue(maseerOneScript.MASEER_ORACLE_IMPLEMENTATION() != address(0), "MASEER_ORACLE is zero");
        assertTrue(maseerOneScript.MASEER_ORACLE_PROXY() != address(0), "MASEER_ORACLE_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_MARKET_IMPLEMENTATION() != address(0), "MASEER_MARKET is zero");
        assertTrue(maseerOneScript.MASEER_MARKET_PROXY() != address(0), "MASEER_MARKET_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_COMPLIANCE_IMPLEMENTATION() != address(0), "MASEER_COMPLIANCE is zero");
        assertTrue(maseerOneScript.MASEER_COMPLIANCE_PROXY() != address(0), "MASEER_COMPLIANCE_PROXY is zero");
        assertTrue(maseerOneScript.MASEER_CONDUIT_IMPLEMENTATION() != address(0), "MASEER_CONDUIT is zero");
        assertTrue(maseerOneScript.MASEER_CONDUIT_PROXY() != address(0), "MASEER_CONDUIT_PROXY is zero");

        MaseerOne maseerOne = MaseerOne(maseerOneScript.maseerOne());


        assertEq(maseerOne.name(), maseerOneScript.NAME());
        assertEq(maseerOne.symbol(), maseerOneScript.SYMBOL());
        assertEq(maseerOne.decimals(), 18);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.pip(), maseerOneScript.MASEER_ORACLE_PROXY());
        assertEq(maseerOne.act(), maseerOneScript.MASEER_MARKET_PROXY());
        assertEq(maseerOne.cop(), maseerOneScript.MASEER_COMPLIANCE_PROXY());
        assertEq(maseerOne.flo(), maseerOneScript.MASEER_CONDUIT_PROXY());
        assertEq(maseerOne.mintable(), false);
        assertEq(maseerOne.burnable(), false);
        assertEq(maseerOne.claimDelay(), maseerOneScript.MARKET_DELAY());
        assertEq(maseerOne.price(),     1_000_000);
        assertEq(maseerOne.mintPrice(), 1_010_000);
        assertEq(maseerOne.burnPrice(),   990_100);
        assertEq(maseerOne.cap(), maseerOneScript.MARKET_CAP());


        assertEq(maseerOne.pip(), maseerOneScript.MASEER_ORACLE_PROXY());
        assertEq(MaseerProxy(maseerOne.pip()).impl(), maseerOneScript.MASEER_ORACLE_IMPLEMENTATION());
        assertEq(MaseerPrice(maseerOne.pip()).name(), _bytes32toString(maseerOneScript.ORACLE_NAME()));
        assertEq(MaseerPrice(maseerOne.pip()).decimals(), uint8(uint256(maseerOneScript.ORACLE_DECIMALS())));
        assertEq(MaseerPrice(maseerOne.pip()).wards(maseerOneScript.oracleAuth()), 1);
        assertEq(MaseerProxy(maseerOne.pip()).wardsProxy(maseerOneScript.proxyAuth()), 1);

        assertEq(maseerOne.act(), maseerOneScript.MASEER_MARKET_PROXY());
        assertEq(MaseerProxy(maseerOne.act()).impl(), maseerOneScript.MASEER_MARKET_IMPLEMENTATION());
        assertEq(MaseerGate(maseerOne.act()).cap(), maseerOneScript.MARKET_CAP());
        assertEq(MaseerGate(maseerOne.act()).delay(), maseerOneScript.MARKET_DELAY());
        assertEq(MaseerGate(maseerOne.act()).wards(maseerOneScript.marketAuth()), 1);
        assertEq(MaseerProxy(maseerOne.act()).wardsProxy(maseerOneScript.proxyAuth()), 1);

        assertEq(maseerOne.cop(), maseerOneScript.MASEER_COMPLIANCE_PROXY());
        assertEq(MaseerProxy(maseerOne.cop()).impl(), maseerOneScript.MASEER_COMPLIANCE_IMPLEMENTATION());
        assertEq(MaseerGuard(maseerOne.cop()).wards(maseerOneScript.complianceAuth()), 1);
        assertEq(MaseerProxy(maseerOne.cop()).wardsProxy(maseerOneScript.proxyAuth()), 1);

        assertEq(maseerOne.flo(), maseerOneScript.MASEER_CONDUIT_PROXY());
        assertEq(MaseerProxy(maseerOne.flo()).impl(), maseerOneScript.MASEER_CONDUIT_IMPLEMENTATION());
        assertEq(MaseerConduit(maseerOne.flo()).wards(maseerOneScript.conduitAuth()), 1);
        assertEq(MaseerConduit(maseerOne.flo()).can(maseerOneScript.conduitAuth()), 1);
        assertEq(MaseerConduit(maseerOne.flo()).bud(maseerOneScript.conduitOut()), 1);
        assertEq(MaseerProxy(maseerOne.flo()).wardsProxy(maseerOneScript.proxyAuth()), 1);
    }

}
