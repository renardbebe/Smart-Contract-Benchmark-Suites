 

pragma solidity ^0.4.11;


 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 
contract Authorizable is Ownable {

  address[] authorizers;
  mapping(address => uint) authorizerIndex;

   
  modifier onlyAuthorized {
    require(isAuthorized(msg.sender));
    _;
  }

   
  function Authorizable() public {
    authorizers.length = 2;
    authorizers[1] = msg.sender;
    authorizerIndex[msg.sender] = 1;
  }

   
  function getAuthorizer(uint _authorizerIndex) external constant returns(address) {
    return address(authorizers[_authorizerIndex + 1]);
  }

   
  function isAuthorized(address _addr) public constant returns(bool) {
    return authorizerIndex[_addr] > 0;
  }

   
  function addAuthorized(address _addr) external onlyOwner {
    authorizerIndex[_addr] = authorizers.length;
    authorizers.length++;
    authorizers[authorizers.length - 1] = _addr;
  }

}

 
contract ExchangeRate is Ownable, Authorizable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

   
  function updateRate(string _symbol, uint _rate) public onlyAuthorized {
    rates[keccak256(_symbol)] = _rate;
    RateUpdated(now, keccak256(_symbol), _rate);
  }

   
  function updateRates(uint[] data) public onlyAuthorized {
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
    return rates[keccak256(_symbol)];
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

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) public {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
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

   
  function mint(address _to, uint _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract MyToken is MintableToken, Authorizable {

  string public name = "Bonpay Token";
  string public symbol = "BON";
  uint public decimals = 18;

  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

  function mint(address _to, uint _amount) public onlyAuthorized canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() public onlyAuthorized returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

   
  function startTrading() public onlyOwner {
    tradingStarted = true;
  }

   
  function transfer(address _to, uint _value) public hasStartedTrading {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) public hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }

}

 
contract MainSale is Ownable, Authorizable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  event MainSaleClosed();

  MyToken public token;

  address public multisigVault;

  uint hardcap = 200000 ether;
  ExchangeRate public exchangeRate;

  uint public altDeposits = 0;
  uint public start = 0;

   
  modifier saleIsOn() {
    require(now > start && now < start + 28 days);
    _;
  }

   
  modifier isUnderHardCap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
  }

  function MainSale(address _token, address _exchangeRate, address _multisigVault, uint _start) public onlyOwner {
    token = MyToken(_token);
    setExchangeRate(_exchangeRate);
    setMultisigVault(_multisigVault);
    setStart(_start);
  }

   
  function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
    uint rate = exchangeRate.getRate("ETH");
    uint tokens = rate.mul(msg.value).div(1 ether);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, rate);
  }


   
  function setAltDeposit(uint totalAltDeposits) public onlyAuthorized {
    altDeposits = totalAltDeposits;
  }

   
  function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

   
  function setHardCap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
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

   
  function finishMinting() public onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(49).div(51);
    token.mint(multisigVault, restrictedTokens);
    token.finishMinting();
    MainSaleClosed();
  }

   
  function retrieveTokens(address _token) public onlyAuthorized {
    ERC20 othertoken = ERC20(_token);
    othertoken.transfer(multisigVault, othertoken.balanceOf(this));
  }

   
  function() external payable {
    createTokens(msg.sender);
  }

}