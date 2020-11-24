 

pragma solidity ^0.4.11;

 
contract Owned {
    address public owner;
    
}

 
contract HodlContract{
    
    HodlStruct[] public hodls; 
    address FeeAddress;
    
    event hodlAdded(uint hodlID, address recipient, uint amount, uint waitTime);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    
    struct HodlStruct {
        address recipient;
        uint amount;
        uint waitTime;
        bool executed;
    }
  
   function HodlEth(address beneficiary, uint daysWait) public payable returns (uint hodlID) 
   {
       uint FeeAmount;
       FeeAddress = 0x9979cCFF79De92fbC1fb43bcD2a3a97Bb86b6920; 
        FeeAmount = msg.value * 1/100;  
        FeeAddress.transfer(FeeAmount);
        
        hodlID = hodls.length++;
        HodlStruct storage p = hodls[hodlID];
        p.waitTime = now + daysWait * 1 days;
        p.recipient = beneficiary;
        p.amount = msg.value * 99/100;
        p.executed = false;

        hodlAdded(hodlID, beneficiary, msg.value, p.waitTime);
        return hodlID;
        
    }
    
    function Realize(uint hodlID) public payable returns (uint amount){
    HodlStruct storage p = hodls[hodlID];
    require (now > p.waitTime   
    && !p.executed  
    && msg.sender == p.recipient);  
        
        msg.sender.transfer(p.amount);  
        p.executed = true;
        return p.amount;
    }
    
    
    function FindID(address beneficiary) public returns (uint hodlID){  
        HodlStruct storage p = hodls[hodlID];
        
        for (uint i = 0; i <  hodls.length; ++i) {
            if (p.recipient == beneficiary && !p.executed ) {
                return hodlID;
            } else {
                revert();
            }
        }
        
    }
    
}