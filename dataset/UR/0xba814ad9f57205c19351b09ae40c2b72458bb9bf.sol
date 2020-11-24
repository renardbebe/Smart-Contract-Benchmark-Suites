 

pragma solidity ^0.4.11;

 
 
 
 
 


 
 
 
 
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value)
        returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant
        returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint _value);
}


 
 
 
contract Owned {

     
     
     
    address public owner;
    address public newOwner;

     
     
     
    function Owned() {
        owner = msg.sender;
    }


     
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


     
     
     
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


     
     
     
    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


 
 
 
library SafeMath {

     
     
     
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


 
 
 
contract DanetonToken is ERC20Interface, Owned {
    using SafeMath for uint;

     
     
     
    string public constant symbol = "DNE";
    string public constant name = "Daneton";
    uint8 public constant decimals = 18;

    uint public constant totalSupply = 10 * 10**9 * 10**18;

     
     
     
    mapping(address => uint) balances;

     
     
     
    mapping(address => mapping (address => uint)) allowed;


     
     
     
    function DanetonToken() Owned() {
        balances[owner] = totalSupply;
    }


     
     
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }


     
     
     
    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
     
     
     
     
    function approve(
        address _spender,
        uint _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
     
     
     
    function allowance(
        address _owner,
        address _spender
    ) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }


     
     
     
    function () {
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }
}