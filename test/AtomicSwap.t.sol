// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";


import "../src/AtomicSwap.sol";
import "../src/Tokens.sol";

contract TestAtomicSwap is Test {
    AtomicSwap atomicswap;
    Token token; 
    address public User1 = address(1);
    address public receiver = address(2);

    function setUp() public {
        atomicswap = new AtomicSwap();
        token = new Token();
        console.log("Atomic Swap and Token deployed successfully");
    }

    function testEth_payment() public {
         setUp();
          uint256 initialBalance = address(atomicswap).balance;
          assertEq(initialBalance, 0);


         bytes32 testId = keccak256(abi.encodePacked("Eth_payment"));
         bytes20 secretHash = ripemd160(abi.encodePacked("secret"));
         uint64 lockTime = uint64(block.timestamp + 1 hours);

        atomicswap.ethPayment{value : 1 ether}(testId,receiver,secretHash,lockTime);
        uint256 balance = atomicswap.viewBalance();
        assertEq(balance , 1 ether);

        AtomicSwap.Payment memory payment = atomicswap.payments(testId);
        assertEq(payment.paymentHash, ripemd160(abi.encodePacked(receiver, address(this), secretHash, address(0), 1 ether)));
        assertEq(payment.lockTime, lockTime);
        assertEq(uint(payment.state), uint(AtomicSwap.PaymentState.PaymentSent));
    }

//    function testNewContractHasUninitializedPayments() public {
//     AtomicSwap newSwap = new AtomicSwap();

//     bytes32 testId = keccak256(abi.encodePacked("test"));
//     // AtomicSwap.Payment memory payment = newSwap.payments(testId);

//     // assertEq(uint(payment.state), uint(AtomicSwap.PaymentState.Uninitialized), "Payment should be uninitialized");
// }


    // function testUser1SubmitsEthAndUser2SubmitsErc20() public {
    //     // Arrange
    //     bytes32 ethPaymentId = keccak256(abi.encodePacked("ethPayment"));
    //     bytes32 erc20PaymentId = keccak256(abi.encodePacked("erc20Payment"));
    //     bytes20 secretHash = ripemd160(abi.encodePacked("secret"));
    //     uint64 lockTime = uint64(block.timestamp + 1 hours);
    //     uint256 ethAmount = 1 ether;
    //     uint256 erc20Amount = 200 ether; 

       
    //     vm.prank(User2);
    //     token.mint(User2);  

    //     vm.deal(User1, ethAmount);
    //     vm.startPrank(User1);
    //     atomicswap.ethPayment{value: ethAmount}(ethPaymentId, User2, secretHash, lockTime);
    //     vm.stopPrank();

    //     // Assert ETH Payment
    //     // assertEq(atomicswap.payments(ethPaymentId).state, AtomicSwap.PaymentState.PaymentSent);

    //     // Act - User 2 submits ERC20
    //     vm.startPrank(User2);
    //     token.approve(address(atomicswap), erc20Amount);
    //     // atomicswap.erc20Payment(erc20PaymentId, erc20Amount, address(token), User1, secretHash, lockTime);
    //     vm.stopPrank();

    //     // Assert ERC20 Payment
    //     // assertEq(atomicswap.payments(erc20PaymentId).state, AtomicSwap.PaymentState.PaymentSent);
    // }
}
