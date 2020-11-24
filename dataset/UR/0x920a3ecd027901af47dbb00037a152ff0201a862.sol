 

pragma solidity >=0.4.22 <0.6.0;


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract PrimalityTest {
    mapping ( uint => uint ) balance;

    function deposit(uint256 n) public payable {
        balance[n] += msg.value;
    }

    event NotPrime(uint n);  

    function factor(uint p, uint q) public {
        require(p > 1);
        require(q > 1);
        uint n = SafeMath.mul(p, q);
        uint b = balance[n];
        balance[n] = 0;
        msg.sender.transfer(b);
        emit NotPrime(n);
    }

    function isStillPrime(uint n) public view returns(uint confidence) {
         
         
        return balance[n];
    }
}