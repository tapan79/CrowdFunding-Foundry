// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingAccessControlTest is Test {

    CrowdFunding crowdFunding;

    address OWNER = makeAddr("OWNER");
    address ALICE = makeAddr("ALICE");
    address BOB = makeAddr("BOB");

    uint256 target = 10 ether;
    uint256 deadline = 30 days;

    function setUp() public {
        vm.prank(OWNER);
        crowdFunding = new CrowdFunding(target, deadline);
    }

    /*//////////////////////////////////////////////////////////////
                    1. NON-MANAGER CANNOT CREATE REQUEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertIf_NonManagerCreatesRequest() public {

        vm.prank(ALICE);

        vm.expectRevert();

        crowdFunding.createrequest(
            "Vendor Payment",
            payable(BOB),
            1 ether
        );
    }

    /*//////////////////////////////////////////////////////////////
                    2. NON-MANAGER CANNOT MAKE PAYMENT
    //////////////////////////////////////////////////////////////*/

    function test_RevertIf_NonManagerMakesPayment() public {

        // Alice contributes enough to reach target
        vm.deal(ALICE, 10 ether);

        vm.prank(ALICE);
        crowdFunding.contribution{value:10 ether}();

        // Manager creates payment request
        vm.prank(OWNER);
        crowdFunding.createrequest(
            "Vendor Payment",
            payable(BOB),
            5 ether
        );

        // Alice votes
        vm.prank(ALICE);
        crowdFunding.voterequest(0);

        // Non-manager tries to release payment
        vm.prank(ALICE);

        vm.expectRevert();

        crowdFunding.makepayment(0);
    }

    /*//////////////////////////////////////////////////////////////
                    3. MANAGER CAN CREATE REQUEST
    //////////////////////////////////////////////////////////////*/

    function test_ManagerCanCreateRequest() public {

        vm.prank(OWNER);

        crowdFunding.createrequest(
            "Vendor Payment",
            payable(BOB),
            2 ether
        );

        (
            string memory description,
            address recipient,
            uint256 value,
            bool completed,
            uint256 noOfVoters
        ) = crowdFunding.getRequest(0);

        assertEq(description, "Vendor Payment");
        assertEq(recipient, BOB);
        assertEq(value, 2 ether);
        assertFalse(completed);
        assertEq(noOfVoters, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    4. MANAGER CAN MAKE PAYMENT
    //////////////////////////////////////////////////////////////*/

    function test_ManagerCanMakePayment() public {

        // Alice contributes enough to reach target
        vm.deal(ALICE, 11 ether);

        vm.prank(ALICE);
        crowdFunding.contribution{value:11 ether}();

        // Manager creates request
        vm.prank(OWNER);
        crowdFunding.createrequest(
            "Vendor Payment",
            payable(BOB),
            5 ether
        );

        // Alice votes
        vm.prank(ALICE);
        crowdFunding.voterequest(0);

        uint256 balanceBefore = BOB.balance;

        // Manager makes payment
        vm.prank(OWNER);
        crowdFunding.makepayment(0);

        (
            ,
            ,
            ,
            bool completed,
            
        ) = crowdFunding.getRequest(0);

        assertTrue(completed);

        assertEq(
            BOB.balance,
            balanceBefore + 5 ether
        );
    }

    /*//////////////////////////////////////////////////////////////
                    5. Double Payment Attack
    //////////////////////////////////////////////////////////////*/

    function test_RevertIf_RequestPaidTwice() public {

    // Alice contributes enough to reach target
    vm.deal(ALICE, 11 ether);

    vm.prank(ALICE);
    crowdFunding.contribution{value: 11 ether}();

    // Manager creates payment request
    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Vendor Payment",
        payable(BOB),
        5 ether
    );

    // Alice votes
    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    // Manager makes first payment
    vm.prank(OWNER);
    crowdFunding.makepayment(0);

    // Second payment should fail
    vm.prank(OWNER);

    vm.expectRevert();

    crowdFunding.makepayment(0);
    }

       /*//////////////////////////////////////////////////////////////
                    6. Contract Balance Matches raisedamount
    //////////////////////////////////////////////////////////////*/

    function test_ContractBalanceEqualsRaisedAmount() public {

    // Alice contributes
    vm.deal(ALICE, 3 ether);

    vm.prank(ALICE);
    crowdFunding.contribution{value: 3 ether}();

    // Bob contributes
    vm.deal(BOB, 4 ether);

    vm.prank(BOB);
    crowdFunding.contribution{value: 4 ether}();

    assertEq(
        address(crowdFunding).balance,
        crowdFunding.raisedamount()
    );
    }
}