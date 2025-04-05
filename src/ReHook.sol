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

    struct Data {
        uint256 timestamp;
        uint256 value;
    }
    mapping(address => Data) public records;
    uint256 public lastTimestamp; // last update timestamp
    uint256 public totalWeight; // total weight
    uint256 public totalValue; // total liquidity value
    
    function updateTotalWeight(uint256 timestamp, uint256 updateValue, bool Add) external {
        totalWeight += totalValue*(timestamp - lastTimestamp);
        if(Add){
            totalValue += updateValue;
        } else {
            totalValue -= updateValue;
        }
        lastTimestamp = timestamp;
    }
    // address[] public keys;
    function updateAddressWeight(address sender, uint256 timestamp, uint256 updateValue) external returns(uint256){
        if(records[sender].timestamp == 0) {
            Data storage data = records[sender];
            data.timestamp = timestamp;
            data.value += updateValue;
            lastTimestamp = timestamp;
            return(0);
        }else{
            Data storage data = records[sender];
            data.timestamp = timestamp;
            data.value = updateValue;
            return(data.value*(timestamp - data.timestamp));
        }
    }


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

        manager.take(inputCurrency, address(this), amount/100);// manager transfer to hook

        // outputCurrency.settle(manager, address(this), amount, false);// hook transfer to manager

        BeforeSwapDelta hookDelta = toBeforeSwapDelta(0, int128(params.amountSpecified/100));

        // uint256 amount0 = MockERC20(Currency.unwrap(key.currency0)).balanceOf(address(manager));
        // uint256 amount1 = MockERC20(Currency.unwrap(key.currency1)).balanceOf(address(manager));


        return (IHooks.beforeSwap.selector, hookDelta, 0);
        // return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    function beforeInitialize(
        address sender, 
        PoolKey calldata key,
        uint160 sqrtPriceX96
    ) external override onlyPoolManager returns (bytes4)
    {
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
        address sender, /* sender **/
        PoolKey calldata key, /* key **/
        IPoolManager.ModifyLiquidityParams calldata params, /* params **/
        BalanceDelta, /* delta **/
        BalanceDelta, /* feeDelta **/
        bytes calldata /* hookData **/
    ) external override returns (bytes4, BalanceDelta) {
        console2.log("sender", sender);
        BalanceDelta hookDelta;
        hookDelta = BalanceDeltaLibrary.ZERO_DELTA;
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