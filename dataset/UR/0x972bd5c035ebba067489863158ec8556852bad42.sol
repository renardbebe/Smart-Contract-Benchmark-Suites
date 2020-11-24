 

pragma solidity ^ 0.5 .0;

 
 
 
 
 
 
 
 

 
 
 

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

 
 
 
 

contract BUTT is ERC20Interface, Owned {

  using SafeMath for uint;
  using ExtendedMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 public _totalSupply;
  uint public latestDifficultyPeriodStarted;

  uint public epochCount;  

  uint public _BLOCKS_PER_READJUSTMENT = 1024;

   
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
  
  
  uint private supply;  
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
    
    _totalSupply = 2**(256-1);  
    supply = _totalSupply;
    uint toMint = 306000000 * 10 ** uint(decimals);  

    _mint(msg.sender, toMint);

    tokensMinted = toMint;
    rewardEra = 1;
    maxSupplyForEra = _totalSupply.div(2);
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


     
    lastRewardTo = msg.sender;
    lastRewardAmount = reward_amount;
    lastRewardEthBlockNumber = block.number;

    _startNewMiningEpoch();
    emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);
    
    return true;
  }

   
   
   
  function _startNewMiningEpoch() internal {

    if(tokensMinted>=(2**(256-64))){ 
        tokensMinted = 0;  
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
    return _totalSupply - balances[address(0)];
  }

   
   
   

  function balanceOf(address tokenOwner) public view returns(uint balance) {
    return balances[tokenOwner];
  }

   
   
   
   
   
  function transfer(address to, uint tokens) public returns(bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);

    balances[to] = balances[to].add(tokens);

    uint256 tokensToBurn = findTwoPercent(tokens);
    uint256 toRandomAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn.sub(toRandomAddress);
    uint256 tokensToTransfer = tokens.sub(toRandomAddress.add(toPreviousAddress));
    
    address burnAddress = getButtAddress(msg.sender);
    
    emit Transfer(msg.sender, burnAddress, toRandomAddress);
    emit Transfer(msg.sender, previousSender, toPreviousAddress);
    emit Transfer(msg.sender, to, tokensToTransfer);
    
    previousSender = msg.sender;
    return true;
  }

   
   
   
  function findTwoPercent(uint256 value) private view returns(uint256) {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent.mul(2);
  }

   
   
   
   
   
  function getButtAddress(address account) private pure returns(address) {
     
    bytes20 data = bytes20(account);

    uint8[] memory arr = new uint8[](data.length);

     
    for (uint256 i = 0; i < data.length; i++) {
      arr[i] = uint8(uint160(data) / (2 ** (8 * (19 - i))));
    }

    uint8 first = arr[5];
    uint8 second = arr[6];

    arr[5] = second;
    arr[6] = first;

     
    bytes memory asciiBytes = new bytes(40);

     
    uint8 b;
    uint8 leftNibble;
    uint8 rightNibble;
    bool leftCaps;
    bool rightCaps;
    uint8 asciiOffset;

     
    bool[40] memory caps = _toChecksumCapsFlags(account);

     
    for (uint256 i = 0; i < arr.length; i++) {
       
      b = arr[i];
      leftNibble = b / 16;
      rightNibble = b - 16 * leftNibble;

       
      leftCaps = caps[2 * i];
      rightCaps = caps[2 * i + 1];

       
      asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

       
      asciiBytes[2 * i] = byte(leftNibble + asciiOffset);

       
      asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

       
      asciiBytes[2 * i + 1] = byte(rightNibble + asciiOffset);
    }

    return _toAddress(string(asciiBytes));
  }

   
   
   
  function _toChecksumCapsFlags(address account) private pure returns(bool[40] memory characterCapitalized) {
     
    bytes20 a = bytes20(account);

     
    bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

     
    uint8 leftNibbleAddress;
    uint8 rightNibbleAddress;
    uint8 leftNibbleHash;
    uint8 rightNibbleHash;

     
    for (uint256 i; i < a.length; i++) {
       
      rightNibbleAddress = uint8(a[i]) % 16;
      leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
      rightNibbleHash = uint8(b[i]) % 16;
      leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

      characterCapitalized[2 * i] = (
        leftNibbleAddress > 9 &&
        leftNibbleHash > 7
      );
      characterCapitalized[2 * i + 1] = (
        rightNibbleAddress > 9 &&
        rightNibbleHash > 7
      );
    }
  }

   
   
   
  function _getAsciiOffset(uint8 nibble, bool caps) private pure returns(uint8 offset) {
     
    if (nibble < 10) {
      offset = 48;
    } else if (caps) {
      offset = 55;
    } else {
      offset = 87;
    }
  }

   
   
   
  function _toAsciiString(bytes20 data) private pure returns(string memory asciiString) {
     
    bytes memory asciiBytes = new bytes(40);

     
    uint8 b;
    uint8 leftNibble;
    uint8 rightNibble;

     
    for (uint256 i = 0; i < data.length; i++) {
       
      b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
      leftNibble = b / 16;
      rightNibble = b - 16 * leftNibble;

       
      asciiBytes[2 * i] = byte(leftNibble + (leftNibble < 10 ? 48 : 87));
      asciiBytes[2 * i + 1] = byte(rightNibble + (rightNibble < 10 ? 48 : 87));
    }

    return string(asciiBytes);
  }

   
   
   
  function _toAddress(string memory account) private pure returns(address accountAddress) {
     
    bytes memory accountBytes = bytes(account);

     
    bytes memory accountAddressBytes = new bytes(20);

     
    uint8 b;
    uint8 nibble;
    uint8 asciiOffset;

     
    if (accountBytes.length == 40) {
      for (uint256 i; i < 40; i++) {
         
        b = uint8(accountBytes[i]);

         
        if (b < 48) return address(0);
        if (57 < b && b < 65) return address(0);
        if (70 < b && b < 97) return address(0);
        if (102 < b) return address(0);  

         
        if (b < 65) {  
          asciiOffset = 48;
        } else if (70 < b) {  
          asciiOffset = 87;
        } else {  
          asciiOffset = 55;
        }

         
        if (i % 2 == 0) {
          nibble = b - asciiOffset;
        } else {
          accountAddressBytes[(i - 1) / 2] = (
            byte(16 * nibble + (b - asciiOffset)));
        }
      }

       
      bytes memory packed = abi.encodePacked(accountAddressBytes);
      assembly {
        accountAddress: = mload(add(packed, 20))
      }
    }
  }

   
   
   
  function bytesToAddress(bytes memory b) private pure returns(address) {
    uint result = 0;
    for (uint i = 0; i < b.length; i++) {
      uint c = uint(uint8(b[i]));
      if (c >= 48 && c <= 57) {
        result = result * 16 + (c - 48);
      }
      if (c >= 65 && c <= 90) {
        result = result * 16 + (c - 55);
      }
      if (c >= 97 && c <= 122) {
        result = result * 16 + (c - 87);
      }
    }
    return address(result);
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
    uint256 toRandomAddress = tokensToBurn.div(2);
    uint256 toPreviousAddress = tokensToBurn-toRandomAddress;
    uint256 tokensToTransfer = tokens.sub(toRandomAddress).sub(toPreviousAddress);
    
    address burnAddress = getButtAddress(msg.sender);
    
    emit Transfer(msg.sender, burnAddress, toRandomAddress);
    emit Transfer(msg.sender, previousSender, toPreviousAddress);
    emit Transfer(msg.sender, to, tokensToTransfer);
    
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