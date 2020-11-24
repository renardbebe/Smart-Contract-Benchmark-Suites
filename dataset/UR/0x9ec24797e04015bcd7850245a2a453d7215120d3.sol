 

pragma solidity 0.4.19;

 
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



contract PlayBetsToken is StandardToken {

  string public constant name = "Play Bets Token";
  string public constant symbol = "PLT";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 300 * 1e6 * 1 ether;

  function PlayBetsToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
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


contract PlayBetsPreSale is Ownable {
    string public constant name = "PlayBets Closed Pre-Sale";

    using SafeMath for uint256;

    PlayBetsToken public token;
    address public beneficiary;

    uint256 public tokensPerEth;

    uint256 public weiRaised = 0;
    uint256 public tokensSold = 0;
    uint256 public investorCount = 0;

    uint public startTime;
    uint public endTime;

    bool public crowdsaleFinished = false;

    event GoalReached(uint256 raised, uint256 tokenAmount);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    modifier onlyAfter(uint time) {
        require(currentTime() > time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(currentTime() < time);
        _;
    }

    function PlayBetsPreSale (
        address _tokenAddr,
        address _beneficiary,

        uint256 _tokensPerEth,

        uint _startTime,
        uint _duration
    ) {
        token = PlayBetsToken(_tokenAddr);
        beneficiary = _beneficiary;

        tokensPerEth = _tokensPerEth;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 days;
    }

    function () payable {
        require(msg.value >= 0.01 * 1 ether);
        doPurchase();
    }

    function withdraw(uint256 _value) onlyOwner {
        beneficiary.transfer(_value);
    }

    function finishCrowdsale() onlyOwner {
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {
        
        require(!crowdsaleFinished);
        require(msg.sender != address(0));

        uint256[5] memory _bonusPattern = [ uint256(120), 115, 110, 105, 100];
        uint[4] memory _periodPattern = [ uint(24), 24 * 2, 24 * 7, 24 * 14];

        uint256 tokenCount = tokensPerEth * msg.value;

        uint calcPeriod = startTime;
        uint prevPeriod = 0;
        uint256 _now = currentTime();

        for(uint8 i = 0; i < _periodPattern.length; ++i) {
            calcPeriod = startTime.add(_periodPattern[i] * 1 hours);

            if (prevPeriod < _now && _now <= calcPeriod) {
                tokenCount = tokenCount.mul(_bonusPattern[i]).div(100);
                break;
            }
            prevPeriod = calcPeriod;
        }

        uint256 _wei = msg.value;
        uint256 _availableTokens = token.balanceOf(this);

        if (_availableTokens < tokenCount) {
          uint256 expectingTokenCount = tokenCount;
          tokenCount = _availableTokens;
          _wei = msg.value.mul(tokenCount).div(expectingTokenCount);
          msg.sender.transfer(msg.value.sub(_wei));
        }

        if (token.balanceOf(msg.sender) == 0) {
            investorCount++;
        }
        token.transfer(msg.sender, tokenCount);

        weiRaised = weiRaised.add(_wei);
        tokensSold = tokensSold.add(tokenCount);


        NewContribution(msg.sender, tokenCount, _wei);

        if (token.balanceOf(this) == 0) {
            GoalReached(weiRaised, tokensSold);
        }
    }

    function manualSell(address _sender, uint256 _value) external onlyOwner {
        token.transfer(_sender, _value);
        tokensSold = tokensSold.add(_value);
    }

    function currentTime() internal constant returns(uint256) {
        return now;
    }
}