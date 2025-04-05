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
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";


contract ReHook is BaseTestHooks {

    using Hooks for IHooks;
    using CurrencySettler for Currency;

    // address user = address(0xBEEF);
    struct Data {
        uint256 timestamp;
        uint256 value;
    }
    mapping(address => Data) public recordsCurrency0;
    mapping(address => Data) public recordsCurrency1;
    uint256 public lastTimestamp; // last update timestamp
    uint256 public totalWeightCurrency0; // total Currency0 weight
    uint256 public totalWeightCurrency1; // total Currency1 weight

    uint256 public totalValueCurrency0; // total Currency0 liquidity value
    uint256 public totalValueCurrency1; // total Currency1 liquidity value

    
    function updateTotalWeight(uint256 timestamp, uint256 updateValue0, uint256 updateValue1, bool Add) internal {
        totalWeightCurrency0 += totalValueCurrency0*(timestamp - lastTimestamp);
        totalWeightCurrency1 += totalValueCurrency1*(timestamp - lastTimestamp);
        if(Add){
            totalValueCurrency0 += updateValue0;
            totalValueCurrency1 += updateValue1;
        } else {
            totalValueCurrency0 -= updateValue0;
            totalValueCurrency1 -= updateValue1;
        }
        lastTimestamp = timestamp;
    }
    // address[] public keys;
    function updateAddressWeight(address sender, uint256 timestamp, uint256 updateValue0, uint256 updateValue1, bool ADD) internal returns(uint256, uint256){
        if(recordsCurrency0[sender].timestamp == 0) {
            Data storage data0 = recordsCurrency0[sender];
            data0.timestamp = timestamp;
            data0.value += updateValue0;
            Data storage data1 = recordsCurrency1[sender];
            data1.timestamp = timestamp;
            data1.value += updateValue1;
            return(0, 0);
        }else{
            Data storage data0 = recordsCurrency0[sender];
            Data storage data1 = recordsCurrency1[sender];
            uint256 reward0 = data0.value*(timestamp - data0.timestamp);
            uint256 reward1 = data1.value*(timestamp - data1.timestamp);
            data0.timestamp = timestamp;
            data1.timestamp = timestamp;
            if(ADD){
                data0.value += updateValue0;
                data1.value += updateValue1;
            } else {
                data0.value -= updateValue0;
                data1.value -= updateValue1;
            }
            return(reward0, reward1);
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
        bytes calldata hookData /* hookData **/
    ) external override returns (bytes4, BalanceDelta) {
        console2.log("sender", sender);
        BalanceDelta hookDelta;
        hookDelta = BalanceDeltaLibrary.ZERO_DELTA;
        console2.log("hi");

        bytes memory sig = hookData;
        bytes32 message = keccak256(abi.encode(key));
        address user = recoverSigner(message, sig);
        console2.log("user address check: ", user);

        


        // uint256 userDeposit = 10;
        // uint256 userReward;
        // userReward = updateAddressWeight(user, block.timestamp(), userDeposit, true);
        // updateTotalWeight(block.timestamp(), userDeposit, true);
        // totalWeight -= user1Reward;
        // if(user1Reward!=0){
            
        // }



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

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}
