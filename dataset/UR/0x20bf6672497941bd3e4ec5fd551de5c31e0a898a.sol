 

pragma solidity ^0.4.11;


 
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract SetherToken is MintableToken {

    string public constant name = "Sether";
    string public constant symbol = "SETH";
    uint8 public constant decimals = 18;

    function getTotalSupply() public returns (uint256) {
        return totalSupply;
    }
}

 
contract SetherBaseCrowdsale {
    using SafeMath for uint256;

     
    SetherToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event SethTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function SetherBaseCrowdsale(uint256 _rate, address _wallet) {
        require(_rate > 0);
        require(_wallet != address(0));

        token = createTokenContract();
        rate = _rate;
        wallet = _wallet;
    }

     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);

        SethTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function hasStarted() public constant returns (bool) {
        return now < startTime;
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
     
    function computeTokens(uint256 weiAmount) internal returns (uint256) {
         
    }

     
    function isWithinTokenAllocLimit(uint256 _tokens) internal returns (bool) {
         
    }
    
     
    function createTokenContract() internal returns (SetherToken) {
        return new SetherToken();
    }
}

 
contract SetherMultiStepCrowdsale is SetherBaseCrowdsale {
    uint256 public constant PRESALE_LIMIT = 25 * (10 ** 6) * (10 ** 18);
    uint256 public constant CROWDSALE_LIMIT = 55 * (10 ** 6) * (10 ** 18);
    
    uint256 public constant PRESALE_BONUS_LIMIT = 1 * (10 ** 17);

     
    uint public constant PRESALE_PERIOD = 53 days;
     
    uint public constant CROWD_WEEK1_PERIOD = 7 days;
     
    uint public constant CROWD_WEEK2_PERIOD = 7 days;
     
    uint public constant CROWD_WEEK3_PERIOD = 7 days;
     
    uint public constant CROWD_WEEK4_PERIOD = 7 days;

    uint public constant PRESALE_BONUS = 40;
    uint public constant CROWD_WEEK1_BONUS = 25;
    uint public constant CROWD_WEEK2_BONUS = 20;
    uint public constant CROWD_WEEK3_BONUS = 10;

    uint256 public limitDatePresale;
    uint256 public limitDateCrowdWeek1;
    uint256 public limitDateCrowdWeek2;
    uint256 public limitDateCrowdWeek3;

    function SetherMultiStepCrowdsale() {

    }

    function isWithinPresaleTimeLimit() internal returns (bool) {
        return now <= limitDatePresale;
    }

    function isWithinCrowdWeek1TimeLimit() internal returns (bool) {
        return now <= limitDateCrowdWeek1;
    }

    function isWithinCrowdWeek2TimeLimit() internal returns (bool) {
        return now <= limitDateCrowdWeek2;
    }

    function isWithinCrowdWeek3TimeLimit() internal returns (bool) {
        return now <= limitDateCrowdWeek3;
    }

    function isWithinCrodwsaleTimeLimit() internal returns (bool) {
        return now <= endTime && now > limitDatePresale;
    }

    function isWithinPresaleLimit(uint256 _tokens) internal returns (bool) {
        return token.getTotalSupply().add(_tokens) <= PRESALE_LIMIT;
    }

    function isWithinCrowdsaleLimit(uint256 _tokens) internal returns (bool) {
        return token.getTotalSupply().add(_tokens) <= CROWDSALE_LIMIT;
    }

    function validPurchase() internal constant returns (bool) {
        return super.validPurchase() &&
                 !(isWithinPresaleTimeLimit() && msg.value < PRESALE_BONUS_LIMIT);
    }

    function isWithinTokenAllocLimit(uint256 _tokens) internal returns (bool) {
        return (isWithinPresaleTimeLimit() && isWithinPresaleLimit(_tokens)) ||
                        (isWithinCrodwsaleTimeLimit() && isWithinCrowdsaleLimit(_tokens));
    }

    function computeTokens(uint256 weiAmount) internal returns (uint256) {
        uint256 appliedBonus = 0;
        if (isWithinPresaleTimeLimit()) {
            appliedBonus = PRESALE_BONUS;
        } else if (isWithinCrowdWeek1TimeLimit()) {
            appliedBonus = CROWD_WEEK1_BONUS;
        } else if (isWithinCrowdWeek2TimeLimit()) {
            appliedBonus = CROWD_WEEK2_BONUS;
        } else if (isWithinCrowdWeek3TimeLimit()) {
            appliedBonus = CROWD_WEEK3_BONUS;
        }

        return weiAmount.mul(10).mul(100 + appliedBonus).div(rate);
    }
}

 
contract SetherCappedCrowdsale is SetherMultiStepCrowdsale {
    using SafeMath for uint256;

    uint256 public constant HARD_CAP = 55 * (10 ** 6) * (10 ** 18);

    function SetherCappedCrowdsale() {
        
    }

     
     
    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= HARD_CAP;

        return super.validPurchase() && withinCap;
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= HARD_CAP;
        return super.hasEnded() || capReached;
    }
}

 
contract SetherStartableCrowdsale is SetherBaseCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isStarted = false;

  event SetherStarted();

   
  function start() onlyOwner public {
    require(!isStarted);
    require(!hasStarted());

    starting();
    SetherStarted();

    isStarted = true;
  }

   
  function starting() internal {
     
  }
}

 
contract SetherFinalizableCrowdsale is SetherBaseCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event SetherFinalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    SetherFinalized();

    isFinalized = true;
  }

   
  function finalization() internal {
     
  }
}

 
contract SetherCrowdsale is SetherCappedCrowdsale, SetherStartableCrowdsale, SetherFinalizableCrowdsale {

    function SetherCrowdsale(uint256 rate, address _wallet) 
        SetherCappedCrowdsale()
        SetherFinalizableCrowdsale()
        SetherStartableCrowdsale()
        SetherMultiStepCrowdsale()
        SetherBaseCrowdsale(rate, _wallet) 
    {
   
    }

    function starting() internal {
        super.starting();
        startTime = now;
        limitDatePresale = startTime + PRESALE_PERIOD;
        limitDateCrowdWeek1 = limitDatePresale + CROWD_WEEK1_PERIOD; 
        limitDateCrowdWeek2 = limitDateCrowdWeek1 + CROWD_WEEK2_PERIOD; 
        limitDateCrowdWeek3 = limitDateCrowdWeek2 + CROWD_WEEK3_PERIOD;         
        endTime = limitDateCrowdWeek3 + CROWD_WEEK4_PERIOD;
    }

    function finalization() internal {
        super.finalization();
        uint256 ownerShareTokens = token.getTotalSupply().mul(9).div(11);

        token.mint(wallet, ownerShareTokens);
    }
}