 

pragma solidity ^0.4.2;

 
contract owned {

    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function ownerTransferOwnership(address newOwner)
        onlyOwner
    {
        owner = newOwner;
    }

}

 
contract DSSafeAddSub {

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
    
    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) throw;
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) throw;
        return a - b;
    } 

}


  


contract EtherollToken is owned, DSSafeAddSub {

     
    modifier onlyBy(address _account) {
        if (msg.sender != _account) throw;
        _;
    }    

     
    string public standard = 'Token 1.0';
    string public name = "DICE";
    string public symbol = "ROL";
    uint8 public decimals = 16;
    uint public totalSupply = 250000000000000000000000; 

    address public priviledgedAddress;  
    bool public tokensFrozen;
    uint public crowdfundDeadline = now + 2 * 1 weeks;       
    uint public nextFreeze = now + 12 * 1 weeks;
    uint public nextThaw = now + 13 * 1 weeks;
   

     
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;  

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogTokensFrozen(bool indexed Frozen);    

       
    function EtherollToken(){
         
        balanceOf[msg.sender] = 250000000000000000000000;
           
        tokensFrozen = false;                                      

    }  

          
    function transfer(address _to, uint _value) public
        returns (bool success)    
    {
        if(tokensFrozen && msg.sender != priviledgedAddress) return false;   
        if (balanceOf[msg.sender] < _value) return false;                    
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;                        
        balanceOf[msg.sender] -=  _value;                                    
        balanceOf[_to] += _value;                                            
        Transfer(msg.sender, _to, _value);                                   
        return true;
    }      

            
    function transferFrom(address _from, address _to, uint _value) public
        returns (bool success) 
    {                
        if(tokensFrozen && msg.sender != priviledgedAddress) return false;   
        if (balanceOf[_from] < _value) return false;                         
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;                          
        if (_value > allowance[_from][msg.sender]) return false;             
        balanceOf[_from] -= _value;                                          
        balanceOf[_to] += _value;                                            
        allowance[_from][msg.sender] -= _value;                              
        Transfer(_from, _to, _value);                                        
        return true;
    }        
 
           
    function approve(address _spender, uint _value) public
        returns (bool success)
    {
         
        allowance[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);        
        return true;
    } 
  
          
    function priviledgedAddressBurnUnsoldCoins() public
         
        onlyBy(priviledgedAddress)
    {
         
        totalSupply = safeSub(totalSupply, balanceOf[priviledgedAddress]); 
         
        balanceOf[priviledgedAddress] = 0;
    }

              
    function updateTokenStatus() public
    {
        
         
        if(now < crowdfundDeadline){                       
            tokensFrozen = true;         
            LogTokensFrozen(tokensFrozen);  
        }  

         
        if(now >= nextFreeze){          
            tokensFrozen = true;
            LogTokensFrozen(tokensFrozen);  
        }

         
        if(now >= nextThaw){         
            tokensFrozen = false;
            nextFreeze = now + 12 * 1 weeks;
            nextThaw = now + 13 * 1 weeks;              
            LogTokensFrozen(tokensFrozen);  
        }        
      
    }                              

           
    function ownerSetPriviledgedAddress(address _newPriviledgedAddress) public 
        onlyOwner
    {
        priviledgedAddress = _newPriviledgedAddress;
    }   
                    
    
}