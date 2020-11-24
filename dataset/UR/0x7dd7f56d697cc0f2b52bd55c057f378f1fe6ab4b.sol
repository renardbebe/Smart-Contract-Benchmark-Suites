 

pragma solidity ^0.4.13;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract STEAK is StandardToken {

    uint256 public initialSupply;
     
     

    string public constant name   = "$TEAK";
    string public constant symbol = "$TEAK";
     
     
     
    uint8 public constant decimals = 18;
     

    address public tokenSaleContract;

    modifier validDestination(address to)
    {
        require(to != address(this));
        _;
    }

    function STEAK(uint tokenTotalAmount)
    public
    {
        initialSupply = tokenTotalAmount * (10 ** uint256(decimals));
        totalSupply = initialSupply;

         
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        tokenSaleContract = msg.sender;
    }

     
    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

     
    function burn(uint _value)
        public
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
        returns(bool)
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
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
        public
    {
         
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
        public
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
}

contract CappedCrowdsale is StandardCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
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

contract InfiniteCappedCrowdsale is StandardCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;

     
    function InfiniteCappedCrowdsale(uint256 _cap, uint256 _rate, address _wallet)
        CappedCrowdsale(_cap)
        StandardCrowdsale(0, uint256(int256(-1)), _rate, _wallet)
        public
    {

    }
}

contract ICS is InfiniteCappedCrowdsale {

    uint256 public constant TOTAL_SUPPLY = 975220000000;
    uint256 public constant ARBITRARY_VALUATION_IN_ETH = 33;
     
    uint256 public constant ETH_TO_WEI = (10 ** 18);
    uint256 public constant TOKEN_RATE = (TOTAL_SUPPLY / ARBITRARY_VALUATION_IN_ETH);
     


    function ICS(address _wallet)
        InfiniteCappedCrowdsale(ARBITRARY_VALUATION_IN_ETH * ETH_TO_WEI, TOKEN_RATE, _wallet)
        public
    {

    }

    function createTokenContract() internal returns (StandardToken) {
        return new STEAK(TOTAL_SUPPLY);
    }
}