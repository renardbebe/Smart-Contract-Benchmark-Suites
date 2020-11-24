 

pragma solidity ^0.4.11;

library SafeMath {
     
     
     
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
	
}

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) returns (bool success) ;
	function balanceOf(address _owner) constant returns (uint256 balance);
}

contract IQTCrowdsale is Owned{
    using SafeMath for uint256;
    using SafeMath for uint;
	
	struct ContributorData{
		bool isActive;
		bool isTokenDistributed;
		uint contributionAmount;	 
		uint tokensAmount;			 
	}
	
	mapping(address => ContributorData) public contributorList;
	mapping(uint => address) contributorIndexes;
	uint nextContributorIndex;
	uint contributorCount;
    
    address public beneficiary;
    uint public fundingLimit;
    uint public amountRaised;
	uint public remainAmount;
    uint public deadline;
    uint public exchangeTokenRate;
    token public tokenReward;
	uint256 public tokenBalance;
    bool public crowdsaleClosed = false;
    bool public isIQTDistributed = false;
    

     
     
     
     
     
     
     
     
    uint public constant START_TIME = 1506340800;
    uint public constant SECOND_TIER_SALE_START_TIME = 1506787200;
    uint public constant THIRD_TIER_SALE_START_TIME = 1507651200;
    uint public constant FOURTH_TIER_SALE_START_TIME = 1508515200;
    uint public constant END_TIME = 1511611200;
	
	
    
     
     
     
    uint public START_RATE = 900;
    uint public SECOND_TIER_RATE = 850;
    uint public THIRD_TIER_RATE = 800;
    uint public FOURTH_RATE = 700;
    

     
     
     
     
    uint public constant FUNDING_ETH_HARD_CAP = 33000;
    
     
    uint8 public constant IQT_DECIMALS = 8;
    uint public constant IQT_DECIMALSFACTOR = 10**uint(IQT_DECIMALS);
    
    address public constant IQT_FUNDATION_ADDRESS = 0xB58d67ced1E480aC7FBAf70dc2b023e30140fBB4;
    address public constant IQT_CONTRACT_ADDRESS = 0x51ee82641Ac238BDe34B9859f98F5F311d6E4954;

    event GoalReached(address raisingAddress, uint amountRaised);
	event LimitReached(address raisingAddress, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
	event WithdrawFailed(address raisingAddress, uint amount, bool isContribution);
	event FundReturn(address backer, uint amount, bool isContribution);

     
    function IQTCrowdsale(
    ) {
        beneficiary = IQT_FUNDATION_ADDRESS;
        fundingLimit = FUNDING_ETH_HARD_CAP * 1 ether;   
		
        deadline = END_TIME;   
        exchangeTokenRate = FOURTH_RATE * IQT_DECIMALSFACTOR;
        tokenReward = token(IQT_CONTRACT_ADDRESS);
		contributorCount = 0;
    }

     
    function () payable {
		
        require(!crowdsaleClosed);
        require(now >= START_TIME && now < END_TIME);
        
		processTransaction(msg.sender, msg.value);
    }
	
	 
	function processTransaction(address _contributor, uint _amount) internal{	
		uint contributionEthAmount = _amount;
			
        amountRaised += contributionEthAmount;                     
		remainAmount += contributionEthAmount;
        
		 
        if (now >= START_TIME && now < SECOND_TIER_SALE_START_TIME){
			exchangeTokenRate = START_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= SECOND_TIER_SALE_START_TIME && now < THIRD_TIER_SALE_START_TIME){
            exchangeTokenRate = SECOND_TIER_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= THIRD_TIER_SALE_START_TIME && now < FOURTH_TIER_SALE_START_TIME){
            exchangeTokenRate = THIRD_TIER_RATE * IQT_DECIMALSFACTOR;
        }
        if (now >= FOURTH_TIER_SALE_START_TIME && now < END_TIME){
            exchangeTokenRate = FOURTH_RATE * IQT_DECIMALSFACTOR;
        }
        uint amountIqtToken = _amount * exchangeTokenRate / 1 ether;
		
		if (contributorList[_contributor].isActive == false){                   
			contributorList[_contributor].isActive = true;                             
			contributorList[_contributor].contributionAmount = contributionEthAmount;     
			contributorList[_contributor].tokensAmount = amountIqtToken;
			contributorList[_contributor].isTokenDistributed = false;
			contributorIndexes[nextContributorIndex] = _contributor;                   
			nextContributorIndex++;
			contributorCount++;
		}
		else{
			contributorList[_contributor].contributionAmount += contributionEthAmount;    
			contributorList[_contributor].tokensAmount += amountIqtToken;              
		}
		
        FundTransfer(msg.sender, contributionEthAmount, true);
		
		if (amountRaised >= fundingLimit){
			 
			crowdsaleClosed = true;
		}		
		
	}

    modifier afterDeadline() { if (now >= deadline) _; }	
	modifier afterCrowdsaleClosed() { if (crowdsaleClosed == true || now >= deadline) _; }
	
	
	 
	function closeCrowdSale(){
		require(beneficiary == msg.sender);
		if ( beneficiary == msg.sender) {
			crowdsaleClosed = true;
		}
	}
	
     
	function checkTokenBalance(){
		if ( beneficiary == msg.sender) {
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
     
    function safeWithdrawalAll() {
        if ( beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
				remainAmount = remainAmount - amountRaised;
            } else {
				WithdrawFailed(beneficiary, amountRaised, false);
				 
            }
        }
    }
	
	 
    function safeWithdrawalAmount(uint256 withdrawAmount) {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(withdrawAmount)) {
                FundTransfer(beneficiary, withdrawAmount, false);
				remainAmount = remainAmount - withdrawAmount;
            } else {
				WithdrawFailed(beneficiary, withdrawAmount, false);
				 
            }
        }
    }
	
	 
    function withdrawIQT(uint256 tokenAmount) afterCrowdsaleClosed {
		require(beneficiary == msg.sender);
        if (isIQTDistributed && beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, tokenAmount);
			 
			tokenBalance = tokenReward.balanceOf(address(this));
        }
    }
	

	 
	function distributeIQTToken() {
		if (beneficiary == msg.sender) {   
			address currentParticipantAddress;
			for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountIqtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountIqtToken);
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			 
			checkIfAllIQTDistributed();
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	 
	function distributeIQTTokenBatch(uint batchUserCount) {
		if (beneficiary == msg.sender) {   
			address currentParticipantAddress;
			uint transferedUserCount = 0;
			for (uint index = 0; index < contributorCount && transferedUserCount<batchUserCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountIqtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountIqtToken);
					transferedUserCount = transferedUserCount + 1;
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			 
			checkIfAllIQTDistributed();
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	 
	function checkIfAllIQTDistributed(){
	    address currentParticipantAddress;
		isIQTDistributed = true;
		for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
			if (false == contributorList[currentParticipantAddress].isTokenDistributed){
				isIQTDistributed = false;
				break;
			}
		}
	}
	
}