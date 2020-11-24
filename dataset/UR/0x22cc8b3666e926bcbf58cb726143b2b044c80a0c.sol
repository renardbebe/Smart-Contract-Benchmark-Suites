 

pragma solidity ^0.5.0;

contract IERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function transferFrom(address from, address to, uint256 tokenId) public returns (bool);
  function safeTransferFrom(address from, address to, uint256 tokenId) public returns (bool);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public returns (bool);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);
  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator) public view returns (bool);
}

contract IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

 
interface IERC165 {
   
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 
contract ERC165 is IERC165 {
   
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

   
  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor () internal {
     
     
    registerInterface(_INTERFACE_ID_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

   
  function registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }
}

library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b, "Invalid argument.");

    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0, "Invalid argument.");
    uint256 c = _a / _b;

    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a, "Invalid argument.");
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a, "Invalid argument.");

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Invalid argument.");
    return a % b;
  }
}

contract Ownable {
  address payable private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == _owner, "Forbidden");
    _;
  }

  constructor() public {
    _owner = msg.sender;
  }

  function owner() public view returns (address payable) {
    return _owner;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Non-zero address required.");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Ticket is ERC165, IERC721, Ownable {
  using SafeMath for uint256;

  mapping(uint256 => bool) private _redemptions;
  mapping(address => bool) private _operators;
  mapping(uint256 => address) private _tokenOwner;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => uint256) private _ownedTokensCount;
  mapping(address => uint256[]) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;
  bool private _paused;
  string private _name;
  string private _symbol;
  mapping(uint256 => string) private _tokenURIs;

  event TokenRedeemed(uint256 tokenID);

  modifier whenNotPaused() {
    require(!_paused, "contract is paused");
    _;
  }

  modifier onlyOperator() {
    require(_operators[msg.sender] == true, "Forbidden");
    _;
  }

  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    registerInterface(0x80ac58cd);
    registerInterface(0x5b5e139f);
    registerInterface(0x780e9d63);

    _operators[msg.sender] = true;
    _paused = true;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(exists(tokenId), "URI query for nonexistent token");
    return _tokenURIs[tokenId];
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _ownedTokensCount[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    return owner;
  }

  function paused() public view returns (bool) {
    return _paused;
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId) {
    require(index < balanceOf(owner), "owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "global index out of bounds");
    return _allTokens[index];
  }

  function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused returns (bool) {
    require(ownerOf(tokenId) == from, "transfer of token that is not own");
    require(to != address(0), "transfer to the zero address");
    require(isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");

    clearApproval(tokenId);

    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

    _tokenOwner[tokenId] = to;

    removeTokenFromOwnerEnumeration(from, tokenId);
    addTokenToOwnerEnumeration(to, tokenId);

    emit Transfer(from, to, tokenId);
    return true;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public returns (bool) {
    return safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public returns (bool) {
    require(checkOnERC721Received(from, to, tokenId, data), "transfer to non ERC721Receiver implementer");
    return transferFrom(from, to, tokenId);
  }

  function approve(address to, uint256 tokenId) public whenNotPaused {
    address owner = ownerOf(tokenId);
    require(to != owner, "approval to current owner");
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "approve caller is not owner nor approved for all");
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(exists(tokenId), "approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address to, bool approved) public whenNotPaused {
    require(to != msg.sender, "approve to caller");
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function exists(uint256 tokenId) public view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function mint(address to, uint256 tokenId) public onlyOwner returns (bool) {
    require(to != address(0), "mint to the zero address");
    require(!exists(tokenId), "token already minted");

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

    addTokenToOwnerEnumeration(to, tokenId);
    addTokenToAllTokensEnumeration(tokenId);

    emit Transfer(address(0), to, tokenId);
    return true;
  }

  function mintWithTokenURI(address to, uint256 tokenId, string memory uri) public onlyOwner returns (bool) {
    mint(to, tokenId);
    _tokenURIs[tokenId] = uri;
    return true;
  }

  function burn(uint256 tokenId) public whenNotPaused returns (bool) {
    require(isApprovedOrOwner(msg.sender, tokenId), "caller is not owner nor approved");

    clearApproval(tokenId);

    _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].sub(1);
    _tokenOwner[tokenId] = address(0);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }

    removeTokenFromOwnerEnumeration(msg.sender, tokenId);
    _ownedTokensIndex[tokenId] = 0;
    removeTokenFromAllTokensEnumeration(tokenId);

    emit Transfer(msg.sender, address(0), tokenId);

    return true;
  }

  function pause() public onlyOwner {
    _paused = true;
  }

  function unpause() public onlyOwner {
    _paused = false;
  }

  function addOperator(address operator) public onlyOwner {
    _operators[operator] = true;
  }

  function isOperator(address user) public view returns (bool) {
    return _operators[user];
  }

  function removeOperator(address operator) public onlyOwner {
    delete _operators[operator];
  }

  function isRedeemed(uint256 tokenID) public view returns (bool) {
    return _redemptions[tokenID];
  }

  function getSignerAndOwner(uint256 tokenID, bytes memory signature) public view returns (address, address) {
    bytes32 hash = keccak256(abi.encodePacked(_tokenURIs[tokenID]));

    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    hash = keccak256(abi.encodePacked(prefix, hash));

    address signer = recover(hash,signature);
    address tokenOwner = ownerOf(tokenID);

    return (signer, tokenOwner);
  }

  function markTokenAsRedeemed(uint256 tokenID, bytes memory signature) public onlyOperator {
    require(!_redemptions[tokenID], "Token already redeemed");

    (address signer, address tokenOwner) = getSignerAndOwner(tokenID, signature);

    require(signer == tokenOwner, "Not signed by token owner");

    _redemptions[tokenID] = true;
    emit TokenRedeemed(tokenID);
  }

  function isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
    require(exists(tokenId), "operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
    if (!isContract(to)) {
      return true;
    }

    bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
    return (retval == 0x150b7a02);
  }

  function clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  function isContract(address account) private view returns (bool) {
    uint256 size = 0;
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  function addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
        uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

        _ownedTokens[from][tokenIndex] = lastTokenId;
        _ownedTokensIndex[lastTokenId] = tokenIndex;
    }

    _ownedTokens[from].pop();
  }

  function removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 tokenIndex = _allTokensIndex[tokenId];

    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId;
    _allTokensIndex[lastTokenId] = tokenIndex;

    _allTokens.pop();
    _allTokensIndex[tokenId] = 0;
  }

  function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

  function destroy() public onlyOwner {
    selfdestruct(owner());
  }
}