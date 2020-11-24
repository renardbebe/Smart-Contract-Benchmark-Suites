 

 

 

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

 

interface IWETH {

  function deposit() external payable;
  function withdraw(uint256) external;
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}

 

pragma solidity ^0.5.0;

 
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

 

 
contract Wrapper {

   
  ISwap public swapContract;

   
  IWETH public wethContract;

  uint256 constant MAX_INT = 2**256 - 1;
   
  constructor(
    address _swapContract,
    address _wethContract
  ) public {
    swapContract = ISwap(_swapContract);
    wethContract = IWETH(_wethContract);

     
    wethContract.approve(_swapContract, MAX_INT);
  }

   
  function() external payable {
     
    if(msg.sender != address(wethContract)) {
      revert("DO_NOT_SEND_ETHER");
    }
  }

   
  function swap(
    Types.Order calldata _order
  ) external payable {

     
    require(_order.taker.wallet == msg.sender,
      "SENDER_MUST_BE_TAKER");

     
    if (_order.taker.token == address(wethContract)) {

       
      require(_order.taker.param == msg.value,
        "VALUE_MUST_BE_SENT");

       
      wethContract.deposit.value(msg.value)();

       
      wethContract.transfer(_order.taker.wallet, _order.taker.param);

    } else {

       
      require(msg.value == 0,
        "VALUE_MUST_BE_ZERO");

    }

     
    swapContract.swap(_order);

     
    if (_order.maker.token == address(wethContract)) {

       
      wethContract.transferFrom(_order.taker.wallet, address(this), _order.maker.param);

       
      wethContract.withdraw(_order.maker.param);

       
      msg.sender.transfer(_order.maker.param);

    }
  }
}