 

 
contract ERC20 {
   
  uint public totalSupply;
   
  function balanceOf(address _owner) constant returns (uint);
   
  function allowance(address _owner, address _spender) constant returns (uint);
   
  function transfer(address _to, uint _value) returns (bool ok);
   
  function transferFrom(address _from, address _to, uint _value) returns (bool ok);
   
  function approve(address _spender, uint _value) returns (bool ok);
   
  event Transfer(address indexed _from, address indexed _to, uint _value);
   
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}



 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



 
contract StandardToken is ERC20, SafeMath {

   
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
     
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
     
    balances[_to] = safeAdd(balances[_to], _value);
     
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)  returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
    balances[_to] = safeAdd(balances[_to], _value);
     
    balances[_from] = safeSub(balances[_from], _value);
     
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
     
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
     
    return allowed[_owner][_spender];
  }

}


 
contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

  event Burned(address burner, uint burnedAmount);

   
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner], burnAmount);
    totalSupply = safeSub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}




 
contract HLCToken is BurnableToken {

  string public name;   
  string public symbol;   
  uint8 public decimals = 18;   
  uint256 public totalSupply;
  function HLCToken(address _owner, string _name, string _symbol, uint _totalSupply, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply * 10 ** uint256(_decimals);
    decimals = _decimals;

     
    balances[_owner] = totalSupply;
  }
}