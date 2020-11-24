 

pragma solidity 0.4.24;

 
contract DependentOnIPFS {
   
  function isValidIPFSMultihash(bytes _multihashBytes) internal pure returns (bool) {
    require(_multihashBytes.length > 2);

    uint8 _size;

     
     
    assembly {
       
      _size := byte(0, mload(add(_multihashBytes, 33)))
    }

    return (_multihashBytes.length == _size + 2);
  }
}

 
contract Poll is DependentOnIPFS {
   
   

  bytes public pollDataMultihash;
  uint16 public numChoices;
  uint256 public startTime;
  uint256 public endTime;
  address public author;
  address public pollAdmin;

  AccountRegistryInterface public registry;
  SigningLogicInterface public signingLogic;

  mapping(uint256 => uint16) public votes;

  mapping (bytes32 => bool) public usedSignatures;

  event VoteCast(address indexed voter, uint16 indexed choice);

  constructor(
    bytes _ipfsHash,
    uint16 _numChoices,
    uint256 _startTime,
    uint256 _endTime,
    address _author,
    AccountRegistryInterface _registry,
    SigningLogicInterface _signingLogic,
    address _pollAdmin
  ) public {
    require(_startTime >= now && _endTime > _startTime);
    require(isValidIPFSMultihash(_ipfsHash));

    numChoices = _numChoices;
    startTime = _startTime;
    endTime = _endTime;
    pollDataMultihash = _ipfsHash;
    author = _author;
    registry = _registry;
    signingLogic = _signingLogic;
    pollAdmin = _pollAdmin;
  }

  function vote(uint16 _choice) external {
    voteForUser(_choice, msg.sender);
  }

  function voteFor(uint16 _choice, address _voter, bytes32 _nonce, bytes _delegationSig) external onlyPollAdmin {
    require(!usedSignatures[keccak256(abi.encodePacked(_delegationSig))], "Signature not unique");
    usedSignatures[keccak256(abi.encodePacked(_delegationSig))] = true;
    bytes32 _delegationDigest = signingLogic.generateVoteForDelegationSchemaHash(
      _choice,
      _voter,
      _nonce,
      this
    );
    require(_voter == signingLogic.recoverSigner(_delegationDigest, _delegationSig));
    voteForUser(_choice, _voter);
  }

   
  function voteForUser(uint16 _choice, address _voter) internal duringPoll {
     
    require(_choice <= numChoices && _choice > 0);
    uint256 _voterId = registry.accountIdForAddress(_voter);

    votes[_voterId] = _choice;
    emit VoteCast(_voter, _choice);
  }

  modifier duringPoll {
    require(now >= startTime && now <= endTime);
    _;
  }

  modifier onlyPollAdmin {
    require(msg.sender == pollAdmin);
    _;
  }
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

 
contract VotingCenter {
  Poll[] public polls;

  event PollCreated(address indexed poll, address indexed author);

   
  function createPoll(
    bytes _ipfsHash,
    uint16 _numOptions,
    uint256 _startTime,
    uint256 _endTime,
    AccountRegistryInterface _registry,
    SigningLogicInterface _signingLogic,
    address _pollAdmin
  ) public returns (address) {
    Poll newPoll = new Poll(
      _ipfsHash,
      _numOptions,
      _startTime,
      _endTime,
      msg.sender,
      _registry,
      _signingLogic,
      _pollAdmin
      );
    polls.push(newPoll);

    emit PollCreated(newPoll, msg.sender);

    return newPoll;
  }

  function allPolls() view public returns (Poll[]) {
    return polls;
  }

  function numPolls() view public returns (uint256) {
    return polls.length;
  }
}