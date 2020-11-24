 

pragma solidity 0.4.15;

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

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
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

contract BlockbidCrowdsale is Crowdsale, Ownable {

  uint public goal;
  uint public cap;
  uint public earlybonus;
  uint public standardrate;
  bool public goalReached = false;
  bool public paused = false;
  uint public constant weeklength = 604800;

  mapping(address => uint) public weiContributed;
  address[] public contributors;

  event LogClaimRefund(address _address, uint _value);

  modifier notPaused() {
    if (paused) {
      revert();
    }
    _;
  }

  function BlockbidCrowdsale(uint _goal, uint _cap, uint _startTime, uint _endTime, uint _rate, uint _earlyBonus, address _wallet)
  Crowdsale(_startTime, _endTime, _rate, _wallet) public {
    require(_cap > 0);
    require(_goal > 0);

    standardrate = _rate;
    earlybonus = _earlyBonus;
    cap = _cap;
    goal = _goal;
  }

   
   
  function validPurchase() internal constant returns (bool) {

    updateRate();

    bool withinPeriod = (now >= startTime && now <= endTime);
    bool withinPurchaseLimit = (msg.value >= 0.1 ether && msg.value <= 100 ether);
    bool withinCap = (token.totalSupply() <= cap);
    return withinPeriod && withinPurchaseLimit && withinCap;
  }

   
  function tokensPurchased() internal constant returns (uint) {
    return rate.mul(msg.value).mul(100000000).div(1 ether);
  }

   
  function updateRate() internal returns (bool) {

    if (now >= startTime.add(weeklength.mul(4))) {
      rate = 200;
    }
    else if (now >= startTime.add(weeklength.mul(3))) {
      rate = standardrate;
    }
    else if (now >= startTime.add(weeklength.mul(2))) {
      rate = standardrate.add(earlybonus.sub(40));
    }
    else if (now >= startTime.add(weeklength)) {
      rate = standardrate.add(earlybonus.sub(20));
    }
    else {
      rate = standardrate.add(earlybonus);
    }

    return true;
  }

  function buyTokens(address beneficiary) notPaused public payable {
    require(beneficiary != 0x0);

     
    if (msg.sender == wallet) {
      require(hasEnded());
      require(!goalReached);
    }
     
    else {
      require(validPurchase());
    }

     
    weiRaised = weiRaised.add(msg.value);

     
    if (weiContributed[beneficiary] > 0) {
      weiContributed[beneficiary] = weiContributed[beneficiary].add(msg.value);
    }
     
    else {
      weiContributed[beneficiary] = msg.value;
      contributors.push(beneficiary);
    }

     
    token.mint(beneficiary, tokensPurchased());
    TokenPurchase(msg.sender, beneficiary, msg.value, tokensPurchased());
    token.mint(wallet, (tokensPurchased().div(4)));

    if (token.totalSupply() > goal) {
      goalReached = true;
    }

     
    if (msg.sender != wallet) {
      forwardFunds();
    }
  }

  function getContributorsCount() public constant returns(uint) {
    return contributors.length;
  }

   
  function claimRefund() notPaused public returns (bool) {
    require(!goalReached);
    require(hasEnded());
    uint contributedAmt = weiContributed[msg.sender];
    require(contributedAmt > 0);
    weiContributed[msg.sender] = 0;
    msg.sender.transfer(contributedAmt);
    LogClaimRefund(msg.sender, contributedAmt);
    return true;
  }

   
  function setPaused(bool _val) onlyOwner public returns (bool) {
    paused = _val;
    return true;
  }

   
  function kill() onlyOwner public {
    require(!goalReached);
    require(hasEnded());
    selfdestruct(wallet);
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new BlockbidMintableToken();
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract BlockbidMintableToken is MintableToken {

  string public constant name = "Blockbid Token";
  string public constant symbol = "BID";
  uint8 public constant decimals = 8;

}