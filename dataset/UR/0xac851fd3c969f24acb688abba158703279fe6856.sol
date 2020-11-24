 

pragma solidity ^0.4.24;

 

 
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

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

contract ITVToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function safeTransfer(address _to, uint256 _value, bytes _data) public;
}

contract IArtefact {
    function artefacts(uint id) public returns (uint, uint);
    function ownerOf(uint256 _tokenId) public view returns (address);
}

contract ITVKey {
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function keys(uint id) public returns (uint, uint);
    function mint(address to, uint chestId) public returns (uint);
    function burn(uint id) public;
}

contract TVLottery is Ownable, ERC721Receiver {
    address public manager;
    address public TVTokenAddress;
    address public TVKeyAddress;

    struct Collection {
        uint id;
        uint[] typeIds;
        address[] tokens;
        uint chestId;
        uint lotteryId;
        bool created;
    }

    struct Lottery {
        uint id;
        address bank;
        uint[] collections;
        uint bankPercentage;
        bool isActive;
        bool created;
    }

    struct Chest {
        uint id;
        uint lotteryId;
        uint percentage;
        uint count;
        uint keysCount;
        uint openedCount;
        bool created;
    }

    mapping(uint => Lottery) public lotteries;
    mapping(uint => Chest) public chests;
    mapping(uint => Collection) public collections;
    mapping(uint => mapping(address => bool)) public usedElements;

    event KeyReceived(uint keyId, uint lotteryId, uint collectionId, uint chestId, address receiver);
    event ChestOpened(uint keyId, uint lotteryId, uint chestId, uint reward, address receiver);
    event ArtefactUsed(uint id, address token, address sender);

    modifier onlyOwnerOrManager() {
        require(msg.sender == owner || manager == msg.sender);
        _;
    }

    constructor(
        address _TVTokenAddress,
        address _TVKeyAddress,
        address _manager
    ) public {
        manager = _manager;
        TVTokenAddress = _TVTokenAddress;
        TVKeyAddress = _TVKeyAddress;
    }

    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes
    ) public returns (bytes4) {
        require(msg.sender == TVKeyAddress);
        (, uint chestId) = ITVKey(TVKeyAddress).keys(_tokenId);
        Chest memory chest = chests[chestId];
        Lottery memory lottery = lotteries[chest.lotteryId];

        ITVKey(TVKeyAddress).transferFrom(this, lottery.bank, _tokenId);
        lotteries[chest.lotteryId].bankPercentage -= chest.percentage;
        chests[chestId].openedCount = chest.openedCount + 1;
        uint reward = getChestReward(chestId);
        ITVToken(TVTokenAddress).transferFrom(lottery.bank, _from, reward);
        emit ChestOpened(_tokenId, lottery.id, chest.id, reward, _from);
        return ERC721_RECEIVED;
    }

    function getChestReward(uint chestId) public view returns (uint) {
        Chest memory chest = chests[chestId];
        Lottery memory lottery = lotteries[chest.lotteryId];
        uint bankBalance = ITVToken(TVTokenAddress).balanceOf(lottery.bank);
        uint onePercentage = bankBalance / lottery.bankPercentage;
        return chest.percentage * onePercentage;
    }

    function getKey(uint lotteryId, uint collectionId, uint[] elementIds) public returns (uint) {
        Lottery memory lottery = lotteries[lotteryId];
        Collection memory collection = collections[collectionId];
        Chest memory chest = chests[collection.chestId];

        require(collection.lotteryId == lotteryId);
        require(lottery.created && lottery.isActive && collection.created);
        require(chest.keysCount > 0);

        checkCollection(collection, elementIds);

        chests[collection.chestId].keysCount = chest.keysCount - 1;
        uint keyId = ITVKey(TVKeyAddress).mint(msg.sender, chest.id);
        emit KeyReceived(keyId, lotteryId, collectionId, chest.id, msg.sender);

        return keyId;
    }

    function checkCollection(Collection collection, uint[] elementsIds) internal {
        require(elementsIds.length == collection.typeIds.length);
        for (uint i = 0; i < elementsIds.length; i++) {
            (uint id, uint typeId) = IArtefact(collection.tokens[i]).artefacts(elementsIds[i]);
            require(typeId == collection.typeIds[i]);
            require(!usedElements[id][collection.tokens[i]]);
            require(IArtefact(collection.tokens[i]).ownerOf(id) == msg.sender);
            usedElements[id][collection.tokens[i]] = true;
            emit ArtefactUsed(id, collection.tokens[i], msg.sender);
        }
    }

    function setCollection(
        uint id,
        uint[] typeIds,
        address[] tokens,
        uint chestId,
        uint lotteryId,
        bool created
    ) public onlyOwnerOrManager {
        require(typeIds.length == tokens.length);
        collections[id] = Collection(id, typeIds, tokens, chestId, lotteryId, created);
    }

    function getCollectionElementsCount(uint id) public view returns(uint) {
        return collections[id].typeIds.length;
    }

    function getCollectionElementByIndex(uint id, uint index) public view returns(uint, address) {
        return (collections[id].typeIds[index], collections[id].tokens[index]);
    }

    function setChest(
        uint lotteryId,
        uint id,
        uint percentage,
        uint count,
        uint keysCount,
        uint openedCount,
        bool created
    ) public onlyOwnerOrManager {
        chests[id] = Chest(id, lotteryId, percentage, count, keysCount, openedCount, created);
    }

    function setLottery(
        uint id,
        address bank,
        uint[] _collections,
        uint bankPercentage,
        bool isActive,
        bool created
    ) public onlyOwnerOrManager {
        lotteries[id] = Lottery(id, bank, _collections, bankPercentage, isActive, created);
    }

    function getLotteryCollectionCount(uint id) public view returns(uint) {
        return lotteries[id].collections.length;
    }

    function getLotteryCollectionByIndex(uint id, uint index) public view returns(uint) {
        return lotteries[id].collections[index];
    }

    function changeLotteryBank(uint lotteryId, address bank, uint bankPercentage) public onlyOwnerOrManager {
        lotteries[lotteryId].bank = bank;
        lotteries[lotteryId].bankPercentage = bankPercentage;
    }

    function updateCollections(uint lotteryId, uint[] _collections) public onlyOwnerOrManager {
        lotteries[lotteryId].collections = _collections;
    }

    function setLotteryActive(uint id, bool isActive) public onlyOwnerOrManager {
        lotteries[id].isActive = isActive;
    }

    function changeTVTokenAddress(address newAddress) public onlyOwnerOrManager {
        TVTokenAddress = newAddress;
    }

    function changeTVKeyAddress(address newAddress) public onlyOwnerOrManager {
        TVKeyAddress = newAddress;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }
}