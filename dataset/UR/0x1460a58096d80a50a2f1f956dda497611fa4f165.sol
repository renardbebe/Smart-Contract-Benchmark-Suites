 

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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

contract CHXToken is BurnableToken, Ownable {
    string public constant name = "Chainium";
    string public constant symbol = "CHX";
    uint8 public constant decimals = 18;

    bool public isRestricted = true;
    address public tokenSaleContractAddress;

    function CHXToken()
        public
    {
        totalSupply = 200000000e18;
        balances[owner] = totalSupply;
        Transfer(address(0), owner, totalSupply);
    }

    function setTokenSaleContractAddress(address _tokenSaleContractAddress)
        external
        onlyOwner
    {
        require(_tokenSaleContractAddress != address(0));
        tokenSaleContractAddress = _tokenSaleContractAddress;
    }


     
     
     

    function setRestrictedState(bool _isRestricted)
        external
        onlyOwner
    {
        isRestricted = _isRestricted;
    }

    modifier restricted() {
        if (isRestricted) {
            require(
                msg.sender == owner ||
                (msg.sender == tokenSaleContractAddress && tokenSaleContractAddress != address(0))
            );
        }
        _;
    }


     
     
     

    function transfer(address _to, uint _value)
        public
        restricted
        returns (bool)
    {
        require(_to != address(this));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        public
        restricted
        returns (bool)
    {
        require(_to != address(this));
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value)
        public
        restricted
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue)
        public
        restricted
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        restricted
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }


     
     
     

    function batchTransfer(address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_recipients.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transfer(_recipients[i], _values[i]));
        }

        return true;
    }

    function batchTransferFrom(address _from, address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_recipients.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_from, _recipients[i], _values[i]));
        }

        return true;
    }

    function batchTransferFromMany(address[] _senders, address _to, uint[] _values)
        external
        returns (bool)
    {
        require(_senders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_senders[i], _to, _values[i]));
        }

        return true;
    }

    function batchTransferFromManyToMany(address[] _senders, address[] _recipients, uint[] _values)
        external
        returns (bool)
    {
        require(_senders.length == _recipients.length);
        require(_senders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(transferFrom(_senders[i], _recipients[i], _values[i]));
        }

        return true;
    }

    function batchApprove(address[] _spenders, uint[] _values)
        external
        returns (bool)
    {
        require(_spenders.length == _values.length);

        for (uint i = 0; i < _values.length; i++) {
            require(approve(_spenders[i], _values[i]));
        }

        return true;
    }

    function batchIncreaseApproval(address[] _spenders, uint[] _addedValues)
        external
        returns (bool)
    {
        require(_spenders.length == _addedValues.length);

        for (uint i = 0; i < _addedValues.length; i++) {
            require(increaseApproval(_spenders[i], _addedValues[i]));
        }

        return true;
    }

    function batchDecreaseApproval(address[] _spenders, uint[] _subtractedValues)
        external
        returns (bool)
    {
        require(_spenders.length == _subtractedValues.length);

        for (uint i = 0; i < _subtractedValues.length; i++) {
            require(decreaseApproval(_spenders[i], _subtractedValues[i]));
        }

        return true;
    }


     
     
     

    function burn(uint _value)
        public
        onlyOwner
    {
        super.burn(_value);
    }

     
    function drainStrayEther(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

     
    function drainStrayTokens(ERC20Basic _token, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        return _token.transfer(owner, _amount);
    }
}