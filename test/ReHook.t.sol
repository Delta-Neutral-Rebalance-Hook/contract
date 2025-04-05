// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {SafeCast} from "v4-core/src/libraries/SafeCast.sol";
import {Constants} from "v4-core/test/utils/Constants.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {ReHook} from "../src/ReHook.sol";
import {console2} from "forge-std/console2.sol";

contract ReHookTest is Test, Deployers {

    using SafeCast for *;

    address hook;
    address user = vm.addr(1);
    uint256 userPrivateKey = 1;

    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));
    }
    function testRehook() public {

        address impl = address(new ReHook(manager));
        address hookAddr = address(uint160(Hooks.AFTER_REMOVE_LIQUIDITY_FLAG|Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG|Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG|Hooks.AFTER_ADD_LIQUIDITY_FLAG|Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));
        _etchHookAndInitPool(hookAddr, impl);
        console2.log("hookAddr", hookAddr);
        console2.log("impl", impl);
        console2.log("manager", address(manager));


        // test for beforeAddLiquidity
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
            tickLower: TickMath.MIN_TICK,
            tickUpper: TickMath.MAX_TICK,
            liquidityDelta: 1e6,
            salt: 0
        });

        // test for beforeSwap

        bool zeroForOne = false;
        uint256 amountToSwap = 1e4;
        int256 amountSpecified = int256(amountToSwap);

        IPoolManager.SwapParams memory sparams = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });

        _setApprovalsFor(user, address(Currency.unwrap(key.currency0)));
        _setApprovalsFor(user, address(Currency.unwrap(key.currency1)));

        key.currency0.transfer(address(user), 10e18);
        key.currency1.transfer(address(user), 10e18);
        key.currency0.transfer(address(hook), 10e18);
        key.currency1.transfer(address(hook), 10e18);
        console2.log("Before swap");
        console2.log("user balance", MockERC20(Currency.unwrap(key.currency0)).balanceOf(user));
        console2.log("user balance", MockERC20(Currency.unwrap(key.currency1)).balanceOf(user));
        console2.log("hook balance", MockERC20(Currency.unwrap(key.currency0)).balanceOf(hook));
        console2.log("hook balance", MockERC20(Currency.unwrap(key.currency1)).balanceOf(hook));

        vm.startPrank(user);
        console2.log("user address: ", user);
        bytes32 message = keccak256(abi.encode(key));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, message);
        bytes memory signature = abi.encodePacked(bytes32(r), bytes32(s), uint8(v));
        bytes memory hookData = signature;

        console2.log("user:", user);

        modifyLiquidityRouter.modifyLiquidity(key, params, hookData, false, true);
        swapRouter.swap(key, sparams, _defaultTestSettings(), ZERO_BYTES);
        modifyLiquidityRouter.modifyLiquidity(key, params, hookData, false, true);


        vm.stopPrank();

        // console2.log("After swap);
        console2.log("user balance", MockERC20(Currency.unwrap(key.currency0)).balanceOf(user));
        console2.log("user balance", MockERC20(Currency.unwrap(key.currency1)).balanceOf(user));
        console2.log("hook balance", MockERC20(Currency.unwrap(key.currency0)).balanceOf(hook));
        console2.log("hook balance", MockERC20(Currency.unwrap(key.currency1)).balanceOf(hook));
    }
    function _etchHookAndInitPool(address hookAddr, address implAddr) internal {
        vm.etch(hookAddr, implAddr.code);
        hook = hookAddr;
        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hook), 100, SQRT_PRICE_1_1);
    }
    function _defaultTestSettings() internal returns (PoolSwapTest.TestSettings memory testSetting) {
        return PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
    }
    function _setApprovalsFor(address _user, address token) internal {
        address[8] memory toApprove = [
            address(swapRouter),
            address(swapRouterNoChecks),
            address(modifyLiquidityRouter),
            address(modifyLiquidityNoChecks),
            address(donateRouter),
            address(takeRouter),
            address(claimsRouter),
            address(nestedActionRouter.executor())
        ];

        for (uint256 i = 0; i < toApprove.length; i++) {
            vm.prank(_user);
            MockERC20(token).approve(toApprove[i], Constants.MAX_UINT256);
        }
    }
}
