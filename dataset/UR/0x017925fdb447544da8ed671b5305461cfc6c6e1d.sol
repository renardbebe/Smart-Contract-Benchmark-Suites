 

pragma solidity 0.4.24;

 
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


contract SigningLogicInterface {
  function recoverSigner(bytes32 _hash, bytes _sig) external pure returns (address);
  function generateRequestAttestationSchemaHash(
    address _subject,
    address _attester,
    address _requester,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateAttestForDelegationSchemaHash(
    address _subject,
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce
    ) external view returns (bytes32);
  function generateContestForDelegationSchemaHash(
    address _requester,
    uint256 _reward,
    bytes32 _paymentNonce
  ) external view returns (bytes32);
  function generateStakeForDelegationSchemaHash(
    address _subject,
    uint256 _value,
    bytes32 _paymentNonce,
    bytes32 _dataHash,
    uint256[] _typeIds,
    bytes32 _requestNonce,
    uint256 _stakeDuration
    ) external view returns (bytes32);
  function generateRevokeStakeForDelegationSchemaHash(
    uint256 _subjectId,
    uint256 _attestationId
    ) external view returns (bytes32);
  function generateAddAddressSchemaHash(
    address _senderAddress,
    bytes32 _nonce
    ) external view returns (bytes32);
  function generateVoteForDelegationSchemaHash(
    uint16 _choice,
    address _voter,
    bytes32 _nonce,
    address _poll
    ) external view returns (bytes32);
  function generateReleaseTokensSchemaHash(
    address _sender,
    address _receiver,
    uint256 _amount,
    bytes32 _uuid
    ) external view returns (bytes32);
  function generateLockupTokensDelegationSchemaHash(
    address _sender,
    uint256 _amount,
    bytes32 _nonce
    ) external view returns (bytes32);
}

interface AccountRegistryInterface {
  function accountIdForAddress(address _address) public view returns (uint256);
  function addressBelongsToAccount(address _address) public view returns (bool);
  function createNewAccount(address _newUser) external;
  function addAddressToAccount(
    address _newAddress,
    address _sender
    ) external;
  function removeAddressFromAccount(address _addressToRemove) external;
}

 
contract AccountRegistryLogic is Ownable{

  SigningLogicInterface public signingLogic;
  AccountRegistryInterface public registry;
  address public registryAdmin;

   
  constructor(
    SigningLogicInterface _signingLogic,
    AccountRegistryInterface _registry
    ) public {
    signingLogic = _signingLogic;
    registry = _registry;
    registryAdmin = owner;
  }

  event AccountCreated(uint256 indexed accountId, address indexed newUser);
  event InviteCreated(address indexed inviter, address indexed inviteAddress);
  event InviteAccepted(address recipient, address indexed inviteAddress);
  event AddressAdded(uint256 indexed accountId, address indexed newAddress);
  event AddressRemoved(uint256 indexed accountId, address indexed oldAddress);
  event RegistryAdminChanged(address oldRegistryAdmin, address newRegistryAdmin);
  event SigningLogicChanged(address oldSigningLogic, address newSigningLogic);
  event AccountRegistryChanged(address oldRegistry, address newRegistry);

   
  modifier onlyNonUser {
    require(!registry.addressBelongsToAccount(msg.sender));
    _;
  }

   
  modifier onlyUser {
    require(registry.addressBelongsToAccount(msg.sender));
    _;
  }

   
  modifier nonZero(address _address) {
    require(_address != 0);
    _;
  }

   
  modifier onlyRegistryAdmin {
    require(msg.sender == registryAdmin);
    _;
  }

   
   
  mapping (bytes32 => bool) public usedSignatures;

   
   
   
   
  mapping(address => bool) public pendingInvites;

   
  function setSigningLogic(SigningLogicInterface _newSigningLogic) public nonZero(_newSigningLogic) onlyOwner {
    address oldSigningLogic = signingLogic;
    signingLogic = _newSigningLogic;
    emit SigningLogicChanged(oldSigningLogic, signingLogic);
  }

   
  function setRegistryAdmin(address _newRegistryAdmin) public onlyOwner nonZero(_newRegistryAdmin) {
    address _oldRegistryAdmin = registryAdmin;
    registryAdmin = _newRegistryAdmin;
    emit RegistryAdminChanged(_oldRegistryAdmin, registryAdmin);
  }

   
  function setAccountRegistry(AccountRegistryInterface _newRegistry) public nonZero(_newRegistry) onlyOwner {
    address oldRegistry = registry;
    registry = _newRegistry;
    emit AccountRegistryChanged(oldRegistry, registry);
  }

   
  function createInvite(bytes _sig) public onlyUser {
    address inviteAddress = signingLogic.recoverSigner(keccak256(abi.encodePacked(msg.sender)), _sig);
    require(!pendingInvites[inviteAddress]);
    pendingInvites[inviteAddress] = true;
    emit InviteCreated(msg.sender, inviteAddress);
  }

   
  function acceptInvite(bytes _sig) public onlyNonUser {
    address inviteAddress = signingLogic.recoverSigner(keccak256(abi.encodePacked(msg.sender)), _sig);
    require(pendingInvites[inviteAddress]);
    pendingInvites[inviteAddress] = false;
    createAccountForUser(msg.sender);
    emit InviteAccepted(msg.sender, inviteAddress);
  }

   
  function createAccount(address _newUser) public onlyRegistryAdmin {
    createAccountForUser(_newUser);
  }

   
  function createAccountForUser(address _newUser) internal nonZero(_newUser) {
    registry.createNewAccount(_newUser);
    uint256 _accountId = registry.accountIdForAddress(_newUser);
    emit AccountCreated(_accountId, _newUser);
  }

   
  function addAddressToAccountFor(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    address _sender,
    bytes32 _nonce
    ) public onlyRegistryAdmin {
    addAddressToAccountForUser(_newAddress, _newAddressSig, _senderSig, _sender, _nonce);
  }

   
  function addAddressToAccount(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    bytes32 _nonce
    ) public onlyUser {
    addAddressToAccountForUser(_newAddress, _newAddressSig, _senderSig, msg.sender, _nonce);
  }

   
  function addAddressToAccountForUser(
    address _newAddress,
    bytes _newAddressSig,
    bytes _senderSig,
    address _sender,
    bytes32 _nonce
    ) private nonZero(_newAddress) {

    require(!usedSignatures[keccak256(abi.encodePacked(_newAddressSig))], "Signature not unique");
    require(!usedSignatures[keccak256(abi.encodePacked(_senderSig))], "Signature not unique");

    usedSignatures[keccak256(abi.encodePacked(_newAddressSig))] = true;
    usedSignatures[keccak256(abi.encodePacked(_senderSig))] = true;

     
    bytes32 _currentAddressDigest = signingLogic.generateAddAddressSchemaHash(_newAddress, _nonce);
    require(_sender == signingLogic.recoverSigner(_currentAddressDigest, _senderSig));

     
    bytes32 _newAddressDigest = signingLogic.generateAddAddressSchemaHash(_sender, _nonce);
    require(_newAddress == signingLogic.recoverSigner(_newAddressDigest, _newAddressSig));

    registry.addAddressToAccount(_newAddress, _sender);
    uint256 _accountId = registry.accountIdForAddress(_newAddress);
    emit AddressAdded(_accountId, _newAddress);
  }

   
  function removeAddressFromAccountFor(
    address _addressToRemove
  ) public onlyRegistryAdmin {
    uint256 _accountId = registry.accountIdForAddress(_addressToRemove);
    registry.removeAddressFromAccount(_addressToRemove);
    emit AddressRemoved(_accountId, _addressToRemove);
  }
}