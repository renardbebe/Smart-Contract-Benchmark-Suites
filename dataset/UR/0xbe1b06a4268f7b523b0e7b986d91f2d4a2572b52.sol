 

pragma solidity ^0.4.19;


 
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


contract ERC20 {
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
}

contract PresalePool {

   
   
  using SafeMath for uint;
  
   
   
   
   
   
  uint8 public contractStage = 1;
  
   
   
  address public owner;
   
  uint public contributionMin;
   
  uint public contractMax;
   
  uint public feePct;
   
  address public receiverAddress;
  
   
   
  uint public submittedAmount;
   
  uint public refundPct;
   
  uint public contributorCount;
   
  address public activeToken;
  
   
  struct Contributor {
    bool refundedEth;
    uint balance;
    mapping (address => uint) tokensClaimed;
  }
   
  mapping (address => Contributor) contributors;
  
   
  struct TokenAllocation {
    ERC20 token;
    uint pct;
    uint claimRound;
    uint claimCount;
  }
   
  mapping (address => TokenAllocation) distribution;
  
  
   
  modifier onlyOwner () {
    require (msg.sender == owner);
    _;
  }
  
   
  bool locked;
  modifier noReentrancy() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }
  
  event ContributorBalanceChanged (address contributor, uint totalBalance);
  event TokensWithdrawn (address receiver, uint amount);
  event EthRefunded (address receiver, uint amount);
  event ReceiverAddressChanged ( address _addr);
  event WithdrawalsOpen (address tokenAddr);
  event ERC223Received (address token, uint value);
   
   
   
  function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
    return numerator.mul(10 ** 20) / denominator;
  }
  
   
  function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
    return numerator.mul(pct) / (10 ** 20);
  }
  
   
  function PresalePool(address receiver, uint individualMin, uint poolMax, uint fee) public {
    require (fee < 100);
    require (100000000000000000 <= individualMin);
    require (individualMin <= poolMax);
    require (receiver != 0x00);
    owner = msg.sender;
    receiverAddress = receiver;
    contributionMin = individualMin;
    contractMax = poolMax;
    feePct = _toPct(fee,100);
  }
  
   
   
  function () payable public {
    require (contractStage == 1);
    require (this.balance <= contractMax);
    var c = contributors[msg.sender];
    uint newBalance = c.balance.add(msg.value);
    require (newBalance >= contributionMin);
    if (contributors[msg.sender].balance == 0) {
      contributorCount = contributorCount.add(1);
    }
    contributors[msg.sender].balance = newBalance;
    ContributorBalanceChanged(msg.sender, newBalance);
  }
    
   
   
   
   
   
  function withdraw (address tokenAddr) public {
    var c = contributors[msg.sender];
    require (c.balance > 0);
    if (contractStage < 3) {
      uint amountToTransfer = c.balance;
      c.balance = 0;
      msg.sender.transfer(amountToTransfer);
      contributorCount = contributorCount.sub(1);
      ContributorBalanceChanged(msg.sender, 0);
    } else {
      _withdraw(msg.sender,tokenAddr);
    }  
  }
  
   
   
   
  function withdrawFor (address contributor, address tokenAddr) public onlyOwner {
    require (contractStage == 3);
    require (contributors[contributor].balance > 0);
    _withdraw(contributor,tokenAddr);
  }
  
   
   
  function _withdraw (address receiver, address tokenAddr) internal {
    assert (contractStage == 3);
    var c = contributors[receiver];
    if (tokenAddr == 0x00) {
      tokenAddr = activeToken;
    }
    var d = distribution[tokenAddr];
    require ( (refundPct > 0 && !c.refundedEth) || d.claimRound > c.tokensClaimed[tokenAddr] );
    if (refundPct > 0 && !c.refundedEth) {
      uint ethAmount = _applyPct(c.balance,refundPct);
      c.refundedEth = true;
      if (ethAmount == 0) return;
      if (ethAmount+10 > c.balance) {
        ethAmount = c.balance-10;
      }
      c.balance = c.balance.sub(ethAmount+10);
      receiver.transfer(ethAmount);
      EthRefunded(receiver,ethAmount);
    }
    if (d.claimRound > c.tokensClaimed[tokenAddr]) {
      uint amount = _applyPct(c.balance,d.pct);
      c.tokensClaimed[tokenAddr] = d.claimRound;
      d.claimCount = d.claimCount.add(1);
      if (amount > 0) {
        require (d.token.transfer(receiver,amount));
      }
      TokensWithdrawn(receiver,amount);
    }
  }
  
   
   
  function modifyMaxContractBalance (uint amount) public onlyOwner {
    require (contractStage < 3);
    require (amount >= contributionMin);
    require (amount >= this.balance);
    contractMax = amount;
  }
  
   
  function checkPoolBalance () view public returns (uint poolCap, uint balance, uint remaining) {
    return (contractMax,this.balance,contractMax.sub(this.balance));
  }
  
   
  function checkContributorBalance (address addr) view public returns (uint balance) {
    return contributors[addr].balance;
  }
  
   
  function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint amount) {
    var c = contributors[addr];
    var d = distribution[tokenAddr];
    if (d.claimRound == c.tokensClaimed[tokenAddr]) return 0;
    return _applyPct(c.balance,d.pct);
  }
  
   
   
   
  function closeContributions () public onlyOwner {
    require (contractStage == 1);
    contractStage = 2;
  }
  
   
   
  function reopenContributions () public onlyOwner {
    require (contractStage == 2);
    contractStage = 1;
  }
  
   
   
   
   
  function submitPool (uint amountInWei) public onlyOwner noReentrancy {
    require (contractStage < 3);
    require (contributionMin <= amountInWei && amountInWei <= this.balance);
    uint b = this.balance;
    require (receiverAddress.call.value(amountInWei).gas(msg.gas.sub(5000))());
    submittedAmount = b.sub(this.balance);
    refundPct = _toPct(this.balance,b);
    contractStage = 3;
  }
  
   
   
   
   
   
  function enableTokenWithdrawals (address tokenAddr, bool notDefault) public onlyOwner noReentrancy {
    require (contractStage == 3);
    if (notDefault) {
      require (activeToken != 0x00);
    } else {
      activeToken = tokenAddr;
    }
    var d = distribution[tokenAddr];
    require (d.claimRound == 0 || d.claimCount == contributorCount);
    d.token = ERC20(tokenAddr);
    uint amount = d.token.balanceOf(this);
    require (amount > 0);
    if (feePct > 0) {
      require (d.token.transfer(owner,_applyPct(amount,feePct)));
    }
    d.pct = _toPct(d.token.balanceOf(this),submittedAmount);
    d.claimCount = 0;
    d.claimRound = d.claimRound.add(1);
  }
  
   
  function tokenFallback (address from, uint value, bytes data) public {
    ERC223Received (from, value);
  }
  
}