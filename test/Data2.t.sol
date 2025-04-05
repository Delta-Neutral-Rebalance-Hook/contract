// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

contract testData is Test{

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

    function testDataCounting2() public{

        address user1 = address(0x123);
        address user2 = address(0x456);
        uint256 timestamp = 1;
        // // user1 deposits 10
        uint256 user1Deposit0 = 10;
        uint256 user1Deposit1 = 10;
        uint256 user1Reward0;
        uint256 user1Reward1;
        (user1Reward0, user1Reward1) = updateAddressWeight(user1,  block.timestamp, user1Deposit0, user1Deposit1, true);
        console2.log("value0", recordsCurrency0[user1].value);
        console2.log("value1", recordsCurrency1[user1].value);
        console2.log("time", recordsCurrency0[user1].timestamp);
        console2.log("time", recordsCurrency1[user1].timestamp);
        console2.log("user1Reward0", user1Reward0);
        console2.log("user1Reward1", user1Reward1);

        updateTotalWeight(timestamp, user1Deposit0, user1Deposit1, true);
        totalWeightCurrency0 -= user1Reward0;
        totalWeightCurrency1 -= user1Reward1;
        
        vm.warp(block.timestamp + 1 hours);
        (user1Reward0, user1Reward1) = updateAddressWeight(user1, block.timestamp, user1Deposit0, user1Deposit1, true);
        console2.log("value0", recordsCurrency0[user1].value);
        console2.log("value1", recordsCurrency1[user1].value);
        console2.log("time", recordsCurrency0[user1].timestamp);
        console2.log("time", recordsCurrency1[user1].timestamp);
        console2.log("user1Reward0", user1Reward0);
        console2.log("user1Reward1", user1Reward1);
        
        assertEq(user1Reward1, 36000);
        console2.log("Accum", totalWeightCurrency0);
        console2.log("Accum", totalWeightCurrency1);
    }
}