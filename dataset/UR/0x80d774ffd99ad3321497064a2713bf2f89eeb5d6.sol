 

pragma solidity ^0.4.24;


 
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



contract AssetManager is Ownable {

    struct Asset {
        uint id;
        uint packId;
         
         
         
         
        uint attributes;
        bytes32 ipfsHash;  
    }

    struct AssetPack {
        bytes32 packCover;
        uint[] assetIds;
        address creator;
        uint price;
        string ipfsHash;  
    }

    uint public numberOfAssets;
    uint public numberOfAssetPacks;

    Asset[] public assets;
    AssetPack[] public assetPacks;

    UserManager public userManager;

    mapping(address => uint) public artistBalance;
    mapping(bytes32 => bool) public hashExists;

    mapping(address => uint[]) public createdAssetPacks;
    mapping(address => uint[]) public boughtAssetPacks;
    mapping(address => mapping(uint => bool)) public hasPermission;
    mapping(uint => address) public approvedTakeover;

    event AssetPackCreated(uint indexed id, address indexed owner);
    event AssetPackBought(uint indexed id, address indexed buyer);

    function addUserManager(address _userManager) public onlyOwner {
        require(userManager == address(0));

        userManager = UserManager(_userManager);
    }

     
     
     
     
     
     
    function createAssetPack(
        bytes32 _packCover, 
        uint[] _attributes, 
        bytes32[] _ipfsHashes, 
        uint _packPrice,
        string _ipfsHash) public {
        
        require(_ipfsHashes.length > 0);
        require(_ipfsHashes.length < 50);
        require(_attributes.length == _ipfsHashes.length);

        uint[] memory ids = new uint[](_ipfsHashes.length);

        for (uint i = 0; i < _ipfsHashes.length; i++) {
            ids[i] = createAsset(_attributes[i], _ipfsHashes[i], numberOfAssetPacks);
        }

        assetPacks.push(AssetPack({
            packCover: _packCover,
            assetIds: ids,
            creator: msg.sender,
            price: _packPrice,
            ipfsHash: _ipfsHash
        }));

        createdAssetPacks[msg.sender].push(numberOfAssetPacks);
        numberOfAssetPacks++;

        emit AssetPackCreated(numberOfAssetPacks-1, msg.sender);
    }

     
     
     
    function createAsset(uint _attributes, bytes32 _ipfsHash, uint _packId) internal returns(uint) {
        uint id = numberOfAssets;

        require(isAttributesValid(_attributes), "Attributes are not valid.");

        assets.push(Asset({
            id : id,
            packId: _packId,
            attributes: _attributes,
            ipfsHash : _ipfsHash
        }));

        numberOfAssets++;

        return id;
    }

     
     
     
    function buyAssetPack(address _to, uint _assetPackId) public payable {
        require(!checkHasPermissionForPack(_to, _assetPackId));

        AssetPack memory assetPack = assetPacks[_assetPackId];
        require(msg.value >= assetPack.price);
         
        artistBalance[assetPack.creator] += msg.value * 95 / 100;
        artistBalance[owner] += msg.value * 5 / 100;
        boughtAssetPacks[_to].push(_assetPackId);
        hasPermission[_to][_assetPackId] = true;

        emit AssetPackBought(_assetPackId, _to);
    }

     
     
     
    function changeAssetPackPrice(uint _assetPackId, uint _newPrice) public {
        require(assetPacks[_assetPackId].creator == msg.sender);

        assetPacks[_assetPackId].price = _newPrice;
    }

     
     
     
    function approveTakeover(uint _assetPackId, address _newCreator) public {
        require(assetPacks[_assetPackId].creator == msg.sender);

        approvedTakeover[_assetPackId] = _newCreator;
    }

     
     
    function claimAssetPack(uint _assetPackId) public {
        require(approvedTakeover[_assetPackId] == msg.sender);
        
        approvedTakeover[_assetPackId] = address(0);
        assetPacks[_assetPackId].creator = msg.sender;
    }

     
    function withdraw() public {
        uint amount = artistBalance[msg.sender];
        artistBalance[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

     
     
    function getNumberOfAssets() public view returns (uint) {
        return numberOfAssets;
    }

     
     
    function getNumberOfAssetPacks() public view returns(uint) {
        return numberOfAssetPacks;
    }

     
     
     
    function checkHasPermissionForPack(address _address, uint _packId) public view returns (bool) {

        return (assetPacks[_packId].creator == _address) || hasPermission[_address][_packId];
    }

     
     
    function checkHashExists(bytes32 _ipfsHash) public view returns (bool) {
        return hashExists[_ipfsHash];
    }

     
    function pickUniquePacks(uint[] assetIds) public view returns (uint[]) {
        require(assetIds.length > 0);

        uint[] memory packs = new uint[](assetIds.length);
        uint packsCount = 0;
        
        for (uint i = 0; i < assetIds.length; i++) {
            Asset memory asset = assets[assetIds[i]];
            bool exists = false;

            for (uint j = 0; j < packsCount; j++) {
                if (asset.packId == packs[j]) {
                    exists = true;
                }
            }

            if (!exists) {
                packs[packsCount] = asset.packId;
                packsCount++;
            }
        }

        uint[] memory finalPacks = new uint[](packsCount);
        for (i = 0; i < packsCount; i++) {
            finalPacks[i] = packs[i];
        }

        return finalPacks;
    }

     
     
     
    function getAssetInfo(uint id) public view returns (uint, uint, uint, bytes32) {
        require(id >= 0);
        require(id < numberOfAssets);
        Asset memory asset = assets[id];

        return (asset.id, asset.packId, asset.attributes, asset.ipfsHash);
    }

     
     
    function getAssetPacksUserCreated(address _address) public view returns(uint[]) {
        return createdAssetPacks[_address];
    }

     
     
     
    function getAssetIpfs(uint _id) public view returns (bytes32) {
        require(_id < numberOfAssets);
        
        return assets[_id].ipfsHash;
    }

     
     
     
    function getAssetAttributes(uint _id) public view returns (uint) {
        require(_id < numberOfAssets);
        
        return assets[_id].attributes;
    }

     
     
     
     
    function getIpfsForAssets(uint[] _ids) public view returns (bytes32[]) {
        bytes32[] memory hashes = new bytes32[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            Asset memory asset = assets[_ids[i]];
            hashes[i] = asset.ipfsHash;
        }

        return hashes;
    }

     
    function getAttributesForAssets(uint[] _ids) public view returns(uint[]) {
        uint[] memory attributes = new uint[](_ids.length);
        
        for (uint i = 0; i < _ids.length; i++) {
            Asset memory asset = assets[_ids[i]];
            attributes[i] = asset.attributes;
        }
        return attributes;
    }

     
     
     
    function getAssetPackData(uint _assetPackId) public view 
    returns(bytes32, address, uint, uint[], uint[], bytes32[], string, string, bytes32) {
        require(_assetPackId < numberOfAssetPacks);

        AssetPack memory assetPack = assetPacks[_assetPackId];
        bytes32[] memory hashes = new bytes32[](assetPack.assetIds.length);

        for (uint i = 0; i < assetPack.assetIds.length; i++) {
            hashes[i] = getAssetIpfs(assetPack.assetIds[i]);
        }

        uint[] memory attributes = getAttributesForAssets(assetPack.assetIds);

        return(
            assetPack.packCover, 
            assetPack.creator, 
            assetPack.price, 
            assetPack.assetIds, 
            attributes, 
            hashes,
            assetPack.ipfsHash,
            userManager.getUsername(assetPack.creator),
            userManager.getProfilePicture(assetPack.creator)
        );
    }

    function getAssetPackPrice(uint _assetPackId) public view returns (uint) {
        require(_assetPackId < numberOfAssetPacks);

        return assetPacks[_assetPackId].price;
    }

    function getBoughtAssetPacks(address _address) public view returns (uint[]) {
        return boughtAssetPacks[_address];
    }

     
     
     
    function getCoversForPacks(uint[] _packIds) public view returns (bytes32[]) {
        require(_packIds.length > 0);
        bytes32[] memory covers = new bytes32[](_packIds.length);
        for (uint i = 0; i < _packIds.length; i++) {
            AssetPack memory assetPack = assetPacks[_packIds[i]];
            covers[i] = assetPack.packCover;
        }
        return covers;
    }

    function isAttributesValid(uint attributes) private pure returns(bool) {
        if (attributes < 100 || attributes > 999) {
            return false;
        }

        uint num = attributes;

        while (num > 0) {
            if (num % 10 != 1 && num % 10 != 2) {
                return false;
            } 
            num = num / 10;
        }

        return true;
    }
}