 

pragma solidity 0.4.24;

 
 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
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

 
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract HasNoEther is Ownable {

     
    constructor() public payable {
        require(msg.value == 0);
    }

     
    function() external {}

     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

 
contract HasNoContracts is Ownable {

     
    function reclaimContract(address contractAddr) external onlyOwner {
        Ownable contractInst = Ownable(contractAddr);
        contractInst.transferOwnership(owner);
    }
}

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
 
contract LockableToken is Ownable, StandardToken {

     
    bool public locked = true;

     
    mapping(address => bool) public lockExceptions;

    constructor() public {
         
        lockExceptions[this] = true;
    }

     
    function lock() public onlyOwner {
        locked = true;
    }

     
    function unlock() public onlyOwner {
        locked = false;
    }

     
     
     
    function setTradeException(address sender, bool _canTrade) public onlyOwner {
        lockExceptions[sender] = _canTrade;
    }

     
     
     
    function canTrade(address sender) public view returns(bool) {
        return !locked || lockExceptions[sender];
    }

     
    modifier whenNotLocked() {
        require(canTrade(msg.sender));
        _;
    }

    function transfer(address _to, uint256 _value)
                public whenNotLocked returns (bool) {

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
                public whenNotLocked returns (bool) {

        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value)
                public whenNotLocked returns (bool) {

        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue)
                public whenNotLocked returns (bool success) {

        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
                public whenNotLocked returns (bool success) {
                        
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
 
 
contract PLGToken is Ownable, NoOwner, LockableToken {
    using SafeMath for uint256;
    
     
     
     
    event Burn(address indexed burner, uint256 value);

    string public name = "PLGToken";
    string public symbol = "PLG";
    uint8 public decimals = 18;

     
    bool public initialized = false;

     
     
     
    function initialize(address[] addresses, uint256[] allocations) public onlyOwner {
        require(!initialized);
        require(addresses.length == allocations.length);
        initialized = true;

        for(uint i = 0; i<allocations.length; i += 1) {
            require(addresses[i] != address(0));
            require(allocations[i] > 0);
            balances[addresses[i]] = allocations[i];
            totalSupply_ = totalSupply_.add(allocations[i]);
        }
    }

     
     
    function burn(uint256 value) public {
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

}

 
 
contract Whitelist is Ownable {
    using SafeMath for uint256;

     
    struct Participant {
         
        uint256 bonusPercent;
         
        uint256 maxPurchaseAmount;
         
        uint256 weiContributed;
    }

     
    address public crowdsaleAddress;

     
     
    mapping(address => Participant) private participants;

     
     
    function setCrowdsale(address crowdsale) public onlyOwner {
        require(crowdsale != address(0));
        crowdsaleAddress = crowdsale;
    }

     
     
     
    function getBonusPercent(address user) public view returns(uint256) {
        return participants[user].bonusPercent;
    }

     
     
     
    function isValidPurchase(address user, uint256 weiAmount) public view returns(bool) {
        require(user != address(0));
        Participant storage participant = participants[user];
        if(participant.maxPurchaseAmount == 0) {
            return false;
        }
        return participant.weiContributed.add(weiAmount) <= participant.maxPurchaseAmount;
    }

     
     
     
     
     
     
    function addParticipant(address user, uint256 bonusPercent, uint256 maxPurchaseAmount) external onlyOwner {
        require(user != address(0));
        participants[user].bonusPercent = bonusPercent;
        participants[user].maxPurchaseAmount = maxPurchaseAmount;
    }

     
     
     
     
    function addParticipants(address[] users, uint256 bonusPercent, uint256 maxPurchaseAmount) external onlyOwner {
        
        for(uint i=0; i<users.length; i+=1) {
            require(users[i] != address(0));
            participants[users[i]].bonusPercent = bonusPercent;
            participants[users[i]].maxPurchaseAmount = maxPurchaseAmount;
        }
    }

     
     
    function revokeParticipant(address user) external onlyOwner {
        require(user != address(0));
        participants[user].maxPurchaseAmount = 0;
    }

     
     
    function revokeParticipants(address[] users) external onlyOwner {
        
        for(uint i=0; i<users.length; i+=1) {
            require(users[i] != address(0));
            participants[users[i]].maxPurchaseAmount = 0;
        }
    }

    function recordPurchase(address beneficiary, uint256 weiAmount) public {

        require(msg.sender == crowdsaleAddress);

        Participant storage participant = participants[beneficiary];
        participant.weiContributed = participant.weiContributed.add(weiAmount);
    }
    
}

 
 
 
contract PLGCrowdsale is Ownable {
    using SafeMath for uint256;

     
     
     
     
     
     
    event TokenPurchase(address indexed buyer, address indexed beneficiary,
                        uint256 value, uint256 tokenAmount, uint256 bonusAmount);

     
     
     
    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);

     
    event Closed();

     
    bool public saleActive;

     
    PLGToken plgToken;

     
    uint256 public startTime;

     
    uint256 public endTime;

     
    uint256 public tokensPerEther;

     
    uint256 public amountRaised;

     
    uint256 public minimumPurchase;

     
    address public bonusPool;

     
    Whitelist whitelist;

     
     
     
     
     
    constructor(address _plgToken, uint256 _startTime, uint256 _rate, uint256 _minimumPurchase) public {

        require(_startTime >= now);
        require(_rate > 0);
        require(_plgToken != address(0));

        startTime = _startTime;
        tokensPerEther = _rate;
        minimumPurchase = _minimumPurchase;
        plgToken = PLGToken(_plgToken);
    }

     
     
     
    function setBonusPool(address _bonusPool) public onlyOwner {
        bonusPool = _bonusPool;
    }

     
     
    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != address(0));
        whitelist = Whitelist(_whitelist);
    }

     
    function start() public onlyOwner {
        require(!saleActive);
        require(now > startTime);
        require(endTime == 0);
        require(plgToken.initialized());
        require(plgToken.lockExceptions(address(this)));
        require(bonusPool != address(0));
        require(whitelist != address(0));
        
        saleActive = true;
    }

     
     
    function end() public onlyOwner {
        require(saleActive);
        require(bonusPool != address(0));
        saleActive = false;
        endTime = now;

        withdrawTokens();

        owner.transfer(address(this).balance);
    }

     
    function withdrawEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokens() public onlyOwner {
        require(!saleActive);
        uint256 remainingTokens = plgToken.balanceOf(this);
        plgToken.transfer(bonusPool, remainingTokens);
    }

     
    function () external payable {
        buyTokensInternal(msg.sender);
    }

     
    function buyTokens() external payable {
        buyTokensInternal(msg.sender);
    }

     
     
    function buyTokensFor(address beneficiary) external payable onlyOwner {
        require(beneficiary != address(0));
        buyTokensInternal(beneficiary);
    }

     
     
    function buyTokensInternal(address beneficiary) private {
        require(whitelist != address(0));
        require(bonusPool != address(0));
        require(validPurchase(msg.value));
        uint256 weiAmount = msg.value;

         
        require(whitelist.isValidPurchase(beneficiary, weiAmount));

         
        uint256 tokens = weiAmount.mul(tokensPerEther);

         
        amountRaised = amountRaised.add(weiAmount);
         
        whitelist.recordPurchase(beneficiary, weiAmount);

        plgToken.transfer(beneficiary, tokens);

        uint256 bonusPercent = whitelist.getBonusPercent(beneficiary);
        uint256 bonusTokens = tokens.mul(bonusPercent) / 100;

        if(bonusTokens > 0) {
            plgToken.transferFrom(bonusPool, beneficiary, bonusTokens);
        }

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, bonusTokens);
    }

     
     
    function setExchangeRate(uint256 _tokensPerEther) external onlyOwner {

        emit ExchangeRateUpdated(tokensPerEther, _tokensPerEther);
        tokensPerEther = _tokensPerEther;
    }

     
     
    function validPurchase(uint256 amount) public view returns (bool) {
        bool nonZeroPurchase = amount != 0;
        bool isMinPurchase = (amount >= minimumPurchase);
        return saleActive && nonZeroPurchase && isMinPurchase;
    }

     
    function validCrowdsale() public view returns (bool) {
        return true;
    }
}