 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 

 
 
 
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

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
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

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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

 
 
 
 
contract PoWAdvCoinToken is ERC20Interface, Owned {
    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    uint public latestDifficultyPeriodStarted;
    uint public firstValidBlockNumber;

    uint public epochCount;  

    uint public _BLOCKS_PER_READJUSTMENT = 16;
     
    uint public _TARGET_EPOCH_PER_PEDIOD = _BLOCKS_PER_READJUSTMENT * 60; 
    uint public _BLOCK_REWARD = (250 * 10**uint(8));
     
    uint public  _MINIMUM_TARGET = 2**16;
     
    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget;
    bytes32 public challengeNumber;    

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

     
     
     
    function PoWAdvCoinToken() public onlyOwner {

        symbol = "POWA";
        name = "PoWAdv Token";
        decimals = 8;
        _totalSupply = 100000000 * 10**uint(decimals);

        if(locked) 
			revert();
			
        locked = true;
        tokensMinted = 0;
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        firstValidBlockNumber =  5349511;
        _startNewMiningEpoch();

         
        epochCount = 3071;
        balances[owner] = epochCount * _BLOCK_REWARD;
        tokensMinted = epochCount * _BLOCK_REWARD;
    }
 
	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

        require(block.number > firstValidBlockNumber);
            
		 
		bytes32 digest = keccak256(challengeNumber, msg.sender, nonce);

		 
		if (digest != challenge_digest) 
			revert();

		 
		if(uint256(digest) > discountedMiningTarget(msg.sender)) 
			revert();

		 
		bytes32 solution = solutionForChallenge[challengeNumber];
		solutionForChallenge[challengeNumber] = digest;
		if(solution != 0x0) 
			revert();   

		uint reward_amount = _BLOCK_REWARD;

		balances[msg.sender] = balances[msg.sender].add(reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);
        
		assert(tokensMinted <= _totalSupply);
	
		_startNewMiningEpoch();

		emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);

		return true;
	}

     
    function _startNewMiningEpoch() internal {
		epochCount = epochCount.add(1);

		 
		if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
			_reAdjustDifficulty();
		
		 
		 
		challengeNumber = block.blockhash(block.number - 1);
    }

    function _reAdjustDifficulty() internal {

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;

         
        uint targetEthBlocksPerDiffPeriod = _TARGET_EPOCH_PER_PEDIOD;  

         
        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
			uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div(ethBlocksSinceLastDifficultyPeriod);
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
		
			 
			miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));    
        }else{
			uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div(targetEthBlocksPerDiffPeriod);
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);  

			 
			miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   
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
        return _MAXIMUM_TARGET.div(miningTarget);
    }

	function getMiningTarget() public constant returns (uint) {
		return miningTarget;
	}
	
    function discountedMiningTarget(address solver) public constant returns (uint256 discountedDiff) {
         
        uint256 minerBalance = uint256(balanceOf(solver));
         
        if(minerBalance <= 2 * _BLOCK_REWARD)
            return getMiningTarget();
            
         
        uint256 minerDiscount = uint256(minerBalance.div(_BLOCK_REWARD));
            
        discountedDiff = miningTarget.mul(minerDiscount.mul(minerDiscount));
        
        if(discountedDiff > _MAXIMUM_TARGET)  
            discountedDiff = _MAXIMUM_TARGET;
      
        return discountedDiff;
    }
    
    function discountedMiningDifficulty(address solver) public constant returns (uint256 discountedDiff) {
        return _MAXIMUM_TARGET.div(discountedMiningTarget(solver));
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0);
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

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}