 

 

 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

interface CryptoLegacyBaseAPI {
  function getVersion() external view returns (uint);
  function getOwner() external view returns (address);
  function getContinuationContractAddress() external view returns (address);
  function isAcceptingKeeperProposals() external view returns (bool);
}

 

contract CryptoLegacy is CryptoLegacyBaseAPI {

   
  uint public constant VERSION = 3;

  event KeysNeeded();
  event ContinuationContractAnnounced(address continuationContractAddress);
  event Cancelled();

  enum States {
    CallForKeepers,
    Active,
    CallForKeys,
    Cancelled
  }

  modifier atState(States _state) {
    require(state == _state, "0");  
    _;
  }

  modifier atEitherOfStates(States state1, States state2) {
    require(state == state1 || state == state2, "1");  
    _;
  }

  modifier ownerOnly() {
    require(msg.sender == owner, "2");  
    _;
  }

  modifier activeKeepersOnly() {
    require(isActiveKeeper(msg.sender), "3");  
    _;
  }

  struct KeeperProposal {
    address keeperAddress;
    bytes publicKey;  
    uint keepingFee;
  }

  struct ActiveKeeper {
    bytes publicKey;  
    bytes32 keyPartHash;  
    uint keepingFee;
    uint balance;
    uint lastCheckInAt;
    bool keyPartSupplied;
  }

  struct EncryptedData {
    bytes encryptedData;
    bytes16 aesCounter;
    bytes32 dataHash;  
    uint16 shareLength;
    bytes[] suppliedKeyParts;
  }

  struct ActiveKeeperDescription {
    address keeperAddress;
    uint balance;
    uint lastCheckInAt;
    bool keyPartSupplied;
  }

  struct Description {
    States state;
    uint checkInInterval;
    uint lastOwnerCheckInAt;
    KeeperProposal[] proposals;
    ActiveKeeperDescription[] keepers;
    uint checkInPrice;
  }

  address public owner;

   
   
  address public continuationContractAddress = address(0);

  uint public checkInInterval;
  uint public lastOwnerCheckInAt;

  States public state = States.CallForKeepers;

  bytes[] public encryptedKeyPartsChunks;
  EncryptedData public encryptedData;

  KeeperProposal[] public keeperProposals;
  mapping(address => bool) public proposedKeeperFlags;
  mapping(bytes32 => bool) private proposedPublicKeyHashes;

  mapping(address => ActiveKeeper) public activeKeepers;
  address[] public activeKeepersAddresses;

   
  uint public totalKeepingFee;

   
   
   
  uint public constant KEEPING_FEE_ROUNDING_MULT = 1 ether;

   
  uint public constant MINIMUM_CHECK_IN_INTERVAL = 1 minutes;


   
   
   
  constructor(address _owner, uint _checkInInterval) public {
    require(_checkInInterval >= MINIMUM_CHECK_IN_INTERVAL, "4");  
    require(_owner != address(0), "5");  
    owner = _owner;
    checkInInterval = _checkInInterval;
  }


  function describe() external view returns (Description memory) {
    ActiveKeeperDescription[] memory keepers = new ActiveKeeperDescription[](activeKeepersAddresses.length);

    for (uint i = 0; i < activeKeepersAddresses.length; i++) {
      address addr = activeKeepersAddresses[i];
      ActiveKeeper storage keeper = activeKeepers[addr];
      keepers[i] = ActiveKeeperDescription({
        keeperAddress: addr,
        balance: keeper.balance,
        lastCheckInAt: keeper.lastCheckInAt,
        keyPartSupplied: keeper.keyPartSupplied
      });
    }

    return Description({
      state: state,
      checkInInterval: checkInInterval,
      lastOwnerCheckInAt: lastOwnerCheckInAt,
      proposals: keeperProposals,
      keepers: keepers,
      checkInPrice: canCheckIn() ? calculateApproximateCheckInPrice() : 0
    });
  }


  function getVersion() public view returns (uint) {
    return VERSION;
  }


  function getOwner() public view returns (address) {
    return owner;
  }


  function getContinuationContractAddress() public view returns (address) {
    return continuationContractAddress;
  }


  function canCheckIn() public view returns (bool) {
    if (state != States.Active) {
      return false;
    }
    uint timeSinceLastOwnerCheckIn = SafeMath.sub(getBlockTimestamp(), lastOwnerCheckInAt);
    return timeSinceLastOwnerCheckIn <= checkInInterval;
  }


  function isAcceptingKeeperProposals() public view returns (bool) {
    return state == States.CallForKeepers;
  }


  function getNumProposals() external view returns (uint) {
    return keeperProposals.length;
  }


  function getNumKeepers() external view returns (uint) {
    return activeKeepersAddresses.length;
  }


  function getNumEncryptedKeyPartsChunks() external view returns (uint) {
    return encryptedKeyPartsChunks.length;
  }


  function getEncryptedKeyPartsChunk(uint index) external view returns (bytes memory) {
    return encryptedKeyPartsChunks[index];
  }


  function getNumSuppliedKeyParts() external view returns (uint) {
    return encryptedData.suppliedKeyParts.length;
  }


  function getSuppliedKeyPart(uint index) external view returns (bytes memory) {
    return encryptedData.suppliedKeyParts[index];
  }

  function isActiveKeeper(address addr) public view returns (bool) {
    return activeKeepers[addr].lastCheckInAt > 0;
  }

  function didSendProposal(address addr) public view returns (bool) {
    return proposedKeeperFlags[addr];
  }


   
   
  function submitKeeperProposal(bytes calldata publicKey, uint keepingFee) external
    atState(States.CallForKeepers)
  {
    require(msg.sender != owner, "6");  
    require(!didSendProposal(msg.sender), "7");  
    require(publicKey.length <= 128, "8");  

    bytes32 publicKeyHash = keccak256(publicKey);

     
    require(!proposedPublicKeyHashes[publicKeyHash], "9");

    keeperProposals.push(KeeperProposal({
      keeperAddress: msg.sender,
      publicKey: publicKey,
      keepingFee: keepingFee
    }));

    proposedKeeperFlags[msg.sender] = true;
    proposedPublicKeyHashes[publicKeyHash] = true;
  }

   
   
  function calculateActivationPrice(uint[] memory selectedProposalIndices) public view returns (uint) {
    uint _totalKeepingFee = 0;

    for (uint i = 0; i < selectedProposalIndices.length; i++) {
      uint proposalIndex = selectedProposalIndices[i];
      KeeperProposal storage proposal = keeperProposals[proposalIndex];
      _totalKeepingFee = SafeMath.add(_totalKeepingFee, proposal.keepingFee);
    }

    return _totalKeepingFee;
  }

  function acceptKeepersAndActivate(
    uint16 shareLength,
    bytes32 dataHash,
    bytes16 aesCounter,
    uint[] calldata selectedProposalIndices,
    bytes32[] calldata keyPartHashes,
    bytes calldata encryptedKeyParts,
    bytes calldata _encryptedData
  ) payable external
  {
    acceptKeepers(selectedProposalIndices, keyPartHashes, encryptedKeyParts);
    activate(shareLength, _encryptedData, dataHash, aesCounter);
  }

   
   
   
  function acceptKeepers(
    uint[] memory selectedProposalIndices,
    bytes32[] memory keyPartHashes,
    bytes memory encryptedKeyParts
  ) public
    ownerOnly()
    atState(States.CallForKeepers)
  {
     
    require(selectedProposalIndices.length > 0, "10");
     
    require(keyPartHashes.length == selectedProposalIndices.length, "11");
     
    require(encryptedKeyParts.length > 0, "12");

    uint timestamp = getBlockTimestamp();
    uint chunkKeepingFee = 0;

    for (uint i = 0; i < selectedProposalIndices.length; i++) {
      uint proposalIndex = selectedProposalIndices[i];
      KeeperProposal storage proposal = keeperProposals[proposalIndex];

       
      require(activeKeepers[proposal.keeperAddress].lastCheckInAt == 0, "13");

      activeKeepers[proposal.keeperAddress] = ActiveKeeper({
        publicKey: proposal.publicKey,
        keyPartHash: keyPartHashes[i],
        keepingFee: proposal.keepingFee,
        lastCheckInAt: timestamp,
        balance: 0,
        keyPartSupplied: false
      });

      activeKeepersAddresses.push(proposal.keeperAddress);
      chunkKeepingFee = SafeMath.add(chunkKeepingFee, proposal.keepingFee);
    }

    totalKeepingFee = SafeMath.add(totalKeepingFee, chunkKeepingFee);
    encryptedKeyPartsChunks.push(encryptedKeyParts);
  }

   
   
   
  function activate(
    uint16 shareLength,
    bytes memory _encryptedData,
    bytes32 dataHash,
    bytes16 aesCounter
  ) payable public
    ownerOnly()
    atState(States.CallForKeepers)
  {
    require(activeKeepersAddresses.length > 0, "14");  

    uint balance = address(this).balance;
     
    require(balance >= totalKeepingFee, "15");

    uint timestamp = getBlockTimestamp();
    lastOwnerCheckInAt = timestamp;

    for (uint i = 0; i < activeKeepersAddresses.length; i++) {
      ActiveKeeper storage keeper = activeKeepers[activeKeepersAddresses[i]];
      keeper.lastCheckInAt = timestamp;
    }

    encryptedData = EncryptedData({
      encryptedData: _encryptedData,
      aesCounter: aesCounter,
      dataHash: dataHash,
      shareLength: shareLength,
      suppliedKeyParts: new bytes[](0)
    });

    state = States.Active;
  }


   
   
  function ownerCheckIn() payable external
    ownerOnly()
    atState(States.Active)
  {
    uint excessBalance = creditKeepers({prepayOneKeepingPeriodUpfront: true});

    lastOwnerCheckInAt = getBlockTimestamp();

    if (excessBalance > 0) {
      msg.sender.transfer(excessBalance);
    }
  }


   
   
   
  function calculateApproximateCheckInPrice() public view returns (uint) {
    uint keepingFeeMult = calculateKeepingFeeMult();
    uint requiredBalance = 0;

    for (uint i = 0; i < activeKeepersAddresses.length; i++) {
      ActiveKeeper storage keeper = activeKeepers[activeKeepersAddresses[i]];
      uint balanceToAdd = SafeMath.mul(keeper.keepingFee, keepingFeeMult) / KEEPING_FEE_ROUNDING_MULT;
      uint newKeeperBalance = SafeMath.add(keeper.balance, balanceToAdd);
      requiredBalance = SafeMath.add(requiredBalance, newKeeperBalance);
    }

    requiredBalance = SafeMath.add(requiredBalance, totalKeepingFee);
    uint balance = address(this).balance;

    if (balance >= requiredBalance) {
      return 0;
    } else {
      return requiredBalance - balance;
    }
  }


   
   
  function creditKeepers(bool prepayOneKeepingPeriodUpfront) internal returns (uint) {
    uint keepingFeeMult = calculateKeepingFeeMult();
    uint requiredBalance = 0;

    for (uint i = 0; i < activeKeepersAddresses.length; i++) {
      ActiveKeeper storage keeper = activeKeepers[activeKeepersAddresses[i]];
      uint balanceToAdd = SafeMath.mul(keeper.keepingFee, keepingFeeMult) / KEEPING_FEE_ROUNDING_MULT;
      keeper.balance = SafeMath.add(keeper.balance, balanceToAdd);
      requiredBalance = SafeMath.add(requiredBalance, keeper.balance);
    }

    if (prepayOneKeepingPeriodUpfront) {
      requiredBalance = SafeMath.add(requiredBalance, totalKeepingFee);
    }

    uint balance = address(this).balance;

     
    require(balance >= requiredBalance, "16");
    return balance - requiredBalance;
  }


  function calculateKeepingFeeMult() internal view returns (uint) {
    uint timeSinceLastOwnerCheckIn = SafeMath.sub(getBlockTimestamp(), lastOwnerCheckInAt);

     
    require(timeSinceLastOwnerCheckIn <= checkInInterval, "17");

     
    if (timeSinceLastOwnerCheckIn == 0) {
      timeSinceLastOwnerCheckIn = 600;
    } else {
      timeSinceLastOwnerCheckIn = ceil(timeSinceLastOwnerCheckIn, 600);
    }

    if (timeSinceLastOwnerCheckIn > checkInInterval) {
      timeSinceLastOwnerCheckIn = checkInInterval;
    }

    return SafeMath.mul(KEEPING_FEE_ROUNDING_MULT, timeSinceLastOwnerCheckIn) / checkInInterval;
  }


   
   
   
   
   
  function keeperCheckIn() external
    activeKeepersOnly()
  {
    uint timestamp = getBlockTimestamp();

    ActiveKeeper storage keeper = activeKeepers[msg.sender];
    keeper.lastCheckInAt = timestamp;

    if (state == States.Active) {
      uint timeSinceLastOwnerCheckIn = SafeMath.sub(timestamp, lastOwnerCheckInAt);
      if (timeSinceLastOwnerCheckIn > checkInInterval) {
        state = States.CallForKeys;
        emit KeysNeeded();
      }
    }

    uint keeperBalance = keeper.balance;
    if (keeperBalance > 0) {
      keeper.balance = 0;
      msg.sender.transfer(keeperBalance);
    }
  }


   
   
  function supplyKey(bytes calldata keyPart) external
    activeKeepersOnly()
    atState(States.CallForKeys)
  {
    ActiveKeeper storage keeper = activeKeepers[msg.sender];
    require(!keeper.keyPartSupplied, "18");  

    bytes32 suppliedKeyPartHash = keccak256(keyPart);
    require(suppliedKeyPartHash == keeper.keyPartHash, "19");  

    encryptedData.suppliedKeyParts.push(keyPart);
    keeper.keyPartSupplied = true;

     
    uint toBeTransferred = SafeMath.add(keeper.balance, keeper.keepingFee);
    keeper.balance = 0;

    if (toBeTransferred > 0) {
      msg.sender.transfer(toBeTransferred);
    }
  }


   
   
   
   
   
   
  function announceContinuationContract(address _continuationContractAddress) external
    ownerOnly()
    atState(States.Active)
  {
     
    require(continuationContractAddress == address(0), "20");
     
    require(_continuationContractAddress != address(this), "21");

    CryptoLegacyBaseAPI continuationContract = CryptoLegacyBaseAPI(_continuationContractAddress);

     
    require(continuationContract.getOwner() == getOwner(), "22");
     
    require(continuationContract.getVersion() >= getVersion(), "23");
     
    require(continuationContract.isAcceptingKeeperProposals(), "24");

    continuationContractAddress = _continuationContractAddress;
    emit ContinuationContractAnnounced(_continuationContractAddress);
  }


   
   
   
  function cancel() payable external
    ownerOnly()
    atEitherOfStates(States.CallForKeepers, States.Active)
  {
    uint excessBalance = 0;

    if (state == States.Active) {
       
       
      excessBalance = creditKeepers({prepayOneKeepingPeriodUpfront: false});
    }

    state = States.Cancelled;
    emit Cancelled();

    if (excessBalance > 0) {
      msg.sender.transfer(excessBalance);
    }
  }


   
   
   
   
   
  function getBlockTimestamp() internal view returns (uint) {
    return now;
  }


   
   
  function ceil(uint x, uint y) internal pure returns (uint) {
    if (x == 0) return 0;
    return SafeMath.mul(1 + SafeMath.div(x - 1, y), y);
  }

}

 

contract Registry {
  event NewContract(string id, address addr, uint totalContracts);

  struct Contract {
    address initialAddress;
    address currentAddress;
  }

  mapping(address => string[]) internal contractsByOwner;
  mapping(string => Contract) internal contractsById;
  string[] public contracts;

  function getNumContracts() external view returns (uint) {
    return contracts.length;
  }

  function getContractAddress(string calldata id) external view returns (address) {
    return contractsById[id].currentAddress;
  }

  function getContractInitialAddress(string calldata id) external view returns (address) {
    return contractsById[id].initialAddress;
  }

  function getNumContractsByOwner(address owner) external view returns (uint) {
    return contractsByOwner[owner].length;
  }

  function getContractByOwner(address owner, uint index) external view returns (string memory) {
    return contractsByOwner[owner][index];
  }

  function deployAndRegisterContract(string calldata id, uint checkInInterval)
    external
    payable
    returns (CryptoLegacy)
  {
    CryptoLegacy instance = new CryptoLegacy(msg.sender, checkInInterval);
    addContract(id, address(instance));
    return instance;
  }

  function addContract(string memory id, address addr) public {
     
    require(contractsById[id].initialAddress == address(0), "R1");

    CryptoLegacyBaseAPI instance = CryptoLegacyBaseAPI(addr);
    address owner = instance.getOwner();

     
    require(msg.sender == owner, "R2");

    contracts.push(id);
    contractsByOwner[owner].push(id);
    contractsById[id] = Contract({initialAddress: addr, currentAddress: addr});

    emit NewContract(id, addr, contracts.length);
  }

  function updateAddress(string calldata id) external {
    Contract storage ctr = contractsById[id];
     
    require(ctr.currentAddress != address(0), "R3");

    CryptoLegacyBaseAPI instance = CryptoLegacyBaseAPI(ctr.currentAddress);
     
    require(instance.getOwner() == msg.sender, "R4");

    address continuationAddress = instance.getContinuationContractAddress();
    if (continuationAddress == address(0)) {
      return;
    }

    CryptoLegacyBaseAPI continuationInstance = CryptoLegacyBaseAPI(continuationAddress);
     
    require(continuationInstance.getOwner() == msg.sender, "R5");
     
    require(continuationInstance.getVersion() >= instance.getVersion(), "R6");

    ctr.currentAddress = continuationAddress;

     
     
     
     
     
     
     
    contracts.push(id);
    emit NewContract(id, continuationAddress, contracts.length);
  }

}