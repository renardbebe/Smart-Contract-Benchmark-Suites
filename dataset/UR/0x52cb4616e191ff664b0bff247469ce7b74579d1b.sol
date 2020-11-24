 

pragma solidity ^0.4.24;

interface IOracle {

     
    function getCurrencyAddress() external view returns(address);

     
    function getCurrencySymbol() external view returns(bytes32);

     
    function getCurrencyDenominated() external view returns(bytes32);

     
    function getPrice() external view returns(uint256);

}

 

interface IMedianizer {

    function peek() constant external returns (bytes32, bool);

    function read() constant external returns (bytes32);

    function set(address wat) external;

    function set(bytes12 pos, address wat) external;

    function setMin(uint96 min_) external;

    function setNext(bytes12 next_) external;

    function unset(bytes12 pos) external;

    function unset(address wat) external;

    function poke() external;

    function poke(bytes32) external;

    function compute() constant external returns (bytes32, bool);

    function void() external;

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

contract MakerDAOOracle is IOracle, Ownable {

    address public medianizer;
    address public currencyAddress;
    bytes32 public currencySymbol;

    bool public manualOverride;
    uint256 public manualPrice;

    event ChangeMedianizer(address _newMedianizer, address _oldMedianizer, uint256 _now);
    event SetManualPrice(uint256 _oldPrice, uint256 _newPrice, uint256 _time);
    event SetManualOverride(bool _override, uint256 _time);

     
    constructor (address _medianizer, address _currencyAddress, bytes32 _currencySymbol) public {
        medianizer = _medianizer;
        currencyAddress = _currencyAddress;
        currencySymbol = _currencySymbol;
    }

     
    function changeMedianier(address _medianizer) public onlyOwner {
        require(_medianizer != address(0), "0x not allowed");
        emit ChangeMedianizer(_medianizer, medianizer, now);
        medianizer = _medianizer;
    }

     
    function getCurrencyAddress() external view returns(address) {
        return currencyAddress;
    }

     
    function getCurrencySymbol() external view returns(bytes32) {
        return currencySymbol;
    }

     
    function getCurrencyDenominated() external view returns(bytes32) {
         
        return bytes32("USD");
    }

     
    function getPrice() external view returns(uint256) {
        if (manualOverride) {
            return manualPrice;
        }
        (bytes32 price, bool valid) = IMedianizer(medianizer).peek();
        require(valid, "MakerDAO Oracle returning invalid value");
        return uint256(price);
    }

     
    function setManualPrice(uint256 _price) public onlyOwner {
        emit SetManualPrice(manualPrice, _price, now);
        manualPrice = _price;
    }

     
    function setManualOverride(bool _override) public onlyOwner {
        manualOverride = _override;
        emit SetManualOverride(_override, now);
    }

}