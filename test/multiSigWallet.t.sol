pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWallet;

    function setUp() public {
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        multiSigWallet = new MultiSigWallet(owners, 1);
    }

    // Add more test functions here...
    function testConstructor() public {
        address[] memory owners = new address[](2);
        owners[0] = address(this);
        owners[1] = address(0x123);
        MultiSigWallet wallet = new MultiSigWallet(owners, 2);
        assertEq(wallet.getOwners().length, 2, "Number of owners is incorrect");
        assertEq(
            wallet.required(),
            2,
            "Required number of confirmations is incorrect"
        );
    }

    function testGetOwners() public {
        address[] memory owners = multiSigWallet.getOwners();
        assertEq(owners.length, 1, "Wrong number of owners");
        assertEq(owners[0], address(this), "Wrong owner");
    }

    function testSubmit() public {
        multiSigWallet.submit(address(this), 1 ether, "");
        (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        ) = multiSigWallet.getTransaction(0);
        assertEq(to, address(this), "Wrong recipient");
        assertEq(amount, 1 ether, "Wrong amount");
        assertFalse(executed, "Transaction was executed");
        assertEq(data.length, 0, "Wrong data");
        assertEq(noOfConfirmations, 0, "Wrong number of confirmations");
    }

    function testGetTransaction() public {
        multiSigWallet.submit(address(this), 1 ether, "");
        (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        ) = multiSigWallet.getTransaction(0);
        assertEq(to, address(this), "Wrong recipient");
        assertEq(amount, 1 ether, "Wrong amount");
        assertFalse(executed, "Transaction was executed");
        assertEq(data.length, 0, "Wrong data");
        assertEq(noOfConfirmations, 0, "Wrong number of confirmations");
    }

    function testRevoke() public {
        multiSigWallet.submit(address(this), 1 ether, "");
        multiSigWallet.approve(0);
        multiSigWallet.revoke(0);
        (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        ) = multiSigWallet.getTransaction(0);
        assertEq(noOfConfirmations, 0, "Wrong number of confirmations");
    }

    function testApprove() public {
        multiSigWallet.submit(address(this), 1 ether, "");
        multiSigWallet.approve(0);
        (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        ) = multiSigWallet.getTransaction(0);
        assertEq(noOfConfirmations, 1, "Wrong number of confirmations");
    }

    function testExecute() public {
        multiSigWallet.submit(address(this), 1 ether, "");
        multiSigWallet.approve(0);
        multiSigWallet.execute(0);
        (
            address to,
            uint amount,
            bool executed,
            bytes memory data,
            uint noOfConfirmations
        ) = multiSigWallet.getTransaction(0);
        assertTrue(executed, "Transaction was not executed");
    }

    function testOnlyOwner() public {
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        MultiSigWallet wallet = new MultiSigWallet(owners, 1);

        // Should succeed because the test contract is the owner
        wallet.submit(address(this), 1 ether, "");

        // Should fail because the test contract is not the owner

        // try wallet.submit(address(0x123), 1 ether, "") {
        //     fail("Expected revert not received");
        // } catch Error(string memory reason) {
        //     assertEq(
        //         reason,
        //         "Not an owner",
        //         "Expected revert reason did not match"
        //     );
        // }
    }

    function testTxExist() public {
        multiSigWallet.submit(address(this), 1 ether, "");

        // CASE 1: Should succeed because the transaction exists
        multiSigWallet.approve(0);

        // CASE 2: Should fail because the transaction does not exist
        // try multiSigWallet.approve(1) {
        //     fail("Expected revert not received");
        // } catch Error(string memory reason) {
        //     assertEq(
        //         reason,
        //         "Transaction does not exist",
        //         "Expected revert reason did not match"
        //     );
        // }
    }

    function testNotApproved() public {
        multiSigWallet.submit(address(this), 1 ether, "");

        // CASE 1: Should succeed because the transaction has not been approved yet
        multiSigWallet.approve(0);

        // CASE 2: Should fail because the transaction has already been approved
        // try multiSigWallet.approve(0) {
        //     fail("Expected revert not received");
        // } catch Error(string memory reason) {
        //     assertEq(
        //         reason,
        //         "Transaction is already approved",
        //         "Expected revert reason did not match"
        //     );
        // }
    }
}
