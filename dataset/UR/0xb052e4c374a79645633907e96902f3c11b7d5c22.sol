 

pragma solidity ^0.4.23;

contract CoinSen  
{
     
     
    address public admin_address = 0xea899208Eb2C574e24f5638AeC2cF72CE765AD0f;  
    address public account_address = 0xea899208Eb2C574e24f5638AeC2cF72CE765AD0f;  
    
     
    mapping(address => uint256) balances;
    
     
    string public name = "SchrödingerEquationNet";  
    string public symbol = "SEN";  
    uint8 public decimals = 18;  
    uint256 initSupply = 45000000000;  
    uint256 public totalSupply = 0;  

     
    constructor() 
    payable 
    public
    {
        totalSupply = mul(initSupply, 10**uint256(decimals));
        balances[account_address] = totalSupply;

         
         
        _add_lock_account(0xDFAeAb6d32C3eE23846a12559e2162bBBd9E37f9, mul(30000000000,10**uint256(decimals)), 1600918560);
        _add_lock_account(0xA058542a14d1d35Eda10434180937E0Df64DAcf7, mul(30000000000,10**uint256(decimals)), 1600918560);
        _add_lock_account(0x42585f0ccb3c09F6955dcCc31C2D2783164a4848, mul(30000000000,10**uint256(decimals)), 1600918560);
        
        
    }

    function balanceOf( address _addr ) public view returns ( uint )
    {
        return balances[_addr];
    }

     
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    ); 

    function transfer(
        address _to, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = sub(balances[msg.sender],_value);

         
         
         
        if(lockInfo[msg.sender].amount > 0 && block.timestamp < lockInfo[msg.sender].release_time)
            require(balances[msg.sender] >= lockInfo[msg.sender].amount);

            

        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    
    mapping (address => mapping (address => uint256)) internal allowed;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = sub(balances[_from], _value);
        
         
         
         
        if(lockInfo[_from].amount > 0 && block.timestamp < lockInfo[_from].release_time)
            require(balances[_from] >= lockInfo[_from].amount);
        
        
        balances[_to] = add(balances[_to], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } 
        else 
        {
            allowed[msg.sender][_spender] = sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    
     
    bool public direct_drop_switch = true;  
    uint256 public direct_drop_rate = 11000000;  
    address public direct_drop_address = 0xea899208Eb2C574e24f5638AeC2cF72CE765AD0f;  
    address public direct_drop_withdraw_address = 0xb2b354E9652Fb548A60ecA0d7a6Eb7672d95cA6c;  

    bool public direct_drop_range = false;  
    uint256 public direct_drop_range_start = 1569814560;  
    uint256 public direct_drop_range_end = 1572406560;  

    event TokenPurchase
    (
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    function buyTokens( address _beneficiary ) 
    public 
    payable  
    returns (bool)
    {
        require(direct_drop_switch);
        require(_beneficiary != address(0));

         
        if( direct_drop_range )
        {
             
             
            require(block.timestamp >= direct_drop_range_start && block.timestamp <= direct_drop_range_end);

        }
        
         
         
        
        uint256 tokenAmount = div(mul(msg.value,direct_drop_rate ), 10**18);  
        uint256 decimalsAmount = mul( 10**uint256(decimals), tokenAmount);
        
         
        require
        (
            balances[direct_drop_address] >= decimalsAmount
        );

        assert
        (
            decimalsAmount > 0
        );

        
         
        uint256 all = add(balances[direct_drop_address], balances[_beneficiary]);

        balances[direct_drop_address] = sub(balances[direct_drop_address], decimalsAmount);

         
         
         
        if(lockInfo[direct_drop_address].amount > 0 && block.timestamp < lockInfo[direct_drop_address].release_time)
            require(balances[direct_drop_address] >= lockInfo[direct_drop_address].amount);

            

        balances[_beneficiary] = add(balances[_beneficiary], decimalsAmount);
        
        assert
        (
            all == add(balances[direct_drop_address], balances[_beneficiary])
        );

         
        emit TokenPurchase
        (
            msg.sender,
            _beneficiary,
            msg.value,
            tokenAmount
        );

        return true;

    } 
    

      
    bool public air_drop_switch = true;  
    uint256 public air_drop_rate = 75000;  
    address public air_drop_address = 0xD1054c5B71022788cF439902Ba603E33882B3da7;  
    uint256 public air_drop_count = 1;  

    mapping(address => uint256) airdrop_times;  

    bool public air_drop_range = false;  
    uint256 public air_drop_range_start = 1601436960;  
    uint256 public air_drop_range_end = 1601436960;  

    event TokenGiven
    (
        address indexed sender,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    function airDrop( address _beneficiary ) 
    public 
    payable  
    returns (bool)
    {
        require(air_drop_switch);
        require(_beneficiary != address(0));
         
        if( air_drop_range )
        {
             
             
            require(block.timestamp >= air_drop_range_start && block.timestamp <= air_drop_range_end);

        }

         
        if( air_drop_count > 0 )
        {
            require
            ( 
                airdrop_times[_beneficiary] <= air_drop_count 
            );
        }
        
         
        uint256 tokenAmount = air_drop_rate;
        uint256 decimalsAmount = mul(10**uint256(decimals), tokenAmount); 
        
         
        require
        (
            balances[air_drop_address] >= decimalsAmount
        );

        assert
        (
            decimalsAmount > 0
        );

        
        
         
        uint256 all = add(balances[air_drop_address], balances[_beneficiary]);

        balances[air_drop_address] = sub(balances[air_drop_address], decimalsAmount);

         
         
         
        if(lockInfo[air_drop_address].amount > 0 && block.timestamp < lockInfo[air_drop_address].release_time)
            require(balances[air_drop_address] >= lockInfo[air_drop_address].amount);
        
        balances[_beneficiary] = add(balances[_beneficiary], decimalsAmount);
        
        assert
        (
            all == add(balances[air_drop_address], balances[_beneficiary])
        );

         
        emit TokenGiven
        (
            msg.sender,
            _beneficiary,
            msg.value,
            tokenAmount
        );

        return true;

    }
    
     
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public 
    {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal 
    {
        require(_value <= balances[_who]);
        
        balances[_who] = sub(balances[_who], _value);

         
         
         
        if(lockInfo[_who].amount > 0 && block.timestamp < lockInfo[_who].release_time)
            require(balances[_who] >= lockInfo[_who].amount);
            

        totalSupply = sub(totalSupply, _value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
     
     
     
    struct LockAccount 
    {
         
        uint256 amount ;  
        uint256 release_time ;  
    }

    mapping(address => LockAccount) public lockInfo;

     
    function _add_lock_account(address _lock_address, uint256 _amount, uint256 _release_time) internal
    {
         
         
        if( lockInfo[_lock_address].amount == 0 )
            lockInfo[_lock_address] = LockAccount( _amount , _release_time);
    }
    
     
    modifier admin_only()
    {
        require(msg.sender==admin_address);
        _;
    }

    function setAdmin( address new_admin_address ) 
    public 
    admin_only 
    returns (bool)
    {
        require(new_admin_address != address(0));
        admin_address = new_admin_address;
        return true;
    }

     
    function setAirDrop( bool status )
    public
    admin_only
    returns (bool)
    {
        air_drop_switch = status;
        return true;
    }
    
     
    function setDirectDrop( bool status )
    public
    admin_only
    returns (bool)
    {
        direct_drop_switch = status;
        return true;
    }
    
     
    function withDraw()
    public
    {
         
        require(msg.sender == admin_address || msg.sender == direct_drop_withdraw_address);
        require(address(this).balance > 0);
         
        direct_drop_withdraw_address.transfer(address(this).balance);
    }
         
     
    function () external payable
    {
                        if( msg.value > 0 )
            buyTokens(msg.sender);
        else
            airDrop(msg.sender); 
        
        
        
           
    }

     
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) 
        {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

}