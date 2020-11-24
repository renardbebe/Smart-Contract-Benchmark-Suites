 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract BlockportDistributor {
    using SafeMath for uint256;

    event Distributed(address payable[] receivers, uint256 amount);

     
    constructor () public {
    }

     
    function () external payable {
        revert();
    }

     
    function distribute(address payable[] calldata receivers, uint256 amount) external payable returns (bool success) {
        require(amount.mul(receivers.length) == msg.value);

        for (uint256 i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amount);
        }
        emit Distributed(receivers, amount);
        return true;
    }
}