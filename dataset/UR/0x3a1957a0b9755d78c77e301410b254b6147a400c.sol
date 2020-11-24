 

pragma solidity 0.4.24;

 

 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 
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

 

contract IMarketplace {
    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external;
}

 

contract GameData {
    struct Country {       
        bytes2 isoCode;
        uint8 animalsCount;
        uint256[3] animalIds;
    }

    struct Animal {
        bool isSold;
        uint256 currentValue;
        uint8 rarity;  

        bytes32 name;         
        uint256 countryId;  

    }

    struct Dna {
        uint256 animalId; 
        uint8 effectiveness;  
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

 

contract Restricted is Ownable {
    mapping(address => bool) private addressIsAdmin;
    bool private isActive = true;

    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] || msg.sender == owner);
        _;
    }

    modifier contractIsActive() {
        require(isActive);
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

 

contract CryptoServal is ERC721Token("CryptoServal", "CS"), GameData, Restricted {

    using AddressUtils for address;

    uint8 internal developersFee = 5;
    uint256[3] internal rarityTargetValue = [0.5 ether, 1 ether, 2 ether];

    Country[] internal countries;
    Animal[] internal animals;
    Dna[] internal dnas;

    using SafeMath for uint256;

    event AnimalBoughtEvent(
        uint256 animalId,
        address previousOwner,
        address newOwner,
        uint256 pricePaid,
        bool isSold
    );

    mapping (address => uint256) private addressToDnaCount;

    mapping (uint => address) private dnaIdToOwnerAddress;

    uint256 private startingAnimalPrice = 0.001 ether;

    IMarketplace private marketplaceContract;

    bool private shouldGenerateDna = true;

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < animals.length);
        _;
    }

    modifier soldOnly(uint256 _tokenId) {
        require(animals[_tokenId].isSold);
        _;
    }

    modifier isNotFromContract() {
        require(!msg.sender.isContract());
        _;
    }

    function () public payable {
    }

    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external
        isNotFromContract
    {
         
        approve(address(marketplaceContract), _tokenId);
        marketplaceContract.createAuction(_tokenId, startPrice, endPrice, duration);
    }

    function setMarketplaceContract(address marketplaceAddress) external onlyOwner {
        marketplaceContract = IMarketplace(marketplaceAddress);
    }

    function getPlayerAnimals(address playerAddress)
        external
        view
        returns(uint256[])
    {
        uint256 animalsOwned = ownedTokensCount[playerAddress];
        uint256[] memory playersAnimals = new uint256[](animalsOwned);

        if (animalsOwned == 0) {
            return playersAnimals;
        }

        uint256 animalsLength = animals.length;
        uint256 playersAnimalsIndex = 0;
        uint256 animalId = 0;
        while (playersAnimalsIndex < animalsOwned && animalId < animalsLength) {
            if (tokenOwner[animalId] == playerAddress) {
                playersAnimals[playersAnimalsIndex] = animalId;
                playersAnimalsIndex++;
            }
            animalId++;
        }

        return playersAnimals;
    }

    function getPlayerDnas(address playerAddress) external view returns(uint256[]) {
        uint256 dnasOwned = addressToDnaCount[playerAddress];
        uint256[] memory playersDnas = new uint256[](dnasOwned);

        if (dnasOwned == 0) {
            return playersDnas;
        }

        uint256 dnasLength = dnas.length;
        uint256 playersDnasIndex = 0;
        uint256 dnaId = 0;
        while (playersDnasIndex < dnasOwned && dnaId < dnasLength) {
            if (dnaIdToOwnerAddress[dnaId] == playerAddress) {
                playersDnas[playersDnasIndex] = dnaId;
                playersDnasIndex++;
            }
            dnaId++;
        }

        return playersDnas;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function buyAnimal(uint256 id) public payable isNotFromContract contractIsActive {
        uint256 etherSent = msg.value;
        address sender = msg.sender;

        Animal storage animalToBuy = animals[id];

        require(etherSent >= animalToBuy.currentValue);
        require(tokenOwner[id] != sender);
        require(!animalToBuy.isSold);
        uint256 etherToPay = animalToBuy.currentValue;
        uint256 etherToRefund = etherSent.sub(etherToPay);
        address previousOwner = tokenOwner[id];

         
        clearApproval(previousOwner, id);
        removeTokenFrom(previousOwner, id);
        addTokenTo(sender, id);

        emit Transfer(previousOwner, sender, id);
         

         
        uint256 ownersShare = etherToPay.sub(etherToPay * developersFee / 100);
         
        previousOwner.transfer(ownersShare);
         
        refundSender(sender, etherToRefund);

         
        if (etherToPay >= rarityTargetValue[animalToBuy.rarity]) {
            animalToBuy.isSold = true;
            animalToBuy.currentValue = 0;
        } else {
             
            animalToBuy.currentValue = calculateNextEtherValue(animalToBuy.currentValue);
        }

        if (shouldGenerateDna) {
            generateDna(sender, id, etherToPay, animalToBuy);
        }
        emit AnimalBoughtEvent(id, previousOwner, sender, etherToPay, animalToBuy.isSold);
    }

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
        )
    {
        Animal storage animal = animals[_animalId];
        return (
            animal.countryId,
            animal.name,
            animal.rarity,
            animal.currentValue,
            rarityTargetValue[animal.rarity],
            tokenOwner[_animalId],
            _animalId
        );
    }

    function getAnimalsCount() public view returns(uint256 animalsCount) {
        return animals.length;
    }

    function getDna(uint256 _dnaId)
        public
        view
        returns(
            uint animalId,
            address owner,
            uint16 effectiveness,
            uint256 id
        )
    {
        Dna storage dna = dnas[_dnaId];
        return (dna.animalId, dnaIdToOwnerAddress[_dnaId], dna.effectiveness, _dnaId);
    }

    function getDnasCount() public view returns(uint256) {
        return dnas.length;
    }

    function getCountry(uint256 _countryId)
        public
        view
        returns(
            bytes2 isoCode,
            uint8 animalsCount,
            uint256[3] animalIds,
            uint256 id
        )
    {
        Country storage country = countries[_countryId];
        return(country.isoCode, country.animalsCount, country.animalIds, _countryId);
    }

    function getCountriesCount() public view returns(uint256 countriesCount) {
        return countries.length;
    }

    function getDevelopersFee() public view returns(uint8) {
        return developersFee;
    }

    function getMarketplaceContract() public view returns(address) {
        return marketplaceContract;
    }

    function getShouldGenerateDna() public view returns(bool) {
        return shouldGenerateDna;
    }

    function withdrawContract() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setDevelopersFee(uint8 _developersFee) public onlyOwner {
        require((_developersFee >= 0) && (_developersFee <= 8));
        developersFee = _developersFee;
    }

    function setShouldGenerateDna(bool _shouldGenerateDna) public onlyAdmin {
        shouldGenerateDna = _shouldGenerateDna;
    }

    function addCountry(bytes2 isoCode) public onlyAdmin {
        Country memory country;
        country.isoCode = isoCode;
        countries.push(country);
    }

    function addAnimal(uint256 countryId, bytes32 animalName, uint8 rarity) public onlyAdmin {
        require((rarity >= 0) && (rarity < 3));
        Country storage country = countries[countryId];

        uint256 id = animals.length;  

        Animal memory animal = Animal(
            false,  
            startingAnimalPrice,
            rarity,
            animalName,
            countryId
        );

        animals.push(animal);
        addAnimalIdToCountry(id, country);
        _mint(address(this), id);
    }

    function changeCountry(uint256 id, bytes2 isoCode) public onlyAdmin {
        Country storage country = countries[id];
        country.isoCode = isoCode;
    }

    function changeAnimal(uint256 animalId, uint256 countryId, bytes32 name, uint8 rarity)
        public
        onlyAdmin
    {
        require(countryId < countries.length);
        Animal storage animal = animals[animalId];
        if (animal.name != name) {
            animal.name = name;
        }
        if (animal.rarity != rarity) {
            require((rarity >= 0) && (rarity < 3));
            animal.rarity = rarity;
        }
        if (animal.countryId != countryId) {
            Country storage country = countries[countryId];

            uint256 oldCountryId = animal.countryId;

            addAnimalIdToCountry(animalId, country);
            removeAnimalIdFromCountry(animalId, oldCountryId);

            animal.countryId = countryId;
        }
    }

    function setRarityTargetValue(uint8 index, uint256 targetValue) public onlyAdmin {
        rarityTargetValue[index] = targetValue;
    }

    function calculateNextEtherValue(uint256 currentEtherValue) public pure returns(uint256) {
        if (currentEtherValue < 0.1 ether) {
            return currentEtherValue.mul(2);
        } else if (currentEtherValue < 0.5 ether) {
            return currentEtherValue.mul(3).div(2);  
        } else if (currentEtherValue < 1 ether) {
            return currentEtherValue.mul(4).div(3);  
        } else if (currentEtherValue < 5 ether) {
            return currentEtherValue.mul(5).div(4);  
        } else if (currentEtherValue < 10 ether) {
            return currentEtherValue.mul(6).div(5);  
        } else {
            return currentEtherValue.mul(7).div(6);  
        }
    }

    function refundSender(address sender, uint256 etherToRefund) private {
        if (etherToRefund > 0) {
            sender.transfer(etherToRefund);
        }
    }

    function generateDna(
        address sender,
        uint256 animalId,
        uint256 pricePaid,
        Animal animal
    )
        private
    {
        uint256 id = dnas.length;  
        Dna memory dna = Dna(
            animalId,
            calculateAnimalEffectiveness(pricePaid, animal)
        );

        dnas.push(dna);

        dnaIdToOwnerAddress[id] = sender;
        addressToDnaCount[sender] = addressToDnaCount[sender].add(1);
    }

    function calculateAnimalEffectiveness(
        uint256 pricePaid,
        Animal animal
    )
        private
        view
        returns(uint8)
    {
        if (animal.isSold) {
            return 100;
        }

        uint256 effectiveness = 10;  
         
        uint256 effectivenessPerEther = 10**18 * 80 / rarityTargetValue[animal.rarity];
        effectiveness = effectiveness.add(pricePaid * effectivenessPerEther / 10**18);

        if (effectiveness > 90) {
            effectiveness = 90;
        }

        return uint8(effectiveness);
    }

    function addAnimalIdToCountry(
        uint256 animalId,
        Country storage country
    )
        private
    {
        uint8 animalSlotIndex = country.animalsCount;
        require(animalSlotIndex < 3);
        country.animalIds[animalSlotIndex] = animalId;
        country.animalsCount += 1;
    }

    function removeAnimalIdFromCountry(uint256 animalId, uint256 countryId) private {
        Country storage country = countries[countryId];
        for (uint8 i = 0; i < country.animalsCount; i++) {
            if (country.animalIds[i] == animalId) {
                if (i != country.animalsCount - 1) {
                    country.animalIds[i] = country.animalIds[country.animalsCount - 1];
                }
                country.animalsCount -= 1;
                return;
            }
        }
    }
}