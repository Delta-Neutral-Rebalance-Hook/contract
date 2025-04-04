// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, toBeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencySettler} from "v4-core/test/utils/CurrencySettler.sol";
import {BaseTestHooks} from "v4-core/src/test/BaseTestHooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";


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
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
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
}