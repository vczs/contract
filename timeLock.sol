// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TimeLock {
    event Queue(address indexed caller, address target,  bytes32 txId, uint256 value, bytes data, uint256 timestamp);
    event Execute(address indexed caller, address target, bytes32 txId, uint256 value, bytes data, uint256 timestamp);
    event Cancel(address indexed caller, bytes32 txId);

    address public owner;
    uint256 private constant delayTime = 60;
    uint256 private constant execTime = 600;

    struct Transaction {
        address target;
        uint value;
        bytes data;
        uint256 timestamp;
        bool execute;
        bool cancel;
    }
    mapping(address => mapping(bytes32 => Transaction)) private callerTxIdTx;
    mapping(address => bytes32[]) private callerTxIds;
    mapping(bytes32 => address) private txIdCaller;

    constructor() {owner = msg.sender;}

    receive() external payable {}

    function queue(address _target, uint256 _value, bytes calldata _data) external returns(bytes32) {
        require(_target != address(0),"invalid target address");

        uint256 blockTimestamp = block.timestamp;
        bytes32 txId = _getHash(_target, _value, _data, blockTimestamp);
        require(callerTxIdTx[msg.sender][txId].target == address(0),"tx already exist");
    
        callerTxIdTx[msg.sender][txId] = (Transaction({target: _target, value: _value, data: _data, timestamp: blockTimestamp, execute: false, cancel: false}));
        callerTxIds[msg.sender].push(txId);
        txIdCaller[txId] = msg.sender;
        emit Queue(msg.sender, _target, txId, _value, _data, blockTimestamp);

        return txId;
    }

    function execute(bytes32 _txId) external payable returns (bytes memory) {
        Transaction storage transaction = callerTxIdTx[msg.sender][_txId];
        require(transaction.target != address(0),"tx not exist queued");
        require(!transaction.execute && !transaction.cancel,"tx already exec or already cancel");

        uint256 blockTimestamp = block.timestamp;
        require(transaction.timestamp + delayTime < blockTimestamp && blockTimestamp < transaction.timestamp + execTime , "not in exec time range");

        (bool success, bytes memory data) = transaction.target.call{value: transaction.value}(transaction.data);
        require(success,"tx exec failed");

        transaction.execute = true;
        emit Execute(msg.sender, transaction.target, _txId, transaction.value, transaction.data, blockTimestamp);

        return data;
    }

    function cancle(bytes32 _txId) external {
        require(msg.sender == owner, "not owner");

        Transaction storage transaction = callerTxIdTx[txIdCaller[_txId]][_txId];
        require(transaction.target != address(0),"tx not exist queued");
        require(!transaction.execute && !transaction.cancel,"tx already exec or already cancel");

        transaction.cancel = true;
        emit Cancel(msg.sender, _txId);
    }

    function getTransaction(address _caller, bytes32 _txId) external view returns (address, uint, bytes memory, uint256, bool, bool) {
        Transaction memory transaction = callerTxIdTx[_caller][_txId];
        require(transaction.target != address(0),"tx not exist queued");
        return (transaction.target,transaction.value,transaction.data,transaction.timestamp,transaction.execute,transaction.cancel);
    }

    function getTxIds(address caller) external view returns (bytes32[] memory) {
        return callerTxIds[caller];
    }

    function getFuncData(string calldata funcSignature, bytes calldata encodedArgs) external pure returns (bytes memory) {
        return abi.encodePacked(bytes4(keccak256(bytes(funcSignature))), encodedArgs);
    }

    function _getHash(address _target,uint256 _value,bytes calldata _data,uint256 _timestamp) private pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _data, _timestamp));
    }
}

contract TestTimeLock {
    address immutable timeLock;

    uint public status = 1;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    function test() external returns (uint256, uint256) {
        require(msg.sender == timeLock,"access denied");
        status = 2;
        return (66, block.timestamp);
    }
}
