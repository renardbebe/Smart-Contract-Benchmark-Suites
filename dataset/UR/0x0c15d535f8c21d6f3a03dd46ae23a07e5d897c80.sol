 

pragma solidity ^0.4.25;

	 

	 
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
	
	 
	contract ReentrancyGuard {

	 
	uint256 private guardCounter = 1;

	 
		modifier nonReentrant() {
			guardCounter += 1;
			uint256 localCounter = guardCounter;
			_;
			require(localCounter == guardCounter);
		}
	}
	
	 
	interface ERC165 {

	   
	  function supportsInterface(bytes4 _interfaceId)
		external
		view
		returns (bool);
	}

	 
	contract ERC721Receiver {
	   
	  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	   
	  function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes _data
	  )
		public
		returns(bytes4);
	}

	 
	library AddressUtils {

	   
	  function isContract(address addr) internal view returns (bool) {
		uint256 size;
		 
		 
		 
		 
		 
		 
		 
		assembly { size := extcodesize(addr) }
		return size > 0;
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

	   
	  function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	  }

	   
	  function transferOwnership(address _newOwner) public onlyOwner {
		_transferOwnership(_newOwner);
	  }

	   
	  function _transferOwnership(address _newOwner) internal onlyOwner {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	  }
	}
	
	contract Fallback is Ownable {

	  function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
      }
	}
	
	 
	contract SupportsInterfaceWithLookup is ERC165 {
	  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
	   

	   
	  mapping(bytes4 => bool) internal supportedInterfaces;

	   
	  constructor()
		public
	  {
		_registerInterface(InterfaceId_ERC165);
	  }

	   
	  function supportsInterface(bytes4 _interfaceId)
		external
		view
		returns (bool)
	  {
		return supportedInterfaces[_interfaceId];
	  }

	   
	  function _registerInterface(bytes4 _interfaceId)
		internal
	  {
		require(_interfaceId != 0xffffffff);
		supportedInterfaces[_interfaceId] = true;
	  }
	}

	 
	contract ERC721Basic is ERC165 {
	  event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 indexed _tokenId
	  );
	  event Approval(
		address indexed _owner,
		address indexed _approved,
		uint256 indexed _tokenId
	  );
	  event ApprovalForAll(
		address indexed _owner,
		address indexed _operator,
		bool _approved
	  );

	  function balanceOf(address _owner) public view returns (uint256 _balance);
	  function ownerOf(uint256 _tokenId) public view returns (address _owner);
	  function exists(uint256 _tokenId) public view returns (bool _exists);

	  function approve(address _to, uint256 _tokenId) public;
	  function getApproved(uint256 _tokenId)
		public view returns (address _operator);

	  function setApprovalForAll(address _operator, bool _approved) public;
	  function isApprovedForAll(address _owner, address _operator)
		public view returns (bool);

	  function transferFrom(address _from, address _to, uint256 _tokenId) public;
	  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
		public;

	  function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes _data
	  )
		public;
	}

	 
	contract ERC721Enumerable is ERC721Basic {
	  function totalSupply() public view returns (uint256);
	  function tokenOfOwnerByIndex(
		address _owner,
		uint256 _index
	  )
		public
		view
		returns (uint256 _tokenId);

	  function tokenByIndex(uint256 _index) public view returns (uint256);
	}


	 
	contract ERC721Metadata is ERC721Basic {
	  function name() external view returns (string _name);
	  function symbol() external view returns (string _symbol);
	  function tokenURI(uint256 _tokenId) public view returns (string);
	}


	 
	contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
	}

	 
	contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

	  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
	   

	  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
	   

	  using SafeMath for uint256;
	  using AddressUtils for address;

	   
	   
	  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

	   
	  mapping (uint256 => address) internal tokenOwner;

	   
	  mapping (uint256 => address) internal tokenApprovals;

	   
	  mapping (address => uint256) internal ownedTokensCount;

	   
	  mapping (address => mapping (address => bool)) internal operatorApprovals;

	   
	  modifier onlyOwnerOf(uint256 _tokenId) {
		require(ownerOf(_tokenId) == msg.sender);
		_;
	  }

	   
	  modifier canTransfer(uint256 _tokenId) {
		require(isApprovedOrOwner(msg.sender, _tokenId));
		_;
	  }

	  constructor()
		public
	  {
		 
		_registerInterface(InterfaceId_ERC721);
		_registerInterface(InterfaceId_ERC721Exists);
	  }

	   
	  function balanceOf(address _owner) public view returns (uint256) {
		require(_owner != address(0));
		return ownedTokensCount[_owner];
	  }

	   
	  function ownerOf(uint256 _tokenId) public view returns (address) {
		address owner = tokenOwner[_tokenId];
		require(owner != address(0));
		return owner;
	  }

	   
	  function exists(uint256 _tokenId) public view returns (bool) {
		address owner = tokenOwner[_tokenId];
		return owner != address(0);
	  }

	   
	  function approve(address _to, uint256 _tokenId) public {
		address owner = ownerOf(_tokenId);
		require(_to != owner);
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

		tokenApprovals[_tokenId] = _to;
		emit Approval(owner, _to, _tokenId);
	  }

	   
	  function getApproved(uint256 _tokenId) public view returns (address) {
		return tokenApprovals[_tokenId];
	  }

	   
	  function setApprovalForAll(address _to, bool _approved) public {
		require(_to != msg.sender);
		operatorApprovals[msg.sender][_to] = _approved;
		emit ApprovalForAll(msg.sender, _to, _approved);
	  }

	   
	  function isApprovedForAll(
		address _owner,
		address _operator
	  )
		public
		view
		returns (bool)
	  {
		return operatorApprovals[_owner][_operator];
	  }

	   
	  function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	  )
		public
		canTransfer(_tokenId)
	  {
		require(_from != address(0));
		require(_to != address(0));

		clearApproval(_from, _tokenId);
		removeTokenFrom(_from, _tokenId);
		addTokenTo(_to, _tokenId);

		emit Transfer(_from, _to, _tokenId);
	  }

	   
	  function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	  )
		public
		canTransfer(_tokenId)
	  {
		 
		safeTransferFrom(_from, _to, _tokenId, "");
	  }

	   
	  function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes _data
	  )
		public
		canTransfer(_tokenId)
	  {
		transferFrom(_from, _to, _tokenId);
		 
		require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
	  }

	   
	  function isApprovedOrOwner(
		address _spender,
		uint256 _tokenId
	  )
		internal
		view
		returns (bool)
	  {
		address owner = ownerOf(_tokenId);
		 
		 
		 
		return (
		  _spender == owner ||
		  getApproved(_tokenId) == _spender ||
		  isApprovedForAll(owner, _spender)
		);
	  }

	   
	  function _mint(address _to, uint256 _tokenId) internal {
		require(_to != address(0));
		addTokenTo(_to, _tokenId);
		emit Transfer(address(0), _to, _tokenId);
	  }

	   
	  function clearApproval(address _owner, uint256 _tokenId) internal {
		require(ownerOf(_tokenId) == _owner);
		if (tokenApprovals[_tokenId] != address(0)) {
		  tokenApprovals[_tokenId] = address(0);
		}
	  }

	   
	  function addTokenTo(address _to, uint256 _tokenId) internal {
		require(tokenOwner[_tokenId] == address(0));
		tokenOwner[_tokenId] = _to;
		ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
	  }

	   
	  function removeTokenFrom(address _from, uint256 _tokenId) internal {
		require(ownerOf(_tokenId) == _from);
		ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
		tokenOwner[_tokenId] = address(0);
	  }

	   
	  function checkAndCallSafeTransfer(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes _data
	  )
		internal
		returns (bool)
	  {
		if (!_to.isContract()) {
		  return true;
		}
		bytes4 retval = ERC721Receiver(_to).onERC721Received(
		  msg.sender, _from, _tokenId, _data);
		return (retval == ERC721_RECEIVED);
	  }
	}

	 
	contract ERC721dAppCaps is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721, Ownable, Fallback {

	   
	   
	  event BoughtToken(address indexed buyer, uint256 tokenId);

	   
      string public constant company = "Qwoyn, LLC ";
      string public constant contact = "https://qwoyn.io";
      string public constant author  = "Daniel Pittman";

	  
	  uint8 constant TITLE_MAX_LENGTH = 64;
	  uint256 constant DESCRIPTION_MAX_LENGTH = 100000;

	   

	   
	   
	   
	  uint256 currentPrice = 0;
	  
	  mapping(uint256 => uint256) tokenTypes;
	  mapping(uint256 => string)  tokenTitles;	  
	  mapping(uint256 => string)  tokenDescriptions;
	  mapping(uint256 => string)  specialQualities;	  	  
	  mapping(uint256 => string)  tokenClasses;
	  mapping(uint256 => string)  iptcKeywords;
	  

	  constructor(string _name, string _symbol) public {
		name_ = _name;
		symbol_ = _symbol;

		 
		_registerInterface(InterfaceId_ERC721Enumerable);
		_registerInterface(InterfaceId_ERC721Metadata);
	  }

	   
	   
	   
	   
	   
	  function buyToken (
		uint256 _type,
		string  _title,
		string  _description,
		string  _specialQuality,
		string  _iptcKeyword,
		string  _tokenClass
	  ) public onlyOwner {
		bytes memory _titleBytes = bytes(_title);
		require(_titleBytes.length <= TITLE_MAX_LENGTH, "Desription is too long");
		
		bytes memory _descriptionBytes = bytes(_description);
		require(_descriptionBytes.length <= DESCRIPTION_MAX_LENGTH, "Description is too long");
		require(msg.value >= currentPrice, "Amount of Ether sent too small");

		uint256 index = allTokens.length + 1;

		_mint(msg.sender, index);

		tokenTypes[index]        = _type;
		tokenTitles[index]       = _title;
		tokenDescriptions[index] = _description;
		specialQualities[index]  = _specialQuality;
		iptcKeywords[index]      = _iptcKeyword;
		tokenClasses[index]      = _tokenClass;

		emit BoughtToken(msg.sender, index);
	  }

	   
	  function myTokens()
		external
		view
		returns (
		  uint256[]
		)
	  {
		return ownedTokens[msg.sender];
	  }

	   
	   
	  function viewTokenMeta(uint256 _tokenId)
		external
		view
		returns (
		  uint256 tokenType_,
		  string  specialQuality_,
		  string  tokenTitle_,
		  string  tokenDescription_,
		  string  iptcKeyword_,
		  string  tokenClass_
	  ) {
		  tokenType_        = tokenTypes[_tokenId];
		  tokenTitle_       = tokenTitles[_tokenId];
		  tokenDescription_ = tokenDescriptions[_tokenId];
		  specialQuality_   = specialQualities[_tokenId];
		  iptcKeyword_      = iptcKeywords[_tokenId];
		  tokenClass_       = tokenClasses[_tokenId];
	  }

	   
	  function setCurrentPrice(uint256 newPrice)
		public
		onlyOwner
	  {
		  currentPrice = newPrice;
	  }

	   
	  function getCurrentPrice()
		external
		view
		returns (
		uint256 price
	  ) {
		  price = currentPrice;
	  }
	  
	  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
	   

	  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
	   

	   
	  string internal name_;

	   
	  string internal symbol_;

	   
	  mapping(address => uint256[]) internal ownedTokens;

	   
	  mapping(uint256 => uint256) internal ownedTokensIndex;

	   
	  uint256[] internal allTokens;

	   
	  mapping(uint256 => uint256) internal allTokensIndex;

	   
	  mapping(uint256 => string) internal tokenURIs;

	   
	  function name() external view returns (string) {
		return name_;
	  }

	   
	  function symbol() external view returns (string) {
		return symbol_;
	  }

	   
	  function tokenURI(uint256 _tokenId) public view returns (string) {
		require(exists(_tokenId));
		return tokenURIs[_tokenId];
	  }

	   
	  function tokenOfOwnerByIndex(
		address _owner,
		uint256 _index
	  )
		public
		view
		returns (uint256)
	  {
		require(_index < balanceOf(_owner));
		return ownedTokens[_owner][_index];
	  }

	   
	  function totalSupply() public view returns (uint256) {
		return allTokens.length;
	  }

	   
	  function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return allTokens[_index];
	  }

	   
	  function _setTokenURI(uint256 _tokenId, string _uri) public onlyOwner {
		require(exists(_tokenId));
		tokenURIs[_tokenId] = _uri;
	  }

	   
	  function addTokenTo(address _to, uint256 _tokenId) internal {
		super.addTokenTo(_to, _tokenId);
		uint256 length = ownedTokens[_to].length;
		ownedTokens[_to].push(_tokenId);
		ownedTokensIndex[_tokenId] = length;
	  }

	   
	  function removeTokenFrom(address _from, uint256 _tokenId) internal {
		super.removeTokenFrom(_from, _tokenId);

		uint256 tokenIndex = ownedTokensIndex[_tokenId];
		uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
		uint256 lastToken = ownedTokens[_from][lastTokenIndex];

		ownedTokens[_from][tokenIndex] = lastToken;
		ownedTokens[_from][lastTokenIndex] = 0;
		 
		 
		 

		ownedTokens[_from].length--;
		ownedTokensIndex[_tokenId] = 0;
		ownedTokensIndex[lastToken] = tokenIndex;
	  }

	   
	  function _mint(address _to, uint256 _tokenId) internal {
		super._mint(_to, _tokenId);

		allTokensIndex[_tokenId] = allTokens.length;
		allTokens.push(_tokenId);
	  }
	}