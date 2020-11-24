 

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


contract EtherHeroes {
   
   
  
   
  address ceoAddress = 0xC0c8Dc6C1485060a72FCb629560371fE09666500;
  struct Hero {
    address currentHeroOwner;
    uint256 currentValue;
   
  }
  Hero[16] data;
  
   
  function EtherHeroes() public {
    for (uint i = 0; i < 16; i++) {
     
      data[i].currentValue = 10000000000000000;
      data[i].currentHeroOwner = msg.sender;
    }
  }

   
   
  function payPreviousOwner(address previousHeroOwner, uint256 currentValue) private {
    previousHeroOwner.transfer(currentValue);
  }
   
   
  function transactionFee(address, uint256 currentValue) private {
    ceoAddress.transfer(currentValue);
  }
   
   
   
  function purchaseHeroForEth(uint uniqueHeroID) public payable returns (uint, uint) {
    require(uniqueHeroID >= 0 && uniqueHeroID <= 15);
     
    if ( data[uniqueHeroID].currentValue == 10000000000000000 ) {
      data[uniqueHeroID].currentValue = 20000000000000000;
    } else {
       
      data[uniqueHeroID].currentValue = data[uniqueHeroID].currentValue * 2;
    }
    
    require(msg.value >= data[uniqueHeroID].currentValue * uint256(1));
     
    payPreviousOwner(data[uniqueHeroID].currentHeroOwner,  (data[uniqueHeroID].currentValue / 10) * (9)); 
    transactionFee(ceoAddress, (data[uniqueHeroID].currentValue / 10) * (1));
     
    data[uniqueHeroID].currentHeroOwner = msg.sender;
     
    return (uniqueHeroID, data[uniqueHeroID].currentValue);

  }
   
  function getCurrentHeroOwners() external view returns (address[], uint256[]) {
    address[] memory currentHeroOwners = new address[](16);
    uint256[] memory currentValues =  new uint256[](16);
    for (uint i=0; i<16; i++) {
      currentHeroOwners[i] = (data[i].currentHeroOwner);
      currentValues[i] = (data[i].currentValue);
    }
    return (currentHeroOwners,currentValues);
  }
  
}