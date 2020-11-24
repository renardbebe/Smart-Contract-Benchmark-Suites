 

pragma solidity ^0.4.24;


 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}





 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


















 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



 
contract MineableToken is MintableToken { 
  event Commit(address indexed from, uint value,uint atStake, int onBlockReward);
  event Withdraw(address indexed from, uint reward, uint commitment);

  uint256 totalStake_ = 0;
  int256 blockReward_;          

  struct Commitment {
    uint256 value;              
    uint256 onBlockNumber;      
    uint256 atStake;            
    int256 onBlockReward;
  }

  mapping( address => Commitment ) miners;

   
  function commit(uint256 _value) public returns (uint256 commitmentValue) {
    require(0 < _value);
    require(_value <= balances[msg.sender]);
    
    commitmentValue = _value;
    uint256 prevCommit = miners[msg.sender].value;
     
     
    if (0 < prevCommit) {
       
      uint256 prevReward;
      (prevReward, prevCommit) = withdraw();
      commitmentValue = prevReward.add(prevCommit).add(_value);
    }

     
    balances[msg.sender] = balances[msg.sender].sub(commitmentValue);
    emit Transfer(msg.sender, address(0), commitmentValue);

    totalStake_ = totalStake_.add(commitmentValue);

    miners[msg.sender] = Commitment(
      commitmentValue,  
      block.number,  
      totalStake_,  
      blockReward_  
      );
    
    emit Commit(msg.sender, commitmentValue, totalStake_, blockReward_);  

    return commitmentValue;
  }

   
  function withdraw() public returns (uint256 reward, uint256 commitmentValue) {
    require(miners[msg.sender].value > 0); 

     
    reward = getReward(msg.sender);

    Commitment storage commitment = miners[msg.sender];
    commitmentValue = commitment.value;

    uint256 withdrawnSum = commitmentValue.add(reward);
    
    totalStake_ = totalStake_.sub(commitmentValue);
    totalSupply_ = totalSupply_.add(reward);
    
    balances[msg.sender] = balances[msg.sender].add(withdrawnSum);
    emit Transfer(address(0), msg.sender, commitmentValue.add(reward));
    
    delete miners[msg.sender];
    
    emit Withdraw(msg.sender, reward, commitmentValue);   
    return (reward, commitmentValue);
  }

    
  function getReward(address _miner) public view returns (uint256) {
    if (miners[_miner].value == 0) {
      return 0;
    }

    Commitment storage commitment = miners[_miner];

    int256 averageBlockReward = signedAverage(commitment.onBlockReward, blockReward_);
    
    require(0 <= averageBlockReward);
    
    uint256 effectiveBlockReward = uint256(averageBlockReward);
    
    uint256 effectiveStake = average(commitment.atStake, totalStake_);
    
    uint256 numberOfBlocks = block.number.sub(commitment.onBlockNumber);

    uint256 miningReward = numberOfBlocks.mul(effectiveBlockReward).mul(commitment.value).div(effectiveStake);
       
    return miningReward;
  }

   
  function average(uint256 a, uint256 b) public pure returns (uint256) {
    return a.add(b).div(2);
  }

   
  function signedAverage(int256 a, int256 b) public pure returns (int256) {
    int256 ans = a + b;

    if (a > 0 && b > 0 && ans <= 0) {
      require(false);
    }
    if (a < 0 && b < 0 && ans >= 0) {
      require(false);
    }

    return ans / 2;
  }

   
  function commitmentOf(address _miner) public view returns (uint256) {
    return miners[_miner].value;
  }

   
  function getCommitment(address _miner) public view 
  returns (
    uint256 value,              
    uint256 onBlockNumber,      
    uint256 atStake,            
    int256 onBlockReward        
    ) 
  {
    value = miners[_miner].value;
    onBlockNumber = miners[_miner].onBlockNumber;
    atStake = miners[_miner].atStake;
    onBlockReward = miners[_miner].onBlockReward;
  }

   
  function totalStake() public view returns (uint256) {
    return totalStake_;
  }

   
  function blockReward() public view returns (int256) {
    return blockReward_;
  }
}


 
contract MCoinDistribution is Ownable {
  using SafeMath for uint256;

  event Commit(address indexed from, uint256 value, uint256 window);
  event Withdraw(address indexed from, uint256 value, uint256 window);
  event MoveFunds(uint256 value);

  MineableToken public MCoin;

  uint256 public firstPeriodWindows;
  uint256 public firstPeriodSupply;
 
  uint256 public secondPeriodWindows;
  uint256 public secondPeriodSupply;
  
  uint256 public totalWindows;   

  address public foundationWallet;

  uint256 public startTimestamp;
  uint256 public windowLength;          

  mapping (uint256 => uint256) public totals;
  mapping (address => mapping (uint256 => uint256)) public commitment;
  
  constructor(
    uint256 _firstPeriodWindows,
    uint256 _firstPeriodSupply,
    uint256 _secondPeriodWindows,
    uint256 _secondPeriodSupply,
    address _foundationWallet,
    uint256 _startTimestamp,
    uint256 _windowLength
  ) public 
  {
    require(0 < _firstPeriodWindows);
    require(0 < _firstPeriodSupply);
    require(0 < _secondPeriodWindows);
    require(0 < _secondPeriodSupply);
    require(0 < _startTimestamp);
    require(0 < _windowLength);
    require(_foundationWallet != address(0));
    
    firstPeriodWindows = _firstPeriodWindows;
    firstPeriodSupply = _firstPeriodSupply;
    secondPeriodWindows = _secondPeriodWindows;
    secondPeriodSupply = _secondPeriodSupply;
    foundationWallet = _foundationWallet;
    startTimestamp = _startTimestamp;
    windowLength = _windowLength;

    totalWindows = firstPeriodWindows.add(secondPeriodWindows);
    require(currentWindow() == 0);
  }

   
  function () public payable {
    commit();
  }

   
  function init(MineableToken _MCoin) public onlyOwner {
    require(address(MCoin) == address(0));
    require(_MCoin.owner() == address(this));
    require(_MCoin.totalSupply() == 0);

    MCoin = _MCoin;
    MCoin.mint(address(this), firstPeriodSupply.add(secondPeriodSupply));
    MCoin.finishMinting();
  }

   
  function allocationFor(uint256 window) view public returns (uint256) {
    require(window < totalWindows);
    
    return (window < firstPeriodWindows) 
      ? firstPeriodSupply.div(firstPeriodWindows) 
      : secondPeriodSupply.div(secondPeriodWindows);
  }

   
  function windowOf(uint256 timestamp) view public returns (uint256) {
    return (startTimestamp < timestamp) 
      ? timestamp.sub(startTimestamp).div(windowLength) 
      : 0;
  }

   
  function detailsOf(uint256 window) view public 
    returns (
      uint256 start,   
      uint256 end,     
      uint256 remainingTime,  
      uint256 allocation,     
      uint256 totalEth,       
      uint256 number          
    ) 
    {
    require(window < totalWindows);
    start = startTimestamp.add(windowLength.mul(window));
    end = start.add(windowLength);
    remainingTime = (block.timestamp < end)  
      ? end.sub(block.timestamp)             
      : 0; 

    allocation = allocationFor(window);
    totalEth = totals[window];
    return (start, end, remainingTime, allocation, totalEth, window);
  }

   
  function detailsOfWindow() view public
    returns (
      uint256 start,   
      uint256 end,     
      uint256 remainingTime,  
      uint256 allocation,     
      uint256 totalEth,       
      uint256 number          
    )
  {
    return (detailsOf(currentWindow()));
  }

   
  function currentWindow() view public returns (uint256) {
    return windowOf(block.timestamp);  
  }

   
  function commitOn(uint256 window) public payable {
     
    require(currentWindow() < totalWindows);
     
    require(currentWindow() <= window);
     
    require(window < totalWindows);
     
    require(0.01 ether <= msg.value);

     
    commitment[msg.sender][window] = commitment[msg.sender][window].add(msg.value);
     
    totals[window] = totals[window].add(msg.value);
     
    emit Commit(msg.sender, msg.value, window);
  }

   
  function commit() public payable {
    commitOn(currentWindow());
  }
  
   
  function withdraw(uint256 window) public returns (uint256 reward) {
     
    require(window < currentWindow());
     
    if (commitment[msg.sender][window] == 0) {
      return 0;
    }

     
     
     
     
    
     
    reward = allocationFor(window).mul(commitment[msg.sender][window]).div(totals[window]);
    
     
    commitment[msg.sender][window] = 0;
     
    MCoin.transfer(msg.sender, reward);
     
    emit Withdraw(msg.sender, reward, window);
    return reward;
  }

   
  function withdrawAll() public {
    for (uint256 i = 0; i < currentWindow(); i++) {
      withdraw(i);
    }
  }

   
  function getAllRewards() public view returns (uint256[]) {
    uint256[] memory rewards = new uint256[](totalWindows);
     
    uint256 lastWindow = currentWindow() < totalWindows ? currentWindow() : totalWindows;
    for (uint256 i = 0; i < lastWindow; i++) {
      rewards[i] = withdraw(i);
    }
    return rewards;
  }

   
  function getCommitmentsOf(address from) public view returns (uint256[]) {
    uint256[] memory commitments = new uint256[](totalWindows);
    for (uint256 i = 0; i < totalWindows; i++) {
      commitments[i] = commitment[from][i];
    }
    return commitments;
  }

   
  function getTotals() public view returns (uint256[]) {
    uint256[] memory ethTotals = new uint256[](totalWindows);
    for (uint256 i = 0; i < totalWindows; i++) {
      ethTotals[i] = totals[i];
    }
    return ethTotals;
  }

   
  function moveFunds() public onlyOwner returns (uint256 value) {
    value = address(this).balance;
    require(0 < value);

    foundationWallet.transfer(value);
    
    emit MoveFunds(value);
    return value;
  }
}



 
contract MCoinDistributionWrap is MCoinDistribution {
  using SafeMath for uint256;
  
  uint8 public constant decimals = 18;   

  constructor(
    uint256 firstPeriodWindows,
    uint256 firstPeriodSupply,
    uint256 secondPeriodWindows,
    uint256 secondPeriodSupply,
    address foundationWallet,
    uint256 startTime,
    uint256 windowLength
    )
    MCoinDistribution (
      firstPeriodWindows,               
      toDecimals(firstPeriodSupply),    
      secondPeriodWindows,              
      toDecimals(secondPeriodSupply),   
      foundationWallet,                 
      startTime,                        
      windowLength                      
    ) public 
  {}    

  function toDecimals(uint256 _value) pure internal returns (uint256) {
    return _value.mul(10 ** uint256(decimals));
  }
}