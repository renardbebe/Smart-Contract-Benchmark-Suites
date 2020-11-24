 

 

 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.11;


 
contract Token {

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool);

     
     
    function balanceOf(address _owner) public constant returns (uint);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint);

     
     
    uint256 public totalSupply;
}

library Math {
     
     
     
     
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}


 
contract StandardToken is Token {
    using Math for *;

     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

     
     
     
     
     
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        if (!balances[msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[from].safeToSub(value)
            || !allowances[from][msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address spender, uint value)
        public
        returns (bool)
    {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowances[owner][spender];
    }

     
     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint)
    {
        return balances[owner];
    }
}

 
 
 
 
contract DelphyToken is StandardToken {
     

    string constant public name = "Delphy Token";
    string constant public symbol = "DPY";
    uint8 constant public decimals = 18;

     
    uint public constant TOTAL_TOKENS = 100000000 * 10**18;  

     

     
     
     
    function DelphyToken(address[] owners, uint[] tokens)
        public
    {
        totalSupply = 0;

        for (uint i=0; i<owners.length; i++) {
            require (owners[i] != 0);

            balances[owners[i]] += tokens[i];
            Transfer(0, owners[i], tokens[i]);
            totalSupply += tokens[i];
        }

        require (totalSupply == TOTAL_TOKENS);
    }
}