 

pragma solidity ^0.4.13; 
contract Owned { 
    address public owner;
    function Owned() {
      owner = msg.sender;
  }

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
      owner = newOwner;
  }
}

contract Token {
      
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public totalSupply;      
         
    mapping (address => uint256) public balanceOf;
  
   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  event Burn(address indexed from, uint256 value);

   
  function Token(
      uint256 initialSupply,
      string tokenName,
      uint8 decimalUnits,
      string tokenSymbol
      ) {
      balanceOf[msg.sender] = initialSupply;               
      totalSupply = initialSupply;                         
      name = tokenName;                                    
      symbol = tokenSymbol;                                
      decimals = decimalUnits;                             
  }

   
  function _transfer(address _from, address _to, uint _value) internal {
      require (_to != 0x0);                                
      require (balanceOf[_from] >= _value);                 
      require (balanceOf[_to] + _value > balanceOf[_to]);  
      balanceOf[_from] -= _value;                          
      balanceOf[_to] += _value;                             
      Transfer(_from, _to, _value);
  }

   
   
   
  function transfer(address _to, uint256 _value) {       
      _transfer(msg.sender, _to, _value);
  }
    
   
   
  function burn(uint256 _value) returns (bool success) {
      require (balanceOf[msg.sender] >= _value);             
      balanceOf[msg.sender] -= _value;                       
      totalSupply -= _value;                                 
      Burn(msg.sender, _value);
      return true;
  } 
}

contract BiteduToken is Owned, Token {  
  mapping (address => bool) public frozenAccount;

   
  event FrozenFunds(address target, bool frozen);

   
  function BiteduToken() Token (29000000, "BITEDU", 0, "BTEU") {
      
  }

  
  function _transfer(address _from, address _to, uint _value) internal {      
      require (_to != 0x0);                                
      require (balanceOf[_from] >= _value);                 
      require (balanceOf[_to] + _value > balanceOf[_to]);  
      require(!frozenAccount[_from]);                      
      require(!frozenAccount[_to]);                        
      balanceOf[_from] -= _value;                          
      balanceOf[_to] += _value;                            
      Transfer(_from, _to, _value);
  }

   
  function _transferFrom(address _from, address _to, uint256 _value) internal {            
      require (_to != 0x0);                                
      require (balanceOf[_from] >= _value);                 
      require (balanceOf[_to] + _value > balanceOf[_to]);  
      require(!frozenAccount[_from]);                      
      require(!frozenAccount[_to]);                        
      balanceOf[_from] -= _value;                          
      balanceOf[_to] += _value;                            
      Transfer(_from, _to, _value);
  }
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {                   
      _transferFrom(_from, _to, _value);
      return true;
  }
   
   
   
  function mintToken(address target, uint256 mintedAmount) onlyOwner {
      balanceOf[target] += mintedAmount;
      totalSupply += mintedAmount;
      Transfer(0, this, mintedAmount);
      Transfer(this, target, mintedAmount);
  }
   
   
   
  function freezeAccount(address target, bool freeze) onlyOwner {
      frozenAccount[target] = freeze;
      FrozenFunds(target, freeze);
  }  
   
}