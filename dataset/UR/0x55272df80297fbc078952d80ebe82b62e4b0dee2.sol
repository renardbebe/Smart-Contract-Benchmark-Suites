 

pragma solidity ^0.4.13;

contract StandardContract {
     
    modifier requires(bool b) {
        require(b);
        _;
    }

     
    modifier requiresOne(bool b1, bool b2) {
        require(b1 || b2);
        _;
    }

    modifier notNull(address a) {
        require(a != 0);
        _;
    }

    modifier notZero(uint256 a) {
        require(a != 0);
        _;
    }
}

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

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

contract HasNoEther is Ownable {

   
  function HasNoEther() payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 
contract SingleTokenLocker is Claimable, ReentrancyGuard, StandardContract, HasNoEther {

  using SafeMath for uint256;

   
  ERC20 public token;

   
  uint256 public nextPromiseId;

   
  mapping(uint256 => TokenPromise) public promises;

   
  uint256 public promisedTokenBalance;

   
  uint256 public lockedTokenBalance;

   
   
   
   
   
   
   
  enum PromiseState { none, pending, confirmed, executed, canceled, failed }

   
  mapping (uint => mapping(uint => bool)) stateTransitionMatrix;

   
  bool initialized;

  struct TokenPromise {
    uint256 promiseId;
    address recipient;
    uint256 amount;
    uint256 lockedUntil;
    PromiseState state;
  }

  event logPromiseCreated(uint256 promiseId, address recipient, uint256 amount, uint256 lockedUntil);
  event logPromiseConfirmed(uint256 promiseId);
  event logPromiseCanceled(uint256 promiseId);
  event logPromiseFulfilled(uint256 promiseId);
  event logPromiseUnfulfillable(uint256 promiseId, address recipient, uint256 amount);

   
  modifier onlyRecipient(uint256 promiseId) {
    require(msg.sender == promises[promiseId].recipient);
    _;
  }

   
  modifier promiseExists(uint promiseId) {
    require(promiseId < nextPromiseId);
    _;
  }

   
  modifier thenAssertState() {
    _;
    uint256 balance = tokenBalance();
    assert(lockedTokenBalance <= promisedTokenBalance);
    assert(promisedTokenBalance <= balance);
  }

   
  function SingleTokenLocker(address tokenAddress) {
    token = ERC20(tokenAddress);

    allowTransition(PromiseState.pending, PromiseState.canceled);
    allowTransition(PromiseState.pending, PromiseState.executed);
    allowTransition(PromiseState.pending, PromiseState.confirmed);
    allowTransition(PromiseState.confirmed, PromiseState.executed);
    allowTransition(PromiseState.executed, PromiseState.failed);
    initialized = true;
  }

   
  function lockup(address recipient, uint256 amount, uint256 lockedUntil)
    onlyOwner
    notNull(recipient)
    notZero(amount)
    nonReentrant
    external
  {
     
     
    ensureTokensAvailable(amount);

     
    TokenPromise storage promise = createPromise(recipient, amount, lockedUntil);

     
    if (recipient == owner) {
      doConfirm(promise);
    }
  }

   
  function cancel(uint256 promiseId)
    promiseExists(promiseId)
    requires(promises[promiseId].state == PromiseState.pending)
    requiresOne(
      msg.sender == owner,
      msg.sender == promises[promiseId].recipient
    )
    nonReentrant
    external
  {
    TokenPromise storage promise = promises[promiseId];
    unlockTokens(promise, PromiseState.canceled);
    logPromiseCanceled(promise.promiseId);
  }

   
   
  function confirm(uint256 promiseId)
    promiseExists(promiseId)
    onlyRecipient(promiseId)
    requires(promises[promiseId].state == PromiseState.pending)
    nonReentrant
    external
  {
    doConfirm(promises[promiseId]);
  }

   
  function collect(uint256 promiseId)
    promiseExists(promiseId)
    onlyRecipient(promiseId)
    requires(block.timestamp >= promises[promiseId].lockedUntil)
    requiresOne(
      promises[promiseId].state == PromiseState.pending,
      promises[promiseId].state == PromiseState.confirmed
    )
    nonReentrant
    external
  {
    TokenPromise storage promise = promises[promiseId];

    unlockTokens(promise, PromiseState.executed);
    if (token.transfer(promise.recipient, promise.amount)) {
      logPromiseFulfilled(promise.promiseId);
    }
    else {
       
       
       
       
       
       
      transition(promise, PromiseState.failed);
      logPromiseUnfulfillable(promiseId, promise.recipient, promise.amount);
    }
  }

   
  function withdrawUncommittedTokens(uint amount)
    onlyOwner
    requires(amount <= uncommittedTokenBalance())
    nonReentrant
    external
  {
    token.transfer(owner, amount);
  }

   
  function withdrawAllUncommittedTokens()
    onlyOwner
    nonReentrant
    external
  {
     
     
    token.transfer(owner, uncommittedTokenBalance());
  }

   
   
   
   
   
   
   
  function salvageTokensFromContract(address tokenAddress, address to, uint amount)
    onlyOwner
    requiresOne(
      tokenAddress != address(token),
      amount <= uncommittedTokenBalance()
    )
    nonReentrant
    external
  {
    ERC20(tokenAddress).transfer(to, amount);
  }

   
  function isConfirmed(uint256 promiseId)
    constant
    returns(bool)
  {
    return promises[promiseId].state == PromiseState.confirmed;
  }

   
  function canCollect(uint256 promiseId)
    constant
    returns(bool)
  {
    return (promises[promiseId].state == PromiseState.confirmed || promises[promiseId].state == PromiseState.pending)
      && block.timestamp >= promises[promiseId].lockedUntil;
  }

   
  function collectableTokenBalance()
    constant
    returns(uint256 collectable)
  {
    collectable = 0;
    for (uint i=0; i<nextPromiseId; i++) {
      if (canCollect(i)) {
        collectable = collectable.add(promises[i].amount);
      }
    }
    return collectable;
  }

   
  function getPromiseCount(address recipient, bool includeCompleted)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<nextPromiseId; i++) {
      if (recipient != 0x0 && recipient != promises[i].recipient)
        continue;

        if (includeCompleted
            || promises[i].state == PromiseState.pending
            || promises[i].state == PromiseState.confirmed)
      count += 1;
    }
  }

   
  function getPromiseIds(uint from, uint to, address recipient, bool includeCompleted)
    public
    constant
    returns (uint[] promiseIds)
  {
    uint[] memory promiseIdsTemp = new uint[](nextPromiseId);
    uint count = 0;
    uint i;
    for (i=0; i<nextPromiseId && count < to; i++) {
      if (recipient != 0x0 && recipient != promises[i].recipient)
        continue;

      if (includeCompleted
        || promises[i].state == PromiseState.pending
        || promises[i].state == PromiseState.confirmed)
      {
        promiseIdsTemp[count] = i;
        count += 1;
      }
    }
    promiseIds = new uint[](to - from);
    for (i=from; i<to; i++)
      promiseIds[i - from] = promiseIdsTemp[i];
  }

   
  function tokenBalance()
    constant
    returns(uint256)
  {
    return token.balanceOf(address(this));
  }

   
  function uncommittedTokenBalance()
    constant
    returns(uint256)
  {
    return tokenBalance() - promisedTokenBalance;
  }

   
  function pendingTokenBalance()
    constant
    returns(uint256)
  {
    return promisedTokenBalance - lockedTokenBalance;
  }

   

   
  function unlockTokens(TokenPromise storage promise, PromiseState newState)
    internal
  {
    promisedTokenBalance = promisedTokenBalance.sub(promise.amount);
    if (promise.state == PromiseState.confirmed) {
      lockedTokenBalance = lockedTokenBalance.sub(promise.amount);
    }
    transition(promise, newState);
  }

   
  function allowTransition(PromiseState from, PromiseState to)
    requires(!initialized)
    internal
  {
    stateTransitionMatrix[uint(from)][uint(to)] = true;
  }

   
  function transition(TokenPromise storage promise, PromiseState newState)
    internal
  {
    assert(stateTransitionMatrix[uint(promise.state)][uint(newState)]);
    promise.state = newState;
  }

   
  function doConfirm(TokenPromise storage promise)
    thenAssertState
    internal
  {
    transition(promise, PromiseState.confirmed);
    lockedTokenBalance = lockedTokenBalance.add(promise.amount);
    logPromiseConfirmed(promise.promiseId);
  }

   
  function createPromise(address recipient, uint256 amount, uint256 lockedUntil)
    requires(amount <= uncommittedTokenBalance())
    thenAssertState
    internal
    returns(TokenPromise storage promise)
  {
    uint256 promiseId = nextPromiseId++;
    promise = promises[promiseId];
    promise.promiseId = promiseId;
    promise.recipient = recipient;
    promise.amount = amount;
    promise.lockedUntil = lockedUntil;
    promise.state = PromiseState.pending;

    promisedTokenBalance = promisedTokenBalance.add(promise.amount);

    logPromiseCreated(promiseId, recipient, amount, lockedUntil);

    return promise;
  }

   
  function ensureTokensAvailable(uint256 amount)
    onlyOwner
    internal
  {
    uint256 uncommittedBalance = uncommittedTokenBalance();
    if (uncommittedBalance < amount) {
      token.transferFrom(owner, this, amount.sub(uncommittedBalance));

       
       
      assert(uncommittedTokenBalance() >= amount);
    }
  }
}