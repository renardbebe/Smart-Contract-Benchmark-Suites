 

pragma solidity ^0.4.18;

  
contract SafeMath {
  function safeMul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);  
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

  
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

  
contract SilentNotaryTokenSale is Ownable, SafeMath {

    
    
    
    
    
    
  enum Status {Unknown, Preparing, Selling, ProlongedSelling, TokenShortage, Finished}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount);

   
  event Withdraw(uint tokenAmount);

   
  event TokenPriceChanged(uint newTokenPrice);

   
  ERC20 public token;

   
  address public ethMultisigWallet;

   
  address public tokenMultisigWallet;

   
  uint public startTime;

   
  uint public duration;

   
  uint public prolongedDuration;

   
  uint public tokenPrice;

   
  uint public minInvestment;

   
  address[] public allowedSenders;

   
  uint public tokensSoldAmount = 0;

   
  uint public weiRaisedAmount = 0;

   
  uint public investorCount = 0;

   
  bool public prolongationPermitted;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  uint public tokenValueMultiplier;

   
  bool public stopped;

   
   
   
   
   
   
   
   
   
   
  function SilentNotaryTokenSale(address _token, address _ethMultisigWallet, address _tokenMultisigWallet,
            uint _startTime, uint _duration, uint _prolongedDuration, uint _tokenPrice, uint _minInvestment, address[] _allowedSenders) public {
    require(_token != 0);
    require(_ethMultisigWallet != 0);
    require(_tokenMultisigWallet != 0);
    require(_duration > 0);
    require(_tokenPrice > 0);
    require(_minInvestment > 0);

    token = ERC20(_token);
    ethMultisigWallet = _ethMultisigWallet;
    tokenMultisigWallet = _tokenMultisigWallet;
    startTime = _startTime;
    duration = _duration;
    prolongedDuration = _prolongedDuration;
    tokenPrice = _tokenPrice;
    minInvestment = _minInvestment;
    allowedSenders = _allowedSenders;
    tokenValueMultiplier = 10 ** token.decimals();
  }

   
  function() public payable {
    require(!stopped);
    require(getCurrentStatus() == Status.Selling || getCurrentStatus() == Status.ProlongedSelling);
    require(msg.value >= minInvestment);
    address receiver = msg.sender;

     
    var senderAllowed = false;
    if (allowedSenders.length > 0) {
      for (uint i = 0; i < allowedSenders.length; i++)
        if (allowedSenders[i] == receiver){
          senderAllowed = true;
          break;
        }
    }
    else
      senderAllowed = true;

    assert(senderAllowed);

    uint weiAmount = msg.value;
    uint tokenAmount = safeDiv(safeMul(weiAmount, tokenValueMultiplier), tokenPrice);
    assert(tokenAmount > 0);

    uint changeWei = 0;
    var currentContractTokens = token.balanceOf(address(this));
    if (currentContractTokens < tokenAmount) {
      var changeTokenAmount = safeSub(tokenAmount, currentContractTokens);
      changeWei = safeDiv(safeMul(changeTokenAmount, tokenPrice), tokenValueMultiplier);
      tokenAmount = currentContractTokens;
      weiAmount = safeSub(weiAmount, changeWei);
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }
     
    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);
     
    weiRaisedAmount = safeAdd(weiRaisedAmount, weiAmount);
    tokensSoldAmount = safeAdd(tokensSoldAmount, tokenAmount);

     
    ethMultisigWallet.transfer(weiAmount);

     
    var transferSuccess = token.transfer(receiver, tokenAmount);
    assert(transferSuccess);

     
    if (changeWei > 0) {
      receiver.transfer(changeWei);
    }

     
    Invested(receiver, weiAmount, tokenAmount);
  }

    
    
  function getCurrentStatus() public constant returns (Status) {
    if (startTime > now)
      return Status.Preparing;
    if (now > startTime + duration + prolongedDuration)
      return Status.Finished;
    if (now > startTime + duration && !prolongationPermitted)
      return Status.Finished;
    if (token.balanceOf(address(this)) <= 0)
      return Status.TokenShortage;
    if (now > startTime + duration)
      return Status.ProlongedSelling;
    if (now >= startTime)
        return Status.Selling;
    return Status.Unknown;
  }

   
   
  function withdrawTokens(uint value) public onlyOwner {
    require(value <= token.balanceOf(address(this)));
     
    token.transfer(tokenMultisigWallet, value);
    Withdraw(value);
  }

   
   
  function changeTokenPrice(uint newTokenPrice) public onlyOwner {
    require(newTokenPrice > 0);

    tokenPrice = newTokenPrice;
    TokenPriceChanged(newTokenPrice);
  }

   
  function prolong() public onlyOwner {
    require(!prolongationPermitted && prolongedDuration > 0);
    prolongationPermitted = true;
  }

   
  function stopSale() public onlyOwner {
    stopped = true;
  }

   
  function resumeSale() public onlyOwner {
    require(stopped);
    stopped = false;
  }

   
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}