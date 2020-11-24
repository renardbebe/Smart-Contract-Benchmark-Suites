 

pragma solidity ^0.4.2;

contract owned 
{
	address public owner;

	function owned() 
	{
		owner = msg.sender;
	}

	modifier onlyOwner 
	{
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner 
	{
		owner = newOwner;
	}
}

contract tokenRecipient 
{ 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
}

library MathFunction 
{
     

    function plus(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function minus(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function multiply(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function divide(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }
    
     

    function hplus(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function hminus(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function hmultiply(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function hdivide(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

     

    uint256 constant BIG = 10 ** 18;

    function wplus(uint256 x, uint256 y) constant internal returns (uint256) {
        return hplus(x, y);
    }

    function wminus(uint256 x, uint256 y) constant internal returns (uint256) {
        return hminus(x, y);
    }

    function wmultiply(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = cast((uint256(x) * y + BIG / 2) / BIG);
    }

    function wdivide(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = cast((uint256(x) * BIG + y / 2) / y);
    }

    function cast(uint256 x) constant internal returns (uint256 z) {
        assert((z = uint256(x)) == x);
    }
}

contract ERC20 
{
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract token is owned, ERC20
{
	using MathFunction for uint256;
	
	 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	
	mapping (address => uint256) public contrubutedAmount;
	mapping (address => uint256) public balanceOf;													 
	mapping (address => mapping (address => uint256)) public allowance;								 
	
	modifier onlyContributer
	{
		require(balanceOf[msg.sender] > 0);
		_;
	}
	
	 
	function token() 
	{		
		totalSupply = 166000;  																		 
		totalSupply = totalSupply.multiply(10 ** 18);
		balanceOf[msg.sender] = totalSupply;              											 
		name = "Global Academy Place";               										 
		symbol = "GAP";                                											 
		decimals = 18;                            													 
	}
	
	function balanceOf(address _owner) constant returns (uint256 balance) 
	{
		return balanceOf[_owner];																	 
	}
	
	function totalSupply() constant returns (uint256 _totalSupply)
	{
	    return totalSupply;
	}
  
	function transfer(address _to, uint256 _value) returns (bool success) 
	{
		require(balanceOf[msg.sender] >= _value);													 
		require(balanceOf[_to] <= balanceOf[_to].plus(_value));										 
								
		balanceOf[msg.sender] = balanceOf[msg.sender].minus(_value);                     			 
		balanceOf[_to] = balanceOf[_to].plus(_value);                            					 
		
		Transfer(msg.sender, _to, _value);                   										 
		return true;
	}
	
	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success)			
	{
		require(_value <= balanceOf[_from]);														 
		require(balanceOf[_to] <= balanceOf[_to].plus(_value));										 
		require(_value <= allowance[_from][msg.sender]);											 
  									
		balanceOf[_from] = balanceOf[_from].minus(_value);                          				 
		balanceOf[_to] = balanceOf[_to].plus(_value);                            					 
		allowance[_from][msg.sender] = allowance[_from][msg.sender].minus(_value);					 
		
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value)	returns (bool success) 						
	{
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
		
		allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}
	
	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) 
	{    
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) 
		{
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}	
	
	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) 
	{
		return allowance[_owner][_spender];
	}
}

contract ICOToken is token
{
	 
	string public firstLevelPrice = "Token 0.0100 ETH per Token";
	string public secondLevelPrice = "Token 0.0125 ETH per Token";
	string public thirdLevelPrice = "Token 0.0166 ETH per Token";
	string public CapLevelPrice = "Token 0.0250 ETH per Token";
	uint256 public _firstLevelEth;
	uint256 public _secondLevelEth;
	uint256 public _thirdLevelEth;
	uint256 public _capLevelEth;
	uint256 public buyPrice;
	uint256 public fundingGoal;
	uint256 public amountRaisedEth; 
	uint256 public deadline;
	uint256 public maximumBuyBackPriceInCents;
	uint256 public maximumBuyBackAmountInCents;
	uint256 public maximumBuyBackAmountInWEI;
	address public beneficiary;	
	
	mapping (address => uint256) public KilledTokens;												 
	
	 
	uint256 _currentLevelEth;
	uint256 _currentLevelPrice;
	uint256 _nextLevelEth;
	uint256 _nextLevelPrice;
	uint256 _firstLevelPrice;
	uint256 _secondLevelPrice;
	uint256 _thirdLevelPrice;
	uint256 _capLevelPrice;
	uint256 _currentSupply;
	uint256 remainig;
	uint256 amount;
	uint256 TokensAmount;
	bool fundingGoalReached;
	bool crowdsaleClosed;

	event GoalReached(address _beneficiary, uint amountRaised);
	
	modifier afterDeadline() 
	{
		require(crowdsaleClosed);
		_;
	}
	 
	 
	
	function ICOToken() token() 
	{          
		balanceOf[msg.sender] = totalSupply;              											 
		
		beneficiary = owner;
		fundingGoal = 1600 ether;																	 
		deadline = 1506549600;																		 
		
		fundingGoalReached = false;
		crowdsaleClosed = false;
												
		_firstLevelEth = 600 ether;										
		_firstLevelPrice = 10000000000000000;										
		_secondLevelEth = 1100 ether;										
		_secondLevelPrice = 12500000000000000;										
		_thirdLevelEth = 1600 ether;										
		_thirdLevelPrice = 16666666666666666;										
		_capLevelEth = 2501 ether;										
		_capLevelPrice = 25000000000000000;										
												
		_currentLevelEth = _firstLevelEth;															 
		_currentLevelPrice = _firstLevelPrice;														 
		_nextLevelEth = _secondLevelEth;															
		_nextLevelPrice = _secondLevelPrice;										
		
		amountRaisedEth = 0;
		maximumBuyBackAmountInWEI = 50000000000000000;
	}
	
	 
	 
	 
	function levelChanger() internal						
	{
		if(_nextLevelPrice == _secondLevelPrice)
		{
			_currentLevelEth = _secondLevelEth;
			_currentLevelPrice = _secondLevelPrice;
			_nextLevelEth = _thirdLevelEth;
			_nextLevelPrice = _thirdLevelPrice;
		}
		else if(_nextLevelPrice == _thirdLevelPrice)
		{
			_currentLevelEth = _thirdLevelEth;
			_currentLevelPrice = _thirdLevelPrice;
			_nextLevelEth = _capLevelEth;
			_nextLevelPrice = _capLevelPrice;
		}
		else
		{
			_currentLevelEth = _capLevelEth;
			_currentLevelPrice = _capLevelPrice;
			_nextLevelEth = _capLevelEth;
			_nextLevelPrice = _capLevelPrice;
		}
	}
	
	 
	function safeCheck (uint256 _TokensAmount) internal
	{
		require(_TokensAmount <= totalSupply);
	}
	
	 
	function tokensAmount() internal returns (uint256 _tokensAmount) 			
	{   
		amountRaisedEth = amountRaisedEth.wplus(amount);
		uint256 raisedForNextLevel = amountRaisedEth.wminus(_currentLevelEth);
		remainig = amount.minus(raisedForNextLevel);
		TokensAmount = (raisedForNextLevel.wdivide(_nextLevelPrice)).wplus(remainig.wdivide(_currentLevelPrice));
		buyPrice = _nextLevelPrice;
		levelChanger();			
		
		return TokensAmount;
	}
	
	function manualBuyPrice (uint256 _NewPrice) onlyOwner
	{
		_currentLevelPrice = _NewPrice;
		buyPrice = _currentLevelPrice;
	}
	
	 
	function buyTokens () payable         								
	{
		assert(!crowdsaleClosed);																	 
	
		amount = msg.value;																			 
		assert(amountRaisedEth.plus(amount) <= _nextLevelEth);										 
								
		if(amountRaisedEth.plus(amount) > _currentLevelEth)											
		{								
			TokensAmount = tokensAmount();															 
			safeCheck(TokensAmount);						
		}						
		else						
		{						
			buyPrice = _currentLevelPrice;															 
			TokensAmount = amount.wdivide(buyPrice);
			safeCheck(TokensAmount);						
			amountRaisedEth = amountRaisedEth.plus(amount);						
		}						
								
		_currentSupply = _currentSupply.plus(TokensAmount);
		contrubutedAmount[msg.sender] = contrubutedAmount[msg.sender].plus(msg.value);		
		balanceOf[this] = balanceOf[this].minus(TokensAmount);						
		balanceOf[msg.sender] = balanceOf[msg.sender].plus(TokensAmount);                   		 
		Transfer(this, msg.sender, TokensAmount);                									 
		return;                                     	            								 
	}						
	function () payable   
	{
		buyTokens();
	}
	 
	function CloseCrowdSale(uint256 _maximumBuyBackAmountInCents) internal 								
	{
		if (amountRaisedEth >= fundingGoal)
		{
			fundingGoalReached = true;																 
			GoalReached(beneficiary, amountRaisedEth);
		}
		crowdsaleClosed = true;																		 
		maximumBuyBackPriceInCents = _maximumBuyBackAmountInCents;            						 
		totalSupply = _currentSupply;
		balanceOf[this] = 0;
		maximumBuyBackAmountInCents = maximumBuyBackPriceInCents.multiply(totalSupply);				 
		maximumBuyBackAmountInWEI = maximumBuyBackAmountInWEI.multiply(totalSupply);
	}
}

contract GAP is ICOToken
{	
	 
	string public maximumBuyBack = "Token 0.05 ETH per Token";										 
	uint256 public KilledTillNow;
	uint256 public sellPrice;
	uint256 public mustToSellCourses;
	uint public depositsTillNow;
	uint public actualPriceInCents;
	address public Killer;	
	
	event FundTransfer(address backer, uint amount, bool isContribution);
	
	function GAP() ICOToken()
	{
		Killer = 0;
		KilledTillNow = 0;
		sellPrice = 0;
		mustToSellCourses = 0;
		depositsTillNow = 0;
	}
	
	 
	function checkActualPrice() returns (uint256 _sellPrice)
	{
		return sellPrice;
	}
				
	 
	 
	function BuyBackStart(uint256 actualSellPriceInWei, uint256 _mustToSellCourses, uint256 maxBuyBackPriceCents) onlyOwner			
	{																	
		CloseCrowdSale(maxBuyBackPriceCents);															
		sellPrice = actualSellPriceInWei;
		mustToSellCourses = _mustToSellCourses;
	}			
	
	function deposit (uint _deposits, uint256 actualSellPriceInWei, uint _actualPriceInCents) onlyOwner payable												
	{
		assert(_deposits < 100);																	 
		depositsTillNow = depositsTillNow.plus(_deposits);          								 
		assert(mustToSellCourses > 0);
		if(mustToSellCourses < _deposits)
		{
			_deposits = mustToSellCourses;		
		}
		mustToSellCourses = mustToSellCourses.minus(_deposits);										 
		sellPrice = actualSellPriceInWei;
		actualPriceInCents = _actualPriceInCents;
	}	
				
	function sell(uint256 amount) onlyContributer returns (uint256 revenue)			
	{	
	    require(this.balance >= amount * sellPrice);                                                  
		revenue = amount.multiply(sellPrice);														 
		amount = amount.multiply(10 ** 18);
		balanceOf[msg.sender] = balanceOf[msg.sender].minus(amount);                   				 
		balanceOf[Killer] = balanceOf[Killer].plus(amount);                         				 
		KilledTokens[msg.sender] = KilledTokens[msg.sender].plus(amount);							 
		KilledTillNow = KilledTillNow.plus(amount);													 
			
		msg.sender.transfer(revenue);															 
		
		Transfer(msg.sender, Killer, amount);             											 
		return revenue;                                 											 
	}
	
	function ownerWithdrawal(uint256 amountInWei, address _to) onlyOwner
	{						
		uint256 _value = amountInWei;						
		_to.transfer(_value);						
	}
	
	function safeWithdrawal() afterDeadline 			
	{			
		if (!fundingGoalReached) 			
		{			
			uint256 tokensAmount = balanceOf[msg.sender];
			uint256 amountForReturn = contrubutedAmount[msg.sender];
			balanceOf[msg.sender] = 0;
			KilledTillNow = KilledTillNow.plus(tokensAmount);
			KilledTokens[msg.sender] = KilledTokens[msg.sender].plus(tokensAmount);
			require(tokensAmount > 0);
			contrubutedAmount[msg.sender] = contrubutedAmount[msg.sender].minus(amountForReturn);
            msg.sender.transfer(amountForReturn);
		}
		
		if(fundingGoalReached && beneficiary == msg.sender)
		{
			require(fundingGoalReached && beneficiary == msg.sender);
			beneficiary.transfer(amountRaisedEth); 
		}
	}
}