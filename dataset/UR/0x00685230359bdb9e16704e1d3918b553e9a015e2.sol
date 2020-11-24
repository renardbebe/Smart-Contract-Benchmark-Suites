 

pragma solidity ^0.4.24;

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

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


contract IAssetManager {
    function createAssetPack(bytes32 _packCover, string _name, uint[] _attributes, bytes32[] _ipfsHashes, uint _packPrice) public;
    function createAsset(uint _attributes, bytes32 _ipfsHash, uint _packId) public;
    function buyAssetPack(address _to, uint _assetPackId) public payable;
    function getNumberOfAssets() public view returns (uint);
    function getNumberOfAssetPacks() public view returns(uint);
    function checkHasPermissionForPack(address _address, uint _packId) public view returns (bool);
    function checkHashExists(bytes32 _ipfsHash) public view returns (bool);
    function givePermission(address _address, uint _packId) public;
    function pickUniquePacks(uint [] assetIds) public view returns (uint[]);
    function getAssetInfo(uint id) public view returns (uint, uint, bytes32);
    function getAssetPacksUserCreated(address _address) public view returns(uint[]);
    function getAssetIpfs(uint _id) public view returns (bytes32);
    function getAssetAttributes(uint _id) public view returns (uint);
    function getIpfsForAssets(uint [] _ids) public view returns (bytes32[]);
    function getAttributesForAssets(uint [] _ids) public view returns(uint[]);
    function withdraw() public;
    function getAssetPackData(uint _assetPackId) public view returns(string, uint[], uint[], bytes32[]);
    function getAssetPackName(uint _assetPackId) public view returns (string);
    function getAssetPackPrice(uint _assetPackId) public view returns (uint);
    function getCoversForPacks(uint [] _packIds) public view returns (bytes32[]);
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

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}




 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
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

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

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
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
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





contract Functions {

    bytes32[] public randomHashes;

    function fillWithHashes() public {
        require(randomHashes.length == 0);

        for (uint i = block.number - 100; i < block.number; i++) {
            randomHashes.push(blockhash(i));
        }
    }

     
     
     
     
    function calculateSeed(uint[] _randomHashIds, uint _timestamp) public view returns (uint) {
        require(_timestamp != 0);
        require(_randomHashIds.length == 10);

        bytes32 randomSeed = keccak256(
            abi.encodePacked(
            randomHashes[_randomHashIds[0]], randomHashes[_randomHashIds[1]],
            randomHashes[_randomHashIds[2]], randomHashes[_randomHashIds[3]],
            randomHashes[_randomHashIds[4]], randomHashes[_randomHashIds[5]],
            randomHashes[_randomHashIds[6]], randomHashes[_randomHashIds[7]],
            randomHashes[_randomHashIds[8]], randomHashes[_randomHashIds[9]],
            _timestamp
            )
        );

        return uint(randomSeed);
    }

    function getRandomHashesLength() public view returns(uint) {
        return randomHashes.length;
    }

     
     
     
    function decodeAssets(bytes32[] _potentialAssets) public pure returns (uint[] assets) {
        require(_potentialAssets.length > 0);

        uint[] memory assetsCopy = new uint[](_potentialAssets.length*10);
        uint numberOfAssets = 0;

        for (uint j = 0; j < _potentialAssets.length; j++) {
            uint input;
            bytes32 pot = _potentialAssets[j];

            assembly {
                input := pot
            }

            for (uint i = 10; i > 0; i--) {
                uint mask = (2 << ((i-1) * 24)) / 2;
                uint b = (input & (mask * 16777215)) / mask;

                if (b != 0) {
                    assetsCopy[numberOfAssets] = b;
                    numberOfAssets++;
                }
            }
        }

        assets = new uint[](numberOfAssets);
        for (i = 0; i < numberOfAssets; i++) {
            assets[i] = assetsCopy[i];
        }
    }

     
     
     
     
    function pickRandomAssets(uint _finalSeed, bytes32[] _potentialAssets) public pure returns(uint[] finalPicked) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

     
     
     
     
     
     
    function getImage(uint _finalSeed, bytes32[] _potentialAssets, uint _width, uint _height) public pure 
    returns(uint[] finalPicked, uint[] x, uint[] y, uint[] zoom, uint[] rotation, uint[] layers) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);
        x = new uint[](assetIds.length);
        y = new uint[](assetIds.length);
        zoom = new uint[](assetIds.length);
        rotation = new uint[](assetIds.length);
        layers = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                (x[index], y[index], zoom[index], rotation[index], layers[index]) = pickRandomAssetPosition(finalSeedCopy, _width, _height);
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

     
     
     
     
     
    function pickRandomAssetPosition(uint _randomSeed, uint _width, uint _height) public pure 
    returns (uint x, uint y, uint zoom, uint rotation, uint layer) {
        
        x = _randomSeed % _width;
        y = _randomSeed % _height;
        zoom = _randomSeed % 200 + 800;
        rotation = _randomSeed % 360;
         
         
        layer = _randomSeed % 1234567; 
    }

     
     
     
     
    function getFinalSeed(uint _randomSeed, uint _iterations) public pure returns (bytes32) {
        require(_randomSeed != 0);
        require(_iterations != 0);
        bytes32 finalSeed = bytes32(_randomSeed);

        finalSeed = keccak256(abi.encodePacked(_randomSeed, _iterations));
        for (uint i = 0; i < _iterations; i++) {
            finalSeed = keccak256(abi.encodePacked(finalSeed, i));
        }

        return finalSeed;
    }

    function toHex(uint _randomSeed) public pure returns (bytes32) {
        return bytes32(_randomSeed);
    }
}





contract UserManager {

    struct User {
        string username;
        bytes32 hashToProfilePicture;
        bool exists;
    }

    uint public numberOfUsers;

    mapping(string => bool) internal usernameExists;
    mapping(address => User) public addressToUser;

    mapping(bytes32 => bool) public profilePictureExists;
    mapping(string => address) internal usernameToAddress;

    event NewUser(address indexed user, string username, bytes32 profilePicture);

    function register(string _username, bytes32 _hashToProfilePicture) public {
        require(usernameExists[_username] == false || 
                keccak256(abi.encodePacked(getUsername(msg.sender))) == keccak256(abi.encodePacked(_username))
        );

        if (usernameExists[getUsername(msg.sender)]) {
             
            usernameExists[getUsername(msg.sender)] = false;
        } else {
            numberOfUsers++;
            emit NewUser(msg.sender, _username, _hashToProfilePicture);
        }

        addressToUser[msg.sender] = User({
            username: _username,
            hashToProfilePicture: _hashToProfilePicture,
            exists: true
        });

        usernameExists[_username] = true;
        profilePictureExists[_hashToProfilePicture] = true;
        usernameToAddress[_username] = msg.sender;
    }

    function changeProfilePicture(bytes32 _hashToProfilePicture) public {
        require(addressToUser[msg.sender].exists, "User doesn't exists");

        addressToUser[msg.sender].hashToProfilePicture = _hashToProfilePicture;
    }

    function getUserInfo(address _address) public view returns(string, bytes32) {
        User memory user = addressToUser[_address];
        return (user.username, user.hashToProfilePicture);
    }

    function getUsername(address _address) public view returns(string) {
        return addressToUser[_address].username;
    } 

    function getProfilePicture(address _address) public view returns(bytes32) {
        return addressToUser[_address].hashToProfilePicture;
    }

    function isUsernameExists(string _username) public view returns(bool) {
        return usernameExists[_username];
    }

}


contract DigitalPrintImage is ERC721Token("DigitalPrintImage", "DPM"), UserManager, Ownable {

    struct ImageMetadata {
        uint finalSeed;
        bytes32[] potentialAssets;
        uint timestamp;
        address creator;
        string ipfsHash;
        string extraData;
    }

    mapping(uint => bool) public seedExists;
    mapping(uint => ImageMetadata) public imageMetadata;
    mapping(uint => string) public idToIpfsHash;

    address public marketplaceContract;
    IAssetManager public assetManager;
    Functions public functions;

    modifier onlyMarketplaceContract() {
        require(msg.sender == address(marketplaceContract));
        _;
    }

    event ImageCreated(uint indexed imageId, address indexed owner);
     
     
     
     

     
     
     
     
     
     
     
     
     
    function createImage(
        uint[] _randomHashIds,
        uint _timestamp,
        uint _iterations,
        bytes32[] _potentialAssets,
        string _author,
        string _ipfsHash,
        string _extraData) public payable {
        require(_potentialAssets.length <= 5);
         
        require(msg.sender == usernameToAddress[_author] || !usernameExists[_author]);

         
        if (!usernameExists[_author]) {
            register(_author, bytes32(0));
        }

        uint[] memory pickedAssets;
        uint finalSeed;
       
        (pickedAssets, finalSeed) = getPickedAssetsAndFinalSeed(_potentialAssets, _randomHashIds, _timestamp, _iterations); 
        uint[] memory pickedAssetPacks = assetManager.pickUniquePacks(pickedAssets);
        uint finalPrice = 0;

        for (uint i = 0; i < pickedAssetPacks.length; i++) {
            if (assetManager.checkHasPermissionForPack(msg.sender, pickedAssetPacks[i]) == false) {
                finalPrice += assetManager.getAssetPackPrice(pickedAssetPacks[i]);

                assetManager.buyAssetPack.value(assetManager.getAssetPackPrice(pickedAssetPacks[i]))(msg.sender, pickedAssetPacks[i]);
            }
        }
        
        require(msg.value >= finalPrice);

        uint id = totalSupply();
        _mint(msg.sender, id);

        imageMetadata[id] = ImageMetadata({
            finalSeed: finalSeed,
            potentialAssets: _potentialAssets,
            timestamp: _timestamp,
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            extraData: _extraData
        });

        idToIpfsHash[id] = _ipfsHash;
        seedExists[finalSeed] = true;

        emit ImageCreated(id, msg.sender);
    }

     
     
     
     
    function transferFromMarketplace(address _from, address _to, uint256 _imageId) public onlyMarketplaceContract {
        require(isApprovedOrOwner(_from, _imageId));

        clearApproval(_from, _imageId);
        removeTokenFrom(_from, _imageId);
        addTokenTo(_to, _imageId);

        emit Transfer(_from, _to, _imageId);
    }

     
     
    function addMarketplaceContract(address _marketplaceContract) public onlyOwner {
        require(address(marketplaceContract) == 0x0);
        
        marketplaceContract = _marketplaceContract;
    }

     
     
    function addAssetManager(address _assetManager) public onlyOwner {
        require(address(assetManager) == 0x0);

        assetManager = IAssetManager(_assetManager);
    }

     
     
    function addFunctions(address _functions) public onlyOwner {
        require(address(functions) == 0x0);

        functions = Functions(_functions);
    }

     
     
     
     
    function calculatePrice(uint[] _pickedAssets, address _owner) public view returns (uint) {
        if (_pickedAssets.length == 0) {
            return 0;
        }

        uint[] memory pickedAssetPacks = assetManager.pickUniquePacks(_pickedAssets);
        uint finalPrice = 0;
        for (uint i = 0; i < pickedAssetPacks.length; i++) {
            if (assetManager.checkHasPermissionForPack(_owner, pickedAssetPacks[i]) == false) {
                finalPrice += assetManager.getAssetPackPrice(pickedAssetPacks[i]);
            }
        }

        return finalPrice;
    }

     
     
    function getGalleryData(uint _imageId) public view 
    returns(address, address, string, bytes32, string, string) {
        require(_imageId < totalSupply());

        return(
            imageMetadata[_imageId].creator,
            ownerOf(_imageId),
            addressToUser[ownerOf(_imageId)].username,
            addressToUser[ownerOf(_imageId)].hashToProfilePicture,
            imageMetadata[_imageId].ipfsHash,
            imageMetadata[_imageId].extraData
        );

    }

     
     
     
    function getImageMetadata(uint _imageId) public view
    returns(address, string, uint, string, uint, bytes32[]) {
        ImageMetadata memory metadata = imageMetadata[_imageId];

        return(
            metadata.creator,
            metadata.extraData,
            metadata.finalSeed,
            metadata.ipfsHash,
            metadata.timestamp,
            metadata.potentialAssets
        );
    }

     
     
    function getUserImages(address _user) public view returns(uint[]) {
        return ownedTokens[_user];
    }

     
     
     
     
     
    function getPickedAssetsAndFinalSeed(bytes32[] _potentialAssets, uint[] _randomHashIds, uint _timestamp, uint _iterations) internal view returns(uint[], uint) {
        uint finalSeed = uint(functions.getFinalSeed(functions.calculateSeed(_randomHashIds, _timestamp), _iterations));

        require(!seedExists[finalSeed]);

        return (functions.pickRandomAssets(finalSeed, _potentialAssets), finalSeed);
    }

}



contract Marketplace is Ownable {

    struct Ad {
        uint price;
        address exchanger;
        bool exists;
        bool active;
    }

    DigitalPrintImage public digitalPrintImageContract;

    uint public creatorPercentage = 3;  
    uint public marketplacePercentage = 2;  
    uint public numberOfAds;
    uint[] public allAds;
     
    mapping(uint => Ad) public sellAds;
    mapping(address => uint) public balances;

    constructor(address _digitalPrintImageContract) public {
        digitalPrintImageContract = DigitalPrintImage(_digitalPrintImageContract);
        numberOfAds = 0;
    }

    event SellingImage(uint indexed imageId, uint price);
    event ImageBought(uint indexed imageId, address indexed newOwner, uint price);

     
     
     
     
    function sell(uint _imageId, uint _price) public {
        require(digitalPrintImageContract.ownerOf(_imageId) == msg.sender);

        bool exists = sellAds[_imageId].exists;

        sellAds[_imageId] = Ad({
            price: _price,
            exchanger: msg.sender,
            exists: true,
            active: true
        });

        if (!exists) {
            numberOfAds++;
            allAds.push(_imageId);
        }

        emit SellingImage(_imageId, _price);
    }
    
    function getActiveAds() public view returns (uint[], uint[]) {
        uint count;
        for (uint i = 0; i < numberOfAds; i++) {
             
            if (isImageOnSale(allAds[i])) {
                count++;
            }
        }

        uint[] memory imageIds = new uint[](count);
        uint[] memory prices = new uint[](count);
        count = 0;
        for (i = 0; i < numberOfAds; i++) {
            Ad memory ad = sellAds[allAds[i]];
             
            if (isImageOnSale(allAds[i])) {
                imageIds[count] = allAds[i];
                prices[count] = ad.price;
                count++;
            }
        }

        return (imageIds, prices);
    }

    function isImageOnSale(uint _imageId) public view returns(bool) {
        Ad memory ad = sellAds[_imageId];

        return ad.exists && ad.active && (ad.exchanger == digitalPrintImageContract.ownerOf(_imageId));
    }

     
     
    function buy(uint _imageId) public payable {
        require(isImageOnSale(_imageId));
        require(msg.value >= sellAds[_imageId].price);

        removeOrder(_imageId);

        address _creator;
        address _imageOwner = digitalPrintImageContract.ownerOf(_imageId);
        (, , _creator, ,) = digitalPrintImageContract.imageMetadata(_imageId);

        balances[_creator] += msg.value * 2 / 100;
        balances[owner] += msg.value * 3 / 100;
        balances[_imageOwner] += msg.value * 95 / 100;

        digitalPrintImageContract.transferFromMarketplace(sellAds[_imageId].exchanger, msg.sender, _imageId);

        emit ImageBought(_imageId, msg.sender, msg.value);
    }

     
     
     
    function cancel(uint _imageId) public {
        require(sellAds[_imageId].exists == true);
        require(sellAds[_imageId].exchanger == msg.sender);
        require(sellAds[_imageId].active == true);

        removeOrder(_imageId);
    }

    function withdraw() public {
        
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

     
     
    function removeOrder(uint _imageId) private {
        sellAds[_imageId].active = false;
    }
}