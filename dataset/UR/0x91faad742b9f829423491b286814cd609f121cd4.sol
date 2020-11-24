 

pragma solidity ^0.4.2;

contract Owner {
     
    address public owner;
     
    function Owner() {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
         
        _;
    }
     
    function transferOwnership(address new_owner) onlyOwner {
        owner = new_owner;
    }
}

contract MyToken is Owner {
     
    string public name;
    string public symbol;
    uint8  public decimal;
    uint256 public totalSupply;
    
     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => bool) public frozenAccount;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
     
    function MyToken(uint256 initial_supply, string _name, string _symbol, uint8 _decimal) {
        balanceOf[msg.sender] = initial_supply;
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        totalSupply = initial_supply;
    }
    
     
    function transfer(address to, uint value) {
         
        if (frozenAccount[msg.sender]) throw;
         
        if(balanceOf[msg.sender] < value) throw;
         
        if(balanceOf[to] + value < balanceOf[to]) throw;
        
         
        balanceOf[msg.sender] -= value;
         
        balanceOf[to] += value;
        
         
        Transfer(msg.sender, to, value);
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner{
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        
        Transfer(0,owner,mintedAmount);
        Transfer(owner,target,mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
}