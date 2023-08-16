// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external { // setup always runs first
        fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); 
    }

    function testMin$Is5() public {
        // console.log("heyo");
        assertEq(fundMe.MINIMUM_USD(), 5e18); 
        // assertEq(fundMe.MINIMUM_USD(), 6e18); // will fail but if 5e18 will work
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.owner()); not the same as below diff addys
        // console.log(msg.sender);
        assertEq(fundMe.owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}