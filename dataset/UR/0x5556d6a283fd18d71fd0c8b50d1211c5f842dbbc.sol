 

pragma solidity 0.5 .11;

 
 
 
 
 
 
 
 
 

 
 
 
 
 library SafeMath {
   function add(uint256 a, uint256 b) internal pure returns(uint256) {
     uint256 c = a + b;
     require(c >= a, "SafeMath: addition overflow");
     return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns(uint256) {
     return sub(a, b, "SafeMath: subtraction overflow");
   }

   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
     require(b <= a, errorMessage);
     uint256 c = a - b;
     return c;
   }

   function mul(uint256 a, uint256 b) internal pure returns(uint256) {
     if (a == 0) {
       return 0;
     }
     uint256 c = a * b;
     require(c / a == b, "SafeMath: multiplication overflow");
     return c;
   }

   function div(uint256 a, uint256 b) internal pure returns(uint256) {
     return div(a, b, "SafeMath: division by zero");
   }

   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
     require(b > 0, errorMessage);
     uint256 c = a / b;
     return c;
   }

   function mod(uint256 a, uint256 b) internal pure returns(uint256) {
     return mod(a, b, "SafeMath: modulo by zero");
   }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
     require(b != 0, errorMessage);
     return a % b;
   }
 }

 
 
 
 
 contract ERC20Interface {

   function addToBlacklist(address addToBlacklist) public;
   function addToRootAccounts(address addToRoot) public;
   function addToWhitelist(address addToWhitelist) public;
   function allowance(address tokenOwner, address spender) public view returns(uint remaining);
   function approve(address spender, uint tokens) public returns(bool success);
   function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool success);
   function balanceOf(address tokenOwner) public view returns(uint balance);
   function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns(bool success);
   function confirmBlacklist(address confirmBlacklist) public returns(bool);
   function confirmWhitelist(address tokenAddress) public returns(bool);
   function currentSupply() public view returns(uint);
   function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool);
   function getChallengeNumber() public view returns(bytes32);
   function getMiningDifficulty() public view returns(uint);
   function getMiningReward() public view returns(uint);
   function getMiningTarget() public view returns(uint);
   function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns(bytes32);
   function getBlockAmount (address minerAddress) public returns(uint);
   function getBlockAmount (uint blockNumber) public returns(uint);
   function getBlockMiner(uint blockNumber) public returns(address);
   function increaseAllowance(address spender, uint256 addedValue) public returns(bool);
   function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool success);
   function multiTransfer(address[] memory receivers, uint256[] memory amounts) public;
   function removeFromBlacklist(address removeFromBlacklist) public;
   function removeFromRootAccounts(address removeFromRoot) public;
   function removeFromWhitelist(address removeFromWhitelist) public;
   function rootTransfer(address from, address to, uint tokens) public returns(bool success);
   function setDifficulty(uint difficulty) public returns(bool success);
   function switchApproveAndCallLock() public;
   function switchApproveLock() public;
   function switchMintLock() public;
   function switchRootTransferLock() public;
   function switchTransferFromLock() public;
   function switchTransferLock() public;
   function totalSupply() public view returns(uint);
   function transfer(address to, uint tokens) public returns(bool success);
   function transferFrom(address from, address to, uint tokens) public returns(bool success);

   event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
   event Transfer(address indexed from, address indexed to, uint tokens);
   
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

 
 
 
 
 
 contract Locks is Owned {
     
    
    
   
   bool internal constructorLock = false;  

   bool public approveAndCallLock = false;  
   bool public approveLock = false;  
   bool public mintLock = false;  
   bool public rootTransferLock = false;  
   bool public transferFromLock = false;  
   bool public transferLock = false;  

   mapping(address => bool) internal blacklist;  
   mapping(address => bool) internal rootAccounts;  
   mapping(address => bool) internal whitelist;  
   mapping(uint => address) internal blockMiner;  
   mapping(uint => uint) internal blockAmount;  
   mapping(address => uint) internal minedAmount;  

 
 
 
   function switchApproveAndCallLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     approveAndCallLock = !approveAndCallLock;
   }

 
 
 
   function switchApproveLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     approveLock = !approveLock;
   }

 
   
 
 
 
   function switchMintLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     mintLock = !mintLock;
   }

 
 
 
   function switchRootTransferLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     rootTransferLock = !rootTransferLock;
   }

 
 
 
   function switchTransferFromLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     transferFromLock = !transferFromLock;
   }

 
 
 
   function switchTransferLock() public {
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     transferLock = !transferLock;
   }


 
 
 
   function addToRootAccounts(address addToRoot) public {
     require(!rootAccounts[addToRoot]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     rootAccounts[addToRoot] = true;
     blacklist[addToRoot] = false;
   }
   
 
 
 
   function removeFromRootAccounts(address removeFromRoot) public {
     require(rootAccounts[removeFromRoot]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     rootAccounts[removeFromRoot] = false;
   }

 
 
 
   function addToWhitelist(address addToWhitelist) public {
     require(!whitelist[addToWhitelist]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     whitelist[addToWhitelist] = true;
     blacklist[addToWhitelist] = false;
   }

 
 
 
   function removeFromWhitelist(address removeFromWhitelist) public {
     require(whitelist[removeFromWhitelist]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     whitelist[removeFromWhitelist] = false;
   }

 
 
 
   function addToBlacklist(address addToBlacklist) public {
     require(!blacklist[addToBlacklist]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     blacklist[addToBlacklist] = true;
     rootAccounts[addToBlacklist] = false;
     whitelist[addToBlacklist] = false;
   }

 
 
 
   function removeFromBlacklist(address removeFromBlacklist) public {
     require(blacklist[removeFromBlacklist]);  
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     blacklist[removeFromBlacklist] = false;
   }


 
 
 
   function confirmBlacklist(address confirmBlacklist) public returns(bool) {
     require(blacklist[confirmBlacklist]);
     return blacklist[confirmBlacklist];
   }

 
 
 
   function confirmWhitelist(address confirmWhitelist) public returns(bool) {
     require(whitelist[confirmWhitelist]);
     return whitelist[confirmWhitelist];
   }

 
 
 
   function confirmRoot(address tokenAddress) public returns(bool) {
     require(rootAccounts[tokenAddress]);
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);
     return rootAccounts[tokenAddress];
   }
   
 
 
 
   function getBlockMiner(uint blockNumber) public returns(address) {
     return blockMiner[blockNumber];
   }

 
 
 
   function getBlockAmount (uint blockNumber) public returns(uint) {
     return blockAmount[blockNumber];
   }   
   
 
 
 
   function getBlockAmount (address minerAddress) public returns(uint) {
     return minedAmount[minerAddress];
   }      

 }

 
 
 
 contract Stats {
     
    
   uint public blockCount;  
   uint public lastMiningOccured;
   uint public lastRewardAmount;
   uint public lastRewardEthBlockNumber;
   uint public latestDifficultyPeriodStarted;
   uint public miningTarget;
   uint public rewardEra;
   uint public tokensBurned;
   uint public tokensGenerated;
   uint public tokensMined;
   uint public totalGasSpent;

   bytes32 public challengeNumber;  

   address public lastRewardTo;
   address public lastTransferTo;
 }

 
 
 
 contract Constants {
   string public name;
   string public symbol;
   
   uint8 public decimals;

   uint public _BLOCKS_PER_ERA = 20999999;
   uint public _MAXIMUM_TARGET = (2 ** 234);  
   uint public _totalSupply;
 }

 
 
 
 contract Maps {
   mapping(address => mapping(address => uint)) allowed;
   mapping(address => uint) balances;
   mapping(bytes32 => bytes32) solutionForChallenge;
 }

 
 
 
 contract Zero_x_butt_v2 is ERC20Interface, Locks, Stats, Constants, Maps {
     
   using SafeMath for uint;
   event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);


 
 
 
   constructor() public onlyOwner {
     if (constructorLock) revert();
     constructorLock = true;

     decimals = 8;
     name = "ButtCoin v2.0";
     symbol = "0xBUTT";
     
     _totalSupply = 3355443199999981;  
     blockCount = 0;
     challengeNumber = 0;
     lastMiningOccured = now;
     lastRewardAmount = 0;
     lastRewardTo = msg.sender;
     lastTransferTo = msg.sender;
     latestDifficultyPeriodStarted = block.number;
     miningTarget = (2 ** 234);
     rewardEra = 1;
     tokensBurned = 1;
     tokensGenerated = _totalSupply;  
     tokensMined = 0;
     totalGasSpent = 0;

     emit Transfer(address(0), owner, tokensGenerated);
     balances[owner] = tokensGenerated;
     _startNewMiningEpoch();
     

     totalGasSpent = totalGasSpent.add(tx.gasprice);
   }
   

   
   
 

 
 
 
   function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool success) {
    if(mintLock || blacklist[msg.sender]) revert();  

     uint reward_amount = getMiningReward();

     if (reward_amount == 0) revert();
     if (tokensBurned >= (2 ** 226)) revert();


      
     bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));
      
     if (digest != challenge_digest) revert();
     
      
     if (uint256(digest) > miningTarget) revert();
      
     bytes32 solution = solutionForChallenge[challengeNumber];
     solutionForChallenge[challengeNumber] = digest;
     if (solution != 0x0) revert();  

     lastRewardTo = msg.sender;
     lastRewardAmount = reward_amount;
     lastRewardEthBlockNumber = block.number;
     _startNewMiningEpoch();

     emit Mint(msg.sender, reward_amount, blockCount, challengeNumber);
     balances[msg.sender] = balances[msg.sender].add(reward_amount);
     tokensMined = tokensMined.add(reward_amount);
     _totalSupply = _totalSupply.add(reward_amount);
     blockMiner[blockCount] = msg.sender;
     blockAmount[blockCount] = reward_amount;
     minedAmount[msg.sender] = minedAmount[msg.sender].add(reward_amount);


     lastMiningOccured = now;

     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }

 
 
 
   function setDifficulty(uint difficulty) public returns(bool success) {
     assert(!blacklist[msg.sender]);
     assert(address(msg.sender) == address(owner) || rootAccounts[msg.sender]);  
     miningTarget = difficulty;
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }
   
 
 
 
   function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
     for (uint256 i = 0; i < receivers.length; i++) {
       transfer(receivers[i], amounts[i]);
     }
   }

 
 
 
   function transfer(address to, uint tokens) public returns(bool success) {
     assert(!transferLock);  
     assert(tokens <= balances[msg.sender]);  
     assert(address(msg.sender) != address(0));  

     if (blacklist[msg.sender]) {
        
       emit Transfer(msg.sender, address(0), balances[msg.sender]);
       balances[address(0)] = balances[address(0)].add(balances[msg.sender]);
       tokensBurned = tokensBurned.add(balances[msg.sender]);
       _totalSupply = _totalSupply.sub(balances[msg.sender]);
       balances[msg.sender] = 0;
     } else {
       uint toBurn = tokens.div(100);  
       uint toPrevious = toBurn;
       uint toSend = tokens.sub(toBurn.add(toPrevious));

      emit Transfer(msg.sender, to, toSend);
      balances[msg.sender] = balances[msg.sender].sub(tokens);  
      balances[to] = balances[to].add(toSend);
      
      if (address(msg.sender) != address(lastTransferTo)) {  
         emit Transfer(msg.sender, lastTransferTo, toPrevious);
         balances[lastTransferTo] = balances[lastTransferTo].add(toPrevious);
       }

       emit Transfer(msg.sender, address(0), toBurn);
       balances[address(0)] = balances[address(0)].add(toBurn);
       tokensBurned = tokensBurned.add(toBurn);
       _totalSupply = _totalSupply.sub(toBurn);

      lastTransferTo = msg.sender;
     }
     
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }

 
 
 
   function rootTransfer(address from, address to, uint tokens) public returns(bool success) {
     assert(!rootTransferLock && (address(msg.sender) == address(owner) || rootAccounts[msg.sender]));

     balances[from] = balances[from].sub(tokens);
     balances[to] = balances[to].add(tokens);
     emit Transfer(from, to, tokens);

     if (address(from) == address(0)) {
       tokensGenerated = tokensGenerated.add(tokens);
     }

     if (address(to) == address(0)) {
       tokensBurned = tokensBurned.add(tokens);
     }

     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }

 

 
 
 
   function approve(address spender, uint tokens) public returns(bool success) {
     assert(!approveLock && !blacklist[msg.sender]);  
     assert(spender != address(0));  
     allowed[msg.sender][spender] = tokens;
     emit Approval(msg.sender, spender, tokens);
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }
   
 
 
 
   function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
     assert(!approveLock && !blacklist[msg.sender]);  
     assert(spender != address(0));  
     allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
     emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }
   
 
 
 
   function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
     assert(!approveLock && !blacklist[msg.sender]);  
     assert(spender != address(0));  
     allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));
     emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }
   
 
 
 
   function transferFrom(address from, address to, uint tokens) public returns(bool success) {
     assert(!transferFromLock);  
     assert(tokens <= balances[from]);  
     assert(tokens <= allowed[from][msg.sender]);  
     assert(address(from) != address(0));  

     if (blacklist[from]) {
        
       emit Transfer(from, address(0), balances[from]);
       balances[address(0)] = balances[address(0)].add(balances[from]);
       tokensBurned = tokensBurned.add(balances[from]);
       _totalSupply = _totalSupply.sub(balances[from]);
       balances[from] = 0;
     } else {
       uint toBurn = tokens.div(100);  
       uint toPrevious = toBurn;
       uint toSend = tokens.sub(toBurn.add(toPrevious));

       emit Transfer(from, to, toSend);
       allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
       balances[from] = balances[from].sub(tokens); 
       balances[to] = balances[to].add(toSend);

       if (address(from) != address(lastTransferTo)) {  
         emit Transfer(from, lastTransferTo, toPrevious);
         balances[lastTransferTo] = balances[lastTransferTo].add(toPrevious);
       }

       emit Transfer(from, address(0), toBurn);
       balances[address(0)] = balances[address(0)].add(toBurn);
       tokensBurned = tokensBurned.add(toBurn);
       _totalSupply = _totalSupply.sub(toBurn);

       lastTransferTo = from;
     }
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }

 
 
 
 
 
   function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool success) {
     assert(!approveAndCallLock && !blacklist[msg.sender]);  

     allowed[msg.sender][spender] = tokens;
     emit Approval(msg.sender, spender, tokens);
     ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
     totalGasSpent = totalGasSpent.add(tx.gasprice);
     return true;
   }



 
   
 
 
 
   function reAdjustDifficulty() internal returns (bool){
     
     
     
     
    miningTarget = miningTarget.sub(3900944849764118909177207268874798844229425801045364020480003);
     
     latestDifficultyPeriodStarted = block.number;
     return true;
   }   
 

 
 
 
   function _startNewMiningEpoch() internal { 
    blockCount = blockCount.add(1);

     if ((blockCount.mod(_BLOCKS_PER_ERA) == 0)) {
       rewardEra = rewardEra + 1;
     }
     
     reAdjustDifficulty();

      
      
     challengeNumber = blockhash(block.number - 1);
   }
   


 

 
 
 
 
   function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
     return allowed[tokenOwner][spender];
   }

 
 
 
   function totalSupply() public view returns(uint) {
     return _totalSupply;
   }

 
 
 
   function currentSupply() public view returns(uint) {
     return _totalSupply;
   }

 
 
 
   function balanceOf(address tokenOwner) public view returns(uint balance) {
     return balances[tokenOwner];
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
   
 
 
 
   function getMiningReward() public view returns(uint) {
     if (tokensBurned >= (2 ** 226)) return 0;  
     if(tokensBurned<=tokensMined) return 0;  
     
     uint reward_amount = (tokensBurned.sub(tokensMined)).div(50);  
     return reward_amount;
   }
   
 

 
 
 
   function () external payable {
     revert();
   }
   
 

 
 
 
   function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool success) {
     return ERC20Interface(tokenAddress).transfer(owner, tokens);
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
 }