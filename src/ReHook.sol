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
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";


contract ReHook is BaseTestHooks {

    using Hooks for IHooks;
    using CurrencySettler for Currency;

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

    IPoolManager immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    modifier onlyPoolManager() {
        require(msg.sender == address(manager));
        _;
    }

    function updateTotalWeight(uint256 timestamp, uint256 updateValue0, uint256 updateValue1, bool ADD) internal {
        totalWeightCurrency0 += totalValueCurrency0 * (timestamp - lastTimestamp);
        totalWeightCurrency1 += totalValueCurrency1 * (timestamp - lastTimestamp);
        if(ADD) {
            totalValueCurrency0 += updateValue0;
            totalValueCurrency1 += updateValue1;
        } else {
            totalValueCurrency0 -= updateValue0;
            totalValueCurrency1 -= updateValue1;
        }
        lastTimestamp = timestamp;
    }

    function updateAddressWeight(address sender, uint256 timestamp, uint256 updateValue0, uint256 updateValue1, bool ADD) internal returns(uint256, uint256) {
        if(recordsCurrency0[sender].timestamp == 0) {
            Data storage data0 = recordsCurrency0[sender];
            data0.timestamp = timestamp;
            data0.value += updateValue0;
            Data storage data1 = recordsCurrency1[sender];
            data1.timestamp = timestamp;
            data1.value += updateValue1;
            return(0, 0);
        } else {
            Data storage data0 = recordsCurrency0[sender];
            Data storage data1 = recordsCurrency1[sender];
            uint256 reward0 = data0.value*(timestamp - data0.timestamp);
            uint256 reward1 = data1.value*(timestamp - data1.timestamp);
            data0.timestamp = timestamp;
            data1.timestamp = timestamp;
            if(ADD) {
                data0.value += updateValue0;
                data1.value += updateValue1;
            } else {
                data0.value -= updateValue0;
                data1.value -= updateValue1;
            }
            return(reward0, reward1);
        }
    }

    function beforeSwap(
        address, /* sender **/
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /* hookData **/
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        
        (Currency inputCurrency, Currency outputCurrency, uint256 amount) = _getInputOutputAndAmount(key, params);

        manager.take(inputCurrency, address(this), amount/100); // manager transfer to hook

        BeforeSwapDelta hookDelta = toBeforeSwapDelta(0, int128(params.amountSpecified/100));
        return (IHooks.beforeSwap.selector, hookDelta, 0);
    }

    function afterAddLiquidity(
        address sender, /* sender **/
        PoolKey calldata key, /* key **/
        IPoolManager.ModifyLiquidityParams calldata params, /* params **/
        BalanceDelta delta, 
        BalanceDelta, /* feeDelta **/
        bytes calldata hookData /* hookData **/
    ) external override returns (bytes4, BalanceDelta) {

        bytes memory sig = hookData;
        bytes32 message = keccak256(abi.encode(key));
        address user = recoverSigner(message, sig);
        uint256 amountCurrency0 = uint256(int256(-BalanceDeltaLibrary.amount0(delta)));
        uint256 amountCurrency1 = uint256(int256(-BalanceDeltaLibrary.amount1(delta)));

        uint256 userReward0;
        uint256 userReward1;

       (userReward0, userReward1) = updateAddressWeight(user, block.timestamp, amountCurrency0, amountCurrency1, true);
        updateTotalWeight(block.timestamp, amountCurrency0, amountCurrency1, true);
        totalWeightCurrency0 -= userReward0;
        totalWeightCurrency1 -= userReward1;
        if(userReward0!=0 && totalWeightCurrency0!=0 && IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this))!=0){ 
            uint256 totalReward0 = userReward0*IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this))/totalWeightCurrency0;
            IERC20(Currency.unwrap(key.currency0)).transfer(user, totalReward0);
        }
        if(userReward1!=0 && totalWeightCurrency1!=0 && IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this))!=0){
            uint256 totalReward1 = userReward1*IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this))/totalWeightCurrency1;
            IERC20(Currency.unwrap(key.currency1)).transfer(user, totalReward1);
        }

        return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }
    function afterRemoveLiquidity(
        address, /* sender **/
        PoolKey calldata key, /* key **/
        IPoolManager.ModifyLiquidityParams calldata params, /* params **/
        BalanceDelta delta, /* delta **/
        BalanceDelta, /* feeDelta **/
        bytes calldata hookData /* hookData **/
    ) external override returns (bytes4, BalanceDelta) {

        bytes memory sig = hookData;
        bytes32 message = keccak256(abi.encode(key));
        address user = recoverSigner(message, sig);
        uint256 amountCurrency0 = uint256(int256(-BalanceDeltaLibrary.amount0(delta)));
        uint256 amountCurrency1 = uint256(int256(-BalanceDeltaLibrary.amount1(delta)));

        uint256 userReward0;
        uint256 userReward1;

        (userReward0, userReward1) = updateAddressWeight(user, block.timestamp, amountCurrency0, amountCurrency1, false);
        updateTotalWeight(block.timestamp, amountCurrency0, amountCurrency1, false);
        totalWeightCurrency0 -= userReward0;
        totalWeightCurrency1 -= userReward1;
        if(userReward0!=0 && totalWeightCurrency0!=0 && IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this))!=0){ 
            uint256 totalReward0 = userReward0*IERC20(Currency.unwrap(key.currency0)).balanceOf(address(this))/totalWeightCurrency0;
            IERC20(Currency.unwrap(key.currency0)).transfer(user, totalReward0);
        }
        if(userReward1!=0 && totalWeightCurrency1!=0 && IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this))!=0){
            uint256 totalReward1 = userReward1*IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this))/totalWeightCurrency1;
            IERC20(Currency.unwrap(key.currency1)).transfer(user, totalReward1);
        }

        return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    // HELPER FUNCTIONS
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
