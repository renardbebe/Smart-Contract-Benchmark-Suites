 

pragma solidity ^0.4.0;

 

contract Ownable {

  address public owner;





  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





   

  function Ownable () public {owner = msg.sender;

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



contract token {function transfer (address receiver, uint _amount) public { } }



contract Distribute is Ownable{

  

    token tokenReward = token(0xdd007278B667F6bef52fD0a4c23604aA1f96039a);



  function register(address[] _addrs) public onlyOwner{

    for(uint i = 0; i < _addrs.length; ++i){

      tokenReward.transfer(_addrs[i],500*10**8);

    }

  }



  function withdraw(uint _amount) public onlyOwner {

    tokenReward.transfer(owner,_amount);

  }

}