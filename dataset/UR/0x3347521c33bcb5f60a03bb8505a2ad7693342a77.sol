 

pragma solidity ^0.4.24;

 

 
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

     
    function balanceOf(address _owner) public view returns (uint256);

     
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
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);  
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

 

interface IEntityStorage {
    function storeBulk(uint256[] _tokenIds, uint256[] _attributes) external;
    function store(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external;
    function remove(uint256 _tokenId) external;
    function list() external view returns (uint256[] tokenIds);
    function getAttributes(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds);
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external;
    function totalSupply() external view returns (uint256);
}

 

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

    IEntityStorage internal cbStorage;

    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
     

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
     

    string internal uriPrefix;

     
    string internal name_;

     
    string internal symbol_;

     
    mapping(address => uint256[]) internal ownedTokens;
    
     
    uint256[] internal transferableTokens;

     
    constructor(string _name, string _symbol, string _uriPrefix, address _storage) public {
        require(_storage != address(0), "Storage Address is required");
        name_ = _name;
        symbol_ = _symbol;

         
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);
        cbStorage = IEntityStorage(_storage);
        uriPrefix = _uriPrefix;
    }

     
    function name() external view returns (string) {
        return name_;
    }

     
    function symbol() external view returns (string) {
        return symbol_;
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return strConcat(uriPrefix, uintToString(_tokenId));
    }

     
    function totalSupply() public view returns (uint256) {
        return cbStorage.totalSupply();
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        ownedTokens[_to].push(_tokenId);
    }

     
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = 0;
        while (ownedTokens[_from][tokenIndex] != _tokenId && tokenIndex < ownedTokens[_from].length) {
            tokenIndex++;
        }
         
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
         
        require(!isTransferable(_tokenId));  
        super._burn(_owner, _tokenId);
        cbStorage.remove(_tokenId);
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }

         
    function listTransferableTokens() public view returns(uint256[]) {
        return transferableTokens;
    } 

     
    function isTransferable(uint256 _tokenId) public view returns (bool) {
        for (uint256 index = 0; index < transferableTokens.length; index++) {
            if (transferableTokens[index] == _tokenId) {
                return true;
            }
        }
        return false;
    }

     
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        if (isTransferable(_tokenId)) {
            return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
        }
        return false;
    }

     
    function uintToString(uint v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

     
    function strConcat(string _a, string _b)internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory ba = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        return string(ba);
    }
}

 

 
contract Ownable {
    address public owner;
    address public newOwner;
    
     
    address[] internal controllers;
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() public {
        owner = msg.sender;
    }
   
     
    modifier onlyController() {
        require(isController(msg.sender), "only Controller");
        _;
    }

    modifier onlyOwnerOrController() {
        require(msg.sender == owner || isController(msg.sender), "only Owner Or Controller");
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "sender address must be the owner's address");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "new owner address must not be the owner's address");
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender address must not be the new owner's address");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

    function isController(address _controller) internal view returns(bool) {
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return true;
            }
        }
        return false;
    }

    function getControllers() public onlyOwner view returns(address[]) {
        return controllers;
    }

     
    function addController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        require(_controller != owner, "controller address must not be the owner's address");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return;
            }
        }
        controllers.push(_controller);
    }

     
    function removeController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                delete controllers[index];
            }
        }
    }
}

 

interface ICryptoBeastiesToken {
    function bulk(uint256[] _tokenIds, uint256[] _attributes, address[] _owners) external;
    function create(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds, address _owner) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokens);
    function getProperties(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds); 
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external; 
    function updateStorage(address _storage) external;
    function listTokens() external view returns (uint256[] tokens);
    function setURI(string _uriPrefix) external;
    function setTransferable(uint256 _tokenId) external;
    function removeTransferable(uint256 _tokenId) external;
}

 

 
contract CryptoBeastiesToken is ERC721Token, Ownable, ICryptoBeastiesToken { 
    using SafeMath for uint256;

    address proxyRegistryAddress;

     
    constructor(address _storage, string _uriPrefix) 
        ERC721Token("CryptoBeasties Token", "CRYB", _uriPrefix, _storage) public {
        proxyRegistryAddress = address(0);
    }

     
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwnerOrController {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

     
    function bulk(uint256[] _tokenIds, uint256[] _attributes, address[] _owners) external onlyOwnerOrController {
        for (uint index = 0; index < _tokenIds.length; index++) {
            ownedTokens[_owners[index]].push(_tokenIds[index]);
            tokenOwner[_tokenIds[index]] = _owners[index];
            emit Transfer(address(0), _owners[index], _tokenIds[index]);
        }
        cbStorage.storeBulk(_tokenIds, _attributes);
    }

     
    function create(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds, address _owner) external onlyOwnerOrController {
        require(!super.exists(_tokenId));
        require(_owner != address(0));
        require(_attributes > 0); 
        super._mint(_owner, _tokenId);
        cbStorage.store(_tokenId, _attributes, _componentIds);
    }

    
    function isApprovedForAll(
        address owner,
        address operator
    )
    public
    view
    returns (bool)
    {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (proxyRegistry.proxies(owner) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

     
    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        return ownedTokens[_owner];
    }
    
     
    function getOwnedTokenData(
        address _owner
        ) 
        public 
        view 
        returns 
        (
            uint256[] tokens, 
            uint256[] attrs, 
            uint256[] componentIds, 
            bool[] isTransferable
        ) {

        uint256[] memory tokenIds = this.tokensOfOwner(_owner);
        uint256[] memory attribs = new uint256[](tokenIds.length);
        uint256[] memory firstCompIds = new uint256[](tokenIds.length);
        bool[] memory transferable = new bool[](tokenIds.length);
        
        uint256[] memory compIds;

        for (uint i = 0; i < tokenIds.length; i++) {
            (attribs[i], compIds) = cbStorage.getAttributes(tokenIds[i]);
            transferable[i] = this.isTransferable(tokenIds[i]);
            if (compIds.length > 0)
            {
                firstCompIds[i] = compIds[0];
            }
        }
        return (tokenIds, attribs, firstCompIds, transferable);
    }

     
    function getProperties(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds) {
        return cbStorage.getAttributes(_tokenId);
    }

     
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender));  
        cbStorage.updateAttributes(_tokenId, _attributes, _componentIds);
    }

     
    function updateStorage(address _storage) external  onlyOwnerOrController {
        cbStorage = IEntityStorage(_storage);
    }

     
    function listTokens() external view returns (uint256[] tokens) {
        return cbStorage.list();
    }

     
    function setURI(string _uriPrefix) external onlyOwnerOrController {
        uriPrefix = _uriPrefix;
    }

     
    function bulkTransferable(uint256[] _tokenIds) external {
        address _owner = ownerOf(_tokenIds[0]);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender));  
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_owner == msg.sender) {
                require(ownerOf(_tokenIds[index]) == _owner);  
            } 
            transferableTokens.push(_tokenIds[index]);
        }
    }

     
    function setTransferable(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender));  
        transferableTokens.push(_tokenId);
    }

     
    function bulkRemoveTransferable(uint256[] _tokenIds) external {
        address _owner = ownerOf(_tokenIds[0]);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender));  
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_owner == msg.sender) {
                require(ownerOf(_tokenIds[index]) == _owner);  
            }
            _removeTransfer(_tokenIds[index]);
        }
    }

     
    function removeTransferable(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender));  
        _removeTransfer(_tokenId);
    }

     
    function _removeTransfer(uint256 _tokenId) internal {
        uint256 tokenIndex = 0;
        while (transferableTokens[tokenIndex] != _tokenId && tokenIndex < transferableTokens.length) {
            tokenIndex++;
        }

         
        uint256 lastTokenIndex = transferableTokens.length.sub(1);
        uint256 lastToken = transferableTokens[lastTokenIndex];

        transferableTokens[tokenIndex] = lastToken;
        transferableTokens[lastTokenIndex] = 0;

        transferableTokens.length--;
    }

     
    function mergeTokens(uint256[] _mergeTokenIds, uint256 _targetTokenId, uint256 _targetAttributes) external {
        address _owner = ownerOf(_targetTokenId);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender));  
        require(_mergeTokenIds.length > 0);  
        require(!isTransferable(_targetTokenId));  


         
        for (uint256 index = 0; index < _mergeTokenIds.length; index++) {
            require(ownerOf(_mergeTokenIds[index]) == _owner);  
            _burn(_owner, _mergeTokenIds[index]);
        }

         
        uint256 attribs;
        uint256[] memory compIds;
        (attribs, compIds) = cbStorage.getAttributes(_targetTokenId);
        cbStorage.updateAttributes(_targetTokenId, _targetAttributes, compIds);
    }
}

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}