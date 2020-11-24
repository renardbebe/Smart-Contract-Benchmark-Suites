//Single transaction overflow
//Post-transaction effect: overflow escapes to publicly-readable storage
/* @Labeled: [11] */

pragma solidity ^0.4.19;

contract IntegerOverflowMinimal {
    uint public count = 1;

    function run(uint256 input) public {
        count -= input;
    }
}