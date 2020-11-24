 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 
 
 


 
 
 
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


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

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
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


 
 
 
 
contract ERC20Token {
    using SafeMath for uint;

     
     
     
    uint256 _totalSupply = 0;

     
     
     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
     
     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
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
        uint256 _amount
    ) returns (bool success) {
         
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
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
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract DaoCasinoToken is ERC20Token, Owned {

     
     
     
    string public constant symbol = "BET";
    string public constant name = "Dao.Casino";
    uint8 public constant decimals = 18;

    function DaoCasinoToken() {
    }

     
     
     
     
    bool public sealed;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;
     
     
    function fill(uint256[] data) onlyOwner {
        require(!sealed);
        for (uint256 i = 0; i < data.length; i++) {
            address account = address(data[i] & (D160-1));
            uint256 amount = data[i] / D160;
             
            if (balances[account] == 0) {
                balances[account] = amount;
                _totalSupply = _totalSupply.add(amount);
                Transfer(0x0, account, amount);
            }
        }
    }

     
     
     
    function seal() onlyOwner {
        require(!sealed);
        sealed = true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}