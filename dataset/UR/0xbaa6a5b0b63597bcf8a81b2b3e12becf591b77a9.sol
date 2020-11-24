 

pragma solidity ^0.5.0;

interface ICustodian {
	function users(uint) external returns(address);
	function totalUsers() external returns (uint);
	function totalSupplyA() external returns (uint);
	function totalSupplyB() external returns (uint);
	function balanceOf(uint, address) external returns (uint);
	function allowance(uint, address, address) external returns (uint);
	function transfer(uint, address, address, uint) external returns (bool);
	function transferFrom(uint, address, address, address, uint) external returns (bool);
	function approve(uint, address, address, uint) external returns (bool);
}

 
 
contract Esplanade {

	 
	uint constant WEI_DENOMINATOR = 1000000000000000000;
	uint constant BP_DENOMINATOR = 10000;
	uint constant MIN_POOL_SIZE = 5;
	uint constant VOTE_TIME_OUT = 2 hours;
	uint constant COLD_POOL_IDX = 0;
	uint constant HOT_POOL_IDX = 1;
	uint constant NEW_STATUS = 0;
	uint constant IN_COLD_POOL_STATUS = 1;
	uint constant IN_HOT_POOL_STATUS = 2;
	uint constant USED_STATUS = 3;
	enum VotingStage {
        NotStarted,
		Moderator,
		Contract
    }
	 
	VotingStage public votingStage;
	address public moderator;
	 
	 
	address [][] public addrPool =[   
		[
			0xAc31E7Bc5F730E460C6B2b50617F421050265ece,
            0x39426997B2B5f0c8cad0C6e571a2c02A6510d67b,
            0x292B0E0060adBa58cCA9148029a79D5496950c9D,
            0x835B8D6b7b62240000491f7f0B319204BD5dDB25,
            0x8E0E4DE505ee21ECA63fAF762B48D774E8BB8f51,
            0x8750A35A4FB67EE5dE3c02ec35d5eA59193034f5,
            0x8849eD77E94B075D89bB67D8ef98D80A8761d913,
            0x2454Da2d95FBA41C3a901D8ce69D0fdC8dA8274e,
            0x56F08EE15a4CBB8d35F82a44d288D08F8b924c8b
		],
		[
            0x709494F5766a7e280A24cF15e7feBA9fbadBe7F5,
            0xF7029296a1dA0388b0b637127F241DD11901f2af,
            0xE266581CDe8468915D9c9F42Be3DcEd51db000E0,
            0x37c521F852dbeFf9eC93991fFcE91b2b836Ad549,
            0x2fEF2469937EeA7B126bC888D8e02d762D8c7e16,
            0x249c1daD9c31475739fBF08C95C2DCB137135957,
            0x8442Dda926BFb4Aeba526D4d1e8448c762cf4A0c,
            0xe71DA90BC3cb2dBa52bacfBbA7b973260AAAFc05,
            0xd3FA38302b0458Bf4E1405D209F30db891eBE038
		]
	];
	 
	 
	 
	 
	mapping(address => uint) public addrStatus; 
	address[] public custodianPool;
	mapping(address => bool) public existingCustodians;
	address[] public otherContractPool;
	mapping(address => bool) public existingOtherContracts;
	uint public operatorCoolDown = 1 hours;
	uint public lastOperationTime;
	bool public started;

	address public candidate;
	mapping(address => bool) public passedContract;
	mapping(address => bool) public voted;
	uint public votedFor;
	uint public votedAgainst;
	uint public voteStartTimestamp;

	 
	modifier only(address addr) {
		require(msg.sender == addr);
		_;
	}

	modifier inColdAddrPool() {
		require(addrStatus[msg.sender] == IN_COLD_POOL_STATUS);
		_;
	}

	modifier inHotAddrPool() {
		require(addrStatus[msg.sender] == IN_HOT_POOL_STATUS);
		_;
	}

	modifier isValidRequestor(address origin) {
		address requestorAddr = msg.sender;
		require((existingCustodians[requestorAddr] 
		|| existingOtherContracts[requestorAddr]) 
		&& addrStatus[origin] == IN_COLD_POOL_STATUS);
		_;
	}

	modifier inUpdateWindow() {
		uint currentTime = getNowTimestamp();
		if (started)
			require(currentTime - lastOperationTime >= operatorCoolDown);
		_;
		lastOperationTime = currentTime;
	}

	modifier inVotingStage(VotingStage _stage) {
		require(votingStage == _stage);
		_;
	}

	modifier allowedToVote() {
		address voterAddr = msg.sender;
		require(!voted[voterAddr] && addrStatus[voterAddr] == 1);
		_;
	}

	 
	event AddAddress(uint poolIndex, address added1, address added2);
	event RemoveAddress(uint poolIndex, address addr);
	event ProvideAddress(uint poolIndex, address requestor, address origin, address addr);
	event AddCustodian(address newCustodianAddr);
	event AddOtherContract(address newContractAddr);
	event StartContractVoting(address proposer, address newContractAddr);
	event TerminateContractVoting(address terminator, address currentCandidate);
	event StartModeratorVoting(address proposer);
	event TerminateByTimeOut(address candidate);
	event Vote(address voter, address candidate, bool voteFor, uint votedFor, uint votedAgainst);
	event CompleteVoting(bool isContractVoting, address newAddress);
	event ReplaceModerator(address oldModerator, address newModerator);

	 
	 
	 
	constructor(uint optCoolDown) public 
	{	
		votingStage = VotingStage.NotStarted;
		moderator = msg.sender;
		addrStatus[moderator] = USED_STATUS;
		for (uint i = 0; i < addrPool[COLD_POOL_IDX].length; i++) 
			addrStatus[addrPool[COLD_POOL_IDX][i]] = IN_COLD_POOL_STATUS;
		for (uint j = 0; j < addrPool[HOT_POOL_IDX].length; j++) 
			addrStatus[addrPool[HOT_POOL_IDX][j]] = IN_HOT_POOL_STATUS;
		operatorCoolDown = optCoolDown;
	}

	 
	 
	 
	function startContractVoting(address addr) 
		public 
		only(moderator) 
		inVotingStage(VotingStage.NotStarted) 
	returns (bool) {
		require(addrStatus[addr] == NEW_STATUS);
		candidate = addr;
		addrStatus[addr] = USED_STATUS;
		votingStage = VotingStage.Contract;
		replaceModerator();
		startVoting();
		emit StartContractVoting(moderator, addr);
		return true;
	}

	 
	function terminateContractVoting() 
		public 
		only(moderator) 
		inVotingStage(VotingStage.Contract) 
	returns (bool) {
		votingStage = VotingStage.NotStarted;
		emit TerminateContractVoting(moderator, candidate);
		replaceModerator();
		return true;
	}

	 
	function terminateByTimeout() public returns (bool) {
		require(votingStage != VotingStage.NotStarted);
		uint nowTimestamp = getNowTimestamp();
		if (nowTimestamp > voteStartTimestamp && nowTimestamp - voteStartTimestamp > VOTE_TIME_OUT) {
			votingStage = VotingStage.NotStarted;
			emit TerminateByTimeOut(candidate);
			return true;
		} else
			return false;
	}

	 
	function startModeratorVoting() public inColdAddrPool() returns (bool) {
		candidate = msg.sender;
		votingStage = VotingStage.Moderator;
		removeFromPoolByAddr(COLD_POOL_IDX, candidate);
		startVoting();
		emit StartModeratorVoting(candidate);
		return true;
	}

	 
	function vote(bool voteFor) 
		public 
		allowedToVote() 
	returns (bool) {
		address voter = msg.sender;
		if (voteFor)
			votedFor = votedFor + 1;
		else
			votedAgainst += 1;
		voted[voter] = true;
		uint threshold = addrPool[COLD_POOL_IDX].length / 2;
		emit Vote(voter, candidate, voteFor, votedFor, votedAgainst);
		if (votedFor > threshold || votedAgainst > threshold) {
			if (votingStage == VotingStage.Contract) {
				passedContract[candidate] = true;
				emit CompleteVoting(true, candidate);
			}
			else {
				emit CompleteVoting(false, candidate);
				moderator = candidate;
			}
			votingStage = VotingStage.NotStarted;
		}
		return true;
	}

	 
	 
	function startManager() public only(moderator) returns (bool) {
		require(!started && custodianPool.length > 0);
		started = true;
		return true;
	}

	 
	 
	function addCustodian(address custodianAddr) 
		public 
		only(moderator) 
		inUpdateWindow() 
	returns (bool success) {
		require(!existingCustodians[custodianAddr] && !existingOtherContracts[custodianAddr]);
		ICustodian custodian = ICustodian(custodianAddr);
		require(custodian.totalUsers() >= 0);
		 
		uint custodianLength = custodianPool.length;
		if (custodianLength > 0) 
			replaceModerator();
		else if (!started) {
			uint index = getNextAddrIndex(COLD_POOL_IDX, custodianAddr);
			address oldModerator = moderator;
			moderator = addrPool[COLD_POOL_IDX][index];
			emit ReplaceModerator(oldModerator, moderator);
			removeFromPool(COLD_POOL_IDX, index);
		}
		existingCustodians[custodianAddr] = true;
		custodianPool.push(custodianAddr);
		addrStatus[custodianAddr] = USED_STATUS;
		emit AddCustodian(custodianAddr);
		return true;
	}

	 
	 
	function addOtherContracts(address contractAddr) 
		public 
		only(moderator) 
		inUpdateWindow() 
	returns (bool success) {
		require(!existingCustodians[contractAddr] && !existingOtherContracts[contractAddr]);		
		existingOtherContracts[contractAddr] = true;
		otherContractPool.push(contractAddr);
		addrStatus[contractAddr] = USED_STATUS;
		replaceModerator();
		emit AddOtherContract(contractAddr);
		return true;
	}

	 
	 
	 
	 
	function addAddress(address addr1, address addr2, uint poolIndex) 
		public 
		only(moderator) 
		inUpdateWindow() 
	returns (bool success) {
		require(addrStatus[addr1] == NEW_STATUS 
			&& addrStatus[addr2] == NEW_STATUS 
			&& addr1 != addr2 
			&& poolIndex < 2);
		replaceModerator();
		addrPool[poolIndex].push(addr1);
		addrStatus[addr1] = poolIndex + 1;
		addrPool[poolIndex].push(addr2);
		addrStatus[addr2] = poolIndex + 1;
		emit AddAddress(poolIndex, addr1, addr2);
		return true;
	}

	 
	 
	 
	function removeAddress(address addr, uint poolIndex) 
		public 
		only(moderator) 
		inUpdateWindow() 
	returns (bool success) {
		require(addrPool[poolIndex].length > MIN_POOL_SIZE 
			&& addrStatus[addr] == poolIndex + 1 
			&& poolIndex < 2);
		removeFromPoolByAddr(poolIndex, addr);
		replaceModerator();
		emit RemoveAddress(poolIndex, addr);
		return true;
	}

	 
	 
	 
	function provideAddress(address origin, uint poolIndex) 
		public 
		isValidRequestor(origin) 
		inUpdateWindow() 
	returns (address) {
		require(addrPool[poolIndex].length > MIN_POOL_SIZE 
			&& poolIndex < 2 
			&& custodianPool.length > 0);
		removeFromPoolByAddr(COLD_POOL_IDX, origin);
		address requestor = msg.sender;
		uint index = 0;
		 
		if (existingCustodians[requestor])
			index = getNextAddrIndex(poolIndex, requestor);
		else  
			index = getNextAddrIndex(poolIndex, custodianPool[custodianPool.length - 1]);
		address addr = addrPool[poolIndex][index];
		removeFromPool(poolIndex, index);

		emit ProvideAddress(poolIndex, requestor, origin, addr);
		return addr;
	}

	 
	 
	function startVoting() internal {
		address[] memory coldPool = addrPool[COLD_POOL_IDX];
		for (uint i = 0; i < coldPool.length; i++) 
			voted[coldPool[i]] = false;
		votedFor = 0;
		votedAgainst = 0;
		voteStartTimestamp = getNowTimestamp();
	}
	
	function replaceModerator() internal {
		require(custodianPool.length > 0);
		uint index = getNextAddrIndex(COLD_POOL_IDX, custodianPool[custodianPool.length - 1]);
		address oldModerator = moderator;
		moderator = addrPool[COLD_POOL_IDX][index];
		emit ReplaceModerator(oldModerator, moderator);
		removeFromPool(COLD_POOL_IDX, index);
	}

	 
	 
	 
	function removeFromPoolByAddr(uint poolIndex, address addr) internal {
	 	address[] memory subPool = addrPool[poolIndex];
		for (uint i = 0; i < subPool.length; i++) {
			if (subPool[i] == addr) {
				removeFromPool(poolIndex, i);
				break;
            }
		}
	}

	 
	 
	 
	function removeFromPool(uint poolIndex, uint idx) internal {
	 	address[] memory subPool = addrPool[poolIndex];
		addrStatus[subPool[idx]] = USED_STATUS;
		if (idx < subPool.length - 1)
			addrPool[poolIndex][idx] = addrPool[poolIndex][subPool.length-1];
		delete addrPool[poolIndex][subPool.length - 1];
		 
		addrPool[poolIndex].length--;
	}

	 
	 
	 
	function getNextAddrIndex(uint poolIndex, address custodianAddr) internal returns (uint) {
		uint prevHashNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))));
		ICustodian custodian = ICustodian(custodianAddr);
		uint userLength = custodian.totalUsers();
		if(userLength > 255) {
			address randomUserAddress = custodian.users(prevHashNumber % userLength);
			return uint256(keccak256(abi.encodePacked(randomUserAddress))) % addrPool[poolIndex].length;
		} else 
			return prevHashNumber % addrPool[poolIndex].length;
	}

	 
	function getNowTimestamp() internal view returns (uint) {
		return now;
	}

	 
	function getAddressPoolSizes() public view returns (uint, uint) {
		return (addrPool[COLD_POOL_IDX].length, addrPool[HOT_POOL_IDX].length);
	}

	 
	function getContractPoolSizes() public view returns (uint, uint) {
		return (custodianPool.length, otherContractPool.length);
	}
}