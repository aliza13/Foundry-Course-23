// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";

contract randomScript is Script {
    function run() public {
        vm.startBroadcast(); // just starting/stopping & run script gas = 24394
        console.log("Hey"); // gas used = 27521
        // console.log(string("Hey")) // gas used = 27521
        vm.stopBroadcast();
    }
}