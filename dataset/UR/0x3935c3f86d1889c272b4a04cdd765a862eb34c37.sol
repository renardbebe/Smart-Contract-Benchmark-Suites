 

pragma solidity ^0.5.0;

contract Ownable {
  address payable private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == _owner, "Forbidden");
    _;
  }

  constructor() public {
    _owner = msg.sender;
  }

  function owner() public view returns (address payable) {
    return _owner;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Non-zero address required.");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b, "Invalid argument.");

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0, "Invalid argument.");
    uint256 c = _a / _b;

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a, "Invalid argument.");
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a, "Invalid argument.");

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Invalid argument.");
    return a % b;
  }
}

 
interface IERC20 {
   
  function totalSupply() external view returns (uint256);

   
  function balanceOf(address account) external view returns (uint256);

   
  function transfer(address recipient, uint256 amount) external returns (bool);

   
  function allowance(address owner, address spender) external view returns (uint256);

   
  function approve(address spender, uint256 amount) external returns (bool);

   
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TicketDistribution is Ownable {
  using SafeMath for uint256;

  uint256 private _price;
  uint256 private _startDistribution;
  uint256 private _endDistribution;
  address payable private _wallet;
  uint256 private _startRefund;
  uint256 private _fees;
  uint256 private _donation;

  uint256 private _secureHash;
  string private _secureDataURL;

  struct Deposit {
    address payable from;
    bool refunded;
    bool selected;
  }

  Deposit[] private _deposits;
  mapping(address => uint256[]) _depositsMap;

  modifier underDistribution {
    require((_startDistribution <= now) && (_endDistribution == 0 || _endDistribution > now), "Distribution has not started");
    _;
  }

  modifier afterDistribution {
    require((_endDistribution > 0) && (_endDistribution <= now), "Distribution has not ended");
    _;
  }

  modifier refundHasStarted {
    require(_startRefund > 0, "Refund has not started");
    _;
  }

  event DepositReceived(address indexed from);
  event DepositSelected(address indexed from);
  event DepositRefunded(address indexed to, uint256 amount);
  event DepositWithdrawed(uint256 amount);
  event RefundStarted();
  event DistributionClosed();

  constructor(uint256 price, address payable wallet, uint256 secureHash, uint256 startDistribution, uint256 endDistribution) public {
    _price = price;
    _donation = price.div(100).mul(2);
    _wallet = wallet;
    _secureHash = secureHash;
    _startDistribution = startDistribution;
    _endDistribution = endDistribution;

    if (_startDistribution == 0) {
      _startDistribution = now;
    }

    require(_wallet != address(0), "Wallet must be a valid address");
  }

  function price() public view returns (uint256) {
    return _price;
  }

  function donation() public view returns (uint256) {
    return _donation;
  }

  function wallet() public view returns (address payable) {
    return _wallet;
  }

  function fees() public view returns (uint256) {
    return _fees;
  }

  function numberOfDeposits() public view returns (uint256) {
    return _deposits.length;
  }

  function startOfDistribution() public view returns (uint256) {
    return _startDistribution;
  }

  function endOfDistribution() public view returns (uint256) {
    return _endDistribution;
  }

  function startOfRefund() public view returns (uint256) {
    return _startRefund;
  }

  function secureDataURL() public view returns (string memory) {
    return _secureDataURL;
  }

  function secureHash() public view returns (uint256) {
    return _secureHash;
  }

  function deposit(uint256 index) public view returns (address, bool, bool) {
    require((index >= 0) && (index < _deposits.length), "Invalid index");
    Deposit memory p = _deposits[index];
    return (p.from, p.refunded, p.selected);
  }

  function numberOfDepositsByAddress(address addr) public view returns (uint256) {
    return _depositsMap[addr].length;
  }

  function depositByAddress(address addr, uint256 index) public view returns (address, bool, bool) {
    require((index >= 0) && (index < _depositsMap[addr].length), "Invalid index");
    Deposit memory p = _deposits[_depositsMap[addr][index]];
    return (p.from, p.refunded, p.selected);
  }

  function closeDistribution() public onlyOwner underDistribution {
    if (_endDistribution == 0) {
      _endDistribution = now;
      emit DistributionClosed();
    }
  }

  function distributionIsStarted() public view returns (bool) {
    return (_startDistribution <= now) && (_endDistribution == 0 || _endDistribution > now);
  }

  function distributionIsClosed() public view returns (bool) {
    return (_endDistribution > 0) && (_endDistribution <= now);
  }

  function startRefund() public onlyOwner afterDistribution {
    _startRefund = now;
    emit RefundStarted();
  }

  function refundIsStarted() public view returns (bool) {
    return _startRefund > 0;
  }

  function() external payable underDistribution {
    require(msg.value == _price, "Invalid value");

    uint pos = _deposits.push(Deposit({
      from: msg.sender,
      refunded: false,
      selected: false
    }));

    _depositsMap[msg.sender].push(pos - 1);

    emit DepositReceived(msg.sender);
  }

  function setSecureDataURL(string memory dataURL) public onlyOwner afterDistribution {
    _secureDataURL = dataURL;
  }

  function reveal(uint256[] memory indices) public onlyOwner afterDistribution {
    uint256 amount = 0;

    uint256 length = indices.length;
    for (uint256 idx = 0; idx < length; idx++) {
      uint256 index = indices[idx];
      if (index < _deposits.length) {
        Deposit storage p = _deposits[index];
        if (p.refunded == false) {
          amount = amount.add(_price);
        }
        p.selected = true;
        p.refunded = true;

        emit DepositSelected(p.from);
      }
    }

    _fees = _fees.add(amount);
  }

  function refund() public afterDistribution refundHasStarted {
    uint256[] memory indices = _depositsMap[msg.sender];
    uint256 amount = 0;
    uint256 length = _deposits.length;
    for (uint256 idx = 0; idx < indices.length; idx++) {
      if (idx < length) {
        Deposit storage p = _deposits[indices[idx]];
        if (p.refunded == false && p.selected == false) {
          p.refunded = true;
          amount = amount.add(_price.sub(_donation));
          _fees = _fees.add(_donation);
        }
      }
    }

    msg.sender.transfer(amount);
    emit DepositRefunded(msg.sender, amount);
  }

  function withdraw() public onlyOwner afterDistribution refundHasStarted {
    uint256 amount = _fees;

    if (now > _startRefund + 30 days) {
      amount = address(this).balance;
    }

    _fees = 0;
    _wallet.transfer(amount);
    emit DepositWithdrawed(amount);
  }

  function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner afterDistribution returns (bool) {
    return IERC20(tokenAddress).transfer(owner(), amount);
  }

  function transferOwnership(address payable) public onlyOwner {
    require(false, "Ownership transfer do not allowed");
  }
}