 

pragma solidity ^0.4.18;

 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

 

 
contract Lockable is Ownable {
  event Lock();
  event Unlock();

  bool public locked = false;

   
  modifier whenNotLocked() {
    require(!locked);
    _;
  }

   
  modifier whenLocked() {
    require(locked);
    _;
  }

   
  function lock() onlyOwner whenNotLocked public {
    locked = true;
    Lock();
  }

   
  function unlock() onlyOwner whenLocked public {
    locked = false;
    Unlock();
  }
}

 

contract BaseFixedERC20Token is Lockable {
  using SafeMath for uint;

   
  uint public totalSupply;

  mapping(address => uint) balances;

  mapping(address => mapping (address => uint)) private allowed;

   
  event Transfer(address indexed from, address indexed to, uint value);

   
  event Approval(address indexed owner, address indexed spender, uint value);

   
  function balanceOf(address owner_) public view returns (uint balance) {
    return balances[owner_];
  }

   
  function transfer(address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(value_);
    balances[to_] = balances[to_].add(value_);
    Transfer(msg.sender, to_, value_);
    return true;
  }

   
  function transferFrom(address from_, address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
    balances[from_] = balances[from_].sub(value_);
    balances[to_] = balances[to_].add(value_);
    allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
    Transfer(from_, to_, value_);
    return true;
  }

   
  function approve(address spender_, uint value_) whenNotLocked public returns (bool) {
    if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
      revert();
    }
    allowed[msg.sender][spender_] = value_;
    Approval(msg.sender, spender_, value_);
    return true;
  }

   
  function allowance(address owner_, address spender_) view public returns (uint) {
    return allowed[owner_][spender_];
  }
}

 

 
contract BaseICOToken is BaseFixedERC20Token {

   
  uint public availableSupply;

   
  address public ico;

   
  event ICOTokensInvested(address indexed to, uint amount);

   
  event ICOChanged(address indexed icoContract);

   
  function BaseICOToken(uint totalSupply_) public {
    locked = true;  
    totalSupply = totalSupply_;
    availableSupply = totalSupply_;
  }

   
  function changeICO(address ico_) onlyOwner public {
    ico = ico_;
    ICOChanged(ico);
  }

   
   
  function isValidICOInvestment(address to_, uint amount_) internal view returns(bool) {
    return msg.sender == ico && to_ != address(0) && amount_ <= availableSupply;
  }

   
  function icoInvestment(address to_, uint amount_) public returns (uint) {
    require(isValidICOInvestment(to_, amount_));
    availableSupply -= amount_;  
    balances[to_] = balances[to_].add(amount_);
    ICOTokensInvested(to_, amount_);
    return amount_;
  }
}

 

 
contract BaseICO is Ownable {

   
  enum State {
     
    Inactive,
     
     
    Active,
     
     
     
    Suspended,
     
    Terminated,
     
     
    NotCompleted,
     
     
    Completed
  }

   
  BaseICOToken public token;

   
  State public state;

   
  uint public startAt;

   
  uint public endAt;

   
  uint public lowCapWei;  

   
   
  uint public hardCapWei;

   
  uint public lowCapTxWei;  

   
  uint public hardCapTxWei;  

   
  uint public collectedWei;

   
  address public teamWallet;

   
  bool public whitelistEnabled = true;

   
  mapping (address => bool) public whitelist;

   
  event ICOStarted(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
  event ICOResumed(uint indexed endAt, uint lowCapWei, uint hardCapWei, uint lowCapTxWei, uint hardCapTxWei);
  event ICOSuspended();
  event ICOTerminated();
  event ICONotCompleted();
  event ICOCompleted(uint collectedWei);
  event ICOInvestment(address indexed from, uint investedWei, uint tokens, uint8 bonusPct);
  event ICOWhitelisted(address indexed addr);
  event ICOBlacklisted(address indexed addr);

  modifier isSuspended() {
    require(state == State.Suspended);
    _;
  }

  modifier isActive() {
    require(state == State.Active);
    _;
  }

   
  function whitelist(address address_) external onlyOwner {
    whitelist[address_] = true;
    ICOWhitelisted(address_);
  }

   
  function blacklist(address address_) external onlyOwner {
    delete whitelist[address_];
    ICOBlacklisted(address_);
  }

   
  function whitelisted(address address_) public view returns (bool) {
    if (whitelistEnabled) {
      return whitelist[address_];
    } else {
      return true;
    }
  }

   
  function enableWhitelist() public onlyOwner {
    whitelistEnabled = true;
  }

   
  function disableWhitelist() public onlyOwner {
    whitelistEnabled = false;
  }

   
  function start(uint endAt_) onlyOwner public {
    require(endAt_ > block.timestamp && state == State.Inactive);
    endAt = endAt_;
    startAt = block.timestamp;
    state = State.Active;
    ICOStarted(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
  }

   
  function suspend() onlyOwner isActive public {
    state = State.Suspended;
    ICOSuspended();
  }

   
  function terminate() onlyOwner public {
    require(state != State.Terminated &&
            state != State.NotCompleted &&
            state != State.Completed);
    state = State.Terminated;
    ICOTerminated();
  }

   
  function tune(uint endAt_,
                uint lowCapWei_,
                uint hardCapWei_,
                uint lowCapTxWei_,
                uint hardCapTxWei_) onlyOwner isSuspended public {
    if (endAt_ > block.timestamp) {
      endAt = endAt_;
    }
    if (lowCapWei_ > 0) {
      lowCapWei = lowCapWei_;
    }
    if (hardCapWei_ > 0) {
      hardCapWei = hardCapWei_;
    }
    if (lowCapTxWei_ > 0) {
      lowCapTxWei = lowCapTxWei_;
    }
    if (hardCapTxWei_ > 0) {
      hardCapTxWei = hardCapTxWei_;
    }
    require(lowCapWei <= hardCapWei && lowCapTxWei <= hardCapTxWei);
    touch();
  }

   
  function resume() onlyOwner isSuspended public {
    state = State.Active;
    ICOResumed(endAt, lowCapWei, hardCapWei, lowCapTxWei, hardCapTxWei);
    touch();
  }

   
    
    
    
    
    
  function forwardFunds() internal {
    teamWallet.transfer(msg.value);
  }

   
  function touch() public;

   
  function buyTokens() public payable;
}

 

 

 
 
contract OTCPreICO is BaseICO {
  using SafeMath for uint;

   
  uint internal constant ONE_TOKEN = 1e18;

   
  uint public constant ETH_TOKEN_EXCHANGE_RATIO = 5000;

   
  function OTCPreICO(address icoToken_,
                     address teamWallet_,
                     uint lowCapWei_,
                     uint hardCapWei_,
                     uint lowCapTxWei_,
                     uint hardCapTxWei_) public {
    require(icoToken_ != address(0) && teamWallet_ != address(0));
    token = BaseICOToken(icoToken_); 
    teamWallet = teamWallet_;
    state = State.Inactive;
    lowCapWei = lowCapWei_;
    hardCapWei = hardCapWei_;
    lowCapTxWei = lowCapTxWei_;
    hardCapTxWei = hardCapTxWei_;
  }

   
  function touch() public {
    if (state != State.Active && state != State.Suspended) {
      return;
    }
    if (collectedWei >= hardCapWei) {
      state = State.Completed;
      endAt = block.timestamp;
      ICOCompleted(collectedWei);
    } else if (block.timestamp >= endAt) {
      if (collectedWei < lowCapWei) {
        state = State.NotCompleted;
        ICONotCompleted();
      } else {
        state = State.Completed;
        ICOCompleted(collectedWei);
      }
    }
  }

  function buyTokens() public payable {
    require(state == State.Active &&
            block.timestamp <= endAt &&
            msg.value >= lowCapTxWei &&
            msg.value <= hardCapTxWei &&
            collectedWei + msg.value <= hardCapWei &&
            whitelisted(msg.sender) );
    uint amountWei = msg.value;
    uint8 bonus = (block.timestamp - startAt >= 1 weeks) ? 10 : 20;
    uint iwei = bonus > 0 ? amountWei.mul(100 + bonus).div(100) : amountWei;
    uint itokens = iwei * ETH_TOKEN_EXCHANGE_RATIO;
    token.icoInvestment(msg.sender, itokens);  
    collectedWei = collectedWei.add(amountWei);
    ICOInvestment(msg.sender, amountWei, itokens, bonus);
    forwardFunds();
    touch();
  }

   
  function() external payable {
    buyTokens();
  }
}