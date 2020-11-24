 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Constants {
    uint public constant RESELLING_LOCK_UP_PERIOD = 210 days;
    uint public constant RESELLING_UNLOCK_COUNT = 10;
}

contract CardioCoin is ERC20Basic, Ownable, Constants {
    using SafeMath for uint256;

    uint public constant UNLOCK_PERIOD = 30 days;

    string public name = "CardioCoin";
    string public symbol = "CRDC";

    uint8 public decimals = 18;
    uint256 internal totalSupply_ = 50000000000 * (10 ** uint256(decimals));

    mapping (address => uint256) internal reselling;
    uint256 internal resellingAmount = 0;

    struct locker {
        bool isLocker;
        string role;
        uint lockUpPeriod;
        uint unlockCount;
    }

    mapping (address => locker) internal lockerList;

    event AddToLocker(address owner, uint lockUpPeriod, uint unlockCount);

    event ResellingAdded(address seller, uint256 amount);
    event ResellingSubtracted(address seller, uint256 amount);
    event Reselled(address seller, address buyer, uint256 amount);

    event TokenLocked(address owner, uint256 amount);
    event TokenUnlocked(address owner, uint256 amount);

    constructor() public Ownable() {
        balance memory b;

        b.available = totalSupply_;
        balances[msg.sender] = b;
    }

    function addLockedUpTokens(address _owner, uint256 amount, uint lockUpPeriod, uint unlockCount)
    internal {
        balance storage b = balances[_owner];
        lockUp memory l;

        l.amount = amount;
        l.unlockTimestamp = now + lockUpPeriod;
        l.unlockCount = unlockCount;
        b.lockedUp += amount;
        b.lockUpData[b.lockUpCount] = l;
        b.lockUpCount += 1;
        emit TokenLocked(_owner, amount);
    }

    function addResellingAmount(address seller, uint256 amount)
    public
    onlyOwner
    {
        require(seller != address(0));
        require(amount > 0);
        require(balances[seller].available >= amount);

        reselling[seller] = reselling[seller].add(amount);
        balances[seller].available = balances[seller].available.sub(amount);
        resellingAmount = resellingAmount.add(amount);
        emit ResellingAdded(seller, amount);
    }

    function subtractResellingAmount(address seller, uint256 _amount)
    public
    onlyOwner
    {
        uint256 amount = reselling[seller];

        require(seller != address(0));
        require(_amount > 0);
        require(amount >= _amount);

        reselling[seller] = reselling[seller].sub(_amount);
        resellingAmount = resellingAmount.sub(_amount);
        balances[seller].available = balances[seller].available.add(_amount);
        emit ResellingSubtracted(seller, _amount);
    }

    function cancelReselling(address seller)
    public
    onlyOwner {
        uint256 amount = reselling[seller];

        require(seller != address(0));
        require(amount > 0);

        subtractResellingAmount(seller, amount);
    }

    function resell(address seller, address buyer, uint256 amount)
    public
    onlyOwner
    returns (bool)
    {
        require(seller != address(0));
        require(buyer != address(0));
        require(amount > 0);
        require(reselling[seller] >= amount);
        require(balances[owner].available >= amount);

        reselling[seller] = reselling[seller].sub(amount);
        resellingAmount = resellingAmount.sub(amount);
        addLockedUpTokens(buyer, amount, RESELLING_LOCK_UP_PERIOD, RESELLING_UNLOCK_COUNT);
        emit Reselled(seller, buyer, amount);

        return true;
    }

    struct lockUp {
        uint256 amount;
        uint unlockTimestamp;
        uint unlockedCount;
        uint unlockCount;
    }

    struct balance {
        uint256 available;
        uint256 lockedUp;
        mapping (uint => lockUp) lockUpData;
        uint lockUpCount;
        uint unlockIndex;
    }

    mapping(address => balance) internal balances;

    function unlockBalance(address _owner) internal {
        balance storage b = balances[_owner];

        if (b.lockUpCount > 0 && b.unlockIndex < b.lockUpCount) {
            for (uint i = b.unlockIndex; i < b.lockUpCount; i++) {
                lockUp storage l = b.lockUpData[i];

                if (l.unlockTimestamp <= now) {
                    uint count = calculateUnlockCount(l.unlockTimestamp, l.unlockedCount, l.unlockCount);
                    uint256 unlockedAmount = l.amount.mul(count).div(l.unlockCount);

                    if (unlockedAmount > b.lockedUp) {
                        unlockedAmount = b.lockedUp;
                        l.unlockedCount = l.unlockCount;
                    } else {
                        b.available = b.available.add(unlockedAmount);
                        b.lockedUp = b.lockedUp.sub(unlockedAmount);
                        l.unlockedCount += count;
                    }
                    emit TokenUnlocked(_owner, unlockedAmount);
                    if (l.unlockedCount == l.unlockCount) {
                        lockUp memory tempA = b.lockUpData[i];
                        lockUp memory tempB = b.lockUpData[b.unlockIndex];

                        b.lockUpData[i] = tempB;
                        b.lockUpData[b.unlockIndex] = tempA;
                        b.unlockIndex += 1;
                    } else {
                        l.unlockTimestamp += UNLOCK_PERIOD * count;
                    }
                }
            }
        }
    }

    function calculateUnlockCount(uint timestamp, uint unlockedCount, uint unlockCount) view internal returns (uint) {
        uint count = 0;
        uint nowFixed = now;

        while (timestamp < nowFixed && unlockedCount + count < unlockCount) {
            count++;
            timestamp += UNLOCK_PERIOD;
        }

        return count;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value)
    public
    returns (bool) {
        unlockBalance(msg.sender);

        locker storage l = lockerList[msg.sender];

        if (l.isLocker) {
            require(_value <= balances[msg.sender].available);
            require(_to != address(0));

            balances[msg.sender].available = balances[msg.sender].available.sub(_value);
            addLockedUpTokens(_to, _value, l.lockUpPeriod, l.unlockCount);
        } else {
            require(_value <= balances[msg.sender].available);
            require(_to != address(0));

            balances[msg.sender].available = balances[msg.sender].available.sub(_value);
            balances[_to].available = balances[_to].available.add(_value);
        }
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner].available.add(balances[_owner].lockedUp);
    }

    function lockedUpBalanceOf(address _owner) public view returns (uint256) {
        balance storage b = balances[_owner];
        uint256 lockedUpBalance = b.lockedUp;

        if (b.lockUpCount > 0 && b.unlockIndex < b.lockUpCount) {
            for (uint i = b.unlockIndex; i < b.lockUpCount; i++) {
                lockUp storage l = b.lockUpData[i];

                if (l.unlockTimestamp <= now) {
                    uint count = calculateUnlockCount(l.unlockTimestamp, l.unlockedCount, l.unlockCount);
                    uint256 unlockedAmount = l.amount.mul(count).div(l.unlockCount);

                    if (unlockedAmount > lockedUpBalance) {
                        lockedUpBalance = 0;
                        break;
                    } else {
                        lockedUpBalance = lockedUpBalance.sub(unlockedAmount);
                    }
                }
            }
        }

        return lockedUpBalance;
    }

    function resellingBalanceOf(address _owner) public view returns (uint256) {
        return reselling[_owner];
    }

    function transferWithLockUp(address _to, uint256 _value, uint lockUpPeriod, uint unlockCount)
    public
    onlyOwner
    returns (bool) {
        require(_value <= balances[owner].available);
        require(_to != address(0));

        balances[owner].available = balances[owner].available.sub(_value);
        addLockedUpTokens(_to, _value, lockUpPeriod, unlockCount);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who].available);

        balances[_who].available = balances[_who].available.sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function addAddressToLockerList(address _operator, string role, uint lockUpPeriod, uint unlockCount)
    public
    onlyOwner {
        locker storage existsLocker = lockerList[_operator];

        require(!existsLocker.isLocker);

        locker memory l;

        l.isLocker = true;
        l.role = role;
        l.lockUpPeriod = lockUpPeriod;
        l.unlockCount = unlockCount;
        lockerList[_operator] = l;
        emit AddToLocker(_operator, lockUpPeriod, unlockCount);
    }

    function lockerRole(address _operator) public view returns (string) {
        return lockerList[_operator].role;
    }

    function lockerLockUpPeriod(address _operator) public view returns (uint) {
        return lockerList[_operator].lockUpPeriod;
    }

    function lockerUnlockCount(address _operator) public view returns (uint) {
        return lockerList[_operator].unlockCount;
    }
}