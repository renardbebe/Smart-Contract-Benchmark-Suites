 

pragma solidity ^0.4.23;

 

 
contract GrapevineWhitelistInterface {

   
  function whitelist(address _address) view external returns (bool);

 
   
  function handleOffchainWhitelisted(address _addr, bytes _sig) external returns (bool);
}

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract SignatureBouncer is Ownable, RBAC {
  using ECRecovery for bytes32;

  string public constant ROLE_BOUNCER = "bouncer";

   
  modifier onlyValidSignature(bytes _sig)
  {
    require(isValidSignature(msg.sender, _sig));
    _;
  }

   
  function addBouncer(address _bouncer)
    onlyOwner
    public
  {
    require(_bouncer != address(0));
    addRole(_bouncer, ROLE_BOUNCER);
  }

   
  function removeBouncer(address _bouncer)
    onlyOwner
    public
  {
    require(_bouncer != address(0));
    removeRole(_bouncer, ROLE_BOUNCER);
  }

   
  function isValidSignature(address _address, bytes _sig)
    internal
    view
    returns (bool)
  {
    return isValidDataHash(
      keccak256(address(this), _address),
      _sig
    );
  }

   
  function isValidDataHash(bytes32 hash, bytes _sig)
    internal
    view
    returns (bool)
  {
    address signer = hash
      .toEthSignedMessageHash()
      .recover(_sig);
    return hasRole(signer, ROLE_BOUNCER);
  }
}

 

 
contract GrapevineWhitelist is SignatureBouncer, GrapevineWhitelistInterface {

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);
  event UselessEvent(address addr, bytes sign, bool ret);

  mapping(address => bool) public whitelist;

  address crowdsale;

  constructor(address _signer) public {
    require(_signer != address(0));
    addBouncer(_signer);
  }

  modifier onlyOwnerOrCrowdsale() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

   
  function whitelist(address _address) view external returns (bool) {
    return whitelist[_address];
  }
  
   
  function setCrowdsale(address _crowdsale) external onlyOwner {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

   
  function addAddressesToWhitelist(address[] _beneficiaries) external onlyOwnerOrCrowdsale {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      addAddressToWhitelist(_beneficiaries[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _beneficiary) external onlyOwnerOrCrowdsale {
    whitelist[_beneficiary] = false;
    emit WhitelistedAddressRemoved(_beneficiary);
  }

   
  function handleOffchainWhitelisted(address _addr, bytes _sig) external onlyOwnerOrCrowdsale returns (bool) {
    bool valid;
     
    if (whitelist[_addr]) {
      valid = true;
    } else {
      valid = isValidSignature(_addr, _sig);
      if (valid) {
         
        addAddressToWhitelist(_addr);
      }
    }
    return valid;
  }

   
  function addAddressToWhitelist(address _beneficiary) public onlyOwnerOrCrowdsale {
    whitelist[_beneficiary] = true;
    emit WhitelistedAddressAdded(_beneficiary);
  }
}