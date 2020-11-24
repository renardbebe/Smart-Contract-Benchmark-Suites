 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

 

contract TokenLockUp is StandardToken, Ownable {
  using SafeMath for uint256;

  struct LockUp {
    uint256 startTime;
    uint256 endTime;
    uint256 lockamount;
  }

  string public name;
  string public symbol;
  uint public decimals;

  mapping (address => LockUp[]) addressLock;

  event Lock(address indexed from, address indexed to, uint256 amount, uint256 startTime, uint256 endTime);

  constructor (uint _initialSupply, string _name, string _symbol, uint _decimals) public {
    require(_initialSupply >= 0);
    require(_decimals >= 0);

    totalSupply_ = _initialSupply;
    balances[msg.sender] = _initialSupply;
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    emit Transfer(address(0), msg.sender, _initialSupply);
  }

  modifier checkLock (uint _amount) {
    require(_amount >= 0);

     
    LockUp[] storage lockData = addressLock[msg.sender];

    uint256 lockAmountNow;
    for (uint256 i = 0; i < lockData.length; i++) {
      LockUp memory temp = lockData[i];

       
      if (block.timestamp >= temp.startTime && block.timestamp < temp.endTime) {
        lockAmountNow = lockAmountNow.add(temp.lockamount);
      }
    }

     
    if (lockAmountNow == 0) {
       
      require(balances[msg.sender] >= _amount);
    } else {
       
      require(balances[msg.sender].sub(lockAmountNow) >= _amount);
    }
    _;
  }

  function lockUp(address _to, uint256 _amount, uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) {
    require(_to != address(0));
    require(_amount >= 0);
    require(_endTime >= 0);
    require(_startTime < _endTime);

    LockUp memory temp;
    temp.lockamount = _amount;
    temp.startTime = block.timestamp.add(_startTime);
    temp.endTime = block.timestamp.add(_endTime);
    addressLock[_to].push(temp);
    emit Lock(msg.sender, _to, _amount, temp.startTime, temp.endTime);
    return true;
  }

  function lockBatch(address[] _addresses, uint256[] _amounts, uint256[] _startTimes, uint256[] _endTimes) public onlyOwner returns (bool) {
    require(_addresses.length == _amounts.length && _amounts.length == _startTimes.length && _startTimes.length == _endTimes.length);
    for (uint256 i = 0; i < _amounts.length; i++) {
      lockUp(_addresses[i], _amounts[i], _startTimes[i], _endTimes[i]);
    }
    return true;
  }

  function getLockTime(address _to) public view returns (uint256, uint256) {
     
    LockUp[] storage lockData = addressLock[_to];

    uint256 lockAmountNow;
    uint256 lockLimit;
    for (uint256 i = 0; i < lockData.length; i++) {
      LockUp memory temp = lockData[i];

       
      if (block.timestamp >= temp.startTime && block.timestamp < temp.endTime) {
        lockAmountNow = lockAmountNow.add(temp.lockamount);
        if (lockLimit == 0 || lockLimit > temp.endTime) {
          lockLimit = temp.endTime;
        }
      }
    }
    return (lockAmountNow, lockLimit);
  }

  function deleteLockTime(address _to) public onlyOwner returns (bool) {
    require(_to != address(0));
    
    delete addressLock[_to];
    return true;
  }

  function transfer(address _to, uint256 _value) public checkLock(_value) returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferBatch(address[] _addresses, uint256[] _amounts) public onlyOwner returns (bool) {
    require(_addresses.length == _amounts.length);
    uint256 sum;
    for (uint256 i = 0; i < _amounts.length; i++) {
      sum = sum + _amounts[i];
    }
    require(sum <= balances[msg.sender]);
    for (uint256 j = 0; j < _amounts.length; j++) {
      transfer(_addresses[j], _amounts[j]);
    }
    return true;
  }

  function transferWithLock(address _to, uint256 _value, uint256 _startTime, uint256 _endTime) public onlyOwner returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);

    lockUp(_to, _value, _startTime, _endTime);
    return true;
  }

  function transferWithLockBatch(address[] _addresses, uint256[] _amounts, uint256[] _startTimes, uint256[] _endTimes) public onlyOwner returns (bool) {
    require(_addresses.length == _amounts.length && _amounts.length == _startTimes.length && _startTimes.length == _endTimes.length);
    uint256 sum;
    for (uint256 i = 0; i < _amounts.length; i++) {
      sum = sum + _amounts[i];
    }
    require(sum <= balances[msg.sender]);
    for (uint256 j = 0; j < _amounts.length; j++) {
      transferWithLock(_addresses[j], _amounts[j], _startTimes[j], _endTimes[j]);
    }
    return true;
  }

   
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    require(_to != address(0));

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

   
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