 

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


interface ERC20 {
  function balanceOf(address _owner) external returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
}

interface WhiteList {
   function isPaidUntil (address addr) external view returns (uint);
}


contract PresalePool {

   
   
  using SafeMath for uint;
  
   
   
   
   
  uint8 public contractStage = 1;
  
   
   
  address public owner;
  uint maxContractBalance;
   
  uint contributionCap;
   
  uint public feePct;
   
  address public receiverAddress;
  
   
   
  uint constant public contributionMin = 100000000000000000;
   
  uint constant public maxGasPrice = 50000000000;
   
  WhiteList constant public whitelistContract = WhiteList(0xf6E386FA4794B58350e7B4Cb32B6f86Fb0F357d4);
  bool whitelistIsActive = true;
  
   
   
  uint public nextCapTime;
   
  uint public nextContributionCap;
   
  uint public addressChangeBlock;
   
  uint public finalBalance;
   
  uint[] public ethRefundAmount;
   
  address public activeToken;
  
   
  struct Contributor {
    uint ethRefund;
    uint balance;
    uint cap;
    mapping (address => uint) tokensClaimed;
  }
   
  mapping (address => Contributor) whitelist;
  
   
  struct TokenAllocation {
    ERC20 token;
    uint[] pct;
    uint balanceRemaining;
  }
   
  mapping (address => TokenAllocation) distributionMap;
  
  
   
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
  event ReceiverAddressSet ( address _addr);
  event PoolSubmitted (address receiver, uint amount);
  event WithdrawalsOpen (address tokenAddr);
  event TokensWithdrawn (address receiver, address token, uint amount);
  event EthRefundReceived (address sender, uint amount);
  event EthRefunded (address receiver, uint amount);
  event ERC223Received (address token, uint value);
   
   
   
  function _toPct (uint numerator, uint denominator ) internal pure returns (uint) {
    return numerator.mul(10 ** 20) / denominator;
  }
  
   
  function _applyPct (uint numerator, uint pct) internal pure returns (uint) {
    return numerator.mul(pct) / (10 ** 20);
  }
  
   
   
  function PresalePool (address receiverAddr, uint contractCap, uint cap, uint fee) public {
    require (fee < 100);
    require (contractCap >= cap);
    owner = msg.sender;
    receiverAddress = receiverAddr;
    maxContractBalance = contractCap;
    contributionCap = cap;
    feePct = _toPct(fee,100);
  }
  
   
   
   
  function () payable public {
    if (contractStage == 1) {
      _ethDeposit();
    } else _ethRefund();
  }
  
   
  function _ethDeposit () internal {
    assert (contractStage == 1);
    require (!whitelistIsActive || whitelistContract.isPaidUntil(msg.sender) > now);
    require (tx.gasprice <= maxGasPrice);
    require (this.balance <= maxContractBalance);
    var c = whitelist[msg.sender];
    uint newBalance = c.balance.add(msg.value);
    require (newBalance >= contributionMin);
    if (nextCapTime > 0 && nextCapTime < now) {
      contributionCap = nextContributionCap;
      nextCapTime = 0;
    }
    if (c.cap > 0) require (newBalance <= c.cap);
    else require (newBalance <= contributionCap);
    c.balance = newBalance;
    ContributorBalanceChanged(msg.sender, newBalance);
  }
  
   
  function _ethRefund () internal {
    assert (contractStage == 2);
    require (msg.sender == owner || msg.sender == receiverAddress);
    require (msg.value >= contributionMin);
    ethRefundAmount.push(msg.value);
    EthRefundReceived(msg.sender, msg.value);
  }
  
   
   
   
   
   
  function withdraw (address tokenAddr) public {
    var c = whitelist[msg.sender];
    require (c.balance > 0);
    if (contractStage == 1) {
      uint amountToTransfer = c.balance;
      c.balance = 0;
      msg.sender.transfer(amountToTransfer);
      ContributorBalanceChanged(msg.sender, 0);
    } else {
      _withdraw(msg.sender,tokenAddr);
    }  
  }
  
   
  function withdrawFor (address contributor, address tokenAddr) public onlyOwner {
    require (contractStage == 2);
    require (whitelist[contributor].balance > 0);
    _withdraw(contributor,tokenAddr);
  }
  
   
   
  function _withdraw (address receiver, address tokenAddr) internal {
    assert (contractStage == 2);
    var c = whitelist[receiver];
    if (tokenAddr == 0x00) {
      tokenAddr = activeToken;
    }
    var d = distributionMap[tokenAddr];
    require ( (ethRefundAmount.length > c.ethRefund) || d.pct.length > c.tokensClaimed[tokenAddr] );
    if (ethRefundAmount.length > c.ethRefund) {
      uint pct = _toPct(c.balance,finalBalance);
      uint ethAmount = 0;
      for (uint i=c.ethRefund; i<ethRefundAmount.length; i++) {
        ethAmount = ethAmount.add(_applyPct(ethRefundAmount[i],pct));
      }
      c.ethRefund = ethRefundAmount.length;
      if (ethAmount > 0) {
        receiver.transfer(ethAmount);
        EthRefunded(receiver,ethAmount);
      }
    }
    if (d.pct.length > c.tokensClaimed[tokenAddr]) {
      uint tokenAmount = 0;
      for (i=c.tokensClaimed[tokenAddr]; i<d.pct.length; i++) {
        tokenAmount = tokenAmount.add(_applyPct(c.balance,d.pct[i]));
      }
      c.tokensClaimed[tokenAddr] = d.pct.length;
      if (tokenAmount > 0) {
        require(d.token.transfer(receiver,tokenAmount));
        d.balanceRemaining = d.balanceRemaining.sub(tokenAmount);
        TokensWithdrawn(receiver,tokenAddr,tokenAmount);
      }  
    }
    
  }
  
  
   
   
  function modifyIndividualCap (address addr, uint cap) public onlyOwner {
    require (contractStage == 1);
    require (cap <= maxContractBalance);
    var c = whitelist[addr];
    require (cap >= c.balance);
    c.cap = cap;
  }
  
   
  function modifyCap (uint cap) public onlyOwner {
    require (contractStage == 1);
    require (contributionCap <= cap && maxContractBalance >= cap);
    contributionCap = cap;
    nextCapTime = 0;
  }
  
   
  function modifyNextCap (uint time, uint cap) public onlyOwner {
    require (contractStage == 1);
    require (contributionCap <= cap && maxContractBalance >= cap);
    require (time > now);
    nextCapTime = time;
    nextContributionCap = cap;
  }
  
   
  function modifyMaxContractBalance (uint amount) public onlyOwner {
    require (contractStage == 1);
    require (amount >= contributionMin);
    require (amount >= this.balance);
    maxContractBalance = amount;
    if (amount < contributionCap) contributionCap = amount;
  }
  
  function toggleWhitelist (bool active) public onlyOwner {
    whitelistIsActive = active;
  }
  
   
  function checkPoolBalance () view public returns (uint poolCap, uint balance, uint remaining) {
    if (contractStage == 1) {
      remaining = maxContractBalance.sub(this.balance);
    } else {
      remaining = 0;
    }
    return (maxContractBalance,this.balance,remaining);
  }
  
   
  function checkContributorBalance (address addr) view public returns (uint balance, uint cap, uint remaining) {
    var c = whitelist[addr];
    if (contractStage == 2) return (c.balance,0,0);
    if (whitelistIsActive && whitelistContract.isPaidUntil(addr) < now) return (c.balance,0,0);
    if (c.cap > 0) cap = c.cap;
    else cap = contributionCap;
    if (cap.sub(c.balance) > maxContractBalance.sub(this.balance)) return (c.balance, cap, maxContractBalance.sub(this.balance));
    return (c.balance, cap, cap.sub(c.balance));
  }
  
   
  function checkAvailableTokens (address addr, address tokenAddr) view public returns (uint tokenAmount) {
    var c = whitelist[addr];
    var d = distributionMap[tokenAddr];
    for (uint i = c.tokensClaimed[tokenAddr]; i < d.pct.length; i++) {
      tokenAmount = tokenAmount.add(_applyPct(c.balance, d.pct[i]));
    }
    return tokenAmount;
  }
   
   
   
   
   
   
  function setReceiverAddress (address addr) public onlyOwner {
    require (contractStage == 1);
    receiverAddress = addr;
    addressChangeBlock = block.number;
    ReceiverAddressSet(addr);
  }

   
   
   
   
  function submitPool (uint amountInWei) public onlyOwner noReentrancy {
    require (contractStage == 1);
    require (receiverAddress != 0x00);
    require (block.number >= addressChangeBlock.add(6000));
    if (amountInWei == 0) amountInWei = this.balance;
    require (contributionMin <= amountInWei && amountInWei <= this.balance);
    finalBalance = this.balance;
    require (receiverAddress.call.value(amountInWei).gas(msg.gas.sub(5000))());
    if (this.balance > 0) ethRefundAmount.push(this.balance);
    contractStage = 2;
    PoolSubmitted(receiverAddress, amountInWei);
  }
  
   
   
   
   
  function enableTokenWithdrawals (address tokenAddr, bool notDefault) public onlyOwner noReentrancy {
    require (contractStage == 2);
    if (notDefault) {
      require (activeToken != 0x00);
    } else {
      activeToken = tokenAddr;
    }
    var d = distributionMap[tokenAddr];    
    if (d.pct.length==0) d.token = ERC20(tokenAddr);
    uint amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    require (amount > 0);
    if (feePct > 0) {
      require (d.token.transfer(owner,_applyPct(amount,feePct)));
    }
    amount = d.token.balanceOf(this).sub(d.balanceRemaining);
    d.balanceRemaining = d.token.balanceOf(this);
    d.pct.push(_toPct(amount,finalBalance));
  }
  
   
  function tokenFallback (address from, uint value, bytes data) public {
    ERC223Received (from, value);
  }
  
}