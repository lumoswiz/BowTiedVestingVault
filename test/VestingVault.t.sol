// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {VestingVault} from "../src/VestingVault.sol";

import {Utilities} from "./utils/Utilities.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract VestingVaultTest is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 69_420e18;

    uint256 internal constant WETH_FUND_VAULT = 50 ether;
    uint256 internal constant TOKEN_FUND_VAULT = 100e18;

    Utilities internal utils;
    VestingVault internal vault;

    address payable internal beneficiary;
    address payable internal vaultOwner;
    address payable internal user;

    MockERC20 tkn;
    WETH weth;

    function setUp() public {
        utils = new Utilities();

        // Create users: `beneficiary` and `vaultOwner`
        address payable[] memory users = utils.createUsers(3);
        beneficiary = users[0];
        vaultOwner = users[1];
        user = users[2];

        deployVault();

        // Deploy token contracts, mint supply and distribute to vaultOwner
        vm.startPrank(vaultOwner);
        tkn = new MockERC20(TOKEN_INITIAL_SUPPLY);
        tkn.approve(address(vault), type(uint256).max);
        assertEq(tkn.balanceOf(address(vaultOwner)), TOKEN_INITIAL_SUPPLY);

        weth = new WETH();

        assertEq(weth.balanceOf(address(vaultOwner)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: WETH_FUND_VAULT}();
        weth.approve(address(vault), type(uint256).max);

        assertEq(weth.balanceOf(address(vaultOwner)), WETH_FUND_VAULT);
        assertEq(weth.totalSupply(), WETH_FUND_VAULT);

        vm.stopPrank();
    }

    function testDeployVault() public {
        vm.prank(vaultOwner);
        vault = new VestingVault(beneficiary);

        assertEq(vault.startTimestamp(), block.timestamp);
        assertEq(vault.owner(), vaultOwner);
    }

    function testFundVault() public {
        uint256 endTimestamp = block.timestamp + 365 days;

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = setFundTokenAmounts();

        uint256 ownerTknBalanceBefore = tkn.balanceOf(vaultOwner);
        uint256 ownerWethBalanceBefore = weth.balanceOf(vaultOwner);

        uint256 vaultTknBalanceBefore = tkn.balanceOf(address(vault));
        uint256 vaultWethBalanceBefore = weth.balanceOf(address(vault));

        vm.prank(vaultOwner);
        vault.fund(tokens, amounts, endTimestamp);

        for (uint256 i; i < tokens.length; ++i) {
            (address addr, uint256 amt, bool claimed) = vault.vestingDetails(i);
            assertEq(tokens[i], addr);
            assertEq(amounts[i], amt);
            assertEq(claimed, false);
        }

        assertEq(
            stdMath.delta(ownerTknBalanceBefore, tkn.balanceOf(vaultOwner)),
            TOKEN_FUND_VAULT
        );
        assertEq(
            stdMath.delta(ownerWethBalanceBefore, weth.balanceOf(vaultOwner)),
            WETH_FUND_VAULT
        );

        assertEq(
            stdMath.delta(tkn.balanceOf(address(vault)), vaultTknBalanceBefore),
            TOKEN_FUND_VAULT
        );
        assertEq(
            stdMath.delta(
                weth.balanceOf(address(vault)),
                vaultWethBalanceBefore
            ),
            WETH_FUND_VAULT
        );
    }

    function testUserCannotFundVault() public {
        uint256 endTimestamp = block.timestamp + 365 days;

        vm.startPrank(user);

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = setFundTokenAmounts();

        vm.expectRevert();
        vault.fund(tokens, amounts, endTimestamp);

        vm.stopPrank();
    }

    function testVaultEndTimestampLtMaxDuration() public {
        uint256 endTimestamp = block.timestamp + 1465 days; // MAX_VESTING_DURATION = 1460 days

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = setFundTokenAmounts();

        vm.prank(vaultOwner);
        vm.expectRevert(VestingVault.Error_ExceedsMaxVestingDuration.selector);
        vault.fund(tokens, amounts, endTimestamp);
    }

    function testBeneficiaryCanWithdrawFromVault() public {
        uint256 endTimestamp = block.timestamp + 365 days;

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = setFundTokenAmounts();

        vm.prank(vaultOwner);
        vault.fund(tokens, amounts, endTimestamp);

        uint256 tknBalanceBefore = tkn.balanceOf(beneficiary);
        uint256 wethBalanceBefore = weth.balanceOf(beneficiary);

        vm.warp(block.timestamp + 366 days);
        vm.prank(beneficiary);
        vault.withdraw();

        assertEq(
            stdMath.delta(tkn.balanceOf(beneficiary), tknBalanceBefore),
            TOKEN_FUND_VAULT
        );
        assertEq(
            stdMath.delta(weth.balanceOf(beneficiary), wethBalanceBefore),
            WETH_FUND_VAULT
        );
    }

    // Helper functions

    function deployVault() public {
        vm.prank(vaultOwner);
        vault = new VestingVault(beneficiary);
    }

    function setFundTokenAmounts()
        public
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = new address[](2);
        tokens[0] = address(tkn);
        tokens[1] = address(weth);

        amounts = new uint256[](2);
        amounts[0] = TOKEN_FUND_VAULT;
        amounts[1] = WETH_FUND_VAULT;
    }
}
