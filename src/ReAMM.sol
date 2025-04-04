// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReAMMERC20} from "./ReAMMERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract ReAMM is ReAMMERC20 {
    address manager;
    address public token0;
    address public token1;
    constructor(address _manager, address _token0, address _token1) {
        manager = _manager;
        token0 = _token0;
        token1 = _token1;
    }
    modifier onlyPoolManager() {
        require(msg.sender == manager);
        _;
    }
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    uint256 private reserve0;           // save slot
    uint256 private reserve1;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    
    function mint(address to) external lock returns (uint liquidity) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0*amount1)-MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0*totalSupply / reserve0, amount1*totalSupply) / reserve1;
        }
        require(liquidity > 0, 'REQUIRES_MORE_LIQUIDITY');
        _mint(to, liquidity);

        reserve0 = uint256(balance0);
        reserve1 = uint256(balance1);
        emit Mint(msg.sender, amount0, amount1);
    }
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        amount0 = liquidity*balance0 / totalSupply;
        amount1 = liquidity*balance1 / totalSupply;
        require(amount0 > 0 && amount1 > 0, 'REQUIRES_MORE_LIQUIDITY_TO_BURN');
        _burn(address(this), liquidity);
        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        reserve0 = uint256(balance0);
        reserve1 = uint256(balance1);
        emit Burn(msg.sender, amount0, amount1, to);
    }






}