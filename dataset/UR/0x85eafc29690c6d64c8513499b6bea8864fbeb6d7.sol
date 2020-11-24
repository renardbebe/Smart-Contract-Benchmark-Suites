 

pragma solidity ^0.4.23;

 

 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  address public owner;

   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public soldTokens;

   
  uint256 public processedTokens;

   
  uint256 public unSoldTokens;

   
  uint256 public lockedTokens;

   
  uint256 public allocatedTokens;

   
  uint256 public distributedTokens;

   
  bool public paused = false;

   
  uint256 public minPurchase = 53 finney;

   
  uint256 public currentRound;

   
  uint256 public constant maxTokensRaised = 1000000000E4;

   
  uint256 public startTime = 1527703200;

   
  uint256 public currentRoundStart = startTime;

   
  uint256 public endTime = 1532386740;

   
  uint256 public lockedTill = 1542931200;

   
  uint256 public approvedTill = 1535328000;

   
  mapping(address => uint256) public crowdsaleBalances;

   
  mapping(address => uint256) public tokensBought;

   
  mapping(address => uint256) public bonusBalances;

   
  mapping(address => uint256) public lockedBalances;

   
  mapping(address => uint256) public allocatedBalances;

   
  mapping(address => bool) public approved;

   
  mapping(address => uint256) public distributedBalances;

   
  mapping (uint256 => uint256) public bonusLevels;

   
  mapping (uint256 => uint256) public rateLevels;

   
  mapping (uint256 => uint256) public capLevels;

   
  address[] public allocatedAddresses;              


   

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event Pause();
  event Unpause();

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  function setNewBonusLevel (uint256 _bonusIndex, uint256 _bonusValue) onlyOwner external {
    bonusLevels[_bonusIndex] = _bonusValue;
  }

  function setNewRateLevel (uint256 _rateIndex, uint256 _rateValue) onlyOwner external {
    rateLevels[_rateIndex] = _rateValue;
  }

  function setMinPurchase (uint256 _minPurchase) onlyOwner external {
    minPurchase = _minPurchase;
  }

    
  function setNewRatesCustom (uint256 _r1, uint256 _r2, uint256 _r3, uint256 _r4, uint256 _r5, uint256 _r6) onlyOwner external {
    require(_r1 > 0 && _r2 > 0 && _r3 > 0 && _r4 > 0 && _r5 > 0 && _r6 > 0);
    rateLevels[1] = _r1;
    rateLevels[2] = _r2;
    rateLevels[3] = _r3;
    rateLevels[4] = _r4;
    rateLevels[5] = _r5;
    rateLevels[6] = _r6;
  }

    
  function setNewRatesBase (uint256 _r1) onlyOwner external {
    require(_r1 > 0);
    rateLevels[1] = _r1;
    rateLevels[2] = _r1.div(2);
    rateLevels[3] = _r1.div(3);
    rateLevels[4] = _r1.div(4);
    rateLevels[5] = _r1.div(5);
    rateLevels[6] = _r1.div(5);
  }

   

  constructor(uint256 _rate, address _wallet, address _owner, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    wallet = _wallet;
    token = _token;
    owner = _owner;

    soldTokens = 0;
    unSoldTokens = 0;
    processedTokens = 0;

    lockedTokens = 0;
    distributedTokens = 0;

    currentRound = 1;

     
    bonusLevels[1] =  5;
    bonusLevels[2] = 10;
    bonusLevels[3] = 15;
    bonusLevels[4] = 20;
    bonusLevels[5] = 50;
    bonusLevels[6] = 0;

     
    rateLevels[1] = _rate;
    rateLevels[2] = _rate.div(2);
    rateLevels[3] = _rate.div(3);
    rateLevels[4] = _rate.div(4);
    rateLevels[5] = _rate.div(5);
    rateLevels[6] = _rate.div(5);

     
    capLevels[1] = 150000000E4;
    capLevels[2] = 210000000E4;
    capLevels[3] = 255000000E4;
    capLevels[4] = 285000000E4;
    capLevels[5] = 300000000E4;
    capLevels[6] = maxTokensRaised;

  }

   
   
   

  function () external payable whenNotPaused {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused {

    uint256 amountPaid = msg.value;
    _preValidatePurchase(_beneficiary, amountPaid);

    uint256 tokens = 0;
    uint256 bonusTokens = 0;
    uint256 fullTokens = 0;

     
    if(processedTokens < capLevels[1]) {

        tokens = _getTokensAmount(amountPaid, 1);
        bonusTokens = _getBonusAmount(tokens, 1);
        fullTokens = tokens.add(bonusTokens);

         
        if(processedTokens.add(fullTokens) > capLevels[1]) {
            tokens = _calculateExcessTokens(amountPaid, 1);
            bonusTokens = _calculateExcessBonus(tokens, 1);
            setCurrentRound(2);
        }

     
    } else if(processedTokens >= capLevels[1] && processedTokens < capLevels[2]) {
        tokens = _getTokensAmount(amountPaid, 2);
        bonusTokens = _getBonusAmount(tokens, 2);
        fullTokens = tokens.add(bonusTokens);

         
        if(processedTokens.add(fullTokens) > capLevels[2]) {
            tokens = _calculateExcessTokens(amountPaid, 2);
            bonusTokens = _calculateExcessBonus(tokens, 2);
            setCurrentRound(3);
        }

     
    } else if(processedTokens >= capLevels[2] && processedTokens < capLevels[3]) {
         tokens = _getTokensAmount(amountPaid, 3);
         bonusTokens = _getBonusAmount(tokens, 3);
         fullTokens = tokens.add(bonusTokens);

          
         if(processedTokens.add(fullTokens) > capLevels[3]) {
            tokens = _calculateExcessTokens(amountPaid, 3);
            bonusTokens = _calculateExcessBonus(tokens, 3);
            setCurrentRound(4);
         }

     
    } else if(processedTokens >= capLevels[3] && processedTokens < capLevels[4]) {
         tokens = _getTokensAmount(amountPaid, 4);
         bonusTokens = _getBonusAmount(tokens, 4);
         fullTokens = tokens.add(bonusTokens);

          
         if(processedTokens.add(fullTokens) > capLevels[4]) {
            tokens = _calculateExcessTokens(amountPaid, 4);
            bonusTokens = _calculateExcessBonus(tokens, 4);
            setCurrentRound(5);
         }

     
    } else if(processedTokens >= capLevels[4] && processedTokens < capLevels[5]) {
         tokens = _getTokensAmount(amountPaid, 5);
         bonusTokens = _getBonusAmount(tokens, 5);
         fullTokens = tokens.add(bonusTokens);

          
         if(processedTokens.add(fullTokens) > capLevels[5]) {
            tokens = _calculateExcessTokens(amountPaid, 5);
            bonusTokens = 0;
            setCurrentRound(6);
         }

     
    } else if(processedTokens >= capLevels[5]) {
        tokens = _getTokensAmount(amountPaid, 6);
    }

     
    weiRaised = weiRaised.add(amountPaid);
    fullTokens = tokens.add(bonusTokens);
    soldTokens = soldTokens.add(fullTokens);
    processedTokens = processedTokens.add(fullTokens);

     
    tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);

     
    crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);

     
    bonusBalances[msg.sender] = bonusBalances[msg.sender].add(bonusTokens);

    
    uint256 totalTokens = tokens.add(bonusTokens);

     
    _processPurchase(_beneficiary, totalTokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      amountPaid,
      totalTokens
    );
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal {

    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    bool withinPeriod = hasStarted() && hasNotEnded();
    bool nonZeroPurchase = msg.value > 0;
    bool withinTokenLimit = processedTokens < maxTokensRaised;
    bool minimumPurchase = msg.value >= minPurchase;

    require(withinPeriod);
    require(nonZeroPurchase);
    require(withinTokenLimit);
    require(minimumPurchase);
  }


   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 _tokensToPreAllocate = _tokenAmount.div(2);
    uint256 _tokensToLock = _tokenAmount.sub(_tokensToPreAllocate);
    
     
    allocatedAddresses.push(_beneficiary);    

     
    _preAllocateTokens(_beneficiary, _tokensToPreAllocate);
    
     
    _lockTokens(_beneficiary, _tokensToLock);
    
     
    approved[_beneficiary] = true;
  }

  function _lockTokens(address _beneficiary, uint256 _tokenAmount) internal {
    lockedBalances[_beneficiary] = lockedBalances[_beneficiary].add(_tokenAmount);
    lockedTokens = lockedTokens.add(_tokenAmount);
  }

  function _preAllocateTokens(address _beneficiary, uint256 _tokenAmount) internal {
    allocatedBalances[_beneficiary] = allocatedBalances[_beneficiary].add(_tokenAmount);
    allocatedTokens = allocatedTokens.add(_tokenAmount);
  }

   
  function _getBonusAmount(uint256 _tokenAmount, uint256 _bonusIndex) internal view returns (uint256) {
    uint256 bonusValue = _tokenAmount.mul(bonusLevels[_bonusIndex]);
    return bonusValue.div(100);
  }

    function _calculateExcessBonus(uint256 _tokens, uint256 _level) internal view returns (uint256) {
        uint256 thisLevelTokens = processedTokens.add(_tokens);
        uint256 nextLevelTokens = thisLevelTokens.sub(capLevels[_level]);
        uint256 totalBonus = _getBonusAmount(nextLevelTokens, _level.add(1));
        return totalBonus;
    }

   function _calculateExcessTokens(
      uint256 amount,
      uint256 roundSelected
   ) internal returns(uint256) {
      require(amount > 0);
      require(roundSelected >= 1 && roundSelected <= 6);

      uint256 _rate = rateLevels[roundSelected];
      uint256 _leftTokens = capLevels[roundSelected].sub(processedTokens);
      uint256 weiThisRound = _leftTokens.div(_rate).mul(1E14);
      uint256 weiNextRound = amount.sub(weiThisRound);
      uint256 tokensNextRound = 0;

       
      uint256 nextRound = roundSelected.add(1);
      if(roundSelected != 6) {
        tokensNextRound = _getTokensAmount(weiNextRound, nextRound);
      }
      else {
         msg.sender.transfer(weiNextRound);
      }

      uint256 totalTokens = _leftTokens.add(tokensNextRound);
      return totalTokens;
   }


   function _getTokensAmount(uint256 weiPaid, uint256 roundSelected)
        internal constant returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(roundSelected >= 1 && roundSelected <= 6);
      uint256 typeTokenWei = weiPaid.div(1E14);
      calculatedTokens = typeTokenWei.mul(rateLevels[roundSelected]);

   }

   
   
   

   
  function _withdrawAllFunds() onlyOwner external {
    wallet.transfer(address(this).balance);
  }

  function _withdrawWei(uint256 _amount) onlyOwner external {
    wallet.transfer(_amount);
  }

   function _changeLockDate(uint256 _newDate) onlyOwner external {
    require(_newDate <= endTime.add(36 weeks));
    lockedTill = _newDate;
  }

   function _changeApproveDate(uint256 _newDate) onlyOwner external {
    require(_newDate <= endTime.add(12 weeks));
    approvedTill = _newDate;
  }

  function changeWallet(address _newWallet) onlyOwner external {
    wallet = _newWallet;
  }

    
   function hasNotEnded() public constant returns(bool) {
      return now < endTime && processedTokens < maxTokensRaised;
   }

    
   function hasStarted() public constant returns(bool) {
      return now > startTime;
   }

    function setCurrentRound(uint256 _roundIndex) internal {
        currentRound = _roundIndex;
        currentRoundStart = now;
    }

     
   function goNextRound() onlyOwner external {
       require(currentRound < 6);
       uint256 notSold = getUnsold();
       unSoldTokens = unSoldTokens.add(notSold);
       processedTokens = capLevels[currentRound];
       currentRound = currentRound.add(1);
       currentRoundStart = now;
   }

    function getUnsold() internal view returns (uint256) {
        uint256 unSold = capLevels[currentRound].sub(processedTokens);
        return unSold;
    }

    function checkUnsold() onlyOwner external view returns (uint256) {
        uint256 unSold = capLevels[currentRound].sub(processedTokens);
        return unSold;
    }

    function round() public view returns(uint256) {
        return currentRound;
    }

    function currentBonusLevel() public view returns(uint256) {
        return bonusLevels[currentRound];
    }

    function currentRateLevel() public view returns(uint256) {
        return rateLevels[currentRound];
    }

    function currentCapLevel() public view returns(uint256) {
        return capLevels[currentRound];
    }

    function changeApproval(address _beneficiary, bool _newStatus) onlyOwner public {
        approved[_beneficiary] = _newStatus;
    }

    function massApproval(bool _newStatus, uint256 _start, uint256 _end) onlyOwner public {
        require(_start >= 0);
        require(_end > 0);
        require(_end > _start);
        for (uint256 i = _start; i < _end; i++) {
            approved[allocatedAddresses[i]] = _newStatus;
        }
    }

    function autoTransferApproved(uint256 _start, uint256 _end) onlyOwner public {
        require(_start >= 0);
        require(_end > 0);
        require(_end > _start);
        for (uint256 i = _start; i < _end; i++) {
            transferApprovedBalance(allocatedAddresses[i]);
        }
    }

    function autoTransferLocked(uint256 _start, uint256 _end) onlyOwner public {
        require(_start >= 0);
        require(_end > 0);
        require(_end > _start);
        for (uint256 i = _start; i < _end; i++) {
            transferLockedBalance(allocatedAddresses[i]);
        }
    }

    function transferApprovedBalance(address _beneficiary) public {
        require(_beneficiary != address(0));
        require(now >= approvedTill);
        require(allocatedTokens > 0);
        require(approved[_beneficiary]);
        require(allocatedBalances[_beneficiary] > 0);
        
        uint256 _approvedTokensToTransfer = allocatedBalances[_beneficiary];
        token.transfer(_beneficiary, _approvedTokensToTransfer);
        distributedBalances[_beneficiary] = distributedBalances[_beneficiary].add(_approvedTokensToTransfer);
        allocatedTokens = allocatedTokens.sub(_approvedTokensToTransfer);
        allocatedBalances[_beneficiary] = 0;
        distributedTokens = distributedTokens.add(_approvedTokensToTransfer);
    }

    function transferLockedBalance(address _beneficiary) public {
        require(_beneficiary != address(0));
        require(now >= lockedTill);
        require(lockedTokens > 0);
        require(approved[_beneficiary]);
        require(lockedBalances[_beneficiary] > 0);

        uint256 _lockedTokensToTransfer = lockedBalances[_beneficiary];
        token.transfer(_beneficiary, _lockedTokensToTransfer);
        distributedBalances[_beneficiary] = distributedBalances[_beneficiary].add(_lockedTokensToTransfer);
        lockedTokens = lockedTokens.sub(_lockedTokensToTransfer);
        lockedBalances[_beneficiary] = 0;
        distributedTokens = distributedTokens.add(_lockedTokensToTransfer);
    }

    function transferToken(uint256 _tokens) external onlyOwner returns (bool success) {
         
         
        return token.transfer(owner, _tokens);
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

     
    function burnUnsold() public onlyOwner {
        require(now > lockedTill);
        require(address(this).balance == 0);
        require(lockedTokens == 0);
        require(allocatedTokens == 0);
        require(unSoldTokens > 0);
        selfdestruct(owner);
    }

}