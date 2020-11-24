 

pragma solidity ^0.4.11;


contract Storage {
    struct Crate {
        mapping(bytes32 => uint256) uints;
        mapping(bytes32 => address) addresses;
        mapping(bytes32 => bool) bools;
        mapping(address => uint256) bals;
    }

    mapping(bytes32 => Crate) crates;

    function setUInt(bytes32 _crate, bytes32 _key, uint256 _value)  {
        crates[_crate].uints[_key] = _value;
    }

    function getUInt(bytes32 _crate, bytes32 _key) constant returns(uint256) {
        return crates[_crate].uints[_key];
    }

    function setAddress(bytes32 _crate, bytes32 _key, address _value)  {
        crates[_crate].addresses[_key] = _value;
    }

    function getAddress(bytes32 _crate, bytes32 _key) constant returns(address) {
        return crates[_crate].addresses[_key];
    }

    function setBool(bytes32 _crate, bytes32 _key, bool _value)  {
        crates[_crate].bools[_key] = _value;
    }

    function getBool(bytes32 _crate, bytes32 _key) constant returns(bool) {
        return crates[_crate].bools[_key];
    }

    function setBal(bytes32 _crate, address _key, uint256 _value)  {
        crates[_crate].bals[_key] = _value;
    }

    function getBal(bytes32 _crate, address _key) constant returns(uint256) {
        return crates[_crate].bals[_key];
    }
}

contract StorageEnabled {

   
  address public storageAddr;

  function StorageEnabled(address _storageAddr) {
    storageAddr = _storageAddr;
  }


   
   
   


   
  function babzBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal('Nutz', _owner);
  }
  function _setBabzBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal('Nutz', _owner, _newValue);
  }
   
  function activeSupply() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'activeSupply');
  }
  function _setActiveSupply(uint256 _newActiveSupply) internal {
    Storage(storageAddr).setUInt('Nutz', 'activeSupply', _newActiveSupply);
  }
   
  function burnPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'burnPool');
  }
  function _setBurnPool(uint256 _newBurnPool) internal {
    Storage(storageAddr).setUInt('Nutz', 'burnPool', _newBurnPool);
  }
   
  function powerPool() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Nutz', 'powerPool');
  }
  function _setPowerPool(uint256 _newPowerPool) internal {
    Storage(storageAddr).setUInt('Nutz', 'powerPool', _newPowerPool);
  }





   
   
   

   
  function powerBalanceOf(address _owner) constant returns (uint256) {
    return Storage(storageAddr).getBal('Power', _owner);
  }

  function _setPowerBalanceOf(address _owner, uint256 _newValue) internal {
    Storage(storageAddr).setBal('Power', _owner, _newValue);
  }

  function outstandingPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Power', 'outstandingPower');
  }

  function _setOutstandingPower(uint256 _newOutstandingPower) internal {
    Storage(storageAddr).setUInt('Power', 'outstandingPower', _newOutstandingPower);
  }

  function authorizedPower() constant returns (uint256) {
    return Storage(storageAddr).getUInt('Power', 'authorizedPower');
  }

  function _setAuthorizedPower(uint256 _newAuthorizedPower) internal {
    Storage(storageAddr).setUInt('Power', 'authorizedPower', _newAuthorizedPower);
  }


  function downs(address _user) constant public returns (uint256 total, uint256 left, uint256 start) {
    uint256 rawBytes = Storage(storageAddr).getBal('PowerDown', _user);
    start = uint64(rawBytes);
    left = uint96(rawBytes >> (64));
    total = uint96(rawBytes >> (96 + 64));
    return;
  }

  function _setDownRequest(address _holder, uint256 total, uint256 left, uint256 start) internal {
    uint256 result = uint64(start) + (left << 64) + (total << (96 + 64));
    Storage(storageAddr).setBal('PowerDown', _holder, result);
  }

}


contract Governable {

   
  address[] public admins;

  function Governable() {
    admins.length = 1;
    admins[0] = msg.sender;
  }

  modifier onlyAdmins() {
    bool isAdmin = false;
    for (uint256 i = 0; i < admins.length; i++) {
      if (msg.sender == admins[i]) {
        isAdmin = true;
      }
    }
    require(isAdmin == true);
    _;
  }

  function addAdmin(address _admin) public onlyAdmins {
    for (uint256 i = 0; i < admins.length; i++) {
      require(_admin != admins[i]);
    }
    require(admins.length < 10);
    admins[admins.length++] = _admin;
  }

  function removeAdmin(address _admin) public onlyAdmins {
    uint256 pos = admins.length;
    for (uint256 i = 0; i < admins.length; i++) {
      if (_admin == admins[i]) {
        pos = i;
      }
    }
    require(pos < admins.length);
     
    if (pos < admins.length - 1) {
      admins[pos] = admins[admins.length - 1];
    }
     
    admins.length--;
  }

}

 
contract Pausable is Governable {

  bool public paused = true;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyAdmins whenNotPaused {
    paused = true;
  }

   
  function unpause() onlyAdmins whenPaused {
     
    paused = false;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract NutzEnabled is Pausable, StorageEnabled {
  using SafeMath for uint;

   
  address public nutzAddr;


  modifier onlyNutz() {
    require(msg.sender == nutzAddr);
    _;
  }

  function NutzEnabled(address _nutzAddr, address _storageAddr)
    StorageEnabled(_storageAddr) {
    nutzAddr = _nutzAddr;
  }

   
   
   

   
  function totalSupply() constant returns (uint256) {
    return activeSupply().add(powerPool()).add(burnPool());
  }

   
   
  mapping (address => mapping (address => uint)) internal allowed;

  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  function approve(address _owner, address _spender, uint256 _amountBabz) public onlyNutz whenNotPaused {
    require(_owner != _spender);
    allowed[_owner][_spender] = _amountBabz;
  }

  function _transfer(address _from, address _to, uint256 _amountBabz, bytes _data) internal {
    require(_to != address(this));
    require(_to != address(0));
    require(_amountBabz > 0);
    require(_from != _to);
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setBabzBalanceOf(_to, babzBalanceOf(_to).add(_amountBabz));
  }

  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    _transfer(_from, _to, _amountBabz, _data);
  }

  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public onlyNutz whenNotPaused {
    allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    _transfer(_from, _to, _amountBabz, _data);
  }

}

 
contract PullPayment {

  modifier onlyNutz() {
      _;
  }
  
modifier onlyOwner() {
      _;
  }

  modifier whenNotPaused () {_;}

  function balanceOf(address _owner) constant returns (uint256 value);

  function paymentOf(address _owner) constant returns (uint256 value, uint256 date) ;

   
   
  function changeDailyLimit(uint _dailyLimit) public ;

  function changeWithdrawalDate(address _owner, uint256 _newDate)  public ;

  function asyncSend(address _dest) public payable ;


  function withdraw() public ;

   
   
   
   
  function isUnderLimit(uint amount) internal returns (bool);

}


 
contract Nutz {


   
  function balanceOf(address _owner) constant returns (uint);

  function totalSupply() constant returns (uint256);

  function activeSupply() constant returns (uint256);

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256);

   
   
  function floor() constant returns (uint256);

   
   
  function ceiling() constant returns (uint256);

  function powerPool() constant returns (uint256);


  function _checkDestination(address _from, address _to, uint256 _value, bytes _data) internal;



   
   
   

  function powerDown(address powerAddr, address _holder, uint256 _amountBabz) public ;


  function asyncSend(address _pullAddr, address _dest, uint256 _amountWei) public ;


   
   
   

  function approve(address _spender, uint256 _amountBabz) public;

  function transfer(address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transfer(address _to, uint256 _amountBabz) public returns (bool);

  function transData(address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _amountBabz, bytes _data) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _amountBabz);

  function () public payable;

  function purchase(uint256 _price) public payable;

  function sell(uint256 _price, uint256 _amountBabz);

  function powerUp(uint256 _amountBabz) public;

}


contract MarketEnabled is NutzEnabled {

  uint256 constant INFINITY = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

   
  address public pullAddr;

   
   
  uint256 internal purchasePrice;

   
  uint256 internal salePrice;

  function MarketEnabled(address _pullAddr, address _storageAddr, address _nutzAddr)
    NutzEnabled(_nutzAddr, _storageAddr) {
    pullAddr = _pullAddr;
  }


  function ceiling() constant returns (uint256) {
    return purchasePrice;
  }

   
   
  function floor() constant returns (uint256) {
    if (nutzAddr.balance == 0) {
      return INFINITY;
    }
    uint256 maxFloor = activeSupply().mul(1000000).div(nutzAddr.balance);  
     
    return maxFloor >= salePrice ? maxFloor : salePrice;
  }

  function moveCeiling(uint256 _newPurchasePrice) public onlyAdmins {
    require(_newPurchasePrice <= salePrice);
    purchasePrice = _newPurchasePrice;
  }

  function moveFloor(uint256 _newSalePrice) public onlyAdmins {
    require(_newSalePrice >= purchasePrice);
     
     
     
    if (_newSalePrice < INFINITY) {
      require(nutzAddr.balance >= activeSupply().mul(1000000).div(_newSalePrice));  
    }
    salePrice = _newSalePrice;
  }

  function purchase(address _sender, uint256 _value, uint256 _price) public onlyNutz whenNotPaused returns (uint256) {
     
    require(purchasePrice > 0);
    require(_price == purchasePrice);

    uint256 amountBabz = purchasePrice.mul(_value).div(1000000);  
     
     
    require(amountBabz > 0);

     
    uint256 activeSup = activeSupply();
    uint256 powPool = powerPool();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(amountBabz).div(activeSup.add(burnPool()));
      _setPowerPool(powPool.add(powerShare));
    }
    _setActiveSupply(activeSup.add(amountBabz));
    _setBabzBalanceOf(_sender, babzBalanceOf(_sender).add(amountBabz));
    return amountBabz;
  }

  function sell(address _from, uint256 _price, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 effectiveFloor = floor();
    require(_amountBabz != 0);
    require(effectiveFloor != INFINITY);
    require(_price == effectiveFloor);

    uint256 amountWei = _amountBabz.mul(1000000).div(effectiveFloor);   
    require(amountWei > 0);
     
    uint256 powPool = powerPool();
    uint256 activeSup = activeSupply();
    if (powPool > 0) {
      uint256 powerShare = powPool.mul(_amountBabz).div(activeSup);
      _setPowerPool(powPool.sub(powerShare));
    }
    _setActiveSupply(activeSup.sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    Nutz(nutzAddr).asyncSend(pullAddr, _from, amountWei);
  }


   
  function allocateEther(uint256 _amountWei, address _beneficiary) public onlyAdmins {
    require(_amountWei > 0);
     
     
     
    require(nutzAddr.balance.sub(_amountWei) >= activeSupply().mul(1000000).div(salePrice));  
    Nutz(nutzAddr).asyncSend(pullAddr, _beneficiary, _amountWei);
  }

}



contract Power {



  function balanceOf(address _holder) constant returns (uint256);

  function totalSupply() constant returns (uint256);

  function activeSupply() constant returns (uint256);


   
   
   

  function slashPower(address _holder, uint256 _value, bytes32 _data) public ;

  function powerUp(address _holder, uint256 _value) public ;

   
   
   

   
  function transfer(address _to, uint256 _amountPower) public returns (bool success);

  function downtime() public returns (uint256);

  function downTick(address _owner) public;

  function downs(address _owner) constant public returns (uint256, uint256, uint256);

}


contract PowerEnabled is MarketEnabled {

   
  address public powerAddr;

   
   
  uint256 public maxPower = 0;

   
  uint256 public downtime;

  modifier onlyPower() {
    require(msg.sender == powerAddr);
    _;
  }

  function PowerEnabled(address _powerAddr, address _pullAddr, address _storageAddr, address _nutzAddr)
    MarketEnabled(_pullAddr, _nutzAddr, _storageAddr) {
    powerAddr = _powerAddr;
  }

  function setMaxPower(uint256 _maxPower) public onlyAdmins {
    require(outstandingPower() <= _maxPower && _maxPower < authorizedPower());
    maxPower = _maxPower;
  }

  function setDowntime(uint256 _downtime) public onlyAdmins {
    downtime = _downtime;
  }

   
  function dilutePower(uint256 _amountBabz, uint256 _amountPower) public onlyAdmins {
    uint256 authorizedPow = authorizedPower();
    uint256 totalBabz = totalSupply();
    if (authorizedPow == 0) {
       
      _setAuthorizedPower((_amountPower > 0) ? _amountPower : _amountBabz.add(totalBabz));
    } else {
       
      _setAuthorizedPower(authorizedPow.mul(totalBabz.add(_amountBabz)).div(totalBabz));
    }
    _setBurnPool(burnPool().add(_amountBabz));
  }

  function _slashPower(address _holder, uint256 _value, bytes32 _data) internal {
    uint256 previouslyOutstanding = outstandingPower();
    _setOutstandingPower(previouslyOutstanding.sub(_value));
     
    uint256 powPool = powerPool();
    uint256 slashingBabz = _value.mul(powPool).div(previouslyOutstanding);
    _setPowerPool(powPool.sub(slashingBabz));
     
    Power(powerAddr).slashPower(_holder, _value, _data);
  }

  function slashPower(address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    _setPowerBalanceOf(_holder, powerBalanceOf(_holder).sub(_value));
    _slashPower(_holder, _value, _data);
  }

  function slashDownRequest(uint256 _pos, address _holder, uint256 _value, bytes32 _data) public onlyAdmins {
    var (total, left, start) = downs(_holder);
    left = left.sub(_value);
    _setDownRequest(_holder, total, left, start);
    _slashPower(_holder, _value, _data);
  }

   
  function powerUp(address _sender, address _from, uint256 _amountBabz) public onlyNutz whenNotPaused {
    uint256 authorizedPow = authorizedPower();
    require(authorizedPow != 0);
    require(_amountBabz != 0);
    uint256 totalBabz = totalSupply();
    require(totalBabz != 0);
    uint256 amountPow = _amountBabz.mul(authorizedPow).div(totalBabz);
     
    uint256 outstandingPow = outstandingPower();
    require(outstandingPow.add(amountPow) <= maxPower);

    if (_sender != _from) {
      allowed[_from][_sender] = allowed[_from][_sender].sub(_amountBabz);
    }

    _setOutstandingPower(outstandingPow.add(amountPow));

    uint256 powBal = powerBalanceOf(_from).add(amountPow);
    require(powBal >= authorizedPow.div(10000));  
    _setPowerBalanceOf(_from, powBal);
    _setActiveSupply(activeSupply().sub(_amountBabz));
    _setBabzBalanceOf(_from, babzBalanceOf(_from).sub(_amountBabz));
    _setPowerPool(powerPool().add(_amountBabz));
    Power(powerAddr).powerUp(_from, amountPow);
  }

  function powerTotalSupply() constant returns (uint256) {
    uint256 issuedPower = authorizedPower().div(2);
     
    return maxPower >= issuedPower ? maxPower : issuedPower;
  }

  function _vestedDown(uint256 _total, uint256 _left, uint256 _start, uint256 _now) internal constant returns (uint256) {
    if (_now <= _start) {
      return 0;
    }
     
     
    uint256 timePassed = _now.sub(_start);
    if (timePassed > downtime) {
     timePassed = downtime;
    }
    uint256 amountVested = _total.mul(timePassed).div(downtime);
    uint256 amountFrozen = _total.sub(amountVested);
    if (_left <= amountFrozen) {
      return 0;
    }
    return _left.sub(amountFrozen);
  }

  function createDownRequest(address _owner, uint256 _amountPower) public onlyPower whenNotPaused {
     
     
    require(_amountPower >= authorizedPower().div(10000));  
    _setPowerBalanceOf(_owner, powerBalanceOf(_owner).sub(_amountPower));

    var (, left, ) = downs(_owner);
    uint256 total = _amountPower.add(left);
    _setDownRequest(_owner, total, total, now);
  }

   
  function downTick(address _holder, uint256 _now) public onlyPower whenNotPaused {
    var (total, left, start) = downs(_holder);
    uint256 amountPow = _vestedDown(total, left, start, _now);

     
    uint256 minStep = total.div(10);
    require(left <= minStep || minStep <= amountPow);

     
    uint256 amountBabz = amountPow.mul(totalSupply()).div(authorizedPower());

     
    _setOutstandingPower(outstandingPower().sub(amountPow));
    left = left.sub(amountPow);
    _setPowerPool(powerPool().sub(amountBabz));
    _setActiveSupply(activeSupply().add(amountBabz));
    _setBabzBalanceOf(_holder, babzBalanceOf(_holder).add(amountBabz));
     
    if (left == 0) {
      start = 0;
      total = 0;
    }
     
    _setDownRequest(_holder, total, left, start);
    Nutz(nutzAddr).powerDown(powerAddr, _holder, amountBabz);
  }
}


contract Controller is PowerEnabled {

  function Controller(address _powerAddr, address _pullAddr, address _nutzAddr, address _storageAddr) 
    PowerEnabled(_powerAddr, _pullAddr, _nutzAddr, _storageAddr) {
  }

  function setContracts(address _storageAddr, address _nutzAddr, address _powerAddr, address _pullAddr) public onlyAdmins whenPaused {
    storageAddr = _storageAddr;
    nutzAddr = _nutzAddr;
    powerAddr = _powerAddr;
    pullAddr = _pullAddr;
  }

  function changeDailyLimit(uint256 _dailyLimit) public onlyAdmins {
    PullPayment(pullAddr).changeDailyLimit(_dailyLimit);
  }

  function kill(address _newController) public onlyAdmins whenPaused {
    if (powerAddr != address(0)) { Ownable(powerAddr).transferOwnership(msg.sender); }
    if (pullAddr != address(0)) { Ownable(pullAddr).transferOwnership(msg.sender); }
    if (nutzAddr != address(0)) { Ownable(nutzAddr).transferOwnership(msg.sender); }
    if (storageAddr != address(0)) { Ownable(storageAddr).transferOwnership(msg.sender); }
    selfdestruct(_newController);
  }

}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}