/* * @Labeled: [8] */
pragma solidity 0.4.24;

contract Overflow_Add {
    uint public balance = 1;

    function add(uint256 deposit) public {
        balance += deposit;
    }
}