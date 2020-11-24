 

pragma solidity ^0.4.24;

 


 
contract IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract IERC721 {
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public;
}


 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns (bytes4);
}


 
contract ERC165 is IERC165 {
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


 
contract IERC721Metadata {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function tokenURI(uint256 tokenId) external view returns (string);
}


 
contract IERC721Enumerable {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


contract ERC20Token {
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}


 
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


 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

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


 
contract MemeAwards2018 is ERC165, IERC721, IERC721Metadata, IERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string private _name;
    string private _symbol;
    uint256 private releaseDate;
    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
     
    mapping (address => bool) public hasClaimed;

     
    struct Meme {
        uint32 templateId;
    }
    
     
    struct Template {
        string uri;
    }
    
     
    Meme[] private claimedMemes;
    
     
    Template[] private memeTemplates;

     
    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }
    
     
    modifier canClaim() {
        require(releaseDate + 30 days >= now);
        _;
    }
    
    constructor(string name, string symbol) public {
         
        _name = name;
         
        _symbol = symbol;
         
        _registerInterface(InterfaceId_ERC721Metadata);
         
        _registerInterface(_InterfaceId_ERC721Enumerable);
         
        _registerInterface(_InterfaceId_ERC721);
         
        releaseDate = now;
    }
    
     
    function _randomMeme() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(now, msg.sender))) % 10);
    }
    
     
    function claimMeme() public hasNotClaimed canClaim {
         
        uint32 randomMemeId = _randomMeme();
         
        uint id = claimedMemes.push(Meme(randomMemeId)) -1;
         
        _mint(msg.sender, id);
         
        hasClaimed[msg.sender] = true;
    }
    
     
     
    function getIndividualCount(uint32 _templateId) external view returns (uint) {
        uint counter = 0;
        for (uint i = 0; i < claimedMemes.length; i++) {
            if (claimedMemes[i].templateId == _templateId) {
                counter++;
            }
        }
         
        return counter;
    }
    
     
    function getMemesByOwner(address _owner) public view returns(uint[]) {
        uint[] memory result = new uint[](_ownedTokensCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < claimedMemes.length; i++) {
            if (_tokenOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
         
        return result;
    }
    
     
    function getEndTime() external view returns (uint) {
        return releaseDate + 30 days;
    }

     
    function withdrawERC20Tokens(address _tokenContract) external onlyOwner returns (bool) {
        ERC20Token token = ERC20Token(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(msg.sender, amount);
    }
    
     
    function withdraw() external onlyOwner {
        uint256 etherBalance = address(this).balance;
        msg.sender.transfer(etherBalance);
    }
    
     
    function setMemeTemplate(string _uri) external onlyOwner {
        require(memeTemplates.length < 10);
        memeTemplates.push(Template(_uri));
    }
    
     
     
    function editMemeTemplate(uint _templateId, string _newUri) external onlyOwner {
        memeTemplates[_templateId].uri = _newUri;
    }
    
     
    function totalSupply() public view returns (uint256) {
        return claimedMemes.length;
    }
    
     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return claimedMemes[_index].templateId;
    }
    
     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId) {
        require(index < balanceOf(owner));
        return getMemesByOwner(owner)[index];
    }

     
    function name() external view returns (string) {
        return _name;
    }

     
    function symbol() external view returns (string) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        uint tokenTemplateId = claimedMemes[tokenId].templateId;
        return memeTemplates[tokenTemplateId].uri;
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

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
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

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
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