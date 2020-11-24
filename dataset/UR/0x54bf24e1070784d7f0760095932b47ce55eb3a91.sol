 

pragma solidity 0.4.24;

 

interface EthPriceFeedI {
    function getUnit() external view returns(string);
    function getRate() external view returns(uint256);
    function getLastTimeUpdated() external view returns(uint256); 
}

 

 

pragma solidity 0.4.24;

interface ReadableI {

     
    function peek() external view returns(bytes32, bool);
    function read() external view returns(bytes32);

     
     
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

contract MakerDAOPriceFeed is Ownable, EthPriceFeedI {
    using SafeMath for uint256;
    
    uint256 public constant RATE_THRESHOLD_PERCENTAGE = 10;
    uint256 public constant MAKERDAO_FEED_MULTIPLIER = 10**36;

    ReadableI public makerDAOMedianizer;

    uint256 private weiPerUnitRate;

    uint256 private lastTimeUpdated; 
    
    event RateUpdated(uint256 _newRate, uint256 _timeUpdated);

    modifier isValidRate(uint256 _weiPerUnitRate) {
        require(validRate(_weiPerUnitRate));
        _;
    }

    constructor(ReadableI _makerDAOMedianizer) public {
        require(_makerDAOMedianizer != address(0));
        makerDAOMedianizer = _makerDAOMedianizer;

        weiPerUnitRate = convertToRate(_makerDAOMedianizer.read());
        lastTimeUpdated = now;
    }
    
     
     
    function updateRate(uint256 _weiPerUnitRate) 
        external 
        onlyOwner
        isValidRate(_weiPerUnitRate)
    {
        weiPerUnitRate = _weiPerUnitRate;

        lastTimeUpdated = now; 

        emit RateUpdated(_weiPerUnitRate, now);
    }

    function getUnit()
        external
        view 
        returns(string)
    {
        return "USD";
    }

     
    function getRate() 
        public 
        view 
        returns(uint256)
    {
        return weiPerUnitRate; 
    }

     
    function getLastTimeUpdated()
        public
        view
        returns(uint256)
    {
        return lastTimeUpdated;
    }

     
     
     
    function validRate(uint256 _weiPerUnitRate) public view returns(bool) {
        if (_weiPerUnitRate == 0) return false;

        (bytes32 value, bool valid) = makerDAOMedianizer.peek();

         
        uint256 currentRate = valid ? convertToRate(value) : weiPerUnitRate;

         
        uint256 diff = _weiPerUnitRate < currentRate ?  currentRate.sub(_weiPerUnitRate) : _weiPerUnitRate.sub(currentRate);

        return diff <= currentRate.mul(RATE_THRESHOLD_PERCENTAGE).div(100);
    }

     
     
     
    function convertToRate(bytes32 _fromMedianizer) internal pure returns(uint256) {
        uint256 value = uint256(_fromMedianizer);
        return MAKERDAO_FEED_MULTIPLIER.div(value);
    }
}