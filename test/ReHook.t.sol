// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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
import {ReHook} from "../src/ReHook.sol";
import {console2} from "forge-std/console2.sol";

contract ReHookTest is Test, Deployers {

    using SafeCast for *;

    address hook;
    address user = address(0xBEEF);

    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));
    }

    function testRehook() public {


        address impl = address(new ReHook(manager));
        address hookAddr = address(uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG));
        _etchHookAndInitPool(hookAddr, impl);
        console2.log("hookAddr", hookAddr);

    }
    function _etchHookAndInitPool(address hookAddr, address implAddr) internal {
        vm.etch(hookAddr, implAddr.code);
        hook = hookAddr;
        (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hook), 100, SQRT_PRICE_1_1);
    }
    function _defaultTestSettings() internal returns (PoolSwapTest.TestSettings memory testSetting) {
        return PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});
    }

}