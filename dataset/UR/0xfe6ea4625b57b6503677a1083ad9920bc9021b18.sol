 

pragma solidity ^0.4.25;
 
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
contract BonusContract {
    address public owner = 0xdF8AB44409132d358F10bd4a7d1221b418ff8dFF;
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

   
    function () public payable {
       (msg.sender, msg.value);
    }

    
    function getCurrentBalance() constant returns (uint) {
        return this.balance;
    }
    
    function distribution() public isOwner {
       

        owner.transfer(this.balance);
    }

   
}