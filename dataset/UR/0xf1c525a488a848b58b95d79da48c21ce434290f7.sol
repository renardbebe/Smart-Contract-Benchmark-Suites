 

pragma solidity ^0.4.24;

 
contract LoggingErrors {
   
  event LogErrorString(string errorString);

   

   
  function error(string _errorMessage) internal returns(bool) {
    LogErrorString(_errorMessage);
    return false;
  }
}

 
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

 
contract WalletV2 is LoggingErrors {
   
   
  address public owner_;
  address public exchange_;
  mapping(address => uint256) public tokenBalances_;

  address public logic_;  
  uint256 public birthBlock_;

  WalletConnector private connector_;

   
  event LogDeposit(address token, uint256 amount, uint256 balance);
  event LogWithdrawal(address token, uint256 amount, uint256 balance);

   
  function WalletV2(address _owner, address _connector) public {
    owner_ = _owner;
    connector_ = WalletConnector(_connector);
    exchange_ = msg.sender;
    logic_ = connector_.latestLogic_();
    birthBlock_ = block.number;
  }

   
  function () external payable {
    require(msg.sender == exchange_);
  }

   

   
  function depositEther()
    external
    payable
  {
    require(logic_.delegatecall(bytes4(sha3('deposit(address,uint256)')), 0, msg.value));
  }

   
  function depositERC20Token (
    address _token,
    uint256 _amount
  ) external
    returns(bool)
  {
     
    if (_token == 0)
      return error('Cannot deposit ether via depositERC20, Wallet.depositERC20Token()');

    require(logic_.delegatecall(bytes4(sha3('deposit(address,uint256)')), _token, _amount));
    return true;
  }

   
  function updateBalance (
    address _token,
    uint256 _amount,
    bool _subtractionFlag
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
    address _token,
    uint256 _amount,
    uint256 _fee,
    address _feeToken
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

   
  function withdraw(address _token, uint256 _amount)
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
    return tokenBalances_[_token];
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
   
  function totalSupply() constant returns (uint256 supply) {}

   
   
  function balanceOf(address _owner) constant returns (uint256 balance) {}

   
   
   
   
  function transfer(address _to, uint256 _value) returns (bool success) {}

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

   
   
   
   
  function approve(address _spender, uint256 _value) returns (bool success) {}

   
   
   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

interface ExchangeV1 {
  function userAccountToWallet_(address) external returns(address);
}

interface BadERC20 {
  function transfer(address to, uint value) external;
  function transferFrom(address from, address to, uint256 value) external;
}

 
contract ExchangeV2 is LoggingErrors {

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

   
  address public previousExchangeAddress_;
  address private orderBookAccount_;
  address public owner_;
  uint256 public birthBlock_;
  address public edoToken_;
  address public walletConnector;

  mapping (address => uint256) public feeEdoPerQuote;
  mapping (address => uint256) public feeEdoPerQuoteDecimals;

  address public eidooWallet_;

   
  mapping(address => mapping(address => bool)) public mustSkipFee;

   
  mapping(address => uint256) public quotePriority;

  mapping(bytes32 => OrderStatus) public orders_;  
  mapping(address => address) public userAccountToWallet_;  

   
  event LogFeeRateSet(address indexed token, uint256 rate, uint256 decimals);
  event LogQuotePrioritySet(address indexed quoteToken, uint256 priority);
  event LogMustSkipFeeSet(address indexed base, address indexed quote, bool mustSkipFee);
  event LogUserAdded(address indexed user, address walletAddress);
  event LogWalletDeposit(address indexed walletAddress, address token, uint256 amount, uint256 balance);
  event LogWalletWithdrawal(address indexed walletAddress, address token, uint256 amount, uint256 balance);

  event LogOrderExecutionSuccess(
    bytes32 indexed makerOrderId,
    bytes32 indexed takerOrderId,
    uint256 toMaker,
    uint256 toTaker
  );
  event LogOrderFilled(bytes32 indexed orderId, uint256 totalOfferRemaining, uint256 totalWantReceived);

   
  constructor (
    address _bookAccount,
    address _edoToken,
    uint256 _edoPerWei,
    uint256 _edoPerWeiDecimals,
    address _eidooWallet,
    address _previousExchangeAddress,
    address _walletConnector
  ) public {
    orderBookAccount_ = _bookAccount;
    owner_ = msg.sender;
    birthBlock_ = block.number;
    edoToken_ = _edoToken;
    feeEdoPerQuote[address(0)] = _edoPerWei;
    feeEdoPerQuoteDecimals[address(0)] = _edoPerWeiDecimals;
    eidooWallet_ = _eidooWallet;
    quotePriority[address(0)] = 10;
    previousExchangeAddress_ = _previousExchangeAddress;
    require(_walletConnector != address (0), "WalletConnector address == 0");
    walletConnector = _walletConnector;
  }

   
  function () external payable { }

   

   
  function retrieveWallet(address userAccount)
    public
    returns(address walletAddress)
  {
    walletAddress = userAccountToWallet_[userAccount];
    if (walletAddress == address(0) && previousExchangeAddress_ != 0) {
       
      walletAddress = ExchangeV1(previousExchangeAddress_).userAccountToWallet_(userAccount);
       
       

      if (walletAddress != address(0)) {
        userAccountToWallet_[userAccount] = walletAddress;
      }
    }
  }

   
  function addNewUser(address userExternalOwnedAccount)
    public
    returns (bool)
  {
    if (retrieveWallet(userExternalOwnedAccount) != address(0)) {
      return error("User already exists, Exchange.addNewUser()");
    }

     
    address userTradingWallet = new WalletV2(userExternalOwnedAccount, walletConnector);
    userAccountToWallet_[userExternalOwnedAccount] = userTradingWallet;
    emit LogUserAdded(userExternalOwnedAccount, userTradingWallet);
    return true;
  }

   
  function batchExecuteOrder(
    address[4][] ownedExternalAddressesAndTokenAddresses,
    uint256[8][] amountsExpirationsAndSalts,  
    uint8[2][] vSignatures,
    bytes32[4][] rAndSsignatures
  ) external
    returns(bool)
  {
    for (uint256 i = 0; i < amountsExpirationsAndSalts.length; i++) {
      require(
        executeOrder(
          ownedExternalAddressesAndTokenAddresses[i],
          amountsExpirationsAndSalts[i],
          vSignatures[i],
          rAndSsignatures[i]
        ),
        "Cannot execute order, Exchange.batchExecuteOrder()"
      );
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
     
     
    WalletV2[2] memory makerAndTakerTradingWallets = [
      WalletV2(retrieveWallet(ownedExternalAddressesAndTokenAddresses[0])),  
      WalletV2(retrieveWallet(ownedExternalAddressesAndTokenAddresses[2]))  
    ];

     
    if(!__executeOrderInputIsValid__(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts,
      makerAndTakerTradingWallets[0],  
      makerAndTakerTradingWallets[1]  
    )) {
      return error("Input is invalid, Exchange.executeOrder()");
    }

     
    bytes32[2] memory makerAndTakerOrderHash = generateOrderHashes(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts
    );

     
    if (!__signatureIsValid__(
      ownedExternalAddressesAndTokenAddresses[0],
      makerAndTakerOrderHash[0],
      vSignatures[0],
      rAndSsignatures[0],
      rAndSsignatures[1]
    )) {
      return error("Maker signature is invalid, Exchange.executeOrder()");
    }

     
    if (!__signatureIsValid__(
      ownedExternalAddressesAndTokenAddresses[2],
      makerAndTakerOrderHash[1],
      vSignatures[1],
      rAndSsignatures[2],
      rAndSsignatures[3]
    )) {
      return error("Taker signature is invalid, Exchange.executeOrder()");
    }

     
    OrderStatus memory makerOrderStatus = orders_[makerAndTakerOrderHash[0]];
    OrderStatus memory takerOrderStatus = orders_[makerAndTakerOrderHash[1]];
    Order memory makerOrder;
    Order memory takerOrder;

    makerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[1];
    makerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[0];
    makerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[3];
    makerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[1];

    if (makerOrderStatus.expirationBlock_ > 0) {   
       
      if (makerOrderStatus.offerTokenRemaining_ == 0) {
        return error("Maker order is inactive, Exchange.executeOrder()");
      }
      makerOrder.offerTokenRemaining_ = makerOrderStatus.offerTokenRemaining_;  
      makerOrder.wantTokenReceived_ = makerOrderStatus.wantTokenReceived_;  
    } else {
      makerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[0];  
      makerOrder.wantTokenReceived_ = 0;  
      makerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[4];  
    }

    takerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[3];
    takerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[2];
    takerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[1];
    takerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[3];

    if (takerOrderStatus.expirationBlock_ > 0) {   
      if (takerOrderStatus.offerTokenRemaining_ == 0) {
        return error("Taker order is inactive, Exchange.executeOrder()");
      }
      takerOrder.offerTokenRemaining_ = takerOrderStatus.offerTokenRemaining_;   
      takerOrder.wantTokenReceived_ = takerOrderStatus.wantTokenReceived_;  

    } else {
      takerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[2];   
      takerOrder.wantTokenReceived_ = 0;  
      takerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[6];  
    }

     
    if (!__ordersMatch_and_AreVaild__(makerOrder, takerOrder)) {
      return error("Orders do not match, Exchange.executeOrder()");
    }

     
     
     
    uint[2] memory toTakerAndToMakerAmount;
    toTakerAndToMakerAmount = __getTradeAmounts__(makerOrder, takerOrder);

     
    if (toTakerAndToMakerAmount[0] < 1 || toTakerAndToMakerAmount[1] < 1) {
      return error("Token amount < 1, price ratio is invalid! Token value < 1, Exchange.executeOrder()");
    }

    uint calculatedFee = __calculateFee__(makerOrder, toTakerAndToMakerAmount[0], toTakerAndToMakerAmount[1]);

     
    if (
      takerOrder.offerToken_ == edoToken_ &&
      Token(edoToken_).balanceOf(makerAndTakerTradingWallets[1]) < calculatedFee.add(toTakerAndToMakerAmount[1])
    ) {
      return error("Taker has an insufficient EDO token balance to cover the fee AND the offer, Exchange.executeOrder()");
    } else if (Token(edoToken_).balanceOf(makerAndTakerTradingWallets[1]) < calculatedFee) {
      return error("Taker has an insufficient EDO token balance to cover the fee, Exchange.executeOrder()");
    }

     
    if (
      !__ordersVerifiedByWallets__(
        ownedExternalAddressesAndTokenAddresses,
        toTakerAndToMakerAmount[1],
        toTakerAndToMakerAmount[0],
        makerAndTakerTradingWallets[0],
        makerAndTakerTradingWallets[1],
        calculatedFee
    )) {
      return error("Order could not be verified by wallets, Exchange.executeOrder()");
    }

     
    makerOrderStatus.offerTokenRemaining_ = makerOrder.offerTokenRemaining_.sub(toTakerAndToMakerAmount[0]);
    makerOrderStatus.wantTokenReceived_ = makerOrder.wantTokenReceived_.add(toTakerAndToMakerAmount[1]);

    takerOrderStatus.offerTokenRemaining_ = takerOrder.offerTokenRemaining_.sub(toTakerAndToMakerAmount[1]);
    takerOrderStatus.wantTokenReceived_ = takerOrder.wantTokenReceived_.add(toTakerAndToMakerAmount[0]);

     
    orders_[makerAndTakerOrderHash[0]] = makerOrderStatus;
    orders_[makerAndTakerOrderHash[1]] = takerOrderStatus;

     
    require(
      __executeTokenTransfer__(
        ownedExternalAddressesAndTokenAddresses,
        toTakerAndToMakerAmount[0],
        toTakerAndToMakerAmount[1],
        calculatedFee,
        makerAndTakerTradingWallets[0],
        makerAndTakerTradingWallets[1]
      ),
      "Cannot execute token transfer, Exchange.__executeTokenTransfer__()"
    );

     
    emit LogOrderFilled(makerAndTakerOrderHash[0], makerOrderStatus.offerTokenRemaining_, makerOrderStatus.wantTokenReceived_);
    emit LogOrderFilled(makerAndTakerOrderHash[1], takerOrderStatus.offerTokenRemaining_, takerOrderStatus.wantTokenReceived_);
    emit LogOrderExecutionSuccess(makerAndTakerOrderHash[0], makerAndTakerOrderHash[1], toTakerAndToMakerAmount[1], toTakerAndToMakerAmount[0]);

    return true;
  }

   
  function setFeeRate(
    address _quoteToken,
    uint256 _edoPerQuote,
    uint256 _edoPerQuoteDecimals
  ) external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setFeeRate()");
    }

    if (quotePriority[_quoteToken] == 0) {
      return error("quotePriority[_quoteToken] == 0, Exchange.setFeeRate()");
    }

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
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setEidooWallet()");
    }
    eidooWallet_ = eidooWallet;
    return true;
  }

   
  function setOrderBookAcount (
    address account
  ) external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setOrderBookAcount()");
    }
    orderBookAccount_ = account;
    return true;
  }

   
  function setMustSkipFee (
    address _baseTokenAddress,
    address _quoteTokenAddress,
    bool _mustSkipFee
  ) external
    returns(bool)
  {
     
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setMustSkipFee()");
    }
    mustSkipFee[_baseTokenAddress][_quoteTokenAddress] = _mustSkipFee;
    emit LogMustSkipFeeSet(_baseTokenAddress, _quoteTokenAddress, _mustSkipFee);
    return true;
  }

   

  function setQuotePriority(address _token, uint256 _priority)
    external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setQuotePriority()");
    }
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

   

   
  function __calculateFee__(
    Order makerOrder,
    uint256 toTakerAmount,
    uint256 toMakerAmount
  ) private
    view
    returns(uint256)
  {
     
    if (!__isSell__(makerOrder)) {
       
      return mustSkipFee[makerOrder.wantToken_][makerOrder.offerToken_]
        ? 0
        : toTakerAmount.mul(feeEdoPerQuote[makerOrder.offerToken_]).div(10**feeEdoPerQuoteDecimals[makerOrder.offerToken_]);
    } else {
       
      return mustSkipFee[makerOrder.offerToken_][makerOrder.wantToken_]
        ? 0
        : toMakerAmount.mul(feeEdoPerQuote[makerOrder.wantToken_]).div(10**feeEdoPerQuoteDecimals[makerOrder.wantToken_]);
    }
  }

   
  function __executeOrderInputIsValid__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts,
    address makerTradingWallet,
    address takerTradingWallet
  ) private
    returns(bool)
  {
     
    if (msg.sender != orderBookAccount_) {
      return error("msg.sender != orderBookAccount, Exchange.__executeOrderInputIsValid__()");
    }

     
    if (block.number > amountsExpirationsAndSalts[4]) {
      return error("Maker order has expired, Exchange.__executeOrderInputIsValid__()");
    }

    if (block.number > amountsExpirationsAndSalts[6]) {
      return error("Taker order has expired, Exchange.__executeOrderInputIsValid__()");
    }

     
    if (makerTradingWallet == address(0)) {
      return error("Maker wallet does not exist, Exchange.__executeOrderInputIsValid__()");
    }

    if (takerTradingWallet == address(0)) {
      return error("Taker wallet does not exist, Exchange.__executeOrderInputIsValid__()");
    }

    if (quotePriority[ownedExternalAddressesAndTokenAddresses[1]] == quotePriority[ownedExternalAddressesAndTokenAddresses[3]]) {
      return error("Quote token is omitted! Is not offered by either the Taker or Maker, Exchange.__executeOrderInputIsValid__()");
    }

     
    if (
        amountsExpirationsAndSalts[0] == 0 ||
        amountsExpirationsAndSalts[1] == 0 ||
        amountsExpirationsAndSalts[2] == 0 ||
        amountsExpirationsAndSalts[3] == 0
      )
      return error("May not execute an order where token amount == 0, Exchange.__executeOrderInputIsValid__()");

     
     
     
     
     

     
     
     

    return true;
  }

   
  function __executeTokenTransfer__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256 toTakerAmount,
    uint256 toMakerAmount,
    uint256 fee,
    WalletV2 makerTradingWallet,
    WalletV2 takerTradingWallet
  ) private
    returns (bool)
  {
     
    address makerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[1];
    address takerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[3];

     
    if(fee != 0) {
      require(
        takerTradingWallet.updateBalance(edoToken_, fee, true),
        "Taker trading wallet cannot update balance with fee, Exchange.__executeTokenTransfer__()"
      );

      require(
        Token(edoToken_).transferFrom(takerTradingWallet, eidooWallet_, fee),
        "Cannot transfer fees from taker trading wallet to eidoo wallet, Exchange.__executeTokenTransfer__()"
      );
    }

     
    require(
      makerTradingWallet.updateBalance(makerOfferTokenAddress, toTakerAmount, true),
      "Maker trading wallet cannot update balance subtracting toTakerAmount, Exchange.__executeTokenTransfer__()"
    );  

     
    require(
      takerTradingWallet.updateBalance(makerOfferTokenAddress, toTakerAmount, false),
      "Taker trading wallet cannot update balance adding toTakerAmount, Exchange.__executeTokenTransfer__()"
    );  

     
    require(
      takerTradingWallet.updateBalance(takerOfferTokenAddress, toMakerAmount, true),
      "Taker trading wallet cannot update balance subtracting toMakerAmount, Exchange.__executeTokenTransfer__()"
    );  

     
    require(
      makerTradingWallet.updateBalance(takerOfferTokenAddress, toMakerAmount, false),
      "Maker trading wallet cannot update balance adding toMakerAmount, Exchange.__executeTokenTransfer__()"
    );  

     
    if (makerOfferTokenAddress == address(0)) {
      address(takerTradingWallet).transfer(toTakerAmount);
    } else {
      require(
        safeTransferFrom(makerOfferTokenAddress, makerTradingWallet, takerTradingWallet, toTakerAmount),
        "Token transfership from makerTradingWallet to takerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
      assert(
        __tokenAndWalletBalancesMatch__(
          makerTradingWallet,
          takerTradingWallet,
          makerOfferTokenAddress
        )
      );
    }

    if (takerOfferTokenAddress == address(0)) {
      address(makerTradingWallet).transfer(toMakerAmount);
    } else {
      require(
        safeTransferFrom(takerOfferTokenAddress, takerTradingWallet, makerTradingWallet, toMakerAmount),
        "Token transfership from takerTradingWallet to makerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
      assert(
        __tokenAndWalletBalancesMatch__(
          makerTradingWallet,
          takerTradingWallet,
          takerOfferTokenAddress
        )
      );
    }

    return true;
  }

   

  function generateOrderHashes(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts
  ) public
    view
    returns (bytes32[2])
  {
    bytes32 makerOrderHash = keccak256(
      address(this),
      ownedExternalAddressesAndTokenAddresses[0],  
      ownedExternalAddressesAndTokenAddresses[1],  
      amountsExpirationsAndSalts[0],   
      ownedExternalAddressesAndTokenAddresses[3],  
      amountsExpirationsAndSalts[1],   
      amountsExpirationsAndSalts[4],  
      amountsExpirationsAndSalts[5]  
    );

    bytes32 takerOrderHash = keccak256(
      address(this),
      ownedExternalAddressesAndTokenAddresses[2],  
      ownedExternalAddressesAndTokenAddresses[3],  
      amountsExpirationsAndSalts[2],   
      ownedExternalAddressesAndTokenAddresses[1],  
      amountsExpirationsAndSalts[3],   
      amountsExpirationsAndSalts[6],  
      amountsExpirationsAndSalts[7]  
    );

    return [makerOrderHash, takerOrderHash];
  }

   
  function __isSell__(Order _order) internal view returns (bool) {
    return quotePriority[_order.offerToken_] < quotePriority[_order.wantToken_];
  }

   
  function __getTradeAmounts__(
    Order makerOrder,
    Order takerOrder
  ) internal
    view
    returns (uint256[2])
  {
    bool isMakerBuy = __isSell__(takerOrder);   
    uint256 priceRatio;
    uint256 makerAmountLeftToReceive;
    uint256 takerAmountLeftToReceive;

    uint toTakerAmount;
    uint toMakerAmount;

    if (makerOrder.offerTokenTotal_ >= makerOrder.wantTokenTotal_) {
      priceRatio = makerOrder.offerTokenTotal_.mul(2**128).div(makerOrder.wantTokenTotal_);
      if (isMakerBuy) {
         
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
         
        toTakerAmount = toMakerAmount.mul(priceRatio).add(2**128-1).div(2**128);
      } else {
         
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
        toMakerAmount = toTakerAmount.mul(2**128).div(priceRatio);
      }
    } else {
      priceRatio = makerOrder.wantTokenTotal_.mul(2**128).div(makerOrder.offerTokenTotal_);
      if (isMakerBuy) {
         
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
        toTakerAmount = toMakerAmount.mul(2**128).div(priceRatio);
      } else {
         
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
         
        toMakerAmount = toTakerAmount.mul(priceRatio).add(2**128-1).div(2**128);
      }
    }
    return [toTakerAmount, toMakerAmount];
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

   
  function __ordersMatch_and_AreVaild__(
    Order makerOrder,
    Order takerOrder
  ) private
    returns (bool)
  {
     
     
    if (makerOrder.wantToken_ != takerOrder.offerToken_) {
      return error("Maker wanted token does not match taker offer token, Exchange.__ordersMatch_and_AreVaild__()");
    }

    if (makerOrder.offerToken_ != takerOrder.wantToken_) {
      return error("Maker offer token does not match taker wanted token, Exchange.__ordersMatch_and_AreVaild__()");
    }

     
     

    uint256 orderPrice;    
    uint256 offeredPrice;  

     
    if (makerOrder.offerTokenTotal_ >= makerOrder.wantTokenTotal_) {
      orderPrice = makerOrder.offerTokenTotal_.mul(2**128).div(makerOrder.wantTokenTotal_);
      offeredPrice = takerOrder.wantTokenTotal_.mul(2**128).div(takerOrder.offerTokenTotal_);

       
       
      if (orderPrice < offeredPrice) {
        return error("Taker price is greater than maker price, Exchange.__ordersMatch_and_AreVaild__()");
      }
    } else {
      orderPrice = makerOrder.wantTokenTotal_.mul(2**128).div(makerOrder.offerTokenTotal_);
      offeredPrice = takerOrder.offerTokenTotal_.mul(2**128).div(takerOrder.wantTokenTotal_);

       
       
      if (orderPrice > offeredPrice) {
        return error("Taker price is less than maker price, Exchange.__ordersMatch_and_AreVaild__()");
      }
    }

    return true;
  }

   
  function __ordersVerifiedByWallets__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256 toMakerAmount,
    uint256 toTakerAmount,
    WalletV2 makerTradingWallet,
    WalletV2 takerTradingWallet,
    uint256 fee
  ) private
    returns (bool)
  {
     
     
    if(!makerTradingWallet.verifyOrder(ownedExternalAddressesAndTokenAddresses[1], toTakerAmount, 0, 0)) {
      return error("Maker wallet could not verify the order, Exchange.____ordersVerifiedByWallets____()");
    }

    if(!takerTradingWallet.verifyOrder(ownedExternalAddressesAndTokenAddresses[3], toMakerAmount, fee, edoToken_)) {
      return error("Taker wallet could not verify the order, Exchange.____ordersVerifiedByWallets____()");
    }

    return true;
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
    if (Token(token).balanceOf(makerTradingWallet) != WalletV2(makerTradingWallet).balanceOf(token)) {
      return false;
    }

    if (Token(token).balanceOf(takerTradingWallet) != WalletV2(takerTradingWallet).balanceOf(token)) {
      return false;
    }

    return true;
  }

   
  function safeTransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  )
    public
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
}