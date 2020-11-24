 

pragma solidity ^0.4.18;

contract FakeVote {
    
     
    mapping (address => uint256) public voteCount;
    
     
    mapping (address => uint256) public alreadyUsedVotes;
    
     
    uint256 public maxNumVotesPerAccount = 10;
    
     
    function voteFor(address participant, uint256 numVotes) public {

         
        require (voteCount[participant] < voteCount[participant] + numVotes);
        
         
        require(participant != msg.sender);
        
         
        require(alreadyUsedVotes[msg.sender] + numVotes <= maxNumVotesPerAccount);
        
         
        alreadyUsedVotes[msg.sender] += numVotes;
        
         
        voteCount[participant] += numVotes;
    }
}