 

pragma solidity ^0.4.17;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
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

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  address public saleAgent;

  function setSaleAgent(address newSaleAgnet) {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

  function mint(address _to, uint256 _amount) returns (bool) {
    require(msg.sender == saleAgent && !mintingFinished);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
    mintingFinished = true;
    MintFinished();
    return true;
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

   
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
  
}

contract CovestingToken is MintableToken {	
    
  string public constant name = "Covesting";
   
  string public constant symbol = "COV";
    
  uint32 public constant decimals = 18;

  mapping (address => uint) public locked;

  function transfer(address _to, uint256 _value) returns (bool) {
    require(locked[msg.sender] < now);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(locked[_from] < now);
    return super.transferFrom(_from, _to, _value);
  }
  
  function lock(address addr, uint periodInDays) {
    require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
    locked[addr] = now + periodInDays * 1 days;
  }

  function () payable {
    revert();
  }

}

contract StagedCrowdsale is Pausable {

  using SafeMath for uint;

  struct Stage {
    uint hardcap;
    uint price;
    uint invested;
    uint closed;
  }

  uint public start;

  uint public period;

  uint public totalHardcap;
 
  uint public totalInvested;

  Stage[] public stages;

  function stagesCount() public constant returns(uint) {
    return stages.length;
  }

  function setStart(uint newStart) public onlyOwner {
    start = newStart;
  }

  function setPeriod(uint newPeriod) public onlyOwner {
    period = newPeriod;
  }

  function addStage(uint hardcap, uint price) public onlyOwner {
    require(hardcap > 0 && price > 0);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    stages.push(stage);
    totalHardcap = totalHardcap.add(stage.hardcap);
  }

  function removeStage(uint8 number) public onlyOwner {
    require(number >=0 && number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    delete stages[number];
    for (uint i = number; i < stages.length - 1; i++) {
      stages[i] = stages[i+1];
    }
    stages.length--;
  }

  function changeStage(uint8 number, uint hardcap, uint price) public onlyOwner {
    require(number >= 0 &&number < stages.length);
    Stage storage stage = stages[number];
    totalHardcap = totalHardcap.sub(stage.hardcap);    
    stage.hardcap = hardcap.mul(1 ether);
    stage.price = price;
    totalHardcap = totalHardcap.add(stage.hardcap);    
  }

  function insertStage(uint8 numberAfter, uint hardcap, uint price) public onlyOwner {
    require(numberAfter < stages.length);
    Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
    totalHardcap = totalHardcap.add(stage.hardcap);
    stages.length++;
    for (uint i = stages.length - 2; i > numberAfter; i--) {
      stages[i + 1] = stages[i];
    }
    stages[numberAfter + 1] = stage;
  }

  function clearStages() public onlyOwner {
    for (uint i = 0; i < stages.length; i++) {
      delete stages[i];
    }
    stages.length -= stages.length;
    totalHardcap = 0;
  }

  function lastSaleDate() public constant returns(uint) {
    return start + period * 1 days;
  }

  modifier saleIsOn() {
    require(stages.length > 0 && now >= start && now < lastSaleDate());
    _;
  }
  
  modifier isUnderHardcap() {
    require(totalInvested <= totalHardcap);
    _;
  }

  function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
    for(uint i=0; i < stages.length; i++) {
      if(stages[i].closed == 0) {
        return i;
      }
    }
    revert();
  }

}

contract CommonSale is StagedCrowdsale {

  address public multisigWallet;

  uint public minPrice;

  uint public totalTokensMinted;

  CovestingToken public token;
  
  function setMinPrice(uint newMinPrice) public onlyOwner {
    minPrice = newMinPrice;
  }

  function setMultisigWallet(address newMultisigWallet) public onlyOwner {
    multisigWallet = newMultisigWallet;
  }
  
  function setToken(address newToken) public onlyOwner {
    token = CovestingToken(newToken);
  }

  function createTokens() public whenNotPaused payable {
    require(msg.value >= minPrice);
    uint stageIndex = currentStage();
    multisigWallet.transfer(msg.value);
    Stage storage stage = stages[stageIndex];
    uint tokens = msg.value.mul(stage.price);
    token.mint(this, tokens);
    token.transfer(msg.sender, tokens);
    totalTokensMinted = totalTokensMinted.add(tokens);
    totalInvested = totalInvested.add(msg.value);
    stage.invested = stage.invested.add(msg.value);
    if(stage.invested >= stage.hardcap) {
      stage.closed = now;
    }
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}

contract Presale is CommonSale {

  Mainsale public mainsale;

  function setMainsale(address newMainsale) public onlyOwner {
    mainsale = Mainsale(newMainsale);
  }

  function setMultisigWallet(address newMultisigWallet) public onlyOwner {
    multisigWallet = newMultisigWallet;
  }

  function finishMinting() public whenNotPaused onlyOwner {
    token.setSaleAgent(mainsale);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(multisigWallet, token.balanceOf(this));
  }

}


contract Mainsale is CommonSale {

  address public foundersTokensWallet;
  
  address public bountyTokensWallet;
  
  uint public foundersTokensPercent;
  
  uint public bountyTokensPercent;
  
  uint public percentRate = 100;

  uint public lockPeriod;

  function setLockPeriod(uint newLockPeriod) public onlyOwner {
    lockPeriod = newLockPeriod;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner {
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
    bountyTokensPercent = newBountyTokensPercent;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner {
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
    bountyTokensWallet = newBountyTokensWallet;
  }

  function finishMinting() public whenNotPaused onlyOwner {
    uint summaryTokensPercent = bountyTokensPercent + foundersTokensPercent;
    uint mintedTokens = token.totalSupply();
    uint summaryFoundersTokens = mintedTokens.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
    uint totalSupply = summaryFoundersTokens + mintedTokens;
    uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
    uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
    token.mint(this, foundersTokens);
    token.lock(foundersTokensWallet, lockPeriod * 1 days);
    token.transfer(foundersTokensWallet, foundersTokens);
    token.mint(this, bountyTokens);
    token.transfer(bountyTokensWallet, bountyTokens);
    totalTokensMinted = totalTokensMinted.add(foundersTokens).add(bountyTokens);
    token.finishMinting();
  }

}

contract TestConfigurator is Ownable {

  CovestingToken public token; 

  Presale public presale;

  Mainsale public mainsale;

  function deploy() public onlyOwner {
    token = new CovestingToken();

    presale = new Presale();

    presale.setToken(token);
    presale.addStage(5,300);
    presale.setMultisigWallet(0x055fa3f2DAc0b9Db661A4745965DDD65490d56A8);
    presale.setStart(1507208400);
    presale.setPeriod(2);
    presale.setMinPrice(100000000000000000);
    token.setSaleAgent(presale);	

    mainsale = new Mainsale();

    mainsale.setToken(token);
    mainsale.addStage(1,200);
    mainsale.addStage(2,100);
    mainsale.setMultisigWallet(0x4d9014eF9C3CE5790A326775Bd9F609969d1BF4f);
    mainsale.setFoundersTokensWallet(0x59b398bBED1CC6c82b337B3Bd0ad7e4dCB7d4de3);
    mainsale.setBountyTokensWallet(0x555635F2ea026ab65d7B44526539E0aB3874Ab24);
    mainsale.setStart(1507467600);
    mainsale.setPeriod(2);
    mainsale.setLockPeriod(1);
    mainsale.setMinPrice(100000000000000000);
    mainsale.setFoundersTokensPercent(13);
    mainsale.setBountyTokensPercent(5);

    presale.setMainsale(mainsale);

    token.transferOwnership(owner);
    presale.transferOwnership(owner);
    mainsale.transferOwnership(owner);
  }

}

contract Configurator is Ownable {

  CovestingToken public token; 

  Presale public presale;

  Mainsale public mainsale;

  function deploy() public onlyOwner {
    token = new CovestingToken();

    presale = new Presale();

    presale.setToken(token);
    presale.addStage(5000,300);
    presale.setMultisigWallet(0x6245C05a6fc205d249d0775769cfE73CB596e57D);
    presale.setStart(1508504400);
    presale.setPeriod(30);
    presale.setMinPrice(100000000000000000);
    token.setSaleAgent(presale);	

    mainsale = new Mainsale();

    mainsale.setToken(token);
    mainsale.addStage(5000,200);
    mainsale.addStage(5000,180);
    mainsale.addStage(10000,170);
    mainsale.addStage(20000,160);
    mainsale.addStage(20000,150);
    mainsale.addStage(40000,130);
    mainsale.setMultisigWallet(0x15A071B83396577cCbd86A979Af7d2aBa9e18970);
    mainsale.setFoundersTokensWallet(0x25ED4f0D260D5e5218D95390036bc8815Ff38262);
    mainsale.setBountyTokensWallet(0x717bfD30f039424B049D918F935DEdD069B66810);
    mainsale.setStart(1511222400);
    mainsale.setPeriod(30);
    mainsale.setLockPeriod(90);
    mainsale.setMinPrice(100000000000000000);
    mainsale.setFoundersTokensPercent(13);
    mainsale.setBountyTokensPercent(5);

    presale.setMainsale(mainsale);

    token.transferOwnership(owner);
    presale.transferOwnership(owner);
    mainsale.transferOwnership(owner);
  }

}

contract UpdateMainsale is CommonSale {

    enum Currency { BTC, LTC, ZEC, DASH, WAVES, USD, EUR }

    event ExternalSale(
        Currency _currency,
        bytes32 _txIdSha3,
        address indexed _buyer,
        uint256 _amountWei,
        uint256 _tokensE18
    );

    event NotifierChanged(
        address indexed _oldAddress,
        address indexed _newAddress
    );

     
    address public notifier;

     
    mapping(uint8 => mapping(bytes32 => uint256)) public externalTxs;

     
    uint256 public totalExternalSales = 0;

    modifier canNotify() {
        require(msg.sender == owner || msg.sender == notifier);
        _;
    }

     

    address public foundersTokensWallet;

    address public bountyTokensWallet;

    uint public foundersTokensPercent;

    uint public bountyTokensPercent;

    uint public percentRate = 100;

    uint public lockPeriod;

    function setLockPeriod(uint newLockPeriod) public onlyOwner {
        lockPeriod = newLockPeriod;
    }

    function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner {
        foundersTokensPercent = newFoundersTokensPercent;
    }

    function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
        bountyTokensPercent = newBountyTokensPercent;
    }

    function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner {
        foundersTokensWallet = newFoundersTokensWallet;
    }

    function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
        bountyTokensWallet = newBountyTokensWallet;
    }

    function finishMinting() public whenNotPaused onlyOwner {
        uint summaryTokensPercent = bountyTokensPercent + foundersTokensPercent;
        uint mintedTokens = token.totalSupply();
        uint summaryFoundersTokens = mintedTokens.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
        uint totalSupply = summaryFoundersTokens + mintedTokens;
        uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
        uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
        token.mint(this, foundersTokens);
        token.lock(foundersTokensWallet, lockPeriod * 1 days);
        token.transfer(foundersTokensWallet, foundersTokens);
        token.mint(this, bountyTokens);
        token.transfer(bountyTokensWallet, bountyTokens);
        totalTokensMinted = totalTokensMinted.add(foundersTokens).add(bountyTokens);
        token.finishMinting();
    }

     
     

    function setNotifier(address _notifier) public onlyOwner {
        NotifierChanged(notifier, _notifier);
        notifier = _notifier;
    }

    function externalSales(
        uint8[] _currencies,
        bytes32[] _txIdSha3,
        address[] _buyers,
        uint256[] _amountsWei,
        uint256[] _tokensE18
    ) public whenNotPaused canNotify {

        require(_currencies.length > 0);
        require(_currencies.length == _txIdSha3.length);
        require(_currencies.length == _buyers.length);
        require(_currencies.length == _amountsWei.length);
        require(_currencies.length == _tokensE18.length);

        for (uint i = 0; i < _txIdSha3.length; i++) {
            _externalSaleSha3(
                Currency(_currencies[i]),
                _txIdSha3[i],
                _buyers[i],
                _amountsWei[i],
                _tokensE18[i]
            );
        }
    }

    function _externalSaleSha3(
        Currency _currency,
        bytes32 _txIdSha3,  
        address _buyer,
        uint256 _amountWei,
        uint256 _tokensE18
    ) internal {

        require(_buyer > 0 && _amountWei > 0 && _tokensE18 > 0);

        var txsByCur = externalTxs[uint8(_currency)];

         
        require(txsByCur[_txIdSha3] == 0);
        txsByCur[_txIdSha3] = _tokensE18;

        uint stageIndex = currentStage();
        Stage storage stage = stages[stageIndex];

        token.mint(this, _tokensE18);
        token.transfer(_buyer, _tokensE18);
        totalTokensMinted = totalTokensMinted.add(_tokensE18);
        totalExternalSales++;

        totalInvested = totalInvested.add(_amountWei);
        stage.invested = stage.invested.add(_amountWei);
        if (stage.invested >= stage.hardcap) {
            stage.closed = now;
        }

        ExternalSale(_currency, _txIdSha3, _buyer, _amountWei, _tokensE18);
    }

     

    function btcId() public constant returns (uint8) {
        return uint8(Currency.BTC);
    }

    function ltcId() public constant returns (uint8) {
        return uint8(Currency.LTC);
    }

    function zecId() public constant returns (uint8) {
        return uint8(Currency.ZEC);
    }

    function dashId() public constant returns (uint8) {
        return uint8(Currency.DASH);
    }

    function wavesId() public constant returns (uint8) {
        return uint8(Currency.WAVES);
    }

    function usdId() public constant returns (uint8) {
        return uint8(Currency.USD);
    }

    function eurId() public constant returns (uint8) {
        return uint8(Currency.EUR);
    }

     

    function _tokensByTx(Currency _currency, string _txId) internal constant returns (uint256) {
        return tokensByTx(uint8(_currency), _txId);
    }

    function tokensByTx(uint8 _currency, string _txId) public constant returns (uint256) {
        return externalTxs[_currency][keccak256(_txId)];
    }

    function tokensByBtcTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.BTC, _txId);
    }

    function tokensByLtcTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.LTC, _txId);
    }

    function tokensByZecTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.ZEC, _txId);
    }

    function tokensByDashTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.DASH, _txId);
    }

    function tokensByWavesTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.WAVES, _txId);
    }

    function tokensByUsdTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.USD, _txId);
    }

    function tokensByEurTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.EUR, _txId);
    }

     
     
}

contract UpdateConfigurator is Ownable {

    CovestingToken public token;

    UpdateMainsale public mainsale;

    function deploy() public onlyOwner {
        mainsale = new UpdateMainsale();
        token = CovestingToken(0xE2FB6529EF566a080e6d23dE0bd351311087D567);
        mainsale.setToken(token);
        mainsale.addStage(5000,200);
        mainsale.addStage(5000,180);
        mainsale.addStage(10000,170);
        mainsale.addStage(20000,160);
        mainsale.addStage(20000,150);
        mainsale.addStage(40000,130);
        mainsale.setMultisigWallet(0x15A071B83396577cCbd86A979Af7d2aBa9e18970);
        mainsale.setFoundersTokensWallet(0x25ED4f0D260D5e5218D95390036bc8815Ff38262);
        mainsale.setBountyTokensWallet(0x717bfD30f039424B049D918F935DEdD069B66810);
        mainsale.setStart(1511528400);
        mainsale.setPeriod(30);
        mainsale.setLockPeriod(90);
        mainsale.setMinPrice(100000000000000000);
        mainsale.setFoundersTokensPercent(13);
        mainsale.setBountyTokensPercent(5);
        mainsale.setNotifier(owner);
        mainsale.transferOwnership(owner);
    }

}

contract IncreaseTokensOperator is Ownable {

  using SafeMath for uint256;

  mapping (address => bool) public authorized;

  mapping (address => bool) public minted;

  address[] public mintedList;

  mapping (address => bool) public pending;

  address[] public pendingList;

  CovestingToken public token = CovestingToken(0xE2FB6529EF566a080e6d23dE0bd351311087D567);

  uint public increaseK = 4;

  uint public index;

  modifier onlyAuthorized() {
    require(owner == msg.sender || authorized[msg.sender]);
    _;
  }

  function investorsCount() public returns(uint) {
    uint count = pendingList.length;
    return count;
  }

  function extraMintArrayPendingProcess(uint count) public onlyAuthorized {
    for(uint i = 0; index < pendingList.length && i < count; i++) {
      address tokenHolder = pendingList[index];
      uint value = token.balanceOf(tokenHolder);
      if(value != 0) {
        uint targetValue = value.mul(increaseK);
        uint diffValue = targetValue.sub(value);
        token.mint(this, diffValue);
        token.transfer(tokenHolder, diffValue);
      }
      minted[tokenHolder] = true;
      mintedList.push(tokenHolder);
      index++;
    }
  }

  function extraMintArrayPending(address[] tokenHolders) public onlyAuthorized {
    for(uint i = 0; i < tokenHolders.length; i++) {
      address tokenHolder = tokenHolders[i];
      require(!pending[tokenHolder]);
      pending[tokenHolder] = true;
      pendingList.push(tokenHolder);
    }
  }

  function extraMint(address tokenHolder) public onlyAuthorized {
    uint value = token.balanceOf(tokenHolder);
    if(value != 0) {
      uint targetValue = value.mul(increaseK);
      uint diffValue = targetValue.sub(value);
      token.mint(this, diffValue);
      token.transfer(tokenHolder, diffValue);
    }
    minted[tokenHolder] = true;
    mintedList.push(tokenHolder);
  }

  function extraMintArray(address[] tokenHolders) public onlyAuthorized {
    for(uint i = 0; i < tokenHolders.length; i++) {
      address tokenHolder = tokenHolders[i];
      require(!minted[tokenHolder]);
      uint value = token.balanceOf(tokenHolder);
      if(value != 0) {
        uint targetValue = value.mul(increaseK);
        uint diffValue = targetValue.sub(value);
        token.mint(this, diffValue);
        token.transfer(tokenHolder, diffValue);      
      }
      minted[tokenHolder] = true;
      mintedList.push(tokenHolder);
    }
  }

  function setIncreaseK(uint newIncreaseK) public onlyOwner {
    increaseK = newIncreaseK;
  }

  function setToken(address newToken) public onlyOwner {
    token = CovestingToken(newToken);
  }

  function authorize(address to) public onlyAuthorized {
    require(!authorized[to]);
    authorized[to] = true;
  }

  function unauthorize(address to) public onlyAuthorized {
    require(authorized[to]);
    authorized[to] = false;
  }

}