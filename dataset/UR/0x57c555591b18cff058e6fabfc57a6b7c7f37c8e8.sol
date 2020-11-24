 

pragma solidity ^0.4.19;

 
contract Ballot {
     
     
     
    struct Voter {
        uint weight;  
        bytes32 voterName;  
        uint proposalId;  
    }

     
    struct Proposal {
        uint proposalId; 
        bytes32 proposalName;    
        uint voteCount;  
    }

    address public chairperson;

     
    Proposal[] public proposals;

    event BatchVote(address indexed _from);

    modifier onlyChairperson {
      require(msg.sender == chairperson);
      _;
    }

    function transferChairperson(address newChairperson) onlyChairperson  public {
        chairperson = newChairperson;
    }

     
    function Ballot(bytes32[] proposalNames) public {
        chairperson = msg.sender;

         
         
         
        for (uint i = 0; i < proposalNames.length; i++) {
             
             
             
            proposals.push(Proposal({
                proposalId: proposals.length,
                proposalName: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function addProposals(bytes32[] proposalNames) onlyChairperson public {
         
         
         
        for (uint i = 0; i < proposalNames.length; i++) {
             
             
             
            proposals.push(Proposal({
                proposalId: proposals.length,
                proposalName: proposalNames[i],
                voteCount: 0
            }));
        }
    }


     
    function vote(uint[] weights, bytes32[] voterNames, uint[] proposalIds) onlyChairperson public {

        require(weights.length == voterNames.length);
        require(weights.length == proposalIds.length);
        require(voterNames.length == proposalIds.length);

        for (uint i = 0; i < weights.length; i++) {
            Voter memory voter = Voter({
              weight: weights[i],
              voterName: voterNames[i],
              proposalId: proposalIds[i]
            });
            proposals[voter.proposalId-1].voteCount += voter.weight;
        }

        BatchVote(msg.sender);
    }

     
     
    function winningProposal() internal
            returns (uint winningProposal)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }

     
     
     
    function winnerName() public view
            returns (bytes32 winnerName)
    {
        winnerName = proposals[winningProposal()].proposalName;
    }

    function resetBallot(bytes32[] proposalNames) onlyChairperson public {

        delete proposals;

         
         
         
        for (uint i = 0; i < proposalNames.length; i++) {
             
             
             
            proposals.push(Proposal({
                proposalId: proposals.length,
                proposalName: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function batchSearchProposalsId(bytes32[] proposalsName) public view
          returns (uint[] proposalsId) {
      proposalsId = new uint[](proposalsName.length);
      for (uint i = 0; i < proposalsName.length; i++) {
        uint proposalId = searchProposalId(proposalsName[i]);
        proposalsId[i]=proposalId;
      }
    }

    function searchProposalId(bytes32 proposalName) public view
          returns (uint proposalId) {
      for (uint i = 0; i < proposals.length; i++) {
          if(proposals[i].proposalName == proposalName){
            proposalId = proposals[i].proposalId;
          }
      }
    }

     
    function proposalsRank() public view
          returns (uint[] rankByProposalId,
          bytes32[] rankByName,
          uint[] rankByvoteCount) {

    uint n = proposals.length;
    Proposal[] memory arr = new Proposal[](n);

    uint i;
    for(i=0; i<n; i++) {
      arr[i] = proposals[i];
    }

    uint[] memory stack = new uint[](n+ 2);

     
    uint top = 1;
    stack[top] = 0;
    top = top + 1;
    stack[top] = n-1;

     
    while (top > 0) {

      uint h = stack[top];
      top = top - 1;
      uint l = stack[top];
      top = top - 1;

      i = l;
      uint x = arr[h].voteCount;

      for(uint j=l; j<h; j++){
        if  (arr[j].voteCount <= x) {
           
          (arr[i], arr[j]) = (arr[j],arr[i]);
          i = i + 1;
        }
      }
      (arr[i], arr[h]) = (arr[h],arr[i]);
      uint p = i;

       
      if (p > l + 1) {
        top = top + 1;
        stack[top] = l;
        top = top + 1;
        stack[top] = p - 1;
      }

       
      if (p+1 < h) {
        top = top + 1;
        stack[top] = p + 1;
        top = top + 1;
        stack[top] = h;
      }
    }

    rankByProposalId = new uint[](n);
    rankByName = new bytes32[](n);
    rankByvoteCount = new uint[](n);
    for(i=0; i<n; i++) {
      rankByProposalId[i]= arr[n-1-i].proposalId;
      rankByName[i]=arr[n-1-i].proposalName;
      rankByvoteCount[i]=arr[n-1-i].voteCount;
    }
  }
}