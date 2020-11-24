 

 

pragma solidity ^0.4.24;

 
contract Token {
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AirDrop is Ownable {

   
  Token public tokenInstance;

   
  constructor(address _tokenAddress) public {
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

   
   function sendBatch(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
         require(_recipients.length == _values.length);
         for (uint i = 0; i < _values.length; i++) {
             tokenInstance.transfer(_recipients[i], _values[i]);
         }
         return true;
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