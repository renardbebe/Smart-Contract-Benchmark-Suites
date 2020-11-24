 

pragma solidity ^0.4.24;

library Attribute {
  enum AttributeType {
    ROLE_MANAGER,                    
    ROLE_OPERATOR,                   
    IS_BLACKLISTED,                  
    HAS_PASSED_KYC_AML,              
    NO_FEES,                         
     
    USER_DEFINED
  }

  function toUint256(AttributeType _type) internal pure returns (uint256) {
    return uint256(_type);
  }
}


library BitManipulation {
  uint256 constant internal ONE = uint256(1);

  function setBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num | (ONE << _pos);
  }

  function clearBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num & ~(ONE << _pos);
  }

  function toggleBit(uint256 _num, uint256 _pos) internal pure returns (uint256) {
    return _num ^ (ONE << _pos);
  }

  function checkBit(uint256 _num, uint256 _pos) internal pure returns (bool) {
    return (_num >> _pos & ONE == ONE);
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






 
contract RegistryAccessManager {
   
   
  function confirmWrite(
    address _who,
    Attribute.AttributeType _attribute,
    address _admin
  )
    public returns (bool);
}










 
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



 
contract ClaimableEx is Claimable {
   
  function cancelOwnershipTransfer() onlyOwner public {
    pendingOwner = owner;
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











contract Registry is ClaimableEx {
  using BitManipulation for uint256;

  struct AttributeData {
    uint256 value;
  }

   
   
   
   
   
   
  mapping(address => AttributeData) private attributes;

   
   
  RegistryAccessManager public accessManager;

  event SetAttribute(
    address indexed who,
    Attribute.AttributeType attribute,
    bool enable,
    string notes,
    address indexed adminAddr
  );

  event SetManager(
    address indexed oldManager,
    address indexed newManager
  );

  constructor() public {
    accessManager = new DefaultRegistryAccessManager();
  }

   
  function setAttribute(
    address _who,
    Attribute.AttributeType _attribute,
    string _notes
  )
    public
  {
    bool _canWrite = accessManager.confirmWrite(
      _who,
      _attribute,
      msg.sender
    );
    require(_canWrite);

     
    uint256 _tempVal = attributes[_who].value;

    attributes[_who] = AttributeData(
      _tempVal.setBit(Attribute.toUint256(_attribute))
    );

    emit SetAttribute(_who, _attribute, true, _notes, msg.sender);
  }

  function clearAttribute(
    address _who,
    Attribute.AttributeType _attribute,
    string _notes
  )
    public
  {
    bool _canWrite = accessManager.confirmWrite(
      _who,
      _attribute,
      msg.sender
    );
    require(_canWrite);

     
    uint256 _tempVal = attributes[_who].value;

    attributes[_who] = AttributeData(
      _tempVal.clearBit(Attribute.toUint256(_attribute))
    );

    emit SetAttribute(_who, _attribute, false, _notes, msg.sender);
  }

   
  function hasAttribute(
    address _who,
    Attribute.AttributeType _attribute
  )
    public
    view
    returns (bool)
  {
    return attributes[_who].value.checkBit(Attribute.toUint256(_attribute));
  }

   
  function getAttributes(
    address _who
  )
    public
    view
    returns (uint256)
  {
    AttributeData memory _data = attributes[_who];
    return _data.value;
  }

  function setManager(RegistryAccessManager _accessManager) public onlyOwner {
    emit SetManager(accessManager, _accessManager);
    accessManager = _accessManager;
  }
}




contract DefaultRegistryAccessManager is RegistryAccessManager {
  function confirmWrite(
    address  ,
    Attribute.AttributeType _attribute,
    address _operator
  )
    public
    returns (bool)
  {
    Registry _client = Registry(msg.sender);
    if (_operator == _client.owner()) {
      return true;
    } else if (_client.hasAttribute(_operator, Attribute.AttributeType.ROLE_MANAGER)) {
      return (_attribute == Attribute.AttributeType.ROLE_OPERATOR);
    } else if (_client.hasAttribute(_operator, Attribute.AttributeType.ROLE_OPERATOR)) {
      return (_attribute != Attribute.AttributeType.ROLE_OPERATOR &&
              _attribute != Attribute.AttributeType.ROLE_MANAGER);
    }
  }
}