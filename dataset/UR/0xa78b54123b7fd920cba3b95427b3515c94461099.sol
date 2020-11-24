 

pragma solidity ^0.4.24;

 

contract SnailFarm2 {
    using SafeMath for uint;
    
     
    
    event SoldAcorn (address indexed seller, uint acorns, uint eth);
    event BoughtAcorn (address indexed buyer, uint acorns, uint eth);
    event BecameMaster (address indexed newmaster, uint indexed round, uint reward, uint pot);
    event WithdrewEarnings (address indexed player, uint eth);
    event Hatched (address indexed player, uint eggs, uint snails);
    event SoldEgg (address indexed seller, uint eggs, uint eth);
    event BoughtEgg (address indexed buyer, uint eggs, uint eth);
    event StartedSnailing (address indexed player, uint indexed round);
    event BecameQueen (address indexed newqueen, uint indexed round, uint newreq);
    event BecameDuke (address indexed newduke, uint indexed round, uint newreq);
    event BecamePrince (address indexed newprince, uint indexed round, uint newreq);

     
    
    uint256 public TIME_TO_HATCH_1SNAIL = 86400;  
    uint256 public STARTING_SNAIL       = 200;
    uint256 public SNAILMASTER_INCREASE = 100000;
    uint256 public STARTING_SNAIL_COST  = 0.004 ether;
    uint256 public HATCHING_COST        = 0.0008 ether;
    uint256 public SPIDER_BASE_REQ      = 80;
    uint256 public SPIDER_BOOST         = 1;
    uint256 public TADPOLE_BASE_REQ     = 0.02 ether;
    uint256 public TADPOLE_BOOST        = 1;
	uint256 public SQUIRREL_BASE_REQ    = 1;
    uint256 public SQUIRREL_BOOST       = 1;

	
     
    
	 
    bool public gameStarted             = false;
	
	 
    address public gameOwner;
	
	 
    uint256 public round                = 0;
	
	 
    address public currentSpiderOwner;
    address public currentTadpoleOwner;
	address public currentSquirrelOwner;
	
	 
	uint256 public spiderReq;
    uint256 public tadpoleReq;
	uint256 public squirrelReq;
	
	 
    uint256 public snailmasterReq       = SNAILMASTER_INCREASE;
    
     
	uint256 public startingSnailAmount  = STARTING_SNAIL;
	
	 
    uint256 public marketEggs;
	
	 
	uint256 public totalAcorns;
		
	 
    uint256 public snailPot;
	uint256 public previousSnailPot;
    uint256 public treePot;

    	
     
    
	mapping (address => bool) public hasStartingSnails;
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public playerAcorns;
    mapping (address => uint256) public playerEarnings;
    mapping (address => uint256) public playerProdBoost;
    
	
     
    
     
     
     
     
    
    constructor() public {
        gameOwner = msg.sender;
        
        currentTadpoleOwner = gameOwner;
        currentSquirrelOwner = gameOwner;
        currentSpiderOwner = gameOwner;
        hasStartingSnails[gameOwner] = true;  
        playerProdBoost[gameOwner] = 4;  
    }
    
     
     
	
	 
	 
	 
	 
	 
	 
	 
    
    function SeedMarket(uint256 _eggs, uint256 _acorns) public payable {
        require(msg.value > 0);
        require(round == 0);
        require(msg.sender == gameOwner);
        
        marketEggs = _eggs.mul(TIME_TO_HATCH_1SNAIL);  
        snailPot = msg.value.div(10);  
        treePot = msg.value.sub(snailPot);  
		previousSnailPot = snailPot.mul(10);  
        totalAcorns = _acorns; 
        playerAcorns[msg.sender] = _acorns.mul(99).div(100); 
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
		squirrelReq = SQUIRREL_BASE_REQ;
        round = 1;
        gameStarted = true;
    }
    
     
     
    
    function SellAcorns(uint256 _acorns) public {
        require(playerAcorns[msg.sender] > 0);
        
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(_acorns);
        uint256 _acornEth = ComputeAcornPrice().mul(_acorns);
        totalAcorns = totalAcorns.sub(_acorns);
        treePot = treePot.sub(_acornEth);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_acornEth);
        
        emit SoldAcorn(msg.sender, _acorns, _acornEth);
    }
    
     
     
	
	 
	 
    
    function BuyAcorns() public payable {
        require(msg.value > 0);
        require(tx.origin == msg.sender);
        require(gameStarted);
        
		if (snailPot < previousSnailPot) {
			uint256 _acornBought = ((msg.value.div(ComputeAcornPrice())).mul(3)).div(4);
			AcornPotSplit(msg.value);
		} else {
			_acornBought = (msg.value.div(ComputeAcornPrice())).div(2);
			PotSplit(msg.value);
		}
        totalAcorns = totalAcorns.add(_acornBought);
        playerAcorns[msg.sender] = playerAcorns[msg.sender].add(_acornBought);
        
        emit BoughtAcorn(msg.sender, _acornBought, msg.value);
    }
    
     
     
	
     
     
    
    function BecomeSnailmaster() public {
        require(gameStarted);
        require(hatcherySnail[msg.sender] >= snailmasterReq);
        
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].div(10);
        
        uint256 _snailReqIncrease = round.mul(SNAILMASTER_INCREASE);
        snailmasterReq = snailmasterReq.add(_snailReqIncrease);
        uint256 _startingSnailIncrease = round.mul(STARTING_SNAIL);
        startingSnailAmount = startingSnailAmount.add(_startingSnailIncrease);
        
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
        squirrelReq = SQUIRREL_BASE_REQ;
        
        previousSnailPot = snailPot;
        uint256 _rewardSnailmaster = snailPot.div(5);
        snailPot = snailPot.sub(_rewardSnailmaster);
        round++;
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_rewardSnailmaster);
        
        emit BecameMaster(msg.sender, round, _rewardSnailmaster, snailPot);
    }
    
     
     
    
    function WithdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        
        uint _amount = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewEarnings(msg.sender, _amount);
    }
    
     
	 
	
     
    
    function PotSplit(uint256 _msgValue) private {
        uint256 _potBoost = _msgValue.div(2);
        snailPot = snailPot.add(_potBoost);
        treePot = treePot.add(_potBoost);
    }
	
	 
     
    
	 
	 
	
    function AcornPotSplit(uint256 _msgValue) private {
        uint256 _snailBoost = _msgValue.div(4);
		uint256 _treeBoost = _msgValue.sub(_snailBoost);
        snailPot = snailPot.add(_snailBoost);
        treePot = treePot.add(_treeBoost);
    }
    
     
     
	
     
    
    function HatchEggs() public payable {
        require(gameStarted);
        require(msg.value == HATCHING_COST);		
        
        PotSplit(msg.value);
        uint256 eggsUsed = ComputeMyEggs();
        uint256 newSnail = (eggsUsed.div(TIME_TO_HATCH_1SNAIL)).mul(playerProdBoost[msg.sender]);
        claimedEggs[msg.sender]= 0;
        lastHatch[msg.sender]= now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(newSnail);
        
        emit Hatched(msg.sender, eggsUsed, newSnail);
    }
    
     
     
	
     
	 
    
    function SellEggs() public {
        require(gameStarted);
        
        uint256 eggsSold = ComputeMyEggs();
        uint256 eggValue = ComputeSell(eggsSold);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = marketEggs.add(eggsSold);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(eggValue);
        
        emit SoldEgg(msg.sender, eggsSold, eggValue);
    }
    
     
     
	
	 
    
    function BuyEggs() public payable {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(msg.sender != gameOwner);
        
        uint256 eggsBought = ComputeBuy(msg.value);
        PotSplit(msg.value);
        marketEggs = marketEggs.sub(eggsBought);
        claimedEggs[msg.sender] = claimedEggs[msg.sender].add(eggsBought);
        
        emit BoughtEgg(msg.sender, eggsBought, msg.value);
    }
    
     
     
    
    function BuyStartingSnails() public payable {
        require(gameStarted);
        require(tx.origin == msg.sender);
        require(hasStartingSnails[msg.sender] == false);
        require(msg.value == STARTING_SNAIL_COST); 

        PotSplit(msg.value);
		hasStartingSnails[msg.sender] = true;
        lastHatch[msg.sender] = now;
		playerProdBoost[msg.sender] = 1;
        hatcherySnail[msg.sender] = startingSnailAmount;
        
        emit StartedSnailing(msg.sender, round);
    }
    
     
     
	
	 
    
    function BecomeSpiderQueen() public {
        require(gameStarted);
        require(hatcherySnail[msg.sender] >= spiderReq);

         
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(spiderReq);
        spiderReq = spiderReq.mul(2);
        
         
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].sub(SPIDER_BOOST);
        
         
        currentSpiderOwner = msg.sender;
        playerProdBoost[currentSpiderOwner] = playerProdBoost[currentSpiderOwner].add(SPIDER_BOOST);
        
        emit BecameQueen(msg.sender, round, spiderReq);
    }
	
	 
	 

     
    
    function BecomeSquirrelDuke() public {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(playerAcorns[msg.sender] >= squirrelReq);
        
         
        playerAcorns[msg.sender] = playerAcorns[msg.sender].sub(squirrelReq);
		totalAcorns = totalAcorns.sub(squirrelReq);
        squirrelReq = squirrelReq.mul(2);
        
         
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].sub(SQUIRREL_BOOST);
        
         
        currentSquirrelOwner = msg.sender;
        playerProdBoost[currentSquirrelOwner] = playerProdBoost[currentSquirrelOwner].add(SQUIRREL_BOOST);
        
        emit BecameDuke(msg.sender, round, squirrelReq);
    }
    
     
     
	
     
    
    function BecomeTadpolePrince() public payable {
        require(gameStarted);
        require(hasStartingSnails[msg.sender] == true);
        require(msg.value >= tadpoleReq);
        
         
        if (msg.value > tadpoleReq) {
            uint _excess = msg.value.sub(tadpoleReq);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_excess);
        }  
        
         
         
        uint _extra = tadpoleReq.div(12); 
        PotSplit(_extra);
        
         
         
        uint _previousFlip = tadpoleReq.mul(11).div(12);
        playerEarnings[currentTadpoleOwner] = playerEarnings[currentTadpoleOwner].add(_previousFlip);
        
         
        tadpoleReq = (tadpoleReq.mul(6)).div(5); 
        
         
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].sub(TADPOLE_BOOST);
        
         
        currentTadpoleOwner = msg.sender;
        playerProdBoost[currentTadpoleOwner] = playerProdBoost[currentTadpoleOwner].add(TADPOLE_BOOST);
        
        emit BecamePrince(msg.sender, round, tadpoleReq);
    }
    
     
	 
	
     
    
    function ComputeAcornPrice() public view returns(uint256) {
        return treePot.div(totalAcorns);
    }
    
     
	 
    
	 
	 
    
    function ComputeSell(uint256 eggspent) public view returns(uint256) {
        uint256 _eggPool = eggspent.add(marketEggs);
        uint256 _eggFactor = eggspent.mul(snailPot).div(_eggPool);
        return _eggFactor.div(2);
    }
    
     
	 
	
     
    
    function ComputeBuy(uint256 ethspent) public view returns(uint256) {
        uint256 _ethPool = ethspent.add(snailPot);
        uint256 _ethFactor = ethspent.mul(marketEggs).div(_ethPool);
        return _ethFactor;
    }
    
     
     
    
    function ComputeMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender].add(ComputeEggsSinceLastHatch(msg.sender));
    }
    
     
     
    
    function ComputeEggsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_HATCH_1SNAIL , now.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcherySnail[adr]);
    }
    
     
	 
	 
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

     
    
    function GetMySnail() public view returns(uint256) {
        return hatcherySnail[msg.sender];
    }
	
	function GetMyProd() public view returns(uint256) {
		return playerProdBoost[msg.sender];
	}
    
    function GetMyEgg() public view returns(uint256) {
        return ComputeMyEggs().div(TIME_TO_HATCH_1SNAIL);
    }
    
    function GetMyAcorn() public view returns(uint256) {
        return playerAcorns[msg.sender];
    }
	
	function GetMyEarning() public view returns(uint256) {
	    return playerEarnings[msg.sender];
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