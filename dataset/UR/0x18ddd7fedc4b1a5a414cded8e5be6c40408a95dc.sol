 

 

pragma solidity ^0.4.24;

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.4.24;


 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 

pragma solidity ^0.4.24;

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

 

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

 

pragma solidity ^0.4.24;

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

pragma solidity ^0.4.24;


 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 

pragma solidity ^0.4.24;






 
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
    _registerInterface(_InterfaceId_ERC721);
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

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

   
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

 

pragma solidity ^0.4.24;


 
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.4.24;




contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
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

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

     
     
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
     
    _ownedTokens[from].length--;

     
     
     

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

 

pragma solidity ^0.4.24;


 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

 

pragma solidity ^0.4.24;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

   
  function _setTokenURI(uint256 tokenId, string uri) internal {
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

 

pragma solidity ^0.4.24;




 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

 

pragma solidity ^0.4.24;

 


contract Landemic is ERC721Full("Landemic","LAND") {

    uint256 public _basePrice = 810000000000000;  
    uint8 public _bountyDivisor = 20;  
    uint16 public _defaultMultiple = 100;  
    address public _owner = msg.sender;
    string public _baseURL = "https://landemic.io/";

    struct Price {
        uint240 lastPrice;
        uint16 multiple;
    }
    mapping(uint256 => Price) public _prices;

     
     
    mapping(address => uint256) public failedPayouts;
    uint256 public failedPayoutsSum;

     

    modifier onlyContractOwner() {
        require(msg.sender == _owner);
        _;
    }

    function _lastPrice(uint256 tokenId) public view returns (uint256) {
        return uint256(_prices[tokenId].lastPrice);
    }

    function _multiple(uint256 tokenId) public view returns (uint16) {
        return _prices[tokenId].multiple;
    }

    function setBasePrice(uint256 basePrice) onlyContractOwner public {
        _basePrice = basePrice;
    }

    function setBountyDivisor(uint8 bountyDivisor) onlyContractOwner public {
        _bountyDivisor = bountyDivisor;
    }

    function setBaseURL(string baseURL) public onlyContractOwner {
        _baseURL = baseURL;
    }

    function setOwner(address owner) onlyContractOwner public {
        _owner = owner;
    }

     
     
    function withdraw(uint256 amount) onlyContractOwner public {
        msg.sender.transfer(amount);
    }

    function withdrawProfit() onlyContractOwner public {
        msg.sender.transfer(address(this).balance.sub(failedPayoutsSum));
    }

     

    function getAllOwned() public view returns (uint256[], address[]) {

        uint totalOwned = totalSupply();

        uint256[] memory ownedUint256 = new uint256[](totalOwned);
        address[] memory ownersAddress = new address[](totalOwned);

        for (uint i = 0; i < totalOwned; i++) {
            ownedUint256[i] = tokenByIndex(i);
            ownersAddress[i] = ownerOf(ownedUint256[i]);
        }

        return (ownedUint256, ownersAddress);

    }

    function metadataForToken(uint256 tokenId) public view returns (uint256, address, uint16, uint256) {
        uint256 price = priceOf(tokenId);

        if (_exists(tokenId)) {
            return (_lastPrice(tokenId), ownerOf(tokenId), multipleOf(tokenId), price);
        }
        return (_basePrice, 0, 10, price);
    }

    function priceOf(uint256 tokenId) public view returns (uint256) {
        if (_exists(tokenId)) {
            return _lastPrice(tokenId).mul(uint256(multipleOf(tokenId))).div(10);
        }
        return _basePrice;
    }

    function multipleOf(uint256 tokenId) public view returns (uint16) {
        uint16 multiple = _multiple(tokenId);
        if (multiple > 0) {
            return multiple;
        }
        return _defaultMultiple;
    }

     

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId));
        _;
    }

    function setMultiple(uint256 tokenId, uint16 multiple) public onlyTokenOwner(tokenId) {
        require(multiple >= 1 && multiple <= 1000);
        _prices[tokenId].multiple = multiple;
    }

     

     
     
     
     
     
     



    function _pushOrDelayBounty(address to, uint256 amount) internal {
        bool success = to.send(amount);
        if (!success) {
            failedPayouts[to] = failedPayouts[to].add(amount);
            failedPayoutsSum = failedPayoutsSum.add(amount);
        }
    }

    function grabCode(uint256 tokenId) public payable {
         

        uint256 price = priceOf(tokenId);   
        require(msg.value >= price);

        _prices[tokenId] = Price(uint240(msg.value), uint16(0));

        if (!_exists(tokenId)) {
            _mint(msg.sender, tokenId);
            return;
        }

        address owner = ownerOf(tokenId);
        require(owner != msg.sender);

        _burn(owner, tokenId);
        _mint(msg.sender, tokenId);

        uint256 bounty = msg.value.div(_bountyDivisor);   
        uint256 bountiesCount = 1;  
        uint256[4] memory neighbors = neighborsOfToken(tokenId);
        for (uint i = 0; i < 4; i++) {
            uint256 neighbor = neighbors[i];
            if (!_exists(neighbor)) {
                continue;
            }
            _pushOrDelayBounty(ownerOf(neighbor), bounty);
            bountiesCount++;
        }

        _pushOrDelayBounty(owner, msg.value.sub(bounty.mul(bountiesCount)));   
    }

    function pullBounty(address to) public {
        uint256 bounty = failedPayouts[msg.sender];
        if (bounty == 0) {
            return;
        }
        failedPayouts[msg.sender] = 0;
        failedPayoutsSum = failedPayoutsSum.sub(bounty);
        to.transfer(bounty);
    }


     

     
    function tokenURI(uint256 _tokenId) external view returns (string) {
        require(_exists(_tokenId));
        return strConcat(strConcat(_baseURL, uint256ToString(_tokenId)),".json");
    }

     

     
    function uint256ToString(uint256 y) private pure returns (string) {
        bytes32 x = bytes32(y);
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory testEmptyStringTest = bytes(source);
        if (testEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

     
    function strConcat(string _a, string _b) private pure returns (string) {
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory ab = new string (bytes_a.length + bytes_b.length);
        bytes memory bytes_ab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < bytes_a.length; i++) bytes_ab[k++] = bytes_a[i];
        for (i = 0; i < bytes_b.length; i++) bytes_ab[k++] = bytes_b[i];
        return string(bytes_ab);
    }

     

    bytes20 constant DIGITS = bytes20('23456789CFGHJMPQRVWX');
    bytes20 constant STIGID = bytes20('XWVRQPMJHGFC98765432');

    function nextChar(byte c, bytes20 digits) private pure returns (byte) {
        for (uint i = 0; i < 20; i++)
            if (c == digits[i])
                return (i == 19) ? digits[0] : digits[i+1];

    }

    function replaceChar(uint256 tokenId, uint pos, byte c) private pure returns (uint256) {

        uint shift = (8 - pos) * 8;
        uint256 insert = uint256(c) << shift;
        uint256 mask = ~(uint256(0xff) << shift);

        return tokenId & mask | insert;
    }

    function incrementChar(uint256 tokenId, int pos, bytes20 digits) private pure returns (uint256) {

        if (pos < 0)
            return tokenId;

        byte c = nextChar(bytes32(tokenId)[23 + uint(pos)], digits);
        uint256 updated = replaceChar(tokenId, uint(pos), c);
        if (c == digits[0]) {
            int nextPos = pos - 2;
            byte nextPosChar = bytes32(updated)[23 + uint(nextPos)];
             
            if (nextPos == 1) {
                if (digits == DIGITS && nextPosChar == 'V') {
                    return replaceChar(updated, uint(nextPos), '2');
                }
                if (digits == STIGID && nextPosChar == '2') {
                    return replaceChar(updated, uint(nextPos), 'V');
                }
            }
             
            if (nextPos == 0) {
                if (digits == DIGITS && nextPosChar == 'C') {
                    return replaceChar(updated, uint(nextPos), '2');
                }
                if (digits == STIGID && nextPosChar == '2') {
                    return replaceChar(updated, uint(nextPos), 'C');
                }
            }
            return incrementChar(updated, nextPos, digits);
        }
        return updated;
    }

    function northOfToken(uint256 tokenId) public pure returns (uint256) {
        return incrementChar(tokenId, 6, DIGITS);
    }

    function southOfToken(uint256 tokenId) public pure returns (uint256) {
        return incrementChar(tokenId, 6, STIGID);
    }

    function eastOfToken(uint256 tokenId) public pure returns (uint256) {
        return incrementChar(tokenId, 7, DIGITS);
    }

    function westOfToken(uint256 tokenId) public pure returns (uint256) {
        return incrementChar(tokenId, 7, STIGID);
    }

    function neighborsOfToken(uint256 tokenId) public pure returns (uint256[4]) {
        return [
            northOfToken(tokenId),
            eastOfToken(tokenId),
            southOfToken(tokenId),
            westOfToken(tokenId)
        ];
    }

}