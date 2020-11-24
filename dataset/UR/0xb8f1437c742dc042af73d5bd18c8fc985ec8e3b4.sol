 

pragma solidity ^0.4.13;

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

contract CryptoHuntIco is Ownable {
     
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

    uint256 public softcap;
    uint256 public hardcap;

     
    RefundVault public vault;

     
    uint256 public startTime;
    uint256 public endTime;
    uint256 public whitelistEndTime;
     
    uint256 public duration;
    uint256 public wlDuration;

     
    address[] public tokenBuyersArray;
     
    uint256 public tokenBuyersAmount;
     
    mapping(address => uint256) public tokenBuyersMapping;
     
    mapping(address => uint256) public tokenBuyersFraction;

     
    mapping(address => uint256) public tokenBuyersRemaining;

     
    mapping(address => uint256) public tokenBuyersContributed;

     
    mapping(address => bool) public wl;

     
    bool public isFinalized = false;

     
    bool public forcedRefund = false;

     
    event Finalized();

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Whitelisted(address addr, bool status);

     
    function CryptoHuntIco(uint256 _durationSeconds, uint256 _wlDurationSeconds, address _wallet, address _token) public {
        require(_durationSeconds > 0);
        require(_wlDurationSeconds > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        duration = _durationSeconds;
        wlDuration = _wlDurationSeconds;

        wallet = _wallet;
        vault = new RefundVault(wallet);

        token = ERC20(_token);
        owner = msg.sender;
    }

     
    function changeTokenAddress(address _token) external onlyOwner {
        token = ERC20(_token);
    }

     
    function setRateAndStart(uint256 _rate, uint256 _softcap, uint256 _hardcap) external onlyOwner {

        require(_rate > 0 && rate < 1);
        require(_softcap > 0);
        require(_hardcap > 0);
        require(_softcap < _hardcap);
        rate = _rate;

        softcap = _softcap;
        hardcap = _hardcap;

 
 
 
            startTime = 1519941600;
 

        whitelistEndTime = startTime.add(wlDuration * 1 seconds);
        endTime = whitelistEndTime.add(duration * 1 seconds);
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function whitelistAddresses(address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
             
            Whitelisted(users[i], true);
        }
    }

     
    function unwhitelistAddresses(address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = false;
            Whitelisted(users[i], false);
        }
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase(beneficiary));

        uint256 weiAmount = msg.value;

         
        uint256 tokenAmount = getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        tokenBuyersContributed[beneficiary] = tokenBuyersContributed[beneficiary].add(weiAmount);

         
        if (tokenBuyersMapping[beneficiary] == 0) {
            tokenBuyersArray.push(beneficiary);
        }
         
        tokenBuyersMapping[beneficiary] = tokenBuyersMapping[beneficiary].add(tokenAmount);
         
        tokenBuyersAmount = tokenBuyersAmount.add(tokenAmount);

         
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);

         
        forwardFunds();
    }

     
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate).div(1e6);
    }

     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function validPurchase(address _beneficiary) internal view returns (bool) {
         
        bool nonZeroPurchase = msg.value > 0;

         
        bool withinCap = weiRaised.add(msg.value) <= hardcap;

         
        bool withinPeriod = now >= whitelistEndTime && now <= endTime;

         
        bool whitelisted = now >= startTime && now <= whitelistEndTime && tokenBuyersContributed[_beneficiary].add(msg.value) <= 15 ether && wl[msg.sender];

        bool superbuyer = msg.sender == 0xEa17f66d28d11a7C1ECd8F591d136795130901A7;

        return withinCap && (superbuyer || withinPeriod || whitelisted) && nonZeroPurchase;
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require((weiRaised == hardcap) || now > endTime);

        finalization();
        Finalized();

        isFinalized = true;

    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached() || forcedRefund);

        vault.refund(msg.sender);
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= softcap;
    }

     
    function forceRefundState() external onlyOwner {
        vault.enableRefunds();
        token.transfer(owner, token.balanceOf(address(this)));
        Finalized();
        isFinalized = true;
        forcedRefund = true;
    }

     
    function finalization() internal {

        if (goalReached()) {
             
            vault.close();
        } else {
            vault.enableRefunds();
            token.transfer(owner, token.balanceOf(address(this)));
        }
    }

     
    function claimTokens(address _beneficiary) public {
        require(isFinalized);
        require(weeksFromEndPlusMonth() > 0);

         
        fractionalize(_beneficiary);

         
        require(tokenBuyersMapping[_beneficiary] > 0 && tokenBuyersRemaining[_beneficiary] > 0);

         
 
        uint256 w = weeksFromEndPlusMonth();
        if (w > 8) {
            w = 8;
        }
         
        uint256 totalDueByNow = w.mul(tokenBuyersFraction[_beneficiary]);

         
        uint256 totalWithdrawnByNow = totalWithdrawn(_beneficiary);

        if (totalDueByNow > totalWithdrawnByNow) {
            uint256 diff = totalDueByNow.sub(totalWithdrawnByNow);
            if (diff > tokenBuyersRemaining[_beneficiary]) {
                diff = tokenBuyersRemaining[_beneficiary];
            }
            token.transfer(_beneficiary, diff);
            tokenBuyersRemaining[_beneficiary] = tokenBuyersRemaining[_beneficiary].sub(diff);
        }
    }

    function claimMyTokens() external {
        claimTokens(msg.sender);
    }

    function massClaim() external onlyOwner {
        massClaimLimited(0, tokenBuyersArray.length - 1);
    }

    function massClaimLimited(uint start, uint end) public onlyOwner {
        for (uint i = start; i <= end; i++) {
            if (tokenBuyersRemaining[tokenBuyersArray[i]] > 0) {
                claimTokens(tokenBuyersArray[i]);
            }
        }
    }

     
    function fractionalize(address _beneficiary) internal {
        require(tokenBuyersMapping[_beneficiary] > 0);
        if (tokenBuyersFraction[_beneficiary] == 0) {
            tokenBuyersRemaining[_beneficiary] = tokenBuyersMapping[_beneficiary];
             
            tokenBuyersFraction[_beneficiary] = percent(tokenBuyersMapping[_beneficiary], 8, 0);
        }
    }

     
    function totalWithdrawn(address _beneficiary) public view returns (uint256) {
        if (tokenBuyersFraction[_beneficiary] == 0) {
            return 0;
        }
        return tokenBuyersMapping[_beneficiary].sub(tokenBuyersRemaining[_beneficiary]);
    }

     
    function weeksFromEnd() public view returns (uint256){
        require(now > endTime);
        return percent(now - endTime, 604800, 0);
         
    }

    function weeksFromEndPlusMonth() public view returns (uint256) {
        require(now > (endTime + 30 days));
        return percent(now - endTime + 30 days, 604800, 0);
         
    }

     
    function withdrawRest() external onlyOwner {
        require(weeksFromEnd() > 9);
        token.transfer(owner, token.balanceOf(address(this)));
    }

     
    function percent(uint numerator, uint denominator, uint precision) internal pure returns (uint256 quotient) {
         
        uint _numerator = numerator * 10 ** (precision + 1);
         
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function unsoldTokens() public view returns (uint) {
        if (token.balanceOf(address(this)) == 0) {
            return 0;
        }
        return token.balanceOf(address(this)) - tokenBuyersAmount;
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
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

   
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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