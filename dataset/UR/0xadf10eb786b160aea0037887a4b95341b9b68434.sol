 

pragma solidity ^0.4.24;

 

 
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

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
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

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

 

 
contract LTOTokenSale is Ownable, ReentrancyGuard {

  using SafeMath for uint256;

  uint256 constant minimumAmount = 0.1 ether;      
  uint256 constant maximumCapAmount = 40 ether;   
  uint256 constant ethDecimals = 1 ether;          
  uint256 constant ltoEthDiffDecimals = 10**10;    
  uint256 constant bonusRateDivision = 10000;      

  ERC20Burnable public token;
  address public receiverAddr;
  uint256 public totalSaleAmount;
  uint256 public totalWannaBuyAmount;
  uint256 public startTime;
  uint256 public bonusEndTime;
  uint256 public bonusPercentage;
  uint256 public bonusDecreaseRate;
  uint256 public endTime;
  uint256 public userWithdrawalStartTime;
  uint256 public clearStartTime;
  uint256 public withdrawn;
  uint256 public proportion = 1 ether;
  uint256 public globalAmount;
  uint256 public rate;
  uint256 public nrOfTransactions = 0;

  address public capListAddress;
  mapping (address => bool) public capFreeAddresses;

  struct PurchaserInfo {
    bool withdrew;
    bool recorded;
    uint256 received;      
    uint256 accounted;     
    uint256 unreceived;    
  }

  struct Purchase {
    uint256 received;      
    uint256 used;          
    uint256 tokens;        
  }
  mapping(address => PurchaserInfo) public purchaserMapping;
  address[] public purchaserList;

  modifier onlyOpenTime {
    require(isStarted());
    require(!isEnded());
    _;
  }

  modifier onlyAutoWithdrawalTime {
    require(isEnded());
    _;
  }

  modifier onlyUserWithdrawalTime {
    require(isUserWithdrawalTime());
    _;
  }

  modifier purchasersAllWithdrawn {
    require(withdrawn==purchaserList.length);
    _;
  }

  modifier onlyClearTime {
    require(isClearTime());
    _;
  }

  modifier onlyCapListAddress {
    require(msg.sender == capListAddress);
    _;
  }

  constructor(address _receiverAddr, ERC20Burnable _token, uint256 _totalSaleAmount, address _capListAddress) public {
    require(_receiverAddr != address(0));
    require(_token != address(0));
    require(_capListAddress != address(0));
    require(_totalSaleAmount > 0);

    receiverAddr = _receiverAddr;
    token = _token;
    totalSaleAmount = _totalSaleAmount;
    capListAddress = _capListAddress;
  }

  function isStarted() public view returns(bool) {
    return 0 < startTime && startTime <= now && endTime != 0;
  }

  function isEnded() public view returns(bool) {
    return 0 < endTime && now > endTime;
  }

  function isUserWithdrawalTime() public view returns(bool) {
    return 0 < userWithdrawalStartTime && now > userWithdrawalStartTime;
  }

  function isClearTime() public view returns(bool) {
    return 0 < clearStartTime && now > clearStartTime;
  }

  function isBonusPeriod() public view returns(bool) {
    return now >= startTime && now <= bonusEndTime;
  }

  function startSale(uint256 _startTime, uint256 _rate, uint256 duration,
    uint256 bonusDuration, uint256 _bonusPercentage, uint256 _bonusDecreaseRate,
    uint256 userWithdrawalDelaySec, uint256 clearDelaySec) public onlyOwner {
    require(endTime == 0);
    require(_startTime > 0);
    require(_rate > 0);
    require(duration > 0);
    require(token.balanceOf(this) == totalSaleAmount);

    rate = _rate;
    bonusPercentage = _bonusPercentage;
    bonusDecreaseRate = _bonusDecreaseRate;
    startTime = _startTime;
    bonusEndTime = startTime.add(bonusDuration);
    endTime = startTime.add(duration);
    userWithdrawalStartTime = endTime.add(userWithdrawalDelaySec);
    clearStartTime = endTime.add(clearDelaySec);
  }

  function getPurchaserCount() public view returns(uint256) {
    return purchaserList.length;
  }

  function _calcProportion() internal {
    assert(totalSaleAmount > 0);

    if (totalSaleAmount >= totalWannaBuyAmount) {
      proportion = ethDecimals;
      return;
    }
    proportion = totalSaleAmount.mul(ethDecimals).div(totalWannaBuyAmount);
  }

  function getSaleInfo(address purchaser) internal view returns (Purchase p) {
    PurchaserInfo storage pi = purchaserMapping[purchaser];
    return Purchase(
      pi.received,
      pi.received.mul(proportion).div(ethDecimals),
      pi.accounted.mul(proportion).div(ethDecimals).mul(rate).div(ltoEthDiffDecimals)
    );
  }

  function getPublicSaleInfo(address purchaser) public view returns (uint256, uint256, uint256) {
    Purchase memory purchase = getSaleInfo(purchaser);
    return (purchase.received, purchase.used, purchase.tokens);
  }

  function () payable public {
    buy();
  }

  function buy() payable public onlyOpenTime {
    require(msg.value >= minimumAmount);

    uint256 amount = msg.value;
    PurchaserInfo storage pi = purchaserMapping[msg.sender];
    if (!pi.recorded) {
      pi.recorded = true;
      purchaserList.push(msg.sender);
    }
    uint256 totalAmount = pi.received.add(amount);
    if (totalAmount > maximumCapAmount && !isCapFree(msg.sender)) {
      uint256 recap = totalAmount.sub(maximumCapAmount);
      amount = amount.sub(recap);
      if (amount <= 0) {
        revert();
      } else {
        msg.sender.transfer(recap);
      }
    }
    pi.received = pi.received.add(amount);

    globalAmount = globalAmount.add(amount);
    if (isBonusPeriod() && bonusDecreaseRate.mul(nrOfTransactions) < bonusPercentage) {
      uint256 percentage = bonusPercentage.sub(bonusDecreaseRate.mul(nrOfTransactions));
      uint256 bonus = amount.div(bonusRateDivision).mul(percentage);
      amount = amount.add(bonus);
    }
    pi.accounted = pi.accounted.add(amount);
    totalWannaBuyAmount = totalWannaBuyAmount.add(amount.mul(rate).div(ltoEthDiffDecimals));
    _calcProportion();
    nrOfTransactions = nrOfTransactions.add(1);
  }

  function _withdrawal(address purchaser) internal {
    require(purchaser != 0x0);
    PurchaserInfo storage pi = purchaserMapping[purchaser];
    if (pi.withdrew || !pi.recorded) {
      return;
    }
    pi.withdrew = true;
    withdrawn = withdrawn.add(1);
    Purchase memory purchase = getSaleInfo(purchaser);
    if (purchase.used > 0 && purchase.tokens > 0) {
      receiverAddr.transfer(purchase.used);
      require(token.transfer(purchaser, purchase.tokens));

      uint256 unused = purchase.received.sub(purchase.used);
      if (unused > 0) {
        if (!purchaser.send(unused)) {
          pi.unreceived = unused;
        }
      }
    } else {
      assert(false);
    }
    return;
  }

  function withdrawal() public onlyUserWithdrawalTime {
    _withdrawal(msg.sender);
  }

  function withdrawalFor(uint256 index, uint256 stop) public onlyAutoWithdrawalTime onlyOwner {
    for (; index < stop; index++) {
      _withdrawal(purchaserList[index]);
    }
  }

  function clear(uint256 tokenAmount, uint256 etherAmount) public purchasersAllWithdrawn onlyClearTime onlyOwner {
    if (tokenAmount > 0) {
      token.burn(tokenAmount);
    }
    if (etherAmount > 0) {
      receiverAddr.transfer(etherAmount);
    }
  }

  function withdrawFailed(address alternativeAddress) public onlyUserWithdrawalTime nonReentrant {
    require(alternativeAddress != 0x0);
    PurchaserInfo storage pi = purchaserMapping[msg.sender];

    require(pi.recorded);
    require(pi.unreceived > 0);
    if (alternativeAddress.send(pi.unreceived)) {
      pi.unreceived = 0;
    }
  }

  function addCapFreeAddress(address capFreeAddress) public onlyCapListAddress {
    require(capFreeAddress != address(0));

    capFreeAddresses[capFreeAddress] = true;
  }

  function removeCapFreeAddress(address capFreeAddress) public onlyCapListAddress {
    require(capFreeAddress != address(0));

    capFreeAddresses[capFreeAddress] = false;
  }

  function isCapFree(address capFreeAddress) internal view returns (bool) {
    return (capFreeAddresses[capFreeAddress]);
  }

  function currentBonus() public view returns(uint256) {
    return bonusPercentage.sub(bonusDecreaseRate.mul(nrOfTransactions));
  }
}