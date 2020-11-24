 

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


contract EtherMemes {
   
   
  
   
  address ceoAddress = 0xc10A6AedE9564efcDC5E842772313f0669D79497;
  struct Sergey {
    address memeHolder;
    uint256 currentValue;
   
  }
  Sergey[32] data;
  
   
  function EtherMemes() public {
    for (uint i = 0; i < 32; i++) {
     
      data[i].currentValue = 15000000000000000;
      data[i].memeHolder = msg.sender;
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
     
    payPreviousOwner(data[uniqueCollectibleID].memeHolder,  (data[uniqueCollectibleID].currentValue / 10) * (8)); 
    transactionFee(ceoAddress, (data[uniqueCollectibleID].currentValue / 10) * (2));
     
    data[uniqueCollectibleID].memeHolder = msg.sender;
     
    return (uniqueCollectibleID, data[uniqueCollectibleID].currentValue);

  }
   
  function getMemeHolders() external view returns (address[], uint256[]) {
    address[] memory memeHolders = new address[](32);
    uint256[] memory currentValues =  new uint256[](32);
    for (uint i=0; i<32; i++) {
      memeHolders[i] = (data[i].memeHolder);
      currentValues[i] = (data[i].currentValue);
    }
    return (memeHolders,currentValues);
  }
  
}