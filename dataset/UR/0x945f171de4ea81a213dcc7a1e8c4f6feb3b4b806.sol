 

pragma solidity ^0.4.20;
contract tokenRecipient
  {
  function receiveApproval(address from, uint256 value, address token, bytes extraData) public; 
  }
contract ECP_Token  
  {
      
    string  public name;                                                         
    string  public symbol;                                                       
    uint8   public decimals;                                                     
    uint256 public totalSupply;                                                  
    uint256 public remaining;                                                    
    address public owner;                                                        
    uint    public icoStatus;                                                    
    address public benAddress;                                                   
    address public bkaddress;                                                    
    uint    public allowTransferToken;                                           

      
    mapping (address => uint256) public balanceOf;                               
    mapping (address => mapping (address => uint256)) public allowance;          
    mapping (address => bool) public frozenAccount;                              

     
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TokenTransferEvent(address indexed from, address indexed to, uint256 value, string typex);


      
    function ECP_Token() public
    {
      totalSupply = 15000000000000000000000000000;                               
      owner =  msg.sender;                                                       
      balanceOf[owner] = totalSupply;                                            
      name = "ECP Token";                                                        
      symbol = "ECP";                                                            
      decimals = 18;                                                             
      remaining = totalSupply;                                                   
      icoStatus = 1;                                                             
      benAddress = 0xe4a7a715bE044186a3ac5C60c7Df7dD1215f7419;
      bkaddress  = 0x44e00602e4B8F546f76983de2489d636CB443722;
      allowTransferToken = 1;                                                    
    }

   modifier onlyOwner()                                                          
    {
        require((msg.sender == owner) || (msg.sender ==  bkaddress));
        _;
    }


    function () public payable                                                   
    {
    }

    function sendToMultipleAccount (address[] dests, uint256[] values) public onlyOwner returns (uint256)  
    {
        uint256 i = 0;
        while (i < dests.length) {

                if(remaining > 0)
                {
                     _transfer(owner, dests[i], values[i]);   
                     TokenTransferEvent(owner, dests[i], values[i],'MultipleAccount');  
                }
                else
                {
                    revert();
                }

            i += 1;
        }
        return(i);
    }


    function sendTokenToSingleAccount(address receiversAddress ,uint256 amountToTransfer) public onlyOwner   
    {
        if (remaining > 0)
        {
                     _transfer(owner, receiversAddress, amountToTransfer);   
                     TokenTransferEvent(owner, receiversAddress, amountToTransfer,'SingleAccount');  
        }
        else
        {
            revert();
        }
    }


    function setTransferStatus (uint st) public  onlyOwner                       
    {
        allowTransferToken = st;
    }

    function changeIcoStatus (uint8 st)  public onlyOwner                        
    {
        icoStatus = st;
    }


    function withdraw(uint amountWith) public onlyOwner                          
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress))
            {
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }

    function withdraw_all() public onlyOwner                                     
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress) )
            {
                var amountWith = this.balance - 10000000000000000;
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }

    function mintToken(uint256 tokensToMint) public onlyOwner                    
        {
            if(tokensToMint > 0)
            {
                var totalTokenToMint = tokensToMint * (10 ** 18);                
                balanceOf[owner] += totalTokenToMint;                            
                totalSupply += totalTokenToMint;                                 
                remaining += totalTokenToMint;                                   
                Transfer(0, owner, totalTokenToMint);                            
            }
        }


	 function adm_trasfer(address _from,address _to, uint256 _value)  public onlyOwner  
		  {
			  _transfer(_from, _to, _value);
		  }


    function freezeAccount(address target, bool freeze) public onlyOwner         
        {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }


    function balanceOf(address _owner) public constant returns (uint256 balance)  
        {
            return balanceOf[_owner];
        }

    function totalSupply() private constant returns (uint256 tsupply)            
        {
            tsupply = totalSupply;
        }


    function transferOwnership(address newOwner) public onlyOwner                
        {
            balanceOf[owner] = 0;
            balanceOf[newOwner] = remaining;
            owner = newOwner;
        }

  function _transfer(address _from, address _to, uint _value) internal           
      {
          if(allowTransferToken == 1 || _from == owner )
          {
              require(!frozenAccount[_from]);                                    
              require (_to != 0x0);                                              
              require (balanceOf[_from] > _value);                               
              require (balanceOf[_to] + _value > balanceOf[_to]);                
              balanceOf[_from] -= _value;                                        
              balanceOf[_to] += _value;                                          
              Transfer(_from, _to, _value);                                      
          }
          else
          {
               revert();
          }
      }

  function transfer(address _to, uint256 _value)  public                         
      {
          _transfer(msg.sender, _to, _value);
      }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)  
      {
          require (_value < allowance[_from][msg.sender]);                       
          allowance[_from][msg.sender] -= _value;                                
          _transfer(_from, _to, _value);                                         
          return true;
      }

  function approve(address _spender, uint256 _value) public returns (bool success)  
      {
          allowance[msg.sender][_spender] = _value;
          return true;
      }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)  
      {
          tokenRecipient spender = tokenRecipient(_spender);
          if (approve(_spender, _value)) {
              spender.receiveApproval(msg.sender, _value, this, _extraData);
              return true;
          }
      }

  function burn(uint256 _value) public returns (bool success)                    
      {
          require (balanceOf[msg.sender] > _value);                              
          balanceOf[msg.sender] -= _value;                                       
          totalSupply -= _value;                                                 
          remaining -= _value;                                                   
          Burn(msg.sender, _value);                                              
          return true;
      }

  function burnFrom(address _from, uint256 _value) public returns (bool success)  
      {
          require(balanceOf[_from] >= _value);                                   
          require(_value <= allowance[_from][msg.sender]);                       
          balanceOf[_from] -= _value;                                            
          allowance[_from][msg.sender] -= _value;                                
          totalSupply -= _value;                                                 
          remaining -= _value;                                                   
          Burn(_from, _value);
          return true;
      }
}  