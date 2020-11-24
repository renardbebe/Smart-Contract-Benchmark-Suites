 

pragma solidity >= 0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

contract Constants {
    uint public constant UNLOCK_COUNT = 7;
}

contract CardioCoin is ERC20, Ownable, Constants {
    using SafeMath for uint256;

    uint public constant RESELLER_UNLOCK_TIME = 1559347200; 
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
        bool isReseller;
    }

    mapping (address => locker) internal lockerList;

    event AddToLocker(address indexed owner, string role, uint lockUpPeriod, uint unlockCount);
    event AddToReseller(address indexed owner);

    event ResellingAdded(address indexed seller, uint256 amount);
    event ResellingSubtracted(address indexed seller, uint256 amount);
    event Reselled(address indexed seller, address indexed buyer, uint256 amount);

    event TokenLocked(address indexed owner, uint256 amount);
    event TokenUnlocked(address indexed owner, uint256 amount);

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

     

    function addAddressToResellerList(address _operator)
    public
    onlyOwner {
        locker storage existsLocker = lockerList[_operator];

        require(!existsLocker.isLocker);

        locker memory l;

        l.isLocker = true;
        l.role = "Reseller";
        l.lockUpPeriod = RESELLER_UNLOCK_TIME;
        l.unlockCount = UNLOCK_COUNT;
        l.isReseller = true;
        lockerList[_operator] = l;
        emit AddToReseller(_operator);
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
        require(balances[owner()].available >= amount);

        reselling[seller] = reselling[seller].sub(amount);
        resellingAmount = resellingAmount.sub(amount);
        addLockedUpTokens(buyer, amount, RESELLER_UNLOCK_TIME - now, UNLOCK_COUNT);
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

    function _transfer(address from, address to, uint256 value) internal {
        locker storage l = lockerList[from];

        if (l.isReseller && RESELLER_UNLOCK_TIME < now) {
            l.isLocker = false;
            l.isReseller = false;

            uint elapsedPeriod = (now - RESELLER_UNLOCK_TIME) / UNLOCK_PERIOD;

            if (elapsedPeriod < UNLOCK_COUNT) {
                balance storage b = balances[from];
                uint256 lockUpAmount = b.available * (UNLOCK_COUNT - elapsedPeriod) / UNLOCK_COUNT;

                b.available = b.available.sub(lockUpAmount);
                addLockedUpTokens(from, lockUpAmount, RESELLER_UNLOCK_TIME + UNLOCK_PERIOD * (elapsedPeriod + 1) - now, UNLOCK_COUNT - elapsedPeriod);
            }
        }
        unlockBalance(from);

        require(value <= balances[from].available);
        require(to != address(0));
        if (l.isLocker) {
            balances[from].available = balances[from].available.sub(value);
            if (l.isReseller) {
                addLockedUpTokens(to, value, RESELLER_UNLOCK_TIME - now, UNLOCK_COUNT);
            } else {
                addLockedUpTokens(to, value, l.lockUpPeriod, l.unlockCount);
            }
        } else {
            balances[from].available = balances[from].available.sub(value);
            balances[to].available = balances[to].available.add(value);
        }
        emit Transfer(from, to, value);
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
        require(_value <= balances[owner()].available);
        require(_to != address(0));

        balances[owner()].available = balances[owner()].available.sub(_value);
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

     

    function addAddressToLockerList(address _operator, string memory role, uint lockUpPeriod, uint unlockCount)
    public
    onlyOwner {
        locker storage existsLocker = lockerList[_operator];

        require(!existsLocker.isLocker);

        locker memory l;

        l.isLocker = true;
        l.role = role;
        l.lockUpPeriod = lockUpPeriod;
        l.unlockCount = unlockCount;
        l.isReseller = false;
        lockerList[_operator] = l;
        emit AddToLocker(_operator, role, lockUpPeriod, unlockCount);
    }

    function lockerInfo(address _operator) public view returns (string memory, uint, uint, bool) {
        locker memory l = lockerList[_operator];

        return (l.role, l.lockUpPeriod, l.unlockCount, l.isReseller);
    }

     

    event RefundRequested(address indexed reuqester, uint256 tokenAmount, uint256 paidAmount);
    event RefundCanceled(address indexed requester);
    event RefundAccepted(address indexed requester, address indexed tokenReceiver, uint256 tokenAmount, uint256 paidAmount);

    struct refundRequest {
        bool active;
        uint256 tokenAmount;
        uint256 paidAmount;
        address buyFrom;
    }

    mapping (address => refundRequest) internal refundRequests;

    function requestRefund(uint256 paidAmount, address buyFrom) public {
        require(!refundRequests[msg.sender].active);

        refundRequest memory r;

        r.active = true;
        r.tokenAmount = balanceOf(msg.sender);
        r.paidAmount = paidAmount;
        r.buyFrom = buyFrom;
        refundRequests[msg.sender] = r;

        emit RefundRequested(msg.sender, r.tokenAmount, r.paidAmount);
    }

    function cancelRefund() public {
        require(refundRequests[msg.sender].active);
        refundRequests[msg.sender].active = false;
        emit RefundCanceled(msg.sender);
    }

    function acceptRefundForOwner(address payable requester, address receiver) public payable onlyOwner {
        require(requester != address(0));
        require(receiver != address(0));

        refundRequest storage r = refundRequests[requester];

        require(r.active);
        require(balanceOf(requester) == r.tokenAmount);
        require(msg.value == r.paidAmount);
        require(r.buyFrom == owner());
        requester.transfer(msg.value);
        transferForRefund(requester, receiver, r.tokenAmount);
        r.active = false;
        emit RefundAccepted(requester, receiver, r.tokenAmount, msg.value);
    }

    function acceptRefundForReseller(address payable requester) public payable {
        require(requester != address(0));

        locker memory l = lockerList[msg.sender];

        require(l.isReseller);

        refundRequest storage r = refundRequests[requester];

        require(r.active);
        require(balanceOf(requester) == r.tokenAmount);
        require(msg.value == r.paidAmount);
        require(r.buyFrom == msg.sender);
        requester.transfer(msg.value);
        transferForRefund(requester, msg.sender, r.tokenAmount);
        r.active = false;
        emit RefundAccepted(requester, msg.sender, r.tokenAmount, msg.value);
    }

    function refundInfo(address requester) public view returns (bool, uint256, uint256) {
        refundRequest memory r = refundRequests[requester];

        return (r.active, r.tokenAmount, r.paidAmount);
    }

    function transferForRefund(address from, address to, uint256 amount) internal {
        require(balanceOf(from) == amount);

        unlockBalance(from);

        balance storage fromBalance = balances[from];
        balance storage toBalance = balances[to];

        fromBalance.available = 0;
        fromBalance.lockedUp = 0;
        fromBalance.unlockIndex = fromBalance.lockUpCount;
        toBalance.available = toBalance.available.add(amount);

        emit Transfer(from, to, amount);
    }
}