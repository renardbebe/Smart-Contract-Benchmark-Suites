 

pragma solidity ^0.4.8;
 
 
 
contract ERC23Interface {
     
    function totalSupply() constant returns (uint256 totalSupply);
 
     
    function balanceOf(address _owner) constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) returns (bool success);
 
     
    function transfer(address to, uint256 _value, bytes data) returns (bool success);
 
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);
 
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes data); 
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract DecentToken is ERC23Interface {
    string public constant symbol = "DCNT";
    string public constant name = "Decent Token";
    uint8 public constant decimals = 1;
    uint256 _totalSupply = 10000000000;
    
     
    address public owner;
 
     
    mapping(address => uint256) balances;
 
     
    mapping(address => mapping (address => uint256)) allowed;
 
     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
 
     
    function DecentToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
 
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
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

     
    function transfer(address _to, uint256 _amount, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount, _data);
            return true;
        } else {
            return false;
        }
    }
 
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
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
 
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}