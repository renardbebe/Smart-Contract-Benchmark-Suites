 

pragma solidity ^0.5.0;

interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
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


 
 
 
 
 


contract VonAeschERC721 is ERC721Full {

    uint256 public liveTokenId;


    mapping(bytes32 => uint256) private PatternToken;
    mapping(uint256 => bytes32) private TokenPattern;
    mapping(uint256 => string) private _tokenMSGs;

    string public info = "Von Aesch Offcial Token https://von-aesch.com";

    string public baseTokenURI = "https://von-aesch.com/tokenURI.php?colors=";
    string public basefallbackTokenURI = "https://cloudflare-ipfs.com/ipfs/Qmes4xg8qpfrpBnfCgcm1i9235gSszMS7pDTStWRAFNmYv#colors=";

    address private constant emergency_admin = 0x59ab67D9BA5a748591bB79Ce223606A8C2892E6d;
    address private constant first_admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;
    address private admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;


    constructor()
        ERC721Full("VonAeschPattern", "VA")
        public
    {}

     

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyEAdmin {
        require(msg.sender == emergency_admin);
        _;
    }


     

     

    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return strConcat(
            baseTokenURI,
            _tokenURI(tokenId)
        );
    }

    function fallbackTokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return strConcat(
            basefallbackTokenURI,
            _tokenURI(tokenId)
        );
    }

     

    function tokenMessage(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenMSGs[tokenId];
    }


     


    function patternIdToTokenId(bytes32 patternid) public view returns(uint256){
      return PatternToken[patternid];
    }

    function tokenIdToPatternId(uint256 tokenId) public view returns(bytes32){
      return TokenPattern[tokenId];
    }


    function _setTokenMSG(uint256 tokenId, string memory _msg) internal {
        require(_exists(tokenId));
        _tokenMSGs[tokenId] = _msg;
    }

    function setMessage(uint256 tokenId, string memory _msg) public {
      address owner = ownerOf(tokenId);
      require(msg.sender == owner);
      _setTokenMSG(tokenId,_msg);
    }


    function checkPatternExistance (bytes32 patternid) public view
    returns(bool)
    {
     
    uint256 t_tokenId = PatternToken[patternid];
      return _exists(t_tokenId);
    }

    function exists(uint256 tokenId) public view returns(bool){
      return _exists(tokenId);
    }

    function nextTokenId() internal returns(uint256) {
      liveTokenId = liveTokenId + 1;
      return liveTokenId;
    }

    function createPattern(bytes32 patternid, string memory dataMixed, address newowner, string memory message)
        onlyAdmin
        public
        returns(string memory)
    {

       
      string memory data = toUpper(dataMixed);

       
      bytes32 colordatahash = keccak256(abi.encodePacked(data));

       
      require(PatternToken[colordatahash] == 0);

       
      uint256 newTokenId = nextTokenId();

       
      PatternToken[colordatahash] = newTokenId;
       
      TokenPattern[newTokenId] = colordatahash;

       
      _mint(newowner, newTokenId);
      _setTokenURI(newTokenId, data);
      _setTokenMSG(newTokenId, message);

      return "ok";


    }
    function transferPattern(bytes32 patternid,address newowner,string memory message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string memory)
    {
         

         
        uint256 t_tokenId = PatternToken[patternid];

         
        address t_oldowner = ownerOf(t_tokenId);
        require(t_oldowner != address(0));

         
        bytes32 h = prefixedHash2(newowner);

         
        require(ecrecover(h, v, r, s) == t_oldowner);

        _transferFrom(t_oldowner, newowner, t_tokenId);
        _setTokenMSG(t_tokenId, message);

        return "ok";

    }

    function changeMessage(bytes32 patternid,string memory message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string memory)
    {
       

       
      uint256 t_tokenId = PatternToken[patternid];

       
      address t_owner = ownerOf(t_tokenId);
      require(t_owner != address(0));

       
      bytes32 h = prefixedHash(message);

       
      require(ecrecover(h, v, r, s) == t_owner);

      _setTokenMSG(t_tokenId, message);

      return "ok";

    }

    function verifyOwner(bytes32 patternid, address owner, uint8 v, bytes32 r, bytes32 s)
      public
      view
      returns(bool)
    {
       
      uint256 t_tokenId = PatternToken[patternid];

       
      address t_owner = ownerOf(t_tokenId);
      require(t_owner != address(0));

       
      bytes32 h = prefixedHash2(owner);

       
      address owner2 = ecrecover(h, v, r, s);

       
      if(t_owner == owner2 && owner == owner2){
        return true;
      }else{
        return false;
      }
    }

    function prefixedHash(string memory message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function prefixedHash2(address message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }


     

    function userHasPattern(address account)
      public
      view
      returns(bool)
    {
      if(balanceOf(account) >=1 )
      {
        return true;
      }else{
        return false;
      }
    }

    function emergency(address newa)
      public
      onlyEAdmin
    {
      require(newa != address(0));
      admin = newa;
    }

    function changeInfo(string memory newstring)
      public
      onlyAdmin
    {
      info = newstring;
    }

    function changeBaseTokenURI(string memory newstring)
      public
      onlyAdmin
    {
      baseTokenURI = newstring;
    }

    function changeFallbackTokenURI(string memory newstring)
      public
      onlyAdmin
    {
      basefallbackTokenURI = newstring;
    }


    function toUpper(string memory str)
      pure
      private
      returns (string memory)
    {
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
         
        if ((uint8(bStr[i]) >= 65+32) && (uint8(bStr[i]) <= 90+32)) {
           
          bLower[i] = bytes1(uint8(bStr[i]) - 32);
        } else {
          bLower[i] = bStr[i];
        }
      }
      return string(bLower);
    }





}