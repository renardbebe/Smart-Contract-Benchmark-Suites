 

pragma solidity ^0.4.18;

 

contract SmartCityToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {}
    
    function setTokenStart(uint256 _newStartTime) public {}

    function burn() public {}
}

contract SmartCityCrowdsale {
    using SafeMath for uint256;

     

    struct Account {
        uint256 accounted;    
        uint256 received;     
    }

     
    mapping (address => Account) public buyins;

     
    mapping(address => uint256) public purchases;

     
    uint256 public totalReceived = 0;

     
    uint256 public totalAccounted = 0;

     
    uint256 public tokensPurchased = 0;

     
    uint256 public totalFinalised = 0;
    
     
    uint256 public firstPhaseEndTime;
    
     
    uint256 public secondPhaseStartTime;
    
     
    uint256 public endTime;

     
    uint256 public auctionEndPrice;
    
     
    uint256 public fixedPrice;

     
    uint256 public currentBonus = 15;

     
    uint256 public auctionSuccessBonus = 0;
    
     
    bool public paused = false;
    
     
    bool public campaignEnded = false;

     

     
    SmartCityToken public tokenContract;

     
    address public owner;

     
    address public wallet;

     
    uint256 public startTime;

     
     
    uint256 public tokenCapPhaseOne;
    
     
    uint256 public tokenCapPhaseTwo;


     

     
    uint256 constant public FUNDING_GOAL = 109573 ether;
    
     
    uint256 constant public TOKEN_MIN_PRICE_THRESHOLD = 100000000;  
    
     
    uint256 constant public FIRST_PHASE_MAX_SPAN = 21 days;
    
     
    uint256 constant public SECOND_PHASE_MAX_SPAN = 33 days;
    
     
    uint256 constant public DUST_LIMIT = 5 finney;

     
    uint256 constant public BONUS_DURATION = 15;
    
     
    uint256 constant public SUCCESS_BONUS = 15;
    
     
     
    uint256 constant public SECOND_PHASE_PRICE_FACTOR = 20;

     
    uint256 constant public FACTOR = 1 finney;

     
    uint256 constant public DIVISOR = 100000;

     

     
    event Buyin(address indexed receiver, uint256 accounted, uint256 received, uint256 price);

     
    event PhaseOneEnded(uint256 price);
    
     
    event PhaseTwoStared(uint256 fixedPrice);

     
    event Invested(address indexed receiver, uint256 received, uint256 tokens);

     
    event Ended(bool goalReached);

     
    event Finalised(address indexed receiver, uint256 tokens);

     
    event Retired();
    
     
    
     
    modifier when_ended { require (now >= endTime); _; }

     
    modifier when_not_halted { require (!paused); _; }

     
    modifier only_investors(address _receiver) { require (buyins[_receiver].accounted != 0 || purchases[_receiver] != 0); _; }

     
    modifier only_owner { require (msg.sender == owner); _; }
    
     
    modifier when_active { require (!campaignEnded); _;}

     
    modifier only_in_phase_1 { require (now >= startTime && now < firstPhaseEndTime); _; }
    
     
    modifier after_phase_1 { require (now >= firstPhaseEndTime); _; }

     
    modifier only_in_phase_2 { require (now >= secondPhaseStartTime && now < endTime); _; }

     
    modifier reject_dust { require ( msg.value >= DUST_LIMIT ); _; }

     

    function SmartCityCrowdsale(
        address _tokenAddress,
        address _owner,
        address _walletAddress,
        uint256 _startTime,
        uint256 _tokenCapPhaseOne,
        uint256 _tokenCapPhaseTwo
    )
        public
    {
        tokenContract = SmartCityToken(_tokenAddress);
        wallet = _walletAddress;
        owner = _owner;
        startTime = _startTime;
        firstPhaseEndTime = startTime.add(FIRST_PHASE_MAX_SPAN);
        secondPhaseStartTime = 253402300799;  
        endTime = secondPhaseStartTime.add(SECOND_PHASE_MAX_SPAN);
        tokenCapPhaseOne = _tokenCapPhaseOne;
        tokenCapPhaseTwo = _tokenCapPhaseTwo;
    }

     
     
     
    function()
        public
        payable
        when_not_halted
        when_active
    {
        if (now >= startTime && now < firstPhaseEndTime) {  
            _buyin(msg.sender, msg.value);
        }
        else {
            _invest(msg.sender, msg.value);
        }
    }

     

     
    function buyin()
        public
        payable
        when_not_halted
        when_active
        only_in_phase_1
        reject_dust
    {
        _buyin(msg.sender, msg.value);
    }
    
     
    function buyinAs(address _receiver)
        public
        payable
        when_not_halted
        when_active
        only_in_phase_1
        reject_dust
    {
        require (_receiver != address(0));
        _buyin(_receiver, msg.value);
    }
    
     
    function _buyin(address _receiver, uint256 _value)
        internal
    {
        if (currentBonus > 0) {
            uint256 daysSinceStart = (now.sub(startTime)).div(86400);  

            if (daysSinceStart < BONUS_DURATION &&
                BONUS_DURATION.sub(daysSinceStart) != currentBonus) {
                currentBonus = BONUS_DURATION.sub(daysSinceStart);
            }
            if (daysSinceStart >= BONUS_DURATION) {
                currentBonus = 0;
            }
        }

        uint256 accounted;
        bool refund;
        uint256 price;

        (accounted, refund, price) = theDeal(_value);

         
        require (!refund);

         
        buyins[_receiver].accounted = buyins[_receiver].accounted.add(accounted);
        buyins[_receiver].received = buyins[_receiver].received.add(_value);
        totalAccounted = totalAccounted.add(accounted);
        totalReceived = totalReceived.add(_value);
        firstPhaseEndTime = calculateEndTime();

        Buyin(_receiver, accounted, _value, price);

         
        wallet.transfer(_value);
    }

     
    function calculateEndTime()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256)
    {
        uint256 res = (FACTOR.mul(240000).div(DIVISOR.mul(totalAccounted.div(tokenCapPhaseOne)).add(FACTOR.mul(4).div(100)))).add(startTime).sub(4848);

        if (res >= firstPhaseEndTime) {
            return firstPhaseEndTime;
        }
        else {
            return res;
        }
    }
    

     
    function currentPrice()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 weiPerIndivisibleTokenPart)
    {
        return ((FACTOR.mul(240000).div(now.sub(startTime).add(4848))).sub(FACTOR.mul(4).div(100))).div(DIVISOR);
    }

     
    function tokensAvailable()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 tokens)
    {
        uint256 _currentCap = totalAccounted.div(currentPrice());
        if (_currentCap >= tokenCapPhaseOne) {
            return 0;
        }
        return tokenCapPhaseOne.sub(_currentCap);
    }

     
    function maxPurchase()
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 spend)
    {
        return tokenCapPhaseOne.mul(currentPrice()).sub(totalAccounted);
    }

     
     
    function theDeal(uint256 _value)
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 accounted, bool refund, uint256 price)
    {
        uint256 _bonus = auctionBonus(_value);

        price = currentPrice();
        accounted = _value.add(_bonus);

        uint256 available = tokensAvailable();
        uint256 tokens = accounted.div(price);
        refund = (tokens > available);
    }

     
    function auctionBonus(uint256 _value)
        public
        constant
        when_active
        only_in_phase_1
        returns (uint256 extra)
    {
        return _value.mul(currentBonus).div(100);
    }

     
    
     
     
    function finaliseFirstPhase()
        public
        when_not_halted
        when_active
        after_phase_1
        returns(uint256)
    {
        if (auctionEndPrice == 0) {
            auctionEndPrice = totalAccounted.div(tokenCapPhaseOne);
            PhaseOneEnded(auctionEndPrice);

             
            if (totalAccounted >= FUNDING_GOAL ) {
                 
                auctionSuccessBonus = SUCCESS_BONUS;
                endTime = firstPhaseEndTime;
                campaignEnded = true;
                
                tokenContract.setTokenStart(endTime);

                Ended(true);
            }
            
            else if (auctionEndPrice >= TOKEN_MIN_PRICE_THRESHOLD) {
                 
                fixedPrice = auctionEndPrice.add(auctionEndPrice.mul(SECOND_PHASE_PRICE_FACTOR).div(100));
                secondPhaseStartTime = now;
                endTime = secondPhaseStartTime.add(SECOND_PHASE_MAX_SPAN);

                PhaseTwoStared(fixedPrice);
            }
            else if (auctionEndPrice < TOKEN_MIN_PRICE_THRESHOLD && auctionEndPrice > 0){
                 
                endTime = firstPhaseEndTime;
                campaignEnded = true;

                tokenContract.setTokenStart(endTime);

                Ended(false);
            }
            else {  
                auctionEndPrice = 1 wei;
                endTime = firstPhaseEndTime;
                campaignEnded = true;

                tokenContract.setTokenStart(endTime);

                Ended(false);

                Retired();
            }
        }
        
        return auctionEndPrice;
    }

     

     
    function invest()
        public
        payable
        when_not_halted
        when_active
        only_in_phase_2
        reject_dust
    {
        _invest(msg.sender, msg.value);
    }
    
     
    function investAs(address _receiver)
        public
        payable
        when_not_halted
        when_active
        only_in_phase_2
        reject_dust
    {
        require (_receiver != address(0));
        _invest(_receiver, msg.value);
    }
    
     
    function _invest(address _receiver, uint256 _value)
        internal
    {
        uint256 tokensCnt = getTokens(_receiver, _value); 

        require(tokensCnt > 0);
        require(tokensPurchased.add(tokensCnt) <= tokenCapPhaseTwo);  
        require(_value <= maxTokenPurchase(_receiver));  

        purchases[_receiver] = purchases[_receiver].add(_value);
        totalReceived = totalReceived.add(_value);
        totalAccounted = totalAccounted.add(_value);
        tokensPurchased = tokensPurchased.add(tokensCnt);

        Invested(_receiver, _value, tokensCnt);
        
         
        wallet.transfer(_value);

         
        if (totalAccounted >= FUNDING_GOAL) {
            endTime = now;
            campaignEnded = true;
            
            tokenContract.setTokenStart(endTime);
            
            Ended(true);
        }
    }
    
     
    function getTokens(address _receiver, uint256 _value)
        public
        constant
        when_active
        only_in_phase_2
        returns(uint256 tokensCnt)
    {
         
        if (buyins[_receiver].received > 0) {
            tokensCnt = _value.div(auctionEndPrice);
        }
        else {
            tokensCnt = _value.div(fixedPrice);
        }

    }
    
     
    function maxTokenPurchase(address _receiver)
        public
        constant
        when_active
        only_in_phase_2
        returns(uint256 spend)
    {
        uint256 availableTokens = tokenCapPhaseTwo.sub(tokensPurchased);
        uint256 fundingGoalOffset = FUNDING_GOAL.sub(totalReceived);
        uint256 maxInvestment;
        
        if (buyins[_receiver].received > 0) {
            maxInvestment = availableTokens.mul(auctionEndPrice);
        }
        else {
            maxInvestment = availableTokens.mul(fixedPrice);
        }

        if (maxInvestment > fundingGoalOffset) {
            return fundingGoalOffset;
        }
        else {
            return maxInvestment;
        }
    }

     
    
     
    function finalise()
        public
        when_not_halted
        when_ended
        only_investors(msg.sender)
    {
        finaliseAs(msg.sender);
    }

     
    function finaliseAs(address _receiver)
        public
        when_not_halted
        when_ended
        only_investors(_receiver)
    {
        bool auctionParticipant;
        uint256 total;
        uint256 tokens;
        uint256 bonus;
        uint256 totalFixed;
        uint256 tokensFixed;

         
        if (!campaignEnded) {
            campaignEnded = true;
            
            tokenContract.setTokenStart(endTime);
            
            Ended(false);
        }

        if (buyins[_receiver].accounted != 0) {
            auctionParticipant = true;

            total = buyins[_receiver].accounted;
            tokens = total.div(auctionEndPrice);
            
            if (auctionSuccessBonus > 0) {
                bonus = tokens.mul(auctionSuccessBonus).div(100);
            }
            totalFinalised = totalFinalised.add(total);
            delete buyins[_receiver];
        }
        
        if (purchases[_receiver] != 0) {
            totalFixed = purchases[_receiver];
            
            if (auctionParticipant) {
                tokensFixed = totalFixed.div(auctionEndPrice);
            }
            else {
                tokensFixed = totalFixed.div(fixedPrice);
            }
            totalFinalised = totalFinalised.add(totalFixed);
            delete purchases[_receiver];
        }

        tokens = tokens.add(bonus).add(tokensFixed);

        require (tokenContract.transferFrom(owner, _receiver, tokens));

        Finalised(_receiver, tokens);

        if (totalFinalised == totalAccounted) {
            tokenContract.burn();  
            Retired();
        }
    }

     

     
    function setPaused(bool _paused) public only_owner { paused = _paused; }

     
    function drain() public only_owner { wallet.transfer(this.balance); }
    
     
    function isActive() public constant returns (bool) { return now >= startTime && now < endTime; }

     
    function allFinalised() public constant returns (bool) { return now >= endTime && totalAccounted == totalFinalised; }
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

     