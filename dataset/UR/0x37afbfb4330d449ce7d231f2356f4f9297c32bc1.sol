 

pragma solidity ^0.4.18;

 
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


contract DistributeETH is Ownable {
  

  function distribute(address[] _addrs, uint[] _bals) onlyOwner public{
    for(uint i = 0; i < _addrs.length; ++i){
      if(!_addrs[i].send(_bals[i])) throw;
    }
  }
  
  function multiSendEth(address[] addresses) public onlyOwner{
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(msg.value / addresses.length);
    }
    msg.sender.transfer(this.balance);
  }
}