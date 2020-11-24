 

pragma solidity ^0.4.19;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    assert(c >= a);
    return c;
  }
}


contract StinkyLinky {
   
   
  
   
  address ceoAddress = 0xC0c8Dc6C1485060a72FCb629560371fE09666500;
  struct Sergey {
    address currentStinkyLinky;
    uint256 currentValue;
   
  }
  Sergey[32] data;
  
   
  function StinkyLinky() public {
    for (uint i = 0; i < 32; i++) {
     
      data[i].currentValue = 15000000000000000;
      data[i].currentStinkyLinky = msg.sender;
    }
  }

   
   
  function payPreviousOwner(address previousHeroOwner, uint256 currentValue) private {
    previousHeroOwner.transfer(currentValue);
  }
   
   
  function transactionFee(address, uint256 currentValue) private {
    ceoAddress.transfer(currentValue);
  }
   
   
   
  function purchaseCollectible(uint uniqueCollectibleID) public payable returns (uint, uint) {
    require(uniqueCollectibleID >= 0 && uniqueCollectibleID <= 31);
     
    if ( data[uniqueCollectibleID].currentValue == 15000000000000000 ) {
      data[uniqueCollectibleID].currentValue = 30000000000000000;
    } else {
       
      data[uniqueCollectibleID].currentValue = data[uniqueCollectibleID].currentValue * 2;
    }
    
    require(msg.value >= data[uniqueCollectibleID].currentValue * uint256(1));
     
    payPreviousOwner(data[uniqueCollectibleID].currentStinkyLinky,  (data[uniqueCollectibleID].currentValue / 10) * (9)); 
    transactionFee(ceoAddress, (data[uniqueCollectibleID].currentValue / 10) * (1));
     
    data[uniqueCollectibleID].currentStinkyLinky = msg.sender;
     
    return (uniqueCollectibleID, data[uniqueCollectibleID].currentValue);

  }
   
  function getCurrentStinkyLinkys() external view returns (address[], uint256[]) {
    address[] memory currentStinkyLinkys = new address[](32);
    uint256[] memory currentValues =  new uint256[](32);
    for (uint i=0; i<32; i++) {
      currentStinkyLinkys[i] = (data[i].currentStinkyLinky);
      currentValues[i] = (data[i].currentValue);
    }
    return (currentStinkyLinkys,currentValues);
  }
  
}