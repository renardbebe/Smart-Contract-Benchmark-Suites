 

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
    uint256 amount;                
    uint256 id;                    
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
    "uint256 amount,",
    "uint256 id",
    ")"
  ));
  bytes32 constant internal PARTY_TYPEHASH = keccak256(abi.encodePacked(
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 amount,",
    "uint256 id",
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
          order.signer.amount,
          order.signer.id
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.sender.kind,
          order.sender.wallet,
          order.sender.token,
          order.sender.amount,
          order.sender.id
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.affiliate.kind,
          order.affiliate.wallet,
          order.affiliate.token,
          order.affiliate.amount,
          order.affiliate.id
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
 
 
interface IDelegate {
  struct Rule {
    uint256 maxSenderAmount;       
    uint256 priceCoef;             
    uint256 priceExp;              
  }
  event SetRule(
    address indexed owner,
    address indexed senderToken,
    address indexed signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  );
  event UnsetRule(
    address indexed owner,
    address indexed senderToken,
    address indexed signerToken
  );
  event ProvideOrder(
    address indexed owner,
    address tradeWallet,
    address indexed senderToken,
    address indexed signerToken,
    uint256 senderAmount,
    uint256 priceCoef,
    uint256 priceExp
  );
  function setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) external;
  function unsetRule(
    address senderToken,
    address signerToken
  ) external;
  function provideOrder(
    Types.Order calldata order
  ) external;
  function rules(address, address) external view returns (Rule memory);
  function getSignerSideQuote(
    uint256 senderAmount,
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 signerAmount
  );
  function getSenderSideQuote(
    uint256 signerAmount,
    address signerToken,
    address senderToken
  ) external view returns (
    uint256 senderAmount
  );
  function getMaxQuote(
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 senderAmount,
    uint256 signerAmount
  );
  function owner()
    external view returns (address);
  function tradeWallet()
    external view returns (address);
}
 
 
interface IIndexer {
  event CreateIndex(
    address indexed signerToken,
    address indexed senderToken,
    bytes2 protocol,
    address indexAddress
  );
  event Stake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    bytes2 protocol,
    uint256 stakeAmount
  );
  event Unstake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    bytes2 protocol,
    uint256 stakeAmount
  );
  event AddTokenToBlacklist(
    address token
  );
  event RemoveTokenFromBlacklist(
    address token
  );
  function setLocatorWhitelist(
    bytes2 protocol,
    address newLocatorWhitelist
  ) external;
  function createIndex(
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) external returns (address);
  function addTokenToBlacklist(
    address token
  ) external;
  function removeTokenFromBlacklist(
    address token
  ) external;
  function setIntent(
    address signerToken,
    address senderToken,
    bytes2 protocol,
    uint256 stakingAmount,
    bytes32 locator
  ) external;
  function unsetIntent(
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) external;
  function stakingToken() external view returns (address);
  function indexes(address, address, bytes2) external view returns (address);
  function tokenBlacklist(address) external view returns (bool);
  function getStakedAmount(
    address user,
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) external view returns (uint256);
  function getLocators(
    address signerToken,
    address senderToken,
    bytes2 protocol,
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory,
    uint256[] memory,
    address
  );
}
 
 
interface ISwap {
  event Swap(
    uint256 indexed nonce,
    uint256 timestamp,
    address indexed signerWallet,
    uint256 signerAmount,
    uint256 signerId,
    address signerToken,
    address indexed senderWallet,
    uint256 senderAmount,
    uint256 senderId,
    address senderToken,
    address affiliateWallet,
    uint256 affiliateAmount,
    uint256 affiliateId,
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
 
 
contract Context {
     
     
    constructor () internal { }
     
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}
 
 
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
     
    function owner() public view returns (address) {
        return _owner;
    }
     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         
        return c;
    }
     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
 
 
 
contract Delegate is IDelegate, Ownable {
  using SafeMath for uint256;
   
  ISwap public swapContract;
   
  IIndexer public indexer;
   
  uint256 constant internal MAX_INT =  2**256 - 1;
   
  address public tradeWallet;
   
  mapping (address => mapping (address => Rule)) public rules;
   
  bytes4 constant internal ERC20_INTERFACE_ID = 0x36372b07;
   
  bytes2 public protocol;
   
  constructor(
    ISwap delegateSwap,
    IIndexer delegateIndexer,
    address delegateContractOwner,
    address delegateTradeWallet,
    bytes2 delegateProtocol
  ) public {
    swapContract = delegateSwap;
    indexer = delegateIndexer;
    protocol = delegateProtocol;
     
    if (delegateContractOwner != address(0)) {
      transferOwnership(delegateContractOwner);
    }
     
    if (delegateTradeWallet != address(0)) {
      tradeWallet = delegateTradeWallet;
    } else {
      tradeWallet = owner();
    }
     
    require(
      IERC20(indexer.stakingToken())
      .approve(address(indexer), MAX_INT), "STAKING_APPROVAL_FAILED"
    );
  }
   
  function setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) external onlyOwner {
    _setRule(
      senderToken,
      signerToken,
      maxSenderAmount,
      priceCoef,
      priceExp
    );
  }
   
  function unsetRule(
    address senderToken,
    address signerToken
  ) external onlyOwner {
    _unsetRule(
      senderToken,
      signerToken
    );
  }
   
  function setRuleAndIntent(
    address senderToken,
    address signerToken,
    Rule calldata rule,
    uint256 newStakeAmount
  ) external onlyOwner {
    _setRule(
      senderToken,
      signerToken,
      rule.maxSenderAmount,
      rule.priceCoef,
      rule.priceExp
    );
     
    uint256 oldStakeAmount = indexer.getStakedAmount(address(this), signerToken, senderToken, protocol);
    if (oldStakeAmount == newStakeAmount && oldStakeAmount > 0) {
      return;  
    } else if (oldStakeAmount < newStakeAmount) {
       
      require(
        IERC20(indexer.stakingToken())
        .transferFrom(msg.sender, address(this), newStakeAmount - oldStakeAmount), "STAKING_TRANSFER_FAILED"
      );
    }
    indexer.setIntent(
      signerToken,
      senderToken,
      protocol,
      newStakeAmount,
      bytes32(uint256(address(this)) << 96)  
    );
    if (oldStakeAmount > newStakeAmount) {
       
      require(
        IERC20(indexer.stakingToken())
        .transfer(msg.sender, oldStakeAmount - newStakeAmount), "STAKING_RETURN_FAILED"
      );
    }
  }
   
  function unsetRuleAndIntent(
    address senderToken,
    address signerToken
  ) external onlyOwner {
    _unsetRule(senderToken, signerToken);
     
    uint256 stakedAmount = indexer.getStakedAmount(address(this), signerToken, senderToken, protocol);
    indexer.unsetIntent(signerToken, senderToken, protocol);
     
     
    if (stakedAmount > 0) {
      require(
        IERC20(indexer.stakingToken())
          .transfer(msg.sender, stakedAmount),"STAKING_RETURN_FAILED"
      );
    }
  }
   
  function provideOrder(
    Types.Order calldata order
  ) external {
    Rule memory rule = rules[order.sender.token][order.signer.token];
    require(order.signature.v != 0,
      "SIGNATURE_MUST_BE_SENT");
     
    require(order.sender.wallet == tradeWallet,
      "INVALID_SENDER_WALLET");
     
    require(order.signer.kind == ERC20_INTERFACE_ID,
      "SIGNER_KIND_MUST_BE_ERC20");
    require(order.sender.kind == ERC20_INTERFACE_ID,
      "SENDER_KIND_MUST_BE_ERC20");
     
    require(rule.maxSenderAmount != 0,
      "TOKEN_PAIR_INACTIVE");
     
    require(order.sender.amount <= rule.maxSenderAmount,
      "AMOUNT_EXCEEDS_MAX");
     
    require(order.sender.amount <= _calculateSenderAmount(order.signer.amount, rule.priceCoef, rule.priceExp),
      "PRICE_INVALID");
     
    rules[order.sender.token][order.signer.token] = Rule({
      maxSenderAmount: (rule.maxSenderAmount).sub(order.sender.amount),
      priceCoef: rule.priceCoef,
      priceExp: rule.priceExp
    });
     
    swapContract.swap(order);
    emit ProvideOrder(
      owner(),
      tradeWallet,
      order.sender.token,
      order.signer.token,
      order.sender.amount,
      rule.priceCoef,
      rule.priceExp
    );
  }
   
  function setTradeWallet(address newTradeWallet) external onlyOwner {
    require(newTradeWallet != address(0), "TRADE_WALLET_REQUIRED");
    tradeWallet = newTradeWallet;
  }
   
  function getSignerSideQuote(
    uint256 senderAmount,
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 signerAmount
  ) {
    Rule memory rule = rules[senderToken][signerToken];
     
    if(rule.maxSenderAmount > 0) {
       
      if(senderAmount <= rule.maxSenderAmount) {
        signerAmount = _calculateSignerAmount(senderAmount, rule.priceCoef, rule.priceExp);
         
        return signerAmount;
      }
    }
    return 0;
  }
   
  function getSenderSideQuote(
    uint256 signerAmount,
    address signerToken,
    address senderToken
  ) external view returns (
    uint256 senderAmount
  ) {
    Rule memory rule = rules[senderToken][signerToken];
     
    if(rule.maxSenderAmount > 0) {
       
      senderAmount = _calculateSenderAmount(signerAmount, rule.priceCoef, rule.priceExp);
       
      if(senderAmount <= rule.maxSenderAmount) {
        return senderAmount;
      }
    }
    return 0;
  }
   
  function getMaxQuote(
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 senderAmount,
    uint256 signerAmount
  ) {
    Rule memory rule = rules[senderToken][signerToken];
    senderAmount = rule.maxSenderAmount;
     
    if (senderAmount > 0) {
       
      signerAmount = _calculateSignerAmount(senderAmount, rule.priceCoef, rule.priceExp);
       
      return (
        senderAmount,
        signerAmount
      );
    }
    return (0, 0);
  }
   
  function _setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) internal {
    require(priceCoef > 0, "INVALID_PRICE_COEF");
    rules[senderToken][signerToken] = Rule({
      maxSenderAmount: maxSenderAmount,
      priceCoef: priceCoef,
      priceExp: priceExp
    });
    emit SetRule(
      owner(),
      senderToken,
      signerToken,
      maxSenderAmount,
      priceCoef,
      priceExp
    );
  }
   
  function _unsetRule(
    address senderToken,
    address signerToken
  ) internal {
     
    if (rules[senderToken][signerToken].priceCoef > 0) {
       
      delete rules[senderToken][signerToken];
      emit UnsetRule(
        owner(),
        senderToken,
        signerToken
    );
    }
  }
   
  function _calculateSignerAmount(
    uint256 senderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) internal pure returns (
    uint256 signerAmount
  ) {
     
    uint256 multiplier = senderAmount.mul(priceCoef);
    signerAmount = multiplier.div(10 ** priceExp);
     
    if (multiplier.mod(10 ** priceExp) > 0) {
      signerAmount++;
    }
  }
   
  function _calculateSenderAmount(
    uint256 signerAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) internal pure returns (
    uint256 senderAmount
  ) {
     
    senderAmount = signerAmount
      .mul(10 ** priceExp)
      .div(priceCoef);
  }
}
 
 
interface IDelegateFactory {
  event CreateDelegate(
    address indexed delegateContract,
    address swapContract,
    address indexerContract,
    address indexed delegateContractOwner,
    address delegateTradeWallet
  );
   
  function createDelegate(
    address delegateTradeWallet
  ) external returns (address delegateContractAddress);
}
 
 
interface ILocatorWhitelist {
  function has(
    bytes32 locator
  ) external view returns (bool);
}
 
 
contract DelegateFactory is IDelegateFactory, ILocatorWhitelist {
   
  mapping(address => bool) internal _deployedAddresses;
   
  ISwap public swapContract;
  IIndexer public indexerContract;
  bytes2 public protocol;
   
  constructor(
    ISwap factorySwapContract,
    IIndexer factoryIndexerContract,
    bytes2 factoryProtocol
  ) public {
    swapContract = factorySwapContract;
    indexerContract = factoryIndexerContract;
    protocol = factoryProtocol;
  }
   
  function createDelegate(
    address delegateTradeWallet
  ) external returns (address delegateContractAddress) {
    delegateContractAddress = address(
      new Delegate(swapContract, indexerContract, msg.sender, delegateTradeWallet, protocol)
    );
    _deployedAddresses[delegateContractAddress] = true;
    emit CreateDelegate(
      delegateContractAddress,
      address(swapContract),
      address(indexerContract),
      msg.sender,
      delegateTradeWallet
    );
    return delegateContractAddress;
  }
   
  function has(bytes32 locator) external view returns (bool) {
    return _deployedAddresses[address(bytes20(locator))];
  }
}
 
 
 
contract Index is Ownable {
   
  uint256 public length;
   
  address constant internal HEAD = address(uint160(2**160-1));
   
  mapping(address => Entry) public entries;
   
  struct Entry {
    bytes32 locator;
    uint256 score;
    address prev;
    address next;
  }
   
  event SetLocator(
    address indexed identifier,
    uint256 score,
    bytes32 indexed locator
  );
  event UnsetLocator(
    address indexed identifier
  );
   
  constructor() public {
     
    entries[HEAD] = Entry(bytes32(0), 0, HEAD, HEAD);
  }
   
  function setLocator(
    address identifier,
    uint256 score,
    bytes32 locator
  ) external onlyOwner {
     
    require(!_hasEntry(identifier), "ENTRY_ALREADY_EXISTS");
    _setLocator(identifier, score, locator);
     
    length = length + 1;
    emit SetLocator(identifier, score, locator);
  }
   
  function unsetLocator(
    address identifier
  ) external onlyOwner {
    _unsetLocator(identifier);
     
    length = length - 1;
    emit UnsetLocator(identifier);
  }
   
  function updateLocator(
    address identifier,
    uint256 score,
    bytes32 locator
  ) external onlyOwner {
     
    _unsetLocator(identifier);
    _setLocator(identifier, score, locator);
    emit SetLocator(identifier, score, locator);
  }
   
  function getScore(
    address identifier
  ) external view returns (uint256) {
    return entries[identifier].score;
  }
     
  function getLocator(
    address identifier
  ) external view returns (bytes32) {
    return entries[identifier].locator;
  }
   
  function getLocators(
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory locators,
    uint256[] memory scores,
    address nextCursor
  ) {
    address identifier;
     
    if (cursor != address(0) && cursor != HEAD) {
       
      if (!_hasEntry(cursor)) {
        return (new bytes32[](0), new uint256[](0), address(0));
      }
       
      identifier = cursor;
    } else {
      identifier = entries[HEAD].next;
    }
     
     
    uint256 size = (length < limit) ? length : limit;
    locators = new bytes32[](size);
    scores = new uint256[](size);
     
    uint256 i;
    while (i < size && identifier != HEAD) {
      locators[i] = entries[identifier].locator;
      scores[i] = entries[identifier].score;
      i = i + 1;
      identifier = entries[identifier].next;
    }
    return (locators, scores, identifier);
  }
   
  function _setLocator(
    address identifier,
    uint256 score,
    bytes32 locator
  ) internal {
     
    require(locator != bytes32(0), "LOCATOR_MUST_BE_SENT");
     
    address nextEntry = _getEntryLowerThan(score);
     
    address prevEntry = entries[nextEntry].prev;
    entries[prevEntry].next = identifier;
    entries[nextEntry].prev = identifier;
    entries[identifier] = Entry(locator, score, prevEntry, nextEntry);
  }
   
  function _unsetLocator(
    address identifier
  ) internal {
     
    require(_hasEntry(identifier), "ENTRY_DOES_NOT_EXIST");
     
    address prevUser = entries[identifier].prev;
    address nextUser = entries[identifier].next;
    entries[prevUser].next = nextUser;
    entries[nextUser].prev = prevUser;
     
    delete entries[identifier];
  }
   
  function _hasEntry(
    address identifier
  ) internal view returns (bool) {
    return entries[identifier].locator != bytes32(0);
  }
   
  function _getEntryLowerThan(
    uint256 score
  ) internal view returns (address) {
    address identifier = entries[HEAD].next;
     
    if (score == 0) {
      return HEAD;
    }
     
    while (score <= entries[identifier].score) {
      identifier = entries[identifier].next;
    }
    return identifier;
  }
}
 
 
 
contract Indexer is IIndexer, Ownable {
   
  IERC20 public stakingToken;
   
  mapping (address => mapping (address => mapping (bytes2 => Index))) public indexes;
   
  mapping (bytes2 => address) public locatorWhitelists;
   
  mapping (address => bool) public tokenBlacklist;
   
  constructor(
    address indexerStakingToken
  ) public {
    stakingToken = IERC20(indexerStakingToken);
  }
   
  modifier indexExists(address signerToken, address senderToken, bytes2 protocol) {
    require(indexes[signerToken][senderToken][protocol] != Index(0),
      "INDEX_DOES_NOT_EXIST");
    _;
  }
   
  function setLocatorWhitelist(
    bytes2 protocol,
    address newLocatorWhitelist
  ) external onlyOwner {
    locatorWhitelists[protocol] = newLocatorWhitelist;
  }
   
  function createIndex(
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) external returns (address) {
     
    if (indexes[signerToken][senderToken][protocol] == Index(0)) {
       
      indexes[signerToken][senderToken][protocol] = new Index();
      emit CreateIndex(signerToken, senderToken, protocol, address(indexes[signerToken][senderToken][protocol]));
    }
     
    return address(indexes[signerToken][senderToken][protocol]);
  }
   
  function addTokenToBlacklist(
    address token
  ) external onlyOwner {
    if (!tokenBlacklist[token]) {
      tokenBlacklist[token] = true;
      emit AddTokenToBlacklist(token);
    }
  }
   
  function removeTokenFromBlacklist(
    address token
  ) external onlyOwner {
    if (tokenBlacklist[token]) {
      tokenBlacklist[token] = false;
      emit RemoveTokenFromBlacklist(token);
    }
  }
   
  function setIntent(
    address signerToken,
    address senderToken,
    bytes2 protocol,
    uint256 stakingAmount,
    bytes32 locator
  ) external indexExists(signerToken, senderToken, protocol) {
     
    if (locatorWhitelists[protocol] != address(0)) {
      require(ILocatorWhitelist(locatorWhitelists[protocol]).has(locator),
      "LOCATOR_NOT_WHITELISTED");
    }
     
    require(!tokenBlacklist[signerToken] && !tokenBlacklist[senderToken],
      "PAIR_IS_BLACKLISTED");
    bool notPreviouslySet = (indexes[signerToken][senderToken][protocol].getLocator(msg.sender) == bytes32(0));
    if (notPreviouslySet) {
       
      if (stakingAmount > 0) {
         
        require(stakingToken.transferFrom(msg.sender, address(this), stakingAmount),
          "UNABLE_TO_STAKE");
      }
       
      indexes[signerToken][senderToken][protocol].setLocator(msg.sender, stakingAmount, locator);
      emit Stake(msg.sender, signerToken, senderToken, protocol, stakingAmount);
    } else {
      uint256 oldStake = indexes[signerToken][senderToken][protocol].getScore(msg.sender);
      _updateIntent(msg.sender, signerToken, senderToken, protocol, stakingAmount, locator, oldStake);
    }
  }
   
  function unsetIntent(
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) external {
    _unsetIntent(msg.sender, signerToken, senderToken, protocol);
  }
   
  function getLocators(
    address signerToken,
    address senderToken,
    bytes2 protocol,
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory locators,
    uint256[] memory scores,
    address nextCursor
  ) {
     
    if (tokenBlacklist[signerToken] || tokenBlacklist[senderToken]) {
      return (new bytes32[](0), new uint256[](0), address(0));
    }
     
    if (indexes[signerToken][senderToken][protocol] == Index(0)) {
      return (new bytes32[](0), new uint256[](0), address(0));
    }
    return indexes[signerToken][senderToken][protocol].getLocators(cursor, limit);
  }
   
  function getStakedAmount(
    address user,
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) public view returns (uint256 stakedAmount) {
    if (indexes[signerToken][senderToken][protocol] == Index(0)) {
      return 0;
    }
     
    return indexes[signerToken][senderToken][protocol].getScore(user);
  }
  function _updateIntent(
    address user,
    address signerToken,
    address senderToken,
    bytes2 protocol,
    uint256 newAmount,
    bytes32 newLocator,
    uint256 oldAmount
  ) internal {
     
    if (oldAmount < newAmount) {
       
      require(stakingToken.transferFrom(user, address(this), newAmount - oldAmount),
        "UNABLE_TO_STAKE");
    }
     
    if (newAmount < oldAmount) {
       
      require(stakingToken.transfer(user, oldAmount - newAmount));
    }
     
    indexes[signerToken][senderToken][protocol].updateLocator(user, newAmount, newLocator);
    emit Stake(user, signerToken, senderToken, protocol, newAmount);
  }
   
  function _unsetIntent(
    address user,
    address signerToken,
    address senderToken,
    bytes2 protocol
  ) internal indexExists(signerToken, senderToken, protocol) {
      
    uint256 score = indexes[signerToken][senderToken][protocol].getScore(user);
     
    indexes[signerToken][senderToken][protocol].unsetLocator(user);
    if (score > 0) {
       
      require(stakingToken.transfer(user, score));
    }
    emit Unstake(user, signerToken, senderToken, protocol, score);
  }
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
 
 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         
         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
 
 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         
         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");
         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
 
 
contract Swap is ISwap {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
   
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
      order.sender.amount,
      order.sender.id,
      order.sender.token,
      order.sender.kind
    );
     
    transferToken(
      order.signer.wallet,
      finalSenderWallet,
      order.signer.amount,
      order.signer.id,
      order.signer.token,
      order.signer.kind
    );
     
    if (order.affiliate.token != address(0)) {
      transferToken(
        order.signer.wallet,
        order.affiliate.wallet,
        order.affiliate.amount,
        order.affiliate.id,
        order.affiliate.token,
        order.affiliate.kind
      );
    }
    emit Swap(
      order.nonce,
      block.timestamp,
      order.signer.wallet,
      order.signer.amount,
      order.signer.id,
      order.signer.token,
      finalSenderWallet,
      order.sender.amount,
      order.sender.id,
      order.sender.token,
      order.affiliate.wallet,
      order.affiliate.amount,
      order.affiliate.id,
      order.affiliate.token
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
      uint256 amount,
      uint256 id,
      address token,
      bytes4 kind
  ) internal {
     
    require(from != to, "INVALID_SELF_TRANSFER");
    if (kind == ERC721_INTERFACE_ID) {
      require(amount == 0, "NO_AMOUNT_FIELD_IN_ERC721");
       
      IERC721(token).transferFrom(from, to, id);
    } else {
      require(id == 0, "NO_ID_FIELD_IN_ERC20");
       
      IERC20(token).safeTransferFrom(from, to, amount);
    }
  }
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
     
    _wrapEther(order.sender);
     
    swapContract.swap(order);
     
    _unwrapEther(order.sender.wallet, order.signer.token, order.signer.amount);
  }
   
  function provideDelegateOrder(
    Types.Order calldata order,
    IDelegate delegate
  ) external payable {
     
     
    require(order.signature.v != 0,
      "SIGNATURE_MUST_BE_SENT");
     
    _wrapEther(order.signer);
     
    delegate.provideOrder(order);
     
    _unwrapEther(order.signer.wallet, order.sender.token, order.sender.amount);
  }
   
  function _wrapEther(Types.Party memory party) internal {
     
    if (party.token == address(wethContract)) {
       
      require(party.amount == msg.value,
        "VALUE_MUST_BE_SENT");
       
      wethContract.deposit.value(msg.value)();
       
       
      wethContract.transfer(party.wallet, party.amount);
    } else {
       
      require(msg.value == 0,
        "VALUE_MUST_BE_ZERO");
    }
  }
   
  function _unwrapEther(address recipientWallet, address receivingToken, uint256 amount) internal {
     
    if (receivingToken == address(wethContract)) {
       
      wethContract.transferFrom(recipientWallet, address(this), amount);
       
      wethContract.withdraw(amount);
       
       
      (bool success, ) = recipientWallet.call.value(amount)("");
      require(success, "ETH_RETURN_FAILED");
    }
  }
}
 
 
contract Imports {}