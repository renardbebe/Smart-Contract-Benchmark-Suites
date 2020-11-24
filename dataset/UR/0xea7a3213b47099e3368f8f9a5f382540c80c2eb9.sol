 

pragma solidity ^0.4.17;
contract tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData); }
contract JaxBox
  { 
      
    string  public name;          
    string  public symbol;        
    uint8   public decimals;      
    uint256 public totalSupply;  
    uint256 public remaining;    
    uint256 public ethRate;      
    address public owner;        
    uint256 public amountCollected;  
    uint8   public icoStatus;
    uint8   public icoTokenPrice;
    address public benAddress;
    
      
    mapping (address => uint256) public balanceOf;  
    mapping (address => uint256) public investors;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
     
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex);  
    

      
    function JaxBox() 
    {
      totalSupply = 10000000000000000000000000000;  
      owner =  msg.sender;                       
      balanceOf[owner] = totalSupply;            
      totalSupply = totalSupply;                 
      name = "JaxBox";                      
      symbol = "JBC";                        
      decimals = 18;                             
      remaining = totalSupply;
      ethRate = 300;
      icoStatus = 1;
      icoTokenPrice = 10;  
      benAddress = 0x57D1aED65eE1921CC7D2F3702C8A28E5Dd317913;
    }

   modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    function ()  payable 
    {
        if (remaining > 0 && icoStatus == 1 )
        {
            uint  finalTokens =  ((msg.value / 10 ** 16) * ((ethRate * 10 ** 2) / icoTokenPrice)) / 10 ** 2;
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    amountCollected = amountCollected + (msg.value / 10 ** 18);
                    _transfer(owner,msg.sender, finalTokens); 
                    TransferSell(owner, msg.sender, finalTokens,'Online');
                }
            else
                {
                    throw;
                }
        }
        else
        {
            throw;
        }
    }    
    
    function sellOffline(address rec_address,uint256 token_amount) onlyOwner 
    {
        if (remaining > 0)
        {
            uint finalTokens =  (token_amount  * (10 ** 18));  
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    _transfer(owner,rec_address, finalTokens);    
                    TransferSell(owner, rec_address, finalTokens,'Offline');
                }
            else
                {
                    throw;
                }
        }
        else
        {
            throw;
        }        
    }
    
    function getEthRate() onlyOwner constant returns  (uint)  
    {
        return ethRate;
    }
    
    function setEthRate (uint newEthRate)   onlyOwner  
    {
        ethRate = newEthRate;
    } 


    function getTokenPrice() onlyOwner constant returns  (uint8)  
    {
        return icoTokenPrice;
    }
    
    function setTokenPrice (uint8 newTokenRate)   onlyOwner  
    {
        icoTokenPrice = newTokenRate;
    }     
    
    

    
    function changeIcoStatus (uint8 statx)   onlyOwner  
    {
        icoStatus = statx;
    } 
    
    
    function withdraw(uint amountWith) onlyOwner  
        {
            if(msg.sender == owner)
            {
                if(amountWith > 0)
                    {
                        amountWith = (amountWith * 10 ** 18);  
                        benAddress.send(amountWith);
                    }
            }
            else
            {
                throw;
            }
        }

    function withdraw_all() onlyOwner  
        {
            if(msg.sender == owner)
            {
                benAddress.send(this.balance);
                 
            }
            else
            {
                throw;
            }
        }

    function mintToken(uint256 tokensToMint) onlyOwner 
        {
            var totalTokenToMint = tokensToMint * (10 ** 18);
            balanceOf[owner] += totalTokenToMint;
            totalSupply += totalTokenToMint;
            Transfer(0, owner, totalTokenToMint);
        }

    function freezeAccount(address target, bool freeze) onlyOwner 
        {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
            

    function getCollectedAmount() constant returns (uint256 balance) 
        {
            return amountCollected;
        }        

    function balanceOf(address _owner) constant returns (uint256 balance) 
        {
            return balanceOf[_owner];
        }

    function totalSupply() constant returns (uint256 tsupply) 
        {
            tsupply = totalSupply;
        }    


    function transferOwnership(address newOwner) onlyOwner 
        { 
            balanceOf[owner] = 0;                        
            balanceOf[newOwner] = remaining;               
            owner = newOwner; 
        }        

   
  function _transfer(address _from, address _to, uint _value) internal 
      {
          require(!frozenAccount[_from]);                      
          require (_to != 0x0);                                
          require (balanceOf[_from] > _value);                 
          require (balanceOf[_to] + _value > balanceOf[_to]);  
          balanceOf[_from] -= _value;                          
          balanceOf[_to] += _value;                             
          Transfer(_from, _to, _value);
      }


  function transfer(address _to, uint256 _value) 
      {
          _transfer(msg.sender, _to, _value);
      }

   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) 
      {
          require (_value < allowance[_from][msg.sender]);      
          allowance[_from][msg.sender] -= _value;
          _transfer(_from, _to, _value);
          return true;
      }

   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) 
      {
          allowance[msg.sender][_spender] = _value;
          return true;
      }

   
   
   
   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success)
      {
          tokenRecipient spender = tokenRecipient(_spender);
          if (approve(_spender, _value)) {
              spender.receiveApproval(msg.sender, _value, this, _extraData);
              return true;
          }
      }        

   
   
  function burn(uint256 _value) returns (bool success) 
      {
          require (balanceOf[msg.sender] > _value);             
          balanceOf[msg.sender] -= _value;                       
          totalSupply -= _value;                                 
          Burn(msg.sender, _value);
          return true;
      }

  function burnFrom(address _from, uint256 _value) returns (bool success) 
      {
          require(balanceOf[_from] >= _value);                 
          require(_value <= allowance[_from][msg.sender]);     
          balanceOf[_from] -= _value;                          
          allowance[_from][msg.sender] -= _value;              
          totalSupply -= _value;                               
          Burn(_from, _value);
          return true;
      }
}  