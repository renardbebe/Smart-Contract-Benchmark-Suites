 

pragma solidity ^0.4.24;

 

contract SnailFarm3 {
    using SafeMath for uint;
    
     
    
    event FundedTree (address indexed player, uint eth, uint acorns);
    event ClaimedShare (address indexed player, uint eth, uint acorns);
    event BecameMaster (address indexed player, uint indexed round);
    event WithdrewBalance (address indexed player, uint eth);
    event Hatched (address indexed player, uint eggs, uint snails, uint hatchery);
    event SoldEgg (address indexed player, uint eggs, uint eth);
    event BoughtEgg (address indexed player, uint eggs, uint eth, uint playereggs);
    event StartedSnailing (address indexed player, uint indexed round);
    event BecameQueen (address indexed player, uint indexed round, uint spiderreq, uint hatchery);
    event BecameDuke (address indexed player, uint indexed round, uint squirrelreq, uint playerreds);
    event BecamePrince (address indexed player, uint indexed round, uint tadpolereq);
    event WonRound (address indexed roundwinner, uint indexed round, uint eth);
    event BeganRound (uint indexed round);
    event JoinedRound (address indexed player, uint indexed round, uint playerreds);
    event GrabbedHarvest (address indexed player, uint indexed round, uint eth, uint playerreds);
    event UsedRed (address indexed player, uint eggs, uint snails, uint hatchery);
    event FoundSlug (address indexed player, uint indexed round, uint snails);
    event FoundLettuce (address indexed player, uint indexed round, uint lettucereq, uint playerreds);
    event FoundCarrot (address indexed player, uint indexed round);
    event PaidThrone (address indexed player, uint eth);
    event BoostedPot (address indexed player, uint eth);

     
    
    uint256 public constant FUND_TIMESTAMP       = 1544385600;  
    uint256 public constant START_TIMESTAMP      = 1544904000;  
    uint256 public constant TIME_TO_HATCH_1SNAIL = 86400;  
    uint256 public constant STARTING_SNAIL       = 300;
    uint256 public constant FROGKING_REQ         = 1000000;
    uint256 public constant ACORN_PRICE          = 0.001 ether;
    uint256 public constant ACORN_MULT           = 10;
    uint256 public constant STARTING_SNAIL_COST  = 0.004 ether;
    uint256 public constant HATCHING_COST        = 0.0008 ether;
    uint256 public constant SPIDER_BASE_REQ      = 80;
    uint256 public constant SQUIRREL_BASE_REQ    = 2;
    uint256 public constant TADPOLE_BASE_REQ     = 0.02 ether;
    uint256 public constant SLUG_MIN_REQ         = 100000;
    uint256 public constant LETTUCE_BASE_REQ     = 20;
    uint256 public constant CARROT_COST          = 0.02 ether;
    uint256 public constant HARVEST_COUNT        = 300;
    uint256 public constant HARVEST_DURATION     = 14400;  
    uint256 public constant HARVEST_DUR_ROOT     = 120;  
    uint256 public constant HARVEST_MIN_COST     = 0.002 ether;
    uint256 public constant SNAILMASTER_REQ      = 4096;
    uint256 public constant ROUND_DOWNTIME       = 43200;  
    address public constant SNAILTHRONE          = 0x261d650a521103428C6827a11fc0CBCe96D74DBc;

     
    
	 
    bool public gameActive             = false;
	
	 
    address public dev;
	
	 
    uint256 public round                = 0;
	
	 
	address public currentLeader;
	
	 
    address public currentSpiderOwner;
    address public currentTadpoleOwner;
	address public currentSquirrelOwner;
	address public currentSnailmaster;
	
	 
	uint256 public spiderReq;
    uint256 public tadpoleReq;
	uint256 public squirrelReq;
	
	 
	uint256 public lettuceReq;
	
	 
	uint256 public snailmasterReq       = SNAILMASTER_REQ;
	
	 
	uint256 public nextRoundStart;
	
	 
	uint256 public harvestStartCost;
	
	 
	uint256 public harvestStartTime;
	
	 
	uint256 public maxAcorn             = 0;
	
	 
	uint256 public divPerAcorn          = 0;
	
	 
    uint256 public marketEgg            = 0;
		
	 
    uint256 public snailPot             = 0;
    uint256 public roundPot             = 0;
    
	 
    uint256 public eggPot               = 0;
    
     
    uint256 public thronePot            = 0;

     
    
	mapping (address => bool) public hasStartingSnail;
	mapping (address => bool) public hasSlug;
	mapping (address => bool) public hasLettuce;
	mapping (address => uint256) public gotCarrot;
	mapping (address => uint256) public playerRound;
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public claimedEgg;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public redEgg;
    mapping (address => uint256) public playerBalance;
    mapping (address => uint256) public prodBoost;
    mapping (address => uint256) public acorn;
    mapping (address => uint256) public claimedShare;
    
     
    
     
     
     
    
    constructor() public {
        nextRoundStart = START_TIMESTAMP;
        
         
        dev = msg.sender;
        currentSnailmaster = msg.sender;
        currentTadpoleOwner = msg.sender;
        currentSquirrelOwner = msg.sender;
        currentSpiderOwner = msg.sender;
        currentLeader = msg.sender;
        prodBoost[msg.sender] = 4;  
    }
    
     
     
     
    
    function BeginRound() public {
        require(gameActive == false, "cannot start round while game is active");
        require(now > nextRoundStart, "round downtime isn't over");
        require(snailPot > 0, "cannot start round on empty pot");
        
        round = round.add(1);
		marketEgg = STARTING_SNAIL;
        roundPot = snailPot.div(10);
        spiderReq = SPIDER_BASE_REQ;
        tadpoleReq = TADPOLE_BASE_REQ;
        squirrelReq = SQUIRREL_BASE_REQ;
        lettuceReq = LETTUCE_BASE_REQ.mul(round);
        if(snailmasterReq > 2) {
            snailmasterReq = snailmasterReq.div(2);
        }
        harvestStartTime = now;
        harvestStartCost = roundPot;
        
        gameActive = true;
        
        emit BeganRound(round);
    }
    
     
     
     
    
    function FundTree() public payable {
        require(tx.origin == msg.sender, "no contracts allowed");
        require(now > FUND_TIMESTAMP, "funding hasn't started yet");
        
        uint256 _acornsBought = ComputeAcornBuy(msg.value);
        
         
        claimedShare[msg.sender] = claimedShare[msg.sender].add(_acornsBought.mul(divPerAcorn));
        
         
        maxAcorn = maxAcorn.add(_acornsBought);
        
         
        PotSplit(msg.value);
        
         
        acorn[msg.sender] = acorn[msg.sender].add(_acornsBought);
        
        emit FundedTree(msg.sender, msg.value, _acornsBought);
    }
    
     
     
     
    
    function ClaimAcornShare() public {
        
        uint256 _playerShare = ComputeMyShare();
        
        if(_playerShare > 0) {
            
             
            claimedShare[msg.sender] = claimedShare[msg.sender].add(_playerShare);
            
             
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_playerShare);
            
            emit ClaimedShare(msg.sender, _playerShare, acorn[msg.sender]);
        }
    }
    
     
     
     
     
	
    function BecomeSnailmaster() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= snailmasterReq, "not enough red eggs");
        
        redEgg[msg.sender] = redEgg[msg.sender].sub(snailmasterReq);
        snailmasterReq = snailmasterReq.mul(2);
        currentSnailmaster = msg.sender;
        
        emit BecameMaster(msg.sender, round);
    }
    
     
     
    
    function WithdrawBalance() public {
        require(playerBalance[msg.sender] > 0, "no ETH in player balance");
        
        uint _amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewBalance(msg.sender, _amount);
    }
    
     
	 
	 
    
    function PotSplit(uint256 _msgValue) private {
        
        snailPot = snailPot.add(_msgValue.div(2));
        eggPot = eggPot.add(_msgValue.div(4));
        thronePot = thronePot.add(_msgValue.div(10));
        
         
        divPerAcorn = divPerAcorn.add(_msgValue.div(10).div(maxAcorn));
        
         
        playerBalance[currentSnailmaster] = playerBalance[currentSnailmaster].add(_msgValue.div(20));
    }
    
     
     
    
    function JoinRound() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] != round, "player already in current round");
        require(hasStartingSnail[msg.sender] == true, "buy starting snails first");
        
        uint256 _bonusRed = hatcherySnail[msg.sender].div(100);
        hatcherySnail[msg.sender] = STARTING_SNAIL;
        redEgg[msg.sender] = redEgg[msg.sender].add(_bonusRed);
        
         
        if(gotCarrot[msg.sender] > 0) {
            gotCarrot[msg.sender] = gotCarrot[msg.sender].sub(1);
            
             
            if(gotCarrot[msg.sender] == 0) {
                prodBoost[msg.sender] = prodBoost[msg.sender].sub(1);
            }
        }
        
         
        if(hasLettuce[msg.sender]) {
            prodBoost[msg.sender] = prodBoost[msg.sender].sub(1);
            hasLettuce[msg.sender] = false;
        }
        
		 
		lastHatch[msg.sender] = now;
        playerRound[msg.sender] = round;
        
        emit JoinedRound(msg.sender, round, redEgg[msg.sender]);
    }
    
     
     
     
     
    
    function WinRound(address _msgSender) private {
        
        gameActive = false;
        nextRoundStart = now.add(ROUND_DOWNTIME);
        
        hatcherySnail[_msgSender] = 0;
        snailPot = snailPot.sub(roundPot);
        playerBalance[_msgSender] = playerBalance[_msgSender].add(roundPot);
        
        emit WonRound(_msgSender, round, roundPot);
    }
    
     
     
     
    
    function HatchEgg() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(msg.value == HATCHING_COST, "wrong ETH cost");
        
        PotSplit(msg.value);
        uint256 eggUsed = ComputeMyEgg(msg.sender);
        uint256 newSnail = eggUsed.mul(prodBoost[msg.sender]);
        claimedEgg[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(newSnail);
        
        if(hatcherySnail[msg.sender] > hatcherySnail[currentLeader]) {
            currentLeader = msg.sender;
        }
        
        if(hatcherySnail[msg.sender] >= FROGKING_REQ) {
            WinRound(msg.sender);
        }
        
        emit Hatched(msg.sender, eggUsed, newSnail, hatcherySnail[msg.sender]);
    }
    
     
     
	 
    
    function SellEgg() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
        uint256 eggSold = ComputeMyEgg(msg.sender);
        uint256 eggValue = ComputeSell(eggSold);
        claimedEgg[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEgg = marketEgg.add(eggSold);
        eggPot = eggPot.sub(eggValue);
        playerBalance[msg.sender] = playerBalance[msg.sender].add(eggValue);
        
        emit SoldEgg(msg.sender, eggSold, eggValue);
    }
    
     
     
	
	 
    
    function BuyEgg() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
        uint256 _eggBought = ComputeBuy(msg.value);
        
         
        uint256 _ethSpent = msg.value;
        
         
         
        uint256 _maxBuy = eggPot.div(4);
        if (msg.value > _maxBuy) {
            uint _excess = msg.value.sub(_maxBuy);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
            _ethSpent = _maxBuy;
        }  
        
        PotSplit(_ethSpent);
        marketEgg = marketEgg.sub(_eggBought);
        claimedEgg[msg.sender] = claimedEgg[msg.sender].add(_eggBought);
        
        emit BoughtEgg(msg.sender, _eggBought, _ethSpent, hatcherySnail[msg.sender]);
    }
    
     
     
    
    function BuyStartingSnail() public payable {
        require(gameActive, "game is paused");
        require(tx.origin == msg.sender, "no contracts allowed");
        require(hasStartingSnail[msg.sender] == false, "player already active");
        require(msg.value == STARTING_SNAIL_COST, "wrongETH cost");
        require(msg.sender != dev, "shoo shoo, developer");

        PotSplit(msg.value);
		hasStartingSnail[msg.sender] = true;
        lastHatch[msg.sender] = now;
		prodBoost[msg.sender] = 1;
		playerRound[msg.sender] = round;
        hatcherySnail[msg.sender] = STARTING_SNAIL;
        
        emit StartedSnailing(msg.sender, round);
    }
    
     
     
     
    
    function GrabRedHarvest() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        
         
        uint256 _harvestCost = ComputeHarvest();
        require(msg.value >= _harvestCost);
        
         
        if (msg.value > _harvestCost) {
            uint _excess = msg.value.sub(_harvestCost);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
        }
        
        PotSplit(_harvestCost);
        
         
        harvestStartCost = roundPot;
        harvestStartTime = now;
        
         
        redEgg[msg.sender] = redEgg[msg.sender].add(HARVEST_COUNT);
        
        emit GrabbedHarvest(msg.sender, round, msg.value, redEgg[msg.sender]);
    }
    
     
     
     
    
    function UseRedEgg(uint256 _redAmount) public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= _redAmount, "not enough red eggs");
        
        redEgg[msg.sender] = redEgg[msg.sender].sub(_redAmount);
        uint256 _newSnail = _redAmount.mul(prodBoost[msg.sender]);
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_newSnail);
        
        if(hatcherySnail[msg.sender] > hatcherySnail[currentLeader]) {
            currentLeader = msg.sender;
        }
        
        if(hatcherySnail[msg.sender] >= FROGKING_REQ) {
            WinRound(msg.sender);
        }
        
        emit UsedRed(msg.sender, _redAmount, _newSnail, hatcherySnail[msg.sender]);
    }
    
     
     
     
    
    function FindSlug() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hasSlug[msg.sender] == false, "already owns slug");
        require(hatcherySnail[msg.sender] >= SLUG_MIN_REQ, "not enough snails");
        
		uint256 _sacrifice = hatcherySnail[msg.sender];
        hatcherySnail[msg.sender] = 0;
        hasSlug[msg.sender] = true;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundSlug(msg.sender, round, _sacrifice);
    }
    
     
     
     
    
    function FindLettuce() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hasLettuce[msg.sender] == false, "already owns lettuce");
        require(redEgg[msg.sender] >= lettuceReq, "not enough red eggs");
        
        uint256 _eventLettuceReq = lettuceReq;
        redEgg[msg.sender] = redEgg[msg.sender].sub(lettuceReq);
        lettuceReq = lettuceReq.sub(LETTUCE_BASE_REQ);
        if(lettuceReq < LETTUCE_BASE_REQ) {
            lettuceReq = LETTUCE_BASE_REQ;
        }
        
        hasLettuce[msg.sender] = true;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundLettuce(msg.sender, round, _eventLettuceReq, redEgg[msg.sender]);
    }
    
     
     
    
    function FindCarrot() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(gotCarrot[msg.sender] == 0, "already owns carrot");
        require(msg.value == CARROT_COST);
        
        PotSplit(msg.value);
        gotCarrot[msg.sender] = 3;
        prodBoost[msg.sender] = prodBoost[msg.sender].add(1);

        emit FoundCarrot(msg.sender, round);
    }
    
     
     
    
    function PayThrone() public {
        uint256 _payThrone = thronePot;
        thronePot = 0;
        if (!SNAILTHRONE.call.value(_payThrone)()){
            revert();
        }
        
        emit PaidThrone(msg.sender, _payThrone);
    }
    
     
     
	 
    
    function BecomeSpiderQueen() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(hatcherySnail[msg.sender] >= spiderReq, "not enough snails");

         
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(spiderReq);
        spiderReq = spiderReq.mul(2);
        
         
        prodBoost[currentSpiderOwner] = prodBoost[currentSpiderOwner].sub(1);
        
         
        currentSpiderOwner = msg.sender;
        prodBoost[currentSpiderOwner] = prodBoost[currentSpiderOwner].add(1);
        
        emit BecameQueen(msg.sender, round, spiderReq, hatcherySnail[msg.sender]);
    }
	
	 
	 
     
    
    function BecomeSquirrelDuke() public {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(redEgg[msg.sender] >= squirrelReq, "not enough red eggs");
        
         
        redEgg[msg.sender] = redEgg[msg.sender].sub(squirrelReq);
        squirrelReq = squirrelReq.mul(2);
        
         
        prodBoost[currentSquirrelOwner] = prodBoost[currentSquirrelOwner].sub(1);
        
         
        currentSquirrelOwner = msg.sender;
        prodBoost[currentSquirrelOwner] = prodBoost[currentSquirrelOwner].add(1);
        
        emit BecameDuke(msg.sender, round, squirrelReq, redEgg[msg.sender]);
    }
    
     
     
	
     
    
    function BecomeTadpolePrince() public payable {
        require(gameActive, "game is paused");
        require(playerRound[msg.sender] == round, "join new round to play");
        require(msg.value >= tadpoleReq, "not enough ETH");
        
         
        if (msg.value > tadpoleReq) {
            uint _excess = msg.value.sub(tadpoleReq);
            playerBalance[msg.sender] = playerBalance[msg.sender].add(_excess);
        }  
        
         
         
        uint _extra = tadpoleReq.div(12); 
        PotSplit(_extra);
        
         
         
        uint _previousFlip = tadpoleReq.mul(11).div(12);
        playerBalance[currentTadpoleOwner] = playerBalance[currentTadpoleOwner].add(_previousFlip);
        
         
        tadpoleReq = (tadpoleReq.mul(6)).div(5); 
        
         
        prodBoost[currentTadpoleOwner] = prodBoost[currentTadpoleOwner].sub(1);
        
         
        currentTadpoleOwner = msg.sender;
        prodBoost[currentTadpoleOwner] = prodBoost[currentTadpoleOwner].add(1);
        
        emit BecamePrince(msg.sender, round, tadpoleReq);
    }
    
     
     
    
    function() public payable {
        snailPot = snailPot.add(msg.value);
        
        emit BoostedPot(msg.sender, msg.value);
    }
    
     
     
     
     
    
    function ComputeAcornCost() public view returns(uint256) {
        uint256 _acornCost;
        if(round != 0) {
            _acornCost = ACORN_PRICE.mul(ACORN_MULT).div(ACORN_MULT.add(round));
        } else {
            _acornCost = ACORN_PRICE.div(2);
        }
        return _acornCost;
    }
    
     
     
    
    function ComputeAcornBuy(uint256 _ether) public view returns(uint256) {
        uint256 _costPerAcorn = ComputeAcornCost();
        return _ether.div(_costPerAcorn);
    }
    
     
     
    
    function ComputeMyShare() public view returns(uint256) {
         
        uint256 _playerShare = divPerAcorn.mul(acorn[msg.sender]);
		
         
    	_playerShare = _playerShare.sub(claimedShare[msg.sender]);
        return _playerShare;
    }
    
     
     
     
    
    function ComputeHarvest() public view returns(uint256) {

         
        uint256 _timeLapsed = now.sub(harvestStartTime);
        
         
        if(_timeLapsed > HARVEST_DURATION) {
            _timeLapsed = HARVEST_DURATION;
        }
        
         
        _timeLapsed = ComputeSquare(_timeLapsed);
        
         
        uint256 _priceChange = harvestStartCost.sub(HARVEST_MIN_COST);
        
         
        uint256 _harvestFactor = _priceChange.mul(_timeLapsed).div(HARVEST_DUR_ROOT);
        
         
        return harvestStartCost.sub(_harvestFactor);
    }
    
     
     
    
    function ComputeSquare(uint256 base) public pure returns (uint256 squareRoot) {
        uint256 z = (base + 1) / 2;
        squareRoot = base;
        while (z < squareRoot) {
            squareRoot = z;
            z = (base / z + z) / 2;
        }
    }
    
     
	 
	 
	 
    
    function ComputeSell(uint256 eggspent) public view returns(uint256) {
        uint256 _eggPool = eggspent.add(marketEgg);
        uint256 _eggFactor = eggspent.mul(eggPot).div(_eggPool);
        return _eggFactor.div(2);
    }
    
     
	 
     
     
    
    function ComputeBuy(uint256 ethspent) public view returns(uint256) {
        uint256 _ethPool = ethspent.add(eggPot);
        uint256 _ethFactor = ethspent.mul(marketEgg).div(_ethPool);
        uint256 _maxBuy = marketEgg.div(5);
        if(_ethFactor > _maxBuy) {
            _ethFactor = _maxBuy;
        }
        return _ethFactor;
    }
    
     
     
	 
    
    function ComputeMyEgg(address adr) public view returns(uint256) {
        uint256 _eggs = now.sub(lastHatch[adr]);
        _eggs = _eggs.mul(hatcherySnail[adr]).div(TIME_TO_HATCH_1SNAIL);
        if (_eggs > hatcherySnail[adr]) {
            _eggs = hatcherySnail[adr];
        }
        _eggs = _eggs.add(claimedEgg[adr]);
        return _eggs;
    }

     
    
    function GetSnail(address adr) public view returns(uint256) {
        return hatcherySnail[adr];
    }
    
    function GetAcorn(address adr) public view returns(uint256) {
        return acorn[adr];
    }
	
	function GetProd(address adr) public view returns(uint256) {
		return prodBoost[adr];
	}
    
    function GetMyEgg() public view returns(uint256) {
        return ComputeMyEgg(msg.sender);
    }
	
	function GetMyBalance() public view returns(uint256) {
	    return playerBalance[msg.sender];
	}
	
	function GetRed(address adr) public view returns(uint256) {
	    return redEgg[adr];
	}
	
	function GetLettuce(address adr) public view returns(bool) {
	    return hasLettuce[adr];
	}
	
	function GetCarrot(address adr) public view returns(uint256) {
	    return gotCarrot[adr];
	}
	
	function GetSlug(address adr) public view returns(bool) {
	    return hasSlug[adr];
	}
	
	function GetMyRound() public view returns(uint256) {
	    return playerRound[msg.sender];
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