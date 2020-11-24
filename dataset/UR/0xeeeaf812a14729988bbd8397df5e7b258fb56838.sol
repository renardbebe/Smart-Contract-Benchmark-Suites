 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
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

 
interface StoreInterface {

     
    function payOracleFees() external payable;

     
     
    function payOracleFeesErc20(address erc20Address) external; 

     
     
     
    function computeOracleFees(uint startTime, uint endTime, uint pfc) external view returns (uint feeAmount);
}

contract Withdrawable is Ownable {
     
    function withdraw(uint amount) external onlyOwner {
        msg.sender.transfer(amount);
    }

     
    function withdrawErc20(address erc20Address, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.transfer(msg.sender, amount));
    }
}

 
contract CentralizedStore is StoreInterface, Withdrawable {

    using SafeMath for uint;

    uint private fixedOracleFeePerSecond;  
    uint private constant FP_SCALING_FACTOR = 10**18;

    function payOracleFees() external payable {
        require(msg.value > 0);
    }

    function payOracleFeesErc20(address erc20Address) external {
        IERC20 erc20 = IERC20(erc20Address);
        uint authorizedAmount = erc20.allowance(msg.sender, address(this));
        require(authorizedAmount > 0);
        require(erc20.transferFrom(msg.sender, address(this), authorizedAmount));
    }

     
    function setFixedOracleFeePerSecond(uint newOracleFee) external onlyOwner {
         
        require(newOracleFee < FP_SCALING_FACTOR);
        fixedOracleFeePerSecond = newOracleFee;
        emit SetFixedOracleFeePerSecond(newOracleFee);
    }

    function computeOracleFees(uint startTime, uint endTime, uint pfc) external view returns (uint oracleFeeAmount) {
        uint timeRange = endTime.sub(startTime);

         
        uint oracleFeesPreDivision = pfc.mul(fixedOracleFeePerSecond).mul(timeRange);
        oracleFeeAmount = oracleFeesPreDivision.div(FP_SCALING_FACTOR);

         
        if (oracleFeesPreDivision.mod(FP_SCALING_FACTOR) != 0) {
            oracleFeeAmount = oracleFeeAmount.add(1);
        }
    }

    event SetFixedOracleFeePerSecond(uint newOracleFee);
}