 

pragma solidity ^0.4.16;



contract TokenERC20 {

   
   
  mapping (address => bool) public owners;

   
  bool public nextActionIsAuthorised = false;
  address public actionAuthorisedBy;
   
  bool public requireAuthorisation = true;



  function isOwner(address addressToCheck) view public returns (bool) {
    return owners[addressToCheck];
  }



  modifier onlyOwners {
    require(isOwner(msg.sender));
    if (requireAuthorisation) {
      checkActionIsAuthorisedAndReset();
    }
    _;
  }



  function authoriseNextAction() public {
    require(isOwner(msg.sender));
    require(requireAuthorisation);
    require(!nextActionIsAuthorised);
    nextActionIsAuthorised = true;
    actionAuthorisedBy = msg.sender;
  }



  function checkActionIsAuthorisedAndReset() public {
    require(isOwner(msg.sender));
    bool isValidAuthorisationRequest = (nextActionIsAuthorised && actionAuthorisedBy != msg.sender);
    require(isValidAuthorisationRequest);
    nextActionIsAuthorised = false;
  }



  function setRequireAuthorisation(bool _requireAuthorisation) onlyOwners public {
    requireAuthorisation = _requireAuthorisation;
  }
   


   
  bool public tokenInitialised = false;
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;
  uint256 public sellPrice;
  address public currentSeller;

   
  bool public allowTransfers = false;  
  bool public allowBurns = false;      
  bool public allowBuying = false;     

   
  mapping (address => uint256) public balanceOf;     
  mapping (address => uint256) public etherSpent;    
  mapping (address => bool) public frozenAccounts;   
  address[] investors;
  uint64 public investorCount;



   

   
  uint256 constant public weekLength = 60 * 60 * 24 * 7;
  uint256 constant public monthLength = 2627856;  
  uint256 constant public yearLength = 60 * 60 * 24 * 7 * 52;

  uint256 public icoBeginDate;
  uint256 public icoEndDate;
  bool public icoParametersSet = false;

  uint256 public tokensSoldAtIco = 0;
  uint256 public minimumTokenThreshold;
  bool public etherHasBeenReturnedToInvestors = false;
  uint256 public softCap;
  uint256 public runTimeAfterSoftCapReached;
  uint256 public dateSoftCapWasReached = 0;

  uint256 public maxFundsThatCanBeWithdrawnByOwners = 0;
  uint256 public fundsWithdrawnByOwners = 0;

  uint8 immediateAllowancePercentage;
  uint8 firstYearAllowancePercentage;
  uint8 secondYearAllowancePercentage;

  mapping (uint8 => uint8) public weekBonuses;  



  modifier onlyWhenIcoParametersAreSet {
    require(icoParametersSet);
    _;
  }



  modifier onlyWhenIcoParametersAreNotSet {
    require(!icoParametersSet);
    _;
  }



  modifier onlyDuringIco {
    require(icoParametersSet);
    updateContract();
    require(isIcoRunning());
    _;
  }
   



   
  function setIcoParametersSet(bool set) onlyWhenIcoParametersAreNotSet onlyOwners public {
    icoParametersSet = set;
  }



  function setIcoBeginDate(uint256 beginDate) onlyWhenIcoParametersAreNotSet onlyOwners public {
    icoBeginDate = beginDate;
  }



  function setIcoEndDate (uint256 endDate) onlyWhenIcoParametersAreNotSet onlyOwners public {
    icoEndDate = endDate;
  }



  function setSoftCap (uint256 cap) onlyWhenIcoParametersAreNotSet onlyOwners public {
    softCap = cap;
  }



  function setRunTimeAfterSoftCapReached (uint256 runTime) onlyWhenIcoParametersAreNotSet onlyOwners public {
    runTimeAfterSoftCapReached = runTime;
  }



  function setImmediateAllowancePercentage(uint8 allowancePercentage) onlyWhenIcoParametersAreNotSet onlyOwners public {
    immediateAllowancePercentage = allowancePercentage;
  }



  function setFirstYearAllowancePercentage(uint8 allowancePercentage) onlyWhenIcoParametersAreNotSet onlyOwners public {
    firstYearAllowancePercentage = allowancePercentage;
  }



  function setSecondYearAllowancePercentage(uint8 allowancePercentage) onlyWhenIcoParametersAreNotSet onlyOwners public {
    secondYearAllowancePercentage = allowancePercentage;
  }



  function initialiseToken() public {
    require(!tokenInitialised);
    name = "BaraToken";
    symbol = "BRT";
    totalSupply = 160000000 * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
    currentSeller = msg.sender;
    owners[msg.sender] = true;
    owners[0x1434e028b12D196AcBE5304A94d0a5F816eb5d55] = true;
    tokenInitialised = true;
  }



  function() payable public {
    buyTokens();
  }



  function updateContract() onlyWhenIcoParametersAreSet public {
    if (hasSoftCapBeenReached() && dateSoftCapWasReached == 0) {
      dateSoftCapWasReached = now;
      bool reachingSoftCapWillExtendIco = (dateSoftCapWasReached + runTimeAfterSoftCapReached > icoEndDate);
      if (!reachingSoftCapWillExtendIco)
        icoEndDate = dateSoftCapWasReached + runTimeAfterSoftCapReached;
    }
    if (!isBeforeIco())
      updateOwnersWithdrawAllowance();
  }



  function isBeforeIco() onlyWhenIcoParametersAreSet internal view returns (bool) {
    return (now <= icoBeginDate);
  }



  function isIcoRunning() onlyWhenIcoParametersAreSet internal view returns (bool) {
    bool reachingSoftCapWillExtendIco = (dateSoftCapWasReached + runTimeAfterSoftCapReached) > icoEndDate;
    bool afterBeginDate = now > icoBeginDate;
    bool beforeEndDate = now < icoEndDate;
    if (hasSoftCapBeenReached() && !reachingSoftCapWillExtendIco)
      beforeEndDate = now < (dateSoftCapWasReached + runTimeAfterSoftCapReached);
    bool running = afterBeginDate && beforeEndDate;
    return running;
  }



  function isAfterIco() onlyWhenIcoParametersAreSet internal view returns (bool) {
    return (now > icoEndDate);
  }




  function hasSoftCapBeenReached() onlyWhenIcoParametersAreSet internal view returns (bool) {
    return (tokensSoldAtIco >= softCap && softCap != 0);
  }



   
   
  function getWeekBonus(uint256 amountPurchased) onlyWhenIcoParametersAreSet internal view returns (uint256) {
    uint256 weekBonus = uint256(weekBonuses[getWeeksPassedSinceStartOfIco()]);
    if (weekBonus != 0)
      return (amountPurchased * weekBonus) / 100;
    return amountPurchased;
  }



  function getTimeSinceEndOfIco() onlyWhenIcoParametersAreSet internal view returns (uint256) {
    require(now > icoEndDate);
    uint256 timeSinceEndOfIco = now - icoEndDate;
    return timeSinceEndOfIco;
  }



  function getWeeksPassedSinceStartOfIco() onlyWhenIcoParametersAreSet internal view returns (uint8) {
    require(!isBeforeIco());
    uint256 timeSinceIco = now - icoBeginDate;
    uint8 weeksPassedSinceIco = uint8(timeSinceIco / weekLength);
    return weeksPassedSinceIco;
  }



   
   
  function updateOwnersWithdrawAllowance() onlyWhenIcoParametersAreSet internal {
    if (isAfterIco()) {
      uint256 totalFunds = this.balance;
      maxFundsThatCanBeWithdrawnByOwners = 0;
      uint256 immediateAllowance = (totalFunds * immediateAllowancePercentage) / 100;
      bool secondYear = now - icoEndDate >= yearLength;
      uint8 monthsPassedSinceIco = getMonthsPassedEndOfSinceIco();
      if (secondYear) {
        uint256 monthsPassedInSecondYear = monthsPassedSinceIco - 12;
         
         
         
         
         
        uint256 secondYearAllowance = ((totalFunds * secondYearAllowancePercentage * monthsPassedInSecondYear) / 1200);
      }
      uint8 monthsPassedInFirstYear = monthsPassedSinceIco;
      if (secondYear)
        monthsPassedInFirstYear = 12;
      uint256 firstYearAllowance = ((totalFunds * firstYearAllowancePercentage * monthsPassedInFirstYear) / 1200);
      maxFundsThatCanBeWithdrawnByOwners = immediateAllowance + firstYearAllowance + secondYearAllowance;
    }
  }



  function getMonthsPassedEndOfSinceIco() onlyWhenIcoParametersAreSet internal view returns (uint8) {
    uint256 timePassedSinceIco = now - icoEndDate;
    uint8 monthsPassedSinceIco = uint8(timePassedSinceIco / weekLength);
    return monthsPassedSinceIco + 1;
  }



   
  function amountIsWithinOwnersAllowance(uint256 amountToWithdraw) internal view returns (bool) {
    if (now - icoEndDate >= yearLength * 2)
      return true;
    uint256 totalFundsWithdrawnAfterThisTransaction = fundsWithdrawnByOwners + amountToWithdraw;
    bool withinAllowance = totalFundsWithdrawnAfterThisTransaction <= maxFundsThatCanBeWithdrawnByOwners;
    return withinAllowance;
  }



  function buyTokens() onlyDuringIco payable public {
    require(allowBuying);
    require(!frozenAccounts[msg.sender]);
    require(msg.value > 0);
    uint256 numberOfTokensPurchased = msg.value / sellPrice;
    require(numberOfTokensPurchased >= 10 ** 6);
    numberOfTokensPurchased = getWeekBonus(numberOfTokensPurchased);
    _transfer(currentSeller, msg.sender, numberOfTokensPurchased);
    tokensSoldAtIco += numberOfTokensPurchased;
    if (!(etherSpent[msg.sender] > 0)) {
      investors[investorCount] = msg.sender;
      investorCount++;
    }
    etherSpent[msg.sender] += msg.value;
  }



   
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed from, uint256 value);
  event FrozenFunds(address target, bool frozen);
  event NewSellPrice(uint256 _sellPrice);



  function setTokenName(string tokenName) onlyOwners public {
    name = tokenName;
  }



  function setTokenSymbol(string tokenSymbol) onlyOwners public {
    symbol = tokenSymbol;
  }



  function setAllowTransfers(bool allow) onlyOwners public {
    allowTransfers = allow;
  }



  function setAllowBurns(bool allow) onlyOwners public {
    allowBurns = allow;
  }



  function setAllowBuying(bool allow) onlyOwners public {
    allowBuying = allow;
  }



  function setSellPrice(uint256 _sellPrice) onlyOwners public {
    sellPrice = _sellPrice;
    NewSellPrice(_sellPrice);
  }



  function setCurrentSeller(address newSeller) onlyOwners public {
    currentSeller = newSeller;
  }



  function ownersTransfer(address _to, uint256 _amount) onlyOwners public {
    _transfer(msg.sender, _to, _amount);
  }



  function transfer(address _to, uint256 _value) public {
    require(allowTransfers && !isOwner(msg.sender));
    _transfer(msg.sender, _to, _value);
  }



  function _transfer(address _from, address _to, uint _value) internal {
    require (_to != 0x0);
    require (balanceOf[_from] >= _value);
    require (balanceOf[_to] + _value > balanceOf[_to]);
    require(!frozenAccounts[_from]);
    require(!frozenAccounts[_to]);
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    Transfer(_from, _to, _value);
  }



  function mintToken(address target, uint256 mintedAmount) onlyOwners public {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }



  function burn(uint256 amount) public {
    require(allowBurns && !isOwner(msg.sender));
    require(balanceOf[msg.sender] >= amount);
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    Burn(msg.sender, amount);
  }



  function burnFrom(address from, uint256 amount) onlyOwners public {
    require (balanceOf[from] >= amount);
    balanceOf[from] -= amount;
    totalSupply -= amount;
    Burn(from, amount);
  }



  function freezeAccount(address target, bool freeze) onlyOwners public {
    frozenAccounts[target] = freeze;
    FrozenFunds(target, freeze);
  }



  function addOwner(address owner) onlyOwners public {
    owners[owner] = true;
  }



  function removeOwner(address owner) onlyOwners public {
    owners[owner] = false;
  }



  function sendContractFundsToAddress(uint256 amount, address recipient) onlyOwners public {
    require(icoParametersSet);
    require(isAfterIco());
    require(tokensSoldAtIco >= minimumTokenThreshold);
    require(amount <= this.balance);
    updateContract();
    require(amountIsWithinOwnersAllowance(amount));
    recipient.transfer(amount);
  }



  function returnEtherToInvestors() onlyOwners onlyWhenIcoParametersAreSet public {
    require(isAfterIco());
    require(!etherHasBeenReturnedToInvestors);
    require(tokensSoldAtIco < minimumTokenThreshold);
    for (uint64 investorNumber; investorNumber < investorCount; investorNumber++) {
      address investor = investors[investorNumber];
      uint256 amountToSend = etherSpent[investor];
      investor.transfer(amountToSend);
    }
    etherHasBeenReturnedToInvestors = true;
  }



  function getContractBalance() public view returns (uint256) {
    return this.balance;
  }




}