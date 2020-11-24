 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
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
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract CryptoABS is StandardToken, Ownable {
  string public name;                                    
  string public symbol;                                  
  uint256 public decimals = 0;                           
  address public contractAddress;                        

  uint256 public minInvestInWei;                         
  uint256 public tokenExchangeRateInWei;                 

  uint256 public startBlock;                             
  uint256 public endBlock;                               
  uint256 public maxTokenSupply;                         
  
  uint256 public initializedTime;                        
  uint256 public financingPeriod;                        
  uint256 public tokenLockoutPeriod;                     
  uint256 public tokenMaturityPeriod;                    

  bool public paused;                                    
  bool public initialized;                               
  uint256 public finalizedBlock;                         
  uint256 public finalizedTime;                          
  uint256 public finalizedCapital;                       

  struct ExchangeRate {
    uint256 blockNumber;                                 
    uint256 exchangeRateInWei;                           
  }

  ExchangeRate[] public exchangeRateArray;               
  uint256 public nextExchangeRateIndex;                  
  
  uint256[] public interestArray;                        

  struct Payee {
    bool isExists;                                       
    bool isPayable;                                      
    uint256 interestInWei;                               
  }

  mapping (address => Payee) public payees; 
  address[] public payeeArray;                           
  uint256 public nextPayeeIndex;                         

  struct Asset {
    string data;                                         
  }

  Asset[] public assetArray;                             

   
  modifier notPaused() {
    require(paused == false);
    _;
  }

   
  modifier isPaused() {
    require(paused == true);
    _;
  }

   
  modifier isPayee() {
    require(payees[msg.sender].isPayable == true);
    _;
  }

   
  modifier isInitialized() {
    require(initialized == true);
    _;
  }

   
  modifier isContractOpen() {
    require(
      getBlockNumber() >= startBlock &&
      getBlockNumber() <= endBlock &&
      finalizedBlock == 0);
    _;
  }

   
  modifier notLockout() {
    require(now > (initializedTime + financingPeriod + tokenLockoutPeriod));
    _;
  }
  
   
  modifier overMaturity() {
    require(now > (initializedTime + financingPeriod + tokenMaturityPeriod));
    _;
  }

   
  function CryptoABS() {
    paused = false;
  }

   
  function initialize(
      string _name,
      string _symbol,
      uint256 _decimals,
      address _contractAddress,
      uint256 _startBlock,
      uint256 _endBlock,
      uint256 _initializedTime,
      uint256 _financingPeriod,
      uint256 _tokenLockoutPeriod,
      uint256 _tokenMaturityPeriod,
      uint256 _minInvestInWei,
      uint256 _maxTokenSupply,
      uint256 _tokenExchangeRateInWei,
      uint256 _exchangeRateInWei) onlyOwner {
    require(bytes(name).length == 0);
    require(bytes(symbol).length == 0);
    require(decimals == 0);
    require(contractAddress == 0x0);
    require(totalSupply == 0);
    require(decimals == 0);
    require(_startBlock >= getBlockNumber());
    require(_startBlock < _endBlock);
    require(financingPeriod == 0);
    require(tokenLockoutPeriod == 0);
    require(tokenMaturityPeriod == 0);
    require(initializedTime == 0);
    require(_maxTokenSupply >= totalSupply);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    contractAddress = _contractAddress;
    startBlock = _startBlock;
    endBlock = _endBlock;
    initializedTime = _initializedTime;
    financingPeriod = _financingPeriod;
    tokenLockoutPeriod = _tokenLockoutPeriod;
    tokenMaturityPeriod = _tokenMaturityPeriod;
    minInvestInWei = _minInvestInWei;
    maxTokenSupply = _maxTokenSupply;
    tokenExchangeRateInWei = _tokenExchangeRateInWei;
    ownerSetExchangeRateInWei(_exchangeRateInWei);
    initialized = true;
  }

   
  function finalize() public isInitialized {
    require(getBlockNumber() >= startBlock);
    require(msg.sender == owner || getBlockNumber() > endBlock);

    finalizedBlock = getBlockNumber();
    finalizedTime = now;

    Finalized();
  }

   
  function () payable notPaused {
    proxyPayment(msg.sender);
  }

   
  function proxyPayment(address _payee) public payable notPaused isInitialized isContractOpen returns (bool) {
    require(msg.value > 0);

    uint256 amount = msg.value;
    require(amount >= minInvestInWei); 

    uint256 refund = amount % tokenExchangeRateInWei;
    uint256 tokens = (amount - refund) / tokenExchangeRateInWei;
    require(totalSupply.add(tokens) <= maxTokenSupply);
    totalSupply = totalSupply.add(tokens);
    balances[_payee] = balances[_payee].add(tokens);

    if (payees[msg.sender].isExists != true) {
      payees[msg.sender].isExists = true;
      payees[msg.sender].isPayable = true;
      payeeArray.push(msg.sender);
    }

    require(owner.send(amount - refund));
    if (refund > 0) {
      require(msg.sender.send(refund));
    }
    return true;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) notLockout notPaused isInitialized {
    require(_to != contractAddress);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (payees[_to].isExists != true) {
      payees[_to].isExists = true;
      payees[_to].isPayable = true;
      payeeArray.push(_to);
    }
    Transfer(msg.sender, _to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) notLockout notPaused isInitialized {
    require(_to != contractAddress);
    require(_from != contractAddress);
    var _allowance = allowed[_from][msg.sender];

     
     
    require(_allowance >= _value);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    if (payees[_to].isExists != true) {
      payees[_to].isExists = true;
      payees[_to].isPayable = true;
      payeeArray.push(_to);
    }
    Transfer(_from, _to, _value);
  }

   
  function ownerDepositInterest() onlyOwner isPaused isInitialized {
    uint256 i = nextPayeeIndex;
    uint256 payeesLength = payeeArray.length;
    while (i < payeesLength && msg.gas > 2000000) {
      address _payee = payeeArray[i];
      uint256 _balance = balances[_payee];
      if (payees[_payee].isPayable == true && _balance > 0) {
        uint256 _interestInWei = (_balance * interestArray[getInterestCount() - 1]) / totalSupply;
        payees[_payee].interestInWei += _interestInWei;
        DepositInterest(getInterestCount(), _payee, _balance, _interestInWei);
      }
      i++;
    }
    nextPayeeIndex = i;
  }

   
  function interestOf(address _address) isInitialized constant returns (uint256 result)  {
    require(payees[_address].isExists == true);
    return payees[_address].interestInWei;
  }

   
  function payeeWithdrawInterest(uint256 _interestInWei) payable isPayee isInitialized notLockout {
    require(msg.value == 0);
    uint256 interestInWei = _interestInWei;
    require(payees[msg.sender].isPayable == true && _interestInWei <= payees[msg.sender].interestInWei);
    require(msg.sender.send(interestInWei));
    payees[msg.sender].interestInWei -= interestInWei;
    PayeeWithdrawInterest(msg.sender, interestInWei, payees[msg.sender].interestInWei);
  }

   
  function payeeWithdrawCapital() payable isPayee isPaused isInitialized overMaturity {
    require(msg.value == 0);
    require(balances[msg.sender] > 0 && totalSupply > 0);
    uint256 capital = (balances[msg.sender] * finalizedCapital) / totalSupply;
    balances[msg.sender] = 0;
    require(msg.sender.send(capital));
    PayeeWithdrawCapital(msg.sender, capital);
  }

   
  function ownerPauseContract() onlyOwner {
    paused = true;
  }

   
  function ownerResumeContract() onlyOwner {
    paused = false;
  }

   
  function ownerSetExchangeRateInWei(uint256 _exchangeRateInWei) onlyOwner {
    require(_exchangeRateInWei > 0);
    var _exchangeRate = ExchangeRate( getBlockNumber(), _exchangeRateInWei);
    exchangeRateArray.push(_exchangeRate);
    nextExchangeRateIndex = exchangeRateArray.length;
  }

   
  function ownerDisablePayee(address _address) onlyOwner {
    require(_address != owner);
    payees[_address].isPayable = false;
  }

   
  function ownerEnablePayee(address _address) onlyOwner {
    payees[_address].isPayable = true;
  }

   
  function getPayeeCount() constant returns (uint256) {
    return payeeArray.length;
  }

   
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

   
  function ownerAddAsset(string _data) onlyOwner {
    var _asset = Asset(_data);
    assetArray.push(_asset);
  }

   
  function getAssetCount() constant returns (uint256 result) {
    return assetArray.length;
  }

   
  function ownerPutCapital() payable isInitialized isPaused onlyOwner {
    require(msg.value > 0);
    finalizedCapital = msg.value;
  }

   
  function ownerPutInterest(uint256 _terms) payable isInitialized isPaused onlyOwner {
    require(_terms == (getInterestCount() + 1));
    interestArray.push(msg.value);
  }

   
  function getInterestCount() constant returns (uint256 result) {
    return interestArray.length;
  }

   
  function ownerWithdraw() payable isInitialized onlyOwner {
    require(owner.send(this.balance));
  }

  event PayeeWithdrawCapital(address _payee, uint256 _capital);
  event PayeeWithdrawInterest(address _payee, uint256 _interest, uint256 _remainInterest);
  event DepositInterest(uint256 _terms, address _payee, uint256 _balance, uint256 _interest);
  event Finalized();
}