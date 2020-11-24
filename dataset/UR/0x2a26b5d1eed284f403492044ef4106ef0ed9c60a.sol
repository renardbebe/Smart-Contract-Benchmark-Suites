 

pragma solidity ^0.4.24;

 

contract LordsOfTheSnails {
    using SafeMath for uint;
    
     
    
    event WonRound (address indexed player, uint eth, uint round);
    event StartedRound (uint round);
    event GrabbedSnail (address indexed player, uint snail, uint eth, uint egg, uint playeregg);
    event SnaggedEgg (address indexed player, uint snail, uint egg, uint playeregg);
    event ClaimedLord (address indexed player, uint lord, uint eth, uint egg, uint playeregg);
    event WithdrewBalance (address indexed player, uint eth);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);

     
    
    uint256 constant SNAIL_COST     = 0.01 ether;  
    uint256 constant LORD_COST      = 0.05 ether;  
    uint256 constant SNAG_COST      = 0.002 ether;  
    uint256 constant DOWNTIME       = 86400;  
    uint256 constant WIN_REQ        = 1000000;  
    address constant SNAILTHRONE    = 0x261d650a521103428C6827a11fc0CBCe96D74DBc;

     

    struct Snail {
        uint256 level;
        uint256 lastSnag;
        address owner;
    }
    
    Snail[8] colorSnail;
    
    struct Lord {
        uint256 level;
        address owner;
    }
    
    Lord[8] lord;
    
     
    
     
    bool public gameActive = false;
    
     
    uint256 public round;
    
     
    uint256 public nextRoundStart;
    
     
    uint256 public victoryEgg;
    
     
    address public leader;
    
     
    uint256 public lastGrab;
    
     
    uint256 public lastClaim;
    
     
    uint256 public snailPot;
    
     
    uint256 public roundPot;
    
     
    uint256 public thronePot;
    
     
    
    mapping (address => uint256) playerEgg;
    mapping (address => uint256) playerBalance;
    
     

     
     
     

    constructor() public {

        Lord memory _lord = Lord({
            level: 1,
            owner: msg.sender
        });
        
        lord[0] =  _lord;
        lord[1] =  _lord;
        lord[2] =  _lord;
        lord[3] =  _lord;
        lord[4] =  _lord;
        lord[5] =  _lord;
        lord[6] =  _lord;
        lord[7] =  _lord;
        
        leader = msg.sender;
        lastClaim = now;
        nextRoundStart = now.add(DOWNTIME);
    }
    
     
    
     
     
    
    function PotSplit(uint256 _msgValue, uint256 _id) private {
        
        snailPot = snailPot.add(_msgValue.mul(8).div(10));
        thronePot = thronePot.add(_msgValue.div(10));
        address _owner = lord[_id].owner;
        playerBalance[_owner] = playerBalance[_owner].add(_msgValue.div(10));
    }
    
     
     
    
    function WinRound(address _msgSender) private {
        gameActive = false;
		lastClaim = now;  
        nextRoundStart = now.add(DOWNTIME);
        playerEgg[_msgSender] = 0;
        playerBalance[_msgSender] = playerBalance[_msgSender].add(roundPot);
        
        emit WonRound(_msgSender, roundPot, round);
    }
    
     
    
     
     
     
    
    function BeginRound() public {
        require(now >= nextRoundStart, "downtime isn't over yet");
        require(gameActive == false, "game is already active");
        
        for(uint256 i = 0; i < 8; i++){
            colorSnail[i].level = 1;
            colorSnail[i].lastSnag = now;
            colorSnail[i].owner = lord[i].owner;
        }

		round = round.add(1);
        victoryEgg = round.mul(WIN_REQ);
        roundPot = snailPot.div(10);
        snailPot = snailPot.sub(roundPot);
        lastGrab = now;
        gameActive = true;
        
        emit StartedRound(round);
    }
    
    function GrabSnail(uint256 _id) public payable {
        require(gameActive == true, "game is paused");
        require(tx.origin == msg.sender, "no contracts allowed");
        
         
        uint256 _cost = ComputeSnailCost(_id);
        require(msg.value == _cost, "wrong amount of ETH");
        
         
        PotSplit(SNAIL_COST, _id);
        
         
        uint256 _prevReward = msg.value.sub(SNAIL_COST);
        address _prevOwner = colorSnail[_id].owner;
        playerBalance[_prevOwner] = playerBalance[_prevOwner].add(_prevReward);
        
         
        uint256 _reward = ComputeEgg(true, _id);
        colorSnail[_id].lastSnag = now;
        playerEgg[msg.sender] = playerEgg[msg.sender].add(_reward);
        
         
        colorSnail[_id].owner = msg.sender;
        colorSnail[_id].level = colorSnail[_id].level.add(1);
        
         
        lastGrab = now;
        
         
        if(playerEgg[msg.sender] >= victoryEgg){
            WinRound(msg.sender);
        } else {
            emit GrabbedSnail(msg.sender, _id, _cost, _reward, playerEgg[msg.sender]);
        }
        
         
        if(playerEgg[msg.sender] > playerEgg[leader]){
            leader = msg.sender;
        }
    }
    
    function ClaimLord(uint256 _id) public payable {
        require(gameActive == false, "lords can only flipped during downtime");
        require(tx.origin == msg.sender, "no contracts allowed");
        
         
        uint256 _cost = ComputeLordCost(_id);
        require(msg.value == _cost, "wrong amount of ETH");
        
        uint256 _potSplit = 0.04 ether;
         
        PotSplit(_potSplit, _id);
        
         
        uint256 _prevReward = msg.value.sub(_potSplit);
        address _prevOwner = lord[_id].owner;
        playerBalance[_prevOwner] = playerBalance[_prevOwner].add(_prevReward);

         
        uint256 _reward = ComputeLordBonus();
        playerEgg[msg.sender] = playerEgg[msg.sender].add(_reward);
        
         
        lord[_id].owner = msg.sender;
        lord[_id].level = lord[_id].level.add(1);
    
         
        lastClaim = now;
        
         
        if(playerEgg[msg.sender] > playerEgg[leader]){
            leader = msg.sender;
        }
        
        emit ClaimedLord(msg.sender, _id, _cost, _reward, playerEgg[msg.sender]);
    }
    
    function SnagEgg(uint256 _id) public payable {
        require(gameActive == true, "can't snag during downtime");
        require(msg.value == SNAG_COST, "wrong ETH amount (should be 0.002eth)");
		require(colorSnail[_id].owner == msg.sender, "own this snail to snag their eggs");
        
         
        PotSplit(SNAG_COST, _id);
        
         
        uint256 _reward = ComputeEgg(false, _id);
        colorSnail[_id].lastSnag = now;
        playerEgg[msg.sender] = playerEgg[msg.sender].add(_reward);
         
         
        if(playerEgg[msg.sender] >= victoryEgg){
            WinRound(msg.sender);
        } else {
            emit SnaggedEgg(msg.sender, _id, _reward, playerEgg[msg.sender]);
        }
        
         
        if(playerEgg[msg.sender] > playerEgg[leader]){
            leader = msg.sender;
        }
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
        snailPot = snailPot.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
     
    
     
     
     
    
    function ComputeSnailCost(uint256 _id) public view returns(uint256){
        uint256 _cost = (colorSnail[_id].level.add(1)).mul(SNAIL_COST);
        return _cost;
    }
    
     
     
     
    
    function ComputeLordCost(uint256 _id) public view returns(uint256){
        uint256 _cost = (lord[_id].level.add(1)).mul(LORD_COST);
        return _cost;
    }
    
     
     
     
     
    
    function ComputeEgg(bool _flip, uint256 _id) public view returns(uint256) {
        
         
        uint256 _bonus = 100;
        if(_flip == true){
            _bonus = _bonus.add((now.sub(lastGrab)).div(60));
        }
        
         
        uint256 _egg = now.sub(colorSnail[_id].lastSnag);
        _egg = _egg.mul(colorSnail[_id].level).mul(_bonus).div(100);
        return _egg;
    }
    
     
     
     
	 
    
    function ComputeLordBonus() public view returns(uint256){
        return (now.sub(lastClaim)).mul(8).mul(round);
    }
    
     
    
    function GetSnailLevel(uint256 _id) public view returns(uint256){
        return colorSnail[_id].level;
    }
    
    function GetSnailSnag(uint256 _id) public view returns(uint256){
        return colorSnail[_id].lastSnag;
    }
    
    function GetSnailOwner(uint256 _id) public view returns(address){
        return colorSnail[_id].owner;
    }
    
    function GetLordLevel(uint256 _id) public view returns(uint256){
        return lord[_id].level;
    }
    
    function GetLordOwner(uint256 _id) public view returns(address){
        return lord[_id].owner;
    }
    
    function GetPlayerBalance(address _player) public view returns(uint256){
        return playerBalance[_player];
    }
    
    function GetPlayerEgg(address _player) public view returns(uint256){
        return playerEgg[_player];
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