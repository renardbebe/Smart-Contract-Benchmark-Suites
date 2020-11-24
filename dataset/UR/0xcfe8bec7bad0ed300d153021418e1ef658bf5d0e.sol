 

pragma solidity >=0.4.20 <0.7.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract multiSender{
    using SafeMath for uint256;
    address contractOwner;
    address defaultTokenAddress;
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    
    constructor(address tokenAddress, address inputOwner) public{
        contractOwner = inputOwner;
        defaultTokenAddress = tokenAddress;
    }
    
    function sendDefaultTokensMultiple(address[] memory _walletDest, uint256 _amountT) onlyOwner public {
        for(uint ia = 0; ia < _walletDest.length; ia++){
            address dest = _walletDest[ia];
            uint amountToken = _amountT;
            IERC20(defaultTokenAddress).transfer(dest, amountToken);
        }
    }
    
    function sendOtherTokens(address _tokenContract, address _walletDest, uint256 _amountT) onlyOwner public returns (bool) {
        address dest = _walletDest;
        uint amountToken = _amountT;
        return IERC20(_tokenContract).transfer(dest, amountToken);
    }
}