 

pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
 
 
 
 
 
 
contract ERC20Interface {
     
 
     
    function balanceOf(address _owner) constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success); 
    
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract migration {
    function migrateFrom(address _from, uint256 _value);
}

 
contract ZeusShieldCoin is owned, ERC20Interface {
     
    string public constant standard = 'ERC20';
    string public constant name = 'Zeus Shield Coin';  
    string public constant symbol = 'ZSC';
    uint8  public constant decimals = 18;
    uint public registrationTime = 0;
    bool public registered = false;

    uint256 public totalMigrated = 0;
    address public migrationAgent = 0;

    uint256 totalTokens = 0; 


     
    mapping (address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;
   
     
    mapping (address => bool) public frozenAccount;
    mapping (address => uint[3]) public frozenTokens;

     
    uint[3] public unlockat;

    event Migrate(address _from, address _to, uint256 _value);

     
    function ZeusShieldCoin() 
    {
    }

     
    function () 
    {
        throw;  
    }

    function totalSupply() 
        constant 
        returns (uint256) 
    {
        return totalTokens;
    }

     
    function balanceOf(address _owner) 
        constant 
        returns (uint256) 
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) 
        returns (bool success) 
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(msg.sender, _amount)) return false;

        if (balances[msg.sender] >= _amount
            && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }     
    }
 
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) 
        returns (bool success) 
    {
        if (!registered) return false;
        if (_amount <= 0) return false;
        if (frozenRules(_from, _amount)) return false;

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) 
        returns (bool success) 
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) 
        constant 
        returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }

     
     
    function setMigrationAgent(address _agent) 
        public
        onlyOwner
    {
        if (!registered) throw;
        if (migrationAgent != 0) throw;
        migrationAgent = _agent;
    }

     
     
    function applyMigrate(uint256 _value) 
        public
    {
        if (!registered) throw;
        if (migrationAgent == 0) throw;

         
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        migration(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }


     
     
     
    function registerSale(address _tokenFactory, address _congressAddress) 
        public
        onlyOwner 
    {
         
        if (!registered) {
             
            totalTokens  = 6100 * 1000 * 1000 * 10**18; 

             
            balances[_tokenFactory]    = 3111 * 1000 * 1000 * 10**18;

             
            balances[_congressAddress] = 2074 * 1000 * 1000 * 10**18;

             
             
            teamAllocation();

            registered = true;
            registrationTime = now;

            unlockat[0] = registrationTime +  6 * 30 days;
            unlockat[1] = registrationTime + 12 * 30 days;
            unlockat[2] = registrationTime + 24 * 30 days;
        }
    }

     
     
     
    function freeze(address _account, uint _totalAmount) 
        public
        onlyOwner 
    {
        frozenAccount[_account] = true;  
        frozenTokens[_account][0] = _totalAmount;             
        frozenTokens[_account][1] = _totalAmount * 80 / 100;  
        frozenTokens[_account][2] = _totalAmount * 50 / 100;  
    }

     
    function teamAllocation() 
        internal 
    {
         
        uint individual = 91500 * 1000 * 10**18;

        balances[0xCDc5BDEFC6Fddc66E73250fCc2F08339e091dDA3] = individual;  
        balances[0x8b47D27b085a661E6306Ac27A932a8c0b1C11b84] = individual;  
        balances[0x825f4977DB4cd48aFa51f8c2c9807Ee89120daB7] = individual;  
        balances[0xcDf5D7049e61b2F50642DF4cb5a005b1b4A5cfc2] = individual;  
        balances[0xab0461FB41326a960d3a2Fe2328DD9A65916181d] = individual;  
        balances[0xd2A131F16e4339B2523ca90431322f559ABC4C3d] = individual;  
        balances[0xCcB4d663E6b05AAda0e373e382628B9214932Fff] = individual;  
        balances[0x60284720542Ff343afCA6a6DBc542901942260f2] = individual;  
        balances[0xcb6d0e199081A489f45c73D1D22F6de58596a99C] = individual;  
        balances[0x928D99333C57D31DB917B4c67D4d8a033F2143A7] = individual;  

         
         
         
         
         
        freeze("0xCDc5BDEFC6Fddc66E73250fCc2F08339e091dDA3", individual);
        freeze("0x8b47D27b085a661E6306Ac27A932a8c0b1C11b84", individual);
        freeze("0x825f4977DB4cd48aFa51f8c2c9807Ee89120daB7", individual);
        freeze("0xcDf5D7049e61b2F50642DF4cb5a005b1b4A5cfc2", individual);
        freeze("0xab0461FB41326a960d3a2Fe2328DD9A65916181d", individual);
        freeze("0xd2A131F16e4339B2523ca90431322f559ABC4C3d", individual);
        freeze("0xCcB4d663E6b05AAda0e373e382628B9214932Fff", individual);
        freeze("0x60284720542Ff343afCA6a6DBc542901942260f2", individual);
        freeze("0xcb6d0e199081A489f45c73D1D22F6de58596a99C", individual);
        freeze("0x928D99333C57D31DB917B4c67D4d8a033F2143A7", individual);
    }

     
     
     
    function frozenRules(address _from, uint256 _value) 
        internal 
        returns (bool success) 
    {
        if (frozenAccount[_from]) {
            if (now < unlockat[0]) {
                
               if (balances[_from] - _value < frozenTokens[_from][0]) 
                    return true;  
            } else if (now >= unlockat[0] && now < unlockat[1]) {
                
               if (balances[_from] - _value < frozenTokens[_from][1]) 
                    return true;  
            } else if (now >= unlockat[1] && now < unlockat[2]) {
                
               if (balances[_from]- _value < frozenTokens[_from][2]) 
                   return true;  
            } else {
                
               frozenAccount[_from] = false; 
            }
        }
        return false;
    }   
}