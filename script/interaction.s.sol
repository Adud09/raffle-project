// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, ConstantFigs} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mockFile/linkToken.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";


contract createSubscriptions is Script{


    
    function createSubscription() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        address s_vrfCoordinator = config.s_vrfCoordinator;
        createSubscription(s_vrfCoordinator,config.account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256 ) {  
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        return (subId);
    }
}

contract fundSubscription is Script , ConstantFigs {

    function fundSubscriptions()  public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        address s_vrfCoordinator = config.s_vrfCoordinator;
        uint256 s_subscriptionId = config.s_subscriptionId;
        address LINK = config.LINK;
        fundSubscriptions(s_vrfCoordinator,s_subscriptionId,LINK,config.account);
    }

    function fundSubscriptions(address _vrfCoordinator, uint256 _subscriptionId, address _LINK, address account) public {
        console.log("Subscription ID:", _subscriptionId);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, 1000 ether);
            vm.stopBroadcast();
        }
        else{

            console.log("Please fund your subscription with LINK tokens on the respective chain using the following details:");
            console.log("Subscription ID:", _subscriptionId);
            console.log("VRF Coordinator:", _vrfCoordinator);
            console.log("LINK Token Address:", _LINK);

            vm.startBroadcast(account);
            LinkToken links = LinkToken(_LINK);
            links.transferAndCall(_vrfCoordinator,3e18,abi.encode(_subscriptionId));
            vm.stopBroadcast();

        }
    }

} 


contract addConsumers is Script {

    function addConsumer(address mydeployContract) external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        address s_vrfCoordinator = config.s_vrfCoordinator;
        uint256 s_subscriptionId = config.s_subscriptionId;
        addConsumer(s_vrfCoordinator,s_subscriptionId,mydeployContract,config.account);

    }

    function addConsumer(address s_vrfCoordinator,uint256 s_subscriptionId, address raffle, address account ) public {
        console.log ("Adding consumer: ", raffle);
        console.log ("To VRF Coordinator: ", s_vrfCoordinator);
        console.log ("On chainId:", block.chainid); 
        console.log("Subscription ID:", s_subscriptionId);
        
        
        
        vm.startBroadcast(account);
        VRFCoordinatorV2_5(s_vrfCoordinator).addConsumer(s_subscriptionId, raffle);
        vm.stopBroadcast();
    }
}

