 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}



 
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



contract ECTAToken is BurnableToken {
    
    string public constant name = "ECTA Token";
    string public constant symbol = "ECTA";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY =  1000000000 * (10 ** uint256(decimals));  
    uint256 public constant ADMIN_ALLOWANCE =  170000000 * (10 ** uint256(decimals));   
    uint256 public constant TEAM_VESTING_AMOUNT = 200000000 * (10 ** uint256(decimals));  
    uint256 public constant PLATFORM_GROWTH_VESTING_AMOUNT = 130000000 * (10 ** uint256(decimals));  
    uint256 public constant CROWDSALE_ALLOWANCE= 500000000 * (10 ** uint256(decimals));  
 

    address public crowdsaleAddress;  
    address public creator;  
    address public adminAddress = 0xCF3D36be31838DA6d600B882848566A1aEAE8008;   
  
    constructor () public BurnableToken(){
        creator = msg.sender;
        approve(adminAddress, ADMIN_ALLOWANCE);
        totalSupply_ = INITIAL_SUPPLY;
        balances[creator] = totalSupply_ - TEAM_VESTING_AMOUNT - PLATFORM_GROWTH_VESTING_AMOUNT;
    }
  
    modifier onlyCreator {
      require(msg.sender == creator);
      _;
    }
    
    function setCrowdsaleAndVesting(address _crowdsaleAddress, address _teamVestingContractAddress, address _platformVestingContractAddress) onlyCreator external {
        require (crowdsaleAddress == address(0));
        crowdsaleAddress = _crowdsaleAddress;
        approve(crowdsaleAddress, CROWDSALE_ALLOWANCE);  
        balances[_teamVestingContractAddress] = TEAM_VESTING_AMOUNT;  
        balances[_platformVestingContractAddress] = PLATFORM_GROWTH_VESTING_AMOUNT;  
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
      require(msg.sender != creator);
      return super.transfer(_to, _value);
    }
   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(msg.sender != creator);
      return super.transferFrom(_from, _to, _value);
    }
}