 

 

pragma solidity 0.5.10;

 
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

 

pragma solidity 0.5.10;


contract Lab {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public balances;

    function getBalance() public view returns (uint256) {
        address user = address(this);
        address assetId = address(this);
        return balances[user][assetId];
    }

    function incrementBalance(uint256 amount) public {
        address user = address(this);
        address assetId = address(this);
        balances[user][assetId] += amount;
    }

    function batchIncrementBalance(uint256 amount) public {
        address user = address(this);
        address assetId = address(this);
        balances[user][assetId] += amount;
        balances[user][assetId] += amount * 2;
        balances[user][assetId] += amount * 3;
        balances[user][assetId] += amount * 4;
        balances[user][assetId] += amount * 5;
    }

    function loopIncrementBalance(uint256 amount) public {
        address user = address(this);
        address assetId = address(this);
        for (uint256 i = 0; i < 5; i++) {
            balances[user][assetId] += amount * i;
        }
    }

    function clearBalance() public {
        address user = address(this);
        address assetId = address(this);
        delete balances[user][assetId];
    }

    function noop() public {}
}