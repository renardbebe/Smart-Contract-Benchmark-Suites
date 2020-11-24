 

pragma solidity ^0.4.24;
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

interface TokenRecipient {
  function receiveApproval(address _sender, uint256 _value,  bytes _data) external returns (bool ok);
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    assert(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);

    return c;
  }

   
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y)
  {
      uint256 z = ((add(x,1)) / 2);
      y = x;
      while (z < y)
      {
          y = z;
          z = ((add((x / z),z)) / 2);
      }
  }

   
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
      return (mul(x,x));
  }

   
  function pwr(uint256 x, uint256 y)
      internal
      pure
      returns (uint256)
  {
      if (x==0)
          return (0);
      else if (y==0)
          return (1);
      else
      {
          uint256 z = x;
          for (uint256 i=1; i < y; i++)
              z = mul(z,x);
          return (z);
      }
  }
}

 



 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
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


  function transferContract(address _to, uint256 _value, bytes _data) public
    returns (bool success)
  {
    bool isContract = false;
     
    assembly {
      isContract := not(iszero(extcodesize(_to)))
    }
    if (isContract) {
      transfer(_to, _value);
      TokenRecipient receiver = TokenRecipient(_to);
      require(receiver.receiveApproval(msg.sender, _value, _data)); 
    }
    return isContract;
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

 
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


contract PCToken is BurnableToken {

 
   
  string public constant name = "PetCraftToken";
  string public constant symbol = "PCTOKEN";
  uint256 public constant decimals = 18;
  string public version = "1.0";

   
  address public inGameRewardAddress;
  address public developerAddress;

   
  constructor(address _financeContract) public {
      require(_financeContract != address(0));
      inGameRewardAddress = _financeContract;
      developerAddress = msg.sender;

      balances[inGameRewardAddress] = 300000000 * 10**uint(decimals);
      balances[developerAddress] = 1200000000 * 10**uint(decimals);
      totalSupply_ = balances[inGameRewardAddress]  + balances[developerAddress];
  }
}