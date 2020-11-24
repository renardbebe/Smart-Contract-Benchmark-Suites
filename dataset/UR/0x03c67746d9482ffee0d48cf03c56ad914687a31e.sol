 

 

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

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;






 
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

 

pragma solidity ^0.5.0;


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.5.0;




 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;


 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity ^0.5.0;



 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 

pragma solidity ^0.5.0;

 
library Strings {

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
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

 

pragma solidity ^0.5.0;



 

contract CustomERC721Metadata is ERC165, ERC721, ERC721Enumerable {

     
    string private _name;

     
    string private _symbol;

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

}

 

pragma solidity ^0.5.0;







contract RendarToken is CustomERC721Metadata, WhitelistedRole {
    using SafeMath for uint256;

     
     
     

     
    event EditionCreated(
        uint256 indexed _editionId
    );

     
     
     

    string public tokenBaseURI = "https://ipfs.infura.io/ipfs/";

     
    struct EditionDetails {
        uint256 editionId;               
        uint256 editionSize;             
        uint256 editionSupply;           
        uint256 priceInWei;              
        uint256 artistCommission;        
        address payable artistAccount;   
        bool active;                     
        string tokenURI;                 
    }

     
    uint256 public editionStep = 10000;

     
    uint256 public totalTokensMinted;

     
    uint256 public highestEditionNumber;

     
    uint256[] public createdEditions;

     
    address payable public rendarAddress;

     
    mapping(uint256 => uint256) internal tokenIdToEditionId;

     
    mapping(uint256 => EditionDetails) internal editionIdToEditionDetails;

     
    mapping(address => uint256[]) internal artistToEditionIds;
     
    mapping(uint256 => uint256) internal editionIdToArtistIndex;

     
     
     

    modifier onlyActiveEdition(uint256 _editionId) {
        require(editionIdToEditionDetails[_editionId].active, "Edition disabled");
        _;
    }

    modifier onlyValidEdition(uint256 _editionId) {
        require(editionIdToEditionDetails[_editionId].editionId > 0, "Edition ID invalid");
        _;
    }

    modifier onlyAvailableEdition(uint256 _editionId) {
        require(editionIdToEditionDetails[_editionId].editionSupply < editionIdToEditionDetails[_editionId].editionSize, "Edition sold out");
        _;
    }

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }

     
     
     

    constructor(address payable _rendarAddress) CustomERC721Metadata("RendarToken", "RDR") public {
        super.addWhitelisted(msg.sender);
        rendarAddress = _rendarAddress;
    }

     
     
     

    function purchase(uint256 _editionId) public payable returns (uint256 _tokenId) {
        return purchaseTo(msg.sender, _editionId);
    }

    function purchaseTo(address _to, uint256 _editionId)
    onlyActiveEdition(_editionId)
    onlyAvailableEdition(_editionId)
    public payable returns (uint256 _tokenId) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        require(msg.value >= _editionDetails.priceInWei, "Not enough ETH");

         
        uint256 tokenId = _internalMint(_to, _editionId);

         
        _splitFunds(_editionDetails.priceInWei, _editionDetails.artistAccount, _editionDetails.artistCommission);

        return tokenId;
    }

    function _splitFunds(uint256 _priceInWei, address payable _artistsAccount, uint256 _artistsCommission) internal {
        if (_priceInWei > 0) {

            if (_artistsCommission > 0) {

                uint256 artistPayment = _priceInWei.div(100).mul(_artistsCommission);
                _artistsAccount.transfer(artistPayment);

                uint256 remainingCommission = msg.value.sub(artistPayment);
                rendarAddress.transfer(remainingCommission);
            } else {

                rendarAddress.transfer(msg.value);
            }
        }
    }

     
    function mint(uint256 _editionId) public returns (uint256 _tokenId) {
        return mintTo(msg.sender, _editionId);
    }

     
    function mintTo(address _to, uint256 _editionId)
    onlyWhitelisted
    onlyValidEdition(_editionId)
    onlyAvailableEdition(_editionId)
    public returns (uint256 _tokenId) {
        return _internalMint(_to, _editionId);
    }

     
    function mintMultipleTo(address _to, uint256 _editionId, uint256 _total)
    onlyWhitelisted
    onlyValidEdition(_editionId)
    public returns (uint256[] memory _tokenIds) {

        uint256 remainingInEdition = editionIdToEditionDetails[_editionId].editionSize - editionIdToEditionDetails[_editionId].editionSupply;
        require(remainingInEdition >= _total, "Not enough left in edition");

        uint256[] memory tokens = new uint256[](_total);
        for (uint i = 0; i < _total; i++) {
            tokens[i] = _internalMint(_to, _editionId);
        }
        return tokens;
    }

    function _internalMint(address _to, uint256 _editionId) internal returns (uint256 _tokenId) {
        uint256 tokenId = _nextTokenId(_editionId);

        _mint(_to, tokenId);

        tokenIdToEditionId[tokenId] = _editionId;

        return tokenId;
    }

     
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
        delete tokenIdToEditionId[tokenId];
    }

     
    function adminBurn(uint256 tokenId) onlyWhitelisted public {
        _burn(tokenId);
        delete tokenIdToEditionId[tokenId];
    }

     
     
     

    function createEdition(
        uint256 _editionSize,
        uint256 _priceInWei,
        uint256 _artistCommission,
        address payable _artistAccount,
        string memory _tokenURI
    ) public onlyWhitelisted returns (bool _created) {
        return _createEdition(_editionSize, _priceInWei, _artistCommission, _artistAccount, _tokenURI, true);
    }

    function createEditionInactive(
        uint256 _editionSize,
        uint256 _priceInWei,
        uint256 _artistCommission,
        address payable _artistAccount,
        string memory _tokenURI
    ) public onlyWhitelisted returns (bool _created) {
        return _createEdition(_editionSize, _priceInWei, _artistCommission, _artistAccount, _tokenURI, false);
    }

    function _createEdition(
        uint256 _editionSize,
        uint256 _priceInWei,
        uint256 _artistCommission,
        address payable _artistAccount,
        string memory _tokenURI,
        bool active
    ) internal returns (bool _created){

         
        require(_editionSize > 0 && _editionSize <= editionStep, "Edition size invalid");
        require(_artistCommission >= 0 && _artistCommission <= 100, "Artist commission invalid");
        require(_artistAccount != address(0), "Artist account missing");
        require(bytes(_tokenURI).length != 0, "Token URI invalid");

         
        uint256 _editionId = highestEditionNumber.add(editionStep);

         
        editionIdToEditionDetails[_editionId] = EditionDetails(
            _editionId,
            _editionSize,
            0,  
            _priceInWei,
            _artistCommission,
            _artistAccount,
            active,
            _tokenURI
        );

        highestEditionNumber = _editionId;

        createdEditions.push(_editionId);

        updateArtistLookupData(_artistAccount, _editionId);

         
        emit EditionCreated(_editionId);

        return true;
    }

    function _nextTokenId(uint256 _editionId) internal returns (uint256) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];

         
        uint256 tokenId = _editionDetails.editionId.add(_editionDetails.editionSupply);

         
        _editionDetails.editionSupply = _editionDetails.editionSupply.add(1);

         
        totalTokensMinted = totalTokensMinted.add(1);

         
        return tokenId;
    }

    function disableEdition(uint256 _editionId)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {
        editionIdToEditionDetails[_editionId].active = false;
    }

    function enableEdition(uint256 _editionId)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {
        editionIdToEditionDetails[_editionId].active = true;
    }

    function updateArtistAccount(uint256 _editionId, address payable _artistAccount)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {

        EditionDetails storage _originalEditionDetails = editionIdToEditionDetails[_editionId];

        uint256 editionArtistIndex = editionIdToArtistIndex[_editionId];

         
        uint256[] storage editionIdsForArtist = artistToEditionIds[_originalEditionDetails.artistAccount];

         
        delete editionIdsForArtist[editionArtistIndex];

         
        uint256 newArtistsEditionIndex = artistToEditionIds[_artistAccount].length;
        artistToEditionIds[_artistAccount].push(_editionId);
        editionIdToArtistIndex[_editionId] = newArtistsEditionIndex;

         
        _originalEditionDetails.artistAccount = _artistAccount;
    }

    function updateArtistCommission(uint256 _editionId, uint256 _artistCommission)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {
        editionIdToEditionDetails[_editionId].artistCommission = _artistCommission;
    }

    function updateEditionTokenUri(uint256 _editionId, string calldata _tokenURI)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {
        editionIdToEditionDetails[_editionId].tokenURI = _tokenURI;
    }

    function updatePrice(uint256 _editionId, uint256 _priceInWei)
    external
    onlyWhitelisted
    onlyValidEdition(_editionId) {
        editionIdToEditionDetails[_editionId].priceInWei = _priceInWei;
    }

    function updateArtistLookupData(address artistAccount, uint256 editionId) internal {
        uint256 artistEditionIndex = artistToEditionIds[artistAccount].length;
        artistToEditionIds[artistAccount].push(editionId);
        editionIdToArtistIndex[editionId] = artistEditionIndex;
    }

     
     
     

    function updateTokenBaseURI(string calldata _newBaseURI)
    external
    onlyWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateRendarAddress(address payable _rendarAddress)
    external
    onlyWhitelisted {
        rendarAddress = _rendarAddress;
    }

     
     
     

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function tokenURI(uint256 _tokenId)
    external view
    onlyValidTokenId(_tokenId)
    returns (string memory) {
        uint256 editionId = tokenIdToEditionId[_tokenId];
        return Strings.strConcat(tokenBaseURI, editionIdToEditionDetails[editionId].tokenURI);
    }

    function editionTokenUri(uint256 _editionId)
    public view
    returns (string memory _tokenUri) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI);
    }

    function editionSize(uint256 _editionId)
    public view
    returns (uint256 _totalRemaining) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.editionSize;
    }

    function editionSupply(uint256 _editionId)
    public view
    returns (uint256 _editionSupply) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.editionSupply;
    }

    function editionPrice(uint256 _editionId)
    public view
    returns (uint256 _priceInWei) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.priceInWei;
    }

    function artistInfo(uint256 _editionId)
    public view
    returns (address _artistAccount, uint256 _artistCommission) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return (_editionDetails.artistAccount, _editionDetails.artistCommission);
    }

    function artistCommission(uint256 _editionId)
    public view
    returns (uint256 _artistCommission) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.artistCommission;
    }

    function artistAccount(uint256 _editionId)
    public view
    returns (address _artistAccount) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.artistAccount;
    }

    function active(uint256 _editionId)
    public view
    returns (bool _active) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.active;
    }

    function allEditions() public view returns (uint256[] memory _editionIds) {
        return createdEditions;
    }

    function artistsEditions(address _artistsAccount) public view returns (uint256[] memory _editionIds) {
        return artistToEditionIds[_artistsAccount];
    }

    function editionDetails(uint256 _editionId) public view onlyValidEdition(_editionId)
    returns (
        uint256 _editionSize,
        uint256 _editionSupply,
        uint256 _priceInWei,
        uint256 _artistCommission,
        address _artistAccount,
        bool _active,
        string memory _tokenURI
    ) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return (
        _editionDetails.editionSize,
        _editionDetails.editionSupply,
        _editionDetails.priceInWei,
        _editionDetails.artistCommission,
        _editionDetails.artistAccount,
        _editionDetails.active,
        Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI)
        );
    }

    function totalRemaining(uint256 _editionId) public view returns (uint256) {
        EditionDetails storage _editionDetails = editionIdToEditionDetails[_editionId];
        return _editionDetails.editionSize.sub(_editionDetails.editionSupply);
    }

    function tokenDetails(uint256 _tokenId) public view onlyValidTokenId(_tokenId)
    returns (
        uint256 _editionId,
        uint256 _editionSize,
        uint256 _editionSupply,
        address _artistAccount,
        address _owner,
        string memory _tokenURI
    ) {
        uint256 editionId = tokenIdToEditionId[_tokenId];
        EditionDetails storage _editionDetails = editionIdToEditionDetails[editionId];
        return (
        editionId,
        _editionDetails.editionSize,
        _editionDetails.editionSupply,
        _editionDetails.artistAccount,
        ownerOf(_tokenId),
        Strings.strConcat(tokenBaseURI, _editionDetails.tokenURI)
        );
    }

}