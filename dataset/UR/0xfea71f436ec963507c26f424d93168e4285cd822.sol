 

pragma solidity ^0.4.21;

 
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


contract batchTransfer {
    using SafeMath for uint256;
    
    uint public totalEther;
    
    function batchTransfer() public {
        totalEther = 0;
    }
    
    function distribute(address[] myAddresses) public payable {
            require(myAddresses.length>0);
            
            uint256 value = msg.value;
            uint256 length = myAddresses.length;
            uint256 distr = value.div(length);
            
            if(length==1)
            {
               myAddresses[0].transfer(value);
            }else
            {
                for(uint256 i=0;i<(length.sub(1));i++)
                {
                    myAddresses[i].transfer(distr);
                    value = value.sub(distr);
                }
                myAddresses[myAddresses.length-1].transfer(value);
            }
            
            totalEther = totalEther.add(msg.value);
    }
}