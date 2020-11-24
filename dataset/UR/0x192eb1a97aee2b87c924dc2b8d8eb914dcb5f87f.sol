 

pragma solidity ^0.4.15;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BurnableToken is StandardToken {

    address public constant BURN_ADDRESS = 0;

    event Burn(address indexed burner, uint256 value);

	
	function burnTokensInternal(address _address, uint256 _value) internal {
        require(_value > 0);
        require(_value <= balances[_address]);
         
         

        address burner = _address;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
		Transfer(burner, BURN_ADDRESS, _value);
		
	}
		
}

 
 contract HIONToken is BurnableToken, Ownable
 {
	
	 
	string public constant name = "HION Token by Handelion"; 
	 
	  
	string public constant symbol = "HION"; 

	 
	uint256 public constant decimals = 18;

	 
	uint256 public constant PREISSUED_AMOUNT = 29750000 * 1 ether;
			
	 
	bool public transferAllowed = false;
			
	 
	event LogTokenPreissued(address ownereAddress, uint256 amount);
	
	
	modifier canTransfer(address sender)
	{
		require(transferAllowed || sender == owner);
		
		_;
	}
	
	 
	function HIONToken()
	{
		 
		owner = msg.sender;
	 
		 
		totalSupply = totalSupply.add(PREISSUED_AMOUNT);
		balances[owner] = balances[owner].add(PREISSUED_AMOUNT);
		
		LogTokenPreissued(owner, PREISSUED_AMOUNT);
	}
	
	 
	function getCreatorAddress() public constant returns(address creatorAddress)
	{
		return owner;
	}
	
	 
	function getTotalSupply() public constant returns(uint256)
	{
		return totalSupply;
	}
	
	 
	function getRemainingTokens() public constant returns(uint256)
	{
		return balanceOf(owner);
	}	
	
	 
	function allowTransfer() onlyOwner public
	{
		transferAllowed = true;
	}
	
	
	 
	function transfer(address _to, uint256 _value) canTransfer(msg.sender) public returns (bool)	
	{
		super.transfer(_to, _value);
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from) public returns (bool) {	
		super.transferFrom(_from, _to, _value);
	}
	
	 
    function burn(uint256 _value) public {
		burnTokensInternal(msg.sender, _value);
    }

     
    function burn(address _address, uint256 _value) public onlyOwner {
		burnTokensInternal(_address, _value);
    }
}

 
contract Stoppable is Ownable {
  bool public stopped;

  modifier stopInEmergency {
    require(!stopped);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require(!stopped || msg.sender == owner);
    _;
  }

  modifier onlyInEmergency {
    require(stopped);
    _;
  }

   
  function stop() external onlyOwner {
    stopped = true;
  }

   
  function unstop() external onlyOwner onlyInEmergency {
    stopped = false;
  }

}

 
contract HANDELIONdiscountSALE is Ownable, Stoppable
{
	using SafeMath for uint256;

	struct FundingTier {
		uint256 cap;
		uint256 rate;
	}
		
	 
	HIONToken public token; 
	
	 
	FundingTier public tier1;
	
	FundingTier public tier2;
	
	FundingTier public tier3;
	
	FundingTier public tier4;
	
	FundingTier public tier5;	

	 
	uint256 public startTime;

	 
	uint256 public endTime;

	 
	address public multisigWallet;
	
	 
	uint256 public minimumTokenAmount;

	 
	uint256 public maximumTokenAmount;

	 
	uint256 public weiRaised;

	 
	uint256 public tokensSold;

	 
	uint public investorCount;

	 
	bool public finalized;

	 
	bool public isRefunding;

	 
	mapping (address => uint256) public investedAmountOf;

	 
	mapping (address => uint256) public tokenAmountOf;
	
	 
	event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	event LogCrowdsaleStarted();

	event LogCrowdsaleFinalized(bool isGoalReached);

	event LogRefundingOpened(uint256 refundAmount);

	event LogInvestorRefunded(address investorAddress, uint256 refundedAmount);
	
	 
	function HANDELIONdiscountSALE() 
	{
		createTokenContract();
		
		startTime = 1512734400;
		endTime = 1522497600;

		multisigWallet = 0x7E23cFa050d23B9706a071dEd0A62d30AE6BB6c8;
		
		minimumTokenAmount = 4830988 * 1 ether;
		maximumTokenAmount = 29750000 * 1 ether;

		tokensSold = 0;
		weiRaised = 0;

		tier1 = FundingTier({cap: 2081338 * 1 ether, rate: 480});
		tier2 = FundingTier({cap: 4830988 * 1 ether, rate: 460});
		tier3 = FundingTier({cap: 9830988 * 1 ether, rate: 440});
		tier4 = FundingTier({cap: 14830988 * 1 ether, rate: 420});
		tier5 = FundingTier({cap: 23184738 * 1 ether, rate: 400});

		finalized = false;
	}
	
	 
	 
	function createTokenContract() internal
	{
		token = HIONToken(0xa089273724e07644da9739a708e544800d925115);
	}
	
	function calculateTierTokens(FundingTier _tier, uint256 _amount, uint256 _currentTokenAmount) constant internal returns (uint256)
	{
		uint256 maxTierTokens = _tier.cap.sub(_currentTokenAmount);

		if (maxTierTokens <= 0)
		{
			return 0;
		}
				
		uint256 tokenCount = _amount.mul(_tier.rate);
			
		if (tokenCount > maxTierTokens)
		{
			tokenCount = maxTierTokens;
		}
			
		return tokenCount;
	}
	
	function calculateTokenAmount(uint256 _weiAmount) constant internal returns (uint256)
	{		
		uint256 nTokens = tokensSold;
		uint256 remainingWei = _weiAmount;
		uint256 tierTokens = 0;
		
		if (nTokens < tier1.cap)
		{			
			tierTokens = calculateTierTokens(tier1, remainingWei, nTokens);
			nTokens = nTokens.add(tierTokens);		
			remainingWei = remainingWei.sub(tierTokens.div(tier1.rate));
		}
		
		if (remainingWei > 0 && nTokens < tier2.cap)
		{
			tierTokens = calculateTierTokens(tier2, remainingWei, nTokens);
			nTokens = nTokens.add(tierTokens);			
			remainingWei = remainingWei.sub(tierTokens.div(tier2.rate));
		}

		if (remainingWei > 0 && nTokens < tier3.cap)
		{
			tierTokens = calculateTierTokens(tier3, remainingWei, nTokens);
			nTokens = nTokens.add(tierTokens);			
			remainingWei = remainingWei.sub(tierTokens.div(tier3.rate));
		}

		if (remainingWei > 0 && nTokens < tier4.cap)
		{
			tierTokens = calculateTierTokens(tier4, remainingWei, nTokens);
			nTokens = nTokens.add(tierTokens);			
			remainingWei = remainingWei.sub(tierTokens.div(tier4.rate));
		}

		if (remainingWei > 0 && nTokens < tier5.cap)
		{
			tierTokens = calculateTierTokens(tier5, remainingWei, nTokens);
			nTokens = nTokens.add(tierTokens);			
			remainingWei = remainingWei.sub(tierTokens.div(tier5.rate));
		}		
		
		require(remainingWei == 0);
		
		return nTokens.sub(tokensSold);
	}	

	 
	function () public payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable stopInEmergency 
	{
		require(beneficiary != address(0));
		require(validPurchase());

		uint256 weiAmount = msg.value;

		 
		 
		uint256 tokens = calculateTokenAmount(weiAmount);

		 
		require(tokensSold.add(tokens) <= maximumTokenAmount);

		 
		weiRaised = weiRaised.add(weiAmount);
		tokensSold = tokensSold.add(tokens);
		investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
		tokenAmountOf[beneficiary] = tokenAmountOf[beneficiary].add(tokens);

		 
		forwardTokens(beneficiary, tokens);

		LogTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		 
		forwardFunds();
	}

	 
	function transferTokens(address beneficiary, uint256 amount) public onlyOwner
	{
		require(beneficiary != address(0));
		require(amount > 0);

		uint256 weiAmount = amount * 1 ether;
		
		tokensSold = tokensSold.add(weiAmount);
		tokenAmountOf[beneficiary] = tokenAmountOf[beneficiary].add(weiAmount);
		
		forwardTokens(beneficiary, weiAmount);
	}
	
		 
	function transferTokensWei(address beneficiary, uint256 amount) public onlyOwner
	{
		require(beneficiary != address(0));
		require(amount > 0);

		uint256 weiAmount = amount;
		
		tokensSold = tokensSold.add(weiAmount);
		tokenAmountOf[beneficiary] = tokenAmountOf[beneficiary].add(weiAmount);
		
		forwardTokens(beneficiary, weiAmount);
	}
	
	 
	 
	function forwardFunds() internal {
		multisigWallet.transfer(msg.value);
	}
	
	 
	function forwardTokens(address _purchaser, uint256 _amount) internal
	{
		token.transfer(_purchaser, _amount);
	}

	 
	function finalize() public onlyOwner
	{
		finalized = true;
		
		LogCrowdsaleFinalized(goalReached());
	}
	
	 
	function burnTokensInternal(address _address, uint256 tokenAmount) internal
	{
		require(_address != address(0));
		
		uint256 tokensToBurn = tokenAmount;
		uint256 maxTokens = token.balanceOf(_address);
		
		if (tokensToBurn > maxTokens)
		{
			tokensToBurn = maxTokens;
		}
		
		token.burn(_address, tokensToBurn);
	}
		
	 
	function burnRemainingTokens() public onlyOwner
	{
		burnTokensInternal(this, getRemainingTokens());
	}
		
		
	 
	function getRemainingTokens() public constant returns(uint256)
	{
		return token.getRemainingTokens();
	}
	
	 
	function getTotalSupply() constant returns (uint256 res)
	{
		return token.getTotalSupply();
	}
	
	 
	function getTokenAmountOf(address investor) constant returns (uint256 res)
	{
		return token.balanceOf(investor);
	}

	 
	function validPurchase() internal constant returns (bool) {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = msg.value != 0;
		bool notFinalized = !finalized;
		bool maxCapNotReached = tokensSold < maximumTokenAmount;

		return withinPeriod && nonZeroPurchase && notFinalized && maxCapNotReached;
	}

	function goalReached() public constant returns (bool)
	{
		return tokensSold >= minimumTokenAmount;
	}

	 
	function hasEnded() public constant returns (bool) {
		return now > endTime;
	}	
}