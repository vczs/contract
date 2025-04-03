// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function safeTransferFrom(address,address,uint) external;
    function transferFrom(address,address,uint) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;

    address payable public seller;

    uint public status = 1; // 1未开始 2进行中 3结束
    uint public endAt;

    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;

    constructor(address _nft,uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(status == 1, "already start");
        require(msg.sender == seller, "you not seller");

        status = 2;
        endAt = block.timestamp + 7 days;

        nft.transferFrom(msg.sender, address(this), nftId);

        emit Start();
    }

    function bid() external payable {
        require(status == 2, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        highestBid = msg.value;
        highestBidder = msg.sender;

        bids[highestBidder] += highestBid;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        require(block.timestamp >= endAt && status == 3, "not ended");

        uint bal = bids[msg.sender];
        require(bal > 0, "not bids");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function receiveNft() external {
        require(block.timestamp >= endAt && status == 3, "not ended");

        status = 3;

        if (highestBidder == address(0)) {
            nft.safeTransferFrom(address(this), seller, nftId);
            return;
        }

        nft.safeTransferFrom(address(this), highestBidder, nftId);
        seller.transfer(highestBid);

        emit End(highestBidder, highestBid);
    }
}
