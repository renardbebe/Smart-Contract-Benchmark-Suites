 

pragma solidity 0.4.19;

 
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


   
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

     
     

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

   
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

   
    function increaseApproval (address _spender, uint _addedValue)
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
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

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract Tigereum is MintableToken, BurnableToken {
    string public webAddress = "www.tigereum.io";
    string public name = "Tigereum";
    string public symbol = "TIG";
    uint8 public decimals = 18;
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    var curtime = now;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

contract TigereumCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
  
     
    bool public LockupTokensWithdrawn = false;
    bool public isFinalized = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 32800000*toDec;
    uint256 public constant cap = 32800000*toDec;
    uint256 public constant startRate = 1333;
    uint256 private accumulated = 0;

    enum State { BeforeSale, Bonus, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;

     

    address public admin; 
    address public ICOadvisor1; 
    uint256 private constant ICOadvisor1Sum = 400000*toDec;  

     

    address public hundredKInvestor; 
    uint256 private constant hundredKInvestorSum = 3200000*toDec;  

    address public additionalPresaleInvestors; 
    uint256 private constant additionalPresaleInvestorsSum = 1000000*toDec;  

    address public preSaleBotReserve; 
    uint256 private constant preSaleBotReserveSum = 2500000*toDec;  

    address public ICOadvisor2; 
    uint256 private constant ICOadvisor2Sum = 100000*toDec;  

    address public team; 
    uint256 private constant teamSum = 1820000*toDec;  
 
    address public bounty; 
    uint256 private constant bountySum = 1000000*toDec;  

    
     
    address public founders; 
    uint256 private constant foundersSum = 7180000*toDec;  


     


    uint256 public constant startTimeNumber = 1512723600 + 1;  
    uint256 public constant endTimeNumber = 1513641540;  

    uint256 public constant lockupPeriod = 90 * 1 days;  
    uint256 public constant bonusPeriod = 12 * 1 hours;  

    uint256 public constant bonusEndTime = bonusPeriod + startTimeNumber;



    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    function TigereumCrowdsale(
        address _admin,
        address _ICOadvisor1,
        address _hundredKInvestor,
        address _additionalPresaleInvestors,
        address _preSaleBotReserve,
        address _ICOadvisor2,
        address _team,
        address _bounty,
        address _founders)
    Crowdsale(
        startTimeNumber  , 
        endTimeNumber  , 
        startRate  , 
        _admin
    )  
    public 
    {      
        admin = _admin;
        ICOadvisor1 = _ICOadvisor1;
        hundredKInvestor = _hundredKInvestor;
        additionalPresaleInvestors = _additionalPresaleInvestors;
        preSaleBotReserve = _preSaleBotReserve;
        ICOadvisor2 = _ICOadvisor2;
        team = _team;
        bounty = _bounty;
        founders = _founders;
        owner = admin;
    }

    function isContract(address addr) private returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }

     
     
    function createTokenContract() internal returns (MintableToken) {
        return new Tigereum();
    }

    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        var onePercent = amount / 100;
        var adminAmount = onePercent.mul(99);
        admin.transfer(adminAmount);
        ICOadvisor1.transfer(onePercent);
        var left = amount.sub(adminAmount).sub(onePercent);
        accumulated = accumulated.add(left);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver);
        if (walletIndex == 0 && !isContract(newAddress)) {
            admin = newAddress;
        }
        if (walletIndex == 1 && !isContract(newAddress)) {
            ICOadvisor1 = newAddress;
        }
        if (walletIndex == 2) {
            hundredKInvestor = newAddress;
        }
        if (walletIndex == 3) {
            additionalPresaleInvestors = newAddress;
        }
        if (walletIndex == 4) {
            preSaleBotReserve = newAddress;
        }
        if (walletIndex == 5) {
            ICOadvisor2 = newAddress;
        }
        if (walletIndex == 6) {
            team = newAddress;
        }
        if (walletIndex == 7) {
            bounty = newAddress;
        }
        if (walletIndex == 8) {
            founders = newAddress;
        }
    }

    function calculateCurrentRate() internal {
        if (state == State.NormalSale) {
            rate = 1000;
        }
    }

    function buyTokensUpdateState() internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.Bonus; }
        if(state == State.Bonus && now >= bonusEndTime) { state = State.NormalSale; }
        calculateCurrentRate();
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver);
        if(msg.value.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            finalize();
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens);  
            super.buyTokens(beneficiary);
        }
    }

    function lastTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokensForFullBuy = weiAmount.mul(rate); 
        uint256 tokensToRefundFor = tokensForFullBuy.sub(tokensLeft);
        uint256 tokensRemaining = tokensForFullBuy.sub(tokensToRefundFor);
        uint256 weiAmountToRefund = tokensToRefundFor.div(rate);
        uint256 weiRemaining = weiAmount.sub(weiAmountToRefund);
        
         
        weiRaised = weiRaised.add(weiRemaining);

        token.mint(beneficiary, tokensRemaining);
        TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);

        forwardFundsAmount(weiRemaining);
        refundAmount(weiAmountToRefund);
    }

    function withdrawLockupTokens() canWithdrawLockup public {
        rate = 1000;
        token.mint(founders, foundersSum);
        token.finishMinting();
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalizeUpdateState() internal {
        if(now > endTimeNumber) { state = State.ShouldFinalize; }
        if(tokensLeft == 0) { state = State.ShouldFinalize; }
    }

    function finalize() public {
        finalizeUpdateState();
        require (!isFinalized);
        require (state == State.ShouldFinalize);

        finalization();
        Finalized();

        isFinalized = true;
    }

    function finalization() internal {
        endTime = block.timestamp;
         
        token.mint(ICOadvisor1, ICOadvisor1Sum);
        token.mint(hundredKInvestor, hundredKInvestorSum);
        token.mint(additionalPresaleInvestors, additionalPresaleInvestorsSum);
        token.mint(preSaleBotReserve, preSaleBotReserveSum);
        token.mint(ICOadvisor2, ICOadvisor2Sum);
        token.mint(team, teamSum);
        token.mint(bounty, bountySum);
        forwardFundsAmount(accumulated);
        tokensLeft = 0;
        state = State.Lockup;
    }
}