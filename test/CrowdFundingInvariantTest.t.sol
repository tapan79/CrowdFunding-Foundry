// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingInvariantTest is StdInvariant, Test {

    CrowdFunding crowdFunding;

    address internal OWNER = makeAddr("OWNER");
    address internal ALICE = makeAddr("ALICE");
    address internal BOB = makeAddr("BOB");

    uint target = 10 ether;
    uint deadline = 30 days;

    function setUp() public {
        vm.prank(OWNER);
        crowdFunding = new CrowdFunding(target, deadline);

        targetContract(address(crowdFunding));
    }

    // Contract Balance Never Negative
    function invariant_ContractBalanceNeverNegative() public {
        assertGe(address(crowdFunding).balance, 0);
    }

    // raised amount equal to contract balance
    function invariant_RaisedAmountEqualsContractBalance() public {
    assertEq(
        crowdFunding.raisedamount(),
        address(crowdFunding).balance
    );
    }

    // Manager Never Changes
    function invariant_ManagerNeverChanges() public {
    assertEq(crowdFunding.manager(), OWNER);
    }

    // Target amount never chnages
    function invariant_TargetNeverChanges() public {
    assertEq(crowdFunding.target(), target);
    }

    // Vote count never exceeds contributors
    function invarient_voteCountNeverExceedsContributors() public {
        uint256 totalRequests = crowdFunding.numrequests();

    for (uint256 i = 0; i < totalRequests; i++) {
        (
            ,
            ,
            ,
            ,
            uint256 noOfVoters
        ) = crowdFunding.getRequest(i);

        assertLe(
            noOfVoters,
            crowdFunding.noofcontributor()
        );
    }
    }

    // Request Recipient Is Never Zero Address
    function invariant_RequestRecipientIsNotZero() public {
    uint256 totalRequests = crowdFunding.numrequests();

    for (uint256 i = 0; i < totalRequests; i++) {
        (
            ,
            address recipient,
            ,
            ,
            
        ) = crowdFunding.getRequest(i);

        assertTrue(recipient != address(0));
    }
    }
}
