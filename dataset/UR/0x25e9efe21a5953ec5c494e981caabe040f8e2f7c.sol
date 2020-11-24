 

pragma solidity 0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
 
 
 
contract ExchangeRate is Ownable {
    event RateUpdated(string id, uint256 rate);
    event UpdaterTransferred(address indexed previousUpdater, address indexed newUpdater);

    address public updater;

    mapping(string => uint256) internal currentRates;

     
     
    constructor(address _updater) public {
        require(_updater != address(0));
        updater = _updater;
    }

     
    modifier onlyUpdater() {
        require(msg.sender == updater);
        _;
    }

     
     
    function transferUpdater(address _newUpdater) external onlyOwner {
        require(_newUpdater != address(0));
        emit UpdaterTransferred(updater, _newUpdater);
        updater = _newUpdater;
    }

     
     
     
    function updateRate(string _id, uint256 _rate) external onlyUpdater {
        require(_rate != 0);
        currentRates[_id] = _rate;
        emit RateUpdated(_id, _rate);
    }

     
     
     
    function getRate(string _id) external view returns(uint256) {
        return currentRates[_id];
    }
}