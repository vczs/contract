// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract DutchAuction {
    bool public complete = false;
    uint private constant DURATION = 7 days;

    address payable public immutable seller;
    uint public immutable startAt;
    uint public immutable expiresAt;
    uint public immutable startingPrice;
    uint public immutable discountRate;

    IERC721 public immutable nft;
    uint public immutable nftId;

    _constructor(uint _startingPrice,uint _discountRate, address _nft,uint _nftId) {
        require(_startingPrice >= _discountRate * DURATION, "starting price < min");

        seller = payable(msg.sender);
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        startingPrice = _startingPrice;
        discountRate = _discountRate;

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view notComplete returns (uint) {
        return startingPrice - discountRate * (block.timestamp - startAt);
    }

    function buy() external payable notComplete{
        require(block.timestamp < expiresAt, "auction expired");

        uint price = getPrice();
        require(msg.value >= price, "ETH < price");

        nft.transferFrom(seller, msg.sender, nftId);

        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        complete = true;
    }

    modifier notComplete() {
        require(!complete, "Auction already complete");_;
    }
}
