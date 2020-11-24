 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract InvestedProvider is Ownable {

  uint public invested;

}

 

contract AddressesFilterFeature is Ownable {

  mapping(address => bool) public allowedAddresses;

  function addAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = true;
  }

  function removeAllowedAddress(address allowedAddress) public onlyOwner {
    allowedAddresses[allowedAddress] = false;
  }

}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

contract MintableToken is AddressesFilterFeature, StandardToken {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  bool public mintingFinished = false;

  address public saleAgent;

  mapping (address => uint) public initialBalances;

  mapping (address => uint) public lockedAddresses;

  modifier notLocked(address _from, uint _value) {
    require(msg.sender == owner || msg.sender == saleAgent || allowedAddresses[_from] || (mintingFinished && now > lockedAddresses[_from]));
    _;
  }

  function lock(address _from, uint lockDays) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    lockedAddresses[_from] = now + 1 days * lockDays;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    initialBalances[_to] = balances[_to];

    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    MintFinished();
    return true;
  }

  function transfer(address _to, uint256 _value) public notLocked(msg.sender, _value)  returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public notLocked(from, value) returns (bool) {
    return super.transferFrom(from, to, value);
  }

}

 

contract TokenProvider is Ownable {

  MintableToken public token;

  function setToken(address newToken) public onlyOwner {
    token = MintableToken(newToken);
  }

}

 

contract MintTokensInterface is TokenProvider {

  uint public minted;

  function mintTokens(address to, uint tokens) internal;

}

 

contract MintTokensFeature is MintTokensInterface {

  using SafeMath for uint;

  function mintTokens(address to, uint tokens) internal {
    token.mint(to, tokens);
    minted = minted.add(tokens);
  }

}

 

contract PercentRateProvider {

  uint public percentRate = 100;

}

 

contract PercentRateFeature is Ownable, PercentRateProvider {

  function setPercentRate(uint newPercentRate) public onlyOwner {
    percentRate = newPercentRate;
  }

}

 

contract RetrieveTokensFeature is Ownable {

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

}

 

contract WalletProvider is Ownable {

  address public wallet;

  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

}

 

contract CommonSale is PercentRateFeature, InvestedProvider, WalletProvider, RetrieveTokensFeature, MintTokensFeature {

  address public directMintAgent;

  uint public price;

  uint public start;

  uint public minInvestedLimit;

  uint public hardcap;

  modifier isUnderHardcap() {
    require(invested <= hardcap);
    _;
  }

  function setHardcap(uint newHardcap) public onlyOwner {
    hardcap = newHardcap;
  }

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  modifier minInvestLimited(uint value) {
    require(value >= minInvestedLimit);
    _;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setMinInvestedLimit(uint newMinInvestedLimit) public onlyOwner {
    minInvestedLimit = newMinInvestedLimit;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function calculateTokens(uint _invested) internal returns(uint);

  function mintTokensExternal(address to, uint tokens) public onlyDirectMintAgentOrOwner {
    mintTokens(to, tokens);
  }

  function endSaleDate() public view returns(uint);

  function mintTokensByETHExternal(address to, uint _invested) public onlyDirectMintAgentOrOwner returns(uint) {
    updateInvested(_invested);
    return mintTokensByETH(to, _invested);
  }

  function mintTokensByETH(address to, uint _invested) internal isUnderHardcap returns(uint) {
    uint tokens = calculateTokens(_invested);
    mintTokens(to, tokens);
    return tokens;
  }

  function transferToWallet(uint value) internal {
    wallet.transfer(value);
  }

  function updateInvested(uint value) internal {
    invested = invested.add(value);
  }

  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    transferToWallet(msg.value);
    updateInvested(msg.value);
    return mintTokensByETH(msg.sender, msg.value);
  }

  function () public payable {
    fallback();
  }

}

 

contract SpecialWallet is PercentRateFeature {
  
  using SafeMath for uint;

  uint public endDate;

  uint initialBalance;

  bool public started;

  uint public startDate;

  uint availableAfterStart;

  uint public withdrawed;

  uint public startQuater;

  uint public quater1;

  uint public quater2;

  uint public quater3;

  uint public quater4;

  modifier notStarted() {
    require(!started);
    _;
  }

  function start() public onlyOwner notStarted {
    started = true;
    startDate = now;

    uint year = 1 years;
    uint quater = year.div(4);
    uint prevYear = endDate.sub(1 years);

    quater1 = prevYear;
    quater2 = prevYear.add(quater);
    quater3 = prevYear.add(quater.mul(2));
    quater4 = prevYear.add(quater.mul(3));

    initialBalance = this.balance;

    startQuater = curQuater();
  }

  function curQuater() public view returns (uint) {
    if(now > quater4) 
      return 4;
    if(now > quater3) 
      return 3;
    if(now > quater2) 
      return 2;
    return 1;
  }
 
  function setAvailableAfterStart(uint newAvailableAfterStart) public onlyOwner notStarted {
    availableAfterStart = newAvailableAfterStart;
  }

  function setEndDate(uint newEndDate) public onlyOwner notStarted {
    endDate = newEndDate;
  }

  function withdraw(address to) public onlyOwner {
    require(started);
    if(now >= endDate) {
      to.transfer(this.balance);
    } else {
      uint cQuater = curQuater();
      uint toTransfer = initialBalance.mul(availableAfterStart).div(percentRate);
      if(startQuater < 4 && cQuater > startQuater) {
        uint secondInitialBalance = initialBalance.sub(toTransfer);
        uint quaters = 4;
        uint allQuaters = quaters.sub(startQuater);        
        uint value = secondInitialBalance.mul(cQuater.sub(startQuater)).div(allQuaters);         
        toTransfer = toTransfer.add(value);
      }
      toTransfer = toTransfer.sub(withdrawed); 
      to.transfer(toTransfer);
      withdrawed = withdrawed.add(toTransfer);        
    }
  }

  function () public payable {
  }

}

 

contract AssembledCommonSale is CommonSale {

  uint public period;

  SpecialWallet public specialWallet;

  function setSpecialWallet(address addrSpecialWallet) public onlyOwner {
    specialWallet = SpecialWallet(addrSpecialWallet);
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function endSaleDate() public view returns(uint) {
    return start.add(period * 1 days);
  }

}

 

contract WalletsPercents is Ownable {

  address[] public wallets;

  mapping (address => uint) percents;

  function addWallet(address wallet, uint percent) public onlyOwner {
    wallets.push(wallet);
    percents[wallet] = percent;
  }
 
  function cleanWallets() public onlyOwner {
    wallets.length = 0;
  }


}

 

 

contract ExtendedWalletsMintTokensFeature is   MintTokensInterface, WalletsPercents {

  using SafeMath for uint;

  uint public percentRate = 100;

  function mintExtendedTokens() public onlyOwner {
    uint summaryTokensPercent = 0;
    for(uint i = 0; i < wallets.length; i++) {
      summaryTokensPercent = summaryTokensPercent.add(percents[wallets[i]]);
    }
    uint mintedTokens = token.totalSupply();
    uint allTokens = mintedTokens.mul(percentRate).div(percentRate.sub(summaryTokensPercent));
    for(uint k = 0; k < wallets.length; k++) {
      mintTokens(wallets[k], allTokens.mul(percents[wallets[k]]).div(percentRate));
    }

  }

}

 

contract StagedCrowdsale is Ownable {

  using SafeMath for uint;

  struct Milestone {
    uint period;
    uint bonus;
  }

  uint public totalPeriod;

  Milestone[] public milestones;

  function milestonesCount() public view returns(uint) {
    return milestones.length;
  }

  function addMilestone(uint period, uint bonus) public onlyOwner {
    require(period > 0);
    milestones.push(Milestone(period, bonus));
    totalPeriod = totalPeriod.add(period);
  }

  function removeMilestone(uint8 number) public onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];
    totalPeriod = totalPeriod.sub(milestone.period);

    delete milestones[number];

    for (uint i = number; i < milestones.length - 1; i++) {
      milestones[i] = milestones[i+1];
    }

    milestones.length--;
  }

  function changeMilestone(uint8 number, uint period, uint bonus) public onlyOwner {
    require(number < milestones.length);
    Milestone storage milestone = milestones[number];

    totalPeriod = totalPeriod.sub(milestone.period);

    milestone.period = period;
    milestone.bonus = bonus;

    totalPeriod = totalPeriod.add(period);
  }

  function insertMilestone(uint8 numberAfter, uint period, uint bonus) public onlyOwner {
    require(numberAfter < milestones.length);

    totalPeriod = totalPeriod.add(period);

    milestones.length++;

    for (uint i = milestones.length - 2; i > numberAfter; i--) {
      milestones[i + 1] = milestones[i];
    }

    milestones[numberAfter + 1] = Milestone(period, bonus);
  }

  function clearMilestones() public onlyOwner {
    require(milestones.length > 0);
    for (uint i = 0; i < milestones.length; i++) {
      delete milestones[i];
    }
    milestones.length -= milestones.length;
    totalPeriod = 0;
  }

  function lastSaleDate(uint start) public view returns(uint) {
    return start + totalPeriod * 1 days;
  }

  function currentMilestone(uint start) public view returns(uint) {
    uint previousDate = start;
    for(uint i=0; i < milestones.length; i++) {
      if(now >= previousDate && now < previousDate + milestones[i].period * 1 days) {
        return i;
      }
      previousDate = previousDate.add(milestones[i].period * 1 days);
    }
    revert();
  }

}

 

contract ITO is ExtendedWalletsMintTokensFeature, AssembledCommonSale {

  function calculateTokens(uint _invested) internal returns(uint) {
    return  _invested.mul(price).div(1 ether);
  }

  function setSpecialWallet(address addrSpecialWallet) public onlyOwner {
    super.setSpecialWallet(addrSpecialWallet);
    setWallet(addrSpecialWallet);
  }

  function finish() public onlyOwner {
     mintExtendedTokens();
     token.finishMinting();
     specialWallet.start();
     specialWallet.transferOwnership(owner);
  }

}

 

contract NextSaleAgentFeature is Ownable {

  address public nextSaleAgent;

  function setNextSaleAgent(address newNextSaleAgent) public onlyOwner {
    nextSaleAgent = newNextSaleAgent;
  }

}

 

contract SoftcapFeature is InvestedProvider, WalletProvider {

  using SafeMath for uint;

  mapping(address => uint) public balances;

  bool public softcapAchieved;

  bool public refundOn;

  bool public feePayed;

  uint public softcap;

  uint public constant devLimit = 26500000000000000000;

  address public constant devWallet = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;

  address public constant special = 0x1D0B575b48a6667FD8E59Da3b01a49c33005d2F1;

  function setSoftcap(uint newSoftcap) public onlyOwner {
    softcap = newSoftcap;
  }

  function withdraw() public {
    require(msg.sender == owner || msg.sender == devWallet);
    require(softcapAchieved);
    if(!feePayed) {
      devWallet.transfer(devLimit.sub(18 ether));
      special.transfer(18 ether);
      feePayed = true;
    }
    wallet.transfer(this.balance);
  }

  function updateBalance(address to, uint amount) internal {
    balances[to] = balances[to].add(amount);
    if (!softcapAchieved && invested >= softcap) {
      softcapAchieved = true;
      softcapReachedCallabck();
    }
  }

  function softcapReachedCallabck() internal {
  }

  function refund() public {
    require(refundOn && balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }

  function updateRefundState() internal returns(bool) {
    if (!softcapAchieved) {
      refundOn = true;
    }
    return refundOn;
  }

}

 

contract PreITO is SoftcapFeature, NextSaleAgentFeature, AssembledCommonSale {

  uint public firstBonusTokensLimit;

  uint public firstBonus;

  uint public secondBonus;

  function setFirstBonusTokensLimit(uint _tokens) public onlyOwner {
    firstBonusTokensLimit = _tokens;
  }

  function setFirstBonus(uint newFirstBonus) public onlyOwner {
    firstBonus = newFirstBonus;
  }

  function setSecondBonus(uint newSecondBonus) public onlyOwner {
    secondBonus = newSecondBonus;
  }

  function calculateTokens(uint _invested) internal returns(uint) {
    uint tokens = _invested.mul(price).div(1 ether);
    if(minted <= firstBonusTokensLimit) {
      if(firstBonus > 0) {
        tokens = tokens.add(tokens.mul(firstBonus).div(percentRate));
      }
    } else {
      if(secondBonus > 0) {
        tokens = tokens.add(tokens.mul(secondBonus).div(percentRate));
      }
    }
    return tokens;
  }

  function softcapReachedCallabck() internal {
    wallet = specialWallet;
  }

  function mintTokensByETH(address to, uint _invested) internal returns(uint) {
    uint _tokens = super.mintTokensByETH(to, _invested);
    updateBalance(to, _invested);
    return _tokens;
  }

  function finish() public onlyOwner {
    if (updateRefundState()) {
      token.finishMinting();
    } else {
      withdraw();
      specialWallet.transferOwnership(nextSaleAgent);
      token.setSaleAgent(nextSaleAgent);
    }
  }

  function fallback() internal minInvestLimited(msg.value) returns(uint) {
    require(now >= start && now < endSaleDate());
    updateInvested(msg.value);
    return mintTokensByETH(msg.sender, msg.value);
  }

}

 

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

 

contract Token is MintableToken {

  string public constant name = "Blockchain Agro Trading Token";

  string public constant symbol = "BATT";

  uint32 public constant decimals = 18;

  mapping(address => bool)  public registeredCallbacks;

  function transfer(address _to, uint256 _value) public returns (bool) {
    return processCallback(super.transfer(_to, _value), msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    return processCallback(super.transferFrom(_from, _to, _value), _from, _to, _value);
  }

  function registerCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = true;
  }

  function deregisterCallback(address callback) public onlyOwner {
    registeredCallbacks[callback] = false;
  }

  function processCallback(bool result, address from, address to, uint value) internal returns(bool) {
    if (result && registeredCallbacks[to]) {
      ReceivingContractCallback targetCallback = ReceivingContractCallback(to);
      targetCallback.tokenFallback(from, value);
    }
    return result;
  }

}

 

contract Configurator is Ownable {

  Token public token;

  SpecialWallet public specialWallet;

  PreITO public preITO;

  ITO public ito;

  function deploy() public onlyOwner {

    address manager = 0x529E6B0e82EF632F070D997dd50C35aAa939cB37;

    token = new Token();
    specialWallet = new SpecialWallet();
    preITO = new PreITO();
    ito = new ITO();

    specialWallet.setAvailableAfterStart(50);
    specialWallet.setEndDate(1546300800);
    specialWallet.transferOwnership(preITO);

    commonConfigure(preITO);
    commonConfigure(ito);

    preITO.setWallet(0x0fc0b9f68DCc12B72203e579d427d1ddf007e464);
    preITO.setStart(1524441600);
    preITO.setSoftcap(1000000000000000000000);
    preITO.setHardcap(33366000000000000000000);
    preITO.setFirstBonus(100);
    preITO.setFirstBonusTokensLimit(30000000000000000000000000);
    preITO.setSecondBonus(50);
    preITO.setMinInvestedLimit(1000000000000000000);

    token.setSaleAgent(preITO);

    ito.setStart(1527206400);
    ito.setHardcap(23000000000000000000000);

    ito.addWallet(0x8c76033Dedd13FD386F12787Ab4973BcbD1de2A8, 1);
    ito.addWallet(0x31Dba1B0b92fa23Eec30e2fF169dc7Cc05eEE915, 1);
    ito.addWallet(0x7Ae3c0DdaC135D69cA8E04d05559cd42822ecf14, 8);
    ito.setMinInvestedLimit(100000000000000000);

    preITO.setNextSaleAgent(ito);

    token.transferOwnership(manager);
    preITO.transferOwnership(manager);
    ito.transferOwnership(manager);
  }

  function commonConfigure(AssembledCommonSale sale) internal {
    sale.setPercentRate(100);
    sale.setPeriod(30);
    sale.setPrice(30000000000000000000000);
    sale.setSpecialWallet(specialWallet);
    sale.setToken(token);
  }

}