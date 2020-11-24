 

pragma solidity ^0.4.13;

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
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
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

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function decreaseApproval (address _spender, uint _subtractedValue)
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

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
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

contract StampifyToken is MintableToken, PausableToken, BurnableToken {  

    string public constant name = "Stampify Token";
    string public constant symbol = "STAMP";
    uint8 public constant decimals = 18;

    function StampifyToken() {
        pause();
    }
}

contract TokenCappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;
    uint256 public tokenSold;

    function TokenCappedCrowdsale(uint256 _cap) {
        require(_cap > 0);
        cap = _cap;
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiToTokens(weiAmount, now);
        require(tokenSold.add(tokens) <= cap);
        
         
        weiRaised = weiRaised.add(weiAmount);
        tokenSold = tokenSold.add(tokens);

        token.mint(beneficiary, tokens);
        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens);

        forwardFunds();
    }

    function weiToTokens(uint256 weiAmount, uint256 time) internal returns (uint256) {
        uint256 _rate = getRate(time);
        return weiAmount.mul(_rate);
    }

     
     
    function getRate(uint256 time) internal returns (uint256) {
        return rate;
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = tokenSold >= cap;
        return super.hasEnded() || capReached;
    }
}

contract StampifyTokenSale is TokenCappedCrowdsale, RefundableCrowdsale, Pausable {
    using SafeMath for uint256;

     
    uint256 constant private BIG_BUYER_THRESHOLD = 40 * 10**18;  
    uint256 constant public RESERVE_AMOUNT = 25000000 * 10**18;  

     
    modifier isValidDataString(uint256 weiAmount, bytes data) {
        if (weiAmount > BIG_BUYER_THRESHOLD) {
            require(bytesToBytes32(data) == dataWhitelist[1]);
        } else {
            require(bytesToBytes32(data) == dataWhitelist[0]);
        }
        _;
    }

     
    struct TeamMember {
        address wallet;  
        address vault;    
        uint64 shareDiv;  
    }
    
     
    uint64[4] private salePeriods;
    bytes32[2] private dataWhitelist;
    uint8 private numTeamMembers;
    mapping (uint => address) private memberLookup;

     
    mapping (address => TeamMember) public teamMembers;   

    function StampifyTokenSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _cap,
        address _wallet,
        uint64[4] _salePeriods,
        bytes32[2] _dataWhitelist
      )
      TokenCappedCrowdsale(_cap)
      FinalizableCrowdsale()
      RefundableCrowdsale(_goal)
      Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_goal.mul(_rate) <= _cap);

        for (uint8 i = 0; i < _salePeriods.length; i++) {
            require(_salePeriods[i] > 0);
        }
        salePeriods = _salePeriods;
        dataWhitelist = _dataWhitelist;
    }

    function createTokenContract() internal returns (MintableToken) {
        return new StampifyToken();
    }

    function () whenNotPaused isValidDataString(msg.value, msg.data) payable {
        super.buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused isValidDataString(msg.value, msg.data) public payable {
        super.buyTokens(beneficiary);
    }

     
    function getRate(uint256 time) internal returns (uint256) {
        if (time <= salePeriods[0]) {
            return 750;
        }
        
        if (time <= salePeriods[1]) {
            return 600;
        }

        if (time <= salePeriods[2]) {
            return 575;
        }

        if (time <= salePeriods[3]) {
            return 525;
        }

        return rate;
    }

    function setTeamVault(address _wallet, address _vault, uint64 _shareDiv) onlyOwner public returns (bool) {
        require(now < startTime);  
        require(_wallet != address(0));
        require(_vault != address(0));
        require(_shareDiv > 0);

        require(numTeamMembers + 1 <= 8);

        memberLookup[numTeamMembers] = _wallet;
        teamMembers[_wallet] = TeamMember(_wallet, _vault, _shareDiv);
        numTeamMembers++;

        return true;
    }

    function getTeamVault(address _wallet) constant public returns (address) {
        require(_wallet != address(0));
        return teamMembers[_wallet].vault;
    }

    function finalization() internal {
        if (goalReached()) {
            bool capReached = tokenSold >= cap;
            if (!capReached) {
                uint256 tokenUnsold = cap.sub(tokenSold);
                 
                require(token.mint(this, tokenUnsold));
                StampifyToken(token).burn(tokenUnsold);
            }
          
            uint256 tokenReserved = RESERVE_AMOUNT;
          
            for (uint8 i = 0; i < numTeamMembers; i++) {
                TeamMember memory member = teamMembers[memberLookup[i]];
                if (member.vault != address(0)) {
                    var tokenAmount = tokenSold.div(member.shareDiv);
                    require(token.mint(member.vault, tokenAmount));
                    tokenReserved = tokenReserved.sub(tokenAmount);
                }
            }

             
            require(token.mint(wallet, tokenReserved));

             
            require(token.finishMinting());
            StampifyToken(token).unpause();
        }

        super.finalization();
    }

    function bytesToBytes32(bytes memory source) returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}