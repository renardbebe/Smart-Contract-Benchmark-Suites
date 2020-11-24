 

pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    constructor() public {
        totalSupply = 12000000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "DCETHER";                                    
        symbol = "DCETH";                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract  DCETHER is owned, TokenERC20 {
    
    uint public sale_step;
    
    address dcether_corp;
    address public Coin_manager;

    mapping (address => address) public followup;

     
    constructor() TokenERC20()  public 
    {
        sale_step = 0;   
        dcether_corp = msg.sender;
        Coin_manager = 0x0;
    }
    
    function SetCoinManager(address manager) onlyOwner public
    {
        require(manager != 0x0);
        
        uint amount = balanceOf[dcether_corp];
        
        Coin_manager = manager;
        balanceOf[Coin_manager] += amount;
        balanceOf[dcether_corp] = 0;
        Transfer(dcether_corp, Coin_manager, amount);                
    }
    
    function SetSaleStep(uint256 step) onlyOwner public
    {
        sale_step = step;
    }

    function () payable public
    {
        require(sale_step!=0);

        uint nowprice = 10000;    
        address follower_1st = 0x0;  
        address follower_2nd = 0x0;  
        
        uint amount = 0;     
        uint amount_1st = 0;     
        uint amount_2nd = 0;     
        uint all_amount = 0;

        amount = msg.value * nowprice;  
        
        follower_1st = followup[msg.sender];
        
        if ( follower_1st != 0x0 )
        {
            amount_1st = amount;     
            if ( balanceOf[follower_1st] < amount_1st )  
                amount_1st = balanceOf[follower_1st];    
                
            follower_2nd = followup[follower_1st];
            
            if ( follower_2nd != 0x0 )
            {
                amount_2nd = amount / 2;     
                
                if ( balanceOf[follower_2nd] < amount_2nd )  
                amount_2nd = balanceOf[follower_2nd];    
            }
        }
        
        all_amount = amount + amount_1st + amount_2nd;
            
        address manager = Coin_manager;
        
        if ( manager == 0x0 )
            manager = dcether_corp;
        
        require(balanceOf[manager]>=all_amount);
        
        require(balanceOf[msg.sender] + amount > balanceOf[msg.sender]);
        balanceOf[manager] -= amount;
        balanceOf[msg.sender] += amount;                   
        require(manager.send(msg.value));
        Transfer(this, msg.sender, amount);                

        if ( amount_1st > 0 )    
        {
            require(balanceOf[follower_1st] + amount_1st > balanceOf[follower_1st]);
            
            balanceOf[manager] -= amount_1st;
            balanceOf[follower_1st] += amount_1st;                   
            
            Transfer(this, follower_1st, amount_1st);                
        }

        if ( amount_2nd > 0 )    
        {
            require(balanceOf[follower_2nd] + amount_2nd > balanceOf[follower_2nd]);
            
            balanceOf[manager] -= amount_2nd;
            balanceOf[follower_2nd] += amount_2nd;                   
            
            Transfer(this, follower_2nd, amount_2nd);                
        }
    }

    function BuyFromFollower(address follow_who) payable public
    {
        require(sale_step!=0);

        uint nowprice = 10000;    
        address follower_1st = 0x0;  
        address follower_2nd = 0x0;  
        
        uint amount = 0;     
        uint amount_1st = 0;     
        uint amount_2nd = 0;     
        uint all_amount = 0;

        amount = msg.value * nowprice;  
        
        follower_1st = follow_who;
        followup[msg.sender] = follower_1st;
        
        if ( follower_1st != 0x0 )
        {
            amount_1st = amount;     
            if ( balanceOf[follower_1st] < amount_1st )  
                amount_1st = balanceOf[follower_1st];    
                
            follower_2nd = followup[follower_1st];
            
            if ( follower_2nd != 0x0 )
            {
                amount_2nd = amount / 2;     
                
                if ( balanceOf[follower_2nd] < amount_2nd )  
                amount_2nd = balanceOf[follower_2nd];    
            }
        }
        
        all_amount = amount + amount_1st + amount_2nd;
            
        address manager = Coin_manager;
        
        if ( manager == 0x0 )
            manager = dcether_corp;
        
        require(balanceOf[manager]>=all_amount);
        
        require(balanceOf[msg.sender] + amount > balanceOf[msg.sender]);
        balanceOf[manager] -= amount;
        balanceOf[msg.sender] += amount;                   
        require(manager.send(msg.value));
        Transfer(this, msg.sender, amount);                

        if ( amount_1st > 0 )    
        {
            require(balanceOf[follower_1st] + amount_1st > balanceOf[follower_1st]);
            
            balanceOf[manager] -= amount_1st;
            balanceOf[follower_1st] += amount_1st;                   
            
            Transfer(this, follower_1st, amount_1st);                
        }

        if ( amount_2nd > 0 )    
        {
            require(balanceOf[follower_2nd] + amount_2nd > balanceOf[follower_2nd]);
            
            balanceOf[manager] -= amount_2nd;
            balanceOf[follower_2nd] += amount_2nd;                   
            
            Transfer(this, follower_2nd, amount_2nd);                
        }
    }


     
    function ForceCoinTransfer(address _from, address _to, uint amount) onlyOwner public
    {
        uint coin_amount = amount * 10 ** uint256(decimals);

        require(_from != 0x0);
        require(_to != 0x0);
        require(balanceOf[_from] >= coin_amount);          

        balanceOf[_from] -= coin_amount;                   
        balanceOf[_to] += coin_amount;                   
        Transfer(_from, _to, coin_amount);                
    }

     
    function DestroyCoin(address _from, uint256 coin_amount) onlyOwner public 
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[_from] >= amount);          
        balanceOf[_from] -= amount;                   
        Transfer(_from, this, amount);                
    }    
    

}