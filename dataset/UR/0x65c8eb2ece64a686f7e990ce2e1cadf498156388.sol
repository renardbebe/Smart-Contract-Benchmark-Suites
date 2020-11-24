 

pragma solidity ^0.4.15;


 
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

pragma solidity ^0.4.15;


 
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

pragma solidity ^0.4.15;




 
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

   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

pragma solidity ^0.4.15;


 
contract Whitelistable is Ownable {
  event AllowEveryone();
  event AllowWhiteList();

   
  bool public everyoneDisabled = true;


   
  modifier whenNotEveryone() {
    require(everyoneDisabled);
    _;
  }

   
  modifier whenEveryone() {
    require(!everyoneDisabled);
    _;
  }

   
  function allowEveryone() onlyOwner whenNotEveryone {
    everyoneDisabled = false;
    AllowEveryone();
  }

   
  function allowWhiteList() onlyOwner whenEveryone {
    everyoneDisabled = true;
    AllowWhiteList();
  }
}

pragma solidity ^0.4.15;


contract FundRequestPublicSeed is Pausable, Whitelistable {
  using SafeMath for uint;

   
  address public wallet;
   
  uint public rate;
   
  uint256 public weiMaxCap;
   
  uint256 public weiRaised;
   
  uint256 public maxPurchaseSize;
  
  mapping(address => uint) public deposits;
  mapping(address => uint) public balances;
  address[] public investors;
  uint public investorCount;
  mapping(address => bool) public allowed;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

  function FundRequestPublicSeed(uint _rate, uint256 _maxCap, address _wallet) {
    require(_rate > 0);
    require(_maxCap > 0);
    require(_wallet != 0x0);

    rate = _rate;
    weiMaxCap = SafeMath.mul(_maxCap, 1 ether);
    wallet = _wallet;
    maxPurchaseSize = 25 ether;
  }
  
   
  function buyTokens(address beneficiary) payable whenNotPaused {
    require(validPurchase());
    require(maxCapNotReached());
    if (everyoneDisabled) {
      require(validBeneficiary(beneficiary));
      require(validPurchaseSize(beneficiary));  
    }
    
    bool existing = deposits[beneficiary] > 0;  
    uint weiAmount = msg.value;
    uint updatedWeiRaised = weiRaised.add(weiAmount);
     
    uint tokens = weiAmount.mul(rate);
    weiRaised = updatedWeiRaised;
    deposits[beneficiary] = deposits[beneficiary].add(msg.value);
    balances[beneficiary] = balances[beneficiary].add(tokens);
    if(!existing) {
      investors.push(beneficiary);
      investorCount++;
    }
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  function validBeneficiary(address beneficiary) internal constant returns (bool) {
    return allowed[beneficiary] == true;
  }
   
  function validPurchase() internal constant returns (bool) {
    return msg.value != 0;
  }
   
  function validPurchaseSize(address beneficiary) internal constant returns (bool) {
    return msg.value.add(deposits[beneficiary]) <= maxPurchaseSize;
  }
  function maxCapNotReached() internal constant returns (bool) {
    return SafeMath.add(weiRaised, msg.value) <= weiMaxCap;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  function depositsOf(address _owner) constant returns (uint deposit) {
    return deposits[_owner];
  }
  function allow(address beneficiary) onlyOwner {
    allowed[beneficiary] = true;
  }
  function updateRate(uint _rate) onlyOwner whenPaused {
    rate = _rate;
  }

  function updateWallet(address _wallet) onlyOwner whenPaused {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function updateMaxCap(uint _maxCap) onlyOwner whenPaused {
    require(_maxCap != 0);
    weiMaxCap = SafeMath.mul(_maxCap, 1 ether);
  }

  function updatePurchaseSize(uint _purchaseSize) onlyOwner whenPaused {
    require(_purchaseSize != 0);
    maxPurchaseSize = _purchaseSize;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }
}