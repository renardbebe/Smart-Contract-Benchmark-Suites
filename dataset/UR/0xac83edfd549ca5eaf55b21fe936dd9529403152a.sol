 

pragma solidity ^0.4.18;

contract Merchant {
     
    address public owner;
    
     
    event ReceiveEther(address indexed from, uint256 value);
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function Merchant() public {
        owner = msg.sender;
    }
    
     
    function () public payable {
        ReceiveEther(msg.sender, msg.value);
    }
    
     
    function withdrawFunds(address withdrawAddress, uint256 amount) onlyOwner public returns (bool) {
        if(this.balance >= amount) {
            if(amount == 0) amount = this.balance;
            withdrawAddress.transfer(amount);
            return true;
        }
        return false;
    }
    
     
    function withdrawAllFunds() onlyOwner public returns (bool) {
        return withdrawFunds(msg.sender, 0);
    }
}