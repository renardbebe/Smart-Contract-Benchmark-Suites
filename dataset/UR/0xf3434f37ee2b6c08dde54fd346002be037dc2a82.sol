 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 


 
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

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
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

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
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
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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

contract TkoToken is MintableToken, BurnableToken, PausableToken {

    string public constant name = 'TkoToken';

    string public constant symbol = 'TKO';

    uint public constant decimals = 18;

}


 
 
 
contract TkoWhitelist is Ownable{

    using SafeMath for uint256;

     
    address public admin;

    mapping(address => uint256) internal totalIndividualWeiAmount;
    mapping(address => bool) internal whitelist;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);


     
    function TkoWhitelist (address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

     
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

     
    function changeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }


     
    function isWhitelisted(address _beneficiary) external view onlyOwnerOrAdmin returns (bool) {
        return whitelist[_beneficiary];
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = true;
    }

     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = false;
    }

     
    function getTotalIndividualWeiAmount(address _beneficiary) external view onlyOwnerOrAdmin returns (uint256) {
        return totalIndividualWeiAmount[_beneficiary];
    }

     
    function setTotalIndividualWeiAmount(address _beneficiary,uint256 _totalWeiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = _totalWeiAmount;
    }

     
    function addTotalIndividualWeiAmount(address _beneficiary,uint256 _weiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = totalIndividualWeiAmount[_beneficiary].add(_weiAmount);
    }

}


 
 
contract TkoTokenSale is FinalizableCrowdsale, Pausable {

    using SafeMath for uint256;

    uint256 public initialRate;
    uint256 public finalRate;

    uint256 public limitEther;
    uint256 public largeContribThreshold;
    uint256 public largeContribPercentage;

    TkoWhitelist internal whitelist;

     
    function TkoTokenSale (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _initialRate,
        uint256 _finalRate,
        uint256 _limitEther,
        uint256 _largeContribThreshold,
        uint256 _largeContribPercentage,
        address _wallet,
        TkoToken _token,
        TkoWhitelist _whitelist
    )
    public
    Crowdsale(_initialRate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    {
        initialRate = _initialRate;
        finalRate   = _finalRate;

        limitEther = _limitEther;
        largeContribThreshold  = _largeContribThreshold;
        largeContribPercentage = _largeContribPercentage;

        whitelist = _whitelist;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen whenNotPaused {

        uint256 limitWeiAmount = limitEther.mul(1 ether);
        require( whitelist.isWhitelisted(_beneficiary) ||
                    whitelist.getTotalIndividualWeiAmount(_beneficiary).add(_weiAmount) < limitWeiAmount);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

     
    function getCurrentRate() public view returns (uint256) {
        uint256 elapsedTime = now.sub(openingTime);
        uint256 timeRange = closingTime.sub(openingTime);
        uint256 rateRange = initialRate.sub(finalRate);
        return initialRate.sub(elapsedTime.mul(rateRange).div(timeRange));
    }


     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

        uint256 currentRate = getCurrentRate();
        uint256 tokenAmount = currentRate.mul(_weiAmount);

        uint256 largeContribThresholdWeiAmount = largeContribThreshold.mul(1 ether);
        if ( _weiAmount >= largeContribThresholdWeiAmount ) {
            tokenAmount = tokenAmount.mul(largeContribPercentage).div(100);
        }

        return tokenAmount;
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        whitelist.addTotalIndividualWeiAmount(_beneficiary, _weiAmount);
        super._updatePurchasingState(_beneficiary, _weiAmount);
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal onlyWhileOpen whenNotPaused {
         
         
        require(TkoToken(token).mint(_beneficiary, _tokenAmount));
    }

     
    function pauseCrowdsale() public onlyOwner whenNotPaused {
        TkoToken(token).pause();
        super.pause();
    }

     
    function unpauseCrowdsale() public onlyOwner whenPaused {
        TkoToken(token).unpause();
        super.unpause();
    }

     
    function evacuate() public onlyOwner {
        TkoToken(token).transferOwnership(wallet);
        whitelist.transferOwnership(wallet);
    }

     
    function finalization() internal {
        TkoToken(token).transferOwnership(wallet);
        whitelist.transferOwnership(wallet);
        super.finalization();
    }

}