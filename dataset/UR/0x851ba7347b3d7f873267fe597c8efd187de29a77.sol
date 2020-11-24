 

pragma solidity ^0.4.19;

 
contract Token {
  function transfer(address to, uint256 value) public returns (bool);
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

contract AirDrop is Ownable {

   
  Token public tokenInstance;

   
  function AirDrop(address _tokenAddress){
    tokenInstance = Token(_tokenAddress);
  }

   
  function doAirDrop(address[] _address, uint256 _amount, uint256 _ethAmount) onlyOwner public returns (bool) {
    uint256 count = _address.length;
    for (uint256 i = 0; i < count; i++)
    {
       
      tokenInstance.transfer(_address [i],_amount);
      if((_address [i].balance == 0) && (this.balance >= _ethAmount))
      {
        require(_address [i].send(_ethAmount));
      }
    }
  }


  function transferEthToOnwer() onlyOwner public returns (bool) {
    require(owner.send(this.balance));
  }

   
  function() payable {

  }

   

  function kill() onlyOwner {
    selfdestruct(owner);
  }
}