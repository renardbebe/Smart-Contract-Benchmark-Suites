 

pragma solidity ^0.4.23;

 

 

 

 

 

 

 

 

 


 



 

 

 

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


 

 

 

 

contract _0xCatetherToken is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;



    uint public latestDifficultyPeriodStarted;


    uint public epochCount; 

     
    uint public  _MINIMUM_TARGET = 2**16;


     
     
    uint public  _MAXIMUM_TARGET = 2**224;


    uint public miningTarget;

    bytes32 public challengeNumber;    


    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

     
    
    mapping(bytes32 => bytes32) public solutionForChallenge;
    mapping(uint => uint) public timeStampForEpoch;
    mapping(uint => uint) public targetForEpoch;

    mapping(address => uint) balances;
    mapping(address => address) donationsTo;


    mapping(address => mapping(address => uint)) allowed;

    event Donation(address donation);
    event DonationAddressOf(address donator, address donnationAddress);
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

     

     

     

    constructor() public{

        symbol = "0xCATE";

        name = "0xCatether Token";

        decimals = 8;
        epochCount = 0;
        _totalSupply = 0;

        miningTarget = _MAXIMUM_TARGET;
        challengeNumber = "GENESIS_BLOCK";
        solutionForChallenge[challengeNumber] = "Yes, this is the Genesis block.";

        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();


         
         
         
    }




        function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {


             
            bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );

             
            if (digest != challenge_digest) revert();

             
            if(uint256(digest) > miningTarget) revert();


             
             bytes32 solution = solutionForChallenge[challengeNumber];
             solutionForChallenge[challengeNumber] = digest;
             if(solution != 0x0) revert();   


            uint reward_amount = getMiningReward(digest);

            balances[msg.sender] = balances[msg.sender].add(reward_amount);

            _totalSupply = _totalSupply.add(reward_amount);

             
            lastRewardTo = msg.sender;
            lastRewardAmount = reward_amount;
            lastRewardEthBlockNumber = block.number;

             _startNewMiningEpoch();

              emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );

           return true;

        }


     
    function _startNewMiningEpoch() internal {
        
        targetForEpoch[epochCount] = miningTarget;
        timeStampForEpoch[epochCount] = block.timestamp;
        epochCount = epochCount.add(1);
    
       
       
       
        _reAdjustDifficulty();


       
       
      challengeNumber = blockhash(block.number - 1);

    }




     
     
    function _reAdjustDifficulty() internal {
        
         
         
         
         
        
        uint timeTarget = 188;  
        
        if(epochCount>28) {
             
            uint i = 0;
            uint sumD = 0;
            uint sumST = 0;   
            uint solvetime;
            
            for(i=epochCount.sub(28); i<epochCount; i++){
                sumD = sumD.add(targetForEpoch[i]);
                solvetime = timeStampForEpoch[i] - timeStampForEpoch[i-1];
                if (solvetime > timeTarget.mul(7)) {solvetime = timeTarget.mul(7); }
                 
                sumST += solvetime;                                                    
                 
            }
            sumST = sumST.mul(10000).div(2523).add(1260);  
            miningTarget = sumD.mul(60).div(sumST);  
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
        targetForEpoch[epochCount] = miningTarget;
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



     
     
    function getMiningReward(bytes32 digest) public constant returns (uint) {
        
        if(epochCount > 600000) return (30000 * 10**uint(decimals) );
        if(epochCount > 500000) return (46875 * 10**uint(decimals) );
        if(epochCount > 400000) return (93750 * 10**uint(decimals) );
        if(epochCount > 300000) return (187500 * 10**uint(decimals) );
        if(epochCount > 200000) return (375000 * 10**uint(decimals) );
        if(epochCount > 145000) return (500000 * 10**uint(decimals) );
        if(epochCount > 100000) return ((uint256(keccak256(digest, blockhash(block.number - 2))) % 1500000) * 10**uint(decimals) );
        return ( (uint256(keccak256(digest, blockhash(block.number - 2))) % 3000000) * 10**uint(decimals) );

    }

     
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

        return digest;

      }

         
      function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {

          bytes32 digest = keccak256(challenge_number,msg.sender,nonce);

          if(uint256(digest) > testTarget) revert();

          return (digest == challenge_digest);

        }



     

     

     

    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }



     

     

     

    function balanceOf(address tokenOwner) public constant returns (uint balance) {

        return balances[tokenOwner];

    }
    
    function donationTo(address tokenOwner) public constant returns (address donationAddress) {

        return donationsTo[tokenOwner];

    }
    
    function changeDonation(address donationAddress) public returns (bool success) {

        donationsTo[msg.sender] = donationAddress;
        
        emit DonationAddressOf(msg.sender , donationAddress); 
        return true;
    
    }



     

     

     

     

     

    function transfer(address to, uint tokens) public returns (bool success) {
        
        address donation = donationsTo[msg.sender];
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        balances[to] = balances[to].add(tokens);
        balances[donation] = balances[donation].add(161803400);
        
        emit Transfer(msg.sender, to, tokens);
        emit Donation(donation);
        
        return true;

    }
    
    function transferAndDonateTo(address to, uint tokens, address donation) public returns (bool success) {
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);
        balances[donation] = balances[donation].add(161803400);

        emit Transfer(msg.sender, to, tokens);
        emit Donation(donation);

        return true;

    }



     

     

     

     

     

     

     

     

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



     

     

     

     

     

     

     

     

     

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        address donation = donationsTo[from];
        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);
        balances[donation] = balances[donation].add(161803400);

        emit Transfer(from, to, tokens);
        emit Donation(donation);

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