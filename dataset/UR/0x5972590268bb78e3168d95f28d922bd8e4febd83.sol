 

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

contract token { function transfer(address receiver, uint amount) external; }

contract DistributeEth is Ownable{
  event Message(string message);
  
  token tokenReward;
  
  address public addressOfTokenUsedAsReward;
  function setTokenReward(address _addr) public onlyOwner {
    tokenReward = token(_addr);
    addressOfTokenUsedAsReward = _addr;
  }
  
  function distributeTokens(address[] _addrs, uint[] _bals,string message) public onlyOwner{
		emit Message(message);
		for(uint i = 0; i < _addrs.length; ++i){
			tokenReward.transfer(_addrs[i],_bals[i]);
		}
	}
  
  function distributeEth(address[] _addrs, uint[] _bals, string message) public onlyOwner {
    for(uint i = 0; i < _addrs.length; ++i) {
        _addrs[i].transfer(_bals[i]);
    }
    emit Message(message);
  }
  
   
  function () payable public {}

  function withdrawEth(uint _value) public onlyOwner {
    owner.transfer(_value);
  }
  
  function withdrawTokens(uint _amount) public onlyOwner {
	tokenReward.transfer(owner,_amount);
  }
}