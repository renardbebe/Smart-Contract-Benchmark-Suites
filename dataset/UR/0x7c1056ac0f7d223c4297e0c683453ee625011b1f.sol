 

 

pragma solidity ^ 0.5 .10;

 
 
 
 
 
 
 

 
 
 

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

 

 
 
 
 

contract ERC20Interface {

    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    function getDifficultyExponent() public view returns(uint); 
    function getMiningDifficulty() public view returns(uint);
    function getMiningTarget() public view returns(uint);
    function getNextAward() public view returns(uint);
    function getChallengeNumber() public view returns(bytes32);
    
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

 
 
 
 

contract ZERO_X_BUTTv5 is ERC20Interface, Owned {

    using SafeMath for uint;
    
    string public symbol;
    string public name;
    
    uint8 public decimals;
    
    uint256 public _totalSupply;
    uint256 public _burned;
    
    uint private n;
    uint public nFutureTime;
    uint public _MAXIMUM_TARGET;
    uint public rewardEra;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    uint public tokensMinted;
    
    address public lastRewardTo;
    address public previousSender = address(0);  
    
    bytes32 public challengeNumber;  

    mapping(bytes32 => bytes32) solutionForChallenge;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint private miningTarget;
    uint private basePercent;
    
    bool internal locked = false;
    
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

   
   
   
    constructor() public {
        if (locked) revert();
            symbol = "0xBUTT";
            name = "ButtCoin";
            decimals = 8;
            basePercent = 100;
            n = 234;  
            _MAXIMUM_TARGET = 2 ** n;
            
            uint toMint = 33554467 * 10 ** uint(decimals);  
            premine(msg.sender, toMint);
            
            tokensMinted = toMint;
            _totalSupply = toMint;
            rewardEra = 1;
            miningTarget = _MAXIMUM_TARGET;
            _startNewMiningEpoch();
            
            nFutureTime = now + 92275199;  
            
            locked = true;
    }

 
 
 

 
 
 
    function getChallengeNumber() public view returns(bytes32) {
        return challengeNumber;
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
        _totalSupply = _totalSupply.add(reward_amount);
        
         
        lastRewardTo = msg.sender;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;
        
        _startNewMiningEpoch();
        emit Mint(msg.sender, reward_amount, rewardEra, challengeNumber);
        
        return true;
    }

 
 
 

    function transfer(address to, uint tokens) public returns(bool success) {
        pulseCheck(); 
        
        uint256 tokensToBurn = findTwoPercent(tokens);
        uint256 toZeroAddress = tokensToBurn.div(2);
        uint256 toPreviousAddress = tokensToBurn.sub(toZeroAddress);
        uint256 tokensToTransfer = tokens.sub(toZeroAddress.add(toPreviousAddress));
        
         sendTo(msg.sender, to, tokensToTransfer);
         sendTo(msg.sender, address(0), toZeroAddress);
        if (previousSender != to) {  
         sendTo(msg.sender, previousSender, toPreviousAddress);
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
  
 
 
 

    function transferFrom(address from, address to, uint tokens) public returns(bool success) {
        pulseCheck();
        
        uint256 tokensToBurn = findTwoPercent(tokens);
        uint256 toZeroAddress = tokensToBurn.div(2);
        uint256 toPreviousAddress = tokensToBurn - toZeroAddress;
        uint256 tokensToTransfer = tokens.sub(toZeroAddress).sub(toPreviousAddress);
        
        sendTo(from, to, tokensToTransfer);
        sendTo(from, address(0), toZeroAddress);
        if (previousSender != to) {  
          sendTo(from, previousSender, toPreviousAddress);
          if (previousSender == address(0)) {
            _burned = _burned.add(toPreviousAddress);
          }
        }
        if (to == address(0)) {
          _burned = _burned.add(tokensToTransfer);
        }
        
        _burned = _burned.add(toZeroAddress);
        _totalSupply = totalSupply();
        previousSender = from;
        
        return true;
  }
  

 
 
 
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
          transfer(receivers[i], amounts[i]);
        }
    }

 
 
 
 
 
 
 
    function approve(address spender, uint tokens) public returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

 
 
 
 
 
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  
 
 
 
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }  





 
 
 

 
 
 
    function premine(address account, uint256 amount) internal {
        if (locked) revert();
        require(amount != 0);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

 
 
 
    function _startNewMiningEpoch() internal {
        rewardEra = rewardEra + 1;  
        _reAdjustDifficulty();
        challengeNumber = blockhash(block.number - 1);
    }

 

 
 
 
    function _reAdjustDifficulty() internal {
        n = n - 1;
        miningTarget = (2 ** n);
        nFutureTime = now + 92275199;
        
         
         
        uint treshold = (tokensMinted.mul(95)).div(100);
        if(_burned>=treshold){
             
            n = (n.mul(105)).div(100);
          if(n>=234){
              n=234;
          }
            miningTarget = (2 ** n);
        }
    }

 
 
 
    function pulseCheck() internal{
     
        if(nFutureTime<=now){
          n = (n.div(2)).add(n); 
          if(n>=234){
              n=234;
          }
          miningTarget = (2 ** n);
          _startNewMiningEpoch();
        }  
    }

 
 
 
    function getMiningReward() internal returns(uint) {
        return ((234 - n) ** 3) * 10 ** uint(decimals);
    }

 
 
 
    function sendTo(address from, address to, uint tokens) internal returns(bool success) {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
 
 
 
    function findTwoPercent(uint256 value) internal returns(uint256) {
        uint256 roundValue = value.ceil(basePercent);
        uint256 onePercent = roundValue.mul(basePercent).div(10000);
        return onePercent.mul(2);
    }
    
    
 
 
 

 
 
 
 
  function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
    return allowed[tokenOwner][spender];
  }

 
 
 
    function getDifficultyExponent() public view returns(uint) {
        return n;
    }     
 
   
 
 
 
    function getMiningDifficulty() public view returns(uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

 
 
 
    function getMiningTarget() public view returns(uint) {
        return miningTarget;
    }

 
 
 
    function getNextAward() public view returns(uint) {
        return ((234 - n) ** 3) * 10 ** uint(decimals);
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



 
 
 
  function balanceOf(address tokenOwner) public view returns(uint balance) {
    return balances[tokenOwner];
  }
    
 
 
 
 
 
 
 
  function () external payable {
    revert();
  }  

}