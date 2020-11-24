 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) onlyOwner private {
        owner = newOwner;
    }
}

 
 
 
 
 
 
 
contract ERC20Interface {
     

     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract YoyoArkCoin is owned, ERC20Interface {
     
    string public constant standard = 'ERC20';
    string public constant name = 'Yoyo Ark Coin';
    string public constant symbol = 'YAC';
    uint8  public constant decimals = 18;
    uint public registrationTime = 0;
    bool public registered = false;

    uint256 totalTokens = 960 * 1000 * 1000 * 10**18;


     
    mapping (address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    mapping (address => bool) public frozenAccount;
    mapping (address => uint[3]) public frozenTokens;

     
    uint public unlockat;

     
    constructor() public
    {
    }

     
    function () private
    {
        revert();  
    }

    function totalSupply()
        constant
        public
        returns (uint256)
    {
        return totalTokens;
    }

     
    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(msg.sender, _amount)) return false;

        if (balances[msg.sender] >= _amount
            && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public
        returns (bool success)
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(_from, _amount)) return false;

        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

     
     
    function initRegister()
        public
    {
         
        balances[msg.sender] = 960 * 1000 * 1000 * 10**18;
         
        registered = true;
        registrationTime = now;

        unlockat = registrationTime + 6 * 30 days;

         
         
        frozenForTeam();
    }

     
    function frozenForTeam()
        internal
    {
        uint totalFrozeNumber = 144 * 1000 * 1000 * 10**18;
        freeze(msg.sender, totalFrozeNumber);
    }

     
     
     
    function freeze(address _account, uint _totalAmount)
        public
        onlyOwner
    {
        frozenAccount[_account] = true;
        frozenTokens[_account][0] = _totalAmount;             
    }

     
     
     
    function frozenRules(address _from, uint256 _value)
        internal
        returns (bool success)
    {
        if (frozenAccount[_from]) {
            if (now < unlockat) {
                
               if (balances[_from] - _value < frozenTokens[_from][0])
                    return true;
            } else {
                
               frozenAccount[_from] = false;
            }
        }
        return false;
    }
}