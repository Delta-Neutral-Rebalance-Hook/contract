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
    function addliquidity(uint256 amount0, uint256 amount1) external{
        require(amount0 > 0 && amount1 > 0, 'REQUIRES_MORE_LIQUIDITY');
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        mint(msg.sender);
        emit Mint(msg.sender, amount0, amount1);
    }
    function removeliquidity(uint256 amount) external{
        require(amount > 0, 'REQUIRES_MORE_LIQUIDITY');
        balanceOf[address(this)] += amount;
        balanceOf[msg.sender] -= amount;
        burn(msg.sender);
    }

    function mint(address to) internal lock returns (uint liquidity) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0*amount1)-MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0*totalSupply / reserve0, amount1*totalSupply) / reserve1;
        }
        require(liquidity > 0, 'REQUIRES_MORE_LIQUIDITY');
        _mint(to, liquidity);

        reserve0 = uint256(balance0);
        reserve1 = uint256(balance1);
    }
    function burn(address to) internal lock returns (uint amount0, uint amount1) {
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
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function swap(uint amount0Out, uint amount1Out, address to) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(amount0Out < reserve0 && amount1Out < reserve1, 'REQUIRES_MORE_LIQUIDITY');

        uint256 balance0;
        uint256 balance1;
        {
        require(to != token0 && to != token1, 'INVALID_TO');
        if (amount0Out > 0) IERC20(token0).transfer(to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) IERC20(token1).transfer(to, amount1Out); // optimistically transfer tokens
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        {
        uint256 balance0Adjusted = balance0*1000-(amount0In*(3));
        uint256 balance1Adjusted = balance1*1000-(amount1In*(3));
        require((balance0Adjusted * balance1Adjusted) >= reserve0*reserve1*(1000**2), 'FAILED_SWAP');
        }
        reserve0 = uint256(balance0);
        reserve1 = uint256(balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }




}