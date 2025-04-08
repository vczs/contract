// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TimeLock {
    event Queue(address indexed caller, bytes32 txId);
    event Exec(address indexed caller, bytes32 txId, bytes data);
    event Cancel(address indexed caller, bytes32 txId);

    address public owner;
    uint256 private constant delayTime = 60;

    enum TxStatus {None, Queued, Executed, Canceled} // 0未定义 1已排队 2已执行 3已取消
    struct Transaction {
        address owner;
        address target;
        uint value;
        bytes data;
        uint256 scheduleTime;
        uint256 unlockTime;
        TxStatus status; 
    }
    mapping(bytes32 => Transaction) private txs;
    mapping(address => bytes32[]) private callerTxIds;

    constructor() {owner = msg.sender;}

    receive() external payable {}

    function queue(address _target, uint256 _value, bytes calldata _data, uint256 _scheduleTime) external  {
        require(_target != address(0),"invalid target address");
        require(_scheduleTime >= block.timestamp, "schedule time must be in future");

        bytes32 txId = _getHash(msg.sender, _target, _value, _data, _scheduleTime);
        require(txs[txId].status == TxStatus.None,"tx already exist");
    
        txs[txId] = (Transaction({owner: msg.sender, target: _target, value: _value, data: _data, scheduleTime: _scheduleTime, unlockTime: _scheduleTime + delayTime, status: TxStatus.Queued}));
        callerTxIds[msg.sender].push(txId);

        emit Queue(msg.sender, txId);
    }

    function execute(bytes32 _txId) external payable{
        Transaction storage transaction = txs[_txId];
        require(msg.sender == owner || msg.sender == transaction.owner, "access denied");
        require(transaction.status == TxStatus.Queued,"tx status not queue");
        require(block.timestamp >= transaction.unlockTime, "tx is lock");

        (bool success, bytes memory data) = transaction.target.call{value: transaction.value}(transaction.data);
        require(success,"tx exec failed");

        transaction.status = TxStatus.Executed;
        emit Exec(msg.sender, _txId, data);
    }

    function cancle(bytes32 _txId) external {
        Transaction storage transaction = txs[_txId];
        require(msg.sender == owner || msg.sender == transaction.owner, "access denied");
        require(transaction.status == TxStatus.Queued,"tx status not queue");

        transaction.status = TxStatus.Canceled;
        emit Cancel(msg.sender, _txId);
    }

    function getTransaction(bytes32 _txId) external view returns (Transaction memory) {
        Transaction memory transaction = txs[_txId];
        require(transaction.status != TxStatus.None,"tx not exist");
        return transaction;
    }

    function getTxIds(address caller) external view returns (bytes32[] memory) {
        return callerTxIds[caller];
    }

    function getFuncData(string calldata funcSignature, bytes calldata encodedArgs) external pure returns (bytes memory) {
        return abi.encodePacked(bytes4(keccak256(bytes(funcSignature))), encodedArgs);
    }

    function _getHash(address _owner,address _target,uint256 _value,bytes calldata _data,uint256 _timestamp) private pure returns (bytes32) {
        return keccak256(abi.encode(_owner,_target, _value, _data, _timestamp));
    }
}

contract TestTimeLock {
    address immutable timeLock;

    uint8 public num = 1;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    function setNum(uint8 _num) external returns (uint8) {
        require(msg.sender == timeLock,"access denied");
        num = _num;
        return _num;
    }
}
