 

pragma solidity 0.5.6;

 
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

 
interface XcertMutable  
{
  
   
  function updateTokenImprint(
    uint256 _tokenId,
    bytes32 _imprint
  )
    external;

}

 
contract XcertUpdateProxy is
  Abilitable
{

   
  uint8 constant ABILITY_TO_EXECUTE = 2;

   
  function update(
    address _xcert,
    uint256 _id,
    bytes32 _imprint
  )
    external
    hasAbilities(ABILITY_TO_EXECUTE)
  {
    XcertMutable(_xcert).updateTokenImprint(_id, _imprint);
  }

}

pragma experimental ABIEncoderV2;





 
contract OrderGateway is
  Abilitable
{

   
  uint8 constant ABILITY_TO_SET_PROXIES = 2;

   
  uint8 constant ABILITY_ALLOW_CREATE_ASSET = 32;
  uint16 constant ABILITY_ALLOW_UPDATE_ASSET = 128;

   
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
    transfer,
    update
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

   
  function performAnyTaker(
    OrderData memory _data,
    SignatureData memory _signature
  )
    public
  {
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

    _data.taker = msg.sender;
    _doActionsReplaceZeroAddress(_data);

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

   
  function _doActionsReplaceZeroAddress(
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

        if (_order.actions[i].to == address(0))
        {
          _order.actions[i].to = _order.taker;
        }

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

        if (_order.actions[i].to == address(0))
        {
          _order.actions[i].to = _order.taker;
        }

        if (from == address(0))
        {
          from = _order.taker;
        }

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
      else if (_order.actions[i].kind == ActionKind.update)
      {
        require(
          Abilitable(_order.actions[i].token).isAble(_order.maker, ABILITY_ALLOW_UPDATE_ASSET),
          SIGNER_NOT_AUTHORIZED
        );

        XcertUpdateProxy(proxies[_order.actions[i].proxy]).update(
          _order.actions[i].token,
          _order.actions[i].value,
          _order.actions[i].param1
        );
      }
    }
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
      else if (_order.actions[i].kind == ActionKind.update)
      {
        require(
          Abilitable(_order.actions[i].token).isAble(_order.maker, ABILITY_ALLOW_UPDATE_ASSET),
          SIGNER_NOT_AUTHORIZED
        );

        XcertUpdateProxy(proxies[_order.actions[i].proxy]).update(
          _order.actions[i].token,
          _order.actions[i].value,
          _order.actions[i].param1
        );
      }
    }
  }

}