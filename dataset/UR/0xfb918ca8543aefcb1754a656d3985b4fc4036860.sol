 

pragma solidity ^0.4.24;

 
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
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract DetailedToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
}

contract KeyValueStorage {

  mapping(address => mapping(bytes32 => uint256)) _uintStorage;
  mapping(address => mapping(bytes32 => address)) _addressStorage;
  mapping(address => mapping(bytes32 => bool)) _boolStorage;

   

  function getAddress(bytes32 key) public view returns (address) {
      return _addressStorage[msg.sender][key];
  }

  function getUint(bytes32 key) public view returns (uint) {
      return _uintStorage[msg.sender][key];
  }

  function getBool(bytes32 key) public view returns (bool) {
      return _boolStorage[msg.sender][key];
  }

   

  function setAddress(bytes32 key, address value) public {
    _addressStorage[msg.sender][key] = value;
  }

  function setUint(bytes32 key, uint value) public {
      _uintStorage[msg.sender][key] = value;
  }

  function setBool(bytes32 key, bool value) public {
      _boolStorage[msg.sender][key] = value;
  }

   

  function deleteAddress(bytes32 key) public {
      delete _addressStorage[msg.sender][key];
  }

  function deleteUint(bytes32 key) public {
      delete _uintStorage[msg.sender][key];
  }

  function deleteBool(bytes32 key) public {
      delete _boolStorage[msg.sender][key];
  }

}

contract Proxy is Ownable {

  event Upgraded(address indexed implementation);

  address internal _implementation;

  function implementation() public view returns (address) {
    return _implementation;
  }

  function upgradeTo(address impl) public onlyOwner {
    require(_implementation != impl);
    _implementation = impl;
    emit Upgraded(impl);
  }

  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}

contract StorageStateful {

  KeyValueStorage _storage;

}

contract StorageConsumer is StorageStateful {

  constructor(KeyValueStorage storage_) public {
    _storage = storage_;
  }

}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract TokenVersion1 is StorageConsumer, Proxy, DetailedToken {

  constructor(KeyValueStorage storage_)
    public
    StorageConsumer(storage_)
  {
     
    name = "Influence";
    symbol = "INFLU";
    decimals = 18;
    totalSupply = 10000000000 * 10 ** uint256(decimals);
    
     
    storage_.setAddress("owner", msg.sender);
    _storage.setUint(keccak256("balances", msg.sender), totalSupply);
  }

}

contract TokenDelegate is StorageStateful {
  using SafeMath for uint256;

  function balanceOf(address owner) public view returns (uint256 balance) {
    return getBalance(owner);
  }

  function getBalance(address balanceHolder) public view returns (uint256) {
    return _storage.getUint(keccak256("balances", balanceHolder));
  }

  function totalSupply() public view returns (uint256) {
    return _storage.getUint("totalSupply");
  }

  function addSupply(uint256 amount) internal {
    _storage.setUint("totalSupply", totalSupply().add(amount));
  }
  
  function subSupply(uint256 amount) internal {
      _storage.setUint("totalSupply", totalSupply().sub(amount));
  }

  function addBalance(address balanceHolder, uint256 amount) internal {
    setBalance(balanceHolder, getBalance(balanceHolder).add(amount));
  }

  function subBalance(address balanceHolder, uint256 amount) internal {
    setBalance(balanceHolder, getBalance(balanceHolder).sub(amount));
  }

  function setBalance(address balanceHolder, uint256 amount) internal {
    _storage.setUint(keccak256("balances", balanceHolder), amount);
  }

}

contract TokenVersion2 is TokenDelegate {
    
     
    mapping (address => mapping (address => uint256)) public allowance;
  
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    event Burn(address indexed from, uint256 value);

   
  function _transfer(address _from, address _to, uint _value) internal {
      require(_to != address(0x0));
      require(getBalance(_from) >= _value);
      require(getBalance(_to) + _value > getBalance(_to));
      uint previousBalances = getBalance(_from) + getBalance(_to);
      subBalance(_from, _value);
      addBalance(_to, _value);
      emit Transfer(_from, _to, _value);
      assert(getBalance(_from) + getBalance(_to) == previousBalances);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
      _transfer(msg.sender, _to, _value);
      return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_value <= allowance[_from][msg.sender]);      
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
  }

   
  function approve(address _spender, uint256 _value) public
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
      public
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, address(this), _extraData);
          return true;
      }
  }

   
  function burn(uint256 _value) public returns (bool success) {
      require(getBalance(msg.sender) >= _value);    
      subBalance(msg.sender, _value);               
      subSupply(_value);                            
      emit Burn(msg.sender, _value);
      return true;
  }

   
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
      require(getBalance(_from) >= _value);                 
      require(_value <= allowance[_from][msg.sender]);     
      subBalance(_from, _value);                           
      allowance[_from][msg.sender] -= _value;              
      
      subSupply(_value);                                   
      emit Burn(_from, _value);
      return true;
  }
  
}

contract TokenVersion3 is TokenDelegate {

  modifier onlyOwner {
    require(msg.sender == _storage.getAddress("owner"));
    _;
  }

  
     
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
  
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    event Burn(address indexed from, uint256 value);

   
  function _transfer(address _from, address _to, uint _value) internal {
      require(_to != address(0x0));
      require(getBalance(_from) >= _value);
      require(getBalance(_to) + _value > getBalance(_to));
      uint previousBalances = getBalance(_from) + getBalance(_to);
      subBalance(_from, _value);
      addBalance(_to, _value);
      emit Transfer(_from, _to, _value);
      assert(getBalance(_from) + getBalance(_to) == previousBalances);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
      _transfer(msg.sender, _to, _value);
      return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_value <= allowance[_from][msg.sender]);      
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
  }

   
  function approve(address _spender, uint256 _value) public
      returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
      public
      returns (bool success) {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, address(this), _extraData);
          return true;
      }
  }

   
  function burn(uint256 _value) public returns (bool success) {
      require(getBalance(msg.sender) >= _value);    
      subBalance(msg.sender, _value);               
      subSupply(_value);                            
      emit Burn(msg.sender, _value);
      return true;
  }

   
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
      require(getBalance(_from) >= _value);                 
      require(_value <= allowance[_from][msg.sender]);     
      subBalance(_from, _value);                           
      allowance[_from][msg.sender] -= _value;              
      
      subSupply(_value);                                   
      emit Burn(_from, _value);
      return true;
  }
  
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        addBalance(target, mintedAmount);
        addSupply(mintedAmount);
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

}