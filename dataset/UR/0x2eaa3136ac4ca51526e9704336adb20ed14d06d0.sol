 

 
pragma solidity ^0.4.11;

 
contract RCCCToken  {
    string public constant name = "RCCC Token";
    string public constant symbol = "RCCC";
    uint public constant decimals = 18;
    uint256 _totalSupply    = 500000000 * 10**decimals;

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
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

    mapping(address => uint256) balances;  
    mapping(address => mapping (address => uint256)) allowed;

    uint public baseStartTime;  

    address public founder = 0x5e06E608959D68Cf33584BEa9bF6e5CF3975EDe4;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function RCCCToken() {
        balances[founder] = _totalSupply;
    }

    function setStartTime(uint _startTime) {
        if (msg.sender!=founder) revert();
        baseStartTime = _startTime;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (now < baseStartTime) revert();

         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) revert();
        founder = newFounder;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (msg.sender != founder) revert();

         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

     
    function() payable {
        if (!founder.call.value(msg.value)()) revert(); 
    }

     
    function kill() { 
        if (msg.sender == founder) {
            suicide(founder); 
        }
    }

}