 

 

 

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

 
library Types {

  bytes constant internal EIP191_HEADER = "\x19\x01";

  struct Order {
    uint256 nonce;         
    uint256 expiry;        
    Party maker;           
    Party taker;           
    Party affiliate;       
    Signature signature;   
  }

  struct Party {
    address wallet;        
    address token;         
    uint256 param;         
    bytes4 kind;           
  }

  struct Signature {
    address signer;        
    uint8 v;               
    bytes32 r;             
    bytes32 s;             
    bytes1 version;        
  }

  bytes32 constant DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
    "EIP712Domain(",
    "string name,",
    "string version,",
    "address verifyingContract",
    ")"
  ));

  bytes32 constant ORDER_TYPEHASH = keccak256(abi.encodePacked(
    "Order(",
    "uint256 nonce,",
    "uint256 expiry,",
    "Party maker,",
    "Party taker,",
    "Party affiliate",
    ")",
    "Party(",
    "address wallet,",
    "address token,",
    "uint256 param,",
    "bytes4 kind",
    ")"
  ));

  bytes32 constant PARTY_TYPEHASH = keccak256(abi.encodePacked(
    "Party(",
    "address wallet,",
    "address token,",
    "uint256 param,",
    "bytes4 kind",
    ")"
  ));

   
  function hashOrder(
    Order calldata _order,
    bytes32 _domainSeparator
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      EIP191_HEADER,
      _domainSeparator,
      keccak256(abi.encode(
        ORDER_TYPEHASH,
        _order.nonce,
        _order.expiry,
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          _order.maker.wallet,
          _order.maker.token,
          _order.maker.param,
          _order.maker.kind
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          _order.taker.wallet,
          _order.taker.token,
          _order.taker.param,
          _order.taker.kind
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          _order.affiliate.wallet,
          _order.affiliate.token,
          _order.affiliate.param,
          _order.affiliate.kind
        ))
      ))
    ));
  }

   
  function hashDomain(
    bytes calldata _name,
    bytes calldata _version,
    address _verifyingContract
  ) external pure returns (bytes32) {
    return keccak256(abi.encode(
      DOMAIN_TYPEHASH,
      keccak256(_name),
      keccak256(_version),
      _verifyingContract
    ));
  }

}


interface ISwap {

  event Swap(
    uint256 indexed nonce,
    uint256 timestamp,
    address indexed makerWallet,
    uint256 makerParam,
    address makerToken,
    address indexed takerWallet,
    uint256 takerParam,
    address takerToken,
    address affiliateWallet,
    uint256 affiliateParam,
    address affiliateToken
  );

  event Cancel(
    uint256 indexed nonce,
    address indexed makerWallet
  );

  event Invalidate(
    uint256 indexed nonce,
    address indexed makerWallet
  );

  event Authorize(
    address indexed approverAddress,
    address indexed delegateAddress,
    uint256 expiry
  );

  event Revoke(
    address indexed approverAddress,
    address indexed delegateAddress
  );

  function delegateApprovals(address, address) external returns (uint256);
  function makerOrderStatus(address, uint256) external returns (byte);
  function makerMinimumNonce(address) external returns (uint256);

   
  function swap(
    Types.Order calldata order
  ) external;

   
  function cancel(
    uint256[] calldata _nonces
  ) external;

   
  function invalidate(
    uint256 _minimumNonce
  ) external;

   
  function authorize(
    address _delegate,
    uint256 _expiry
  ) external;

   
  function revoke(
    address _delegate
  ) external;

}

 

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 


 
contract Swap is ISwap {

   
  bytes constant internal DOMAIN_NAME = "SWAP";
  bytes constant internal DOMAIN_VERSION = "2";

   
  bytes32 private domainSeparator;

   
  byte constant private OPEN = 0x00;
  byte constant private TAKEN = 0x01;
  byte constant private CANCELED = 0x02;

   
  bytes4 constant internal ERC20_INTERFACE_ID = 0x277f8169;
   

   
  bytes4 constant internal ERC721_INTERFACE_ID = 0x80ac58cd;
   

   
  mapping (address => mapping (address => uint256)) public delegateApprovals;

   
  mapping (address => mapping (uint256 => byte)) public makerOrderStatus;

   
  mapping (address => uint256) public makerMinimumNonce;

   
  constructor() public {
    domainSeparator = Types.hashDomain(
      DOMAIN_NAME,
      DOMAIN_VERSION,
      address(this)
    );
  }

   
  function swap(
    Types.Order calldata _order
  ) external {

     
    require(_order.expiry > block.timestamp,
      "ORDER_EXPIRED");

     
    require(makerOrderStatus[_order.maker.wallet][_order.nonce] != TAKEN,
      "ORDER_ALREADY_TAKEN");

     
    require(makerOrderStatus[_order.maker.wallet][_order.nonce] != CANCELED,
      "ORDER_ALREADY_CANCELED");

     
    require(_order.nonce >= makerMinimumNonce[_order.maker.wallet],
      "NONCE_TOO_LOW");

     
    makerOrderStatus[_order.maker.wallet][_order.nonce] = TAKEN;

     
    address finalTakerWallet;

    if (_order.taker.wallet == address(0)) {
       
      finalTakerWallet = msg.sender;

    } else {
       
      if (msg.sender != _order.taker.wallet) {
        require(isAuthorized(_order.taker.wallet, msg.sender),
          "SENDER_UNAUTHORIZED");
      }
       
      finalTakerWallet = _order.taker.wallet;

    }

     
    if (_order.signature.v == 0) {
       
      require(isAuthorized(_order.maker.wallet, msg.sender),
        "SIGNER_UNAUTHORIZED");

    } else {
       
      require(isAuthorized(_order.maker.wallet, _order.signature.signer),
        "SIGNER_UNAUTHORIZED");

       
      require(isValid(_order, domainSeparator),
        "SIGNATURE_INVALID");

    }
     
    transferToken(
      finalTakerWallet,
      _order.maker.wallet,
      _order.taker.param,
      _order.taker.token,
      _order.taker.kind
    );

     
    transferToken(
      _order.maker.wallet,
      finalTakerWallet,
      _order.maker.param,
      _order.maker.token,
      _order.maker.kind
    );

     
    if (_order.affiliate.wallet != address(0)) {
      transferToken(
        _order.maker.wallet,
        _order.affiliate.wallet,
        _order.affiliate.param,
        _order.affiliate.token,
        _order.affiliate.kind
      );
    }

    emit Swap(_order.nonce, block.timestamp,
      _order.maker.wallet, _order.maker.param, _order.maker.token,
      finalTakerWallet, _order.taker.param, _order.taker.token,
      _order.affiliate.wallet, _order.affiliate.param, _order.affiliate.token
    );
  }

   
  function cancel(
    uint256[] calldata _nonces
  ) external {
    for (uint256 i = 0; i < _nonces.length; i++) {
      if (makerOrderStatus[msg.sender][_nonces[i]] == OPEN) {
        makerOrderStatus[msg.sender][_nonces[i]] = CANCELED;
        emit Cancel(_nonces[i], msg.sender);
      }
    }
  }

   
  function invalidate(
    uint256 _minimumNonce
  ) external {
    makerMinimumNonce[msg.sender] = _minimumNonce;
    emit Invalidate(_minimumNonce, msg.sender);
  }

   
  function authorize(
    address _delegate,
    uint256 _expiry
  ) external {
    require(msg.sender != _delegate, "INVALID_AUTH_DELEGATE");
    require(_expiry > block.timestamp, "INVALID_AUTH_EXPIRY");
    delegateApprovals[msg.sender][_delegate] = _expiry;
    emit Authorize(msg.sender, _delegate, _expiry);
  }

   
  function revoke(
    address _delegate
  ) external {
    delete delegateApprovals[msg.sender][_delegate];
    emit Revoke(msg.sender, _delegate);
  }

   
  function isAuthorized(
    address _approver,
    address _delegate
  ) internal view returns (bool) {
    if (_approver == _delegate) return true;
    return (delegateApprovals[_approver][_delegate] > block.timestamp);
  }

   
  function isValid(
    Types.Order memory _order,
    bytes32 _domainSeparator
  ) internal pure returns (bool) {
    if (_order.signature.version == byte(0x01)) {
      return _order.signature.signer == ecrecover(
        Types.hashOrder(
          _order,
          _domainSeparator),
          _order.signature.v,
          _order.signature.r,
          _order.signature.s
      );
    }
    if (_order.signature.version == byte(0x45)) {
      return _order.signature.signer == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            Types.hashOrder(_order, _domainSeparator)
          )
        ),
        _order.signature.v,
        _order.signature.r,
        _order.signature.s
      );
    }
    return false;
  }

   
  function transferToken(
      address _from,
      address _to,
      uint256 _param,
      address _token,
      bytes4 _kind
  ) internal {
    if (_kind == ERC721_INTERFACE_ID) {
       
      IERC721(_token).safeTransferFrom(_from, _to, _param);
    } else {
       
      require(IERC20(_token).transferFrom(_from, _to, _param));
    }
  }
}