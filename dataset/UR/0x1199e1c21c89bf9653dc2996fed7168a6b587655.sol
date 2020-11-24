 

pragma solidity ^0.4.24;

 

contract SnailTree {
    using SafeMath for uint;
    
     
    
    event PlantedRoot(address indexed player, uint eth, uint pecan, uint treesize);
    event GavePecan(address indexed player, uint eth, uint pecan);
    event ClaimedShare(address indexed player, uint eth, uint pecan);
    event GrewTree(address indexed player, uint eth, uint pecan, uint boost);
    event WonRound (address indexed player, uint indexed round, uint eth);
    event WithdrewBalance (address indexed player, uint eth);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);

     
    
    uint256 constant SECONDS_IN_HOUR    = 3600;
    uint256 constant SECONDS_IN_DAY     = 86400;
    uint256 constant PECAN_WIN_FACTOR   = 0.0000000001 ether;  
    uint256 constant TREE_SIZE_COST     = 0.0000005 ether;  
    uint256 constant REWARD_SIZE_ETH    = 0.00000002 ether;  
    address constant SNAILTHRONE        = 0x261d650a521103428C6827a11fc0CBCe96D74DBc;

     
    
	 
    uint256 public gameRound            = 0;
	
	 
	uint256 public treePot              = 0;
	
	 
	uint256 public wonkPot              = 0;
	
	 
	uint256 public jackPot              = 0;
	
	 
	uint256 public thronePot            = 0;
	
	 
	uint256 public pecanToWin           = 0;
	
	 
	uint256 public pecanGiven           = 0;
	
	 
	uint256 public lastRootPlant        = 0;
	
     
    
    mapping (address => uint256) playerRound;
    mapping (address => uint256) playerBalance;
    mapping (address => uint256) treeSize;
    mapping (address => uint256) pecan;
    mapping (address => uint256) lastClaim;
    mapping (address => uint256) boost;

     
    
     
     
    
    constructor() public {
        gameRound = 1;
        pecanToWin = 1;
        lastRootPlant = now;
    }
    
     
    
     
     
     
     
    
    function CheckRound() private {       
        while(playerRound[msg.sender] != gameRound){
            treeSize[msg.sender] = treeSize[msg.sender].mul(4).div(5);
            playerRound[msg.sender] = playerRound[msg.sender].add(1);
            boost[msg.sender] = 1;
        }
    }
    
     
     
     
    
    function WinRound(address _msgSender) private {
        
         
        uint256 _round = gameRound;
        gameRound = gameRound.add(1);
        
         
        uint256 _reward = jackPot.div(5);
        jackPot = jackPot.sub(_reward);
        
         
        pecanGiven = 0;
        
         
        pecanToWin = ComputePecanToWin();
    
         
        playerBalance[_msgSender] = playerBalance[_msgSender].add(_reward);
        
        emit WonRound(_msgSender, _round, _reward);
    }
    
     
	 
	 
    
    function PotSplit(uint256 _msgValue) private {
        
        treePot = treePot.add(_msgValue.mul(4).div(10));
        wonkPot = wonkPot.add(_msgValue.mul(3).div(10));
        jackPot = jackPot.add(_msgValue.div(5));
        thronePot = thronePot.add(_msgValue.div(10));
    }
    
     
    
     
     
     
    
    function PlantRoot() public payable {
        require(tx.origin == msg.sender, "no contracts allowed");
        require(msg.value >= 0.001 ether, "at least 1 finney to plant a root");

         
        CheckRound();

         
        PotSplit(msg.value);
        
         
        pecanToWin = ComputePecanToWin();
        
         
        uint256 _newPecan = ComputePlantPecan(msg.value);
        
         
        lastRootPlant = now;
        lastClaim[msg.sender] = now;
        
         
        uint256 _treePlant = msg.value.div(TREE_SIZE_COST);
        
         
        treeSize[msg.sender] = treeSize[msg.sender].add(_treePlant);
        
         
        pecan[msg.sender] = pecan[msg.sender].add(_newPecan);
        
        emit PlantedRoot(msg.sender, msg.value, _newPecan, treeSize[msg.sender]);
    }
    
     
     
	 
    
    function GivePecan(uint256 _pecanGift) public {
        require(pecan[msg.sender] >= _pecanGift, "not enough pecans");
        
         
        CheckRound();
        
         
        uint256 _ethReward = ComputeWonkTrade(_pecanGift);
        
         
        pecan[msg.sender] = pecan[msg.sender].sub(_pecanGift);
        
         
        pecanGiven = pecanGiven.add(_pecanGift);
        
         
        wonkPot = wonkPot.sub(_ethReward);
        
         
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_ethReward);
        
         
        if(pecanGiven >= pecanToWin){
            WinRound(msg.sender);
        } else {
			emit GavePecan(msg.sender, _ethReward, _pecanGift);
		}
    }
    
     
     
     
    
    function ClaimShare() public {
        require(treeSize[msg.sender] > 0, "plant a root first");
		
         
        CheckRound();
        
         
        uint256 _ethReward = ComputeEtherShare(msg.sender);
        
         
        uint256 _pecanReward = ComputePecanShare(msg.sender);
        
         
        lastClaim[msg.sender] = now;
        
         
        treePot = treePot.sub(_ethReward);
        
         
        pecan[msg.sender] = pecan[msg.sender].add(_pecanReward);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(_ethReward);
        
        emit ClaimedShare(msg.sender, _ethReward, _pecanReward);
    }
    
     
     
     
     
    
    function GrowTree() public {
        require(treeSize[msg.sender] > 0, "plant a root first");

         
        CheckRound();
        
         
        uint256 _ethUsed = ComputeEtherShare(msg.sender);
        
         
        uint256 _pecanReward = ComputePecanShare(msg.sender);
        
         
        uint256 _timeSpent = now.sub(lastClaim[msg.sender]);
        
         
        lastClaim[msg.sender] = now;
        
         
        uint256 _treeGrowth = _ethUsed.div(TREE_SIZE_COST);
        
         
        treeSize[msg.sender] = treeSize[msg.sender].add(_treeGrowth);
        
         
        if(_timeSpent >= SECONDS_IN_HOUR){
            uint256 _boostPlus = _timeSpent.div(SECONDS_IN_HOUR);
            if(_boostPlus > 10){
                _boostPlus = 10;
            }
            boost[msg.sender] = boost[msg.sender].add(_boostPlus);
        }
        
         
        pecan[msg.sender] = pecan[msg.sender].add(_pecanReward);
        
        emit GrewTree(msg.sender, _ethUsed, _pecanReward, boost[msg.sender]);
    }
    
     
    
     
     
    
    function WithdrawBalance() public {
        require(playerBalance[msg.sender] > 0, "no ETH in player balance");
        
        uint _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
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
        jackPot = jackPot.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
     
    
     
     
     
    
    function ComputeEtherShare(address adr) public view returns(uint256) {
        
         
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
         
        uint256 _reward = _timeLapsed.mul(REWARD_SIZE_ETH).mul(treeSize[adr]).div(SECONDS_IN_DAY);
        
         
        if(_reward >= treePot){
            _reward = treePot;
        }
        return _reward;
    }
    
     
     
     
    
    function ComputeShareBoostFactor(address adr) public view returns(uint256) {
        
         
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
         
        uint256 _boostFactor = (_timeLapsed.div(SECONDS_IN_HOUR)).add(4);
        return _boostFactor;
    }
    
     
     
     
    
    function ComputePecanShare(address adr) public view returns(uint256) {
        
         
        uint256 _timeLapsed = now.sub(lastClaim[adr]);
        
         
        uint256 _shareBoostFactor = ComputeShareBoostFactor(adr);
        
         
        uint256 _reward = _timeLapsed.mul(treeSize[adr]).mul(_shareBoostFactor).mul(boost[msg.sender]).div(SECONDS_IN_DAY);
        return _reward;
    }
    
     
     
     
    
    function ComputePecanToWin() public view returns(uint256) {
        uint256 _pecanToWin = jackPot.div(PECAN_WIN_FACTOR);
        return _pecanToWin;
    }
    
     
     
     
    
    function ComputeWonkTrade(uint256 _pecanGift) public view returns(uint256) {
        
         
        if(_pecanGift > pecanToWin) {
            _pecanGift = pecanToWin;
        }
        uint256 _reward = _pecanGift.mul(wonkPot).div(pecanToWin).div(2);
        return _reward;
    }
    
     
     
     
    
    function ComputePlantBoostFactor() public view returns(uint256) {
        
         
        uint256 _timeLapsed = now.sub(lastRootPlant);
        
         
        uint256 _boostFactor = (_timeLapsed.mul(1)).add(100);
        return _boostFactor;
    }
    
     
     
     
    
    function ComputePlantPecan(uint256 _msgValue) public view returns(uint256) {

         
        uint256 _treeBoostFactor = ComputePlantBoostFactor();
        
         
        uint256 _reward = _msgValue.mul(_treeBoostFactor).div(TREE_SIZE_COST).div(100);
        return _reward;
    }

     
    
    function GetTree(address adr) public view returns(uint256) {
        return treeSize[adr];
    }
    
    function GetPecan(address adr) public view returns(uint256) {
        return pecan[adr];
    }
	
	function GetMyBoost() public view returns(uint256) {
        return boost[msg.sender];
    }
	
	function GetMyBalance() public view returns(uint256) {
	    return playerBalance[msg.sender];
	}
	
	function GetMyRound() public view returns(uint256) {
	    return playerRound[msg.sender];
	}
	
	function GetMyLastClaim() public view returns(uint256) {
	    return lastClaim[msg.sender];
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