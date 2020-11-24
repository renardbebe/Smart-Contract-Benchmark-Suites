 

pragma solidity ^0.4.19;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

   
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

 

 
 
pragma solidity ^0.4.19;

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

 

 
pragma solidity ^0.4.19;


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
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

 

contract Validating {

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier notZero(uint _number) {
    require(_number != 0);
    _;
  }

  modifier notEmpty(string _string) {
    require(bytes(_string).length != 0);
    _;
  }

}

 

 
contract Fee is Owned, Validating, StandardToken {

   
  event Burn(address indexed from, uint256 value);

  string public name;                    
  uint8 public decimals;                 
  string public symbol;                  
  string public version = 'F0.2';        
  address public minter;

  modifier onlyMinter {
    require(msg.sender == minter);
    _;
  }

   
  function Fee(
  address[] _owners,
  string _tokenName,
  uint8 _decimalUnits,
  string _tokenSymbol
  )
  public
  notEmpty(_tokenName)
  notEmpty(_tokenSymbol)
  {
    setOwners(_owners);
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
  }

   
   
  function setMinter(address _minter) external onlyOwner validAddress(_minter) {
    minter = _minter;
  }

   
   
  function burnTokens(uint _value) public notZero(_value) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    totalSupply = SafeMath.sub(totalSupply, _value);
    Burn(msg.sender, _value);
  }

   
   
   
   
  function sendTokens(address _to, uint _value) public onlyMinter validAddress(_to) notZero(_value) {
    balances[_to] = SafeMath.add(balances[_to], _value);
    totalSupply = SafeMath.add(totalSupply, _value);
    Transfer(0x0, _to, _value);
  }
}

 

contract GenericCall {

   
  modifier isAllowed {_;}
   

  event Execution(address destination, uint value, bytes data);

  function execute(address destination, uint value, bytes data) external isAllowed {
    if (destination.call.value(value)(data)) {
      Execution(destination, value, data);
    }
  }
}

 

 
pragma solidity ^0.4.19;








contract Stake is Owned, Validating, GenericCall {
  using SafeMath for uint;

  event StakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock);

  event RedeemEvent(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock);

  event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock);

  event StakingInterval(uint startBlock, uint endBlock);

   
  mapping (address => uint) public levBlocks;

   
  mapping (address => uint) public stakes;

  uint public totalLevs;

   
  uint public totalLevBlocks;

   
  uint public weiPerFee;

   
  uint public feeForTheStakingInterval;

   
  Token public levToken;  

   
  Fee public feeToken;  

  uint public startBlock;

  uint public endBlock;

  address public wallet;

  bool public feeCalculated = false;

  modifier isStaking {
    require(startBlock <= block.number && block.number < endBlock);
    _;
  }

  modifier isDoneStaking {
    require(block.number >= endBlock);
    _;
  }

  modifier isAllowed{
    require(isOwner[msg.sender]);
    _;
  }

  function() public payable {
  }

   
   
  function Stake(
  address[] _owners,
  address _operator,
  address _wallet,
  uint _weiPerFee,
  address _levToken
  ) public
  validAddress(_wallet)
  validAddress(_operator)
  validAddress(_levToken)
  notZero(_weiPerFee)
  {
    setOwners(_owners);
    operator = _operator;
    wallet = _wallet;
    weiPerFee = _weiPerFee;
    levToken = Token(_levToken);
  }

  function version() external pure returns (string) {
    return "1.0.0";
  }

   
   
  function setLevToken(address _levToken) external validAddress(_levToken) onlyOwner {
    levToken = Token(_levToken);
  }

   
   
  function setFeeToken(address _feeToken) external validAddress(_feeToken) onlyOwner {
    feeToken = Fee(_feeToken);
  }

   
   
  function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
    wallet = _wallet;
  }

   
   
   
   
  function stakeTokens(uint _quantity) external isStaking notZero(_quantity) {
    require(levToken.allowance(msg.sender, this) >= _quantity);

    levBlocks[msg.sender] = levBlocks[msg.sender].add(_quantity.mul(endBlock.sub(block.number)));
    stakes[msg.sender] = stakes[msg.sender].add(_quantity);
    totalLevBlocks = totalLevBlocks.add(_quantity.mul(endBlock.sub(block.number)));
    totalLevs = totalLevs.add(_quantity);
    require(levToken.transferFrom(msg.sender, this, _quantity));
    StakeEvent(msg.sender, _quantity, startBlock, endBlock);
  }

  function revertFeeCalculatedFlag(bool _flag) external onlyOwner isDoneStaking {
    feeCalculated = _flag;
  }

   
   
  function updateFeeForCurrentStakingInterval() external onlyOperator isDoneStaking {
    require(feeCalculated == false);
    uint feeReceived = feeToken.balanceOf(this);
    feeForTheStakingInterval = feeForTheStakingInterval.add(feeReceived.add(this.balance.div(weiPerFee)));
    feeCalculated = true;
    FeeCalculated(feeForTheStakingInterval, feeReceived, this.balance, startBlock, endBlock);
    if (feeReceived > 0) feeToken.burnTokens(feeReceived);
    if (this.balance > 0) wallet.transfer(this.balance);
  }

   
  function redeemLevAndFeeByStaker() external {
    redeemLevAndFee(msg.sender);
  }

  function redeemLevAndFeeToStakers(address[] _stakers) external onlyOperator {
    for (uint i = 0; i < _stakers.length; i++) redeemLevAndFee(_stakers[i]);
  }

  function redeemLevAndFee(address _staker) private validAddress(_staker) isDoneStaking {
    require(feeCalculated);
    require(totalLevBlocks > 0);

    uint levBlock = levBlocks[_staker];
    uint stake = stakes[_staker];
    require(stake > 0);

    uint feeEarned = levBlock.mul(feeForTheStakingInterval).div(totalLevBlocks);
    delete stakes[_staker];
    delete levBlocks[_staker];
    totalLevs = totalLevs.sub(stake);
    if (feeEarned > 0) feeToken.sendTokens(_staker, feeEarned);
    require(levToken.transfer(_staker, stake));
    RedeemEvent(_staker, stake, feeEarned, startBlock, endBlock);
  }

   
   
   
  function startNewStakingInterval(uint _start, uint _end)
  external
  notZero(_start)
  notZero(_end)
  onlyOperator
  isDoneStaking
  {
    require(totalLevs == 0);

    startBlock = _start;
    endBlock = _end;

     
    totalLevBlocks = 0;
    feeForTheStakingInterval = 0;
    feeCalculated = false;
    StakingInterval(_start, _end);
  }

}