 

 

pragma solidity ^0.5.0;

 
interface ERC721
{

   
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

   
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

   
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

   
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

   
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

   
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

   
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);
    
   
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

 

pragma solidity ^0.5.0;

 
interface ERC721TokenReceiver
{

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);
    
}

 

pragma solidity ^0.5.0;

 
library SafeMath
{

   
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
     
     
     
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2);
  }

   
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
     
    require(_divisor > 0);
    quotient = _dividend / _divisor;
     
  }

   
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend);
    difference = _minuend - _subtrahend;
  }

   
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1);
  }

   
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0);
    remainder = _dividend % _divisor;
  }

}

 

pragma solidity ^0.5.0;

 
interface ERC165
{

   
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

 

pragma solidity ^0.5.0;


 
contract SupportsInterface is
  ERC165
{

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor ()
    public 
  {
    supportedInterfaces[0x01ffc9a7] = true;  
  }

   
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

 

pragma solidity ^0.5.0;

 
library AddressUtils
{

   
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    uint256 size;

     
    assembly { size := extcodesize(_addr) }  
    addressCheck = size > 0;
  }

}

 

pragma solidity ^0.5.0;






 
contract NFToken is
  ERC721,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

   
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal idToOwner;

   
  mapping (uint256 => address) internal idToApproval;

    
  mapping (address => uint256) private ownerToNFTokenCount;

   
  mapping (address => mapping (address => bool)) internal ownerToOperators;

   
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

   
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

   
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

   
  modifier canOperate(
    uint256 _tokenId
  ) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

   
  modifier canTransfer(
    uint256 _tokenId
  ) 
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

   
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

   
  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true;  
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

   
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

   
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256)
  {
    require(_owner != address(0));
    return _getOwnerNFTCount(_owner);
  }

   
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

   
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

   
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }
   
   
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(_to != address(0));
    require(idToOwner[_tokenId] == address(0));

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(
    uint256 _tokenId
  )
    internal
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

   
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == _from);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

   
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

   
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

   
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) 
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

   
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }

}

 

pragma solidity ^0.5.0;

 
interface ERC721Enumerable
{

   
  function totalSupply()
    external
    view
    returns (uint256);

   
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

 

pragma solidity ^0.5.0;



 
contract NFTokenEnumerable is
  NFToken,
  ERC721Enumerable
{

   
  uint256[] internal tokens;

   
  mapping(uint256 => uint256) internal idToIndex;

   
  mapping(address => uint256[]) internal ownerToIds;

   
  mapping(uint256 => uint256) internal idToOwnerIndex;

   
  constructor ()
    public
  {
    supportedInterfaces[0x780e9d63] = true;  
  }

   
  function totalSupply()
    external
    view
    returns (uint256)
  {
    return tokens.length;
  }

   
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < tokens.length);
    return tokens[_index];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length);
    return ownerToIds[_owner][_index];
  }

   
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    super._mint(_to, _tokenId);
    uint256 length = tokens.push(_tokenId);
    idToIndex[_tokenId] = length - 1;
  }

   
  function _burn(
    uint256 _tokenId
  )
    internal
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.length--;
     
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

   
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == _from);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].length--;
  }

   
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == address(0));
    idToOwner[_tokenId] = _to;

    uint256 length = ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length - 1;
  }

   
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }
}

 

pragma solidity ^0.5.0;

 
contract Ownable
{
  
   
  string public constant NOT_OWNER = "018001";
  string public constant ZERO_ADDRESS = "018002";

   
  address public owner;

   
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor ()
    public
  {
    owner = msg.sender;
  }

   
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_OWNER);
    _;
  }

   
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

 

pragma solidity ^0.5.0;



 
contract NFTokenEnumerableMock is
  NFTokenEnumerable,
  Ownable
{

   
  function mint(
    address _to,
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
  }

   
  function burn(
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_tokenId);
  }

}

 

pragma solidity ^0.5.0;

 
interface ERC721Metadata
{

   
  function name()
    external
    view
    returns (string memory _name);

   
  function symbol()
    external
    view
    returns (string memory _symbol);

   
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

 

pragma solidity ^0.5.0;



 
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

   
  string internal nftName;

   
  string internal nftSymbol;

   
  mapping (uint256 => string) internal idToUri;

   
  constructor ()
    public
  {
    supportedInterfaces[0x5b5e139f] = true;  
  }

   
  function name()
    external
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

   
  function symbol()
    external
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

   
  function tokenURI(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }

   
  function _burn(
    uint256 _tokenId
  )
    internal
  {
    super._burn(_tokenId);

    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

   
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}

 

pragma solidity ^0.5.0;




 
contract NFTokenMetadataEnumerableMock is
  NFTokenEnumerable,
  NFTokenMetadata,
  Ownable
{

   
  constructor (
    string memory _name,
    string memory _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
  }

   
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

   
  function burn(
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_tokenId);
  }

}

 

pragma solidity ^0.5.0;



 
contract NFTokenMetadataMock is
  NFTokenMetadata,
  Ownable
{

   
  constructor (
    string memory _name,
    string memory _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
  }

   
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

   
  function burn(
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_tokenId);
  }

}

 

pragma solidity ^0.5.0;



 
contract NFTokenMock is
  NFToken,
  Ownable
{

   
  function mint(
    address _to,
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._mint(_to, _tokenId);
  }

}

 

pragma solidity ^0.5.0;




contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract LinkerProxyNFT058 is
  NFTokenMetadata,
  NFTokenEnumerable,
  Ownable
{
  address proxyRegistryAddress;
  constructor (
    string memory _name,
    string memory _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
    proxyRegistryAddress = msg.sender;
  }

   
  function proxyAddress()
    external
    view
    returns (address _proxyAddress)
  {
    _proxyAddress = proxyRegistryAddress;
  }


   
  function mint(
    address _owner,
    uint256 _id,
    string calldata _uri
  )
    onlyOwner
    external
  {
    super._mint(_owner, _id);
    super._setTokenUri(_id, _uri);
    this.setApprovalForAll(proxyRegistryAddress, true);
  }

  function burn(
    uint256 _tokenId
  )
    onlyOwner
    external
  {
    super._burn(_tokenId);
  }

   
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
  {
    if (address(proxyRegistryAddress) == _operator){
      this.setApprovalForAll(_operator, true);
    }
    this.setApprovalForAll(_operator, _approved);
  }
}

 

pragma solidity ^0.5.0;





contract LinkerCommonNFT058 is
  NFTokenMetadata,
  NFTokenEnumerable,
  Ownable
{
  constructor (
    string memory _name,
    string memory _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
  }

   
  function mint(
    address _owner,
    uint256 _id,
    string calldata _uri
  )
    onlyOwner
    external
  {
    super._mint(_owner, _id);
    super._setTokenUri(_id, _uri);
  }

  function burn(
    uint256 _tokenId
  )
    onlyOwner
    external
  {
    super._burn(_tokenId);
  }
}

 

pragma solidity ^0.5.0;





contract Unchain is
  NFTokenMetadata,
  NFTokenEnumerable,
  Ownable
{
  constructor (
    string memory _name,
    string memory _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
  }

   
  function mint(
    address _owner,
    uint256 _id,
    string calldata _uri
  )
    onlyOwner
    external
  {
    super._mint(_owner, _id);
    super._setTokenUri(_id, _uri);
  }

  function burn(
    uint256 _tokenId
  )
    onlyOwner
    external
  {
    super._burn(_tokenId);
  }
}