 

pragma solidity 0.5.6;




 
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


 
interface ERC165
{

   
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

   
  function ownerOf(uint256 _tokenId)
  public
  view
  returns (address) {
    address _owner = idToOwner[_tokenId];
    require(_owner != address(0));
    return _owner;
  }

  function isOwner(uint256 _tokenId, address _addr)
  public
  view
  returns (bool) {
    return idToOwner[_tokenId] == _addr && _addr != address(0);
  }

   
  function getApproved(uint256 _tokenId)
  public
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
    public
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

 
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

   
  string internal nftName;

   
  string internal gateway;

   
  string internal nftSymbol;

   
  mapping (uint256 => string) internal _idToUri;

   
  constructor()
    public
  {
    supportedInterfaces[0x5b5e139f] = true;  
  }

  function idToUri(uint256 _tokenID)
  public
  view
  returns (string memory){
    return _idToUri[_tokenID];
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

   
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    _idToUri[_tokenId] = _uri;
  }

     
  function tokenURI(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return strConcat(ipfsGateway(), _idToUri[_tokenId]);
  }

   
  function ipfsGateway() public view returns (string memory) {
    return gateway;
  }

   
  function _setBaseURI(string memory _newBase)
  internal {
    gateway = _newBase;
  }

  function strConcat(string memory _a, string memory _b)
  internal
  pure
  returns (string memory) {
    bytes memory aa = bytes(_a);
    bytes memory bb = bytes(_b);
    string memory ab = new string(aa.length + bb.length);
    bytes memory bytes_ab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < aa.length; i++) bytes_ab[k++] = aa[i];
    for (uint i = 0; i < bb.length; i++) bytes_ab[k++] = bb[i];
    return string(bytes_ab);
  }
}

 
contract Ownable
{
  
   
  string public constant NOT_OWNER = "018001";
  string public constant ZERO_ADDRESS = "018002";

   
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

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

 
contract Galaxia is
  NFTokenMetadata,
  Ownable
{
  address public proxyRegistryAddress;
  mapping (bytes32 => bool) public validUpgrade;
  uint256 public totalSupply;

   
  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress)
  public {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftName = _name;
    nftSymbol = _symbol;
    gateway = "https://cloudflare-ipfs.com/ipfs/";
  }

   
  function mint(address _to, string calldata _uri)
  external
  onlyOwner {
    super._mint(_to, totalSupply);
    super._setTokenUri(totalSupply, _uri);
    totalSupply++;
  }

     
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    returns (bool) {
     
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

     
  function addUpgradePath(uint256 _tokenId, string calldata _newURI, uint8 _version) external onlyOwner {
    require(_tokenId < totalSupply);
    bytes32 upgradeHash = keccak256(abi.encodePacked(_tokenId, _newURI));
    validUpgrade[upgradeHash] = true;
    emit UpgradePathAdded(_tokenId, _newURI, _version);
  }

     
  function upgradeMetadata(uint256 _tokenId, string calldata _newURI) external  {
    require(super.isOwner(_tokenId, msg.sender));
    bytes32 upgradeHash = keccak256(abi.encodePacked(_tokenId, _newURI));
    require(validUpgrade[upgradeHash]);
    string memory oldURI = idToUri(_tokenId);
    super._setTokenUri(_tokenId, _newURI);
    emit MetadataUpgraded(oldURI, _newURI);
  }

   
  function changeGateway(string calldata _gatewayURL) external onlyOwner {
    require(bytes(_gatewayURL).length > 0);
    emit GatewayChanged(gateway, _gatewayURL);
    gateway = _gatewayURL;
  }


  event MetadataUpgraded(string indexed _oldURI, string _newURI);
  event UpgradePathAdded(uint256 indexed _tokenID, string _newURI, uint8 _version);
  event GatewayChanged(string indexed _old, string _new);

}