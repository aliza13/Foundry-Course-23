// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol"; // has console.log, StdCheatsSafe etc
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11166111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        return 
            NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            subscriptionId: 1893, // update w our subId
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getOrCreateAnvilEthConfig() 
        public 
        returns (NetworkConfig memory anvilNetworkConfig) 
    {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast(//DEFAULT_ANVIL_PRIVATE_KEY
        );
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            // uint96 baseFee = 0.25 ether; // link
            // uint96 gasPriceLink = 1e9; // 1 gwei of link
            baseFee,
            gasPriceLink
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            subscriptionId: 0, // our script will add this
            callbackGasLimit: 500000,
            link: address(link)

        });
    }
}