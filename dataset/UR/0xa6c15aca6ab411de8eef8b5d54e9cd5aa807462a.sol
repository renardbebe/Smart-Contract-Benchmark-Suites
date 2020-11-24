 

 

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

 

pragma solidity ^0.4.24;



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

pragma solidity 0.4.25;


 
contract Adminable is Claimable {
    address[] public adminArray;

    struct AdminInfo {
        bool valid;
        uint256 index;
    }

    mapping(address => AdminInfo) public adminTable;

    event AdminAccepted(address indexed _admin);
    event AdminRejected(address indexed _admin);

     
    modifier onlyAdmin() {
        require(adminTable[msg.sender].valid, "caller is illegal");
        _;
    }

     
    function accept(address _admin) external onlyOwner {
        require(_admin != address(0), "administrator is illegal");
        AdminInfo storage adminInfo = adminTable[_admin];
        require(!adminInfo.valid, "administrator is already accepted");
        adminInfo.valid = true;
        adminInfo.index = adminArray.length;
        adminArray.push(_admin);
        emit AdminAccepted(_admin);
    }

     
    function reject(address _admin) external onlyOwner {
        AdminInfo storage adminInfo = adminTable[_admin];
        require(adminArray.length > adminInfo.index, "administrator is already rejected");
        require(_admin == adminArray[adminInfo.index], "administrator is already rejected");
         
        address lastAdmin = adminArray[adminArray.length - 1];  
        adminTable[lastAdmin].index = adminInfo.index;
        adminArray[adminInfo.index] = lastAdmin;
        adminArray.length -= 1;  
        delete adminTable[_admin];
        emit AdminRejected(_admin);
    }

     
    function getAdminArray() external view returns (address[] memory) {
        return adminArray;
    }

     
    function getAdminCount() external view returns (uint256) {
        return adminArray.length;
    }
}

 

pragma solidity 0.4.25;

 
interface IWalletsTradingLimiterValueConverter {
     
    function toLimiterValue(uint256 _sgaAmount) external view returns (uint256);
}

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity 0.4.25;




 

 
contract WalletsTradingLimiterValueConverter is IWalletsTradingLimiterValueConverter, Adminable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

     
    uint256 public constant MAX_RESOLUTION = 0x10000000000000000;

    uint256 public sequenceNum = 0;
    uint256 public priceN = 0;
    uint256 public priceD = 0;

    event PriceSaved(uint256 _priceN, uint256 _priceD);
    event PriceNotSaved(uint256 _priceN, uint256 _priceD);

     
    function setPrice(uint256 _sequenceNum, uint256 _priceN, uint256 _priceD) external onlyAdmin {
        require(1 <= _priceN && _priceN <= MAX_RESOLUTION, "price numerator is out of range");
        require(1 <= _priceD && _priceD <= MAX_RESOLUTION, "price denominator is out of range");

        if (sequenceNum < _sequenceNum) {
            sequenceNum = _sequenceNum;
            priceN = _priceN;
            priceD = _priceD;
            emit PriceSaved(_priceN, _priceD);
        }
        else {
            emit PriceNotSaved(_priceN, _priceD);
        }
    }

     
    function toLimiterValue(uint256 _sgaAmount) external view returns (uint256) {
        assert(priceN > 0 && priceD > 0);
        return _sgaAmount.mul(priceN) / priceD;
    }
}