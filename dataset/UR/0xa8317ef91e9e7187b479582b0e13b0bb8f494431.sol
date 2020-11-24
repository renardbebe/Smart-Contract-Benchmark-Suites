 

pragma solidity ^0.4.13;

contract DavidCoin {
    
     
     
     

    uint256 public totalSupply = 1000000000000000000000;
    uint256 public circulatingSupply = 0;  	
    uint8   public decimals = 18;
    bool    initialized = false;    
  
    string  public standard = 'ERC20 Token';
    string  public name = 'DavidCoin';
    string  public symbol = 'David';                          
    address public owner = msg.sender; 

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;	
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
	
    function transferOwnership(address newOwner) {
        if (msg.sender == owner){
            owner = newOwner;
        }
    }	
    
    function initializeCoins() {
        if (msg.sender == owner){
            if (!initialized){
                balances[msg.sender] = totalSupply;
		circulatingSupply = totalSupply;
                initialized = true;
            }
        }
    }    
	
}