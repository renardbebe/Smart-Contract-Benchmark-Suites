 

pragma solidity ^0.4.24;


 
contract ERC721 {

	 
	bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;

	 
	bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;

	 
	bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;

	 
	bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;

	 
	mapping(bytes4 => bool) internal supportedInterfaces;

	 
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	 
	constructor() public
	{
		registerInterface(InterfaceId_ERC165);
		registerInterface(InterfaceId_ERC721);
		registerInterface(InterfaceId_ERC721Enumerable);
		registerInterface(InterfaceId_ERC721Metadata);
	}

	 
	function registerInterface(bytes4 _interfaceId) internal
	{
		require(_interfaceId != 0xffffffff);
		supportedInterfaces[_interfaceId] = true;
	}

	 
	function supportsInterface(bytes4 _interfaceId) external view returns(bool)
	{
		return supportedInterfaces[_interfaceId];
	}

	 
	function balanceOf(address _owner) public view returns(uint256 _balance);
	function ownerOf(uint256 _tokenId) public view returns(address _owner);
	function approve(address _to, uint256 _tokenId) public;
	function getApproved(uint256 _tokenId) public view returns(address _operator);
	function setApprovalForAll(address _operator, bool _approved) public;
	function isApprovedForAll(address _owner, address _operator) public view returns(bool);
	function transferFrom(address _from, address _to, uint256 _tokenId) public;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;

	 
	function totalSupply() public view returns(uint256 _total);
	function tokenByIndex(uint256 _index) public view returns(uint256 _tokenId);
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns(uint256 _tokenId);

	 
	function name() public view returns(string _name);
	function symbol() public view returns(string _symbol);
	function tokenURI(uint256 _tokenId) public view returns(string);
}


 
contract PixelCons is ERC721 {

	using AddressUtils for address;

	 
	bytes4 private constant ERC721_RECEIVED = 0x150b7a02;


	 
	 
	 

	 
	struct PixelCon {
		uint256 tokenId;
		 
		address creator;
		uint64 collectionIndex;
		uint32 dateCreated;
	}

	 
	struct TokenLookup {
		address owner;
		uint64 tokenIndex;
		uint32 ownedIndex;
	}


	 
	 
	 

	 
	address internal admin;

	 
	string internal tokenURITemplate;

	 

	 
	mapping(uint256 => TokenLookup) internal tokenLookup;

	 
	mapping(address => uint64[]) internal ownedTokens;

	 
	mapping(address => uint64[]) internal createdTokens;

	 
	mapping(uint256 => address) internal tokenApprovals;

	 
	mapping(address => mapping(address => bool)) internal operatorApprovals;

	 
	PixelCon[] internal pixelcons;

	 
	bytes8[] internal pixelconNames;

	 

	 
	mapping(uint64 => uint64[]) internal collectionTokens;

	 
	bytes8[] internal collectionNames;


	 
	 
	 

	 
	event Create(uint256 indexed _tokenId, address indexed _creator, uint64 _tokenIndex, address _to);
	event Rename(uint256 indexed _tokenId, bytes8 _newName);

	 
	event CreateCollection(address indexed _creator, uint64 indexed _collectionIndex);
	event RenameCollection(uint64 indexed _collectionIndex, bytes8 _newName);
	event ClearCollection(uint64 indexed _collectionIndex);


	 
	 
	 

	 
	modifier validIndex(uint64 _index) {
		require(_index != uint64(0), "Invalid index");
		_;
	}
	modifier validId(uint256 _id) {
		require(_id != uint256(0), "Invalid ID");
		_;
	}
	modifier validAddress(address _address) {
		require(_address != address(0), "Invalid address");
		_;
	}


	 
	 
	 

	 
	constructor() public
	{
		 
		admin = msg.sender;

		 
		collectionNames.length++;
	}

	 
	function getAdmin() public view returns(address)
	{
		return admin;
	}

	 
	function adminWithdraw(address _to) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		_to.transfer(address(this).balance);
	}

	 
	function adminChange(address _newAdmin) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		admin = _newAdmin;
	}

	 
	function adminSetTokenURITemplate(string _newTokenURITemplate) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		tokenURITemplate = _newTokenURITemplate;
	}

	 

	 
	function create(address _to, uint256 _tokenId, bytes8 _name) public payable validAddress(_to) validId(_tokenId) returns(uint64)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(pixelcons.length < uint256(2 ** 64) - 1, "Max number of PixelCons has been reached");
		require(lookupData.owner == address(0), "PixelCon already exists");

		 
		uint32 dateCreated = 0;
		if (now < uint256(2 ** 32)) dateCreated = uint32(now);

		 
		uint64 index = uint64(pixelcons.length);
		lookupData.tokenIndex = index;
		pixelcons.length++;
		pixelconNames.length++;
		PixelCon storage pixelcon = pixelcons[index];
		pixelcon.tokenId = _tokenId;
		pixelcon.creator = msg.sender;
		pixelcon.dateCreated = dateCreated;
		pixelconNames[index] = _name;
		uint64[] storage createdList = createdTokens[msg.sender];
		uint createdListIndex = createdList.length;
		createdList.length++;
		createdList[createdListIndex] = index;
		addTokenTo(_to, _tokenId);

		emit Create(_tokenId, msg.sender, index, _to);
		emit Transfer(address(0), _to, _tokenId);
		return index;
	}

	 
	function rename(uint256 _tokenId, bytes8 _name) public validId(_tokenId) returns(uint64)
	{
		require(isCreatorAndOwner(msg.sender, _tokenId), "Sender is not the creator and owner");

		 
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		pixelconNames[lookupData.tokenIndex] = _name;

		emit Rename(_tokenId, _name);
		return lookupData.tokenIndex;
	}

	 
	function exists(uint256 _tokenId) public view validId(_tokenId) returns(bool)
	{
		address owner = tokenLookup[_tokenId].owner;
		return owner != address(0);
	}

	 
	function creatorOf(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return pixelcons[lookupData.tokenIndex].creator;
	}

	 
	function creatorTotal(address _creator) public view validAddress(_creator) returns(uint256)
	{
		return createdTokens[_creator].length;
	}

	 
	function tokenOfCreatorByIndex(address _creator, uint256 _index) public view validAddress(_creator) returns(uint256)
	{
		require(_index < createdTokens[_creator].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[createdTokens[_creator][_index]];
		return pixelcon.tokenId;
	}

	 
	function getTokenData(uint256 _tokenId) public view validId(_tokenId)
	returns(uint256 _tknId, uint64 _tknIdx, uint64 _collectionIdx, address _owner, address _creator, bytes8 _name, uint32 _dateCreated)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		PixelCon storage pixelcon = pixelcons[lookupData.tokenIndex];
		return (pixelcon.tokenId, lookupData.tokenIndex, pixelcon.collectionIndex, lookupData.owner,
			pixelcon.creator, pixelconNames[lookupData.tokenIndex], pixelcon.dateCreated);
	}

	 
	function getTokenDataByIndex(uint64 _tokenIndex) public view
	returns(uint256 _tknId, uint64 _tknIdx, uint64 _collectionIdx, address _owner, address _creator, bytes8 _name, uint32 _dateCreated)
	{
		require(_tokenIndex < totalSupply(), "PixelCon index is out of bounds");

		PixelCon storage pixelcon = pixelcons[_tokenIndex];
		TokenLookup storage lookupData = tokenLookup[pixelcon.tokenId];
		return (pixelcon.tokenId, lookupData.tokenIndex, pixelcon.collectionIndex, lookupData.owner,
			pixelcon.creator, pixelconNames[lookupData.tokenIndex], pixelcon.dateCreated);
	}

	 
	function getTokenIndex(uint256 _tokenId) validId(_tokenId) public view returns(uint64)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return lookupData.tokenIndex;
	}

	 

	 
	function createCollection(uint64[] _tokenIndexes, bytes8 _name) public returns(uint64)
	{
		require(collectionNames.length < uint256(2 ** 64) - 1, "Max number of collections has been reached");
		require(_tokenIndexes.length > 1, "Collection must contain more than one PixelCon");

		 
		uint64 collectionIndex = uint64(collectionNames.length);
		uint64[] storage collection = collectionTokens[collectionIndex];
		collection.length = _tokenIndexes.length;
		for (uint i = 0; i < _tokenIndexes.length; i++) {
			uint64 tokenIndex = _tokenIndexes[i];
			require(tokenIndex < totalSupply(), "PixelCon index is out of bounds");

			PixelCon storage pixelcon = pixelcons[tokenIndex];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");
			require(pixelcon.collectionIndex == uint64(0), "PixelCon is already in a collection");

			pixelcon.collectionIndex = collectionIndex;
			collection[i] = tokenIndex;
		}
		collectionNames.length++;
		collectionNames[collectionIndex] = _name;

		emit CreateCollection(msg.sender, collectionIndex);
		return collectionIndex;
	}

	 
	function renameCollection(uint64 _collectionIndex, bytes8 _name) validIndex(_collectionIndex) public returns(uint64)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");

		 
		uint64[] storage collection = collectionTokens[_collectionIndex];
		require(collection.length > 0, "Collection has been cleared");
		for (uint i = 0; i < collection.length; i++) {
			PixelCon storage pixelcon = pixelcons[collection[i]];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");
		}

		 
		collectionNames[_collectionIndex] = _name;

		emit RenameCollection(_collectionIndex, _name);
		return _collectionIndex;
	}

	 
	function clearCollection(uint64 _collectionIndex) validIndex(_collectionIndex) public returns(uint64)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");

		 
		uint64[] storage collection = collectionTokens[_collectionIndex];
		require(collection.length > 0, "Collection is already cleared");
		for (uint i = 0; i < collection.length; i++) {
			PixelCon storage pixelcon = pixelcons[collection[i]];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");

			pixelcon.collectionIndex = 0;
		}

		 
		delete collectionNames[_collectionIndex];
		delete collectionTokens[_collectionIndex];

		emit ClearCollection(_collectionIndex);
		return _collectionIndex;
	}

	 
	function collectionExists(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bool)
	{
		return _collectionIndex < totalCollections();
	}

	 
	function collectionCleared(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bool)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionTokens[_collectionIndex].length == uint256(0);
	}

	 
	function totalCollections() public view returns(uint256)
	{
		return collectionNames.length;
	}

	 
	function collectionOf(uint256 _tokenId) public view validId(_tokenId) returns(uint256)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return pixelcons[tokenLookup[_tokenId].tokenIndex].collectionIndex;
	}

	 
	function collectionTotal(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(uint256)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionTokens[_collectionIndex].length;
	}

	 
	function getCollectionName(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bytes8)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionNames[_collectionIndex];
	}

	 
	function tokenOfCollectionByIndex(uint64 _collectionIndex, uint256 _index) public view validIndex(_collectionIndex) returns(uint256)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		require(_index < collectionTokens[_collectionIndex].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[collectionTokens[_collectionIndex][_index]];
		return pixelcon.tokenId;
	}

	 

	 
	function getForOwner(address _owner) public view validAddress(_owner) returns(uint64[])
	{
		return ownedTokens[_owner];
	}

	 
	function getForCreator(address _creator) public view validAddress(_creator) returns(uint64[])
	{
		return createdTokens[_creator];
	}

	 
	function getForCollection(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(uint64[])
	{
		return collectionTokens[_collectionIndex];
	}

	 
	function getBasicData(uint64[] _tokenIndexes) public view returns(uint256[], bytes8[], address[], uint64[])
	{
		uint256[] memory tokenIds = new uint256[](_tokenIndexes.length);
		bytes8[] memory names = new bytes8[](_tokenIndexes.length);
		address[] memory owners = new address[](_tokenIndexes.length);
		uint64[] memory collectionIdxs = new uint64[](_tokenIndexes.length);

		for (uint i = 0; i < _tokenIndexes.length; i++)	{
			uint64 tokenIndex = _tokenIndexes[i];
			require(tokenIndex < totalSupply(), "PixelCon index is out of bounds");

			tokenIds[i] = pixelcons[tokenIndex].tokenId;
			names[i] = pixelconNames[tokenIndex];
			owners[i] = tokenLookup[pixelcons[tokenIndex].tokenId].owner;
			collectionIdxs[i] = pixelcons[tokenIndex].collectionIndex;
		}
		return (tokenIds, names, owners, collectionIdxs);
	}

	 
	function getAllNames() public view returns(bytes8[])
	{
		return pixelconNames;
	}

	 
	function getNamesInRange(uint64 _startIndex, uint64 _endIndex) public view returns(bytes8[])
	{
		require(_startIndex <= totalSupply(), "Start index is out of bounds");
		require(_endIndex <= totalSupply(), "End index is out of bounds");
		require(_startIndex <= _endIndex, "End index is less than the start index");

		uint64 length = _endIndex - _startIndex;
		bytes8[] memory names = new bytes8[](length);
		for (uint i = 0; i < length; i++)	{
			names[i] = pixelconNames[_startIndex + i];
		}
		return names;
	}

	 
	function getCollectionData(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bytes8, uint64[])
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return (collectionNames[_collectionIndex], collectionTokens[_collectionIndex]);
	}

	 
	function getAllCollectionNames() public view returns(bytes8[])
	{
		return collectionNames;
	}

	 
	function getCollectionNamesInRange(uint64 _startIndex, uint64 _endIndex) public view returns(bytes8[])
	{
		require(_startIndex <= totalCollections(), "Start index is out of bounds");
		require(_endIndex <= totalCollections(), "End index is out of bounds");
		require(_startIndex <= _endIndex, "End index is less than the start index");

		uint64 length = _endIndex - _startIndex;
		bytes8[] memory names = new bytes8[](length);
		for (uint i = 0; i < length; i++)	{
			names[i] = collectionNames[_startIndex + i];
		}
		return names;
	}


	 
	 
	 

	 
	function balanceOf(address _owner) public view validAddress(_owner) returns(uint256)
	{
		return ownedTokens[_owner].length;
	}

	 
	function ownerOf(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return owner;
	}

	 
	function approve(address _to, uint256 _tokenId) public validId(_tokenId)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(_to != owner, "Cannot approve PixelCon owner");
		require(msg.sender == owner || operatorApprovals[owner][msg.sender], "Sender does not have permission to approve address");

		tokenApprovals[_tokenId] = _to;
		emit Approval(owner, _to, _tokenId);
	}

	 
	function getApproved(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return tokenApprovals[_tokenId];
	}

	 
	function setApprovalForAll(address _to, bool _approved) public validAddress(_to)
	{
		require(_to != msg.sender, "Cannot approve self");
		operatorApprovals[msg.sender][_to] = _approved;
		emit ApprovalForAll(msg.sender, _to, _approved);
	}

	 
	function isApprovedForAll(address _owner, address _operator) public view validAddress(_owner) validAddress(_operator) returns(bool)
	{
		return operatorApprovals[_owner][_operator];
	}

	 
	function transferFrom(address _from, address _to, uint256 _tokenId) public validAddress(_from) validAddress(_to) validId(_tokenId)
	{
		require(isApprovedOrOwner(msg.sender, _tokenId), "Sender does not have permission to transfer PixelCon");
		clearApproval(_from, _tokenId);
		removeTokenFrom(_from, _tokenId);
		addTokenTo(_to, _tokenId);

		emit Transfer(_from, _to, _tokenId);
	}

	 
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public
	{
		 
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	 
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public
	{
		 
		transferFrom(_from, _to, _tokenId);
		require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data), "Transfer was not safe");
	}


	 
	 
	 

	 
	function totalSupply() public view returns(uint256)
	{
		return pixelcons.length;
	}

	 
	function tokenByIndex(uint256 _tokenIndex) public view returns(uint256)
	{
		require(_tokenIndex < totalSupply(), "PixelCon index is out of bounds");
		return pixelcons[_tokenIndex].tokenId;
	}

	 
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view validAddress(_owner) returns(uint256)
	{
		require(_index < ownedTokens[_owner].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[ownedTokens[_owner][_index]];
		return pixelcon.tokenId;
	}


	 
	 
	 

	 
	function name() public view returns(string)
	{
		return "PixelCons";
	}

	 
	function symbol() public view returns(string)
	{
		return "PXCN";
	}

	 
	function tokenURI(uint256 _tokenId) public view returns(string)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");
		PixelCon storage pixelcon = pixelcons[lookupData.tokenIndex];
		bytes8 pixelconName = pixelconNames[lookupData.tokenIndex];

		 

		 
		string memory finalTokenURI = tokenURITemplate;
		finalTokenURI = StringUtils.replace(finalTokenURI, "<tokenId>", StringUtils.toHexString(_tokenId, 32));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<tokenIndex>", StringUtils.toHexString(uint256(lookupData.tokenIndex), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<name>", StringUtils.toHexString(uint256(pixelconName), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<owner>", StringUtils.toHexString(uint256(lookupData.owner), 20));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<creator>", StringUtils.toHexString(uint256(pixelcon.creator), 20));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<dateCreated>", StringUtils.toHexString(uint256(pixelcon.dateCreated), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<collectionIndex>", StringUtils.toHexString(uint256(pixelcon.collectionIndex), 8));

		return finalTokenURI;
	}


	 
	 
	 

	 
	function isCreatorAndOwner(address _address, uint256 _tokenId) internal view returns(bool)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		address owner = lookupData.owner;
		address creator = pixelcons[lookupData.tokenIndex].creator;

		return (_address == owner && _address == creator);
	}

	 
	function isApprovedOrOwner(address _address, uint256 _tokenId) internal view returns(bool)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return (_address == owner || tokenApprovals[_tokenId] == _address || operatorApprovals[owner][_address]);
	}

	 
	function clearApproval(address _owner, uint256 _tokenId) internal
	{
		require(tokenLookup[_tokenId].owner == _owner, "Incorrect PixelCon owner");
		if (tokenApprovals[_tokenId] != address(0)) {
			tokenApprovals[_tokenId] = address(0);
		}
	}

	 
	function addTokenTo(address _to, uint256 _tokenId) internal
	{
		uint64[] storage ownedList = ownedTokens[_to];
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(ownedList.length < uint256(2 ** 32) - 1, "Max number of PixelCons per owner has been reached");
		require(lookupData.owner == address(0), "PixelCon already has an owner");
		lookupData.owner = _to;

		 
		uint ownedListIndex = ownedList.length;
		ownedList.length++;
		lookupData.ownedIndex = uint32(ownedListIndex);
		ownedList[ownedListIndex] = lookupData.tokenIndex;
	}

	 
	function removeTokenFrom(address _from, uint256 _tokenId) internal
	{
		uint64[] storage ownedList = ownedTokens[_from];
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner == _from, "From address is incorrect");
		lookupData.owner = address(0);

		 
		uint64 replacementTokenIndex = ownedList[ownedList.length - 1];
		delete ownedList[ownedList.length - 1];
		ownedList.length--;
		if (lookupData.ownedIndex < ownedList.length) {
			 
			ownedList[lookupData.ownedIndex] = replacementTokenIndex;
			tokenLookup[pixelcons[replacementTokenIndex].tokenId].ownedIndex = lookupData.ownedIndex;
		}
		lookupData.ownedIndex = 0;
	}

	 
	function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns(bool)
	{
		if (!_to.isContract()) return true;

		bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
		return (retval == ERC721_RECEIVED);
	}
}


 
contract ERC721Receiver {

	 
	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	 
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


 
library AddressUtils {

	 
	function isContract(address _account) internal view returns(bool) 
	{
		uint256 size;
		 
		 
		 
		 
		 
		 
		assembly { size := extcodesize(_account) }
		return size > 0;
	}
}


 
library StringUtils {

	 
	function replace(string _str, string _key, string _value) internal pure returns(string)
	{
		bytes memory bStr = bytes(_str);
		bytes memory bKey = bytes(_key);
		bytes memory bValue = bytes(_value);

		uint index = indexOf(bStr, bKey);
		if (index < bStr.length) {
			bytes memory rStr = new bytes((bStr.length + bValue.length) - bKey.length);

			uint i;
			for (i = 0; i < index; i++) rStr[i] = bStr[i];
			for (i = 0; i < bValue.length; i++) rStr[index + i] = bValue[i];
			for (i = 0; i < bStr.length - (index + bKey.length); i++) rStr[index + bValue.length + i] = bStr[index + bKey.length + i];

			return string(rStr);
		}
		return string(bStr);
	}

	 
	function toHexString(uint256 _num, uint _byteSize) internal pure returns(string)
	{
		bytes memory s = new bytes(_byteSize * 2 + 2);
		s[0] = 0x30;
		s[1] = 0x78;
		for (uint i = 0; i < _byteSize; i++) {
			byte b = byte(uint8(_num / (2 ** (8 * (_byteSize - 1 - i)))));
			byte hi = byte(uint8(b) / 16);
			byte lo = byte(uint8(b) - 16 * uint8(hi));
			s[2 + 2 * i] = char(hi);
			s[3 + 2 * i] = char(lo);
		}
		return string(s);
	}

	 
	function char(byte _b) internal pure returns(byte c)
	{
		if (_b < 10) return byte(uint8(_b) + 0x30);
		else return byte(uint8(_b) + 0x57);
	}

	 
	function indexOf(bytes _str, bytes _key) internal pure returns(uint)
	{
		for (uint i = 0; i < _str.length - (_key.length - 1); i++) {
			bool matchFound = true;
			for (uint j = 0; j < _key.length; j++) {
				if (_str[i + j] != _key[j]) {
					matchFound = false;
					break;
				}
			}
			if (matchFound) {
				return i;
			}
		}
		return _str.length;
	}
}