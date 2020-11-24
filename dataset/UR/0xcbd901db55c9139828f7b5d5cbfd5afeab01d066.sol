 

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
}

 
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

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}



 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
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

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
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



 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
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

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
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

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
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



contract NFT is ERC721Metadata,
  ERC721Enumerable,
  Ownable {
  
  constructor(string name, string symbol) public ERC721Metadata(name, symbol){
  }
    
  function mintWithTokenURI(
		uint256 _id,			    
		string _uri
		) onlyOwner public {
    super._mint(owner(), _id);
    super._setTokenURI(_id, _uri);
  }
  
}



contract CryptoxmasEscrow is Pausable, Ownable {
  using SafeMath for uint256;
  
   
  address public givethBridge;
  uint64 public givethReceiverId;

   
  NFT public nft; 
  
   
  uint public EPHEMERAL_ADDRESS_FEE = 0.01 ether;
  uint public MIN_PRICE = 0.05 ether;  
  uint public tokensCounter;  
  
   
  enum Statuses { Empty, Deposited, Claimed, Cancelled }  
  
  struct Gift {
    address sender;
    uint claimEth;  
    uint256 tokenId;
    Statuses status;
    string msgHash;  
  }

   
  mapping (address => Gift) gifts;


   
  enum CategoryId { Common, Special, Rare, Scarce, Limited, Epic, Unique }  
  struct TokenCategory {
    CategoryId categoryId;
    uint minted;   
    uint maxQnty;  
    uint price; 
  }

   
  mapping(string => TokenCategory) tokenCategories;
  
   
  event LogBuy(
	       address indexed transitAddress,
	       address indexed sender,
	       string indexed tokenUri,
	       uint tokenId,
	       uint claimEth,
	       uint nftPrice
	       );

  event LogClaim(
		 address indexed transitAddress,
		 address indexed sender,
		 uint tokenId,
		 address receiver,
		 uint claimEth
		 );  

  event LogCancel(
		  address indexed transitAddress,
		  address indexed sender,
		  uint tokenId
		  );

  event LogAddTokenCategory(
			    string tokenUri,
			    CategoryId categoryId,
			    uint maxQnty,
			    uint price
		  );
  

   
  constructor(address _givethBridge,
	      uint64 _givethReceiverId,
	      string _name,
	      string _symbol) public {
     
    givethBridge = _givethBridge;
    givethReceiverId = _givethReceiverId;
    
     
    nft = new NFT(_name, _symbol);
  }

    
  
     
  function getTokenCategory(string _tokenUri) public view returns (CategoryId categoryId,
								  uint minted,
								  uint maxQnty,
								  uint price) { 
    TokenCategory memory category = tokenCategories[_tokenUri];    
    return (category.categoryId,
	    category.minted,
	    category.maxQnty,
	    category.price);
  }

       
  function addTokenCategory(string _tokenUri, CategoryId _categoryId, uint _maxQnty, uint _price)
    public onlyOwner returns (bool success) {

     
    require(_price >= MIN_PRICE);
	    
     
    require(tokenCategories[_tokenUri].price == 0);
    
    tokenCategories[_tokenUri] = TokenCategory(_categoryId,
					       0,  
					       _maxQnty,
					       _price);

    emit LogAddTokenCategory(_tokenUri, _categoryId, _maxQnty, _price);
    return true;
  }

         
  function canBuyGift(string _tokenUri, address _transitAddress, uint _value) public view whenNotPaused returns (bool) {
     
    require(gifts[_transitAddress].status == Statuses.Empty);

     
    TokenCategory memory category = tokenCategories[_tokenUri];
    require(_value >= category.price);

     
    require(category.minted < category.maxQnty);
    
    return true;
  }

       
  function buyGift(string _tokenUri, address _transitAddress, string _msgHash)
          payable public whenNotPaused returns (bool) {
    
    require(canBuyGift(_tokenUri, _transitAddress, msg.value));

     
    uint tokenPrice = tokenCategories[_tokenUri].price;

     
    uint claimEth = msg.value.sub(tokenPrice);

     
    uint tokenId = tokensCounter.add(1);
    nft.mintWithTokenURI(tokenId, _tokenUri);

     
    tokenCategories[_tokenUri].minted = tokenCategories[_tokenUri].minted.add(1);
    tokensCounter = tokensCounter.add(1);
    
     
    gifts[_transitAddress] = Gift(
				  msg.sender,
				  claimEth,
				  tokenId,
				  Statuses.Deposited,
				  _msgHash
				  );


     
    _transitAddress.transfer(EPHEMERAL_ADDRESS_FEE);

     
    uint donation = tokenPrice.sub(EPHEMERAL_ADDRESS_FEE);
    if (donation > 0) {
      bool donationSuccess = _makeDonation(msg.sender, donation);

       
      require(donationSuccess == true);
    }
    
     
    emit LogBuy(
		_transitAddress,
		msg.sender,
		_tokenUri,
		tokenId,
		claimEth,
		tokenPrice);
    return true;
  }

       
  function _makeDonation(address _giver, uint _value) internal returns (bool success) {
    bytes memory _data = abi.encodePacked(0x1870c10f,  
					   bytes32(_giver),
					   bytes32(givethReceiverId),
					   bytes32(0),
					   bytes32(0));
     
    success = givethBridge.call.value(_value)(_data);
    return success;
  }

       
  function getGift(address _transitAddress) public view returns (
	     uint256 tokenId,
	     string tokenUri,								 
	     address sender,   
	     uint claimEth,    
	     uint nftPrice,    
	     Statuses status,  
	     string msgHash    
    ) {
    Gift memory gift = gifts[_transitAddress];
    tokenUri =  nft.tokenURI(gift.tokenId);
    TokenCategory memory category = tokenCategories[tokenUri];    
    return (
	    gift.tokenId,
	    tokenUri,
	    gift.sender,
	    gift.claimEth,
	    category.price,	    
	    gift.status,
	    gift.msgHash
	    );
  }
  
   
  function cancelGift(address _transitAddress) public returns (bool success) {
    Gift storage gift = gifts[_transitAddress];

     
    require(gift.status == Statuses.Deposited);
    
     
    require(msg.sender == gift.sender);
    
     
    gift.status = Statuses.Cancelled;

     
    if (gift.claimEth > 0) {
      gift.sender.transfer(gift.claimEth);
    }

     
    nft.transferFrom(address(this), msg.sender, gift.tokenId);

     
    emit LogCancel(_transitAddress, msg.sender, gift.tokenId);

    return true;
  }

  
   
  function claimGift(address _receiver) public whenNotPaused returns (bool success) {
     
    address _transitAddress = msg.sender;
    
    Gift storage gift = gifts[_transitAddress];

     
    require(gift.status == Statuses.Deposited);

     
    gift.status = Statuses.Claimed;
    
     
    nft.transferFrom(address(this), _receiver, gift.tokenId);
    
     
    if (gift.claimEth > 0) {
      _receiver.transfer(gift.claimEth);
    }

     
    emit LogClaim(_transitAddress, gift.sender, gift.tokenId, _receiver, gift.claimEth);
    
    return true;
  }

   
  function() public payable {
    revert();
  }
}