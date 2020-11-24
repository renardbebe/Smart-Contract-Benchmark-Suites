 

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

 
interface PriceFeedInterface {
     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported);

     
     
    function latestPrice(bytes32 identifier) external view returns (uint publishTime, int price);

     
    event PriceUpdated(bytes32 indexed identifier, uint indexed time, int price);
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

contract Testable is Ownable {

     
     
    bool public isTest;

    uint private currentTime;

    constructor(bool _isTest) internal {
        isTest = _isTest;
        if (_isTest) {
            currentTime = now;  
        }
    }

    modifier onlyIfTest {
        require(isTest);
        _;
    }

    function setCurrentTime(uint _time) external onlyOwner onlyIfTest {
        currentTime = _time;
    }

    function getCurrentTime() public view returns (uint) {
        if (isTest) {
            return currentTime;
        } else {
            return now;  
        }
    }
}

 
contract ManualPriceFeed is PriceFeedInterface, Withdrawable, Testable {

    using SafeMath for uint;

     
    struct PriceTick {
        uint timestamp;
        int price;
    }

     
    mapping(bytes32 => PriceTick) private prices;

     
     
     
     
     
    uint constant private BLOCK_TIMESTAMP_TOLERANCE = 900;

    constructor(bool _isTest) public Testable(_isTest) {}  

     
     
    function pushLatestPrice(bytes32 identifier, uint publishTime, int newPrice) external onlyOwner {
        require(publishTime <= getCurrentTime().add(BLOCK_TIMESTAMP_TOLERANCE));
        require(publishTime > prices[identifier].timestamp);
        prices[identifier] = PriceTick(publishTime, newPrice);
        emit PriceUpdated(identifier, publishTime, newPrice);
    }

     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported) {
        isSupported = _isIdentifierSupported(identifier);
    }

    function latestPrice(bytes32 identifier) external view returns (uint publishTime, int price) {
        require(_isIdentifierSupported(identifier));
        publishTime = prices[identifier].timestamp;
        price = prices[identifier].price;
    }

    function _isIdentifierSupported(bytes32 identifier) private view returns (bool isSupported) {
        isSupported = prices[identifier].timestamp > 0;
    }
}