 

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

 
contract ModulumInvestorsWhitelist is Ownable {

  mapping (address => bool) public isWhitelisted;

   
  function ModulumInvestorsWhitelist() {
  }

   
  function addInvestorToWhitelist(address _address) public onlyOwner {
    require(_address != 0x0);
    require(!isWhitelisted[_address]);
    isWhitelisted[_address] = true;
  }

   
  function removeInvestorFromWhiteList(address _address) public onlyOwner {
    require(_address != 0x0);
    require(isWhitelisted[_address]);
    isWhitelisted[_address] = false;
  }

   
  function isInvestorInWhitelist(address _address) constant public returns (bool result) {
    return isWhitelisted[_address];
  }
}