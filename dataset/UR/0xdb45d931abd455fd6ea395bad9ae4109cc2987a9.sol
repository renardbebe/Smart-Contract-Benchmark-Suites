 

pragma solidity ^0.4.24;
 
contract Ownable {
  address public owner;
 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
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

interface token { function transfer(address, uint) external; }

contract DistributeTokens is Ownable{
  
  token tokenReward;
  address public addressOfTokenUsedAsReward;
  function setTokenReward(address _addr) public onlyOwner {
    tokenReward = token(_addr);
    addressOfTokenUsedAsReward = _addr;
  }

  function distributeVariable(address[] _addrs, uint[] _bals) public onlyOwner{
    for(uint i = 0; i < _addrs.length; ++i){
      tokenReward.transfer(_addrs[i],_bals[i]);
    }
  }

  function distributeFixed(address[] _addrs, uint _amoutToEach) public onlyOwner{
    for(uint i = 0; i < _addrs.length; ++i){
      tokenReward.transfer(_addrs[i],_amoutToEach);
    }
  }

  function withdrawTokens(uint _amount) public onlyOwner {
    tokenReward.transfer(owner,_amount);
  }
}