 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  uint256 public totalSupply;
  uint8 public decimals;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
}


 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Exchange is Ownable {
  mapping (address => bool) public supportedTokens;
  event ExchangeEvent(address tokenToSell, address tokenToBuy, uint256 value);
  
  function setSupportedTokens(address tokenAddress, bool op) onlyOwner public {
    supportedTokens[tokenAddress] = op;
  }
  
     
  function exchangeERC20(address _tokenToSell, address _tokenToBuy, uint256 _value) {
    require(supportedTokens[_tokenToSell]);
    require(supportedTokens[_tokenToBuy]);
    require(_tokenToSell != _tokenToBuy);
    
    ERC20Basic tokenToSell = ERC20Basic(_tokenToSell);
    ERC20Basic tokenToBuy = ERC20Basic(_tokenToBuy);

    require(_value > 0 && tokenToBuy.balanceOf(address(this)) >= _value);

    if (!tokenToSell.transferFrom(msg.sender, address(this), _value)) throw;
    tokenToBuy.transfer(msg.sender, _value);
  
    ExchangeEvent(_tokenToSell,_tokenToBuy,_value);
  }
}