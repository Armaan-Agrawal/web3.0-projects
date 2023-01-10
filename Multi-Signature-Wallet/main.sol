//SPDX-License-Identifier: MIT


pragma solidity 0.8.13;


//a wallet that needs votes to approve transactions
//list of voters
//mechanism to conduct transaction
//mechanism to retract vote

contract multiSig{

    address[] public owners;
    mapping (address => bool) public ownerList; 
    mapping(uint => mapping (address => bool)) public alreadyVoted; //to see if a voter has already voted on a part. transaction
    uint public approvalsRequired = 5;

    receive() external payable{}

    modifier onlyOwner() {
        require(ownerList[msg.sender] == true, "You are not the owner!");
        _;
    }

    constructor() {
        owners.push(msg.sender);
        ownerList[msg.sender] = true;
    }

    function addOwner(address ownerAddress) public onlyOwner {
        require(ownerList[ownerAddress] == false, "You are already an owner!");
        owners.push(ownerAddress);
        ownerList[ownerAddress] = true;
    }

    struct Transaction {
        address sendingTo;
        uint approvals;
        uint value;
        bool alreadyExecuted;
    }

    Transaction[] public proposedTransaction; 

    function voteOnTransaction(uint index) public onlyOwner {
        require(alreadyVoted[index][msg.sender] == false, "You have already voted!");
        proposedTransaction[index].approvals += 1;
        alreadyVoted[index][msg.sender] = true;
        if(proposedTransaction[index].approvals >= 3){
            address payable toSend = payable(proposedTransaction[index].sendingTo);
            (bool tryToSend,) = toSend.call{value: proposedTransaction[index].value, gas: 5000}("");
            require(tryToSend, "You don't have enough funds!");
            proposedTransaction[index].alreadyExecuted = true;
        }
    }

    function retractVote(uint index) public onlyOwner {
        require(proposedTransaction[index].alreadyExecuted == false, "Sorry, transaction has already been executed!");
        proposedTransaction[index].approvals -= 1;
        alreadyVoted[index][msg.sender] = false; 
    }

    function proposeTX(address to, uint amount) public onlyOwner {
        proposedTransaction.push(Transaction({
            sendingTo: to,
            value: amount,
            approvals: 0,
            alreadyExecuted: false
        }));
    }

    function executeTX(uint index) public onlyOwner {
        require(proposedTransaction[index].approvals >= approvalsRequired, "You do not have enough approvals yet!");
        require(proposedTransaction[index].alreadyExecuted == false, "This transaction has already been executed!");
        address payable toSend = payable(proposedTransaction[index].sendingTo);
        (bool tryToSend,) = toSend.call{value: proposedTransaction[index].value, gas: 5000}("");
        require(tryToSend, "You don't have enough funds!");
        proposedTransaction[index].alreadyExecuted = true;
    }

}