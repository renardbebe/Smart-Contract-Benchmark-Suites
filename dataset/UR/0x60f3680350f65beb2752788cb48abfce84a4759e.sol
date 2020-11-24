 

pragma solidity ^0.4.24;

     

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}

contract Autoglyphs { 
  function draw(uint id) public view returns (string);
  function ownerOf(uint256 _tokenId) external view returns (address);
}

contract Colorglyphs {

    event Generated(uint indexed index, address indexed a, string value);

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant CLAIMABLE_TOKEN_LIMIT = 512;
    uint public constant CREATEABLE_TOKEN_LIMIT = 512;
    uint public constant TOTAL_TOKEN_LIMIT = 1024;
    uint public constant ARTIST_PRINTS = 32;

    uint public constant PRICE = 50 finney;

     
    address public constant BENEFICIARY = 0xb189f76323678E094D4996d182A792E52369c005;

    address public autoglyphsAddress = 0xd4e4078ca3495de5b1d4db434bebc5a986197782;

     
    mapping (uint256 => bool) private idToGlyphIsClaimed;

     
    mapping (uint => address) private idToCreator;
     
    mapping (uint => string) private idToColorScheme;

     
    mapping(bytes4 => bool) internal supportedInterfaces;

     
    mapping (uint256 => address) internal idToOwner;

     
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;

     
    mapping (uint256 => address) internal idToApproval;

     
    mapping (address => mapping (address => bool)) internal ownerToOperators;

     
    mapping(address => uint256[]) internal ownerToIds;

     
    mapping(uint256 => uint256) internal idToOwnerIndex;

     
    uint internal numCreatedTokens = 0;

     
    uint internal numClaimedTokens = 0;

     
    uint internal numTotalTokens = 0;

     
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

    string internal nftName = "Colorglyphs";
    string internal nftSymbol = "☲";

     
     
     

    function draw(uint256 _tokenId) public view returns (string memory) {
        Autoglyphs autoglyphs = Autoglyphs(autoglyphsAddress);
        uint autoglyphsTokenId;
        if (_tokenId > 512) {
            autoglyphsTokenId = _tokenId - 512;
        } else {
            autoglyphsTokenId = _tokenId;
        }
        string memory drawing = autoglyphs.draw(autoglyphsTokenId);
        string memory scheme = idToColorScheme[_tokenId];
        string memory creator_address = toAsciiString(idToCreator[_tokenId]);
        return Strings.strConcat(
            drawing,
            scheme,
            creator_address
        );
    }

    function getScheme(uint a) internal pure returns (string) {
        uint index = a % 83;
        string memory scheme;
        if (index < 20) {
            scheme = ' 1 ';
        } else if (index < 35) {
            scheme = ' 2 ';
        } else if (index < 48) {
            scheme = ' 3 ';
        } else if (index < 59) {
            scheme = ' 4 ';
        } else if (index < 68) {
            scheme = ' 5 ';
        } else if (index < 73) {
            scheme = ' 6 ';
        } else if (index < 77) {
            scheme = ' 7 ';
        } else if (index < 80) {
            scheme = ' 8 ';
        } else if (index < 82) {
            scheme = ' 9 ';
        } else {
            scheme = ' 10 ';
        }
        return scheme;
    }

    function toAsciiString(address x) returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
        byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        byte hi = byte(uint8(b) / 16);
        byte lo = byte(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(byte b) returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function colorScheme(uint _id) external view returns (string) {
        return idToColorScheme[_id];
    }

    function createGlyph(uint seed) external payable returns (string) {
        return _mint(msg.sender, seed, false, 0);
    }

    function claimGlyph(uint seed, uint idBeingClaimed) external payable returns (string) {
        return _mint(msg.sender, seed, true, idBeingClaimed);
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

     
    function _mint(address _to, uint seed, bool autoglyphOwnerIsClaimingToken, uint idBeingClaimed) internal returns (string) {
        require(_to != address(0));
        require(numCreatedTokens < CREATEABLE_TOKEN_LIMIT);
        require(numClaimedTokens < CLAIMABLE_TOKEN_LIMIT);
        require(numTotalTokens < TOTAL_TOKEN_LIMIT);
        if (autoglyphOwnerIsClaimingToken) {
            Autoglyphs autoglyphs = Autoglyphs(autoglyphsAddress);
            require(idToGlyphIsClaimed[idBeingClaimed] == false);
            require(autoglyphs.ownerOf(idBeingClaimed) == msg.sender);
        }
        uint amount = 0;
        if (numCreatedTokens >= ARTIST_PRINTS && autoglyphOwnerIsClaimingToken == false) {
            amount = PRICE;
            require(msg.value >= amount);
        }
        require(seedToId[seed] == 0);
        uint id;
        if (autoglyphOwnerIsClaimingToken) {
            id = idBeingClaimed + 512;
        } else {
            id = numCreatedTokens + 1;
        }

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint a = uint(uint160(keccak256(abi.encodePacked(seed))));
        idToColorScheme[id] = getScheme(a);
        string memory uri = draw(id);
        emit Generated(id, _to, uri);

        numTotalTokens = numTotalTokens + 1;
        if (autoglyphOwnerIsClaimingToken) {
            numClaimedTokens = numClaimedTokens + 1;
        } else {
            numCreatedTokens = numCreatedTokens + 1;
        }
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
        return numTotalTokens;
    }

    function totalCreatedSupply() public view returns (uint256) {
        return numCreatedTokens;
    }

    function totalClaimedSupply() public view returns (uint256) {
        return numClaimedTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < TOTAL_TOKEN_LIMIT);
        if (index < CREATEABLE_TOKEN_LIMIT) {
            require(index < numCreatedTokens);
        } else {
            require(idToGlyphIsClaimed[index]);
        }
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