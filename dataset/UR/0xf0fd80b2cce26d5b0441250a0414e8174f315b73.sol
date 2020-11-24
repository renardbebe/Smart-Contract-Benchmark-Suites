 

pragma solidity ^0.4.13;

contract ForeignToken {
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface Token { 
    function transfer(address _to, uint256 _value) returns (bool);
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract FuddCrowdsale {

    using SafeMath for uint256;
    mapping (address => uint256) balances;
    Token public fuddToken;

     
    address public beneficiary;                     
    address public creator;                         
    address public confirmedBy;                     
    uint256 public maxSupply;    
    bool public purchasingAllowed = false;
    uint256 public totalSupplied = 0;
    uint256 public startTimestamp;
    uint256 public rate;
    uint256 public firstBonus;
    uint256 public secondBonus;
    uint256 public firstTimer;
    uint256 public secondTimer;
    uint256 public endTimer;
    
     
    function FuddCrowdsale(address _tokenAddress, address _beneficiary, address _creator) {
        fuddToken = Token(_tokenAddress);
        beneficiary = _beneficiary;
        creator = _creator;
    }

    enum Stages {
        PreSale,      
        InProgress,   
        Ended,        
        Withdrawn     
    }

    Stages public stage = Stages.PreSale;

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

     
    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender);
        _;
    }

     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }
    
    function enablePurchasing(uint256 _firstTimer, uint256 _secondTimer, uint256 _endTimer,
    uint256 _maxSupply, uint256 _rate, uint256 _firstBonus, uint256 _secondBonus) onlyBeneficiary atStage(Stages.PreSale) {
        firstTimer = _firstTimer;
        secondTimer = _secondTimer;
        endTimer = _endTimer;
        maxSupply = _maxSupply;
        rate = _rate;
        firstBonus = _firstBonus;
        secondBonus = _secondBonus;
        purchasingAllowed = true;
        startTimestamp = now;
        stage = Stages.InProgress;
    }

    function disablePurchasing() onlyBeneficiary atStage(Stages.InProgress) {
        purchasingAllowed = false;
        stage = Stages.Ended;
    }
    
    function hasEnded() atStage(Stages.InProgress) {
        if (now >= startTimestamp.add(endTimer)){
            purchasingAllowed = false;
            stage = Stages.Ended;
        }
    }

    function enableNewPurchasing(uint256 _firstTimer, uint256 _secondTimer, uint256 _endTimer,
    uint256 _maxSupply, uint256 _rate, uint256 _firstBonus, uint256 _secondBonus) onlyBeneficiary atStage(Stages.Withdrawn) {
        firstTimer = _firstTimer;
        secondTimer = _secondTimer;
        endTimer = _endTimer;
        maxSupply = _maxSupply;
        rate = _rate;
        firstBonus = _firstBonus;
        secondBonus = _secondBonus;
        totalSupplied = 0;
        startTimestamp = now;
        purchasingAllowed = true;
        stage = Stages.InProgress;
    }
    
     
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {
        uint256 ethBalance = this.balance;
        beneficiary.transfer(ethBalance);
        stage = Stages.Withdrawn;
    }

     
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }
    
    event sendTokens(address indexed to, uint256 value);

     
    function () payable atStage(Stages.InProgress) {
        hasEnded();
        require(purchasingAllowed);
        if (msg.value == 0) { return; }
        uint256 weiAmount = msg.value;
        address investor = msg.sender;
        uint256 received = weiAmount.div(10e7);
        uint256 tokens = (received).mul(rate);

        if (msg.value >= 10 finney) {
            if (now <= startTimestamp.add(firstTimer)){
                uint256 firstBonusToken = (tokens.div(100)).mul(firstBonus);
                tokens = tokens.add(firstBonusToken);
            }
            
            if (startTimestamp.add(firstTimer) < now && 
            now <= startTimestamp.add(secondTimer)){
                uint256 secondBonusToken = (tokens.div(100)).mul(secondBonus);
                tokens = tokens.add(secondBonusToken);
            }
        }
        
        sendTokens(msg.sender, tokens);
        fuddToken.transfer(investor, tokens);
        totalSupplied = (totalSupplied).add(tokens);
            
        if (totalSupplied >= maxSupply) {
            purchasingAllowed = false;
            stage = Stages.Ended;
        }
    }
    
    function tokensAvailable() constant returns (uint256) {
        return fuddToken.balanceOf(this);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyBeneficiary public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(beneficiary, amount);
    }
}