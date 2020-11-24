 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract USDPrice is Ownable {

    using SafeMath for uint256;

     
     
    uint256 public ETHUSD;

     
    uint256 public updatedTime;

     
    mapping (uint256 => uint256) public priceHistory;

    event PriceUpdated(uint256 price);

    constructor() public {
    }

    function getHistoricPrice(uint256 time) public view returns (uint256) {
        return priceHistory[time];
    } 

    function updatePrice(uint256 price) public onlyOwner {
        require(price > 0);

        priceHistory[updatedTime] = ETHUSD;

        ETHUSD = price;
         
        updatedTime = block.timestamp;

        emit PriceUpdated(ETHUSD);
    }

     
    function getPrice(uint256 _weiAmount)
        public view returns (uint256)
    {
        return _weiAmount.mul(ETHUSD);
    }
    
}