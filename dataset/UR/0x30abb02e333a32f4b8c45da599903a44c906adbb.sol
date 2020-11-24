 

pragma solidity ^0.4.15;

 
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

 
contract Wallet is LoggingErrors {
   
   
  address public owner_;
  address public exchange_;
  mapping(address => uint256) public tokenBalances_;

  address public logic_;  
  uint256 public birthBlock_;

   
  WalletConnector private connector_ = WalletConnector(0x03d6e7b2f48120fd57a89ff0bbd56e9ec39af21c);

   
  event LogDeposit(address token, uint256 amount, uint256 balance);
  event LogWithdrawal(address token, uint256 amount, uint256 balance);

   
  function Wallet(address _owner) public {
    owner_ = _owner;
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
    constant
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


 
contract Exchange is LoggingErrors {

  using SafeMath for uint256;

   
  struct Order {
    bool active_;   
    address offerToken_;
    uint256 offerTokenTotal_;
    uint256 offerTokenRemaining_;   
    address wantToken_;
    uint256 wantTokenTotal_;
    uint256 wantTokenReceived_;   
  }

   
  address private orderBookAccount_;
  address private owner_;
  uint256 public minOrderEthAmount_;
  uint256 public birthBlock_;
  address public edoToken_;
  uint256 public edoPerWei_;
  uint256 public edoPerWeiDecimals_;
  address public eidooWallet_;
  mapping(bytes32 => Order) public orders_;  
  mapping(address => address) public userAccountToWallet_;  

   
  event LogEdoRateSet(uint256 rate);
  event LogOrderExecutionSuccess();
  event LogOrderFilled(bytes32 indexed orderId, uint256 fillAmount, uint256 fillRemaining);
  event LogUserAdded(address indexed user, address walletAddress);
  event LogWalletDeposit(address indexed walletAddress, address token, uint256 amount, uint256 balance);
  event LogWalletWithdrawal(address indexed walletAddress, address token, uint256 amount, uint256 balance);

   
  function Exchange(
    address _bookAccount,
    uint256 _minOrderEthAmount,
    address _edoToken,
    uint256 _edoPerWei,
    uint256 _edoPerWeiDecimals,
    address _eidooWallet
  ) public {
    orderBookAccount_ = _bookAccount;
    minOrderEthAmount_ = _minOrderEthAmount;
    owner_ = msg.sender;
    birthBlock_ = block.number;
    edoToken_ = _edoToken;
    edoPerWei_ = _edoPerWei;
    edoPerWeiDecimals_ = _edoPerWeiDecimals;
    eidooWallet_ = _eidooWallet;
  }

   
  function () external payable { }

   

   
  function addNewUser(address _userAccount)
    external
    returns (bool)
  {
    if (userAccountToWallet_[_userAccount] != address(0))
      return error('User already exists, Exchange.addNewUser()');

     
    address userWallet = new Wallet(_userAccount);

    userAccountToWallet_[_userAccount] = userWallet;

    LogUserAdded(_userAccount, userWallet);

    return true;
  }

   
  function batchExecuteOrder(
    address[4][] _token_and_EOA_Addresses,
    uint256[8][] _amountsExpirationAndSalt,  
    uint8[2][] _sig_v,
    bytes32[4][] _sig_r_and_s
  ) external
    returns(bool)
  {
    for (uint256 i = 0; i < _amountsExpirationAndSalt.length; i++) {
      require(executeOrder(
        _token_and_EOA_Addresses[i],
        _amountsExpirationAndSalt[i],
        _sig_v[i],
        _sig_r_and_s[i]
      ));
    }

    return true;
  }

   
  function executeOrder (
    address[4] _token_and_EOA_Addresses,
    uint256[8] _amountsExpirationAndSalt,  
    uint8[2] _sig_v,
    bytes32[4] _sig_r_and_s
  ) public
    returns(bool)
  {
     
     
    Wallet[2] memory wallets = [
      Wallet(userAccountToWallet_[_token_and_EOA_Addresses[0]]),  
      Wallet(userAccountToWallet_[_token_and_EOA_Addresses[2]])  
    ];

     
    if(!__executeOrderInputIsValid__(
      _token_and_EOA_Addresses,
      _amountsExpirationAndSalt,
      wallets[0],
      wallets[1]
    ))
      return error('Input is invalid, Exchange.executeOrder()');

     
    bytes32 makerOrderHash;
    bytes32 takerOrderHash;
    (makerOrderHash, takerOrderHash) = __generateOrderHashes__(_token_and_EOA_Addresses, _amountsExpirationAndSalt);

    if (!__signatureIsValid__(
      _token_and_EOA_Addresses[0],
      makerOrderHash,
      _sig_v[0],
      _sig_r_and_s[0],
      _sig_r_and_s[1]
    ))
      return error('Maker signature is invalid, Exchange.executeOrder()');

    if (!__signatureIsValid__(
      _token_and_EOA_Addresses[2],
      takerOrderHash,
      _sig_v[1],
      _sig_r_and_s[2],
      _sig_r_and_s[3]
    ))
      return error('Taker signature is invalid, Exchange.executeOrder()');

     
    Order memory makerOrder = orders_[makerOrderHash];
    Order memory takerOrder = orders_[takerOrderHash];

    if (makerOrder.wantTokenTotal_ == 0) {   
      makerOrder.active_ = true;
      makerOrder.offerToken_ = _token_and_EOA_Addresses[1];
      makerOrder.offerTokenTotal_ = _amountsExpirationAndSalt[0];
      makerOrder.offerTokenRemaining_ = _amountsExpirationAndSalt[0];  
      makerOrder.wantToken_ = _token_and_EOA_Addresses[3];
      makerOrder.wantTokenTotal_ = _amountsExpirationAndSalt[1];
      makerOrder.wantTokenReceived_ = 0;  
    }

    if (takerOrder.wantTokenTotal_ == 0) {   
      takerOrder.active_ = true;
      takerOrder.offerToken_ = _token_and_EOA_Addresses[3];
      takerOrder.offerTokenTotal_ = _amountsExpirationAndSalt[2];
      takerOrder.offerTokenRemaining_ = _amountsExpirationAndSalt[2];   
      takerOrder.wantToken_ = _token_and_EOA_Addresses[1];
      takerOrder.wantTokenTotal_ = _amountsExpirationAndSalt[3];
      takerOrder.wantTokenReceived_ = 0;  
    }

    if (!__ordersMatch_and_AreVaild__(makerOrder, takerOrder))
      return error('Orders do not match, Exchange.executeOrder()');

     
    uint256 toTakerAmount;
    uint256 toMakerAmount;
    (toTakerAmount, toMakerAmount) = __getTradeAmounts__(makerOrder, takerOrder);

     
    if (toTakerAmount < 1 || toMakerAmount < 1)
      return error('Token amount < 1, price ratio is invalid! Token value < 1, Exchange.executeOrder()');

     
    if (
        takerOrder.offerToken_ == edoToken_ &&
        Token(edoToken_).balanceOf(wallets[1]) < __calculateFee__(makerOrder, toTakerAmount, toMakerAmount).add(toMakerAmount)
      ) {
        return error('Taker has an insufficient EDO token balance to cover the fee AND the offer, Exchange.executeOrder()');
     
    } else if (Token(edoToken_).balanceOf(wallets[1]) < __calculateFee__(makerOrder, toTakerAmount, toMakerAmount))
      return error('Taker has an insufficient EDO token balance to cover the fee, Exchange.executeOrder()');

     
    if (!__ordersVerifiedByWallets__(
        _token_and_EOA_Addresses,
        toMakerAmount,
        toTakerAmount,
        wallets[0],
        wallets[1],
        __calculateFee__(makerOrder, toTakerAmount, toMakerAmount)
      ))
      return error('Order could not be verified by wallets, Exchange.executeOrder()');

     
     
    __updateOrders__(makerOrder, takerOrder, toTakerAmount, toMakerAmount);

     
     
    if (makerOrder.offerTokenRemaining_ == 0)
      makerOrder.active_ = false;

    if (takerOrder.offerTokenRemaining_ == 0)
      takerOrder.active_ = false;

     
    orders_[makerOrderHash] = makerOrder;
    orders_[takerOrderHash] = takerOrder;

     
    require(
      __executeTokenTransfer__(
        _token_and_EOA_Addresses,
        toTakerAmount,
        toMakerAmount,
        __calculateFee__(makerOrder, toTakerAmount, toMakerAmount),
        wallets[0],
        wallets[1]
      )
    );

     
    LogOrderFilled(makerOrderHash, toTakerAmount, makerOrder.offerTokenRemaining_);
    LogOrderFilled(takerOrderHash, toMakerAmount, takerOrder.offerTokenRemaining_);

    LogOrderExecutionSuccess();

    return true;
  }

   
  function setEdoRate(
    uint256 _edoPerWei
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, Exchange.setEdoRate()');

    edoPerWei_ = _edoPerWei;

    LogEdoRateSet(edoPerWei_);

    return true;
  }

   
  function setEidooWallet(
    address _eidooWallet
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, Exchange.setEidooWallet()');

    eidooWallet_ = _eidooWallet;

    return true;
  }

   
  function setMinOrderEthAmount (
    uint256 _minOrderEthAmount
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, Exchange.setMinOrderEtherAmount()');

    minOrderEthAmount_ = _minOrderEthAmount;

    return true;
  }

   
  function setOrderBookAcount (
    address _account
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, Exchange.setOrderBookAcount()');

    orderBookAccount_ = _account;
    return true;
  }

   

   
  function walletDeposit(
    address _token,
    uint256 _amount,
    uint256 _walletBalance
  ) external
  {
    LogWalletDeposit(msg.sender, _token, _amount, _walletBalance);
  }

   
  function walletWithdrawal(
    address _token,
    uint256 _amount,
    uint256 _walletBalance
  ) external
  {
    LogWalletWithdrawal(msg.sender, _token, _amount, _walletBalance);
  }

   

   
  function __calculateFee__(
    Order _makerOrder,
    uint256 _toTaker,
    uint256 _toMaker
  ) private
    constant
    returns(uint256)
  {
     
    if (_makerOrder.offerToken_ == address(0)) {
      return _toTaker.mul(edoPerWei_).div(10**edoPerWeiDecimals_);
    } else {
      return _toMaker.mul(edoPerWei_).div(10**edoPerWeiDecimals_);
    }
  }

   
  function __executeOrderInputIsValid__(
    address[4] _token_and_EOA_Addresses,
    uint256[8] _amountsExpirationAndSalt,
    address _makerWallet,
    address _takerWallet
  ) private
    constant
    returns(bool)
  {
    if (msg.sender != orderBookAccount_)
      return error('msg.sender != orderBookAccount, Exchange.__executeOrderInputIsValid__()');

    if (block.number > _amountsExpirationAndSalt[4])
      return error('Maker order has expired, Exchange.__executeOrderInputIsValid__()');

    if (block.number > _amountsExpirationAndSalt[6])
      return error('Taker order has expired, Exchange.__executeOrderInputIsValid__()');

     
    if (_makerWallet == address(0))
      return error('Maker wallet does not exist, Exchange.__executeOrderInputIsValid__()');

    if (_takerWallet == address(0))
      return error('Taker wallet does not exist, Exchange.__executeOrderInputIsValid__()');

     
    if (_token_and_EOA_Addresses[1] != address(0) && _token_and_EOA_Addresses[3] != address(0))
      return error('Ether omitted! Is not offered by either the Taker or Maker, Exchange.__executeOrderInputIsValid__()');

    if (_token_and_EOA_Addresses[1] == address(0) && _token_and_EOA_Addresses[3] == address(0))
      return error('Taker and Maker offer token are both ether, Exchange.__executeOrderInputIsValid__()');

    if (
        _amountsExpirationAndSalt[0] == 0 ||
        _amountsExpirationAndSalt[1] == 0 ||
        _amountsExpirationAndSalt[2] == 0 ||
        _amountsExpirationAndSalt[3] == 0
      )
      return error('May not execute an order where token amount == 0, Exchange.__executeOrderInputIsValid__()');

     
     
    uint256 minOrderEthAmount = minOrderEthAmount_;  
    if (_token_and_EOA_Addresses[1] == 0 && _amountsExpirationAndSalt[0] < minOrderEthAmount)
      return error('Maker order does not meet the minOrderEthAmount_ of ether, Exchange.__executeOrderInputIsValid__()');

     
    if (_token_and_EOA_Addresses[3] == 0 && _amountsExpirationAndSalt[2] < minOrderEthAmount)
      return error('Taker order does not meet the minOrderEthAmount_ of ether, Exchange.__executeOrderInputIsValid__()');

    return true;
  }

   
  function __executeTokenTransfer__(
    address[4] _token_and_EOA_Addresses,
    uint256 _toTakerAmount,
    uint256 _toMakerAmount,
    uint256 _fee,
    Wallet _makerWallet,
    Wallet _takerWallet
  ) private
    returns (bool)
  {
     
    address makerOfferToken = _token_and_EOA_Addresses[1];
    address takerOfferToken = _token_and_EOA_Addresses[3];

     
    require(_takerWallet.updateBalance(edoToken_, _fee, true));   
    require(Token(edoToken_).transferFrom(_takerWallet, eidooWallet_, _fee));

     
    require(_makerWallet.updateBalance(makerOfferToken, _toTakerAmount, true));   
       

    require(_takerWallet.updateBalance(makerOfferToken, _toTakerAmount, false));
       

     
    require(_takerWallet.updateBalance(takerOfferToken, _toMakerAmount, true));   
       

    require(_makerWallet.updateBalance(takerOfferToken, _toMakerAmount, false));
       

     
     
    if (makerOfferToken == address(0)) {
      _takerWallet.transfer(_toTakerAmount);
      require(
        Token(takerOfferToken).transferFrom(_takerWallet, _makerWallet, _toMakerAmount)
      );
      assert(
        __tokenAndWalletBalancesMatch__(_makerWallet, _takerWallet, takerOfferToken)
      );

     
    } else if (takerOfferToken == address(0)) {
      _makerWallet.transfer(_toMakerAmount);
      require(
        Token(makerOfferToken).transferFrom(_makerWallet, _takerWallet, _toTakerAmount)
      );
      assert(
        __tokenAndWalletBalancesMatch__(_makerWallet, _takerWallet, makerOfferToken)
      );

     
    } else revert();

    return true;
  }

   
  function __flooredLog10__(uint _number)
    public
    constant
    returns (uint256)
  {
    uint unit = 0;
    while (_number / (10**unit) >= 10)
      unit++;
    return unit;
  }

   
  function __generateOrderHashes__(
    address[4] _token_and_EOA_Addresses,
    uint256[8] _amountsExpirationAndSalt
  ) private
    constant
    returns (bytes32, bytes32)
  {
    bytes32 makerOrderHash = keccak256(
      address(this),
      _token_and_EOA_Addresses[0],  
      _token_and_EOA_Addresses[1],  
      _amountsExpirationAndSalt[0],   
      _token_and_EOA_Addresses[3],  
      _amountsExpirationAndSalt[1],   
      _amountsExpirationAndSalt[4],  
      _amountsExpirationAndSalt[5]  
    );


    bytes32 takerOrderHash = keccak256(
      address(this),
      _token_and_EOA_Addresses[2],  
      _token_and_EOA_Addresses[3],  
      _amountsExpirationAndSalt[2],   
      _token_and_EOA_Addresses[1],  
      _amountsExpirationAndSalt[3],   
      _amountsExpirationAndSalt[6],  
      _amountsExpirationAndSalt[7]  
    );

    return (makerOrderHash, takerOrderHash);
  }

   
  function __getOrderPriceRatio__(Order _makerOrder, uint256 _decimals)
    private
    constant
    returns (uint256 orderPriceRatio)
  {
    if (_makerOrder.offerTokenTotal_ >= _makerOrder.wantTokenTotal_) {
      orderPriceRatio = _makerOrder.offerTokenTotal_.mul(10**_decimals).div(_makerOrder.wantTokenTotal_);
    } else {
      orderPriceRatio = _makerOrder.wantTokenTotal_.mul(10**_decimals).div(_makerOrder.offerTokenTotal_);
    }
  }

   
  function __getTradeAmounts__(
    Order _makerOrder,
    Order _takerOrder
  ) private
    constant
    returns (uint256 toTakerAmount, uint256 toMakerAmount)
  {
    bool ratioIsWeiPerTok = __ratioIsWeiPerTok__(_makerOrder);
    uint256 decimals = __flooredLog10__(__max__(_makerOrder.offerTokenTotal_, _makerOrder.wantTokenTotal_)) + 1;
    uint256 priceRatio = __getOrderPriceRatio__(_makerOrder, decimals);

     
    uint256 makerAmountLeftToReceive = _makerOrder.wantTokenTotal_.sub(_makerOrder.wantTokenReceived_);
    uint256 takerAmountLeftToReceive = _takerOrder.wantTokenTotal_.sub(_takerOrder.wantTokenReceived_);

     
    if (
        ratioIsWeiPerTok && _takerOrder.wantToken_ == address(0) ||
        !ratioIsWeiPerTok && _takerOrder.wantToken_ != address(0)
    ) {
       
       
       
      if (
        _makerOrder.offerTokenRemaining_ > takerAmountLeftToReceive &&
        makerAmountLeftToReceive <= _takerOrder.offerTokenRemaining_
      ) {
        toTakerAmount = __max__(_makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
      } else {
        toTakerAmount = __min__(_makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
      }

      toMakerAmount = toTakerAmount.mul(10**decimals).div(priceRatio);

     
    } else {
      toMakerAmount = __min__(_takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
      toTakerAmount = toMakerAmount.mul(10**decimals).div(priceRatio);
    }
  }

   
  function __max__(uint256 _a, uint256 _b)
    private
    constant
    returns (uint256)
  {
    return _a < _b ? _b : _a;
  }

   
  function __min__(uint256 _a, uint256 _b)
    private
    constant
    returns (uint256)
  {
    return _a < _b ? _a : _b;
  }

   
  function __ratioIsWeiPerTok__(Order _makerOrder)
    private
    constant
    returns (bool)
  {
    bool offerIsWei = _makerOrder.offerToken_ == address(0) ? true : false;

     
    if (offerIsWei && _makerOrder.offerTokenTotal_ >= _makerOrder.wantTokenTotal_) {
      return true;

    } else if (!offerIsWei && _makerOrder.wantTokenTotal_ >= _makerOrder.offerTokenTotal_) {
      return true;

     
    } else {
      return false;
    }
  }

   
  function __ordersMatch_and_AreVaild__(
    Order _makerOrder,
    Order _takerOrder
  ) private
    constant
    returns (bool)
  {
     
    if (!_makerOrder.active_)
      return error('Maker order is inactive, Exchange.__ordersMatch_and_AreVaild__()');

    if (!_takerOrder.active_)
      return error('Taker order is inactive, Exchange.__ordersMatch_and_AreVaild__()');

     
     
    if (_makerOrder.wantToken_ != _takerOrder.offerToken_)
      return error('Maker wanted token does not match taker offer token, Exchange.__ordersMatch_and_AreVaild__()');

    if (_makerOrder.offerToken_ != _takerOrder.wantToken_)
      return error('Maker offer token does not match taker wanted token, Exchange.__ordersMatch_and_AreVaild__()');

     
     
    uint256 orderPrice;   
    uint256 offeredPrice;  
    uint256 decimals = _makerOrder.offerToken_ == address(0) ? __flooredLog10__(_makerOrder.wantTokenTotal_) : __flooredLog10__(_makerOrder.offerTokenTotal_);

     
    if (_makerOrder.offerTokenTotal_ >= _makerOrder.wantTokenTotal_) {
      orderPrice = _makerOrder.offerTokenTotal_.mul(10**decimals).div(_makerOrder.wantTokenTotal_);
      offeredPrice = _takerOrder.wantTokenTotal_.mul(10**decimals).div(_takerOrder.offerTokenTotal_);

       
       
      if (orderPrice < offeredPrice)
        return error('Taker price is greater than maker price, Exchange.__ordersMatch_and_AreVaild__()');

    } else {
      orderPrice = _makerOrder.wantTokenTotal_.mul(10**decimals).div(_makerOrder.offerTokenTotal_);
      offeredPrice = _takerOrder.offerTokenTotal_.mul(10**decimals).div(_takerOrder.wantTokenTotal_);

       
       
      if (orderPrice > offeredPrice)
        return error('Taker price is less than maker price, Exchange.__ordersMatch_and_AreVaild__()');

    }

    return true;
  }

   
  function __ordersVerifiedByWallets__(
    address[4] _token_and_EOA_Addresses,
    uint256 _toMakerAmount,
    uint256 _toTakerAmount,
    Wallet _makerWallet,
    Wallet _takerWallet,
    uint256 _fee
  ) private
    constant
    returns (bool)
  {
     
     
    if(!_makerWallet.verifyOrder(_token_and_EOA_Addresses[1], _toTakerAmount, 0, 0))
      return error('Maker wallet could not verify the order, Exchange.__ordersVerifiedByWallets__()');

    if(!_takerWallet.verifyOrder(_token_and_EOA_Addresses[3], _toMakerAmount, _fee, edoToken_))
      return error('Taker wallet could not verify the order, Exchange.__ordersVerifiedByWallets__()');

    return true;
  }

   
  function __signatureIsValid__(
    address _signer,
    bytes32 _orderHash,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) private
    constant
    returns (bool)
  {
    address recoveredAddr = ecrecover(
      keccak256('\x19Ethereum Signed Message:\n32', _orderHash),
      _v, _r, _s
    );

    return recoveredAddr == _signer;
  }

   
  function __tokenAndWalletBalancesMatch__(
    address _makerWallet,
    address _takerWallet,
    address _token
  ) private
    constant
    returns(bool)
  {
    if (Token(_token).balanceOf(_makerWallet) != Wallet(_makerWallet).balanceOf(_token))
      return false;

    if (Token(_token).balanceOf(_takerWallet) != Wallet(_takerWallet).balanceOf(_token))
      return false;

    return true;
  }

   
  function __updateOrders__(
    Order _makerOrder,
    Order _takerOrder,
    uint256 _toTakerAmount,
    uint256 _toMakerAmount
  ) private
  {
     
    _makerOrder.wantTokenReceived_ = _makerOrder.wantTokenReceived_.add(_toMakerAmount);
    _takerOrder.offerTokenRemaining_ = _takerOrder.offerTokenRemaining_.sub(_toMakerAmount);

     
    _takerOrder.wantTokenReceived_ = _takerOrder.wantTokenReceived_.add(_toTakerAmount);
    _makerOrder.offerTokenRemaining_ = _makerOrder.offerTokenRemaining_.sub(_toTakerAmount);
  }
}