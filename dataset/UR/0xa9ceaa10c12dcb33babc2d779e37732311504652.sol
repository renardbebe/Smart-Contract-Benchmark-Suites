 

 

pragma solidity ^0.5.0;

 
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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 
contract RequestHashStorage is WhitelistedRole {

   
  event NewHash(string hash, address hashSubmitter, bytes feesParameters);

   
  function declareNewHash(string calldata _hash, bytes calldata _feesParameters)
    external
    onlyWhitelisted
  {
     
    emit NewHash(_hash, msg.sender, _feesParameters);
  }

   
  function()
    external
  {
    revert("not payable fallback");
  }
}


 
library Bytes {
   
  function extractBytes32(bytes memory data, uint offset)
    internal
    pure
    returns (bytes32 bs)
  {
    require(offset >= 0 && offset + 32 <= data.length, "offset value should be in the correct range");

     
    assembly {
        bs := mload(add(data, add(32, offset)))
    }
  }
}

 
contract StorageFeeCollector is WhitelistAdminRole {
  using SafeMath for uint256;

   
  uint256 public minimumFee;
  uint256 public rateFeesNumerator;
  uint256 public rateFeesDenominator;

   
  address payable public requestBurnerContract;

  event UpdatedFeeParameters(uint256 minimumFee, uint256 rateFeesNumerator, uint256 rateFeesDenominator);
  event UpdatedMinimumFeeThreshold(uint256 threshold);
  event UpdatedBurnerContract(address burnerAddress);

   
  constructor(address payable _requestBurnerContract)
    public
  {
    requestBurnerContract = _requestBurnerContract;
  }

   
  function setFeeParameters(uint256 _minimumFee, uint256 _rateFeesNumerator, uint256 _rateFeesDenominator)
    external
    onlyWhitelistAdmin
  {
    minimumFee = _minimumFee;
    rateFeesNumerator = _rateFeesNumerator;
    rateFeesDenominator = _rateFeesDenominator;
    emit UpdatedFeeParameters(minimumFee, rateFeesNumerator, rateFeesDenominator);
  }


   
  function setRequestBurnerContract(address payable _requestBurnerContract)
    external
    onlyWhitelistAdmin
  {
    requestBurnerContract = _requestBurnerContract;
    emit UpdatedBurnerContract(requestBurnerContract);
  }

   
  function getFeesAmount(uint256 _contentSize)
    public
    view
    returns(uint256)
  {
     
    uint256 computedAllFee = _contentSize.mul(rateFeesNumerator);

    if (rateFeesDenominator != 0) {
      computedAllFee = computedAllFee.div(rateFeesDenominator);
    }

    if (computedAllFee <= minimumFee) {
      return minimumFee;
    } else {
      return computedAllFee;
    }
  }

   
  function collectForREQBurning(uint256 _amount)
    internal
  {
     
    requestBurnerContract.transfer(_amount);
  }
}

 
contract RequestOpenHashSubmitter is StorageFeeCollector {

  RequestHashStorage public requestHashStorage;
  
   
  constructor(address _addressRequestHashStorage, address payable _addressBurner)
    StorageFeeCollector(_addressBurner)
    public
  {
    requestHashStorage = RequestHashStorage(_addressRequestHashStorage);
  }

   
  function submitHash(string calldata _hash, bytes calldata _feesParameters)
    external
    payable
  {
     
    uint256 contentSize = uint256(Bytes.extractBytes32(_feesParameters, 0));

     
    require(getFeesAmount(contentSize) == msg.value, "msg.value does not match the fees");

     
    collectForREQBurning(msg.value);

     
    requestHashStorage.declareNewHash(_hash, _feesParameters);
  }

   
  function()
    external
    payable
  {
    revert("not payable fallback");
  }
}