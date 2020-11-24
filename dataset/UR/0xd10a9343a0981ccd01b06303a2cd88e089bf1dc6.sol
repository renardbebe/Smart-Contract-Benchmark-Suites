 

pragma solidity ^0.5.7;

 

contract SnailThrone {
    mapping (address => uint256) public hatcherySnail;
}

contract SnailTroi {
    using SafeMath for uint;
    
     

    event GrewTroi(address indexed player, uint eth, uint size);
    event NewLeader(address indexed player, uint eth);
    event HarvestedFroot(address indexed player, uint eth, uint size);
    event BecameKing(address indexed player, uint eth, uint king);
    event ResetClock(address indexed player, uint eth);
    event Doomed(address leader, address king, uint eth);
    event WonDaily (address indexed player, uint eth);
    event WithdrewBalance (address indexed player, uint eth);
    event PaidThrone (address indexed player, uint eth);
    event BoostedChest (address indexed player, uint eth);

     
    
    uint256 constant SECONDS_IN_DAY     = 86400;
    uint256 constant MINIMUM_INVEST     = 0.001 ether;  
    uint256 constant KING_BASE_COST     = 0.02 ether;  
    uint256 constant REFERRAL_REQ       = 420;
    uint256 constant REFERRAL_PERCENT   = 20;
    uint256 constant KING_PERCENT       = 4;
    uint256 constant DAILY_PERCENT      = 2;
    address payable constant SNAILTHRONE= 0x261d650a521103428C6827a11fc0CBCe96D74DBc;
    
	SnailThrone throneContract;

     
	
	 
	bool public gameActive              = false;
	
	 
	address public dev                  = msg.sender;
	
	 
	uint256 public troiChest            = 0;
	
	 
	uint256 public thronePot            = 0;
	
	 
	uint256 public troiReward           = 0.000001 ether;  
	
	 
	uint256 public doomclockTimer;
	uint256 public doomclockCost        = MINIMUM_INVEST;
	address public doomclockLeader;  
	
	 
	struct King {
        uint256 cost;
        address owner;
    }

    King[4] lostKing;
	
	 
	uint256 public lastBonus;
	
	 
	uint256 public dailyTimer;
	address public dailyLeader;
	uint256 public dailyMax;
	
     
    
    mapping (address => uint256) playerBalance;
    mapping (address => uint256) troiSize;
    mapping (address => uint256) lastFroot;
    mapping (address => address) referral;

     
    
     
    
    constructor() public {
        throneContract = SnailThrone(SNAILTHRONE);
    }
    
     
     
     
    
    function StartGame() payable public {
        require(gameActive != true, "game is already active");
        require(msg.sender == dev, "you're not snailking!");
        require(msg.value == 1 ether, "seed must be 1 ETH");
        
         
		troiChest = msg.value;
		
		 
        uint256 _growth = msg.value.div(troiReward);
        
         
        troiSize[msg.sender] = troiSize[msg.sender].add(_growth);
		
		 
		referral[msg.sender] = dev;
		doomclockLeader = dev;
		dailyLeader = dev;
		
        for(uint256 i = 0; i < 4; i++){
            lostKing[i].cost = KING_BASE_COST;
            lostKing[i].owner = dev;
        }
        
        dailyTimer = now.add(SECONDS_IN_DAY);
        doomclockTimer = now.add(SECONDS_IN_DAY);
        lastBonus = now;
        lastFroot[msg.sender] = now;
        gameActive = true;
    }
    
     
    
     
     
     
    
    function CheckDailyTimer() private {
        if(now > dailyTimer){
            dailyTimer = now.add(SECONDS_IN_DAY);
            uint256 _reward = troiChest.mul(DAILY_PERCENT).div(100);
            troiChest = troiChest.sub(_reward);
            playerBalance[dailyLeader] = playerBalance[dailyLeader].add(_reward);
            dailyMax = 0;
            
            emit WonDaily(dailyLeader, _reward);
            
            if(thronePot > 0.01 ether){
                uint256 _payThrone = thronePot;
                thronePot = 0;
                (bool success, bytes memory data) = SNAILTHRONE.call.value(_payThrone)("");
                require(success);
     
                emit PaidThrone(msg.sender, _payThrone);
            }
        }
    }

     
     
     
     
    
    function CheckDoomclock(uint256 _msgValue) private {
        if(now < doomclockTimer){
            if(_msgValue >= doomclockCost){
                doomclockTimer = now.add(SECONDS_IN_DAY);
                doomclockCost = doomclockCost.add(MINIMUM_INVEST);
                doomclockLeader = msg.sender;
                
                emit ResetClock(msg.sender, doomclockCost);
            }
        } else {
			troiReward = troiReward.mul(9).div(10);
            doomclockTimer = now.add(SECONDS_IN_DAY);
            doomclockCost = MINIMUM_INVEST;
            uint256 _reward = troiChest.mul(KING_PERCENT).div(100);
            troiChest = troiChest.sub(_reward.mul(2));
            playerBalance[doomclockLeader] = playerBalance[doomclockLeader].add(_reward);
            playerBalance[lostKing[3].owner] = playerBalance[lostKing[3].owner].add(_reward);
            
            for(uint256 i = 0; i < 4; i++){
            lostKing[i].cost = KING_BASE_COST;
            }
            
            emit Doomed(doomclockLeader, lostKing[3].owner, _reward);
        }
    }
    
     
    
     
     
     
     
    
    function GrowTroi(address _ref) public payable {
        require(gameActive == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "no contracts allowed");
        require(msg.value >= MINIMUM_INVEST, "at least 1 finney to grow a troi");
        require(_ref != msg.sender, "can't refer yourself, silly");
        
         
        if(troiSize[msg.sender] != 0){
            HarvestFroot();
        } else {
            lastFroot[msg.sender] = now;
        }
        
         
        uint256 _snail = GetSnail(_ref);
        if(_snail >= REFERRAL_REQ){
            referral[msg.sender] = _ref;
        } else {
            referral[msg.sender] = dev;
        }

         
        uint256 _chestTemp = troiChest.add(msg.value.mul(9).div(10));
        thronePot = thronePot.add(msg.value.div(10));
        
         
        uint256 _reward = msg.value.mul(KING_PERCENT).div(100);
        _chestTemp = _chestTemp.sub(_reward);
        troiChest = _chestTemp;
        playerBalance[lostKing[0].owner] = playerBalance[lostKing[0].owner].add(_reward);
        
         
        uint256 _growth = msg.value.div(troiReward);
        
         
        troiSize[msg.sender] = troiSize[msg.sender].add(_growth);
        
         
        emit GrewTroi(msg.sender, msg.value, troiSize[msg.sender]);
    
         
        if(msg.value > dailyMax){
            dailyMax = msg.value;
            dailyLeader = msg.sender;
            
            emit NewLeader(msg.sender, msg.value);
        }
        
         
        CheckDailyTimer();
        
         
        CheckDoomclock(msg.value);
    }
    
     
     
     
     
    
    function HarvestFroot() public {
        require(gameActive == true, "game hasn't started yet");
        require(troiSize[msg.sender] > 0, "grow your troi first");
        uint256 _timeSince = lastFroot[msg.sender].add(SECONDS_IN_DAY);
        require(now > _timeSince, "your harvest isn't ready");
        
         
        uint256 _reward = ComputeHarvest();
        uint256 _ref = _reward.mul(REFERRAL_PERCENT).div(100);
        uint256 _king = _reward.mul(KING_PERCENT).div(100);
        
         
        lastFroot[msg.sender] = now;
        lastBonus = now;
        
         
        troiChest = troiChest.sub(_reward).sub(_ref).sub(_king);
        
         
        playerBalance[referral[msg.sender]] = playerBalance[referral[msg.sender]].add(_ref);
        
         
        playerBalance[lostKing[2].owner] = playerBalance[lostKing[2].owner].add(_king);
        
         
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_reward);
        
        emit HarvestedFroot(msg.sender, _reward, troiSize[msg.sender]);
        
         
        CheckDailyTimer();
        
         
        CheckDoomclock(0);
    }
    
     
     
     
    
    function BecomeKing(uint256 _id) payable public {
        require(gameActive == true, "game is paused");
        require(tx.origin == msg.sender, "no contracts allowed");
        require(msg.value == lostKing[_id].cost, "wrong ether cost for king");
        
         
        troiChest = troiChest.add(KING_BASE_COST.div(4));
        thronePot = thronePot.add(KING_BASE_COST.div(4));
        
         
        uint256 _prevReward = msg.value.sub(KING_BASE_COST.div(2));
        address _prevOwner = lostKing[_id].owner;
        playerBalance[_prevOwner] = playerBalance[_prevOwner].add(_prevReward);
        
         
        lostKing[_id].owner = msg.sender;
        lostKing[_id].cost = lostKing[_id].cost.add(KING_BASE_COST);
        
        emit BecameKing(msg.sender, msg.value, _id);
    }
    
     
    
     
     
    
    function WithdrawBalance() public {
        require(playerBalance[msg.sender] > 0, "no ETH in player balance");
        
        uint _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
    }
    
     
     
    
    function() external payable {
        troiChest = troiChest.add(msg.value);
        
        emit BoostedChest(msg.sender, msg.value);
    }
    
     
    
     
     
    
    function ComputeHarvest() public view returns(uint256) {
        
         
        uint256 _timeLapsed = now.sub(lastFroot[msg.sender]);
        
         
        uint256 _bonus = ComputeBonus();
         
        uint256 _reward = troiReward.mul(troiSize[msg.sender]).mul(_timeLapsed.add(_bonus)).div(SECONDS_IN_DAY).div(100);
        
         
        uint256 _sum = _reward.add(_reward.mul(REFERRAL_PERCENT.add(KING_PERCENT)).div(100));
        if(_sum > troiChest){
            _reward = troiChest.mul(100).div(REFERRAL_PERCENT.add(KING_PERCENT).add(100));
        }
        return _reward;
    }
    
     
     
    
    function ComputeBonus() public view returns(uint256) {
        uint256 _bonus = (now.sub(lastBonus)).mul(8);
        if(msg.sender == lostKing[1].owner){
            _bonus = _bonus.mul(2);
        }
        return _bonus;
    }
    
     
    
    function GetTroi(address adr) public view returns(uint256) {
        return troiSize[adr];
    }
	
	function GetMyBalance() public view returns(uint256) {
	    return playerBalance[msg.sender];
	}
	
	function GetMyLastHarvest() public view returns(uint256) {
	    return lastFroot[msg.sender];
	}
	
	function GetMyReferrer() public view returns(address) {
	    return referral[msg.sender];
	}
	
	function GetSnail(address _adr) public view returns(uint256) {
        return throneContract.hatcherySnail(_adr);
    }
	
	function GetKingCost(uint256 _id) public view returns(uint256) {
		return lostKing[_id].cost;
	}
	
	function GetKingOwner(uint256 _id) public view returns(address) {
		return lostKing[_id].owner;
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