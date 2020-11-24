 

 

pragma solidity ^0.4.11;

 
contract LoggingErrors {
   
  event LogErrorString(string errorString);

   

   
  function error(string _errorMessage) internal returns(bool) {
    emit LogErrorString(_errorMessage);
    return false;
  }
}

 

pragma solidity ^0.4.15;


 
contract WalletConnector is LoggingErrors {
   
  address public owner_;
  address public latestLogic_;
  uint256 public latestVersion_;
  mapping(uint256 => address) public logicVersions_;
  uint256 public birthBlock_;

   
  event LogLogicVersionAdded(uint256 version);
  event LogLogicVersionRemoved(uint256 version);

   
  function WalletConnector (
    uint256 _latestVersion,
    address _latestLogic
  ) public {
    owner_ = msg.sender;
    latestLogic_ = _latestLogic;
    latestVersion_ = _latestVersion;
    logicVersions_[_latestVersion] = _latestLogic;
    birthBlock_ = block.number;
  }

   
  function addLogicVersion (
    uint256 _version,
    address _logic
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, WalletConnector.addLogicVersion()');

    if (logicVersions_[_version] != 0)
      return error('Version already exists, WalletConnector.addLogicVersion()');

     
    if (_version > latestVersion_) {
      latestLogic_ = _logic;
      latestVersion_ = _version;
    }

    logicVersions_[_version] = _logic;
    LogLogicVersionAdded(_version);

    return true;
  }

   
  function removeLogicVersion(uint256 _version) external {
    require(msg.sender == owner_);
    require(_version != latestVersion_);
    delete logicVersions_[_version];
    LogLogicVersionRemoved(_version);
  }

   

   
  function getLogic(uint256 _version)
    external
    constant
    returns(address)
  {
    if (_version == 0)
      return latestLogic_;
    else
      return logicVersions_[_version];
  }
}

 

pragma solidity ^0.4.11;

interface Token {
   
  function totalSupply() external constant returns (uint256 supply);

   
   
  function balanceOf(address _owner) external constant returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) external returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) external returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function decimals() external constant returns(uint);
  function name() external constant returns(string);
}

 

pragma solidity ^0.4.15;




 
contract WalletV3 is LoggingErrors {
   
   
  address public owner_;
  address public exchange_;
  mapping(address => uint256) public tokenBalances_;

  address public logic_;  
  uint256 public birthBlock_;

  WalletConnector private connector_;

   
  event LogDeposit(address token, uint256 amount, uint256 balance);
  event LogWithdrawal(address token, uint256 amount, uint256 balance);

   
  constructor(address _owner, address _connector, address _exchange) public {
    owner_ = _owner;
    connector_ = WalletConnector(_connector);
    exchange_ = _exchange;
    logic_ = connector_.latestLogic_();
    birthBlock_ = block.number;
  }

  function () external payable {}

   

   
  function depositEther()
    external
    payable
  {
    require(
      logic_.delegatecall(abi.encodeWithSignature('deposit(address,uint256)', 0, msg.value)),
      "depositEther() failed"
    );
  }

   
  function depositERC20Token (
    address _token,
    uint256 _amount
  ) external
    returns(bool)
  {
     
    if (_token == 0)
      return error('Cannot deposit ether via depositERC20, Wallet.depositERC20Token()');

    require(
      logic_.delegatecall(abi.encodeWithSignature('deposit(address,uint256)', _token, _amount)),
      "depositERC20Token() failed"
    );
    return true;
  }

   
  function updateBalance (
    address  ,
    uint256  ,
    bool  
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

   
  function updateExchange(address _exchange)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner_, Wallet.updateExchange()');

     
    exchange_ = _exchange;

    return true;
  }

   
  function updateLogic(uint256 _version)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner_, Wallet.updateLogic()');

    address newVersion = connector_.getLogic(_version);

     
    if (newVersion == 0)
      return error('Invalid version, Wallet.updateLogic()');

    logic_ = newVersion;
    return true;
  }

   
  function verifyOrder (
    address  ,
    uint256  ,
    uint256  ,
    address  
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

   
  function withdraw(address  , uint256  )
    external
    returns(bool)
  {
    if(msg.sender != owner_)
      return error('msg.sender != owner, Wallet.withdraw()');

    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

   

   
  function balanceOf(address _token)
    public
    view
    returns(uint)
  {
    if (_token == address(0)) {
      return address(this).balance;
    } else {
      return Token(_token).balanceOf(this);
    }
  }

  function walletVersion() external pure returns(uint){
    return 3;
  }
}

 

pragma solidity ^0.4.15;



 
interface WalletBuilderInterface {

   
  function buildWallet(address _owner, address _exchange) external returns(address);
}

 

pragma solidity ^0.4.24;

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "msg.sender != owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "newOwner == 0");
    owner = newOwner;
  }

}

 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

pragma solidity ^0.4.24;







interface RetrieveWalletInterface {
  function retrieveWallet(address userAccount) external returns(address walletAddress);
}

contract UsersManager is Ownable, RetrieveWalletInterface {
  mapping(address => address) public userAccountToWallet_;  
  WalletBuilderInterface public walletBuilder;
  RetrieveWalletInterface public previousMapping;

  event LogUserAdded(address indexed user, address walletAddress);
  event LogWalletUpgraded(address indexed user, address oldWalletAddress, address newWalletAddress);
  event LogWalletBuilderChanged(address newWalletBuilder);

  constructor (
    address _previousMappingAddress,
    address _walletBuilder
  ) public {
    require(_walletBuilder != address (0), "WalletConnector address == 0");
    previousMapping = RetrieveWalletInterface(_previousMappingAddress);
    walletBuilder = WalletBuilderInterface(_walletBuilder);
  }

   

   
  function retrieveWallet(address userAccount)
    public
    returns(address walletAddress)
  {
    walletAddress = userAccountToWallet_[userAccount];
    if (walletAddress == address(0) && address(previousMapping) != address(0)) {
       
      walletAddress = previousMapping.retrieveWallet(userAccount);

      if (walletAddress != address(0)) {
        userAccountToWallet_[userAccount] = walletAddress;
      }
    }
  }

   
  function __addNewUser(address userExternalOwnedAccount, address exchangeAddress)
    private
    returns (address)
  {
    address userTradingWallet = walletBuilder.buildWallet(userExternalOwnedAccount, exchangeAddress);
    userAccountToWallet_[userExternalOwnedAccount] = userTradingWallet;
    emit LogUserAdded(userExternalOwnedAccount, userTradingWallet);
    return userTradingWallet;
  }

   
  function addNewUser(address userExternalOwnedAccount)
    public
    returns (bool)
  {
    require (
      retrieveWallet(userExternalOwnedAccount) == address(0),
      "User already exists, Exchange.addNewUser()"
    );

     
     
    __addNewUser(userExternalOwnedAccount, msg.sender);
    return true;
  }

   
  function upgradeWallet() external
  {
    address oldWallet = retrieveWallet(msg.sender);
    require(
      oldWallet != address(0),
      "User does not exists yet, Exchange.upgradeWallet()"
    );
    address exchange = WalletV3(oldWallet).exchange_();
    address userTradingWallet = __addNewUser(msg.sender, exchange);
    emit LogWalletUpgraded(msg.sender, oldWallet, userTradingWallet);
  }

   
  function adminSetWallet(address userExternalOwnedAccount, address userTradingWallet)
    onlyOwner
    external
  {
    address oldWallet = retrieveWallet(userExternalOwnedAccount);
    userAccountToWallet_[userExternalOwnedAccount] = userTradingWallet;
    emit LogUserAdded(userExternalOwnedAccount, userTradingWallet);
    if (oldWallet != address(0)) {
      emit LogWalletUpgraded(userExternalOwnedAccount, oldWallet, userTradingWallet);
    }
  }

   
  function setWalletBuilder(address newWalletBuilder)
    public
    onlyOwner
    returns (bool)
  {
    require(newWalletBuilder != address(0), "setWalletBuilder(): newWalletBuilder == 0");
    walletBuilder = WalletBuilderInterface(newWalletBuilder);
    emit LogWalletBuilderChanged(walletBuilder);
    return true;
  }
}

 

pragma solidity ^0.4.11;


interface BadERC20 {
  function transfer(address to, uint value) external;
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint value) external;
}

 
library SafeERC20 {

  event LogWarningNonZeroAllowance(address token, address spender, uint256 allowance);

   

  function safeTransfer(
    address _token,
    address _to,
    uint _amount
  )
  internal
  returns (bool result)
  {
    BadERC20(_token).transfer(_to, _amount);

    assembly {
      switch returndatasize()
      case 0 {                       
        result := not(0)             
      }
      case 32 {                      
        returndatacopy(0, 0, 32)
        result := mload(0)           
      }
      default {                      
        revert(0, 0)
      }
    }
  }


   

  function safeTransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  )
  internal
  returns (bool result)
  {
    BadERC20(_token).transferFrom(_from, _to, _value);

    assembly {
      switch returndatasize()
      case 0 {                       
        result := not(0)             
      }
      case 32 {                      
        returndatacopy(0, 0, 32)
        result := mload(0)           
      }
      default {                      
        revert(0, 0)
      }
    }
  }

  function checkAndApprove(
    address _token,
    address _spender,
    uint256 _value
  )
  internal
  returns (bool result)
  {
    uint currentAllowance = Token(_token).allowance(this, _spender);
    if (currentAllowance > 0) {
      emit LogWarningNonZeroAllowance(_token, _spender, currentAllowance);
       
      safeApprove(_token, _spender, 0);
    }
    return safeApprove(_token, _spender, _value);
  }
   

  function safeApprove(
    address _token,
    address _spender,
    uint256 _value
  )
  internal
  returns (bool result)
  {
    BadERC20(_token).approve(_spender, _value);

    assembly {
      switch returndatasize()
      case 0 {                       
        result := not(0)             
      }
      case 32 {                      
        returndatacopy(0, 0, 32)
        result := mload(0)           
      }
      default {                      
        revert(0, 0)
      }
    }
  }
}

 

pragma solidity ^0.4.24;






 
contract ExchangeV3 {

  using SafeMath for uint256;

   
  struct Order {
    address offerToken_;
    uint256 offerTokenTotal_;
    uint256 offerTokenRemaining_;   
    address wantToken_;
    uint256 wantTokenTotal_;
    uint256 wantTokenReceived_;   
  }

  struct OrderStatus {
    uint256 expirationBlock_;
    uint256 wantTokenReceived_;     
    uint256 offerTokenRemaining_;   
  }

  struct Orders {
    Order makerOrder;
    Order takerOrder;
    bool isMakerBuy;
  }

  struct FeeRate {
    uint256 edoPerQuote;
    uint256 edoPerQuoteDecimals;
  }

  struct Balances {
    uint256 makerWantTokenBalance;
    uint256 makerOfferTokenBalance;
    uint256 takerWantTokenBalance;
    uint256 takerOfferTokenBalance;
  }

  struct TradingWallets {
    WalletV3 maker;
    WalletV3 taker;
  }

  struct TradingAmounts {
    uint256 toTaker;
    uint256 toMaker;
    uint256 fee;
  }

  struct OrdersHashes {
    bytes32 makerOrder;
    bytes32 takerOrder;
  }

   
  address private orderBookAccount_;
  address public owner_;
  address public feeManager_;
  uint256 public birthBlock_;
  address public edoToken_;
  uint256 public dustLimit = 100;

  mapping (address => uint256) public feeEdoPerQuote;
  mapping (address => uint256) public feeEdoPerQuoteDecimals;

  address public eidooWallet_;

   
  mapping(address => mapping(address => FeeRate)) public customFee;
   
  mapping(address => bool) public feeTakersWhitelist;

   
  mapping(address => uint256) public quotePriority;

  mapping(bytes32 => OrderStatus) public orders_;  
  UsersManager public users;

   
  event LogFeeRateSet(address indexed token, uint256 rate, uint256 decimals);
  event LogQuotePrioritySet(address indexed quoteToken, uint256 priority);
  event LogCustomFeeSet(address indexed base, address indexed quote, uint256 edoPerQuote, uint256 edoPerQuoteDecimals);
  event LogFeeTakersWhitelistSet(address takerEOA, bool value);
  event LogWalletDeposit(address indexed walletAddress, address token, uint256 amount, uint256 balance);
  event LogWalletWithdrawal(address indexed walletAddress, address token, uint256 amount, uint256 balance);
  event LogWithdraw(address recipient, address token, uint256 amount);

  event LogOrderExecutionSuccess(
    bytes32 indexed makerOrderId,
    bytes32 indexed takerOrderId,
    uint256 toMaker,
    uint256 toTaker
  );
  event LogBatchOrderExecutionFailed(
    bytes32 indexed makerOrderId,
    bytes32 indexed takerOrderId,
    uint256 position
  );
  event LogOrderFilled(bytes32 indexed orderId, uint256 totalOfferRemaining, uint256 totalWantReceived);

   
  constructor (
    address _bookAccount,
    address _edoToken,
    uint256 _edoPerWei,
    uint256 _edoPerWeiDecimals,
    address _eidooWallet,
    address _usersMapperAddress
  ) public {
    orderBookAccount_ = _bookAccount;
    owner_ = msg.sender;
    birthBlock_ = block.number;
    edoToken_ = _edoToken;
    feeEdoPerQuote[address(0)] = _edoPerWei;
    feeEdoPerQuoteDecimals[address(0)] = _edoPerWeiDecimals;
    eidooWallet_ = _eidooWallet;
    quotePriority[address(0)] = 10;
    setUsersMapper(_usersMapperAddress);
  }

   
  function () external payable { }

  modifier onlyOwner() {
    require (
      msg.sender == owner_,
      "msg.sender != owner"
    );
    _;
  }

  function setUsersMapper(address _userMapperAddress)
    public
    onlyOwner
    returns (bool)
  {
    require(_userMapperAddress != address(0), "_userMapperAddress == 0");
    users = UsersManager(_userMapperAddress);
    return true;
  }

  function setFeeManager(address feeManager)
    public
    onlyOwner
  {
    feeManager_ = feeManager;
  }

  function setDustLimit(uint limit)
    public
    onlyOwner
  {
    dustLimit = limit;
  }

   
  function addNewUser(address userExternalOwnedAccount)
    external
    returns (bool)
  {
    return users.addNewUser(userExternalOwnedAccount);
  }

   
  function userAccountToWallet_(address userExternalOwnedAccount) external returns(address)
  {
    return users.retrieveWallet(userExternalOwnedAccount);
  }

  function retrieveWallet(address userExternalOwnedAccount)
    external
    returns(address)
  {
    return users.retrieveWallet(userExternalOwnedAccount);
  }

   
  function batchExecuteOrder(
    address[4][] ownedExternalAddressesAndTokenAddresses,
    uint256[8][] amountsExpirationsAndSalts,  
    uint8[2][] vSignatures,
    bytes32[4][] rAndSsignatures
  ) external
    returns(bool)
  {
    require(
      msg.sender == orderBookAccount_,
      "msg.sender != orderBookAccount, Exchange.batchExecuteOrder()"
    );

    for (uint256 i = 0; i < amountsExpirationsAndSalts.length; i++) {
       
 
 
 
 
 
 
 
 
      bool success = address(this).call(abi.encodeWithSignature("executeOrder(address[4],uint256[8],uint8[2],bytes32[4])",
        ownedExternalAddressesAndTokenAddresses[i],
        amountsExpirationsAndSalts[i],
        vSignatures[i],
        rAndSsignatures[i]
      ));
      if (!success) {
        OrdersHashes memory hashes = __generateOrderHashes__(
          ownedExternalAddressesAndTokenAddresses[i],
          amountsExpirationsAndSalts[i]
        );
        emit LogBatchOrderExecutionFailed(hashes.makerOrder, hashes.takerOrder, i);
      }
    }

    return true;
  }

   
  function executeOrder (
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts,  
    uint8[2] vSignatures,
    bytes32[4] rAndSsignatures
  ) public
    returns(bool)
  {
     
    TradingWallets memory wallets =
      getMakerAndTakerTradingWallets(ownedExternalAddressesAndTokenAddresses);

     
    __executeOrderInputIsValid__(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts
    );

     
    OrdersHashes memory hashes = __generateOrderHashes__(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts
    );

     
    require(
      __signatureIsValid__(
      ownedExternalAddressesAndTokenAddresses[0],
        hashes.makerOrder,
        vSignatures[0],
        rAndSsignatures[0],
        rAndSsignatures[1]
      ),
      "Maker signature is invalid, Exchange.executeOrder()"
    );

     
    require(__signatureIsValid__(
        ownedExternalAddressesAndTokenAddresses[2],
        hashes.takerOrder,
        vSignatures[1],
        rAndSsignatures[2],
        rAndSsignatures[3]
      ),
      "Taker signature is invalid, Exchange.executeOrder()"
    );

     
    Orders memory orders = __getOrders__(ownedExternalAddressesAndTokenAddresses, amountsExpirationsAndSalts, hashes);

     
    TradingAmounts memory amounts = __getTradeAmounts__(orders, ownedExternalAddressesAndTokenAddresses[2]);

    require(
      amounts.toTaker > 0 && amounts.toMaker > 0,
      "Token amount < 1, price ratio is invalid! Token value < 1, Exchange.executeOrder()"
    );

     
    orders.makerOrder.offerTokenRemaining_ = orders.makerOrder.offerTokenRemaining_.sub(amounts.toTaker);
    orders.makerOrder.wantTokenReceived_ = orders.makerOrder.wantTokenReceived_.add(amounts.toMaker);

    orders.takerOrder.offerTokenRemaining_ = orders.takerOrder.offerTokenRemaining_.sub(amounts.toMaker);
    orders.takerOrder.wantTokenReceived_ = orders.takerOrder.wantTokenReceived_.add(amounts.toTaker);

     
     
    uint limit = dustLimit;
    if ((orders.makerOrder.offerTokenRemaining_ <= limit) ||
        (orders.isMakerBuy && (orders.makerOrder.wantTokenReceived_ + limit) >= orders.makerOrder.wantTokenTotal_)
    ) {
      orders_[hashes.makerOrder].offerTokenRemaining_ = 0;
      orders_[hashes.makerOrder].wantTokenReceived_ = 0;
    } else {
      orders_[hashes.makerOrder].offerTokenRemaining_ = orders.makerOrder.offerTokenRemaining_;
      orders_[hashes.makerOrder].wantTokenReceived_ = orders.makerOrder.wantTokenReceived_;
    }

    if ((orders.takerOrder.offerTokenRemaining_ <= limit) ||
        (!orders.isMakerBuy && (orders.takerOrder.wantTokenReceived_ + limit) >= orders.takerOrder.wantTokenTotal_)
    ) {
      orders_[hashes.takerOrder].offerTokenRemaining_ = 0;
      orders_[hashes.takerOrder].wantTokenReceived_ = 0;
    } else {
      orders_[hashes.takerOrder].offerTokenRemaining_ = orders.takerOrder.offerTokenRemaining_;
      orders_[hashes.takerOrder].wantTokenReceived_ = orders.takerOrder.wantTokenReceived_;
    }

     
    __executeTokenTransfer__(
      ownedExternalAddressesAndTokenAddresses,
      amounts,
      wallets
    );

     
    emit LogOrderFilled(hashes.makerOrder, orders.makerOrder.offerTokenRemaining_, orders.makerOrder.wantTokenReceived_);
    emit LogOrderFilled(hashes.takerOrder, orders.takerOrder.offerTokenRemaining_, orders.takerOrder.wantTokenReceived_);
    emit LogOrderExecutionSuccess(hashes.makerOrder, hashes.takerOrder, amounts.toMaker, amounts.toTaker);

    return true;
  }

   
  function setFeeRate(
    address _quoteToken,
    uint256 _edoPerQuote,
    uint256 _edoPerQuoteDecimals
  ) external
    returns(bool)
  {
    require(
      msg.sender == owner_ || msg.sender == feeManager_,
      "msg.sender != owner, Exchange.setFeeRate()"
    );

    require(
      quotePriority[_quoteToken] != 0,
      "quotePriority[_quoteToken] == 0, Exchange.setFeeRate()"
    );

    feeEdoPerQuote[_quoteToken] = _edoPerQuote;
    feeEdoPerQuoteDecimals[_quoteToken] = _edoPerQuoteDecimals;

    emit LogFeeRateSet(_quoteToken, _edoPerQuote, _edoPerQuoteDecimals);

    return true;
  }

   
  function setEidooWallet(
    address eidooWallet
  ) external
    returns(bool)
  {
    require(
      msg.sender == owner_,
      "msg.sender != owner, Exchange.setEidooWallet()"
    );
    eidooWallet_ = eidooWallet;
    return true;
  }

   
  function setOrderBookAcount (
    address account
  ) external
    returns(bool)
  {
    require(
      msg.sender == owner_,
      "msg.sender != owner, Exchange.setOrderBookAcount()"
    );
    orderBookAccount_ = account;
    return true;
  }

   
  function setCustomFee (
    address _baseTokenAddress,
    address _quoteTokenAddress,
    uint256 _edoPerQuote,
    uint256 _edoPerQuoteDecimals
  ) external
    returns(bool)
  {
     
    require(
      msg.sender == owner_ || msg.sender == feeManager_,
      "msg.sender != owner, Exchange.setCustomFee()"
    );
    if (_edoPerQuote == 0 && _edoPerQuoteDecimals == 0) {
      delete customFee[_baseTokenAddress][_quoteTokenAddress];
    } else {
      customFee[_baseTokenAddress][_quoteTokenAddress] = FeeRate({
        edoPerQuote: _edoPerQuote,
        edoPerQuoteDecimals: _edoPerQuoteDecimals
      });
    }
    emit LogCustomFeeSet(_baseTokenAddress, _quoteTokenAddress, _edoPerQuote, _edoPerQuoteDecimals);
    return true;
  }

   
  function mustSkipFee(address base, address quote) external view returns(bool) {
    FeeRate storage rate = customFee[base][quote];
    return rate.edoPerQuote == 0 && rate.edoPerQuoteDecimals != 0;
  }

   
  function setFeeTakersWhitelist(
    address _takerEOA,
    bool _value
  ) external
    returns(bool)
  {
    require(
      msg.sender == owner_,
      "msg.sender != owner, Exchange.setFeeTakersWhitelist()"
    );
    feeTakersWhitelist[_takerEOA] = _value;
    emit LogFeeTakersWhitelistSet(_takerEOA, _value);
    return true;
  }

   

  function setQuotePriority(address _token, uint256 _priority)
    external
    returns(bool)
  {
    require(
      msg.sender == owner_,
      "msg.sender != owner, Exchange.setQuotePriority()"
    );
    quotePriority[_token] = _priority;
    emit LogQuotePrioritySet(_token, _priority);
    return true;
  }

   

   
  function walletDeposit(
    address tokenAddress,
    uint256 amount,
    uint256 tradingWalletBalance
  ) external
  {
    emit LogWalletDeposit(msg.sender, tokenAddress, amount, tradingWalletBalance);
  }

   
  function walletWithdrawal(
    address tokenAddress,
    uint256 amount,
    uint256 tradingWalletBalance
  ) external
  {
    emit LogWalletWithdrawal(msg.sender, tokenAddress, amount, tradingWalletBalance);
  }

   

   
  function getMakerAndTakerTradingWallets(address[4] ownedExternalAddressesAndTokenAddresses)
    private
    returns (TradingWallets wallets)
  {
    wallets = TradingWallets(
      WalletV3(users.retrieveWallet(ownedExternalAddressesAndTokenAddresses[0])),  
      WalletV3(users.retrieveWallet(ownedExternalAddressesAndTokenAddresses[2]))  
    );

     
    require(
      wallets.maker != address(0),
      "Maker wallet does not exist, Exchange.getMakerAndTakerTradingWallets()"
    );

    require(
      wallets.taker != address(0),
      "Taker wallet does not exist, Exchange.getMakerAndTakerTradingWallets()"
    );
  }

  function calculateFee(
    address base,
    address quote,
    uint256 quoteAmount,
    address takerEOA
  ) public
    view
    returns(uint256)
  {
    require(quotePriority[quote] > quotePriority[base], "Invalid pair");
    return __calculateFee__(base, quote, quoteAmount, takerEOA);
  }

  function __calculateFee__(
    address base,
    address quote,
    uint256 quoteAmount,
    address takerEOA
  )
    internal view returns(uint256)
  {
    FeeRate memory fee;
    if (feeTakersWhitelist[takerEOA]) {
      return 0;
    }

     
      fee = customFee[base][quote];
      if (fee.edoPerQuote == 0 && fee.edoPerQuoteDecimals == 0) {
         
        fee.edoPerQuote = feeEdoPerQuote[quote];
        fee.edoPerQuoteDecimals = feeEdoPerQuoteDecimals[quote];
      }
      return quoteAmount.mul(fee.edoPerQuote).div(10**fee.edoPerQuoteDecimals);
  }

   
  function __executeOrderInputIsValid__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts
  ) private view
  {
     
    require(
      msg.sender == orderBookAccount_ || msg.sender == address(this),
      "msg.sender != orderBookAccount, Exchange.__executeOrderInputIsValid__()"
    );

     
    require (
      block.number <= amountsExpirationsAndSalts[4],
      "Maker order has expired, Exchange.__executeOrderInputIsValid__()"
    );

    require(
      block.number <= amountsExpirationsAndSalts[6],
      "Taker order has expired, Exchange.__executeOrderInputIsValid__()"
    );

    require(
      quotePriority[ownedExternalAddressesAndTokenAddresses[1]] != quotePriority[ownedExternalAddressesAndTokenAddresses[3]],
      "Quote token is omitted! Is not offered by either the Taker or Maker, Exchange.__executeOrderInputIsValid__()"
    );

     
    if (
        amountsExpirationsAndSalts[0] == 0 ||
        amountsExpirationsAndSalts[1] == 0 ||
        amountsExpirationsAndSalts[2] == 0 ||
        amountsExpirationsAndSalts[3] == 0
      )
    {
      revert("May not execute an order where token amount == 0, Exchange.__executeOrderInputIsValid__()");
    }
  }

  function __getBalance__(address token, address owner) private view returns(uint256) {
    if (token == address(0)) {
      return owner.balance;
    } else {
      return Token(token).balanceOf(owner);
    }
  }

   
  function __executeTokenTransfer__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    TradingAmounts amounts,
    TradingWallets wallets
  ) private
  {

     
    Balances memory initialBalances;
    initialBalances.takerOfferTokenBalance = __getBalance__(ownedExternalAddressesAndTokenAddresses[3], wallets.taker);
    initialBalances.makerOfferTokenBalance = __getBalance__(ownedExternalAddressesAndTokenAddresses[1], wallets.maker);
    initialBalances.takerWantTokenBalance = __getBalance__(ownedExternalAddressesAndTokenAddresses[1], wallets.taker);
    initialBalances.makerWantTokenBalance = __getBalance__(ownedExternalAddressesAndTokenAddresses[3], wallets.maker);
     


     
     
    require(
      wallets.maker.verifyOrder(
        ownedExternalAddressesAndTokenAddresses[1],
        amounts.toTaker,
        0,
        0
      ),
      "Maker wallet could not prepare the transfer, Exchange.__executeTokenTransfer__()"
    );

    require(
      wallets.taker.verifyOrder(
        ownedExternalAddressesAndTokenAddresses[3],
        amounts.toMaker,
        amounts.fee,
        edoToken_
      ),
      "Taker wallet could not prepare the transfer, Exchange.__executeTokenTransfer__()"
    );

     
    address makerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[1];
    address takerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[3];

    WalletV3 makerTradingWallet = wallets.maker;
    WalletV3 takerTradingWallet = wallets.taker;

     
    if(amounts.fee != 0) {
      uint256 takerInitialFeeTokenBalance = Token(edoToken_).balanceOf(takerTradingWallet);

      require(
        Token(edoToken_).transferFrom(takerTradingWallet, eidooWallet_, amounts.fee),
        "Cannot transfer fees from taker trading wallet to eidoo wallet, Exchange.__executeTokenTransfer__()"
      );
      require(
        Token(edoToken_).balanceOf(takerTradingWallet) == takerInitialFeeTokenBalance.sub(amounts.fee),
        "Wrong fee token balance after transfer, Exchange.__executeTokenTransfer__()"
      );
    }

     
    if (makerOfferTokenAddress == address(0)) {
      address(takerTradingWallet).transfer(amounts.toTaker);
    } else {
      require(
        SafeERC20.safeTransferFrom(makerOfferTokenAddress, makerTradingWallet, takerTradingWallet, amounts.toTaker),
        "Token transfership from makerTradingWallet to takerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
    }

    if (takerOfferTokenAddress == address(0)) {
      address(makerTradingWallet).transfer(amounts.toMaker);
    } else {
      require(
        SafeERC20.safeTransferFrom(takerOfferTokenAddress, takerTradingWallet, makerTradingWallet, amounts.toMaker),
        "Token transfership from takerTradingWallet to makerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
    }

     
    Balances memory expected;
    if (takerTradingWallet != makerTradingWallet) {
      expected.makerWantTokenBalance = initialBalances.makerWantTokenBalance.add(amounts.toMaker);
      expected.makerOfferTokenBalance = initialBalances.makerOfferTokenBalance.sub(amounts.toTaker);
      expected.takerWantTokenBalance = edoToken_ == makerOfferTokenAddress
        ? initialBalances.takerWantTokenBalance.add(amounts.toTaker).sub(amounts.fee)
        : initialBalances.takerWantTokenBalance.add(amounts.toTaker);
      expected.takerOfferTokenBalance = edoToken_ == takerOfferTokenAddress
        ? initialBalances.takerOfferTokenBalance.sub(amounts.toMaker).sub(amounts.fee)
        : initialBalances.takerOfferTokenBalance.sub(amounts.toMaker);
    } else {
      expected.makerWantTokenBalance = expected.takerOfferTokenBalance =
        edoToken_ == takerOfferTokenAddress
        ? initialBalances.takerOfferTokenBalance.sub(amounts.fee)
        : initialBalances.takerOfferTokenBalance;
      expected.makerOfferTokenBalance = expected.takerWantTokenBalance =
        edoToken_ == makerOfferTokenAddress
        ? initialBalances.takerWantTokenBalance.sub(amounts.fee)
        : initialBalances.takerWantTokenBalance;
    }

    require(
      expected.takerOfferTokenBalance == __getBalance__(takerOfferTokenAddress, takerTradingWallet),
      "Wrong taker offer token balance after transfer, Exchange.__executeTokenTransfer__()"
    );
    require(
      expected.makerOfferTokenBalance == __getBalance__(makerOfferTokenAddress, makerTradingWallet),
      "Wrong maker offer token balance after transfer, Exchange.__executeTokenTransfer__()"
    );
    require(
      expected.takerWantTokenBalance == __getBalance__(makerOfferTokenAddress, takerTradingWallet),
      "Wrong taker want token balance after transfer, Exchange.__executeTokenTransfer__()"
    );
    require(
      expected.makerWantTokenBalance == __getBalance__(takerOfferTokenAddress, makerTradingWallet),
      "Wrong maker want token balance after transfer, Exchange.__executeTokenTransfer__()"
    );
  }

   
  function generateOrderHashes(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts
  ) public
    view
    returns (bytes32[2])
  {
    OrdersHashes memory hashes = __generateOrderHashes__(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts
    );
    return [hashes.makerOrder, hashes.takerOrder];
  }

  function __generateOrderHashes__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts
  ) internal
    view
    returns (OrdersHashes)
  {
    bytes32 makerOrderHash = keccak256(abi.encodePacked(
      address(this),
      ownedExternalAddressesAndTokenAddresses[0],  
      ownedExternalAddressesAndTokenAddresses[1],  
      amountsExpirationsAndSalts[0],   
      ownedExternalAddressesAndTokenAddresses[3],  
      amountsExpirationsAndSalts[1],   
      amountsExpirationsAndSalts[4],  
      amountsExpirationsAndSalts[5]  
    ));

    bytes32 takerOrderHash = keccak256(abi.encodePacked(
      address(this),
      ownedExternalAddressesAndTokenAddresses[2],  
      ownedExternalAddressesAndTokenAddresses[3],  
      amountsExpirationsAndSalts[2],   
      ownedExternalAddressesAndTokenAddresses[1],  
      amountsExpirationsAndSalts[3],   
      amountsExpirationsAndSalts[6],  
      amountsExpirationsAndSalts[7]  
    ));

    return OrdersHashes(makerOrderHash, takerOrderHash);
  }

  function __getOrders__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts,
    OrdersHashes hashes
  ) private
    returns(Orders orders)
  {
    OrderStatus storage makerOrderStatus = orders_[hashes.makerOrder];
    OrderStatus storage takerOrderStatus = orders_[hashes.takerOrder];

    orders.makerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[1];
    orders.makerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[0];
    orders.makerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[3];
    orders.makerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[1];

    if (makerOrderStatus.expirationBlock_ > 0) {   
       
      require(
        makerOrderStatus.offerTokenRemaining_ != 0,
        "Maker order is inactive, Exchange.executeOrder()"
      );
      orders.makerOrder.offerTokenRemaining_ = makerOrderStatus.offerTokenRemaining_;  
      orders.makerOrder.wantTokenReceived_ = makerOrderStatus.wantTokenReceived_;  
    } else {
      makerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[4];  
      orders.makerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[0];  
      orders.makerOrder.wantTokenReceived_ = 0;  
    }

    orders.takerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[3];
    orders.takerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[2];
    orders.takerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[1];
    orders.takerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[3];

    if (takerOrderStatus.expirationBlock_ > 0) {   
      require(
        takerOrderStatus.offerTokenRemaining_ != 0,
        "Taker order is inactive, Exchange.executeOrder()"
      );
      orders.takerOrder.offerTokenRemaining_ = takerOrderStatus.offerTokenRemaining_;   
      orders.takerOrder.wantTokenReceived_ = takerOrderStatus.wantTokenReceived_;  
    } else {
      takerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[6];  
      orders.takerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[2];   
      orders.takerOrder.wantTokenReceived_ = 0;  
    }

    orders.isMakerBuy = __isSell__(orders.takerOrder);
  }

   
  function __isSell__(Order _order) internal view returns (bool) {
    return quotePriority[_order.offerToken_] < quotePriority[_order.wantToken_];
  }

   
  function __getTradeAmounts__(
    Orders memory orders,
    address takerEOA
  ) internal
    view
    returns (TradingAmounts)
  {
    Order memory makerOrder = orders.makerOrder;
    Order memory takerOrder = orders.takerOrder;
    bool isMakerBuy = orders.isMakerBuy;   
    uint256 priceRatio;
    uint256 makerAmountLeftToReceive;
    uint256 takerAmountLeftToReceive;

    uint toTakerAmount;
    uint toMakerAmount;

    if (makerOrder.offerTokenTotal_ >= makerOrder.wantTokenTotal_) {
      priceRatio = makerOrder.offerTokenTotal_.mul(2**128).div(makerOrder.wantTokenTotal_);
      require(
        priceRatio >= takerOrder.wantTokenTotal_.mul(2**128).div(takerOrder.offerTokenTotal_),
        "Taker price is greater than maker price, Exchange.__getTradeAmounts__()"
      );
      if (isMakerBuy) {
         
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
         
        toTakerAmount = toMakerAmount.mul(priceRatio).div(2**128);
      } else {
         
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
        toMakerAmount = toTakerAmount.mul(2**128).div(priceRatio);
      }
    } else {
      priceRatio = makerOrder.wantTokenTotal_.mul(2**128).div(makerOrder.offerTokenTotal_);
      require(
        priceRatio <= takerOrder.offerTokenTotal_.mul(2**128).div(takerOrder.wantTokenTotal_),
        "Taker price is less than maker price, Exchange.__getTradeAmounts__()"
      );
      if (isMakerBuy) {
         
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
        toTakerAmount = toMakerAmount.mul(2**128).div(priceRatio);
      } else {
         
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
         
        toMakerAmount = toTakerAmount.mul(priceRatio).div(2**128);
      }
    }

    uint fee = isMakerBuy
      ? __calculateFee__(makerOrder.wantToken_, makerOrder.offerToken_, toTakerAmount, takerEOA)
      : __calculateFee__(makerOrder.offerToken_, makerOrder.wantToken_, toMakerAmount, takerEOA);

    return TradingAmounts(toTakerAmount, toMakerAmount, fee);
  }

   
  function __max__(uint256 a, uint256 b)
    private
    pure
    returns (uint256)
  {
    return a < b
      ? b
      : a;
  }

   
  function __min__(uint256 a, uint256 b)
    private
    pure
    returns (uint256)
  {
    return a < b
      ? a
      : b;
  }

   
  function __signatureIsValid__(
    address signer,
    bytes32 orderHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private
    pure
    returns (bool)
  {
    address recoveredAddr = ecrecover(
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)),
      v,
      r,
      s
    );

    return recoveredAddr == signer;
  }

   
  function __tokenAndWalletBalancesMatch__(
    address makerTradingWallet,
    address takerTradingWallet,
    address token
  ) private
    view
    returns(bool)
  {
    if (Token(token).balanceOf(makerTradingWallet) != WalletV3(makerTradingWallet).balanceOf(token)) {
      return false;
    }

    if (Token(token).balanceOf(takerTradingWallet) != WalletV3(takerTradingWallet).balanceOf(token)) {
      return false;
    }

    return true;
  }

   
  function withdraw(address _tokenAddress)
    public
    onlyOwner
  returns(bool)
  {
    uint tokenBalance;
    if (_tokenAddress == address(0)) {
      tokenBalance = address(this).balance;
      msg.sender.transfer(tokenBalance);
    } else {
      tokenBalance = Token(_tokenAddress).balanceOf(address(this));
      require(
        Token(_tokenAddress).transfer(msg.sender, tokenBalance),
        "withdraw transfer failed"
      );
    }
    emit LogWithdraw(msg.sender, _tokenAddress, tokenBalance);
    return true;
  }

}