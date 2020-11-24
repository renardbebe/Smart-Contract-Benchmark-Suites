 

pragma solidity ^0.4.19;

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

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract StandardToken is ERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  
  address internal tokensHolder = 0x2Ff4be5E03a079D5FC20Dba8d763059FcB78CA9f;
  address internal burnAndRef = 0x84765e3f2D0379eC7AAb7de8b480762a75f14ef4;

  uint256 totalSupply_;
  uint256 tokensDistributed_;
  uint256 burnedTokens_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  function tokensAvailable() public view returns (uint256) {
    return balances[tokensHolder];
  }
  function tokensDistributed() public view returns (uint256) {
    return tokensDistributed_;
  }
  function getTokensHolder() public view returns (address) {
    return tokensHolder;
  }
  function burnedTokens() public view returns (uint256) {
    return burnedTokens_;
  }
  function getRefAddress() public view returns (address) {
    return burnAndRef;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function deposit(address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_value <= tokensAvailable());

     
    balances[tokensHolder] = balances[tokensHolder].sub(_value);
    balances[_to] = balances[_to].add(_value);
    tokensDistributed_ = tokensDistributed_.add(_value);
    emit Transfer(address(0), _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract BurnableToken is MintableToken {

  event Burn(address indexed burner, uint256 value);
  
  function transferToRef(address _to, uint256 _value) public onlyOwner {
    require(_value <= balances[tokensHolder]);

    balances[tokensHolder] = balances[tokensHolder].sub(_value);
    balances[_to] = balances[_to].add(_value);
    tokensDistributed_ = tokensDistributed_.add(_value);
    emit Transfer(tokensHolder, address(0), _value);
  }
  
  function burnTokens(uint256 _value) public onlyOwner {
    require(_value <= balances[burnAndRef]);

    balances[burnAndRef] = balances[burnAndRef].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    burnedTokens_ = burnedTokens_.add(_value);
    emit Burn(burnAndRef, _value);
    emit Transfer(burnAndRef, address(0), _value);
  }
}

contract WRLToken is BurnableToken {
    string public name = "Whyral Token";
    string public symbol = "WRL";
    uint256 public decimals = 8;
    
    uint256 internal rate;
    
    uint256 public currentStage;
  
    uint256 internal stage0Cap = 42000000 * (10 ** uint256(decimals));
    uint256 internal stage1Cap = 71165000 * (10 ** uint256(decimals));   
    uint256 internal stage2Cap = 91165000 * (10 ** uint256(decimals));   
    uint256 internal stage3Cap = 103497402 * (10 ** uint256(decimals));  

    uint256 internal stage0Start = 1523782800;  
    uint256 internal stage0End = 1527764400;    
    uint256 internal stage1Start = 1528016400;  
    uint256 internal stage1End = 1530356400;    
    uint256 internal stage2Start = 1530608400;  
    uint256 internal stage2End = 1532516400;    
    uint256 internal stage3Start = 1532768400;  
    uint256 internal stage3End = 1534330800;    
    
    uint256 internal stage0Rate = 700000;   
    uint256 internal stage1Rate = 583300;   
    uint256 internal stage2Rate = 500000;   
    uint256 internal stage3Rate = 466782;   
    
    function getStage0Cap() public view returns (uint256) {
        return stage0Cap;
    }
    function getStage1Cap() public view returns (uint256) {
        return stage1Cap;
    }
    function getStage2Cap() public view returns (uint256) {
        return stage2Cap;
    }
    function getStage3Cap() public view returns (uint256) {
        return stage3Cap;
    }
    function getStage0End() public view returns (uint256) {
        return stage0End;
    }
    function getStage1End() public view returns (uint256) {
        return stage1End;
    }
    function getStage2End() public view returns (uint256) {
        return stage2End;
    }
    function getStage3End() public view returns (uint256) {
        return stage3End;
    }
    function getStage0Start() public view returns (uint256) {
        return stage0Start;
    }
    function getStage1Start() public view returns (uint256) {
        return stage1Start;
    }
    function getStage2Start() public view returns (uint256) {
        return stage2Start;
    }
    function getStage3Start() public view returns (uint256) {
        return stage3Start;
    }
    function getDecimals() public view returns (uint256) {
        return decimals;
    }

    
    function getRateStages(uint256 _tokens) public onlyOwner returns(uint256) {
      uint256 tokensDistributedValue = tokensDistributed();
      tokensDistributedValue = tokensDistributedValue.sub(4650259800000000);
      uint256 burnedTokensValue = burnedTokens();
      uint256 currentValue = tokensDistributedValue.add(burnedTokensValue);
      uint256 finalTokenValue = currentValue.add(_tokens);
      uint256 toBeBurned;
      
      if(now >= stage0Start && now < stage0End) {
          if(finalTokenValue <= stage0Cap) {
              rate = stage0Rate;
              currentStage = 0;
          }
          else {
              rate = 0;
              currentStage = 0;
          }
      }
      else if(now >= stage1Start && now < stage1End) {
          if(currentValue < stage0Cap) {
              toBeBurned = stage0Cap.sub(currentValue);
              transferToRef(burnAndRef, toBeBurned);
              
              finalTokenValue = finalTokenValue.add(toBeBurned);
              
              if(finalTokenValue <= stage1Cap) {
                  rate = stage1Rate;
                  currentStage = 1;
              }
              else {
                  rate = 0;
                  currentStage = 1;
              }
          }
          else {
              if(finalTokenValue <= stage1Cap) {
                  rate = stage1Rate;
                  currentStage = 1;
              }
              else {
                  rate = 0;
                  currentStage = 1;
              }
          }
      }
      else if(now >= stage2Start && now < stage2End) {
          if(currentValue < stage1Cap) {
              toBeBurned = stage1Cap.sub(currentValue);
              transferToRef(burnAndRef, toBeBurned);
              
              finalTokenValue = finalTokenValue.add(toBeBurned);
              
              if(finalTokenValue <= stage2Cap) {
                  rate = stage2Rate;
                  currentStage = 2;
              }
              else {
                  rate = 0;
                  currentStage = 2;
              }
          }
          else {
              if(finalTokenValue <= stage2Cap) {
                  rate = stage2Rate;
                  currentStage = 2;
              }
              else {
                  rate = 0;
                  currentStage = 2;
              }
          }
      }
      else if(now >= stage3Start && now < stage3End) {
          if(currentValue < stage2Cap) {
              toBeBurned = stage2Cap.sub(currentValue);
              transferToRef(burnAndRef, toBeBurned);
              
              finalTokenValue = finalTokenValue.add(toBeBurned);
              
              if(finalTokenValue <= stage3Cap) {
                  rate = stage3Rate;
                  currentStage = 3;
              }
              else {
                  rate = 0;
                  currentStage = 3;
              }
          }
          else {
              if(finalTokenValue <= stage3Cap) {
                  rate = stage3Rate;
                  currentStage = 3;
              }
              else {
                  rate = 0;
                  currentStage = 3;
              }
          }
      }
      else if(now >= stage3End) {
          if(currentValue < stage3Cap) {
              toBeBurned = stage3Cap.sub(currentValue);
              transferToRef(burnAndRef, toBeBurned);
              
              rate = 0;
              currentStage = 4;
          }
          else {
              rate = 0;
              currentStage = 4;
          }
      }
      else {
          rate = 0;
      }
      
      return rate;
  }
    
    function WRLToken() public {
        totalSupply_ = 0;
        tokensDistributed_ = 0;
        currentStage = 0;
        
        uint256 __initialSupply = 150000000 * (10 ** uint256(decimals));
        address tokensHolder = getTokensHolder();
        mint(tokensHolder, __initialSupply);
        finishMinting();
    }
}

contract TimedCrowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
  
  function isOpen() public view returns (bool) {
    return ((now > openingTime) && (now < closingTime));
  }
  
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
     
  }

}

contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;
  
   
  WRLToken public token;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
      token.getRateStages(0);
  }
}

contract WhitelistedCrowdsale is FinalizableCrowdsale {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract WRLCrowdsale is WhitelistedCrowdsale {
  using SafeMath for uint256;

   
  address public wallet = 0x4fB0346F51fA853639EC0d0dA211Cb6F3e27a1f5;
   
  address internal foundersAndTeam = 0x2E6f0ebFdee59546f224450Ba0c8F0522cedA2e9;
  address internal advisors = 0xCa502d4cEaa99Bf1aD554f91FD2A9013511629D4;
  address internal bounties = 0x45138E31Ab7402b8Cf363F9d4e732fdb020e5Dd8;
  address internal reserveFund = 0xE9ebcAdB98127e3CDe242EaAdcCb57BF0d9576Cc;
  
  uint256 internal foundersAndTeamTokens = 22502598 * (10 ** uint256(8));
  uint256 internal advisorsTokens = 12000000 * (10 ** uint256(8));
  uint256 internal bountiesTokens = 6000000 * (10 ** uint256(8));
  uint256 internal reserveFundTokens = 6000000 * (10 ** uint256(8));
    
   
  uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
   
   
  function WRLCrowdsale() public 
     TimedCrowdsale(1523782800, 1534330800)
  {
      weiRaised = 0;
      
      token = new WRLToken();
      
      token.deposit(foundersAndTeam, foundersAndTeamTokens);
      token.deposit(advisors, advisorsTokens);
      token.deposit(bounties, bountiesTokens);
      token.deposit(reserveFund, reserveFundTokens);
  }
  
   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {
    require(msg.value >= 100000000000000000);
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    uint256 rate = token.getRateStages(tokens);
    require(rate != 0);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }
  
  function referralTokens(address _beneficiary, uint256 _tokens) onlyOwner public {
      uint256 decimals = token.getDecimals();
      _tokens = _tokens * (10 ** uint256(decimals));
      _preValidatePurchase(_beneficiary, _tokens);
      
      uint256 rate = token.getRateStages(_tokens);
      require(rate != 0);
      
      _processPurchase(_beneficiary, _tokens);
      emit TokenPurchase(msg.sender, _beneficiary, 0, _tokens);
      
      _updatePurchasingState(_beneficiary, 0);
      
      _postValidatePurchase(_beneficiary, 0);
  }
  
  function callStages() onlyOwner public {
      token.getRateStages(0);
  }
  
  function callBurnTokens(uint256 _tokens) public {
      address a = token.getRefAddress();
      require(msg.sender == a);
      
      token.burnTokens(_tokens);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(_tokenAmount <= token.tokensAvailable());

    token.deposit(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
      uint256 tokenAmount = _weiAmount;
      uint256 rate = token.getRateStages(0);
      require(rate != 0);
      tokenAmount = tokenAmount.mul(rate);
      tokenAmount = tokenAmount.div(1000000000000);
      return tokenAmount;
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}