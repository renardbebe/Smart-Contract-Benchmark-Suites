 

pragma solidity ^0.4.24;

 

contract Slugroad {
    using SafeMath for uint;
    
     
    
    event WithdrewBalance (address indexed player, uint eth);
    event BoughtSlug (address indexed player, uint eth, uint slug);
    event SkippedAhead (address indexed player, uint eth, uint slug);
    event TradedMile (address indexed player, uint eth, uint mile);
    event BecameDriver (address indexed player, uint eth);
    event TookWheel (address indexed player, uint eth);
    event ThrewSlug (address indexed player);
    event JumpedOut (address indexed player, uint eth);
    event TimeWarped (address indexed player, uint indexed loop, uint eth);
    event NewLoop (address indexed player, uint indexed loop);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);    

     
    
    uint256 constant public RACE_TIMER_START    = 604800;  
    uint256 constant public HYPERSPEED_LENGTH   = 3600;  
	uint256 constant public THROW_SLUG_REQ      = 200;  
    uint256 constant public DRIVER_TIMER_BOOST  = 360;  
    uint256 constant public SLUG_COST_FLOOR     = 0.000025 ether;  
    uint256 constant public DIV_SLUG_COST       = 10000;  
    uint256 constant public TOKEN_MAX_BUY       = 1 ether;  
    uint256 constant public MIN_SPEED           = 100;
    uint256 constant public MAX_SPEED           = 1000;
    uint256 constant public ACCEL_FACTOR        = 672;  
    uint256 constant public MILE_REQ            = 6000;  
    address constant public SNAILTHRONE         = 0x261d650a521103428C6827a11fc0CBCe96D74DBc;
	
     
    
     
    address public starter;
    bool public gameStarted;
    
     
    uint256 public loop;
    uint256 public timer;
    address public driver;
    
     
    bool public hyperSpeed = false;
    
     
    uint256 public lastHijack;
    
     
    uint256 public loopChest;
    uint256 public slugBank;
    uint256 public thronePot;
    
     
    uint256 public divPerSlug;
    uint256 public maxSlug;
    	
     
    
    mapping (address => uint256) public slugNest;
    mapping (address => uint256) public playerBalance;
    mapping (address => uint256) public claimedDiv;
    mapping (address => uint256) public mile;
	
     
    
     
    
     
     
    
    constructor() public {
        starter = msg.sender;
        gameStarted = false;
    }
    
     
     
     
     
    
    function StartRace() public payable {
        require(gameStarted == false);
        require(msg.sender == starter);
        
        timer = now.add(RACE_TIMER_START).add(HYPERSPEED_LENGTH);
        loop = 1;
        gameStarted = true;
        lastHijack = now;
        driver = starter;
        BuySlug();
    }

     

     
     
     
    
    function PotSplit(uint256 _msgValue) private {
        divPerSlug = divPerSlug.add(_msgValue.mul(3).div(5).div(maxSlug));
        slugBank = slugBank.add(_msgValue.div(5));
        loopChest = loopChest.add(_msgValue.div(10));
        thronePot = thronePot.add(_msgValue.div(10));
    }
    
     
     
     
    
    function ClaimDiv() private {
        uint256 _playerDiv = ComputeDiv(msg.sender);
        
        if(_playerDiv > 0){
             
            claimedDiv[msg.sender] = claimedDiv[msg.sender].add(_playerDiv);
                
             
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_playerDiv);
        }
    }
    
     
     
    
    function BecomeDriver() private {
        
         
        uint256 _mile = ComputeMileDriven();
        mile[driver] = mile[driver].add(_mile);
        
         
        if(now.add(HYPERSPEED_LENGTH) >= timer){
            timer = now.add(DRIVER_TIMER_BOOST).add(HYPERSPEED_LENGTH);
            
            emit TookWheel(msg.sender, loopChest);
            
         
        } else {
            timer = timer.add(DRIVER_TIMER_BOOST);
            
            emit BecameDriver(msg.sender, loopChest);
        }
        
        lastHijack = now;
        driver = msg.sender;
    }
    
     
    
     
     
     
    
    function TimeWarp() public {
		require(gameStarted == true, "game hasn't started yet");
        require(now >= timer, "race isn't finished yet");
        
         
        uint256 _mile = ComputeMileDriven();
        mile[driver] = mile[driver].add(_mile);
        
         
        timer = now.add(RACE_TIMER_START).add(HYPERSPEED_LENGTH);
        loop = loop.add(1);
        
         
        uint256 _nextPot = slugBank.div(2);
        slugBank = slugBank.sub(_nextPot);
        
         
        if(driver != starter){
            
             
            uint256 _reward = loopChest;
        
             
            loopChest = _nextPot;
        
             
            playerBalance[driver] = playerBalance[driver].add(_reward);
        
            emit TimeWarped(driver, loop, _reward);
            
         
        } else {
            
             
            loopChest = loopChest.add(_nextPot);

            emit NewLoop(msg.sender, loop);
        }
        
        lastHijack = now;
         
        driver = msg.sender;
    }
    
     
     
    
    function BuySlug() public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= TOKEN_MAX_BUY, "maximum buy = 1 ETH");
		require(now <= timer, "race is over!");
        
         
        uint256 _slugBought = ComputeBuy(msg.value, true);
            
         
        claimedDiv[msg.sender] = claimedDiv[msg.sender].add(_slugBought.mul(divPerSlug));
            
         
        maxSlug = maxSlug.add(_slugBought);
            
         
        PotSplit(msg.value);
            
         
        slugNest[msg.sender] = slugNest[msg.sender].add(_slugBought);
        
		emit BoughtSlug(msg.sender, msg.value, _slugBought);
		
         
        if(_slugBought >= 200){
            BecomeDriver();
        }       
    }
    
     
     
     
    
    function SkipAhead() public {
        require(gameStarted == true, "game hasn't started yet");
        ClaimDiv();
        require(playerBalance[msg.sender] > 0, "no ether to timetravel");
		require(now <= timer, "race is over!");
        
         
        uint256 _etherSpent = playerBalance[msg.sender];
        uint256 _slugHatched = ComputeBuy(_etherSpent, false);
            
         
        claimedDiv[msg.sender] = claimedDiv[msg.sender].add(_slugHatched.mul(divPerSlug));
        playerBalance[msg.sender] = 0;
            
         
        maxSlug = maxSlug.add(_slugHatched);
                    
         
        PotSplit(_etherSpent);
            
         
        slugNest[msg.sender] = slugNest[msg.sender].add(_slugHatched);
        
		emit SkippedAhead(msg.sender, _etherSpent, _slugHatched);
		
         
        if(_slugHatched >= 200){
            BecomeDriver();
        }
    }
    
     
     
    
    function WithdrawBalance() public {
        ClaimDiv();
        require(playerBalance[msg.sender] > 0, "no ether to withdraw");
        
        uint256 _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
    }
    
     
     
    
    function ThrowSlug() public {
        require(gameStarted == true, "game hasn't started yet");
        require(slugNest[msg.sender] >= THROW_SLUG_REQ, "not enough slugs in nest");
        require(now <= timer, "race is over!");
        
         
        ClaimDiv();
            
         
        maxSlug = maxSlug.sub(THROW_SLUG_REQ);
        slugNest[msg.sender] = slugNest[msg.sender].sub(THROW_SLUG_REQ);
            
         
        claimedDiv[msg.sender] = claimedDiv[msg.sender].sub(THROW_SLUG_REQ.mul(divPerSlug));
        
		emit ThrewSlug(msg.sender);
		
         
        BecomeDriver();
    }
    
     
     
     
    
    function JumpOut() public {
        require(gameStarted == true, "game hasn't started yet");
        require(msg.sender == driver, "can't jump out if you're not in the car!");
        require(msg.sender != starter, "starter isn't allowed to be driver");
        
         
        uint256 _mile = ComputeMileDriven();
        mile[driver] = mile[driver].add(_mile);
        
         
        uint256 _reward = ComputeHyperReward();
            
         
        loopChest = loopChest.sub(_reward);
            
         
        timer = now.add(HYPERSPEED_LENGTH.mul(2));
            
         
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_reward);
        
         
        driver = starter;
        
         
        lastHijack = now;
            
        emit JumpedOut(msg.sender, _reward);
    }
    
     
     
    
    function TradeMile() public {
        require(mile[msg.sender] >= MILE_REQ, "not enough miles for a reward");
        require(msg.sender != starter, "starter isn't allowed to trade miles");
        require(msg.sender != driver, "can't trade miles while driver");
        
         
		uint256 _mile = mile[msg.sender].div(MILE_REQ);
		
		 
		if(_mile > 20){
		    _mile = 20;
		}
        
         
        uint256 _reward = ComputeMileReward(_mile);
        
         
        loopChest = loopChest.sub(_reward);
        
         
        mile[msg.sender] = mile[msg.sender].sub(_mile.mul(MILE_REQ));
        
         
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_reward);
        
        emit TradedMile(msg.sender, _reward, _mile);
    }
    
     
     
    
    function PayThrone() public {
        uint256 _payThrone = thronePot;
        thronePot = 0;
        if (!SNAILTHRONE.call.value(_payThrone)()){
            revert();
        }
        
        emit PaidThrone(msg.sender, _payThrone);
    }
    
     
     
    
    function() public payable {
        slugBank = slugBank.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
     

     
     
     
     
     
    
    function ComputeHyperReward() public view returns(uint256) {
        uint256 _remainder = timer.sub(now);
        return HYPERSPEED_LENGTH.sub(_remainder).mul(loopChest).div(10000);
    }

     
     
     
     
    
    function ComputeSlugCost(bool _isBuy) public view returns(uint256) {
        if(_isBuy == true){
            return (SLUG_COST_FLOOR.add(loopChest.div(DIV_SLUG_COST))).div(loop);
        } else {
            return (SLUG_COST_FLOOR.add(loopChest.div(DIV_SLUG_COST))).div(loop.add(1));
        }
    }
    
     
     
     
    
    function ComputeBuy(uint256 _ether, bool _isBuy) public view returns(uint256) {
        uint256 _slugCost;
        if(_isBuy == true){
            _slugCost = ComputeSlugCost(true);
        } else {
            _slugCost = ComputeSlugCost(false);
        }
        return _ether.div(_slugCost);
    }
    
     
     
    
    function ComputeDiv(address _player) public view returns(uint256) {
         
        uint256 _playerShare = divPerSlug.mul(slugNest[_player]);
		
         
    	_playerShare = _playerShare.sub(claimedDiv[_player]);
        return _playerShare;
    }
    
     
     
     
    
    function ComputeSpeed(uint256 _time) public view returns(uint256) {
        
         
        if(timer > _time.add(HYPERSPEED_LENGTH)){
            
             
            if(timer.sub(_time) < RACE_TIMER_START){
                return MAX_SPEED.sub((timer.sub(_time).sub(HYPERSPEED_LENGTH)).div(ACCEL_FACTOR));
            } else {
                return MIN_SPEED;  
            }
        } else {
            return MAX_SPEED;  
        }
    }
    
     
     
    
    function ComputeMileDriven() public view returns(uint256) {
        uint256 _speedThen = ComputeSpeed(lastHijack);
        uint256 _speedNow = ComputeSpeed(now);
        uint256 _timeDriven = now.sub(lastHijack);
        uint256 _averageSpeed = (_speedNow.add(_speedThen)).div(2);
        return _timeDriven.mul(_averageSpeed).div(HYPERSPEED_LENGTH);
    }
    
     
     
    
    function ComputeMileReward(uint256 _reqMul) public view returns(uint256) {
        return _reqMul.mul(loopChest).div(100);
    }
    
     
     
    
    function GetNest(address _player) public view returns(uint256) {
        return slugNest[_player];
    }
    
     
     
    
    function GetMile(address _player) public view returns(uint256) {
        return mile[_player];
    }
    
     
     
    
    function GetBalance(address _player) public view returns(uint256) {
        return playerBalance[_player];
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