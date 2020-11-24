 

pragma solidity ^0.4.13;

contract Math {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assert((z = x + y) >= x);
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assert((z = x - y) <= x);
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assert((z = x * y) >= x);
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x / y;
  }
}

contract Token {
  uint256 public totalSupply;
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ERC20 is Token {

  function name() public pure returns (string) { name; }
  function symbol() public pure returns (string) { symbol; }
  function decimals() public pure returns (uint8) { decimals; }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}

contract owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}

contract EPCToken is ERC20, Math, owned {
   
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  string public version;

   
  event Reward(address indexed _to, uint256 _value);
  event MintToken(address indexed _to, uint256 _value);
  event Burn(address indexed _to, uint256 _value);

   
  function EPCToken(
   string _name,
   string _symbol,
   string _version
  ) public {
    name = _name;
    symbol = _symbol;
    version = _version;
  }

   
  function mintToken(address target, uint256 mintedAmount) public onlyOwner {
    balances[target] += mintedAmount;
    totalSupply += mintedAmount;
    MintToken(target, mintedAmount);
  }

   
  function burn(uint256 amount) public returns (bool success) {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    totalSupply -= amount;
    Burn(msg.sender, amount);
    return true;
  }

   
  function reward(address target, uint256 amount) public onlyOwner {
    balances[target] += amount;
    Reward(target, amount);
  }

   
  function kill() public onlyOwner {
    selfdestruct(owner);
  }
}

contract EPCSale is Math, owned {
  EPCToken public epc;
  uint256 public constant decimals = 18;
   
  bool public isFinalized;   
  uint256 public fundingStartBlock;
  uint256 public fundingEndBlock;
  uint256 public funded;
  uint256 public constant totalCap = 250 * (10**6) * 10**decimals;  

   
  function EPCSale(
   EPCToken _epc,
   uint256 _fundingStartBlock,
   uint256 _fundingEndBlock
  )
  public {
    isFinalized = false;  
    epc = EPCToken(_epc);
    fundingStartBlock = _fundingStartBlock;
    fundingEndBlock = _fundingEndBlock;
  }

   
  function crowdSale() public payable {
    require(!isFinalized);
    assert(block.number >= fundingStartBlock);
    assert(block.number <= fundingEndBlock);
    require(msg.value > 0);
    uint256 tokens = mul(msg.value, exchangeRate());  
    funded = add(funded, tokens);
    assert(funded <= totalCap);
    assert(epc.transfer(msg.sender, tokens));
  }

   
  function exchangeRate() public constant returns(uint256) {
    if (block.number<=fundingStartBlock+43200) return 10000;  
    if (block.number<=fundingStartBlock+2*43200) return 8000;  
    return 7000;  
  }

   
  function testExchangeRate(uint blockNumber) public constant returns(uint256) {
    if (blockNumber <= fundingStartBlock+43200) return 10000;  
    if (blockNumber <= fundingStartBlock+2*43200) return 8000;  
    return 7000;  
  }

   
  function testFunded(uint256 amount) public constant returns(uint256) {
    uint256 tokens = mul(amount, exchangeRate());
    return add(funded, tokens);
  }

   
  function () public payable {
    crowdSale();
  }

   
  function withdrawal() public onlyOwner {
    msg.sender.transfer(this.balance);
  }

   
  function stop() public onlyOwner {
    isFinalized = true;
  }

   
  function start() public onlyOwner {
    isFinalized = false;
  }

   
  function retrieveTokens(uint256 amount) public onlyOwner {
    assert(epc.transfer(owner, amount));
  }

   
  function kill() public onlyOwner {
    epc.transfer(owner, epc.balanceOf(this));
    selfdestruct(owner);
  }
}