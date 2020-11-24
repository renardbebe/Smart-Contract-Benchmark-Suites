 

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
  function totalSupply() public view returns (uint256);
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


contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}


 
contract RateToken is Ownable {
    using SafeMath for uint256;
     
    struct Discount {
         
        uint256 minTokens;
         
        uint256 percent;
    }
     
    mapping(address => Discount) private discounts;
     
    uint256 public rate;

    
    event RateSet(uint256 rate);

   
    function RateToken(uint256 _initialRate) public {
        setRate(_initialRate);
    }

    
    function setRate(uint _rateInWei) onlyOwner public {
        require(_rateInWei > 0);
        rate = _rateInWei;
        RateSet(rate);
    }

    
    
     
    function addDiscount(address _buyer, uint256 _minTokens, uint256 _percent) public onlyOwner returns (bool) { 
        require(_buyer != address(0));
        require(_minTokens > 0);
        require(_percent > 0);
        require(_percent < 100);
        Discount memory discount;
        discount.minTokens = _minTokens;
        discount.percent = _percent;
        discounts[_buyer] = discount;
        return true;
    }

    
    function removeDiscount(address _buyer) public onlyOwner {
        require(_buyer != address(0));
        removeExistingDiscount(_buyer);
    }

     
    function calculateWeiNeeded(address _buyer, uint _tokens) public view returns (uint256) {
        require(_buyer != address(0));
        require(_tokens > 0);

        Discount memory discount = discounts[_buyer];
        require(_tokens >= discount.minTokens);
        if (discount.minTokens == 0) {
            return _tokens.div(rate);
        }

        uint256 costOfTokensNormally = _tokens.div(rate);
        return costOfTokensNormally.mul(100 - discount.percent).div(100);

    }
    
     
    function removeExistingDiscount(address _buyer) internal {
        delete(discounts[_buyer]);
    }

     
    function calculateTokens(address _buyer, uint256 _buyerAmountInWei) internal view returns (uint256) {
        Discount memory discount = discounts[_buyer];
        if (discount.minTokens == 0) {
            return _buyerAmountInWei.mul(rate);
        }

        uint256 normalTokens = _buyerAmountInWei.mul(rate);
        uint256 discountBonus = normalTokens.mul(discount.percent).div(100);
        uint256 tokens = normalTokens + discountBonus;
        require(tokens >= discount.minTokens);
        return tokens;
    }  
}



 
contract CaerusToken is RateToken, PausableToken, DetailedERC20 {
    mapping (address => uint256) public contributions;
    uint256 public tokenSold = 0; 
    uint256 public weiRaised = 0; 
    address transferAddress;
    
    mapping (address => TokenVesting) public vestedTokens;

    event TokensBought(address indexed buyer, uint256 tokens);
    event Contribution(address indexed buyer, uint256 amountInWei);
    event VestedTokenCreated(address indexed beneficiary, uint256 duration, uint256 tokens);
    event TokensSpent(address indexed tokensHolder, uint256 tokens);

    function CaerusToken(address _transferAddress, uint _initialRate) public RateToken(_initialRate) DetailedERC20("Caerus Token", "CAER", 18) {
        totalSupply_ = 73000000 * 10 ** 18;
        transferAddress = _transferAddress;
        balances[owner] = totalSupply_;
  	}
     
    function setTransferAddress(address _transferAddress) onlyOwner public {
        transferAddress = _transferAddress;
    }
     
    function() payable public {
        buyTokens();
    }

     
    function buyTokens() payable public whenNotPaused {
        require(msg.value > 0);
        
        uint256 tokens = calculateTokens(msg.sender, msg.value);
        transferTokens(owner, msg.sender, tokens);

        markTokenSold(tokens);
        markContribution();
        removeExistingDiscount(msg.sender);
        transferAddress.transfer(msg.value);
        TokensBought(msg.sender, tokens);
    }

     
     
    function markTransferTokens(address _to, uint256 _tokens) onlyOwner public returns (bool) {
        require(_to != address(0));

        transferTokens(owner, _to, _tokens);
        markTokenSold(_tokens);
        return true;
    }

     
    function createVestedToken(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _tokens) onlyOwner public returns (bool) {
        TokenVesting vestedToken = new TokenVesting(_beneficiary, _start, _cliff, _duration, false);
        vestedTokens[_beneficiary] = vestedToken;
        address vestedAddress = address(vestedToken);
        transferTokens(owner, vestedAddress, _tokens);
        VestedTokenCreated(_beneficiary, _duration, _tokens);
        return true;
    }

     
    function spendToken(uint256 _tokens) public returns (bool) {
        transferTokens(msg.sender, owner, _tokens);
        TokensSpent(msg.sender, _tokens);
        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool) {
         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        return super.approve(_spender, _value);
    }

     
    function transferTokens(address _from, address _to, uint256 _tokens) private {
        require(_tokens > 0);
        require(balances[_from] >= _tokens);
        
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        Transfer(_from, _to, _tokens);
    }

     
    function markContribution() private {
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        weiRaised = weiRaised.add(msg.value);
        Contribution(msg.sender, msg.value);
    }

     
    function markTokenSold(uint256 _tokens) private {
        tokenSold = tokenSold.add(_tokens);
    }
    
         
    function transferAnyCaerusToken(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        transferTokens(_tokenAddress, owner, _tokens);
        return true;
    }
}