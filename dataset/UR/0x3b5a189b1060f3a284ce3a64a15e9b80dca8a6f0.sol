 

pragma solidity ^0.4.19;


 

 
 

 

 
 
 


 
 
 
 

contract NBAOnlineLaunchPromotion {
    
     
    mapping(address => uint256) public deposits;
    mapping(address => bool) depositorAlreadyStored;
    address[] public depositors;

     
    address public ownerAddress;
    
     
    bool public prizesAwarded = false;
    
     
	 
    uint256 public constant LAUNCH_DATE = 1523678400;  
    
     
    uint256 private constant TOP_DEPOSIT_PRIZE = 0.5 ether;
    uint256 private constant RANDOM_DEPOSIT_PRIZE1 = 0.35 ether;
    uint256 private constant RANDOM_DEPOSIT_PRIZE2 = 0.15 ether;
    
    function NBAOnlineLaunchPromotion() public payable {
        require(msg.value == 1 ether);  
        ownerAddress = msg.sender;
    }
    
    
    function deposit() external payable {
        uint256 existing = deposits[msg.sender];
        
         
        deposits[msg.sender] = SafeMath.add(msg.value, existing);
        
         
        if (msg.value >= 0.01 ether && !depositorAlreadyStored[msg.sender]) {
            depositors.push(msg.sender);
            depositorAlreadyStored[msg.sender] = true;
        }
    }
    
    function refund() external {
         
        uint256 depositAmount = deposits[msg.sender];
        deposits[msg.sender] = 0;  
        msg.sender.transfer(depositAmount);
    }
    
    
    function refundPlayer(address depositor) external {
        require(msg.sender == ownerAddress);
        
         
        uint256 depositAmount = deposits[depositor];
        deposits[depositor] = 0;  
        
         
        depositor.transfer(depositAmount);
    }
    
    
    function awardPrizes() external {
        require(msg.sender == ownerAddress);
        require(now >= LAUNCH_DATE);
        require(!prizesAwarded);
        
         
        prizesAwarded = true;
        
        uint256 highestDeposit;
        address highestDepositWinner;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            address depositor = depositors[i];
            
             
            if (deposits[depositor] > highestDeposit) {
                highestDeposit = deposits[depositor];
                highestDepositWinner = depositor;
            }
        }
        
        uint256 numContestants = depositors.length;
        uint256 seed1 = numContestants + block.timestamp;
        uint256 seed2 = seed1 + (numContestants*2);
        
        address randomDepositWinner1 = depositors[randomContestant(numContestants, seed1)];
        address randomDepositWinner2 = depositors[randomContestant(numContestants, seed2)];
        
         
        while(randomDepositWinner2 == randomDepositWinner1) {
            seed2++;
            randomDepositWinner2 = depositors[randomContestant(numContestants, seed2)];
        }
        
        highestDepositWinner.transfer(TOP_DEPOSIT_PRIZE);
        randomDepositWinner1.transfer(RANDOM_DEPOSIT_PRIZE1);
        randomDepositWinner2.transfer(RANDOM_DEPOSIT_PRIZE2);
    }
    
    
     
    function randomContestant(uint256 contestants, uint256 seed) constant internal returns (uint256 result){
        return addmod(uint256(block.blockhash(block.number-1)), seed, contestants);   
    }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}