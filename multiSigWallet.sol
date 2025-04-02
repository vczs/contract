// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner,uint indexed txIndex,address indexed to,uint value,bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint confirmOwnerNum;
    }

    mapping(address => bool) private isOwner;
    address[] private owners;

    uint private exeNeedMinConfirmOwnerNum;
    Transaction[] private transactions;
    mapping(uint => mapping(address => bool)) private txOwnerConfirm;

    constructor(address[] memory _owners, uint _exeNeedMinConfirmOwnerNum) {
        require(_owners.length > 0, "owners required");
        require(_exeNeedMinConfirmOwnerNum > 0 && _exeNeedMinConfirmOwnerNum <= _owners.length,"invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner repeat");

            isOwner[owner] = true;
            owners.push(owner);
        }

        exeNeedMinConfirmOwnerNum = _exeNeedMinConfirmOwnerNum;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address _to,uint _value,bytes memory _data) external onlyOwner {
        transactions.push(Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmOwnerNum: 0
            }));
        emit SubmitTransaction(msg.sender, transactions.length, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(!txOwnerConfirm[_txIndex][msg.sender], "tx already confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmOwnerNum += 1;
        txOwnerConfirm[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex){
        require(txOwnerConfirm[_txIndex][msg.sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmOwnerNum -= 1;
        txOwnerConfirm[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.confirmOwnerNum >= exeNeedMinConfirmOwnerNum,"cannot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }


    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint _txIndex) external view txExists(_txIndex) returns (address,uint,bytes memory,bool,uint){
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmOwnerNum
        );
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");_;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");_;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");_;
    }
}
