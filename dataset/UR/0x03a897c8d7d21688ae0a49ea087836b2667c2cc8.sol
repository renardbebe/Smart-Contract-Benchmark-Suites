 

pragma solidity ^0.4.24;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract StrayToken is StandardToken, BurnableToken, Ownable {
	using SafeERC20 for ERC20;
	
	uint256 public INITIAL_SUPPLY = 1000000000;
	
	string public name = "Stray";
	string public symbol = "ST";
	uint8 public decimals = 18;

	address public companyWallet;
	address public privateWallet;
	address public fund;
	
	 
	constructor(address _companyWallet, address _privateWallet) public {
		require(_companyWallet != address(0));
		require(_privateWallet != address(0));
		
		totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
		companyWallet = _companyWallet;
		privateWallet = _privateWallet;
		
		 
		_preSale(companyWallet, totalSupply_.mul(15).div(100));
		
		 
		_preSale(privateWallet, totalSupply_.mul(25).div(100));
		
		 
		uint256 sold = balances[companyWallet].add(balances[privateWallet]);
	    balances[msg.sender] = balances[msg.sender].add(totalSupply_.sub(sold));
	    emit Transfer(address(0), msg.sender, balances[msg.sender]);
	}
	
	 
	function setFundContract(address _fund) onlyOwner public {
	    require(_fund != address(0));
	     
	     
	    require(_fund != address(this));
	    
	    fund = _fund;
	}
	
	 
	function burnAll(address _from) public {
	    require(fund == msg.sender);
	    require(0 != balances[_from]);
	    
	    _burn(_from, balances[_from]);
	}
	
	 
	function _preSale(address _to, uint256 _value) internal onlyOwner {
		balances[_to] = _value;
		emit Transfer(address(0), _to, _value);
	}
	
}

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

contract StrayCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;
    
     
    uint256 public softCapInToken;
    uint256 public hardCapInToken;
    uint256 public soldToken = 0;
    
     
    uint256 public bonusClosingTime0;
    uint256 public bonusClosingTime1;
    
     
    uint256 public bonusRateInPercent0 = 33;
    uint256 public bonusRateInPercent1 = 20;
    
     
    uint256 public mininumContributeUSD = 100;
    
     
    uint256 public decimalsETHToUSD;
    uint256 public exchangeRateETHToUSD;
   
    
    uint256 public mininumPurchaseTokenQuantity;
    
     
    uint256 public mininumContributeWei;
    
     
     
    uint256 public exchangeRateUSDToToken = 100;
    
     
    StrayToken public strayToken;
    
     
    RefundVault public vault;
    
     
    event RateUpdated(uint256 rate, uint256 mininumContributeWei);
    
     
    constructor(uint256 _softCapInUSD
        , uint256 _hardCapInUSD
        , address _fund
        , ERC20 _token
        , uint256 _openingTime
        , uint256 _closingTime
        , uint256 _bonusClosingTime0
        , uint256 _bonusClosingTime1
        ) 
        Crowdsale(1, _fund, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        public 
    {
         
        require(_bonusClosingTime0 >= _openingTime);
        require(_bonusClosingTime1 >= _bonusClosingTime0);
        require(_closingTime >= _bonusClosingTime1);
        
        bonusClosingTime0 = _bonusClosingTime0;
        bonusClosingTime1 = _bonusClosingTime1;
        
         
        strayToken = StrayToken(token);
        
         
        require(_softCapInUSD > 0 && _softCapInUSD <= _hardCapInUSD);
        
        softCapInToken = _softCapInUSD * exchangeRateUSDToToken * (10 ** uint256(strayToken.decimals()));
        hardCapInToken = _hardCapInUSD * exchangeRateUSDToToken * (10 ** uint256(strayToken.decimals()));
        
        require(strayToken.balanceOf(owner) >= hardCapInToken);
        
         
        vault = new RefundVault(_fund);
        
         
        mininumPurchaseTokenQuantity = exchangeRateUSDToToken * mininumContributeUSD 
            * (10 ** (uint256(strayToken.decimals())));
        
         
        setExchangeRateETHToUSD(40000, 2);
    }
    
     
    function setExchangeRateETHToUSD(uint256 _rate, uint256 _decimals) onlyOwner public {
         
         
         
         
         
         
         
        
        require(uint256(strayToken.decimals()).add(2) >= _decimals.add(18));
        
        exchangeRateETHToUSD = _rate;
        decimalsETHToUSD = _decimals;
        rate = _rate.mul(exchangeRateUSDToToken);
        if (uint256(strayToken.decimals()) >= _decimals.add(18)) {
            rate = rate.mul(10 ** (uint256(strayToken.decimals()).sub(18).sub(_decimals)));
        } else {
            rate = rate.div(10 ** (_decimals.add(18).sub(uint256(strayToken.decimals()))));
        }
        
        mininumContributeWei = mininumPurchaseTokenQuantity.div(rate); 
        
         
        if (mininumContributeWei * rate < mininumPurchaseTokenQuantity)
            mininumContributeWei += 1;
            
        emit RateUpdated(rate, mininumContributeWei);
    }
    
     
    function claimRefund() public {
        require(isFinalized);
        require(!softCapReached());

        vault.refund(msg.sender);
    }
    
     
    function softCapReached() public view returns (bool) {
        return soldToken >= softCapInToken;
    }
    
     
    function isInStage1() view public returns (bool) {
        return now <= bonusClosingTime0 && now >= openingTime;
    }
    
     
    function isInStage2() view public returns (bool) {
        return now <= bonusClosingTime1 && now > bonusClosingTime0;
    }
    
     
    function hasStarted() view public returns (bool) {
        return now >= openingTime;
    }
    
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= mininumContributeWei);
    }
    
     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        soldToken = soldToken.add(_tokenAmount);
        require(soldToken <= hardCapInToken);
        
       _tokenAmount = _addBonus(_tokenAmount);
        
        super._processPurchase(_beneficiary, _tokenAmount);
    }
    
     
    function finalization() internal {
        if (softCapReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        
         
        strayToken.burn(token.balanceOf(address(this)));
        
        super.finalization();
    }

     
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
    
     
    function _addBonus(uint256 _tokenAmount) internal view returns (uint256) {
        if (bonusClosingTime0 >= now) {
            _tokenAmount = _tokenAmount.mul(100 + bonusRateInPercent0).div(100);
        } else if (bonusClosingTime1 >= now) {
            _tokenAmount = _tokenAmount.mul(100 + bonusRateInPercent1).div(100);
        }
        
        require(_tokenAmount <= token.balanceOf(address(this)));
        
        return _tokenAmount;
    }
}