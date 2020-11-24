 

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Distributable is Ownable {
  mapping(address => bool) public dealership;
  event Trust(address dealer);
  event Distrust(address dealer);

  modifier onlyDealers() {
    require(dealership[msg.sender]);
    _;
  }

  function trust(address newDealer) onlyOwner {
    require(newDealer != address(0));
    require(!dealership[newDealer]);
    dealership[newDealer] = true;
    Trust(newDealer);
  }

  function distrust(address dealer) onlyOwner {
    require(dealership[dealer]);
    dealership[dealer] = false;
    Distrust(dealer);
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}




 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
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

}


contract DistributionToken is StandardToken, Distributable {
  event Mint(address indexed dealer, address indexed to, uint256 value);
  event Burn(address indexed dealer, address indexed from, uint256 value);

    
  function mint(address _to, uint256 _value) onlyDealers returns (bool) {
    totalSupply = totalSupply.add(_value);
    balances[_to] = balances[_to].add(_value);
    Mint(msg.sender, _to, _value);
    Transfer(address(0), _to, _value);
    return true;
  }


  function burn(address _from, uint256 _value) onlyDealers returns (bool) {
    totalSupply = totalSupply.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    Burn(msg.sender, _from, _value);
    Transfer(_from, address(0), _value);
    return true;
  }
}


contract EverFountainBeanSale is Ownable, Pausable, Distributable {
  using SafeMath for uint256;
  event Sale(address indexed customer, uint256 value, uint256 amount, uint256 consume, string order, uint256 reward);
  struct FlexibleReward {
    uint256 percentage;
    uint256 limit;
  }

  uint256 public totalSales;
  uint256 public totalReward;
  uint256 public totalConsume;
  FlexibleReward[] public flexibleRewardLevel;
  uint256 flexibleRewardIndex = 0;

   
  address public wallet;

   
  uint256 public rate;

  uint256 public weiRaised;

  DistributionToken public token;

  function EverFountainBeanSale(DistributionToken _token, uint256 _rate, address _wallet){
    require(_token != address(0));
    require(_rate > 0);
    require(_wallet != address(0));
    token = _token;
    wallet = _wallet;
    rate = _rate;

    flexibleRewardLevel.push(FlexibleReward({ limit:1000000, percentage:15}));
    flexibleRewardLevel.push(FlexibleReward({ limit:3000000, percentage:13}));
    flexibleRewardLevel.push(FlexibleReward({ limit:6000000, percentage:11}));
    flexibleRewardLevel.push(FlexibleReward({ limit:10000000, percentage:9}));
    flexibleRewardLevel.push(FlexibleReward({ limit:15000000, percentage:7}));
    flexibleRewardLevel.push(FlexibleReward({ limit:21000000, percentage:5}));
    flexibleRewardLevel.push(FlexibleReward({ limit:0, percentage:0}));
    trust(msg.sender);
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return token.balanceOf(_owner);
  }

  function calcFlexibleReward(uint256 amount) constant returns (uint256 reward){
    FlexibleReward memory level = flexibleRewardLevel[flexibleRewardIndex];
    if (level.limit == 0) {
      return 0;
    }
    FlexibleReward memory nextLevel = flexibleRewardLevel[flexibleRewardIndex + 1];
    uint256 futureTotalSales = totalSales.add(amount);
    uint256 benefit;
    if (nextLevel.limit == 0) {
      if (level.limit >= futureTotalSales) {
        return amount.mul(level.percentage).div(100);
      }
      benefit = level.limit.sub(totalSales);
      return benefit.mul(level.percentage).div(100);
    }

    require(nextLevel.limit > futureTotalSales);

    if (level.limit >= futureTotalSales) {
      return amount.mul(level.percentage).div(100);
    }

    benefit = level.limit.sub(totalSales);
    uint256 nextBenefit = amount.sub(benefit);
    return benefit.mul(level.percentage).div(100).add(nextBenefit.mul(nextLevel.percentage).div(100));

  }

  function calcFixedReward(uint256 amount) constant returns (uint256 reward){
    uint256 less6000Reward = 0;
    uint256 less24000Percentage = 5;
    uint256 mostPercentage = 15;

    if (amount < 6000) {
      return less6000Reward;
    }

    if (amount < 24000) {
      return amount.mul(less24000Percentage).div(100);
    }

    return amount.mul(mostPercentage).div(100);
  }

  function calcReward(uint256 amount) constant returns (uint256 reward){
    return calcFixedReward(amount).add(calcFlexibleReward(amount));
  }

  function flexibleReward() constant returns (uint256 percentage, uint limit){
    FlexibleReward memory level = flexibleRewardLevel[flexibleRewardIndex];
    return (level.percentage, level.limit);
  }

  function nextFlexibleReward() constant returns (uint256 percentage, uint limit){
    FlexibleReward memory nextLevel = flexibleRewardLevel[flexibleRewardIndex+1];
    return (nextLevel.percentage, nextLevel.limit);
  }

  function setRate(uint256 _rate) onlyDealers returns(bool) {
    require(_rate > 0);
    rate = _rate;
    return true;
  }

  function destroy() onlyOwner {
    selfdestruct(owner);
  }

  function changeWallet(address _wallet) onlyOwner returns(bool) {
    require(_wallet != address(0));
    wallet = _wallet;
    return true;
  }

  function trade(uint256 amount, uint256 consume, string order) payable whenNotPaused returns(bool){
    require(bytes(order).length > 0);
    uint256 balance;
    if (msg.value == 0) {
       
      require(consume > 0);
      require(amount == 0);
      balance = token.balanceOf(msg.sender);
      require(balance >= consume);
      totalConsume = totalConsume.add(consume);
      token.burn(msg.sender, consume);
      Sale(msg.sender, msg.value, amount, consume, order, 0);
      return true;
    }

    require(amount > 0);
    uint256 sales = msg.value.div(rate);
    require(sales == amount);
    totalSales = totalSales.add(sales);
    uint256 reward = calcReward(sales);
    totalReward = totalReward.add(reward);
    FlexibleReward memory level = flexibleRewardLevel[flexibleRewardIndex];
    if (level.limit>0 && totalSales >= level.limit) {
      flexibleRewardIndex = flexibleRewardIndex + 1;
    }
    uint256 gain = sales.add(reward);

    if (consume == 0) {
       
      token.mint(msg.sender, gain);

      weiRaised = weiRaised.add(msg.value);
      wallet.transfer(msg.value);

      Sale(msg.sender, msg.value, amount, consume, order, reward);
      return true;
    }

    balance = token.balanceOf(msg.sender);
    uint256 futureBalance = balance.add(gain);
    require(futureBalance >= consume);

    totalConsume = totalConsume.add(consume);
    token.mint(msg.sender, gain);
    token.burn(msg.sender, consume);

    weiRaised = weiRaised.add(msg.value);
    wallet.transfer(msg.value);

    Sale(msg.sender, msg.value, amount, consume, order, reward);
    return true;
  }

}