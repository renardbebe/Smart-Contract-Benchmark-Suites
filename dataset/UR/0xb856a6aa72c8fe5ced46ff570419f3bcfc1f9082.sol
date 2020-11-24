 

pragma solidity ^0.4.13;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract AUDToken is StandardToken {
  string public name = 'AUDToken';
  string public token = 'AUD';
  uint8 public decimals = 6;
  uint public INITIAL_SUPPLY = 1000000*10**6;
  uint public constant ONE_DECIMAL_QUANTUM_ANZ_TOKEN_PRICE = 1 ether/(100*10**6);

   
  event tokenOverriden(address investor, uint decimalTokenAmount);
  event receivedEther(address sender, uint amount);
  mapping (address => bool) administrators;

   
  address public tokenAdministrator = 0x5a27ACD4A9C68DC28A96918f2403F9a928f73b51;
  address public vault= 0x8049335C4435892a52eA58eD7A73149C48452b45;

   
  modifier onlyAdministrators {
      require(administrators[msg.sender]);
      _;
  }

  function isEqualLength(address[] x, uint[] y) pure internal returns (bool) { return x.length == y.length; }
  modifier onlySameLengthArray(address[] x, uint[] y) {
      require(isEqualLength(x,y));
      _;
  }

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[this] = INITIAL_SUPPLY;
    administrators[tokenAdministrator]=true;
  }

  function()
  payable
  public
  {
      uint amountSentInWei = msg.value;
      uint decimalTokenAmount = amountSentInWei/ONE_DECIMAL_QUANTUM_ANZ_TOKEN_PRICE;
      require(vault.send(msg.value));
      require(this.transfer(msg.sender, decimalTokenAmount));
      emit receivedEther(msg.sender, amountSentInWei);
  }

  function addAdministrator(address newAdministrator)
  public
  onlyAdministrators
  {
        administrators[newAdministrator]=true;
  }

  function overrideTokenHolders(address[] toOverride, uint[] decimalTokenAmount)
  public
  onlyAdministrators
  onlySameLengthArray(toOverride, decimalTokenAmount)
  {
      for (uint i = 0; i < toOverride.length; i++) {
      		uint previousAmount = balances[toOverride[i]];
      		balances[toOverride[i]] = decimalTokenAmount[i];
      		totalSupply_ = totalSupply_-previousAmount+decimalTokenAmount[i];
          emit tokenOverriden(toOverride[i], decimalTokenAmount[i]);
      }
  }

  function overrideTokenHolder(address toOverride, uint decimalTokenAmount)
  public
  onlyAdministrators
  {
  		uint previousAmount = balances[toOverride];
  		balances[toOverride] = decimalTokenAmount;
  		totalSupply_ = totalSupply_-previousAmount+decimalTokenAmount;
      emit tokenOverriden(toOverride, decimalTokenAmount);
  }

  function resetContract()
  public
  onlyAdministrators
  {
    selfdestruct(vault);
  }

}