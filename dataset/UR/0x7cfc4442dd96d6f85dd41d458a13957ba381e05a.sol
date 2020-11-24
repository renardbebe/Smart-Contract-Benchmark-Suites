 

 
 
 
 
 

 


pragma solidity ^0.4.18;

contract HTLC {
    
 
 
 

    string public version = "0.0.1";
    bytes32 public digest = 0x2e99758548972a8e8822ad47fa1017ff72f06f3ff6a016851f45c398732bc50c;
    address public dest = 0x9552ae966A8cA4E0e2a182a2D9378506eB057580;
    uint public timeOut = now + 1 hours;
    address issuer = msg.sender; 

 
 
 

    
    modifier onlyIssuer {require(msg.sender == issuer); _; }

 
 
 

    
     
    function claim(string _hash) public returns(bool result) {
       require(digest == sha256(_hash));
       selfdestruct(dest);
       return true;
       }
    
     
    function () public payable {}

 
     
    function refund() onlyIssuer public returns(bool result) {
        require(now >= timeOut);
        selfdestruct(issuer);
        return true;
    }
}

 
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   