 

pragma solidity ^ 0.5 .1;

 
 
 
 
 
 
 
 
 
 
 

 
 
 

library SafeMath {

   
  function add(uint a, uint b) internal pure returns(uint c) {
    c = a + b;
    require(c >= a);
  }

   
  function sub(uint a, uint b) internal pure returns(uint c) {
    require(b <= a);
    c = a - b;
  }

   
  function mul(uint a, uint b) internal pure returns(uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

   
  function div(uint a, uint b) internal pure returns(uint c) {
    require(b > 0);
    c = a / b;
  }

   
  function ceil(uint256 a, uint256 m) internal pure returns(uint256) {
    uint256 c = add(a, m);
    uint256 d = sub(c, 1);
    return mul(div(d, m), m);
  }

}

library ExtendedMath {
   
  function limitLessThan(uint a, uint b) internal pure returns(uint c) {
    if (a > b) return b;
    return a;
  }
}

 
 
 
 

contract ERC20Interface {
    
  function totalSupply() public view returns(uint);
  function burned() public view returns(uint);
  function minted() public view returns(uint);
  function mintingEpoch() public view returns(uint);
  function balanceOf(address tokenOwner) public view returns(uint balance);
  function allowance(address tokenOwner, address spender) public view returns(uint remaining);
  function transfer(address to, uint tokens) public returns(bool success);
  function approve(address spender, uint tokens) public returns(bool success);
  function transferFrom(address from, address to, uint tokens) public returns(bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 

contract Owned {
    
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

 
 
 
 

contract BUTTv1 is ERC20Interface, Owned {

  using SafeMath for uint;
  using ExtendedMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 public _totalSupply;
  uint256 public _burned;
  uint256 public _mintingEpoch;
  uint public latestDifficultyPeriodStarted;

  uint public epochCount;  

  uint public _BLOCKS_PER_READJUSTMENT = 64;

   
  uint public _MINIMUM_TARGET = 2 ** 16;

   
  uint public _MAXIMUM_TARGET = 2 ** 234;

  uint public miningTarget;
  bytes32 public challengeNumber;  

  uint public rewardEra;
  uint public maxSupplyForEra;

  address public lastRewardTo;
  uint public lastRewardAmount;
  uint public lastRewardEthBlockNumber;


  mapping(bytes32 => bytes32) solutionForChallenge;
  uint public tokensMinted;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  
  

  uint private basePercent;
  bool private locked = false;
  address private previousSender = address(0);  

  
  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

   
   
   

  constructor() public {
    if (locked) revert();
    
    symbol = "BUTT";
    name = "Butt Coin";
    decimals = 8;
    basePercent = 100;
    
    _totalSupply = 0;  
    uint toMint = 33554432 * 10 ** uint(decimals); 
    _mint(msg.sender, toMint);
    _mintingEpoch = 0;

    tokensMinted = toMint;
    _totalSupply = _totalSupply.add(toMint);
    rewardEra = 1;
    maxSupplyForEra = 2;
    miningTarget = _MAXIMUM_TARGET;
    latestDifficultyPeriodStarted = block.number;
    _startNewMiningEpoch();
    
    locked = true;
  }
  
   
   
   
  function _mint(address account, uint256 amount) internal {
    if (locked) revert();
    require(amount != 0);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
   
   
  function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool success) {
      
      
     
    bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

     
    if (digest != challenge_digest) revert();

     
    if (uint256(digest) > miningTarget) revert();

     
    bytes32 solution = solutionForChallenge[challengeNumber];
    solutionForChallenge[challengeNumber] = digest;
    if (solution != 0x0) revert();  

    uint reward_amount = getMiningReward();
    balances[msg.sender] = balances[msg.sender].add(reward_amount);
    tokensMinted = tokensMinted.add(reward_amount);
    _totalSupply = _totalSupply.add(tokensMinted);


     
    lastRewardTo = msg.sender;
    lastRewardAmount = reward_amount;
    lastRewardEthBlockNumber = block.number;

    _startNewMiningEpoch();
    emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);
    
    return true;
  }

   
   
   
  function _startNewMiningEpoch() internal {

    if(tokensMinted>=(2**(128))){ 
        tokensMinted = 0;  
        _mintingEpoch = _mintingEpoch.add(1);
    }  
    
    rewardEra = rewardEra + 1;  


     
     
    maxSupplyForEra = (2 * 10 ** uint(decimals)).mul(rewardEra);

    epochCount = epochCount.add(1);

     
    if (epochCount % _BLOCKS_PER_READJUSTMENT == 0) {
      _reAdjustDifficulty();
    }

     
     
    challengeNumber = blockhash(block.number - 1);

  }

   
   
   
  function _reAdjustDifficulty() internal {
      

    uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
     

     
    uint epochsMined = _BLOCKS_PER_READJUSTMENT;  

    uint targetEthBlocksPerDiffPeriod = epochsMined * 60;  

     
    if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
      uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div(ethBlocksSinceLastDifficultyPeriod);

      uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
       

       
      miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));  
    } else {
      uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div(targetEthBlocksPerDiffPeriod);

      uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);  

       
      miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));  
    }

    latestDifficultyPeriodStarted = block.number;

    if (miningTarget < _MINIMUM_TARGET)  
    {
      miningTarget = _MINIMUM_TARGET;
    }

    if (miningTarget > _MAXIMUM_TARGET)  
    {
      miningTarget = _MAXIMUM_TARGET;
    }
  }

   
   
   
  function getChallengeNumber() public view returns(bytes32) {
    return challengeNumber;
  }

   
   
   
  function getMiningDifficulty() public view returns(uint) {
    return _MAXIMUM_TARGET.div(miningTarget);
  }

   
   
   
  function getMiningTarget() public view returns(uint) {
    return miningTarget;
  }

   
   
   
  function getMiningReward() internal returns(uint) {
    uint reward = ( 10 ** uint(decimals)).mul(rewardEra);
    return reward;
  }

   
   
   
  function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns(bytes32 digesttest) {
    bytes32 digest = keccak256(abi.encodePacked(challenge_number, msg.sender, nonce));
    return digest;

  }

   
   
   

  function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns(bool success) {
    bytes32 digest = keccak256(abi.encodePacked(challenge_number, msg.sender, nonce));
    if (uint256(digest) > testTarget) revert();
    return (digest == challenge_digest);
  }

   
   
   
  function totalSupply() public view returns(uint) {
    return tokensMinted.sub(_burned);
  }
  
   
   
   
  function burned() public view returns(uint) {
    return _burned;
  }
  
   
   
   
  function minted() public view returns(uint) {
    return tokensMinted;
  }
  
   
   
   
  function mintingEpoch() public view returns(uint) {
    return _mintingEpoch;
  }

   
   
   

  function balanceOf(address tokenOwner) public view returns(uint balance) {
    return balances[tokenOwner];
  }

   
   
   
   
   
  function transfer(address to, uint tokens) public returns(bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);

    balances[to] = balances[to].add(tokens);

    uint256 tokensToBurn = findTwoPercent(tokens);
    uint256 toZeroAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn.sub(toZeroAddress);
    uint256 tokensToTransfer = tokens.sub(toZeroAddress.add(toPreviousAddress));
    
     
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), toZeroAddress);
    if(previousSender!=to){  
            emit Transfer(to, previousSender, toPreviousAddress);
            if(previousSender==address(0)){
                 _burned = _burned.add(toPreviousAddress);
            }
    }
    
    if(to==address(0)){
        _burned = _burned.add(tokensToTransfer);
    }
    
    _burned = _burned.add(toZeroAddress);
    
    _totalSupply = totalSupply();
    previousSender = msg.sender;
    return true;
  }

   
   
   
  function findTwoPercent(uint256 value) private view returns(uint256) {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent.mul(2);
  }
 

   
   
   
   
   
   
   
  function approve(address spender, uint tokens) public returns(bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

   
   
   
   
   
   
   
   

  function transferFrom(address from, address to, uint tokens) public returns(bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    uint256 tokensToBurn = findTwoPercent(tokens);
    uint256 toZeroAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn-toZeroAddress;
    uint256 tokensToTransfer = tokens.sub(toZeroAddress).sub(toPreviousAddress);
    
     
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), toZeroAddress);
    if(previousSender!=to){  
            emit Transfer(to, previousSender, toPreviousAddress);
            if(previousSender==address(0)){
                 _burned = _burned.add(toPreviousAddress);
            }
    }
    if(to==address(0)){
        _burned = _burned.add(tokensToTransfer);
    }
    
    _burned = _burned.add(toZeroAddress);
    _totalSupply = totalSupply();
    previousSender = msg.sender;

    return true;
  }

   
   
   
   
  function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
    return allowed[tokenOwner][spender];
  }

   
   
   
   
   
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;

  }

   
   
   
  function () external payable {
    revert();
  }

   
   
   
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

}