 

 

contract EtherVote {
    event LogVote(bytes32 indexed proposalHash, bool pro, address addr);
    function vote(bytes32 proposalHash, bool pro) {
         
        if (msg.value > 0) throw;
         
        LogVote(proposalHash, pro, msg.sender);
    }

     
    function () { throw; }
}