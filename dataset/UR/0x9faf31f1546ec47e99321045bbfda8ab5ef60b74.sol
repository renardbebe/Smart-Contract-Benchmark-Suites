 

 
 
 

 
 

pragma solidity ^0.4.21;
contract TestContract {
    function SHA256(string s) public pure returns(bytes32) {
        return(sha256(s));
    }

    mapping ( bytes32 => uint ) public amount;
    
     
    function commitTo(bytes32 hash) public payable {
        amount[hash] = msg.value;
    }
    
     
    
     
     
     
     
     
     
     
     
     
     
     
     
    
    event BountyClaimed(string note, uint);
    function claim(string s) public payable {
        emit BountyClaimed("bounty claimed for eth amount:", amount[sha256(s)]);
        msg.sender.transfer( amount[sha256(s)] );
    }

}