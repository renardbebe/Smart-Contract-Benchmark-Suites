 

 

pragma solidity ^0.4.21;


 
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

 

pragma solidity ^0.4.22;


 
contract ApprovedCreatorRegistryInterface {

    function getVersion() public pure returns (uint);
    function typeOfContract() public pure returns (string);
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) public view returns (bool);

}

 

pragma solidity 0.4.25;


 
contract DigitalMediaStoreInterface {

    function getDigitalMediaStoreVersion() public pure returns (uint);

    function getStartingDigitalMediaId() public view returns (uint256);

    function registerTokenContractAddress() external;

     
    function createDigitalMedia(
                address _creator, 
                uint32 _printIndex, 
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath) external returns (uint);

     
    function incrementDigitalMediaPrintIndex(
                uint256 _digitalMediaId, 
                uint32 _increment)  external;

     
    function getDigitalMedia(uint256 _digitalMediaId) external view returns(
                uint256 id,
                uint32 totalSupply,
                uint32 printIndex,
                uint256 collectionId,
                address creator,
                string metadataPath);

     
    function createCollection(address _creator, string _metadataPath) external returns (uint);

     
    function getCollection(uint256 _collectionId) external view
            returns(
                uint256 id,
                address creator,
                string metadataPath);
}

 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

}

 

pragma solidity ^0.4.21;



 
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

 

pragma solidity 0.4.25;



 
contract MediaStoreVersionControl is Pausable {

     
    DigitalMediaStoreInterface public v1DigitalMediaStore;

     
    DigitalMediaStoreInterface public currentDigitalMediaStore;
    uint256 public currentStartingDigitalMediaId;


     
    modifier managersInitialized() {
        require(v1DigitalMediaStore != address(0));
        require(currentDigitalMediaStore != address(0));
        _;
    }

     
    function setDigitalMediaStoreAddress(address _dmsAddress)  
            internal {
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 2, "Incorrect version.");
        currentDigitalMediaStore = candidateDigitalMediaStore;
        currentDigitalMediaStore.registerTokenContractAddress();
        currentStartingDigitalMediaId = currentDigitalMediaStore.getStartingDigitalMediaId();
    }

     
    function setV1DigitalMediaStoreAddress(address _dmsAddress) public onlyOwner {
        require(address(v1DigitalMediaStore) == 0, "V1 media store already set.");
        DigitalMediaStoreInterface candidateDigitalMediaStore = DigitalMediaStoreInterface(_dmsAddress);
        require(candidateDigitalMediaStore.getDigitalMediaStoreVersion() == 1, "Incorrect version.");
        v1DigitalMediaStore = candidateDigitalMediaStore;
        v1DigitalMediaStore.registerTokenContractAddress();
    }

     
    function _getDigitalMediaStore(uint256 _digitalMediaId) 
            internal 
            view
            managersInitialized
            returns (DigitalMediaStoreInterface) {
        if (_digitalMediaId < currentStartingDigitalMediaId) {
            return v1DigitalMediaStore;
        } else {
            return currentDigitalMediaStore;
        }
    }  
}

 

pragma solidity 0.4.25;




 
contract DigitalMediaManager is MediaStoreVersionControl {

    struct DigitalMedia {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string metadataPath;
    }

    struct DigitalMediaCollection {
        uint256 id;
        address creator;
        string metadataPath;
    }

    ApprovedCreatorRegistryInterface public creatorRegistryStore;

     
    function setCreatorRegistryStore(address _crsAddress) internal {
        ApprovedCreatorRegistryInterface candidateCreatorRegistryStore = ApprovedCreatorRegistryInterface(_crsAddress);
        require(candidateCreatorRegistryStore.getVersion() == 1);
         
         
        require(keccak256(candidateCreatorRegistryStore.typeOfContract()) == keccak256("approvedCreatorRegistry"));
        creatorRegistryStore = candidateCreatorRegistryStore;
    }

     
    modifier registryInitialized() {
        require(creatorRegistryStore != address(0));
        _;
    }

     
    function _getCollection(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMediaCollection) {
        uint256 id;
        address creator;
        string memory metadataPath;
        (id, creator, metadataPath) = currentDigitalMediaStore.getCollection(_id);
        DigitalMediaCollection memory collection = DigitalMediaCollection({
            id: id,
            creator: creator,
            metadataPath: metadataPath
        });
        return collection;
    }

     
    function _getDigitalMedia(uint256 _id) 
            internal 
            view 
            managersInitialized 
            returns(DigitalMedia) {
        uint256 id;
        uint32 totalSupply;
        uint32 printIndex;
        uint256 collectionId;
        address creator;
        string memory metadataPath;
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_id);
        (id, totalSupply, printIndex, collectionId, creator, metadataPath) = _digitalMediaStore.getDigitalMedia(_id);
        DigitalMedia memory digitalMedia = DigitalMedia({
            id: id,
            creator: creator,
            totalSupply: totalSupply,
            printIndex: printIndex,
            collectionId: collectionId,
            metadataPath: metadataPath
        });
        return digitalMedia;
    }

     
    function _incrementDigitalMediaPrintIndex(DigitalMedia _dm, uint32 _increment) 
            internal 
            managersInitialized {
        DigitalMediaStoreInterface _digitalMediaStore = _getDigitalMediaStore(_dm.id);
        _digitalMediaStore.incrementDigitalMediaPrintIndex(_dm.id, _increment);
    }

     
    function isOperatorApprovedForCustodialAccount(
        address _operator, 
        address _owner) internal view registryInitialized returns(bool) {
        return creatorRegistryStore.isOperatorApprovedForCustodialAccount(
            _operator, _owner);
    }
}

 

pragma solidity 0.4.25;


 
contract SingleCreatorControl {

     
    address public singleCreatorAddress;

     
    event SingleCreatorChanged(
        address indexed previousCreatorAddress, 
        address indexed newCreatorAddress);

     
    function setSingleCreator(address _singleCreatorAddress) internal {
        require(singleCreatorAddress == address(0), "Single creator address already set.");
        singleCreatorAddress = _singleCreatorAddress;
    }

     
    function isAllowedSingleCreator(address _creatorAddress) internal view returns (bool) {
        require(_creatorAddress != address(0), "0x0 creator addresses are not allowed.");
        return singleCreatorAddress == address(0) || singleCreatorAddress == _creatorAddress;
    }

     
    function changeSingleCreator(address _newCreatorAddress) public {
        require(_newCreatorAddress != address(0));
        require(msg.sender == singleCreatorAddress, "Not approved to change single creator.");
        singleCreatorAddress = _newCreatorAddress;
        emit SingleCreatorChanged(singleCreatorAddress, _newCreatorAddress);
    }
}

 

pragma solidity ^0.4.21;


 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

pragma solidity ^0.4.21;



 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

pragma solidity ^0.4.21;


 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

pragma solidity ^0.4.21;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

pragma solidity ^0.4.21;






 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
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

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
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

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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
      emit Approval(_owner, address(0), _tokenId);
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

pragma solidity ^0.4.21;




 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
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

 

pragma solidity 0.4.25;

 



contract ERC721Safe is ERC721Token {
    bytes4 constant internal InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant internal InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
	
   function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 

pragma solidity 0.4.25;


library Memory {

     
    uint internal constant WORD_SIZE = 32;
     
    uint internal constant BYTES_HEADER_SIZE = 32;
     
    uint internal constant FREE_MEM_PTR = 0x40;

     
     
     
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

     
     
     
     
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts,  32)
        }
        return equals(addr, addr2, len);
    }

     
     
     
    function allocate(uint numBytes) internal pure returns (uint addr) {
         
        assembly {
            addr := mload( 0x40)
            mstore( 0x40, add(addr, numBytes))
        }
        uint words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint i = 0; i < words; i++) {
            assembly {
                mstore(add(addr, mul(i,  32)), 0)
            }
        }
    }

     
     
     
    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

         
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

     
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts,  32)
        }
    }

     
     
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts,  32)
        }
    }

     
     
     
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts,  32)
        }
        copy(addr, btsptr, len);
    }

     
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

     
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

     
}

 

pragma solidity 0.4.25;


 
contract HelperUtils {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}

 

pragma solidity 0.4.25;





 
contract DigitalMediaToken is DigitalMediaManager, ERC721Safe, HelperUtils, SingleCreatorControl {

    event DigitalMediaReleaseCreateEvent(
        uint256 id, 
        address owner,
        uint32 printEdition,
        string tokenURI, 
        uint256 digitalMediaId);

     
    event DigitalMediaCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        uint32 totalSupply, 
        uint32 printIndex, 
        uint256 collectionId, 
        string metadataPath);

     
    event DigitalMediaCollectionCreateEvent(
        uint256 id, 
        address storeContractAddress,
        address creator, 
        string metadataPath);

     
    event DigitalMediaBurnEvent(
        uint256 id,
        address caller,
        address storeContractAddress);

     
    event DigitalMediaReleaseBurnEvent(
        uint256 tokenId, 
        address owner);

    event UpdateDigitalMediaPrintIndexEvent(
        uint256 digitalMediaId,
        uint32 printEdition);

     
    event ChangedCreator(
        address creator,
        address newCreator);

    struct DigitalMediaRelease {
         
        uint32 printEdition;

         
        uint256 digitalMediaId;
    }

     
    mapping (uint256 => DigitalMediaRelease) public tokenIdToDigitalMediaRelease;

     
     
    mapping (address => address) public approvedCreators;

     
    uint256 internal tokenIdCounter = 0;

    constructor (string _tokenName, string _tokenSymbol, uint256 _tokenIdStartingCounter) 
            public ERC721Token(_tokenName, _tokenSymbol) {
        tokenIdCounter = _tokenIdStartingCounter;
    }

     
    function _createDigitalMedia(
          address _creator, uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
          internal 
          returns (uint) {

        require(_validateCollection(_collectionId, _creator), "Creator for collection not approved.");

        uint256 newDigitalMediaId = currentDigitalMediaStore.createDigitalMedia(
            _creator,
            0, 
            _totalSupply,
            _collectionId,
            _metadataPath);

        emit DigitalMediaCreateEvent(
            newDigitalMediaId,
            address(currentDigitalMediaStore),
            _creator,
            _totalSupply,
            0,
            _collectionId,
            _metadataPath);

        return newDigitalMediaId;
    }

     
    function _burnToken(uint256 _tokenId, address _caller) internal {
        address owner = ownerOf(_tokenId);
        require(_caller == owner || 
                getApproved(_tokenId) == _caller || 
                isApprovedForAll(owner, _caller),
                "Failed token burn.  Caller is not approved.");
        _burn(owner, _tokenId);
        delete tokenIdToDigitalMediaRelease[_tokenId];
        emit DigitalMediaReleaseBurnEvent(_tokenId, owner);
    }

     
    function _burnDigitalMedia(uint256 _digitalMediaId, address _caller) internal {
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        require(_checkApprovedCreator(_digitalMedia.creator, _caller) || 
                isApprovedForAll(_digitalMedia.creator, _caller), 
                "Failed digital media burn.  Caller not approved.");

        uint32 increment = _digitalMedia.totalSupply - _digitalMedia.printIndex;
        _incrementDigitalMediaPrintIndex(_digitalMedia, increment);
        address _burnDigitalMediaStoreAddress = address(_getDigitalMediaStore(_digitalMedia.id));
        emit DigitalMediaBurnEvent(
          _digitalMediaId, _caller, _burnDigitalMediaStoreAddress);
    }

     
    function _createCollection(
          address _creator, string _metadataPath) 
          internal 
          returns (uint) {
        uint256 newCollectionId = currentDigitalMediaStore.createCollection(
            _creator,
            _metadataPath);

        emit DigitalMediaCollectionCreateEvent(
            newCollectionId,
            address(currentDigitalMediaStore),
            _creator,
            _metadataPath);

        return newCollectionId;
    }

     
    function _createDigitalMediaReleases(
        address _owner, uint256 _digitalMediaId, uint32 _count)
        internal {

        require(_count > 0, "Failed print edition.  Creation count must be > 0.");
        require(_count < 10000, "Cannot print more than 10K tokens at once");
        DigitalMedia memory _digitalMedia = _getDigitalMedia(_digitalMediaId);
        uint32 currentPrintIndex = _digitalMedia.printIndex;
        require(_checkApprovedCreator(_digitalMedia.creator, _owner), "Creator not approved.");
        require(isAllowedSingleCreator(_owner), "Creator must match single creator address.");
        require(_count + currentPrintIndex <= _digitalMedia.totalSupply, "Total supply exceeded.");
        
        string memory tokenURI = HelperUtils.strConcat("ipfs://ipfs/", _digitalMedia.metadataPath);

        for (uint32 i=0; i < _count; i++) {
            uint32 newPrintEdition = currentPrintIndex + 1 + i;
            DigitalMediaRelease memory _digitalMediaRelease = DigitalMediaRelease({
                printEdition: newPrintEdition,
                digitalMediaId: _digitalMediaId
            });

            uint256 newDigitalMediaReleaseId = _getNextTokenId();
            tokenIdToDigitalMediaRelease[newDigitalMediaReleaseId] = _digitalMediaRelease;
        
            emit DigitalMediaReleaseCreateEvent(
                newDigitalMediaReleaseId,
                _owner,
                newPrintEdition,
                tokenURI,
                _digitalMediaId
            );

             
            _mint(_owner, newDigitalMediaReleaseId);
            _setTokenURI(newDigitalMediaReleaseId, tokenURI);
            tokenIdCounter = tokenIdCounter.add(1);

        }
        _incrementDigitalMediaPrintIndex(_digitalMedia, _count);
        emit UpdateDigitalMediaPrintIndexEvent(_digitalMediaId, currentPrintIndex + _count);
    }

     
    function _checkApprovedCreator(address _creator, address _caller) 
            internal 
            view 
            returns (bool) {
        address approvedCreator = approvedCreators[_creator];
        if (approvedCreator != address(0)) {
            return approvedCreator == _caller;
        } else {
            return _creator == _caller;
        }
    }

     
    function _validateCollection(uint256 _collectionId, address _address) 
            private 
            view 
            returns (bool) {
        if (_collectionId == 0 ) {
            return true;
        }

        DigitalMediaCollection memory collection = _getCollection(_collectionId);
        return _checkApprovedCreator(collection.creator, _address);
    }

     
    function _getNextTokenId() private view returns (uint256) {
        return tokenIdCounter.add(1); 
    }

     
    function _changeCreator(address _caller, address _creator, address _newCreator) internal {
        address approvedCreator = approvedCreators[_creator];
        require(_caller != address(0) && _creator != address(0), "Creator must be valid non 0x0 address.");
        require(_caller == _creator || _caller == approvedCreator, "Unauthorized caller.");
        if (approvedCreator == address(0)) {
            approvedCreators[_caller] = _newCreator;
        } else {
            require(_caller == approvedCreator, "Unauthorized caller.");
            approvedCreators[_creator] = _newCreator;
        }
        emit ChangedCreator(_creator, _newCreator);
    }

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

}

 

pragma solidity 0.4.25;



contract OBOControl is Pausable {
	 
    mapping (address => bool) public approvedOBOs;

	 
    function addApprovedOBO(address _oboAddress) external onlyOwner {
        approvedOBOs[_oboAddress] = true;
    }

     
    function removeApprovedOBO(address _oboAddress) external onlyOwner {
        delete approvedOBOs[_oboAddress];
    }

     
    modifier isApprovedOBO() {
        require(approvedOBOs[msg.sender] == true);
        _;
    }
}

 

pragma solidity 0.4.25;



contract WithdrawFundsControl is Pausable {

	 
    mapping (address => uint256) public approvedWithdrawAddresses;

     
    uint256 constant internal withdrawApprovalWaitPeriod = 60 * 60 * 24;

    event WithdrawAddressAdded(address withdrawAddress);
    event WithdrawAddressRemoved(address widthdrawAddress);

	 
    function addApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        approvedWithdrawAddresses[_withdrawAddress] = now;
        emit WithdrawAddressAdded(_withdrawAddress);
    }

     
    function removeApprovedWithdrawAddress(address _withdrawAddress) external onlyOwner {
        delete approvedWithdrawAddresses[_withdrawAddress];
        emit WithdrawAddressRemoved(_withdrawAddress);
    }

     
    function isApprovedWithdrawAddress(address _withdrawAddress) internal view returns (bool)  {
        uint256 approvalTime = approvedWithdrawAddresses[_withdrawAddress];
        require (approvalTime > 0);
        return now - approvalTime > withdrawApprovalWaitPeriod;
    }
}

 

pragma solidity ^0.4.21;



contract ERC721Holder is ERC721Receiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}

 

pragma solidity 0.4.25;







 
contract DigitalMediaSaleBase is ERC721Holder, Pausable, OBOControl, WithdrawFundsControl {
    using SafeMath for uint256;

      
    mapping (address => bool) public approvedTokenContracts;

     
    function addApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {
        approvedTokenContracts[_tokenContractAddress] = true;
    }

     
    function removeApprovedTokenContract(address _tokenContractAddress) 
            public onlyOwner {            
        delete approvedTokenContracts[_tokenContractAddress];
    }

     
    function _isValidTokenContract(address _tokenContractAddress) 
            internal view returns (bool) {
        return approvedTokenContracts[_tokenContractAddress];
    }

     
    function _getTokenContract(address _tokenContractAddress) internal view returns (ERC721Safe) {
        require(_isValidTokenContract(_tokenContractAddress));
        return ERC721Safe(_tokenContractAddress);
    }

     
    function _owns(address _claimant, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.ownerOf(_tokenId) == _claimant);
    }

     
    function _ownerOf(uint256 _tokenId, address _tokenContractAddress) internal view returns (address) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return tokenContract.ownerOf(_tokenId);
    }

     
    function _approvedForEscrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal view returns (bool) {
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        return (tokenContract.isApprovedForAll(_seller, this) || 
                tokenContract.getApproved(_tokenId) == address(this));
    }

     
    function _escrow(address _seller, uint256 _tokenId, address _tokenContractAddress) internal {
         
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(_seller, this, _tokenId);
    }

     
    function _transfer(address _receiver, uint256 _tokenId, address _tokenContractAddress) internal {
         
        ERC721Safe tokenContract = _getTokenContract(_tokenContractAddress);
        tokenContract.safeTransferFrom(this, _receiver, _tokenId);
    }

     
    function isEscrowContract() public pure returns(bool) {
        return true;
    }

     
    function withdrawFunds(address _withdrawAddress) public onlyOwner {
        require(isApprovedWithdrawAddress(_withdrawAddress));
        _withdrawAddress.transfer(address(this).balance);
    }
}

 

pragma solidity 0.4.25;





 
contract DigitalMediaCore is DigitalMediaToken {
    using SafeMath for uint32;

     
    mapping (address => bool) public approvedTokenCreators;

     
    mapping (address => mapping (address => bool)) internal oboOperatorApprovals;

     
    mapping (address => bool) public disabledOboOperators;

     
    event OboApprovalForAll(
        address _owner, 
        address _operator, 
        bool _approved);

     
    event OboDisabledForAll(address _operator);

    constructor (
        string _tokenName, 
        string _tokenSymbol, 
        uint256 _tokenIdStartingCounter, 
        address _dmsAddress,
        address _crsAddress)
            public DigitalMediaToken(
                _tokenName, 
                _tokenSymbol,
                _tokenIdStartingCounter) {
        paused = true;
        setDigitalMediaStoreAddress(_dmsAddress);
        setCreatorRegistryStore(_crsAddress);
    }

     
    function getDigitalMedia(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 totalSupply,
            uint32 printIndex,
            uint256 collectionId,
            address creator,
            string metadataPath) {

        DigitalMedia memory digitalMedia = _getDigitalMedia(_id);
        require(digitalMedia.creator != address(0), "DigitalMedia not found.");
        id = _id;
        totalSupply = digitalMedia.totalSupply;
        printIndex = digitalMedia.printIndex;
        collectionId = digitalMedia.collectionId;
        creator = digitalMedia.creator;
        metadataPath = digitalMedia.metadataPath;
    }

     
    function getCollection(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            address creator,
            string metadataPath) {
        DigitalMediaCollection memory digitalMediaCollection = _getCollection(_id);
        require(digitalMediaCollection.creator != address(0), "Collection not found.");
        id = _id;
        creator = digitalMediaCollection.creator;
        metadataPath = digitalMediaCollection.metadataPath;
    }

     
    function getDigitalMediaRelease(uint256 _id) 
            external 
            view 
            returns (
            uint256 id,
            uint32 printEdition,
            uint256 digitalMediaId) {
        require(exists(_id));
        DigitalMediaRelease storage digitalMediaRelease = tokenIdToDigitalMediaRelease[_id];
        id = _id;
        printEdition = digitalMediaRelease.printEdition;
        digitalMediaId = digitalMediaRelease.digitalMediaId;
    }

     
    function createCollection(string _metadataPath) 
            external 
            whenNotPaused {
        _createCollection(msg.sender, _metadataPath);
    }

     
    function createDigitalMedia(uint32 _totalSupply, uint256 _collectionId, string _metadataPath) 
            external 
            whenNotPaused {
        _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
    }

     
    function createDigitalMediaAndReleases(
                uint32 _totalSupply,
                uint256 _collectionId,
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

     
    function createDigitalMediaAndReleasesInNewCollection(
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused {
        uint256 collectionId = _createCollection(msg.sender, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, _numReleases);
    }

     
    function createDigitalMediaReleases(uint256 _digitalMediaId, uint32 _numReleases) 
            external 
            whenNotPaused {
        _createDigitalMediaReleases(msg.sender, _digitalMediaId, _numReleases);
    }

     
    function burnToken(uint256 _tokenId) external {
        _burnToken(_tokenId, msg.sender);
    }

     
    function burn(uint256 tokenId) public {
        _burnToken(tokenId, msg.sender);
    }

     
    function burnDigitalMedia(uint256 _digitalMediaId) external whenNotPaused {
        _burnDigitalMedia(_digitalMediaId, msg.sender);
    }

     
    function resetApproval(uint256 _tokenId) external {
        clearApproval(msg.sender, _tokenId);
    }

     
    function changeCreator(address _creator, address _newCreator) external {
        _changeCreator(msg.sender, _creator, _newCreator);
    }

     
      
     
    
     
    function addApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        require(disabledOboOperators[_creatorAddress] != true, "Address disabled.");
        approvedTokenCreators[_creatorAddress] = true;
    }

     
    function removeApprovedTokenCreator(address _creatorAddress) external onlyOwner {
        delete approvedTokenCreators[_creatorAddress];
    }

     
    modifier isApprovedCreator() {
        require(
            (approvedTokenCreators[msg.sender] == true && 
             disabledOboOperators[msg.sender] != true), 
            "Unapproved OBO address.");
        _;
    }

     
    function setOboApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender, "Approval address is same as approver.");
        require(approvedTokenCreators[_to], "Unrecognized OBO address.");
        require(disabledOboOperators[_to] != true, "Approval address is disabled.");
        oboOperatorApprovals[msg.sender][_to] = _approved;
        emit OboApprovalForAll(msg.sender, _to, _approved);
    }

     
    function disableOboAddress(address _oboAddress) public onlyOwner {
        require(approvedTokenCreators[_oboAddress], "Unrecognized OBO address.");
        disabledOboOperators[_oboAddress] = true;
        delete approvedTokenCreators[_oboAddress];
        emit OboDisabledForAll(_oboAddress);
    }

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        if (disabledOboOperators[_operator] == true) {
            return false;
        } else if (isOperatorApprovedForCustodialAccount(_operator, _owner) == true) {
            return true;
        } else if (oboOperatorApprovals[_owner][_operator]) {
            return true;
        } else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

     
    function oboCreateDigitalMediaAndReleases(
                address _owner,
                uint32 _totalSupply, 
                uint256 _collectionId, 
                string _metadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, _collectionId, _metadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

     
    function oboCreateDigitalMediaAndReleasesInNewCollection(
                address _owner,
                uint32 _totalSupply, 
                string _digitalMediaMetadataPath,
                string _collectionMetadataPath,
                uint32 _numReleases)
            external 
            whenNotPaused
            isApprovedCreator {
        uint256 collectionId = _createCollection(_owner, _collectionMetadataPath);
        uint256 digitalMediaId = _createDigitalMedia(_owner, _totalSupply, collectionId, _digitalMediaMetadataPath);
        _createDigitalMediaReleases(_owner, digitalMediaId, _numReleases);
    }

     
    function oboCreateDigitalMediaReleases(
                address _owner,
                uint256 _digitalMediaId,
                uint32 _numReleases) 
            external 
            whenNotPaused
            isApprovedCreator {
        _createDigitalMediaReleases(_owner, _digitalMediaId, _numReleases);
    }

}