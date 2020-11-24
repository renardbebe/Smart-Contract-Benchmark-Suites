 

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;






 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
     

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
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

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
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
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

pragma solidity ^0.5.0;


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.5.0;




 
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
     

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
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

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
         
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

     
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

     
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

     
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

         
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;  
            _ownedTokensIndex[lastTokenId] = tokenIndex;  
        }

         
        _ownedTokens[from].length--;

         
         
    }

     
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

         
         
         
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;  
        _allTokensIndex[lastTokenId] = tokenIndex;  

         
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
     

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
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

 

pragma solidity ^0.5.0;




 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

 

pragma solidity 0.5.0;


contract GameData {
    struct Animal {
        uint256 wildAnimalId;
        uint256 xp;
        uint16 effectiveness;
        uint16[3] accessories;      
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity 0.5.0;



contract Restricted is Ownable {
    mapping(address => bool) private addressIsAdmin;
    bool private isActive = true;

    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] || msg.sender == owner(), "Sender is not admin");
        _;
    }

    modifier contractIsActive() {
        require(isActive, "Contract is not active");
        _;
    }

    function addAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = false;
    }

    function pauseContract() public onlyOwner {
        isActive = false;
    }

    function activateContract() public onlyOwner {
        isActive = true;
    }
}

 

pragma solidity 0.5.0;


contract IDnaRepository {
    function getDna(uint256 _dnaId)
        public
        view
        returns(
            uint animalId,
            address owner,
            uint16 effectiveness,
            uint256 id
        );
}

 

pragma solidity 0.5.0;



contract IServal is IDnaRepository {
    function getAnimal(uint256 _animalId)
        public
        view
        returns(
            uint256 countryId,
            bytes32 name,
            uint8 rarity,
            uint256 currentValue,
            uint256 targetValue,
            address owner,
            uint256 id
        );
}

 

pragma solidity 0.5.0;


contract IMarketplace {
    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external;
}

 

pragma solidity 0.5.0;









contract CryptoServalV2 is ERC721Full("CryptoServalGame", "CSG"), GameData, Restricted {
    address private servalChainAddress;
    IServal private cryptoServalContract;
    IDnaRepository private dnaRepositoryContract;
    IMarketplace private marketplaceContract;

    mapping(uint256 => bool) private usedNonces;
    mapping(address => uint256) private addressToGems;

    mapping(bytes32 => bool) private withdrawnHashedContractAnimals;
    mapping(bytes32 => bool) private withdrawnHashedRepositoryAnimals;

    Animal[] internal animals;

    uint256 private syncCost = 0.003 ether;
    uint256 private spawnCost = 0.01 ether;

    uint256 private spawnWindow = 1 hours;
    uint256[3] private rarityToSpawnGemCost = [30, 60, 90];

    using SafeMath for uint256;

    event GemsAddedEvent(
        address to,
        uint256 gemAmount
    );

    event XpAddedEvent(
        uint256 animalId,
        uint256 xpAmount
    );

    event AccessoryAddedEvent(
        uint256 animalId,
        uint8 accessorySlot,
        uint16 accessoryId
    );

    function setServalChainAddress(address newServalChainAddress) external onlyAdmin() {
        servalChainAddress = newServalChainAddress;
    }

    function setCryptoServalContract(address cryptoServalContractAddress) external onlyAdmin() {
        cryptoServalContract = IServal(cryptoServalContractAddress);
    }

    function setDnaRepositoryContract(address dnaRepositoryContractAddress) external onlyAdmin() {
        dnaRepositoryContract = IDnaRepository(dnaRepositoryContractAddress);
    }

    function setMarketplaceContract(address marketplaceContractAddress) external onlyAdmin() {
        marketplaceContract = IMarketplace(marketplaceContractAddress);
    }

    function setSyncCost(uint256 _syncCost) external onlyAdmin() {
        syncCost = _syncCost;
    }

    function setSpawnCost(uint256 _spawnCost) external onlyAdmin() {
        spawnCost = _spawnCost;
    }

    function setRarityToSpawnGemCost(uint8 index, uint256 targetValue) external onlyAdmin {
        rarityToSpawnGemCost[index] = targetValue;
    }

    function sequenceContractDna(uint256 wildAnimalId, uint256[] calldata dnaIds) external {
        require(!isWithdrawnFromContract(msg.sender, wildAnimalId), "Animal was already minted from contract");  
        withdrawnHashedContractAnimals[keccak256(abi.encodePacked(msg.sender, wildAnimalId))] = true;
        sequenceDna(wildAnimalId, dnaIds, cryptoServalContract);  
    }

    function sequenceRepositoryDna(uint256 wildAnimalId, uint256[] calldata dnaIds) external {
        require(!isWithdrawnFromRepository(msg.sender, wildAnimalId), "Animal was already minted from repository");  
        withdrawnHashedRepositoryAnimals[keccak256(abi.encodePacked(msg.sender, wildAnimalId))] = true;
        sequenceDna(wildAnimalId, dnaIds, dnaRepositoryContract);  
    }

    function spawnOffspring(
        uint256 wildAnimalId,
        uint16 effectiveness,
        uint256 timestamp,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
        )
        external
        payable
        usesNonce(nonce)
        spawnPriced()
    {        
        require(now < timestamp.add(spawnWindow), "Animal spawn expired");
        require(effectiveness <= 100, "Invalid effectiveness");
        require(isServalChainSigner(
                keccak256(abi.encodePacked(wildAnimalId, effectiveness, timestamp, nonce, msg.sender, this)),
                v,
                r,
                s
            ), "Invalid signature");

        uint8 rarity;
        (, , rarity, , , ,) = cryptoServalContract.getAnimal(wildAnimalId);
         
        addressToGems[msg.sender] = addressToGems[msg.sender].sub(rarityToSpawnGemCost[rarity]);
        mintAnimal(wildAnimalId, effectiveness, msg.sender);
    }
        
    function requestGems(
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
        )
        external
        payable        
        usesNonce(nonce)
        syncPriced()
    {
        require(isServalChainSigner(
            keccak256(abi.encodePacked(amount, nonce, msg.sender, this)), v, r, s),
            "Invalid signature"
            );        
        addGems(msg.sender, amount);        
    }

    function addXp(
        uint256 animalId,
        uint256 xpToAdd,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
        )
        external
        payable
        syncPriced()
        usesNonce(nonce)
    {
        require(isServalChainSigner(
            keccak256(abi.encodePacked(animalId, xpToAdd, nonce, msg.sender, this)), v, r, s),
            "Invalid signature"
            );
        animals[animalId].xp = animals[animalId].xp.add(xpToAdd);

        emit XpAddedEvent(animalId, xpToAdd);
    }
      
    function addAccessories(
        uint256 animalId,
        uint8 accessorySlot,
        uint16 accessoryId,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
        )
        external
        payable
        syncPriced()      
        usesNonce(nonce)
    {
        require(isServalChainSigner(
                keccak256(abi.encodePacked(animalId, accessorySlot, accessoryId, nonce, msg.sender, this)),
                v,
                r,
                s
            ),
            "Invalid signature"
            );        
        require(msg.sender == ownerOf(animalId));
        require(animals[animalId].accessories[accessorySlot] == 0);     
        
        animals[animalId].accessories[accessorySlot] = accessoryId;
        emit AccessoryAddedEvent(animalId, accessorySlot, accessoryId);
    }

    function fuseAnimal(uint256 animalId) external payable syncPriced() {        
        Animal memory animal = animals[animalId];

        address wildAnimalOwner;
        uint8 rarity;
        (, , rarity, , , wildAnimalOwner,) = cryptoServalContract.getAnimal(animal.wildAnimalId);
        
        uint256 gemsToAdd = uint256(animal.effectiveness).div(4);
        uint256 rarityMultiplier = uint256(rarity).add(1);

        if (gemsToAdd > 2) {            
            gemsToAdd = gemsToAdd.mul(rarityMultiplier);
        }

        _burn(msg.sender, animalId);
        delete animals[animalId];

        addGems(msg.sender, gemsToAdd);
        addGems(wildAnimalOwner, rarityMultiplier.mul(5));
    }

    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external
    {
         
        approve(address(marketplaceContract), _tokenId);
        marketplaceContract.createAuction(_tokenId, startPrice, endPrice, duration);
    } 

    function getAnimal(uint256 animalId)
    external
    view
    returns(
        address owner,
        uint256 wildAnimalId,
        uint256 xp,
        uint16 effectiveness,
        uint16[3] memory accessories
    )
    {
        Animal memory animal = animals[animalId];
        return (
            ownerOf(animalId),
            animal.wildAnimalId,
            animal.xp,
            animal.effectiveness,
            animal.accessories
        );
    }

    function getPlayerAnimals(address playerAddress)
        external
        view
        returns(uint256[] memory)
    {
        return _tokensOfOwner(playerAddress);
    }

    function getPlayerGems(address addr) external view returns(uint256) {
        return addressToGems[addr];
    }

    function getSyncCost() external view returns(uint256) {
        return syncCost;
    }

    function getSpawnCost() external view returns(uint256) {
        return spawnCost;
    }

    function getRarityToSpawnGemCost(uint8 index) public view returns(uint256) {
        return rarityToSpawnGemCost[index];
    }

    function isWithdrawnFromContract(address owner, uint256 wildAnimalId) public view returns(bool) {
        return withdrawnHashedContractAnimals[keccak256(abi.encodePacked(owner, wildAnimalId))];
    }

    function isWithdrawnFromRepository(address owner, uint256 wildAnimalId) public view returns(bool) {
        return withdrawnHashedRepositoryAnimals[keccak256(abi.encodePacked(owner, wildAnimalId))]; 
    }

    function isServalChainSigner(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return servalChainAddress == ecrecover(msgHash, v, r, s);
    }

    function withdrawContract() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function sequenceDna(uint256 animalToSpawn, uint256[] memory dnaIds, IDnaRepository dnaContract) private {
        uint256 highestEffectiveness = 0;
        uint256 sumOfEffectiveness = 0;

        require(!hasDuplicateMember(dnaIds), "DNA array contains the same cards");
        
        for (uint256 i = 0; i < dnaIds.length; i++) {
            uint animalId;
            address owner;
            uint16 effectiveness;
            uint256 id;

            (animalId, owner, effectiveness, id) = dnaContract.getDna(dnaIds[i]);

            require(animalId == animalToSpawn, "Provided DNA has incorrect wild animal id");
            require(msg.sender == owner, "Sender is not owner of DNA");

            if (effectiveness > highestEffectiveness) { 
                highestEffectiveness = effectiveness;
            }

            sumOfEffectiveness = sumOfEffectiveness.add(effectiveness);
        }
        
        uint256 effectivenessBonus = (sumOfEffectiveness.sub(highestEffectiveness)).div(10); 
        uint256 finalEffectiveness = highestEffectiveness.add(effectivenessBonus);
        if (finalEffectiveness > 100) {
            addGems(msg.sender, finalEffectiveness.sub(100));
            
            finalEffectiveness = 100;            
        }
        
        mintAnimal(animalToSpawn, uint16(finalEffectiveness), msg.sender);
    }

    function hasDuplicateMember(uint256[] memory uintArray) private pure returns(bool) {
        uint256 uintArrayLength = uintArray.length;
        for (uint256 i = 0; i < uintArrayLength - 1; i++) {
            for (uint256 u = i + 1; u < uintArrayLength; u++) {
                if (uintArray[i] == uintArray[u]) {
                    return true;
                }
            }
        }

        return false;
    }

    function mintAnimal(uint256 wildAnimalId, uint16 effectiveness, address mintTo) private
    {
        Animal memory animal = Animal(
            wildAnimalId,
            0,
            effectiveness,
            [uint16(0), uint16(0), uint16(0)]
        ); 
        uint256 id = animals.length;  
        animals.push(animal);
        _mint(mintTo, id);
    }

    function addGems(address receiver, uint256 gemsCount) private {
        addressToGems[receiver] = addressToGems[receiver].add(gemsCount);

        emit GemsAddedEvent(receiver, gemsCount);
    }

    modifier usesNonce(uint256 nonce) {
        require(!usedNonces[nonce], "Nonce already used");
        usedNonces[nonce] = true;
        _;
    }

    modifier syncPriced() {
        require(msg.value == syncCost, "Sync price not paid");
        _;
    }

    modifier spawnPriced() {
        require(msg.value == spawnCost, "Mint price not paid");
        _;
    }
}