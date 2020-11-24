 

pragma solidity ^0.5.0;


 
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

contract ERC20 {

     
    function totalSupply() public view returns (uint256);

     
    function balanceOf(address who) public view returns (uint256);

     
    function transfer(address to, uint256 value) public returns (bool);

     
    function transferFrom(address from, address to, uint256 value) public returns (bool);

     
     
     
    function approve(address spender, uint256 value) public returns (bool);

     
    function allowance(address owner, address spender) public view returns (uint256);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

 
 
contract _Base20 is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) internal accounts;

  address internal admin;

  address payable internal founder;

  uint256 internal __totalSupply;

  constructor(uint256 _totalSupply,
    address payable _founder,
    address _admin) public {
      __totalSupply = _totalSupply;
      admin = _admin;
      founder = _founder;
      accounts[founder] = __totalSupply;
      emit Transfer(address(0), founder, accounts[founder]);
    }

     
    modifier onlyAdmin {
      require(admin == msg.sender);
      _;
    }

     
    modifier onlyFounder {
      require(founder == msg.sender);
      _;
    }

     
    function changeFounder(address payable who) onlyFounder public {
      founder = who;
    }

     
    function getFounder() onlyFounder public view returns (address) {
      return founder;
    }

     
    function changeAdmin(address who) public {
      require(who == founder || who == admin);
      admin = who;
    }

     
    function getAdmin() public view returns (address) {
      require(msg.sender == founder || msg.sender == admin);
      return admin;
    }

     
     
     
    function totalSupply() public view returns (uint256) {
      return __totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
      return accounts[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value)
    internal returns (bool) {
      require(_to != address(0));

      require(_value <= accounts[_from]);

       
      accounts[_to] = accounts[_to].add(_value);
      accounts[_from] = accounts[_from].sub(_value);

      emit Transfer(_from, _to, _value);

      return true;
    }
     
    function transfer(address _to, uint256 _value) public returns (bool) {
      return _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool) {
      require(_value <= allowed[_from][msg.sender]);

       
      _transfer(_from, _to, _value);

      allowed[_from][msg.sender] -= _value;
      emit Approval(_from, msg.sender, allowed[_from][msg.sender]);

      return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
      return allowed[_owner][_spender];
    }
}

 
 
contract _Suspendable is _Base20 {
   
   
  bool internal isTransferable = false;
   
   
  mapping(address => bool) internal suspendedAddresses;

   
   
   
   
  constructor(uint256 _totalSupply,
    address payable _founder,
    address _admin) public _Base20(_totalSupply, _founder, _admin)
  {
  }

   
   
  modifier transferable {
    require(isTransferable || msg.sender == founder);
    _;
  }

   
   
  function isTransferEnabled() public view returns (bool) {
    return isTransferable;
  }

   
   
   
  function enableTransfer() onlyAdmin public {
    isTransferable = true;
  }

   
   
   
  function disableTransfer() onlyAdmin public {
    isTransferable = false;
  }

   
   
   
   
  function isSuspended(address _address) public view returns(bool) {
    return suspendedAddresses[_address];
  }

   
   
   
  function suspend(address who) onlyAdmin public {
    if (who == founder || who == admin) {
      return;
    }
    suspendedAddresses[who] = true;
  }

   
   
  function unsuspend(address who) onlyAdmin public {
    suspendedAddresses[who] = false;
  }

   
   
   

   
   
  function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
    require(!isSuspended(_to));
    require(!isSuspended(_from));

    return super._transfer(_from, _to, _value);
  }

   
   
  function transfer(address _to, uint256 _value) public transferable returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value) public transferable returns (bool) {
    require(!isSuspended(msg.sender));
    return super.transferFrom(_from, _to, _value);
  }

   
   
   
   
  function approve(address _spender, uint256 _value) public transferable returns (bool) {
    require(!isSuspended(msg.sender));
    return super.approve(_spender, _value);
  }

   
  function changeFounder(address payable who) onlyFounder public {
    require(!isSuspended(who));
    super.changeFounder(who);
  }

   
  function changeAdmin(address who) public {
    require(!isSuspended(who));
    super.changeAdmin(who);
  }
}

 
 
 
contract ColorCoinBase is _Suspendable {

   
  struct LockUp {
     
    uint256 unlockDate;
     
    uint256 amount;
  }

   
  struct Investor {
     
    uint256 initialAmount;
     
    uint256 lockedAmount;
     
    uint256 currentLockUpPeriod;
     
    LockUp[] lockUpPeriods;
  }

   
  struct AdminTransfer {
     
    address from;
     
    address to;
     
    uint256 amount;
     
    string  reason;
  }

   
   
   
   
  event Unlock(address who, uint256 period, uint256 amount);

   
   
   
   
   
   
  event SuperAction(address from, address to, uint256 requestedAmount, uint256 returnedAmount, string reason);

   
  mapping (address => Investor) internal investors;

   
   
  address internal supply;
   
   
  uint256 internal totalLocked;

   
  AdminTransfer[] internal adminTransferLog;

   
   
   
   
  constructor(uint256 _totalSupply,
    address payable _founder,
    address _admin
  ) public _Suspendable (_totalSupply, _founder, _admin)
  {
    supply = founder;
  }

   
   
   

   
   
   
  function balanceOf(address _owner) public view returns (uint256) {
    return accounts[_owner] + investors[_owner].lockedAmount;
  }

   
   
   
   
   
   
   
   
   
  function _transfer(address _from, address _to, uint256 _value)
  internal returns (bool) {
    if (hasLockup(_from)) {
      tryUnlock(_from);
    }
    super._transfer(_from, _to, _value);
  }

   
   
   
   
   
   
   
   
   
   
  function distribute(address _to, uint256 _value,
      uint256[] memory unlockDates, uint256[] memory amounts
    ) onlyFounder public returns (bool) {
     
    require(balanceOf(_to) == 0);
    require(_value <= accounts[founder]);
    require(unlockDates.length == amounts.length);

     
     

     
     

    investors[_to].initialAmount = _value;
    investors[_to].lockedAmount = _value;
    investors[_to].currentLockUpPeriod = 0;

    for (uint256 i=0; i<unlockDates.length; i++) {
      investors[_to].lockUpPeriods.push(LockUp(unlockDates[i], amounts[i]));
    }

     
    accounts[founder] -= _value;
    emit Transfer(founder, _to, _value);
    totalLocked = totalLocked.add(_value);
     
     
    tryUnlock(_to);
    return true;
  }

   
   
   
  function hasLockup(address _address) public view returns(bool) {
    return (investors[_address].lockedAmount > 0);
  }

   
   
   

   
   
   
   
  function _nextUnlockDate(address who) internal view returns (bool, uint256) {
    if (!hasLockup(who)) {
      return (false, 0);
    }

    uint256 i = investors[who].currentLockUpPeriod;
     
     
     
    if (i == investors[who].lockUpPeriods.length) return (true, 0);

    if (now < investors[who].lockUpPeriods[i].unlockDate) {
       
      return (true, investors[who].lockUpPeriods[i].unlockDate - now);
    } else {
       
      return (true, 0);
    }
  }

   
   
   
   
  function nextUnlockDate() public view returns (bool, uint256) {
    return _nextUnlockDate(msg.sender);
  }

   
   
   
   
  function nextUnlockDate_Admin(address who) public view onlyAdmin returns (bool, uint256) {
    return _nextUnlockDate(who);
  }

   
  function doUnlock() public {
    tryUnlock(msg.sender);
  }

   
   
  function doUnlock_Admin(address who) public onlyAdmin {
    tryUnlock(who);
  }
   
   
   
  function getLockedAmount() public view returns (uint256) {
    return investors[msg.sender].lockedAmount;
  }

   
   
  function getLockedAmount_Admin(address who) public view onlyAdmin returns (uint256) {
    return investors[who].lockedAmount;
  }

  function tryUnlock(address _address) internal {
    if (!hasLockup(_address)) {
      return ;
    }

    uint256 amount = 0;
    uint256 i;
    uint256 start = investors[_address].currentLockUpPeriod;
    uint256 end = investors[_address].lockUpPeriods.length;

    for ( i = start;
          i < end;
          i++)
    {
      if (investors[_address].lockUpPeriods[i].unlockDate <= now) {
        amount += investors[_address].lockUpPeriods[i].amount;
      } else {
        break;
      }
    }

    if (i == investors[_address].lockUpPeriods.length) {
       
      amount = investors[_address].lockedAmount;
    } else if (amount > investors[_address].lockedAmount) {
      amount = investors[_address].lockedAmount;
    }

    if (amount > 0 || i > start) {
      investors[_address].lockedAmount = investors[_address].lockedAmount.sub(amount);
      investors[_address].currentLockUpPeriod = i;
      accounts[_address] = accounts[_address].add(amount);
      emit Unlock(_address, i, amount);
      totalLocked = totalLocked.sub(amount);
    }
  }

   
   
   

  modifier superuser {
    require(msg.sender == admin || msg.sender == founder);
    _;
  }

   
   
   
   
   
   
   
   
  function adminTransfer(address from, address to, uint256 amount, string memory reason) public superuser {
    if (amount == 0) return;

    uint256 requested = amount;
     
    if (accounts[from] < amount) {
      amount = accounts[from];
    }

    accounts[from] -= amount;
    accounts[to] = accounts[to].add(amount);
    emit SuperAction(from, to, requested, amount, reason);
    adminTransferLog.push(AdminTransfer(from, to, amount, reason));
  }

   
   
  function getAdminTransferLogSize() public view superuser returns (uint256) {
    return adminTransferLog.length;
  }

   
   
   
  function getAdminTransferLogItem(uint32 pos) public view superuser
    returns (address from, address to, uint256 amount, string memory reason)
  {
    require(pos < adminTransferLog.length);
    AdminTransfer storage item = adminTransferLog[pos];
    return (item.from, item.to, item.amount, item.reason);
  }

   
   
   

   
   
  function circulatingSupply() public view returns(uint256) {
    return __totalSupply.sub(accounts[supply]).sub(totalLocked);
  }

   
   
   

   
  function destroy() public onlyAdmin {
    selfdestruct(founder);
  }
}

 
 
 
 
 
 
 
 
 
 
 
contract ColorCoinWithPixel is ColorCoinBase {

  address internal pixelAccount;

   
  uint256 internal pixelConvRate;

   
  modifier pixelOrFounder {
    require(msg.sender == founder || msg.sender == pixelAccount);
    _;
  }

  function circulatingSupply() public view returns(uint256) {
    uint256 result = super.circulatingSupply();
    return result - balanceOf(pixelAccount);
  }

   
   
   
   
   
   
   
   
  constructor(uint256 _totalSupply,
    address payable _founder,
    address _admin,
    uint256 _pixelCoinSupply,
    address _pixelAccount
  ) public ColorCoinBase (_totalSupply, _founder, _admin)
  {
    require(_pixelAccount != _founder);
    require(_pixelAccount != _admin);

    pixelAccount = _pixelAccount;
    accounts[pixelAccount] = _pixelCoinSupply;
    accounts[_founder] = accounts[_founder].sub(_pixelCoinSupply);
    emit Transfer(founder, pixelAccount, accounts[pixelAccount]);
  }

   
   
   
   
   
  function setPixelConversionRate(uint256 _pixelConvRate) public pixelOrFounder {
    pixelConvRate = _pixelConvRate;
  }

   
  function getPixelConversionRate() public view returns (uint256) {
    return pixelConvRate;
  }

   
   
   
   
   
  function sendCoinsForPixels(
    uint32 pixels, address destination
  ) public pixelOrFounder {
    uint256 coins = pixels*pixelConvRate;
    if (coins == 0) return;

    require(coins <= accounts[pixelAccount]);

    accounts[destination] = accounts[destination].add(coins);
    accounts[pixelAccount] -= coins;
  }

   
   
   
   
   
   
   
  function sendCoinsForPixels_Batch(
    uint32[] memory pixels,
    address[] memory destinations
  ) public pixelOrFounder {
    require(pixels.length == destinations.length);
    uint256 total = 0;
    for (uint256 i = 0; i < pixels.length; i++) {
      uint256 coins = pixels[i]*pixelConvRate;
      address dst = destinations[i];
      accounts[dst] = accounts[dst].add(coins);
      total += coins;
    }

    require(total <= accounts[pixelAccount]);
    accounts[pixelAccount] -= total;
  }

   
   
   
   
   
   
   
   
  function sendCoinsForPixels_Array(
    uint32 pixels, address[] memory recipients
  ) public pixelOrFounder {
    uint256 coins = pixels*pixelConvRate;
    uint256 total = coins * recipients.length;

    if (total == 0) return;
    require(total <= accounts[pixelAccount]);

    for (uint256 i; i < recipients.length; i++) {
      address dst = recipients[i];
      accounts[dst] = accounts[dst].add(coins);
    }

    accounts[pixelAccount] -= total;
  }
}


 
 
 
contract ColorCoin is ColorCoinWithPixel {
   
  string public constant name = "Color Coin";

   
  string public constant symbol = "COL";

   
  uint8 public constant decimals = 18;

   
   
   
   
   
   
  constructor(uint256 _totalSupply,
    address payable _founder,
    address _admin,
    uint256 _pixelCoinSupply,
    address _pixelAccount
  ) public ColorCoinWithPixel (_totalSupply, _founder, _admin, _pixelCoinSupply, _pixelAccount)
  {
  }
}