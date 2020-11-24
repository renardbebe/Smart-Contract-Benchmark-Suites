 

 

pragma solidity 0.4.18;

contract Token {

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {}

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool) {}

     
     
    function balanceOf(address _owner) public view returns (uint) {}

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint) {}

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ERC20Token is Token {

    function transfer(address _to, uint _value)
        public
        returns (bool) 
    {
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]); 
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
        public 
        returns (bool) 
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]); 
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) 
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint)
    {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) 
        public
        view
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnlimitedAllowanceToken is ERC20Token {

    uint constant MAX_UINT = 2**256 - 1;

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public 
        returns (bool) 
    {
        uint allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value && balances[_to] + _value >= balances[_to]); 
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }
}

contract SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

contract EtherToken is UnlimitedAllowanceToken, SafeMath {

    string constant public name = "Ether Token";
    string constant public symbol = "WETH";
    string constant public version = "2.0.0";  
    uint8 constant public decimals = 18;

     
    function()
        public
        payable
    {
        deposit();
    }

     
    function deposit()
        public
        payable
    {
        balances[msg.sender] = safeAdd(balances[msg.sender], msg.value);
        totalSupply = safeAdd(totalSupply, msg.value);
        Transfer(address(0), msg.sender, msg.value);
    }

     
     
    function withdraw(uint _value)
        public
    {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        totalSupply = safeSub(totalSupply, _value);
        require(msg.sender.send(_value));
        Transfer(msg.sender, address(0), _value);
    }
}