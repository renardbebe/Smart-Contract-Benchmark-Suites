 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

 
contract MINDToken is StandardToken, Ownable {
    string  public  constant name = "MIND Token";
    string  public  constant symbol = "MIND";
    uint8    public  constant decimals = 18;

    uint    public  transferableStartTime;

    address public  tokenSaleContract;
    address public  fullTokenWallet;

    function gettransferableStartTime() constant returns (uint){return now - transferableStartTime;}

    modifier onlyWhenTransferEnabled() 
    {
        if ( now < transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == fullTokenWallet || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) 
    {
        require(to != address(this));
        _;
    }

    modifier onlySaleContract()
    {
        require(msg.sender == tokenSaleContract);
        _;
    }

    function MINDToken(
        uint tokenTotalAmount, 
        uint _transferableStartTime, 
        address _admin, 
        address _fullTokenWallet) 
    {
        
         
        totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;
        tokenSaleContract = msg.sender;
        fullTokenWallet = _fullTokenWallet;

        transferOwnership(_admin);  

    }

     
    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

     
    function burn(uint _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns(bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

     
    function enableTransferEarlier ()
        public
        onlySaleContract
    {
        transferableStartTime = now + 3 days;
    }


     
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }

}


 
contract StandardCrowdsale {
    using SafeMath for uint256;

     
    StandardToken public token;  

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    function StandardCrowdsale(
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _rate, 
        address _wallet) 
    {
        
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        
        token = createTokenContract();  
    }

     
     
     
    function createTokenContract() 
        internal 
        returns(StandardToken) 
    {
        return new StandardToken();
    }

     
    function () 
       payable 
    {
        buyTokens();
    }

     
     
    function buyTokens() 
       public 
       payable 
    {
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);
        tokens += getBonus(tokens);

         
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(msg.sender, tokens));  
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();

        postBuyTokens();
    }

     
    function postBuyTokens ()
        internal
    {
    }

     
     
    function forwardFunds() 
       internal 
    {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() 
        internal 
        returns(bool) 
    {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() 
        public 
        constant 
        returns(bool) 
    {
        return now > endTime;
    }

    modifier onlyBeforeSale() {
        require(now < startTime);
        _;
    }

     
    modifier only24HBeforeSale() {
        require(now < startTime.sub(1 days));
        _;
    }

    function getBonus(uint256 _tokens) constant returns (uint256 bonus) {
        return 0;
    }
}

 
contract CappedCrowdsale is StandardCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
   
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract MINDTokenPreSale is Ownable, CappedCrowdsale {
     
    uint private constant HARD_CAP_IN_WEI = 10000 ether;

     
    uint public constant TOTAL_MIND_TOKEN_SUPPLY = 50000000;

     
    uint private constant RATE_ETH_MIND = 1000;

     
    address public constant TEAM_VESTING_WALLET = 0xb3F3D774C3575aB01bce9d9a9Fe92Aa41926a92e;
    uint public constant TEAM_VESTING_AMOUNT = 7500000e18;

     
    address public constant FULL_TOKEN_WALLET = 0x8759A03B3BEB1aa1A7bA765792cF83CaAe4f28E9;
    uint public constant FULL_TOKEN_AMOUNT = 20000000e18;

     
     
    address private constant MIND_FOUNDATION_WALLET = 0xDfD5e09bB845d39bd05be4664271e471FA8dA4E6;
    uint public constant MIND_FOUNDATION_AMOUNT = 7500000e18;

     
    uint public constant PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC = 3 days;

    event PreSaleTokenSoldout();

    function MINDTokenPreSale(uint256 _startTime, uint256 _endTime)
      CappedCrowdsale(HARD_CAP_IN_WEI)
      StandardCrowdsale(_startTime, _endTime, RATE_ETH_MIND, MIND_FOUNDATION_WALLET)
    {
        
        token.transfer(TEAM_VESTING_WALLET, TEAM_VESTING_AMOUNT);

        token.transfer(FULL_TOKEN_WALLET, FULL_TOKEN_AMOUNT);

        token.transfer(MIND_FOUNDATION_WALLET, MIND_FOUNDATION_AMOUNT);
        
    }

     
    function createTokenContract () 
      internal 
      returns(StandardToken) 
    {
        return new MINDToken(TOTAL_MIND_TOKEN_SUPPLY, endTime.add(PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC), MIND_FOUNDATION_WALLET, FULL_TOKEN_WALLET);
    }

     
    function getBonus(uint256 _tokens) constant returns (uint256 bonus) {
        require(_tokens != 0);
        if (startTime <= now && now < startTime + 1 days) {
            return _tokens.div(2);
        } else if (startTime + 1 days <= now && now < startTime + 2 days ) {
            return _tokens.div(4);
        } else if (startTime + 2 days <= now && now < startTime + 3 days ) {
            return _tokens.div(10);
        }

        return 0;
    }

     
    function drainRemainingToken () 
      public
      onlyOwner
    {
        require(hasEnded());
        token.transfer(MIND_FOUNDATION_WALLET, token.balanceOf(this));
    }


     
    function postBuyTokens ()
        internal
    {
        if ( weiRaised >= HARD_CAP_IN_WEI ) 
        {
            MINDToken mindToken = MINDToken (token);
            mindToken.enableTransferEarlier();
            PreSaleTokenSoldout();
        }
    }
}