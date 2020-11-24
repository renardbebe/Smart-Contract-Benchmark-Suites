 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract crowdfund {

Idea[] public ideas;

uint256 public PROPOSED_STATUS;
uint256 public UNDERWAY_STATUS;
uint256 public SUFFICIENT_STATUS;
uint256 public FAILED_STATUS;
uint256 public REQUEST_CANCELED_BY_CREATOR;
uint256 public REQUEST_REJECTED_BY_HOST; 
uint256 public DISTRIBUTED_STATUS; 

uint256 public MAX_FUNDING_AMOUNT;
uint256 public MAX_HOST_PERCENT;

event ProposalCreatedAtIndex(uint256 index);
event SetNewCreator(address newCreator,uint256 index);
event ProposalCanceledByCreatorAtIndex(uint256 index);
event ProposalCanceledByHostAtIndex(uint256 index);
event ProposalAcceptedAtIndex(uint256 index);
event UserPledgedAmountAtIndex(address user,uint256 amount,uint256 index);
event ProposalAtIndexFailed(uint256 index);
event UserRegainedAmountAtIndex(address user,uint256 amount,uint256 index);
event TokensDistributed(uint256 hostCut,uint256 creatorCut,uint256 index);
event MaxGoalReachedAtIndex(uint256 hostCut,uint256 creatorCut,uint256 index);
event SufficientFundingReached(uint256 index);

struct Idea {
	string title;
	uint256 minGoal; 
	uint256 maxGoal; 
	uint256 hostCut; 
	uint256 duration; 
	uint256 startTime;
	uint256 status;
	uint256 amountRaisedSoFar;
	address host;
	address tokenAddress; 
	address creator;
	mapping(address => uint256) amountPledged; 
	mapping(address => bool) reclaimed; 
}

function crowdfund() {

	PROPOSED_STATUS=1;
	UNDERWAY_STATUS=2;
	SUFFICIENT_STATUS=3;
	FAILED_STATUS=4;
	REQUEST_CANCELED_BY_CREATOR=5;
	REQUEST_REJECTED_BY_HOST=6; 
	DISTRIBUTED_STATUS=7;

	MAX_FUNDING_AMOUNT = 100000000000000000000000000000;
	MAX_HOST_PERCENT=100000000000000000000;
}

function makeProposal(string title,uint256 minGoal,uint256 maxGoal,uint256 hostCut,uint256 duration,address host,address tokenAddress) public returns(uint256)	{

	if (maxGoal==0 || minGoal==0 || maxGoal>MAX_FUNDING_AMOUNT) revert(); 
	if (minGoal>maxGoal) revert();
	if (hostCut>MAX_HOST_PERCENT) revert(); 
	if (duration<5 || duration>225257142) revert();  
	
	if (!(tokenAddress==0xc8C6A31A4A806d3710A7B38b7B296D2fABCCDBA8)) revert();
	
	uint256 status=PROPOSED_STATUS;
	address creator=msg.sender;
	
	Idea memory newIdea=Idea(title,minGoal,maxGoal,hostCut,duration,0,status,0,host,tokenAddress,creator);
	ideas.push(newIdea);
	
	emit ProposalCreatedAtIndex(ideas.length-1);
	
	return ideas.length-1; 
}

function setNewCreator(address newCreator,uint256 index) public returns(bool)	{
	if (ideas[index].creator==msg.sender && ideas[index].status==PROPOSED_STATUS)	{
		ideas[index].creator=newCreator;
		emit SetNewCreator(newCreator,index);
		return true;
	}
	return false;
}

function cancelProposalByCreator(uint256 index) public	{
 	if (msg.sender==ideas[index].creator && ideas[index].status==PROPOSED_STATUS)	{ 
 		ideas[index].status=REQUEST_CANCELED_BY_CREATOR;
 		emit ProposalCanceledByCreatorAtIndex(index);
 	}
}

function rejectProposalAsHost(uint256 index) public	{
	if (msg.sender==ideas[index].host && ideas[index].status==PROPOSED_STATUS)	{ 
		ideas[index].status=REQUEST_REJECTED_BY_HOST;
		emit ProposalCanceledByHostAtIndex(index);
	}
}

function acceptProposal(uint256 index,address currCreator) public returns(bool)	{

	if (ideas[index].status==PROPOSED_STATUS && msg.sender==ideas[index].host && currCreator==ideas[index].creator)	{
		ideas[index].status=UNDERWAY_STATUS;
		ideas[index].startTime=block.number;
		emit ProposalAcceptedAtIndex(index);
		return true;
	}
	return false;
}

function maxGoalReached(uint256 index) private {
	ideas[index].status=DISTRIBUTED_STATUS;
	uint256 hostCut;
	uint256 creatorCut;
	(hostCut, creatorCut) = returnHostAndCreatorCut(index);
	emit MaxGoalReachedAtIndex(hostCut,creatorCut,index);
	if(! token(ideas[index].tokenAddress).transfer(ideas[index].creator,creatorCut)) revert();
	if(! token(ideas[index].tokenAddress).transfer(ideas[index].host,hostCut)) revert();
	
}

function distributeSuccessfulCampaignFunds(uint256 index) public returns(bool)	{
	if ((msg.sender==ideas[index].creator) || (msg.sender==ideas[index].host))	{
		if (ideas[index].status==SUFFICIENT_STATUS && block.number> SafeMath.add(ideas[index].startTime,ideas[index].duration) )	{ 
			uint256 hostCut;
			uint256 creatorCut;
			(hostCut, creatorCut) = returnHostAndCreatorCut(index);
			ideas[index].status=DISTRIBUTED_STATUS;
			emit TokensDistributed(hostCut,creatorCut,index);
			if(! token(ideas[index].tokenAddress).transfer(ideas[index].creator,creatorCut)) revert();
			if(! token(ideas[index].tokenAddress).transfer(ideas[index].host,hostCut)) revert();
			return true;
		}
	}
	return false;
}

function returnHostAndCreatorCut(uint256 index) private returns(uint256, uint256)	{
	uint256 hostCut = SafeMath.div( SafeMath.mul(ideas[index].amountRaisedSoFar, ideas[index].hostCut), MAX_HOST_PERCENT );
	uint256 creatorCut = SafeMath.sub(ideas[index].amountRaisedSoFar, hostCut );
	return ( hostCut, creatorCut );
}

function stateFail(uint256 index) public	{
	if (block.number> SafeMath.add(ideas[index].startTime,ideas[index].duration) && ideas[index].amountRaisedSoFar<ideas[index].minGoal && ideas[index].status==UNDERWAY_STATUS) {
		ideas[index].status=FAILED_STATUS;
		emit ProposalAtIndexFailed(index);
	}
}

function reclaimTokens(uint256 index) public	{
	if (ideas[index].status==FAILED_STATUS)	{
	    if (!ideas[index].reclaimed[msg.sender])    { 
	        uint256 reclaimAmount=ideas[index].amountPledged[msg.sender];
		    if (reclaimAmount>0)    { 
		    	ideas[index].reclaimed[msg.sender]=true; 
		        emit UserRegainedAmountAtIndex(msg.sender,reclaimAmount,index);
		        if(! token(ideas[index].tokenAddress).transfer(msg.sender,reclaimAmount)) revert();
		    }
	    }
	}
}

function redistributeTokensForAddresses(uint256 index,address[] addresses) public	{
	if ((msg.sender==ideas[index].creator) || (msg.sender==ideas[index].host))	{
		if (ideas[index].status==FAILED_STATUS)	{
			for(uint256 i = 0; i < addresses.length; i++) {
				address addr=addresses[i];
	    		if (!ideas[index].reclaimed[addr])    { 
	        		uint256 reclaimAmount=ideas[index].amountPledged[addr];
		    		if (reclaimAmount>0)    { 
		    			ideas[index].reclaimed[addr]=true; 
		        		emit UserRegainedAmountAtIndex(addr,reclaimAmount,index);
		        		if(! token(ideas[index].tokenAddress).transfer(addr,reclaimAmount)) revert();
		    		}
	    		}
	    	}    
		}
	}
}

function pledgeTokens(uint256 amount,uint256 index) public returns(bool)	{
    if (msg.sender==ideas[index].creator || msg.sender==ideas[index].host) revert(); 
    if (amount==0 || amount>MAX_FUNDING_AMOUNT) revert(); 
	if ((ideas[index].status==UNDERWAY_STATUS) || (ideas[index].status==SUFFICIENT_STATUS))	{ 
	    if (block.number<= SafeMath.add(ideas[index].startTime, ideas[index].duration))   { 
	        uint256 amountAvailable= SafeMath.sub(ideas[index].maxGoal, ideas[index].amountRaisedSoFar); 
			if (amount>amountAvailable)	revert(); 
			ideas[index].amountRaisedSoFar = SafeMath.add(ideas[index].amountRaisedSoFar, amount); 
			ideas[index].amountPledged[msg.sender] = SafeMath.add(ideas[index].amountPledged[msg.sender], amount); 
			if (!token(ideas[index].tokenAddress).transferFrom(msg.sender,address(this),amount)) revert(); 
			if (ideas[index].amountRaisedSoFar==ideas[index].maxGoal)  { 
			    maxGoalReached(index); 
			}
			else if ((ideas[index].amountRaisedSoFar>=ideas[index].minGoal) && (ideas[index].status==UNDERWAY_STATUS))   { 
			   ideas[index].status=SUFFICIENT_STATUS;
			   emit SufficientFundingReached(index);
			}
			emit UserPledgedAmountAtIndex(msg.sender,amount,index);
			return true;
	    }
	}
	return false;
}

function returnMinGoal(uint256 index) public returns(uint256)	{
	return ideas[index].minGoal;
}

function returnMaxGoal(uint256 index) public returns(uint256)	{
	return ideas[index].maxGoal;
}

function returnHostCut(uint256 index) public returns(uint256)	{
	return ideas[index].hostCut;
}

function returnDuration(uint256 index) public returns(uint256)	{
	return ideas[index].duration;
}

function returnStartTime(uint256 index) public returns(uint256)	{
	return ideas[index].startTime;
}

function returnStatus(uint256 index) public returns(uint256)	{
	return ideas[index].status;
}

function returnAmountRaisedSoFar(uint256 index) public returns(uint256)	{
	return ideas[index].amountRaisedSoFar;
}

function returnHost(uint256 index) public returns(address)	{
	return ideas[index].host;
}

function returnTokenAddress(uint256 index) public returns(address)	{
	return ideas[index].tokenAddress;
}

function returnCreator(uint256 index) public returns(address)	{
	return ideas[index].creator;
}

function returnAmountPledged(uint256 index,address addr) public returns(uint256)	{
	return ideas[index].amountPledged[addr];
}

function returnReclaimed(uint256 index,address addr) public returns(bool)	{
	return ideas[index].reclaimed[addr];
}	

function getProposalsCount() public returns(uint256) {
    return ideas.length;
}

}

contract token	{
	function transfer(address _to, uint256 _amount) returns (bool success);
	function transferFrom(address _from,address _to,uint256 _amount) returns (bool success);
}