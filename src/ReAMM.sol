// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ReAMM{
    address manager;
    constructor(address _manager) {
        manager = _manager;
    }
    modifier onlyPoolManager() {
        require(msg.sender == manager);
        _;
    }
    uint public constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;           // save slot
    uint112 private reserve1;
    uint32  private blockTimestampLast;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    





}