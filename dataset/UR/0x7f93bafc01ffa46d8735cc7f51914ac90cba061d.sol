 

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

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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

 

contract Proxy is Ownable, Destructible, Pausable {
     
    Crowdsale public crowdsale;

    function Proxy(Crowdsale _crowdsale) public {
        setCrowdsale(_crowdsale);
    }

    function setCrowdsale(address _crowdsale) onlyOwner public {
        require(_crowdsale != address(0));
        crowdsale = Crowdsale(_crowdsale);
    }

    function () external whenNotPaused payable {
         
        crowdsale.buyTokens.value(msg.value)(msg.sender);
    }
}

 

contract Referral is Ownable, Destructible, Pausable {
    using SafeMath for uint256;

    Crowdsale public crowdsale;
    Token public token;

    address public beneficiary;

    function Referral(address _crowdsale, address _token, address _beneficiary) public {
        setCrowdsale(_crowdsale);
        setToken(_token);
        setBeneficiary(_beneficiary);
    }

    function setCrowdsale(address _crowdsale) onlyOwner public {
        require(_crowdsale != address(0));
        crowdsale = Crowdsale(_crowdsale);
    }

    function setToken(address _token) onlyOwner public {
        require(_token != address(0));
        token = Token(_token);
    }

    function setBeneficiary(address _beneficiary) onlyOwner public {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
    }

    function () external whenNotPaused payable {
        uint256 tokens = crowdsale.buyTokens.value(msg.value)(this);

        uint256 baseAmount = crowdsale.getBaseAmount(msg.value);
        uint256 refTokens = baseAmount.div(10);

         
        token.transfer(beneficiary, refTokens);

         
        tokens = tokens.sub(refTokens);

         
        token.transfer(msg.sender, tokens);
    }
}

 

contract Token is StandardToken, BurnableToken, DetailedERC20, Destructible {
    function Token(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply)
        DetailedERC20(_name, _symbol, _decimals) public
        {

         
        _totalSupply = _totalSupply;

        totalSupply_ = _totalSupply;

         
        balances[msg.sender] = totalSupply_;

         
        Transfer(0x0, msg.sender, totalSupply_);
    }
}

 

contract Crowdsale is Ownable, Pausable, Destructible {
    using SafeMath for uint256;

    struct Vault {
        uint256 tokenAmount;
        uint256 weiValue;
        address referralBeneficiary;
    }

    struct CustomContract {
        bool isReferral;
        bool isSpecial;
        address referralAddress;
    }

     
    bool crowdsaleConcluded = false;

     
    Token public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 minimum_invest = 100000000000000;

     
    uint256 week_1 = 20;
    uint256 week_2 = 15;
    uint256 week_3 = 10;
    uint256 week_4 = 0;

     
    uint256 week_special_1 = 40;
    uint256 week_special_2 = 15;
    uint256 week_special_3 = 10;
    uint256 week_special_4 = 0;

    uint256 week_referral_1 = 25;
    uint256 week_referral_2 = 20;
    uint256 week_referral_3 = 15;
    uint256 week_referral_4 = 5;

     
    mapping (address => CustomContract) public customBonuses;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;
    uint256 public tokensSold;

     
    uint256 public tokensOnHold;

     
    mapping(address => Vault) ballers;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        token = Token(_token);
    }

     
    function () external whenNotPaused payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public whenNotPaused payable returns (uint256) {
        require(!hasEnded());

         
        require(minimum_invest <= msg.value);

        address beneficiary = _beneficiary;

        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        var tokens = getTokenAmount(weiAmount);

         
        bool isLess = false;
        if (!hasEnoughTokensLeft(weiAmount)) {
            isLess = true;

            uint256 percentOfValue = tokensLeft().mul(100).div(tokens);
            require(percentOfValue <= 100);

            tokens = tokens.mul(percentOfValue).div(100);
            weiAmount = weiAmount.mul(percentOfValue).div(100);

             
            beneficiary.transfer(msg.value.sub(weiAmount));
        }

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        if ((11 ether) <= weiAmount) {
             
             

            tokensOnHold = tokensOnHold.add(tokens);

            ballers[beneficiary].tokenAmount += tokens;
            ballers[beneficiary].weiValue += weiAmount;
            ballers[beneficiary].referralBeneficiary = address(0);

             
            if (customBonuses[msg.sender].isReferral == true) {
              ballers[beneficiary].referralBeneficiary = customBonuses[msg.sender].referralAddress;
            }

            return (0);
        }

        token.transfer(beneficiary, tokens);

        forwardFunds(weiAmount);

        if (isLess == true) {
          return (tokens);
        }
        return (tokens);
    }

     

    function viewFunds(address _wallet) public view returns (uint256) {
        return ballers[_wallet].tokenAmount;
    }

    function releaseFunds(address _wallet) onlyOwner public {
        require(ballers[_wallet].tokenAmount > 0);
        require(ballers[_wallet].weiValue <= this.balance);

         
        uint256 tokens = ballers[_wallet].tokenAmount;

         
        tokensOnHold = tokensOnHold.sub(tokens);

         
        forwardFunds(ballers[_wallet].weiValue);

         
        if (ballers[_wallet].referralBeneficiary != address(0)) {
          uint256 refTokens = tokens.mul(10).div(100);
          token.transfer(ballers[_wallet].referralBeneficiary, refTokens);

           
          tokens = tokens.sub(refTokens);
        }

         
        token.transfer(_wallet, tokens);


         
        ballers[_wallet].tokenAmount = 0;
        ballers[_wallet].weiValue = 0;
    }

    function refundFunds(address _wallet) onlyOwner public {
        require(ballers[_wallet].tokenAmount > 0);
        require(ballers[_wallet].weiValue <= this.balance);

         
        tokensOnHold = tokensOnHold.sub(ballers[_wallet].tokenAmount);

        _wallet.transfer(ballers[_wallet].weiValue);

        weiRaised = weiRaised.sub(ballers[_wallet].weiValue);
        tokensSold = tokensSold.sub(ballers[_wallet].tokenAmount);

        ballers[_wallet].tokenAmount = 0;
        ballers[_wallet].weiValue = 0;
    }

     

    function addOldInvestment(address _beneficiary, uint256 _weiAmount, uint256 _tokensWithDecimals) onlyOwner public {
      require(_beneficiary != address(0));

       
      weiRaised = weiRaised.add(_weiAmount);
      tokensSold = tokensSold.add(_tokensWithDecimals);

      token.transfer(_beneficiary, _tokensWithDecimals);

      TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokensWithDecimals);
    }

    function setCustomBonus(address _contract, bool _isReferral, bool _isSpecial, address _referralAddress) onlyOwner public {
      require(_contract != address(0));

      customBonuses[_contract] = CustomContract({
          isReferral: _isReferral,
          isSpecial: _isSpecial,
          referralAddress: _referralAddress
      });
    }

    function addOnHold(uint256 _amount) onlyOwner public {
      tokensOnHold = tokensOnHold.add(_amount);
    }

    function subOnHold(uint256 _amount) onlyOwner public {
      tokensOnHold = tokensOnHold.sub(_amount);
    }

    function setMinInvestment(uint256 _investment) onlyOwner public {
      require(_investment > 0);
      minimum_invest = _investment;
    }

    function changeEndTime(uint256 _endTime) onlyOwner public {
        require(_endTime > startTime);
        endTime = _endTime;
    }

    function changeStartTime(uint256 _startTime) onlyOwner public {
        require(endTime > _startTime);
        startTime = _startTime;
    }

    function setWallet(address _wallet) onlyOwner public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    function setToken(address _token) onlyOwner public {
        require(_token != address(0));
        token = Token(_token);
    }

     

    function endSale() onlyOwner public {
       
      crowdsaleConcluded = true;

       
      token.burn(token.balanceOf(this));
    }

     

    function evacuateTokens(address _wallet) onlyOwner public {
      require(_wallet != address(0));
      token.transfer(_wallet, token.balanceOf(this));
    }

     

     
    function hasEnded() public view returns (bool) {
        return now > endTime || token.balanceOf(this) == 0 || crowdsaleConcluded;
    }

    function getBaseAmount(uint256 _weiAmount) public view returns (uint256) {
        return _weiAmount.mul(rate);
    }

     
    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokens = getBaseAmount(_weiAmount);
        uint256 percentage = 0;

          
        if (customBonuses[msg.sender].isSpecial == true) {

          if ( startTime <= now && now < startTime + 7 days ) {
            percentage = week_special_1;
          } else if ( startTime + 7 days <= now && now < startTime + 14 days ) {
            percentage = week_special_2;
          } else if ( startTime + 14 days <= now && now < startTime + 21 days ) {
            percentage = week_special_3;
          } else if ( startTime + 21 days <= now && now <= endTime ) {
            percentage = week_special_4;
          }

         
        } else {

          if ( startTime <= now && now < startTime + 7 days ) {
            percentage = week_1;
          } else if ( startTime + 7 days <= now && now < startTime + 14 days ) {
            percentage = week_2;
          } else if ( startTime + 14 days <= now && now < startTime + 21 days ) {
            percentage = week_3;
          } else if ( startTime + 21 days <= now && now <= endTime ) {
            percentage = week_4;
          }

           
          if (customBonuses[msg.sender].isReferral == true) {
            percentage += 15;  
          }

        }

         
        if (msg.value >= 50 ether) {
          percentage += 80;
        } else if (msg.value >= 30 ether) {
          percentage += 70;
        } else if (msg.value >= 10 ether) {
          percentage += 50;
        } else if (msg.value >= 5 ether) {
          percentage += 30;
        } else if (msg.value >= 3 ether) {
          percentage += 10;
        }

        tokens += tokens.mul(percentage).div(100);

        assert(tokens > 0);

        return (tokens);
    }

     
    function forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function tokensLeft() public view returns (uint256) {
        return token.balanceOf(this).sub(tokensOnHold);
    }

    function hasEnoughTokensLeft(uint256 _weiAmount) public payable returns (bool) {
        return tokensLeft().sub(_weiAmount) >= getBaseAmount(_weiAmount);
    }
}