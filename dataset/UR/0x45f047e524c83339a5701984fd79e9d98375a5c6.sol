 

pragma solidity ^0.4.18;

library SafeMath {
     
     
     
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
	
}

contract Owned {

    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) public returns (bool success) ;
	function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract ArtisMain is Owned{
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
    bool public isARTDistributed = false;
    

     
     
     
    uint public constant START_TIME = 1516017600;                    
    uint public constant SECOND_TIER_SALE_START_TIME = 1517227200;   
    uint public constant THIRD_TIER_SALE_START_TIME = 1518436800;    
    uint public constant FOURTH_TIER_SALE_START_TIME = 1519041600;   
    uint public constant END_TIME = 1519646400;                      
	
	
    
     
     
     
    uint public START_RATE = 3000;           
    uint public SECOND_TIER_RATE = 2600;     
    uint public THIRD_TIER_RATE = 2200;      
    uint public FOURTH_RATE = 2000;          
    

     
     
     
     
    uint public constant FUNDING_ETH_HARD_CAP = 50000000000000000000000; 
    
     
    uint8 public constant ART_DECIMALS = 8;
    uint public constant ART_DECIMALSFACTOR = 10**uint(ART_DECIMALS);
    
    address public constant ART_FOUNDATION_ADDRESS = 0x55BeA1A0335A8Ea56572b8E66f17196290Ca6467;
    address public constant ART_CONTRACT_ADDRESS = 0x082E13494f12EBB7206FBf67E22A6E1975A1A669;

    event GoalReached(address raisingAddress, uint amountRaised);
	event LimitReached(address raisingAddress, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
	event WithdrawFailed(address raisingAddress, uint amount, bool isContribution);
	event FundReturn(address backer, uint amount, bool isContribution);

     
    function ArtisMain(
    ) public {
        beneficiary = ART_FOUNDATION_ADDRESS;
        fundingLimit = FUNDING_ETH_HARD_CAP;  
	    deadline = END_TIME;   
        exchangeTokenRate = FOURTH_RATE * ART_DECIMALSFACTOR;
        tokenReward = token(ART_CONTRACT_ADDRESS);
		contributorCount = 0;
    }

     
    function () public payable {
		
        require(!crowdsaleClosed);
        require(now >= START_TIME && now < END_TIME);
        
		processTransaction(msg.sender, msg.value);
    }
	
	 
	function processTransaction(address _contributor, uint _amount) internal{	
		uint contributionEthAmount = _amount;
			
        amountRaised += contributionEthAmount;                     
		remainAmount += contributionEthAmount;
        
		 
        if (now >= START_TIME && now < SECOND_TIER_SALE_START_TIME){
			exchangeTokenRate = START_RATE * ART_DECIMALSFACTOR;
        }
        if (now >= SECOND_TIER_SALE_START_TIME && now < THIRD_TIER_SALE_START_TIME){
            exchangeTokenRate = SECOND_TIER_RATE * ART_DECIMALSFACTOR;
        }
        if (now >= THIRD_TIER_SALE_START_TIME && now < FOURTH_TIER_SALE_START_TIME){
            exchangeTokenRate = THIRD_TIER_RATE * ART_DECIMALSFACTOR;
        }
        if (now >= FOURTH_TIER_SALE_START_TIME && now < END_TIME){
            exchangeTokenRate = FOURTH_RATE * ART_DECIMALSFACTOR;
        }
        uint amountArtToken = _amount * exchangeTokenRate / 1 ether;
		
		if (contributorList[_contributor].isActive == false){                   
			contributorList[_contributor].isActive = true;                             
			contributorList[_contributor].contributionAmount = contributionEthAmount;     
			contributorList[_contributor].tokensAmount = amountArtToken;
			contributorList[_contributor].isTokenDistributed = false;
			contributorIndexes[nextContributorIndex] = _contributor;                   
			nextContributorIndex++;
			contributorCount++;
		}
		else{
			contributorList[_contributor].contributionAmount += contributionEthAmount;    
			contributorList[_contributor].tokensAmount += amountArtToken;              
		}
		
        FundTransfer(msg.sender, contributionEthAmount, true);
		
		if (amountRaised >= fundingLimit){
			 
			crowdsaleClosed = true;
		}		
		
	}

    modifier afterDeadline() { if (now >= deadline) _; }	
	modifier afterCrowdsaleClosed() { if (crowdsaleClosed == true || now >= deadline) _; }
	
	
	 
	function closeCrowdSale() public {
		require(beneficiary == msg.sender);
		if ( beneficiary == msg.sender) {
			crowdsaleClosed = true;
		}
	}
	
     
	function checkTokenBalance() public {
		if ( beneficiary == msg.sender) {
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
     
    function safeWithdrawalAll() public {
        if ( beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
				remainAmount = remainAmount - amountRaised;
            } else {
				WithdrawFailed(beneficiary, amountRaised, false);
				 
            }
        }
    }
	
	 
    function safeWithdrawalAmount(uint256 withdrawAmount) public {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(withdrawAmount)) {
                FundTransfer(beneficiary, withdrawAmount, false);
				remainAmount = remainAmount - withdrawAmount;
            } else {
				WithdrawFailed(beneficiary, withdrawAmount, false);
				 
            }
        }
    }
	
	 
    function withdrawART(uint256 tokenAmount) public afterCrowdsaleClosed {
		require(beneficiary == msg.sender);
        if (isARTDistributed && beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, tokenAmount);
			 
			tokenBalance = tokenReward.balanceOf(address(this));
        }
    }
	

	 
	function distributeARTToken() public {
		if (beneficiary == msg.sender) {   
			address currentParticipantAddress;
			for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountArtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountArtToken);
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			 
			checkIfAllARTDistributed();
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	 
	function distributeARTTokenBatch(uint batchUserCount) public {
		if (beneficiary == msg.sender) {   
			address currentParticipantAddress;
			uint transferedUserCount = 0;
			for (uint index = 0; index < contributorCount && transferedUserCount<batchUserCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
				uint amountArtToken = contributorList[currentParticipantAddress].tokensAmount;
				if (false == contributorList[currentParticipantAddress].isTokenDistributed){
					bool isSuccess = tokenReward.transfer(currentParticipantAddress, amountArtToken);
					transferedUserCount = transferedUserCount + 1;
					if (isSuccess){
						contributorList[currentParticipantAddress].isTokenDistributed = true;
					}
				}
			}
			
			 
			checkIfAllARTDistributed();
			 
			tokenBalance = tokenReward.balanceOf(address(this));
		}
	}
	
	 
	function checkIfAllARTDistributed() public {
	    address currentParticipantAddress;
		isARTDistributed = true;
		for (uint index = 0; index < contributorCount; index++){
				currentParticipantAddress = contributorIndexes[index]; 
				
			if (false == contributorList[currentParticipantAddress].isTokenDistributed){
				isARTDistributed = false;
				break;
			}
		}
	}
	
}