 

pragma solidity ^0.4.21;

 
 
 
 
 
 
 
 
 
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
}

library ExtendedMath {
     
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
 
contract _0xEtherToken is ERC20Interface {
    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol = "PoWEth";
    string public name = "PoWEth Token";
    uint8 public decimals = 8;
    uint public _totalSupply = 10000000000000000;
	uint public maxSupplyForEra = 5000000000000000;
	
    uint public latestDifficultyPeriodStarted;
	uint public tokensMinted;
	
    uint public epochCount;  
    uint public _BLOCKS_PER_READJUSTMENT = 1024;

    uint public  _MINIMUM_TARGET = 2**16;
    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget = _MAXIMUM_TARGET;

    bytes32 public challengeNumber;    

    uint public rewardEra;
    
    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    mapping(bytes32 => bytes32) solutionForChallenge;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    address private owner;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    function _0xEtherToken() public {
        
        owner = msg.sender;
        
        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();

         
         
         
    }

	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

		 
		bytes32 digest = keccak256(challengeNumber, msg.sender, nonce );

		 
		if (digest != challenge_digest) revert();

		 
		if(uint256(digest) > miningTarget) revert();

		 
		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) 
			revert();   

		uint reward_amount = getMiningReward();

		balances[msg.sender] = balances[msg.sender].add(reward_amount);

		tokensMinted = tokensMinted.add(reward_amount);

		 
		assert(tokensMinted <= maxSupplyForEra);

		 
		lastRewardTo = msg.sender;
		lastRewardAmount = reward_amount;
		lastRewardEthBlockNumber = block.number;
		
		_startNewMiningEpoch();
    	emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );

	   return true;
	}

     
    function _startNewMiningEpoch() internal {
		 

		 
		 
		 
		if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 19)
		{
			rewardEra = rewardEra + 1;
		}

		maxSupplyForEra = _totalSupply - _totalSupply / (2**(rewardEra + 1));

		epochCount = epochCount.add(1);

		 
		if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
		{
			_reAdjustDifficulty();
		}

		 
		 
		challengeNumber = block.blockhash(block.number - 1);
    }

     
     
     
    function _reAdjustDifficulty() internal {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        
         
         
        uint targetEthBlocksPerDiffPeriod = _BLOCKS_PER_READJUSTMENT * 30;  

         
        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
			uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)) / ethBlocksSinceLastDifficultyPeriod;
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
			
			 
			miningTarget = miningTarget.sub((miningTarget/2000).mul(excess_block_pct_extra));
        }else{
			uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)) / targetEthBlocksPerDiffPeriod;
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);

			 
			miningTarget = miningTarget.add((miningTarget/2000).mul(shortage_block_pct_extra));
        }

        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET)  
        {
			miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET)  
        {
			miningTarget = _MAXIMUM_TARGET;
        }
    }

     
    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

     
     function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET / miningTarget;
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
	}

     
     
    function getMiningReward() public constant returns (uint) {
		return 25000000000/(2**rewardEra);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender == owner);
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
    function getMintDigest(uint256 nonce, bytes32 challenge_number) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
        return digest;
	}

	 
	function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
		bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
		if(uint256(digest) > testTarget) 
			revert();
		return (digest == challenge_digest);
	}
}