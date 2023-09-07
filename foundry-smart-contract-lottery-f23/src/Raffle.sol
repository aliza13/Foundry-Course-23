// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A sample Raffle Contract
 * @author Aliza Camero
 * @notice This contract is for creating a sample raffle
 * Implements Chainlink VRFv2
 */

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
// internal & private view & pure functions
// external & public view & pure functions

contract Raffle is VRFConsumerBaseV2 {

    error Raffle__NotEnoughEthSent(); // contractName__CustomError
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState // or can do RaffleState raffleState
    );

    /** Type Declarations */
    enum RaffleState { // can be directly converted to a uint256
        OPEN, // 0
        CALCULATING // 1
        // if more then 2, 3 etc
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; 
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;

    address payable[] private s_players; // # of players going to change
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;


    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gas_lane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
        ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator); // new type
        i_gasLane = gas_lane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable { // ex instead of payable, more gas eff, 
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!"); // bruh not gas eff
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent(); 
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender)); // push player addy to array, storage update
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the CL Automation nodes call
     * to see if it's time to perform an upkeep.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in open state
     * 3. The contract has ETH (aka players)
     * 4. (Implicit) The subscription is funded w LINK
     */

    function checkUpkeep(
        bytes memory /* checkdata */
    ) public view returns(bool upkeepNeeded, bytes memory /* performData */) {
        // upkeepNeeded = true -> wil automatically return true w out explicitly returning
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); 
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }


    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
    // get rand num, use rand num to pick a player, automatically called
    // function pickWinner() external {
        // enough time has passed? 1200 seconds - 500 = 700
        // if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        //     revert();
        // }
        s_raffleState = RaffleState.CALCULATING;
        // request the RNG chainlink node, get rand num, response
        // uint256 requestId = i_vrfCoordinator.requestRandomWords(
        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId, 
            REQUEST_CONFIRMATIONS, // num of block confirmations
            i_callBackGasLimit,
            NUM_WORDS // num of rand nums
        );
    }

    function fulfillRandomWords (
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override{ // this func exists in our inheritance 
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable [] (0); // so the same players don't get in new raffle for free
        s_lastTimeStamp = block.timestamp; 

        emit PickedWinner(winner);

        (bool success,) = winner.call{value: address(this).balance}(""); // blank bytes for the object
        if (!success) {
            revert Raffle__TransferFailed(); 
        }
    } 

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}