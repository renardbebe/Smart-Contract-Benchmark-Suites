 

pragma solidity 0.4.23;

 

 
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

 

contract GivingLog {
    using SafeMath for uint128;

    event Give(address give, address take, uint128 amount, string ipfs);

    function logGive(address _to, string _ipfs) public payable{
        require(msg.value > 0);
        _to.transfer(uint128(msg.value));
        emit Give(msg.sender, _to, uint128(msg.value), _ipfs);
    }

}