 

pragma solidity ^0.4.13;

contract Utils {

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

      
    modifier greaterOrEqualThanZero(uint256 _amount) {
        require(_amount >= 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0 && _address != address(0) && _address != 0);
        _;
    }

     
    modifier validAddresses(address _address, address _anotherAddress) {
        require((_address != 0x0         && _address != address(0)        && _address != 0 ) &&
                ( _anotherAddress != 0x0 && _anotherAddress != address(0) && _anotherAddress != 0)
        );
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    modifier greaterThanNow(uint256 _startTime) {
         require(_startTime >= now);
        _;
    }
}

contract ERC23Receiver {
    function tokenFallback(address _sender, address _origin, uint256 _value, bytes _data) returns (bool success);
}

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
     
    uint256 c = a / b;
     
    return c;
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC23Basic is ERC20Basic {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    function contractFallback(address _origin, address _to, uint _value, bytes _data) internal returns (bool success);
    function isContract(address _addr) internal returns (bool is_contract);
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes indexed _data);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Basic23Token is Utils, ERC23Basic, BasicToken {
  
     
    function transfer(address _to, uint _value, bytes _data) 
        public
        validAddress(_to) 
        notThis(_to)
        greaterThanZero(_value)
        returns (bool success)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);             
        require(balances[_to].add(_value) > balances[_to]);   
    
        assert(super.transfer(_to, _value));                

        if (isContract(_to)){
          return contractFallback(msg.sender, _to, _value, _data);
        }
        return true;
    }

     
    function transfer(address _to, uint256 _value) 
        public
        validAddress(_to) 
        notThis(_to)
        greaterThanZero(_value)
        returns (bool success)
    {        
        return transfer(_to, _value, new bytes(0));
    }

     
    function balanceOf(address _owner) 
        public
        validAddress(_owner) 
        constant returns (uint256 balance)
    {
        return super.balanceOf(_owner);
    }

     
    function contractFallback(address _origin, address _to, uint _value, bytes _data) internal returns (bool success) {
        ERC23Receiver reciever = ERC23Receiver(_to);
        return reciever.tokenFallback(msg.sender, _origin, _value, _data);
    }

     
    function isContract(address _addr) internal returns (bool is_contract) {
         
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC23 is ERC20{
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool success);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Standard23Token is Utils, ERC23, Basic23Token, StandardToken {

     
    function transferFrom(address _from, address _to, uint256 _value, bytes _data)
        public
        validAddresses(_from, _to) 
        notThis(_to)
        greaterThanZero(_value)
        returns (bool success)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(balances[_to].add(_value) > balances[_to]);   
        require(_value <= allowance);                         
        if (_value > 0 && _from != _to) {
            require(transferFromInternal(_from, _to, _value));  
            if (isContract(_to)) {
                return contractFallback(_from, _to, _value, _data);
            }
        }
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddresses(_from, _to) 
        greaterThanZero(_value)
        returns (bool success)
    {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

     
    function transferFromInternal(address _from, address _to, uint256 _value)
        internal
        validAddresses(_from, _to) 
        greaterThanZero(_value)
        returns (bool success)
    {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}

contract Mintable23Token is Standard23Token, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract MavroToken is Mintable23Token {

    string public constant name = "Mavro Token";
    string public constant symbol = "MVR";
    uint8 public constant decimals = 18;
    bool public TRANSFERS_ALLOWED = false;

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value, address victim) public {
        require(_value <= balances[victim]);
        balances[victim] = balances[victim].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(victim, _value);
    }

    function transferFromInternal(address _from, address _to, uint256 _value)
    internal
    returns (bool success)
    {
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        super.transferFromInternal(_from, _to, _value);
    }

    function transfer(address _to, uint _value, bytes _data) returns (bool success){
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        super.transfer(_to, _value, _data);
    }

    function switchTransfers() onlyOwner {
        TRANSFERS_ALLOWED = !TRANSFERS_ALLOWED;
    }

}