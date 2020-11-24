 

pragma solidity ^0.4.21;

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

contract MintableToken is StandardToken, Ownable {
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
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

  function () external payable {
      buyTokens(msg.sender);
  }
   
  function buyTokens(address _beneficiary) payable public  {
    uint weiAmount;
    uint changeEthBack;

    (weiAmount,changeEthBack) = _prePurchaseAmount(msg.value);
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds(weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
    if (changeEthBack > 0) {
        msg.sender.transfer(changeEthBack);
    }
  }

   
   
   

   
  function _prePurchaseAmount(uint _weiAmount) internal returns(uint , uint) {
       return (_weiAmount,0);
  }
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds(uint _value) internal {
    wallet.transfer(_value);
  }
}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {
  event LogAddedToWhiteList(address indexed _address);
  event LogRemovedFromWhiteList(address indexed _address);

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    emit LogAddedToWhiteList(_beneficiary);
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit LogAddedToWhiteList(_beneficiaries[i]);
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    emit LogRemovedFromWhiteList(_beneficiary);
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

contract TimedCrowdsale is Crowdsale {
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

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

contract BuyLimits {
    event LogLimitsChanged(uint _minBuy, uint _maxBuy);

     
    uint public minBuy;  
    uint public maxBuy;  

     
    modifier isWithinLimits(uint _amount) {
        require(withinLimits(_amount));
        _;
    }

     
    function BuyLimits(uint _min, uint  _max) public {
        _setLimits(_min, _max);
    }

     
    function withinLimits(uint _value) public view returns(bool) {
        if (maxBuy != 0) {
            return (_value >= minBuy && _value <= maxBuy);
        }
        return (_value >= minBuy);
    }

     
    function _setLimits(uint _min, uint _max) internal {
        if (_max != 0) {
            require (_min <= _max);  
        }
        minBuy = _min;
        maxBuy = _max;
        emit LogLimitsChanged(_min, _max);
    }
}

contract BuyLimitsCrowdsale is BuyLimits,Crowdsale {

     
    function BuyLimitsCrowdsale(uint _min, uint  _max)
    public
    BuyLimits(_min,_max)
    {
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWithinLimits(_weiAmount) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

contract DAOstackSale is MintedCrowdsale, CappedCrowdsale, FinalizableCrowdsale, BuyLimitsCrowdsale, WhitelistedCrowdsale {
    using SafeMath for uint256;

    uint public maxGasPrice;

     
    function DAOstackSale(
        uint _openingTime,
        uint _closingTime,
        uint _rate,
        address _wallet,
        uint _cap,
        uint _minBuy,
        uint _maxBuy,
        uint _maxGasPrice,
        MintableToken _token
    ) public
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap)
        BuyLimitsCrowdsale(_minBuy, _maxBuy)
        TimedCrowdsale(_openingTime,_closingTime)
    {
        maxGasPrice = _maxGasPrice;
    }

     
    function drain() onlyOwner public {
        wallet.transfer((address(this)).balance);
    }

     
    function drainTokens(StandardToken _token) onlyOwner public {
        _token.transfer(wallet, _token.balanceOf(address(this)));
    }

    function hasClosed() public view returns (bool) {
        return (capReached() || super.hasClosed());
    }

     
    function finalization() internal {
        MintableToken(token).transferOwnership(wallet);
        super.finalization();
    }

     
    function _prePurchaseAmount(uint _weiAmount) internal returns(uint weiAmount, uint changeEthBack) {
        if (weiRaised.add(_weiAmount) > cap) {
            changeEthBack = weiRaised.add(_weiAmount) - cap;
            weiAmount = _weiAmount.sub(changeEthBack);
            if (weiAmount < minBuy) {
                _setLimits(weiAmount,maxBuy);
            }
        } else {
            weiAmount = _weiAmount;
        }
    }


     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
      require(tx.gasprice <= maxGasPrice);
      super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}