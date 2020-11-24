 

pragma solidity ^0.4.18;

 

 
 
 
 
contract MigrationTarget {
  function migrateFrom(address _from, uint256 _amount, uint256 _rewards, uint256 _trueBuy, bool _devStatus) public;
}

 

contract Ownable {
  address public owner;

   
  event OwnershipChanged(address indexed oldOwner, address indexed newOwner);

   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }
}

 

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address _owner) view public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) view public returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract StandardToken is ERC20 {
   
  function _transfer(address _from, address _to, uint _value) internal returns (bool success) {
     
    require(_to != address(0));
     
    require(balances[_from] >= _value);
     
    require(balances[_to] + _value > balances[_to]);
     
    uint256 previousBalances = balances[_from] + balances[_to];
     
    balances[_from] -= _value;
     
    balances[_to] += _value;
    emit Transfer(_from, _to, _value);
     
    assert(balances[_from] + balances[_to] == previousBalances);

    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
    return _transfer(msg.sender, _to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);      
    allowed[_from][msg.sender] -= _value;
    return _transfer(_from, _to, _value);
  }

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }

   
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;
}

 

 
contract RoyaltyToken is StandardToken {
  using SafeMath for uint256;
   
  mapping(address => bool) public restrictedAddresses;
  
  event RestrictedStatusChanged(address indexed _address, bool status);

  struct Account {
    uint256 balance;
    uint256 lastRoyaltyPoint;
  }

  mapping(address => Account) public accounts;
  uint256 public totalRoyalty;
  uint256 public unclaimedRoyalty;

   
  function RoyaltysOwing(address account) public view returns (uint256) {
    uint256 newRoyalty = totalRoyalty.sub(accounts[account].lastRoyaltyPoint);
    return balances[account].mul(newRoyalty).div(totalSupply);
  }

   
  function updateAccount(address account) internal {
    uint256 owing = RoyaltysOwing(account);
    accounts[account].lastRoyaltyPoint = totalRoyalty;
    if (owing > 0) {
      unclaimedRoyalty = unclaimedRoyalty.sub(owing);
      accounts[account].balance = accounts[account].balance.add(owing);
    }
  }

  function disburse() public payable {
    require(totalSupply > 0);
    require(msg.value > 0);

    uint256 newRoyalty = msg.value;
    totalRoyalty = totalRoyalty.add(newRoyalty);
    unclaimedRoyalty = unclaimedRoyalty.add(newRoyalty);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
     
    require(restrictedAddresses[msg.sender] == false);
    updateAccount(_to);
    updateAccount(msg.sender);
    return super.transfer(_to, _value);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success) {
    updateAccount(_to);
    updateAccount(_from);
    return super.transferFrom(_from, _to, _value);
  }

  function withdrawRoyalty() public {
    updateAccount(msg.sender);

     
    uint256 RoyaltyAmount = accounts[msg.sender].balance;
    require(RoyaltyAmount > 0);
    accounts[msg.sender].balance = 0;

     
    msg.sender.transfer(RoyaltyAmount);
  }
}

 

contract Q2 is Ownable, RoyaltyToken {
  using SafeMath for uint256;

  string public name = "Q2";
  string public symbol = "Q2";
  uint8 public decimals = 18;

  bool public whitelist = true;

   
  mapping(address => bool) public whitelistedAddresses;

   
  uint256 public creationCap = 15000000 * (10 ** 18);  
  uint256 public reservedFund = 10000000 * (10 ** 18);  

   
  struct Stage {
    uint8 number;
    uint256 exchangeRate;
    uint256 startBlock;
    uint256 endBlock;
    uint256 cap;
  }

   
  event MintTokens(address indexed _to, uint256 _value);
  event StageStarted(uint8 _stage, uint256 _totalSupply, uint256 _balance);
  event StageEnded(uint8 _stage, uint256 _totalSupply, uint256 _balance);
  event WhitelistStatusChanged(address indexed _address, bool status);
  event WhitelistChanged(bool status);

   
  address public ethWallet;
  mapping (uint8 => Stage) stages;

   
  uint8 public currentStage;

  function Q2(address _ethWallet) public {
    ethWallet = _ethWallet;

     
    mintTokens(ethWallet, reservedFund);
  }

  function mintTokens(address to, uint256 value) internal {
    require(value > 0);
    balances[to] = balances[to].add(value);
    totalSupply = totalSupply.add(value);
    require(totalSupply <= creationCap);

     
    emit MintTokens(to, value);
  }

  function () public payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(whitelist==false || whitelistedAddresses[msg.sender] == true);
    require(msg.value > 0);

    Stage memory stage = stages[currentStage];
    require(block.number >= stage.startBlock && block.number <= stage.endBlock);

    uint256 tokens = msg.value * stage.exchangeRate;
    require(totalSupply.add(tokens) <= stage.cap);

    mintTokens(msg.sender, tokens);
  }

  function startStage(
    uint256 _exchangeRate,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock
  ) public onlyOwner {
    require(_exchangeRate > 0 && _cap > 0);
    require(_startBlock > block.number);
    require(_startBlock < _endBlock);

     
    Stage memory currentObj = stages[currentStage];
    if (currentObj.endBlock > 0) {
       
      emit StageEnded(currentStage, totalSupply, address(this).balance);
    }

     
    currentStage = currentStage + 1;

     
    Stage memory s = Stage({
      number: currentStage,
      startBlock: _startBlock,
      endBlock: _endBlock,
      exchangeRate: _exchangeRate,
      cap: _cap + totalSupply
    });
    stages[currentStage] = s;

     
    emit StageStarted(currentStage, totalSupply, address(this).balance);
  }

  function withdraw() public onlyOwner {
    ethWallet.transfer(address(this).balance);
  }

  function getCurrentStage() view public returns (
    uint8 number,
    uint256 exchangeRate,
    uint256 startBlock,
    uint256 endBlock,
    uint256 cap
  ) {
    Stage memory currentObj = stages[currentStage];
    number = currentObj.number;
    exchangeRate = currentObj.exchangeRate;
    startBlock = currentObj.startBlock;
    endBlock = currentObj.endBlock;
    cap = currentObj.cap;
  }

  function changeWhitelistStatus(address _address, bool status) public onlyOwner {
    whitelistedAddresses[_address] = status;
    emit WhitelistStatusChanged(_address, status);
  }

  function changeRestrictedtStatus(address _address, bool status) public onlyOwner {
    restrictedAddresses[_address] = status;
    emit RestrictedStatusChanged(_address, status);
  }
  
  function changeWhitelist(bool status) public onlyOwner {
     whitelist = status;
     emit WhitelistChanged(status);
  }
}

 

interface TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Quarters is Ownable, StandardToken {
   
  string public name = "Quarters";
  string public symbol = "Q";
  uint8 public decimals = 0;  

  uint16 public ethRate = 4000;  
  uint256 public tranche = 40000;  

   
   
  mapping (address => bool) public developers;

  uint256 public outstandingQuarters;
  address public q2;

   
  uint8 public trancheNumerator = 2;
  uint8 public trancheDenominator = 1;

   
  uint32 public mega = 20;
  uint32 public megaRate = 115;
  uint32 public large = 100;
  uint32 public largeRate = 90;
  uint32 public medium = 2000;
  uint32 public mediumRate = 75;
  uint32 public small = 50000;
  uint32 public smallRate = 50;
  uint32 public microRate = 25;

   
  mapping (address => uint256) public rewards;     
  mapping (address => uint256) public trueBuy;     

  uint256 public rewardAmount = 40;

  uint8 public rewardNumerator = 1;
  uint8 public rewardDenominator = 4;

   
  uint256 public reserveETH=0;

   
  event EthRateChanged(uint16 currentRate, uint16 newRate);

   
  event Burn(address indexed from, uint256 value);

  event QuartersOrdered(address indexed sender, uint256 ethValue, uint256 tokens);
  event DeveloperStatusChanged(address indexed developer, bool status);
  event TrancheIncreased(uint256 _tranche, uint256 _etherPool, uint256 _outstandingQuarters);
  event MegaEarnings(address indexed developer, uint256 value, uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool);
  event Withdraw(address indexed developer, uint256 value, uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool);
  event BaseRateChanged(uint256 _baseRate, uint256 _tranche, uint256 _outstandingQuarters, uint256 _etherPool,  uint256 _totalSupply);
  event Reward(address indexed _address, uint256 value, uint256 _outstandingQuarters, uint256 _totalSupply);

   
  modifier onlyActiveDeveloper() {
    require(developers[msg.sender] == true);
    _;
  }

   
  function Quarters(
    address _q2,
    uint256 firstTranche
  ) public {
    q2 = _q2;
    tranche = firstTranche;  
  }

  function setEthRate (uint16 rate) onlyOwner public {
     
    require(rate > 0);
    ethRate = rate;
    emit EthRateChanged(ethRate, rate);
  }

   
  function adjustReward (uint256 reward) onlyOwner public {
    rewardAmount = reward;  
  }

  function adjustWithdrawRate(uint32 mega2, uint32 megaRate2, uint32 large2, uint32 largeRate2, uint32 medium2, uint32 mediumRate2, uint32 small2, uint32 smallRate2, uint32 microRate2) onlyOwner public {
     
     
    if (mega2 > 0 && megaRate2 > 0) {
      mega = mega2;
      megaRate = megaRate2;
    }

    if (large2 > 0 && largeRate2 > 0) {
      large = large2;
      largeRate = largeRate2;
    }

    if (medium2 > 0 && mediumRate2 > 0) {
      medium = medium2;
      mediumRate = mediumRate2;
    }

    if (small2 > 0 && smallRate2 > 0){
      small = small2;
      smallRate = smallRate2;
    }

    if (microRate2 > 0) {
      microRate = microRate2;
    }
  }

   
  function adjustNextTranche (uint8 numerator, uint8 denominator) onlyOwner public {
    require(numerator > 0 && denominator > 0);
    trancheNumerator = numerator;
    trancheDenominator = denominator;
  }

  function adjustTranche(uint256 tranche2) onlyOwner public {
    require(tranche2 > 0);
    tranche = tranche2;
  }

   
  function updatePlayerRewards(address _address) internal {
    require(_address != address(0));

    uint256 _reward = 0;
    if (rewards[_address] == 0) {
      _reward = rewardAmount;
    } else if (rewards[_address] < tranche) {
      _reward = trueBuy[_address] * rewardNumerator / rewardDenominator;
    }

    if (_reward > 0) {
       
      rewards[_address] = tranche;

      balances[_address] += _reward;
      allowed[_address][msg.sender] += _reward;  

      totalSupply += _reward;
      outstandingQuarters += _reward;

      uint256 spentETH = (_reward * (10 ** 18)) / ethRate;
      if (reserveETH >= spentETH) {
          reserveETH -= spentETH;
        } else {
          reserveETH = 0;
        }

       
      _changeTrancheIfNeeded();

      emit Approval(_address, msg.sender, _reward);
      emit Reward(_address, _reward, outstandingQuarters, totalSupply);
    }
  }

   
  function setDeveloperStatus (address _address, bool status) onlyOwner public {
    developers[_address] = status;
    emit DeveloperStatusChanged(_address, status);
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
  public
  returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }

    return false;
  }

   
  function burn(uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value);    
    balances[msg.sender] -= _value;             
    totalSupply -= _value;                      
    outstandingQuarters -= _value;               
    emit Burn(msg.sender, _value);

     
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);
    return true;
  }

   
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balances[_from] >= _value);                 
    require(_value <= allowed[_from][msg.sender]);      
    balances[_from] -= _value;                          
    allowed[_from][msg.sender] -= _value;               
    totalSupply -= _value;                       
    outstandingQuarters -= _value;               
    emit Burn(_from, _value);

     
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);
    return true;
  }

   
  function () payable public {
    _buy(msg.sender);
  }


  function buy() payable public {
    _buy(msg.sender);
  }

  function buyFor(address buyer) payable public {
    uint256 _value =  _buy(buyer);

     
    allowed[buyer][msg.sender] += _value;
    emit Approval(buyer, msg.sender, _value);
  }

  function _changeTrancheIfNeeded() internal {
    if (totalSupply >= tranche) {
       
      tranche = (tranche * trancheNumerator) / trancheDenominator;

       
      emit TrancheIncreased(tranche, address(this).balance, outstandingQuarters);
    }
  }

   
  function _buy(address buyer) internal returns (uint256) {
    require(buyer != address(0));

    uint256 nq = (msg.value * ethRate) / (10 ** 18);
    require(nq != 0);
    if (nq > tranche) {
      nq = tranche;
    }

    totalSupply += nq;
    balances[buyer] += nq;
    trueBuy[buyer] += nq;
    outstandingQuarters += nq;

     
    _changeTrancheIfNeeded();

     
    emit QuartersOrdered(buyer, msg.value, nq);

     
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);

     
    Q2(q2).disburse.value(msg.value * 15 / 100)();

     
    return nq;
  }

   
  function transferAllowance(address _from, address _to, uint256 _value) public returns (bool success) {
    updatePlayerRewards(_from);
    require(_value <= allowed[_from][msg.sender]);      
    allowed[_from][msg.sender] -= _value;

    if (_transfer(_from, _to, _value)) {
       
      allowed[_to][msg.sender] += _value;
      emit Approval(_to, msg.sender, _value);
      return true;
    }

    return false;
  }

  function withdraw(uint256 value) onlyActiveDeveloper public {
    require(balances[msg.sender] >= value);

    uint256 baseRate = getBaseRate();
    require(baseRate > 0);  

    uint256 earnings = value * baseRate;
    uint256 rate = getRate(value);  
    uint256 earningsWithBonus = (rate * earnings) / 100;
    if (earningsWithBonus > address(this).balance) {
      earnings = address(this).balance;
    } else {
      earnings = earningsWithBonus;
    }

    balances[msg.sender] -= value;
    outstandingQuarters -= value;  

    uint256 etherPool = address(this).balance - earnings;
    if (rate == megaRate) {
      emit MegaEarnings(msg.sender, earnings, baseRate, tranche, outstandingQuarters, etherPool);  
    }

     
    emit Withdraw(msg.sender, earnings, baseRate, tranche, outstandingQuarters, etherPool);   

     
    emit BaseRateChanged(getBaseRate(), tranche, outstandingQuarters, address(this).balance, totalSupply);

     
    msg.sender.transfer(earnings);  
}

  function disburse() public payable {
    reserveETH += msg.value;
  }

  function getBaseRate () view public returns (uint256) {
    if (outstandingQuarters > 0) {
      return (address(this).balance - reserveETH) / outstandingQuarters;
    }

    return (address(this).balance - reserveETH);
  }

  function getRate (uint256 value) view public returns (uint32) {
    if (value * mega > tranche) {   
      return megaRate;
    } else if (value * large > tranche) {    
      return largeRate;
    } else if (value * medium > tranche) {   
      return mediumRate;
    } else if (value * small > tranche){   
      return smallRate;
    }

    return microRate;  
  }


   
   
   

   
  address public migrationTarget;
  bool public migrating = false;

   
  event Migrate(address indexed _from, uint256 _value);

   
   
   
  function migrate() public {
    require(migrationTarget != address(0));
    uint256 _amount = balances[msg.sender];
    require(_amount > 0);
    balances[msg.sender] = 0;

    totalSupply = totalSupply - _amount;
    outstandingQuarters = outstandingQuarters - _amount;

    rewards[msg.sender] = 0;
    trueBuy[msg.sender] = 0;
    developers[msg.sender] = false;

    emit Migrate(msg.sender, _amount);
    MigrationTarget(migrationTarget).migrateFrom(msg.sender, _amount, rewards[msg.sender], trueBuy[msg.sender], developers[msg.sender]);
  }

   
   
   
   
  function setMigrationTarget(address _target) onlyOwner public {
    migrationTarget = _target;
  }
}