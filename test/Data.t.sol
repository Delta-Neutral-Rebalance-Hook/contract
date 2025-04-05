// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

contract testData{

    struct Data {
        uint256 timestamp;
        uint256 value;
    }
    mapping(address => Data) public records;
    uint256 public lastTimestamp; // last update timestamp
    uint256 public totalWeight; // total weight
    uint256 public totalValue; // total liquidity value
    
    function updateTotalWeight(uint256 timestamp, uint256 updateValue, bool Add) internal {
        totalWeight += totalValue*(timestamp - lastTimestamp);
        if(Add){
            totalValue += updateValue;
        } else {
            totalValue -= updateValue;
        }
        lastTimestamp = timestamp;
    }
    // address[] public keys;
    function updateAddressWeight(address sender, uint256 timestamp, uint256 updateValue, bool ADD) internal returns(uint256){
        if(records[sender].timestamp == 0) {
            Data storage data = records[sender];
            data.timestamp = timestamp;
            data.value += updateValue;
            return(0);
        }else{
            Data storage data = records[sender];
            uint256 reward = data.value*(timestamp - data.timestamp);
            data.timestamp = timestamp;
            if(ADD){
                data.value += updateValue;
            } else {
                data.value -= updateValue;
            }
            return(reward);
        }
    }
    function testDataCounting() public{

        address user1 = address(0x123);
        address user2 = address(0x456);
        uint256 timestamp = 1;
        // user1 deposits 10
        uint256 user1Deposit = 10;
        uint256 user1Reward;
        user1Reward = updateAddressWeight(user1, timestamp, user1Deposit, true);
        updateTotalWeight(timestamp, user1Deposit, true);
        totalWeight -= user1Reward;
        console2.log("user1Reward", user1Reward);
        console2.log("user1Value", records[user1].value);
        console2.log("totalValue", totalValue); 
        console2.log("Accum", totalWeight);
        timestamp = 3;
        console2.log("time:", timestamp);
        uint256 user2Deposit = 15;
        uint256 user2Reward;
        user2Reward = updateAddressWeight(user2, timestamp, user2Deposit, true);
        updateTotalWeight(timestamp, user2Deposit, true);
        totalWeight -= user2Reward;
        console2.log("user2Reward", user2Reward);
        console2.log("user2Value", records[user2].value);
        console2.log("totalValue", totalValue); 
        console2.log("Accum", totalWeight);
        timestamp = 5;
        console2.log("time:", timestamp);
        user1Deposit = 10;
        user1Reward = updateAddressWeight(user1, timestamp, user1Deposit, true);
        updateTotalWeight(timestamp, user1Deposit, true);
        totalWeight -= user1Reward;
        console2.log("user1Reward", user1Reward);
        console2.log("user1Value", records[user1].value);
        console2.log("totalValue", totalValue); 
        console2.log("Accum", totalWeight);
        timestamp = 7;
        console2.log("time:", timestamp);
        user2Deposit = 15;
        user2Reward = updateAddressWeight(user2, timestamp, user2Deposit, false);
        updateTotalWeight(timestamp, user2Deposit, false);
        totalWeight -= user2Reward;
        console2.log("user2Reward", user2Reward);
        console2.log("user2Value", records[user2].value);
        console2.log("totalValue", totalValue); 
        console2.log("Accum", totalWeight);



        // user2 deposits 15
        // // user1 deposits 10
        // uint256 user1Deposit = 10;
        // updateAddressWeight(user1, timestamp, user1Deposit, true);
        // updateTotalWeight(timestamp, user1Deposit, true);
        // console2.log("user1DepositValue", records[user1].value);
        // console2.log("totalValue", totalValue);

        // timestamp = 3;
        // uint256 user2Deposit = 15;
        // updateAddressWeight(user2, timestamp, user2Deposit, true);
        // updateTotalWeight(timestamp, user2Deposit, true);
        // console2.log("user2DepositValue", records[user2].value);
        // console2.log("totalValue", totalValue);
        // console2.log("Accum", totalWeight);

        // timestamp = 5;
        // console2.log("timestamp", timestamp);
        // uint256 user1Reward;
        // user1Reward = updateAddressWeight(user1, timestamp, user1Deposit, true);
        // updateTotalWeight(timestamp, user1Deposit, true);
        // console2.log("totalValue", totalValue);
        // console2.log("Accum", totalWeight);
        // console2.log("user1Reward", user1Reward);
        // console2.log("user1Value", records[user1].value);
        // console2.log("user2Value", records[user2].value);
        // // update
        // totalWeight -= user1Reward;
        // console2.log("Accum test", totalWeight);
        // timestamp = 7;
        //  console2.log("timestamp", timestamp);
        // uint256 user2Reward;
        // user2Reward = updateAddressWeight(user2, timestamp, user2Deposit, false);
        // updateTotalWeight(timestamp, user2Deposit, false);
        // totalWeight -= user2Reward;
        // console2.log("totalValue", totalValue);
        // console2.log("Accum", totalWeight);
        // console2.log("user2Reward", user2Reward);






    }
}