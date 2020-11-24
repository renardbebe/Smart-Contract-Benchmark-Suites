 

 

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

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity 0.5.12;


contract IRegistry is IERC721Metadata {

    event NewURI(uint256 indexed tokenId, string uri);

    event NewURIPrefix(string prefix);

    event Resolve(uint256 indexed tokenId, address indexed to);

    event Sync(address indexed resolver, uint256 indexed updateId, uint256 indexed tokenId);

     
    function controlledSetTokenURIPrefix(string calldata prefix) external;

     
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

     
    function mintChild(address to, uint256 tokenId, string calldata label) external;

     
    function controlledMintChild(address to, uint256 tokenId, string calldata label) external;

     
    function transferFromChild(address from, address to, uint256 tokenId, string calldata label) external;

     
    function controlledTransferFrom(address from, address to, uint256 tokenId) external;

     
    function safeTransferFromChild(address from, address to, uint256 tokenId, string calldata label, bytes calldata _data) external;

     
    function safeTransferFromChild(address from, address to, uint256 tokenId, string calldata label) external;

     
    function controlledSafeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data) external;

     
    function burnChild(uint256 tokenId, string calldata label) external;

     
    function controlledBurn(uint256 tokenId) external;

     
    function resolveTo(address to, uint256 tokenId) external;

     
    function resolverOf(uint256 tokenId) external view returns (address);

     
    function controlledResolveTo(address to, uint256 tokenId) external;

}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;


 
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
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;







 
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

 

pragma solidity ^0.5.0;


 
contract ERC721Burnable is ERC721 {
     
    function burn(uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity 0.5.12;


 

 
contract ControllerRole {

    using Roles for Roles.Role;

     
     
     

    Roles.Role private _controllers;

    constructor () public {
        _addController(msg.sender);
    }

    modifier onlyController() {
        require(isController(msg.sender));
        _;
    }

    function isController(address account) public view returns (bool) {
        return _controllers.has(account);
    }

    function addController(address account) public onlyController {
        _addController(account);
    }

    function renounceController() public {
        _removeController(msg.sender);
    }

    function _addController(address account) internal {
        _controllers.add(account);
         
    }

    function _removeController(address account) internal {
        _controllers.remove(account);
         
    }

}

 

pragma solidity 0.5.12;




 

 
contract Registry is IRegistry, ControllerRole, ERC721Burnable {

     
    mapping(uint256 => string) internal _tokenURIs;

    string internal _prefix;

     
    mapping (uint256 => address) internal _tokenResolvers;

     
    uint256 private constant _CRYPTO_HASH =
        0x0f4a10a4f46c288cea365fcf45cccf0e9d901b945b9829ccdb54c10dc3cb7a6f;

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _;
    }

    constructor () public {
        _mint(address(0xdead), _CRYPTO_HASH);
         
        _registerInterface(0x5b5e139f);  
        _tokenURIs[root()] = "crypto";
        emit NewURI(root(), "crypto");
    }

     

    function name() external view returns (string memory) {
        return ".crypto";
    }

    function symbol() external view returns (string memory) {
        return "UD";
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return string(abi.encodePacked(_prefix, _tokenURIs[tokenId]));
    }

    function controlledSetTokenURIPrefix(string calldata prefix) external onlyController {
        _prefix = prefix;
        emit NewURIPrefix(prefix);
    }

     

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

     

    function root() public pure returns (uint256) {
        return _CRYPTO_HASH;
    }

    function childIdOf(uint256 tokenId, string calldata label) external pure returns (uint256) {
        return _childId(tokenId, label);
    }

     

    function mintChild(address to, uint256 tokenId, string calldata label) external onlyApprovedOrOwner(tokenId) {
        _mintChild(to, tokenId, label);
    }

    function controlledMintChild(address to, uint256 tokenId, string calldata label) external onlyController {
        _mintChild(to, tokenId, label);
    }

    function safeMintChild(address to, uint256 tokenId, string calldata label) external onlyApprovedOrOwner(tokenId) {
        _safeMintChild(to, tokenId, label, "");
    }

    function safeMintChild(address to, uint256 tokenId, string calldata label, bytes calldata _data)
        external
        onlyApprovedOrOwner(tokenId)
    {
        _safeMintChild(to, tokenId, label, _data);
    }

    function controlledSafeMintChild(address to, uint256 tokenId, string calldata label, bytes calldata _data)
        external
        onlyController
    {
        _safeMintChild(to, tokenId, label, _data);
    }

     

    function setOwner(address to, uint256 tokenId) external onlyApprovedOrOwner(tokenId)  {
        super._transferFrom(ownerOf(tokenId), to, tokenId);
    }

    function transferFromChild(address from, address to, uint256 tokenId, string calldata label)
        external
        onlyApprovedOrOwner(tokenId)
    {
        _transferFrom(from, to, _childId(tokenId, label));
    }

    function controlledTransferFrom(address from, address to, uint256 tokenId) external onlyController {
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFromChild(
        address from,
        address to,
        uint256 tokenId,
        string memory label,
        bytes memory _data
    ) public onlyApprovedOrOwner(tokenId) {
        uint256 childId = _childId(tokenId, label);
        _transferFrom(from, to, childId);
        require(_checkOnERC721Received(from, to, childId, _data));
    }

    function safeTransferFromChild(address from, address to, uint256 tokenId, string calldata label) external {
        safeTransferFromChild(from, to, tokenId, label, "");
    }

    function controlledSafeTransferFrom(address from, address to, uint256 tokenId, bytes calldata _data)
        external
        onlyController
    {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

     

    function burnChild(uint256 tokenId, string calldata label) external onlyApprovedOrOwner(tokenId) {
        _burn(_childId(tokenId, label));
    }

    function controlledBurn(uint256 tokenId) external onlyController {
        _burn(tokenId);
    }

     

    function resolverOf(uint256 tokenId) external view returns (address) {
        address resolver = _tokenResolvers[tokenId];
        require(resolver != address(0));
        return resolver;
    }

    function resolveTo(address to, uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        _resolveTo(to, tokenId);
    }

    function controlledResolveTo(address to, uint256 tokenId) external onlyController {
        _resolveTo(to, tokenId);
    }

    function sync(uint256 tokenId, uint256 updateId) external {
        require(_tokenResolvers[tokenId] == msg.sender);
        emit Sync(msg.sender, updateId, tokenId);
    }

     

    function _childId(uint256 tokenId, string memory label) internal pure returns (uint256) {
        require(bytes(label).length != 0);
        return uint256(keccak256(abi.encodePacked(tokenId, keccak256(abi.encodePacked(label)))));
    }

    function _mintChild(address to, uint256 tokenId, string memory label) internal {
        uint256 childId = _childId(tokenId, label);
        _mint(to, childId);

        require(bytes(label).length != 0);
        require(_exists(childId));

        bytes memory domain = abi.encodePacked(label, ".", _tokenURIs[tokenId]);

        _tokenURIs[childId] = string(domain);
        emit NewURI(childId, string(domain));
    }

    function _safeMintChild(address to, uint256 tokenId, string memory label, bytes memory _data) internal {
        _mintChild(to, tokenId, label);
        require(_checkOnERC721Received(address(0), to, _childId(tokenId, label), _data));
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
         
        if (_tokenResolvers[tokenId] != address(0x0)) {
            delete _tokenResolvers[tokenId];
        }
    }

    function _burn(uint256 tokenId) internal {
        super._burn(tokenId);
         
        if (_tokenResolvers[tokenId] != address(0x0)) {
            delete _tokenResolvers[tokenId];
        }
         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _resolveTo(address to, uint256 tokenId) internal {
        require(_exists(tokenId));
        emit Resolve(tokenId, to);
        _tokenResolvers[tokenId] = to;
    }

}

 

pragma solidity ^0.5.0;

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity 0.5.12;



 

contract SignatureUtil {
    using ECDSA for bytes32;

     
    mapping (uint256 => uint256) internal _nonces;

    Registry internal _registry;

    constructor(Registry registry) public {
        _registry = registry;
    }

    function registry() external view returns (address) {
        return address(_registry);
    }

     
    function nonceOf(uint256 tokenId) external view returns (uint256) {
        return _nonces[tokenId];
    }

    function _validate(bytes32 hash, uint256 tokenId, bytes memory signature) internal {
        uint256 nonce = _nonces[tokenId];

        address signer = keccak256(abi.encodePacked(hash, address(this), nonce)).toEthSignedMessageHash().recover(signature);
        require(
            signer != address(0) &&
            _registry.isApprovedOrOwner(
                signer,
                tokenId
            )
        );

        _nonces[tokenId] += 1;
    }

}

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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

 

pragma solidity 0.5.12;

interface IMintingController {

     
    function mintSLD(address to, string calldata label) external;

     
    function safeMintSLD(address to, string calldata label) external;

     
    function safeMintSLD(address to, string calldata label, bytes calldata _data) external;

}

 

pragma solidity 0.5.12;




 
contract MintingController is IMintingController, MinterRole {

    Registry internal _registry;

    constructor (Registry registry) public {
        _registry = registry;
    }

    function registry() external view returns (address) {
        return address(_registry);
    }

    function mintSLD(address to, string memory label) public onlyMinter {
        _registry.controlledMintChild(to, _registry.root(), label);
    }

    function safeMintSLD(address to, string calldata label) external {
        safeMintSLD(to, label, "");
    }

    function safeMintSLD(address to, string memory label, bytes memory _data) public onlyMinter {
        _registry.controlledSafeMintChild(to, _registry.root(), label, _data);
    }

    function mintSLDWithResolver(address to, string memory label, address resolver) public onlyMinter {
        _registry.controlledMintChild(to, _registry.root(), label);
        _registry.controlledResolveTo(resolver, _registry.childIdOf(_registry.root(), label));
    }

    function safeMintSLDWithResolver(address to, string calldata label, address resolver) external {
        safeMintSLD(to, label, "");
        _registry.controlledResolveTo(resolver, _registry.childIdOf(_registry.root(), label));
    }

    function safeMintSLDWithResolver(address to, string calldata label, address resolver, bytes calldata _data) external {
        safeMintSLD(to, label, _data);
        _registry.controlledResolveTo(resolver, _registry.childIdOf(_registry.root(), label));
    }

}

 

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;



 

contract Resolver is SignatureUtil {

    event Set(uint256 indexed preset, string indexed key, string value, uint256 indexed tokenId);
    event SetPreset(uint256 indexed preset, uint256 indexed tokenId);

     
    mapping (uint256 => mapping (uint256 =>  mapping (string => string))) internal _records;

     
    mapping (uint256 => uint256) _tokenPresets;

    MintingController internal _mintingController;

    constructor(Registry registry, MintingController mintingController) public SignatureUtil(registry) {
        require(address(registry) == mintingController.registry());
        _mintingController = mintingController;
    }

     
    modifier whenResolver(uint256 tokenId) {
        require(address(this) == _registry.resolverOf(tokenId), "SimpleResolver: is not the resolver");
        _;
    }

    function presetOf(uint256 tokenId) external view returns (uint256) {
        return _tokenPresets[tokenId];
    }

    function setPreset(uint256 presetId, uint256 tokenId) external {
        require(_registry.isApprovedOrOwner(msg.sender, tokenId));
        _setPreset(presetId, tokenId);
    }

    function setPresetFor(uint256 presetId, uint256 tokenId, bytes calldata signature) external {
        _validate(keccak256(abi.encodeWithSelector(this.setPreset.selector, presetId, tokenId)), tokenId, signature);
        _setPreset(presetId, tokenId);
    }

    function reset(uint256 tokenId) external {
        require(_registry.isApprovedOrOwner(msg.sender, tokenId));
        _setPreset(now, tokenId);
    }

    function resetFor(uint256 tokenId, bytes calldata signature) external {
        _validate(keccak256(abi.encodeWithSelector(this.reset.selector, tokenId)), tokenId, signature);
        _setPreset(now, tokenId);
    }

     
    function get(string memory key, uint256 tokenId) public view whenResolver(tokenId) returns (string memory) {
        return _records[tokenId][_tokenPresets[tokenId]][key];
    }

    function preconfigure(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) public {
        require(_mintingController.isMinter(msg.sender));
        _setMany(_tokenPresets[tokenId], keys, values, tokenId);
    }

     
    function set(string calldata key, string calldata value, uint256 tokenId) external {
        require(_registry.isApprovedOrOwner(msg.sender, tokenId));
        _set(_tokenPresets[tokenId], key, value, tokenId);
    }

     
    function setFor(
        string calldata key,
        string calldata value,
        uint256 tokenId,
        bytes calldata signature
    ) external {
        _validate(keccak256(abi.encodeWithSelector(this.set.selector, key, value, tokenId)), tokenId, signature);
        _set(_tokenPresets[tokenId], key, value, tokenId);
    }

     
    function getMany(string[] calldata keys, uint256 tokenId) external view whenResolver(tokenId) returns (string[] memory) {
        uint256 keyCount = keys.length;
        string[] memory values = new string[](keyCount);
        uint256 preset = _tokenPresets[tokenId];
        for (uint256 i = 0; i < keyCount; i++) {
            values[i] = _records[tokenId][preset][keys[i]];
        }
        return values;
    }

    function setMany(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) public {
        require(_registry.isApprovedOrOwner(msg.sender, tokenId));
        _setMany(_tokenPresets[tokenId], keys, values, tokenId);
    }

     
    function setManyFor(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId,
        bytes memory signature
    ) public {
        _validate(keccak256(abi.encodeWithSelector(this.setMany.selector, keys, values, tokenId)), tokenId, signature);
        _setMany(_tokenPresets[tokenId], keys, values, tokenId);
    }

    function _setPreset(uint256 presetId, uint256 tokenId) internal {
        _tokenPresets[tokenId] = presetId;
        emit SetPreset(presetId, tokenId);
    }

     
    function _set(uint256 preset, string memory key, string memory value, uint256 tokenId) internal {
        _registry.sync(tokenId, uint256(keccak256(bytes(key))));
        _records[tokenId][preset][key] = value;
        emit Set(preset, key, value, tokenId);
    }

     
    function _setMany(uint256 preset, string[] memory keys, string[] memory values, uint256 tokenId) internal {
        uint256 keyCount = keys.length;
        for (uint256 i = 0; i < keyCount; i++) {
            _set(preset, keys[i], values[i], tokenId);
        }
    }

}