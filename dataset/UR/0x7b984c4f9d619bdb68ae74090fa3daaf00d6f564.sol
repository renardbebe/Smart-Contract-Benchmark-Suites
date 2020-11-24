 

pragma solidity ^0.4.11;

contract KolkhaToken {
   
  mapping (address => uint) public balanceOf;            
  string  public constant name = "Kolkha";          
  string public constant symbol = "KHC";                 
  uint8 public constant decimals = 6;
  uint public totalSupply;                               

  event Transfer(address indexed from, address indexed to, uint value);  
   

  function KolkhaToken(uint initSupply) {
    balanceOf[msg.sender] = initSupply;
    totalSupply = initSupply;
  }


   
  function transfer(address _to, uint _value) returns (bool)
  {
    assert(msg.data.length == 2*32 + 4);
    require(balanceOf[msg.sender] >= _value);  
    require(balanceOf[_to] + _value >= balanceOf[_to]);  

     
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;

    Transfer(msg.sender, _to, _value);  
    return true;
  }
}