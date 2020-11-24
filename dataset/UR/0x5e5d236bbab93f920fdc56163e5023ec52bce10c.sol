 

pragma solidity ^0.4.10;
contract Pedal {  
   
string public name; 
string public symbol; 
uint8 public decimals;
uint256 public totalSupply;
 
 
mapping(address => uint256) balances;
address devAddress;
 
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Transfer(address indexed from, address indexed to, uint256 value);
 
 
mapping(address => mapping (address => uint256)) allowed;
 
function Pedal() {  
    name = "Pedal";  
    symbol = "PEDL";  
    decimals = 18;  
    devAddress=0x3501Ec4ddDF17d86b0cA3a8BE82C40eF23965Ce5;  
    uint initialBalance=1000000000000000000*1000000;  
    balances[devAddress]=initialBalance;
    totalSupply+=initialBalance;  
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
}