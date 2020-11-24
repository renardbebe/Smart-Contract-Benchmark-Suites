 

pragma solidity ^0.4.18;

contract Ownable {

	 
	address owner;

	modifier onlyOwner() {
		require (msg.sender == owner);
		_;
	}

	 
	function Ownable() public {
		owner = msg.sender;
	}

	 
	function getOwner() public constant returns(address) {
		return owner;
	}

	 
	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		owner = newOwner;
	}
}

contract ICKBase {

	function ownerOf(uint256) public pure returns (address);
}

contract IKittyKendoStorage {

	function createProposal(uint proposal, address proposalOwner) public;
	function createVoter(address account) public;

	function updateProposalOwner(uint proposal, address voter) public;

	function voterExists(address voter) public constant returns (bool);
	function proposalExists(uint proposal) public constant returns (bool);

	function proposalOwner(uint proposal) public constant returns (address);
	function proposalCreateTime(uint proposal) public constant returns (uint);

	function voterVotingTime(address voter) public constant returns (uint);

	function addProposalVote(uint proposal, address voter) public;
	function addVoterVote(address voter) public;

	function updateVoterTimes(address voter, uint time) public;

	function getProposalTTL() public constant returns (uint);
	function setProposalTTL(uint time) public;

	function getVotesPerProposal() public constant returns (uint);
	function setVotesPerProposal(uint votes) public;

	function getTotalProposalsCount() public constant returns(uint);
	function getTotalVotersCount() public constant returns(uint);

	function getProposalVotersCount(uint proposal) public constant returns(uint);
	function getProposalVotesCount(uint proposal) public constant returns(uint);
	function getProposalVoterVotesCount(uint proposal, address voter) public constant returns(uint);

	function getVoterProposalsCount(address voter) public constant returns(uint);
	function getVoterVotesCount(address voter) public constant returns(uint);
	function getVoterProposal(address voter, uint index) public constant returns(uint);
}

contract KittyKendoCore is Ownable {

	IKittyKendoStorage kks;
	address kksAddress;

	 
	event VotesRecorded (
		address indexed from,
		uint[] votes
	);

	 
	event ProposalAdded (
		address indexed from,
		uint indexed proposal
	);

	 
	uint fee;

	 
	function KittyKendoCore() public {
		fee = 0;
		kksAddress = address(0);
	}
	
	 
	function storageAddress() onlyOwner public constant returns(address) {
		return kksAddress;
	}

	 
	function setStorageAddress(address addr) onlyOwner public {
		kksAddress = addr;
		kks = IKittyKendoStorage(kksAddress);
	}

	 
	function getFee() public constant returns(uint) {
		return fee;
	}

	 
	function setFee(uint val) onlyOwner public {
		fee = val;
	}

	 
	function withdraw(uint amount) onlyOwner public {
		require(amount <= address(this).balance);
		owner.transfer(amount);
	}
	
	 
	function getBalance() onlyOwner public constant returns(uint) {
	    return address(this).balance;
	}

	 
	function registerProposal(uint proposal, uint[] votes) public payable {

		 
		require(msg.value >= fee);

		recordVotes(votes);

		if (proposal > 0) {
			addProposal(proposal);
		}
	}

	 
	function recordVotes(uint[] votes) private {

        require(kksAddress != address(0));

		 
		if (!kks.voterExists(msg.sender)) {
			kks.createVoter(msg.sender);
		}

		 
		for (uint i = 0; i < votes.length; i++) {
			 
			if (kks.proposalExists(votes[i])) {
				 
				require(kks.proposalOwner(votes[i]) != msg.sender);

				 
				if (kks.proposalCreateTime(votes[i]) + kks.getProposalTTL() <= now) {
					continue;
				}

				 
				require(kks.getProposalVoterVotesCount(votes[i], msg.sender) == uint(0));

				 
				kks.addProposalVote(votes[i], msg.sender);
			}

			 
			kks.addVoterVote(msg.sender);
		}

		 
		kks.updateVoterTimes(msg.sender, now);

		 
		VotesRecorded(msg.sender, votes);
	}

	 
	function addProposal(uint proposal) private {

        require(kksAddress != address(0));

		 
		require(kks.voterExists(msg.sender));

		 
		require(kks.getVoterVotesCount(msg.sender) / kks.getVotesPerProposal() > kks.getVoterProposalsCount(msg.sender));

		 
		 

		 
		require(getCKOwner(proposal) == msg.sender);

		 
		if (!kks.proposalExists(proposal)) {
			 
			kks.createProposal(proposal, msg.sender);
		} else {
			 
			kks.updateProposalOwner(proposal, msg.sender);
		}

		 
		ProposalAdded(msg.sender, proposal);
	}

	 
	function getCKOwner(uint proposal) private pure returns(address) {
		ICKBase ckBase = ICKBase(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
		return ckBase.ownerOf(uint256(proposal));
	}

}