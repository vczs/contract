// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Transfer {
    constructor() payable {}

    fallback() external {}

    function testTransfer(address payable ads) external payable  {
        ads.transfer(100);
    }

    function testSend(address payable ads) external payable  {
        bool ok = ads.send(100);
        require(ok,"send failed");
    }

    function testCall(address payable ads) external payable  {
      (bool ok,) = ads.call{value: 100, gas: 10000}("");
       require(ok,"send failed");
    }
}
