 

pragma solidity ^0.4.19;

contract CrowdsaleTokenInterface {

  uint public decimals;
   
  function addLockAddress(address addr, uint lock_time) public;
  function mint(address _to, uint256 _amount) public returns (bool);
  function finishMinting() public returns (bool);
}

contract CrowdsaleLimit {
  using SafeMath for uint256;

   
  uint public startsAt;
   
  uint public endsAt;
  
  uint public token_decimals = 8;
    
  uint public TOKEN_RATE_PRESALE  = 7200;
  uint public TOKEN_RATE_CROWDSALE= 6000;
  
   
  uint public PRESALE_TOKEN_IN_WEI = 1 ether / TOKEN_RATE_PRESALE;  
   
  uint public CROWDSALE_TOKEN_IN_WEI = 1 ether / TOKEN_RATE_CROWDSALE;
  
   
  uint public PRESALE_ETH_IN_WEI_FUND_MAX = 40000 ether; 
   
  uint public CROWDSALE_ETH_IN_WEI_FUND_MIN = 22000 ether;
   
  uint public CROWDSALE_ETH_IN_WEI_FUND_MAX = 90000 ether;
  
   
  uint public PRESALE_ETH_IN_WEI_ACCEPTED_MIN = 1 ether; 
   
  uint public CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = 100 finney;
  
   
  uint public CROWDSALE_GASPRICE_IN_WEI_MAX = 0;
 
  
  uint public presale_eth_fund= 0;
   
  uint public crowdsale_eth_fund= 0;
   
  uint public crowdsale_eth_refund = 0;
   
   
  mapping(address => uint) public team_addresses_token_percentage;
  mapping(uint => address) public team_addresses_idx;
  uint public team_address_count= 0;
  uint public team_token_percentage_total= 0;
  uint public team_token_percentage_max= 40;
    
  event EndsAtChanged(uint newEndsAt);
  event AddTeamAddress(address addr, uint release_time, uint token_percentage);
  event Refund(address investor, uint weiAmount);
    
   
  modifier allowCrowdsaleAmountLimit(){	
	if (msg.value == 0) revert();
	if((crowdsale_eth_fund.add(msg.value)) > CROWDSALE_ETH_IN_WEI_FUND_MAX) revert();
	if((CROWDSALE_GASPRICE_IN_WEI_MAX > 0) && (tx.gasprice > CROWDSALE_GASPRICE_IN_WEI_MAX)) revert();
	_;
  }
   
  function CrowdsaleLimit(uint _start, uint _end) public {
	require(_start != 0);
	require(_end != 0);
	require(_start < _end);
			
	startsAt = _start;
    endsAt = _end;
  }
    
   
  function calculateTokenPresale(uint value, uint decimals)   public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(PRESALE_TOKEN_IN_WEI);
  }
  
   
  function calculateTokenCrowsale(uint value, uint decimals)   public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(CROWDSALE_TOKEN_IN_WEI);
  }
  
   
  function isMinimumGoalReached() public constant returns (bool) {
    return crowdsale_eth_fund >= CROWDSALE_ETH_IN_WEI_FUND_MIN;
  }
  
   
  function addTeamAddressInternal(address addr, uint release_time, uint token_percentage) internal {
	if((team_token_percentage_total.add(token_percentage)) > team_token_percentage_max) revert();
	if((team_token_percentage_total.add(token_percentage)) > 100) revert();
	if(team_addresses_token_percentage[addr] != 0) revert();
	
	team_addresses_token_percentage[addr]= token_percentage;
	team_addresses_idx[team_address_count]= addr;
	team_address_count++;
	
	team_token_percentage_total = team_token_percentage_total.add(token_percentage);

	AddTeamAddress(addr, release_time, token_percentage);
  }
   
   
  function hasEnded() public constant returns (bool) {
    return now > endsAt;
  }
}

contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract Crowdsale is CrowdsaleLimit, Haltable {
  using SafeMath for uint256;

  CrowdsaleTokenInterface public token;
    
   
  address public multisigWallet;
    
   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;
     
   
  uint public tokensSold = 0;
  
   
  uint public investorCount = 0;
  
   
  uint public loadedRefund = 0;
  
   
  bool public finalized;
  
  enum State{Unknown, PreFunding, Funding, Success, Failure, Finalized, Refunding}
    
   
  event Invested(address investor, uint weiAmount, uint tokenAmount);
    
  event createTeamTokenEvent(address addr, uint tokens);
  
  event Finalized();
  
   
  modifier inState(State state) {
    if(getState() != state) revert();
    _;
  }

  function Crowdsale(address _token, address _multisigWallet, uint _start, uint _end) CrowdsaleLimit(_start, _end) public
  {
    require(_token != 0x0);
    require(_multisigWallet != 0x0);
	
	token = CrowdsaleTokenInterface(_token);	
	if(token_decimals != token.decimals()) revert();
	
	multisigWallet = _multisigWallet;
  }
  
   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (now < startsAt) return State.PreFunding;
    else if (now <= endsAt && !isMinimumGoalReached()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && crowdsale_eth_fund > 0 && loadedRefund >= crowdsale_eth_fund) return State.Refunding;
    else return State.Failure;
  }
    
   
  function addTeamAddress(address addr, uint release_time, uint token_percentage) onlyOwner inState(State.PreFunding) public {
	super.addTeamAddressInternal(addr, release_time, token_percentage);
	token.addLockAddress(addr, release_time);   
  }
  
   
  function createTeamTokenByPercentage() onlyOwner internal {
	 
	uint total= tokensSold;
	
	 
	uint tokens= total.mul(team_token_percentage_total).div(100-team_token_percentage_total);
	
	for(uint i=0; i<team_address_count; i++) {
		address addr= team_addresses_idx[i];
		if(addr==0x0) continue;
		
		uint ntoken= tokens.mul(team_addresses_token_percentage[addr]).div(team_token_percentage_total);
		token.mint(addr, ntoken);		
		createTeamTokenEvent(addr, ntoken);
	}
  }
  
   
  function () stopInEmergency allowCrowdsaleAmountLimit payable public {
	require(msg.sender != 0x0);
    buyTokensCrowdsale(msg.sender);
  }

   
  function buyTokensCrowdsale(address receiver) internal   {
	uint256 weiAmount = msg.value;
	uint256 tokenAmount= 0;
	
	if(getState() == State.PreFunding) {
		if (weiAmount < PRESALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
		if((PRESALE_ETH_IN_WEI_FUND_MAX > 0) && ((presale_eth_fund.add(weiAmount)) > PRESALE_ETH_IN_WEI_FUND_MAX)) revert();		
		
		tokenAmount = calculateTokenPresale(weiAmount, token_decimals);
		presale_eth_fund = presale_eth_fund.add(weiAmount);
	}
	else if((getState() == State.Funding) || (getState() == State.Success)) {
		if (weiAmount < CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
		
		tokenAmount = calculateTokenCrowsale(weiAmount, token_decimals);
		
    } else {
       
      revert();
    }
	
	if(tokenAmount == 0) {
		revert();
	}	
	
	if(investedAmountOf[receiver] == 0) {
       investorCount++;
    }
    
	 
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
	
     
	crowdsale_eth_fund = crowdsale_eth_fund.add(weiAmount);
	tokensSold = tokensSold.add(tokenAmount);
	
    token.mint(receiver, tokenAmount);

    if(!multisigWallet.send(weiAmount)) revert();
	
	 
    Invested(receiver, weiAmount, tokenAmount);
  }
 
   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) revert();
    loadedRefund = loadedRefund.add(msg.value);
  }
  
   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) revert();
    investedAmountOf[msg.sender] = 0;
    crowdsale_eth_refund = crowdsale_eth_refund.add(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) revert();
  }
  
  function setEndsAt(uint time) onlyOwner public {
    if(now > time) {
      revert();
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }
  
   
   
  function doFinalize() public inState(State.Success) onlyOwner stopInEmergency {
    
	if(finalized) {
      revert();
    }

	createTeamTokenByPercentage();
    token.finishMinting();	
        
    finalized = true;
	Finalized();
  }
  
}

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