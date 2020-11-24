 

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


 
contract GDPOraclizedToken is MineableToken {

  event GDPOracleTransferred(address indexed previousOracle, address indexed newOracle);
  event BlockRewardChanged(int oldBlockReward, int newBlockReward);

  address GDPOracle_;
  address pendingGDPOracle_;

   
  modifier onlyGDPOracle() {
    require(msg.sender == GDPOracle_);
    _;
  }
  
   
  modifier onlyPendingGDPOracle() {
    require(msg.sender == pendingGDPOracle_);
    _;
  }

   
  function transferGDPOracle(address newOracle) public onlyGDPOracle {
    pendingGDPOracle_ = newOracle;
  }

   
  function claimOracle() onlyPendingGDPOracle public {
    emit GDPOracleTransferred(GDPOracle_, pendingGDPOracle_);
    GDPOracle_ = pendingGDPOracle_;
    pendingGDPOracle_ = address(0);
  }

   
  function setPositiveGrowth(int256 newBlockReward) public onlyGDPOracle returns(bool) {
     
    require(0 <= newBlockReward);
    
    emit BlockRewardChanged(blockReward_, newBlockReward);
    blockReward_ = newBlockReward;
  }

   
  function setNegativeGrowth(int256 newBlockReward) public onlyGDPOracle returns(bool) {
    require(newBlockReward < 0);

    emit BlockRewardChanged(blockReward_, newBlockReward);
    blockReward_ = newBlockReward;
  }

   
  function GDPOracle() public view returns (address) {  
    return GDPOracle_;
  }

   
  function pendingGDPOracle() public view returns (address) {  
    return pendingGDPOracle_;
  }
}



 
contract MineableM5Token is GDPOraclizedToken { 
  
  event M5TokenUpgrade(address indexed oldM5Token, address indexed newM5Token);
  event M5LogicUpgrade(address indexed oldM5Logic, address indexed newM5Logic);
  event FinishUpgrade();

   
  address M5Token_;
   
  address M5Logic_;
   
  address upgradeManager_;
   
  bool isUpgradeFinished_ = false;

   
  function M5Token() public view returns (address) {
    return M5Token_;
  }

   
  function M5Logic() public view returns (address) {
    return M5Logic_;
  }

   
  function upgradeManager() public view returns (address) {
    return upgradeManager_;
  }

   
  function isUpgradeFinished() public view returns (bool) {
    return isUpgradeFinished_;
  }

   
  modifier onlyUpgradeManager() {
    require(msg.sender == upgradeManager_);
    require(!isUpgradeFinished_);
    _;
  }

   
  function upgradeM5Token(address newM5Token) public onlyUpgradeManager {  
    require(newM5Token != address(0));
    emit M5TokenUpgrade(M5Token_, newM5Token);
    M5Token_ = newM5Token;
  }

   
  function upgradeM5Logic(address newM5Logic) public onlyUpgradeManager {  
    require(newM5Logic != address(0));
    emit M5LogicUpgrade(M5Logic_, newM5Logic);
    M5Logic_ = newM5Logic;
  }

   
  function upgradeM5(address newM5Token, address newM5Logic) public onlyUpgradeManager {  
    require(newM5Token != address(0));
    require(newM5Logic != address(0));
    emit M5TokenUpgrade(M5Token_, newM5Token);
    emit M5LogicUpgrade(M5Logic_, newM5Logic);
    M5Token_ = newM5Token;
    M5Logic_ = newM5Logic;
  }

   
  function finishUpgrade() onlyUpgradeManager public returns (bool) {
    isUpgradeFinished_ = true;
    emit FinishUpgrade();
    return true;
  }

   
  function getM5Reward(address _miner) public view returns (uint256) {
    require(M5Logic_ != address(0));
    if (miners[_miner].value == 0) {
      return 0;
    }
     
    require(signedAverage(miners[_miner].onBlockReward, blockReward_) < 0);

     
    uint32 returnSize = 32;
     
    address target = M5Logic_;
     
    bytes32 signature = keccak256("getM5Reward(address)");
     
    uint32 inputSize = 4 + 32;
     
    uint8 callResult;
     
    uint256 result;
    
    assembly {  
         
        mstore(0x0, signature)  
        mstore(0x4, _miner)     
         
         
         
        callResult := delegatecall(sub(gas, 10000), target, 0x0, inputSize, 0x0, returnSize)
        switch callResult 
        case 0 
          { revert(0,0) } 
        default 
          { result := mload(0x0) }
    }
    return result;
  }

  event WithdrawM5(address indexed from,uint commitment, uint M5Reward);

   
  function withdrawM5() public returns (uint256 reward, uint256 commitmentValue) {
    require(M5Logic_ != address(0));
    require(M5Token_ != address(0));
    require(miners[msg.sender].value > 0); 
    
     
    reward = getM5Reward(msg.sender);
    commitmentValue = miners[msg.sender].value;
    
    require(M5Logic_.delegatecall(bytes4(keccak256("withdrawM5()"))));  
    
    return (reward,commitmentValue);
  }

   
  event Swap(address indexed from, uint256 M5Value, uint256 value);

   
  function swap(uint256 _value) public returns (bool) {
    require(M5Logic_ != address(0));
    require(M5Token_ != address(0));

    require(M5Logic_.delegatecall(bytes4(keccak256("swap(uint256)")),_value));  
    
    return true;
  }
}


 
contract MCoin is MineableM5Token {

  string public name;  
  string public symbol;  
  uint8 public constant decimals = 18;  

  constructor(
    string tokenName,
    string tokenSymbol,
    uint256 blockReward,  
    address GDPOracle,
    address upgradeManager
    ) public 
    {
    require(GDPOracle != address(0));
    require(upgradeManager != address(0));
    
    name = tokenName;
    symbol = tokenSymbol;

    blockReward_ = toDecimals(blockReward);
    emit BlockRewardChanged(0, blockReward_);

    GDPOracle_ = GDPOracle;
    emit GDPOracleTransferred(0x0, GDPOracle_);

    M5Token_ = address(0);
    M5Logic_ = address(0);
    upgradeManager_ = upgradeManager;
  }

  function toDecimals(uint256 _value) pure internal returns (int256 value) {
    value = int256 (
      _value.mul(10 ** uint256(decimals))
    );
    assert(0 < value);
    return value;
  }

}