 

pragma solidity ^0.4.15;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract OpportyToken is StandardToken {

  string public constant name = "OpportyToken";
  string public constant symbol = "OPP";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

   
  function OpportyToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract HoldPresaleContract is Ownable {
  using SafeMath for uint256;
   
  OpportyToken public OppToken;
  address private presaleCont;

  struct Holder {
    bool isActive;
    uint tokens;
    uint8 holdPeriod;
    uint holdPeriodTimestamp;
    bool withdrawed;
  }

  mapping(address => Holder) public holderList;
  mapping(uint => address) private holderIndexes;

  mapping (uint => address) private assetOwners;
  mapping (address => uint) private assetOwnersIndex;
  uint public assetOwnersIndexes;

  uint private holderIndex;

  event TokensTransfered(address contributor , uint amount);
  event Hold(address sender, address contributor, uint amount, uint8 holdPeriod);

  modifier onlyAssetsOwners() {
    require(assetOwnersIndex[msg.sender] > 0);
    _;
  }

   
  function HoldPresaleContract(address _OppToken) {
    OppToken = OpportyToken(_OppToken);
  }

  function setPresaleCont(address pres)  public onlyOwner
  {
    presaleCont = pres;
  }

  function addHolder(address holder, uint tokens, uint8 timed, uint timest) onlyAssetsOwners external {
    if (holderList[holder].isActive == false) {
      holderList[holder].isActive = true;
      holderList[holder].tokens = tokens;
      holderList[holder].holdPeriod = timed;
      holderList[holder].holdPeriodTimestamp = timest;
      holderIndexes[holderIndex] = holder;
      holderIndex++;
    } else {
      holderList[holder].tokens += tokens;
      holderList[holder].holdPeriod = timed;
      holderList[holder].holdPeriodTimestamp = timest;
    }
    Hold(msg.sender, holder, tokens, timed);
  }

  function getBalance() constant returns (uint) {
    return OppToken.balanceOf(this);
  }

  function unlockTokens() external {
    address contributor = msg.sender;

    if (holderList[contributor].isActive && !holderList[contributor].withdrawed) {
      if (now >= holderList[contributor].holdPeriodTimestamp) {
        if ( OppToken.transfer( msg.sender, holderList[contributor].tokens ) ) {
          holderList[contributor].withdrawed = true;
          TokensTransfered(contributor,  holderList[contributor].tokens);
        }
      } else {
        revert();
      }
    } else {
      revert();
    }
  }

  function addAssetsOwner(address _owner) public onlyOwner {
    assetOwnersIndexes++;
    assetOwners[assetOwnersIndexes] = _owner;
    assetOwnersIndex[_owner] = assetOwnersIndexes;
  }
  function removeAssetsOwner(address _owner) public onlyOwner {
    uint index = assetOwnersIndex[_owner];
    delete assetOwnersIndex[_owner];
    delete assetOwners[index];
    assetOwnersIndexes--;
  }
  function getAssetsOwners(uint _index) onlyOwner public constant returns (address) {
    return assetOwners[_index];
  }
}

contract OpportyPresale is Pausable {
  using SafeMath for uint256;

  OpportyToken public token;

  HoldPresaleContract public holdContract;

  enum SaleState  { NEW, SALE, ENDED }
  SaleState public state;

  uint public endDate;
  uint public endSaleDate;

   
  address private wallet;

   
  uint public ethRaised;

  uint private price;

  uint public tokenRaised;
  bool public tokensTransferredToHold;

   
  event SaleStarted(uint blockNumber);
  event SaleEnded(uint blockNumber);
  event FundTransfered(address contrib, uint amount);
  event WithdrawedEthToWallet(uint amount);
  event ManualChangeEndDate(uint beforeDate, uint afterDate);
  event TokensTransferedToHold(address hold, uint amount);
  event AddedToWhiteList(address inv, uint amount, uint8 holdPeriod, uint8 bonus);
  event AddedToHolder( address sender, uint tokenAmount, uint8 holdPeriod, uint holdTimestamp);

  struct WhitelistContributor {
    bool isActive;
    uint invAmount;
    uint8 holdPeriod;
    uint holdTimestamp;
    uint8 bonus;
    bool payed;
  }

  mapping(address => WhitelistContributor) public whiteList;
  mapping(uint => address) private whitelistIndexes;
  uint private whitelistIndex;

   
  function OpportyPresale(
    address tokenAddress,
    address walletAddress,
    uint end,
    uint endSale,
    address holdCont )
  {
    token = OpportyToken(tokenAddress);
    state = SaleState.NEW;

    endDate     = end;
    endSaleDate = endSale;
    price       = 0.0002 * 1 ether;
    wallet      = walletAddress;

    holdContract = HoldPresaleContract(holdCont);
  }

  function startPresale() public onlyOwner {
    require(state == SaleState.NEW);
    state = SaleState.SALE;
    SaleStarted(block.number);
  }

  function endPresale() public onlyOwner {
    require(state == SaleState.SALE);
    state = SaleState.ENDED;
    SaleEnded(block.number);
  }

  function addToWhitelist(address inv, uint amount, uint8 holdPeriod, uint8 bonus) public onlyOwner {
    require(state == SaleState.NEW || state == SaleState.SALE);
    require(holdPeriod == 1 || holdPeriod == 3 || holdPeriod == 6 || holdPeriod == 12);

    amount = amount * (10 ** 18);

    if (whiteList[inv].isActive == false) {
      whiteList[inv].isActive = true;
      whiteList[inv].payed    = false;
      whitelistIndexes[whitelistIndex] = inv;
      whitelistIndex++;
    }

    whiteList[inv].invAmount  = amount;
    whiteList[inv].holdPeriod = holdPeriod;
    whiteList[inv].bonus = bonus;

    if (whiteList[inv].holdPeriod==1)  whiteList[inv].holdTimestamp = endSaleDate.add(30 days); else
    if (whiteList[inv].holdPeriod==3)  whiteList[inv].holdTimestamp = endSaleDate.add(92 days); else
    if (whiteList[inv].holdPeriod==6)  whiteList[inv].holdTimestamp = endSaleDate.add(182 days); else
    if (whiteList[inv].holdPeriod==12) whiteList[inv].holdTimestamp = endSaleDate.add(1 years);

    AddedToWhiteList(inv, whiteList[inv].invAmount, whiteList[inv].holdPeriod,  whiteList[inv].bonus);
  }

  function() whenNotPaused public payable {
    require(state == SaleState.SALE);
    require(msg.value >= 0.3 ether);
    require(whiteList[msg.sender].isActive);

    if (now > endDate) {
      state = SaleState.ENDED;
      msg.sender.transfer(msg.value);
      return ;
    }

    WhitelistContributor memory contrib = whiteList[msg.sender];
    require(contrib.invAmount <= msg.value || contrib.payed);

    if(whiteList[msg.sender].payed == false) {
      whiteList[msg.sender].payed = true;
    }

    ethRaised += msg.value;

    uint tokenAmount  = msg.value.div(price);
    tokenAmount += tokenAmount.mul(contrib.bonus).div(100);
    tokenAmount *= 10 ** 18;

    tokenRaised += tokenAmount;

    holdContract.addHolder(msg.sender, tokenAmount, contrib.holdPeriod, contrib.holdTimestamp);
    AddedToHolder(msg.sender, tokenAmount, contrib.holdPeriod, contrib.holdTimestamp);
    FundTransfered(msg.sender, msg.value);
  }

  function getBalanceContract() internal returns (uint) {
    return token.balanceOf(this);
  }

  function sendTokensToHold() public onlyOwner {
    require(state == SaleState.ENDED);

    require(getBalanceContract() >= tokenRaised);

    if (token.transfer(holdContract, tokenRaised )) {
      tokensTransferredToHold = true;
      TokensTransferedToHold(holdContract, tokenRaised );
    }
  }

  function getTokensBack() public onlyOwner {
    require(state == SaleState.ENDED);
    require(tokensTransferredToHold == true);
    uint balance;
    balance = getBalanceContract() ;
    token.transfer(msg.sender, balance);
  }

  function withdrawEth() {
    require(this.balance != 0);
    require(state == SaleState.ENDED);
    require(msg.sender == wallet);
    require(tokensTransferredToHold == true);
    uint bal = this.balance;
    wallet.transfer(bal);
    WithdrawedEthToWallet(bal);
  }

  function setEndSaleDate(uint date) public onlyOwner {
    require(state == SaleState.NEW);
    require(date > now);
    uint oldEndDate = endSaleDate;
    endSaleDate = date;
    ManualChangeEndDate(oldEndDate, date);
  }

  function setEndDate(uint date) public onlyOwner {
    require(state == SaleState.NEW || state == SaleState.SALE);
    require(date > now);
    uint oldEndDate = endDate;
    endDate = date;
    ManualChangeEndDate(oldEndDate, date);
  }

  function getTokenBalance() constant returns (uint) {
    return token.balanceOf(this);
  }

  function getEthRaised() constant external returns (uint) {
    return ethRaised;
  }
}



contract OpportySaleBonus is Ownable {
  using SafeMath for uint256;

  uint private startDate;

   
  uint private firstBonusPhase;
  uint private firstExtraBonus;
  uint private secondBonusPhase;
  uint private secondExtraBonus;
  uint private thirdBonusPhase;
  uint private thirdExtraBonus;
  uint private fourBonusPhase;
  uint private fourExtraBonus;
  uint private fifthBonusPhase;
  uint private fifthExtraBonus;
  uint private sixthBonusPhase;
  uint private sixthExtraBonus;

   
  function OpportySaleBonus(uint _startDate) {
    startDate = _startDate;

    firstBonusPhase   = startDate.add(1 days);
    firstExtraBonus   = 20;
    secondBonusPhase  = startDate.add(4 days);
    secondExtraBonus  = 15;
    thirdBonusPhase   = startDate.add(9 days);
    thirdExtraBonus   = 12;
    fourBonusPhase    = startDate.add(14 days);
    fourExtraBonus    = 10;
    fifthBonusPhase   = startDate.add(19 days);
    fifthExtraBonus   = 8;
    sixthBonusPhase   = startDate.add(24 days);
    sixthExtraBonus   = 5;
  }

   
  function calculateBonusForHours(uint256 _tokens) returns(uint256) {
    if (now >= startDate && now <= firstBonusPhase ) {
      return _tokens.mul(firstExtraBonus).div(100);
    } else
    if (now <= secondBonusPhase ) {
      return _tokens.mul(secondExtraBonus).div(100);
    } else
    if (now <= thirdBonusPhase ) {
      return _tokens.mul(thirdExtraBonus).div(100);
    } else
    if (now <= fourBonusPhase ) {
      return _tokens.mul(fourExtraBonus).div(100);
    } else
    if (now <= fifthBonusPhase ) {
      return _tokens.mul(fifthExtraBonus).div(100);
    } else
    if (now <= sixthBonusPhase ) {
      return _tokens.mul(sixthExtraBonus).div(100);
    } else
    return 0;
  }

  function changeStartDate(uint _date) onlyOwner {
    startDate = _date;
    firstBonusPhase   = startDate.add(1 days);
    secondBonusPhase  = startDate.add(4 days);
    thirdBonusPhase   = startDate.add(9 days);
    fourBonusPhase    = startDate.add(14 days);
    fifthBonusPhase   = startDate.add(19 days);
    sixthBonusPhase   = startDate.add(24 days);
  }

   
  function getBonus() public constant returns (uint) {
    if (now >= startDate && now <= firstBonusPhase ) {
      return firstExtraBonus;
    } else
    if ( now <= secondBonusPhase ) {
      return secondExtraBonus;
    } else
    if ( now <= thirdBonusPhase ) {
      return thirdExtraBonus;
    } else
    if ( now <= fourBonusPhase ) {
      return fourExtraBonus;
    } else
    if ( now <= fifthBonusPhase ) {
      return fifthExtraBonus;
    } else
    if ( now <= sixthBonusPhase ) {
      return sixthExtraBonus;
    } else
    return 0;
  }

}

contract OpportySale is Pausable {

  using SafeMath for uint256;

  OpportyToken public token;

   
  uint private SOFTCAP;
   
  uint private HARDCAP;

   
  uint private startDate;
  uint private endDate;

  uint private price;

   
  uint private ethRaised;
   
  uint private totalTokens;
   
  uint private withdrawedTokens;
   
  uint private minimalContribution;

  bool releasedTokens;

   
  address public wallet;
   
  HoldPresaleContract public holdContract;
  OpportyPresale private presale;
  OpportySaleBonus private bonus;

   
  uint private minimumTokensToStart = 150000000 * (10 ** 18);

  struct ContributorData {
    bool isActive;
    uint contributionAmount; 
    uint tokensIssued; 
    uint bonusAmount; 
  }

  enum SaleState  { NEW, SALE, ENDED }
  SaleState private state;

  mapping(address => ContributorData) public contributorList;
  uint private nextContributorIndex;
  uint private nextContributorToClaim;
  uint private nextContributorToTransferTokens;

  mapping(uint => address) private contributorIndexes;
  mapping(address => bool) private hasClaimedEthWhenFail;  
  mapping(address => bool) private hasWithdrawedTokens;  

   
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event SoftCapReached(uint blockNumber);
  event HardCapReached(uint blockNumber);
  event FundTransfered(address contrib, uint amount);
  event TokensTransfered(address contributor , uint amount);
  event Refunded(address ref, uint amount);
  event ErrorSendingETH(address to, uint amount);
  event WithdrawedEthToWallet(uint amount);
  event ManualChangeStartDate(uint beforeDate, uint afterDate);
  event ManualChangeEndDate(uint beforeDate, uint afterDate);
  event TokensTransferedToHold(address hold, uint amount);
  event TokensTransferedToOwner(address hold, uint amount);

  function OpportySale(
    address tokenAddress,
    address walletAddress,
    uint start,
    uint end,
    address holdCont,
    address presaleCont )
  {
    token = OpportyToken(tokenAddress);
    state = SaleState.NEW;
    SOFTCAP   = 1000 * 1 ether;
    HARDCAP   = 50000 * 1 ether;
    price     = 0.0002 * 1 ether;
    startDate = start;
    endDate   = end;
    minimalContribution = 0.3 * 1 ether;
    releasedTokens = false;

    wallet = walletAddress;
    holdContract = HoldPresaleContract(holdCont);
    presale = OpportyPresale(presaleCont);
    bonus   = new OpportySaleBonus(start);
  }

   

  function setStartDate(uint date) onlyOwner {
    require(state == SaleState.NEW);
    require(date < endDate);
    uint oldStartDate = startDate;
    startDate = date;
    bonus.changeStartDate(date);
    ManualChangeStartDate(oldStartDate, date);
  }
  function setEndDate(uint date) onlyOwner {
    require(state == SaleState.NEW || state == SaleState.SALE);
    require(date > now && date > startDate);
    uint oldEndDate = endDate;
    endDate = date;
    ManualChangeEndDate(oldEndDate, date);
  }
  function setSoftCap(uint softCap) onlyOwner {
    require(state == SaleState.NEW);
    SOFTCAP = softCap;
  }
  function setHardCap(uint hardCap) onlyOwner {
    require(state == SaleState.NEW);
    HARDCAP = hardCap;
  }

   
  function() whenNotPaused public payable {
    require(msg.value != 0);

    if (state == SaleState.ENDED) {
      revert();
    }

    bool chstate = checkCrowdsaleState();

    if (state == SaleState.SALE) {
      processTransaction(msg.sender, msg.value);
    }
    else {
      refundTransaction(chstate);
    }
  }

   
  function checkCrowdsaleState() internal returns (bool){
    if (getEthRaised() >= HARDCAP && state != SaleState.ENDED) {
      state = SaleState.ENDED;
      HardCapReached(block.number);  
      CrowdsaleEnded(block.number);
      return true;
    }

    if(now > startDate && now <= endDate) {
      if (state == SaleState.SALE && checkBalanceContract() >= minimumTokensToStart ) {
        return true;
      }
    } else {
      if (state != SaleState.ENDED && now > endDate) {
        state = SaleState.ENDED;
        CrowdsaleEnded(block.number);
        return true;
      }
    }
    return false;
  }

   
  function processTransaction(address _contributor, uint _amount) internal {

    require(msg.value >= minimalContribution);

    uint maxContribution = calculateMaxContribution();
    uint contributionAmount = _amount;
    uint returnAmount = 0;

    if (maxContribution < _amount) {
      contributionAmount = maxContribution;
      returnAmount = _amount - maxContribution;
    }
    uint ethrai = getEthRaised() ;
    if (ethrai + contributionAmount >= SOFTCAP && SOFTCAP > ethrai) {
      SoftCapReached(block.number);
    }

    if (contributorList[_contributor].isActive == false) {
      contributorList[_contributor].isActive = true;
      contributorList[_contributor].contributionAmount = contributionAmount;
      contributorIndexes[nextContributorIndex] = _contributor;
      nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionAmount += contributionAmount;
    }

    ethRaised += contributionAmount;

    FundTransfered(_contributor, contributionAmount);

    uint tokenAmount  = contributionAmount.div(price);
    uint timeBonus    = bonus.calculateBonusForHours(tokenAmount);

    if (tokenAmount > 0) {
      contributorList[_contributor].tokensIssued += tokenAmount.add(timeBonus);
      contributorList[_contributor].bonusAmount += timeBonus;
      totalTokens += tokenAmount.add(timeBonus);
    }

    if (returnAmount != 0) {
      _contributor.transfer(returnAmount);
    }
  }

   
  function refundTransaction(bool _stateChanged) internal {
    if (_stateChanged) {
      msg.sender.transfer(msg.value);
    } else{
      revert();
    }
  }

   
  function releaseTokens() onlyOwner {
    require (state == SaleState.ENDED);

    uint cbalance = checkBalanceContract();

    require (cbalance != 0);
    require (withdrawedTokens >= totalTokens || getEthRaised() < SOFTCAP);

    if (getEthRaised() >= SOFTCAP) {
      if (releasedTokens == true) {
        if (token.transfer(msg.sender, cbalance ) ) {
          TokensTransferedToOwner(msg.sender , cbalance );
        }
      } else {
        if (token.transfer(holdContract, cbalance ) ) {
          holdContract.addHolder(msg.sender, cbalance, 1, endDate.add(182 days) );
          releasedTokens = true;
          TokensTransferedToHold(holdContract , cbalance );
        }
      }
    } else {
      if (token.transfer(msg.sender, cbalance) ) {
        TokensTransferedToOwner(msg.sender , cbalance );
      }
    }
  }

  function checkBalanceContract() internal returns (uint) {
    return token.balanceOf(this);
  }

   
  function getTokens() whenNotPaused {
    uint er =  getEthRaised();
    require((now > endDate && er >= SOFTCAP )  || ( er >= HARDCAP)  );
    require(state == SaleState.ENDED);
    require(contributorList[msg.sender].tokensIssued > 0);
    require(!hasWithdrawedTokens[msg.sender]);

    uint tokenCount = contributorList[msg.sender].tokensIssued;

    if (token.transfer(msg.sender, tokenCount * (10 ** 18) )) {
      TokensTransfered(msg.sender , tokenCount * (10 ** 18) );
      withdrawedTokens += tokenCount;
      hasWithdrawedTokens[msg.sender] = true;
    }

  }
  function batchReturnTokens(uint _numberOfReturns) onlyOwner whenNotPaused {
    uint er = getEthRaised();
    require((now > endDate && er >= SOFTCAP )  || (er >= HARDCAP)  );
    require(state == SaleState.ENDED);

    address currentParticipantAddress;
    uint tokensCount;

    for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
      currentParticipantAddress = contributorIndexes[nextContributorToTransferTokens];
      if (currentParticipantAddress == 0x0) return;
      if (!hasWithdrawedTokens[currentParticipantAddress]) {
        tokensCount = contributorList[currentParticipantAddress].tokensIssued;
        hasWithdrawedTokens[currentParticipantAddress] = true;
        if (token.transfer(currentParticipantAddress, tokensCount * (10 ** 18))) {
          TokensTransfered(currentParticipantAddress, tokensCount * (10 ** 18));
          withdrawedTokens += tokensCount;
          hasWithdrawedTokens[msg.sender] = true;
        }
      }
      nextContributorToTransferTokens += 1;
    }

  }

   
  function refund() whenNotPaused {
    require(now > endDate && getEthRaised() < SOFTCAP);
    require(contributorList[msg.sender].contributionAmount > 0);
    require(!hasClaimedEthWhenFail[msg.sender]);

    uint ethContributed = contributorList[msg.sender].contributionAmount;
    hasClaimedEthWhenFail[msg.sender] = true;
    if (!msg.sender.send(ethContributed)) {
      ErrorSendingETH(msg.sender, ethContributed);
    } else {
      Refunded(msg.sender, ethContributed);
    }
  }
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner whenNotPaused {
    require(now > endDate && getEthRaised() < SOFTCAP);
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];
      if (currentParticipantAddress == 0x0) return;
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {
        contribution = contributorList[currentParticipantAddress].contributionAmount;
        hasClaimedEthWhenFail[currentParticipantAddress] = true;

        if (!currentParticipantAddress.send(contribution)){
          ErrorSendingETH(currentParticipantAddress, contribution);
        } else {
          Refunded(currentParticipantAddress, contribution);
        }
      }
      nextContributorToClaim += 1;
    }
  }

   
  function withdrawEth() {
    require(this.balance != 0);
    require(getEthRaised() >= SOFTCAP);
    require(msg.sender == wallet);
    uint bal = this.balance;
    wallet.transfer(bal);
    WithdrawedEthToWallet(bal);
  }

  function withdrawRemainingBalanceForManualRecovery() onlyOwner {
    require(this.balance != 0);
    require(now > endDate);
    require(contributorIndexes[nextContributorToClaim] == 0x0);
    msg.sender.transfer(this.balance);
  }

   
  function startCrowdsale() onlyOwner  {
    require(now > startDate && now <= endDate);
    require(state == SaleState.NEW);
    require(checkBalanceContract() >= minimumTokensToStart);

    state = SaleState.SALE;
    CrowdsaleStarted(block.number);
  }

   

  function getAccountsNumber() constant returns (uint) {
    return nextContributorIndex;
  }

  function getEthRaised() constant returns (uint) {
    uint pre = presale.getEthRaised();
    return pre + ethRaised;
  }

  function getTokensTotal() constant returns (uint) {
    return totalTokens;
  }

  function getWithdrawedToken() constant returns (uint) {
    return withdrawedTokens;
  }

  function calculateMaxContribution() constant returns (uint) {
    return HARDCAP - getEthRaised();
  }

  function getSoftCap() constant returns(uint) {
    return SOFTCAP;
  }

  function getHardCap() constant returns(uint) {
    return HARDCAP;
  }

  function getSaleStatus() constant returns (uint) {
    return uint(state);
  }

  function getStartDate() constant returns (uint) {
    return startDate;
  }

  function getEndDate() constant returns (uint) {
    return endDate;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endDate || state == SaleState.ENDED;
  }

  function getTokenBalance() constant returns (uint) {
    return token.balanceOf(this);
  }

   
  function getCurrentBonus() public constant returns (uint) {
    if(now > endDate || state == SaleState.ENDED) {
      return 0;
    }
    return bonus.getBonus();
  }
}