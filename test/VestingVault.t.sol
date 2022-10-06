// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {VestingVault} from "../src/VestingVault.sol";

import {Utilities} from "./utils/Utilities.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract VestingVaultTest is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 1_000e18;

    Utilities internal utils;
    VestingVault internal vault;

    address payable internal beneficiary;
    address payable internal vaultOwner;

    MockERC20 tokenX;
    MockERC20 tokenY;
    WETH weth;

    function setUp() public {
        utils = new Utilities();

        // Create users: `beneficiary` and `vaultOwner`
        address payable[] memory users = utils.createUsers(2);
        beneficiary = users[0];
        vaultOwner = users[1];

        // Deploy token contracts, mint supply and distribute to vaultOwner
        tokenX = new MockERC20("TokenX", "TKX", 18);
        tokenX.mint(address(vaultOwner), TOKEN_INITIAL_SUPPLY);

        assertEq(tokenX.balanceOf(address(vaultOwner)), TOKEN_INITIAL_SUPPLY);

        tokenY = new MockERC20("TokenY", "TKY", 18);
        tokenY.mint(address(vaultOwner), TOKEN_INITIAL_SUPPLY);

        assertEq(tokenY.balanceOf(address(vaultOwner)), TOKEN_INITIAL_SUPPLY);

        weth = new WETH();

        assertEq(weth.balanceOf(address(vaultOwner)), 0);
        assertEq(weth.totalSupply(), 0);

        vm.prank(vaultOwner);
        weth.deposit{value: 50 ether}();

        assertEq(weth.balanceOf(address(vaultOwner)), 50 ether);
        assertEq(weth.totalSupply(), 50 ether);
    }

    function testDeployVault() public {
        vm.prank(vaultOwner);
        vault = new VestingVault(beneficiary);

        assertEq(vault.startTimestamp(), block.timestamp);
        assertEq(vault.owner(), vaultOwner);
    }

    function testAddresses() public {
        emit log_address(address(tokenX));
        emit log_address(address(tokenY));
        emit log_address(address(weth));
    }

    function testFundVault() public {
        vm.startPrank(vaultOwner);
        vault = new VestingVault(beneficiary);

        uint256 _endTimestamp = block.timestamp + 365 days;

        address[] memory _tokens = new address[](3);
        _tokens[0] = address(tokenX);
        _tokens[1] = address(tokenY);
        _tokens[2] = address(weth);

        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = 100e18;
        _amounts[1] = 100e18;
        _amounts[2] = 50 ether;

        vault.fund(_tokens, _amounts, _endTimestamp);
    }
}
