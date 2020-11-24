 

pragma solidity ^0.4.6;

contract Owned {

     
    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

 
 
contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token {

     
    bool public locked;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;
    

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        if (balances[msg.sender] < _value) { 
            throw;
        }        

         
        if (balances[_to] + _value < balances[_to])  { 
            throw;
        }

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

          
        if (locked) {
            throw;
        }

         
        if (balances[_from] < _value) { 
            throw;
        }

         
        if (balances[_to] + _value < balances[_to]) { 
            throw;
        }

         
        if (_value > allowed[_from][msg.sender]) { 
            throw;
        }

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) returns (bool success) {

         
        if (locked) {
            throw;
        }

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


 
contract SCLToken is Owned, StandardToken {

     
    string public standard = "Token 0.1";

     
    string public name = "SOCIAL";        
    
     
    string public symbol = "SCL";

     
    uint8 public decimals = 8;


     
    function SCLToken() {  
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = true;
    }


     
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }


     
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

         
        if (_value < 0) {
            throw;
        }

         
        balances[_recipient] += _value;
        totalSupply += _value;

         
        Transfer(0, owner, _value);
        Transfer(owner, _recipient, _value);

        return true;
    }


     
    function () {
        throw;
    }
}