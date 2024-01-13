// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approval(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Executed(address indexed owner, uint indexed txId);

    struct Transaction {
        address to;
        uint amount;
        bool executed;
        bytes data;
        uint noOfConfirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExist(uint _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(
            !transactions[_txId].executed,
            "Transaction is already executed"
        );
        _;
    }

    modifier notApproved(uint _txId) {
        require(
            !approved[_txId][msg.sender],
            "Transaction is already approved"
        );
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners are required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required number of owners"
        );

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner is not allowed");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) public onlyOwner {
        transactions.push(
            Transaction({
                to: _to,
                amount: _value,
                data: _data,
                executed: false,
                noOfConfirmations: 0
            })
        );
        emit Submit(transactions.length - 1);
    }

    function approve(
        uint _txId
    ) external onlyOwner txExist(_txId) notExecuted(_txId) notApproved(_txId) {
        Transaction storage transaction = transactions[_txId];
        transaction.noOfConfirmations += 1;
        approved[_txId][msg.sender] = true;
        emit Approval(msg.sender, _txId);
    }

    function execute(uint _txId) external txExist(_txId) notExecuted(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(transaction.noOfConfirmations >= required, "Cannot execute");
        transaction.executed = true;
        emit Executed(msg.sender, _txId);
    }

    function revoke(
        uint _txId
    ) external onlyOwner notExecuted(_txId) txExist(_txId) {
        Transaction storage transaction = transactions[_txId];
        require(approved[_txId][msg.sender], "Transaction not approved");
        transaction.noOfConfirmations -= 1;
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransaction(
        uint _txId
    )
        public
        view
        returns (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        )
    {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.amount,
            transaction.executed,
            transaction.data,
            transaction.noOfConfirmations
        );
    }
}
