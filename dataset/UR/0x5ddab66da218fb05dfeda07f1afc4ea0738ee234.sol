 

pragma solidity ^0.4.9;

 
 
 
 
 
 
 

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
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


contract ERC20Token is Owned {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;

     
     
     
    mapping (address => uint256) balances;

     
     
     
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
     
    function ERC20Token(string _symbol, string _name, uint8 _decimals, uint256 _totalSupply) {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
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
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
    function () {
        throw;
    }
}


contract RareToken is ERC20Token {
     
     
     
    function RareToken() ERC20Token ("RARE", "RARE", 8, 0) {
    }

    function burnTokens(uint256 value) onlyOwner {
        if (balances[owner] < value) throw;
        balances[owner] -= value;
        totalSupply -= value;
        Transfer(owner, 0, value);
    }

     
     
     
     
    bool public sealed;
     
    uint256 constant D160 = 0x010000000000000000000000000000000000000000;
     
     
    function fill(uint256[] data) onlyOwner {
        if (sealed) throw;
        for (uint256 i = 0; i < data.length; i++) {
            address account = address(data[i] & (D160-1));
            uint256 amount = data[i] / D160;
             
            if (balances[account] == 0) {
                balances[account] = amount;
                totalSupply += amount;
                Transfer(0x0, account, amount);
            }
        }
    }

     
     
     
    function seal() onlyOwner {
        if (sealed) throw;
        sealed = true;
    }
}