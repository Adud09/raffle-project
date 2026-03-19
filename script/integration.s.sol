// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DeployRaffles} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";


contract fundRafles is Script{
    Raffle raffle;
    function enterRaffle(address _raffle, address realCaller) external payable {
        raffle = Raffle(_raffle);  
        vm.startBroadcast(realCaller);
        Raffle(_raffle).enterRaffle{value: msg.value}();
        vm.stopBroadcast();
    }
}