 

pragma solidity ^0.4.24;

 

 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

interface IMonethaVoucher {
     
    function totalInSharedPool() external view returns (uint256);

     
    function toWei(uint256 _value) external view returns (uint256);

     
    function fromWei(uint256 _value) external view returns (uint256);

     
    function applyDiscount(address _for, uint256 _vouchers) external returns (uint256 amountVouchers, uint256 amountWei);

     
    function applyPayback(address _for, uint256 _amountWei) external returns (uint256 amountVouchers);

     
    function buyVouchers(uint256 _vouchers) external payable;

     
    function sellVouchers(uint256 _vouchers) external returns(uint256 weis);

     
    function releasePurchasedTo(address _to, uint256 _value) external returns (bool);

     
    function purchasedBy(address owner) external view returns (uint256);
}

 

 
contract Restricted is Ownable {

     
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

     
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

     
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        emit MonethaAddressSet(_address, _isMonethaAddress);
    }
}

 

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract CanReclaimEther is Ownable {
    event ReclaimEther(address indexed to, uint256 amount);

     
    function reclaimEther() external onlyOwner {
        uint256 value = address(this).balance;
        owner.transfer(value);

        emit ReclaimEther(owner, value);
    }

     
    function reclaimEtherTo(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _to.transfer(_value);

        emit ReclaimEther(_to, _value);
    }
}

 

contract CanReclaimTokens is Ownable {
    using SafeERC20 for ERC20Basic;

    event ReclaimTokens(address indexed to, uint256 amount);

     
    function reclaimToken(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        _token.safeTransfer(owner, balance);

        emit ReclaimTokens(owner, balance);
    }

     
    function reclaimTokenTo(ERC20Basic _token, address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "zero address is not allowed");
        _token.safeTransfer(_to, _value);

        emit ReclaimTokens(_to, _value);
    }
}

 

contract MonethaVoucher is IMonethaVoucher, Restricted, Pausable, IERC20, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event DiscountApplied(address indexed user, uint256 releasedVouchers, uint256 amountWeiTransferred);
    event PaybackApplied(address indexed user, uint256 addedVouchers, uint256 amountWeiEquivalent);
    event VouchersBought(address indexed user, uint256 vouchersBought);
    event VouchersSold(address indexed user, uint256 vouchersSold, uint256 amountWeiTransferred);
    event VoucherMthRateUpdated(uint256 oldVoucherMthRate, uint256 newVoucherMthRate);
    event MthEthRateUpdated(uint256 oldMthEthRate, uint256 newMthEthRate);
    event VouchersAdded(address indexed user, uint256 vouchersAdded);
    event VoucherReleased(address indexed user, uint256 releasedVoucher);
    event PurchasedVouchersReleased(address indexed from, address indexed to, uint256 vouchers);

     
    string constant public standard = "ERC20";
    string constant public name = "Monetha Voucher";
    string constant public symbol = "MTHV";
    uint8 constant public decimals = 5;

     
    uint256 constant private DAY_IN_SECONDS = 86400;
    uint256 constant private YEAR_IN_SECONDS = 365 * DAY_IN_SECONDS;
    uint256 constant private LEAP_YEAR_IN_SECONDS = 366 * DAY_IN_SECONDS;
    uint256 constant private YEAR_IN_SECONDS_AVG = (YEAR_IN_SECONDS * 3 + LEAP_YEAR_IN_SECONDS) / 4;
    uint256 constant private HALF_YEAR_IN_SECONDS_AVG = YEAR_IN_SECONDS_AVG / 2;

    uint256 constant public RATE_COEFFICIENT = 1000000000000000000;  
    uint256 constant private RATE_COEFFICIENT2 = RATE_COEFFICIENT * RATE_COEFFICIENT;  
    
    uint256 public voucherMthRate;  
    uint256 public mthEthRate;  
    uint256 internal voucherMthEthRate;  

    ERC20Basic public mthToken;

    mapping(address => uint256) public purchased;  
    uint256 public totalPurchased;                         

    mapping(uint16 => uint256) public totalDistributedIn;  
    mapping(uint16 => mapping(address => uint256)) public distributed;  

    constructor(uint256 _voucherMthRate, uint256 _mthEthRate, ERC20Basic _mthToken) public {
        require(_voucherMthRate > 0, "voucherMthRate should be greater than 0");
        require(_mthEthRate > 0, "mthEthRate should be greater than 0");
        require(_mthToken != address(0), "must be valid contract");

        voucherMthRate = _voucherMthRate;
        mthEthRate = _mthEthRate;
        mthToken = _mthToken;
        _updateVoucherMthEthRate();
    }

     
    function totalSupply() external view returns (uint256) {
        return _totalVouchersSupply();
    }

     
    function totalInSharedPool() external view returns (uint256) {
        return _vouchersInSharedPool(_currentHalfYear());
    }

     
    function totalDistributed() external view returns (uint256) {
        return _vouchersDistributed(_currentHalfYear());
    }

     
    function balanceOf(address owner) external view returns (uint256) {
        return _distributedTo(owner, _currentHalfYear()).add(purchased[owner]);
    }

     
    function allowance(address owner, address spender) external view returns (uint256) {
        owner;
        spender;
        return 0;
    }

     
    function transfer(address to, uint256 value) external returns (bool) {
        to;
        value;
        revert();
    }

     
    function approve(address spender, uint256 value) external returns (bool) {
        spender;
        value;
        revert();
    }

     
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        from;
        to;
        value;
        revert();
    }

     
    function () external onlyMonetha payable {
    }

     
    function toWei(uint256 _value) external view returns (uint256) {
        return _vouchersToWei(_value);
    }

     
    function fromWei(uint256 _value) external view returns (uint256) {
        return _weiToVouchers(_value);
    }

     
    function applyDiscount(address _for, uint256 _vouchers) external onlyMonetha returns (uint256 amountVouchers, uint256 amountWei) {
        require(_for != address(0), "zero address is not allowed");
        uint256 releasedVouchers = _releaseVouchers(_for, _vouchers);
        if (releasedVouchers == 0) {
            return (0,0);
        }
        
        uint256 amountToTransfer = _vouchersToWei(releasedVouchers);

        require(address(this).balance >= amountToTransfer, "insufficient funds");
        _for.transfer(amountToTransfer);

        emit DiscountApplied(_for, releasedVouchers, amountToTransfer);

        return (releasedVouchers, amountToTransfer);
    }

     
    function applyPayback(address _for, uint256 _amountWei) external onlyMonetha returns (uint256 amountVouchers) {
        amountVouchers = _weiToVouchers(_amountWei);
        require(_addVouchers(_for, amountVouchers), "vouchers must be added");

        emit PaybackApplied(_for, amountVouchers, _amountWei);
    }

     
    function buyVouchers(uint256 _vouchers) external onlyMonetha payable {
        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= _vouchers, "insufficient vouchers present");
        require(msg.value == _vouchersToWei(_vouchers), "insufficient funds");

        _addPurchasedTo(msg.sender, _vouchers);

        emit VouchersBought(msg.sender, _vouchers);
    }

     
    function sellVouchers(uint256 _vouchers) external onlyMonetha returns(uint256 weis) {
        require(_vouchers <= purchased[msg.sender], "Insufficient vouchers");

        _subPurchasedFrom(msg.sender, _vouchers);
        weis = _vouchersToWei(_vouchers);
        msg.sender.transfer(weis);
        
        emit VouchersSold(msg.sender, _vouchers, weis);
    }

     
    function releasePurchasedTo(address _to, uint256 _value) external onlyMonetha returns (bool) {
        require(_value <= purchased[msg.sender], "Insufficient Vouchers");
        require(_to != address(0), "address should be valid");

        _subPurchasedFrom(msg.sender, _value);
        _addVouchers(_to, _value);

        emit PurchasedVouchersReleased(msg.sender, _to, _value);

        return true;
    }

     
    function purchasedBy(address owner) external view returns (uint256) {
        return purchased[owner];
    }

     
    function updateVoucherMthRate(uint256 _voucherMthRate) external onlyMonetha {
        require(_voucherMthRate > 0, "should be greater than 0");
        require(voucherMthRate != _voucherMthRate, "same as previous value");

        voucherMthRate = _voucherMthRate;
        _updateVoucherMthEthRate();

        emit VoucherMthRateUpdated(voucherMthRate, _voucherMthRate);
    }

     
    function updateMthEthRate(uint256 _mthEthRate) external onlyMonetha {
        require(_mthEthRate > 0, "should be greater than 0");
        require(mthEthRate != _mthEthRate, "same as previous value");
        
        mthEthRate = _mthEthRate;
        _updateVoucherMthEthRate();

        emit MthEthRateUpdated(mthEthRate, _mthEthRate);
    }

    function _addPurchasedTo(address _to, uint256 _value) internal {
        purchased[_to] = purchased[_to].add(_value);
        totalPurchased = totalPurchased.add(_value);
    }

    function _subPurchasedFrom(address _from, uint256 _value) internal {
        purchased[_from] = purchased[_from].sub(_value);
        totalPurchased = totalPurchased.sub(_value);
    }

    function _updateVoucherMthEthRate() internal {
        voucherMthEthRate = voucherMthRate.mul(mthEthRate);
    }

     
    function _addVouchers(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "zero address is not allowed");

        uint16 currentHalfYear = _currentHalfYear();
        require(_vouchersInSharedPool(currentHalfYear) >= _value, "must be less or equal than vouchers present in shared pool");

        uint256 oldDist = totalDistributedIn[currentHalfYear];
        totalDistributedIn[currentHalfYear] = oldDist.add(_value);
        uint256 oldBalance = distributed[currentHalfYear][_to];
        distributed[currentHalfYear][_to] = oldBalance.add(_value);

        emit VouchersAdded(_to, _value);

        return true;
    }

     
    function _releaseVouchers(address _from, uint256 _value) internal returns (uint256) {
        require(_from != address(0), "must be valid address");

        uint16 currentHalfYear = _currentHalfYear();
        uint256 released = 0;
        if (currentHalfYear > 0) {
            released = released.add(_releaseVouchers(_from, _value, currentHalfYear - 1));
            _value = _value.sub(released);
        }
        released = released.add(_releaseVouchers(_from, _value, currentHalfYear));

        emit VoucherReleased(_from, released);

        return released;
    }

    function _releaseVouchers(address _from, uint256 _value, uint16 _currentHalfYear) internal returns (uint256) {
        if (_value == 0) {
            return 0;
        }

        uint256 oldBalance = distributed[_currentHalfYear][_from];
        uint256 subtracted = _value;
        if (oldBalance <= _value) {
            delete distributed[_currentHalfYear][_from];
            subtracted = oldBalance;
        } else {
            distributed[_currentHalfYear][_from] = oldBalance.sub(_value);
        }

        uint256 oldDist = totalDistributedIn[_currentHalfYear];
        if (oldDist == subtracted) {
            delete totalDistributedIn[_currentHalfYear];
        } else {
            totalDistributedIn[_currentHalfYear] = oldDist.sub(subtracted);
        }
        return subtracted;
    }

     
    function _vouchersToWei(uint256 _value) internal view returns (uint256) {
        return _value.mul(RATE_COEFFICIENT2).div(voucherMthEthRate);
    }

     
    function _weiToVouchers(uint256 _value) internal view returns (uint256) {
        return _value.mul(voucherMthEthRate).div(RATE_COEFFICIENT2);
    }

     
    function _mthToVouchers(uint256 _value) internal view returns (uint256) {
        return _value.mul(voucherMthRate).div(RATE_COEFFICIENT);
    }

     
    function _weiToMth(uint256 _value) internal view returns (uint256) {
        return _value.mul(mthEthRate).div(RATE_COEFFICIENT);
    }

    function _totalVouchersSupply() internal view returns (uint256) {
        return _mthToVouchers(mthToken.balanceOf(address(this)));
    }

    function _vouchersInSharedPool(uint16 _currentHalfYear) internal view returns (uint256) {
        return _totalVouchersSupply().sub(_vouchersDistributed(_currentHalfYear)).sub(totalPurchased);
    }

    function _vouchersDistributed(uint16 _currentHalfYear) internal view returns (uint256) {
        uint256 dist = totalDistributedIn[_currentHalfYear];
        if (_currentHalfYear > 0) {
             
            dist = dist.add(totalDistributedIn[_currentHalfYear - 1]);
        }
        return dist;
    }

    function _distributedTo(address _owner, uint16 _currentHalfYear) internal view returns (uint256) {
        uint256 balance = distributed[_currentHalfYear][_owner];
        if (_currentHalfYear > 0) {
             
            balance = balance.add(distributed[_currentHalfYear - 1][_owner]);
        }
        return balance;
    }
    
    function _currentHalfYear() internal view returns (uint16) {
        return uint16(now / HALF_YEAR_IN_SECONDS_AVG);
    }
}