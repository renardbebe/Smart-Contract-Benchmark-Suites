 

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.25;

library Groups {
    struct MemberMap {
        mapping(address => bool) members;
    }

    struct GroupMap {
        mapping(uint8 => MemberMap) groups;
    }

     
    function add(GroupMap storage map, uint8 groupId, address account) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(!groupContains(group, account));

        group.members[account] = true;
    }

     
    function remove(GroupMap storage map, uint8 groupId, address account) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(groupContains(group, account));

        group.members[account] = false;
    }

     
    function contains(GroupMap storage map, uint8 groupId, address account) internal view returns (bool) {
        MemberMap storage group = map.groups[groupId];
        return groupContains(group, account);
    }

    function groupContains(MemberMap storage group, address account) internal view returns (bool) {
        require(account != address(0));
        return group.members[account];
    }
}

 

pragma solidity ^0.4.24;

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 

pragma solidity ^0.4.24;


contract ERC165Map is ERC165 {
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[INTERFACE_ID_ERC165] = true;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    function _addInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.4.24;

 
 
 
interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external payable;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

pragma solidity ^0.4.24;

 
 
 
interface ERC721Metadata   {
     
    function name() external view returns (string);

     
    function symbol() external view returns (string);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 

pragma solidity ^0.4.24;

interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns (bytes4);
}

 

pragma solidity ^0.4.24;

 
 
 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 

pragma solidity ^0.4.24;








contract Qri is ERC165Map, ERC721, ERC721Metadata, ERC721Enumerable {
    using Groups for Groups.GroupMap;
    using SafeMath for uint256;

    uint8 public constant ADMIN = 1;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    string private tokenName;
    string private tokenSymbol;

    bool public unrestrictedMinting;

    Groups.GroupMap groups;

    address public tokenOwner;

    uint256[] private allTokens;
    mapping(uint256 => uint256) private tokenIndex;
    mapping(uint256 => address) private owners;
    mapping(address => uint256[]) private ownedTokens;
    mapping(uint256 => uint256) private ownedTokensIndex;
    mapping(uint256 => address) private approval;
    mapping(address => uint256) private tokenCount;
    mapping(address => mapping(address => bool)) private operatorApproval;
    mapping(uint256 => string) private uri;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);

    constructor(string _name, string _symbol) public {
        _addInterface(INTERFACE_ID_ERC721);
        _addInterface(INTERFACE_ID_ERC721_METADATA);
        _addInterface(INTERFACE_ID_ERC721_ENUMERABLE);

        tokenName = _name;
        tokenSymbol = _symbol;

        _addAdmin(msg.sender);
        tokenOwner = msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Must be an admin");
        _;
    }

    function unrestrictMinting() public onlyAdmin {
        unrestrictedMinting = true;
    }

    function restrictMinting() public onlyAdmin {
        unrestrictedMinting = false;
    }

    function name() external view returns (string) {
        return tokenName;
    }

    function symbol() external view returns (string) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0));
        return tokenCount[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0));
        return owner;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return allTokens[index];
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return approval[tokenId];
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return operatorApproval[account][operator];
    }

    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return uri[tokenId];
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function _addAdmin(address account) internal {
        groups.add(ADMIN, account);
        emit AddedToGroup(ADMIN, account);
    }

    function removeAdmin(address account) public onlyAdmin {
        groups.remove(ADMIN, account);
        emit RemovedFromGroup(ADMIN, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return groups.contains(ADMIN, account);
    }

    function approve(address account, uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        approval[tokenId] = account;
        emit Approval(owner, account, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        operatorApproval[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, ""));
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external payable {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data));
    }

    function mint(address to, uint256 tokenId) public onlyAdmin returns (bool) {
        _mint(to, tokenId);
        return true;
    }

    function mintWithTokenURI(address to, uint256 tokenId, string URIForToken) public onlyAdmin returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, URIForToken);
        return true;
    }

    function addQr(uint256 tokenId) public returns (bool) {
        if (!unrestrictedMinting) {
            require(isAdmin(msg.sender), "Must be an admin");
        }
        _mint(tokenOwner, tokenId);
        _setTokenURI(tokenId, concat("https://qr.blockwell.ai/qri/", uint2str(tokenId)));
        return true;
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        _burn(msg.sender, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);

        tokenIndex[tokenId] = allTokens.length;
        allTokens.push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(address account, uint256 tokenId) internal {
        _clearApproval(account, tokenId);
        _removeTokenFrom(account, tokenId);

        if (bytes(uri[tokenId]).length != 0) {
            delete uri[tokenId];
        }

         
        uint256 index = tokenIndex[tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[index] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        tokenIndex[tokenId] = 0;
        tokenIndex[lastToken] = index;

        emit Transfer(account, address(0), tokenId);
    }

    function _addTokenTo(address to, uint256 tokenId) internal {
        require(owners[tokenId] == address(0));
        owners[tokenId] = to;
        tokenCount[to] = tokenCount[to].add(1);

        ownedTokens[to].push(tokenId);
        ownedTokensIndex[tokenId] = ownedTokens[to].length - 1;
    }

    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        tokenCount[from] = tokenCount[from].sub(1);
        owners[tokenId] = address(0);

         
        uint256 index = ownedTokensIndex[tokenId];
        uint256 lastTokenIndex = ownedTokens[from].length.sub(1);
        uint256 lastToken = ownedTokens[from][lastTokenIndex];

        ownedTokens[from][index] = lastToken;
        ownedTokens[from].length--;

        ownedTokensIndex[tokenId] = 0;
        ownedTokensIndex[lastToken] = index;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes data) internal returns (bool) {
        if (!isContract(to)) {
            return true;
        }
        ERC721TokenReceiver receiver = ERC721TokenReceiver(to);
        bytes4 retval = receiver.onERC721Received(msg.sender, from, tokenId, data);
        return (retval == receiver.onERC721Received.selector);
    }

    function _clearApproval(address account, uint256 tokenId) private {
        require(ownerOf(tokenId) == account);
        if (approval[tokenId] != address(0)) {
            approval[tokenId] = address(0);
        }
    }

    function _setTokenURI(uint256 tokenId, string newURI) internal {
        require(_exists(tokenId));
        uri[tokenId] = newURI;
    }


    function concat(string memory a, string memory b) internal pure returns (string memory) {
        uint256 aLength = bytes(a).length;
        uint256 bLength = bytes(b).length;
        string memory value = new string(aLength + bLength);
        uint valuePointer;
        uint aPointer;
        uint bPointer;
        assembly {
            valuePointer := add(value, 32)
            aPointer := add(a, 32)
            bPointer := add(b, 32)
        }
        copy(aPointer, valuePointer, aLength);
        copy(bPointer, valuePointer + aLength, bLength);
        return value;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function copy(uint src, uint dest, uint len) internal pure {
         
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}