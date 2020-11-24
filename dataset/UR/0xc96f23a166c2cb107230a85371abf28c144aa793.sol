 

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

 

 
contract Destructible is Ownable {

  constructor() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract ERC223Basic is ERC20Basic {
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

 

 
contract ERC223ReceivingContract {
   
  function tokenFallback(address _from, uint256 _value, bytes _data) public returns (bool);
}

 

 
contract Adminable is Ownable {
	address public admin;
	event AdminDesignated(address indexed previousAdmin, address indexed newAdmin);

   
	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

   
  modifier onlyOwnerOrAdmin() {
		require(msg.sender == owner || msg.sender == admin);
		_;
	}

   
	function designateAdmin(address _address) public onlyOwner {
		require(_address != address(0) && _address != owner);
		emit AdminDesignated(admin, _address);
		admin = _address;
	}
}

 

 
contract Lockable is Adminable, ERC20Basic {
  using SafeMath for uint256;
   
   
  uint public globalUnlockTime = 1562025600;
  uint public constant decimals = 18;

  event UnLock(address indexed unlocked);
  event Lock(address indexed locked, uint until, uint256 value, uint count);
  event UpdateGlobalUnlockTime(uint256 epoch);

  struct LockMeta {
    uint256 value;
    uint until;
  }

  mapping(address => LockMeta[]) internal locksMeta;
  mapping(address => bool) locks;

   
  function lock(address _address, uint _days, uint256 _value) onlyOwnerOrAdmin public {
    _value = _value*(10**decimals);
    require(_value > 0);
    require(_days > 0);
    require(_address != owner);
    require(_address != admin);

    uint untilTime = block.timestamp + _days * 1 days;
    locks[_address] = true;
     
    locksMeta[_address].push(LockMeta(_value, untilTime));
     
    emit Lock(_address, untilTime, _value, locksMeta[_address].length);
  }

   
  function unlock(address _address) onlyOwnerOrAdmin public {
    locks[_address] = false;
    delete locksMeta[_address];
    emit UnLock(_address);
  }

   
  function lockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    LockMeta[] memory locked = locksMeta[_owner];
    uint length = locked.length;
     
    if (length == 0) {
      return 0;
    }
     
    uint256 _result = 0;
    for (uint i = 0; i < length; i++) {
      if (_time <= locked[i].until) {
        _result = _result.add(locked[i].value);
      }
    }
    return _result;
  }

   
  function lockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.lockedBalanceOf(_owner, block.timestamp);
  }

   
  function unlockedBalanceOf(address _owner, uint _time) public view returns (uint256) {
    return this.balanceOf(_owner).sub(lockedBalanceOf(_owner, _time));
  }

   
  function unlockedNowBalanceOf(address _owner) public view returns (uint256) {
    return this.unlockedBalanceOf(_owner, block.timestamp);
  }

  function updateGlobalUnlockTime(uint256 _epoch) public onlyOwnerOrAdmin returns (bool) {
    require(_epoch >= 0);
    globalUnlockTime = _epoch;
    emit UpdateGlobalUnlockTime(_epoch);
     
     
     
     
  }

   
  modifier onlyUnlocked(uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if (locks[msg.sender] == true) {
        require(this.unlockedNowBalanceOf(msg.sender) >= _value);
      }
      _;
    }
  }

   
  modifier onlyUnlockedOf(address _address, uint256 _value) {
    if(block.timestamp > globalUnlockTime) {
      _;
    } else {
      if (locks[_address] == true) {
        require(this.unlockedNowBalanceOf(_address) >= _value);
      } else {

      }
      _;
    }
  }
}

 

 
contract StandardLockableToken is Lockable,  ERC223Basic,  StandardToken {

   
  function isContract(address _address) private constant returns (bool) {
    uint256 codeLength;
    assembly {
      codeLength := extcodesize(_address)
    }
    return codeLength > 0;
  }

   
  function transfer(address _to, uint256 _value) onlyUnlocked(_value) public returns (bool) {
    bytes memory empty;
    return _transfer(_to, _value, empty);
  }

   
  function transfer(address _to, uint256 _value, bytes _data) onlyUnlocked(_value) public returns (bool) {
    return _transfer(_to, _value, _data);
  }

   
  function _transfer(address _to, uint256 _value, bytes _data) internal returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value > 0);
     
     

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

     
    if (isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
    }

     
    emit Transfer(msg.sender, _to, _value);
     
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) onlyUnlockedOf(_from, _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);

     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    bytes memory empty;
    if (isContract(_to)) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, empty);
    }

     
    emit Transfer(_from, _to, _value);
     
    emit Transfer(_from, _to, _value, empty);
    return true;
  }
}

 

 
contract StandardBurnableLockableToken is StandardLockableToken, BurnableToken {
   
  function burnFrom(address _from, uint256 _value) onlyOwner onlyUnlockedOf(_from, _value) public {
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    _burn(_from, _value);

    bytes memory empty;
     
    emit Transfer(msg.sender, address(0), _value, empty);
  }

   
  function burn(uint256 _value) onlyOwner onlyUnlocked(_value) public {
    require(_value > 0);
    _burn(msg.sender, _value);

    bytes memory empty;
       
    emit Transfer(msg.sender, address(0), _value, empty);
  }
}

 

 
contract RubiixToken is StandardBurnableLockableToken, Destructible {
  string public constant name = "Rubiix Token";
	uint public constant decimals = 18;
	string public constant symbol = "RBX";

   
  constructor() public {
     
    owner = msg.sender;
    admin = 0xfb36E83F6bE7C0E9ba9FF403389001f2312121aF;

    uint256 INITIAL_SUPPLY = 223684211 * (10**decimals);

     
    totalSupply_ = INITIAL_SUPPLY;

     
    bytes memory empty;

     
    uint256 ownerSupply =  12302631605 * (10**(decimals-2));
    balances[msg.sender] = ownerSupply;
    emit Transfer(address(0), msg.sender, ownerSupply);
    emit Transfer(address(0), msg.sender, ownerSupply, empty);

     
    address teamAddress = 0x7B1Af4A3b427C8eED8aA36a9f997b056853d0e36;
    uint256 teamSupply = 447368422 * (10**(decimals - 1));
    balances[teamAddress] = teamSupply;
    emit Transfer(address(0), teamAddress, teamSupply);
    emit Transfer(address(0), teamAddress, teamSupply, empty);

     
    address companyAddress = 0x3AFb62d009fEe4DD66A405f191B25e77f1d64126;
    uint256 companySupply = 5144736853 * (10**(decimals-2));
    balances[companyAddress] = companySupply;
    emit Transfer(address(0), companyAddress, companySupply);
    emit Transfer(address(0), companyAddress, companySupply, empty);

     
    address walletAddress = 0x4E44743330b950a8c624C457178AaC1355c4f6b2;
    uint256 walletSupply = 447368422 * (10**(decimals-2));
    balances[walletAddress] = walletSupply;
    emit Transfer(address(0), walletAddress, walletSupply);
    emit Transfer(address(0), walletAddress, walletSupply, empty);
  }
}