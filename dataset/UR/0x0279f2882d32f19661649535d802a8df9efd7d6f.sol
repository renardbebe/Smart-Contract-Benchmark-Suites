 

pragma solidity ^0.4.19;



contract TeaVoucher {

  mapping(address => uint256) balances;
 
  mapping(address => mapping (address => uint256)) allowed;
  
  
  using SafeMath for uint256;
  
  
  address public owner;
  
  uint256 public _totalSupply = 36936;
    uint256 public totalSupply = 36936;
    string public constant symbol = "TEAVO";
    string public constant name = "Tea Voucher";
    uint8 public constant decimals = 0;
    

    uint256 public constant RATE = 200;
   
  function TeaVoucher(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = 36936;                
        totalSupply = _initialAmount;                  
       }
        
         function () payable {
        createTokens();
        throw;
    }
        function createTokens() payable {
        require(msg.value > 0);
        
        uint256 tokens = msg.value.add(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        
        owner.transfer(msg.value);
    }
  
  function totalSupply() constant returns (uint256 theTotalSupply) {
     
     
     
     
     
    theTotalSupply = _totalSupply;
    return theTotalSupply;
  }
  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
     
     
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  
   
   
  function transfer(address _to, uint256 _amount) returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _amount 
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
       
       
      Transfer(msg.sender, _to, _amount);
        return true;
      } else {
        return false;
      }
   }
   
   function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
      && allowed[_from][msg.sender] >= _amount
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
    balances[_from] -= _amount;
    balances[_to] += _amount;
    Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}