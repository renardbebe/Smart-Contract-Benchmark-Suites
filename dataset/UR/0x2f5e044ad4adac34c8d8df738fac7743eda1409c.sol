 

pragma solidity ^0.4.8;

contract ERC20Interface {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AgoraToken is ERC20Interface {

  string public constant name = "Agora";
  string public constant symbol = "AGO";
  uint8  public constant decimals = 18;

  uint256 constant minimumToRaise = 500 ether;
  uint256 constant icoStartBlock = 4116800;
  uint256 constant icoPremiumEndBlock = icoStartBlock + 78776;  
  uint256 constant icoEndBlock = icoStartBlock + 315106;  

  address owner;
  uint256 raised = 0;
  uint256 created = 0;

  struct BalanceSnapshot {
    bool initialized;
    uint256 value;
  }

  mapping(address => uint256) shares;
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(uint256 => mapping (address => BalanceSnapshot)) balancesAtBlock;

  function AgoraToken() {
    owner = msg.sender;
  }

   
   
   

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _value) returns (bool success) {
     
    require(msg.sender != owner && _to != owner);

    if (balances[msg.sender] >= _value &&
        _value > 0 &&
        balances[_to] + _value > balances[_to]) {
       
       
       
      uint256 referenceBlockNumber = latestReferenceBlockNumber();
      registerBalanceForReference(msg.sender, referenceBlockNumber);
      registerBalanceForReference(_to, referenceBlockNumber);

       
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     
    require(_to != owner);

    if(balances[_from] >= _value &&
       _value > 0 &&
       allowed[_from][msg.sender] >= _value &&
       balances[_to] + _value > balances[_to]) {
       
       
       
       
      uint256 referenceBlockNumber = latestReferenceBlockNumber();
      registerBalanceForReference(_from, referenceBlockNumber);
      registerBalanceForReference(_to, referenceBlockNumber);

       
      balances[_from] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

   
  function approve(address _spender, uint256 _value) returns (bool success) {
     
    require(msg.sender != owner);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function totalSupply() constant returns (uint256 totalSupply) { return created; }

   
   
   

   
  function icoOverview() constant returns(
    uint256 currentlyRaised,
    uint256 tokensCreated,
    uint256 developersTokens
  ){
    currentlyRaised = raised;
    tokensCreated = created;
    developersTokens = balances[owner];
  }

   
  function buy() payable {
    require(block.number > icoStartBlock && block.number < icoEndBlock && msg.sender != owner);

    uint256 tokenAmount = msg.value * ((block.number < icoPremiumEndBlock) ? 550 : 500);

    shares[msg.sender] += msg.value;
    balances[msg.sender] += tokenAmount;
    balances[owner] += tokenAmount / 6;

    raised += msg.value;
    created += tokenAmount;
  }

   
   
   
  function withdraw(uint256 amount) {
    require(block.number > icoEndBlock && raised >= minimumToRaise && msg.sender == owner);
    owner.transfer(amount);
  }

   
  function refill() {
    require(block.number > icoEndBlock && raised < minimumToRaise);
    uint256 share = shares[msg.sender];
    shares[msg.sender] = 0;
    msg.sender.transfer(share);
  }

   
   
   
   
   
   

   
   
   
   
   
  function registerBalanceForReference(address _owner, uint256 referenceBlockNumber) private {
    if (balancesAtBlock[referenceBlockNumber][_owner].initialized) { return; }
    balancesAtBlock[referenceBlockNumber][_owner].initialized = true;
    balancesAtBlock[referenceBlockNumber][_owner].value = balances[_owner];
  }

   
  function latestReferenceBlockNumber() constant returns (uint256 blockNumber) {
    return (block.number - block.number % 157553);
  }

   
   
   
   
   
   
  function balanceAtBlock(address _owner, uint256 blockNumber) constant returns (uint256 balance) {
    if(balancesAtBlock[blockNumber][_owner].initialized) {
      return balancesAtBlock[blockNumber][_owner].value;
    }
    return balances[_owner];
  }
}