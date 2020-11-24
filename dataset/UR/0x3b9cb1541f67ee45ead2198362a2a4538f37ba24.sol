 

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC721Receiver {
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes   _userData
  ) external returns (bytes4);
}

contract IERC721Metadata {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function description() external view returns (string);
    function tokenMetadata(uint256 assetId) external view returns (string);
}

contract IERC721Enumerable {
    function tokensOf(address owner) external view returns (uint256[]);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface IERC721Base {
    function totalSupply() external view returns (uint256);
     
    function ownerOf(uint256 assetId) external view returns (address);
    function balanceOf(address holder) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 assetId) external;
    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external;
    function transferFrom(address from, address to, uint256 assetId) external;
    function approve(address operator, uint256 assetId) external;
    function setApprovalForAll(address operator, bool authorized) external;
    function getApprovedAddress(uint256 assetId) external view returns (address);
    function isApprovedForAll(address assetHolder, address operator) external view returns (bool);
    function isAuthorized(address operator, uint256 assetId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed assetId, address operator, bytes userData);
    event Transfer(address indexed from, address indexed to, uint256 indexed assetId);
    event ApprovalForAll(address indexed operator, address indexed holder, bool authorized);
    event Approval(address indexed owner, address indexed operator, uint256 indexed assetId);
}

interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract AssetRegistryStorage {
    string internal _name;
    string internal _symbol;
    string internal _description;

    uint256 internal _count;
    mapping(address => uint256[]) internal _assetsOf;
    mapping(uint256 => address) internal _holderOf;
    mapping(uint256 => uint256) internal _indexOfAsset;
    mapping(uint256 => string) internal _assetData;
    mapping(address => mapping(address => bool)) internal _operators;
    mapping(uint256 => address) internal _approval;
}

contract ERC721Enumerable is AssetRegistryStorage, IERC721Enumerable {
    function tokensOf(address owner) external view returns (uint256[]) {
        return _assetsOf[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)external view returns (uint256 assetId) {
        require(index < _assetsOf[owner].length);
        require(index < (1<<127));
        return _assetsOf[owner][index];
    }
}

contract ERC721Holder is IERC721Receiver {
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function onERC721Received(address  , address  , uint256  , bytes  ) external returns (bytes4) {
        return ERC721_RECEIVED;
    }
}

contract ERC721Metadata is AssetRegistryStorage, IERC721Metadata {
    function name() external view returns (string) {
        return _name;
    }

    function symbol() external view returns (string) {
        return _symbol;
    }

    function description() external view returns (string) {
        return _description;
    }

    function tokenMetadata(uint256 assetId) external view returns (string) {
        return _assetData[assetId];
    }

    function _update(uint256 assetId, string data) internal {
        _assetData[assetId] = data;
    }
}

contract ERC721Base is AssetRegistryStorage, IERC721Base, ERC165 {
    using SafeMath for uint256;

     
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant InterfaceId_ERC165 = 0x01ffc9a7;
     

    bytes4 private constant Old_InterfaceId_ERC721 = 0x7c0633c6;
    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
     

     
     
     

     
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }

    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

    function isApprovedForAll(address assetHolder, address operator) external view returns (bool) {
        return _isApprovedForAll(assetHolder, operator);
    }
    
    function _isApprovedForAll(address assetHolder, address operator) internal view returns (bool) {
        return _operators[assetHolder][operator];
    }

    function getApproved(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }

    function getApprovedAddress(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }

    function _getApprovedAddress(uint256 assetId) internal view returns (address) {
        return _approval[assetId];
    }

    function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
        return _isAuthorized(operator, assetId);
    }

    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool) {
        require(operator != 0);
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return _isApprovedForAll(owner, operator) || _getApprovedAddress(assetId) == operator;
    }

    function setApprovalForAll(address operator, bool authorized) external {
        return _setApprovalForAll(operator, authorized);
    }

    function _setApprovalForAll(address operator, bool authorized) internal {
        if (authorized) {
            require(!_isApprovedForAll(msg.sender, operator));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(msg.sender, operator));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(msg.sender, operator, authorized);
    }

    function approve(address operator, uint256 assetId) external {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder));
        require(operator != holder);

        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

         
        _assetsOf[from][assetIndex] = lastAssetId;

         
        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

         
        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

         
        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }

    function _generate(uint256 assetId, address beneficiary) internal {
        require(_holderOf[assetId] == 0);

        _addAssetTo(beneficiary, assetId);

        emit Transfer(0, beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != 0);

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, 0, assetId);
    }

    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender);
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId));
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from);
        _;
    }

    modifier isDestinataryDefined(address destinatary) {
        require(destinatary != 0);
        _;
    }

    modifier destinataryIsNotHolder(uint256 assetId, address to) {
        require(_ownerOf(assetId) != to);
        _;
    }

    function safeTransferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, '', true);
    }

    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

    function transferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, '', false);
    }

    function _doTransferFrom(address from, address to, uint256 assetId, bytes userData, bool doCheck) onlyAuthorized(assetId) internal {
        _moveToken(from, to, assetId, userData, doCheck);
    }

    function _moveToken(address from, address to, uint256 assetId, bytes userData, bool doCheck) isDestinataryDefined(to) destinataryIsNotHolder(assetId, to) isCurrentOwner(from, assetId) internal{
        address holder = _holderOf[assetId];
        _removeAssetFrom(holder, assetId);
        _clearApproval(holder, assetId);
        _addAssetTo(to, assetId);

        if (doCheck && _isContract(to)) {
             
            require(IERC721Receiver(to).onERC721Received(msg.sender, holder, assetId, userData) == ERC721_RECEIVED);
        }

        emit Transfer(holder, to, assetId);
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        if (_interfaceID == 0xffffffff) {
            return false;
        }
        
        return _interfaceID == InterfaceId_ERC165 || _interfaceID == Old_InterfaceId_ERC721 || _interfaceID == InterfaceId_ERC721;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }

        return size > 0;
    }
}

contract FullAssetRegistry is ERC721Base, ERC721Enumerable, ERC721Metadata {
    constructor() public {
    }

    function exists(uint256 assetId) external view returns (bool) {
        return _exists(assetId);
    }

    function _exists(uint256 assetId) internal view returns (bool) {
        return _holderOf[assetId] != 0;
    }

    function decimals() external pure returns (uint256) {
        return 0;
    }
}

contract JZToken is FullAssetRegistry {
    constructor() public {
        _name = "JZToken";
        _symbol = "JZ";
        _description = "JZ NFT Token";
    }

    function isContractProxy(address addr) public view returns (bool) {
        return _isContract(addr);
    }

    function generate(uint256 assetId, address beneficiary) public {
        _generate(assetId, beneficiary);
    }

    function destroy(uint256 assetId) public {
        _destroy(assetId);
    }

     
    function safeTransfer(address from, address to, uint256 assetId, bytes data) public {
        return _doTransferFrom(from, to, assetId, data, true);
    }
}