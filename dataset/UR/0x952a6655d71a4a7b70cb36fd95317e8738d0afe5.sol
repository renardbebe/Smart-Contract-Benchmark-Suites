 

pragma solidity ^0.4.24;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }


}





contract owned {  
  address public owner;

  function owned() public {
  owner = msg.sender;
  }

  modifier onlyOwner {
  require(msg.sender == owner);
  _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
  owner = newOwner;
  }
}


contract TokenERC20 {

using SafeMath for uint256;
 
string public name;
string public symbol;
uint8 public decimals = 18;
 
uint256 public totalSupply;


 
mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;

 
event Transfer(address indexed from, address indexed to, uint256 value);

 
event Burn(address indexed from, uint256 value);

 
function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
  totalSupply = initialSupply * 10 ** uint256(decimals);   
  balanceOf[msg.sender] = totalSupply;                 
  name = tokenName;                                    
  symbol = tokenSymbol;                                
}

 
function _transfer(address _from, address _to, uint _value) internal {
   
  require(_to != 0x0);
   
   
  balanceOf[_from] = balanceOf[_from].sub(_value);
   
  balanceOf[_to] = balanceOf[_to].add(_value);
  emit Transfer(_from, _to, _value);
}

 
function transfer(address _to, uint256 _value) public {
  _transfer(msg.sender, _to, _value);
}

 
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
  allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
  _transfer(_from, _to, _value);
  return true;
}

 
function approve(address _spender, uint256 _value) public returns (bool success) {
  allowance[msg.sender][_spender] = _value;
  return true;
}


 
function burn(uint256 _value) public returns (bool success) {
  balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
  totalSupply = totalSupply.sub(_value);                       
  emit Burn(msg.sender, _value);
  return true;
}



 
function burnFrom(address _from, uint256 _value) public returns (bool success) {
  balanceOf[_from] = balanceOf[_from].sub(_value);                          
  allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);              
  totalSupply = totalSupply.sub(_value);                               
  emit Burn(_from, _value);
  return true;
}


}

 
 
 

contract AccommodationCoin is owned, TokenERC20  {

   
  uint256 _initialSupply=100000000; 
  string _tokenName="Accommodation Coin";  
  string _tokenSymbol="ACC";

  mapping (address => bool) public frozenAccount;

   
  event FrozenFunds(address target, bool frozen);

   
  function AccommodationCoin( ) TokenERC20(_initialSupply, _tokenName, _tokenSymbol) public {}

   
  function _transfer(address _from, address _to, uint _value) internal {
    require (_to != 0x0);                                
    require(!frozenAccount[_from]);                      
    require(!frozenAccount[_to]);                        
    balanceOf[_from] = balanceOf[_from].sub(_value);                          
    balanceOf[_to] = balanceOf[_to].add(_value);                            
    emit Transfer(_from, _to, _value);
  }

   
   
   
  function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    balanceOf[target] = balanceOf[target].add(mintedAmount);
    totalSupply = totalSupply.add(mintedAmount);
    emit Transfer(0, this, mintedAmount);
    emit Transfer(this, target, mintedAmount);
  }

  function freezeAccount(address target, bool freeze) onlyOwner public {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }



}