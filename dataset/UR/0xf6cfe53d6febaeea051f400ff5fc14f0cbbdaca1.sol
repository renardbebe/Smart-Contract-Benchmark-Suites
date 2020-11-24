 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    asserts(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    asserts(b <= a);
    return a - b;
  }
  function div(uint a, uint b) internal returns (uint) {
    asserts(b > 0);
    uint c = a / b;
    asserts(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    asserts(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    asserts(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  function asserts(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}


 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) revert();
    _;
  }
}


 
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      revert();
    }
    _;
  }

  modifier onlyInEmergency {
    if (!stopped) {
      revert();
    }
    _;
  }

   
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

   
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }
}

 
contract Token {
   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token {
   
  function transfer(address _to, uint256 _value) returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}


contract DigipulseFirstRoundToken is StandardToken {
  using SafeMath for uint;
}

contract DigipulseToken is StandardToken, Pausable {
  using SafeMath for uint;

   
  string public           name                    = "DigiPulse Token";
  string public           symbol                  = "DGPT";
  uint8 public            decimals                = 18;
  string public           version                 = 'v0.0.3';
  address public          owner                   = msg.sender;
  uint freezeTransferForOwnerTime;

   
  address public DGPTokenOldContract = 0x9AcA6aBFe63A5ae0Dc6258cefB65207eC990Aa4D;
  DigipulseFirstRoundToken public coin;


   

   
  bool public             finalizedCrowdfunding   = false;
  uint public constant    MIN_CAP                 = 500   * 1e18;
  uint public constant    MAX_CAP                 = 41850 * 1e18;  
  uint public             TierAmount              = 8300  * 1e18;
  uint public constant    TOKENS_PER_ETH          = 250;
  uint public constant    MIN_INVEST_ETHER        = 500 finney;
  uint public             startTime;
  uint public             endTime;
  uint public             etherReceived;
  uint public             coinSentToEther;
  bool public             isFinalized;

   
  bool public             isOBR;
  uint public             raisedOBR;
  uint public             MAX_OBR_CAP             = 1600  * 1e18;
  uint public             OBR_Duration;

   
  enum TierState{Completed, Tier01, Tier02, Tier03, Tier04, Tier05, Overspend, Failure, OBR}

   
  modifier minCapNotReached() {
    require (now < endTime && etherReceived <= MIN_CAP);
    _;
  }

   
  mapping(address => Backer) public backers;
  struct Backer {
    uint weiReceived;
    uint coinSent;
  }

   
  event LogReceivedETH(address addr, uint value);
  event LogCoinsEmited(address indexed from, uint amount);


   
  address public          presaleWallet           = 0x83D0Aa2292efD8475DF241fBA42fe137dA008d79;
  address public          companyWallet           = 0x5C967dE68FC54365872203D49B51cDc79a61Ca85;
  address public          bountyWallet            = 0x49fe3E535906d10e55E2e4AD47ff6cB092Abc692;

   
  address public          teamWallet_1            = 0x91D9B09a4157e02783D5D19f7DfC66a759bDc1E4;
  address public          teamWallet_2            = 0x56298A4e0f60Ab4A323EDB0b285A9421F8e6E276;
  address public          teamWallet_3            = 0x09e9e24b3e6bA1E714FB86B04602a7Aa62D587FD;
  address public          teamWallet_4            = 0x2F4283D0362A3AaEe359aC55F2aC7a4615f97c46;



  mapping(address => uint256) public payments;
  uint256 public totalPayments;


  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }


  function withdrawPayments() onlyOwner {
     
    require (isFinalized);
    require (etherReceived != 0);

    owner.transfer(this.balance);
  }


   
  function DigipulseToken() {
    coin = DigipulseFirstRoundToken(DGPTokenOldContract);
    isOBR = true;
    isFinalized = false;
    start();

     
    balances[presaleWallet]         = 600000 * 1e18;                 
    Transfer(0x0, presaleWallet, 600000 * 1e18);

    balances[teamWallet_1]          = 20483871 * 1e16;               
    Transfer(0x0, teamWallet_1, 20483871 * 1e16);

    balances[teamWallet_2]          = 901290324 * 1e15;              
    Transfer(0x0, teamWallet_2, 901290324 * 1e15);

    balances[teamWallet_3]          = 901290324 * 1e15;              
    Transfer(0x0, teamWallet_3, 901290324 * 1e15);

    balances[teamWallet_4]          = 40967724 * 1e15;               
    Transfer(0x0, teamWallet_4, 40967724 * 1e15);

    balances[companyWallet]          = 512096775 * 1e16;             
    Transfer(0x0, companyWallet, 512096775 * 1e16);

    balances[bountyWallet]          = 61451613 * 1e16;               
    Transfer(0x0, bountyWallet, 61451613 * 1e16);

    balances[this]                  = 12100000 * 1e18;               
    Transfer(0x0, this, 12100000 * 1e18);

    totalSupply = 20483871 * 1e18;
  }


  function start() onlyOwner {
    if (startTime != 0) revert();
    startTime    =  1506610800 ;   
    endTime      =  1509494400 ;   
    OBR_Duration =  startTime + 72 hours;
  }


  function toWei(uint _amount) constant returns (uint256 result){
     
    result = _amount.mul(1e18);
    return result;
  }


  function isOriginalRoundContributor() constant returns (bool _state){
    uint balance = coin.balanceOf(msg.sender);
    if (balance > 0) return true;
  }


  function() payable {
    if (isOBR) {
      buyDigipulseOriginalBackersRound(msg.sender);
    } else {
      buyDigipulseTokens(msg.sender);
    }
  }


  function buyDigipulseOriginalBackersRound(address beneficiary) internal  {
     
    require (isOBR);
    require(msg.value > 0);
    require(msg.value > MIN_INVEST_ETHER);
    require(isOriginalRoundContributor());

    uint ethRaised          = raisedOBR;
    uint userContribution   = msg.value;
    uint shouldBecome       = ethRaised.add(userContribution);
    uint excess             = 0;
    Backer storage backer   = backers[beneficiary];

     
    if (shouldBecome > MAX_OBR_CAP) {
      userContribution = MAX_OBR_CAP - ethRaised;
      excess = msg.value - userContribution;
    }

    uint tierBonus   = getBonusPercentage( userContribution );
    balances[beneficiary] += tierBonus;
    balances[this]      -= tierBonus;
    raisedOBR = raisedOBR.add(userContribution);
    backer.coinSent = backer.coinSent.add(tierBonus);
    backer.weiReceived = backer.weiReceived.add(userContribution);

    if (raisedOBR >= MAX_OBR_CAP) {
      isOBR = false;
    }

    Transfer(this, beneficiary, tierBonus);
    LogCoinsEmited(beneficiary, tierBonus);
    LogReceivedETH(beneficiary, userContribution);

     
    if (excess > 0) {
      assert(msg.sender.send(excess));
    }
  }


  function buyDigipulseTokens(address beneficiary) internal {
    require (!finalizedCrowdfunding);
    require (now > OBR_Duration);
    require (msg.value > MIN_INVEST_ETHER);

    uint CurrentTierMax = getCurrentTier().mul(TierAmount);

     
    if (getCurrentTier() == 5) {
      CurrentTierMax = CurrentTierMax.add(350 * 1e18);
    }
    uint userContribution = msg.value;
    uint shouldBecome = etherReceived.add(userContribution);
    uint tierBonus = 0;
    uint excess = 0;
    uint excess_bonus = 0;

    Backer storage backer = backers[beneficiary];

     
    if (shouldBecome > CurrentTierMax) {
      userContribution = CurrentTierMax - etherReceived;
      excess = msg.value - userContribution;
    }

    tierBonus = getBonusPercentage( userContribution );
    balances[beneficiary] += tierBonus;
    balances[this] -= tierBonus;
    etherReceived = etherReceived.add(userContribution);
    backer.coinSent = backer.coinSent.add(tierBonus);
    backer.weiReceived = backer.weiReceived.add(userContribution);
    Transfer(this, beneficiary, tierBonus);

     
    if (excess > 0 && etherReceived < MAX_CAP) {
      excess_bonus = getBonusPercentage( excess );
      balances[beneficiary] += excess_bonus;
      balances[this] -= excess_bonus;
      etherReceived = etherReceived.add(excess);
      backer.coinSent = backer.coinSent.add(excess_bonus);
      backer.weiReceived = backer.weiReceived.add(excess);
      Transfer(this, beneficiary, excess_bonus);
    }

    LogCoinsEmited(beneficiary, tierBonus.add(excess_bonus));
    LogReceivedETH(beneficiary, userContribution.add(excess));

    if(etherReceived >= MAX_CAP) {
      finalizedCrowdfunding = true;
    }

     
    if (excess > 0 && etherReceived == MAX_CAP) {
      assert(msg.sender.send(excess));
    }
  }


  function getCurrentTier() returns (uint Tier) {
    uint ethRaised = etherReceived;

    if (isOBR) return uint(TierState.OBR);

    if (ethRaised >= 0 && ethRaised < toWei(8300)) return uint(TierState.Tier01);
    else if (ethRaised >= toWei(8300) && ethRaised < toWei(16600)) return uint(TierState.Tier02);
    else if (ethRaised >= toWei(16600) && ethRaised < toWei(24900)) return uint(TierState.Tier03);
    else if (ethRaised >= toWei(24900) && ethRaised < toWei(33200)) return uint(TierState.Tier04);
    else if (ethRaised >= toWei(33200) && ethRaised <= toWei(MAX_CAP)) return uint(TierState.Tier05);  
    else if (ethRaised > toWei(MAX_CAP)) {
      finalizedCrowdfunding = true;
      return uint(TierState.Overspend);
    }
    else return uint(TierState.Failure);
  }


  function getBonusPercentage(uint contribution) returns (uint _amount) {
    uint tier = getCurrentTier();

    uint bonus =
        tier == 1 ? 20 :
        tier == 2 ? 15 :
        tier == 3 ? 10 :
        tier == 4 ? 5 :
        tier == 5 ? 0 :
        tier == 8 ? 50 :
                    0;

    return contribution.mul(TOKENS_PER_ETH).mul(bonus + 100).div(100);
  }


  function refund(uint _value) minCapNotReached public {

    if (_value != backers[msg.sender].coinSent) revert();  

    uint ETHToSend = backers[msg.sender].weiReceived;
    backers[msg.sender].weiReceived=0;

    if (ETHToSend > 0) {
      asyncSend(msg.sender, ETHToSend);  
    }
  }


  function finalize() onlyOwner public {
    require (now >= endTime);
    require (etherReceived >= MIN_CAP);

    finalizedCrowdfunding = true;
    isFinalized = true;
    freezeTransferForOwnerTime = now + 182 days;
  }


  function transfer(address _to, uint256 _value) returns (bool success) {
    require(isFinalized);

    if (msg.sender == owner) {
      require(now > freezeTransferForOwnerTime);
    }

    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(isFinalized);

    if (msg.sender == owner) {
      require(now > freezeTransferForOwnerTime);
    }

    return super.transferFrom(_from, _to, _value);
  }
}