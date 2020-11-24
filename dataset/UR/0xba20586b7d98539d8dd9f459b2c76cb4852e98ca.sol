 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC223Interface {
    function transfer(address to, uint value, bytes data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
contract ERC223Receiver {
    function tokenFallback(address _fromm, uint256 _value, bytes _data) public pure;
}


 
contract Ownable {

  address public owner;

  address public newOwner;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  constructor() public {
    owner = msg.sender;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
  event OwnershipTransferred(address oldOwner, address newOwner);
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

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event FinalUnpause();
  
  bool public paused = false;
   
  bool public finalUnpaused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    require (!finalUnpaused);
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

     
  function finalUnpause() onlyOwner public {
    paused = false;
    emit FinalUnpause();
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
     
     
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
contract TipcoinToken is StandardToken, Pausable, BurnableToken, ERC223Interface {
    
  using SafeMath for uint256;
  
  string public constant name = "Tipcoin";
  
  string public constant symbol = "TIPC";
  
  uint8 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 1000000000;
  
  constructor() public {
     
     
    totalSupply_ = INITIAL_SUPPLY * 10 ** 18;
    balances[owner] = totalSupply_;
    emit Transfer(address(0), owner, INITIAL_SUPPLY);
  }    
  
   
  function transfer(address _to, uint256 _value, bytes _data, string _fallback) public whenNotPaused returns (bool) {
    require( _to != address(0));
    
    if (isContract(_to)) {            
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_fallback))), msg.sender, _value, _data));
      
      if (_data.length == 0) {
        emit Transfer(msg.sender, _to, _value);
      } else {
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
      }
      return true;
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
    if (isContract(_to)) {
      return transferToContract(msg.sender, _to, _value, _data);
    } else {
      return transferToAddress(msg.sender, _to, _value, _data);
    }
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
      bytes memory empty;
      if (isContract(_to)) {
          return transferToContract(msg.sender, _to, _value, empty);
      } else {
          return transferToAddress(msg.sender, _to, _value, empty);
      }
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){      
    require( _to != address(0));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    bytes memory empty;

    if (isContract(_to)) {
        return transferToContract(_from, _to, _value, empty);
      } else {
        return transferToAddress(_from, _to, _value, empty);
      }
  }

   
  function isContract(address _addr) internal view returns (bool) {
    uint length;
    
    assembly {
      length := extcodesize(_addr)
    }
    
    return (length >0);
  }
  
  function transferToAddress(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (_data.length == 0) {
      emit Transfer(_from, _to, _value);
    } else {
      emit Transfer(_from, _to, _value);
      emit Transfer(_from, _to, _value, _data);
    }    
    return true;
  }
  
  function transferToContract(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    ERC223Receiver receiver = ERC223Receiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    if (_data.length == 0) {
      emit Transfer(_from, _to, _value);
    } else {
      emit Transfer(_from, _to, _value);
      emit Transfer(_from, _to, _value, _data);
    }    
    return true;   
  }
}