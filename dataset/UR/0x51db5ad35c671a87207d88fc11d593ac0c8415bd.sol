 

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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract HasNoTokens is Ownable {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    revert();
  }

   
  function reclaimToken(address tokenAddr) external onlyOwner {
    ERC20Basic tokenInst = ERC20Basic(tokenAddr);
    uint256 balance = tokenInst.balanceOf(this);
    tokenInst.transfer(owner, balance);
  }
}

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

contract MigrationAgent {
   
  uint256 public constant MIGRATE_MAGIC_ID = 0x6e538c0d750418aae4131a91e5a20363;

   
  function migrateTo(address beneficiary, uint256 amount) external;
}

 
 
contract MoedaToken is StandardToken, Ownable, HasNoTokens {
  string public constant name = "Moeda Loyalty Points";
  string public constant symbol = "MDA";
  uint8 public constant decimals = 18;

   
   
   
  MigrationAgent public migrationAgent;

   
  uint256 constant AGENT_MAGIC_ID = 0x6e538c0d750418aae4131a91e5a20363;
  uint256 public totalMigrated;

  uint constant TOKEN_MULTIPLIER = 10**uint256(decimals);
   
  uint public constant MAX_TOKENS = 20000000 * TOKEN_MULTIPLIER;

   
  bool public mintingFinished;

   
  event LogMigration(address indexed spender, address grantee, uint256 amount);
  event LogCreation(address indexed donor, uint256 tokensReceived);
  event LogDestruction(address indexed sender, uint256 amount);
  event LogMintingFinished();

  modifier afterMinting() {
    require(mintingFinished);
    _;
  }

  modifier canTransfer(address recipient) {
    require(mintingFinished && recipient != address(0));
    _;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function MoedaToken() {
     
    issueTokens();
  }

  function issueTokens() internal {
    mint(0x2f37be861699b6127881693010596B4bDD146f5e, MAX_TOKENS);
  }

   
   
  function setMigrationAgent(address agent) external onlyOwner afterMinting {
    require(agent != address(0) && isContract(agent));
    require(MigrationAgent(agent).MIGRATE_MAGIC_ID() == AGENT_MAGIC_ID);
    require(migrationAgent == address(0));
    migrationAgent = MigrationAgent(agent);
  }

  function isContract(address addr) internal constant returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

   
   
   
  function migrate(address beneficiary, uint256 amount) external afterMinting {
    require(beneficiary != address(0));
    require(migrationAgent != address(0));
    require(amount > 0);

     
    balances[msg.sender] = balances[msg.sender].sub(amount);
    totalSupply = totalSupply.sub(amount);
    totalMigrated = totalMigrated.add(amount);
    migrationAgent.migrateTo(beneficiary, amount);

    LogMigration(msg.sender, beneficiary, amount);
  }

   
   
  function burn(uint256 amount) external {
    require(amount > 0);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    totalSupply = totalSupply.sub(amount);

    LogDestruction(msg.sender, amount);
  }

   
  function unlock() external onlyOwner canMint {
    mintingFinished = true;
    LogMintingFinished();
  }

   
   
   
  function mint(address recipient, uint256 amount) internal canMint {
    require(amount > 0);
    require(totalSupply.add(amount) <= MAX_TOKENS);

    balances[recipient] = balances[recipient].add(amount);
    totalSupply = totalSupply.add(amount);

    LogCreation(recipient, amount);
  }

   
   
  function transfer(address to, uint _value)
  public canTransfer(to) returns (bool)
  {
    return super.transfer(to, _value);
  }

   
   
  function transferFrom(address from, address to, uint value)
  public canTransfer(to) returns (bool)
  {
    return super.transferFrom(from, to, value);
  }
}