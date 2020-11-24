 

pragma solidity ^0.5.5;

 
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

 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        public returns (bytes4);
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

     
     
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) public _tokenOwner;

     
    mapping (address => uint256) public _ownedTokensCount;

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0xab7fecf1;
     

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

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(ownerOf(tokenId) == from);
        require(to != address(0));
        require(_checkOnERC721Received(from, to, tokenId, _data));
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to]= _ownedTokensCount[to].add(1);
        emit Transfer(address(0), to, tokenId);
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
}

 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {

     
    string internal _name;

     
    string internal _symbol;

     
    mapping(uint256 => string) internal _tokenURIs;

     
    mapping(uint256 => string) internal _tokenNames;

    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0xbc7bebe8;
     

     
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

     
    function tokenName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenNames[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

     

    function _substring(string memory _base, int _length, int _offset) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset+_length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
            for(uint i = uint(_offset); i < uint(_offset+_length); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            return string(_tmpBytes);
        }
}

 
contract GatherStandardTrophies is ERC721, ERC721Metadata {

     
    address public creator;

      
    modifier onlyCreator() {
        require(creator == msg.sender);
        _;
    }

     
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        name = _name;
        symbol = _symbol;
        creator = msg.sender;
    }

     
    function mintStandardTrophies(address[] memory winners, string memory uri) public onlyCreator {
        mintSchmoozerTrophy((winners[0]), _substring(uri,59,0));
        mintCupidTrophy((winners[1]), _substring(uri,59,59));
        mintMVPTrophy((winners[2]), _substring(uri,59,118));
        mintHumanRouterTrophy((winners[3]), _substring(uri,59,177));
        mintOracleTrophy((winners[4]), _substring(uri,59,236));
        mintKevinBaconTrophy((winners[5]), _substring(uri,59,295));
    }

     
    function mintSchmoozerTrophy(address winner, string memory uri) public onlyCreator {
        _mint(winner, 1);
        _tokenNames[1] = "Schmoozer Trophy";
        _tokenURIs[1] = uri;
    }

     
    function mintCupidTrophy(address winner, string memory uri) public onlyCreator  {
        _mint(winner, 2);
        _tokenNames[2] = "Cupid Trophy";
        _tokenURIs[2] = uri;
    } 
    
      
    function mintMVPTrophy(address winner, string memory uri) public onlyCreator {
        _mint(winner, 3);
        _tokenNames[3] = "MVP Trophy";
        _tokenURIs[3] = uri;
    } 

     
    function mintHumanRouterTrophy(address winner, string memory uri) public onlyCreator {
        _mint(winner, 4);
        _tokenNames[4] = "Human Router Trophy";
        _tokenURIs[4] = uri;
    }
    
     
    function mintOracleTrophy(address winner, string memory uri) public onlyCreator {
        _mint(winner, 5);
        _tokenNames[5] = "Oracle Trophy";
        _tokenURIs[5] = uri;
    } 


     
    function mintKevinBaconTrophy(address winner, string memory uri) public onlyCreator {
        _mint(winner, 6);
        _tokenNames[6] = "Kevin Bacon Trophy";
        _tokenURIs[6] = uri;
    }   

}