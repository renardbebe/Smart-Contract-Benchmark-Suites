 

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;
 
 
 
library Types {
  bytes constant internal EIP191_HEADER = "\x19\x01";
  struct Order {
    uint256 nonce;                 
    uint256 expiry;                
    Party signer;                  
    Party sender;                  
    Party affiliate;               
    Signature signature;           
  }
  struct Party {
    bytes4 kind;                   
    address wallet;                
    address token;                 
    uint256 param;                 
  }
  struct Signature {
    address signatory;             
    address validator;             
    bytes1 version;                
    uint8 v;                       
    bytes32 r;                     
    bytes32 s;                     
  }
  bytes32 constant internal DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
    "EIP712Domain(",
    "string name,",
    "string version,",
    "address verifyingContract",
    ")"
  ));
  bytes32 constant internal ORDER_TYPEHASH = keccak256(abi.encodePacked(
    "Order(",
    "uint256 nonce,",
    "uint256 expiry,",
    "Party signer,",
    "Party sender,",
    "Party affiliate",
    ")",
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 param",
    ")"
  ));
  bytes32 constant internal PARTY_TYPEHASH = keccak256(abi.encodePacked(
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 param",
    ")"
  ));
   
  function hashOrder(
    Order calldata order,
    bytes32 domainSeparator
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      EIP191_HEADER,
      domainSeparator,
      keccak256(abi.encode(
        ORDER_TYPEHASH,
        order.nonce,
        order.expiry,
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.signer.kind,
          order.signer.wallet,
          order.signer.token,
          order.signer.param
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.sender.kind,
          order.sender.wallet,
          order.sender.token,
          order.sender.param
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.affiliate.kind,
          order.affiliate.wallet,
          order.affiliate.token,
          order.affiliate.param
        ))
      ))
    ));
  }
   
  function hashDomain(
    bytes calldata name,
    bytes calldata version,
    address verifyingContract
  ) external pure returns (bytes32) {
    return keccak256(abi.encode(
      DOMAIN_TYPEHASH,
      keccak256(name),
      keccak256(version),
      verifyingContract
    ));
  }
}
 
 
interface ISwap {
  event Swap(
    uint256 indexed nonce,
    uint256 timestamp,
    address indexed signerWallet,
    uint256 signerParam,
    address signerToken,
    address indexed senderWallet,
    uint256 senderParam,
    address senderToken,
    address affiliateWallet,
    uint256 affiliateParam,
    address affiliateToken
  );
  event Cancel(
    uint256 indexed nonce,
    address indexed signerWallet
  );
  event CancelUpTo(
    uint256 indexed nonce,
    address indexed signerWallet
  );
  event AuthorizeSender(
    address indexed authorizerAddress,
    address indexed authorizedSender
  );
  event AuthorizeSigner(
    address indexed authorizerAddress,
    address indexed authorizedSigner
  );
  event RevokeSender(
    address indexed authorizerAddress,
    address indexed revokedSender
  );
  event RevokeSigner(
    address indexed authorizerAddress,
    address indexed revokedSigner
  );
   
  function swap(
    Types.Order calldata order
  ) external;
   
  function cancel(
    uint256[] calldata nonces
  ) external;
   
  function cancelUpTo(
    uint256 minimumNonce
  ) external;
   
  function authorizeSender(
    address authorizedSender
  ) external;
   
  function authorizeSigner(
    address authorizedSigner
  ) external;
   
  function revokeSender(
    address authorizedSender
  ) external;
   
  function revokeSigner(
    address authorizedSigner
  ) external;
  function senderAuthorizations(address, address) external view returns (bool);
  function signerAuthorizations(address, address) external view returns (bool);
  function signerNonceStatus(address, uint256) external view returns (byte);
  function signerMinimumNonce(address) external view returns (uint256);
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
 
 
 
contract Wrapper {
   
  ISwap public swapContract;
   
  IWETH public wethContract;
   
  constructor(
    address wrapperSwapContract,
    address wrapperWethContract
  ) public {
    swapContract = ISwap(wrapperSwapContract);
    wethContract = IWETH(wrapperWethContract);
  }
   
  function() external payable {
     
    if(msg.sender != address(wethContract)) {
      revert("DO_NOT_SEND_ETHER");
    }
  }
   
  function swap(
    Types.Order calldata order
  ) external payable {
     
    require(order.sender.wallet == msg.sender,
      "MSG_SENDER_MUST_BE_ORDER_SENDER");
     
     
    require(order.signature.v != 0,
      "SIGNATURE_MUST_BE_SENT");
     
    if (order.sender.token == address(wethContract)) {
       
      require(order.sender.param == msg.value,
        "VALUE_MUST_BE_SENT");
       
      wethContract.deposit.value(msg.value)();
       
      wethContract.transfer(order.sender.wallet, order.sender.param);
    } else {
       
      require(msg.value == 0,
        "VALUE_MUST_BE_ZERO");
    }
     
    swapContract.swap(order);
     
    if (order.signer.token == address(wethContract)) {
       
      wethContract.transferFrom(order.sender.wallet, address(this), order.signer.param);
       
      wethContract.withdraw(order.signer.param);
       
       
      (bool success, ) = msg.sender.call.value(order.signer.param)("");
      require(success, "ETH_RETURN_FAILED");
    }
  }
}