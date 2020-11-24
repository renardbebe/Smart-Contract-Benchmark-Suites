 

pragma solidity ^0.4.24;

 

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
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

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
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

 

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
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

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
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

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
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

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 



 
contract ERC721TokenWithData is ERC721Token("CryptoAssaultUnit", "CAU"), Ownable {

   
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
			approvedContractAddresses[_spender] ||
			getApproved(_tokenId) == _spender ||
			isApprovedForAll(owner, _spender)
		);
	}

	mapping (address => bool) internal approvedContractAddresses;
	bool approvedContractsFinalized = false;

	 
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

	mapping(uint256 => mapping(uint256 => uint256)) data;

	function getData(uint256 _tokenId, uint256 _index) public view returns (uint256) {
		return data[_index][_tokenId];
	}

	function getData3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _index) public view returns (uint256, uint256, uint256) {
		return (
			data[_index][_tokenId1],
			data[_index][_tokenId2],
			data[_index][_tokenId3]
		);
	}
	
	function getDataAndOwner3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _index) public view returns (uint256, uint256, uint256, address, address, address) {
		return (
			data[_index][_tokenId1],
			data[_index][_tokenId2],
			data[_index][_tokenId3],
			ownerOf(_tokenId1),
			ownerOf(_tokenId2),
			ownerOf(_tokenId3)
		);
	}
	
	function _setData(uint256 _tokenId, uint256 _index, uint256 _data) internal {
		
		data[_index][_tokenId] = _data;
	}

	function setData(uint256 _tokenId, uint256 _index, uint256 _data) public {
		
		require(approvedContractAddresses[msg.sender], "not an approved sender");
		data[_index][_tokenId] = _data;
	}

	 
	function tokensOfWithData(address _owner, uint256 _index) public view returns (uint256[], uint256[]) {
		uint256[] memory tokensList = ownedTokens[_owner];
		uint256[] memory dataList = new uint256[](tokensList.length);
		for (uint i=0; i<tokensList.length; i++) {
			dataList[i] = data[_index][tokensList[i]];
		}
		return (tokensList, dataList);
	}

	 
	uint256 nextTokenId = 1;

	function getNextTokenId() public view returns (uint256) {
		return nextTokenId;
	}

	 
	function mintAndSetData(address _to, uint256 _data) public returns (uint256) {

		require(approvedContractAddresses[msg.sender], "not an approved sender");

		uint256 tokenId = nextTokenId;
		nextTokenId++;
		_mint(_to, tokenId);
		_setData(tokenId, 0, _data);

		return tokenId;
	}

	function burn(uint256 _tokenId) public {
		require(
			approvedContractAddresses[msg.sender] ||
			msg.sender == owner, "burner not approved"
		);

		_burn(ownerOf(_tokenId), _tokenId);
	}
	
	function burn3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3) public {
		require(
			approvedContractAddresses[msg.sender] ||
			msg.sender == owner, "burner not approved"
		);

		_burn(ownerOf(_tokenId1), _tokenId1);
		_burn(ownerOf(_tokenId2), _tokenId2);
		_burn(ownerOf(_tokenId3), _tokenId3);
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

 

contract Token is ERC721TokenWithData {

	string metadataUrlPrefix = "https://metadata.cryptoassault.io/unit/";

	 
	function tokenURI(uint256 _tokenId) public view returns (string) {
		require(exists(_tokenId));
		return Strings.strConcat(metadataUrlPrefix, Strings.uint2str(_tokenId));
	}

	function setMetadataUrlPrefix(string _metadataUrlPrefix) public onlyOwner
	{
		metadataUrlPrefix = _metadataUrlPrefix;
	}
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

contract PackSale is Pausable {

	event Sold(address buyer, uint256 sku, uint256 totalPrice);
	event Hatched(address buyer, uint256 amount);

	uint256 constant PRESALE_START_TIME = 1542484800;  
	uint256 constant NUM_UNIT_TYPES = 30;

	Token token;

	function setTokenContractAddress(address newAddress) onlyOwner public {
		token = Token(newAddress);
	}
	
	struct WaitingToHatch {
		address owner;
		uint16 amount;
		uint16 rarity;
		uint16 sku;
		uint48 purchasedOnBlockNumber;
	}
	mapping (uint256 => WaitingToHatch) waitingToHatch;  

	uint64 waitingToHatchNum;
	uint64 hatchNonce = 1;

	 
	mapping(uint256 => uint256) prices;

	constructor() public {
		prices[1] = 0.017 ether;
		prices[2] = 0.085 ether;
		prices[3] = 0.33 ether;
		prices[4] = 0.587 ether;
		prices[5] = 1.2 ether;
		prices[6] = 2.99 ether;
	}
	
	function withdrawBalance() onlyOwner public {
		owner.transfer(address(this).balance);
	}

	function setPrice(uint32 sku, uint64 price) public onlyOwner {
		prices[sku] = price;
	}

	function getPrice(uint32 sku) public view returns (uint256)
	{
		require(now >= PRESALE_START_TIME, "The sale hasn't started yet");

		uint256 price = prices[sku];
		require (price > 0);

		 
		uint256 intervalsSinceSaleStarted = (now - PRESALE_START_TIME) / (2 days);
		 
		uint256 pricePercentage = 70 + intervalsSinceSaleStarted;
		if (pricePercentage < 100) {
			price = (price * pricePercentage) / 100;
		}

		return price;
	}

	function pushHatch(address to, uint16 amount, uint16 rarity, uint16 sku) private {

		waitingToHatch[waitingToHatchNum] = WaitingToHatch(to, amount, rarity, sku, uint32(block.number));
		waitingToHatchNum = waitingToHatchNum + 1;
	}

	function popHatch() private {

		require(waitingToHatchNum > 0, "trying to popHatch() an empty stack");
		waitingToHatchNum = waitingToHatchNum - 1;
	}

	function peekHatch() private view returns (WaitingToHatch) {

		return waitingToHatch[waitingToHatchNum-1];
	}

	function buy(uint16 sku, address referral) external payable whenNotPaused {

		uint256 price = getPrice(sku);
		require(msg.value >= price, "Amount paid is too low");

		 

		if (sku == 1) {
			pushHatch(msg.sender, 1, 0, sku);  
		} else if (sku == 2) {
			pushHatch(msg.sender, 5, 0, sku);  
		} else if (sku == 3) {
			 
			pushHatch(msg.sender, 10, 0, sku); 
			pushHatch(msg.sender, 10, 0, sku); 
		} else if (sku == 4) {
			pushHatch(msg.sender, 10, 1, sku);   
		} else if (sku == 5) {
			pushHatch(msg.sender, 10, 1, sku);   
			 
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
		} else if (sku == 6) {
			 
			pushHatch(msg.sender, 3, 2, sku);
			 
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 7, 1, sku);
		} else {
			require(false, "Invalid sku");
		}

		 
		if (referral != address(0) && referral != msg.sender) {
			referral.transfer(price / 20);
		}

		emit Sold(msg.sender, sku, price);
	}

	function giveFreeUnit(address to, uint16 minRarity) onlyOwner public
	{
		pushHatch(to, 1, minRarity, 0);
	}

	function getNumMyHatchingUnits() public view returns (uint256) {
		uint256 num = 0;
		for (uint256 i=0; i<waitingToHatchNum; i++) {
			if (waitingToHatch[i].owner == msg.sender) {
				num += waitingToHatch[i].amount;
			}
		}
		return num;
	}

	function hatchingsNeeded() external view returns (uint256) {

		return waitingToHatchNum;
	}
	
	function getProjectedBlockHash(uint256 blockNumber) internal view returns (uint256) {

		uint256 blockToHash = blockNumber;
		uint256 blocksAgo = block.number - blockToHash;
		blockToHash += ((blocksAgo-1) / 256) * 256;
		return uint256(blockhash(blockToHash));
	}

	function getRandomType(uint16 rand) internal pure returns (uint8)
	{
		return uint8(rand % NUM_UNIT_TYPES);
	}
 
	function getRandomRarity(uint32 rand, uint256 minimumRarity) internal pure returns (uint256)
	{

		uint256 rarityRand;
		if (minimumRarity == 0) {
			rarityRand = rand % 100;
		} else if (minimumRarity == 1) {
			rarityRand = rand % 20 + 80;
		} else if (minimumRarity == 2) {
			rarityRand = rand % 5 + 95;
		} else if (minimumRarity == 3) {
			rarityRand = 99;
		} else {
			require(false, "Invalid minimumRarity");
		}

		if (rarityRand < 80) return 0;
		if (rarityRand < 95) return 1;
		if (rarityRand < 99) return 2;
		return 3;
	}

	function hatch() external whenNotPaused {

		require(waitingToHatchNum > 0, "nothing to hatch");

		WaitingToHatch memory w = peekHatch();
		
		 
		require (w.purchasedOnBlockNumber < block.number, "Can't hatch on the same block.");

		uint256 rand = getProjectedBlockHash(w.purchasedOnBlockNumber) + hatchNonce;

		for (uint256 i=0; i<w.amount; i++) {
			rand = uint256(keccak256(abi.encodePacked(rand)));
			uint256 thisRand = rand;
			uint8 unitType = getRandomType(uint16(thisRand));
			thisRand >>= 16;

			uint256 rarity = getRandomRarity(uint32(thisRand), w.rarity);
			thisRand >>= 32;

			 

			uint256 data = unitType;  

			data <<= 4;
			 

			 
			data <<= 24;
			data |= now / (1 days);

			data <<= 4;
			data |= rarity;
			data <<= 8;
			data |= w.sku;
			data <<= 208;
			data |= thisRand & 0xffffffffffffffffffffffffffffffffffff0000000000000000;

			token.mintAndSetData(w.owner, data);
		}

		popHatch();

		hatchNonce++;

		emit Hatched(w.owner, w.amount);
	}

}