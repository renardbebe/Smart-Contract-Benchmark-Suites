 

pragma solidity 0.4.23;

 
contract AccessControlLight {
   
   
  uint256 private constant ROLE_ROLE_MANAGER = 0x10000000;

   
   
   
  uint256 private constant ROLE_FEATURE_MANAGER = 0x20000000;

   
  uint256 private constant FULL_PRIVILEGES_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  uint256 public features;

   
   
   
   
   
   
   
  mapping(address => uint256) public userRoles;

   
  event FeaturesUpdated(address indexed _by, uint256 _requested, uint256 _actual);

   
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

   
  constructor() public {
     
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

   
  function updateFeatures(uint256 mask) public {
     
    require(isSenderInRole(ROLE_FEATURE_MANAGER));

     
    features = evaluateBy(msg.sender, features, mask);

     
    emit FeaturesUpdated(msg.sender, mask, features);
  }

   
  function updateRole(address operator, uint256 role) public {
     
    require(isSenderInRole(ROLE_ROLE_MANAGER));

     
    userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

     
    emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
  }

   
  function evaluateBy(address operator, uint256 actual, uint256 required) public constant returns(uint256) {
     
    uint256 p = userRoles[operator];

     
     
    actual |= p & required;
     
    actual &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ required));

     
    return actual;
  }

   
  function isFeatureEnabled(uint256 required) public constant returns(bool) {
     
    return __hasRole(features, required);
  }

   
  function isSenderInRole(uint256 required) public constant returns(bool) {
     
    return isOperatorInRole(msg.sender, required);
  }

   
  function isOperatorInRole(address operator, uint256 required) public constant returns(bool) {
     
    return __hasRole(userRoles[operator], required);
  }

   
  function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
     
    return actual & required == required;
  }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
     
    uint256 size = 0;

     
     
     
     
     
    assembly {
       
      size := extcodesize(addr)
    }

     
    return size > 0;
  }

}

 
interface ERC20Receiver {
   
  function onERC20Received(address _operator, address _from, uint256 _value, bytes _data) external returns(bytes4);
}

 
contract GoldERC20 is AccessControlLight {
   
  uint32 public constant TOKEN_VERSION = 0x300;

   
  string public constant symbol = "GLD";

   
  string public constant name = "GOLD - CryptoMiner World";

   
  uint8 public constant decimals = 3;

   
  uint256 public constant ONE_UNIT = uint256(10) ** decimals;

   
  mapping(address => uint256) private tokenBalances;

   
  uint256 private tokensTotal;

   
  mapping(address => mapping(address => uint256)) private transferAllowances;

   
  uint32 public constant FEATURE_TRANSFERS = 0x00000001;

   
  uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x00000002;

   
  uint32 public constant ROLE_TOKEN_CREATOR = 0x00000001;

   
  uint32 public constant ROLE_TOKEN_DESTROYER = 0x00000002;

   
  bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
  event Minted(address indexed _by, address indexed _to, uint256 _value);

   
  event Burnt(address indexed _by, address indexed _from, uint256 _value);

   
  function totalSupply() public constant returns (uint256) {
     
    return tokensTotal;
  }

   
  function balanceOf(address _owner) public constant returns (uint256) {
     
    return tokenBalances[_owner];
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256) {
     
    return transferAllowances[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
     
     
    return transferFrom(msg.sender, _to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     
     
    safeTransferFrom(_from, _to, _value, "");

     
     
     
    return true;
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _value, bytes _data) public {
     
     
    unsafeTransferFrom(_from, _to, _value);

     
     
     
     
    if (AddressUtils.isContract(_to)) {
       
      bytes4 response = ERC20Receiver(_to).onERC20Received(msg.sender, _from, _value, _data);

       
      require(response == ERC20_RECEIVED);
    }
  }

   
  function unsafeTransferFrom(address _from, address _to, uint256 _value) public {
     
     
    require(_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
         || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF));

     
    require(_to != address(0));

     
    require(_from != _to);

     
    require(_value != 0);

     
     

     
    if(_from != msg.sender) {
       
      require(transferAllowances[_from][msg.sender] >= _value);

       
      transferAllowances[_from][msg.sender] -= _value;
    }

     
    require(tokenBalances[_from] >= _value);

     
     
    tokenBalances[_from] -= _value;

     
    tokenBalances[_to] += _value;

     
    emit Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
     
    transferAllowances[msg.sender][_spender] = _value;

     
    emit Approval(msg.sender, _spender, _value);

     
    return true;
  }

   
  function mint(address _to, uint256 _value) public {
     
    uint256 value = _value * ONE_UNIT;

     
    require(value > _value);

     
    mintNative(_to, value);
  }

   
  function mintNative(address _to, uint256 _value) public {
     
    require(isSenderInRole(ROLE_TOKEN_CREATOR));

     
    require(_to != address(0));

     
     
    require(tokensTotal + _value > tokensTotal);

     
    tokenBalances[_to] += _value;

     
    tokensTotal += _value;

     
    emit Transfer(address(0), _to, _value);

     
    emit Minted(msg.sender, _to, _value);
  }

   
  function burn(address _from, uint256 _value) public {
     
    uint256 value = _value * ONE_UNIT;

     
    require(value > _value);

     
    burnNative(_from, value);
  }

   
  function burnNative(address _from, uint256 _value) public {
     
    require(isSenderInRole(ROLE_TOKEN_DESTROYER));

     
    require(_value != 0);

     
     
    require(tokenBalances[_from] >= _value);

     
    tokenBalances[_from] -= _value;

     
    tokensTotal -= _value;

     
    emit Transfer(_from, address(0), _value);

     
    emit Burnt(msg.sender, _from, _value);
  }

}


 
contract SilverERC20 is GoldERC20 {
   
  uint32 public constant TOKEN_VERSION = 0x30;

   
  string public constant symbol = "SLV";

   
  string public constant name = "SILVER - CryptoMiner World";

}