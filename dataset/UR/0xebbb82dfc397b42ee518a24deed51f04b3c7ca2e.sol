 

pragma solidity ^0.5.6;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 
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

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

library Strings {
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }
    
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
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

 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}
 
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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ProductInventory is MinterRole {
    using SafeMath for uint256;
    using Address for address;
    
    event ProductCreated(
        uint256 id,
        uint256 price,
        uint256 activationPrice,
        uint256 available,
        uint256 supply,
        uint256 interval,
        bool minterOnly
    );
    event ProductAvailabilityChanged(uint256 productId, uint256 available);
    event ProductPriceChanged(uint256 productId, uint256 price);

     
    uint256[] public allProductIds;

     
    mapping (uint256 => Product) public products;

    struct Product {
        uint256 id;
        uint256 price;
        uint256 activationPrice;
        uint256 available;
        uint256 supply;
        uint256 sold;
        uint256 interval;
        bool minterOnly;
    }

    function _productExists(uint256 _productId) internal view returns (bool) {
        return products[_productId].id != 0;
    }

    function _createProduct(
        uint256 _productId,
        uint256 _price,
        uint256 _activationPrice,
        uint256 _initialAvailable,
        uint256 _supply,
        uint256 _interval,
        bool _minterOnly
    )
    internal
    {
        require(_productId != 0);
        require(!_productExists(_productId));
        require(_initialAvailable <= _supply);

        Product memory _product = Product({
            id: _productId,
            price: _price,
            activationPrice: _activationPrice,
            available: _initialAvailable,
            supply: _supply,
            sold: 0,
            interval: _interval,
            minterOnly: _minterOnly
        });

        products[_productId] = _product;
        allProductIds.push(_productId);

        emit ProductCreated(
            _product.id,
            _product.price,
            _product.activationPrice,
            _product.available,
            _product.supply,
            _product.interval,
            _product.minterOnly
        );
    }

    function _incrementAvailability(
        uint256 _productId,
        uint256 _increment)
        internal
    {
        require(_productExists(_productId));
        uint256 newAvailabilityLevel = products[_productId].available.add(_increment);
         
        if(products[_productId].supply != 0) {
            require(products[_productId].sold.add(newAvailabilityLevel) <= products[_productId].supply);
        }
        products[_productId].available = newAvailabilityLevel;
    }

    function _setAvailability(uint256 _productId, uint256 _availability) internal
    {
        require(_productExists(_productId));
        require(_availability >= 0);
        products[_productId].available = _availability;
    }

    function _setPrice(uint256 _productId, uint256 _price) internal
    {
        require(_productExists(_productId));
        products[_productId].price = _price;
    }

    function _setMinterOnly(uint256 _productId, bool _isMinterOnly) internal
    {
        require(_productExists(_productId));
        products[_productId].minterOnly = _isMinterOnly;
    }

    function _purchaseProduct(uint256 _productId) internal {
        require(_productExists(_productId));
        require(products[_productId].available > 0);
        require(products[_productId].available.sub(1) >= 0);
        products[_productId].available = products[_productId].available.sub(1);
        products[_productId].sold = products[_productId].sold.add(1);
    }

     

     
    function createProduct(
        uint256 _productId,
        uint256 _price,
        uint256 _activationPrice,
        uint256 _initialAvailable,
        uint256 _supply,
        uint256 _interval,
        bool _minterOnly
    )
    external
    onlyMinter
    {
        _createProduct(
            _productId,
            _price,
            _activationPrice,
            _initialAvailable,
            _supply,
            _interval,
            _minterOnly);
    }

     
    function incrementAvailability(
        uint256 _productId,
        uint256 _increment)
    external
    onlyMinter
    {
        _incrementAvailability(_productId, _increment);
        emit ProductAvailabilityChanged(_productId, products[_productId].available);
    }

     
    function setAvailability(
        uint256 _productId,
        uint256 _amount)
    external
    onlyMinter
    {
        _setAvailability(_productId, _amount);
        emit ProductAvailabilityChanged(_productId, products[_productId].available);
    }

     
    function setPrice(uint256 _productId, uint256 _price)
    external
    onlyMinter
    {
        _setPrice(_productId, _price);
        emit ProductPriceChanged(_productId, _price);
    }

     
    function setMinterOnly(uint256 _productId, bool _isMinterOnly)
    external
    onlyMinter
    {
        _setMinterOnly(_productId, _isMinterOnly);
    }

     

     
    function totalSold(uint256 _productId) public view returns (uint256) {
        return products[_productId].sold;
    }

     
    function isMinterOnly(uint256 _productId) public view returns (bool) {
        return products[_productId].minterOnly;
    }

     
    function priceOf(uint256 _productId) public view returns (uint256) {
        return products[_productId].price;
    }

     
    function priceOfActivation(uint256 _productId) public view returns (uint256) {
        return products[_productId].activationPrice;
    }

     
    function productInfo(uint256 _productId)
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, bool)
    {
        return (
            products[_productId].price,
            products[_productId].activationPrice,
            products[_productId].available,
            products[_productId].supply,
            products[_productId].interval,
            products[_productId].minterOnly
        );
    }

   
    function getAllProductIds() public view returns (uint256[] memory) {
        return allProductIds;
    }
}

contract IERC721ProductKey is IERC721Enumerable, IERC721Metadata {
    function activate(uint256 _tokenId) public payable;
    function purchase(uint256 _productId, address _beneficiary) public payable returns (uint256);
    function setKeyAttributes(uint256 _keyId, uint256 _attributes) public;
    function keyInfo(uint256 _keyId) external view returns (uint256, uint256, uint256, uint256);
    function isKeyActive(uint256 _keyId) public view returns (bool);
    event KeyIssued(
        address indexed owner,
        address indexed purchaser,
        uint256 keyId,
        uint256 productId,
        uint256 attributes,
        uint256 issuedTime,
        uint256 expirationTime
    );
    event KeyActivated(
        address indexed owner,
        address indexed activator,
        uint256 keyId,
        uint256 productId,
        uint256 attributes,
        uint256 issuedTime,
        uint256 expirationTime
    );
}

contract ERC721ProductKey is IERC721ProductKey, ERC721Enumerable, ReentrancyGuard, ProductInventory {
    using SafeMath for uint256;
    using Address for address;

     
    string private _name;
     
    string private _symbol;
     
    string private _baseMetadataURI;
     
    address payable private _withdrawalWallet;

    event KeyIssued(
        address indexed owner,
        address indexed purchaser,
        uint256 keyId,
        uint256 productId,
        uint256 attributes,
        uint256 issuedTime,
        uint256 expirationTime
    );

    event KeyActivated(
        address indexed owner,
        address indexed activator,
        uint256 keyId,
        uint256 productId,
        uint256 attributes,
        uint256 issuedTime,
        uint256 expirationTime
    );

    struct ProductKey {
        uint256 productId;
        uint256 attributes;
        uint256 issuedTime;
        uint256 expirationTime;
    }
    
     
    mapping (uint256 => ProductKey) public productKeys;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
     

     
    constructor (string memory name, string memory symbol, string memory baseURI, address payable withdrawalWallet) public {
        _name = name;
        _symbol = symbol;
        _baseMetadataURI = baseURI;
        _withdrawalWallet = withdrawalWallet;
         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function withdrawalWallet() public view returns (address payable) {
        return _withdrawalWallet;
    }

     
    function setTokenMetadataBaseURI(string calldata baseURI) external onlyMinter {
        _baseMetadataURI = baseURI;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return Strings.strConcat(
            _baseMetadataURI,
            Strings.uint2str(tokenId));
    }
    
     
    function _activate(uint256 _keyId) internal {
        require(_isApprovedOrOwner(msg.sender, _keyId));
        require(!isKeyActive(_keyId));
        require(productKeys[_keyId].expirationTime == 0);
        uint256 productId = productKeys[_keyId].productId;
         
        productKeys[_keyId].expirationTime = now.add(products[productId].interval);
         
        emit KeyActivated(
            ownerOf(_keyId),
            msg.sender,
            _keyId,
            productId,
            productKeys[_keyId].attributes,
            productKeys[_keyId].issuedTime,
            productKeys[_keyId].expirationTime
        );
    }

    function _createKey(
        uint256 _productId,
        address _beneficiary
    )
    internal
    returns (uint)
    {
        ProductKey memory _productKey = ProductKey({
            productId: _productId,
            attributes: 0,
            issuedTime: now, 
            expirationTime: 0
        });

        uint256 newKeyId = totalSupply();
            
        productKeys[newKeyId] = _productKey;
        emit KeyIssued(
            _beneficiary,
            msg.sender,
            newKeyId,
            _productKey.productId,
            _productKey.attributes,
            _productKey.issuedTime,
            _productKey.expirationTime);
        _mint(_beneficiary, newKeyId);
        return newKeyId;
    }

    function _setKeyAttributes(uint256 _keyId, uint256 _attributes) internal
    {
        productKeys[_keyId].attributes = _attributes;
    }

    function _purchase(
        uint256 _productId,
        address _beneficiary)
    internal returns (uint)
    {
        _purchaseProduct(_productId);
        return _createKey(
            _productId,
            _beneficiary
        );
    }

     

    function withdrawBalance() external onlyMinter {
        _withdrawalWallet.transfer(address(this).balance);
    }

    function minterOnlyPurchase(
        uint256 _productId,
        address _beneficiary
    )
    external
    onlyMinter
    returns (uint256)
    {
        return _purchase(
            _productId,
            _beneficiary
        );
    }

    function setKeyAttributes(
        uint256 _keyId,
        uint256 _attributes
    )
    public
    onlyMinter
    {
        return _setKeyAttributes(
            _keyId,
            _attributes
        );
    }

     

     
    function isKeyActive(uint256 _keyId) public view returns (bool) {
        return productKeys[_keyId].expirationTime > now || products[productKeys[_keyId].productId].interval == 0;
    }

     
    function keyInfo(uint256 _keyId)
    external view returns (uint256, uint256, uint256, uint256)
    {
        return (productKeys[_keyId].productId,
            productKeys[_keyId].attributes,
            productKeys[_keyId].issuedTime,
            productKeys[_keyId].expirationTime
        );
    }

     
    function purchase(
        uint256 _productId,
        address _beneficiary
    )
    public
    payable
    returns (uint256)
    {
        require(_productId != 0);
        require(_beneficiary != address(0));
         
        require(msg.value == priceOf(_productId));
        require(!isMinterOnly(_productId));
        return _purchase(
            _productId,
            _beneficiary
        );
    }

     
    function activate(
        uint256 _tokenId
    )
    public
    payable
    {
        require(ownerOf(_tokenId) != address(0));
         
        require(msg.value == priceOfActivation(_tokenId));
        _activate(_tokenId);

    }
}