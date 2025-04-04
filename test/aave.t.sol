// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAave {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

/*
aave on base: 
0xA238Dd80C259a72e81d7e4664a9801593F98d1c5
usdc on base: 
0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
weth on base: 
0x4200000000000000000000000000000000000006
*/


contract AAVETest is Test {
    /// State Variable
    // Role
    address internal admin;

    address internal aave = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address internal usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC
    address internal weth = 0x4200000000000000000000000000000000000006; // WETH
    address internal aweth = 0xD4a0e0b9149BCee3C920d2E00b5dE09138fd8bb7; // aWETH

    // Modifier
    modifier validation() {
        // assertEq(nft.balanceOf(address(this)), 0);
        assertEq(IERC20(aweth).balanceOf(admin), 0);
        _;
        // uint256 tokensAfter = IERC20(wweth).balanceOf(address(this));
        // assertGt(tokensAfter, 1 ether);
        assertGt(IERC20(aweth).balanceOf(admin), 1 ether);
        console2.log("aWETH balance: ", IERC20(aweth).balanceOf(admin));
    }

    /// Setup function
    function setUp() public {
        vm.createSelectFork("https://base-mainnet.g.alchemy.com/v2/AUBsPkVCh3vM7L6hqx5mUCh25TNoMSY-");
        admin = makeAddr("admin");

        deal(weth, admin, 40 * 1e18);
        deal(usdc, admin, 40 * 1e6);

    }
    function testShort() public validation {
        vm.startPrank(admin);

        IERC20(weth).approve(aave, 40 * 1e18);
        IERC20(usdc).approve(aave, 40 * 1e6);
        IAave(aave).supply(weth, 40 * 1e18, admin, 0);

        // IERC20(weth).transfer(address(nft), 40 * 1e18);
        // IERC20(usdc).transfer(address(nft), 40 * 1e6);
        
        vm.stopPrank();
    }
}

