 

pragma solidity 0.4.24;

contract Token {

  
    function totalSupply() constant returns (uint supply) {}

    function balanceOf(address _owner) constant returns (uint balance) {}
    
    function transfer(address _to, uint _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}

    function approve(address _spender, uint _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {

    function transfer(address _to, uint _value) returns (bool) {
         
            require (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
            require (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit  Transfer(_from, _to, _value);
            return true;
       
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
 
    function transferFrom(address _from, address _to, uint _value) public returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        require (balances[_from] >= _value && allowance >= _value && balances[_to] + _value >= balances[_to]); 
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            emit Transfer(_from, _to, _value);
            return true;
      
    }
}

contract Dkey is UnboundedRegularToken {

    uint public totalSupply = 260000000000000000000000000;
    uint8 constant public decimals = 18;
    string constant public name = "Dkey";
    string constant public symbol = "Dkey";

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}