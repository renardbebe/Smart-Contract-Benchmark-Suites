 

pragma solidity ^0.4.11;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


   contract StudioToken  {
       
       using SafeMath for uint256;
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
   
    address public owner;
    bool public pauseForDividend = false;
    
    
    

     
    mapping (address => uint256) public balanceOf;
    mapping ( uint => address ) public accountIndex;
    uint accountCount;
    
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function StudioToken(
       ) {
            
       uint256 initialSupply = 50000000;
        uint8 decimalUnits = 0;   
        appendTokenHolders ( msg.sender );    
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = "Studio";                                    
        symbol = "STDO";                                
        decimals = decimalUnits;                             
        
        owner = msg.sender;
    }
    
    function getBalance ( address tokenHolder ) returns (uint256) {
        return balanceOf[ tokenHolder ];
    }
    
    
    function getAccountCount ( ) returns (uint256) {
        return accountCount;
    }
    
    
    function getAddress ( uint256 slot ) returns ( address ) {
        return accountIndex[ slot ];
    }
    
    function getTotalSupply ( ) returns (uint256) {
        return totalSupply;
    }
    
    
   
    
   
    function appendTokenHolders ( address tokenHolder ) private {
        
        if ( balanceOf[ tokenHolder ] == 0 ){ 
            accountIndex[ accountCount ] = tokenHolder;
            accountCount++;
        }
        
    }
    

     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                                
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (  pauseForDividend == true ) throw; 
        appendTokenHolders ( _to);
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                 
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;      
        if (  pauseForDividend == true ) throw; 
        balanceOf[_from] -= _value;                            
        balanceOf[_to] += _value;                              
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;             
        balanceOf[msg.sender] -= _value;                       
        totalSupply -= _value;                                 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 
        if (_value > allowance[_from][msg.sender]) throw;     
        balanceOf[_from] -= _value;                           
        totalSupply -= _value;                                
        Burn(_from, _value);
        return true;
    }
    
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    
    
    function pauseForDividend() onlyOwner{
        
        if ( pauseForDividend == true ) pauseForDividend = false; else pauseForDividend = true;
        
    }
    
    
    
    
    
    
    function transferOwnership ( address newOwner) onlyOwner {
        
        owner = newOwner;
        
        
    }
    
    
    
    
}


contract Dividend {
    StudioToken studio;  
    address studio_contract;
   
  
    uint public accountCount;
    event Log(uint);
    address owner;


    uint256 public ether_profit;
    uint256 public profit_per_token;
    uint256 holder_token_balance;
    uint256 holder_profit;
    
    
    
     mapping (address => uint256) public balanceOf;
    
    
    event Message(uint256 holder_profit);
    event Transfer(address indexed_from, address indexed_to, uint value);

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
     
    function Dividend(address Studiocontract) {
        owner = msg.sender;
        studio = StudioToken(Studiocontract);
    }
     
    function() payable {
       
        studio.pauseForDividend();

        accountCount = studio.getAccountCount();
        
          Log(accountCount);

            ether_profit = msg.value;

            profit_per_token = ether_profit / studio.getTotalSupply();

            Message(profit_per_token);
        
        
        if (msg.sender == owner) {
            
            for ( uint i=0; i < accountCount ; i++ ) {
               
               address tokenHolder = studio.getAddress(i);
               balanceOf[ tokenHolder ] +=  studio.getBalance( tokenHolder ) * profit_per_token;
        
            }
            
          

          
            
        }
        
        
         studio.pauseForDividend();
    }
    
    
    
    function withdrawDividends (){
        
        
        msg.sender.transfer(balanceOf[ msg.sender ]);
        balanceOf[ msg.sender ] = 0;
        
        
    }
    
  
    


}