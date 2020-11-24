 

pragma solidity ^0.4.15;

 
contract Ownable {
  
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);
  
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    assert(_newOwner != address(0));      
    newOwner = _newOwner;
  }

   
  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
  }
}

 
contract SafeMath {

  function sub(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x - y;
    assert(z <= x);
	  return z;
  }

  function add(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x + y;
	  assert(z >= x);
	  return z;
  }
	
  function div(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x / y;
    return z;
  }
	
  function mul(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x * y;
    assert(x == 0 || z / x == y);
    return z;
  }

  function min(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x <= y ? x : y;
    return z;
  }

  function max(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x >= y ? x : y;
    return z;
  }
}


 
contract ERC20 {
	function totalSupply() public constant returns (uint);
	function balanceOf(address owner) public constant returns (uint);
	function allowance(address owner, address spender) public constant returns (uint);
	function transfer(address to, uint value) public returns (bool success);
	function transferFrom(address from, address to, uint value) public returns (bool success);
	function approve(address spender, uint value) public returns (bool success);
	function mint(address to, uint value) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is ERC20, SafeMath, Ownable{
	
  uint256 _totalSupply;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) approvals;
  address public crowdsaleAgent;
  bool public released = false;  
  
   
  modifier onlyPayloadSize(uint numwords) {
    assert(msg.data.length == numwords * 32 + 4);
    _;
  }
  
   
  modifier onlyCrowdsaleAgent() {
    assert(msg.sender == crowdsaleAgent);
    _;
  }

   
  modifier canMint() {
    assert(!released);
    _;
  }
  
   
  modifier canTransfer() {
    assert(released);
    _;
  } 
  
     
  function totalSupply() public constant returns (uint256) {
    return _totalSupply;
  }
  
   
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }
  
      
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return approvals[_owner][_spender];
  }

      
  function transfer(address _to, uint _value) public canTransfer onlyPayloadSize(2) returns (bool success) {
    assert(balances[msg.sender] >= _value);
    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
       
  function transferFrom(address _from, address _to, uint _value) public canTransfer onlyPayloadSize(3) returns (bool success) {
    assert(balances[_from] >= _value);
    assert(approvals[_from][msg.sender] >= _value);
    approvals[_from][msg.sender] = sub(approvals[_from][msg.sender], _value);
    balances[_from] = sub(balances[_from], _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(_from, _to, _value);
    return true;
  }
  
   
  function approve(address _spender, uint _value) public onlyPayloadSize(2) returns (bool success) {
     
     
     
     
    assert((_value == 0) || (approvals[msg.sender][_spender] == 0));
    approvals[msg.sender][_spender] = _value;
    
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
    
  function mint(address _to, uint _value) public onlyCrowdsaleAgent canMint onlyPayloadSize(2) returns (bool success) {
    _totalSupply = add(_totalSupply, _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(0, _to, _value);
    return true;
	
  }
  
   
  function setCrowdsaleAgent(address _crowdsaleAgent) public onlyOwner {
    assert(!released);
    crowdsaleAgent = _crowdsaleAgent;
  }
  
   
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }

}

 
contract DAOPlayMarketToken is StandardToken {
  
  string public name;
  string public symbol;
  uint public decimals;
  
   
  event UpdatedTokenInformation(string newName, string newSymbol);

   
   
  function DAOPlayMarketToken(string _name, string _symbol, uint _initialSupply, uint _decimals, address _addr) public {
    require(_addr != 0x0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
	
    _totalSupply = _initialSupply*10**_decimals;

     
    balances[_addr] = _totalSupply;
  }   
  
    
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}


 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    assert(!halted);
    _;
  }

  modifier onlyInEmergency {
    assert(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }
}


 
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}

 
contract DAOPlayMarketTokenCrowdsale is Haltable, SafeMath, Killable {
  
   
  DAOPlayMarketToken public token;

   
  address public multisigWallet;

   
  uint public startsAt;
  
   
  uint public endsAt;
  
   
  uint public tokensSold = 0;
  
   
  uint public weiRaised = 0;
  
   
  uint public investorCount = 0;
  
   
  bool public finalized;
  
   
  uint public CAP;
  
   
  mapping (address => uint256) public investedAmountOf;
  
   
  mapping (address => uint256) public tokenAmountOf;
  
   
  address public cryptoAgent;
  
   
  mapping (uint => mapping (address => uint256)) public tokenAmountOfPeriod;
  
  struct Stage {
     
    uint start;
     
    uint end;
     
    uint period;
     
    uint price1;
     
    uint price2;
     
    uint price3;
     
    uint price4;
     
    uint cap;
     
    uint tokenSold;
  }
  
   
  Stage[] public stages;
  uint public periodStage;
  uint public stage;
  
   
  enum State{Unknown, Preparing, Funding, Success, Failure, Finalized}
  
   
  event Invested(address investor, uint weiAmount, uint tokenAmount);
  
   
  event InvestedOtherCrypto(address investor, uint weiAmount, uint tokenAmount);

   
  event EndsAtChanged(uint _endsAt);
  
   
  event DistributedTokens(address investor, uint tokenAmount);
  
   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }
  
   
  modifier onlyCryptoAgent() {
    assert(msg.sender == cryptoAgent);
    _;
  }
  
   
  function DAOPlayMarketTokenCrowdsale(address _token, address _multisigWallet, uint _start, uint _cap, uint[20] _price, uint _periodStage, uint _capPeriod) public {
  
    require(_multisigWallet != 0x0);
    require(_start >= block.timestamp);
    require(_cap > 0);
    require(_periodStage > 0);
    require(_capPeriod > 0);
	
    token = DAOPlayMarketToken(_token);
    multisigWallet = _multisigWallet;
    startsAt = _start;
    CAP = _cap*10**token.decimals();
	
    periodStage = _periodStage*1 days;
    uint capPeriod = _capPeriod*10**token.decimals();
    uint j = 0;
    for(uint i=0; i<_price.length; i=i+4) {
      stages.push(Stage(startsAt+j*periodStage, startsAt+(j+1)*periodStage, j, _price[i], _price[i+1], _price[i+2], _price[i+3], capPeriod, 0));
      j++;
    }
    endsAt = stages[stages.length-1].end;
    stage = 0;
  }
  
   
  function() public payable {
    investInternal(msg.sender);
  }

   
  function investInternal(address receiver) private stopInEmergency {
    require(msg.value > 0);
	
    assert(getState() == State.Funding);

     
    stage = getStage();
	
    uint weiAmount = msg.value;

     
    uint tokenAmount = calculateToken(weiAmount, stage, token.decimals());

    assert(tokenAmount > 0);

	 
    assert(stages[stage].cap >= add(tokenAmount, stages[stage].tokenSold));
	
    tokenAmountOfPeriod[stage][receiver]=add(tokenAmountOfPeriod[stage][receiver],tokenAmount);
	
    stages[stage].tokenSold = add(stages[stage].tokenSold,tokenAmount);
	
    if (stages[stage].cap == stages[stage].tokenSold){
      updateStage(stage);
      endsAt = stages[stages.length-1].end;
    }
	
	 
     
	
    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = add(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = add(tokenAmountOf[receiver],tokenAmount);

     
    weiRaised = add(weiRaised,weiAmount);
    tokensSold = add(tokensSold,tokenAmount);

    assignTokens(receiver, tokenAmount);

     
    multisigWallet.transfer(weiAmount);

     
    Invested(receiver, weiAmount, tokenAmount);
	
  }
  
   
  function investOtherCrypto(address receiver, uint _weiAmount) public onlyCryptoAgent stopInEmergency {
    require(_weiAmount > 0);
	
    assert(getState() == State.Funding);

     
    stage = getStage();
	
    uint weiAmount = _weiAmount;

     
    uint tokenAmount = calculateToken(weiAmount, stage, token.decimals());

    assert(tokenAmount > 0);

	 
    assert(stages[stage].cap >= add(tokenAmount, stages[stage].tokenSold));
	
    tokenAmountOfPeriod[stage][receiver]=add(tokenAmountOfPeriod[stage][receiver],tokenAmount);
	
    stages[stage].tokenSold = add(stages[stage].tokenSold,tokenAmount);
	
    if (stages[stage].cap == stages[stage].tokenSold){
      updateStage(stage);
      endsAt = stages[stages.length-1].end;
    }
	
	 
     
	
    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = add(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = add(tokenAmountOf[receiver],tokenAmount);

     
    weiRaised = add(weiRaised,weiAmount);
    tokensSold = add(tokensSold,tokenAmount);

    assignTokens(receiver, tokenAmount);
	
     
    InvestedOtherCrypto(receiver, weiAmount, tokenAmount);
  }
  
   
  function assignTokens(address receiver, uint tokenAmount) private {
     token.mint(receiver, tokenAmount);
  }
   
   
  function isBreakingCap(uint tokenAmount, uint tokensSoldTotal) public constant returns (bool limitBroken){
	if(add(tokenAmount,tokensSoldTotal) <= CAP){
	  return false;
	}
	return true;
  }

   
  function distributionOfTokens() public stopInEmergency {
    require(block.timestamp >= endsAt);
    require(!finalized);
    uint amount;
    for(uint i=0; i<stages.length; i++) {
      if(tokenAmountOfPeriod[stages[i].period][msg.sender] != 0){
        amount = add(amount,div(mul(sub(stages[i].cap,stages[i].tokenSold),tokenAmountOfPeriod[stages[i].period][msg.sender]),stages[i].tokenSold));
        tokenAmountOfPeriod[stages[i].period][msg.sender] = 0;
      }
    }
    assert(amount > 0);
    assignTokens(msg.sender, amount);
	
     
    DistributedTokens(msg.sender, amount);
  }
  
   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(block.timestamp >= (endsAt+periodStage));
    require(!finalized);
	
    finalizeCrowdsale();
    finalized = true;
  }
  
   
  function finalizeCrowdsale() internal {
    token.releaseTokenTransfer();
  }
  
   
  function isCrowdsaleFull() public constant returns (bool) {
    if(tokensSold >= CAP || block.timestamp >= endsAt){
      return true;  
    }
    return false;
  }
  
   
  function setEndsAt(uint time) public onlyOwner {
    require(!finalized);
    require(time >= block.timestamp);
    endsAt = time;
    EndsAtChanged(endsAt);
  }
  
    
  function setMultisig(address addr) public onlyOwner {
    require(addr != 0x0);
    multisigWallet = addr;
  }
  
   
  function setToken(address addr) public onlyOwner {
    require(addr != 0x0);
    token = DAOPlayMarketToken(addr);
  }
  
   
  function getState() public constant returns (State) {
    if (finalized) return State.Finalized;
    else if (address(token) == 0 || address(multisigWallet) == 0 || block.timestamp < startsAt) return State.Preparing;
    else if (block.timestamp <= endsAt && block.timestamp >= startsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isCrowdsaleFull()) return State.Success;
    else return State.Failure;
  }
  
   
  function setBasePrice(uint[20] _price, uint _startDate, uint _periodStage, uint _cap, uint _decimals) public onlyOwner {
    periodStage = _periodStage*1 days;
    uint cap = _cap*10**_decimals;
    uint j = 0;
    delete stages;
    for(uint i=0; i<_price.length; i=i+4) {
      stages.push(Stage(_startDate+j*periodStage, _startDate+(j+1)*periodStage, j, _price[i], _price[i+1], _price[i+2], _price[i+3], cap, 0));
      j++;
    }
    endsAt = stages[stages.length-1].end;
    stage =0;
  }
  
   
  function updateStage(uint number) private {
    require(number>=0);
    uint time = block.timestamp;
    uint j = 0;
    stages[number].end = time;
    for (uint i = number+1; i < stages.length; i++) {
      stages[i].start = time+periodStage*j;
      stages[i].end = time+periodStage*(j+1);
      j++;
    }
  }
  
   
  function getStage() private constant returns (uint){
    for (uint i = 0; i < stages.length; i++) {
      if (block.timestamp >= stages[i].start && block.timestamp < stages[i].end) {
        return stages[i].period;
      }
    }
    return stages[stages.length-1].period;
  }
  
   
  function getAmountCap(uint value) private constant returns (uint ) {
    if(value <= 10*10**18){
      return 0;
    }else if (value <= 50*10**18){
      return 1;
    }else if (value <= 300*10**18){
      return 2;
    }else {
      return 3;
    }
  }
  
   
   
  function calculateToken(uint value, uint _stage, uint decimals) private constant returns (uint){
    uint tokenAmount = 0;
    uint saleAmountCap = getAmountCap(value); 
	
    if(saleAmountCap == 0){
      tokenAmount = div(value*10**decimals,stages[_stage].price1);
    }else if(saleAmountCap == 1){
      tokenAmount = div(value*10**decimals,stages[_stage].price2);
    }else if(saleAmountCap == 2){
      tokenAmount = div(value*10**decimals,stages[_stage].price3);
    }else{
      tokenAmount = div(value*10**decimals,stages[_stage].price4);
    }
    return tokenAmount;
  }
 
   
  function setCryptoAgent(address _cryptoAgent) public onlyOwner {
    require(!finalized);
    cryptoAgent = _cryptoAgent;
  }
}