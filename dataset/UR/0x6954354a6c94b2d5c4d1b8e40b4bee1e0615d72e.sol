 

pragma solidity ^0.4.17;

 

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) external;
  function setApprovalForAll(address _to, bool _approved) external;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}
library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

 
 
 
interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}
contract ERC721SlimToken is Ownable, ERC721, ERC165, ERC721Metadata {
  using SafeMath for uint256;

  string public constant NAME = "EtherLoot";
  string public constant SYMBOL = "ETLT";
  string public tokenMetadataBaseURI = "http://api.etherloot.moonshadowgames.com/tokenmetadata/";

  struct AddressAndTokenIndex {
    address owner;
    uint32 tokenIndex;
  }

  mapping (uint256 => AddressAndTokenIndex) private tokenOwnerAndTokensIndex;

  mapping (address => uint256[]) private ownedTokens;

  mapping (uint256 => address) private tokenApprovals;

  mapping (address => mapping (address => bool)) private operatorApprovals;

  mapping (address => bool) private approvedContractAddresses;

  bool approvedContractsFinalized = false;

  function implementsERC721() external pure returns (bool) {
    return true;
  }



  function supportsInterface(
    bytes4 interfaceID)
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector ||  
      interfaceID == 0x5b5e139f ||  
      interfaceID == 0x6466353c;  
  }

  function name() external pure returns (string) {
    return NAME;
  }

  function symbol() external pure returns (string) {
    return SYMBOL;
  }

  function setTokenMetadataBaseURI(string _tokenMetadataBaseURI) external onlyOwner {
    tokenMetadataBaseURI = _tokenMetadataBaseURI;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    returns (string infoUrl)
  {
    return Strings.strConcat(
      tokenMetadataBaseURI,
      Strings.uint2str(tokenId));
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender, "not owner");
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0), "null owner");
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner), "invalid index");
    return ownedTokens[_owner][_index];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    require(_owner != address(0), "invalid owner");
    return _owner;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    return (_owner != address(0));
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function isSenderApprovedFor(uint256 _tokenId) internal view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      isSpecificallyApprovedFor(msg.sender, _tokenId) ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }

   
  function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
    return getApproved(_tokenId) == _asker;
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transfer(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    address _owner = ownerOf(_tokenId);
    require(_to != _owner, "already owns");
    if (getApproved(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(_owner, _to, _tokenId);
    }
  }

   
  function setApprovalForAll(address _to, bool _approved)
    external
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

   
  function approveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant approve yourself");
    require(_to != address(0), "invalid owner");
    operatorApprovals[msg.sender][_to] = true;
    emit ApprovalForAll(msg.sender, _to, true);
  }

   
  function disapproveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant unapprove yourself");
    delete operatorApprovals[msg.sender][_to];
    emit ApprovalForAll(msg.sender, _to, false);
  }

   
  function takeOwnership(uint256 _tokenId)
   external
  {
    require(isSenderApprovedFor(_tokenId), "not approved");
    _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    address tokenOwner = ownerOf(_tokenId);
    require(isSenderApprovedFor(_tokenId) || 
      (approvedContractAddresses[msg.sender] && tokenOwner == tx.origin), "not an approved sender");
    require(tokenOwner == _from, "wrong owner");
    _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    require(_to != address(0), "invalid target address");
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")), "invalid receiver respononse");
    }
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function addApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = true;
  }

   
  function removeApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = false;
  }

   
  function finalizeApprovedContracts() public onlyOwner {
    approvedContractsFinalized = true;
  }

   
  function mint(address _to, uint256 _tokenId) public {
    require(
      approvedContractAddresses[msg.sender] ||
      msg.sender == owner, "minter not approved"
    );
    _mint(_to, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(tokenOwnerAndTokensIndex[_tokenId].owner == address(0), "token already exists");
    _addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

   
  function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(_to != ownerOf(_tokenId), "already owns");
    require(ownerOf(_tokenId) == _from, "wrong owner");

    _clearApproval(_from, _tokenId);
    _removeToken(_from, _tokenId);
    _addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function _clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner, "wrong owner");
    if (tokenApprovals[_tokenId] != 0) {
      tokenApprovals[_tokenId] = 0;
      emit Approval(_owner, 0, _tokenId);
    }
  }

   
  function _addToken(address _to, uint256 _tokenId) private {
    uint256 newTokenIndex = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);

     
    require(newTokenIndex == uint256(uint32(newTokenIndex)), "overflow");

    tokenOwnerAndTokensIndex[_tokenId] = AddressAndTokenIndex({owner: _to, tokenIndex: uint32(newTokenIndex)});
  }

   
  function _removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from, "wrong owner");

    uint256 tokenIndex = tokenOwnerAndTokensIndex[_tokenId].tokenIndex;
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;

    ownedTokens[_from].length--;
    tokenOwnerAndTokensIndex[lastToken] = AddressAndTokenIndex({owner: _from, tokenIndex: uint32(tokenIndex)});
  }

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}
 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function smax256(int256 a, int256 b) internal pure returns (int256) {
    return a >= b ? a : b;
  }
}

contract ContractAccessControl {

  event ContractUpgrade(address newContract);
  event Paused();
  event Unpaused();

  address public ceoAddress;

  address public cfoAddress;

  address public cooAddress;

  address public withdrawalAddress;

  bool public paused = false;

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress ||
      msg.sender == cfoAddress
    );
    _;
  }

  modifier onlyCEOOrCFO() {
    require(
      msg.sender == cfoAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  modifier onlyCEOOrCOO() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  function setWithdrawalAddress(address _newWithdrawalAddress) external onlyCEO {
    require(_newWithdrawalAddress != address(0));
    withdrawalAddress = _newWithdrawalAddress;
  }

  function withdrawBalance() external onlyCEOOrCFO {
    require(withdrawalAddress != address(0));
    withdrawalAddress.transfer(this.balance);
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyCLevel whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
    emit Unpaused();
  }
}

contract CryptoBoss is ContractAccessControl {

  address constant tokenContractAddress = 0xe1015a79a7d488f8fecf073b187d38c6f1a77368;
  ERC721SlimToken constant tokenContract = ERC721SlimToken(tokenContractAddress);

  event Participating(address indexed player, uint encounterId);
  event LootClaimed(address indexed player, uint encounterId);
  event DailyLootClaimed(uint day);

  struct ParticipantData {
    uint32 damage;
    uint64 cumulativeDamage;
    uint8 forgeWeaponRarity;
    uint8 forgeWeaponDamagePure;
    bool lootClaimed;
    bool consolationPrizeClaimed;
  }

  struct Encounter {
    mapping (address => ParticipantData) participantData;
    address[] participants;
  }

   
  mapping (uint => Encounter) encountersById;

  mapping (uint => address) winnerPerDay;
  mapping (uint => mapping (address => uint)) dayToAddressToScore;
  mapping (uint => bool) dailyLootClaimedPerDay;

   uint constant encounterBlockDuration = 80;
   uint constant blocksInADay = 5760;

 
 

  uint256 gasRefundForClaimLoot = 279032000000000;
  uint256 gasRefundForClaimConsolationPrizeLoot = 279032000000000;
  uint256 gasRefundForClaimLootWithConsolationPrize = 279032000000000;

  uint participateFee = 0.002 ether;
  uint participateDailyLootContribution = 0.001 ether;

  constructor() public {

    paused = false;

    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    withdrawalAddress = msg.sender;
  }
  
  function setGasRefundForClaimLoot(uint256 _gasRefundForClaimLoot) external onlyCEO {
      gasRefundForClaimLoot = _gasRefundForClaimLoot;
  }

  function setGasRefundForClaimConsolationPrizeLoot(uint256 _gasRefundForClaimConsolationPrizeLoot) external onlyCEO {
      gasRefundForClaimConsolationPrizeLoot = _gasRefundForClaimConsolationPrizeLoot;
  }

  function setGasRefundForClaimLootWithConsolationPrize(uint256 _gasRefundForClaimLootWithConsolationPrize) external onlyCEO {
      gasRefundForClaimLootWithConsolationPrize = _gasRefundForClaimLootWithConsolationPrize;
  }

  function setParticipateFee(uint _participateFee) public onlyCLevel {
    participateFee = _participateFee;
  }

  function setParticipateDailyLootContribution(uint _participateDailyLootContribution) public onlyCLevel {
    participateDailyLootContribution = _participateDailyLootContribution;
  }

  function getFirstEncounterIdFromDay(uint day) internal pure returns (uint) {
    return (day * blocksInADay) / encounterBlockDuration;
  }

  function leaderboardEntries(uint day) public view returns
    (uint etherPot, bool dailyLootClaimed, uint blockDeadline, address[] memory entryAddresses, uint[] memory entryDamages) {    

    dailyLootClaimed = dailyLootClaimedPerDay[day];
    blockDeadline = (((day+1) * blocksInADay) / encounterBlockDuration) * encounterBlockDuration;

    uint participantCount = 0;
    etherPot = 0;

    for (uint encounterId = getFirstEncounterIdFromDay(day); encounterId < getFirstEncounterIdFromDay(day+1); encounterId++)
    {
      address[] storage participants = encountersById[encounterId].participants;
      participantCount += participants.length;
      etherPot += participateDailyLootContribution * participants.length;
    }

    entryAddresses = new address[](participantCount);
    entryDamages = new uint[](participantCount);

    participantCount = 0;

    for (encounterId = getFirstEncounterIdFromDay(day); encounterId < getFirstEncounterIdFromDay(day+1); encounterId++)
    {
      participants = encountersById[encounterId].participants;
      mapping (address => ParticipantData) participantData = encountersById[encounterId].participantData;
      for (uint i = 0; i < participants.length; i++)
      {
        address participant = participants[i];
        entryAddresses[participantCount] = participant;
        entryDamages[participantCount] = participantData[participant].damage;
        participantCount++;
      }
    }
  }

  function claimDailyLoot(uint day) public {
    require(!dailyLootClaimedPerDay[day]);
    require(winnerPerDay[day] == msg.sender);

    uint firstEncounterId = day * blocksInADay / encounterBlockDuration;
    uint firstEncounterIdTomorrow = ((day+1) * blocksInADay / encounterBlockDuration);
    uint etherPot = 0;
    for (uint encounterId = firstEncounterId; encounterId < firstEncounterIdTomorrow; encounterId++)
    {
      etherPot += participateDailyLootContribution * encountersById[encounterId].participants.length;
    }

    dailyLootClaimedPerDay[day] = true;

    msg.sender.transfer(etherPot);

    emit DailyLootClaimed(day);
  }

  function blockBeforeEncounter(uint encounterId) private pure returns (uint) {
    return encounterId*encounterBlockDuration - 1;
  }

  function getEncounterDetails() public view
    returns (uint encounterId, uint encounterFinishedBlockNumber, bool isParticipating, uint day, uint monsterDna) {
    encounterId = block.number / encounterBlockDuration;
    encounterFinishedBlockNumber = (encounterId+1) * encounterBlockDuration;
    Encounter storage encounter = encountersById[encounterId];
    isParticipating = (encounter.participantData[msg.sender].damage != 0);
    day = (encounterId * encounterBlockDuration) / blocksInADay;
    monsterDna = uint(blockhash(blockBeforeEncounter(encounterId)));
  }

  function getParticipants(uint encounterId) public view returns (address[]) {

    Encounter storage encounter = encountersById[encounterId];
    return encounter.participants;
  }

  function calculateWinner(uint numParticipants, Encounter storage encounter, uint blockToHash) internal view returns
    (address winnerAddress, uint rand, uint totalDamageDealt) {

    if (numParticipants == 0) {
      return;
    }

    totalDamageDealt = encounter.participantData[encounter.participants[numParticipants-1]].cumulativeDamage;

    rand = uint(keccak256(blockhash(blockToHash)));
    uint winnerDamageValue = rand % totalDamageDealt;

    uint winnerIndex = numParticipants;

     
     
     

    uint min = 0;
    uint max = numParticipants - 1;
    while(max >= min) {
      uint guess = (min+max)/2;
      if (guess > 0 && winnerDamageValue < encounter.participantData[encounter.participants[guess-1]].cumulativeDamage) {
        max = guess-1;
      }
      else if (winnerDamageValue >= encounter.participantData[encounter.participants[guess]].cumulativeDamage) {
        min = guess+1;
      } else {
        winnerIndex = guess;
        break;
      }

    }

    require(winnerIndex < numParticipants, "error in binary search");

    winnerAddress = encounter.participants[winnerIndex];
  }

  function getBlockToHashForResults(uint encounterId) public view returns (uint) {
      
    uint blockToHash = (encounterId+1)*encounterBlockDuration - 1;
    
    require(block.number > blockToHash);
    
    uint diff = block.number - (blockToHash+1);
    if (diff > 255) {
        blockToHash += (diff/256)*256;
    }
    
    return blockToHash;
  }
  
  function getEncounterResults(uint encounterId, address player) public view returns (
    address winnerAddress, uint lootTokenId, uint consolationPrizeTokenId,
    bool lootClaimed, uint damageDealt, uint totalDamageDealt) {

    uint blockToHash = getBlockToHashForResults(encounterId);

    Encounter storage encounter = encountersById[encounterId];
    uint numParticipants = encounter.participants.length;
    if (numParticipants == 0) {
      return (address(0), 0, 0, false, 0, 0);
    }

    damageDealt = encounter.participantData[player].damage;

    uint rand;
    (winnerAddress, rand, totalDamageDealt) = calculateWinner(numParticipants, encounter, blockToHash);

    lootTokenId = constructWeaponTokenIdForWinner(rand, numParticipants);

    lootClaimed = true;
    consolationPrizeTokenId = getConsolationPrizeTokenId(encounterId, player);

    if (consolationPrizeTokenId != 0) {
        lootClaimed = encounter.participantData[player].consolationPrizeClaimed;
        
         
     
    }
  }
  
    function getLootClaimed(uint encounterId, address player) external view returns (bool, bool) {
        ParticipantData memory participantData = encountersById[encounterId].participantData[player];
        return (
            participantData.lootClaimed,
            participantData.consolationPrizeClaimed
        );
    }

  function constructWeaponTokenIdForWinner(uint rand, uint numParticipants) pure internal returns (uint) {

    uint rarity = 0;
    if (numParticipants > 1) rarity = 1;
    if (numParticipants > 10) rarity = 2;

    return constructWeaponTokenId(rand, rarity, 0);
  }

  function getWeaponRarityFromTokenId(uint tokenId) pure internal returns (uint) {
    return tokenId & 0xff;
  }  

   
  function getWeaponDamageFromTokenId(uint tokenId, uint damageType) pure internal returns (uint) {
    return ((tokenId >> (64 + damageType*8)) & 0xff);
  }  

  function getPureWeaponDamageFromTokenId(uint tokenId) pure internal returns (uint) {
    return ((tokenId >> (56)) & 0xff);
  }  

  function getMonsterDefenseFromDna(uint monsterDna, uint damageType) pure internal returns (uint) {
    return ((monsterDna >> (64 + damageType*8)) & 0xff);
  }


   

  bytes10 constant elementsAvailableForCommon =     hex"01020408100102040810";    
  bytes10 constant elementsAvailableForRare =       hex"030506090A0C11121418";    
  bytes10 constant elementsAvailableForEpic =       hex"070B0D0E131516191A1C";    
  bytes10 constant elementsAvailableForLegendary =  hex"0F171B1D1E0F171B1D1E";    

   
   
   
   
   
  function constructWeaponTokenId(uint rand, uint rarity, uint pureDamage) pure internal returns (uint) {
    uint lootTokenId = (rand & 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000) + rarity;

    bytes10[4] memory elementsAvailablePerRarity = [
      elementsAvailableForCommon,
      elementsAvailableForRare,
      elementsAvailableForEpic,
      elementsAvailableForLegendary
      ];

    bytes10 elementsAvailable = elementsAvailablePerRarity[rarity];
     
    uint8 elementsUsed = uint8(elementsAvailable[((rand >> 104) & 0xffff) % 10]);
     
     
    for (uint i = 0; i < 5; i++) {
      if ((elementsUsed & (1 << i)) == 0) {
        lootTokenId = lootTokenId & ~(0xff << (64 + i*8));
      }
    }

    pureDamage = Math.min256(100, pureDamage);

    lootTokenId = lootTokenId | (pureDamage << 56);

    return lootTokenId;
  }

  function weaponTokenIdToDamageForEncounter(uint weaponTokenId, uint encounterId) view internal returns (uint) {
    uint monsterDna = uint(blockhash(encounterId*encounterBlockDuration - 1));

    uint physicalDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 0)) - int(getMonsterDefenseFromDna(monsterDna, 0))));
    uint fireDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 4)) - int(getMonsterDefenseFromDna(monsterDna, 4))));
    uint earthDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 3)) - int(getMonsterDefenseFromDna(monsterDna, 3))));
    uint waterDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 2)) - int(getMonsterDefenseFromDna(monsterDna, 2))));
    uint magicDamage = uint(Math.smax256(0, int(getWeaponDamageFromTokenId(weaponTokenId, 1)) - int(getMonsterDefenseFromDna(monsterDna, 1))));
    uint pureDamage = getPureWeaponDamageFromTokenId(weaponTokenId);

    uint damage = physicalDamage + fireDamage + earthDamage + waterDamage + magicDamage + pureDamage;
    damage = Math.max256(1, damage);

    return damage;
  }

  function forgeWeaponPureDamage(uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4)
    internal pure returns (uint8) {
    if (sacrificeTokenId1 == 0) {
      return 0;
    }
    return uint8(Math.min256(255,
        getPureWeaponDamageFromTokenId(sacrificeTokenId1) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId2) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId3) +
        getPureWeaponDamageFromTokenId(sacrificeTokenId4)));
  }

  function forgeWeaponRarity(uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4)
    internal pure returns (uint8) {
    if (sacrificeTokenId1 == 0) {
      return 0;
    }
    uint rarity = getWeaponRarityFromTokenId(sacrificeTokenId1);
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId2));
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId3));
    rarity = Math.min256(rarity, getWeaponRarityFromTokenId(sacrificeTokenId4)) + 1;
    require(rarity < 5, "cant forge an ultimate weapon");
    return uint8(rarity);
  }

  function participate(uint encounterId, uint weaponTokenId,
    uint sacrificeTokenId1, uint sacrificeTokenId2, uint sacrificeTokenId3, uint sacrificeTokenId4) public whenNotPaused payable {
    require(msg.value >= participateFee);   

    require(encounterId == block.number / encounterBlockDuration, "a new encounter is available");

    Encounter storage encounter = encountersById[encounterId];

    require(encounter.participantData[msg.sender].damage == 0, "you are already participating");

    uint damage = 1;
     
    if (weaponTokenId != 0) {
      require(tokenContract.ownerOf(weaponTokenId) == msg.sender, "you dont own that weapon");
      damage = weaponTokenIdToDamageForEncounter(weaponTokenId, encounterId);
    }

    uint day = (encounterId * encounterBlockDuration) / blocksInADay;
    uint newScore = dayToAddressToScore[day][msg.sender] + damage;
    dayToAddressToScore[day][msg.sender] = newScore;

    if (newScore > dayToAddressToScore[day][winnerPerDay[day]] &&
      winnerPerDay[day] != msg.sender) {
      winnerPerDay[day] = msg.sender;
    }

    uint cumulativeDamage = damage;
    if (encounter.participants.length > 0) {
      cumulativeDamage = cumulativeDamage + encounter.participantData[encounter.participants[encounter.participants.length-1]].cumulativeDamage;
    }

    if (sacrificeTokenId1 != 0) {

       
       

       

      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId1);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId2);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId3);
      tokenContract.transferFrom(msg.sender, 1, sacrificeTokenId4);
    }

    encounter.participantData[msg.sender] = ParticipantData(uint32(damage), uint64(cumulativeDamage), 
      forgeWeaponRarity(sacrificeTokenId1, sacrificeTokenId2, sacrificeTokenId3, sacrificeTokenId4),
      forgeWeaponPureDamage(sacrificeTokenId1, sacrificeTokenId2, sacrificeTokenId3, sacrificeTokenId4),
      false, false);
    encounter.participants.push(msg.sender);

    emit Participating(msg.sender, encounterId);
  }

  function claimLoot(uint encounterId, address player) public whenNotPaused {
    address winnerAddress;
    uint lootTokenId;
    uint consolationPrizeTokenId;
    (winnerAddress, lootTokenId, consolationPrizeTokenId, , ,,) = getEncounterResults(encounterId, player);
    require(winnerAddress == player, "player is not the winner");

    ParticipantData storage participantData = encountersById[encounterId].participantData[player];

    require(!participantData.lootClaimed, "loot already claimed");

    participantData.lootClaimed = true;
    tokenContract.mint(player, lootTokenId);

     
     

    require(consolationPrizeTokenId != 0, "consolation prize invalid");

    if (!participantData.consolationPrizeClaimed) {
        participantData.consolationPrizeClaimed = true;
         
        tokenContract.mint(player, consolationPrizeTokenId);

         
        msg.sender.transfer(gasRefundForClaimLootWithConsolationPrize);
    } else {
        
         
        msg.sender.transfer(gasRefundForClaimLoot);
    }

    emit LootClaimed(player, encounterId);
  }

  function getConsolationPrizeTokenId(uint encounterId, address player) internal view returns (uint) {

    ParticipantData memory participantData = encountersById[encounterId].participantData[player];
    if (participantData.damage == 0) {
      return 0;
    }

    uint blockToHash = getBlockToHashForResults(encounterId);

    uint rand = uint(keccak256(uint(blockhash(blockToHash)) ^ uint(player)));

    if (participantData.forgeWeaponRarity != 0) {
      return constructWeaponTokenId(rand, participantData.forgeWeaponRarity, participantData.forgeWeaponDamagePure);
    }

    return constructWeaponTokenId(rand, 0, 0);
  }

  function claimConsolationPrizeLoot(uint encounterId, address player) public whenNotPaused {
    uint lootTokenId = getConsolationPrizeTokenId(encounterId, player);
    require(lootTokenId != 0, "player didnt participate");

    ParticipantData storage participantData = encountersById[encounterId].participantData[player];
    require(!participantData.consolationPrizeClaimed, "consolation prize already claimed");

    participantData.consolationPrizeClaimed = true;
    tokenContract.mint(player, lootTokenId);

    msg.sender.transfer(gasRefundForClaimConsolationPrizeLoot);

    emit LootClaimed(player, encounterId);
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return tokenContract.balanceOf(_owner);
  }

  function tokensOf(address _owner) public view returns (uint256[]) {
    return tokenContract.tokensOf(_owner);
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    return tokenContract.tokenOfOwnerByIndex(_owner, _index);
  }
}