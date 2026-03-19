// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mockFile/linkToken.sol";
abstract contract ConstantFigs {
    uint96 constant base_fee = 0.25 ether;
    uint96 constant gas_price = 1e9;
    int256 constant  wei_per_unit_link = 4e15;

    uint256 constant SEPOLIA_NET = 11155111;
    uint256 constant LOCAL_NET = 31337;
}

contract HelperConfig is Script, ConstantFigs {

    struct networkConfig {
        uint256 s_minimumEntranceFee;
        uint256 s_intervals;
        bytes32 s_keyHash;
        uint256 s_subscriptionId;
        address s_vrfCoordinator;
        address LINK;
        address account;
    }

    mapping (uint256  => networkConfig) networkWrap;
    networkConfig public localNetworkConfig;

    constructor () {
        networkWrap[SEPOLIA_NET] = getSepoliaConfig();
        networkWrap[LOCAL_NET] = getLocalNetworkConfig();
        
        
    }

    function getConfig() external view  returns (networkConfig memory) {
        if (block.chainid == SEPOLIA_NET) {
            return networkWrap[SEPOLIA_NET];
        }
        else if (block.chainid == LOCAL_NET) {
            return localNetworkConfig;
        } 
        else {
            revert();
        }
    }
  
    function getSepoliaConfig() public pure returns (networkConfig memory) {
        return networkConfig({
            s_minimumEntranceFee: 0.01 ether,
            s_intervals: 30,
            s_keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            s_subscriptionId:71054312457942208389295611335860611689978471849436258283686763140007530032606,
            s_vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            LINK:0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account:0x6394c9d96Af8dd3b7d3DB94c43D3513591828252
        });
    }

    function getLocalNetworkConfig() public returns (networkConfig memory) {

        if (localNetworkConfig.s_vrfCoordinator != address(0)) {
            return networkWrap[LOCAL_NET];
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock s_vrfCoordinator = new VRFCoordinatorV2_5Mock(base_fee,gas_price,wei_per_unit_link);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = networkConfig({
            s_minimumEntranceFee: 0.01 ether,
            s_intervals: 30,
            s_keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            s_subscriptionId: 0,
            s_vrfCoordinator: address(s_vrfCoordinator),
            LINK: address(link),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return localNetworkConfig;

    }
}
