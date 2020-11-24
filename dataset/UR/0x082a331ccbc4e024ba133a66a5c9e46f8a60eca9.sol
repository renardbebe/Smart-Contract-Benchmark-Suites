 

pragma solidity ^0.4.18;

 

contract ReceivingContractCallback {

  function tokenFallback(address _from, uint _value) public;

}

 

 
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

 

contract LightcashCryptoToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  string public constant name = 'Lightcash crypto';

  string public constant symbol = 'LCCT';

  uint32 public constant decimals = 18;

  bool public mintingFinished = false;

  address public saleAgent;

  mapping(address => bool) public authorized;

  mapping(address => bool)  public registeredCallbacks;

  function transfer(address _to, uint256 _value) public returns (bool) {
    return processCallback(super.transfer(_to, _value), msg.sender, _to, _value);
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    return processCallback(super.transferFrom(from, to, value), from, to, value);
  }

  function setSaleAgent(address newSaleAgent) public {
    require(saleAgent == msg.sender || owner == msg.sender);
    saleAgent = newSaleAgent;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(!mintingFinished);
    require(msg.sender == saleAgent);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(address(0), _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public returns (bool) {
    require(!mintingFinished);
    require(msg.sender == owner || msg.sender == saleAgent);
    mintingFinished = true;
    MintFinished();
    return true;
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

 

contract CommonTokenEvent is Ownable {

  using SafeMath for uint;

  uint public constant PERCENT_RATE = 100;

  uint public price;

  uint public start;

  uint public period;

  uint public minPurchaseLimit;

  uint public minted;

  uint public hardcap;

  uint public invested;

  uint public referrerPercent;

  uint public maxReferrerTokens;

  address public directMintAgent;

  address public wallet;

  LightcashCryptoToken public token;

  modifier canMint() {
    require(now >= start && now < lastSaleDate() && msg.value >= minPurchaseLimit && minted < hardcap);
    _;
  }

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  function sendReferrerTokens(uint tokens) internal {
    if (msg.data.length == 20) {
      address referrer = bytesToAddres(bytes(msg.data));
      require(referrer != address(token) && referrer != msg.sender);
      uint referrerTokens = tokens.mul(referrerPercent).div(PERCENT_RATE);
      if(referrerTokens > maxReferrerTokens) {
        referrerTokens = maxReferrerTokens;
      }
      mintAndSendTokens(referrer, referrerTokens);
    }
  }

  function bytesToAddres(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for (uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }

  function setMaxReferrerTokens(uint newMaxReferrerTokens) public onlyOwner {
    maxReferrerTokens = newMaxReferrerTokens;
  }

  function setHardcap(uint newHardcap) public onlyOwner {
    hardcap = newHardcap;
  }

  function setToken(address newToken) public onlyOwner {
    token = LightcashCryptoToken(newToken);
  }

  function setReferrerPercent(uint newReferrerPercent) public onlyOwner {
    referrerPercent = newReferrerPercent;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function lastSaleDate() public view returns(uint) {
    return start + period * 1 days;
  }

  function setMinPurchaseLimit(uint newMinPurchaseLimit) public onlyOwner {
    minPurchaseLimit = newMinPurchaseLimit;
  }

  function setWallet(address newWallet) public onlyOwner {
    wallet = newWallet;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner {
    calculateAndTransferTokens(to, investedWei);
  }

  function directMintTokens(address to, uint count) public onlyDirectMintAgentOrOwner {
    mintAndSendTokens(to, count);
  }

  function mintAndSendTokens(address to, uint amount) internal {
    token.mint(to, amount);
    minted = minted.add(amount);
  }

  function calculateAndTransferTokens(address to, uint investedInWei) internal returns(uint) {
    uint tokens = calculateTokens(investedInWei);
    mintAndSendTokens(to, tokens);
    invested = invested.add(investedInWei);
    return tokens;
  }

  function calculateAndTransferTokensWithReferrer(address to, uint investedInWei) internal {
    uint tokens = calculateAndTransferTokens(to, investedInWei);
    sendReferrerTokens(tokens);
  }

  function calculateTokens(uint investedInWei) public view returns(uint);

  function createTokens() public payable;

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(this));
  }

}

 

contract PreTGE is CommonTokenEvent {

  uint public softcap;

  bool public refundOn;

  bool public softcapAchieved;

  address public nextSaleAgent;

  mapping (address => uint) public balances;

  event RefundsEnabled();

  event SoftcapReached();

  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function calculateTokens(uint investedInWei) public view returns(uint) {
    return investedInWei.mul(price).div(1 ether);
  }

  function setNextSaleAgent(address newNextSaleAgent) public onlyOwner {
    nextSaleAgent = newNextSaleAgent;
  }

  function setSoftcap(uint newSoftcap) public onlyOwner {
    softcap = newSoftcap;
  }

  function refund() public {
    require(now > start && refundOn && balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
    Refunded(msg.sender, value);
  }

  function widthraw() public {
    require(softcapAchieved);
    wallet.transfer(this.balance);
  }

  function createTokens() public payable canMint {
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    super.calculateAndTransferTokensWithReferrer(msg.sender, msg.value);
    if (!softcapAchieved && minted >= softcap) {
      softcapAchieved = true;
      SoftcapReached();
    }
  }

  function finish() public onlyOwner {
    if (!softcapAchieved) {
      refundOn = true;
      RefundsEnabled();
    } else {
      widthraw();
      token.setSaleAgent(nextSaleAgent);
    }
  }

}

 

contract StagedTokenEvent is CommonTokenEvent {

  using SafeMath for uint;

  struct Stage {
    uint period;
    uint discount;
  }

  uint public constant STAGES_PERCENT_RATE = 100;

  Stage[] public stages;

  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

  function addStage(uint stagePeriod, uint discount) public onlyOwner {
    require(stagePeriod > 0);
    stages.push(Stage(stagePeriod, discount));
    period = period.add(stagePeriod);
  }

  function removeStage(uint8 number) public onlyOwner {
    require(number >= 0 && number < stages.length);

    Stage storage stage = stages[number];
    period = period.sub(stage.period);

    delete stages[number];

    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }

    stages.length--;
  }

  function changeStage(uint8 number, uint stagePeriod, uint discount) public onlyOwner {
    require(number >= 0 && number < stages.length);

    Stage storage stage = stages[number];

    period = period.sub(stage.period);

    stage.period = stagePeriod;
    stage.discount = discount;

    period = period.add(stagePeriod);
  }

  function insertStage(uint8 numberAfter, uint stagePeriod, uint discount) public onlyOwner {
    require(numberAfter < stages.length);


    period = period.add(stagePeriod);

    stages.length++;

    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }

    stages[numberAfter + 1] = Stage(period, discount);
  }

  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    period = 0;
  }

  function getDiscount() public constant returns(uint) {
    uint prevTimeLimit = start;
    for (uint i = 0; i < stages.length; i++) {
      Stage storage stage = stages[i];
      prevTimeLimit += stage.period * 1 days;
      if (now < prevTimeLimit)
        return stage.discount;
    }
    revert();
  }

}

 

contract TGE is StagedTokenEvent {

  address public extraTokensWallet;

  uint public extraTokensPercent;

  bool public finished = false;

  function setExtraTokensWallet(address newExtraTokensWallet) public onlyOwner {
    extraTokensWallet = newExtraTokensWallet;
  }

  function setExtraTokensPercent(uint newExtraTokensPercent) public onlyOwner {
    extraTokensPercent = newExtraTokensPercent;
  }

  function calculateTokens(uint investedInWei) public view returns(uint) {
    return investedInWei.mul(price).mul(STAGES_PERCENT_RATE).div(STAGES_PERCENT_RATE.sub(getDiscount())).div(1 ether);
  }

  function finish() public onlyOwner {
    require(!finished);
    finished = true;
    uint256 totalSupply = token.totalSupply();
    uint allTokens = totalSupply.mul(PERCENT_RATE).div(PERCENT_RATE.sub(extraTokensPercent));
    uint extraTokens = allTokens.mul(extraTokensPercent).div(PERCENT_RATE);
    mintAndSendTokens(extraTokensWallet, extraTokens);
  }

  function createTokens() public payable canMint {
    require(!finished);
    wallet.transfer(msg.value);
    calculateAndTransferTokensWithReferrer(msg.sender, msg.value);
  }

}

 

contract Deployer is Ownable {

  LightcashCryptoToken public token;

  PreTGE public preTGE;

  TGE public tge;

  function deploy() public onlyOwner {
    token = new LightcashCryptoToken();

    preTGE = new PreTGE();
    preTGE.setPrice(7143000000000000000000);  
    preTGE.setMinPurchaseLimit(100000000000000000);  
    preTGE.setSoftcap(7000000000000000000000000);  
    preTGE.setHardcap(52500000000000000000000000);  
    preTGE.setStart(1519995600);  
    preTGE.setPeriod(11);
    preTGE.setWallet(0xDFDCAc0c9Eb45C63Bcff91220A48684882F1DAd0);
    preTGE.setMaxReferrerTokens(10000000000000000000000);  
    preTGE.setReferrerPercent(10);

    tge = new TGE();
    tge.setPrice(5000000000000000000000);  
    tge.setMinPurchaseLimit(10000000000000000);  
    tge.setHardcap(126000000000000000000000000);  
    tge.setStart(1520859600);  
    tge.setWallet(0x3aC45b49A4D3CB35022fd8122Fd865cd1B47932f);
    tge.setExtraTokensWallet(0xF0e830148F3d1C4656770DAa282Fda6FAAA0Fe0B);
    tge.setExtraTokensPercent(15);
    tge.addStage(7, 20);
    tge.addStage(7, 15);
    tge.addStage(7, 10);
    tge.addStage(1000, 5);
    tge.setMaxReferrerTokens(10000000000000000000000);  
    tge.setReferrerPercent(10);

    preTGE.setToken(token);
    tge.setToken(token);
    preTGE.setNextSaleAgent(tge);
    token.setSaleAgent(preTGE);

    address newOnwer = 0xF51E0a3a17990D41C5f1Ff1d0D772b26E4D6B6d0;
    token.transferOwnership(newOnwer);
    preTGE.transferOwnership(newOnwer);
    tge.transferOwnership(newOnwer);
  }

}