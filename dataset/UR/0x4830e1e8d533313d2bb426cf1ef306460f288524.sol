 

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

 

library DateTime {
     
    function toDate(uint256 _ts) internal pure returns (uint256 year, uint256 month, uint256 day) {
        _ts /= 86400;
        uint256 a = (4 * _ts + 102032) / 146097 + 15;
        uint256 b = _ts + 2442113 + a - (a / 4);
        year = (20 * b - 2442) / 7305;
        uint256 d = b - 365 * year - (year / 4);
        month = d * 1000 / 30601;
        day = d - month * 30 - month * 601 / 1000;

         
        if (month <= 13) {
            year -= 4716;
            month -= 1;
        } else {
            year -= 4715;
            month -= 13;
        }
    }

     
    function toTimestamp(uint256 _year, uint256 _month, uint256 _day) internal pure returns (uint256 ts) {
         
        if (_month <= 2) {
            _month += 12;
            _year -= 1;
        }

         
        ts = (365 * _year) + (_year / 4) - (_year / 100) + (_year / 400);
         
        ts += (30 * _month) + (3 * (_month + 1) / 5) + _day;
         
        ts -= 719561;
         
        ts *= 86400;
    }
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

 

contract MonethaTokenHoldersProgram is Restricted, Pausable, CanReclaimEther, CanReclaimTokens {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC20 for ERC20Basic;

    event VouchersPurchased(uint256 vouchers, uint256 weis);
    event VouchersSold(uint256 vouchers, uint256 weis);
    event ParticipationStarted(address indexed participant, uint256 mthTokens);
    event ParticipationStopped(address indexed participant, uint256 mthTokens);
    event VouchersRedeemed(address indexed participant, uint256 vouchers);

    ERC20 public mthToken;
    IMonethaVoucher public monethaVoucher;

    uint256 public participateFromTimestamp;

    mapping(address => uint256) public stakedBy;
    uint256 public totalStacked;

    constructor(ERC20 _mthToken, IMonethaVoucher _monethaVoucher) public {
        require(_monethaVoucher != address(0), "must be valid address");
        require(_mthToken != address(0), "must be valid address");

        mthToken = _mthToken;
        monethaVoucher = _monethaVoucher;
         
        participateFromTimestamp = uint256(- 1);
    }

     
    function buyVouchers() external onlyMonetha {
        uint256 amountToExchange = address(this).balance;
        require(amountToExchange > 0, "positive balance needed");

        uint256 vouchersAvailable = monethaVoucher.totalInSharedPool();
        require(vouchersAvailable > 0, "no vouchers available");

        uint256 vouchersToBuy = monethaVoucher.fromWei(address(this).balance);
         
        if (vouchersToBuy > vouchersAvailable) {
            vouchersToBuy = vouchersAvailable;
        }
         
        amountToExchange = monethaVoucher.toWei(vouchersToBuy);

        (uint256 year, uint256 month,) = DateTime.toDate(now);
        participateFromTimestamp = _nextMonth1stDayTimestamp(year, month);

        monethaVoucher.buyVouchers.value(amountToExchange)(vouchersToBuy);

        emit VouchersPurchased(vouchersToBuy, amountToExchange);
    }

     
    function sellVouchers() external onlyMonetha {
         
        participateFromTimestamp = uint256(- 1);

        uint256 vouchersPool = monethaVoucher.purchasedBy(address(this));
        uint256 weis = monethaVoucher.sellVouchers(vouchersPool);

        emit VouchersSold(vouchersPool, weis);
    }

     
    function isAllowedToParticipateNow() external view returns (bool) {
        return now >= participateFromTimestamp && _participateIsAllowed(now);
    }

     
    function participate() external {
        require(now >= participateFromTimestamp, "too early to participate");
        require(_participateIsAllowed(now), "participate on the 1st day of every month");

        uint256 allowedToTransfer = mthToken.allowance(msg.sender, address(this));
        require(allowedToTransfer > 0, "positive allowance needed");

        mthToken.safeTransferFrom(msg.sender, address(this), allowedToTransfer);
        stakedBy[msg.sender] = stakedBy[msg.sender].add(allowedToTransfer);
        totalStacked = totalStacked.add(allowedToTransfer);

        emit ParticipationStarted(msg.sender, allowedToTransfer);
    }

     
    function isAllowedToRedeemNow() external view returns (bool) {
        return now >= participateFromTimestamp && _redeemIsAllowed(now);
    }

     
    function redeem() external {
        require(now >= participateFromTimestamp, "too early to redeem");
        require(_redeemIsAllowed(now), "redeem is not allowed at the moment");

        (uint256 stackedBefore, uint256 totalStackedBefore) = _cancelParticipation();

        uint256 vouchersPool = monethaVoucher.purchasedBy(address(this));
        uint256 vouchers = vouchersPool.mul(stackedBefore).div(totalStackedBefore);

        require(monethaVoucher.releasePurchasedTo(msg.sender, vouchers), "vouchers was not released");

        emit VouchersRedeemed(msg.sender, vouchers);
    }

     
    function cancelParticipation() external {
        _cancelParticipation();
    }

     
    function() external onlyMonetha payable {
    }

    function _cancelParticipation() internal returns (uint256 stackedBefore, uint256 totalStackedBefore) {
        stackedBefore = stakedBy[msg.sender];
        require(stackedBefore > 0, "must be a participant");
        totalStackedBefore = totalStacked;

        stakedBy[msg.sender] = 0;
        totalStacked = totalStackedBefore.sub(stackedBefore);
        mthToken.safeTransfer(msg.sender, stackedBefore);

        emit ParticipationStopped(msg.sender, stackedBefore);
    }

    function _participateIsAllowed(uint256 _now) internal pure returns (bool) {
        (,, uint256 day) = DateTime.toDate(_now);
        return day == 1;
    }

    function _redeemIsAllowed(uint256 _now) internal pure returns (bool) {
        (uint256 year, uint256 month,) = DateTime.toDate(_now);
        return _currentMonth2ndDayTimestamp(year, month) + 30 minutes <= _now &&
        _now <= _nextMonth1stDayTimestamp(year, month) - 30 minutes;
    }

    function _currentMonth2ndDayTimestamp(uint256 _year, uint256 _month) internal pure returns (uint256) {
        return DateTime.toTimestamp(_year, _month, 2);
    }

    function _nextMonth1stDayTimestamp(uint256 _year, uint256 _month) internal pure returns (uint256) {
        _month += 1;
        if (_month > 12) {
            _year += 1;
            _month = 1;
        }
        return DateTime.toTimestamp(_year, _month, 1);
    }
}