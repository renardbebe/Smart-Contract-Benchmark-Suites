 

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

   
  function ceil(uint a, uint m) internal pure returns(uint) {
    uint c = add(a, m);
    uint d = sub(c, 1);
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

 
 
 
 

contract ZERO_X_BUTTv3 is ERC20Interface, Owned {

  using SafeMath for uint;
  using ExtendedMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 public _totalSupply;
  uint256 public _burned;

   
  uint private n = 234;  
  uint private nFutureTime = now + 1097 days;  
  
  uint public _MAXIMUM_TARGET = 2 ** n;

  bytes32 public challengeNumber;  

  uint public rewardEra;

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

  uint private miningTarget;
  uint private _mintingEpoch;

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

   
   
   

  constructor() public {
    if (locked) revert();

    symbol = "0xBUTT";
    name = "ButtCoin";
    decimals = 8;
    basePercent = 100;

    uint toMint = 33554432 * 10 ** uint(decimals);
    _mint(msg.sender, toMint);

    tokensMinted = toMint;
    _totalSupply = _totalSupply.add(toMint);
    rewardEra = 1;
    miningTarget = _MAXIMUM_TARGET;
    _startNewMiningEpoch();

    _mintingEpoch = 0;

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
    emit Mint(msg.sender, reward_amount, rewardEra, challengeNumber);

    return true;
  }

   
   
   
  function _startNewMiningEpoch() internal {
    rewardEra = rewardEra + 1;  
    checkMintedNumber();
    _reAdjustDifficulty();
    challengeNumber = blockhash(block.number - 1);
  }

   
  function checkMintedNumber() internal {
    if (tokensMinted >= (2 ** (230))) {  
        
         
        tokensMinted = tokensMinted.div(2 ** (50));
        _burned = _burned.div(2 ** (50));
         
      _mintingEpoch = _mintingEpoch + 1;
    }
  }

   
   
   
  function _reAdjustDifficulty() internal {
    n = n - 1;
    miningTarget = (2 ** n);
    nFutureTime = now + 1097 days;
    
     
     
    uint treshold = (tokensMinted.mul(95)).div(100);
    if(_burned>=treshold){
         
        n = (n.mul(105)).div(100);
        if(n > 213){n = 213;}
        miningTarget = (2 ** n);
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
    uint reward = ((234 - n) ** 3) * 10 ** uint(decimals);
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


  function pulseCheck() internal{
    
    if(nFutureTime<=now){
      n = (n.mul(150)).div(100); 
      miningTarget = (2 ** n);
      _startNewMiningEpoch();
    }  
      
  }

   
   
   
   
   
  function transfer(address to, uint tokens) public returns(bool success) {
      
    pulseCheck(); 

    balances[msg.sender] = balances[msg.sender].sub(tokens);

    balances[to] = balances[to].add(tokens);

    uint256 tokensToBurn = findTwoPercent(tokens);
    uint256 toZeroAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn.sub(toZeroAddress);
    uint256 tokensToTransfer = tokens.sub(toZeroAddress.add(toPreviousAddress));

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), toZeroAddress);
    if (previousSender != to) {  
      emit Transfer(to, previousSender, toPreviousAddress);
      if (previousSender == address(0)) {
        _burned = _burned.add(toPreviousAddress);
      }
    }

    if (to == address(0)) {
      _burned = _burned.add(tokensToTransfer);
    }

    _burned = _burned.add(toZeroAddress);

    _totalSupply = totalSupply();
    previousSender = msg.sender;
    return true;
  }

   
   
   
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
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
    
    pulseCheck();
    
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);

    uint256 tokensToBurn = findTwoPercent(tokens);
    uint256 toZeroAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn - toZeroAddress;
    uint256 tokensToTransfer = tokens.sub(toZeroAddress).sub(toPreviousAddress);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), toZeroAddress);
    if (previousSender != to) {  
      emit Transfer(to, previousSender, toPreviousAddress);
      if (previousSender == address(0)) {
        _burned = _burned.add(toPreviousAddress);
      }
    }
    if (to == address(0)) {
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