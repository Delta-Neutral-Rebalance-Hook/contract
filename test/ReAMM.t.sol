// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ReAMM} from "../src/ReAMM.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReHookTest is Test {

    address manager;
    address user;
    address internal usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC
    address internal weth = 0x4200000000000000000000000000000000000006; // WETH
    function setUp() public {
        vm.createSelectFork("https://base-mainnet.g.alchemy.com/v2/AUBsPkVCh3vM7L6hqx5mUCh25TNoMSY-");
        manager = address(0x123);
        user = address(0xBEEF);
    }

    function testReAMM() public {
        vm.startPrank(manager);
        ReAMM amm = new ReAMM(manager, weth, usdc);
        vm.stopPrank();

        deal(weth, user, 10 ether); // token0 for weth
        deal(usdc, user, 1e11); // token1 for usdc

        vm.startPrank(user);
        IERC20(weth).approve(address(amm), 10 ether);
        IERC20(usdc).approve(address(amm), 1e11);
        console2.log("add liquidity");
        amm.addliquidity(10 ether, 1e11);
        console2.log("user balance of LP token", IERC20(amm).balanceOf(user));
        console2.log("weth reserve", amm.reserve0());
        console2.log("usdc reserve", amm.reserve1());

        // console2.log("ReAMM deployed at:", address(amm));
        vm.stopPrank();


        // Add more tests here to validate the functionality of ReAMM
    }









}
