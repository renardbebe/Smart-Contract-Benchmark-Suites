 

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
 
 
interface INRERC20 {
     
    function totalSupply() external view returns (uint256);
     
    function balanceOf(address account) external view returns (uint256);
     
    function transfer(address recipient, uint256 amount) external;
     
    function allowance(address owner, address spender) external view returns (uint256);
     
    function approve(address spender, uint256 amount) external returns (bool);
     
    function transferFrom(address sender, address recipient, uint256 amount) external;
     
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
 
 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         
        return c;
    }
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
 
 
 
contract Swap is ISwap {
  using SafeMath for uint256;
   
  bytes constant internal DOMAIN_NAME = "SWAP";
  bytes constant internal DOMAIN_VERSION = "2";
   
  bytes32 private _domainSeparator;
   
  byte constant internal AVAILABLE = 0x00;
  byte constant internal UNAVAILABLE = 0x01;
   
  bytes4 constant internal ERC721_INTERFACE_ID = 0x80ac58cd;
   
  mapping (address => mapping (address => bool)) public senderAuthorizations;
   
  mapping (address => mapping (address => bool)) public signerAuthorizations;
   
  mapping (address => mapping (uint256 => byte)) public signerNonceStatus;
   
  mapping (address => uint256) public signerMinimumNonce;
   
  constructor() public {
    _domainSeparator = Types.hashDomain(
      DOMAIN_NAME,
      DOMAIN_VERSION,
      address(this)
    );
  }
   
  function swap(
    Types.Order calldata order
  ) external {
     
    require(order.expiry > block.timestamp,
      "ORDER_EXPIRED");
     
    require(signerNonceStatus[order.signer.wallet][order.nonce] == AVAILABLE,
      "ORDER_TAKEN_OR_CANCELLED");
     
    require(order.nonce >= signerMinimumNonce[order.signer.wallet],
      "NONCE_TOO_LOW");
     
    signerNonceStatus[order.signer.wallet][order.nonce] = UNAVAILABLE;
     
    address finalSenderWallet;
    if (order.sender.wallet == address(0)) {
       
      finalSenderWallet = msg.sender;
    } else {
       
      require(isSenderAuthorized(order.sender.wallet, msg.sender),
          "SENDER_UNAUTHORIZED");
       
      finalSenderWallet = order.sender.wallet;
    }
     
    if (order.signature.v == 0) {
       
      require(isSignerAuthorized(order.signer.wallet, msg.sender),
        "SIGNER_UNAUTHORIZED");
    } else {
       
      require(isSignerAuthorized(order.signer.wallet, order.signature.signatory),
        "SIGNER_UNAUTHORIZED");
       
      require(isValid(order, _domainSeparator),
        "SIGNATURE_INVALID");
    }
     
    transferToken(
      finalSenderWallet,
      order.signer.wallet,
      order.sender.param,
      order.sender.token,
      order.sender.kind
    );
     
    transferToken(
      order.signer.wallet,
      finalSenderWallet,
      order.signer.param,
      order.signer.token,
      order.signer.kind
    );
     
    if (order.affiliate.wallet != address(0)) {
      transferToken(
        order.signer.wallet,
        order.affiliate.wallet,
        order.affiliate.param,
        order.affiliate.token,
        order.affiliate.kind
      );
    }
    emit Swap(order.nonce, block.timestamp,
      order.signer.wallet, order.signer.param, order.signer.token,
      finalSenderWallet, order.sender.param, order.sender.token,
      order.affiliate.wallet, order.affiliate.param, order.affiliate.token
    );
  }
   
  function cancel(
    uint256[] calldata nonces
  ) external {
    for (uint256 i = 0; i < nonces.length; i++) {
      if (signerNonceStatus[msg.sender][nonces[i]] == AVAILABLE) {
        signerNonceStatus[msg.sender][nonces[i]] = UNAVAILABLE;
        emit Cancel(nonces[i], msg.sender);
      }
    }
  }
   
  function cancelUpTo(
    uint256 minimumNonce
  ) external {
    signerMinimumNonce[msg.sender] = minimumNonce;
    emit CancelUpTo(minimumNonce, msg.sender);
  }
   
  function authorizeSender(
    address authorizedSender
  ) external {
    require(msg.sender != authorizedSender, "INVALID_AUTH_SENDER");
    if (!senderAuthorizations[msg.sender][authorizedSender]) {
      senderAuthorizations[msg.sender][authorizedSender] = true;
      emit AuthorizeSender(msg.sender, authorizedSender);
    }
  }
   
  function authorizeSigner(
    address authorizedSigner
  ) external {
    require(msg.sender != authorizedSigner, "INVALID_AUTH_SIGNER");
    if (!signerAuthorizations[msg.sender][authorizedSigner]) {
      signerAuthorizations[msg.sender][authorizedSigner] = true;
      emit AuthorizeSigner(msg.sender, authorizedSigner);
    }
  }
   
  function revokeSender(
    address authorizedSender
  ) external {
    if (senderAuthorizations[msg.sender][authorizedSender]) {
      delete senderAuthorizations[msg.sender][authorizedSender];
      emit RevokeSender(msg.sender, authorizedSender);
    }
  }
   
  function revokeSigner(
    address authorizedSigner
  ) external {
    if (signerAuthorizations[msg.sender][authorizedSigner]) {
      delete signerAuthorizations[msg.sender][authorizedSigner];
      emit RevokeSigner(msg.sender, authorizedSigner);
    }
  }
   
  function isSenderAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      senderAuthorizations[authorizer][delegate]);
  }
   
  function isSignerAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      signerAuthorizations[authorizer][delegate]);
  }
   
  function isValid(
    Types.Order memory order,
    bytes32 domainSeparator
  ) internal pure returns (bool) {
    if (order.signature.version == byte(0x01)) {
      return order.signature.signatory == ecrecover(
        Types.hashOrder(
          order,
          domainSeparator
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    if (order.signature.version == byte(0x45)) {
      return order.signature.signatory == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            Types.hashOrder(order, domainSeparator)
          )
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    return false;
  }
   
  function transferToken(
      address from,
      address to,
      uint256 param,
      address token,
      bytes4 kind
  ) internal {
     
    require(from != to, "INVALID_SELF_TRANSFER");
    if (kind == ERC721_INTERFACE_ID) {
       
      IERC721(token).transferFrom(from, to, param);
    } else {
      uint256 initialBalance = INRERC20(token).balanceOf(from);
       
      INRERC20(token).transferFrom(from, to, param);
       
      require(initialBalance.sub(param) == INRERC20(token).balanceOf(from), "TRANSFER_FAILED");
    }
  }
}