 

pragma solidity ^0.4.11;


 
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


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
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

contract SmokeExchangeCoin is StandardToken {
  string public name = "Smoke Exchange Token";
  string public symbol = "SMX";
  uint256 public decimals = 18;  
  address public ownerAddress;
    
  event Distribute(address indexed to, uint256 value);
  
  function SmokeExchangeCoin(uint256 _totalSupply, address _ownerAddress, address smxTeamAddress, uint256 allocCrowdsale, uint256 allocAdvBounties, uint256 allocTeam) {
    ownerAddress = _ownerAddress;
    totalSupply = _totalSupply;
    balances[ownerAddress] += allocCrowdsale;
    balances[ownerAddress] += allocAdvBounties;
    balances[smxTeamAddress] += allocTeam;
  }
  
  function distribute(address _to, uint256 _value) returns (bool) {
    require(balances[ownerAddress] >= _value);
    balances[ownerAddress] = balances[ownerAddress].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Distribute(_to, _value);
    return true;
  }
}

contract SmokeExchangeCoinCrowdsale is Ownable {
  using SafeMath for uint256;

   
  SmokeExchangeCoin public token;
  
   
  uint256 public startTime;
  uint256 public endTime;
  uint256 public privateStartTime;
  uint256 public privateEndTime;

   
  address public wallet;

   
  uint256 public weiRaised;
  
  uint private constant DECIMALS = 1000000000000000000;
   
  uint public constant TOTAL_SUPPLY = 28500000 * DECIMALS;  
  uint public constant BASIC_RATE = 300;  
  uint public constant PRICE_STANDARD    = BASIC_RATE * DECIMALS; 
  uint public constant PRICE_PREBUY = PRICE_STANDARD * 150/100;
  uint public constant PRICE_STAGE_ONE   = PRICE_STANDARD * 125/100;
  uint public constant PRICE_STAGE_TWO   = PRICE_STANDARD * 115/100;
  uint public constant PRICE_STAGE_THREE   = PRICE_STANDARD * 107/100;
  uint public constant PRICE_STAGE_FOUR = PRICE_STANDARD;
  
  uint public constant PRICE_PREBUY_BONUS = PRICE_STANDARD * 165/100;
  uint public constant PRICE_STAGE_ONE_BONUS = PRICE_STANDARD * 145/100;
  uint public constant PRICE_STAGE_TWO_BONUS = PRICE_STANDARD * 125/100;
  uint public constant PRICE_STAGE_THREE_BONUS = PRICE_STANDARD * 115/100;
  uint public constant PRICE_STAGE_FOUR_BONUS = PRICE_STANDARD;
  
   
  
   
  uint public constant STAGE_ONE_TIME_END = 1 weeks;
  uint public constant STAGE_TWO_TIME_END = 2 weeks;
  uint public constant STAGE_THREE_TIME_END = 3 weeks;
  uint public constant STAGE_FOUR_TIME_END = 4 weeks;
  
  uint public constant ALLOC_CROWDSALE = TOTAL_SUPPLY * 75/100;
  uint public constant ALLOC_TEAM = TOTAL_SUPPLY * 15/100;  
  uint public constant ALLOC_ADVISORS_BOUNTIES = TOTAL_SUPPLY * 10/100;
  
  uint256 public smxSold = 0;
  
  address public ownerAddress;
  address public smxTeamAddress;
  
   
  bool public halted;
  
   
  uint public cap; 
  
   
  uint public privateCap;
  
  uint256 public bonusThresholdWei;
  
    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
   
  modifier isNotHalted() {
    require(!halted);
    _;
  }
  
   
  function SmokeExchangeCoinCrowdsale(uint256 _privateStartTime, uint256 _startTime, address _ethWallet, uint256 _privateWeiCap, uint256 _weiCap, uint256 _bonusThresholdWei, address _smxTeamAddress) {
    require(_privateStartTime >= now);
    require(_ethWallet != 0x0);    
    require(_smxTeamAddress != 0x0);    
    
    privateStartTime = _privateStartTime;
     
    privateEndTime = privateStartTime + 10 days;    
    startTime = _startTime;
    
     
    require(_startTime >= privateEndTime);
    
    endTime = _startTime + STAGE_FOUR_TIME_END;
    
    wallet = _ethWallet;   
    smxTeamAddress = _smxTeamAddress;
    ownerAddress = msg.sender;
    
    cap = _weiCap;    
    privateCap = _privateWeiCap;
    bonusThresholdWei = _bonusThresholdWei;
                 
    token = new SmokeExchangeCoin(TOTAL_SUPPLY, ownerAddress, smxTeamAddress, ALLOC_CROWDSALE, ALLOC_ADVISORS_BOUNTIES, ALLOC_TEAM);
  }
  
   
  function () payable {
    buyTokens(msg.sender);
  }
  
   
  function validPurchase() internal constant returns (bool) {
    bool privatePeriod = now >= privateStartTime && now < privateEndTime;
    bool withinPeriod = (now >= startTime && now <= endTime) || (privatePeriod);
    bool nonZeroPurchase = (msg.value != 0);
     
    bool withinCap = privatePeriod ? (weiRaised.add(msg.value) <= privateCap) : (weiRaised.add(msg.value) <= cap);
     
    bool smxAvailable = (ALLOC_CROWDSALE - smxSold > 0); 
    return withinPeriod && nonZeroPurchase && withinCap && smxAvailable;
     
  }

   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    bool tokenSold = ALLOC_CROWDSALE - smxSold == 0;
    bool timeEnded = now > endTime;
    return timeEnded || capReached || tokenSold;
  }  
  
   
  function buyTokens(address beneficiary) payable isNotHalted {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = SafeMath.div(SafeMath.mul(weiAmount, getCurrentRate(weiAmount)), 1 ether);
     
    require(ALLOC_CROWDSALE - smxSold >= tokens);

     
    weiRaised = weiRaised.add(weiAmount);
     
    smxSold = smxSold.add(tokens);
    
     
    token.distribute(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    forwardFunds();
  }
  
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
   
  function getCurrentRate(uint256 _weiAmount) constant returns (uint256) {  
      
      bool hasBonus = _weiAmount >= bonusThresholdWei;
  
      if (now < startTime) {
        return hasBonus ? PRICE_PREBUY_BONUS : PRICE_PREBUY;
      }
      uint delta = SafeMath.sub(now, startTime);

       
      if (delta > STAGE_THREE_TIME_END) {
        return hasBonus ? PRICE_STAGE_FOUR_BONUS : PRICE_STAGE_FOUR;
      }
       
      if (delta > STAGE_TWO_TIME_END) {
        return hasBonus ? PRICE_STAGE_THREE_BONUS : PRICE_STAGE_THREE;
      }
       
      if (delta > STAGE_ONE_TIME_END) {
        return hasBonus ? PRICE_STAGE_TWO_BONUS : PRICE_STAGE_TWO;
      }

       
      return hasBonus ? PRICE_STAGE_ONE_BONUS : PRICE_STAGE_ONE;
  }
  
   
  function toggleHalt(bool _halted) onlyOwner {
    halted = _halted;
  }
}