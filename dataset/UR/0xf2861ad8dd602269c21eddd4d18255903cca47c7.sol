 

 

pragma solidity ^0.4.24;

 

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library ZethrTierLibrary {
  uint constant internal magnitude = 2 ** 64;

   
   
  function getTier(uint divRate) internal pure returns (uint8) {

     
     
    uint actualDiv = divRate / magnitude;
    if (actualDiv >= 30) {
      return 6;
    } else if (actualDiv >= 25) {
      return 5;
    } else if (actualDiv >= 20) {
      return 4;
    } else if (actualDiv >= 15) {
      return 3;
    } else if (actualDiv >= 10) {
      return 2;
    } else if (actualDiv >= 5) {
      return 1;
    } else if (actualDiv >= 2) {
      return 0;
    } else {
       
      revert();
    }
  }

  function getDivRate(uint _tier)
  internal pure
  returns (uint8)
  {
    if (_tier == 0) {
      return 2;
    } else if (_tier == 1) {
      return 5;
    } else if (_tier == 2) {
      return 10;
    } else if (_tier == 3) {
      return 15;
    } else if (_tier == 4) {
      return 20;
    } else if (_tier == 5) {
      return 25;
    } else if (_tier == 6) {
      return 33;
    } else {
      revert();
    }
  }
}

 

contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 

  
contract ZethrMultiSigWallet is ERC223Receiving {
  using SafeMath for uint;

   

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event WhiteListAddition(address indexed contractAddress);
  event WhiteListRemoval(address indexed contractAddress);
  event RequirementChange(uint required);
  event BankrollInvest(uint amountReceived);

   

  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;
  bool internal reEntered = false;
  uint constant public MAX_OWNER_COUNT = 15;

   

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  struct TKN {
    address sender;
    uint value;
  }

   

  modifier onlyWallet() {
    if (msg.sender != address(this))
      revert();
    _;
  }

  modifier isAnOwner() {
    address caller = msg.sender;
    if (isOwner[caller])
      _;
    else
      revert();
  }

  modifier ownerDoesNotExist(address owner) {
    if (isOwner[owner]) 
      revert();
      _;
  }

  modifier ownerExists(address owner) {
    if (!isOwner[owner])
      revert();
    _;
  }

  modifier transactionExists(uint transactionId) {
    if (transactions[transactionId].destination == 0)
      revert();
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    if (!confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    if (confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notExecuted(uint transactionId) {
    if (transactions[transactionId].executed)
      revert();
    _;
  }

  modifier notNull(address _address) {
    if (_address == 0)
      revert();
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    if ( ownerCount > MAX_OWNER_COUNT
      || _required > ownerCount
      || _required == 0
      || ownerCount == 0)
      revert();
    _;
  }


   

   
   
   
  constructor (address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
  {
     
    for (uint i=0; i<_owners.length; i++) {
      if (isOwner[_owners[i]] || _owners[i] == 0)
        revert();
      isOwner[_owners[i]] = true;
    }

     
    owners = _owners;

     
    required = _required;
  }

   

   
  function()
    public
    payable
  {

  }
    
   
   
  function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner);
  }

   
   
  function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    validRequirement(owners.length, required)
  {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }

    owners.length -= 1;
    if (required > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner);
  }

   
   
   
  function replaceOwner(address owner, address newOwner)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
  {
    for (uint i=0; i<owners.length; i++)
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }

    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

   
   
  function changeRequirement(uint _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
  {
    required = _required;
    emit RequirementChange(_required);
  }

   
   
   
   
   
  function submitTransaction(address destination, uint value, bytes data)
    public
    returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

   
   
  function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
  {
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

   
   
  function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  {
    confirmations[transactionId][msg.sender] = false;
    emit Revocation(msg.sender, transactionId);
  }

   
   
  function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      Transaction storage txToExecute = transactions[transactionId];
      txToExecute.executed = true;
      if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
        emit Execution(transactionId);
      else {
        emit ExecutionFailure(transactionId);
        txToExecute.executed = false;
      }
    }
  }

   
   
   
  function isConfirmed(uint transactionId)
    public
    constant
    returns (bool)
  {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

   

   
   
   
   
   
  function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
  {
    transactionId = transactionCount;

    transactions[transactionId] = Transaction({
        destination: destination,
        value: value,
        data: data,
        executed: false
    });

    transactionCount += 1;
    emit Submission(transactionId);
  }

   
   
   
   
  function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]])
        count += 1;
  }

   
   
   
   
  function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed)
        count += 1;
  }

   
   
  function getOwners()
    public
    constant
    returns (address[])
  {
    return owners;
  }

   
   
   
  function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }

      _confirmations = new address[](count);

      for (i=0; i<count; i++)
        _confirmations[i] = confirmationsTemp[i];
  }

   
   
   
   
   
   
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;

    for (i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed) {
        transactionIdsTemp[count] = i;
        count += 1;
      }

      _transactionIds = new uint[](to - from);

    for (i=from; i<to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  function tokenFallback(address  , uint  , bytes  )
  public
  returns (bool)
  {
    return true;
  }
}

 

 
contract ZethrTokenBankrollInterface is ERC223Receiving {
  uint public jackpotBalance;
  
  function getMaxProfit(address) public view returns (uint);
  function gameTokenResolution(uint _toWinnerAmount, address _winnerAddress, uint _toJackpotAmount, address _jackpotAddress, uint _originalBetSize) external;
  function payJackpotToWinner(address _winnerAddress, uint payoutDivisor) public;
}

 

contract ZethrBankrollControllerInterface is ERC223Receiving {
  address public jackpotAddress;

  ZethrTokenBankrollInterface[7] public tokenBankrolls; 
  
  ZethrMultiSigWallet public multiSigWallet;

  mapping(address => bool) public validGameAddresses;

  function gamePayoutResolver(address _resolver, uint _tokenAmount) public;

  function isTokenBankroll(address _address) public view returns (bool);

  function getTokenBankrollAddressFromTier(uint8 _tier) public view returns (address);

  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 

contract ERC721Interface {
  function approve(address _to, uint _tokenId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _tokenId) public view returns (address addr);
  function takeOwnership(uint _tokenId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _tokenId) public;
  function transfer(address _to, uint _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }
}

 

contract ZethrDividendCards is ERC721Interface {
    using SafeMath for uint;

   

   
  event Birth(uint tokenId, string name, address owner);

   
  event TokenSold(uint tokenId, uint oldPrice, uint newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint tokenId);

   
  event BankrollDivCardProfit(uint bankrollProfit, uint percentIncrease, address oldOwner);
  event BankrollProfitFailure(uint bankrollProfit, uint percentIncrease, address oldOwner);
  event UserDivCardProfit(uint divCardProfit, uint percentIncrease, address oldOwner);
  event DivCardProfitFailure(uint divCardProfit, uint percentIncrease, address oldOwner);
  event masterCardProfit(uint toMaster, address _masterAddress, uint _divCardId);
  event masterCardProfitFailure(uint toMaster, address _masterAddress, uint _divCardId);
  event regularCardProfit(uint toRegular, address _regularAddress, uint _divCardId);
  event regularCardProfitFailure(uint toRegular, address _regularAddress, uint _divCardId);

   

   
  string public constant NAME           = "ZethrDividendCard";
  string public constant SYMBOL         = "ZDC";
  address public         BANKROLL;

   

   
   

  mapping (uint => address) public      divCardIndexToOwner;

   

  mapping (uint => uint) public         divCardRateToIndex;

   
   

  mapping (address => uint) private     ownershipDivCardCount;

   
   
   

  mapping (uint => address) public      divCardIndexToApproved;

   

  mapping (uint => uint) private        divCardIndexToPrice;

  mapping (address => bool) internal    administrators;

  address public                        creator;
  bool    public                        onSale;

   

  struct Card {
    string name;
    uint percentIncrease;
  }

  Card[] private divCards;

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  constructor (address _bankroll) public {
    creator = msg.sender;
    BANKROLL = _bankroll;

    createDivCard("2%", 1 ether, 2);
    divCardRateToIndex[2] = 0;

    createDivCard("5%", 1 ether, 5);
    divCardRateToIndex[5] = 1;

    createDivCard("10%", 1 ether, 10);
    divCardRateToIndex[10] = 2;

    createDivCard("15%", 1 ether, 15);
    divCardRateToIndex[15] = 3;

    createDivCard("20%", 1 ether, 20);
    divCardRateToIndex[20] = 4;

    createDivCard("25%", 1 ether, 25);
    divCardRateToIndex[25] = 5;

    createDivCard("33%", 1 ether, 33);
    divCardRateToIndex[33] = 6;

    createDivCard("MASTER", 5 ether, 10);
    divCardRateToIndex[999] = 7;

	  onSale = true;

    administrators[0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae] = true;  
    administrators[0x11e52c75998fe2E7928B191bfc5B25937Ca16741] = true;  
    administrators[0x20C945800de43394F70D789874a4daC9cFA57451] = true;  
    administrators[0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB] = true;  

    administrators[msg.sender] = true;  
  }

   

   
  modifier isNotContract()
  {
    require (msg.sender == tx.origin);
    _;
  }

	 
	modifier hasStarted()
  {
		require (onSale == true);
		_;
	}

	modifier isAdmin()
  {
	  require(administrators[msg.sender]);
	  _;
  }

   
   
  function setBankroll(address where)
    public
    isAdmin
  {
    BANKROLL = where;
  }

   
   
   
   
   
  function approve(address _to, uint _tokenId)
    public
    isNotContract
  {
     
    require(_owns(msg.sender, _tokenId));

    divCardIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner)
    public
    view
    returns (uint balance)
  {
    return ownershipDivCardCount[_owner];
  }

   
  function createDivCard(string _name, uint _price, uint _percentIncrease)
    public
    onlyCreator
  {
    _createDivCard(_name, BANKROLL, _price, _percentIncrease);
  }

	 
	function startCardSale()
        public
        isAdmin
  {
		onSale = true;
	}

   
   
  function getDivCard(uint _divCardId)
    public
    view
    returns (string divCardName, uint sellingPrice, address owner)
  {
    Card storage divCard = divCards[_divCardId];
    divCardName = divCard.name;
    sellingPrice = divCardIndexToPrice[_divCardId];
    owner = divCardIndexToOwner[_divCardId];
  }

  function implementsERC721()
    public
    pure
    returns (bool)
  {
    return true;
  }

   
  function name()
    public
    pure
    returns (string)
  {
    return NAME;
  }

   
   
   
  function ownerOf(uint _divCardId)
    public
    view
    returns (address owner)
  {
    owner = divCardIndexToOwner[_divCardId];
    require(owner != address(0));
	return owner;
  }

   
  function purchase(uint _divCardId)
    public
    payable
    hasStarted
    isNotContract
  {
    address oldOwner  = divCardIndexToOwner[_divCardId];
    address newOwner  = msg.sender;

     
    uint currentPrice = divCardIndexToPrice[_divCardId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= currentPrice);

     
     
     
    uint percentIncrease = divCards[_divCardId].percentIncrease;
    uint previousPrice   = SafeMath.mul(currentPrice, 100).div(100 + percentIncrease);

     
    uint totalProfit     = SafeMath.sub(currentPrice, previousPrice);
    uint oldOwnerProfit  = SafeMath.div(totalProfit, 2);
    uint bankrollProfit  = SafeMath.sub(totalProfit, oldOwnerProfit);
    oldOwnerProfit       = SafeMath.add(oldOwnerProfit, previousPrice);

     
    uint purchaseExcess  = SafeMath.sub(msg.value, currentPrice);

     
    divCardIndexToPrice[_divCardId] = SafeMath.div(SafeMath.mul(currentPrice, (100 + percentIncrease)), 100);

     
    _transfer(oldOwner, newOwner, _divCardId);

     
    if(BANKROLL.send(bankrollProfit)) {
      emit BankrollDivCardProfit(bankrollProfit, percentIncrease, oldOwner);
    } else {
      emit BankrollProfitFailure(bankrollProfit, percentIncrease, oldOwner);
    }

    if(oldOwner.send(oldOwnerProfit)) {
      emit UserDivCardProfit(oldOwnerProfit, percentIncrease, oldOwner);
    } else {
      emit DivCardProfitFailure(oldOwnerProfit, percentIncrease, oldOwner);
    }

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint _divCardId)
    public
    view
    returns (uint price)
  {
    return divCardIndexToPrice[_divCardId];
  }

  function setCreator(address _creator)
    public
    onlyCreator
  {
    require(_creator != address(0));

    creator = _creator;
  }

   
  function symbol()
    public
    pure
    returns (string)
  {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint _divCardId)
    public
    isNotContract
  {
    address newOwner = msg.sender;
    address oldOwner = divCardIndexToOwner[_divCardId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _divCardId));

    _transfer(oldOwner, newOwner, _divCardId);
  }

   
   
  function totalSupply()
    public
    view
    returns (uint total)
  {
    return divCards.length;
  }

   
   
   
   
  function transfer(address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(msg.sender, _divCardId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _divCardId);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(_from, _divCardId));
    require(_approved(_to, _divCardId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _divCardId);
  }

  function receiveDividends(uint _divCardRate)
    public
    payable
  {
    uint _divCardId = divCardRateToIndex[_divCardRate];
    address _regularAddress = divCardIndexToOwner[_divCardId];
    address _masterAddress = divCardIndexToOwner[7];

    uint toMaster = msg.value.div(2);
    uint toRegular = msg.value.sub(toMaster);

    if(_masterAddress.send(toMaster)){
      emit masterCardProfit(toMaster, _masterAddress, _divCardId);
    } else {
      emit masterCardProfitFailure(toMaster, _masterAddress, _divCardId);
    }

    if(_regularAddress.send(toRegular)) {
      emit regularCardProfit(toRegular, _regularAddress, _divCardId);
    } else {
      emit regularCardProfitFailure(toRegular, _regularAddress, _divCardId);
    }
  }

   
   
  function _addressNotNull(address _to)
    private
    pure
    returns (bool)
  {
    return _to != address(0);
  }

   
  function _approved(address _to, uint _divCardId)
    private
    view
    returns (bool)
  {
    return divCardIndexToApproved[_divCardId] == _to;
  }

   
  function _createDivCard(string _name, address _owner, uint _price, uint _percentIncrease)
    private
  {
    Card memory _divcard = Card({
      name: _name,
      percentIncrease: _percentIncrease
    });
    uint newCardId = divCards.push(_divcard) - 1;

     
     
    require(newCardId == uint(uint32(newCardId)));

    emit Birth(newCardId, _name, _owner);

    divCardIndexToPrice[newCardId] = _price;

     
    _transfer(BANKROLL, _owner, newCardId);
  }

   
  function _owns(address claimant, uint _divCardId)
    private
    view
    returns (bool)
  {
    return claimant == divCardIndexToOwner[_divCardId];
  }

   
  function _transfer(address _from, address _to, uint _divCardId)
    private
  {
     
    ownershipDivCardCount[_to]++;
     
    divCardIndexToOwner[_divCardId] = _to;

     
    if (_from != address(0)) {
      ownershipDivCardCount[_from]--;
       
      delete divCardIndexToApproved[_divCardId];
    }

     
    emit Transfer(_from, _to, _divCardId);
  }
}

 

contract Zethr {
  using SafeMath for uint;

   

  modifier onlyHolders() {
    require(myFrontEndTokens() > 0);
    _;
  }

  modifier dividendHolder() {
    require(myDividends(true) > 0);
    _;
  }

  modifier onlyAdministrator(){
    address _customerAddress = msg.sender;
    require(administrators[_customerAddress]);
    _;
  }

   

  event onTokenPurchase(
    address indexed customerAddress,
    uint incomingEthereum,
    uint tokensMinted,
    address indexed referredBy
  );

  event UserDividendRate(
    address user,
    uint divRate
  );

  event onTokenSell(
    address indexed customerAddress,
    uint tokensBurned,
    uint ethereumEarned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint ethereumReinvested,
    uint tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint ethereumWithdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint tokens
  );

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint tokens
  );

  event Allocation(
    uint toBankRoll,
    uint toReferrer,
    uint toTokenHolders,
    uint toDivCardHolders,
    uint forTokens
  );

  event Referral(
    address referrer,
    uint amountReceived
  );

   

  uint8 constant public                decimals = 18;

  uint constant internal               tokenPriceInitial_ = 0.000653 ether;
  uint constant internal               magnitude = 2 ** 64;

  uint constant internal               icoHardCap = 250 ether;
  uint constant internal               addressICOLimit = 1   ether;
  uint constant internal               icoMinBuyIn = 0.1 finney;
  uint constant internal               icoMaxGasPrice = 50000000000 wei;

  uint constant internal               MULTIPLIER = 9615;

  uint constant internal               MIN_ETH_BUYIN = 0.0001 ether;
  uint constant internal               MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal               MIN_TOKEN_TRANSFER = 1e10;
  uint constant internal               referrer_percentage = 25;

  uint public                          stakingRequirement = 100e18;

   

  string public                        name = "Zethr";
  string public                        symbol = "ZTH";

   
  bytes32 constant public              icoHashedPass = bytes32(0x8a6ddee3fb2508ff4a5b02b48e9bc4566d0f3e11f306b0f75341bf235662a9e3);  

  address internal                     bankrollAddress;

  ZethrDividendCards                   divCardContract;

   

   
  mapping(address => uint) internal    frontTokenBalanceLedger_;
  mapping(address => uint) internal    dividendTokenBalanceLedger_;
  mapping(address =>
  mapping(address => uint))
  public      allowed;

   
  mapping(uint8 => bool)    internal validDividendRates_;
  mapping(address => bool)    internal userSelectedRate;
  mapping(address => uint8)   internal userDividendRate;

   
  mapping(address => uint)    internal referralBalance_;
  mapping(address => int256)  internal payoutsTo_;

   
  mapping(address => uint)    internal ICOBuyIn;

  uint public                          tokensMintedDuringICO;
  uint public                          ethInvestedDuringICO;

  uint public                          currentEthInvested;

  uint internal                        tokenSupply = 0;
  uint internal                        divTokenSupply = 0;

  uint internal                        profitPerDivToken;

  mapping(address => bool) public      administrators;

  bool public                          icoPhase = false;
  bool public                          regularPhase = false;

  uint                                 icoOpenTime;

   
  constructor (address _bankrollAddress, address _divCardAddress)
  public
  {
    bankrollAddress = _bankrollAddress;
    divCardContract = ZethrDividendCards(_divCardAddress);

    administrators[0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae] = true;
     
    administrators[0x11e52c75998fe2E7928B191bfc5B25937Ca16741] = true;
     
    administrators[0x20C945800de43394F70D789874a4daC9cFA57451] = true;
     
    administrators[0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB] = true;
     
    administrators[0x8537aa2911b193e5B377938A723D805bb0865670] = true;
     
    administrators[0x9D221b2100CbE5F05a0d2048E2556a6Df6f9a6C3] = true;
     
    administrators[0xDa83156106c4dba7A26E9bF2Ca91E273350aa551] = true;
     
    administrators[0x71009e9E4e5e68e77ECc7ef2f2E95cbD98c6E696] = true;
     

    administrators[msg.sender] = true;
     

    validDividendRates_[2] = true;
    validDividendRates_[5] = true;
    validDividendRates_[10] = true;
    validDividendRates_[15] = true;
    validDividendRates_[20] = true;
    validDividendRates_[25] = true;
    validDividendRates_[33] = true;

    userSelectedRate[bankrollAddress] = true;
    userDividendRate[bankrollAddress] = 33;

  }

   
  function buyAndSetDivPercentage(address _referredBy, uint8 _divChoice, string  )
  public
  payable
  returns (uint)
  {
    require(icoPhase || regularPhase);

    if (icoPhase) {

       
       
       

      uint gasPrice = tx.gasprice;

       
       
      require(gasPrice <= icoMaxGasPrice && ethInvestedDuringICO <= icoHardCap);

    }

     
    require(validDividendRates_[_divChoice]);

     
    userSelectedRate[msg.sender] = true;
    userDividendRate[msg.sender] = _divChoice;
    emit UserDividendRate(msg.sender, _divChoice);

     
    purchaseTokens(msg.value, _referredBy);
  }

   

  function buy(address _referredBy)
  public
  payable
  returns (uint)
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    purchaseTokens(msg.value, _referredBy);
  }

  function buyAndTransfer(address _referredBy, address target)
  public
  payable
  {
    bytes memory empty;
    buyAndTransfer(_referredBy, target, empty, 20);
  }

  function buyAndTransfer(address _referredBy, address target, bytes _data)
  public
  payable
  {
    buyAndTransfer(_referredBy, target, _data, 20);
  }

   
  function buyAndTransfer(address _referredBy, address target, bytes _data, uint8 divChoice)
  public
  payable
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    uint256 frontendBalance = frontTokenBalanceLedger_[msg.sender];
    if (userSelectedRate[_customerAddress] && divChoice == 0) {
      purchaseTokens(msg.value, _referredBy);
    } else {
      buyAndSetDivPercentage(_referredBy, divChoice, "0x0");
    }
    uint256 difference = SafeMath.sub(frontTokenBalanceLedger_[msg.sender], frontendBalance);
    transferTo(msg.sender, target, difference, _data);
  }

   
  function()
  payable
  public
  {
     
    require(regularPhase);
    address _customerAddress = msg.sender;
    if (userSelectedRate[_customerAddress]) {
      purchaseTokens(msg.value, 0x0);
    } else {
      buyAndSetDivPercentage(0x0, 20, "0x0");
    }
  }

  function reinvest()
  dividendHolder()
  public
  {
    require(regularPhase);
    uint _dividends = myDividends(false);

     
    address _customerAddress = msg.sender;
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    uint _tokens = purchaseTokens(_dividends, 0x0);

     
    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

  function exit()
  public
  {
    require(regularPhase);
     
    address _customerAddress = msg.sender;
    uint _tokens = frontTokenBalanceLedger_[_customerAddress];

    if (_tokens > 0) sell(_tokens);

    withdraw(_customerAddress);
  }

  function withdraw(address _recipient)
  dividendHolder()
  public
  {
    require(regularPhase);
     
    address _customerAddress = msg.sender;
    uint _dividends = myDividends(false);

     
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

     
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    if (_recipient == address(0x0)) {
      _recipient = msg.sender;
    }
    _recipient.transfer(_dividends);

     
    emit onWithdraw(_recipient, _dividends);
  }

   
   
  function sell(uint _amountOfTokens)
  onlyHolders()
  public
  {
     
    require(!icoPhase);
    require(regularPhase);

    require(_amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);

    uint _frontEndTokensToBurn = _amountOfTokens;

     
     
     
    uint userDivRate = getUserAverageDividendRate(msg.sender);
    require((2 * magnitude) <= userDivRate && (50 * magnitude) >= userDivRate);
    uint _divTokensToBurn = (_frontEndTokensToBurn.mul(userDivRate)).div(magnitude);

     
    uint _ethereum = tokensToEthereum_(_frontEndTokensToBurn);

    if (_ethereum > currentEthInvested) {
       
      currentEthInvested = 0;
    } else {currentEthInvested = currentEthInvested - _ethereum;}

     
    uint _dividends = (_ethereum.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude);

     
    uint _taxedEthereum = _ethereum.sub(_dividends);

     
    tokenSupply = tokenSupply.sub(_frontEndTokensToBurn);
    divTokenSupply = divTokenSupply.sub(_divTokensToBurn);

     
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].sub(_frontEndTokensToBurn);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].sub(_divTokensToBurn);

     
    int256 _updatedPayouts = (int256) (profitPerDivToken * _divTokensToBurn + (_taxedEthereum * magnitude));
    payoutsTo_[msg.sender] -= _updatedPayouts;

     
    if (divTokenSupply > 0) {
       
      profitPerDivToken = profitPerDivToken.add((_dividends * magnitude) / divTokenSupply);
    }

     
    emit onTokenSell(msg.sender, _frontEndTokensToBurn, _taxedEthereum);
  }

   
  function transfer(address _toAddress, uint _amountOfTokens)
  onlyHolders()
  public
  returns (bool)
  {
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER && _amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);
    bytes memory empty;
    transferFromInternal(msg.sender, _toAddress, _amountOfTokens, empty);
    return true;
  }

  function approve(address spender, uint tokens)
  public
  returns (bool)
  {
    address _customerAddress = msg.sender;
    allowed[_customerAddress][spender] = tokens;

     
    emit Approval(_customerAddress, spender, tokens);

     
    return true;
  }

   
  function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
  public
  returns (bool)
  {
     
    address _customerAddress = _from;
    bytes memory empty;
     
     
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER
    && _amountOfTokens <= frontTokenBalanceLedger_[_customerAddress]
    && _amountOfTokens <= allowed[_customerAddress][msg.sender]);

    transferFromInternal(_from, _toAddress, _amountOfTokens, empty);

     
    return true;

  }

  function transferTo(address _from, address _to, uint _amountOfTokens, bytes _data)
  public
  {
    if (_from != msg.sender) {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]
      && _amountOfTokens <= allowed[_from][msg.sender]);
    }
    else {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]);
    }

    transferFromInternal(_from, _to, _amountOfTokens, _data);
  }

   
  function totalSupply()
  public
  view
  returns (uint256)
  {
    return tokenSupply;
  }

   
   
  function publicStartRegularPhase()
  public
  {
    require(now > (icoOpenTime + 2 weeks) && icoOpenTime != 0);

    icoPhase = false;
    regularPhase = true;
  }

   


   
  function startICOPhase()
  onlyAdministrator()
  public
  {
     
    require(icoOpenTime == 0);
    icoPhase = true;
    icoOpenTime = now;
  }

   
  function endICOPhase()
  onlyAdministrator()
  public
  {
    icoPhase = false;
  }

  function startRegularPhase()
  onlyAdministrator
  public
  {
     
    icoPhase = false;
    regularPhase = true;
  }

   
  function setAdministrator(address _newAdmin, bool _status)
  onlyAdministrator()
  public
  {
    administrators[_newAdmin] = _status;
  }

  function setStakingRequirement(uint _amountOfTokens)
  onlyAdministrator()
  public
  {
     
    require(_amountOfTokens >= 100e18);
    stakingRequirement = _amountOfTokens;
  }

  function setName(string _name)
  onlyAdministrator()
  public
  {
    name = _name;
  }

  function setSymbol(string _symbol)
  onlyAdministrator()
  public
  {
    symbol = _symbol;
  }

  function changeBankroll(address _newBankrollAddress)
  onlyAdministrator
  public
  {
    bankrollAddress = _newBankrollAddress;
  }

   

  function totalEthereumBalance()
  public
  view
  returns (uint)
  {
    return address(this).balance;
  }

  function totalEthereumICOReceived()
  public
  view
  returns (uint)
  {
    return ethInvestedDuringICO;
  }

   
  function getMyDividendRate()
  public
  view
  returns (uint8)
  {
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    return userDividendRate[_customerAddress];
  }

   
  function getFrontEndTokenSupply()
  public
  view
  returns (uint)
  {
    return tokenSupply;
  }

   
  function getDividendTokenSupply()
  public
  view
  returns (uint)
  {
    return divTokenSupply;
  }

   
  function myFrontEndTokens()
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return getFrontEndTokenBalanceOf(_customerAddress);
  }

   
  function myDividendTokens()
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return getDividendTokenBalanceOf(_customerAddress);
  }

  function myReferralDividends()
  public
  view
  returns (uint)
  {
    return myDividends(true) - myDividends(false);
  }

  function myDividends(bool _includeReferralBonus)
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function theDividendsOf(bool _includeReferralBonus, address _customerAddress)
  public
  view
  returns (uint)
  {
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function getFrontEndTokenBalanceOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return frontTokenBalanceLedger_[_customerAddress];
  }

  function balanceOf(address _owner)
  view
  public
  returns (uint)
  {
    return getFrontEndTokenBalanceOf(_owner);
  }

  function getDividendTokenBalanceOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return dividendTokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return (uint) ((int256)(profitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

   
  function sellPrice()
  public
  view
  returns (uint)
  {
    uint price;

    if (icoPhase || currentEthInvested < ethInvestedDuringICO) {
      price = tokenPriceInitial_;
    } else {

       
       
      uint tokensReceivedForEth = ethereumToTokens_(0.001 ether);

      price = (1e18 * 0.001 ether) / tokensReceivedForEth;
    }

     
    uint theSellPrice = price.sub((price.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude));

    return theSellPrice;
  }

   
  function buyPrice(uint dividendRate)
  public
  view
  returns (uint)
  {
    uint price;

    if (icoPhase || currentEthInvested < ethInvestedDuringICO) {
      price = tokenPriceInitial_;
    } else {

       
       
      uint tokensReceivedForEth = ethereumToTokens_(0.001 ether);

      price = (1e18 * 0.001 ether) / tokensReceivedForEth;
    }

     
    uint theBuyPrice = (price.mul(dividendRate).div(100)).add(price);

    return theBuyPrice;
  }

  function calculateTokensReceived(uint _ethereumToSpend)
  public
  view
  returns (uint)
  {
    uint _dividends = (_ethereumToSpend.mul(userDividendRate[msg.sender])).div(100);
    uint _taxedEthereum = _ethereumToSpend.sub(_dividends);
    uint _amountOfTokens = ethereumToTokens_(_taxedEthereum);
    return _amountOfTokens;
  }

   
   
  function calculateEthereumReceived(uint _tokensToSell)
  public
  view
  returns (uint)
  {
    require(_tokensToSell <= tokenSupply);
    uint _ethereum = tokensToEthereum_(_tokensToSell);
    uint userAverageDividendRate = getUserAverageDividendRate(msg.sender);
    uint _dividends = (_ethereum.mul(userAverageDividendRate).div(100)).div(magnitude);
    uint _taxedEthereum = _ethereum.sub(_dividends);
    return _taxedEthereum;
  }

   

  function getUserAverageDividendRate(address user) public view returns (uint) {
    return (magnitude * dividendTokenBalanceLedger_[user]).div(frontTokenBalanceLedger_[user]);
  }

  function getMyAverageDividendRate() public view returns (uint) {
    return getUserAverageDividendRate(msg.sender);
  }

   

   
  function purchaseTokens(uint _incomingEthereum, address _referredBy)
  internal
  returns (uint)
  {
    require(_incomingEthereum >= MIN_ETH_BUYIN || msg.sender == bankrollAddress, "Tried to buy below the min eth buyin threshold.");

    uint toBankRoll;
    uint toReferrer;
    uint toTokenHolders;
    uint toDivCardHolders;

    uint dividendAmount;

    uint tokensBought;
    uint dividendTokensBought;

    uint remainingEth = _incomingEthereum;

    uint fee;

     
    if (regularPhase) {
      toDivCardHolders = _incomingEthereum.div(100);
      remainingEth = remainingEth.sub(toDivCardHolders);
    }

     

     
    uint dividendRate = userDividendRate[msg.sender];

     
    dividendAmount = (remainingEth.mul(dividendRate)).div(100);

    remainingEth = remainingEth.sub(dividendAmount);

     
    if (icoPhase && msg.sender == bankrollAddress) {
      remainingEth = remainingEth + dividendAmount;
    }

     
    tokensBought = ethereumToTokens_(remainingEth);
    dividendTokensBought = tokensBought.mul(dividendRate);

     
    tokenSupply = tokenSupply.add(tokensBought);
    divTokenSupply = divTokenSupply.add(dividendTokensBought);

     

    currentEthInvested = currentEthInvested + remainingEth;

     
    if (icoPhase) {
      toBankRoll = dividendAmount;

       
       
      if (msg.sender == bankrollAddress) {
        toBankRoll = 0;
      }

      toReferrer = 0;
      toTokenHolders = 0;

       
      ethInvestedDuringICO = ethInvestedDuringICO + remainingEth;
      tokensMintedDuringICO = tokensMintedDuringICO + tokensBought;

       
      require(ethInvestedDuringICO <= icoHardCap);
       
      require(tx.origin == msg.sender || msg.sender == bankrollAddress);

       
      ICOBuyIn[msg.sender] += remainingEth;
       

       
      if (ethInvestedDuringICO == icoHardCap) {
        icoPhase = false;
      }

    } else {
       

       
       
      if (_referredBy != 0x0000000000000000000000000000000000000000 &&
      _referredBy != msg.sender &&
      frontTokenBalanceLedger_[_referredBy] >= stakingRequirement)
      {
        toReferrer = (dividendAmount.mul(referrer_percentage)).div(100);
        referralBalance_[_referredBy] += toReferrer;
        emit Referral(_referredBy, toReferrer);
      }

       
      toTokenHolders = dividendAmount.sub(toReferrer);

      fee = toTokenHolders * magnitude;
      fee = fee - (fee - (dividendTokensBought * (toTokenHolders * magnitude / (divTokenSupply))));

       
      profitPerDivToken = profitPerDivToken.add((toTokenHolders.mul(magnitude)).div(divTokenSupply));
      payoutsTo_[msg.sender] += (int256) ((profitPerDivToken * dividendTokensBought) - fee);
    }

     
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].add(tokensBought);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].add(dividendTokensBought);

     
    if (toBankRoll != 0) {ZethrBankroll(bankrollAddress).receiveDividends.value(toBankRoll)();}
    if (regularPhase) {divCardContract.receiveDividends.value(toDivCardHolders)(dividendRate);}

     
    emit Allocation(toBankRoll, toReferrer, toTokenHolders, toDivCardHolders, remainingEth);

     
    uint sum = toBankRoll + toReferrer + toTokenHolders + toDivCardHolders + remainingEth - _incomingEthereum;
    assert(sum == 0);
  }

   
  function ethereumToTokens_(uint _ethereumAmount)
  public
  view
  returns (uint)
  {
    require(_ethereumAmount > MIN_ETH_BUYIN, "Tried to buy tokens with too little eth.");

    if (icoPhase) {
      return _ethereumAmount.div(tokenPriceInitial_) * 1e18;
    }

     

     
     
     
    uint ethTowardsICOPriceTokens = 0;
    uint ethTowardsVariablePriceTokens = 0;

    if (currentEthInvested >= ethInvestedDuringICO) {
       
      ethTowardsVariablePriceTokens = _ethereumAmount;

    } else if (currentEthInvested < ethInvestedDuringICO && currentEthInvested + _ethereumAmount <= ethInvestedDuringICO) {
       
      ethTowardsICOPriceTokens = _ethereumAmount;

    } else if (currentEthInvested < ethInvestedDuringICO && currentEthInvested + _ethereumAmount > ethInvestedDuringICO) {
       
      ethTowardsICOPriceTokens = ethInvestedDuringICO.sub(currentEthInvested);
      ethTowardsVariablePriceTokens = _ethereumAmount.sub(ethTowardsICOPriceTokens);
    } else {
       
      revert();
    }

     
    assert(ethTowardsICOPriceTokens + ethTowardsVariablePriceTokens == _ethereumAmount);

     
    uint icoPriceTokens = 0;
    uint varPriceTokens = 0;

     
     
    if (ethTowardsICOPriceTokens != 0) {
      icoPriceTokens = ethTowardsICOPriceTokens.mul(1e18).div(tokenPriceInitial_);
    }

    if (ethTowardsVariablePriceTokens != 0) {
       
       
       
       

      uint simulatedEthBeforeInvested = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3) + ethTowardsICOPriceTokens;
      uint simulatedEthAfterInvested = simulatedEthBeforeInvested + ethTowardsVariablePriceTokens;

       

      uint tokensBefore = toPowerOfTwoThirds(simulatedEthBeforeInvested.mul(3).div(2)).mul(MULTIPLIER);
      uint tokensAfter = toPowerOfTwoThirds(simulatedEthAfterInvested.mul(3).div(2)).mul(MULTIPLIER);

       

      varPriceTokens = (1e6) * tokensAfter.sub(tokensBefore);
    }

    uint totalTokensReceived = icoPriceTokens + varPriceTokens;

    assert(totalTokensReceived > 0);
    return totalTokensReceived;
  }

   
  function tokensToEthereum_(uint _tokens)
  public
  view
  returns (uint)
  {
    require(_tokens >= MIN_TOKEN_SELL_AMOUNT, "Tried to sell too few tokens.");

     

     
     
     
    uint tokensToSellAtICOPrice = 0;
    uint tokensToSellAtVariablePrice = 0;

    if (tokenSupply <= tokensMintedDuringICO) {
       
      tokensToSellAtICOPrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens >= tokensMintedDuringICO) {
       
      tokensToSellAtVariablePrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens < tokensMintedDuringICO) {
       
      tokensToSellAtVariablePrice = tokenSupply.sub(tokensMintedDuringICO);
      tokensToSellAtICOPrice = _tokens.sub(tokensToSellAtVariablePrice);

    } else {
       
      revert();
    }

     
    assert(tokensToSellAtVariablePrice + tokensToSellAtICOPrice == _tokens);

     
    uint ethFromICOPriceTokens;
    uint ethFromVarPriceTokens;

     

    if (tokensToSellAtICOPrice != 0) {

       

      ethFromICOPriceTokens = tokensToSellAtICOPrice.mul(tokenPriceInitial_).div(1e18);
    }

    if (tokensToSellAtVariablePrice != 0) {

       

      uint investmentBefore = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint investmentAfter = toPowerOfThreeHalves((tokenSupply - tokensToSellAtVariablePrice).div(MULTIPLIER * 1e6)).mul(2).div(3);

      ethFromVarPriceTokens = investmentBefore.sub(investmentAfter);
    }

    uint totalEthReceived = ethFromVarPriceTokens + ethFromICOPriceTokens;

    assert(totalEthReceived > 0);
    return totalEthReceived;
  }

  function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
  internal
  {
    require(regularPhase);
    require(_toAddress != address(0x0));
    address _customerAddress = _from;
    uint _amountOfFrontEndTokens = _amountOfTokens;

     
    if (theDividendsOf(true, _customerAddress) > 0) withdrawFrom(_customerAddress);

     
     
    uint _amountOfDivTokens = _amountOfFrontEndTokens.mul(getUserAverageDividendRate(_customerAddress)).div(magnitude);

    if (_customerAddress != msg.sender) {
       
       
      allowed[_customerAddress][msg.sender] -= _amountOfTokens;
    }

     
    frontTokenBalanceLedger_[_customerAddress] = frontTokenBalanceLedger_[_customerAddress].sub(_amountOfFrontEndTokens);
    frontTokenBalanceLedger_[_toAddress] = frontTokenBalanceLedger_[_toAddress].add(_amountOfFrontEndTokens);
    dividendTokenBalanceLedger_[_customerAddress] = dividendTokenBalanceLedger_[_customerAddress].sub(_amountOfDivTokens);
    dividendTokenBalanceLedger_[_toAddress] = dividendTokenBalanceLedger_[_toAddress].add(_amountOfDivTokens);

     
    if (!userSelectedRate[_toAddress])
    {
      userSelectedRate[_toAddress] = true;
      userDividendRate[_toAddress] = userDividendRate[_customerAddress];
    }

     
    payoutsTo_[_customerAddress] -= (int256) (profitPerDivToken * _amountOfDivTokens);
    payoutsTo_[_toAddress] += (int256) (profitPerDivToken * _amountOfDivTokens);

    uint length;

    assembly {
      length := extcodesize(_toAddress)
    }

    if (length > 0) {
       
       
      ERC223Receiving receiver = ERC223Receiving(_toAddress);
      receiver.tokenFallback(_from, _amountOfTokens, _data);
    }

     
    emit Transfer(_customerAddress, _toAddress, _amountOfFrontEndTokens);
  }

   
  function withdrawFrom(address _customerAddress)
  internal
  {
     
    uint _dividends = theDividendsOf(false, _customerAddress);

     
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

     
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    _customerAddress.transfer(_dividends);

     
    emit onWithdraw(_customerAddress, _dividends);
  }


   

  function injectEther()
  public
  payable
  onlyAdministrator
  {

  }

   

  function toPowerOfThreeHalves(uint x) public pure returns (uint) {
     
     
    return sqrt(x ** 3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns (uint) {
     
     
    return cbrt(x ** 2);
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z * z) + 2 * z) / 3;
    }
  }
}

 

contract ZethrBankroll {
  function receiveDividends() public payable {}
}

 

 
contract JackpotHolding is ERC223Receiving {

   

   
  uint public payOutNumber = 0;

   
  uint public payOutDivisor = 2;

   
  ZethrBankrollControllerInterface controller;

   
  Zethr zethr;

   

  constructor (address _controllerAddress, address _zethrAddress) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    zethr = Zethr(_zethrAddress);
  }

  function() public payable {}

  function tokenFallback(address  , uint  , bytes )
  public
  returns (bool)
  {
     
  }

   
  function getJackpotBalance()
  public view
  returns (uint)
  {
     
    uint tempBalance;

    for (uint i=0; i<7; i++) {
      tempBalance += controller.tokenBankrolls(i).jackpotBalance() > 0 ? controller.tokenBankrolls(i).jackpotBalance() / payOutDivisor : 0;
    }

    tempBalance += zethr.balanceOf(address(this)) > 0 ? zethr.balanceOf(address(this)) / payOutDivisor : 0;

    return tempBalance;
  }

   

   
  function ownerSetPayOutDivisor(uint _divisor)
  public
  ownerOnly
  {
    require(_divisor != 0);

    payOutDivisor = _divisor;
  }

   
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

   
  function ownerWithdrawZth(address _to)
  public
  ownerOnly
  {
    uint balance = zethr.balanceOf(address(this));
    zethr.transfer(_to, balance);
  }

   
  function ownerWithdrawEth(address _to)
  public
  ownerOnly
  {
    _to.transfer(address(this).balance);
  }

   

  function gamePayOutWinner(address _winner)
  public
  gameOnly
  {
     
    for (uint i=0; i<7; i++) {
      controller.tokenBankrolls(i).payJackpotToWinner(_winner, payOutDivisor);
    }

    uint payOutAmount;

     
    if (zethr.balanceOf(address(this)) >= 1e10) {
      payOutAmount = zethr.balanceOf(address(this)) / payOutDivisor;
    }

    if (payOutAmount >= 1e10) {
      zethr.transfer(_winner, payOutAmount);
    }

     
    payOutNumber += 1;

     
    emit JackpotPayOut(_winner, payOutNumber);
  }

   

  event JackpotPayOut(
    address winner,
    uint payOutNumber
  );

   

   
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

   
  modifier gameOnly()
  {
    require(controller.validGameAddresses(msg.sender));
    _;
  }
}

 

 
contract ZethrGame {
  using SafeMath for uint;
  using SafeMath for uint56;

   
  event Result (address player, uint amountWagered, int amountOffset);
  event Wager (address player, uint amount, bytes data);

   
  address[] pendingBetsQueue;
  uint queueHead = 0;
  uint queueTail = 0;

   
  mapping(address => BetBase) bets;

   
  struct BetBase {
     
    uint56 tokenValue;     
    uint48 blockNumber;
    uint8 tier;
     
  }

   
   
  mapping(address => uint) pendingBetsMapping;

   
  ZethrBankrollControllerInterface controller;

   
  bool paused;

   
  uint minBet = 1e18;

   
  uint resolverPercentage;

   
  string gameName;

  constructor (address _controllerAddress, uint _resolverPercentage, string _name) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    resolverPercentage = _resolverPercentage;
    gameName = _name;
  }

   
  function getMaxProfit()
  public view
  returns (uint)
  {
    return ZethrTokenBankrollInterface(msg.sender).getMaxProfit(address(this));
  }

   
  function ownerPauseGame()
  public
  ownerOnly
  {
    paused = true;
  }

   
  function ownerResumeGame()
  public
  ownerOnly
  {
    paused = false;
  }

   
  function ownerSetResolverPercentage(uint _percentage)
  public
  ownerOnly
  {
    require(_percentage <= 1000000);
    resolverPercentage = _percentage;
  }

   
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

   
   
  function ownerSetGameName(string _name)
  ownerOnly
  public
  {
    gameName = _name;
  }

   
  function getGameName()
  public view
  returns (string)
  {
    return gameName;
  }

   
  function resolveExpiredBets(uint _numToResolve)
  public
  returns (uint tokensEarned_, uint queueHead_)
  {
    uint mQueue = queueHead;
    uint head;
    uint tail = (mQueue + _numToResolve) > pendingBetsQueue.length ? pendingBetsQueue.length : (mQueue + _numToResolve);
    uint tokensEarned = 0;

    for (head = mQueue; head < tail; head++) {
       
       
       
      if (pendingBetsQueue[head] == address(0x0)) {
        continue;
      }

      if (bets[pendingBetsQueue[head]].blockNumber != 0 && block.number > 256 + bets[pendingBetsQueue[head]].blockNumber) {
         
         
         
         
        int sum = - finishBetFrom(pendingBetsQueue[head]);

         
        if (sum > 0) {
          tokensEarned += (uint(sum).mul(resolverPercentage)).div(1000000);
        }

         
      } else {
         
        break;
      }
    }

    queueHead = head;

     
    if (tokensEarned >= 1e14) {
      controller.gamePayoutResolver(msg.sender, tokensEarned);
    }

    return (tokensEarned, head);
  }

   
  function finishBet()
  public
  hasNotBetThisBlock(msg.sender)
  returns (int)
  {
    return finishBetFrom(msg.sender);
  }

   
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

   
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

   
  modifier hasNotBetThisBlock(address _sender)
  {
    require(bets[_sender].blockNumber != block.number);
    _;
  }

   
  modifier bankrollOnly {
    require(controller.isTokenBankroll(msg.sender));
    _;
  }

   
  modifier isNotPaused {
    require(!paused);
    _;
  }

   
  modifier betIsValid(uint _betSize, uint _tier, bytes _data) {
    uint divRate = ZethrTierLibrary.getDivRate(_tier);
    require(isBetValid(_betSize, divRate, _data));
    _;
  }

   
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

   
  function execute(address _player, uint _tokenCount, uint _divRate, bytes _data) public;

   
  function finishBetFrom(address _playerAddress) internal returns (int);

   
  function isBetValid(uint _tokenCount, uint _divRate, bytes _data) public view returns (bool);
}

 

 
contract ZethrBigWheel is ZethrGame {
  using SafeMath for uint8;

   

   
  struct Bet {
     
    uint56 tokenValue;
    uint48 blockNumber;
    uint8 tier;
     
    uint bets;  
  }

   

   
  JackpotHolding public jackpotHoldingContract;

   

  constructor (address _controllerAddress, uint _resolverPercentage, string _name)
  ZethrGame(_controllerAddress, _resolverPercentage, _name)
  public
  {
  }

   

   
  function getLastSpinOutput(address _playerAddress)
  public view
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins, uint output)
  {
     
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

     
    require(playerBet.blockNumber != 0);

    (winAmount, lossAmount, jackpotAmount, jackpotWins, output) = getSpinOutput(playerBet.blockNumber, _playerAddress, playerBet.bets);

    return (winAmount, lossAmount, jackpotAmount, jackpotWins, output);
  }

  event WheelResult(
    uint _blockNumber,
    address _target,
    uint40[5] _bets,
    uint _winAmount,
    uint _lossAmount,
    uint _winCategory
  );

   
  function getSpinOutput(uint _blockNumber, address _target, uint _bets_notconverted)
  public view
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins, uint output)
  {
    uint40[5] memory _bets = uintToBetsArray(_bets_notconverted);
     
    uint result;
    if (block.number - _blockNumber > 255) {
       
      result = 999997;
    } else {
       
      result = random(999996, _blockNumber, _target, 0) + 1;
    }

    uint[5] memory betsMul;
    betsMul[0] = uint(_bets[0]).mul(1e14);
    betsMul[1] = uint(_bets[1]).mul(1e14);
    betsMul[2] = uint(_bets[2]).mul(1e14);
    betsMul[3] = uint(_bets[3]).mul(1e14);
    betsMul[4] = uint(_bets[4]).mul(1e14);

    lossAmount = betsMul[0] + betsMul[1] + betsMul[2] + betsMul[3] + betsMul[4];

     
     
     
     
     
     
     

    uint _winCategory = 0;
    
    if (result < 2) {
      jackpotWins++;
      _winCategory = 99;
    } else {
      if (result < 27028) {
        if (betsMul[4] > 0) {
           
          _winCategory = 25;
          winAmount = SafeMath.mul(betsMul[4], 25);
          lossAmount -= betsMul[4];
        }
      } else if (result < 108108) {
        if (betsMul[3] > 0) {
           
          _winCategory = 10;
          winAmount = SafeMath.mul(betsMul[3], 10);
          lossAmount -= betsMul[3];
        }
      } else if (result < 270269) {
        if (betsMul[2] > 0) {
           
          _winCategory = 6;
          winAmount = SafeMath.mul(betsMul[2], 6);
          lossAmount -= betsMul[2];
        }
      } else if (result < 513512) {
        if (betsMul[1] > 0) {
           
          _winCategory = 4;
          winAmount = SafeMath.mul(betsMul[1], 4);
          lossAmount -= betsMul[1];
        }
      } else if (result < 999997) {
        if (betsMul[0] > 0) {
           
          _winCategory = 2;
          winAmount = SafeMath.mul(betsMul[0], 2);
          lossAmount -= betsMul[0];
        }
      }

      jackpotAmount = lossAmount.div(100);
      lossAmount -= jackpotAmount;
    }
    emit WheelResult(_blockNumber, _target, _bets, winAmount, lossAmount, _winCategory);
    return (winAmount, lossAmount, jackpotAmount, jackpotWins, result);
  }

   
  function getSpinResults(uint _blockNumber, address _target, uint _bets)
  public
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins)
  {
    (winAmount, lossAmount, jackpotAmount, jackpotWins,) = getSpinOutput(_blockNumber, _target, _bets);
  }

   

   
  function ownerSetJackpotAddress(address _jackpotAddress)
  public
  ownerOnly
  {
    jackpotHoldingContract = JackpotHolding(_jackpotAddress);
  }

   

   
  function getBet(address _playerAddress)
  internal view
  returns (Bet storage)
  {
     
    BetBase storage betBase = bets[_playerAddress];

    Bet storage playerBet;
    assembly {
     
      let tmp := betBase_slot

     
      swap1
    }
     

     
    return playerBet;
  }

   
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

   
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

   

   
  function finishBetFrom(address _playerAddress)
  internal
  returns (int  )
  {
     
    uint winAmount;
    uint lossAmount;
    uint jackpotAmount;
    uint jackpotWins;

     
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

     
    require(playerBet.blockNumber != 0);

     
    require(playerBet.blockNumber != 0);
    playerBetInStorage.blockNumber = 0;

     
     
     
     
    (winAmount, lossAmount, jackpotAmount, jackpotWins) = getSpinResults(playerBet.blockNumber, _playerAddress, playerBet.bets);

     
    address tokenBankrollAddress = controller.getTokenBankrollAddressFromTier(playerBet.tier);
    ZethrTokenBankrollInterface bankroll = ZethrTokenBankrollInterface(tokenBankrollAddress);

     
    bankroll.gameTokenResolution(winAmount, _playerAddress, jackpotAmount, address(jackpotHoldingContract), playerBet.tokenValue.mul(1e14));

     
    if (jackpotWins > 0) {
      for (uint x = 0; x < jackpotWins; x++) {
        jackpotHoldingContract.gamePayOutWinner(_playerAddress);
      }
    }

     
    uint index = pendingBetsMapping[_playerAddress];

     
    pendingBetsQueue[index] = address(0x0);

     
    pendingBetsMapping[_playerAddress] = 0;

    emit Result(_playerAddress, playerBet.tokenValue.mul(1e14), int(winAmount) - int(lossAmount) - int(jackpotAmount));

     
    return (int(winAmount) - int(lossAmount) - int(jackpotAmount));
  }

   
  function execute(address _player, uint _tokenCount, uint _tier, bytes _data)
  isNotPaused
  bankrollOnly
  betIsValid(_tokenCount, _tier, _data)
  hasNotBetThisBlock(_player)
  public
  {
    Bet storage playerBet = getBet(_player);

     
    if (playerBet.blockNumber != 0) {
      finishBetFrom(_player);
    }

     
    playerBet.tokenValue = uint56(_tokenCount.div(1e14));
    playerBet.blockNumber = uint48(block.number);
    playerBet.tier = uint8(_tier);
    
    require(_data.length == 32);
    
    uint actual_data;
    
    assembly{
        actual_data := mload(add(_data, 0x20))
    }
    
    playerBet.bets = actual_data;

    uint40[5] memory actual_bets = uintToBetsArray(actual_data);

     
    require((uint(actual_bets[0]) + uint(actual_bets[1]) + uint(actual_bets[2]) + uint(actual_bets[3]) + uint(actual_bets[4])).mul(1e14) == _tokenCount);

     
    pendingBetsQueue.length++;
    pendingBetsQueue[queueTail] = _player;
    queueTail++;

     
    pendingBetsMapping[_player] = queueTail - 1;

     
    emit Wager(_player, _tokenCount, _data);
  }

   
  function isBetValid(uint  , uint  , bytes _data)
  public view
  returns (bool)
  {
    uint actual_data;
    
    assembly{
        actual_data := mload(add(_data, 0x20))
    }

    uint40[5] memory bets = uintToBetsArray(actual_data);
    uint bet2Max = bets[0] * 2;
    uint bet4Max = bets[1] * 4;
    uint bet6Max = bets[2] * 6;
    uint bet10Max = bets[3] * 10;
    uint bet25Max = bets[4] * 25;

    uint max = bet2Max;

    if (bet4Max > max) {
      max = bet4Max;
    }

    if (bet6Max > max) {
      max = bet6Max;
    }

    if (bet10Max > max) {
      max = bet10Max;
    }

    if (bet25Max > max) {
      max = bet25Max;
    }

    uint minBetDiv = minBet.div(1e14);

    return (max*1e14 <= getMaxProfit())
    && ((bets[0]) >= minBetDiv || (bets[0]) == 0)
    && ((bets[1]) >= minBetDiv || (bets[1]) == 0)
    && ((bets[2]) >= minBetDiv || (bets[2]) == 0)
    && ((bets[3]) >= minBetDiv || (bets[3]) == 0)
    && ((bets[4]) >= minBetDiv || (bets[4]) == 0);
  }
  
  
  function betInputToBytes(uint40 bet1, uint40 bet2, uint40 bet3, uint40 bet4, uint40 bet5) pure public returns (bytes32){
    bytes memory concat = (abi.encodePacked(uint56(0), bet1, bet2, bet3, bet4, bet5));
    bytes32 output;
        
    assembly{
      output := mload(add(concat, 0x20))
    }
    return output;
  }
  
  function uintToBetsArray(uint input) public view returns (uint40[5]){
    uint40[5] memory output;
    uint trackme = (input);
    for (uint i=4;; i--){
      output[i] = uint40(trackme);  
      trackme /= 0x0000000000000000000000000000000000000000000000000000010000000000;  
      if (i==0){
        break;
      }
    }
    return output;     
  }
  
  function getPlayerBetData(address player) public view returns(uint40[5]){
      uint betData = getBet(player).bets;
      return (uintToBetsArray(betData));
  }
}