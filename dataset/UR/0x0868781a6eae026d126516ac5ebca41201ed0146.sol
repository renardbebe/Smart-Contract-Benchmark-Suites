 

pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;

 
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

 
interface AdminInterface {
     
    function emergencyShutdown() external;

     
     
    function remargin() external;
}

 
interface OracleInterface {
     
     
     
     
    function requestPrice(bytes32 identifier, uint time) external returns (uint expectedTime);

     
    function hasPrice(bytes32 identifier, uint time) external view returns (bool hasPriceAvailable);

     
     
     
    function getPrice(bytes32 identifier, uint time) external view returns (int price);

     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported);

     
    event VerifiedPriceRequested(bytes32 indexed identifier, uint indexed time);

     
    event VerifiedPriceAvailable(bytes32 indexed identifier, uint indexed time, int price);
}

interface RegistryInterface {
    struct RegisteredDerivative {
        address derivativeAddress;
        address derivativeCreator;
    }

     
    function registerDerivative(address[] calldata counterparties, address derivativeAddress) external;

     
     
    function addDerivativeCreator(address derivativeCreator) external;

     
     
    function removeDerivativeCreator(address derivativeCreator) external;

     
     
    function isDerivativeRegistered(address derivative) external view returns (bool isRegistered);

     
    function getRegisteredDerivatives(address party) external view returns (RegisteredDerivative[] memory derivatives);

     
    function getAllRegisteredDerivatives() external view returns (RegisteredDerivative[] memory derivatives);

     
    function isDerivativeCreatorAuthorized(address derivativeCreator) external view returns (bool isAuthorized);
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

contract Withdrawable is Ownable {
     
    function withdraw(uint amount) external onlyOwner {
        msg.sender.transfer(amount);
    }

     
    function withdrawErc20(address erc20Address, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.transfer(msg.sender, amount));
    }
}

 
contract CentralizedOracle is OracleInterface, Withdrawable, Testable {
    using SafeMath for uint;

     
     
    uint constant private SECONDS_IN_WEEK = 60*60*24*7;

     
    struct Price {
        bool isAvailable;
        int price;
         
        uint verifiedTime;
    }

     
     
    struct QueryIndex {
        bool isValid;
        uint index;
    }

     
    struct QueryPoint {
        bytes32 identifier;
        uint time;
    }

     
    mapping(bytes32 => bool) private supportedIdentifiers;

     
    mapping(bytes32 => mapping(uint => Price)) private verifiedPrices;

     
     
    mapping(bytes32 => mapping(uint => QueryIndex)) private queryIndices;
    QueryPoint[] private requestedPrices;

     
    RegistryInterface private registry;

    constructor(address _registry, bool _isTest) public Testable(_isTest) {
        registry = RegistryInterface(_registry);
    }

     
    function requestPrice(bytes32 identifier, uint time) external returns (uint expectedTime) {
         
        require(registry.isDerivativeRegistered(msg.sender));
        require(supportedIdentifiers[identifier]);
        Price storage lookup = verifiedPrices[identifier][time];
        if (lookup.isAvailable) {
             
            return 0;
        } else if (queryIndices[identifier][time].isValid) {
             
            return getCurrentTime().add(SECONDS_IN_WEEK);
        } else {
             
            queryIndices[identifier][time] = QueryIndex(true, requestedPrices.length);
            requestedPrices.push(QueryPoint(identifier, time));
            emit VerifiedPriceRequested(identifier, time);
            return getCurrentTime().add(SECONDS_IN_WEEK);
        }
    }

     
    function pushPrice(bytes32 identifier, uint time, int price) external onlyOwner {
        verifiedPrices[identifier][time] = Price(true, price, getCurrentTime());
        emit VerifiedPriceAvailable(identifier, time, price);

        QueryIndex storage queryIndex = queryIndices[identifier][time];
        require(queryIndex.isValid, "Can't push prices that haven't been requested");
         
         
        uint indexToReplace = queryIndex.index;
        delete queryIndices[identifier][time];
        uint lastIndex = requestedPrices.length.sub(1);
        if (lastIndex != indexToReplace) {
            QueryPoint storage queryToCopy = requestedPrices[lastIndex];
            queryIndices[queryToCopy.identifier][queryToCopy.time].index = indexToReplace;
            requestedPrices[indexToReplace] = queryToCopy;
        }
        requestedPrices.length = requestedPrices.length.sub(1);
    }

     
    function addSupportedIdentifier(bytes32 identifier) external onlyOwner {
        if(!supportedIdentifiers[identifier]) {
            supportedIdentifiers[identifier] = true;
            emit AddSupportedIdentifier(identifier);
        }
    }

     
    function callEmergencyShutdown(address derivative) external onlyOwner {
        AdminInterface admin = AdminInterface(derivative);
        admin.emergencyShutdown();
    }

     
    function callRemargin(address derivative) external onlyOwner {
        AdminInterface admin = AdminInterface(derivative);
        admin.remargin();
    }

     
    function hasPrice(bytes32 identifier, uint time) external view returns (bool hasPriceAvailable) {
         
        require(registry.isDerivativeRegistered(msg.sender));
        require(supportedIdentifiers[identifier]);
        Price storage lookup = verifiedPrices[identifier][time];
        return lookup.isAvailable;
    }

     
    function getPrice(bytes32 identifier, uint time) external view returns (int price) {
         
        require(registry.isDerivativeRegistered(msg.sender));
        require(supportedIdentifiers[identifier]);
        Price storage lookup = verifiedPrices[identifier][time];
        require(lookup.isAvailable);
        return lookup.price;
    }

     
    function getPendingQueries() external view onlyOwner returns (QueryPoint[] memory queryPoints) {
        return requestedPrices;
    }

     
    function isIdentifierSupported(bytes32 identifier) external view returns (bool isSupported) {
        return supportedIdentifiers[identifier];
    }

    event AddSupportedIdentifier(bytes32 indexed identifier);
}