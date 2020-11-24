 

pragma solidity ^0.4.16;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
    
    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
    
    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y; 
        assert((x == 0)||(z/x == y));
        return z;
    }
    
}

contract Token {
      
    uint256 public totalSupply;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256  balance);
    
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
      
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);
    
     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token ,SafeMath{
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSubtract(balances[msg.sender],_value);
            balances[_to] = safeAdd(balances[_to],_value) ;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to],_value) ;
            balances[_from] = safeSubtract(balances[_from],_value) ;
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
       emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract POCCToken is StandardToken  {
     
    string  public constant name = "POCC Token";
    string  public constant symbol = "POCC";                                
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    uint256 public tokenExchangeRate = 80000;                               
    
    address public owner;  
    
     
    event DecreaseSupply(uint256 _value);

     
    constructor(address _owner) public {
        owner = _owner;
        totalSupply = safeMult(10000000000,10 ** decimals);
        balances[owner] = totalSupply;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
   
      
    function decreaseSupply (uint256 _value) onlyOwner  public{
        if (balances[owner] < _value)  revert();
        uint256 value = safeMult(_value , 10 ** decimals);
        balances[owner] = safeSubtract(balances[owner],value);
        totalSupply = safeSubtract(totalSupply, value);
        emit DecreaseSupply(value);
    }
    
}