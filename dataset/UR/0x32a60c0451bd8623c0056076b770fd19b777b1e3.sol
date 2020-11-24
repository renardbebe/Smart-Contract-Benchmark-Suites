 

pragma solidity 0.5.2;

 

 
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

 

contract Dividend {
    using SafeMath for uint;

    address payable public addr1 = 0x2b339Ebdd12d6f79aA18ed2A032ebFE1FA4Faf45;
    address payable public addr2 = 0x4BB515b7443969f7eb519d175e209aE8Af3601C1;

    event LogPayment(
        address indexed from,
        address indexed to,
        uint amount,
        uint total
    );

     
    function () external payable {
         
        uint amount1 = msg.value.mul(8).div(10);
        uint amount2 = msg.value.sub(amount1);

         
        addr1.transfer(amount1);
        addr2.transfer(amount2);

        emit LogPayment(msg.sender, addr1, amount1, msg.value);
        emit LogPayment(msg.sender, addr2, amount2, msg.value);
    }
}