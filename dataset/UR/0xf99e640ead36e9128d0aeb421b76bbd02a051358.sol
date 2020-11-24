 

pragma solidity 0.5.11;

 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract InscribableToken is Ownable {

    mapping(bytes32 => bytes32) public properties;

    event ClassPropertySet(bytes32 indexed key, bytes32 value);
    event TokenPropertySet(uint indexed id, bytes32 indexed key, bytes32 value);

    function _setProperty(uint _id, bytes32 _key, bytes32 _value) internal {
        properties[getTokenKey(_id, _key)] = _value;
        emit TokenPropertySet(_id, _key, _value);
    }

    function getProperty(uint _id, bytes32 _key) public view returns (bytes32 _value) {
        return properties[getTokenKey(_id, _key)];
    }

    function _setClassProperty(bytes32 _key, bytes32 _value) internal {
        emit ClassPropertySet(_key, _value);
        properties[getClassKey(_key)] = _value;
    }

    function getTokenKey(uint _tokenId, bytes32 _key) public pure returns (bytes32) {
         
        return keccak256(abi.encodePacked(uint(1), _tokenId, _key));
    }

    function getClassKey(bytes32 _key) public pure returns (bytes32) {
         
        return keccak256(abi.encodePacked(uint(0), _key));
    }

    function getClassProperty(bytes32 _key) public view returns (bytes32) {
        return properties[getClassKey(_key)];
    }

}



 


library StorageWrite {

    using SafeMath for uint256;

    function _getStorageArraySlot(uint _dest, uint _index) internal view returns (uint result) {
        uint slot = _getArraySlot(_dest, _index);
        assembly { result := sload(slot) }
    }

    function _getArraySlot(uint _dest, uint _index) internal pure returns (uint slot) {
        assembly {
            let free := mload(0x40)
            mstore(free, _dest)
            slot := add(keccak256(free, 32), _index)
        }
    }

    function _setArraySlot(uint _dest, uint _index, uint _value) internal {
        uint slot = _getArraySlot(_dest, _index);
        assembly { sstore(slot, _value) }
    }

    function _loadSlots(uint _slot, uint _offset, uint _perSlot, uint _length) internal view returns (uint[] memory slots) {
        uint slotCount = _slotCount(_offset, _perSlot, _length);
        slots = new uint[](slotCount);
         
        uint firstPos = _pos(_offset, _perSlot);  
        slots[0] = _getStorageArraySlot(_slot, firstPos);
        if (slotCount > 1) {
            uint lastPos = _pos(_offset.add(_length), _perSlot);  
            slots[slotCount-1] = _getStorageArraySlot(_slot, lastPos);
        }
    }

    function _pos(uint items, uint perPage) internal pure returns (uint) {
        return items / perPage;
    }

    function _slotCount(uint _offset, uint _perSlot, uint _length) internal pure returns (uint) {
        uint start = _offset / _perSlot;
        uint end = (_offset + _length) / _perSlot;
        return (end - start) + 1;
    }

    function _saveSlots(uint _slot, uint _offset, uint _size, uint[] memory _slots) internal {
        uint offset = _offset.div((256/_size));
        for (uint i = 0; i < _slots.length; i++) {
            _setArraySlot(_slot, offset + i, _slots[i]);
        }
    }

    function _write(uint[] memory _slots, uint _offset, uint _size, uint _index, uint _value) internal pure {
        uint perSlot = 256 / _size;
        uint initialOffset = _offset % perSlot;
        uint slotPosition = (initialOffset + _index) / perSlot;
        uint withinSlot = ((_index + _offset) % perSlot) * _size;
         
        for (uint q = 0; q < _size; q += 8) {
            _slots[slotPosition] |= ((_value >> q) & 0xFF) << (withinSlot + q);
        }
    }

    function repeatUint16(uint _slot, uint _offset, uint _length, uint16 _item) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 16, _length);
        for (uint i = 0; i < _length; i++) {
            _write(slots, _offset, 16, i, _item);
        }
        _saveSlots(_slot, _offset, 16, slots);
    }

    function uint16s(uint _slot, uint _offset, uint16[] memory _items) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 16, _items.length);
        for (uint i = 0; i < _items.length; i++) {
            _write(slots, _offset, 16, i, _items[i]);
        }
        _saveSlots(_slot, _offset, 16, slots);
    }

    function uint8s(uint _slot, uint _offset, uint8[] memory _items) internal {
        uint[] memory slots = _loadSlots(_slot, _offset, 32, _items.length);
        for (uint i = 0; i < _items.length; i++) {
            _write(slots, _offset, 8, i, _items[i]);
        }
        _saveSlots(_slot, _offset, 8, slots);
    }

}

library String {

     
    function fromUint(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    function fromAddress(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0F))];
        }
        return string(str);
    }

}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}


 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


contract ImmutableToken {

    string public constant baseURI = "https://api.immutable.com/token/";

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(
            baseURI,
            String.fromAddress(address(this)),
            "/",
            String.fromUint(tokenId)
        ));
    }

}

 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


 
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
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ICards is IERC721 {

    function getDetails(uint tokenId) public view returns (uint16 proto, uint8 quality);
    function setQuality(uint tokenId, uint8 quality) public;
    function burn(uint tokenId) public;
    function batchMintCards(address to, uint16[] memory _protos, uint8[] memory _qualities) public returns (uint);
    function mintCards(address to, uint16[] memory _protos, uint8[] memory _qualities) public returns (uint);
    function mintCard(address to, uint16 _proto, uint8 _quality) public returns (uint);
    function batchSize() public view returns (uint);
}






 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


contract MultiTransfer is ERC721 {

   function transferBatch(address from, address to, uint256 start, uint256 end) public {
       for (uint i = start; i < end; i++) {
           transferFrom(from, to, i);
       }
   }

   function transferAllFrom(address from, address to, uint256[] memory tokenIDs) public {
       for (uint i = 0; i < tokenIDs.length; i++) {
           transferFrom(from, to, tokenIDs[i]);
       }
   }

   function safeTransferBatch(address from, address to, uint256 start, uint256 end) public {
       for (uint i = start; i < end; i++) {
           safeTransferFrom(from, to, i);
       }
   }

   function safeTransferAllFrom(address from, address to, uint256[] memory tokenIDs) public {
       for (uint i = 0; i < tokenIDs.length; i++) {
           safeTransferFrom(from, to, tokenIDs[i]);
       }
   }

}


contract BatchToken is ERC721Metadata {

    using SafeMath for uint256;

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    mapping(uint48 => address) public userIDToAddress;
    mapping(address => uint48) public addressToUserID;

    uint256 public batchSize;
    uint256 public nextBatch;
    uint256 public tokenCount;

    uint48[] internal ownerIDs;
    uint48[] internal approvedIDs;

    Batch[] public batches;

    uint48 internal userCount = 1;
    uint256 public firstFree = 0;

    mapping (address => uint) internal _ownedTokensCount;

    uint256 internal constant MAX_LENGTH = uint(2**256 - 1);

    constructor(uint256 _batchSize, string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        batchSize = _batchSize;
        batches.length = MAX_LENGTH;
        ownerIDs.length = MAX_LENGTH;
        approvedIDs.length = MAX_LENGTH;
    }

    function _sequentialMint(address to, uint16 size) internal returns (uint) {
        uint256 id = firstFree;
        uint256 end = id + size;
        uint48 uID = _getUserID(to);
        for (uint256 i = id; i < end; i++) {
            emit Transfer(address(0), to, i);
            ownerIDs[i] = uID;
        }
        firstFree += size;
        _ownedTokensCount[to] += size;
        tokenCount += size;
        return id;
    }

    function _getUserID(address to) internal returns (uint48) {
        if (to == address(0)) {
            return 0;
        }
        uint48 uID = addressToUserID[to];
        if (uID == 0) {
            require(userCount + 1 > userCount, "must not overflow");
            uID = userCount++;
            userIDToAddress[uID] = to;
            addressToUserID[to] = uID;
        }
        return uID;
    }

    function _getNextBatch() internal returns (uint) {
        if (firstFree > nextBatch) {
            nextBatch = _pageCount(firstFree, batchSize).mul(batchSize);
        }
        return nextBatch;
    }

    function _pageCount(uint256 items, uint256 perPage) internal pure returns (uint){
        return ((items - 1) / perPage) + 1;
    }

    function _batchMint(address to, uint16 size) internal returns (uint) {
        require(to != address(0), "must not be null");
        require(size > 0 && size <= batchSize, "size must be within limits");
        uint256 start = _getNextBatch();
        uint48 uID = _getUserID(to);
        batches[start] = Batch({
            userID: uID,
            size: size
        });
        uint256 end = start + size;
        for (uint256 i = start; i < end; i++) {
            emit Transfer(address(0), to, i);
        }
        nextBatch += batchSize;
        _ownedTokensCount[to] += size;
        tokenCount += size;
        return start;
    }

    function getBatchStart(uint256 tokenId) public view returns (uint) {
        return tokenId.div(batchSize).mul(batchSize);
    }

    function getBatch(uint256 index) public view returns (uint48 userID, uint16 size) {
        return (batches[index].userID, batches[index].size);
    }

     
     

    function ownerOf(uint256 tokenId) public view returns (address) {
        uint48 uID = ownerIDs[tokenId];
        if (uID == 0) {
            uint256 start = getBatchStart(tokenId);
            Batch memory b = batches[start];
            require(start + b.size > tokenId, "token does not exist");
            uID = b.userID;
        }
        return userIDToAddress[uID];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not owner nor approved");
        if (approvedIDs[tokenId] != 0) {
            approvedIDs[tokenId] = 0;
        }
        _ownedTokensCount[from]--;
        _ownedTokensCount[to]++;
        ownerIDs[tokenId] = _getUserID(to);
        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not owner nor approved");
        if (approvedIDs[tokenId] != 0) {
            approvedIDs[tokenId] = 0;
        }
        address owner = ownerOf(tokenId);
        _ownedTokensCount[owner]--;
        ownerIDs[tokenId] = 0;
        tokenCount--;
        emit Transfer(owner, address(0), tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        approvedIDs[tokenId] = _getUserID(to);
        emit Approval(owner, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return userIDToAddress[approvedIDs[tokenId]];
    }

    function totalSupply() public view returns (uint) {
        return tokenCount;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _ownedTokensCount[_owner];
    }

}

 









contract Cards is Ownable, MultiTransfer, BatchToken, ImmutableToken, InscribableToken {

    uint16[] public cardProtos;
    uint8[] public cardQualities;

    struct Season {
        uint16 high;
        uint16 low;
    }

    struct Proto {
        bool locked;
        bool exists;
        uint8 god;
        uint8 cardType;
        uint8 rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 tribe;
    }

    event ProtoUpdated(uint16 indexed id);
    event SeasonStarted(uint16 indexed id, string name, uint16 indexed low, uint16 indexed high);
    event QualityChanged(uint256 indexed tokenId, uint8 quality, address factory);

    uint16[] public protoToSeason;
    address public propertyManager;
    Proto[] public protos;
    Season[] public seasons;
    mapping(uint256 => bool) public seasonTradable;
    mapping(address => mapping(uint256 => bool)) public factoryApproved;
    mapping(uint16 => bool) public mythicCreated;
    uint16 public constant MYTHIC_THRESHOLD = 65000;

    constructor(uint256 _batchSize, string memory _name, string memory _symbol) public BatchToken(_batchSize, _name, _symbol) {
        cardProtos.length = MAX_LENGTH;
        cardQualities.length = MAX_LENGTH;
        protoToSeason.length = MAX_LENGTH;
        protos.length = MAX_LENGTH;
        propertyManager = msg.sender;
    }

    function getDetails(uint256 tokenId) public view returns (uint16 proto, uint8 quality) {
        return (cardProtos[tokenId], cardQualities[tokenId]);
    }

    function mintCard(address to, uint16 _proto, uint8 _quality) external returns (uint) {
        uint256 start = _sequentialMint(to, 1);
        _validateProto(_proto);
        cardProtos[start] = _proto;
        cardQualities[start] = _quality;
    }

    function mintCards(address to, uint16[] calldata _protos, uint8[] calldata _qualities) external returns (uint) {
        require(_protos.length > 0, "must be some protos");
        require(_protos.length == _qualities.length, "must be the same number of protos/qualities");
        uint256 start = _sequentialMint(to, uint16(_protos.length));
        _validateAndSaveDetails(start, _protos, _qualities);
    }

    function batchMintCards(address to, uint16[] calldata _protos, uint8[] calldata _qualities) external returns (uint) {
        require(_protos.length > 0, "must be some protos");
        require(_protos.length == _qualities.length, "must be the same number of protos/qualities");
        uint256 start = _batchMint(to, uint16(_protos.length));
        _validateAndSaveDetails(start, _protos, _qualities);
        return start;
    }

    function addFactory(address _factory, uint256 _season) public onlyOwner {
        require(seasons.length >= _season, "season must exist");
        require(_season > 0, "season must not be 0");
        require(!factoryApproved[_factory][_season], "this factory is already approved");
        require(!seasonTradable[_season], "season must not be tradable");
        factoryApproved[_factory][_season] = true;
    }

    function unlockTrading(uint256 _season) public onlyOwner {
        require(!seasonTradable[_season], "season must not be tradable");
        seasonTradable[_season] = true;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(isTradable(tokenId), "not yet tradable");
        super.transferFrom(from, to, tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(isTradable(_tokenId), "not yet tradable");
        super.burn(_tokenId);
    }

    function burnAll(uint256[] memory tokenIDs) public {
       for (uint256 i = 0; i < tokenIDs.length; i++) {
           burn(tokenIDs[i]);
       }
   }

    function isTradable(uint256 _tokenId) public view returns (bool) {
        return seasonTradable[protoToSeason[cardProtos[_tokenId]]];
    }

    function startSeason(string memory name, uint16 low, uint16 high) public onlyOwner returns (uint) {

        require(low > 0, "must not be zero proto");
        require(high > low, "must be a valid range");
        require(seasons.length == 0 || low > seasons[seasons.length - 1].high, "seasons cannot overlap");

         
        uint16 id = uint16(seasons.push(Season({ high: high, low: low })));

        uint256 cp; assembly { cp := protoToSeason_slot }
        StorageWrite.repeatUint16(cp, low, (high - low) + 1, id);

        emit SeasonStarted(id, name, low, high);

        return id;
    }

    function updateProtos(
        uint16[] memory _ids,
        uint8[] memory _gods,
        uint8[] memory _cardTypes,
        uint8[] memory _rarities,
        uint8[] memory _manas,
        uint8[] memory _attacks,
        uint8[] memory _healths,
        uint8[] memory _tribes
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];
            require(id > 0, "proto must not be zero");
            Proto memory proto = protos[id];
            require(!proto.locked, "proto is locked");
            protos[id] = Proto({
                locked: false,
                exists: true,
                god: _gods[i],
                cardType: _cardTypes[i],
                rarity: _rarities[i],
                mana: _manas[i],
                attack: _attacks[i],
                health: _healths[i],
                tribe: _tribes[i]
            });
            emit ProtoUpdated(id);
        }
    }

    function lockProtos(uint16[] memory _ids) public onlyOwner {
        require(_ids.length > 0, "must lock some");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint16 id = _ids[i];
            require(id > 0, "proto must not be zero");
            Proto storage proto = protos[id];
            require(!proto.locked, "proto is locked");
            require(proto.exists, "proto must exist");
            proto.locked = true;
            emit ProtoUpdated(id);
        }
    }

    function _validateAndSaveDetails(uint256 start, uint16[] memory _protos, uint8[] memory _qualities) internal {
        _validateProtos(_protos);

        uint256 cp; assembly { cp := cardProtos_slot }
        StorageWrite.uint16s(cp, start, _protos);
        uint256 cq; assembly { cq := cardQualities_slot }
        StorageWrite.uint8s(cq, start, _qualities);

    }

    uint16 private constant MAX_UINT16 = 2**16 - 1;

    function _validateProto(uint16 proto) internal {
        if (proto >= MYTHIC_THRESHOLD) {
            require(!mythicCreated[proto], "mythic has already been created");
            mythicCreated[proto] = true;
        } else {
            uint256 season = protoToSeason[proto];
            require(season != 0, "must have season set");
            require(factoryApproved[msg.sender][season], "must be approved factory for this season");
        }
    }

    function _validateProtos(uint16[] memory _protos) internal {
        uint16 maxProto = 0;
        uint16 minProto = MAX_UINT16;
        for (uint256 i = 0; i < _protos.length; i++) {
            uint16 proto = _protos[i];
            if (proto >= MYTHIC_THRESHOLD) {
                require(!mythicCreated[proto], "mythic has already been created");
                mythicCreated[proto] = true;
            } else {
                if (proto > maxProto) {
                    maxProto = proto;
                }
                if (minProto > proto) {
                    minProto = proto;
                }
            }
        }

        if (maxProto != 0) {
            uint256 season = protoToSeason[maxProto];
             
            require(season != 0, "must have season set");
            require(season == protoToSeason[minProto], "can only create cards from the same season");
            require(factoryApproved[msg.sender][season], "must be approved factory for this season");
        }
    }

    function setQuality(uint256 _tokenId, uint8 _quality) public {
        uint16 proto = cardProtos[_tokenId];
        uint256 season = protoToSeason[proto];
        require(factoryApproved[msg.sender][season], "factory can't change quality of this season");
        cardQualities[_quality] = _quality;
        emit QualityChanged(_tokenId, _quality, msg.sender);
    }

    function setPropertyManager(address _manager) public onlyOwner {
        propertyManager = _manager;
    }

    function setProperty(uint256 _id, bytes32 _key, bytes32 _value) public {
        require(msg.sender == propertyManager, "must be property manager");
        _setProperty(_id, _key, _value);
    }

    function setClassProperty(bytes32 _key, bytes32 _value) public {
        require(msg.sender == propertyManager, "must be property manager");
        _setClassProperty(_key, _value);
    }

}