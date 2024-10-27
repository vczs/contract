// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Fund{
    // 外部合约:喂价数据
    AggregatorV3Interface internal dataFeed;

    // 合约所有者
    address public CONTRACT_OWNER;

    // 合约投资者支付金额
    mapping(address => uint256) public fundAmount;
    // 合约融资目标
    uint256 constant private CONTRACT_TARGET_USD_AMOUNT = 30;
    // 投资最小金额(USD)
    uint256 constant private FUND_MIN_USD_AMOUNT = 10;

    // 合约构造函数
    constructor() {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        CONTRACT_OWNER = msg.sender;
    }

    //**********************************************************************//
    // 合约投资
    function fund() external payable {
        require(fundAmount[msg.sender] == 0, "you have fund~");
        require(ethToUsd(msg.value) >= FUND_MIN_USD_AMOUNT, "send more eth~");
        fundAmount[msg.sender] = msg.value;
    }
    // 合约退款
    function refund() external {
        require(ethToUsd(address(this).balance) < CONTRACT_TARGET_USD_AMOUNT,"target is reached~");
        require(fundAmount[msg.sender] != 0, "there is no fund for you~");
        bool success;
        (success, )=payable(msg.sender).call{value: fundAmount[msg.sender]}("");
        require(success,"refund transfer failed~");
        fundAmount[msg.sender] = 0;
    }
    // 合约提款
    function drawFund() external {
        require(ethToUsd(address(this).balance) >= CONTRACT_TARGET_USD_AMOUNT, "target is not reached~");
        
        bool success;
        (success, )= payable(msg.sender).call{value: address(this).balance}("");
        require(success,"draw transfer failed~");
        fundAmount[msg.sender] = 0;
    }
    // 更换合约所有者
    function transferContractOwner(address owner) external {
        require(msg.sender == CONTRACT_OWNER,"you not is contract owner~");
        CONTRACT_OWNER = owner;
    }
    //**********************************************************************//

    // eth转usd
    function ethToUsd(uint256 weiAmount) internal view returns(uint256) {
        uint256 price = uint256(getChainlinkDataFeedLatestAnswer());
        return price * weiAmount / (10 ** 26); 
    }

    // 获取最新ETH/USD价格数据
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        ( ,int answer, , ,) = dataFeed.latestRoundData();
        return answer;
    }
}