 

pragma solidity 0.4.15;

 
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

         
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(msg.sender, tokens));  
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();
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

 
contract ProgressiveIndividualCappedCrowdsale is StandardCrowdsale, Ownable {

    uint public constant TIME_PERIOD_IN_SEC = 1 days;
    uint public constant GAS_LIMIT_IN_WEI = 50000000000 wei;  
    uint256 public baseEthCapPerAddress = 0 ether;

    mapping(address=>uint) public participated;

     
    function validPurchase() 
        internal 
        returns(bool)
    {
        require(tx.gasprice <= GAS_LIMIT_IN_WEI);
        uint ethCapPerAddress = getCurrentEthCapPerAddress();
        participated[msg.sender] = participated[msg.sender].add(msg.value);
        return super.validPurchase() && participated[msg.sender] <= ethCapPerAddress;
    }

     
    function setBaseEthCapPerAddress(uint256 _baseEthCapPerAddress) 
        public
        onlyOwner 
        only24HBeforeSale
    {
        baseEthCapPerAddress = _baseEthCapPerAddress;
    }

     
    function getCurrentEthCapPerAddress() 
        public
        constant
        returns(uint)
    {
        if (block.timestamp < startTime) return 0;
        uint timeSinceStartInSec = block.timestamp.sub(startTime);
        uint currentPeriod = timeSinceStartInSec.div(TIME_PERIOD_IN_SEC).add(1);

         
        return (2 ** currentPeriod.sub(1)).mul(baseEthCapPerAddress);
    }
}

 
contract WhitelistedCrowdsale is StandardCrowdsale, Ownable {
    
    mapping(address=>bool) public registered;

    event RegistrationStatusChanged(address target, bool isRegistered);

     
    function changeRegistrationStatus(address target, bool isRegistered)
        public
        onlyOwner
        only24HBeforeSale
    {
        registered[target] = isRegistered;
        RegistrationStatusChanged(target, isRegistered);
    }

     
    function changeRegistrationStatuses(address[] targets, bool isRegistered)
        public
        onlyOwner
        only24HBeforeSale
    {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

     
    function validPurchase() internal returns (bool) {
        return super.validPurchase() && registered[msg.sender];
    }
}

 
contract RequestToken is StandardToken, Ownable {
    string  public  constant name = "Request Token";
    string  public  constant symbol = "REQ";
    uint8    public  constant decimals = 18;

    uint    public  transferableStartTime;

    address public  tokenSaleContract;
    address public  earlyInvestorWallet;


    modifier onlyWhenTransferEnabled() 
    {
        if ( now <= transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == earlyInvestorWallet || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) 
    {
        require(to != address(this));
        _;
    }

    function RequestToken(
        uint tokenTotalAmount, 
        uint _transferableStartTime, 
        address _admin, 
        address _earlyInvestorWallet) 
    {
         
        totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;
        tokenSaleContract = msg.sender;
        earlyInvestorWallet = _earlyInvestorWallet;

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
        returns(bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

     
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }
}

 
contract RequestTokenSale is Ownable, CappedCrowdsale, WhitelistedCrowdsale, ProgressiveIndividualCappedCrowdsale {
     
    uint private constant HARD_CAP_IN_WEI = 100000 ether;

     
    uint public constant TOTAL_REQUEST_TOKEN_SUPPLY = 1000000000;

     
    uint private constant RATE_ETH_REQ = 5000;

     
    address public constant TEAM_VESTING_WALLET = 0xA76bC39aE4B88ef203C6Afe3fD219549d86D12f2;
    uint public constant TEAM_VESTING_AMOUNT = 150000000e18;

     
    address public constant EARLY_INVESTOR_WALLET = 0xa579E31b930796e3Df50A56829cF82Db98b6F4B3;
    uint public constant EARLY_INVESTOR_AMOUNT = 200000000e18;

     
     
    address private constant REQUEST_FOUNDATION_WALLET = 0xdD76B55ee6dAfe0c7c978bff69206d476a5b9Ce7;
    uint public constant REQUEST_FOUNDATION_AMOUNT = 150000000e18;

     
    uint public constant PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC = 3 days;

    function RequestTokenSale(uint256 _startTime, uint256 _endTime)
      ProgressiveIndividualCappedCrowdsale()
      WhitelistedCrowdsale()
      CappedCrowdsale(HARD_CAP_IN_WEI)
      StandardCrowdsale(_startTime, _endTime, RATE_ETH_REQ, REQUEST_FOUNDATION_WALLET)
    {
        token.transfer(TEAM_VESTING_WALLET, TEAM_VESTING_AMOUNT);

        token.transfer(EARLY_INVESTOR_WALLET, EARLY_INVESTOR_AMOUNT);

        token.transfer(REQUEST_FOUNDATION_WALLET, REQUEST_FOUNDATION_AMOUNT);
    }

     
    function createTokenContract () 
      internal 
      returns(StandardToken) 
    {
        return new RequestToken(TOTAL_REQUEST_TOKEN_SUPPLY, endTime.add(PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC), REQUEST_FOUNDATION_WALLET, EARLY_INVESTOR_WALLET);
    }

     
    function drainRemainingToken () 
      public
      onlyOwner
    {
        require(hasEnded());
        token.transfer(REQUEST_FOUNDATION_WALLET, token.balanceOf(this));
    }
  
}