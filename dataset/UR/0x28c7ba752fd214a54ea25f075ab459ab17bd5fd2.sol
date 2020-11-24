 

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

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
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

}


 
contract SigningLogic {

   
   
  mapping (bytes32 => bool) public usedSignatures;

  function burnSignatureDigest(bytes32 _signatureDigest, address _sender) internal {
    bytes32 _txDataHash = keccak256(abi.encode(_signatureDigest, _sender));
    require(!usedSignatures[_txDataHash], "Signature not unique");
    usedSignatures[_txDataHash] = true;
  }

  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );

  bytes32 constant ATTESTATION_REQUEST_TYPEHASH = keccak256(
    "AttestationRequest(bytes32 dataHash,bytes32 nonce)"
  );

  bytes32 constant ADD_ADDRESS_TYPEHASH = keccak256(
    "AddAddress(address addressToAdd,bytes32 nonce)"
  );

  bytes32 constant REMOVE_ADDRESS_TYPEHASH = keccak256(
    "RemoveAddress(address addressToRemove,bytes32 nonce)"
  );

  bytes32 constant PAY_TOKENS_TYPEHASH = keccak256(
    "PayTokens(address sender,address receiver,uint256 amount,bytes32 nonce)"
  );

  bytes32 constant RELEASE_TOKENS_FOR_TYPEHASH = keccak256(
    "ReleaseTokensFor(address sender,uint256 amount,bytes32 nonce)"
  );

  bytes32 constant ATTEST_FOR_TYPEHASH = keccak256(
    "AttestFor(address subject,address requester,uint256 reward,bytes32 dataHash,bytes32 requestNonce)"
  );

  bytes32 constant CONTEST_FOR_TYPEHASH = keccak256(
    "ContestFor(address requester,uint256 reward,bytes32 requestNonce)"
  );

  bytes32 constant REVOKE_ATTESTATION_FOR_TYPEHASH = keccak256(
    "RevokeAttestationFor(bytes32 link,bytes32 nonce)"
  );

  bytes32 constant VOTE_FOR_TYPEHASH = keccak256(
    "VoteFor(uint16 choice,address voter,bytes32 nonce,address poll)"
  );

  bytes32 constant LOCKUP_TOKENS_FOR_TYPEHASH = keccak256(
    "LockupTokensFor(address sender,uint256 amount,bytes32 nonce)"
  );

  bytes32 DOMAIN_SEPARATOR;

  constructor (string name, string version, uint256 chainId) public {
    DOMAIN_SEPARATOR = hash(EIP712Domain({
      name: name,
      version: version,
      chainId: chainId,
      verifyingContract: this
    }));
  }

  struct EIP712Domain {
      string  name;
      string  version;
      uint256 chainId;
      address verifyingContract;
  }

  function hash(EIP712Domain eip712Domain) private pure returns (bytes32) {
    return keccak256(abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(eip712Domain.name)),
      keccak256(bytes(eip712Domain.version)),
      eip712Domain.chainId,
      eip712Domain.verifyingContract
    ));
  }

  struct AttestationRequest {
      bytes32 dataHash;
      bytes32 nonce;
  }

  function hash(AttestationRequest request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      ATTESTATION_REQUEST_TYPEHASH,
      request.dataHash,
      request.nonce
    ));
  }

  struct AddAddress {
      address addressToAdd;
      bytes32 nonce;
  }

  function hash(AddAddress request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      ADD_ADDRESS_TYPEHASH,
      request.addressToAdd,
      request.nonce
    ));
  }

  struct RemoveAddress {
      address addressToRemove;
      bytes32 nonce;
  }

  function hash(RemoveAddress request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      REMOVE_ADDRESS_TYPEHASH,
      request.addressToRemove,
      request.nonce
    ));
  }

  struct PayTokens {
      address sender;
      address receiver;
      uint256 amount;
      bytes32 nonce;
  }

  function hash(PayTokens request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      PAY_TOKENS_TYPEHASH,
      request.sender,
      request.receiver,
      request.amount,
      request.nonce
    ));
  }

  struct AttestFor {
      address subject;
      address requester;
      uint256 reward;
      bytes32 dataHash;
      bytes32 requestNonce;
  }

  function hash(AttestFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      ATTEST_FOR_TYPEHASH,
      request.subject,
      request.requester,
      request.reward,
      request.dataHash,
      request.requestNonce
    ));
  }

  struct ContestFor {
      address requester;
      uint256 reward;
      bytes32 requestNonce;
  }

  function hash(ContestFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      CONTEST_FOR_TYPEHASH,
      request.requester,
      request.reward,
      request.requestNonce
    ));
  }

  struct RevokeAttestationFor {
      bytes32 link;
      bytes32 nonce;
  }

  function hash(RevokeAttestationFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      REVOKE_ATTESTATION_FOR_TYPEHASH,
      request.link,
      request.nonce
    ));
  }

  struct VoteFor {
      uint16 choice;
      address voter;
      bytes32 nonce;
      address poll;
  }

  function hash(VoteFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      VOTE_FOR_TYPEHASH,
      request.choice,
      request.voter,
      request.nonce,
      request.poll
    ));
  }

  struct LockupTokensFor {
    address sender;
    uint256 amount;
    bytes32 nonce;
  }

  function hash(LockupTokensFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      LOCKUP_TOKENS_FOR_TYPEHASH,
      request.sender,
      request.amount,
      request.nonce
    ));
  }

  struct ReleaseTokensFor {
    address sender;
    uint256 amount;
    bytes32 nonce;
  }

  function hash(ReleaseTokensFor request) private pure returns (bytes32) {
    return keccak256(abi.encode(
      RELEASE_TOKENS_FOR_TYPEHASH,
      request.sender,
      request.amount,
      request.nonce
    ));
  }

  function generateRequestAttestationSchemaHash(
    bytes32 _dataHash,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(AttestationRequest(
          _dataHash,
          _nonce
        ))
      )
      );
  }

  function generateAddAddressSchemaHash(
    address _addressToAdd,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(AddAddress(
          _addressToAdd,
          _nonce
        ))
      )
      );
  }

  function generateRemoveAddressSchemaHash(
    address _addressToRemove,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(RemoveAddress(
          _addressToRemove,
          _nonce
        ))
      )
      );
  }

  function generatePayTokensSchemaHash(
    address _sender,
    address _receiver,
    uint256 _amount,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(PayTokens(
          _sender,
          _receiver,
          _amount,
          _nonce
        ))
      )
      );
  }

  function generateAttestForDelegationSchemaHash(
    address _subject,
    address _requester,
    uint256 _reward,
    bytes32 _dataHash,
    bytes32 _requestNonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(AttestFor(
          _subject,
          _requester,
          _reward,
          _dataHash,
          _requestNonce
        ))
      )
      );
  }

  function generateContestForDelegationSchemaHash(
    address _requester,
    uint256 _reward,
    bytes32 _requestNonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(ContestFor(
          _requester,
          _reward,
          _requestNonce
        ))
      )
      );
  }

  function generateRevokeAttestationForDelegationSchemaHash(
    bytes32 _link,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(RevokeAttestationFor(
          _link,
          _nonce
        ))
      )
      );
  }

  function generateVoteForDelegationSchemaHash(
    uint16 _choice,
    address _voter,
    bytes32 _nonce,
    address _poll
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(VoteFor(
          _choice,
          _voter,
          _nonce,
          _poll
        ))
      )
      );
  }

  function generateLockupTokensDelegationSchemaHash(
    address _sender,
    uint256 _amount,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(LockupTokensFor(
          _sender,
          _amount,
          _nonce
        ))
      )
      );
  }

  function generateReleaseTokensDelegationSchemaHash(
    address _sender,
    uint256 _amount,
    bytes32 _nonce
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        hash(ReleaseTokensFor(
          _sender,
          _amount,
          _nonce
        ))
      )
      );
  }

  function recoverSigner(bytes32 _hash, bytes _sig) internal pure returns (address) {
    address signer = ECRecovery.recover(_hash, _sig);
    require(signer != address(0));

    return signer;
  }
}


 
contract Initializable {
  address public initializer;
  bool public initializing;

  event InitializationEnded();

   
  constructor(address _initializer) public {
    initializer = _initializer;
    initializing = true;
  }

   
  modifier onlyDuringInitialization() {
    require(msg.sender == initializer, 'Method can only be called by initializer');
    require(initializing, 'Method can only be called during initialization');
    _;
  }

   
  function endInitialization() public onlyDuringInitialization {
    initializing = false;
    emit InitializationEnded();
  }

}


 
contract AccountRegistryLogic is Initializable, SigningLogic {
   
  constructor(
    address _initializer
  ) public Initializable(_initializer) SigningLogic("Bloom Account Registry", "2", 1) {}

  event AddressLinked(address indexed currentAddress, address indexed newAddress, uint256 indexed linkId);
  event AddressUnlinked(address indexed addressToRemove);

   
  uint256 linkCounter;
  mapping(address => uint256) public linkIds;

   
  function linkAddresses(
    address _currentAddress,
    bytes _currentAddressSig,
    address _newAddress,
    bytes _newAddressSig,
    bytes32 _nonce
    ) external {
       
      require(linkIds[_newAddress] == 0);
       
      validateLinkSignature(_currentAddress, _newAddress, _nonce, _currentAddressSig);

       
      validateLinkSignature(_newAddress, _currentAddress, _nonce, _newAddressSig);

       
      if (linkIds[_currentAddress] == 0) {
        linkIds[_currentAddress] = ++linkCounter;
      }
      linkIds[_newAddress] = linkIds[_currentAddress];

      emit AddressLinked(_currentAddress, _newAddress, linkIds[_currentAddress]);
  }

   
  function unlinkAddress(
    address _addressToRemove,
    bytes32 _nonce,
    bytes _unlinkSignature
  ) external {
     
    validateUnlinkSignature(_addressToRemove, _nonce, _unlinkSignature);
    linkIds[_addressToRemove] = 0;

    emit AddressUnlinked(_addressToRemove);
  }

   
  function validateLinkSignature(
    address _currentAddress,
    address _addressToAdd,
    bytes32 _nonce,
    bytes _linkSignature
  ) private {
    bytes32 _signatureDigest = generateAddAddressSchemaHash(_addressToAdd, _nonce);
    require(_currentAddress == recoverSigner(_signatureDigest, _linkSignature));
    burnSignatureDigest(_signatureDigest, _currentAddress);
  }

   
  function validateUnlinkSignature(
    address _addressToRemove,
    bytes32 _nonce,
    bytes _unlinkSignature
  ) private {

     
    require(linkIds[_addressToRemove] != 0, "Address does not have active link");

    bytes32 _signatureDigest = generateRemoveAddressSchemaHash(_addressToRemove, _nonce);

    require(_addressToRemove == recoverSigner(_signatureDigest, _unlinkSignature));
    burnSignatureDigest(_signatureDigest, _addressToRemove);
  }

   
  function migrateLink(
    address _currentAddress,
    address _newAddress
  ) external onlyDuringInitialization {
     
    require(linkIds[_newAddress] == 0);

     
    if (linkIds[_currentAddress] == 0) {
      linkIds[_currentAddress] = ++linkCounter;
    }
    linkIds[_newAddress] = linkIds[_currentAddress];

    emit AddressLinked(_currentAddress, _newAddress, linkIds[_currentAddress]);
  }

}

 
contract AttestationLogic is Initializable, SigningLogic{
    TokenEscrowMarketplace public tokenEscrowMarketplace;

   
  constructor(
    address _initializer,
    TokenEscrowMarketplace _tokenEscrowMarketplace
    ) Initializable(_initializer) SigningLogic("Bloom Attestation Logic", "2", 1) public {
    tokenEscrowMarketplace = _tokenEscrowMarketplace;
  }

  event TraitAttested(
    address subject,
    address attester,
    address requester,
    bytes32 dataHash
    );
  event AttestationRejected(address indexed attester, address indexed requester);
  event AttestationRevoked(bytes32 link, address attester);
  event TokenEscrowMarketplaceChanged(address oldTokenEscrowMarketplace, address newTokenEscrowMarketplace);

   
  function attest(
    address _subject,
    address _requester,
    uint256 _reward,
    bytes _requesterSig,
    bytes32 _dataHash,
    bytes32 _requestNonce,
    bytes _subjectSig  
  ) external {
    attestForUser(
      _subject,
      msg.sender,
      _requester,
      _reward,
      _requesterSig,
      _dataHash,
      _requestNonce,
      _subjectSig
    );
  }

   
  function attestFor(
    address _subject,
    address _attester,
    address _requester,
    uint256 _reward,
    bytes _requesterSig,
    bytes32 _dataHash,
    bytes32 _requestNonce,
    bytes _subjectSig,  
    bytes _delegationSig
  ) external {
     
    validateAttestForSig(_subject, _attester, _requester, _reward, _dataHash, _requestNonce, _delegationSig);
    attestForUser(
      _subject,
      _attester,
      _requester,
      _reward,
      _requesterSig,
      _dataHash,
      _requestNonce,
      _subjectSig
    );
  }

   
  function attestForUser(
    address _subject,
    address _attester,
    address _requester,
    uint256 _reward,
    bytes _requesterSig,
    bytes32 _dataHash,
    bytes32 _requestNonce,
    bytes _subjectSig
    ) private {
    
    validateSubjectSig(
      _subject,
      _dataHash,
      _requestNonce,
      _subjectSig
    );

    emit TraitAttested(
      _subject,
      _attester,
      _requester,
      _dataHash
    );

    if (_reward > 0) {
      tokenEscrowMarketplace.requestTokenPayment(_requester, _attester, _reward, _requestNonce, _requesterSig);
    }
  }

   
  function contest(
    address _requester,
    uint256 _reward,
    bytes32 _requestNonce,
    bytes _requesterSig
  ) external {
    contestForUser(
      msg.sender,
      _requester,
      _reward,
      _requestNonce,
      _requesterSig
    );
  }

   
  function contestFor(
    address _attester,
    address _requester,
    uint256 _reward,
    bytes32 _requestNonce,
    bytes _requesterSig,
    bytes _delegationSig
  ) external {
    validateContestForSig(
      _attester,
      _requester,
      _reward,
      _requestNonce,
      _delegationSig
    );
    contestForUser(
      _attester,
      _requester,
      _reward,
      _requestNonce,
      _requesterSig
    );
  }

   
  function contestForUser(
    address _attester,
    address _requester,
    uint256 _reward,
    bytes32 _requestNonce,
    bytes _requesterSig
    ) private {

    if (_reward > 0) {
      tokenEscrowMarketplace.requestTokenPayment(_requester, _attester, _reward, _requestNonce, _requesterSig);
    }
    emit AttestationRejected(_attester, _requester);
  }

   
  function validateSubjectSig(
    address _subject,
    bytes32 _dataHash,
    bytes32 _requestNonce,
    bytes _subjectSig
  ) private {
    bytes32 _signatureDigest = generateRequestAttestationSchemaHash(_dataHash, _requestNonce);
    require(_subject == recoverSigner(_signatureDigest, _subjectSig));
    burnSignatureDigest(_signatureDigest, _subject);
  }

   
  function validateAttestForSig(
    address _subject,
    address _attester,
    address _requester,
    uint256 _reward,
    bytes32 _dataHash,
    bytes32 _requestNonce,
    bytes _delegationSig
  ) private {
    bytes32 _delegationDigest = generateAttestForDelegationSchemaHash(_subject, _requester, _reward, _dataHash, _requestNonce);
    require(_attester == recoverSigner(_delegationDigest, _delegationSig), 'Invalid AttestFor Signature');
    burnSignatureDigest(_delegationDigest, _attester);
  }

   
  function validateContestForSig(
    address _attester,
    address _requester,
    uint256 _reward,
    bytes32 _requestNonce,
    bytes _delegationSig
  ) private {
    bytes32 _delegationDigest = generateContestForDelegationSchemaHash(_requester, _reward, _requestNonce);
    require(_attester == recoverSigner(_delegationDigest, _delegationSig), 'Invalid ContestFor Signature');
    burnSignatureDigest(_delegationDigest, _attester);
  }

   
  function migrateAttestation(
    address _requester,
    address _attester,
    address _subject,
    bytes32 _dataHash
  ) public onlyDuringInitialization {
    emit TraitAttested(
      _subject,
      _attester,
      _requester,
      _dataHash
    );
  }

   
  function revokeAttestation(
    bytes32 _link
    ) external {
      revokeAttestationForUser(_link, msg.sender);
  }

   
  function revokeAttestationFor(
    address _sender,
    bytes32 _link,
    bytes32 _nonce,
    bytes _delegationSig
    ) external {
      validateRevokeForSig(_sender, _link, _nonce, _delegationSig);
      revokeAttestationForUser(_link, _sender);
  }

   
  function validateRevokeForSig(
    address _sender,
    bytes32 _link,
    bytes32 _nonce,
    bytes _delegationSig
  ) private {
    bytes32 _delegationDigest = generateRevokeAttestationForDelegationSchemaHash(_link, _nonce);
    require(_sender == recoverSigner(_delegationDigest, _delegationSig), 'Invalid RevokeFor Signature');
    burnSignatureDigest(_delegationDigest, _sender);
  }

   
  function revokeAttestationForUser(
    bytes32 _link,
    address _sender
    ) private {
      emit AttestationRevoked(_link, _sender);
  }

     
  function setTokenEscrowMarketplace(TokenEscrowMarketplace _newTokenEscrowMarketplace) external onlyDuringInitialization {
    address oldTokenEscrowMarketplace = tokenEscrowMarketplace;
    tokenEscrowMarketplace = _newTokenEscrowMarketplace;
    emit TokenEscrowMarketplaceChanged(oldTokenEscrowMarketplace, tokenEscrowMarketplace);
  }

}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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



 
contract TokenEscrowMarketplace is SigningLogic {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  address public attestationLogic;

  mapping(address => uint256) public tokenEscrow;
  ERC20 public token;

  event TokenMarketplaceWithdrawal(address escrowPayer, uint256 amount);
  event TokenMarketplaceEscrowPayment(address escrowPayer, address escrowPayee, uint256 amount);
  event TokenMarketplaceDeposit(address escrowPayer, uint256 amount);

   
  constructor(
    ERC20 _token,
    address _attestationLogic
    ) public SigningLogic("Bloom Token Escrow Marketplace", "2", 1) {
    token = _token;
    attestationLogic = _attestationLogic;
  }

  modifier onlyAttestationLogic() {
    require(msg.sender == attestationLogic);
    _;
  }

   
  function moveTokensToEscrowLockupFor(
    address _sender,
    uint256 _amount,
    bytes32 _nonce,
    bytes _delegationSig
    ) external {
      validateLockupTokensSig(
        _sender,
        _amount,
        _nonce,
        _delegationSig
      );
      moveTokensToEscrowLockupForUser(_sender, _amount);
  }

   
  function validateLockupTokensSig(
    address _sender,
    uint256 _amount,
    bytes32 _nonce,
    bytes _delegationSig
  ) private {
    bytes32 _signatureDigest = generateLockupTokensDelegationSchemaHash(_sender, _amount, _nonce);
    require(_sender == recoverSigner(_signatureDigest, _delegationSig), 'Invalid LockupTokens Signature');
    burnSignatureDigest(_signatureDigest, _sender);
  }

   
  function moveTokensToEscrowLockup(uint256 _amount) external {
    moveTokensToEscrowLockupForUser(msg.sender, _amount);
  }

   
  function moveTokensToEscrowLockupForUser(
    address _sender,
    uint256 _amount
    ) private {
    token.safeTransferFrom(_sender, this, _amount);
    addToEscrow(_sender, _amount);
  }

   
  function releaseTokensFromEscrowFor(
    address _sender,
    uint256 _amount,
    bytes32 _nonce,
    bytes _delegationSig
    ) external {
      validateReleaseTokensSig(
        _sender,
        _amount,
        _nonce,
        _delegationSig
      );
      releaseTokensFromEscrowForUser(_sender, _amount);
  }

   
  function validateReleaseTokensSig(
    address _sender,
    uint256 _amount,
    bytes32 _nonce,
    bytes _delegationSig

  ) private {
    bytes32 _signatureDigest = generateReleaseTokensDelegationSchemaHash(_sender, _amount, _nonce);
    require(_sender == recoverSigner(_signatureDigest, _delegationSig), 'Invalid ReleaseTokens Signature');
    burnSignatureDigest(_signatureDigest, _sender);
  }

   
  function releaseTokensFromEscrow(uint256 _amount) external {
    releaseTokensFromEscrowForUser(msg.sender, _amount);
  }

   
  function releaseTokensFromEscrowForUser(
    address _payer,
    uint256 _amount
    ) private {
      subFromEscrow(_payer, _amount);
      token.safeTransfer(_payer, _amount);
      emit TokenMarketplaceWithdrawal(_payer, _amount);
  }

   
  function payTokensFromEscrow(address _payer, address _receiver, uint256 _amount) private {
    subFromEscrow(_payer, _amount);
    token.safeTransfer(_receiver, _amount);
  }

   
  function requestTokenPayment(
    address _payer,
    address _receiver,
    uint256 _amount,
    bytes32 _nonce,
    bytes _paymentSig
    ) external onlyAttestationLogic {

    validatePaymentSig(
      _payer,
      _receiver,
      _amount,
      _nonce,
      _paymentSig
    );
    payTokensFromEscrow(_payer, _receiver, _amount);
    emit TokenMarketplaceEscrowPayment(_payer, _receiver, _amount);
  }

   
  function validatePaymentSig(
    address _payer,
    address _receiver,
    uint256 _amount,
    bytes32 _nonce,
    bytes _paymentSig

  ) private {
    bytes32 _signatureDigest = generatePayTokensSchemaHash(_payer, _receiver, _amount, _nonce);
    require(_payer == recoverSigner(_signatureDigest, _paymentSig), 'Invalid Payment Signature');
    burnSignatureDigest(_signatureDigest, _payer);
  }

   
  function addToEscrow(address _from, uint256 _amount) private {
    tokenEscrow[_from] = tokenEscrow[_from].add(_amount);
    emit TokenMarketplaceDeposit(_from, _amount);
  }

   
  function subFromEscrow(address _from, uint256 _amount) private {
    require(tokenEscrow[_from] >= _amount);
    tokenEscrow[_from] = tokenEscrow[_from].sub(_amount);
  }
}

contract BatchInitializer is Ownable{

  AccountRegistryLogic public registryLogic;
  AttestationLogic public attestationLogic;
  address public admin;

  constructor(
    AttestationLogic _attestationLogic,
    AccountRegistryLogic _registryLogic
    ) public {
    attestationLogic = _attestationLogic;
    registryLogic = _registryLogic;
    admin = owner;
  }

  event linkSkipped(address currentAddress, address newAddress);

   
  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

   
  function setAdmin(address _newAdmin) external onlyOwner {
    admin = _newAdmin;
  }

  function setRegistryLogic(AccountRegistryLogic _newRegistryLogic) external onlyOwner {
    registryLogic = _newRegistryLogic;
  }

  function setAttestationLogic(AttestationLogic _newAttestationLogic) external onlyOwner {
    attestationLogic = _newAttestationLogic;
  }

  function setTokenEscrowMarketplace(TokenEscrowMarketplace _newMarketplace) external onlyOwner {
    attestationLogic.setTokenEscrowMarketplace(_newMarketplace);
  }

  function endInitialization(Initializable _initializable) external onlyOwner {
    _initializable.endInitialization();
  }

  function batchLinkAddresses(address[] _currentAddresses, address[] _newAddresses) external onlyAdmin {
    require(_currentAddresses.length == _newAddresses.length);
    for (uint256 i = 0; i < _currentAddresses.length; i++) {
      if (registryLogic.linkIds(_newAddresses[i]) > 0) {
        emit linkSkipped(_currentAddresses[i], _newAddresses[i]);
      } else {
        registryLogic.migrateLink(_currentAddresses[i], _newAddresses[i]);
      }
    }
  }

  function batchMigrateAttestations(
    address[] _requesters,
    address[] _attesters,
    address[] _subjects,
    bytes32[] _dataHashes
    ) external onlyAdmin {
    require(
      _requesters.length == _attesters.length &&
      _requesters.length == _subjects.length &&
      _requesters.length == _dataHashes.length
      );
     
    for (uint256 i = 0; i < _requesters.length; i++) {
      attestationLogic.migrateAttestation(
        _requesters[i],
        _attesters[i],
        _subjects[i],
        _dataHashes[i]
        );
    }
  }
}