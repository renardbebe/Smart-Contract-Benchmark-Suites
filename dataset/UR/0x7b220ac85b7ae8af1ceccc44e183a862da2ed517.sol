 

pragma solidity 0.5.5;

 
interface Proxy {

   
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external;
    
}

 
interface Xcert  
{

   
  function create(
    address _to,
    uint256 _id,
    bytes32 _imprint
  )
    external;

   
  function setUriBase(
    string calldata _uriBase
  )
    external;

   
  function schemaId()
    external
    view
    returns (bytes32 _schemaId);

   
  function tokenImprint(
    uint256 _tokenId
  )
    external
    view
    returns(bytes32 imprint);

}

 
interface XcertBurnable  
{

   
  function destroy(
    uint256 _tokenId
  )
    external;

}

 
interface XcertMutable  
{
  
   
  function updateTokenImprint(
    uint256 _tokenId,
    bytes32 _imprint
  )
    external;

}

 
interface XcertPausable  
{

   
  function setPause(
    bool _isPaused
  )
    external;
    
}

 
interface XcertRevokable  
{
  
   
  function revoke(
    uint256 _tokenId
  )
    external;

}

 
library SafeMath
{

   
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

   
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
    require(product / _factor1 == _factor2, OVERFLOW);
  }

   
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
     
    require(_divisor > 0, DIVISION_BY_ZERO);
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
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
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
    require(sum >= _addend1, OVERFLOW);
  }

   
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}

 
contract Abilitable
{
  using SafeMath for uint;

   
  string constant NOT_AUTHORIZED = "017001";
  string constant CANNOT_REVOKE_OWN_SUPER_ABILITY = "017002";
  string constant INVALID_INPUT = "017003";

   
  uint8 constant SUPER_ABILITY = 1;

   
  mapping(address => uint256) public addressToAbility;

   
  event GrantAbilities(
    address indexed _target,
    uint256 indexed _abilities
  );

   
  event RevokeAbilities(
    address indexed _target,
    uint256 indexed _abilities
  );

   
  modifier hasAbilities(
    uint256 _abilities
  ) 
  {
    require(_abilities > 0, INVALID_INPUT);
    require(
      addressToAbility[msg.sender] & _abilities == _abilities,
      NOT_AUTHORIZED
    );
    _;
  }

   
  constructor()
    public
  {
    addressToAbility[msg.sender] = SUPER_ABILITY;
    emit GrantAbilities(msg.sender, SUPER_ABILITY);
  }

   
  function grantAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(SUPER_ABILITY)
  {
    addressToAbility[_target] |= _abilities;
    emit GrantAbilities(_target, _abilities);
  }

   
  function revokeAbilities(
    address _target,
    uint256 _abilities,
    bool _allowSuperRevoke
  )
    external
    hasAbilities(SUPER_ABILITY)
  {
    if (!_allowSuperRevoke && msg.sender == _target)
    {
      require((_abilities & 1) == 0, CANNOT_REVOKE_OWN_SUPER_ABILITY);
    }
    addressToAbility[_target] &= ~_abilities;
    emit RevokeAbilities(_target, _abilities);
  }

   
  function isAble(
    address _target,
    uint256 _abilities
  )
    external
    view
    returns (bool)
  {
    require(_abilities > 0, INVALID_INPUT);
    return (addressToAbility[_target] & _abilities) == _abilities;
  }
  
}

 
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

 
contract NFTokenMetadataEnumerable is
  ERC721,
  ERC721Metadata,
  ERC721Enumerable,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

   
  string constant ZERO_ADDRESS = "006001";
  string constant NOT_VALID_NFT = "006002";
  string constant NOT_OWNER_OR_OPERATOR = "006003";
  string constant NOT_OWNER_APPROWED_OR_OPERATOR = "006004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "006005";
  string constant NFT_ALREADY_EXISTS = "006006";
  string constant INVALID_INDEX = "006007";

   
  bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

   
  string internal nftName;

   
  string internal nftSymbol;

   
  string public uriBase;

   
  uint256[] internal tokens;

   
  mapping(uint256 => uint256) internal idToIndex;

   
  mapping(address => uint256[]) internal ownerToIds;

   
  mapping(uint256 => uint256) internal idToOwnerIndex;

   
  mapping (uint256 => address) internal idToOwner;

   
  mapping (uint256 => address) internal idToApproval;

   
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

   
  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true;  
    supportedInterfaces[0x5b5e139f] = true;  
    supportedInterfaces[0x780e9d63] = true;  
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
  {
    _transferFrom(_from, _to, _tokenId);
  }

   
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
  {
     
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );

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
    require(_owner != address(0), ZERO_ADDRESS);
    return ownerToIds[_owner].length;
  }

   
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

   
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address)
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
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
    require(_index < tokens.length, INVALID_INDEX);
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
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
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
    returns (string memory)
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    if (bytes(uriBase).length > 0)
    {
      return string(abi.encodePacked(uriBase, _uint2str(_tokenId)));
    }
    return "";
  }

   
  function _setUriBase(
    string memory _uriBase
  )
    internal
  {
    uriBase = _uriBase;
  }

   
  function _create(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

     
    idToOwner[_tokenId] = _to;

    uint256 length = ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length - 1;

     
    length = tokens.push(_tokenId);
    idToIndex[_tokenId] = length - 1;

    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _destroy(
    uint256 _tokenId
  )
    internal
  {
     
    address owner = idToOwner[_tokenId];
    require(owner != address(0), NOT_VALID_NFT);

     
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }

     
    assert(ownerToIds[owner].length > 0);

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[owner].length - 1;
    uint256 lastToken;
    if (lastTokenIndex != tokenToRemoveIndex)
    {
      lastToken = ownerToIds[owner][lastTokenIndex];
      ownerToIds[owner][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    delete idToOwner[_tokenId];
    delete idToOwnerIndex[_tokenId];
    ownerToIds[owner].length--;

     
    assert(tokens.length > 0);

    uint256 tokenIndex = idToIndex[_tokenId];
    lastTokenIndex = tokens.length - 1;
    lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.length--;
     
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;

    emit Transfer(owner, address(0), _tokenId);
  }

   
  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
     
    require(_from != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == _from, NOT_VALID_NFT);
    require(_to != address(0), ZERO_ADDRESS);

     
    require(
      _from == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[_from][msg.sender],
      NOT_OWNER_APPROWED_OR_OPERATOR
    );

     
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }

     
    assert(ownerToIds[_from].length > 0);

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].length--;

     
    idToOwner[_tokenId] = _to;
    uint256 length = ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length - 1;

    emit Transfer(_from, _to, _tokenId);
  }

   
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
  {
    if (_to.isContract())
    {
      require(
        ERC721TokenReceiver(_to)
          .onERC721Received(msg.sender, _from, _tokenId, _data) == MAGIC_ON_ERC721_RECEIVED,
        NOT_ABLE_TO_RECEIVE_NFT
      );
    }

    _transferFrom(_from, _to, _tokenId);
  }

   
  function _uint2str(
    uint256 _i
  ) 
    internal
    pure
    returns (string memory str)
  {
    if (_i == 0)
    {
      return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0)
    {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length - 1;
    j = _i;
    while (j != 0)
    {
      bstr[k--] = byte(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }
  
}

 
contract XcertToken is 
  Xcert,
  XcertBurnable,
  XcertMutable,
  XcertPausable,
  XcertRevokable,
  NFTokenMetadataEnumerable,
  Abilitable
{

   
  uint8 constant ABILITY_CREATE_ASSET = 2;
  uint8 constant ABILITY_REVOKE_ASSET = 4;
  uint8 constant ABILITY_TOGGLE_TRANSFERS = 8;
  uint8 constant ABILITY_UPDATE_ASSET_IMPRINT = 16;
   
   
  uint8 constant ABILITY_UPDATE_URI_BASE = 64;

   
  bytes4 constant MUTABLE = 0xbda0e852;
  bytes4 constant BURNABLE = 0x9d118770;
  bytes4 constant PAUSABLE = 0xbedb86fb;
  bytes4 constant REVOKABLE = 0x20c5429b;

   
  string constant CAPABILITY_NOT_SUPPORTED = "007001";
  string constant TRANSFERS_DISABLED = "007002";
  string constant NOT_VALID_XCERT = "007003";
  string constant NOT_OWNER_OR_OPERATOR = "007004";

   
  event IsPaused(bool isPaused);

   
  event TokenImprintUpdate(
    uint256 indexed _tokenId,
    bytes32 _imprint
  );

   
  bytes32 internal nftSchemaId;

   
  mapping (uint256 => bytes32) internal idToImprint;

   
  mapping (address => bool) internal addressToAuthorized;

   
  bool public isPaused;

   
  constructor()
    public
  {
    supportedInterfaces[0xe08725ee] = true;  
  }

   
  function create(
    address _to,
    uint256 _id,
    bytes32 _imprint
  )
    external
    hasAbilities(ABILITY_CREATE_ASSET)
  {
    super._create(_to, _id);
    idToImprint[_id] = _imprint;
  }

   
  function setUriBase(
    string calldata _uriBase
  )
    external
    hasAbilities(ABILITY_UPDATE_URI_BASE)
  {
    super._setUriBase(_uriBase);
  }

   
  function revoke(
    uint256 _tokenId
  )
    external
    hasAbilities(ABILITY_REVOKE_ASSET)
  {
    require(supportedInterfaces[REVOKABLE], CAPABILITY_NOT_SUPPORTED);
    super._destroy(_tokenId);
    delete idToImprint[_tokenId];
  }

   
  function setPause(
    bool _isPaused
  )
    external
    hasAbilities(ABILITY_TOGGLE_TRANSFERS)
  {
    require(supportedInterfaces[PAUSABLE], CAPABILITY_NOT_SUPPORTED);
    isPaused = _isPaused;
    emit IsPaused(_isPaused);
  }

   
  function updateTokenImprint(
    uint256 _tokenId,
    bytes32 _imprint
  )
    external
    hasAbilities(ABILITY_UPDATE_ASSET_IMPRINT)
  {
    require(supportedInterfaces[MUTABLE], CAPABILITY_NOT_SUPPORTED);
    require(idToOwner[_tokenId] != address(0), NOT_VALID_XCERT);
    idToImprint[_tokenId] = _imprint;
    emit TokenImprintUpdate(_tokenId, _imprint);
  }

   
  function destroy(
    uint256 _tokenId
  )
    external
  {
    require(supportedInterfaces[BURNABLE], CAPABILITY_NOT_SUPPORTED);
    address tokenOwner = idToOwner[_tokenId];
    super._destroy(_tokenId);
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    delete idToImprint[_tokenId];
  }

   
  function schemaId()
    external
    view
    returns (bytes32 _schemaId)
  {
    _schemaId = nftSchemaId;
  }

   
  function tokenImprint(
    uint256 _tokenId
  )
    external
    view
    returns(bytes32 imprint)
  {
    imprint = idToImprint[_tokenId];
  }

   
  function _transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
     
    require(!isPaused, TRANSFERS_DISABLED); 
    super._transferFrom(_from, _to, _tokenId);
  }
}

 
contract XcertCreateProxy is 
  Abilitable 
{

   
  uint8 constant ABILITY_TO_EXECUTE = 2;

   
  function create(
    address _xcert,
    address _to,
    uint256 _id,
    bytes32 _imprint
  )
    external
    hasAbilities(ABILITY_TO_EXECUTE)
  {
    Xcert(_xcert).create(_to, _id, _imprint);
  }
  
}

pragma experimental ABIEncoderV2;




 
contract OrderGateway is
  Abilitable
{

   
  uint8 constant ABILITY_TO_SET_PROXIES = 2;

   
  uint8 constant ABILITY_ALLOW_CREATE_ASSET = 32;

   
  string constant INVALID_SIGNATURE_KIND = "015001";
  string constant INVALID_PROXY = "015002";
  string constant TAKER_NOT_EQUAL_TO_SENDER = "015003";
  string constant SENDER_NOT_TAKER_OR_MAKER = "015004";
  string constant CLAIM_EXPIRED = "015005";
  string constant INVALID_SIGNATURE = "015006";
  string constant ORDER_CANCELED = "015007";
  string constant ORDER_ALREADY_PERFORMED = "015008";
  string constant MAKER_NOT_EQUAL_TO_SENDER = "015009";
  string constant SIGNER_NOT_AUTHORIZED = "015010";

   
  enum SignatureKind
  {
    eth_sign,
    trezor,
    eip712
  }

   
  enum ActionKind
  {
    create,
    transfer
  }

   
  struct ActionData 
  {
    ActionKind kind;
    uint32 proxy;
    address token;
    bytes32 param1;
    address to;
    uint256 value;
  }

   
  struct SignatureData
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    SignatureKind kind;
  }

   
  struct OrderData 
  {
    address maker;
    address taker;
    ActionData[] actions;
    uint256 seed;
    uint256 expiration;
  }

   
  address[] public proxies;

   
  mapping(bytes32 => bool) public orderCancelled;

   
  mapping(bytes32 => bool) public orderPerformed;

   
  event Perform(
    address indexed _maker,
    address indexed _taker,
    bytes32 _claim
  );

   
  event Cancel(
    address indexed _maker,
    address indexed _taker,
    bytes32 _claim
  );

   
  event ProxyChange(
    uint256 indexed _index,
    address _proxy
  );

   
  function addProxy(
    address _proxy
  )
    external
    hasAbilities(ABILITY_TO_SET_PROXIES)
  {
    uint256 length = proxies.push(_proxy);
    emit ProxyChange(length - 1, _proxy);
  }

   
  function removeProxy(
    uint256 _index
  )
    external
    hasAbilities(ABILITY_TO_SET_PROXIES)
  {
    proxies[_index] = address(0);
    emit ProxyChange(_index, address(0));
  }

   
  function perform(
    OrderData memory _data,
    SignatureData memory _signature
  )
    public 
  {
    require(_data.taker == msg.sender, TAKER_NOT_EQUAL_TO_SENDER);
    require(_data.expiration >= now, CLAIM_EXPIRED);

    bytes32 claim = getOrderDataClaim(_data);
    require(
      isValidSignature(
        _data.maker,
        claim,
        _signature
      ), 
      INVALID_SIGNATURE
    );

    require(!orderCancelled[claim], ORDER_CANCELED);
    require(!orderPerformed[claim], ORDER_ALREADY_PERFORMED);

    orderPerformed[claim] = true;

    _doActions(_data);

    emit Perform(
      _data.maker,
      _data.taker,
      claim
    );
  }

   
  function cancel(
    OrderData memory _data
  )
    public
  {
    require(_data.maker == msg.sender, MAKER_NOT_EQUAL_TO_SENDER);

    bytes32 claim = getOrderDataClaim(_data);
    require(!orderPerformed[claim], ORDER_ALREADY_PERFORMED);

    orderCancelled[claim] = true;
    emit Cancel(
      _data.maker,
      _data.taker,
      claim
    );
  }

   
  function getOrderDataClaim(
    OrderData memory _orderData
  )
    public
    view
    returns (bytes32)
  {
    bytes32 temp = 0x0;

    for(uint256 i = 0; i < _orderData.actions.length; i++)
    {
      temp = keccak256(
        abi.encodePacked(
          temp,
          _orderData.actions[i].kind,
          _orderData.actions[i].proxy,
          _orderData.actions[i].token,
          _orderData.actions[i].param1,
          _orderData.actions[i].to,
          _orderData.actions[i].value
        )
      );
    }

    return keccak256(
      abi.encodePacked(
        address(this),
        _orderData.maker,
        _orderData.taker,
        temp,
        _orderData.seed,
        _orderData.expiration
      )
    );
  }
  
   
  function isValidSignature(
    address _signer,
    bytes32 _claim,
    SignatureData memory _signature
  )
    public
    pure
    returns (bool)
  {
    if (_signature.kind == SignatureKind.eth_sign)
    {
      return _signer == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _claim
          )
        ),
        _signature.v,
        _signature.r,
        _signature.s
      );
    } else if (_signature.kind == SignatureKind.trezor)
    {
      return _signer == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n\x20",
            _claim
          )
        ),
        _signature.v,
        _signature.r,
        _signature.s
      );
    } else if (_signature.kind == SignatureKind.eip712)
    {
      return _signer == ecrecover(
        _claim,
        _signature.v,
        _signature.r,
        _signature.s
      );
    }

    revert(INVALID_SIGNATURE_KIND);
  }

   
  function _doActions(
    OrderData memory _order
  )
    private
  {
    for(uint256 i = 0; i < _order.actions.length; i++)
    {
      require(
        proxies[_order.actions[i].proxy] != address(0),
        INVALID_PROXY
      );

      if (_order.actions[i].kind == ActionKind.create)
      {
        require(
          Abilitable(_order.actions[i].token).isAble(_order.maker, ABILITY_ALLOW_CREATE_ASSET),
          SIGNER_NOT_AUTHORIZED
        );
        
        XcertCreateProxy(proxies[_order.actions[i].proxy]).create(
          _order.actions[i].token,
          _order.actions[i].to,
          _order.actions[i].value,
          _order.actions[i].param1
        );
      } 
      else if (_order.actions[i].kind == ActionKind.transfer)
      {
        address from = address(uint160(bytes20(_order.actions[i].param1)));
        require(
          from == _order.maker
          || from == _order.taker,
          SENDER_NOT_TAKER_OR_MAKER
        );
        
        Proxy(proxies[_order.actions[i].proxy]).execute(
          _order.actions[i].token,
          from,
          _order.actions[i].to,
          _order.actions[i].value
        );
      }
    }
  }
  
}