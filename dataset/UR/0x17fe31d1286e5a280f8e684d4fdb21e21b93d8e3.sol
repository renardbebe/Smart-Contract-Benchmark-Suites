 

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


contract CryptoLeaders {
   
   
  
   
  address ceoAddress = 0xc10A6AedE9564efcDC5E842772313f0669D79497;
  struct Leaders {
    address currentLeaderOwner;
    uint256 currentValue;
   
  }

  Leaders[32] data;
  
   
  function CryptoLeaders() public {
    for (uint i = 0; i < 32; i++) {
     
      data[i].currentValue = 15000000000000000;
      data[i].currentLeaderOwner = msg.sender;
    }
  }

   
   
  function payPreviousOwner(address previousLeaderOwner, uint256 currentValue) private {
    previousLeaderOwner.transfer(currentValue);
  }
   
   
  function transactionFee(address, uint256 currentValue) private {
    ceoAddress.transfer(currentValue);
  }
   
   
   
  function purchaseLeader(uint uniqueLeaderID) public payable returns (uint, uint) {
    require(uniqueLeaderID >= 0 && uniqueLeaderID <= 31);
     
    if ( data[uniqueLeaderID].currentValue == 15000000000000000 ) {
      data[uniqueLeaderID].currentValue = 30000000000000000;
    } else {
       
      data[uniqueLeaderID].currentValue = (data[uniqueLeaderID].currentValue / 10) * 12;
    }
    
    require(msg.value >= data[uniqueLeaderID].currentValue * uint256(1));
     
    payPreviousOwner(data[uniqueLeaderID].currentLeaderOwner,  (data[uniqueLeaderID].currentValue / 100) * (88)); 
    transactionFee(ceoAddress, (data[uniqueLeaderID].currentValue / 100) * (12));
     
    data[uniqueLeaderID].currentLeaderOwner = msg.sender;
     
    return (uniqueLeaderID, data[uniqueLeaderID].currentValue);

  }
   
  function getCurrentLeaderOwners() external view returns (address[], uint256[]) {
    address[] memory currentLeaderOwners = new address[](32);
    uint256[] memory currentValues =  new uint256[](32);
    for (uint i=0; i<32; i++) {
      currentLeaderOwners[i] = (data[i].currentLeaderOwner);
      currentValues[i] = (data[i].currentValue);
    }
    return (currentLeaderOwners,currentValues);
  }
  
}