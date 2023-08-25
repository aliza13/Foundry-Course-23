// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    
    function run() external returns (FundMe, HelperConfig) {
        // before startBroadcast -> not a real tx so not a real tx
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();
        // address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // since ethUsdPriceFeed is a struct use () if more than one addy


        // after startB -> real tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed); // Sepolia forked chain
        vm.stopBroadcast();
        return (fundMe, helperConfig);
    }

}