 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract Distribute {

    using SafeMath for SafeMath;

    address public netAddress = 0x88888888c84198BCc5CEb4160d13726F22c151Ab;

    address public otherAddress = 0x8e83D33aB48b110B7C3DF8C6F5D02191aF9b80FD;

    uint proportionA = 94;
    uint proportionB = 6;
    uint base = 100;

    constructor() public {

    }

    function() payable public {
        require(msg.value > 0);

        netAddress.transfer(SafeMath.div(SafeMath.mul(msg.value, proportionA), base));
        otherAddress.transfer(SafeMath.div(SafeMath.mul(msg.value, proportionB), base));

    }


}