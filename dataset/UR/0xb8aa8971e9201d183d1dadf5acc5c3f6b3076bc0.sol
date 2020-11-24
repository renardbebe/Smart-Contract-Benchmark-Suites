 

pragma solidity ^0.4.18;

contract HTLC {
 
 
 
    string public version;
    bytes32 public digest;
    address public dest;
    uint public timeOut;
    address issuer; 
 
 
 
    modifier onlyIssuer {assert(msg.sender == issuer); _; }
 
 
 
 
     
    function HTLC(bytes32 _hash, address _dest, uint _timeLimit) public {
        assert(digest != 0 || _dest != 0 || _timeLimit != 0);
        digest = _hash;
        dest = _dest;
        timeOut = now + (_timeLimit * 1 hours);
        issuer = msg.sender; 
    }
     
     
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


contract xcat {
    string public version = "v1";
    
    struct txLog{
        address issuer;
        address dest;
        string chain1;
        string chain2;
        uint amount1;
        uint amount2;
        uint timeout;
        address crtAddr;
        bytes32 hashedSecret; 
    }
    
    event newTrade(string onChain, string toChain, uint amount1, uint amount2);
    
    mapping(bytes32 => txLog) public ledger;
    
    function testHash(string yourSecretPhrase) public returns (bytes32 SecretHash) {return(sha256(yourSecretPhrase));}
    
    function newXcat(bytes32 _SecretHash, address _ReleaseFundsTo, string _chain1, uint _amount1, string _chain2, uint _amount2, uint _MaxTimeLimit) public returns (address newContract) {
        txLog storage tl = ledger[sha256(msg.sender,_ReleaseFundsTo,_SecretHash)];
     
        HTLC h = new HTLC(_SecretHash, _ReleaseFundsTo, _MaxTimeLimit);
    
     
        tl.issuer = msg.sender;
        tl.dest = _ReleaseFundsTo;
        tl.chain1 = _chain1;
        tl.chain2 = _chain2;
        tl.amount1 = _amount1;
        tl.amount2 = _amount2;
        tl.timeout = _MaxTimeLimit;
        tl.hashedSecret = _SecretHash; 
        tl.crtAddr = h;
        newTrade (tl.chain1, tl.chain2, tl.amount1, tl.amount2);
        return h;
    }

     
    function() public { assert(0>1);} 

     
    function viewXCAT(address _issuer, address _ReleaseFundsTo, bytes32 _SecretHash) public returns (address issuer, address receiver, uint amount1, string onChain, uint amount2, string toChain, uint atTime, address ContractAddress){
        txLog storage tl = ledger[sha256(_issuer,_ReleaseFundsTo,_SecretHash)];
        return (tl.issuer, tl.dest, tl.amount1, tl.chain1, tl.amount2, tl.chain2,tl.timeout, tl.crtAddr);
    }
}

 
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   