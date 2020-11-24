 

pragma solidity ^0.4.13;

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

contract ReentrancyGuard {
   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract AccessControl {
   
  event ContractUpgrade(address newContract);

  address public owner;

   
  bool public paused = false;

   
  function AccessControl() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
   
  function pause() external onlyOwner whenNotPaused {
    paused = true;
  }

   
   
   
  function unpause() public onlyOwner whenPaused {
     
    paused = false;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract BasicToken is AccessControl, ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract LockableToken is StandardToken, ReentrancyGuard {
  struct LockedBalance {
    address owner;
    uint256 value;
    uint256 releaseTime;
  }

  mapping (uint => LockedBalance) public lockedBalances;
  uint public lockedBalanceCount;

  event TransferLockedToken(address indexed from, address indexed to, uint256 value, uint256 releaseTime);
  event ReleaseLockedBalance(address indexed owner, uint256 value, uint256 releaseTime);

   
  function transferLockedToken(address _to, uint256 _value, uint256 _releaseTime) public whenNotPaused nonReentrant returns (bool) {
    require(_releaseTime > now);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    lockedBalances[lockedBalanceCount] = LockedBalance({owner: _to, value: _value, releaseTime: _releaseTime});
    lockedBalanceCount++;
    emit TransferLockedToken(msg.sender, _to, _value, _releaseTime);
    return true;
  }

   
  function lockedBalanceOf(address _owner) public constant returns (uint256 value) {
    for (uint i = 0; i < lockedBalanceCount; i++) {
      LockedBalance storage lockedBalance = lockedBalances[i];
      if (_owner == lockedBalance.owner) {
        value = value.add(lockedBalance.value);
      }
    }
    return value;
  }

   
  function releaseLockedBalance() public whenNotPaused returns (uint256 releaseAmount) {
    uint index = 0;
    while (index < lockedBalanceCount) {
      if (now >= lockedBalances[index].releaseTime) {
        releaseAmount += lockedBalances[index].value;
        unlockBalanceByIndex(index);
      } else {
        index++;
      }
    }
    return releaseAmount;
  }

  function unlockBalanceByIndex(uint index) internal {
    LockedBalance storage lockedBalance = lockedBalances[index];
    balances[lockedBalance.owner] = balances[lockedBalance.owner].add(lockedBalance.value);
    emit ReleaseLockedBalance(lockedBalance.owner, lockedBalance.value, lockedBalance.releaseTime);
    lockedBalances[index] = lockedBalances[lockedBalanceCount - 1];
    delete lockedBalances[lockedBalanceCount - 1];
    lockedBalanceCount--;
  }
}

contract ReleaseableToken is LockableToken {
  uint256 public createTime;
  uint256 public nextReleaseTime;
  uint256 public nextReleaseAmount;
  uint256 standardDecimals = 10000;
  uint256 public totalSupply;
  uint256 public releasedSupply;

  function ReleaseableToken(uint256 initialSupply, uint256 initReleasedSupply, uint256 firstReleaseAmount) public {
    createTime = now;
    nextReleaseTime = now;
    nextReleaseAmount = firstReleaseAmount;
    totalSupply = standardDecimals.mul(initialSupply);
    releasedSupply = standardDecimals.mul(initReleasedSupply);
    balances[msg.sender] = standardDecimals.mul(initReleasedSupply);
  }

   
  function release() public whenNotPaused returns(uint256 _releaseAmount) {
    require(nextReleaseTime <= now);

    uint256 releaseAmount = 0;
    uint256 remainderAmount = totalSupply.sub(releasedSupply);
    if (remainderAmount > 0) {
      releaseAmount = standardDecimals.mul(nextReleaseAmount);
      if (releaseAmount > remainderAmount)
        releaseAmount = remainderAmount;
      releasedSupply = releasedSupply.add(releaseAmount);
      balances[owner] = balances[owner].add(releaseAmount);
      emit Release(msg.sender, releaseAmount, nextReleaseTime);
      nextReleaseTime = nextReleaseTime.add(26 * 1 weeks);
      nextReleaseAmount = nextReleaseAmount.sub(nextReleaseAmount.div(4));
    }
    return releaseAmount;
  }

  event Release(address receiver, uint256 amount, uint256 releaseTime);
}

contract N2Contract is ReleaseableToken {
  string public name = 'N2Chain';
  string public symbol = 'N2C';
  uint8 public decimals = 4;

   
  address public newContractAddress;

  function N2Contract() public ReleaseableToken(1000000000, 200000000, 200000000) {}

   
   
   
   
   
   
  function setNewAddress(address _v2Address) external onlyOwner whenPaused {
    newContractAddress = _v2Address;
    emit ContractUpgrade(_v2Address);
  }

   
   
   
   
   
  function unpause() public onlyOwner whenPaused {
    require(newContractAddress == address(0));

     
    super.unpause();
  }
}