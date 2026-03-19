// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


/*
██████╗  █████╗ ███████╗███████╗██╗     ███████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝██║     ██╔════╝
██████╔╝███████║█████╗  █████╗  ██║     █████╗
██╔══██╗██╔══██║██╔══╝  ██╔══╝  ██║     ██╔══╝
██║  ██║██║  ██║██║     ██║     ███████╗███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚══════╝

Unit tests for the Raffle Contract
Testing randomness, fairness, and chaos.
*/

import {Test,console} from "forge-std/Test.sol";
import {DeployRaffles} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleUnit is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 s_minimumEntranceFee;
    uint256 s_intervals;
    bytes32 s_keyHash;
    uint256 s_subscriptionId;
    address s_vrfCoordinator;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 initial_balace = 20 ether;

    function setUp() external  {
        DeployRaffles deployer = new DeployRaffles();
        (raffle,helperConfig) = deployer.deploycontract();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        s_minimumEntranceFee = config.s_minimumEntranceFee;
        s_intervals =  config.s_intervals;
        s_keyHash = config.s_keyHash;
        s_subscriptionId = config.s_subscriptionId;
        s_vrfCoordinator = config.s_vrfCoordinator;
        vm.deal(alice,initial_balace);
    }

    /**/////////////////////////////////////////////////////////////
    /*            STATE   VARIABLE     RAFFLE  TESTS               */
    /////////////////////////////////////////////////////////////**/

    function testIntervals() public view {
        assertEq(raffle.getIntervals(), 30);
    }

    function testRaffleState() public view {
        
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /**/////////////////////////////////////////////////////////////
    /*                     ENTER RAFFLE                            */ 
    /////////////////////////////////////////////////////////////**/

    event enterRaffleFunded(address indexed, uint256);

    function testEnterRaffleFails() external {
        vm.prank(alice);
        vm.expectRevert(Raffle.increaseStakeAmount.selector);
        raffle.enterRaffle{value: 0}();
    }

    function testEnterRaffleSuccessFully() external{
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        assertEq(address(raffle).balance,initial_balace);
    }

    function testSingleFunderAddedArray() external {
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        assertEq(raffle.getFunder(0), alice);
    }

    function testMultipleFunderAddedArray() external {

        uint256 totalDeposit;
        for (uint256 index = 1; index < 10; index++ ){
            hoax(address(uint160(index)),initial_balace);
            raffle.enterRaffle{value:initial_balace}();
            totalDeposit += initial_balace;
        }

        assertEq(address(raffle).balance,totalDeposit);
        assertEq(raffle.getFunder(8), address(9));
    }


    function testExpectEmit() external {
        vm.prank(alice);
        vm.expectEmit (true,false,false,true,address(raffle));
        emit enterRaffleFunded(alice,initial_balace);
        raffle.enterRaffle{value:initial_balace}();
    }



    /**/////////////////////////////////////////////////////////////
    /*                     CHECK UPKEEP                           */ 
    /////////////////////////////////////////////////////////////**/

    function testCheckUpkeepToBeFalse() external {
        //Arrange 
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();

        //Act
        (bool needsUpkeep,) = raffle.checkUpkeep("");

        //Assert
        assertFalse(needsUpkeep);

    }

    function testCheckUpkeepToBeTrue() external {
        //Arrange 
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        vm.warp(block.timestamp + s_intervals + 1  );
        vm.roll(block.number + 1);
        

        //Act
        (bool needsUpkeep,) = raffle.checkUpkeep("");

        //Assert
        assert(needsUpkeep == true);

    }


    /**/////////////////////////////////////////////////////////////
    /*                     PERFORM UPKEEP                         */ 
    /////////////////////////////////////////////////////////////**/

    function testPerformUpkeepRevert() external {
        //Arrange 
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        vm.expectRevert( abi.encodeWithSelector(Raffle.performUpkeepNotOpen.selector, address(raffle).balance,s_intervals, raffle.getFunderLength(), raffle.getRaffleState()));
        raffle.performUpkeep("");

    }

    function testPerformUpkeepPass() external {
        //Arrange
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        vm.warp(block.timestamp + s_intervals + 1  );
        vm.roll(block.number + 1); 

        // Act
        raffle.performUpkeep("");
    }


    function testGetrequestId() external {
               //Arrange
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        vm.warp(block.timestamp + s_intervals + 1  );
        vm.roll(block.number + 1); 

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 RequestId = entries[1].topics[0];
        uint256 RaffleState = uint256(raffle.getRaffleState());
        console.log("requestId: ", uint256(RequestId));

        //Assert
        assert(uint256(RequestId) > 0);
        assertEq(RaffleState, 1);

    }



    /**/////////////////////////////////////////////////////////////
    /*                     FULFILLRANDOMNESS                      */ 
    /////////////////////////////////////////////////////////////**/


    modifier skipForkedChain() {
        if (block.chainid != 31337 ){
            return;
        }

        _;
    }


    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public skipForkedChain {
        
        //Arrange
        vm.prank(alice);
        raffle.enterRaffle{value:initial_balace}();
        vm.warp(block.timestamp + s_intervals + 1  );
        vm.roll(block.number + 1); 


        
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
    }

    function testFullfillRandomWordsPicksWinnerAndResets() public skipForkedChain {

        uint256 runTime = 4;
        address assumedWinner = address(3);

        for (uint256 index = 1; index < runTime; index++ ){

            hoax(address(uint160(index)),initial_balace);
            raffle.enterRaffle{value:initial_balace}();

        }

        vm.warp(block.timestamp + s_intervals + 1  );
        vm.roll(block.number + 1); 

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        uint256 requestIdUint = uint256(requestId);

        console.log("requestId: ", uint256(requestIdUint));
        console.log("RaffleState: ", uint256(raffle.getRaffleState()));
        console.log("recentWinner: ", raffle.getRecentWinner());

        address emptyWinnerAddress = raffle.getRecentWinner();
        uint256 lastTimeStamp = raffle.getLastTimeStamp();
        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fulfillRandomWords( requestIdUint, address(raffle));

        console.log("requestId: ", uint256(requestIdUint));
        console.log("RaffleState: ", uint256(raffle.getRaffleState()));
        console.log("recentWinner: ", raffle.getRecentWinner());


        uint256 newRaffleState = uint256(raffle.getRaffleState());
        address newEmptyWinnerAddress = raffle.getRecentWinner();
        uint256 newFundersLength = raffle.getFunderLength();
        uint256 newlastTimeStamp = raffle.getLastTimeStamp();

        //Assert
        assertEq(newRaffleState, 0);
        assert(newEmptyWinnerAddress != emptyWinnerAddress);
        assertEq(newFundersLength, 0);
        assert(newlastTimeStamp > lastTimeStamp);
        assertEq(assumedWinner.balance, 60 ether);
  
        
    }
}


