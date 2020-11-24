 

pragma solidity ^0.4.16;
 
 
 
contract ERC20 {
    
    
    string public standard = 'ERC20';
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok); 
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 

contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
  
        modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

 
library SafeMath { 
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);  
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
                     
            
    }
  }

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract EACOIN is ERC20, Ownable {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals;
    string public version = 'v1.0';
   
    uint public totalSupply;
    mapping (address => uint) public balances;  
    mapping (address => mapping (address => uint)) public allowed;

    function EACOIN() {
        totalSupply = 100000000000000000000000000;
        balances[msg.sender] = 100000000000000000000000000;
        name = 'EACOIN';
        symbol = 'EACO';
        decimals = 18;
    }

    function balanceOf(address who) constant returns (uint256) {
        return balances[who];
    }
    function transfer(address _to, uint _value) returns (bool) {
        if (balances[msg.sender] >= _value &&
            _value > 0   &&
            balances[_to] + _value > balances[_to]  ) {
                                      
                
             balances[msg.sender] = balances[msg.sender] - _value;
            balances[_to] = balances[_to] + _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) returns (bool) {
        require(value > 0 && spender != 0x0);
        allowed[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0 &&
            balances[_to] + _value > balances[_to]) {
             balances[_from] -= _value;
             allowed[_from][msg.sender] -= _value;
             balances[_to] += _value;
             return true;
          } else {
             return false;
         }
    }
    
      
        function approveAndCall(address _spender, uint256 _value, bytes _extraData) {
         TokenSpender spender = TokenSpender(_spender);
         if (approve(_spender, _value)) {
             spender.receiveApproval(msg.sender, _value, this, _extraData);
         }
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}