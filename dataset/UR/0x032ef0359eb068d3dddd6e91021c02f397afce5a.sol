 

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

 
 
 
 
 
 
 
 
 


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


 
 
 
contract Admined is Owned {

    mapping (address => bool) public admins;

    event AdminAdded(address addr);
    event AdminRemoved(address addr);

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address addr) public constant returns (bool) {
        return (admins[addr] || owner == addr);
    }
    function addAdmin(address addr) public onlyOwner {
        require(!admins[addr] && addr != owner);
        admins[addr] = true;
        AdminAdded(addr);
    }
    function removeAdmin(address addr) public onlyOwner {
        require(admins[addr]);
        delete admins[addr];
        AdminRemoved(addr);
    }
}


 
 
 
contract DeveryRegistry is Admined {

    struct App {
        address appAccount;
        string appName;
        address feeAccount;
        uint fee;
        bool active;
    }
    struct Brand {
        address brandAccount;
        address appAccount;
        string brandName;
        bool active;
    }
    struct Product {
        address productAccount;
        address brandAccount;
        string description;
        string details;
        uint year;
        string origin;
        bool active;
    }

    ERC20Interface public token;
    address public feeAccount;
    uint public fee;
    mapping(address => App) public apps;
    mapping(address => Brand) public brands;
    mapping(address => Product) public products;
    mapping(address => mapping(address => bool)) permissions;
    mapping(bytes32 => address) markings;
    address[] public appAccounts;
    address[] public brandAccounts;
    address[] public productAccounts;

    event TokenUpdated(address indexed oldToken, address indexed newToken);
    event FeeUpdated(address indexed oldFeeAccount, address indexed newFeeAccount, uint oldFee, uint newFee);
    event AppAdded(address indexed appAccount, string appName, address feeAccount, uint fee, bool active);
    event AppUpdated(address indexed appAccount, string appName, address feeAccount, uint fee, bool active);
    event BrandAdded(address indexed brandAccount, address indexed appAccount, string brandName, bool active);
    event BrandUpdated(address indexed brandAccount, address indexed appAccount, string brandName, bool active);
    event ProductAdded(address indexed productAccount, address indexed brandAccount, address indexed appAccount, string description, bool active);
    event ProductUpdated(address indexed productAccount, address indexed brandAccount, address indexed appAccount, string description, bool active);
    event Permissioned(address indexed marker, address indexed brandAccount, bool permission);
    event Marked(address indexed marker, address indexed productAccount, address appFeeAccount, address feeAccount, uint appFee, uint fee, bytes32 itemHash);


     
     
     
    function setToken(address _token) public onlyAdmin {
        TokenUpdated(address(token), _token);
        token = ERC20Interface(_token);
    }
    function setFee(address _feeAccount, uint _fee) public onlyAdmin {
        FeeUpdated(feeAccount, _feeAccount, fee, _fee);
        feeAccount = _feeAccount;
        fee = _fee;
    }

     
     
     
    function addApp(string appName, address _feeAccount, uint _fee) public {
        App storage e = apps[msg.sender];
        require(e.appAccount == address(0));
        apps[msg.sender] = App({
            appAccount: msg.sender,
            appName: appName,
            feeAccount: _feeAccount,
            fee: _fee,
            active: true
        });
        appAccounts.push(msg.sender);
        AppAdded(msg.sender, appName, _feeAccount, _fee, true);
    }
    function updateApp(string appName, address _feeAccount, uint _fee, bool active) public {
        App storage e = apps[msg.sender];
        require(msg.sender == e.appAccount);
        e.appName = appName;
        e.feeAccount = _feeAccount;
        e.fee = _fee;
        e.active = active;
        AppUpdated(msg.sender, appName, _feeAccount, _fee, active);
    }
    function getApp(address appAccount) public constant returns (App app) {
        app = apps[appAccount];
    }
    function getAppData(address appAccount) public constant returns (address _feeAccount, uint _fee, bool active) {
        App storage e = apps[appAccount];
        _feeAccount = e.feeAccount;
        _fee = e.fee;
        active = e.active;
    }
    function appAccountsLength() public constant returns (uint) {
        return appAccounts.length;
    }

     
     
     
    function addBrand(address brandAccount, string brandName) public {
        App storage app = apps[msg.sender];
        require(app.appAccount != address(0));
        Brand storage brand = brands[brandAccount];
        require(brand.brandAccount == address(0));
        brands[brandAccount] = Brand({
            brandAccount: brandAccount,
            appAccount: msg.sender,
            brandName: brandName,
            active: true
        });
        brandAccounts.push(brandAccount);
        BrandAdded(brandAccount, msg.sender, brandName, true);
    }
    function updateBrand(address brandAccount, string brandName, bool active) public {
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount == msg.sender);
        brand.brandName = brandName;
        brand.active = active;

        BrandUpdated(brandAccount, msg.sender, brandName, active);
    }
    function getBrand(address brandAccount) public constant returns (Brand brand) {
        brand = brands[brandAccount];
    }
    function getBrandData(address brandAccount) public constant returns (address appAccount, address appFeeAccount, bool active) {
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        appAccount = app.appAccount;
        appFeeAccount = app.feeAccount;
        active = app.active && brand.active;
    }
    function brandAccountsLength() public constant returns (uint) {
        return brandAccounts.length;
    }

     
     
     
    function addProduct(address productAccount, string description, string details, uint year, string origin) public {
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        Product storage product = products[productAccount];
        require(product.productAccount == address(0));
        products[productAccount] = Product({
            productAccount: productAccount,
            brandAccount: msg.sender,
            description: description,
            details: details,
            year: year,
            origin: origin,
            active: true
        });
        productAccounts.push(productAccount);
        ProductAdded(productAccount, msg.sender, app.appAccount, description, true);
    }
    function updateProduct(address productAccount, string description, string details, uint year, string origin, bool active) public {
        Product storage product = products[productAccount];
        require(product.brandAccount == msg.sender);
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount == msg.sender);
        App storage app = apps[brand.appAccount];
        product.description = description;
        product.details = details;
        product.year = year;
        product.origin = origin;
        product.active = active;
        ProductUpdated(productAccount, product.brandAccount, app.appAccount, description, active);
    }
    function getProduct(address productAccount) public constant returns (Product product) {
        product = products[productAccount];
    }
    function getProductData(address productAccount) public constant returns (address brandAccount, address appAccount, address appFeeAccount, bool active) {
        Product storage product = products[productAccount];
        require(product.brandAccount != address(0));
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        brandAccount = product.brandAccount;
        appAccount = app.appAccount;
        appFeeAccount = app.feeAccount;
        active = app.active && brand.active && brand.active;
    }
    function productAccountsLength() public constant returns (uint) {
        return productAccounts.length;
    }

     
     
     
    function permissionMarker(address marker, bool permission) public {
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount != address(0));
        permissions[marker][msg.sender] = permission;
        Permissioned(marker, msg.sender, permission);
    }

     
     
     
    function addressHash(address item) public pure returns (bytes32 hash) {
        hash = keccak256(item);
    }

     
     
     
    function mark(address productAccount, bytes32 itemHash) public {
        Product storage product = products[productAccount];
        require(product.brandAccount != address(0) && product.active);
        Brand storage brand = brands[product.brandAccount];
        require(brand.brandAccount != address(0) && brand.active);
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0) && app.active);
        bool permissioned = permissions[msg.sender][brand.brandAccount];
        require(permissioned);
        markings[itemHash] = productAccount;
        Marked(msg.sender, productAccount, app.feeAccount, feeAccount, app.fee, fee, itemHash);
        if (app.fee > 0) {
            token.transferFrom(brand.brandAccount, app.feeAccount, app.fee);
        }
        if (fee > 0) {
            token.transferFrom(brand.brandAccount, feeAccount, fee);
        }
    }

     
     
     
    function check(address item) public constant returns (address productAccount, address brandAccount, address appAccount) {
        bytes32 hash = keccak256(item);
        productAccount = markings[hash];
         
        Product storage product = products[productAccount];
         
        Brand storage brand = brands[product.brandAccount];
         
        brandAccount = product.brandAccount;
        appAccount = brand.appAccount;
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






 
contract ERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_InterfaceId_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns (bytes4);
}


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
contract IERC721Enumerable {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
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

 
contract ERC721 is ERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
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


 
contract DeveryERC721Token is ERC721Enumerable,Admined {


    address[] public tokenIdToProduct;
    mapping(address => uint) public totalAllowedProducts;
    mapping(address => uint) public totalMintedProducts;
    DeveryRegistry deveryRegistry;
    ERC20Interface public token;
    
    event TokenUpdated(address indexed oldToken, address indexed newToken);


    function setToken(address _token) public onlyAdmin {
        TokenUpdated(address(token), _token);
        token = ERC20Interface(_token);
    }

     
    modifier brandOwnerOnly(address _productAddress){
        address productBrandAddress;
        (,productBrandAddress,,,,,) = deveryRegistry.products(_productAddress);
        require(productBrandAddress == msg.sender);
        _;
    }

     
    function setDeveryRegistryAddress(address _deveryRegistryAddress) external onlyAdmin {
        deveryRegistry = DeveryRegistry(_deveryRegistryAddress);
    }

     
    function setMaximumMintableQuantity(address _productAddress, uint _quantity) external payable brandOwnerOnly(_productAddress){
        require(_quantity >= totalMintedProducts[_productAddress] || _quantity == 0);
        totalAllowedProducts[_productAddress] = _quantity;
    }

     
    function claimProduct(address _productAddress,uint _quantity) external payable  brandOwnerOnly(_productAddress) {
        require(totalAllowedProducts[_productAddress] == 0 || totalAllowedProducts[_productAddress] >= totalMintedProducts[_productAddress] + _quantity);
         
        address productBrandAddress;
        address appAccountAddress;
        address appFeeAccount;
        address deveryFeeAccount;
        uint appFee;
        uint deveryFee;
        (,productBrandAddress,,,,,) = deveryRegistry.products(_productAddress);
        (,appAccountAddress,,) = deveryRegistry.brands(productBrandAddress);
        (,,appFeeAccount,appFee,) = deveryRegistry.apps(appAccountAddress);
        deveryFee = deveryRegistry.fee();
        deveryFeeAccount = deveryRegistry.feeAccount();
        if (appFee > 0) {
            token.transferFrom(productBrandAddress, appFeeAccount, appFee*_quantity);
        }
        if (deveryFee > 0) {
            token.transferFrom(productBrandAddress, deveryFeeAccount, deveryFee*_quantity);
        }
         
        for(uint i = 0;i<_quantity;i++){
            uint nextId = tokenIdToProduct.push(_productAddress) - 1;
            _mint(msg.sender,nextId);
        }
        
        totalMintedProducts[_productAddress]+=_quantity;
    }

     
    function getProductsByOwner(address _owner) external view returns (address[]){
        address[] memory products = new address[](balanceOf(_owner));
        uint counter = 0;
        for(uint i = 0; i < tokenIdToProduct.length;i++){
            if(ownerOf(i) == _owner){
                products[counter] = tokenIdToProduct[i];
                counter++;
            }
        }
        return products;
    }
}