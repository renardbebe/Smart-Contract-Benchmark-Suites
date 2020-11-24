 

 

 

pragma solidity ^0.4.22;

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

 
contract System {
	using SafeMath for uint256;
	
	address owner;
	
	 

	 
	modifier onlyOwner() {
		if (msg.sender != owner) {
			error('System: onlyOwner function called by user that is not owner');
		} else {
			_;
		}
	}

	 
	modifier onlyOwnerOrigin() {
		if (msg.sender != owner && tx.origin != owner) {
			error('System: onlyOwnerOrigin function called by user that is not owner nor a contract called by owner at origin');
		} else {
			_;
		}
	}
	
	
	 
	
	 
	function error(string _error) internal {
		 
		 
			emit Error(_error);
			 
	}

	 
	function whoAmI() public constant returns (address) {
		return msg.sender;
	}
	
	 
	function timestamp() public constant returns (uint256) {
		return block.timestamp;
	}
	
	 
	function contractBalance() public constant returns (uint256) {
		return address(this).balance;
	}
	
	 
	constructor() public {
		 
		owner = msg.sender;
		
		 
		if(owner == 0x0) error('System constructor: Owner address is 0x0');  
	}
	
	 

	 
	event Error(string _error);

	 
	event DebugUint256(uint256 _data);

}

 
contract Haltable is System {
	bool public halted;
	
	 

	modifier stopInEmergency {
		if (halted) {
			error('Haltable: stopInEmergency function called and contract is halted');
		} else {
			_;
		}
	}

	modifier onlyInEmergency {
		if (!halted) {
			error('Haltable: onlyInEmergency function called and contract is not halted');
		} {
			_;
		}
	}

	 
	
	 
	function halt() external onlyOwner {
		halted = true;
		emit Halt(true, msg.sender, timestamp());  
	}

	 
	function unhalt() external onlyOwner onlyInEmergency {
		halted = false;
		emit Halt(false, msg.sender, timestamp());  
	}
	
	 
	 
	event Halt(bool _switch, address _halter, uint256 _timestamp);
}
  

 


 
contract Oracles is Haltable {
	 
	struct oracle {
		uint256 oracleId;
		bool oracleAuth;
		address oracleAddress;
	}
	mapping (address => oracle) oracleData;
	mapping (uint256 => address) oracleAddressById;  
	uint256 lastId;


	 

	 
	function isOracle(address _oracle) public constant returns (bool) {
		return (oracleData[_oracle].oracleAuth);
	}

	function newOracle(address _oracle) internal onlyOwner returns (uint256 id) {
		 
		id = ++lastId;
		oracleData[_oracle].oracleId = id;
		oracleData[_oracle].oracleAuth = false;
		oracleData[_oracle].oracleAddress = _oracle;
		oracleAddressById[id] = _oracle;

		emit NewOracle(_oracle, id, timestamp());  
	}

	function grantOracle(address _oracle) public onlyOwner {
		 
		uint256 id;
		if (oracleData[_oracle].oracleId > 0) {
			id = oracleData[_oracle].oracleId;
		} else {
			id = newOracle(_oracle);
		}

		oracleData[_oracle].oracleAuth = true;

		emit GrantOracle(_oracle, id, timestamp());  
	}

	function revokeOracle(address _oracle) external onlyOwner {
		oracleData[_oracle].oracleAuth = false;

		emit RevokeOracle(_oracle, timestamp());  
	}

	 
	function getOracleByAddress(address _oracle) public constant returns (uint256 _oracleId, bool _oracleAuth, address _oracleAddress) {
		return (oracleData[_oracle].oracleId, oracleData[_oracle].oracleAuth, oracleData[_oracle].oracleAddress);
	}

	 
	function getOracleById(uint256 id) public constant returns (uint256 _oracleId, bool _oracleAuth, address _oracleAddress) {
		return (getOracleByAddress(oracleAddressById[id]));
	}


	 

	 
	event NewOracle(address indexed _who, uint256 indexed _id, uint256 _timestamp);

	 
	event GrantOracle(address indexed _who, uint256 indexed _id, uint256 _timestamp);

	 
	event RevokeOracle(address indexed _who, uint256 _timestamp);
}

   

 





 
contract Tellers is Oracles {
	 
	address[] public tellersArray;  
	mapping (address => bytes) public pubKeys;
	bytes[] public pubKeysArray;  

	function grantTeller(address _teller, bytes _pubKey) external onlyOwner {
		 
		if (keccak256(pubKeys[_teller]) != keccak256("")) {  
			error('grantTeller: This teller is already granted');
		}

		tellersArray.push(_teller);
		pubKeys[_teller] = _pubKey;
		pubKeysArray.push(_pubKey);

		grantOracle(_teller);  

		emit GrantTeller(_teller, _pubKey, timestamp());  
	}

	 
	event GrantTeller(address indexed _who, bytes _pubKey, uint256 _timestamp);
}


   

 




 
contract Voting is Haltable {
	 
	mapping (address => string) votes;
	uint256 public numVotes;

	mapping (address => bool) allowed;  
	address[] votersArray;
	uint256 public numVoters;

	uint256 public deadline;
	eVotingStatus public VotingStatus;  
	enum eVotingStatus { Test, Voting, Closed }


	Oracles public SCOracles;  
	Tellers public SCTellers;  

	mapping (address => bytes) public pubKeys;  


	 
	modifier votingClosed() { if (now >= deadline || VotingStatus == eVotingStatus.Closed) _; }
	modifier votingActive() { if (now < deadline && VotingStatus != eVotingStatus.Closed) _; }

	 
	modifier onlyOracle() {
		if (!SCOracles.isOracle(msg.sender)) {
			error('onlyOracle function called by user that is not an authorized oracle');
		} else {
			_;
		}
	}

	 
	modifier onlyTeller() {
		if (!SCTellers.isOracle(msg.sender)) {
			error('onlyTeller function called by user that is not an authorized teller');
		} else {
			_;
		}
	}


	 
	constructor(address _SCOracles, address _SCTellers) public {
		SCOracles = Oracles(_SCOracles);
		SCTellers = Tellers(_SCTellers);
		deadline = now + 60 days;
		VotingStatus = eVotingStatus.Test;
	}

	function pollStatus() public constant returns (eVotingStatus) {
		if (now >= deadline) {
			return eVotingStatus.Closed;
		}
		return VotingStatus;
	}

	function isACitizen(address _voter) public constant returns (bool) {
		if (allowed[_voter]) {
			return true;
		} else {
			return false;
		}
	}

	function amIACitizen() public constant returns (bool) {
		return (isACitizen(msg.sender));
	}

	function canItVote(address _voter) internal constant returns (bool) {
		if (bytes(votes[_voter]).length == 0) {
			return true;
		} else {
			return false;
		}
	}

	function canIVote() public constant returns (bool) {
		return (canItVote(msg.sender));
	}

	function sendVote(string _vote) votingActive public returns (bool) {
		 
		if (!canIVote()) {
			error('sendVote: sender cannot vote because it has previously casted another vote');
			return false;
		}

		 
		if (bytes(_vote).length < 1) {
			error('sendVote: vote is empty');
			return false;
		}

		 
		votes[msg.sender] = _vote;
		numVotes ++;

		emit SendVote(msg.sender, _vote);  

		return true;
	}

	function getVoter(uint256 _idVoter)   public constant returns (address) {
		return (votersArray[_idVoter]);
	}

	function readVote(address _voter)   public constant returns (string) {
		return (votes[_voter]);
	}

	 
	function _grantVoter(address _voter) onlyOracle public {
		if(!allowed[_voter]) {
			allowed[_voter] = true;
			votersArray.push(_voter);
			numVoters ++;

			emit GrantVoter(_voter);  
		}
	}

	 
	function grantVoter(address _voter, bytes _pubKey) onlyOracle public {
		_grantVoter(_voter);

		pubKeys[_voter] = _pubKey;
	}

	function getVoterPubKey(address _voter) public constant returns (bytes) {
		return (pubKeys[_voter]);
	}

	function closeVoting() onlyTeller public {
		VotingStatus = eVotingStatus.Closed;

		emit CloseVoting(true);  
	}

	function endTesting() onlyTeller public {
		numVotes = 0;
		uint256 l = votersArray.length;
		for(uint256 i = 0;i<l;i++) {
			delete votes[votersArray[i]];
		}
		VotingStatus = eVotingStatus.Voting;
	}

	 
	function () payable public {
		revert();
	}


	 
	 
	event SendVote(address indexed _from, string _vote);

	 
	event GrantVoter(address indexed _voter);

	 
	event CloseVoting(bool _VotingClosed);
}