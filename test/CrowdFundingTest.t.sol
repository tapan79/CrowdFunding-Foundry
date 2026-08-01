// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingTest is Test {

    CrowdFunding crowdFunding;

    address internal OWNER = makeAddr("OWNER");
    address internal ALICE = makeAddr("ALICE");
    address internal BOB = makeAddr("BOB");

    uint target = 10 ether;
    uint deadline = 30 days;

    function setUp() public {
        vm.prank(OWNER);
        crowdFunding = new CrowdFunding(target, deadline);
    }

    // Verifies the deployer (msg.sender) is correctly assigned as the contract manager.
    function testManagerIsSetCorrectly() public {
        assertEq(crowdFunding.manager(), OWNER);
    }

    // Verifies the funding target passed to the constructor is stored correctly
    function testTargetIsSetCorrectly() public {
    assertEq(crowdFunding.target(), target);
    }

    // Verifies the deadline is initialized as block.timestamp + _deadline.
    function testDeadlineIsSetCorrectly() public {
    uint expectedDeadline = block.timestamp + deadline;
    assertEq(crowdFunding.deadline(), expectedDeadline);
    }

    // Verifies the minimum contribution is initialized to 100 wei.
    function testMinimumContributionIsSetCorrectly() public {
    assertEq(crowdFunding.minimumcontribution(), 100 wei);
    }

    // Verifies a newly deployed contract starts with 0 ETH raised
    function testInitialRaisedAmountIsZero() public {
    assertEq(crowdFunding.raisedamount(), 0);
    }

    // Verifies a newly deployed contract starts with 0 contributors
    function testInitialContributorCountIsZero() public {
    assertEq(crowdFunding.noofcontributor(), 0);
    }

    // Verifies the crowdfunding contract collect the contribution received by the contributors
    function testContributionSuccess() public {
    // Give ALICE 5 ether
    vm.deal(ALICE, 5 ether);

    // Next transaction is sent by ALICE
    vm.prank(ALICE);

    // Contribute 1 ether
    crowdFunding.contribution{value: 1 ether}();

    // Verify contributor mapping
    assertEq(crowdFunding.contributors(ALICE), 1 ether);

    // Verify total raised amount
    assertEq(crowdFunding.raisedamount(), 1 ether);

    // Verify contributor count
    assertEq(crowdFunding.noofcontributor(), 1);

    // check contract balance
    assertEq(crowdFunding.getcontractbalance(), 1 ether);
    }

    // Contribution below minimum should be revert
    function testContributionBelowMinimumReverts() public {
        // Giver 1 Ether to ALICE
        vm.deal(ALICE, 1 ether);

        // next transection come from ALICE
        vm.prank(ALICE);

        // Expect the next transection to revert
        vm.expectRevert("Minimum contribution is 100 wei");

        // send less than minimum contribution
        crowdFunding.contribution{value: 99 wei}();
    }

    // same User Contributes Twice
    function testSameUserContributionTwice() public {
        // Give ALICE 5 ether
        vm.deal(ALICE, 5 ether);

        // First Contribution by ALICE
        vm.prank(ALICE);
        crowdFunding.contribution{value: 1 ether}();

        // Second Contribution by ALICE
        vm.prank(ALICE);
        crowdFunding.contribution{value: 2 ether}();

        // Total contribution should be 3 ether
        assertEq(crowdFunding.contributors(ALICE), 3 ether);

        // Contributor count should remain 1
        assertEq(crowdFunding.noofcontributor(), 1);

        // Raised amount should be 3 ether
        assertEq(crowdFunding.raisedamount(), 3 ether);

        // Contract balance should be 3 ether
        assertEq(crowdFunding.getcontractbalance(), 3 ether);
    }

    // Multiple Users Can Contribute
    function testMultipleUsersCanContribute() public {
    // Give ETH to ALICE and BOB
    vm.deal(ALICE, 5 ether);
    vm.deal(BOB, 5 ether);

    // ALICE contributes 1 ether
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // BOB contributes 2 ether
    vm.prank(BOB);
    crowdFunding.contribution{value: 2 ether}();

    // Verify individual contributions
    assertEq(crowdFunding.contributors(ALICE), 1 ether);
    assertEq(crowdFunding.contributors(BOB), 2 ether);

    // Verify total raised amount
    assertEq(crowdFunding.raisedamount(), 3 ether);

    // Verify contributor count
    assertEq(crowdFunding.noofcontributor(), 2);

    // Verify contract balance
    assertEq(crowdFunding.getcontractbalance(), 3 ether);
    }

    // Contribution After Deadline Should Revert
    function testContributionAfterDeadlineReverts() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 1 ether);

    // Move blockchain time after the deadline
    vm.warp(block.timestamp + deadline + 1);

    // Next transaction is from ALICE
    vm.prank(ALICE);

    // Expect revert
    vm.expectRevert("Deadline is over");

    // Try to contribute
    crowdFunding.contribution{value: 1 ether}();
    }

    // Contribution Exactly at Deadline Should Revert
    function testContributionAtDeadlineReverts() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 1 ether);

    // Move exactly to the deadline
    vm.warp(crowdFunding.deadline());

    // Next transaction is from ALICE
    vm.prank(ALICE);

    // Expect revert
    vm.expectRevert("Deadline is over");

    // Try to contribute
    crowdFunding.contribution{value: 1 ether}();
    }

    // Successful Refund
    function testRefundSuccess() public {
    // Give ALICE 5 ether
    vm.deal(ALICE, 5 ether);

    // ALICE contributes 1 ether
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Move time after deadline
    vm.warp(crowdFunding.deadline() + 1);

    // Balance before refund
    uint balanceBefore = ALICE.balance;

    // ALICE requests refund
    vm.prank(ALICE);
    crowdFunding.refund();

    // Balance should increase by 1 ether
    assertEq(ALICE.balance, balanceBefore + 1 ether);

    // Contributor record should be cleared
    assertEq(crowdFunding.contributors(ALICE), 0);

    // Contract balance should become zero
    assertEq(crowdFunding.getcontractbalance(), 0);
    }

    // Refund Before Deadline Should Revert
    function testRefundBeforeDeadlineReverts() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 5 ether);

    // ALICE contributes 1 ether
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Try to refund before deadline
    vm.prank(ALICE);

    // Expect revert
    vm.expectRevert("You are not eligible for contribution");

    crowdFunding.refund();
    }

    // Refund When Target Is Reached Should Revert
    function testRefundWhenTargetReachedReverts() public {
    // Give ALICE enough ETH
    vm.deal(ALICE, 20 ether);

    // ALICE contributes more than the target
    vm.prank(ALICE);
    crowdFunding.contribution{value: 11 ether}();

    // Move after deadline
    vm.warp(crowdFunding.deadline() + 1);

    // Refund should revert
    vm.prank(ALICE);
    vm.expectRevert("You are not eligible for contribution");

    crowdFunding.refund();
    }

    // Non-Contributor Cannot Claim Refund
    function testNonContributorCannotRefund() public {
    // Move time after deadline
    vm.warp(crowdFunding.deadline() + 1);

    // BOB never contributed
    vm.prank(BOB);

    // Expect revert
    vm.expectRevert("You are not a contributor");

    // Try refund
    crowdFunding.refund();
    }

    // Double Refund Should Fail
    function testDoubleRefundFails() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 5 ether);

    // ALICE contributes 1 ether
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Move after deadline
    vm.warp(crowdFunding.deadline() + 1);

    // First refund (should succeed)
    vm.prank(ALICE);
    crowdFunding.refund();

    // Second refund (should revert)
    vm.prank(ALICE);
    vm.expectRevert("You are not a contributor");

    crowdFunding.refund();
    }

    // Manager Can Create Request
    function testManagerCanCreateRequest() public {
    vm.prank(OWNER);

    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        5 ether
    );

    // Request count should increase
    assertEq(crowdFunding.numrequests(), 1);
    }

    // Non-Manager Cannot Create Request
    function testNonManagerCannotCreateRequest() public {
    // ALICE is not the manager
    vm.prank(ALICE);

    // Expect revert
    vm.expectRevert("You are not manager");

    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        5 ether
    );
    }

    // Request Counter Increments
    function testRequestCounterIncrements() public {
        vm.startPrank(OWNER);

        crowdFunding.createrequest(
            "Request 1",
            payable(ALICE),
            1 ether
        );

        crowdFunding.createrequest(
            "Request 2",
            payable(BOB),
            2 ether
        );

        vm.stopPrank();

        // Two request should exist
        assertEq(crowdFunding.numrequests(), 2);
    }

    // Verifies only contributor can vote
    function testContributorCanVote() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 5 ether);

    // ALICE contributes
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Manager creates a request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    // ALICE votes
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    // Verify vote count
    (
        ,
        ,
        ,
        ,
        uint noofvoter
    ) = crowdFunding.getRequest(0);

    assertEq(noofvoter, 1);
    }

    // Non-Contributor Cannot Vote
    function testNonContributorCannotVote() public {
    // Manager creates a request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    // BOB never contributed
    vm.prank(BOB);

    // Expect revert
    vm.expectRevert("You are not a contributor");

    // Try voting
    crowdFunding.voterequest(0);
    }

    // Cannot Vote Twice by single contributor
    function testCannotVoteTwice() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 5 ether);

    // ALICE contributes
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Manager creates a request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    // First vote (should succeed)
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    // Second vote (should fail)
    vm.prank(ALICE);
    vm.expectRevert("You have already voted");

    crowdFunding.voterequest(0);
    }

    // Multiple Contributors Can Vote
    function testMultipleContributorsCanVote() public {
    // Give ETH to ALICE and BOB
    vm.deal(ALICE, 5 ether);
    vm.deal(BOB, 5 ether);

    // ALICE contributes
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // BOB contributes
    vm.prank(BOB);
    crowdFunding.contribution{value: 1 ether}();

    // Manager creates a request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    // ALICE votes
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    // BOB votes
    vm.prank(BOB);
    crowdFunding.voterequest(0);
    }

    // Multiple Contributors Can Vote
    function testNonManagerCannotMakePayment() public {
    // ALICE is not the manager
    vm.prank(ALICE);

    // Expect revert
    vm.expectRevert("You are not manager");

    // Try making payment
    crowdFunding.makepayment(0);
    }

    // Payment Before Target Reached Reverts
    function testPaymentBeforeTargetReachedReverts() public {
    // Give ALICE some ETH
    vm.deal(ALICE, 5 ether);

    // ALICE contributes only 1 ETH
    vm.prank(ALICE);
    crowdFunding.contribution{value: 1 ether}();

    // Manager creates a request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    // Manager tries to make payment
    vm.prank(OWNER);

    vm.expectRevert("Target is not reached");

    crowdFunding.makepayment(0);
    }

    // Payment Without Majority Reverts
    function testPaymentWithoutMajorityReverts() public {
    // Give ETH to contributors
    vm.deal(ALICE, 6 ether);
    vm.deal(BOB, 6 ether);

    // Both contribute (Target = 10 ETH)
    vm.prank(ALICE);
    crowdFunding.contribution{value: 5 ether}();

    vm.prank(BOB);
    crowdFunding.contribution{value: 6 ether}();

    // Manager creates a payment request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        2 ether
    );

    // Nobody votes

    // Manager tries to make payment
    vm.prank(OWNER);

    vm.expectRevert("majority does not support this request");

    crowdFunding.makepayment(0);
    }

    // Manager Can Make Payment
    function testManagerCanMakePayment() public {
    // Give ETH to ALICE and BOB
    vm.deal(ALICE, 6 ether);
    vm.deal(BOB, 6 ether);

    // Both contribute
    vm.prank(ALICE);
    crowdFunding.contribution{value: 5 ether}();

    vm.prank(BOB);
    crowdFunding.contribution{value: 6 ether}();

    // Manager creates request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        2 ether
    );

    // ALICE votes
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    // BOB votes
    vm.prank(BOB);
    crowdFunding.voterequest(0);

    // Balance before payment
    uint balanceBefore = BOB.balance;

    // Manager makes payment
    vm.prank(OWNER);
    crowdFunding.makepayment(0);

    // Recipient should receive 2 ETH
    assertEq(BOB.balance, balanceBefore + 2 ether);
    }

    // Cannot Make Payment Twice
    function testCannotMakePaymentTwice() public {
    // Give ETH to contributors
    vm.deal(ALICE, 6 ether);
    vm.deal(BOB, 6 ether);

    // Reach target (11 ETH)
    vm.prank(ALICE);
    crowdFunding.contribution{value: 5 ether}();

    vm.prank(BOB);
    crowdFunding.contribution{value: 6 ether}();

    // Create request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        2 ether
    );

    // Vote
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    vm.prank(BOB);
    crowdFunding.voterequest(0);

    // First payment (Success)
    vm.prank(OWNER);
    crowdFunding.makepayment(0);

    // Second payment should fail
    vm.prank(OWNER);
    vm.expectRevert("This request has been completed");

    crowdFunding.makepayment(0);
    }

    // Payment Fails When raisedAmount == target
    function testPaymentFailsWhenRaisedAmountEqualsTarget() public {
    // Give ETH to contributors
    vm.deal(ALICE, 5 ether);
    vm.deal(BOB, 5 ether);

    // Total contribution = exactly 10 ETH
    vm.prank(ALICE);
    crowdFunding.contribution{value: 5 ether}();

    vm.prank(BOB);
    crowdFunding.contribution{value: 5 ether}();

    // Create request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        2 ether
    );

    // Both vote
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    vm.prank(BOB);
    crowdFunding.voterequest(0);

    // Should revert because contract uses >
    vm.prank(OWNER);
    vm.expectRevert("Target is not reached");

    crowdFunding.makepayment(0);
    }
}

