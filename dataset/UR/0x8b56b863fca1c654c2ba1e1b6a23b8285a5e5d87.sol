 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
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

     
    function TokenERC20() public {
        totalSupply = 200000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "WaraCoin2";                                    
        symbol = "WAC2";                                
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

contract  WaraCoin is owned, TokenERC20 {
    
    uint256 public sale_step;
    
    address waracoin_corp;

     
    struct Product_genuine
    {
        address m_made_from_who;   
        
        string m_Product_GUID;     
        string m_Product_Description;  
        address m_who_have;        
        address m_send_to_who;     
        string m_hash;   
        
        uint256 m_moved_count;   
    }
    
    mapping (address => mapping (uint256 => Product_genuine)) public MyProducts;
    
    
     
    function WaraCoin() TokenERC20()  public 
    {
        sale_step = 0;   
        waracoin_corp = msg.sender;
    }
    
    function SetSaleStep(uint256 step) onlyOwner public
    {
        sale_step = step;
    }

     
    function () payable 
    {
        require(sale_step!=0);
        
        if ( msg.sender != owner )   
        {
            uint amount = 0;
            uint nowprice = 0;
            
            if ( sale_step == 1  )
                nowprice = 10000;    
            else
                if ( sale_step == 2 )
                    nowprice = 5000;     
                else
                    nowprice = 1000;     
                    
            amount = msg.value * nowprice; 
            
            require(balanceOf[waracoin_corp]>=amount);
            
            balanceOf[waracoin_corp] -= amount;
            balanceOf[msg.sender] += amount;                   
            require(waracoin_corp.send(msg.value));
            Transfer(this, msg.sender, amount);                
        }
    }

     
    function waraCoinTransfer(address _to, uint256 coin_amount) public
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[msg.sender] >= amount);          
        balanceOf[msg.sender] -= amount;                   
        balanceOf[_to] += amount;                   
        Transfer(msg.sender, _to, amount);                
    }

     
    function DestroyCoin(address _from, uint256 coin_amount) onlyOwner public 
    {
        uint256 amount = coin_amount * 10 ** uint256(decimals);

        require(balanceOf[_from] >= amount);          
        balanceOf[_from] -= amount;                   
        Transfer(_from, this, amount);                
    }    
    
     
    
     
    function registerNewProduct(uint256 product_idx,string new_guid,string product_descriptions,string hash) public returns(bool success)
    {
        uint256 amount = 1 * 10 ** uint256(decimals-2);        
        
        require(balanceOf[msg.sender]>=amount);    
        
        Product_genuine storage mine = MyProducts[msg.sender][product_idx];
        
        require(mine.m_made_from_who!=msg.sender);
        
        mine.m_made_from_who = msg.sender;
        mine.m_who_have = msg.sender;
        mine.m_Product_GUID = new_guid;
        mine.m_Product_Description = product_descriptions;
        mine.m_hash = hash;

        balanceOf[msg.sender] -= amount;
        return true;        
    }
    
       
    function setMoveProductToWhom(address who_made_this,uint256 product_idx,address moveto) public returns (bool success)
    {
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        
        require(mine.m_who_have==msg.sender);
        
        mine.m_send_to_who = moveto;

        return true;
    }
    
     
    function moveProduct(address who_made_this,address who_have_this,uint256 product_idx) public returns (bool success)
    {
        uint256 amount = 1 * 10 ** uint256(decimals-2);        

        require(balanceOf[msg.sender]>=amount);    
        
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        
        require(mine.m_who_have==who_have_this);     
        require(mine.m_send_to_who==msg.sender);     

        mine.m_who_have = msg.sender;
        mine.m_moved_count += 1;
        
        balanceOf[msg.sender] -= amount;
        
        return true;
    }

     
    function checkProductGenuine(address who_made_this,address who_have_this,uint256 product_idx) public returns (bool success)
    {
        success = false;
        
        Product_genuine storage mine = MyProducts[who_made_this][product_idx];
        if ( mine.m_who_have==who_have_this )     
            success = true;
            
        return success;
    }
    
}