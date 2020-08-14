/*
 * @source: https://github.com/trailofbits/not-so-smart-contracts/blob/master/wrong_constructor_name/incorrect_constructor.sol
 * @author: Ben Perez
 * Modified by Gerhard Wagner
 * @Labeled: [19]
 */


pragma solidity 0.4.24;

contract Missing{
    address private owner;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }
    
    function missing()
        public 
    {
        owner = msg.sender;
    }

    function () payable {} 

    function withdraw() 
        public 
        onlyowner
    {
       owner.transfer(this.balance);
    }
}
