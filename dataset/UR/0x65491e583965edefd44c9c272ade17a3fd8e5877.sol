 

pragma solidity ^0.4.18;


 
contract Buyable {
  function buy (address receiver) public payable;
}

  
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract TokenAdrTokenSaleProxy is Ownable {

   
  Buyable public targetContract;

   
  uint public buyGasLimit = 200000;

   
  bool public stopped = false;

   
  uint public totalWeiVolume = 0;

   
   
  function TokenAdrTokenSaleProxy(address _targetAddress) public {
    require(_targetAddress > 0);
    targetContract = Buyable(_targetAddress);
  }

   
  function() public payable {
    require(msg.value > 0);
    require(!stopped);
    totalWeiVolume += msg.value;
    targetContract.buy.value(msg.value).gas(buyGasLimit)(msg.sender);
  }

   
   
  function changeTargetAddress(address newTargetAddress) public onlyOwner {
    require(newTargetAddress > 0);
    targetContract = Buyable(newTargetAddress);
  }

   
   
  function changeGasLimit(uint newGasLimit) public onlyOwner {
    require(newGasLimit > 0);
    buyGasLimit = newGasLimit;
  }

   
  function stop() public onlyOwner {
    require(!stopped);
    stopped = true;
  }

   
  function resume() public onlyOwner {
    require(stopped);
    stopped = false;
  }
}