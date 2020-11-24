 

pragma solidity 0.4.20;

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


 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
}


 
 
 
contract VLTToken is ERC20Interface {
    using SafeMath for uint256;

    address public owner = msg.sender;

    bytes32 public symbol;
    bytes32 public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
     
    function VLTToken() public {
        symbol = "VAI";
        name = "VIOLET";
        decimals = 18;
        _totalSupply = 250000000 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }


     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
         
        if (_value == 0) {
            Transfer(msg.sender, _to, _value);     
            return;
        }
        
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
         
        if (_value == 0) {
            Transfer(_from, _to, _value);     
            return;
        }

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);                
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);   
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        _totalSupply = _totalSupply.sub(_value);                               
        Burn(_from, _value);
        Transfer(_from, address(0), _value);
        return true;
    } 

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
 
contract ViolaCrowdsale is Ownable {
  using SafeMath for uint256;

  enum State { Deployed, PendingStart, Active, Paused, Ended, Completed }

   
  State public status = State.Deployed;

   
  VLTToken public violaToken;

   
  mapping(address=>uint) public maxBuyCap;

   
  mapping(address => bool)public addressKYC;

   
  mapping(address=>uint) public investedSum;

   
  mapping(address=>uint) public tokensAllocated;

     
  mapping(address=>uint) public externalTokensAllocated;

   
  mapping(address=>uint) public bonusTokensAllocated;

   
  mapping(address=>uint) public externalBonusTokensAllocated;

   
   
  address[] public registeredAddress;

   
  uint256 public totalApprovedAmount = 0;

   
  uint256 public startTime;
  uint256 public endTime;
  uint256 public bonusVestingPeriod = 60 days;


   


   
  address public wallet;

   
  uint256 public minWeiToPurchase;

   
  uint256 public rate;

   
  uint public bonusTokenRateLevelOne = 20;
  uint public bonusTokenRateLevelTwo = 15;
  uint public bonusTokenRateLevelThree = 10;
  uint public bonusTokenRateLevelFour = 0;

   
  uint256 public totalTokensAllocated;

   
   
  uint256 public totalReservedTokenAllocated;

   
  uint256 public leftoverTokensBuffer;

   

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount, uint256 bonusAmount);
  event ExternalTokenPurchase(address indexed purchaser, uint256 amount, uint256 bonusAmount);
  event ExternalPurchaseRefunded(address indexed purchaser, uint256 amount, uint256 bonusAmount);
  event TokenDistributed(address indexed tokenReceiver, uint256 tokenAmount);
  event BonusTokenDistributed(address indexed tokenReceiver, uint256 tokenAmount);
  event TopupTokenAllocated(address indexed tokenReceiver, uint256 amount, uint256 bonusAmount);
  event CrowdsalePending();
  event CrowdsaleStarted();
  event CrowdsaleEnded();
  event BonusRateChanged();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  function initialiseCrowdsale (uint256 _startTime, uint256 _rate, address _tokenAddress, address _wallet) onlyOwner external {
    require(status == State.Deployed);
    require(_startTime >= now);
    require(_rate > 0);
    require(address(_tokenAddress) != address(0));
    require(_wallet != address(0));

    startTime = _startTime;
    endTime = _startTime + 30 days;
    rate = _rate;
    wallet = _wallet;
    violaToken = VLTToken(_tokenAddress);

    status = State.PendingStart;

    CrowdsalePending();

  }

   


   
   
  function startCrowdsale() external {
    require(withinPeriod());
    require(violaToken != address(0));
    require(getTokensLeft() > 0);
    require(status == State.PendingStart);

    status = State.Active;

    CrowdsaleStarted();
  }

   
   
  function endCrowdsale() public {
    if (!tokensHasSoldOut()) {
      require(msg.sender == owner);
    }
    require(status == State.Active);

    bonusVestingPeriod = now + 60 days;

    status = State.Ended;

    CrowdsaleEnded();
  }
   
  function pauseCrowdsale() onlyOwner external {
    require(status == State.Active);

    status = State.Paused;
  }
   
  function unpauseCrowdsale() onlyOwner external {
    require(status == State.Paused);

    status = State.Active;
  }

  function completeCrowdsale() onlyOwner external {
    require(hasEnded());
    require(violaToken.allowance(owner, this) == 0);
    status = State.Completed;

    _forwardFunds();

    assert(this.balance == 0);
  }

  function burnExtraTokens() onlyOwner external {
    require(hasEnded());
    uint256 extraTokensToBurn = violaToken.allowance(owner, this);
    violaToken.burnFrom(owner, extraTokensToBurn);
    assert(violaToken.allowance(owner, this) == 0);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(this.balance);
  }

  function partialForwardFunds(uint _amountToTransfer) onlyOwner external {
    require(status == State.Ended);
    require(_amountToTransfer < totalApprovedAmount);
    totalApprovedAmount = totalApprovedAmount.sub(_amountToTransfer);
    
    wallet.transfer(_amountToTransfer);
  }

   


  function setLeftoverTokensBuffer(uint256 _tokenBuffer) onlyOwner external {
    require(_tokenBuffer > 0);
    require(getTokensLeft() >= _tokenBuffer);
    leftoverTokensBuffer = _tokenBuffer;
  }

   
  function setRate(uint _rate) onlyOwner external {
    require(_rate > 0);
    rate = _rate;
  }

  function setBonusTokenRateLevelOne(uint _rate) onlyOwner external {
     
    bonusTokenRateLevelOne = _rate;
    BonusRateChanged();
  }

  function setBonusTokenRateLevelTwo(uint _rate) onlyOwner external {
     
    bonusTokenRateLevelTwo = _rate;
    BonusRateChanged();
  }

  function setBonusTokenRateLevelThree(uint _rate) onlyOwner external {
     
    bonusTokenRateLevelThree = _rate;
    BonusRateChanged();
  }
  function setBonusTokenRateLevelFour(uint _rate) onlyOwner external {
     
    bonusTokenRateLevelFour = _rate;
    BonusRateChanged();
  }

  function setMinWeiToPurchase(uint _minWeiToPurchase) onlyOwner external {
    minWeiToPurchase = _minWeiToPurchase;
  }


   


   
   
   
  
  function setWhitelistAddress( address _investor, uint _cap ) onlyOwner external {
        require(_cap > 0);
        require(_investor != address(0));
        maxBuyCap[_investor] = _cap;
        registeredAddress.push(_investor);
         
    }

   
  function removeWhitelistAddress(address _investor) onlyOwner external {
    require(_investor != address(0));
    
    maxBuyCap[_investor] = 0;
    uint256 weiAmount = investedSum[_investor];

    if (weiAmount > 0) {
      _refund(_investor);
    }
  }

   
  function approveKYC(address _kycAddress) onlyOwner external {
    require(_kycAddress != address(0));
    addressKYC[_kycAddress] = true;

    uint256 weiAmount = investedSum[_kycAddress];
    totalApprovedAmount = totalApprovedAmount.add(weiAmount);
  }

   
  function revokeKYC(address _kycAddress) onlyOwner external {
    require(_kycAddress != address(0));
    addressKYC[_kycAddress] = false;

    uint256 weiAmount = investedSum[_kycAddress];
    totalApprovedAmount = totalApprovedAmount.sub(weiAmount);

    if (weiAmount > 0) {
      _refund(_kycAddress);
    }
  }

   

   
    function tokensHasSoldOut() view internal returns (bool) {
      if (getTokensLeft() <= leftoverTokensBuffer) {
        return true;
      } else {
        return false;
      }
    }

       
  function withinPeriod() public view returns (bool) {
    return now >= startTime && now <= endTime;
  }

   
  function hasEnded() public view returns (bool) {
    if (status == State.Ended) {
      return true;
    }
    return now > endTime;
  }

  function getTokensLeft() public view returns (uint) {
    return violaToken.allowance(owner, this).sub(totalTokensAllocated);
  }

  function transferTokens (address receiver, uint tokenAmount) internal {
     require(violaToken.transferFrom(owner, receiver, tokenAmount));
  }

  function getTimeBasedBonusRate() public view returns(uint) {
    bool bonusDuration1 = now >= startTime && now <= (startTime + 1 days);   
    bool bonusDuration2 = now > (startTime + 1 days) && now <= (startTime + 3 days); 
    bool bonusDuration3 = now > (startTime + 3 days) && now <= (startTime + 10 days); 
    bool bonusDuration4 = now > (startTime + 10 days) && now <= endTime; 
    if (bonusDuration1) {
      return bonusTokenRateLevelOne;
    } else if (bonusDuration2) {
      return bonusTokenRateLevelTwo;
    } else if (bonusDuration3) {
      return bonusTokenRateLevelThree;
    } else if (bonusDuration4) {
      return bonusTokenRateLevelFour;
    } else {
      return 0;
    }
  }

  function getTotalTokensByAddress(address _investor) public view returns(uint) {
    return getTotalNormalTokensByAddress(_investor).add(getTotalBonusTokensByAddress(_investor));
  }

  function getTotalNormalTokensByAddress(address _investor) public view returns(uint) {
    return tokensAllocated[_investor].add(externalTokensAllocated[_investor]);
  }

  function getTotalBonusTokensByAddress(address _investor) public view returns(uint) {
    return bonusTokensAllocated[_investor].add(externalBonusTokensAllocated[_investor]);
  }

  function _clearTotalNormalTokensByAddress(address _investor) internal {
    tokensAllocated[_investor] = 0;
    externalTokensAllocated[_investor] = 0;
  }

  function _clearTotalBonusTokensByAddress(address _investor) internal {
    bonusTokensAllocated[_investor] = 0;
    externalBonusTokensAllocated[_investor] = 0;
  }


   


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address investor) internal {
    require(status == State.Active);
    require(msg.value >= minWeiToPurchase);

    uint weiAmount = msg.value;

    checkCapAndRecord(investor,weiAmount);

    allocateToken(investor,weiAmount);
    
  }

   
  function checkCapAndRecord(address investor, uint weiAmount) internal {
      uint remaindingCap = maxBuyCap[investor];
      require(remaindingCap >= weiAmount);
      maxBuyCap[investor] = remaindingCap.sub(weiAmount);
      investedSum[investor] = investedSum[investor].add(weiAmount);
  }

   
    function allocateToken(address investor, uint weiAmount) internal {
         
        uint tokens = weiAmount.mul(rate);
        uint bonusTokens = tokens.mul(getTimeBasedBonusRate()).div(100);
        
        uint tokensToAllocate = tokens.add(bonusTokens);
        
        require(getTokensLeft() >= tokensToAllocate);
        totalTokensAllocated = totalTokensAllocated.add(tokensToAllocate);

        tokensAllocated[investor] = tokensAllocated[investor].add(tokens);
        bonusTokensAllocated[investor] = bonusTokensAllocated[investor].add(bonusTokens);

        if (tokensHasSoldOut()) {
          endCrowdsale();
        }
        TokenPurchase(investor, weiAmount, tokens, bonusTokens);
  }



   



   
  function _refund(address _investor) internal {
    uint256 investedAmt = investedSum[_investor];
    require(investedAmt > 0);

  
      uint totalInvestorTokens = tokensAllocated[_investor].add(bonusTokensAllocated[_investor]);

    if (status == State.Active) {
       
      totalTokensAllocated = totalTokensAllocated.sub(totalInvestorTokens);
    }

    _clearAddressFromCrowdsale(_investor);

    _investor.transfer(investedAmt);

    Refunded(_investor, investedAmt);
  }

     
  function refundPartial(address _investor, uint _refundAmt, uint _tokenAmt, uint _bonusTokenAmt) onlyOwner external {

    uint investedAmt = investedSum[_investor];
    require(investedAmt > _refundAmt);
    require(tokensAllocated[_investor] > _tokenAmt);
    require(bonusTokensAllocated[_investor] > _bonusTokenAmt);

    investedSum[_investor] = investedSum[_investor].sub(_refundAmt);
    tokensAllocated[_investor] = tokensAllocated[_investor].sub(_tokenAmt);
    bonusTokensAllocated[_investor] = bonusTokensAllocated[_investor].sub(_bonusTokenAmt);


    uint totalRefundTokens = _tokenAmt.add(_bonusTokenAmt);

    if (status == State.Active) {
       
      totalTokensAllocated = totalTokensAllocated.sub(totalRefundTokens);
    }

    _investor.transfer(_refundAmt);

    Refunded(_investor, _refundAmt);
  }

   
    function claimTokens() external {
      require(hasEnded());
      require(addressKYC[msg.sender]);
      address tokenReceiver = msg.sender;
      uint tokensToClaim = getTotalNormalTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalNormalTokensByAddress(tokenReceiver);

      violaToken.transferFrom(owner, tokenReceiver, tokensToClaim);

      TokenDistributed(tokenReceiver, tokensToClaim);

    }

     
    function claimBonusTokens() external {
      require(hasEnded());
      require(now >= bonusVestingPeriod);
      require(addressKYC[msg.sender]);

      address tokenReceiver = msg.sender;
      uint tokensToClaim = getTotalBonusTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalBonusTokensByAddress(tokenReceiver);

      violaToken.transferFrom(owner, tokenReceiver, tokensToClaim);

      BonusTokenDistributed(tokenReceiver, tokensToClaim);
    }

     
    function distributeBonusTokens(address _tokenReceiver) onlyOwner external {
      require(hasEnded());
      require(now >= bonusVestingPeriod);

      address tokenReceiver = _tokenReceiver;
      uint tokensToClaim = getTotalBonusTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalBonusTokensByAddress(tokenReceiver);

      transferTokens(tokenReceiver, tokensToClaim);

      BonusTokenDistributed(tokenReceiver,tokensToClaim);

    }

     
    function distributeICOTokens(address _tokenReceiver) onlyOwner external {
      require(hasEnded());

      address tokenReceiver = _tokenReceiver;
      uint tokensToClaim = getTotalNormalTokensByAddress(tokenReceiver);

      require(tokensToClaim > 0);
      _clearTotalNormalTokensByAddress(tokenReceiver);

      transferTokens(tokenReceiver, tokensToClaim);

      TokenDistributed(tokenReceiver,tokensToClaim);

    }

     
     

     
     
     

     

     
     
     
     
     

     

     

     

     
    function externalPurchaseTokens(address _investor, uint _amount, uint _bonusAmount) onlyOwner external {
      require(_amount > 0);
      uint256 totalTokensToAllocate = _amount.add(_bonusAmount);

      require(getTokensLeft() >= totalTokensToAllocate);
      totalTokensAllocated = totalTokensAllocated.add(totalTokensToAllocate);
      totalReservedTokenAllocated = totalReservedTokenAllocated.add(totalTokensToAllocate);

      externalTokensAllocated[_investor] = externalTokensAllocated[_investor].add(_amount);
      externalBonusTokensAllocated[_investor] = externalBonusTokensAllocated[_investor].add(_bonusAmount);
      
      ExternalTokenPurchase(_investor,  _amount, _bonusAmount);

    }

    function refundAllExternalPurchase(address _investor) onlyOwner external {
      require(_investor != address(0));
      require(externalTokensAllocated[_investor] > 0);

      uint externalTokens = externalTokensAllocated[_investor];
      uint externalBonusTokens = externalBonusTokensAllocated[_investor];

      externalTokensAllocated[_investor] = 0;
      externalBonusTokensAllocated[_investor] = 0;

      uint totalInvestorTokens = externalTokens.add(externalBonusTokens);

      totalReservedTokenAllocated = totalReservedTokenAllocated.sub(totalInvestorTokens);
      totalTokensAllocated = totalTokensAllocated.sub(totalInvestorTokens);

      ExternalPurchaseRefunded(_investor,externalTokens,externalBonusTokens);
    }

    function refundExternalPurchase(address _investor, uint _amountToRefund, uint _bonusAmountToRefund) onlyOwner external {
      require(_investor != address(0));
      require(externalTokensAllocated[_investor] >= _amountToRefund);
      require(externalBonusTokensAllocated[_investor] >= _bonusAmountToRefund);

      uint totalTokensToRefund = _amountToRefund.add(_bonusAmountToRefund);
      externalTokensAllocated[_investor] = externalTokensAllocated[_investor].sub(_amountToRefund);
      externalBonusTokensAllocated[_investor] = externalBonusTokensAllocated[_investor].sub(_bonusAmountToRefund);

      totalReservedTokenAllocated = totalReservedTokenAllocated.sub(totalTokensToRefund);
      totalTokensAllocated = totalTokensAllocated.sub(totalTokensToRefund);

      ExternalPurchaseRefunded(_investor,_amountToRefund,_bonusAmountToRefund);
    }

    function _clearAddressFromCrowdsale(address _investor) internal {
      tokensAllocated[_investor] = 0;
      bonusTokensAllocated[_investor] = 0;
      investedSum[_investor] = 0;
      maxBuyCap[_investor] = 0;
    }

    function allocateTopupToken(address _investor, uint _amount, uint _bonusAmount) onlyOwner external {
      require(hasEnded());
      require(_amount > 0);
      uint256 tokensToAllocate = _amount.add(_bonusAmount);

      require(getTokensLeft() >= tokensToAllocate);
      totalTokensAllocated = totalTokensAllocated.add(_amount);

      tokensAllocated[_investor] = tokensAllocated[_investor].add(_amount);
      bonusTokensAllocated[_investor] = bonusTokensAllocated[_investor].add(_bonusAmount);

      TopupTokenAllocated(_investor,  _amount, _bonusAmount);
    }

   
  function emergencyERC20Drain( ERC20 token, uint amount ) external onlyOwner {
    require(status == State.Completed);
    token.transfer(owner,amount);
  }

}