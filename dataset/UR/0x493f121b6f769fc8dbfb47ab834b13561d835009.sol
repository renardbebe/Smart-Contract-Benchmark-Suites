 

pragma solidity ^0.4.0;

 
contract Vault {
     
    address public owner;
    
     
    address public recovery;

     
    uint public withdrawDelay;

     
    uint public withdrawTime;
    
     
    uint public withdrawAmount;

    
    modifier only_owner() {
        if(msg.sender != owner) throw;
        _;
    }
    
    modifier only_recovery() {
        if(msg.sender != recovery) throw;
        _;
    }

     
    event Unvault(uint amount, uint when);
    
     
    event Recover(address target, uint value);
    
     
    event Deposit(address from, uint value);
    
     
    event Withdraw(address to, uint value);

     
    function Vault(address _recovery, uint _withdrawDelay) {
        owner = msg.sender;
        recovery = _recovery;
        withdrawDelay = _withdrawDelay;
    }
    
    function max(uint a, uint b) internal returns (uint) {
        if(a > b)
            return a;
        return b;
    }
    
     
    function unvault(uint amount) only_owner {
        if(amount > this.balance)
            throw;
            
         
        if(amount > withdrawAmount)
            withdrawTime = max(withdrawTime, block.timestamp + withdrawDelay);
        
        withdrawAmount = amount;
        Unvault(amount, withdrawTime);
    }
    
     
    function withdraw() only_owner {
        if(block.timestamp < withdrawTime || withdrawAmount == 0)
            throw;
        
        uint amount = withdrawAmount;
        withdrawAmount = 0;

        if(!owner.send(amount))
            throw;

        Withdraw(owner, amount);
    }
    
     
    function recover(address target) only_recovery {
        Recover(target, this.balance);
        selfdestruct(target);
    }
    
     
    function lock(uint duration) only_owner {
        withdrawTime = max(withdrawTime, block.timestamp + duration);
    }
    
    function() payable {
        if(msg.value > 0)
            Deposit(msg.sender, msg.value);
    }
}