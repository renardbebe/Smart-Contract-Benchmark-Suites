 

pragma solidity ^0.4.24;

 


 
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


 
contract ERC918Interface {
    function getChallengeNumber() public constant returns (bytes32);
    function getMiningDifficulty() public constant returns (uint);
    function getMiningTarget() public constant returns (uint);
    function getMiningReward() public constant returns (uint);

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    bytes32 public challengeNumber;
}

 
contract ZeroGoldPOWMining is Owned {
    using SafeMath for uint;

     
    ERC20Interface zeroGold;
    
     
    ERC918Interface public miningLeader;
    
     
    address public mintHelper = 0x0;

    modifier onlyMintHelper {
        require(msg.sender == mintHelper);
        _;
    }
    
     
     
     
    uint rewardDivisor = 20;

     
    uint epochCount = 0;
    
     
    uint public lastRewardAmount = 0;

    mapping(bytes32 => bytes32) solutionForChallenge;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    constructor(address _miningLeader, address _mintHelper) public  {
         
        miningLeader = ERC918Interface(_miningLeader);

         
        mintHelper = _mintHelper;

         
         
        zeroGold = ERC20Interface(0x6ef5bca539A4A01157af842B4823F54F9f7E9968);
    }

     
    function merge() external onlyMintHelper returns (bool success) {
         
        bytes32 futureChallengeNumber = blockhash(block.number - 1);

         
        bytes32 challengeNumber = miningLeader.getChallengeNumber();

         
        if (challengeNumber == futureChallengeNumber) {
             
             
            return false; 
        }

         
        if (miningLeader.lastRewardTo() != msg.sender) {
             
             
            return false;
        }
            
         
        if (miningLeader.lastRewardEthBlockNumber() != block.number) {
             
             
            return false;
        }

         
         
         
        bytes32 parentChallengeNumber = miningLeader.challengeNumber();
        bytes32 solution = solutionForChallenge[parentChallengeNumber];
        if (solution != 0x0) return false;  
        
        bytes32 digest = 'merge';
        solutionForChallenge[parentChallengeNumber] = digest;

         
         
        
         
        uint rewardAmount = getRewardAmount();

         
        uint balance = zeroGold.balanceOf(address(this));

         
        assert(rewardAmount <= balance);

         
         
         
        lastRewardAmount = rewardAmount;
        
         
        epochCount = epochCount.add(1);

         
        emit Mint(msg.sender, rewardAmount, epochCount, 0);

        return true;
    }

     
     
     
    function transfer(
        address _wallet, 
        uint _reward
    ) external onlyMintHelper returns (bool) {
         
        if (_reward > lastRewardAmount) {
            return false;
        }
            
         
        lastRewardAmount = lastRewardAmount.sub(_reward);

         
        zeroGold.transfer(_wallet, _reward);
    }

     
    function getRewardAmount() public constant returns (uint) {
         
        uint totalBalance = zeroGold.balanceOf(address(this));

        return totalBalance.div(rewardDivisor);
    }

     
    function setMiningLeader(address _miningLeader) external onlyOwner {
        miningLeader = ERC918Interface(_miningLeader);
    }

     
    function setMintHelper(address _mintHelper) external onlyOwner {
        mintHelper = _mintHelper;
    }

     
    function setRewardDivisor(uint _rewardDivisor) external onlyOwner {
        rewardDivisor = _rewardDivisor;
    }

     
    function () public payable {
         
        revert('Oops! Direct payments are NOT permitted here.');
    }

     
    function transferAnyERC20Token(
        address tokenAddress, uint tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}