// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Daniel Adu
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

 
contract Raffle is VRFConsumerBaseV2Plus {
    error increaseStakeAmount();
    error raffleCalculating();
    error performUpkeepNotOpen(uint256, uint256, uint256, uint256);
    error rewardTransferFails();
    // Enum

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //state variable
    uint256 immutable i_minimumEntranceFee;
    uint256 immutable i_intervals;
    bytes32 immutable i_keyHash;
    uint256 immutable i_subscriptionId;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant CALLBACK_GAS_LIMIT =  500000;
    uint32 constant NUM_WORDS = 1;
    uint256  s_requestId;
    uint256 s_randomWords;
    address  s_recentWinner;

    uint256 private s_lastTimeStamp;
    RaffleState private raffleState;
    address[]  public s_funders;

    // Event
    event enterRaffleFunded(address indexed, uint256);
    event winnerAndAmountWon(address indexed, uint256);
    event requestIdAdded(uint256 indexed);

    // Functions

    constructor(
        uint256 _minimumEntranceFee,
        uint256 _intervals,
        bytes32 keyhash,
        uint256 subscriptionId,
        address s_vrfCoordinator
    ) VRFConsumerBaseV2Plus(s_vrfCoordinator) {
        i_minimumEntranceFee = _minimumEntranceFee;
        i_intervals = _intervals;
        i_keyHash = keyhash;
        i_subscriptionId = subscriptionId;
        raffleState = RaffleState.OPEN;
        s_lastTimeStamp = uint56(block.timestamp);
    }

    function enterRaffle() external payable {

        if (raffleState != RaffleState.OPEN) {
            revert raffleCalculating();
        }

        if (msg.value < i_minimumEntranceFee) {
            revert increaseStakeAmount();
        }
        s_funders.push(msg.sender);
        emit enterRaffleFunded(msg.sender, msg.value);
    }



       /**
     * @dev This is the function that the Chainlink  nodes call to see
     * if the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription is funded with LINK.
     * @param - ignored
     * @return upkeepNeeded - true if the lottery should pick a winner, false otherwise.
     * @return - ignored
     */

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        returns (bool, bytes memory)
    {
        bool balance = address(this).balance > 0;
        bool intervals = (block.timestamp - s_lastTimeStamp) >= i_intervals;
        bool arrayCheck = s_funders.length > 0;
        bool raffleIsOpen = raffleState == RaffleState.OPEN;
        bool needsUpkeep = balance && intervals && arrayCheck && raffleIsOpen;
        return (needsUpkeep, "");
    }

    function performUpkeep(
        bytes calldata /*performData*/
    )
        external
    {
        (bool needsUpkeep,) = checkUpkeep("");
        if (!needsUpkeep) {
            revert performUpkeepNotOpen(address(this).balance, i_intervals, s_funders.length, uint256(raffleState));
        }

        raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        s_requestId = s_vrfCoordinator.requestRandomWords(req);
        emit requestIdAdded(s_requestId);

        
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] calldata randomWords
    ) internal override {
        s_randomWords = randomWords[0];
        uint256 numWinner = s_randomWords % s_funders.length;
        address  winner = s_funders[numWinner];
        s_recentWinner = winner;
        s_funders = new address[](0);
        s_lastTimeStamp = block.timestamp;
        raffleState = RaffleState.OPEN;
        emit winnerAndAmountWon(winner, address(this).balance);

        ( bool success, ) = payable(winner).call{value: address(this).balance}("");
        if (!success) {
            revert rewardTransferFails();
        }


    }

    /**
    getter Functions 
     */

    function getIntervals() external view returns (uint256) {
        return i_intervals;
    }

    function getRaffleState() external view returns (RaffleState) {
        return raffleState;
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getFunderLength() external view returns (uint256) {
        return s_funders.length;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}

