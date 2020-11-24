 

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

 

 
contract ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
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
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ERC721Receiver {
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    function onERC721Received(
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
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

 

 
contract ERC721Token is ERC721, ERC721BasicToken {
     
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

 

contract IBBArtefact {
    function mint(address to, uint typeId, uint packId, uint packTypeId) public returns (uint);
}

contract BBPack is Ownable, ERC721Token {
    uint public incrementPackId = 0;
    uint public incrementPackTypeId = 0;
    uint public incrementArtefactTypeId = 0;

    address public wallet;
    address public BBArtefactAddress;
    uint public feePercentage;

    struct PackType {
        uint id;
        uint authorId;
        address authorWallet;
        uint[] artefactsTypes;
        uint[] artefactsEmission;
        uint[] artefactsLeft;
        uint typesCount;
        uint packsCount;
        uint activeBefore;
        bool unlimitedEmission;
        bool unlimitedSale;
        bool fullSet;
        uint oneArtefactPrice;
        bool onSale;
        bool created;
    }

    struct Pack {
        uint id;
        uint typeId;
        uint artefactsCount;
        uint cost;
    }

    mapping(address => bool) public managers;
    mapping(uint => PackType) public packTypes;
    mapping(uint => Pack) public packs;


    modifier onlyOwnerOrManager() {
        require(msg.sender == owner || managers[msg.sender]);
        _;
    }

    event PackMinted(uint id, address to, uint typeId, uint count);
    event PackBought(uint id, address to, uint typeId, uint price, uint count);
    event PackBurned(uint id, address owner);
    event PackOpened(uint id, address owner, uint packTypeId);
    event PackTypeUpdated(uint id);

    constructor(address _BBArtefactAddress, address _manger, address _wallet, uint _feePercentage) public ERC721Token("BBPack Token", "BBPT") {
        wallet = _wallet;
        managers[_manger] = true;
        BBArtefactAddress = _BBArtefactAddress;
        feePercentage = _feePercentage;
    }

    function createPackType(
        uint authorId,
        address authorWallet,
        uint[] artefactsEmission,
        uint typesCount,
        uint packsCount,
        bool unlimitedEmission,
        bool fullSet
    ) public onlyOwnerOrManager returns (uint) {
        require(artefactsEmission.length == typesCount);
        require(typesCount > 0);

        incrementPackTypeId++;
        packTypes[incrementPackTypeId] = PackType(
            incrementPackTypeId,
            authorId,
            authorWallet,
            new uint[](typesCount),
            artefactsEmission,
            artefactsEmission,
            typesCount,
            packsCount,
            0,
            unlimitedEmission,
            false,
            fullSet,
            0,
            false,
            true
        );
        for (uint i = 0; i < typesCount; i++) {
            incrementArtefactTypeId++;
            packTypes[incrementPackTypeId].artefactsTypes[i] = incrementArtefactTypeId;
        }
        emit PackTypeUpdated(incrementArtefactTypeId);
        return incrementPackTypeId;
    }

    function setSale(uint id, uint oneArtefactPrice, bool onSale, uint activeBefore, bool unlimitedSale) public onlyOwnerOrManager {
        packTypes[id].oneArtefactPrice = oneArtefactPrice;
        packTypes[id].onSale = onSale;
        packTypes[id].activeBefore = activeBefore;
        packTypes[id].unlimitedSale = unlimitedSale;
        emit PackTypeUpdated(id);
    }

    function editPackType(
        uint id,
        uint authorId,
        address authorWallet,
        uint[] artefactsTypes,
        uint[] artefactsEmission,
        uint[] artefactsLeft,
        uint typesCount,
        uint packsCount,
        bool unlimitedEmission,
        bool fullSet,
        bool created
    ) public onlyOwnerOrManager {
        packTypes[id].authorId = authorId;
        packTypes[id].authorWallet = authorWallet;
        packTypes[id].artefactsTypes = artefactsTypes;
        packTypes[id].artefactsEmission = artefactsEmission;
        packTypes[id].artefactsLeft = artefactsLeft;
        packTypes[id].typesCount = typesCount;
        packTypes[id].packsCount = packsCount;
        packTypes[id].unlimitedEmission = unlimitedEmission;
        packTypes[id].fullSet = fullSet;
        packTypes[id].created = created;
        emit PackTypeUpdated(id);
    }

    function buyPack(uint packTypeId, uint artefactsCount, bool open) public payable returns (uint) {
        PackType memory packType = packTypes[packTypeId];
        require(packType.onSale && packType.created);
        require(packType.unlimitedSale || packType.packsCount > 0);
        require(packType.activeBefore == 0 || block.number < packType.activeBefore);
        require(packType.oneArtefactPrice * artefactsCount == msg.value);

        if (!packType.unlimitedEmission) {
            uint artefactsLeft = 0;
            for (uint i = 0; i < packType.artefactsLeft.length; i++) {
                artefactsLeft += packType.artefactsLeft[i];
            }
            require(artefactsLeft >= artefactsCount);
        }

        if (packType.fullSet) {
            uint part = packType.typesCount / artefactsCount;
            require(part * artefactsCount == packType.typesCount);
        }

        uint fee = (msg.value * feePercentage) / 100;
        uint toAuthor = msg.value - fee;

        wallet.transfer(fee);
        (packType.authorWallet).transfer(toAuthor);

        if (!packType.unlimitedSale) {
            packTypes[packTypeId].packsCount--;
        }
        incrementPackId++;
        super._mint(msg.sender, incrementPackId);
        packs[incrementPackId] = Pack(incrementPackId, packTypeId, artefactsCount, toAuthor);
        emit PackBought(incrementPackId, msg.sender, packTypeId, toAuthor, artefactsCount);

        if (open) {
            openPack(incrementPackId);
        }

        return incrementPackId;
    }

    function mint(address to, uint typeId, uint artefactsCount) public onlyOwnerOrManager returns (uint) {
        incrementPackId++;
        super._mint(to, incrementPackId);
        packs[incrementPackId] = Pack(incrementPackId, typeId, artefactsCount, 0);
        emit PackMinted(incrementPackId, msg.sender, typeId, artefactsCount);
        return incrementPackId;
    }

    function burn(uint tokenId) public onlyOwnerOf(tokenId) {
        super._burn(msg.sender, tokenId);
        delete packs[tokenId];
        emit PackBurned(tokenId, msg.sender);
    }

    function getPackArtefactsTypesByIndex(uint packTypeId, uint index) public view returns (uint, uint, uint) {
        return (
        packTypes[packTypeId].artefactsTypes[index],
        packTypes[packTypeId].artefactsEmission[index],
        packTypes[packTypeId].artefactsLeft[index]
        );
    }

    function openPack(uint packId) public onlyOwnerOf(packId) {
        Pack memory pack = packs[packId];
        PackType memory packType = packTypes[pack.typeId];
        require(packType.activeBefore == 0 || block.number < packType.activeBefore);

        if (packType.fullSet) {
            generateFullPackCollection(packId, packType);
        }

        if (packType.unlimitedEmission && !packType.fullSet) {
            generateUnlimited(packId, packType);
        }

        if (!packType.unlimitedEmission && !packType.fullSet) {
            generateLimited(packId, packType);
        }
        burn(packId);
        emit PackTypeUpdated(packType.id);
        emit PackOpened(packId, msg.sender, packType.id);
    }

    function generateFullPackCollection(uint packId, PackType packType) internal {
        for (uint i = 0; i < packType.typesCount; i++) {
            require(packType.unlimitedEmission || packType.artefactsLeft[i] > 0);
            if (!packType.unlimitedEmission) {
                packTypes[packType.id].artefactsLeft[i]--;
            }
            IBBArtefact(BBArtefactAddress).mint(msg.sender, packType.artefactsTypes[i], packId, packType.id);
        }
    }

    function generateUnlimited(uint packId, PackType packType) internal {
        for (uint i = 0; i < packs[packId].artefactsCount; i++) {
            uint artefactIndex = getRandom(packType.artefactsTypes.length, i);
            uint artefactType = packType.artefactsTypes[artefactIndex];
            IBBArtefact(BBArtefactAddress).mint(msg.sender, artefactType, packId, packType.id);
        }
    }

    function generateLimited(uint packId, PackType packType) internal {
        uint artefactsLeft = 0;
        for (uint i = 0; i < packType.artefactsLeft.length; i++) {
            artefactsLeft += packType.artefactsLeft[i];
        }
        require(artefactsLeft >= packs[packId].artefactsCount);

        for (i = 0; i < packs[packId].artefactsCount; i++) {
            uint random = getRandom(artefactsLeft, i) + 1;
            uint index = getRandomArtefactIndex(packType.id, random);
            require(packTypes[packType.id].artefactsLeft[index] > 0);
            artefactsLeft--;
            packTypes[packType.id].artefactsLeft[index]--;
            IBBArtefact(BBArtefactAddress).mint(msg.sender, packType.artefactsTypes[index], packId, packType.id);
        }
    }

    function getRandomArtefactIndex(uint packTypeId, uint random) internal view returns (uint){
        uint counter = 0;
        for (uint j = 0; j < packTypes[packTypeId].artefactsLeft.length; j++) {
            if (random < counter + packTypes[packTypeId].artefactsLeft[j]) {
                return j;
            }
            counter += packTypes[packTypeId].artefactsLeft[j];
        }
        return j;
    }

    function getRandom(uint max, uint mix) internal view returns (uint random) {
        random = bytesToUint(keccak256(abi.encodePacked(blockhash(block.number - 1), mix))) % max;
    }

    function setTokenURI(uint256 _tokenId, string _uri) public onlyOwnerOrManager {
        super._setTokenURI(_tokenId, _uri);
    }

    function setManager(address _manager, bool enable) public onlyOwner {
        managers[_manager] = enable;
    }

    function changeWallet(address _wallet) public onlyOwnerOrManager {
        wallet = _wallet;
    }

    function changeFee(uint _feePercentage) public onlyOwnerOrManager {
        feePercentage = _feePercentage;
    }

    function changeBBArtefactAddress(address _newAddress) public onlyOwnerOrManager {
        BBArtefactAddress = _newAddress;
    }

    function bytesToUint(bytes32 b) internal pure returns (uint number){
        for (uint i = 0; i < b.length; i++) {
            number = number + uint(b[i]) * (2 ** (8 * (b.length - (i + 1))));
        }
    }

}