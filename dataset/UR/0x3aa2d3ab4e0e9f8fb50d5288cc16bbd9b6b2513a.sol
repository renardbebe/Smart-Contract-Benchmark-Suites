 

pragma solidity ^0.4.24;

 

 
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

 

 
 
contract BancrypToken is StandardToken, BurnableToken {
  string public symbol  = "XBANC";
  string public name    = "XBANC";
  uint8 public decimals = 18;

   
   
  uint256 public constant TRANSFERABLE_START_TIME = 1546300799;
  
   
   
   
  address public constant ADVISORS_WALLET     = 0x0fC8c4288841CB199bDdbf385BD762938f5A8328;
  address public constant BANCRYP_WALLET      = 0xcafBCD7F36ae4506E4331a27CC6CAF12fD35E83C;
  address public constant FUNDS_WALLET        = 0x66fC388e7AF7ee6198D849A37B89a813d559913a;
  address public constant RESERVE_FUND_WALLET = 0xb8dc7BfB6D987464b2006aBd6B7511C8D2Ebe50f;
  address public constant SOCIAL_CAUSE_WALLET = 0xd71383C04F67e2Db7F95aC58c9B2509Cf15AAa95;
  address public constant TEAM_WALLET         = 0x2b400ee4Ff17dE03453e325e9198E6C9c4F88243;

   
  uint256 public constant INITIAL_SUPPLY = 300000000;

   
   
  modifier onlyWhenTransferEnabled(address _to) {
    if ( now <= TRANSFERABLE_START_TIME ) {
       
       
      require(msg.sender == TEAM_WALLET || msg.sender == ADVISORS_WALLET ||
        msg.sender == RESERVE_FUND_WALLET || msg.sender == SOCIAL_CAUSE_WALLET ||
        msg.sender == FUNDS_WALLET || msg.sender == BANCRYP_WALLET ||
        _to == BANCRYP_WALLET, "Forbidden to transfer right now");
    }
    _;
  }

   
  modifier validDestination(address to) {
    require(to != address(this));
    _;
  }

   
   
   
   
  constructor() public {  
     
     
    totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
    balances[FUNDS_WALLET] = totalSupply_;
  }

   
   
   
  function transfer(address _to, uint256 _value)
      public
      validDestination(_to)
      onlyWhenTransferEnabled(_to)
      returns (bool) 
  {
      return super.transfer(_to, _value);
  }

   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value)
    public
    validDestination(_to)
    onlyWhenTransferEnabled(_to)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

   
   
  function burn(uint256 _value) public {
    require(msg.sender == FUNDS_WALLET, "Only funds wallet can burn");
    _burn(msg.sender, _value);
  }
}