 

pragma solidity ^0.4.24;

 

 
interface ERC721 {

   
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

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
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

 

 
interface ERC721TokenReceiver {

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    external
    returns(bytes4);
    
}

 

 
library SafeMath {

   
  function mul(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a / _b;
     
     
    return c;
  }

   
  function sub(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

 

 
interface ERC165 {

   
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

 

 
contract SupportsInterface is
  ERC165
{

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
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

 

 
library AddressUtils {

   
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool)
  {
    uint256 size;

     
    assembly { size := extcodesize(_addr) }  
    return size > 0;
  }

}

 

 
contract NFToken is
  ERC721,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

   
  mapping (uint256 => address) internal idToOwner;

   
  mapping (uint256 => address) internal idToApprovals;

    
  mapping (address => uint256) internal ownerToNFTokenCount;

   
  mapping (address => mapping (address => bool)) internal ownerToOperators;

   
  bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

   
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
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

   
  modifier canTransfer(
    uint256 _tokenId
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || getApproved(_tokenId) == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );

    _;
  }

   
  modifier validNFToken(
    uint256 _tokenId
  ) {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

   
  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true;  
  }

   
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256)
  {
    require(_owner != address(0));
    return ownerToNFTokenCount[_owner];
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

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
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

    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

   
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
  {
    require(_operator != address(0));
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
  function getApproved(
    uint256 _tokenId
  )
    public
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApprovals[_tokenId];
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool)
  {
    require(_owner != address(0));
    require(_operator != address(0));
    return ownerToOperators[_owner][_operator];
  }

   
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

   
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    private
  {
    address from = idToOwner[_tokenId];
    clearApproval(_tokenId);

    removeNFToken(from, _tokenId);
    addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }
   
   
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(_to != address(0));
    require(_tokenId != 0);
    require(idToOwner[_tokenId] == address(0));

    addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(
    address _owner,
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    internal
  {
    clearApproval(_tokenId);
    removeNFToken(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(
    uint256 _tokenId
  )
    private
  {
    if(idToApprovals[_tokenId] != 0)
    {
      delete idToApprovals[_tokenId];
    }
  }

   
  function removeNFToken(
    address _from,
    uint256 _tokenId
  )
   internal
  {
    require(idToOwner[_tokenId] == _from);
    assert(ownerToNFTokenCount[_from] > 0);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

   
  function addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

}

 

 
interface ERC721Metadata {

   
  function name()
    external
    view
    returns (string _name);

   
  function symbol()
    external
    view
    returns (string _symbol);

   
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string);

}

 

 
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

   
  string internal nftName;

   
  string internal nftSymbol;

   
  mapping (uint256 => string) internal idToUri;

   
  constructor()
    public
  {
    supportedInterfaces[0x5b5e139f] = true;  
  }

   
  function _burn(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    super._burn(_owner, _tokenId);

    if (bytes(idToUri[_tokenId]).length != 0) {
      delete idToUri[_tokenId];
    }
  }

   
  function _setTokenUri(
    uint256 _tokenId,
    string _uri
  )
    validNFToken(_tokenId)
    internal
  {
    idToUri[_tokenId] = _uri;
  }

   
  function name()
    external
    view
    returns (string _name)
  {
    _name = nftName;
  }

   
  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = nftSymbol;
  }

   
  function tokenURI(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    external
    view
    returns (string)
  {
    return idToUri[_tokenId];
  }

}

 

 
contract Ownable {
  address public owner;

   
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor()
    public
  {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

 

contract ArtworkToken is
  NFTokenMetadata,
  Ownable
{

  constructor(
    string _name,
    string _symbol
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
  }

  function mint(
    address _owner,
    uint256 _id
  )
    onlyOwner
    external
  {
    super._mint(_owner, _id);
  }

  function burn(
    address _owner,
    uint256 _tokenId
  )
    onlyOwner
    external
  {
    super._burn(_owner, _tokenId);
  }

  function setTokenUri(
    uint256 _tokenId,
    string _uri
  )
    onlyOwner
    external
  {
    super._setTokenUri(_tokenId, _uri);
  }

}