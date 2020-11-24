 

pragma solidity ^0.4.11;

contract TimeBank {

    struct Holder {
    uint fundsDeposited;
    uint withdrawTime;
    }
    mapping (address => Holder) holders;

    function getInfo() constant returns(uint,uint,uint){
        return(holders[msg.sender].fundsDeposited,holders[msg.sender].withdrawTime,block.timestamp);
    }

    function depositFunds(uint _withdrawTime) payable returns (uint _fundsDeposited){
         

        require(msg.value > 0 && _withdrawTime > block.timestamp && _withdrawTime < block.timestamp + 157680000);
         
        if (!(holders[msg.sender].withdrawTime > 0)) holders[msg.sender].withdrawTime = _withdrawTime;
        holders[msg.sender].fundsDeposited += msg.value;
        return msg.value;
    }

    function withdrawFunds() {
        require(holders[msg.sender].withdrawTime < block.timestamp);  

        uint funds = holders[msg.sender].fundsDeposited;  

        holders[msg.sender].fundsDeposited = 0;  
        holders[msg.sender].withdrawTime = 0;  
        msg.sender.transfer(funds);  
    }
}