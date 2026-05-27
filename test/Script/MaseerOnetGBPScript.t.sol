// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20}        from "forge-std/interfaces/IERC20.sol";

import {MaseerOne}      from "../../src/MaseerOne.sol";
import {MaseerPrice}    from "../../src/MaseerPrice.sol";
import {MaseerGate}     from "../../src/MaseerGate.sol";
import {MaseerTreasury} from "../../src/MaseerTreasury.sol";
import {MaseerGuardOZ}  from "../../src/MaseerGuardOZ.sol";
import {MaseerProxy}    from "../../src/MaseerProxy.sol";

import "../../script/MaseerOnetGBP.s.sol";

contract MaseerOnetGBPScriptTest is Test {

    MaseerOnetGBPScript public script;

    function setUp() public {
        script = new MaseerOnetGBPScript();
    }

    function testConstants() public view {
        assertEq(script.NAME(), "Wren Staked tGBP");
        assertEq(script.SYMBOL(), "wstGBP");
        assertEq(script.TGBP(), 0x27f6c8289550fCE67f6B50BeD1F519966aFE5287);
    }

    function testScriptDeployment() public {
        script.run();

        address deployed = address(script.maseerOne());
        assertTrue(deployed != address(0), "Script deployment failure");
    }

    function testScriptDeploymentFunctionality() public {
        script.run();

        assertTrue(script.MASEER_ORACLE_IMPLEMENTATION() != address(0), "MASEER_ORACLE is zero");
        assertTrue(script.MASEER_ORACLE_PROXY() != address(0), "MASEER_ORACLE_PROXY is zero");
        assertTrue(script.MASEER_MARKET_IMPLEMENTATION() != address(0), "MASEER_MARKET is zero");
        assertTrue(script.MASEER_MARKET_PROXY() != address(0), "MASEER_MARKET_PROXY is zero");
        assertTrue(script.MASEER_TREASURY_IMPLEMENTATION() != address(0), "MASEER_TREASURY is zero");
        assertTrue(script.MASEER_TREASURY_PROXY() != address(0), "MASEER_TREASURY_PROXY is zero");
        assertTrue(script.MASEER_COMPLIANCE_IMPLEMENTATION() != address(0), "MASEER_COMPLIANCE is zero");
        assertTrue(script.MASEER_COMPLIANCE_PROXY() != address(0), "MASEER_COMPLIANCE_PROXY is zero");

        MaseerOne maseerOne = script.maseerOne();

        assertEq(maseerOne.name(), script.NAME());
        assertEq(maseerOne.symbol(), script.SYMBOL());
        assertEq(maseerOne.decimals(), 18);
        assertEq(maseerOne.totalSupply(), 0);
        assertEq(maseerOne.totalPending(), 0);
        assertEq(maseerOne.pip(), script.MASEER_ORACLE_PROXY());
        assertEq(maseerOne.act(), script.MASEER_MARKET_PROXY());
        assertEq(maseerOne.cop(), script.MASEER_COMPLIANCE_PROXY());
        assertEq(maseerOne.adm(), script.MASEER_TREASURY_PROXY());

        // flo points to MaseerOne itself (no conduit)
        assertEq(maseerOne.flo(), address(maseerOne));

        assertEq(maseerOne.mintable(), true);
        assertEq(maseerOne.burnable(), true);
        assertEq(maseerOne.cooldown(), script.MARKET_COOLDOWN());
        assertEq(maseerOne.capacity(), script.MARKET_CAPACITY());
        assertEq(maseerOne.terms(), script.TERMS());

        // Oracle config
        assertEq(MaseerProxy(maseerOne.pip()).impl(), script.MASEER_ORACLE_IMPLEMENTATION());
        assertEq(MaseerPrice(maseerOne.pip()).name(), _bytes32toString(script.ORACLE_NAME()));
        assertEq(MaseerPrice(maseerOne.pip()).decimals(), uint8(uint256(script.ORACLE_DECIMALS())));
        assertEq(MaseerPrice(maseerOne.pip()).read(), script.ORACLE_PRICE());
        assertEq(MaseerPrice(maseerOne.pip()).wards(script.oracleAuth()), 1);
        assertEq(MaseerProxy(maseerOne.pip()).wardsProxy(script.proxyAuth()), 1);

        // Market config
        assertEq(MaseerProxy(maseerOne.act()).impl(), script.MASEER_MARKET_IMPLEMENTATION());
        assertEq(MaseerGate(maseerOne.act()).capacity(), script.MARKET_CAPACITY());
        assertEq(MaseerGate(maseerOne.act()).cooldown(), script.MARKET_COOLDOWN());
        assertEq(MaseerGate(maseerOne.act()).wards(script.marketAuth()), 1);
        assertEq(MaseerProxy(maseerOne.act()).wardsProxy(script.proxyAuth()), 1);

        // Compliance config
        assertEq(MaseerProxy(maseerOne.cop()).impl(), script.MASEER_COMPLIANCE_IMPLEMENTATION());
        assertEq(MaseerGuardOZ(maseerOne.cop()).wards(script.complianceAuth()), 1);
        assertEq(MaseerProxy(maseerOne.cop()).wardsProxy(script.proxyAuth()), 1);

        // Treasury config (no treasuryAuth — external issuers not allowed)
        assertEq(MaseerProxy(maseerOne.adm()).impl(), script.MASEER_TREASURY_IMPLEMENTATION());
        assertEq(MaseerProxy(maseerOne.adm()).wardsProxy(script.proxyAuth()), 1);
    }

    function testSettleSendsToSelf() public {
        script.run();

        MaseerOne maseerOne = script.maseerOne();
        address tgbp = script.TGBP();

        // Confirm flo == maseerOne (self-referencing)
        assertEq(maseerOne.flo(), address(maseerOne), "flo should be maseerOne");

        // Seed maseerOne with some tGBP (simulates unsettled funds)
        uint256 amount = 1000 * 10**18;
        deal(tgbp, address(maseerOne), amount);

        uint256 balBefore = IERC20(tgbp).balanceOf(address(maseerOne));
        assertEq(balBefore, amount);

        // settle() transfers gem to flo, which is maseerOne itself
        address settler = makeAddr("settler");
        vm.prank(settler);
        uint256 out = maseerOne.settle();

        uint256 balAfter = IERC20(tgbp).balanceOf(address(maseerOne));

        // Funds stay in MaseerOne (self-transfer)
        assertEq(balAfter, balBefore, "Balance should be unchanged after settle to self");
        assertEq(out, amount, "settle should return full unsettled amount");
    }

    function _bytes32toString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 length = 0;
        while (length < 32 && _bytes32[length] != 0) {
            length++;
        }
        bytes memory bytesArray = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
