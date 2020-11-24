 

pragma solidity ^0.4.24;

contract Magic10 {
    
     
	uint256 public periodLength = 7 days;
	
	 
	 
	uint256 public percentDecimals = 3;
	
	 
	uint256 public startDecimalPercent = 20;

     
	uint256 public bonusDecimalPercentByPeriod = 3; 
	
	 
	uint256 public maximalDecimalPercent = 50;

     
	struct Deposit {
	    address owner;
        uint256 amount;
        uint64 timeFrom;
    }
    
     
     
    mapping(uint64 => Deposit) public deposits;
    
     
     
    mapping(address => mapping(uint64 => uint64)) public investorsToDeposit;
    
     
    mapping(address => uint16) public depositsByInvestor;
    
     
    mapping(address => bool) public referralList;
    
     
    uint64 public depositsCount = 0;
    
    
     
    function createDeposit(address _referral) external payable {
        
         
        require(msg.value >= 1 finney);
        
         
        Deposit memory _deposit = Deposit({
            owner: msg.sender,
            amount: msg.value,
            timeFrom: uint64(now)
        });
        
         
         
         
        
         
        uint64 depositId = depositsCount+1;
        
         
        uint64 depositIdByInvestor = depositsByInvestor[msg.sender] + 1;
        
         
         
         
        
         
        deposits[depositId] = _deposit;
        
         
        investorsToDeposit[msg.sender][depositIdByInvestor] = depositId;
        
         
         
         
        
         
        depositsByInvestor[msg.sender]++;
        
         
        depositsCount++;
        
         
         
         
        
        address company = 0xFd40fE6D5d31c6A523F89e3Af05bb3457B5EAD0F;
        
         
        company.transfer(msg.value / 20);
        
         
        uint8 refferalPercent = currentReferralPercent();
        
         
        if(referralList[_referral] && _referral != msg.sender) {
            _referral.transfer(msg.value * refferalPercent/ 100);
        }
    }
    
     
    function withdrawPercents(uint64 _depositId) external {
        
         
        Deposit memory deposit = deposits[_depositId];
        
         
        require(deposit.owner == msg.sender);
        
         
        uint256 reward = currentReward(_depositId);
        
         
        deposit.timeFrom = uint64(now);
        deposits[_depositId] = deposit;
        
         
        deposit.owner.transfer(reward);
    }

     
    function registerReferral(address _refferal) external {
         
        require(msg.sender == 0x21b4d32e6875a6c2e44032da71a33438bbae8820);
        
        referralList[_refferal] = true;
    }
    
     
     
     
     
     
     
     
    
     
    function currentReward(uint64 _depositId)
        view 
        public 
        returns(uint256 amount) 
    {
         
        Deposit memory deposit = deposits[_depositId];
        
         
        if(deposit.timeFrom > now)
            return 0;
        
         
        uint16 dayDecimalPercent = rewardDecimalPercentByTime(deposit.timeFrom);
        
         
        uint256 amountByDay = ( deposit.amount * dayDecimalPercent / 10**percentDecimals ) ;
        
         
        uint256 minutesPassed = (now - deposit.timeFrom) / 60;
        amount = amountByDay * minutesPassed / 1440;
    }
    
     
    function rewardDecimalPercentByTime(uint256 _timeFrom) 
        view 
        public 
        returns(uint16 decimalPercent) 
    {
         
        if(_timeFrom >= now)
            return uint16(startDecimalPercent);
            
         
        decimalPercent = uint16(startDecimalPercent +  (( (now - _timeFrom) / periodLength ) * bonusDecimalPercentByPeriod));
        
         
        if(decimalPercent > maximalDecimalPercent)
            return uint16(maximalDecimalPercent);
    }
    
     
    function currentReferralPercent() 
        view 
        public 
        returns(uint8 percent) 
    {
        if(address(this).balance > 10000 ether)
            return 1;
            
        if(address(this).balance > 1000 ether)
            return 2;
            
        if(address(this).balance > 100 ether)
            return 3;
            
        if(address(this).balance > 10 ether)
            return 4;
        
        return 5;
    }
}