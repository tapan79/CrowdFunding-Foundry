// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract CrowdFunding
{
    // request details
    struct request
    {
        string description; // why funding is required
        address payable recipient; // recipient address
        uint value; // amount of value raised
        bool completed; // request is completed or not
        uint noofvoter; // number of voter for approve of trasection
        mapping(address=>bool) voters; // for voting
    }

     mapping(uint=>request) public requests; // index to request structure
     mapping(address=>uint) public contributors; // contributor link from address to ether
     uint public numrequests; // count for request behaves as index
     address public manager; // contract deployer address
     uint public minimumcontribution; // minimum contribution by contributor
     uint public deadline; // days in which funding must be collect
     uint public target; // Target amount to be raised
     uint public raisedamount; // amount of hold sofar
     uint public noofcontributor; // number of contributor

    constructor(uint _target, uint _deadline) // set state varible & owner address
    {
        target = _target;
        deadline = block.timestamp + _deadline; // start from 1st jan 1960 + seconds
        minimumcontribution = 100 wei;
        manager = msg.sender;
    }

    modifier onlymanager()
    {
        require(msg.sender == manager, "You are not manager");
        _;
    }

    // create request by manager and feed the requester details
    function createrequest(string calldata _description, address payable _recipient, uint _value) public onlymanager()
    {
        request storage newrequest = requests[numrequests]; // data location
        numrequests++;
        newrequest.description = _description;
        newrequest.recipient = _recipient;
        newrequest.value = _value;
        newrequest.completed = false;
        newrequest.noofvoter = 0;
    }

    // smart contract receive ether from contributors
    function contribution() public payable
    {
        require(block.timestamp < deadline, "Deadline is over");
        require(msg.value >= minimumcontribution, "Minimum contribution is 100 wei");

        // check for first time contributors
        if(contributors[msg.sender] == 0)
        {
            noofcontributor++;
        }

        contributors[msg.sender] += msg.value;
        raisedamount += msg.value;
    }

    // to check the smart contract balance
    function getcontractbalance() public view returns(uint)
    {
        return address(this).balance;
    }

    // refund to contributor if some condition is not work
    function refund() public
    {
        require(block.timestamp > deadline && raisedamount < target, "You are not eligible for contribution");
        require(contributors[msg.sender] > 0, "You are not a contributor");
        uint amount = contributors[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        contributors[msg.sender] = 0; // state update after money withdrawal
    }

    // vote request by contributors
    function voterequest(uint _requestno) public
    {
        require(contributors[msg.sender] > 0, "You are not a contributor");
        request storage thisrequest = requests[_requestno];
        require(thisrequest.voters[msg.sender] == false, "You have already voted");
        thisrequest.voters[msg.sender] = true;
        thisrequest.noofvoter++;
    }

    function makepayment(uint _requestno) public onlymanager
    {
        require(raisedamount > target, "Target is not reached");
        request storage thisrequest = requests[_requestno];
        require(thisrequest.completed == false, "This request has been completed");
        require(thisrequest.noofvoter > noofcontributor / 2, "majority does not support this request");
        uint _value = thisrequest.value;
        (bool success, ) = payable(thisrequest.recipient).call{value: _value}("");
        require(success, "Transfer failed");
        thisrequest.completed = true;
    }

    // create getter function for getRequest for testing purpose
    function getRequest(uint _requestNo)
    public
    view
    returns (
        string memory description,
        address recipient,
        uint value,
        bool completed,
        uint noofvoter
    )
    {
    request storage r = requests[_requestNo];

    return (
        r.description,
        r.recipient,
        r.value,
        r.completed,
        r.noofvoter
    );
}
}