 

pragma solidity ^0.4.18;

 
 
contract Token {
     
     
     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract YouLongToken is Token {
    string public symbol = "YLO";
    string public name = "YouLongToken";        
    uint8 public constant decimals = 4;            
    uint256 _totalSupply = 1 * (10**9) * (10**4);  
    address owner;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

    modifier onlyOwner() {
      assert(msg.sender == owner);
      _;
    }

    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        throw;
      }
      _;
    }

     
    function YouLongToken() {
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
    }

     
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool success) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) onlyPayloadSize(3 * 32) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}