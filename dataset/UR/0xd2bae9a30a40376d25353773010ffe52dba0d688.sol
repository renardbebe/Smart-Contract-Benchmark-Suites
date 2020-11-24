 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
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
   

  constructor()
    public
  {
     
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

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
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

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

 

 
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

 

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
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

 

 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

 

 

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
  using SafeMath for uint256;

  event LockUpdate(uint256 indexed tokenId, uint256 fromLockedTo, uint256 fromLockId, uint256 toLockedTo, uint256 toLockId, uint256 callId);
  event StatsUpdate(uint256 indexed tokenId, uint256 fromLevel, uint256 fromWins, uint256 fromLosses, uint256 toLevel, uint256 toWins, uint256 toLosses);

   
  string private _name;

   
  string private _symbol;

   
  string private _baseURI;

  string private _description;

  string private _url;

  struct Character {
    uint256 mintedAt;
    uint256 genes;
    uint256 lockedTo;
    uint256 lockId;
    uint256 level;
    uint256 wins;
    uint256 losses;
  }

  mapping(uint256 => Character) characters;  


  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol, string baseURI, string description, string url) public {
    _name = name;
    _symbol = symbol;
    _baseURI = baseURI;
    _description = description;
    _url = url;
     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  function description() external view returns (string) {
    return _description;
  }

   
  function url() external view returns (string) {
    return _url;
  }

   
  function _setBaseURI(string newBaseUri) internal {
    _baseURI = newBaseUri;
  }

   
  function _setDescription(string newDescription) internal {
    _description = newDescription;
  }

   
  function _setURL(string newUrl) internal {
    _url = newUrl;
  }


   
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
  }

  function _setMetadata(uint256 tokenId, uint256 genes, uint256 level) internal {
    require(_exists(tokenId));
     
    characters[tokenId] = Character({
      mintedAt : now,
      genes : genes,
      lockedTo : 0,
      lockId : 0,
      level : level,
      wins : 0,
      losses : 0
      });
    emit StatsUpdate(tokenId, 0, 0, 0, level, 0, 0);

  }


  function _clearMetadata(uint256 tokenId) internal {
    require(_exists(tokenId));
    delete characters[tokenId];
  }

   

  function isFree(uint tokenId) public view returns (bool) {
    require(_exists(tokenId));
    return now > characters[tokenId].lockedTo;
  }


  function getLock(uint256 tokenId) external view returns (uint256 lockedTo, uint256 lockId) {
    require(_exists(tokenId));
    Character memory c = characters[tokenId];
    return (c.lockedTo, c.lockId);
  }

  function getLevel(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId));
    return characters[tokenId].level;
  }

  function getGenes(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId));
    return characters[tokenId].genes;
  }

  function getRace(uint256 tokenId) external view returns (uint256) {
    require(_exists(tokenId));
    return characters[tokenId].genes & 0xFFFF;
  }

  function getCharacter(uint256 tokenId) external view returns (
    uint256 mintedAt,
    uint256 genes,
    uint256 race,
    uint256 lockedTo,
    uint256 lockId,
    uint256 level,
    uint256 wins,
    uint256 losses
  ) {
    require(_exists(tokenId));
    Character memory c = characters[tokenId];
    return (c.mintedAt, c.genes, c.genes & 0xFFFF, c.lockedTo, c.lockId, c.level, c.wins, c.losses);
  }

  function _setLock(uint256 tokenId, uint256 lockedTo, uint256 lockId, uint256 callId) internal returns (bool) {
    require(isFree(tokenId));
    Character storage c = characters[tokenId];
    emit LockUpdate(tokenId, c.lockedTo, c.lockId, lockedTo, lockId, callId);
    c.lockedTo = lockedTo;
    c.lockId = lockId;
    return true;
  }

   

  function _addWin(uint256 tokenId, uint256 _winsCount, uint256 _levelUp) internal returns (bool) {
    require(_exists(tokenId));
    Character storage c = characters[tokenId];
    uint prevWins = c.wins;
    uint prevLevel = c.level;
    c.wins = c.wins.add(_winsCount);
    c.level = c.level.add(_levelUp);
    emit StatsUpdate(tokenId, prevLevel, prevWins, c.losses, c.level, c.wins, c.losses);
    return true;
  }

  function _addLoss(uint256 tokenId, uint256 _lossesCount, uint256 _levelDown) internal returns (bool) {
    require(_exists(tokenId));
    Character storage c = characters[tokenId];
    uint prevLosses = c.losses;
    uint prevLevel = c.level;
    c.losses = c.losses.add(_lossesCount);
    c.level = c.level > _levelDown ? c.level.sub(_levelDown) : 1;
    emit StatsUpdate(tokenId, prevLevel, c.wins, prevLosses, c.level, c.wins, c.losses);
    return true;
  }

   
  function uint2str(uint i) internal pure returns (string) {
    if (i == 0) return "0";
    uint j = i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0) {
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }
    return string(bstr);
  }


}

 

 
library Agents {
  using Address for address;

  struct Data {
    uint id;
    bool exists;
    bool allowance;
  }

  struct Agent {
    mapping(address => Data) data;
    mapping(uint => address) list;
  }

   
  function add(Agent storage agent, address account, uint id, bool allowance) internal {
    require(!exists(agent, account));

    agent.data[account] = Data({
      id : id,
      exists : true,
      allowance : allowance
      });
    agent.list[id] = account;
  }

   
  function remove(Agent storage agent, address account) internal {
    require(exists(agent, account));

     
    if (agent.list[agent.data[account].id] == account) {
      delete agent.list[agent.data[account].id];
    }
    delete agent.data[account];
  }

   
  function exists(Agent storage agent, address account) internal view returns (bool) {
    require(account != address(0));
     
    return agent.data[account].exists && agent.list[agent.data[account].id] == account;
  }

   
  function id(Agent storage agent, address account) internal view returns (uint) {
    require(exists(agent, account));
    return agent.data[account].id;
  }

  function byId(Agent storage agent, uint agentId) internal view returns (address) {
    address account = agent.list[agentId];
    require(account != address(0));
    require(agent.data[account].exists && agent.data[account].id == agentId);
    return account;
  }

  function allowance(Agent storage agent, address account) internal view returns (bool) {
    require(exists(agent, account));
    return account.isContract() && agent.data[account].allowance;
  }


}

contract HasAgents is Ownable {
  using Agents for Agents.Agent;

  event AgentAdded(address indexed account);
  event AgentRemoved(address indexed account);

  Agents.Agent private agents;

  constructor() internal {
    _addAgent(msg.sender, 0, false);
  }

  modifier onlyAgent() {
    require(isAgent(msg.sender));
    _;
  }

  function isAgent(address account) public view returns (bool) {
    return agents.exists(account);
  }

  function addAgent(address account, uint id, bool allowance) public onlyOwner {
    _addAgent(account, id, allowance);
  }

  function removeAgent(address account) public onlyOwner {
    _removeAgent(account);
  }

  function renounceAgent() public {
    _removeAgent(msg.sender);
  }

  function _addAgent(address account, uint id, bool allowance) internal {
    agents.add(account, id, allowance);
    emit AgentAdded(account);
  }

  function _removeAgent(address account) internal {
    agents.remove(account);
    emit AgentRemoved(account);
  }

  function getAgentId(address account) public view returns (uint) {
    return agents.id(account);
  }

 
 
 

  function getAgentById(uint id) public view returns (address) {
    return agents.byId(id);
  }

  function isAgentHasAllowance(address account) public view returns (bool) {
    return agents.allowance(account);
  }
}

 

 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

 

 
contract HasDepositary is Ownable, ReentrancyGuard  {

  event Depositary(address depositary);

  address private _depositary;

 
 
 

   
  function() external payable {
    require(msg.value > 0);
 
  }

  function depositary() external view returns (address) {
    return _depositary;
  }

  function setDepositary(address newDepositary) external onlyOwner {
    require(newDepositary != address(0));
    require(_depositary == address(0));
    _depositary = newDepositary;
    emit Depositary(newDepositary);
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    require(balance > 0);
    if (_depositary == address(0)) {
      owner().transfer(balance);
    } else {
      _depositary.transfer(balance);
    }
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract CanReclaimToken is Ownable {

   
  function reclaimToken(IERC20 token) external onlyOwner {
    if (address(token) == address(0)) {
      owner().transfer(address(this).balance);
      return;
    }
    uint256 balance = token.balanceOf(this);
    token.transfer(owner(), balance);
  }

}

 

interface AgentContract {
  function isAllowed(uint _tokenId) external returns (bool);
}

contract Heroes is Ownable, ERC721, ERC721Enumerable, ERC721Metadata, HasAgents, HasDepositary {

  uint256 private lastId = 1000;

  event Mint(address indexed to, uint256 indexed tokenId);
  event Burn(address indexed from, uint256 indexed tokenId);


  constructor() HasAgents() ERC721Metadata(
      "CRYPTO HEROES",  
      "CH ⚔️",  
      "https://api.cryptoheroes.app/hero/",  
      "The first blockchain game in the world with famous characters and fights built on real cryptocurrency exchange quotations.",  
      "https://cryptoheroes.app"  
  ) public {}

   
  function setBaseURI(string uri) external onlyOwner {
    _setBaseURI(uri);
  }
  function setDescription(string description) external onlyOwner {
    _setDescription(description);
  }
  function setURL(string url) external onlyOwner {
    _setURL(url);
  }

   
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    return (
    super._isApprovedOrOwner(spender, tokenId) ||
     
     
    (isAgent(spender) && super._isApprovedOrOwner(tx.origin, tokenId)) ||
     
    owner() == spender
    );
  }


   
  function mint(address to, uint256 genes, uint256 level) public onlyAgent returns (uint) {
    lastId = lastId.add(1);
    return mint(lastId, to, genes, level);
 
 
 
 
  }

   
  function mint(uint256 tokenId, address to, uint256 genes, uint256 level) public onlyAgent returns (uint) {
    _mint(to, tokenId);
    _setMetadata(tokenId, genes, level);
    emit Mint(to, tokenId);
    return tokenId;
  }


   
  function burn(uint256 tokenId) public returns (uint) {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    address owner = ownerOf(tokenId);
    _clearMetadata(tokenId);
    _burn(owner, tokenId);
    emit Burn(owner, tokenId);
    return tokenId;
  }


   

  function addWin(uint256 _tokenId, uint _winsCount, uint _levelUp) external onlyAgent returns (bool){
    require(_addWin(_tokenId, _winsCount, _levelUp));
    return true;
  }

  function addLoss(uint256 _tokenId, uint _lossesCount, uint _levelDown) external onlyAgent returns (bool){
    require(_addLoss(_tokenId, _lossesCount, _levelDown));
    return true;
  }

   

   
  function lock(uint256 _tokenId, uint256 _lockedTo, bool _onlyFreeze) external onlyAgent returns(bool) {
    require(_exists(_tokenId));
    uint agentId = getAgentId(msg.sender);
    Character storage c = characters[_tokenId];
    if (c.lockId != 0 && agentId != c.lockId) {
       
      address a = getAgentById(c.lockId);
      if (isAgentHasAllowance(a)) {
        AgentContract ac = AgentContract(a);
        require(ac.isAllowed(_tokenId));
      }
    }
    require(_setLock(_tokenId, _lockedTo, _onlyFreeze ? c.lockId : agentId, agentId));
    return true;
  }

  function unlock(uint256 _tokenId) external onlyAgent returns (bool){
    require(_exists(_tokenId));
    uint agentId = getAgentId(msg.sender);
     
    require(agentId == characters[_tokenId].lockId);
    require(_setLock(_tokenId, 0, 0, agentId));
    return true;
  }

  function isCallerAgentOf(uint _tokenId) public view returns (bool) {
    require(_exists(_tokenId));
    return isAgent(msg.sender) && getAgentId(msg.sender) == characters[_tokenId].lockId;
  }

   
  function transfer(address to, uint256 tokenId) public {
    transferFrom(msg.sender, to, tokenId);
  }
}