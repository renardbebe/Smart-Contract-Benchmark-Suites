 

pragma solidity 0.4.18;

 
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

contract LordCoin is StandardToken {
  using SafeMath for uint256;

  string public name = "Lord Coin";
  string public symbol = "LC";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 20000000 * 1 ether;

  event Burn(address indexed from, uint256 value);

  function LordCoin() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  function burn(uint256 _value) returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(msg.sender, _value);
    return true;
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

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract LordCoinICO is Pausable {
    using SafeMath for uint256;

    string public constant name = "Lord Coin ICO";

    LordCoin public LC;
    address public beneficiary;

    uint256 public priceETH;
    uint256 public priceLC;

    uint256 public weiRaised = 0;
    uint256 public investorCount = 0;
    uint256 public lcSold = 0;
    uint256 public manualLCs = 0;

    uint public startTime;
    uint public endTime;
    uint public time1;
    uint public time2;

    uint public constant period2Numerator = 110;
    uint public constant period2Denominator = 100;
    uint public constant period3Numerator = 125;
    uint public constant period3Denominator = 100; 

    uint256 public constant premiumValue = 500 * 1 ether;

    bool public crowdsaleFinished = false;

    event GoalReached(uint256 amountRaised);
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    modifier onlyAfter(uint time) {
        require(getCurrentTime() > time);
        _;
    }

    modifier onlyBefore(uint time) {
        require(getCurrentTime() < time);
        _;
    }

    function LordCoinICO (
        address _lcAddr,
        address _beneficiary,
        uint256 _priceETH,
        uint256 _priceLC,

        uint _startTime,
        uint _period1,
        uint _period2,
        uint _duration
    ) public {
        LC = LordCoin(_lcAddr);
        beneficiary = _beneficiary;
        priceETH = _priceETH;
        priceLC = _priceLC;

        startTime = _startTime;
        time1 = startTime + _period1 * 1 hours;
        time2 = time1 + _period2 * 1 hours;
        endTime = _startTime + _duration * 1 days;
    }

    function () external payable whenNotPaused {
        require(msg.value >= 0.01 * 1 ether);
        doPurchase();
    }

    function withdraw(uint256 _value) external onlyOwner {
        beneficiary.transfer(_value);
    }

    function finishCrowdsale() external onlyOwner {
        LC.transfer(beneficiary, LC.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {
        require(!crowdsaleFinished);
        require(msg.sender != address(0));

        uint256 lcCount = msg.value.mul(priceLC).div(priceETH);

        if (getCurrentTime() > time1 && getCurrentTime() <= time2 && msg.value < premiumValue) {
            lcCount = lcCount.mul(period2Denominator).div(period2Numerator);
        }

        if (getCurrentTime() > time2 && msg.value < premiumValue) {
            lcCount = lcCount.mul(period3Denominator).div(period3Numerator);
        }

        uint256 _wei = msg.value;

        if (LC.balanceOf(this) < lcCount) {
          uint256 expectingLCCount = lcCount;
          lcCount = LC.balanceOf(this);
          _wei = msg.value.mul(lcCount).div(expectingLCCount);
          msg.sender.transfer(msg.value.sub(_wei));
        }

        transferLCs(msg.sender, _wei, lcCount);
    }

    function transferLCs(address _sender, uint256 _wei, uint256 _lcCount) private {

        if (LC.balanceOf(_sender) == 0) investorCount++;

        LC.transfer(_sender, _lcCount);

        lcSold = lcSold.add(_lcCount);
        weiRaised = weiRaised.add(_wei);

        NewContribution(_sender, _lcCount, _wei);

        if (LC.balanceOf(this) == 0) {
            GoalReached(weiRaised);
        }

    }

    function manualSell(address _sender, uint256 _value) external onlyOwner {
        transferLCs(_sender, 0, _value);
        manualLCs = manualLCs.add(_value);
    }



    function getCurrentTime() internal constant returns(uint256) {
        return now;
    }
}