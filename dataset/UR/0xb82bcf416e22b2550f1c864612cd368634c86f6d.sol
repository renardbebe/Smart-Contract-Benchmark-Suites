 

pragma solidity ^0.4.19;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
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

 

contract Crowdsale is Pausable {
  using SafeMath for uint256;

   
   
  ERC20 public token;

   
   
  address public tokenWallet;

   
   
  address public wallet;

   
   
  uint256 public baseRate;

   
  uint256 public weiRaised;

  uint256 public cap;

  uint256 public openingTime;

  uint256 firstTierRate = 20;
  uint256 secondTierRate = 10;
  uint256 thirdTierRate = 5;

  mapping(address => uint256) public balances;

  modifier onlyWhileOpen {
    require(now >= openingTime && weiRaised < cap);
    _;
  }
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _openingTime, uint256 _rate, address _wallet, ERC20 _token, uint256 _cap, address _tokenWallet) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_cap > 0);
    require(_tokenWallet != address(0));

    openingTime = _openingTime;
    baseRate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    tokenWallet = _tokenWallet;
  }

  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function withdrawTokens() public {
    require(capReached());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }

   
  function withdrawTokensFor(address _accountToWithdrawFor) public onlyOwner {
    uint256 amount = balances[_accountToWithdrawFor];
    require(amount > 0);
    balances[_accountToWithdrawFor] = 0;
    _deliverTokens(_accountToWithdrawFor, amount);
  }

   
   
   

   
  function () external whenNotPaused payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    
    _forwardFunds();
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
    require(_beneficiary != address(0));
     
     
    require(_weiAmount > 10000000000000000);
    require(weiRaised.add(_weiAmount) <= cap);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      uint256 bonusRate;
      uint256 realRate;
	  if (weiRaised <= 450 ether) {
		   bonusRate = baseRate.mul(firstTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else if (weiRaised <= 800 ether) {
		   bonusRate = baseRate.mul(secondTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else if (weiRaised <= 3000 ether) {
		   bonusRate = baseRate.mul(thirdTierRate).div(100);
		   realRate = baseRate.add(bonusRate);
		  return _weiAmount.mul(realRate);
	  } else {
		  return _weiAmount.mul(baseRate);
	  }
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}