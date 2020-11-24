 

pragma solidity ^0.4.11;


 
contract Controller {

   
   
   
  function proxyPayment(address _owner) payable returns(bool);

   
   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) returns(bool);

   
   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount) returns(bool);
}

 
library SafeMath {

  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
contract Ownable {

  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract HasNoTokens is Ownable {

  
  function tokenFallback(address from_, uint value_, bytes data_) external {
    throw;
  }

   
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

 
 
 
 
contract AbstractSale {
  function saleFinalized() constant returns (bool);
}

contract Escrow is HasNoTokens {

  address public beneficiary;
  uint public finalBlock;
  AbstractSale public tokenSale;

   
   
   
  function Escrow(address _beneficiary, uint _finalBlock, address _tokenSale) {
    beneficiary = _beneficiary;
    finalBlock = _finalBlock;
    tokenSale = AbstractSale(_tokenSale);
  }

   
  function() public payable {}

   
  function withdraw() public {
    if (msg.sender != beneficiary) throw;
    if (block.number > finalBlock) return doWithdraw();
    if (tokenSale.saleFinalized()) return doWithdraw();
  }

  function doWithdraw() internal {
    if (!beneficiary.send(this.balance)) throw;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping (address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {
     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract Controlled {

  address public controller;

  function Controlled() {
    controller = msg.sender;
  }

  function changeController(address _controller) onlyController {
    controller = _controller;
  }

  modifier onlyController {
    if (msg.sender != controller) throw;
    _;
  }
}

 
contract MintableToken is StandardToken, Controlled {

  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;

   
  function mint(address _to, uint _amount) onlyController canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyController returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

  modifier canMint() {
    if (mintingFinished) throw;
    _;
  }
}

 
contract LimitedTransferToken is ERC20 {

   
  modifier canTransfer(address _sender, uint _value) {
   if (_value > transferableTokens(_sender, uint64(now))) throw;
   _;
  }

   
  function transfer(address _to, uint _value) canTransfer(msg.sender, _value) {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) {
    super.transferFrom(_from, _to, _value);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    return balanceOf(holder);
  }
}

 
contract VestedToken is StandardToken, LimitedTransferToken {

  uint256 MAX_GRANTS_PER_ADDRESS = 20;

  struct TokenGrant {
    address granter;      
    uint256 value;        
    uint64 cliff;
    uint64 vesting;
    uint64 start;         
    bool revokable;
    bool burnsOnRevoke;   
  }  

  mapping (address => TokenGrant[]) public grants;

  event NewTokenGrant(address indexed from, address indexed to, uint256 value, uint256 grantId);

   
  function grantVestedTokens(
    address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke
  ) public {

     
    if (_cliff < _start || _vesting < _cliff) {
      throw;
    }

    if (tokenGrantsCount(_to) > MAX_GRANTS_PER_ADDRESS) throw;   

    uint count = grants[_to].push(
                TokenGrant(
                  _revokable ? msg.sender : 0,   
                  _value,
                  _cliff,
                  _vesting,
                  _start,
                  _revokable,
                  _burnsOnRevoke
                )
              );
    transfer(_to, _value);
    NewTokenGrant(msg.sender, _to, _value, count - 1);
  }

   
  function revokeTokenGrant(address _holder, uint _grantId) public {
    TokenGrant grant = grants[_holder][_grantId];

    if (!grant.revokable) {  
      throw;
    }

    if (grant.granter != msg.sender) {  
      throw;
    }

    address receiver = grant.burnsOnRevoke ? 0xdead : msg.sender;
    uint256 nonVested = nonVestedTokens(grant, uint64(now));

     
    delete grants[_holder][_grantId];
    grants[_holder][_grantId] = grants[_holder][grants[_holder].length.sub(1)];
    grants[_holder].length -= 1;

    balances[receiver] = balances[receiver].add(nonVested);
    balances[_holder] = balances[_holder].sub(nonVested);

    Transfer(_holder, receiver, nonVested);
  }

   
  function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
    uint256 grantIndex = tokenGrantsCount(holder);
    if (grantIndex == 0) return balanceOf(holder);  

     
    uint256 nonVested = 0;
    for (uint256 i = 0; i < grantIndex; i++) {
      nonVested = nonVested.add(nonVestedTokens(grants[holder][i], time));
    }

     
    uint256 vestedTransferable = balanceOf(holder).sub(nonVested);

     
     
    return SafeMath.min256(vestedTransferable, super.transferableTokens(holder, time));
  }

   
  function tokenGrantsCount(address _holder) constant returns (uint index) {
    return grants[_holder].length;
  }

   
  function calculateVestedTokens(
    uint256 tokens,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) constant returns (uint256)
    {
       
      if (time < cliff) return 0;
      if (time >= vesting) return tokens;

       
       
       

       
      uint256 vestedTokens = tokens.mul(time.sub(start)).div(vesting.sub(start));
      return vestedTokens;
  }

   
  function tokenGrant(address _holder, uint _grantId) constant returns (address granter, uint256 value, uint256 vested, uint64 start, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke) {
    TokenGrant grant = grants[_holder][_grantId];

    granter = grant.granter;
    value = grant.value;
    start = grant.start;
    cliff = grant.cliff;
    vesting = grant.vesting;
    revokable = grant.revokable;
    burnsOnRevoke = grant.burnsOnRevoke;

    vested = vestedTokens(grant, uint64(now));
  }

   
  function vestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return calculateVestedTokens(
      grant.value,
      uint256(time),
      uint256(grant.start),
      uint256(grant.cliff),
      uint256(grant.vesting)
    );
  }

   
  function nonVestedTokens(TokenGrant grant, uint64 time) private constant returns (uint256) {
    return grant.value.sub(vestedTokens(grant, time));
  }

   
  function lastTokenIsTransferableDate(address holder) constant public returns (uint64 date) {
    date = uint64(now);
    uint256 grantIndex = grants[holder].length;
    for (uint256 i = 0; i < grantIndex; i++) {
      date = SafeMath.max64(grants[holder][i].vesting, date);
    }
  }
}

 
contract Artcoin is MintableToken, VestedToken {

  string public constant name = 'Artcoin';
  string public constant symbol = 'ART';
  uint public constant decimals = 18;

  function() public payable {
    if (isContract(controller)) {
      if (!Controller(controller).proxyPayment.value(msg.value)(msg.sender)) throw;
    } else {
      throw;
    }
  }

  function isContract(address _addr) constant internal returns(bool) {
    uint size;
    if (_addr == address(0)) return false;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }
}

 
contract ArtcoinPlaceholder is Controller {

  Artcoin public token;
  address public tokenSale;

  function ArtcoinPlaceholder(address _token, address _tokenSale) {
    token = Artcoin(_token);
    tokenSale = _tokenSale;
  }

  function changeController(address consortium) public {
    if (msg.sender != tokenSale) throw;
    token.changeController(consortium);
    suicide(consortium);
  }

  function proxyPayment(address _owner) payable public returns (bool) {
    throw;
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return true;
  }
}

 
contract ArtSale is Controller {
  using SafeMath for uint;

  address public manager;
  address public operations;
  ArtcoinPlaceholder public consortiumPlaceholder;

  Artcoin public token;
  Escrow public escrow;

  uint public initialBlock;   
  uint public finalBlock;   
  uint public initialPrice;   
  uint public finalPrice;   
  uint public priceStages;   

  uint public maximumSubscription;   
  uint public totalSubscription = 0;   

  mapping (address => bool) public activations;   
  mapping (address => uint) public subscriptions;   

  uint constant public dust = 1 finney;   

  bool public saleStopped = false;
  bool public saleFinalized = false;

  event NewPresaleAllocation(address indexed holder, uint amount);
  event NewSubscription(address indexed holder, uint amount, uint etherAmount);

  function ArtSale(address _manager,
                   address _operations,
                   uint _initialBlock,
                   uint _finalBlock,
                   uint256 _initialPrice,
                   uint256 _finalPrice,
                   uint8 _priceStages,
                   uint _maximumSubscription)
                   nonZeroAddress(_operations) {
    if (_initialBlock < getBlockNumber()) throw;
    if (_initialBlock >= _finalBlock) throw;
    if (_initialPrice <= _finalPrice) throw;
    if (_priceStages < 2) throw;
    if (_priceStages > _initialPrice - _finalPrice) throw;

    manager = _manager;
    operations = _operations;
    maximumSubscription = _maximumSubscription;
    initialBlock = _initialBlock;
    finalBlock = _finalBlock;
    initialPrice = _initialPrice;
    finalPrice = _finalPrice;
    priceStages = _priceStages;
  }

   
   
   
   
  function setArtcoin(address _token,
                      address _consortiumPlaceholder,
                      address _escrow)
                      nonZeroAddress(_token)
                      nonZeroAddress(_consortiumPlaceholder)
                      nonZeroAddress(_escrow)
                      public {
    if (activations[this]) throw;

    token = Artcoin(_token);
    consortiumPlaceholder = ArtcoinPlaceholder(_consortiumPlaceholder);
    escrow = Escrow(_escrow);

    if (token.controller() != address(this)) throw;   
    if (token.totalSupply() > 0) throw;   
    if (consortiumPlaceholder.tokenSale() != address(this)) throw;   
    if (consortiumPlaceholder.token() != address(token)) throw;  
    if (escrow.finalBlock() != finalBlock) throw;   
    if (escrow.beneficiary() != operations) throw;   
    if (escrow.tokenSale() != address(this)) throw;   

    doActivateSale(this);
  }

   
   
   
  function activateSale() public {
    doActivateSale(msg.sender);
  }

  function doActivateSale(address _entity) nonZeroAddress(token) onlyBeforeSale private {
    activations[_entity] = true;
  }

   
   
  function isActivated() constant public returns (bool) {
    return activations[this] && activations[operations];
  }

   
   
   
   
  function getPrice(uint _blockNumber) constant public returns (uint) {
    if (_blockNumber < initialBlock || _blockNumber >= finalBlock) return 0;
    return priceForStage(stageForBlock(_blockNumber));
  }

   
   
   
  function stageForBlock(uint _blockNumber) constant internal returns (uint) {
    uint blockN = _blockNumber.sub(initialBlock);
    uint totalBlocks = finalBlock.sub(initialBlock);
    return priceStages.mul(blockN).div(totalBlocks);
  }

   
   
   
   
  function priceForStage(uint _stage) constant internal returns (uint) {
    if (_stage >= priceStages) return 0;
    uint priceDifference = initialPrice.sub(finalPrice);
    uint stageDelta = priceDifference.div(uint(priceStages - 1));
    return initialPrice.sub(uint(_stage).mul(stageDelta));
  }

   
   
   
   
   
  function allocatePresaleTokens(address _recipient,
                                 uint _amount,
                                 uint64 cliffDate,
                                 uint64 vestingDate,
                                 bool revokable,
                                 bool burnOnRevocation)
                                 onlyBeforeSaleActivation
                                 onlyBeforeSale
                                 nonZeroAddress(_recipient)
                                 only(operations) public {
    token.grantVestedTokens(_recipient, _amount, uint64(now), cliffDate, vestingDate, revokable, burnOnRevocation);
    NewPresaleAllocation(_recipient, _amount);
  }

   
   
   
   
  function() public payable {
    return doPayment(msg.sender);
  }

   
   
   
  function doPayment(address _subscriber)
           onlyDuringSalePeriod
           onlySaleNotStopped
           onlySaleActivated
           nonZeroAddress(_subscriber)
           minimumValue(dust) internal {
    if (totalSubscription + msg.value > maximumSubscription) throw;   
    uint purchasedTokens = msg.value.mul(getPrice(getBlockNumber()));   

    if (!escrow.send(msg.value)) throw;   
    if (!token.mint(_subscriber, purchasedTokens)) throw;   

    subscriptions[_subscriber] = subscriptions[_subscriber].add(msg.value);
    totalSubscription = totalSubscription.add(msg.value);
    NewSubscription(_subscriber, purchasedTokens, msg.value);
  }

   
   
  function stopSale() onlySaleActivated onlySaleNotStopped only(operations) public {
    saleStopped = true;
  }

   
   
  function restartSale() onlyDuringSalePeriod onlySaleStopped only(operations) public {
    saleStopped = false;
  }

   
   
  function finalizeSale() onlyAfterSale only(operations) public {
    doFinalizeSale();
  }

  function doFinalizeSale() internal {
    uint purchasedTokens = token.totalSupply();

    uint advisorTokens = purchasedTokens * 5 / 100;   
    if (!token.mint(operations, advisorTokens)) throw;

    uint managerTokens = purchasedTokens * 25 / 100;   
    if (!token.mint(manager, managerTokens)) throw;

    token.changeController(consortiumPlaceholder);

    saleFinalized = true;
    saleStopped = true;
  }

   
   
  function deployConsortium(address consortium) onlyFinalizedSale nonZeroAddress(consortium) only(operations) public {
    consortiumPlaceholder.changeController(consortium);
  }

  function setOperations(address _operations) nonZeroAddress(_operations) only(operations) public {
    operations = _operations;
  }

  function getBlockNumber() constant internal returns (uint) {
    return block.number;
  }

  function saleFinalized() constant returns (bool) {
    return saleFinalized;
  }

  function proxyPayment(address _owner) payable public returns (bool) {
    doPayment(_owner);
    return true;
  }

   
   
   
   
   
  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
     
     
    return _from == address(this);
  }

   
   
   
   
   
  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return false;
  }

  modifier only(address x) {
    if (msg.sender != x) throw;
    _;
  }

  modifier onlyBeforeSale {
    if (getBlockNumber() >= initialBlock) throw;
    _;
  }

  modifier onlyDuringSalePeriod {
    if (getBlockNumber() < initialBlock) throw;
    if (getBlockNumber() >= finalBlock) throw;
    _;
  }

  modifier onlyAfterSale {
    if (getBlockNumber() < finalBlock) throw;
    _;
  }

  modifier onlySaleStopped {
    if (!saleStopped) throw;
    _;
  }

  modifier onlySaleNotStopped {
    if (saleStopped) throw;
    _;
  }

  modifier onlyBeforeSaleActivation {
    if (isActivated()) throw;
    _;
  }

  modifier onlySaleActivated {
    if (!isActivated()) throw;
    _;
  }

  modifier onlyFinalizedSale {
    if (getBlockNumber() < finalBlock) throw;
    if (!saleFinalized) throw;
    _;
  }

  modifier nonZeroAddress(address x) {
    if (x == 0) throw;
    _;
  }

  modifier minimumValue(uint256 x) {
    if (msg.value < x) throw;
    _;
  }
}