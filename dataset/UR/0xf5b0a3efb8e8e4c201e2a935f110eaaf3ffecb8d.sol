 

pragma solidity ^0.4.19;

 

 
 
interface IERC165 {
   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 

contract ERC165 is IERC165 {
   
  mapping (bytes4 => bool) internal supportedInterfaces;

  function ERC165() internal {
    supportedInterfaces[0x01ffc9a7] = true;  
  }

  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return supportedInterfaces[interfaceID];
  }
}

 

 
 
 
interface IERC721Base   {
   
   
   
   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

   
   
   
   
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

   
   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
   
   
   
   
  function balanceOf(address _owner) external view returns (uint256);

   
   
   
   
   
  function ownerOf(uint256 _tokenId) external view returns (address);

   
   
   
   
   
   
   
   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable;

   
   
   
   
   
   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

   
   
   
   
   
   
  function approve(address _approved, uint256 _tokenId) external payable;

   
   
   
   
   
  function setApprovalForAll(address _operator, bool _approved) external;

   
   
   
   
  function getApproved(uint256 _tokenId) external view returns (address);

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

 
 
 
interface IERC721Enumerable   {
   
   
   
  function totalSupply() external view returns (uint256);

   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256);

   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

 

 
interface IERC721TokenReceiver {
   
   
   
   
   
   
   
   
   
   
   
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns (bytes4);
}

 

interface AxieSpawningManager {
	function isSpawningAllowed(uint256 _genes, address _owner) external returns (bool);
  function isRebirthAllowed(uint256 _axieId, uint256 _genes) external returns (bool);
}

interface AxieRetirementManager {
  function isRetirementAllowed(uint256 _axieId, bool _rip) external returns (bool);
}

interface AxieMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _axieId) external returns (bool);
}

interface AxieGeneManager {
  function isEvolvementAllowed(uint256 _axieId, uint256 _newGenes) external returns (bool);
}

 

contract AxieDependency {

  address public whitelistSetterAddress;

  AxieSpawningManager public spawningManager;
  AxieRetirementManager public retirementManager;
  AxieMarketplaceManager public marketplaceManager;
  AxieGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedByeSayer;
  mapping (address => bool) public whitelistedMarketplace;
  mapping (address => bool) public whitelistedGeneScientist;

  function AxieDependency() internal {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(uint256 _genes, address _owner) {
    require(
      spawningManager == address(0) ||
        spawningManager.isSpawningAllowed(_genes, _owner)
    );
    _;
  }

  modifier whenRebirthAllowed(uint256 _axieId, uint256 _genes) {
    require(
      spawningManager == address(0) ||
        spawningManager.isRebirthAllowed(_axieId, _genes)
    );
    _;
  }

  modifier whenRetirementAllowed(uint256 _axieId, bool _rip) {
    require(
      retirementManager == address(0) ||
        retirementManager.isRetirementAllowed(_axieId, _rip)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _axieId) {
    require(
      marketplaceManager == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _axieId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _axieId, uint256 _newGenes) {
    require(
      geneManager == address(0) ||
        geneManager.isEvolvementAllowed(_axieId, _newGenes)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyByeSayer() {
    require(whitelistedByeSayer[msg.sender]);
    _;
  }

  modifier onlyMarketplace() {
    require(whitelistedMarketplace[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

   
  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = AxieSpawningManager(_manager);
  }

  function setRetirementManager(address _manager) external onlyWhitelistSetter {
    retirementManager = AxieRetirementManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = AxieMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = AxieGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setByeSayer(address _byeSayer, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedByeSayer[_byeSayer] != _whitelisted);
    whitelistedByeSayer[_byeSayer] = _whitelisted;
  }

  function setMarketplace(address _marketplace, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedMarketplace[_marketplace] != _whitelisted);
    whitelistedMarketplace[_marketplace] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}

 

contract AxieAccessControl {

  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  function AxieAccessControl() internal {
    ceoAddress = msg.sender;
  }

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
       
      msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == cooAddress
       
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    cooAddress = _newCOO;
  }

  function withdrawBalance() external onlyCFO {
    cfoAddress.transfer(this.balance);
  }
}

 

contract AxiePausable is AxieAccessControl {

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract AxieERC721BaseEnumerable is ERC165, IERC721Base, IERC721Enumerable, AxieDependency, AxiePausable {
  using SafeMath for uint256;

   
  uint256 private _totalTokens;

   
  mapping (uint256 => uint256) private _overallTokenId;

   
  mapping (uint256 => uint256) private _overallTokenIndex;

   
  mapping (uint256 => address) private _tokenOwner;

   
   
  mapping (address => mapping (address => bool)) private _tokenOperator;

   
  mapping (uint256 => address) private _tokenApproval;

   
  mapping (address => uint256[]) private _ownedTokens;

   
  mapping (uint256 => uint256) private _ownedTokenIndex;

  function AxieERC721BaseEnumerable() internal {
    supportedInterfaces[0x6466353c] = true;  
    supportedInterfaces[0x780e9d63] = true;  
  }

   

  modifier mustBeValidToken(uint256 _tokenId) {
    require(_tokenOwner[_tokenId] != address(0));
    _;
  }

  function _isTokenOwner(address _ownerToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenOwner[_tokenId] == _ownerToCheck;
  }

  function _isTokenOperator(address _operatorToCheck, uint256 _tokenId) private view returns (bool) {
    return whitelistedMarketplace[_operatorToCheck] ||
      _tokenOperator[_tokenOwner[_tokenId]][_operatorToCheck];
  }

  function _isApproved(address _approvedToCheck, uint256 _tokenId) private view returns (bool) {
    return _tokenApproval[_tokenId] == _approvedToCheck;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenOwnerOrOperator(uint256 _tokenId) {
    require(_isTokenOwner(msg.sender, _tokenId) || _isTokenOperator(msg.sender, _tokenId));
    _;
  }

  modifier onlyTokenAuthorized(uint256 _tokenId) {
    require(
       
      _isTokenOwner(msg.sender, _tokenId) ||
        _isTokenOperator(msg.sender, _tokenId) ||
        _isApproved(msg.sender, _tokenId)
       
    );
    _;
  }

   

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return _ownedTokens[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenOwner[_tokenId];
  }

  function _addTokenTo(address _to, uint256 _tokenId) private {
    require(_to != address(0));

    _tokenOwner[_tokenId] = _to;

    uint256 length = _ownedTokens[_to].length;
    _ownedTokens[_to].push(_tokenId);
    _ownedTokenIndex[_tokenId] = length;
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_tokenOwner[_tokenId] == address(0));

    _addTokenTo(_to, _tokenId);

    _overallTokenId[_totalTokens] = _tokenId;
    _overallTokenIndex[_tokenId] = _totalTokens;
    _totalTokens = _totalTokens.add(1);

    Transfer(address(0), _to, _tokenId);
  }

  function _removeTokenFrom(address _from, uint256 _tokenId) private {
    require(_from != address(0));

    uint256 _tokenIndex = _ownedTokenIndex[_tokenId];
    uint256 _lastTokenIndex = _ownedTokens[_from].length.sub(1);
    uint256 _lastTokenId = _ownedTokens[_from][_lastTokenIndex];

    _tokenOwner[_tokenId] = address(0);

     
    _ownedTokens[_from][_tokenIndex] = _lastTokenId;
    _ownedTokenIndex[_lastTokenId] = _tokenIndex;

     
    delete _ownedTokens[_from][_lastTokenIndex];
    _ownedTokens[_from].length--;

     
    if (_ownedTokens[_from].length == 0) {
      delete _ownedTokens[_from];
    }

     
    delete _ownedTokenIndex[_tokenId];
  }

  function _burn(uint256 _tokenId) internal {
    address _from = _tokenOwner[_tokenId];

    require(_from != address(0));

    _removeTokenFrom(_from, _tokenId);
    _totalTokens = _totalTokens.sub(1);

    uint256 _tokenIndex = _overallTokenIndex[_tokenId];
    uint256 _lastTokenId = _overallTokenId[_totalTokens];

    delete _overallTokenIndex[_tokenId];
    delete _overallTokenId[_totalTokens];
    _overallTokenId[_tokenIndex] = _lastTokenId;
    _overallTokenIndex[_lastTokenId] = _tokenIndex;

    Transfer(_from, address(0), _tokenId);
  }

  function _isContract(address _address) private view returns (bool) {
    uint _size;
     
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }

  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data,
    bool _check
  )
    internal
    mustBeValidToken(_tokenId)
    onlyTokenAuthorized(_tokenId)
    whenTransferAllowed(_from, _to, _tokenId)
  {
    require(_isTokenOwner(_from, _tokenId));
    require(_to != address(0));
    require(_to != _from);

    _removeTokenFrom(_from, _tokenId);

    delete _tokenApproval[_tokenId];
    Approval(_from, address(0), _tokenId);

    _addTokenTo(_to, _tokenId);

    if (_check && _isContract(_to)) {
      IERC721TokenReceiver(_to).onERC721Received.gas(50000)(_from, _tokenId, _data);
    }

    Transfer(_from, _to, _tokenId);
  }

   

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable {
    _transferFrom(_from, _to, _tokenId, _data, true);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _transferFrom(_from, _to, _tokenId, "", true);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _transferFrom(_from, _to, _tokenId, "", false);
  }

   

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    payable
    mustBeValidToken(_tokenId)
    onlyTokenOwnerOrOperator(_tokenId)
    whenNotPaused
  {
    address _owner = _tokenOwner[_tokenId];

    require(_owner != _approved);
    require(_tokenApproval[_tokenId] != _approved);

    _tokenApproval[_tokenId] = _approved;

    Approval(_owner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
    require(_tokenOperator[msg.sender][_operator] != _approved);
    _tokenOperator[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) external view mustBeValidToken(_tokenId) returns (address) {
    return _tokenApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return _tokenOperator[_owner][_operator];
  }

   

  function totalSupply() external view returns (uint256) {
    return _totalTokens;
  }

  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < _totalTokens);
    return _overallTokenId[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId) {
    require(_owner != address(0));
    require(_index < _ownedTokens[_owner].length);
    return _ownedTokens[_owner][_index];
  }
}

 

 
 
 
interface IERC721Metadata   {
   
  function name() external pure returns (string _name);

   
  function symbol() external pure returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}

 

contract AxieERC721Metadata is AxieERC721BaseEnumerable, IERC721Metadata {
  string public tokenURIPrefix = "https://axieinfinity.com/erc/721/axies/";
  string public tokenURISuffix = ".json";

  function AxieERC721Metadata() internal {
    supportedInterfaces[0x5b5e139f] = true;  
  }

  function name() external pure returns (string) {
    return "Axie";
  }

  function symbol() external pure returns (string) {
    return "AXIE";
  }

  function setTokenURIAffixes(string _prefix, string _suffix) external onlyCEO {
    tokenURIPrefix = _prefix;
    tokenURISuffix = _suffix;
  }

  function tokenURI(
    uint256 _tokenId
  )
    external
    view
    mustBeValidToken(_tokenId)
    returns (string)
  {
    bytes memory _tokenURIPrefixBytes = bytes(tokenURIPrefix);
    bytes memory _tokenURISuffixBytes = bytes(tokenURISuffix);
    uint256 _tmpTokenId = _tokenId;
    uint256 _length;

    do {
      _length++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    bytes memory _tokenURIBytes = new bytes(_tokenURIPrefixBytes.length + _length + 5);
    uint256 _i = _tokenURIBytes.length - 6;

    _tmpTokenId = _tokenId;

    do {
      _tokenURIBytes[_i--] = byte(48 + _tmpTokenId % 10);
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    for (_i = 0; _i < _tokenURIPrefixBytes.length; _i++) {
      _tokenURIBytes[_i] = _tokenURIPrefixBytes[_i];
    }

    for (_i = 0; _i < _tokenURISuffixBytes.length; _i++) {
      _tokenURIBytes[_tokenURIBytes.length + _i - 5] = _tokenURISuffixBytes[_i];
    }

    return string(_tokenURIBytes);
  }
}

 

 
contract AxieERC721 is AxieERC721BaseEnumerable, AxieERC721Metadata {
}

 

 
contract AxieCore is AxieERC721 {
  struct Axie {
    uint256 genes;
    uint256 bornAt;
  }

  Axie[] axies;

  event AxieSpawned(uint256 indexed _axieId, address indexed _owner, uint256 _genes);
  event AxieRebirthed(uint256 indexed _axieId, uint256 _genes);
  event AxieRetired(uint256 indexed _axieId);
  event AxieEvolved(uint256 indexed _axieId, uint256 _oldGenes, uint256 _newGenes);

  function AxieCore() public {
    axies.push(Axie(0, now));  
    _spawnAxie(0, msg.sender);  
    _spawnAxie(0, msg.sender);  
    _spawnAxie(0, msg.sender);  
    _spawnAxie(0, msg.sender);  
  }

  function getAxie(
    uint256 _axieId
  )
    external
    view
    mustBeValidToken(_axieId)
    returns (uint256  , uint256  )
  {
    Axie storage _axie = axies[_axieId];
    return (_axie.genes, _axie.bornAt);
  }

  function spawnAxie(
    uint256 _genes,
    address _owner
  )
    external
    onlySpawner
    whenSpawningAllowed(_genes, _owner)
    returns (uint256)
  {
    return _spawnAxie(_genes, _owner);
  }

  function rebirthAxie(
    uint256 _axieId,
    uint256 _genes
  )
    external
    onlySpawner
    mustBeValidToken(_axieId)
    whenRebirthAllowed(_axieId, _genes)
  {
    Axie storage _axie = axies[_axieId];
    _axie.genes = _genes;
    _axie.bornAt = now;
    AxieRebirthed(_axieId, _genes);
  }

  function retireAxie(
    uint256 _axieId,
    bool _rip
  )
    external
    onlyByeSayer
    whenRetirementAllowed(_axieId, _rip)
  {
    _burn(_axieId);

    if (_rip) {
      delete axies[_axieId];
    }

    AxieRetired(_axieId);
  }

  function evolveAxie(
    uint256 _axieId,
    uint256 _newGenes
  )
    external
    onlyGeneScientist
    mustBeValidToken(_axieId)
    whenEvolvementAllowed(_axieId, _newGenes)
  {
    uint256 _oldGenes = axies[_axieId].genes;
    axies[_axieId].genes = _newGenes;
    AxieEvolved(_axieId, _oldGenes, _newGenes);
  }

  function _spawnAxie(uint256 _genes, address _owner) private returns (uint256 _axieId) {
    Axie memory _axie = Axie(_genes, now);
    _axieId = axies.push(_axie) - 1;
    _mint(_owner, _axieId);
    AxieSpawned(_axieId, _owner, _genes);
  }
}