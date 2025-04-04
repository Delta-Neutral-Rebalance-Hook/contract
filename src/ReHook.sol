// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, toBeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta, toBalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencySettler} from "v4-core/test/utils/CurrencySettler.sol";
import {BaseTestHooks} from "v4-core/src/test/BaseTestHooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {console2} from "forge-std/console2.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";


contract ReHook is BaseTestHooks {

    using Hooks for IHooks;
    using CurrencySettler for Currency;

    IPoolManager immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }
    function beforeSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {

        (Currency inputCurrency, Currency outputCurrency, uint256 amount) = _getInputOutputAndAmount(key, params);

        manager.take(inputCurrency, address(this), amount);// manager transfer to hook

        outputCurrency.settle(manager, address(this), amount, false);// hook transfer to manager

        BeforeSwapDelta hookDelta = toBeforeSwapDelta(int128(-params.amountSpecified), int128(params.amountSpecified));

        uint256 amount0 = MockERC20(Currency.unwrap(key.currency0)).balanceOf(address(manager));
        uint256 amount1 = MockERC20(Currency.unwrap(key.currency1)).balanceOf(address(manager));


        return (IHooks.beforeSwap.selector, hookDelta, 0);
        // return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    function beforeInitialize(
        address sender, 
        PoolKey calldata key, 
        uint160 sqrtPriceX96
    ) external override onlyPoolManager returns (bytes4)
    {
        // PoolId poolId = key.toId();

        // string memory tokenSymbol = string(
        //     abi.encodePacked(
        //         "UniV4-REBALANCE",
        //         "-",
        //         IERC20Metadata(Currency.unwrap(key.currency0)).symbol(),
        //         "-",
        //         IERC20Metadata(Currency.unwrap(key.currency1)).symbol(),
        //         "-",
        //         Strings.toString(uint256(key.fee))
        //     )
        // );
        // address poolToken = address(new ReERC20(tokenSymbol, tokenSymbol));

        // liquidityToken = poolToken;
        // console2.log("liquidityToken", liquidityToken);

        return IHooks.beforeInitialize.selector;
    }
    function beforeRemoveLiquidity(
        address, /* sender **/
        PoolKey calldata, /* key **/
        IPoolManager.ModifyLiquidityParams calldata, /* params **/
        bytes calldata /* hookData **/
    ) external override returns (bytes4) {
        return IHooks.beforeRemoveLiquidity.selector;
    }
    function afterAddLiquidity(
        address, /* sender **/
        PoolKey calldata key, /* key **/
        IPoolManager.ModifyLiquidityParams calldata params, /* params **/
        BalanceDelta, /* delta **/
        BalanceDelta, /* feeDelta **/
        bytes calldata /* hookData **/
    ) external override returns (bytes4, BalanceDelta) {
        uint256 amount0 = MockERC20(Currency.unwrap(key.currency0)).balanceOf(address(manager));
        uint256 amount1 = MockERC20(Currency.unwrap(key.currency1)).balanceOf(address(manager));
        // int128 amount00 = 0+amount0;
        // int128 amount11 = 0+amount1;
        BalanceDelta hookDelta;
        if(amount0 > 0 && amount1 > 0) {
            manager.take(key.currency0, address(this), amount0);
            manager.take(key.currency1, address(this), amount1);
            hookDelta = toBalanceDelta(int128(uint128(amount0)), int128(uint128(amount1)));
        }
        else{
            hookDelta = BalanceDeltaLibrary.ZERO_DELTA;
        }


        // manager.take(key.currency0, address(this), uint256(params.liquidityDelta/1e5));
        // manager.take(key.currency1, address(this), uint256(params.liquidityDelta/1e5));

        console2.log("hi");
        return (IHooks.afterAddLiquidity.selector, hookDelta);
    }

    function _getInputOutputAndAmount(PoolKey calldata key, IPoolManager.SwapParams calldata params)
        internal
        pure
        returns (Currency input, Currency output, uint256 amount)
    {
        (input, output) = params.zeroForOne ? (key.currency0, key.currency1) : (key.currency1, key.currency0);

        amount = params.amountSpecified < 0 ? uint256(-params.amountSpecified) : uint256(params.amountSpecified);
    }
}