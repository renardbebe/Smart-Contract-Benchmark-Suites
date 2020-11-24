 

pragma solidity ^0.4.18;

 

interface Vault {
  function sendFunds() payable public returns (bool);
  event Transfer(address beneficiary, uint256 amountWei);
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

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract WebcoinToken is CappedToken {
	string constant public name = "Webcoin";
	string constant public symbol = "WEB";
	uint8 constant public decimals = 18;
    address private miningWallet;

	function WebcoinToken(uint256 _cap, address[] _wallets) public CappedToken(_cap) {
        require(_wallets[0] != address(0) && _wallets[1] != address(0) && _wallets[2] != address(0) && _wallets[3] != address(0) && _wallets[4] != address(0) && _wallets[5] != address(0) && _wallets[6] != address(0));
        
        uint256 mil = (10**6);
        uint256 teamSupply = mil.mul(5).mul(1 ether);
        uint256 miningSupply = mil.mul(15).mul(1 ether);
        uint256 marketingSupply = mil.mul(10).mul(1 ether);
        uint256 developmentSupply = mil.mul(10).mul(1 ether);
        uint256 legalSupply = mil.mul(2).mul(1 ether);
        uint256 functionalCostsSupply = mil.mul(2).mul(1 ether);
        uint256 earlyAdoptersSupply = mil.mul(1).mul(1 ether);
        miningWallet = _wallets[1];
        mint(_wallets[0], teamSupply);
        mint(_wallets[1], miningSupply);
        mint(_wallets[2], marketingSupply);
        mint(_wallets[3], developmentSupply);
        mint(_wallets[4], legalSupply);
        mint(_wallets[5], functionalCostsSupply);
        mint(_wallets[6], earlyAdoptersSupply);
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mint(miningWallet, cap.sub(totalSupply()));
        return super.finishMinting();
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

 

 
contract WebcoinCrowdsale is CappedCrowdsale, TimedCrowdsale, FinalizableCrowdsale, Pausable {
  Vault public vaultWallet;
  WebcoinToken token;
  address[] wallets;
  uint256[] rates;
  uint256 public softCap;
  uint256 public initialSupply = 0;
  
  function WebcoinCrowdsale(uint256 _openingTime, uint256 _closingTime, uint256[] _rates, uint256 _softCap, uint256 _cap, address _vaultAddress, address[] _wallets, ERC20 _token) public
    CappedCrowdsale(_cap)
    TimedCrowdsale(_openingTime, _closingTime)
    FinalizableCrowdsale()
    Crowdsale(_rates[0], _wallets[0], _token) 
    {
        require(_softCap > 0);
        require(_wallets[1] != address(0) && _wallets[2] != address(0) && _wallets[3] != address(0) && _vaultAddress != address(0));
        require(_rates[1] > 0 && _rates[2] > 0 && _rates[3] > 0 && _rates[4] > 0 && _rates[5] > 0 && _rates[6] > 0 && _rates[7] > 0);
        wallets = _wallets;
        vaultWallet = Vault(_vaultAddress);
        rates = _rates;
        token = WebcoinToken(_token);
        softCap = _softCap;
        initialSupply = token.totalSupply();
    }
  
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_weiAmount <= 1000 ether);
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
  
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.mint(_beneficiary, _tokenAmount);
  }
  
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    uint256 crowdsaleSupply = token.totalSupply().sub(initialSupply);
    uint256 mil = (10**6) * 1 ether;
    if (crowdsaleSupply >= mil.mul(2) && crowdsaleSupply < mil.mul(5)) {
      rate = rates[1];
    } else if (crowdsaleSupply >= mil.mul(5) && crowdsaleSupply < mil.mul(11)) {
      rate = rates[2];
    } else if (crowdsaleSupply >= mil.mul(11) && crowdsaleSupply < mil.mul(16)) {
      rate = rates[3];
    } else if (crowdsaleSupply >= mil.mul(16) && crowdsaleSupply < mil.mul(20)) {
      rate = rates[4];
    } else if (crowdsaleSupply >= mil.mul(20) && crowdsaleSupply < mil.mul(22)) {
      rate = rates[5];
    } else if (crowdsaleSupply >= mil.mul(22) && crowdsaleSupply < mil.mul(24)) {
      rate = rates[6];
    } else if (crowdsaleSupply >= mil.mul(24)) {
      rate = rates[7];
    }
  }
  
  function ceil(uint256 a, uint256 m) private pure returns (uint256) {
    return ((a + m - 1) / m) * m;
  }
  
  function _forwardFunds() internal {
    if (softCapReached()) {
        uint256 totalInvestment = msg.value;
        uint256 miningFund = totalInvestment.mul(10).div(100);
        uint256 teamFund = totalInvestment.mul(15).div(100);
        uint256 devFund = totalInvestment.mul(35).div(100);
        uint256 marketingFund = totalInvestment.mul(40).div(100);
        require(wallets[0].send(miningFund) && wallets[1].send(teamFund) && wallets[2].send(devFund) && wallets[3].send(marketingFund));
    } else {
        require(vaultWallet.sendFunds.value(msg.value)());
    }
  }
  
  function softCapReached() public view returns (bool) {
    return weiRaised > softCap;
  }
  
  function capReached() public view returns (bool) {
    return ceil(token.totalSupply(),1 ether).sub(initialSupply) >= cap;
  }
  
  function hasClosed() public view returns (bool) {
    return capReached() || super.hasClosed(); 
  }
  
  function pause() onlyOwner whenNotPaused public {
    token.transferOwnership(owner);
    super.pause();
  }
  
  function finalization() internal {
    token.finishMinting();
    token.transferOwnership(owner);  
  }
}