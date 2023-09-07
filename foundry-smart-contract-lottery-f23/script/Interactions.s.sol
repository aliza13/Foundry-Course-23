// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script{
    function CreateSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinatorV2, , , ) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
        ) public returns (uint64) {
            console.log("Creating Subscription on chainID: ", block.chainid);
            vm.startBroadcast();
            uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
                .createSubscription();
            vm.stopBroadcast();
            console.log("Your sub Id is: ", subId);
            console.log("Pls update subId in Helpconfig.s.sol");
            return subId;
        } 

    function run() external returns(uint64) {
        return createSubscriptionUsingConfig();
    }

}

contract Fundsubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundsubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinatorV2, , uint64 subId, , address link ) = helperConfig
        .activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, link);
    }

    funciton fundSubscription(address vrfCoordinator, uint64 subId, address link) public {
        console.log("Funding subscription", subId);
        console.log("Using vrfcoordinator", vrfCoordinator);
        console.log("On chainID:", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator, 
                FUND_AMOUNT, 
                abi.enconde(subId)
            );
            vm.stopBroadcast();
        }

    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    funciton addConsumer(
        address raffle,
        address vrfCoordinator,
        uint64 subId
    ) public {
        console.log("adding consumer contract: ", raffle);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new Helpconfig();
        (, , address vrfCoordinator, , uint64 subId, , ) = helperConfig.activeNetworkConfig();
        AddConsumer(raffle, vrfCoordinator, subId);
    }

    function run() external {
            address raffle = DevOpsTools.get_most_recent_deployment(
                "Raffle",
                block.chainid
            );
            addConsumerUsingConfig(raffle);
        }
}