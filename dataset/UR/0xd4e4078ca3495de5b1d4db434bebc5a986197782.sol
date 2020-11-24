 

pragma solidity ^0.4.24;

 
interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}

contract Autoglyphs {

    event Generated(uint indexed index, address indexed a, string value);

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 512;  
    uint public constant ARTIST_PRINTS = 128;  

    uint public constant PRICE = 200 finney;

     
    address public constant BENEFICIARY = 0x50990F09d4f0cb864b8e046e7edC749dE410916b;

    mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;

     
    mapping(bytes4 => bool) internal supportedInterfaces;

     
    mapping (uint256 => address) internal idToOwner;

     
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;

     
    mapping (uint256 => address) internal idToApproval;

     
    mapping (address => mapping (address => bool)) internal ownerToOperators;

     
    mapping(address => uint256[]) internal ownerToIds;

     
    mapping(uint256 => uint256) internal idToOwnerIndex;

     
    uint internal numTokens = 0;

     
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }

     
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }

     
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true;  
        supportedInterfaces[0x80ac58cd] = true;  
        supportedInterfaces[0x780e9d63] = true;  
        supportedInterfaces[0x5b5e139f] = true;  
    }

     
     
     

    int constant ONE = int(0x100000000);
    uint constant USIZE = 64;
    int constant SIZE = int(USIZE);
    int constant HALF_SIZE = SIZE / int(2);

    int constant SCALE = int(0x1b81a81ab1a81a823);
    int constant HALF_SCALE = SCALE / int(2);

    bytes prefix = "data:text/plain;charset=utf-8,";

    string internal nftName = "Autoglyphs";
    string internal nftSymbol = "☵";

     
     
     
     
     
     
     
     
     

    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }

    function getScheme(uint a) internal pure returns (uint8) {
        uint index = a % 83;
        uint8 scheme;
        if (index < 20) {
            scheme = 1;
        } else if (index < 35) {
            scheme = 2;
        } else if (index < 48) {
            scheme = 3;
        } else if (index < 59) {
            scheme = 4;
        } else if (index < 68) {
            scheme = 5;
        } else if (index < 73) {
            scheme = 6;
        } else if (index < 77) {
            scheme = 7;
        } else if (index < 80) {
            scheme = 8;
        } else if (index < 82) {
            scheme = 9;
        } else {
            scheme = 10;
        }
        return scheme;
    }

     

     

    function draw(uint id) public view returns (string) {
        uint a = uint(uint160(keccak256(abi.encodePacked(idToSeed[id]))));
        bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
        uint c;
        for (c = 0; c < 30; c++) {
            output[c] = prefix[c];
        }
        int x = 0;
        int y = 0;
        uint v = 0;
        uint value = 0;
        uint mod = (a % 11) + 5;
        bytes5 symbols;
        if (idToSymbolScheme[id] == 0) {
            revert();
        } else if (idToSymbolScheme[id] == 1) {
            symbols = 0x2E582F5C2E;  
        } else if (idToSymbolScheme[id] == 2) {
            symbols = 0x2E2B2D7C2E;  
        } else if (idToSymbolScheme[id] == 3) {
            symbols = 0x2E2F5C2E2E;  
        } else if (idToSymbolScheme[id] == 4) {
            symbols = 0x2E5C7C2D2F;  
        } else if (idToSymbolScheme[id] == 5) {
            symbols = 0x2E4F7C2D2E;  
        } else if (idToSymbolScheme[id] == 6) {
            symbols = 0x2E5C5C2E2E;  
        } else if (idToSymbolScheme[id] == 7) {
            symbols = 0x2E237C2D2B;  
        } else if (idToSymbolScheme[id] == 8) {
            symbols = 0x2E4F4F2E2E;  
        } else if (idToSymbolScheme[id] == 9) {
            symbols = 0x2E232E2E2E;  
        } else {
            symbols = 0x2E234F2E2E;  
        }
        for (int i = int(0); i < SIZE; i++) {
            y = (2 * (i - HALF_SIZE) + 1);
            if (a % 3 == 1) {
                y = -y;
            } else if (a % 3 == 2) {
                y = abs(y);
            }
            y = y * int(a);
            for (int j = int(0); j < SIZE; j++) {
                x = (2 * (j - HALF_SIZE) + 1);
                if (a % 2 == 1) {
                    x = abs(x);
                }
                x = x * int(a);
                v = uint(x * y / ONE) % mod;
                if (v < 5) {
                    value = uint(symbols[v]);
                } else {
                    value = 0x2E;
                }
                output[c] = byte(bytes32(value << 248));
                c++;
            }
            output[c] = byte(0x25);
            c++;
            output[c] = byte(0x30);
            c++;
            output[c] = byte(0x41);
            c++;
        }
        string memory result = string(output);
        return result;
    }

     

    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function symbolScheme(uint _id) external view returns (uint8) {
        return idToSymbolScheme[_id];
    }

    function createGlyph(uint seed) external payable returns (string) {
        return _mint(msg.sender, seed);
    }

     
     
     

     
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) }  
        addressCheck = size > 0;
    }

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }

     
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

     
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

     
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }

     
    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

     
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
}

     
    function _mint(address _to, uint seed) internal returns (string) {
        require(_to != address(0));
        require(numTokens < TOKEN_LIMIT);
        uint amount = 0;
        if (numTokens >= ARTIST_PRINTS) {
            amount = PRICE;
            require(msg.value >= amount);
        }
        require(seedToId[seed] == 0);
        uint id = numTokens + 1;

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint a = uint(uint160(keccak256(abi.encodePacked(seed))));
        idToSymbolScheme[id] = getScheme(a);
        string memory uri = draw(id);
        emit Generated(id, _to, uri);

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        if (msg.value > amount) {
            msg.sender.transfer(msg.value - amount);
        }
        if (amount > 0) {
            BENEFICIARY.transfer(amount);
        }

        emit Transfer(address(0), _to, id);
        return uri;
    }

     
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;

        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }

     
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].length--;
    }

     
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

     
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

     
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

     

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < numTokens);
        return index;
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

     

     
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

     
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

     
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return draw(_tokenId);
    }

}