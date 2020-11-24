 

 

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


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;




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

 

pragma solidity ^0.5.0;




 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

 

pragma solidity ^0.5.0;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

 

pragma solidity 0.5.0;

library Strings {

     
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

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

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
}

 

pragma solidity 0.5.0;




contract ERC721MetadataWithoutTokenUri is ERC165, ERC721, IERC721Metadata {
     
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

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
    }
}

 

pragma solidity 0.5.0;




 
contract CustomERC721Full is ERC721, ERC721Enumerable, ERC721MetadataWithoutTokenUri {
    constructor (string memory name, string memory symbol) public ERC721MetadataWithoutTokenUri(name, symbol) {
         
    }
}

 

pragma solidity 0.5.0;

interface INiftyTradingCardCreator {
    function mintCard(
        uint256 _cardType,
        uint256 _nationality,
        uint256 _position,
        uint256 _ethnicity,
        uint256 _kit,
        uint256 _colour,
        address _to
    ) external returns (uint256 _tokenId);

    function setAttributes(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill
    ) external returns (bool);

    function setName(
        uint256 _tokenId,
        uint256 _firstName,
        uint256 _lastName
    ) external returns (bool);

    function setAttributesAndName(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill,
        uint256 _firstName,
        uint256 _lastName
    ) external returns (bool);
}

 

pragma solidity 0.5.0;


contract INiftyTradingCardAttributes is IERC721 {

    function attributesFlat(uint256 _tokenId) public view returns (
        uint256[5] memory attributes
    );

    function attributesAndName(uint256 _tokenId) public view returns (
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill,
        uint256 _special,
        uint256 _firstName,
        uint256 _lastName
    );

    function extras(uint256 _tokenId) public view returns (
        uint256 _badge,
        uint256 _sponsor,
        uint256 _number,
        uint256 _boots,
        uint256 _stars,
        uint256 _xp
    );

    function card(uint256 _tokenId) public view returns (
        uint256 _cardType,
        uint256 _nationality,
        uint256 _position,
        uint256 _ethnicity,
        uint256 _kit,
        uint256 _colour
    );

}

 

pragma solidity 0.5.0;








contract NiftyTradingCard is CustomERC721Full, WhitelistedRole, INiftyTradingCardCreator, INiftyTradingCardAttributes {
    using SafeMath for uint256;

    string public tokenBaseURI = "";
    string public tokenBaseIpfsURI = "https://ipfs.infura.io/ipfs/";

    event TokenBaseURIChanged(
        string _new
    );

    event TokenBaseIPFSURIChanged(
        string _new
    );

    event StaticIpfsTokenURISet(
        uint256 indexed _tokenId,
        string _ipfsHash
    );

    event StaticIpfsTokenURICleared(
        uint256 indexed _tokenId
    );

    event CardAttributesSet(
        uint256 indexed _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill
    );

    event NameSet(
        uint256 indexed _tokenId,
        uint256 _firstName,
        uint256 _lastName
    );

    event SpecialSet(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event BadgeSet(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event SponsorSet(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event NumberSet(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event BootsSet(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event StarAdded(
        uint256 indexed _tokenId,
        uint256 _value
    );

    event XpAdded(
        uint256 indexed _tokenId,
        uint256 _value
    );

    struct Card {
        uint256 cardType;

        uint256 nationality;
        uint256 position;

        uint256 ethnicity;

        uint256 kit;
        uint256 colour;
    }

    struct Attributes {
        uint256 strength;
        uint256 speed;
        uint256 intelligence;
        uint256 skill;
        uint256 special;
    }

    struct Name {
        uint256 firstName;
        uint256 lastName;
    }

    struct Extras {
        uint256 badge;
        uint256 sponsor;
        uint256 number;
        uint256 boots;
        uint256 stars;
        uint256 xp;
    }

    modifier onlyWhitelistedOrTokenOwner(uint256 _tokenId){
        require(isWhitelisted(msg.sender) || ownerOf(_tokenId) == msg.sender, "Unable to set token image URI unless owner of whitelisted");
        _;
    }

    uint256 public tokenIdPointer = 0;

    mapping(uint256 => string) public staticIpfsImageLink;
    mapping(uint256 => Card) internal cardMapping;
    mapping(uint256 => Attributes) internal attributesMapping;
    mapping(uint256 => Name) internal namesMapping;
    mapping(uint256 => Extras) internal extrasMapping;

    function mintCard(
        uint256 _cardType,
        uint256 _nationality,
        uint256 _position,
        uint256 _ethnicity,
        uint256 _kit,
        uint256 _colour,
        address _to
    ) public onlyWhitelisted returns (uint256 _tokenId) {

         
        tokenIdPointer = tokenIdPointer.add(1);

         
        cardMapping[tokenIdPointer] = Card({
            cardType : _cardType,
            nationality : _nationality,
            position : _position,
            ethnicity : _ethnicity,
            kit : _kit,
            colour : _colour
            });

         
        _mint(_to, tokenIdPointer);

        return tokenIdPointer;
    }

    function setAttributesAndName(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill,
        uint256 _firstName,
        uint256 _lastName
    ) public onlyWhitelisted returns (bool) {

        attributesMapping[_tokenId] = Attributes({
            strength : _strength,
            speed : _speed,
            intelligence : _intelligence,
            skill : _skill,
            special : 0
            });

        namesMapping[_tokenId] = Name({
            firstName : _firstName,
            lastName : _lastName
            });

        return true;
    }

    function setAttributes(
        uint256 _tokenId,
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill
    ) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        attributesMapping[_tokenId] = Attributes({
            strength : _strength,
            speed : _speed,
            intelligence : _intelligence,
            skill : _skill,
            special : 0
            });

        emit CardAttributesSet(
            _tokenId,
            _strength,
            _speed,
            _intelligence,
            _skill
        );

        return true;
    }

    function setName(
        uint256 _tokenId,
        uint256 _firstName,
        uint256 _lastName
    ) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        namesMapping[_tokenId] = Name({
            firstName : _firstName,
            lastName : _lastName
            });

        emit NameSet(
            _tokenId,
            _firstName,
            _lastName
        );

        return true;
    }

    function card(uint256 _tokenId) public view returns (
        uint256 _cardType,
        uint256 _nationality,
        uint256 _position,
        uint256 _ethnicity,
        uint256 _kit,
        uint256 _colour
    ) {
        require(_exists(_tokenId), "Token does not exist");
        Card storage tokenCard = cardMapping[_tokenId];
        return (
        tokenCard.cardType,
        tokenCard.nationality,
        tokenCard.position,
        tokenCard.ethnicity,
        tokenCard.kit,
        tokenCard.colour
        );
    }

    function attributesAndName(uint256 _tokenId) public view returns (
        uint256 _strength,
        uint256 _speed,
        uint256 _intelligence,
        uint256 _skill,
        uint256 _special,
        uint256 _firstName,
        uint256 _lastName
    ) {
        require(_exists(_tokenId), "Token does not exist");
        Attributes storage tokenAttributes = attributesMapping[_tokenId];
        Name storage tokenName = namesMapping[_tokenId];
        return (
        tokenAttributes.strength,
        tokenAttributes.speed,
        tokenAttributes.intelligence,
        tokenAttributes.skill,
        tokenAttributes.special,
        tokenName.firstName,
        tokenName.lastName
        );
    }

    function extras(uint256 _tokenId) public view returns (
        uint256 _badge,
        uint256 _sponsor,
        uint256 _number,
        uint256 _boots,
        uint256 _stars,
        uint256 _xp
    ) {
        require(_exists(_tokenId), "Token does not exist");
        Extras storage tokenExtras = extrasMapping[_tokenId];
        return (
        tokenExtras.badge,
        tokenExtras.sponsor,
        tokenExtras.number,
        tokenExtras.boots,
        tokenExtras.stars,
        tokenExtras.xp
        );
    }

    function attributesFlat(uint256 _tokenId) public view returns (uint256[5] memory) {
        require(_exists(_tokenId), "Token does not exist");
        Attributes storage tokenAttributes = attributesMapping[_tokenId];
        uint256[5] memory tokenAttributesFlat = [
        tokenAttributes.strength,
        tokenAttributes.speed,
        tokenAttributes.intelligence,
        tokenAttributes.skill,
        tokenAttributes.special
        ];
        return tokenAttributesFlat;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function burn(uint256 _tokenId) onlyWhitelisted public returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        delete staticIpfsImageLink[_tokenId];
        delete cardMapping[_tokenId];
        delete attributesMapping[_tokenId];
        delete namesMapping[_tokenId];
        delete extrasMapping[_tokenId];

        _burn(ownerOf(_tokenId), _tokenId);

        return true;
    }

    function setSpecial(uint256 _tokenId, uint256 _newSpecial) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Attributes storage tokenAttributes = attributesMapping[_tokenId];
        tokenAttributes.special = _newSpecial;

        emit SpecialSet(_tokenId, _newSpecial);

        return true;
    }

    function setBadge(uint256 _tokenId, uint256 _new) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.badge = _new;

        emit BadgeSet(_tokenId, _new);

        return true;
    }

    function setSponsor(uint256 _tokenId, uint256 _new) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.sponsor = _new;

        emit SponsorSet(_tokenId, _new);

        return true;
    }

    function setNumber(uint256 _tokenId, uint256 _new) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.number = _new;

        emit NumberSet(_tokenId, _new);

        return true;
    }

    function setBoots(uint256 _tokenId, uint256 _new) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.boots = _new;

        emit BootsSet(_tokenId, _new);

        return true;
    }

    function addStar(uint256 _tokenId) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.stars = tokenExtras.stars.add(1);

        emit StarAdded(_tokenId, tokenExtras.stars);

        return true;
    }

    function addXp(uint256 _tokenId, uint256 _increment) public onlyWhitelisted returns (bool) {
        require(_exists(_tokenId), "Token does not exist");

        Extras storage tokenExtras = extrasMapping[_tokenId];
        tokenExtras.xp = tokenExtras.xp.add(_increment);

        emit XpAdded(_tokenId, tokenExtras.xp);

        return true;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));

         
        if (bytes(staticIpfsImageLink[tokenId]).length > 0) {
            return Strings.strConcat(tokenBaseIpfsURI, staticIpfsImageLink[tokenId]);
        }
        return Strings.strConcat(tokenBaseURI, Strings.uint2str(tokenId));
    }

    function updateTokenBaseURI(string memory _newBaseURI) public onlyWhitelisted returns (bool) {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;

        emit TokenBaseURIChanged(_newBaseURI);

        return true;
    }

    function updateTokenBaseIpfsURI(string memory _tokenBaseIpfsURI) public onlyWhitelisted returns (bool) {
        require(bytes(_tokenBaseIpfsURI).length != 0, "Base IPFS URI invalid");
        tokenBaseIpfsURI = _tokenBaseIpfsURI;

        emit TokenBaseIPFSURIChanged(_tokenBaseIpfsURI);

        return true;
    }

    function overrideDynamicImageWithIpfsLink(uint256 _tokenId, string memory _ipfsHash)
    public
    onlyWhitelistedOrTokenOwner(_tokenId)
    returns (bool) {
        require(bytes(_ipfsHash).length != 0, "Base IPFS URI invalid");

        staticIpfsImageLink[_tokenId] = _ipfsHash;

        emit StaticIpfsTokenURISet(_tokenId, _ipfsHash);

        return true;
    }

    function clearIpfsImageUri(uint256 _tokenId)
    public
    onlyWhitelistedOrTokenOwner(_tokenId)
    returns (bool) {
        delete staticIpfsImageLink[_tokenId];

        emit StaticIpfsTokenURICleared(_tokenId);

        return true;
    }
}

 

pragma solidity 0.5.0;


contract NiftyFootballTradingCard is NiftyTradingCard {

    constructor (string memory _tokenBaseURI) public CustomERC721Full("Nifty Football Trading Card", "NFTFC") {
        super.addWhitelisted(msg.sender);
        tokenBaseURI = _tokenBaseURI;
    }
}