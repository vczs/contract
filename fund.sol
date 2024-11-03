// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Fund{
    // 外部合约:喂价数据
    AggregatorV3Interface internal dataFeed;

    // 合约所有者
    address public CONTRACT_OWNER;

    // 合约融资目标
    uint256 constant private CONTRACT_TARGET_USD_AMOUNT = 30;
    // 投资最小金额(USD)
    uint256 constant private FUND_MIN_USD_AMOUNT = 10;
    // 合约投资者支付金额
    mapping(address => uint256) public fundAmount;

    // 合约生效时间(部署时间)
    uint256 private FUND_EXEC_TIMESTAMP;
    // 合约关闭时间
    uint256 private FUND_CLOSE_TIMESTAMP;

    // 合约构造函数
    constructor(uint256 deployMentTime) {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        CONTRACT_OWNER = msg.sender;
        FUND_EXEC_TIMESTAMP = block.timestamp;
        FUND_CLOSE_TIMESTAMP = FUND_EXEC_TIMESTAMP + deployMentTime;
    }

    //**********************************************************************//
    // 合约投资
    function fund() external payable fundIsExec{
        require(fundAmount[msg.sender] == 0, "you have fund~");
        require(ethToUsd(msg.value) >= FUND_MIN_USD_AMOUNT, "send more eth~");
        fundAmount[msg.sender] = msg.value;
    }
    // 合约退款
    function refund() external fundIsClose {
        require(ethToUsd(address(this).balance) < CONTRACT_TARGET_USD_AMOUNT,"target is reached~");
        require(fundAmount[msg.sender] != 0, "there is no fund for you~");
        fundAmount[msg.sender] = 0; // 先将余额置零，防止重入攻击
        bool success;
        (success, )=payable(msg.sender).call{value: fundAmount[msg.sender]}("");
        require(success,"refund transfer failed~");
    }
    // 合约提款
    function drawFund() external fundIsClose onlyOWner{
        require(ethToUsd(address(this).balance) >= CONTRACT_TARGET_USD_AMOUNT, "target is not reached~");
        
        bool success;
        (success, )= payable(msg.sender).call{value: address(this).balance}("");
        require(success,"draw transfer failed~");
        fundAmount[msg.sender] = 0;
    }
    // 更换合约所有者
    function transferContractOwner(address owner) external onlyOWner{
        CONTRACT_OWNER = owner;
    }
    //**********************************************************************//

    // 获取最新ETH/USD价格数据
    function getChainlinkDataFeedLatestAnswer() private view returns (int) {
        ( ,int answer, , ,) = dataFeed.latestRoundData();
        return answer;
    }
    // eth转usd
    function ethToUsd(uint256 weiAmount) internal view returns(uint256) {
        uint256 price = uint256(getChainlinkDataFeedLatestAnswer());
        return price * weiAmount / (10 ** 26); 
    }

    // 合约在执行
    modifier fundIsExec(){
        require(block.timestamp < FUND_CLOSE_TIMESTAMP,"fund is close~");
        _;
    }
    // 合约已关闭
    modifier fundIsClose(){
        require(block.timestamp >= FUND_CLOSE_TIMESTAMP,"fund is exec~");
        _;
    }
    // 仅允许合约所有者调用
    modifier onlyOWner(){
       require(msg.sender == CONTRACT_OWNER,"you not is contract owner~");
        _;
    }
}