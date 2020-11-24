 

pragma solidity ^0.4.23;

contract Deposit {

    address public owner;
    Withdraw[] public withdraws;

     
    function Deposit() public {
        owner = msg.sender;
    }

     
    function() public payable {
         
        owner.transfer(msg.value);
         
        withdraws.push(new Withdraw(msg.sender));
    }
}

contract Withdraw {

    address public owner;

     
    function Withdraw(address _owner) public {
        owner = _owner;
    }

}