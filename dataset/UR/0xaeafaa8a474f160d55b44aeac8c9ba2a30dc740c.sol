 

pragma solidity ^0.5.2;


interface ERC165Interface {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC721Interface is ERC165Interface {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract GenerateRandomEntityInterface {
  address public tokenAddr;
  address public entityDataAddr;
  uint256 public priceWei;
  uint256 public cntDrawnByEth;
  uint256 public capDrawByEth;
  address payable public adminWalletAddr;
  uint256 public idCounter;
  uint256 public modelId;
  uint256 public constant modelIdDigit = 1000000;
  uint256 public constant typeIdDigit = 100000;
  uint256 public constant gen0TypeId = 1;

  event TokenAdded(address tokenAddr, uint256 priceInToken);

  event Generate (
      uint256 tokenId,
      address owner,
      uint256 createdAt
  );

  function setPriceWei(uint256 _priceWei) external;

  function setPriceToken(address _payableTokenAddr, uint256 _priceInToken) public;

  function removePayableToken(address _payableTokenAddr) external;

  function setAdminWallet(address payable newWalletAddr) public;

  function setCapDrawByEth(uint256 _cap) external;

  function setCapDrawByToken(address _tokenAddr, uint256 _cap) external;

  function setModelId(uint256 _modelId) external;

  function () external payable;

  function tokenFallback(address _from, uint _value, bytes memory _data) public;

  function isReady() external view returns(bool);

  function getPriceInToken(address _payableTokenAddr)
      external
      view
      returns(bool isPayable, uint256 price);

  function isEthAvailable() public view returns (bool);

  function isTokenAvailable(address _tokenAddr) public view returns (bool);

  function getCapDrawByToken(address _tokenAddr) external view returns (uint256);

  function getCntDrawnByToken(address _tokenAddr) external view returns (uint256);

  function calculateTokenId(uint256 _modelId, uint256 _typeId, uint256 _idCount)
      public
      pure
      returns(uint256 tokenId);
}

contract EntityDataInterface {

    address public tokenAddr;

    mapping(uint256 => Entity) public entityData;
    mapping(uint256 => address) public siringApprovedTo;

    event UpdateRootHash (
        uint256 tokenId,
        bytes rootHash
    );

    event Birth (
        uint256 tokenId,
        address owner,
        uint256 matronId,
        uint256 sireId
    );

    struct Entity {
        bytes rootHash;
        uint256 birthTime;
        uint256 cooldownEndTime;
        uint256 matronId;
        uint256 sireId;
        uint256 generation;
    }

    function updateRootHash(uint256 tokenId, bytes calldata rootHash) external;

    function createEntity(address owner, uint256 tokenId, uint256 _generation, uint256 _matronId, uint256 _sireId, uint256 _birthTime) public;

    function getEntity(uint256 tokenId)
      external
      view
      returns(
            uint256 birthTime,
            uint256 cooldownEndTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation
        );

    function setCooldownEndTime(uint256 tokenId, uint256 _cooldownEndTime) external;

    function approveSiring(uint256 sireId, address approveTo) external;

    function clearSiringApproval(uint256 sireId) external;

    function isSiringApprovedTo(uint256 tokenId, address borrower)
        external
        view
        returns(bool);

    function isReadyForFusion(uint256 tokenId)
        external
        view
        returns (bool ready);
}

contract RoleManager {

    mapping(address => bool) private admins;
    mapping(address => bool) private controllers;

    modifier onlyAdmins {
        require(admins[msg.sender], 'only admins');
        _;
    }

    modifier onlyControllers {
        require(controllers[msg.sender], 'only controllers');
        _;
    } 

    constructor() public {
        admins[msg.sender] = true;
        controllers[msg.sender] = true;
    }

    function addController(address _newController) external onlyAdmins{
        controllers[_newController] = true;
    } 

    function addAdmin(address _newAdmin) external onlyAdmins{
        admins[_newAdmin] = true;
    } 

    function removeController(address _controller) external onlyAdmins{
        controllers[_controller] = false;
    } 
    
    function removeAdmin(address _admin) external onlyAdmins{
        require(_admin != msg.sender, 'unexecutable operation'); 
        admins[_admin] = false;
    } 

    function isAdmin(address addr) external view returns (bool) {
        return (admins[addr]);
    }

    function isController(address addr) external view returns (bool) {
        return (controllers[addr]);
    }

}

contract AccessController {

    address roleManagerAddr;

    modifier onlyAdmins {
        require(RoleManager(roleManagerAddr).isAdmin(msg.sender), 'only admins');
        _;
    }

    modifier onlyControllers {
        require(RoleManager(roleManagerAddr).isController(msg.sender), 'only controllers');
        _;
    }

    constructor (address _roleManagerAddr) public {
        require(_roleManagerAddr != address(0), '_roleManagerAddr: Invalid address (zero address)');
        roleManagerAddr = _roleManagerAddr;
    }

}

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

contract FusionInterface {
    using SafeMath for uint256;

    uint256 public fusionFeeWei;
    address public tokenAddr;
    address public entityDataAddr;
    address payable generateRandomEntityAddr;
    uint256 public cooldownPeriod;
    uint256 public incubationTime;
    address payable public adminWalletAddr;
    bool public isFusionDisabled;
    uint256 public idCounter;
    uint256 public constant fusionTypeId = 2;
    uint256 public capDrawByEth;
    uint256 public cntDrawnByEth;

    event Fuse(uint256 matronId, uint256 sireId, uint256 fusionTime);

    function setFusionFee(uint256 newFeeWei) public;

    function setAdminWallet(address payable newWalletAddr) public;

    function fusion(uint256 matronId, uint256 sireId) external payable returns(uint256 childId);

    function isValidFusionPair(uint256 matronId, uint256 sireId)
        public
        view
        returns(bool isValid);

    function setCapDrawByEth(uint256 _cap) external {
        capDrawByEth = _cap;
    }

    function disableFusion() public {
        isFusionDisabled = true;
    }
}

contract ERC721MetadataInterface is ERC721Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721EnumerableInterface is ERC721Interface {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC165 is ERC165Interface {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    

    
    mapping(bytes4 => bool) private _supportedInterfaces;

    
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC721ReceiverInterface {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract ERC721Extended is ERC721Interface, ERC721MetadataInterface, ERC721EnumerableInterface, ERC165, Ownable {
    using SafeMath for uint256;

    
    mapping(uint256 => address) private _tokenOwner;

    
    mapping(uint256 => address) private _tokenApprovals;

    
    mapping(address => uint256) private _ownedTokensCount;

    
    mapping(address => mapping (address => bool)) private _operatorApprovals;

    
    string private _name;

    
    string private _symbol;

    
    mapping(uint256 => string) private _tokenURIs;

    
    mapping(address => uint256[]) private _ownedTokens;

    
    mapping(uint256 => uint256) private _ownedTokensIndex;

    
    uint256[] private _allTokens;

    
    mapping(uint256 => uint256) private _allTokensIndex;

    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _current(owner);
    }

    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId));
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _increment(to);

        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _decrement(owner);
        _tokenOwner[tokenId] = address(0);

        
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        
        _ownedTokensIndex[tokenId] = 0;
        _removeTokenFromAllTokensEnumeration(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _decrement(from);
        _increment(to);

        _tokenOwner[tokenId] = to;

        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!_isContract(to)) {
            return true;
        }

        bytes4 retval = ERC721ReceiverInterface(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    
    function name() external view returns (string memory) {
        return _name;
    }

    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    
    function setTokenURI(uint256 tokenId, string calldata uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

    
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        
        _ownedTokens[from].length--;

        
        
    }

    
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        
        

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        
        
        
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }

    
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function _current(address tokenAddress) private view returns (uint256) {
        return _ownedTokensCount[tokenAddress];
    }

    
    function _increment(address tokenAddress) private {
        _ownedTokensCount[tokenAddress] = _ownedTokensCount[tokenAddress].add(1);
    }

    
    function _decrement(address tokenAddress) private {
        _ownedTokensCount[tokenAddress] = _ownedTokensCount[tokenAddress].sub(1);
    }

    
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
  }

contract GeneAidolsToken is ERC721Extended, AccessController {
    constructor(address _roleManagerAddr)
        public
        ERC721Extended("GeneA.I.dols", "GAI")
        AccessController(_roleManagerAddr)
    {
    }

    function generateToken(uint256 tokenId, address to) external onlyControllers {
        _mint(to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external onlyAdmins {
        _setTokenURI(tokenId, uri);
    }

    function tokenExists(uint256 tokenId) external view returns (bool exists) {
        return _exists(tokenId);
    }
}

contract Fusion is FusionInterface, AccessController{
    using SafeMath for uint256;

    event Fuse(uint256 matronId, uint256 sireId, uint256 childId, uint256 fusionTime);

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    uint256 private constant modelId = 101;

    constructor(
        address _entityDataAddr,
        address _roleManagerAddr,
        address payable _generateRandomEntityAddr
    )
      public
      AccessController(_roleManagerAddr)
    {
        require(_entityDataAddr != address(0), '_entityDataAddr: Invalid address (zero address)');
        entityDataAddr = _entityDataAddr;
        tokenAddr = EntityDataInterface(entityDataAddr).tokenAddr();
        require(ERC721Interface(tokenAddr).supportsInterface(_INTERFACE_ID_ERC721));
        generateRandomEntityAddr = _generateRandomEntityAddr;

        fusionFeeWei = 100 finney;
        cooldownPeriod = 1 days;
        idCounter = 1;
        isFusionDisabled = false;
        capDrawByEth = 10**9;
        cntDrawnByEth = 0;
        incubationTime = 5 minutes;

        setAdminWallet(msg.sender);
    }

    function setFusionFee(uint256 newFeeWei) public onlyAdmins {
        fusionFeeWei = newFeeWei;
    }

    function setAdminWallet(address payable newWalletAddr) public onlyAdmins {
        require(newWalletAddr != address(0), 'newWalletAddr: Invalid address (zero address)');
        adminWalletAddr = newWalletAddr;
    }

    function setCapDrawByEth(uint256 _cap) external onlyAdmins {
        capDrawByEth = _cap;
    }

    function fusion(uint256 matronId, uint256 sireId) external payable returns(uint256 childId) {
        require(!isFusionDisabled, 'Fusion is disabled');
        cntDrawnByEth++;
        require(isFusionAvailable(), 'Reached cap');
        require(fusionFeeWei <= msg.value, 'Insufficient amount of ether');
        require(matronId != sireId, 'matron and sire should be different from each other');

        EntityDataInterface ed = EntityDataInterface(entityDataAddr);

        
        require(ed.isReadyForFusion(matronId), 'matron is not ready for fusion');
        require(ed.isReadyForFusion(sireId), 'sire is not ready for fusion');

        address ownerOfMatron = ERC721Interface(tokenAddr).ownerOf(matronId);
        require(ownerOfMatron == msg.sender || RoleManager(roleManagerAddr).isController(msg.sender) );
        require(ERC721Interface(tokenAddr).ownerOf(sireId) == ownerOfMatron ||
                ed.isSiringApprovedTo(sireId, ownerOfMatron) ||
                RoleManager(roleManagerAddr).isController(msg.sender));

        uint256 cooldownEndTime = uint256(block.timestamp).add(cooldownPeriod);
        ed.setCooldownEndTime(matronId, cooldownEndTime);
        ed.setCooldownEndTime(sireId, cooldownEndTime);

        EntityDataInterface.Entity memory matron;
        (
            matron.birthTime,
            matron.cooldownEndTime,
            matron.matronId,
            matron.sireId,
            matron.generation
        ) = ed.getEntity(matronId);

        EntityDataInterface.Entity memory sire;
        (
            sire.birthTime,
            sire.cooldownEndTime,
            sire.matronId,
            sire.sireId,
            sire.generation
        ) = ed.getEntity(sireId);

        uint256 childGeneration = matron.generation.add(1);
        if(sire.generation > matron.generation){
            childGeneration = sire.generation.add(1);
        }

        address childOwner = ownerOfMatron;


        
        uint256 childId = GenerateRandomEntityInterface(generateRandomEntityAddr).calculateTokenId(modelId, fusionTypeId, idCounter);
        idCounter++;

       ed.createEntity(
            childOwner,
            childId,
            childGeneration,
            matronId,
            sireId,
            uint256(block.timestamp).add(incubationTime)
        );

        emit Fuse(matronId, sireId, childId, uint256(block.timestamp));

        
        msg.sender.transfer(msg.value - fusionFeeWei);

        
        adminWalletAddr.transfer(fusionFeeWei);

        return childId;
    }

    function isValidFusionPair(uint256 matronId, uint256 sireId)
        public
        view
        returns(bool isValid)
    {
      return true;
    }

    function disableFusion() public onlyAdmins {
        isFusionDisabled = true;
    }

    function isFusionAvailable()
        public
        view
        returns(bool isAvailable)
    {
        if( cntDrawnByEth >= capDrawByEth ){
            return false;
          }

        return true;
    }
}