 

pragma solidity ^0.4.11;

contract owned {

	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) throw;
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ICofounditToken {
	function mintTokens(address _to, uint256 _amount, string _reason);
	function totalSupply() constant returns (uint256 totalSupply);
}

contract CofounditICO is owned{

	uint256 public startBlock;
	uint256 public endBlock;
	uint256 public minEthToRaise;
	uint256 public maxEthToRaise;
	uint256 public totalEthRaised;
	address public multisigAddress;

	uint256 public icoSupply;
	uint256 public strategicReserveSupply;
	uint256 public cashilaTokenSupply;
	uint256 public iconomiTokenSupply;
	uint256 public coreTeamTokenSupply;

	ICofounditToken cofounditTokenContract;	
	mapping (address => bool) presaleContributorAllowance;
	uint256 nextFreeParticipantIndex;
	mapping (uint => address) participantIndex;
	mapping (address => uint256) participantContribution;

	uint256 usedIcoSupply;
	uint256 usedStrategicReserveSupply;
	uint256 usedCashilaTokenSupply;
	uint256 usedIconomiTokenSupply;
	uint256 usedCoreTeamTokenSupply;

	bool icoHasStarted;
	bool minTresholdReached;
	bool icoHasSucessfulyEnded;

	uint256 lastEthReturnIndex;
	mapping (address => bool) hasClaimedEthWhenFail;
	uint256 lastCfiIssuanceIndex;

	string icoStartedMessage = "Cofoundit is launching!";
	string icoMinTresholdReachedMessage = "Firing Stage 2!";
	string icoEndedSuccessfulyMessage = "Orbit achieved!";
	string icoEndedSuccessfulyWithCapMessage = "Leaving Earth orbit!";
	string icoFailedMessage = "Rocket crashed.";

	event ICOStarted(uint256 _blockNumber, string _message);
	event ICOMinTresholdReached(uint256 _blockNumber, string _message);
	event ICOEndedSuccessfuly(uint256 _blockNumber, uint256 _amountRaised, string _message);
	event ICOFailed(uint256 _blockNumber, uint256 _ammountRaised, string _message);
	event ErrorSendingETH(address _from, uint256 _amount);

	function CofounditICO(uint256 _startBlock, uint256 _endBlock, address _multisigAddress) {
		startBlock = _startBlock;
		endBlock = _endBlock;
		minEthToRaise = 4525 * 10**18;
		maxEthToRaise = 56565 * 10**18;
		multisigAddress = _multisigAddress;

		icoSupply =	 				125000000 * 10**18;
		strategicReserveSupply = 	125000000 * 10**18;
		cashilaTokenSupply = 		100000000 * 10**18;
		iconomiTokenSupply = 		50000000 * 10**18;
		coreTeamTokenSupply =		100000000 * 10**18;
	}

	 
	  	
	 

	  	
	function () payable { 		
		if (msg.value == 0) throw;  												 
		if (icoHasSucessfulyEnded || block.number > endBlock) throw;				 
		if (!icoHasStarted){														 
			if (block.number < startBlock){											 
				if (!presaleContributorAllowance[msg.sender]) throw;				 
			} 			
			else{																	 
				icoHasStarted = true;												 
				ICOStarted(block.number, icoStartedMessage);						 
			} 		
		} 		
		if (participantContribution[msg.sender] == 0){ 								 
			participantIndex[nextFreeParticipantIndex] = msg.sender;				 
			nextFreeParticipantIndex += 1; 		
		} 		
		if (maxEthToRaise > (totalEthRaised + msg.value)){							 
			participantContribution[msg.sender] += msg.value;						 
			totalEthRaised += msg.value;											 
			if (!minTresholdReached && totalEthRaised >= minEthToRaise){			 
				ICOMinTresholdReached(block.number, icoMinTresholdReachedMessage);	 
				minTresholdReached = true;											 
			} 		
		}else{																		 
			uint maxContribution = maxEthToRaise - totalEthRaised; 					 
			participantContribution[msg.sender] += maxContribution;					 
			totalEthRaised += maxContribution;													
			uint toReturn = msg.value - maxContribution;							 
			icoHasSucessfulyEnded = true;											 
			ICOEndedSuccessfuly(block.number, totalEthRaised, icoEndedSuccessfulyWithCapMessage); 			
			if(!msg.sender.send(toReturn)){											 
				ErrorSendingETH(msg.sender, toReturn);								 
			} 		
		}																			 
	} 	

	  	
	function claimEthIfFailed(){ 		
		if (block.number <= endBlock || totalEthRaised >= minEthToRaise) throw;	 
		if (participantContribution[msg.sender] == 0) throw;					 
		if (hasClaimedEthWhenFail[msg.sender]) throw;							 
		uint256 ethContributed = participantContribution[msg.sender];			 
		hasClaimedEthWhenFail[msg.sender] = true; 		
		if (!msg.sender.send(ethContributed)){ 			
			ErrorSendingETH(msg.sender, ethContributed);						 
		} 	
	} 	

	 
	  	
	 

	  	
	function addPresaleContributors(address[] _presaleContributors) onlyOwner { 		
		for (uint cnt = 0; cnt < _presaleContributors.length; cnt++){ 			
			presaleContributorAllowance[_presaleContributors[cnt]] = true; 		
		} 	
	} 	

	  	
	function batchIssueTokens(uint256 _numberOfIssuances) onlyOwner{ 		
		if (!icoHasSucessfulyEnded) throw;																				 
		address currentParticipantAddress; 		
		uint256 tokensToBeIssued; 		
		for (uint cnt = 0; cnt < _numberOfIssuances; cnt++){ 			
			currentParticipantAddress = participantIndex[lastCfiIssuanceIndex];	 
			if (currentParticipantAddress == 0x0) continue; 			
			tokensToBeIssued = icoSupply * participantContribution[currentParticipantAddress] / totalEthRaised;		 
			cofounditTokenContract.mintTokens(currentParticipantAddress, tokensToBeIssued, "Ico participation mint");	 
			lastCfiIssuanceIndex += 1;	
		} 

		if (participantIndex[lastCfiIssuanceIndex] == 0x0 && cofounditTokenContract.totalSupply() < icoSupply){
			uint divisionDifference = icoSupply - cofounditTokenContract.totalSupply();
			cofounditTokenContract.mintTokens(multisigAddress, divisionDifference, "Mint division error");	 
		}
	} 	

	  	
	function batchReturnEthIfFailed(uint256 _numberOfReturns) onlyOwner{ 		
		if (block.number < endBlock || totalEthRaised >= minEthToRaise) throw;		 
		address currentParticipantAddress; 		
		uint256 contribution;
		for (uint cnt = 0; cnt < _numberOfReturns; cnt++){ 			
			currentParticipantAddress = participantIndex[lastEthReturnIndex];		 
			if (currentParticipantAddress == 0x0) return;							 
			if (!hasClaimedEthWhenFail[currentParticipantAddress]) {				 
				contribution = participantContribution[currentParticipantAddress];	 
				hasClaimedEthWhenFail[msg.sender] = true;							 
				if (!currentParticipantAddress.send(contribution)){					 
					ErrorSendingETH(currentParticipantAddress, contribution);		 
				} 			
			} 			
			lastEthReturnIndex += 1; 		
		} 	
	} 	

	 
	function changeMultisigAddress(address _newAddress) onlyOwner { 		
		multisigAddress = _newAddress;
	} 	

	  	
	function claimReservedTokens(string _which, address _to, uint256 _amount, string _reason) onlyOwner{ 		
		if (!icoHasSucessfulyEnded) throw;                 
		bytes32 hashedStr = sha3(_which);				
		if (hashedStr == sha3("Reserve")){ 			
			if (_amount > strategicReserveSupply - usedStrategicReserveSupply) throw; 			
			cofounditTokenContract.mintTokens(_to, _amount, _reason); 			
			usedStrategicReserveSupply += _amount; 		
		} 		
		else if (hashedStr == sha3("Cashila")){ 			
			if (_amount > cashilaTokenSupply - usedCashilaTokenSupply) throw; 			
			cofounditTokenContract.mintTokens(_to, _amount, "Reserved tokens for cashila"); 			
			usedCashilaTokenSupply += _amount; 		} 		
		else if (hashedStr == sha3("Iconomi")){ 			
			if (_amount > iconomiTokenSupply - usedIconomiTokenSupply) throw; 			
			cofounditTokenContract.mintTokens(_to, _amount, "Reserved tokens for iconomi"); 			
			usedIconomiTokenSupply += _amount; 		
		}
		else if (hashedStr == sha3("Core")){ 			
			if (_amount > coreTeamTokenSupply - usedCoreTeamTokenSupply) throw; 			
			cofounditTokenContract.mintTokens(_to, _amount, "Reserved tokens for cofoundit team"); 			
			usedCoreTeamTokenSupply += _amount; 		
		} 		
		else throw; 	
	} 	

	  	
	function removePresaleContributor(address _presaleContributor) onlyOwner { 		
		presaleContributorAllowance[_presaleContributor] = false; 	
	} 	

	  	
	function setTokenContract(address _cofounditContractAddress) onlyOwner { 		
		cofounditTokenContract = ICofounditToken(_cofounditContractAddress); 	
	} 	

	  	
	function withdrawEth() onlyOwner{ 		
		if (this.balance == 0) throw;				 
		if (totalEthRaised < minEthToRaise) throw;	 
		if (block.number > endBlock){				 
			icoHasSucessfulyEnded = true; 			
			ICOEndedSuccessfuly(block.number, totalEthRaised, icoEndedSuccessfulyMessage); 		
		} 		
		if(multisigAddress.send(this.balance)){}		 
	} 	

	  	
	function withdrawRemainingBalanceForManualRecovery() onlyOwner{ 		
		if (this.balance == 0) throw;											 
		if (block.number < endBlock || totalEthRaised >= minEthToRaise) throw;	 
		if (participantIndex[lastEthReturnIndex] != 0x0) throw;					 
		if(multisigAddress.send(this.balance)){}								 
	} 	

	 
	  	
	 

	function getCfiEstimation(address _querryAddress) constant returns (uint256 answer){ 		
		return icoSupply * participantContribution[_querryAddress] / totalEthRaised; 	
	} 	

	function getCofounditTokenAddress() constant returns(address _tokenAddress){ 		
		return address(cofounditTokenContract); 	
	} 	

	function icoInProgress() constant returns (bool answer){ 		
		return icoHasStarted && !icoHasSucessfulyEnded; 	
	} 	

	function isAddressAllowedInPresale(address _querryAddress) constant returns (bool answer){ 		
		return presaleContributorAllowance[_querryAddress]; 	
	} 	

	function participantContributionInEth(address _querryAddress) constant returns (uint256 answer){ 		
		return participantContribution[_querryAddress]; 	
	}

	 
	 
	 
	 
	 
	 
}