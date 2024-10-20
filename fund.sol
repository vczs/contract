// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Fund{
    // 合约投资者支付金额
    mapping(address => uint256) public fundAmount;

    // 合约收款
    function fund() external payable {
        fundAmount[msg.sender] = msg.value;
    } 
}