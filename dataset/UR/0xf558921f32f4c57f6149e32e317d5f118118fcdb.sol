 

pragma solidity ^0.4.24;

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

 

 
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
    _registerInterface(_InterfaceId_ERC721);
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

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

   
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

 

 
library ERC721Manager {

    using SafeMath for uint256;

     
     
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

    struct ERC721Data {
         
        mapping (bytes4 => bool) supportedInterfaces;

         
        mapping (uint256 => address) tokenOwner;

         
        mapping (uint256 => address) tokenApprovals;

         
        mapping (address => uint256) ownedTokensCount;

         
        mapping (address => mapping (address => bool)) operatorApprovals;


         
        string name_;

         
        string symbol_;

         
        mapping(address => uint256[]) ownedTokens;

         
        mapping(uint256 => uint256) ownedTokensIndex;

         
        uint256[] allTokens;

         
        mapping(uint256 => uint256) allTokensIndex;

         
        mapping(uint256 => string) tokenURIs;
    }

     
     
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;


    bytes4 private constant InterfaceId_ERC165 = 0x01ffc9a7;
     

    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
     

    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
     

    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
     

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
     


    function initialize(ERC721Data storage self, string _name, string _symbol) external {
        self.name_ = _name;
        self.symbol_ = _symbol;

         
        _registerInterface(self, InterfaceId_ERC165);

         
        _registerInterface(self, InterfaceId_ERC721);
        _registerInterface(self, InterfaceId_ERC721Exists);
        _registerInterface(self, InterfaceId_ERC721Enumerable);
        _registerInterface(self, InterfaceId_ERC721Metadata);
    }

    function _registerInterface(ERC721Data storage self, bytes4 _interfaceId) private {
        self.supportedInterfaces[_interfaceId] = true;
    }

    function supportsInterface(ERC721Data storage self, bytes4 _interfaceId) external view returns (bool) {
        return self.supportedInterfaces[_interfaceId];
    }

     
    function balanceOf(ERC721Data storage self, address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return self.ownedTokensCount[_owner];
    }

     
    function ownerOf(ERC721Data storage self, uint256 _tokenId) public view returns (address) {
        address owner = self.tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function exists(ERC721Data storage self, uint256 _tokenId) public view returns (bool) {
        address owner = self.tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(ERC721Data storage self, address _to, uint256 _tokenId) external {
        address owner = ownerOf(self, _tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(self, owner, msg.sender));

        self.tokenApprovals[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

     
    function getApproved(ERC721Data storage self, uint256 _tokenId) public view returns (address) {
        return self.tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(ERC721Data storage self, address _to, bool _approved) external {
        require(_to != msg.sender);
        self.operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

     
    function isApprovedForAll(
        ERC721Data storage self,
        address _owner,
        address _operator
    ) public view returns (bool) {
        return self.operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(
        ERC721Data storage self,
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(isApprovedOrOwner(self, msg.sender, _tokenId));
        require(_from != address(0));
        require(_to != address(0));

        _clearApproval(self, _from, _tokenId);
        _removeTokenFrom(self, _from, _tokenId);
        _addTokenTo(self, _to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(
        ERC721Data storage self,
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
         
        safeTransferFrom(self, _from, _to, _tokenId, "");
    }

     
    function safeTransferFrom(
        ERC721Data storage self,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public {
        transferFrom(self, _from, _to, _tokenId);
         
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

     
    function _clearApproval(ERC721Data storage self, address _owner, uint256 _tokenId) internal {
        require(ownerOf(self, _tokenId) == _owner);
        if (self.tokenApprovals[_tokenId] != address(0)) {
            self.tokenApprovals[_tokenId] = address(0);
        }
    }

     
    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

     
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }


     
    function name(ERC721Data storage self) external view returns (string) {
        return self.name_;
    }

     
    function symbol(ERC721Data storage self) external view returns (string) {
        return self.symbol_;
    }

     
    function tokenURI(ERC721Data storage self, uint256 _tokenId) external view returns (string) {
        require(exists(self, _tokenId));
        return self.tokenURIs[_tokenId];
    }

     
    function tokenOfOwnerByIndex(
        ERC721Data storage self,
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        require(_index < balanceOf(self, _owner));
        return self.ownedTokens[_owner][_index];
    }

     
    function totalSupply(ERC721Data storage self) external view returns (uint256) {
        return self.allTokens.length;
    }

     
    function tokenByIndex(ERC721Data storage self, uint256 _index) external view returns (uint256) {
        require(_index < self.allTokens.length);
        return self.allTokens[_index];
    }

     
    function setTokenURI(ERC721Data storage self, uint256 _tokenId, string _uri) external {
        require(exists(self, _tokenId));
        self.tokenURIs[_tokenId] = _uri;
    }

     
    function _addTokenTo(ERC721Data storage self, address _to, uint256 _tokenId) internal {
        require(self.tokenOwner[_tokenId] == address(0));
        self.tokenOwner[_tokenId] = _to;
        self.ownedTokensCount[_to] = self.ownedTokensCount[_to].add(1);

        uint256 length = self.ownedTokens[_to].length;
        self.ownedTokens[_to].push(_tokenId);
        self.ownedTokensIndex[_tokenId] = length;
    }

     
    function _removeTokenFrom(ERC721Data storage self, address _from, uint256 _tokenId) internal {
        require(ownerOf(self, _tokenId) == _from);
        self.ownedTokensCount[_from] = self.ownedTokensCount[_from].sub(1);
        self.tokenOwner[_tokenId] = address(0);

         
         
        uint256 tokenIndex = self.ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = self.ownedTokens[_from].length.sub(1);
        uint256 lastToken = self.ownedTokens[_from][lastTokenIndex];

        self.ownedTokens[_from][tokenIndex] = lastToken;
        self.ownedTokens[_from].length--;
         

         
         
         

        self.ownedTokensIndex[_tokenId] = 0;
        self.ownedTokensIndex[lastToken] = tokenIndex;
    }

     
    function mint(ERC721Data storage self, address _to, uint256 _tokenId) external {
        require(_to != address(0));
        _addTokenTo(self, _to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);

        self.allTokensIndex[_tokenId] = self.allTokens.length;
        self.allTokens.push(_tokenId);
    }

     
    function burn(ERC721Data storage self, address _owner, uint256 _tokenId) external {
        _clearApproval(self, _owner, _tokenId);
        _removeTokenFrom(self, _owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);

         
        if (bytes(self.tokenURIs[_tokenId]).length != 0) {
            delete self.tokenURIs[_tokenId];
        }

         
        uint256 tokenIndex = self.allTokensIndex[_tokenId];
        uint256 lastTokenIndex = self.allTokens.length.sub(1);
        uint256 lastToken = self.allTokens[lastTokenIndex];

        self.allTokens[tokenIndex] = lastToken;
        self.allTokens[lastTokenIndex] = 0;

        self.allTokens.length--;
        self.allTokensIndex[_tokenId] = 0;
        self.allTokensIndex[lastToken] = tokenIndex;
    }

     
    function isApprovedOrOwner(
        ERC721Data storage self,
        address _spender,
        uint256 _tokenId
    ) public view returns (bool) {
        address owner = ownerOf(self, _tokenId);
         
         
         
        return (
            _spender == owner
            || getApproved(self, _tokenId) == _spender
            || isApprovedForAll(self, owner, _spender)
        );
    }

}

 

 
contract ERC721Token is ERC165, ERC721 {

    ERC721Manager.ERC721Data internal erc721Data;

     
     
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


    constructor(string _name, string _symbol) public {
        ERC721Manager.initialize(erc721Data, _name, _symbol);
    }

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return ERC721Manager.supportsInterface(erc721Data, _interfaceId);
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ERC721Manager.balanceOf(erc721Data, _owner);
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return ERC721Manager.ownerOf(erc721Data, _tokenId);
    }

    function exists(uint256 _tokenId) public view returns (bool _exists) {
        return ERC721Manager.exists(erc721Data, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        ERC721Manager.approve(erc721Data, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address _operator) {
        return ERC721Manager.getApproved(erc721Data, _tokenId);
    }

    function setApprovalForAll(address _to, bool _approved) public {
        ERC721Manager.setApprovalForAll(erc721Data, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return ERC721Manager.isApprovedForAll(erc721Data, _owner, _operator);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        ERC721Manager.transferFrom(erc721Data, _from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        ERC721Manager.safeTransferFrom(erc721Data, _from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public {
        ERC721Manager.safeTransferFrom(erc721Data, _from, _to, _tokenId, _data);
    }


    function totalSupply() public view returns (uint256) {
        return ERC721Manager.totalSupply(erc721Data);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
        return ERC721Manager.tokenOfOwnerByIndex(erc721Data, _owner, _index);
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        return ERC721Manager.tokenByIndex(erc721Data, _index);
    }

    function name() external view returns (string _name) {
        return erc721Data.name_;
    }

    function symbol() external view returns (string _symbol) {
        return erc721Data.symbol_;
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        return ERC721Manager.tokenURI(erc721Data, _tokenId);
    }


    function _mint(address _to, uint256 _tokenId) internal {
        ERC721Manager.mint(erc721Data, _to, _tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        ERC721Manager.burn(erc721Data, _owner, _tokenId);
    }

    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        ERC721Manager.setTokenURI(erc721Data, _tokenId, _uri);
    }

    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    ) public view returns (bool) {
        return ERC721Manager.isApprovedOrOwner(erc721Data, _spender, _tokenId);
    }
}

 

 
library PRNG {

    struct Data {
        uint64 s0;
        uint64 s1;
    }

    function next(Data storage self) external returns (uint64) {
        uint64 x = self.s0;
        uint64 y = self.s1;

        self.s0 = y;
        x ^= x << 23;  
        self.s1 = x ^ y ^ (x >> 17) ^ (y >> 26);  
        return self.s1 + y;
    }
}

 

 
library EnumerableSetAddress {

    struct Data {
        address[] elements;
        mapping(address => uint160) elementToIndex;
    }

     
    function contains(Data storage self, address value) external view returns (bool) {
        uint160 mappingIndex = self.elementToIndex[value];
        return (mappingIndex < self.elements.length) && (self.elements[mappingIndex] == value);
    }

     
    function add(Data storage self, address value) external {
        uint160 mappingIndex = self.elementToIndex[value];
        require(!((mappingIndex < self.elements.length) && (self.elements[mappingIndex] == value)));

        self.elementToIndex[value] = uint160(self.elements.length);
        self.elements.push(value);
    }

     
    function remove(Data storage self, address value) external {
        uint160 currentElementIndex = self.elementToIndex[value];
        require((currentElementIndex < self.elements.length) && (self.elements[currentElementIndex] == value));

        uint160 lastElementIndex = uint160(self.elements.length - 1);
        address lastElement = self.elements[lastElementIndex];

        self.elements[currentElementIndex] = lastElement;
        self.elements[lastElementIndex] = 0;
        self.elements.length--;

        self.elementToIndex[lastElement] = currentElementIndex;
        self.elementToIndex[value] = 0;
    }

     
    function size(Data storage self) external view returns (uint160) {
        return uint160(self.elements.length);
    }

     
    function get(Data storage self, uint160 index) external view returns (address) {
        return self.elements[index];
    }

     
    function clear(Data storage self) external {
        self.elements.length = 0;
    }

     
    function copy(Data storage source, Data storage target) external {
        uint160 numElements = uint160(source.elements.length);

        target.elements.length = numElements;
        for (uint160 index = 0; index < numElements; index++) {
            address element = source.elements[index];
            target.elements[index] = element;
            target.elementToIndex[element] = index;
        }
    }

     
    function addAll(Data storage self, Data storage other) external {
        uint160 numElements = uint160(other.elements.length);

        for (uint160 index = 0; index < numElements; index++) {
            address value = other.elements[index];

            uint160 mappingIndex = self.elementToIndex[value];
            if (!((mappingIndex < self.elements.length) && (self.elements[mappingIndex] == value))) {
                self.elementToIndex[value] = uint160(self.elements.length);
                self.elements.push(value);
            }
        }
    }

}

 

 
library EnumerableSet256 {

    struct Data {
        uint256[] elements;
        mapping(uint256 => uint256) elementToIndex;
    }

     
    function contains(Data storage self, uint256 value) external view returns (bool) {
        uint256 mappingIndex = self.elementToIndex[value];
        return (mappingIndex < self.elements.length) && (self.elements[mappingIndex] == value);
    }

     
    function add(Data storage self, uint256 value) external {
        uint256 mappingIndex = self.elementToIndex[value];
        require(!((mappingIndex < self.elements.length) && (self.elements[mappingIndex] == value)));

        self.elementToIndex[value] = uint256(self.elements.length);
        self.elements.push(value);
    }

     
    function remove(Data storage self, uint256 value) external {
        uint256 currentElementIndex = self.elementToIndex[value];
        require((currentElementIndex < self.elements.length) && (self.elements[currentElementIndex] == value));

        uint256 lastElementIndex = uint256(self.elements.length - 1);
        uint256 lastElement = self.elements[lastElementIndex];

        self.elements[currentElementIndex] = lastElement;
        self.elements[lastElementIndex] = 0;
        self.elements.length--;

        self.elementToIndex[lastElement] = currentElementIndex;
        self.elementToIndex[value] = 0;
    }

     
    function size(Data storage self) external view returns (uint256) {
        return uint256(self.elements.length);
    }

     
    function get(Data storage self, uint256 index) external view returns (uint256) {
        return self.elements[index];
    }

     
    function clear(Data storage self) external {
        self.elements.length = 0;
    }
}

 

 
library URIDistribution {

    struct Data {
        uint16[] cumulativeWeights;
        mapping(uint16 => string) uris;
    }

     
    function addURI(Data storage self, uint16 weight, string uri) external {
        if (weight == 0) return;

        if (self.cumulativeWeights.length == 0) {
            self.cumulativeWeights.push(weight);
        } else {
            self.cumulativeWeights.push(self.cumulativeWeights[uint16(self.cumulativeWeights.length - 1)] + weight);
        }
        self.uris[uint16(self.cumulativeWeights.length - 1)] = uri;
    }

     
    function getURI(Data storage self, uint64 seed) external view returns (string) {
        uint16 n = uint16(self.cumulativeWeights.length);
        uint16 modSeed = uint16(seed % uint64(self.cumulativeWeights[n - 1]));

        uint16 left = 0;
        uint16 right = n;
        uint16 mid;

        while (left < right) {
            mid = uint16((uint24(left) + uint24(right)) / 2);
            if (self.cumulativeWeights[mid] <= modSeed) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        return self.uris[left];
    }
}

 

 
library GameDataLib {

     

    struct Butterfly {
         
        uint64 gene;

         
        uint64 createdTimestamp;

         
        uint64 lastTimestamp;

         
        EnumerableSetAddress.Data previousAddresses;
    }

    struct Heart {
         
        uint256 butterflyId;

         
        uint64 snapshotTimestamp;

         
        EnumerableSetAddress.Data previousAddresses;
    }

    struct Flower {
         
        bool isClaimed;

         
        uint64 gene;

         
        uint64 gardenTimezone;

         
        uint64 createdTimestamp;

         
        uint160 flowerIndex;
    }

    struct URIMappingData {
        URIDistribution.Data flowerURIs;
        string whiteFlowerURI;

        URIDistribution.Data butterflyLiveURIs;
        URIDistribution.Data butterflyDeadURIs;
        URIDistribution.Data heartURIs;
    }

     
    enum TokenType {
        Butterfly,
        Heart
    }

    struct Data {
         
        PRNG.Data seed;

         
        uint256 nextId;

         
        mapping (uint256 => TokenType) tokenToType;
        mapping (uint8 => mapping (address => EnumerableSet256.Data)) typedOwnedTokens;
        mapping (uint8 => EnumerableSet256.Data) typedTokens;

         
        mapping (uint256 => Butterfly) butterflyData;
        mapping (uint256 => Heart) heartData;

         
        mapping (address => Flower) flowerData;
        address[] claimedFlowers;

         
        URIMappingData uriMappingData;
    }

     

     
    function getButterflyInfo(
        Data storage self,
        uint256 butterflyId
    ) external view returns (
        uint64 gene,
        uint64 createdTimestamp,
        uint64 lastTimestamp,
        uint160 numOwners
    ) {
        Butterfly storage butterfly = self.butterflyData[butterflyId];
        require(butterfly.createdTimestamp != 0);

        gene = butterfly.gene;
        createdTimestamp = butterfly.createdTimestamp;
        lastTimestamp = butterfly.lastTimestamp;
        numOwners = uint160(butterfly.previousAddresses.elements.length);
    }

     
    function getHeartInfo(
        Data storage self,
        uint256 heartId
    ) external view returns (
        uint256 butterflyId,
        uint64 gene,
        uint64 snapshotTimestamp,
        uint160 numOwners
    ) {
        Heart storage heart = self.heartData[heartId];
        require(heart.snapshotTimestamp != 0);

        butterflyId = heart.butterflyId;
        gene = self.butterflyData[butterflyId].gene;
        snapshotTimestamp = heart.snapshotTimestamp;
        numOwners = uint160(heart.previousAddresses.elements.length);
    }

     
    function getFlowerInfo(
        Data storage self,
        address flowerAddress
    ) external view returns (
        bool isClaimed,
        uint64 gene,
        uint64 gardenTimezone,
        uint64 createdTimestamp,
        uint160 flowerIndex
    ) {
        Flower storage flower = self.flowerData[flowerAddress];

        isClaimed = flower.isClaimed;
        if (isClaimed) {
            gene = flower.gene;
            gardenTimezone = flower.gardenTimezone;
            createdTimestamp = flower.createdTimestamp;
            flowerIndex = flower.flowerIndex;
        }
    }

     
    function getButterflyOwnerByIndex(
        Data storage self,
        uint256 butterflyId,
        uint160 index
    ) external view returns (address) {
        Butterfly storage butterfly = self.butterflyData[butterflyId];
        require(butterfly.createdTimestamp != 0);

        return butterfly.previousAddresses.elements[index];
    }

     
    function getHeartOwnerByIndex(
        Data storage self,
        uint256 heartId,
        uint160 index
    ) external view returns (address) {
        Heart storage heart = self.heartData[heartId];
        require(heart.snapshotTimestamp != 0);

        return heart.previousAddresses.elements[index];
    }

     
    function canReceiveButterfly(
        Data storage self,
        uint256 butterflyId,
        address receiver,
        uint64 currentTimestamp
    ) public view returns (bool) {
        Butterfly storage butterfly = self.butterflyData[butterflyId];

         
        if (butterfly.createdTimestamp == 0)
            return false;

         
        if (receiver == address(0x0))
            return true;

         
        if (currentTimestamp < butterfly.lastTimestamp || currentTimestamp - butterfly.lastTimestamp > 1 days)
            return false;

         
        Flower storage flower = self.flowerData[receiver];
        if (!flower.isClaimed) return false;

         
        return !EnumerableSetAddress.contains(butterfly.previousAddresses, receiver);
    }


     

     
    function claim(
        Data storage self,
        address claimer,
        uint64 gardenTimezone,
        uint64 currentTimestamp
    ) external returns (uint256 butterflyId) {
        Flower storage flower = self.flowerData[claimer];

         
        require(!flower.isClaimed);
         
        require(self.nextId + 1 != 0);

         
        butterflyId = self.nextId;
         
        Butterfly storage butterfly = self.butterflyData[butterflyId];
        require(butterfly.createdTimestamp == 0);
         
        self.nextId++;

         
        flower.isClaimed = true;
        flower.gardenTimezone = gardenTimezone;
        flower.createdTimestamp = currentTimestamp;
        flower.gene = PRNG.next(self.seed);
        flower.flowerIndex = uint160(self.claimedFlowers.length);

         
        butterfly.gene = PRNG.next(self.seed);
        butterfly.createdTimestamp = currentTimestamp;
        butterfly.lastTimestamp = currentTimestamp;
        EnumerableSetAddress.add(butterfly.previousAddresses, claimer);

         
        self.tokenToType[butterflyId] = TokenType.Butterfly;

         
        EnumerableSet256.add(self.typedOwnedTokens[uint8(TokenType.Butterfly)][claimer], butterflyId);
        EnumerableSet256.add(self.typedTokens[uint8(TokenType.Butterfly)], butterflyId);

         
        self.claimedFlowers.push(claimer);
    }

     
    function transferButterfly(
        Data storage self,
        uint256 butterflyId,
        address sender,
        address receiver,
        uint64 currentTimestamp
    ) external returns (uint256 heartId) {
         
        require(canReceiveButterfly(self, butterflyId, receiver, currentTimestamp));

         
        require(self.nextId + 1 != 0);
         
        heartId = self.nextId;
         
        Heart storage heart = self.heartData[heartId];
        require(heart.snapshotTimestamp == 0);
         
        self.nextId++;

         
        heart.butterflyId = butterflyId;
        heart.snapshotTimestamp = currentTimestamp;
        Butterfly storage butterfly = self.butterflyData[butterflyId];

         
        self.tokenToType[heartId] = TokenType.Heart;

         
        butterfly.lastTimestamp = currentTimestamp;
        EnumerableSetAddress.add(butterfly.previousAddresses, receiver);

         
        EnumerableSetAddress.copy(butterfly.previousAddresses, heart.previousAddresses);

         
        EnumerableSet256.remove(self.typedOwnedTokens[uint8(TokenType.Butterfly)][sender], butterflyId);
        EnumerableSet256.add(self.typedOwnedTokens[uint8(TokenType.Butterfly)][receiver], butterflyId);

         
        EnumerableSet256.add(self.typedOwnedTokens[uint8(TokenType.Heart)][sender], heartId);
        EnumerableSet256.add(self.typedTokens[uint8(TokenType.Heart)], heartId);
    }

     
    function transferHeart(
        Data storage self,
        uint256 heartId,
        address sender,
        address receiver
    ) external {
         
        EnumerableSet256.remove(self.typedOwnedTokens[uint8(TokenType.Heart)][sender], heartId);
        EnumerableSet256.add(self.typedOwnedTokens[uint8(TokenType.Heart)][receiver], heartId);
    }

     
    function typedBalanceOf(Data storage self, uint8 tokenType, address _owner) public view returns (uint256) {
        return self.typedOwnedTokens[tokenType][_owner].elements.length;
    }

     
    function typedTotalSupply(Data storage self, uint8 tokenType) public view returns (uint256) {
        return self.typedTokens[tokenType].elements.length;
    }


     
    function typedTokenOfOwnerByIndex(
        Data storage self,
        uint8 tokenType,
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        return self.typedOwnedTokens[tokenType][_owner].elements[_index];
    }

     
    function typedTokenByIndex(
        Data storage self,
        uint8 tokenType,
        uint256 _index
    ) external view returns (uint256) {
        return self.typedTokens[tokenType].elements[_index];
    }

     
    function totalFlowers(Data storage self) external view returns (uint160) {
        return uint160(self.claimedFlowers.length);
    }

     
    function getFlowerByIndex(Data storage self, uint160 index) external view returns (address) {
        return self.claimedFlowers[index];
    }

     

     
    function addFlowerURI(Data storage self, uint16 weight, string uri) external {
        URIDistribution.addURI(self.uriMappingData.flowerURIs, weight, uri);
    }

     
    function setWhiteFlowerURI(Data storage self, string uri) external {
        self.uriMappingData.whiteFlowerURI = uri;
    }

     
    function getWhiteFlowerURI(Data storage self) external view returns (string) {
        return self.uriMappingData.whiteFlowerURI;
    }

     
    function addButterflyURI(Data storage self, uint16 weight, string liveUri, string deadUri, string heartUri) external {
        URIDistribution.addURI(self.uriMappingData.butterflyLiveURIs, weight, liveUri);
        URIDistribution.addURI(self.uriMappingData.butterflyDeadURIs, weight, deadUri);
        URIDistribution.addURI(self.uriMappingData.heartURIs, weight, heartUri);
    }

     
    function getFlowerURI(Data storage self, address flowerAddress) external view returns (string) {
        Flower storage flower = self.flowerData[flowerAddress];
        require(flower.isClaimed);
        return URIDistribution.getURI(self.uriMappingData.flowerURIs, flower.gene);
    }

     
    function getButterflyURI(
        Data storage self,
        ERC721Manager.ERC721Data storage erc721Data,
        uint256 butterflyId,
        uint64 currentTimestamp
    ) external view returns (string) {
        Butterfly storage butterfly = self.butterflyData[butterflyId];
        require(butterfly.createdTimestamp != 0);

        if (erc721Data.tokenOwner[butterflyId] == 0
            || currentTimestamp < butterfly.lastTimestamp
            || currentTimestamp - butterfly.lastTimestamp > 1 days) {
            return URIDistribution.getURI(self.uriMappingData.butterflyDeadURIs, butterfly.gene);
        }
        return URIDistribution.getURI(self.uriMappingData.butterflyLiveURIs, butterfly.gene);
    }

     
    function getButterflyURIFromGene(
        Data storage self,
        uint64 gene,
        bool isAlive
    ) external view returns (string) {
        if (isAlive) {
            return URIDistribution.getURI(self.uriMappingData.butterflyLiveURIs, gene);
        }
        return URIDistribution.getURI(self.uriMappingData.butterflyDeadURIs, gene);
    }

     
    function getHeartURI(Data storage self, uint256 heartId) external view returns (string) {
        Heart storage heart = self.heartData[heartId];
        require(heart.snapshotTimestamp != 0);

        uint64 gene = self.butterflyData[heart.butterflyId].gene;
        return URIDistribution.getURI(self.uriMappingData.heartURIs, gene);
    }

}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 

 
contract Main is ERC721Token, Ownable {

    GameDataLib.Data internal data;

     
    constructor() ERC721Token("LittleButterfly", "BFLY") public {
         
        data.seed.s0 = uint64(now);
        data.seed.s1 = uint64(msg.sender);
    }


     


     
    function getButterflyInfo(uint256 butterflyId) public view returns (
        uint64 gene,
        uint64 createdTimestamp,
        uint64 lastTimestamp,
        uint160 numOwners
    ) {
       (gene, createdTimestamp, lastTimestamp, numOwners) = GameDataLib.getButterflyInfo(data, butterflyId);
    }

     
    function getButterflyOwnerByIndex(
        uint256 butterflyId,
        uint160 index
    ) external view returns (address) {
        return GameDataLib.getButterflyOwnerByIndex(data, butterflyId, index);
    }


     
    function getHeartInfo(uint256 heartId) public view returns (
        uint256 butterflyId,
        uint64 gene,
        uint64 snapshotTimestamp,
        uint160 numOwners
    ) {
        (butterflyId, gene, snapshotTimestamp, numOwners) = GameDataLib.getHeartInfo(data, heartId);
    }

     
    function getHeartOwnerByIndex(
        uint256 heartId,
        uint160 index
    ) external view returns (address) {
        return GameDataLib.getHeartOwnerByIndex(data, heartId, index);
    }


     
    function getFlowerInfo(
        address flowerAddress
    ) external view returns (
        bool isClaimed,
        uint64 gene,
        uint64 gardenTimezone,
        uint64 createdTimestamp,
        uint160 flowerIndex
    ) {
        (isClaimed, gene, gardenTimezone, createdTimestamp, flowerIndex) = GameDataLib.getFlowerInfo(data, flowerAddress);
    }


     
    function canReceiveButterfly(
        uint256 butterflyId,
        address receiver
    ) external view returns (bool) {
        return GameDataLib.canReceiveButterfly(data, butterflyId, receiver, uint64(now));
    }


     

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _setupTransferFrom(_from, _to, _tokenId, uint64(now));
        ERC721Manager.transferFrom(erc721Data, _from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        _setupTransferFrom(_from, _to, _tokenId, uint64(now));
        ERC721Manager.safeTransferFrom(erc721Data, _from, _to, _tokenId);
    }

     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public {
        _setupTransferFrom(_from, _to, _tokenId, uint64(now));
        ERC721Manager.safeTransferFrom(erc721Data, _from, _to, _tokenId, _data);
    }


     
    function _setupTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint64 currentTimestamp
    ) private {
        if (data.tokenToType[tokenId] == GameDataLib.TokenType.Butterfly) {
             
            uint256 heartId = GameDataLib.transferButterfly(data, tokenId, from, to, currentTimestamp);
            ERC721Manager.mint(erc721Data, from, heartId);
        } else {
            GameDataLib.transferHeart(data, tokenId, from, to);
        }
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        if (data.tokenToType[_tokenId] == GameDataLib.TokenType.Heart) {
            return GameDataLib.getHeartURI(data, _tokenId);
        }
        return GameDataLib.getButterflyURI(data, erc721Data, _tokenId, uint64(now));
    }

     
    function accountURI(address accountAddress) public view returns (string) {
        return GameDataLib.getFlowerURI(data, accountAddress);
    }

     
    function accountZeroURI() public view returns (string) {
        return GameDataLib.getWhiteFlowerURI(data);
    }

     
    function getButterflyURIFromGene(uint64 gene, bool isAlive) public view returns (string) {
        return GameDataLib.getButterflyURIFromGene(data, gene, isAlive);
    }


     

     
    function claim(uint64 gardenTimezone) external {
        address claimer = msg.sender;

         
        uint256 butterflyId = GameDataLib.claim(data, claimer, gardenTimezone, uint64(now));

         
        ERC721Manager.mint(erc721Data, claimer, butterflyId);
    }

     
    function burn(uint256 _tokenId) public {
        require(ERC721Manager.isApprovedOrOwner(erc721Data, msg.sender, _tokenId));

        address _owner = ERC721Manager.ownerOf(erc721Data, _tokenId);

        _setupTransferFrom(_owner, address(0x0), _tokenId, uint64(now));
        ERC721Manager.burn(erc721Data, _owner, _tokenId);
    }



     
    function typedBalanceOf(uint8 tokenType, address _owner) public view returns (uint256) {
        return GameDataLib.typedBalanceOf(data, tokenType, _owner);
    }

     
    function typedTotalSupply(uint8 tokenType) public view returns (uint256) {
        return GameDataLib.typedTotalSupply(data, tokenType);
    }


     
    function typedTokenOfOwnerByIndex(
        uint8 tokenType,
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        return GameDataLib.typedTokenOfOwnerByIndex(data, tokenType, _owner, _index);
    }

     
    function typedTokenByIndex(
        uint8 tokenType,
        uint256 _index
    ) external view returns (uint256) {
        return GameDataLib.typedTokenByIndex(data, tokenType, _index);
    }

     
    function totalFlowers() external view returns (uint160) {
        return GameDataLib.totalFlowers(data);
    }

     
    function getFlowerByIndex(uint160 index) external view returns (address) {
        return GameDataLib.getFlowerByIndex(data, index);
    }


     

     

     
    function addFlowerURI(uint16 weight, string uri) external onlyOwner {
        GameDataLib.addFlowerURI(data, weight, uri);
    }

     
    function setWhiteFlowerURI(string uri) external onlyOwner {
        GameDataLib.setWhiteFlowerURI(data, uri);
    }

     
    function addButterflyURI(uint16 weight, string liveUri, string deadUri, string heartUri) external onlyOwner {
        GameDataLib.addButterflyURI(data, weight, liveUri, deadUri, heartUri);
    }

}