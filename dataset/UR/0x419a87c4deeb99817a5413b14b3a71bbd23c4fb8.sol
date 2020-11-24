 

pragma solidity 0.4.19;

 
contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Authorizable {

  address[] authorizers;
  mapping(address => uint) authorizerIndex;

   
  modifier onlyAuthorized {
    require(isAuthorized(msg.sender));
    _;
  }

   
  function Authorizable() {
    authorizers.length = 2;
    authorizers[1] = msg.sender;
    authorizerIndex[msg.sender] = 1;
  }

   
  function getAuthorizer(uint authorizerIndex) external constant returns(address) {
    return address(authorizers[authorizerIndex + 1]);
  }

   
  function isAuthorized(address _addr) constant returns(bool) {
    return authorizerIndex[_addr] > 0;
  }

   
  function addAuthorized(address _addr) external onlyAuthorized {
    authorizerIndex[_addr] = authorizers.length;
    authorizers.length++;
    authorizers[authorizers.length - 1] = _addr;
  }

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

}


 
contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

   
  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[sha3(_symbol)] = _rate;
    RateUpdated(now, sha3(_symbol), _rate);
  }

   
  function updateRates(uint[] data) public onlyOwner {
    require(data.length % 2 == 0);
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      RateUpdated(now, symbol, rate);
      i++;
    }
  }

   
  function getRate(string _symbol) public constant returns(uint) {
    return rates[sha3(_symbol)];
  }

}


 
contract HardCap is Ownable {
  using SafeMath for uint;
  event CapUpdated(uint timestamp, bytes32 symbol, uint rate);
  
  mapping(bytes32 => uint) public caps;
  uint hardcap = 0;

   
  function updateCap(string _symbol, uint _cap) public onlyOwner {
    caps[sha3(_symbol)] = _cap;
    hardcap = hardcap.add(_cap) ;
    CapUpdated(now, sha3(_symbol), _cap);
  }

   
  function updateCaps(uint[] data) public onlyOwner {
    require(data.length % 2 == 0);
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint cap = data[i * 2 + 1];
      caps[symbol] = cap;
      hardcap = hardcap.add(cap);
      CapUpdated(now, symbol, cap);
      i++;
    }
  }

   
  function getCap(string _symbol) public constant returns(uint) {
    return caps[sha3(_symbol)];
  }
  
   
  function getHardCap() public constant returns(uint) {
    return hardcap;
  }

}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
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

     
     
     
     
    require(_value == 0);
    require(allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}


 
contract AbleToken is MintableToken {

  string public name = "ABLE Token";
  string public symbol = "ABLE";
  uint public decimals = 18;

  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() onlyOwner {
    tradingStarted = true;
  }
  
   
  function stopTrading() onlyOwner {
    tradingStarted = false;
  }

   
  function transfer(address _to, uint _value) hasStartedTrading {
    super.transfer(_to, _value);
  }

    
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }

}


 
contract MainSale is Ownable, Authorizable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  event hardcapChanged(uint[] hardcap);
  event salePreiodChanged(uint salePeriod);
  event MainSaleClosed();

  AbleToken public token = new AbleToken();

  address public multisigVault;
  
  ExchangeRate public exchangeRate;
  HardCap public hardCap;
  string public salePeriod = "";
  uint public ethDeposits = 0;
  uint public altDeposits = 0;
  uint public start = 1519614000;  

   
  modifier saleIsOn() {
    require(now > start && now < start + 30 days);
    _;
  }

   
  modifier isUnderHardCap() {
    require(ethDeposits + altDeposits <= hardCap.getCap(salePeriod));
    _;
  }

   
  function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
    uint rate;
    rate = exchangeRate.getRate(salePeriod);
    uint tokens = rate.mul(msg.value);
    ethDeposits = ethDeposits.add(msg.value);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, rate);
  }


   
  function setAltDeposit(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
  }

   
  function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }


   
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

   
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
    }
  }

   
  function setExchangeRate(address _exchangeRate) public onlyOwner {
    exchangeRate = ExchangeRate(_exchangeRate);
  }
  
   
  function setHardCap(address _hardCap) public onlyOwner {
    hardCap = HardCap(_hardCap);
  }
  
   
  function setSalePeriod(string _salePeriod) public onlyOwner {
    salePeriod = _salePeriod;
    ethDeposits = 0;
  }

   
  function finishMinting() public onlyOwner {
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }
  
   
  function startTrading() public onlyOwner {
    token.startTrading();
  }
  
   
  function stopTrading() public onlyOwner {
    token.stopTrading();
  }

   
  function retrieveTokens(address _token) public onlyOwner {
    ERC20 token = ERC20(_token);
    token.transfer(multisigVault, token.balanceOf(this));
  }

   
  function() external payable {
    createTokens(msg.sender);
  }

}