 

pragma solidity ^0.4.26;

 
interface tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }



   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }




   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }



   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}




contract Ownable {

  address public owner; 
  address public COO;  
  address public CTO;  

 
  event OwnershipTransferred(address indexed _owner, address indexed _newAddress);
 
  event COOTransferred(address indexed _COO, address indexed _newAddress);
 
  event CTOTransferred(address indexed _CTO, address indexed _newAddress);

   
  event OwnershipRenounced(address indexed previousOwner);


   
  constructor() public {
    owner = msg.sender;   
    COO = msg.sender;     
    CTO = msg.sender;     
  }




   
      modifier onlyOwner() {
        require(msg.sender == owner);   
        _;   
      }


      modifier onlyCOO() {
         
        require(msg.sender == COO);
        _;   
      }


      modifier onlyCTO() {
         
        require(msg.sender == CTO);
        _;   
      }


   

   function transferAddress(address _newAddress,uint _type) public onlyOwner returns (bool) {
     require(_newAddress != address(0) && _type > 0  && _type < 4);                 
         if( _type == 1 ){
               owner = _newAddress;                               
               emit OwnershipTransferred(owner, _newAddress);     
         }
         if ( _type == 2 ){
              COO = _newAddress;                               
              emit COOTransferred(COO, _newAddress);           
         }
         if( _type == 3 ){
              CTO = _newAddress;                               
              emit CTOTransferred(CTO, _newAddress);            
         }
         return true;
   }



 
  function renounceOwnership() public onlyOwner returns (bool){
    owner = address(0);    
    emit OwnershipRenounced(owner);    

    return true;
    }


}








contract TokenERC20 is Ownable {

   
  using SafeMath for uint256;    

  string public name;
  string public symbol;
  uint8 public decimals = 1;    
  uint256 public totalSupply;   

  mapping (address => uint256) public balanceOf;   
  mapping (address => mapping (address => uint256)) public allowance;   
  mapping (address => bool) public frozenAccount;   


 
    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Approval(address indexed owner, address indexed spender, uint256 value);   
    event Burn(address indexed from, uint256 value);   
    event FrozenFunds(address target, bool frozen);   






 
  constructor(uint256 _totalSupply,string _name,string tokenSymbol) public {
      totalSupply = _totalSupply * 10 ** uint256(decimals);   
      balanceOf[msg.sender] = totalSupply;                 
      name = _name;                                    
      symbol = tokenSymbol;                                
  }








 
 
   function _transfer(address _from, address _to, uint _value) internal  returns (bool) {
         require(_to != address(0));                     
         require(_value <= balanceOf[_from]);             

         balanceOf[_from] = balanceOf[_from].sub(_value);  
         balanceOf[_to] = balanceOf[_to].add(_value);      

         emit Transfer(_from, _to, _value);              
         return true;
       }

 
    function transfer(address _to, uint256 _value) public returns (bool){
            
           require( _transfer(msg.sender, _to, _value) );
           return true;
         }

 







 
 
    function _approve(address _spender, uint256 _value) internal returns (bool) {
           allowance[msg.sender][_spender] = _value;
           emit Approval(msg.sender, _spender, _value);
           return true;
         }

 
    function approve(address _to, uint256 _value) public returns (bool){
            
           require( _approve(_to, _value) );
           return true;
        }


 



 
        function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
            
            require(_to != address(0)  && _value <= balanceOf[_from] && _value <= allowance[_from][msg.sender]);

            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);   
            require( _transfer(_from, _to, _value) );  

            emit Transfer(_from, _to, _value);
            return true;
          }

          function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
                 
                require( _transferFrom(_from,_to,_value) );
                return true;
             }

 






 
 
      function _increaseApproval(address _spender, uint _addedValue) internal returns (bool) {
         allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue); 

         emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
         return true;
         }

      function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
             
            require( _increaseApproval(_spender,_addedValue) );
            return true;
         }


 
      function _decreaseApproval(address _spender, uint _subtractedValue) internal returns (bool) {

          uint oldValue = allowance[msg.sender][_spender];  

          if (_subtractedValue > oldValue) {       
                 allowance[msg.sender][_spender] = 0;      
           } else {
                 allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);   
           }

           emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]); 
           return true;
         }

       function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
              
             require( _decreaseApproval(_spender,_subtractedValue) );
             return true;
         }
 





 
 
         function _burn(address _who, uint256 _value) internal returns (bool){
              require(_value <= balanceOf[_who]);   

              balanceOf[_who] = balanceOf[_who].sub(_value);    
              totalSupply = totalSupply.sub(_value);        

              emit Burn(_who, _value);                        
              emit Transfer(_who, address(0), _value);        
              return true;
             }
 
        function burn(uint256 _value) public returns (bool) {
               
              require( _burn(msg.sender, _value) );
              return true;
             }




 
 
         function _burnFrom(address _from, uint256 _value) internal returns (bool){
               require(_value <= allowance[_from][msg.sender]);   
                
               allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
                
               require( _burn(_from, _value) );   
               return true;
           }

 
          function burnFrom(address _from, uint256 _value) public returns (bool) {
                
               require( _burnFrom(_from,_value) );
               return true;
           }


 





 
 
     function _mintToken(address target, uint256 mintedAmount) onlyOwner internal returns (bool) {
          
            totalSupply = totalSupply.add(mintedAmount);        
            balanceOf[target] = balanceOf[target].add(mintedAmount);   

            emit Transfer(0, this, mintedAmount);        
            emit Transfer(this, target, mintedAmount);   
            return true;
         }

 
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public returns (bool) {
             
            require( _mintToken(_target,_mintedAmount) );
            return true;
         }




 





 
 
     function _freezeAccount(address target, bool freeze) onlyCTO internal  returns (bool) {
           frozenAccount[target] = freeze;      
           emit  FrozenFunds(target, freeze);
           return true;
        }

 
     function freezeAccount(address _target, bool _freeze) onlyCTO public returns (bool) {
            
           require( _freezeAccount(_target,_freeze) );
           return true;
        }



 









 
 
 
 
   function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
            
           require(_spender != address(this));    

           tokenRecipient spender = tokenRecipient(_spender);  
           if (approve(_spender, _value)) {   
               spender.receiveApproval(msg.sender, _value, this, _extraData);
               return true;
           }
       }




 






  }