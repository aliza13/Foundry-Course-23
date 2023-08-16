// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5 *1e18; 
    address[] public funders;
    mapping(address => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender; 
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // function fund() public payable {
    //     require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enuff");
    //     funders.push(msg.sender); 
    //     addressToAmountFunded[msg.sender] += msg.value;

    // }
    
    function withdraw() public onlyOwner {

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); 

        payable(msg.sender).transfer(address(this).balance);  

        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed");

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed"); 

    }

    modifier onlyOwner() {
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); } 
        _; 
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int256 price,,,) = priceFeed.latestRoundData(); 
        return uint256(price) * 1e10;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
}