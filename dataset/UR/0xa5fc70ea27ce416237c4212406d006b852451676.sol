 

pragma solidity ^0.4.8;

pragma solidity ^0.4.8;

contract IvanToken {
     
    string public standard = 'Token 0.1';
    string public name = 'Ivan\'s Trackable Token';
    string public symbol = 'ITT';
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
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

    function deposit() payable returns (bool success) {
        if (msg.value == 0) return false;
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        return true;
    }
    
    function withdraw(uint256 amount) returns (bool success) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(amount)) {
            balances[msg.sender] += amount;
            totalSupply += amount;
            return false;
        }
        return true;
    }

}