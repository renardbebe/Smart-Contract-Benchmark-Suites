 

pragma solidity ^0.5.0;

 

 
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

 

contract LockedWallet is Ownable {
    using SafeMath for uint256;

    event Withdrawn (
        uint256 period,
        uint256 amount,
        uint256 timestamp
    );

    uint256 public depositedTime;
    uint256 public periodLength;
    uint256 public amountPerPeriod;
    IERC20 public token;
    uint256 public depositedAmount;
    mapping(uint256 => uint256) public withdrawalByPeriod;

    constructor(uint256 newPeriodLength, uint256 newAmountPerPeriod, address tokenAddress) public {
        require(tokenAddress != address(0));
        require(newPeriodLength > 0);
        require(newAmountPerPeriod > 0);

        token = IERC20(tokenAddress);
        periodLength = newPeriodLength;
        amountPerPeriod = newAmountPerPeriod;
    }

    function deposit(uint256 amount) public {
        require(depositedTime == 0, "already deposited");

        depositedTime = now;
        depositedAmount = amount;

        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw() public onlyOwner {
        require(depositedTime > 0, "not deposited");

        uint256 currentPeriod = now.sub(depositedTime).div(periodLength);
        require(currentPeriod > 0, "invalid period 1");
        require(withdrawalByPeriod[currentPeriod] == 0, "already withdrawn");

        uint256 balance = token.balanceOf(address(this));
        uint256 amount = amountPerPeriod < balance ? amountPerPeriod : balance;
        require(amount > 0, "empty");

        withdrawalByPeriod[currentPeriod] = amount;

        emit Withdrawn(currentPeriod, amount, now);

        token.transfer(owner(), amount);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}