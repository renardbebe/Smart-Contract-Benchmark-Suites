 

pragma solidity ^0.4.22;



 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
contract MultiOwnable is Ownable {

  struct Types {
    mapping (address => bool) access;
  }
  mapping (uint => Types) private multiOwnersTypes;

  event AddOwner(uint _type, address addr);
  event AddOwner(uint[] types, address addr);
  event RemoveOwner(uint _type, address addr);

  modifier onlyMultiOwnersType(uint _type) {
    require(multiOwnersTypes[_type].access[msg.sender] || msg.sender == owner, "403");
    _;
  }

  function onlyMultiOwnerType(uint _type, address _sender) public view returns(bool) {
    if (multiOwnersTypes[_type].access[_sender] || _sender == owner) {
      return true;
    }
    return false;
  }

  function addMultiOwnerType(uint _type, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    multiOwnersTypes[_type].access[_owner] = true;
    emit AddOwner(_type, _owner);
    return true;
  }
  
  function addMultiOwnerTypes(uint[] types, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    require(types.length > 0);
    for (uint i = 0; i < types.length; i++) {
      multiOwnersTypes[types[i]].access[_owner] = true;
    }
    emit AddOwner(types, _owner);
    return true;
  }

  function removeMultiOwnerType(uint types, address _owner) public onlyOwner returns(bool) {
    require(_owner != address(0));
    multiOwnersTypes[types].access[_owner] = false;
    emit RemoveOwner(types, _owner);
    return true;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract IBonus {
  function getCurrentDayBonus(uint startSaleDate, bool saleState) public view returns(uint);
  function _currentDay(uint startSaleDate, bool saleState) public view returns(uint);
  function getBonusData() public view returns(string);
  function getPreSaleBonusPercent() public view returns(uint);
  function getMinReachUsdPayInCents() public view returns(uint);
}

contract ICurrency {
  function getUsdAbsRaisedInCents() external view returns(uint);
  function getCoinRaisedBonusInWei() external view returns(uint);
  function getCoinRaisedInWei() public view returns(uint);
  function getUsdFromETH(uint ethWei) public view returns(uint);
  function getTokenFromETH(uint ethWei) public view returns(uint);
  function getCurrencyRate(string _ticker) public view returns(uint);
  function addPay(string _ticker, uint value, uint usdAmount, uint coinRaised, uint coinRaisedBonus) public returns(bool);
  function checkTickerExists(string ticker) public view returns(bool);
  function getUsdFromCurrency(string ticker, uint value) public view returns(uint);
  function getUsdFromCurrency(string ticker, uint value, uint usd) public view returns(uint);
  function getUsdFromCurrency(bytes32 ticker, uint value) public view returns(uint);
  function getUsdFromCurrency(bytes32 ticker, uint value, uint usd) public view returns(uint);
  function getTokenWeiFromUSD(uint usdCents) public view returns(uint);
  function editPay(bytes32 ticker, uint currencyValue, uint currencyUsdRaised, uint _usdAbsRaisedInCents, uint _coinRaisedInWei, uint _coinRaisedBonusInWei) public returns(bool);
  function getCurrencyList(string ticker) public view returns(bool active, uint usd, uint devision, uint raised, uint usdRaised, uint usdRaisedExchangeRate, uint counter, uint lastUpdate);
  function getCurrencyList(bytes32 ticker) public view returns(bool active, uint usd, uint devision, uint raised, uint usdRaised, uint usdRaisedExchangeRate, uint counter, uint lastUpdate);
  function getTotalUsdRaisedInCents() public view returns(uint);
  function getAllCurrencyTicker() public view returns(string);
  function getCoinUSDRate() public view  returns(uint);
  function addPreSaleBonus(uint bonusToken) public returns(bool);
  function editPreSaleBonus(uint beforeBonus, uint afterBonus) public returns(bool);
}

contract IStorage {
  function processPreSaleBonus(uint minTotalUsdAmountInCents, uint bonusPercent, uint _start, uint _limit) external returns(uint);
  function checkNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents) external view returns(bool);
  function getCountNeedProcessPreSaleBonus(uint minTotalUsdAmountInCents, uint start, uint limit) external view returns(uint);
  function reCountUserPreSaleBonus(uint uId, uint minTotalUsdAmountInCents, uint bonusPercent, uint maxPayTime) external returns(uint, uint);
  function getContributorIndexes(uint index) external view returns(uint);
  function checkNeedSendSHPC(bool proc) external view returns(bool);
  function getCountNeedSendSHPC(uint start, uint limit) external view returns(uint);
  function checkETHRefund(bool proc) external view returns(bool);
  function getCountETHRefund(uint start, uint limit) external view returns(uint);
  function addPayment(address _addr, string pType, uint _value, uint usdAmount, uint currencyUSD, uint tokenWithoutBonus, uint tokenBonus, uint bonusPercent, uint payId) public returns(bool);
  function addPayment(uint uId, string pType, uint _value, uint usdAmount, uint currencyUSD, uint tokenWithoutBonus, uint tokenBonus, uint bonusPercent, uint payId) public returns(bool);
  function checkUserIdExists(uint uId) public view returns(bool);
  function getContributorAddressById(uint uId) public view returns(address);
  function editPaymentByUserId(uint uId, uint payId, uint _payValue, uint _usdAmount, uint _currencyUSD, uint _totalToken, uint _tokenWithoutBonus, uint _tokenBonus, uint _bonusPercent) public returns(bool);
  function getUserPaymentById(uint uId, uint payId) public view returns(uint time, bytes32 pType, uint currencyUSD, uint bonusPercent, uint payValue, uint totalToken, uint tokenBonus, uint tokenWithoutBonus, uint usdAbsRaisedInCents, bool refund);
  function checkWalletExists(address addr) public view returns(bool result);
  function checkReceivedCoins(address addr) public view returns(bool);
  function getContributorId(address addr) public view returns(uint);
  function getTotalCoin(address addr) public view returns(uint);
  function setReceivedCoin(uint uId) public returns(bool);
  function checkPreSaleReceivedBonus(address addr) public view returns(bool);
  function checkRefund(address addr) public view returns(bool);
  function setRefund(uint uId) public returns(bool);
  function getEthPaymentContributor(address addr) public view returns(uint);
  function refundPaymentByUserId(uint uId, uint payId) public returns(bool);
  function changeSupportChangeMainWallet(bool support) public returns(bool);
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ShipCoinCrowdsale is MultiOwnable {
  using SafeMath for uint256;

  ERC20Basic public coinContract;
  IStorage public storageContract;
  ICurrency public currencyContract;
  IBonus public bonusContract;

  enum SaleState {NEW, PRESALE, CALCPSBONUS, SALE, END, REFUND}
  uint256 private constant ONE_DAY = 86400;

  SaleState public state;

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  uint public softCapUSD = 500000000;  
   
  uint public hardCapUSD = 6200000000;  
   
  uint public maxDistributeCoin = 600000000 * 1 ether;  
   
  uint public minimalContributionUSD = 100000;  

   
  uint public startPreSaleDate;
  uint public endPreSaleDate;

  uint public unfreezeRefundPreSale;
  uint public unfreezeRefundAll;

   
  uint public startSaleDate;
  uint public endSaleDate;

  bool public softCapAchieved = false;

  address public multiSig1;
  address public multiSig2;

  bool public multiSigReceivedSoftCap = false;


   
  event ChangeState(uint blockNumber, SaleState state);
  event ChangeMinContribUSD(uint oldAmount, uint newAmount);
  event ChangeStorageContract(address oldAddress, address newAddress);
  event ChangeCurrencyContract(address oldAddress, address newAddress);
  event ChangeCoinContract(address oldAddress, address newAddress);
  event ChangeBonusContract(address oldAddress, address newAddress);
  event AddPay(address contributor);
  event EditPay(address contributor);
  event SoftCapAchieved(uint amount);
  event ManualChangeStartPreSaleDate(uint oldDate, uint newDate);
  event ManualChangeEndPreSaleDate(uint oldDate, uint newDate);
  event ManualChangeStartSaleDate(uint oldDate, uint newDate);
  event ManualEndSaleDate(uint oldDate, uint newDate);
  event SendSHPCtoContributor(address contributor);
  event SoftCapChanged();
  event Refund(address contributor);
  event RefundPay(address contributor);

  struct PaymentInfo {
    bytes32 pType;
    uint currencyUSD;
    uint bonusPercent;
    uint payValue;
    uint totalToken;
    uint tokenBonus;
    uint usdAbsRaisedInCents;
    bool refund;
  }

  struct CurrencyInfo {
    uint value;
    uint usdRaised;
    uint usdAbsRaisedInCents;
    uint coinRaisedInWei;
    uint coinRaisedBonusInWei;
  }

  struct EditPaymentInfo {
    uint usdAmount;
    uint currencyUSD;
    uint bonusPercent;
    uint totalToken;
    uint tokenWithoutBonus;
    uint tokenBonus;
    CurrencyInfo currency;
  }

  function () external whenNotPaused payable {
    buyTokens(msg.sender);
  }

   
  function init(
    address _coinAddress,
    address _storageContract,
    address _currencyContract,
    address _bonusContract,
    address _multiSig1,
    uint _startPreSaleDate,
    uint _endPreSaleDate,
    uint _startSaleDate,
    uint _endSaleDate
  )
  public
  onlyOwner
  {
    require(_coinAddress != address(0));
    require(_storageContract != address(0));
    require(_currencyContract != address(0));
    require(_multiSig1 != address(0));
    require(_bonusContract != address(0));
    require(_startPreSaleDate > 0 && _startSaleDate > 0);
    require(_startSaleDate > _endPreSaleDate);
    require(_endSaleDate > _startSaleDate);
    require(startSaleDate == 0);

    coinContract = ERC20Basic(_coinAddress);
    storageContract = IStorage(_storageContract);
    currencyContract = ICurrency(_currencyContract);
    bonusContract = IBonus(_bonusContract);

    multiSig1 = _multiSig1;
    multiSig2 = 0x231121dFCB61C929BCdc0D1E6fC760c84e9A02ad;

    startPreSaleDate = _startPreSaleDate;
    endPreSaleDate = _endPreSaleDate;
    startSaleDate = _startSaleDate;
    endSaleDate = _endSaleDate;

    unfreezeRefundPreSale = _endSaleDate;
    unfreezeRefundAll = _endSaleDate.add(ONE_DAY);

    state = SaleState.NEW;
  }

   
  function pause() public onlyOwner {
    paused = true;
  }

   
  function unpause() public onlyOwner {
    paused = false;
  }

   
  function setMinimalContributionUSD(uint minContribUsd) public onlyOwner {
    require(minContribUsd > 100);  
    uint oldMinAmount = minimalContributionUSD;
    minimalContributionUSD = minContribUsd;
    emit ChangeMinContribUSD(oldMinAmount, minimalContributionUSD);
  }

   
  function setUnfreezeRefund(uint _time) public onlyOwner {
    require(_time > startSaleDate);
    unfreezeRefundPreSale = _time;
    unfreezeRefundAll = _time.add(ONE_DAY);
  }

   
  function setStorageContract(address _storageContract) public onlyOwner {
    require(_storageContract != address(0));
    address oldStorageContract = storageContract;
    storageContract = IStorage(_storageContract);
    emit ChangeStorageContract(oldStorageContract, storageContract);
  }

   
  function setCoinContract(address _coinContract) public onlyOwner {
    require(_coinContract != address(0));
    address oldCoinContract = coinContract;
    coinContract = ERC20Basic(_coinContract);
    emit ChangeCoinContract(oldCoinContract, coinContract);
  }

   
  function setCurrencyContract(address _currencyContract) public onlyOwner {
    require(_currencyContract != address(0));
    address oldCurContract = currencyContract;
    currencyContract = ICurrency(_currencyContract);
    emit ChangeCurrencyContract(oldCurContract, currencyContract);
  }

   
  function setBonusContract(address _bonusContract) public onlyOwner {
    require(_bonusContract != address(0));
    address oldContract = _bonusContract;
    bonusContract = IBonus(_bonusContract);
    emit ChangeBonusContract(oldContract, bonusContract);
  }

   
  function setMultisig(address _address) public onlyOwner {
    require(_address != address(0));
    multiSig1 = _address;
  }

   
  function setSoftCap(uint _softCapUsdInCents) public onlyOwner {
    require(_softCapUsdInCents > 100000);
    softCapUSD = _softCapUsdInCents;
    emit SoftCapChanged();
  }

   
  function changeMaxDistributeCoin(uint _maxCoin) public onlyOwner {
    require(_maxCoin > 0 && _maxCoin >= currencyContract.getCoinRaisedInWei());
    maxDistributeCoin = _maxCoin;
  }

   
  function startPreSale() public onlyMultiOwnersType(1) {
    require(block.timestamp <= endPreSaleDate);
    require(state == SaleState.NEW);

    state = SaleState.PRESALE;
    emit ChangeState(block.number, state);
  }

   
  function startCalculatePreSaleBonus() public onlyMultiOwnersType(5) {
    require(state == SaleState.PRESALE);

    state = SaleState.CALCPSBONUS;
    emit ChangeState(block.number, state);
  }

   
  function startSale() public onlyMultiOwnersType(2) {
    require(block.timestamp <= endSaleDate);
    require(state == SaleState.CALCPSBONUS);
     

    state = SaleState.SALE;
    emit ChangeState(block.number, state);
  }

   
  function saleSetEnded() public onlyMultiOwnersType(3) {
    require((state == SaleState.SALE) || (state == SaleState.PRESALE));
    require(block.timestamp >= startSaleDate);
    require(checkSoftCapAchieved());
    state = SaleState.END;
    storageContract.changeSupportChangeMainWallet(false);
    emit ChangeState(block.number, state);
  }

   
  function saleSetRefund() public onlyMultiOwnersType(4) {
    require((state == SaleState.SALE) || (state == SaleState.PRESALE));
    require(block.timestamp >= endSaleDate);
    require(!checkSoftCapAchieved());
    state = SaleState.REFUND;
    emit ChangeState(block.number, state);
  }

   
  function buyTokens(address _beneficiary) public whenNotPaused payable {
    require((state == SaleState.PRESALE && block.timestamp >= startPreSaleDate && block.timestamp <= endPreSaleDate) || (state == SaleState.SALE && block.timestamp >= startSaleDate && block.timestamp <= endSaleDate));
    require(_beneficiary != address(0));
    require(msg.value > 0);
    uint usdAmount = currencyContract.getUsdFromETH(msg.value);

    assert(usdAmount >= minimalContributionUSD);

    uint bonusPercent = 0;

    if (state == SaleState.SALE) {
      bonusPercent = bonusContract.getCurrentDayBonus(startSaleDate, (state == SaleState.SALE));
    }

    (uint totalToken, uint tokenWithoutBonus, uint tokenBonus) = calcToken(usdAmount, bonusPercent);

    assert((totalToken > 0 && totalToken <= calculateMaxCoinIssued()));

    uint usdRate = currencyContract.getCurrencyRate("ETH");

    assert(storageContract.addPayment(_beneficiary, "ETH", msg.value, usdAmount, usdRate, tokenWithoutBonus, tokenBonus, bonusPercent, 0));
    assert(currencyContract.addPay("ETH", msg.value, usdAmount, totalToken, tokenBonus));

    emit AddPay(_beneficiary);
  }

   
  function addPay(string ticker, uint value, uint uId, uint _pId, uint _currencyUSD) public onlyMultiOwnersType(6) {
    require(value > 0);
    require(storageContract.checkUserIdExists(uId));
    require(_pId > 0);

    string memory _ticker = ticker;
    uint _value = value;
    assert(currencyContract.checkTickerExists(_ticker));
    uint usdAmount = currencyContract.getUsdFromCurrency(_ticker, _value, _currencyUSD);

    assert(usdAmount > 0);

    uint bonusPercent = 0;

    if (state == SaleState.SALE) {
      bonusPercent = bonusContract.getCurrentDayBonus(startSaleDate, (state == SaleState.SALE));
    }

    (uint totalToken, uint tokenWithoutBonus, uint tokenBonus) = calcToken(usdAmount, bonusPercent);

    assert(tokenWithoutBonus > 0);

    uint usdRate = _currencyUSD > 0 ? _currencyUSD : currencyContract.getCurrencyRate(_ticker);

    uint pId = _pId;

    assert(storageContract.addPayment(uId, _ticker, _value, usdAmount, usdRate, tokenWithoutBonus, tokenBonus, bonusPercent, pId));
    assert(currencyContract.addPay(_ticker, _value, usdAmount, totalToken, tokenBonus));

    emit AddPay(storageContract.getContributorAddressById(uId));
  }

   
  function editPay(uint uId, uint payId, uint value, uint _currencyUSD, uint _bonusPercent) public onlyMultiOwnersType(7) {
    require(value > 0);
    require(storageContract.checkUserIdExists(uId));
    require(payId > 0);
    require((_bonusPercent == 0 || _bonusPercent <= getPreSaleBonusPercent()));

    PaymentInfo memory payment = getPaymentInfo(uId, payId);
    EditPaymentInfo memory paymentInfo = calcEditPaymentInfo(payment, value, _currencyUSD, _bonusPercent);

    assert(paymentInfo.tokenWithoutBonus > 0);
    assert(paymentInfo.currency.value > 0);
    assert(paymentInfo.currency.usdRaised > 0);
    assert(paymentInfo.currency.usdAbsRaisedInCents > 0);
    assert(paymentInfo.currency.coinRaisedInWei > 0);

    assert(currencyContract.editPay(payment.pType, paymentInfo.currency.value, paymentInfo.currency.usdRaised, paymentInfo.currency.usdAbsRaisedInCents, paymentInfo.currency.coinRaisedInWei, paymentInfo.currency.coinRaisedBonusInWei));
    assert(storageContract.editPaymentByUserId(uId, payId, value, paymentInfo.usdAmount, paymentInfo.currencyUSD, paymentInfo.totalToken, paymentInfo.tokenWithoutBonus, paymentInfo.tokenBonus, paymentInfo.bonusPercent));

    assert(reCountUserPreSaleBonus(uId));

    emit EditPay(storageContract.getContributorAddressById(uId));
  }

   
  function refundPay(uint uId, uint payId) public onlyMultiOwnersType(18) {
    require(storageContract.checkUserIdExists(uId));
    require(payId > 0);

    (CurrencyInfo memory currencyInfo, bytes32 pType) = calcCurrency(getPaymentInfo(uId, payId), 0, 0, 0, 0);

    assert(storageContract.refundPaymentByUserId(uId, payId));
    assert(currencyContract.editPay(pType, currencyInfo.value, currencyInfo.usdRaised, currencyInfo.usdAbsRaisedInCents, currencyInfo.coinRaisedInWei, currencyInfo.coinRaisedBonusInWei));

    assert(reCountUserPreSaleBonus(uId));

    emit RefundPay(storageContract.getContributorAddressById(uId));
  }

   
  function checkSoftCapAchieved() public view returns(bool) {
    return softCapAchieved || getTotalUsdRaisedInCents() >= softCapUSD;
  }

   
  function activeSoftCapAchieved() public onlyMultiOwnersType(8) {
    require(checkSoftCapAchieved());
    require(getCoinBalance() >= maxDistributeCoin);
    softCapAchieved = true;
    emit SoftCapAchieved(getTotalUsdRaisedInCents());
  }

   
  function getEther() public onlyMultiOwnersType(9) {
    require(getETHBalance() > 0);
    require(softCapAchieved && (!multiSigReceivedSoftCap || (state == SaleState.END)));

    uint sendEther = (address(this).balance / 2);
    assert(sendEther > 0);

    address(multiSig1).transfer(sendEther);
    address(multiSig2).transfer(sendEther);
    multiSigReceivedSoftCap = true;
  }

   
  function calculateMaxCoinIssued() public view returns (uint) {
    return maxDistributeCoin - currencyContract.getCoinRaisedInWei();
  }

   
  function getCoinRaisedInWei() public view returns (uint) {
    return currencyContract.getCoinRaisedInWei();
  }

   
  function getTotalUsdRaisedInCents() public view returns (uint) {
    return currencyContract.getTotalUsdRaisedInCents();
  }

   
  function getAllCurrencyTicker() public view returns (string) {
    return currencyContract.getAllCurrencyTicker();
  }

   
  function getCoinUSDRate() public view returns (uint) {
    return currencyContract.getCoinUSDRate();
  }

   
  function getCoinBalance() public view returns (uint) {
    return coinContract.balanceOf(address(this));
  }

   
  function getETHBalance() public view returns (uint) {
    return address(this).balance;
  }

   
  function processSetPreSaleBonus(uint start, uint limit) public onlyMultiOwnersType(10) {
    require(state == SaleState.CALCPSBONUS);
    require(start >= 0 && limit > 0);
     
    uint bonusToken = storageContract.processPreSaleBonus(getMinReachUsdPayInCents(), getPreSaleBonusPercent(), start, limit);
    if (bonusToken > 0) {
      assert(currencyContract.addPreSaleBonus(bonusToken));
    }
  }

   
  function reCountUserPreSaleBonus(uint uId) public onlyMultiOwnersType(11) returns(bool) {
    if (uint(state) > 1) {  
      uint maxPayTime = 0;
      if (state != SaleState.CALCPSBONUS) {
        maxPayTime = startSaleDate;
      }
      (uint befTokenBonus, uint aftTokenBonus) = storageContract.reCountUserPreSaleBonus(uId, getMinReachUsdPayInCents(), getPreSaleBonusPercent(), maxPayTime);
      assert(currencyContract.editPreSaleBonus(befTokenBonus, aftTokenBonus));
    }
    return true;
  }

   
  function getCoins() public {
    return _getCoins(msg.sender);
  }

   
  function sendSHPCtoContributors(uint start, uint limit) public onlyMultiOwnersType(12) {
    require(state == SaleState.END);
    require(start >= 0 && limit > 0);
    require(getCoinBalance() > 0);
     

    for (uint i = start; i < limit; i++) {
      uint uId = storageContract.getContributorIndexes(i);
      if (uId > 0) {
        address addr = storageContract.getContributorAddressById(uId);
        uint coins = storageContract.getTotalCoin(addr);
        if (!storageContract.checkReceivedCoins(addr) && storageContract.checkWalletExists(addr) && coins > 0 && ((storageContract.checkPreSaleReceivedBonus(addr) && block.timestamp >= unfreezeRefundPreSale) || (!storageContract.checkPreSaleReceivedBonus(addr) && block.timestamp >= unfreezeRefundAll))) {
          if (coinContract.transfer(addr, coins)) {
            storageContract.setReceivedCoin(uId);
            emit SendSHPCtoContributor(addr);
          }
        }
      }
    }
  }

   
  function setStartPreSaleDate(uint date) public onlyMultiOwnersType(13) {
    uint oldDate = startPreSaleDate;
    startPreSaleDate = date;
    emit ManualChangeStartPreSaleDate(oldDate, date);
  }

   
  function setEndPreSaleDate(uint date) public onlyMultiOwnersType(14) {
    uint oldDate = endPreSaleDate;
    endPreSaleDate = date;
    emit ManualChangeEndPreSaleDate(oldDate, date);
  }

   
  function setStartSaleDate(uint date) public onlyMultiOwnersType(15) {
    uint oldDate = startSaleDate;
    startSaleDate = date;
    emit ManualChangeStartSaleDate(oldDate, date);
  }

   
  function setEndSaleDate(uint date) public onlyMultiOwnersType(16) {
    uint oldDate = endSaleDate;
    endSaleDate = date;
    emit ManualEndSaleDate(oldDate, date);
  }

   
  function getSHPCBack() public onlyMultiOwnersType(17) {
    require(state == SaleState.END);
    require(getCoinBalance() > 0);
     
    coinContract.transfer(msg.sender, getCoinBalance());
  }


   
  function refundETH() public {
    return _refundETH(msg.sender);
  }

   
  function refundETHContributors(uint start, uint limit) public onlyMultiOwnersType(19) {
    require(state == SaleState.REFUND);
    require(start >= 0 && limit > 0);
    require(getETHBalance() > 0);
     

    for (uint i = start; i < limit; i++) {
      uint uId = storageContract.getContributorIndexes(i);
      if (uId > 0) {
        address addr = storageContract.getContributorAddressById(uId);
        uint ethAmount = storageContract.getEthPaymentContributor(addr);

        if (!storageContract.checkRefund(addr) && storageContract.checkWalletExists(addr) && ethAmount > 0) {
          storageContract.setRefund(uId);
          addr.transfer(ethAmount);
          emit Refund(addr);
        }
      }
    }
  }

   
  function getPreSaleBonusPercent() public view returns(uint) {
    return bonusContract.getPreSaleBonusPercent();
  }

   
  function getMinReachUsdPayInCents() public view returns(uint) {
    return bonusContract.getMinReachUsdPayInCents();
  }

   
  function _currentDay() public view returns(uint) {
    return bonusContract._currentDay(startSaleDate, (state == SaleState.SALE));
  }

   
  function getCurrentDayBonus() public view returns(uint) {
    return bonusContract.getCurrentDayBonus(startSaleDate, (state == SaleState.SALE));
  }

   
  function getPaymentInfo(uint uId, uint pId) private view returns(PaymentInfo) {
    (, bytes32 pType,
    uint currencyUSD,
    uint bonusPercent,
    uint payValue,
    uint totalToken,
    uint tokenBonus,,
    uint usdAbsRaisedInCents,
    bool refund) = storageContract.getUserPaymentById(uId, pId);

    return PaymentInfo(pType, currencyUSD, bonusPercent, payValue, totalToken, tokenBonus, usdAbsRaisedInCents, refund);
  }

   
  function calcEditPaymentInfo(PaymentInfo payment, uint value, uint _currencyUSD, uint _bonusPercent) private view returns(EditPaymentInfo) {
    (uint usdAmount, uint currencyUSD, uint bonusPercent) = getUsdAmountFromPayment(payment, value, _currencyUSD, _bonusPercent);
    (uint totalToken, uint tokenWithoutBonus, uint tokenBonus) = calcToken(usdAmount, bonusPercent);
    (CurrencyInfo memory currency,) = calcCurrency(payment, value, usdAmount, totalToken, tokenBonus);

    return EditPaymentInfo(usdAmount, currencyUSD, bonusPercent, totalToken, tokenWithoutBonus, tokenBonus, currency);
  }

   
  function getUsdAmountFromPayment(PaymentInfo payment, uint value, uint _currencyUSD, uint _bonusPercent) private view returns(uint, uint, uint) {
    _currencyUSD = _currencyUSD > 0 ? _currencyUSD : payment.currencyUSD;
    _bonusPercent = _bonusPercent > 0 ? _bonusPercent : payment.bonusPercent;
    uint usdAmount = currencyContract.getUsdFromCurrency(payment.pType, value, _currencyUSD);
    return (usdAmount, _currencyUSD, _bonusPercent);
  }

   
  function calcToken(uint usdAmount, uint _bonusPercent) private view returns(uint, uint, uint) {
    uint tokenWithoutBonus = currencyContract.getTokenWeiFromUSD(usdAmount);
    uint tokenBonus = _bonusPercent > 0 ? tokenWithoutBonus.mul(_bonusPercent).div(100) : 0;
    uint totalToken = tokenBonus > 0 ? tokenWithoutBonus.add(tokenBonus) : tokenWithoutBonus;
    return (totalToken, tokenWithoutBonus, tokenBonus);
  }

   
  function calcCurrency(PaymentInfo payment, uint value, uint usdAmount, uint totalToken, uint tokenBonus) private view returns(CurrencyInfo, bytes32) {
    (,,, uint currencyValue, uint currencyUsdRaised,,,) = currencyContract.getCurrencyList(payment.pType);

    uint usdAbsRaisedInCents = currencyContract.getUsdAbsRaisedInCents();
    uint coinRaisedInWei = currencyContract.getCoinRaisedInWei();
    uint coinRaisedBonusInWei = currencyContract.getCoinRaisedBonusInWei();

    currencyValue -= payment.payValue;
    currencyUsdRaised -= payment.usdAbsRaisedInCents;

    usdAbsRaisedInCents -= payment.usdAbsRaisedInCents;
    coinRaisedInWei -= payment.totalToken;
    coinRaisedBonusInWei -= payment.tokenBonus;

    currencyValue += value;
    currencyUsdRaised += usdAmount;

    usdAbsRaisedInCents += usdAmount;
    coinRaisedInWei += totalToken;
    coinRaisedBonusInWei += tokenBonus;

    return (CurrencyInfo(currencyValue, currencyUsdRaised, usdAbsRaisedInCents, coinRaisedInWei, coinRaisedBonusInWei), payment.pType);
  }

   
  function _getCoins(address addr) private {
    require(state == SaleState.END);
    require(storageContract.checkWalletExists(addr));
    require(!storageContract.checkReceivedCoins(addr));
    require((storageContract.checkPreSaleReceivedBonus(addr) && block.timestamp >= unfreezeRefundPreSale) || (!storageContract.checkPreSaleReceivedBonus(addr) && block.timestamp >= unfreezeRefundAll));
    uint uId = storageContract.getContributorId(addr);
    uint coins = storageContract.getTotalCoin(addr);
    assert(uId > 0 && coins > 0);
    if (coinContract.transfer(addr, coins)) {
      storageContract.setReceivedCoin(uId);
      emit SendSHPCtoContributor(addr);
    }
  }

   
  function _refundETH(address addr) private {
    require(state == SaleState.REFUND);
    require(storageContract.checkWalletExists(addr));
    require(!storageContract.checkRefund(addr));

    uint uId = storageContract.getContributorId(addr);
    uint ethAmount = storageContract.getEthPaymentContributor(addr);
    assert(uId > 0 && ethAmount > 0 && getETHBalance() >= ethAmount);

    storageContract.setRefund(uId);
    addr.transfer(ethAmount);
    emit Refund(addr);
  }

}