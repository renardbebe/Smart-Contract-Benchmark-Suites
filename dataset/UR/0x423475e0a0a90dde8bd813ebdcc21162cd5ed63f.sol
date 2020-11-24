 

pragma solidity ^0.4.6;

 
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

 
contract CryptoCopyToken is Owned, Token {

    using SafeMath for uint256;

     
    string public standard = "Token 0.2";

     
    string public name = "CryptoCopy token";

     
    string public symbol = "CCOPY";

     
    uint8 public decimals = 8;
    
     
    uint256 public maxTotalSupply = 1000000 * 10 ** 8;  

     
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

     
    function CryptoCopyToken() {
        balances[msg.sender] = 0;
        totalSupply = 0;
        locked = false;
    }

     
    function unlock() onlyOwner returns (bool success)  {
        locked = false;
        return true;
    }

     
    function lock() onlyOwner returns (bool success)  {
        locked = true;
        return true;
    }
    
     
    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    
     
    function setMaxTotalSupply(uint256 _maxTotalSupply) {
        maxTotalSupply = _maxTotalSupply;
    }

     
    function issue(address _recipient, uint256 _value) onlyOwner returns (bool success) {

        if (totalSupply + _value > maxTotalSupply) {
            return;
        }
        
         
        balances[_recipient] += _value;
        totalSupply += _value;

        return true;
    }

    event Burn(address indexed burner, uint indexed value);

     
    function () {
        throw;
    }
}