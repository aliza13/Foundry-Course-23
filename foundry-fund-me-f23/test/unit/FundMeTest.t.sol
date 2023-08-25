// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";


contract FundMeTest is StdCheats, Test {
    FundMe fundMe;
    HelperConfig public helperConfig;

    // address USER = makeAddr("user"); // can't be a constant bcuz something abt compile time constant
    uint256 constant SEND_VALUE = 0.1 ether; // decimals don't work in sol but this does
    uint256 constant STARTING_USER_BALANCE = 10 ether; 
    uint256 constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external { // setup always runs first
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); 
        DeployFundMe deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.run();
        vm.deal(USER, STARTING_USER_BALANCE); // deal cheatcode to give $ to addy to run tests
    }

    // function testMin$Is5() public {
    //     // console.log("heyo");
    //     assertEq(fundMe.MINIMUM_USD(), 5e18); 
    //     // assertEq(fundMe.MINIMUM_USD(), 6e18); // will fail but if 5e18 will work
    // }

    // function testOwnerIsMsgSender() public {
    //     // console.log(fundMe.owner()); not the same as below diff addys
    //     // console.log(msg.sender);
    //     assertEq(fundMe.getOwner(), msg.sender);
    // }

    // function testPriceFeedVersionIsAccurate() public {
    //     uint256 version = fundMe.getVersion();
    //     assertEq(version, 4);
    // }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // next line reverts if next line fails
        fundMe.fund(); // sends 0 value so fails and test passes
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // making sure its over 10 eth, value is at $5
        // uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this)); // a(t) instead of msg.sender
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); 

        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER); // that funder == USER
    }

    modifier funded() {
        // so we don't have to type this every time in our tests
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // would use next two lines if no modifier funded
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();
        // vm.prank(USER); 

        vm.expectRevert(); // ignores vm lines tho
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        // uint256 gasStart = gasleft(); // built in sol func
        // vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft(); 
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);
        vm.stopPrank();

        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
            ); // should = end owner bal
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // start at 1, cuz 0 addy can revert
            // vm.prank new addy
            // vm.deal new addy
            // or use hoax bcuz it does prank and deal combined
            // hoax (<some addy>, SEND_VALUE);
            // address has to be uint160(same bytes in address)
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        // assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); // calling cheaper func
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        // assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}