 

pragma solidity 0.4.15;

 
contract ERC20Token {
    

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function totalSupply() constant returns (uint256 totalSupply);

     
    function balanceOf(address owner) constant returns (uint256 balance);

     
    function transfer(address to, uint256 value) returns (bool success);

     
    function transferFrom(address from, address to, uint256 value) returns (bool success);

     
    function approve(address spender, uint256 value) returns (bool success);

     
    function allowance(address owner, address spender) constant returns (uint256 remaining);
}

pragma solidity 0.4.15;

 
 contract WIN is ERC20Token {
    

    string public constant symbol = "WIN";
    string public constant name = "WIN";

    uint8 public constant decimals = 7;
    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;
    uint256 public totalTokenSupply = 500 * MILLION * TOKEN;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    event Destroyed(address indexed owner, uint256 amount);

     
    function WIN ()   { 
        balances[msg.sender] = totalTokenSupply;
    }

     
    function totalSupply ()  constant  returns (uint256 result) { 
        result = totalTokenSupply;
    }

     
    function balanceOf (address owner)  constant  returns (uint256 balance) { 
        return balances[owner];
    }

     
    function transfer (address to, uint256 amount)   returns (bool success) { 
        if(balances[msg.sender] < amount)
            return false;

        if(amount <= 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[msg.sender] -= amount;
        balances[to] += amount;
        Transfer(msg.sender, to, amount);
        return true;
    }

     
    function transferFrom (address from, address to, uint256 amount)   returns (bool success) { 
        if (balances[from] < amount)
            return false;

        if(allowed[from][msg.sender] < amount)
            return false;

        if(amount == 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        Transfer(from, to, amount);
        return true;
    }

     
    function approve (address spender, uint256 amount)   returns (bool success) { 
       allowed[msg.sender][spender] = amount;
       Approval(msg.sender, spender, amount);
       return true;
   }

     
    function allowance (address owner, address spender)  constant  returns (uint256 remaining) { 
        return allowed[owner][spender];
    }

      
    function destroy (uint256 amount)   returns (bool success) { 
        if(amount == 0) return false;
        if(balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalTokenSupply -= amount;
        Destroyed(msg.sender, amount);
    }
}