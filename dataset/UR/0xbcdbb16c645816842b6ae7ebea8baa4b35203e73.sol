 

pragma solidity ^0.4.24;

contract NetkillerCashier{

    address public owner;
    uint public amount;
    uint public amounteth;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function transfer(address _to, uint _value) public payable {
        amount += _value;
        if (amounteth < msg.value){
            amounteth += msg.value;
        }else{
            amounteth -= msg.value;
        }
        
    }

	function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function withdraw() onlyOwner public {
        msg.sender.transfer(amounteth);
    }

    function balanceOf() public constant returns (uint balance) {
        return amount;
    }
    
    function balanceOfeth() public constant returns (uint balance) {
        return amounteth;
    }
    
    function balanceOfmax() public constant returns (uint balance) {
         if (amount>=amounteth){
            return amount;
        }else{
            return amounteth;
        }
    }
}