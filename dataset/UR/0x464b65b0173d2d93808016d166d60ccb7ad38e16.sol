 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
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

   
  function transferOwnership(address newOwner) public onlyOwner{
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}


contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool){
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool){
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ComissionList is Claimable {
  using SafeMath for uint256;

  struct Transfer {
    uint256 stat;
    uint256 perc;
  }

  mapping (string => Transfer) refillPaySystemInfo;
  mapping (string => Transfer) widthrawPaySystemInfo;

  Transfer transferInfo;

  event RefillCommisionIsChanged(string _paySystem, uint256 stat, uint256 perc);
  event WidthrawCommisionIsChanged(string _paySystem, uint256 stat, uint256 perc);
  event TransferCommisionIsChanged(uint256 stat, uint256 perc);

   
  function setRefillFor(string _paySystem, uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    refillPaySystemInfo[_paySystem].stat = _stat;
    refillPaySystemInfo[_paySystem].perc = _perc;

    RefillCommisionIsChanged(_paySystem, _stat, _perc);
  }

   
  function setWidthrawFor(string _paySystem,uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    widthrawPaySystemInfo[_paySystem].stat = _stat;
    widthrawPaySystemInfo[_paySystem].perc = _perc;

    WidthrawCommisionIsChanged(_paySystem, _stat, _perc);
  }

   
  function setTransfer(uint256 _stat, uint256 _perc) public onlyOwner returns (uint256) {
    transferInfo.stat = _stat;
    transferInfo.perc = _perc;

    TransferCommisionIsChanged(_stat, _perc);
  }

   
  function getRefillStatFor(string _paySystem) public view returns (uint256) {
    return refillPaySystemInfo[_paySystem].perc;
  }

   
  function getRefillPercFor(string _paySystem) public view returns (uint256) {
    return refillPaySystemInfo[_paySystem].stat;
  }

   
  function getWidthrawStatFor(string _paySystem) public view returns (uint256) {
    return widthrawPaySystemInfo[_paySystem].perc;
  }

   
  function getWidthrawPercFor(string _paySystem) public view returns (uint256) {
    return widthrawPaySystemInfo[_paySystem].stat;
  }

   
  function getTransferPerc() public view returns (uint256) {
    return transferInfo.perc;
  }
  
   
  function getTransferStat() public view returns (uint256) {
    return transferInfo.stat;
  }

   
  function calcWidthraw(string _paySystem, uint256 _value) public view returns(uint256) {
    uint256 _totalComission;
    _totalComission = ( widthrawPaySystemInfo[_paySystem].stat * 100 + (_value / 100 ) * widthrawPaySystemInfo[_paySystem].perc ) / 100;

    return _totalComission;
  }

   
  function calcRefill(string _paySystem, uint256 _value) public view returns(uint256) {
    uint256 _totalSum;
    _totalSum = (((_value - refillPaySystemInfo[_paySystem].stat) * 100) * 100) / (refillPaySystemInfo[_paySystem].perc + (100 * 100));

    return _value.sub(_totalSum);
  }

   
  function calcTransfer(uint256 _value) public view returns(uint256) {
    uint256 _totalSum;
    _totalSum = (((_value - transferInfo.stat) * 100) * 100) / (transferInfo.perc + (100 * 100));

    return _value.sub(_totalSum);
  }
}

contract AddressList is Claimable {
    string public name;
    mapping (address => bool) public onList;

    function AddressList(string _name, bool nullValue) public {
        name = _name;
        onList[0x0] = nullValue;
    }
    event ChangeWhiteList(address indexed to, bool onList);

     
     
    function changeList(address _to, bool _onList) onlyOwner public {
        require(_to != 0x0);
        if (onList[_to] != _onList) {
            onList[_to] = _onList;
            ChangeWhiteList(_to, _onList);
        }
    }
}

contract EvaCurrency is PausableToken, BurnableToken {
  string public name = "EvaEUR";
  string public symbol = "EEUR";

  ComissionList public comissionList;
  AddressList public moderList;

  uint8 public constant decimals = 2;

  mapping(address => uint) lastUsedNonce;

  address public staker;

  event Mint(address indexed to, uint256 amount);

  function EvaCurrency(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
    staker = msg.sender;
  }

  function changeName(string _name, string _symbol) onlyOwner public {
      name = _name;
      symbol = _symbol;
  }

  function setLists(ComissionList _comissionList, AddressList _moderList) onlyOwner public {
    comissionList = _comissionList;
    moderList = _moderList;
  }

  modifier onlyModer() {
    require(moderList.onList(msg.sender));
    _;
  }

   
  function transferOnBehalf(address _to, uint _amount, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) onlyModer public returns (bool success) {
    uint256 fee;
    uint256 resultAmount;
    bytes32 hash = keccak256(_to, _amount, _nonce, address(this));
    address sender = ecrecover(hash, _v, _r, _s);

    require(lastUsedNonce[sender] < _nonce);
    require(_amount <= balances[sender]);

    fee = comissionList.calcTransfer(_amount);
    resultAmount = _amount.sub(fee);

    balances[sender] = balances[sender].sub(_amount);
    balances[_to] = balances[_to].add(resultAmount);
    balances[staker] = balances[staker].add(fee);
    lastUsedNonce[sender] = _nonce;
    
    emit Transfer(sender, _to, resultAmount);
    emit Transfer(sender, address(0), fee);
    return true;
  }

   
  function withdrawOnBehalf(uint _amount, string _paySystem, uint _nonce, uint8 _v, bytes32 _r, bytes32 _s) onlyModer public returns (bool success) {
    uint256 fee;
    uint256 resultAmount;
    bytes32 hash = keccak256(address(0), _amount, _nonce, address(this));
    address sender = ecrecover(hash, _v, _r, _s);

    require(lastUsedNonce[sender] < _nonce);
    require(_amount <= balances[sender]);

    fee = comissionList.calcWidthraw(_paySystem, _amount);
    resultAmount = _amount.sub(fee);

    balances[sender] = balances[sender].sub(_amount);
    balances[staker] = balances[staker].add(fee);
    totalSupply_ = totalSupply_.sub(resultAmount);

    emit Transfer(sender, address(0), resultAmount);
    emit Transfer(sender, address(0), fee);
    return true;
  }

   
   
  function refill(address _to, uint256 _amount, string _paySystem) onlyModer public returns (bool success) {
      uint256 fee;
      uint256 resultAmount;

      fee = comissionList.calcRefill(_paySystem, _amount);
      resultAmount = _amount.sub(fee);

      balances[_to] = balances[_to].add(resultAmount);
      balances[staker] = balances[staker].add(fee);
      totalSupply_ = totalSupply_.add(_amount);

      emit Transfer(address(0), _to, resultAmount);
      emit Transfer(address(0), address(0), fee);
      return true;
  }

  function changeStaker(address _staker) onlyOwner public returns (bool success) {
    staker = _staker;
  }
  
  function getNullAddress() public view returns (address) {
    return address(0);
  }
}