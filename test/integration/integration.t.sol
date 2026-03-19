// what we need when testing and creating a good interaction test
/*
1. we need a deployed contract to test on 
2. we need to simulate a transaction on the project and make sure the contract return back to it original state


** */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {DeployRaffles} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {fundRafles} from "script/integration.s.sol";

contract interactionTest is Test {

    Raffle raffle;
    HelperConfig helperconfig;
    address alice = makeAddr("alice");
    uint256 initial_Balance = 6 ether; 
    uint256 s_minimumEntranceFee;
    address s_vrfCoordinator;
    uint256 s_intervals;


    function setUp() external {
        DeployRaffles deployer = new DeployRaffles();
        (raffle,helperconfig) = deployer.deploycontract();
        HelperConfig.networkConfig memory config =  helperconfig.getConfig();
        s_minimumEntranceFee = config.s_minimumEntranceFee;
        s_vrfCoordinator = config.s_vrfCoordinator;
        s_intervals = config.s_intervals;
        deal(alice,initial_Balance);   
    }

    function testmyEnterRaffle() external  {

        uint256 assumedWinnerStartingBalance  = address(6).balance;
        console.log("winner starting balance:", assumedWinnerStartingBalance);
        //fund Raffle

        for (uint256 i = 1; i < 10; i++) {
            hoax(address(uint160(i)), initial_Balance);
            raffle.enterRaffle{value: 4 ether }();
        }

        console.log("raffle balance:", address(raffle).balance);

        //change timestamp and blockNumber 
        vm.warp(block.timestamp + s_intervals);
        vm.roll(block.number + 1);

        // fetch requestId
        vm.recordLogs();
         raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        

        //call fulfillRandomWords
        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));

        
        uint256 assumedWinnerEndingBalance = address(6).balance;
        uint256 totalDeposit = 4 ether * 9;
        uint256 expectedBalance = initial_Balance - 4 ether + totalDeposit;

        console.log("winner ending balance:", assumedWinnerEndingBalance);
        console.log("recent winner Balance:", raffle.getRecentWinner().balance);
        console.log("recent winner :", raffle.getRecentWinner());
        console.log("assumed winner:", address(6));
        // assert
        assertEq(assumedWinnerEndingBalance , expectedBalance);
        assertEq(uint256(raffle.getRaffleState()),0);
        assertEq(address(raffle).balance,0);
        assert(raffle.getRecentWinner() != address(0));
        assertEq(block.timestamp,raffle.getLastTimeStamp());
    }
}
