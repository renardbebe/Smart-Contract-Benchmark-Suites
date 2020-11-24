 

pragma solidity ^0.4.13;

interface IERC20 {
  function totalSupply() constant returns (uint totalSupply);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
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

contract BitClemm is IERC20{
 using SafeMath for uint256;
 
 uint256 public _totalSupply = 0;
 
 
 string public symbol = "BCM"; 
 string public constant name = "BitClemm";  
 uint256 public constant decimals = 3;  
 
 uint256 public MAX_SUPPLY = 180000000 * 10**decimals;  
 uint256 public TOKEN_TO_CREATOR = 9000000 * 10**decimals;  

 uint256 public constant RATE = 1000;  
 address public owner;
 
 mapping(address => uint256) balances;
 mapping(address => mapping(address => uint256)) allowed;
 
  
 function() payable{
     createTokens();
 }
 
  
 function BitClemm(){
     owner = msg.sender;
     balances[msg.sender] = TOKEN_TO_CREATOR;
     _totalSupply = _totalSupply.add(TOKEN_TO_CREATOR);
 }
 
  
 function createTokens() payable{
      
     require(msg.value >= 0);
     
      
     uint256 tokens = msg.value.mul(10 ** decimals);
     tokens = tokens.mul(RATE);
     tokens = tokens.div(10 ** 18);

     uint256 sum = _totalSupply.add(tokens);
     require(sum <= MAX_SUPPLY);
      
     balances[msg.sender] = balances[msg.sender].add(tokens);
     _totalSupply = sum;
     
      
     owner.transfer(msg.value);
 }

 
  
 function totalSupply() constant returns (uint totalSupply){
     return _totalSupply;
 }
 
  
 function balanceOf(address _owner) constant returns (uint balance){
     return balances[_owner];
 }
 
  
 function transfer(address _to, uint256 _value) returns (bool success){
      
     require(
         balances[msg.sender] >= _value
         && _value > 0
     );
      
     balances[msg.sender] = balances[msg.sender].sub(_value);
      
     balances[_to] = balances[_to].add(_value);
      
     Transfer(msg.sender, _to, _value);
     return true;
 }
 
  
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
      
      
      
     require(
         allowed[_from][msg.sender] >= _value
         && balances[msg.sender] >= _value
         && _value > 0
     );
      
     balances[_from] = balances[_from].sub(_value);
      
     balances[_to] = balances[_to].add(_value);
      
     allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      
     Transfer(_from, _to, _value);
     return true;
 }
 
  
 function approve(address _spender, uint256 _value) returns (bool success){
      
     allowed[msg.sender][_spender] = _value;
      
     Approval(msg.sender, _spender, _value);
     return true;
 }
 
  
 function allowance(address _owner, address _spender) constant returns (uint remaining){
     return allowed[_owner][_spender];
 }

 event Transfer(address indexed _from, address indexed _to, uint _value);
 event Approval(address indexed _owner, address indexed _spender, uint _value);
 
}