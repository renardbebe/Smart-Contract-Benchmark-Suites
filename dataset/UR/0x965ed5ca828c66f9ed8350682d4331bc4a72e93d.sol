 

pragma solidity ^0.4.18;


 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint size) {
      if (msg.data.length < size + 4) {
      revert();
      }
      _;
  }

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));
    require(allowed[_from][msg.sender] >= _value);
    require(balances[_from] >= _value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() internal {
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

 
contract Pausable is Ownable  {
    event Pause();
    event Unpause();
    event Freeze ();
    event LogFreeze();

    bool public paused = false;

    address public founder;
    
     
    modifier whenNotPaused() {
        require(!paused || msg.sender == founder);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
   
   

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract FoxTradingToken is MintableToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  event TokensBurned(address initiatior, address indexed _partner, uint256 _tokens);
 

   
    function FoxTradingToken() public {
        name = "FoxTrading";
        symbol = "FOXT";
        decimals = 18;
        totalSupply = 15000000e18;
        founder = 0x47dE58a352e40d7FC57Efe57944836a0173206c2;
        balances[founder] = totalSupply;
        Transfer(0x0, founder, 15000000e18);
        pause();
    }

    modifier onlyFounder {
      require(msg.sender == founder);
      _;
    }

    event NewFounderAddress(address indexed from, address indexed to);

    function changeFounderAddress(address _newFounder) public onlyFounder {
        require(_newFounder != 0x0);
        NewFounderAddress(founder, _newFounder);
        founder = _newFounder;
    }

     
    function burnTokens(address _partner, uint256 _tokens) public onlyFounder {
        require(balances[_partner] >= _tokens);
        balances[_partner] = balances[_partner].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        TokensBurned(msg.sender, _partner, _tokens);
    }
}


contract Crowdsale is Ownable {

    using SafeMath for uint256;

    FoxTradingToken public token;
    uint256 public tokensForPreICO;
    uint256 public tokenCapForFirstMainStage;
    uint256 public tokenCapForSecondMainStage;
    uint256 public tokenCapForThirdMainStage;
    uint256 public tokenCapForFourthMainStage;
    uint256 public totalTokensForSale;
    uint256 public startTime;
    uint256 public endTime;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;

    uint256[4] public ICObonusStages;

    uint256 public preICOduration;
    bool public mainSaleActive;

    uint256 public tokensSold;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ICOSaleExtended(uint256 newEndTime);

    function Crowdsale() public {
        token = new FoxTradingToken();  
        startTime = now; 
        rate = 1200;
        wallet = 0x47dE58a352e40d7FC57Efe57944836a0173206c2;
        tokensForPreICO = 4500000e18;

        tokenCapForFirstMainStage = 11500000e18;   
        tokenCapForSecondMainStage = 18500000e18;   
        tokenCapForThirdMainStage = 25500000e18;   
        tokenCapForFourthMainStage = 35000000e18;   

        totalTokensForSale = 35000000e18;
        tokensSold = 0;

        preICOduration = now.add(31 days);
        endTime = preICOduration;

        mainSaleActive = false;
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _addr) public payable {
        require(validPurchase() && tokensSold < totalTokensForSale);
        require(_addr != 0x0 && msg.value >= 100 finney);  
        uint256 toMint;
        if(now <= preICOduration) {
            if(tokensSold >= tokensForPreICO) { revert(); }
            toMint = msg.value.mul(rate.mul(2));
        } else {
            if(!mainSaleActive) { revert(); }
            toMint = msg.value.mul(getRateWithBonus());
        }
        tokensSold = tokensSold.add(toMint);
        token.mint(_addr, toMint);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function processOfflinePurchase(address _to, uint256 _toMint) public onlyOwner {
        require(tokensSold.add(_toMint) <= totalTokensForSale);
        require(_toMint > 0 && _to != 0x0);
        tokensSold = tokensSold.add(_toMint);
        token.mint(_to, _toMint);
    }

    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime; 
        bool nonZeroPurchase = msg.value != 0; 
        return withinPeriod && nonZeroPurchase;
    }

    
    function finishMinting() public onlyOwner {
        token.finishMinting();
    }


    function getRateWithBonus() internal view returns (uint256 rateWithDiscount) {
        if (now > preICOduration && tokensSold < totalTokensForSale) {
            return rate.mul(getCurrentBonus()).div(100).add(rate);
            return rateWithDiscount;
        }
        return rate;
    }

     
    function getCurrentBonus() internal view returns (uint256 discount) {
        require(tokensSold < tokenCapForFourthMainStage);
        uint256 timeStamp = now;
        uint256 stage;

        for (uint i = 0; i < ICObonusStages.length; i++) {
            if (timeStamp <= ICObonusStages[i]) {
                stage = i + 1;
                break;
            } 
        } 

        if(stage == 1 && tokensSold < tokenCapForFirstMainStage) { discount = 20; }
        if(stage == 1 && tokensSold >= tokenCapForFirstMainStage) { discount = 15; }
        if(stage == 1 && tokensSold >= tokenCapForSecondMainStage) { discount = 10; }
        if(stage == 1 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 2 && tokensSold < tokenCapForSecondMainStage) { discount = 15; }
        if(stage == 2 && tokensSold >= tokenCapForSecondMainStage) { discount = 10; }
        if(stage == 2 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 3 && tokensSold < tokenCapForThirdMainStage) { discount = 10; }
        if(stage == 3 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 4) { discount = 0; }

        return discount;
    }


    
     
    function activateMainSale() public onlyOwner {
        require(now > preICOduration || tokensSold >= tokensForPreICO);
        require(!mainSaleActive);
        if(now < preICOduration) { preICOduration = now; }
        mainSaleActive = true;
        ICObonusStages[0] = now.add(7 days);

        for (uint y = 1; y < ICObonusStages.length; y++) {
            ICObonusStages[y] = ICObonusStages[y - 1].add(7 days);
        }

        endTime = ICObonusStages[3];
    }

    function extendDuration(uint256 _newEndTime) public onlyOwner {
        require(endTime < _newEndTime && mainSaleActive);
        endTime = _newEndTime;
        ICOSaleExtended(_newEndTime);
    }


    function hasEnded() public view returns (bool) { 
        return now > endTime;
    }

     
    function unpauseToken() public onlyOwner {
        token.unpause();
    }
}