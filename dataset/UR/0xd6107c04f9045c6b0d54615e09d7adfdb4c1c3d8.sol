 

pragma solidity 0.4.18;
 
 contract FAMELINK{

     string public name;  
     string public symbol;  
     uint8 public decimals = 18;   
     uint256 public totalSupply;  
      
     mapping (address => uint256) public balanceOf;

     event Transfer(address indexed from, address indexed to, uint256 value);   


      
     function FAMELINK(uint256 initialSupply,address _owned, string tokenName, string tokenSymbol) public{
          totalSupply = initialSupply * 10 ** uint256(decimals);   
          
         balanceOf[_owned] = totalSupply;
         name = tokenName;
         symbol = tokenSymbol;

     }
     

      
     function transfer(address _to, uint256 _value) public{
        
       balanceOf[msg.sender] -= _value;

        
       balanceOf[_to] += _value;

        
       Transfer(msg.sender, _to, _value);
     }


  }