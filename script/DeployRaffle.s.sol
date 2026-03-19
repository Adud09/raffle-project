// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {createSubscriptions,fundSubscription,addConsumers} from "script/interaction.s.sol";

contract DeployRaffles is Script {

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 s_minimumEntranceFee;
    uint256 s_intervals;
    bytes32 s_keyHash;
    uint256 s_subscriptionId;
    address s_vrfCoordinator;
    address LINK;

    function run() external returns (Raffle,HelperConfig) {
        deploycontract();
        return (raffle,helperConfig);

    }

    function deploycontract() public  returns (Raffle,HelperConfig){
        helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        s_minimumEntranceFee = config.s_minimumEntranceFee;
        s_intervals = config.s_intervals;
        s_keyHash = config.s_keyHash;
        s_subscriptionId = config.s_subscriptionId;
        s_vrfCoordinator = config.s_vrfCoordinator;
        LINK = config.LINK;

        if (s_subscriptionId == 0) {

            createSubscriptions createSub = new createSubscriptions();
            s_subscriptionId = createSub.createSubscription(s_vrfCoordinator,config.account);

            fundSubscription fundSub = new fundSubscription();
            fundSub.fundSubscriptions(s_vrfCoordinator,s_subscriptionId,LINK,config.account);
        }
        

        vm.startBroadcast(config.account);
        raffle = new Raffle(s_minimumEntranceFee,s_intervals,s_keyHash,s_subscriptionId,s_vrfCoordinator);
        vm.stopBroadcast();

        addConsumers addUser = new addConsumers();
        addUser.addConsumer(s_vrfCoordinator,s_subscriptionId,address(raffle),config.account);

        return (raffle,helperConfig);
    }
}