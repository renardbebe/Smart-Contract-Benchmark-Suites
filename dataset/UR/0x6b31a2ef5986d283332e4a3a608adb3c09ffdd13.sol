 

pragma solidity ^0.4.25;

 

 
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

     
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }
    
     
    function sq(uint256 x) internal pure returns (uint256) {
        return (mul(x, x));
    }
    
     
    function pwr(uint256 x, uint256 y) internal pure returns (uint256)
    {
        if (x == 0) {
            return (0);
        }
        else if (y == 0) {
            return 1;
        }
        else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) {
                z = mul(z, x);
            }
            return z;
        }
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyOwner {
      _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract PauserRole is Ownable {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
      _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract AdminRole is Ownable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyOwner {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyOwner {
      _removeAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

contract CommonConfig
{
    uint32 constant public SECONDS_PER_DAY = 5 * 60;  

    uint32 constant public BASE_RATIO = 10000;
}

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_InterfaceId_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 
contract IERC721 is IERC165 {
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public;
}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function tokenURI(uint256 tokenId) external view returns (string);
}

 
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
}

 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
     

    constructor () public {
         
        _registerInterface(_InterfaceId_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
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
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
         
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
         
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
         
         
         
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

     
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

     
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(address owner, uint256 tokenId) private {
        require(ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
     

     
    constructor (string name, string symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(InterfaceId_ERC721Metadata);
    }

     
    function name() external view returns (string) {
        return _name;
    }

     
    function symbol() external view returns (string) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

 
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
     

     
    constructor () public {
         
        _registerInterface(_InterfaceId_ERC721Enumerable);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

     
    function _addTokenTo(address to, uint256 tokenId) internal {
        super._addTokenTo(to, tokenId);
        uint256 length = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }

     
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        super._removeTokenFrom(from, tokenId);

         
         
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 lastToken = _ownedTokens[from][lastTokenIndex];

        _ownedTokens[from][tokenIndex] = lastToken;
         
        _ownedTokens[from].length--;

         
         
         

        _ownedTokensIndex[tokenId] = 0;
        _ownedTokensIndex[lastToken] = tokenIndex;
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 lastToken = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastToken;
        _allTokens[lastTokenIndex] = 0;

        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
        _allTokensIndex[lastToken] = tokenIndex;
    }
}

 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string name, string symbol) ERC721Metadata(name, symbol) public {}
}

contract ITTicket is ERC721Full, AdminRole, Pausable
{
    using SafeMath for uint256;
    using SafeMath for uint32;
    using Address for address;

    enum TICKET_TYPE
    {
        TICKET_TYPE_NULL,
        TICKET_TYPE_NORMAL,
        TICKET_TYPE_RARE,
        TICKET_TYPE_LEGENDARY
    }

    struct TicketHashInfo
    {
        address key;
        TICKET_TYPE ticketType;
        bool exchange;
    }

    struct TicketInfo
    {
        TICKET_TYPE ticketType;
        uint8 ticketFlag;
    }

    mapping(uint256 => TicketHashInfo) public _ticketHashMap;

    mapping(uint256 => TicketInfo) public _ticketMap;

    uint256 public _curTicketId;

    uint256 public _normalPrice;

    uint256 public _rarePrice;

    uint256 public _legendaryPrice;

    uint32 public _sellNormalTicketCount;

    uint32 public _rareTicketCount;

    uint32 public _legendaryTicketCount;

    uint32 public _baseAddRatio;

    uint32 public _rareAddCount;

    uint32 public _legendaryAddCount;

    uint8 public _ticketFlag;

    constructor() ERC721Full("ImperialThrone Ticket", "ITTK") public
    {
        _curTicketId = 1;
        _normalPrice = 0.01 ether;
        _rarePrice = 0.1 ether;
        _legendaryPrice = 1 ether;

        _rareTicketCount = 90;

        _legendaryTicketCount = 10;

        _baseAddRatio = 90;

        _rareAddCount = 9;

        _legendaryAddCount = 1;

        _ticketFlag = 1;
    }

    function setNormalTicketPrice(uint256 price) external onlyAdmin
    {
        _normalPrice = price;
    }

    function setRareTicketPrice(uint256 price) external onlyAdmin
    {
        _rarePrice = price;
    }

    function setLegendaryTicketPrice(uint256 price) external onlyAdmin
    {
        _legendaryPrice = price;
    }

    function setRareTicketCount(uint32 count) external onlyAdmin
    {
        _rareTicketCount = count;
    }

    function setLegendaryTicketCount(uint32 count) external onlyAdmin
    {
        _legendaryTicketCount = count;
    }

    function setBaseAddRatio(uint32 ratio) external onlyAdmin
    {
        _baseAddRatio = ratio;
    }

    function setRareAddCount(uint32 count) external onlyAdmin
    {
        _rareAddCount = count;
    }

    function setLegendaryAddCount(uint32 count) external onlyAdmin
    {
        _legendaryAddCount = count;
    }

    function setTicketFlag(uint8 flag) external onlyAdmin
    {
        _ticketFlag = flag;
    }

    function getHashExchangeState(uint256 id) external view returns(bool)
    {
        TicketHashInfo storage hashInfo = _ticketHashMap[id];
        return hashInfo.exchange;
    }

    function getTicketInfo(uint256 ticketId) external view returns(TICKET_TYPE ticketType, uint8 ticketFlag)
    {
        TicketInfo storage ticketInfo = _ticketMap[ticketId];
        ticketType = ticketInfo.ticketType;
        ticketFlag = ticketInfo.ticketFlag;
    }

    event AddTicketHash(uint256 id);

    function _addTicketHash(uint256 id, address key, TICKET_TYPE ticketType) internal
    {
        require(ticketType >= TICKET_TYPE.TICKET_TYPE_NORMAL
            && ticketType <= TICKET_TYPE.TICKET_TYPE_LEGENDARY);

        TicketHashInfo storage hashInfo = _ticketHashMap[id];
        require(hashInfo.ticketType == TICKET_TYPE.TICKET_TYPE_NULL);
                  
        hashInfo.key = key;
        hashInfo.ticketType = ticketType;
        hashInfo.exchange = false;

        emit AddTicketHash(id);
    }

    function addTicketHashList(uint256[] idList,
        address[] keyList, TICKET_TYPE[] ticketTypeList) external onlyAdmin
    {
        require(idList.length == keyList.length);
        require(idList.length == ticketTypeList.length);

        for(uint32 i = 0; i < idList.length; ++i)
        {
            _addTicketHash(idList[i], keyList[i], ticketTypeList[i]);
        }
    }

    function addTicketHash(uint256 id, address key, TICKET_TYPE ticketType) external onlyAdmin
    {
        _addTicketHash(id, key, ticketType);
    }

    function verifyOwnerTicket(uint256 id, uint8 v,
        bytes32 r, bytes32 s) external view returns(bool)
    {        
        TicketHashInfo storage hashInfo = _ticketHashMap[id];

        require(hashInfo.ticketType >= TICKET_TYPE.TICKET_TYPE_NORMAL
            && hashInfo.ticketType <= TICKET_TYPE.TICKET_TYPE_LEGENDARY);

        require(hashInfo.exchange == false);

        require(ecrecover(keccak256(abi.encodePacked(msg.sender)), v, r, s) == hashInfo.key);

        require(_ticketMap[_curTicketId].ticketType == TICKET_TYPE.TICKET_TYPE_NULL);

        return true;
    }

    event ExchangeOwnerTicket(uint8 indexed channelId, address owner, 
        uint256 id, uint256 ticketId, TICKET_TYPE ticketType);

    function _addOwnerTicket(uint8 channelId, address owner,
        uint256 id, uint8 v, bytes32 r, bytes32 s) internal
    {
        TicketHashInfo storage hashInfo = _ticketHashMap[id];

        require(hashInfo.ticketType >= TICKET_TYPE.TICKET_TYPE_NORMAL
            && hashInfo.ticketType <= TICKET_TYPE.TICKET_TYPE_LEGENDARY);

        require(hashInfo.exchange == false);
    
        require(ecrecover(keccak256(abi.encodePacked(owner)), v, r, s) == hashInfo.key);

        require(_ticketMap[_curTicketId].ticketType == TICKET_TYPE.TICKET_TYPE_NULL);

         
        _mint(owner, _curTicketId);

        hashInfo.exchange = true;
    
        _ticketMap[_curTicketId].ticketType = hashInfo.ticketType;

        emit ExchangeOwnerTicket(channelId, owner, id, _curTicketId, hashInfo.ticketType);

        _curTicketId++;
    }

    function exchangeOwnerTicket(uint8 channelId, uint256 id,
        uint8 v, bytes32 r, bytes32 s) external
    {        
        _addOwnerTicket(channelId, msg.sender, id, v, r, s);
    }

    event BuyTicket(uint8 indexed channelId, address owner, TICKET_TYPE ticket_type);

    function buyTicket(uint8 channelId, TICKET_TYPE ticketType) public payable whenNotPaused
    {
        require(ticketType >= TICKET_TYPE.TICKET_TYPE_NORMAL
            && ticketType <= TICKET_TYPE.TICKET_TYPE_LEGENDARY);

        if(ticketType == TICKET_TYPE.TICKET_TYPE_NORMAL)
        {
            require(msg.value == _normalPrice);
            _sellNormalTicketCount++;

            if(_sellNormalTicketCount.div(_baseAddRatio) > 0
                && _sellNormalTicketCount % _baseAddRatio == 0)
            {
                _rareTicketCount = uint32(_rareTicketCount.add(_rareAddCount));
                _legendaryTicketCount = uint32(_legendaryTicketCount.add(_legendaryAddCount));
            }
        }
        else if(ticketType == TICKET_TYPE.TICKET_TYPE_RARE)
        {
            require(_rareTicketCount > 0);
            require(msg.value == _rarePrice);
            _rareTicketCount--;
        }
        else if(ticketType == TICKET_TYPE.TICKET_TYPE_LEGENDARY)
        {
            require(_legendaryTicketCount > 0);
            require(msg.value == _legendaryPrice);
            _legendaryTicketCount--;
        }

         
        _mint(msg.sender, _curTicketId);

        _ticketMap[_curTicketId].ticketType = ticketType;
        _ticketMap[_curTicketId].ticketFlag = _ticketFlag;

        _curTicketId++;

        emit BuyTicket(channelId, msg.sender, ticketType);
    }

    function withdrawETH(uint256 count) external onlyOwner
    {
        require(count <= address(this).balance);
        msg.sender.transfer(count);
    }
}