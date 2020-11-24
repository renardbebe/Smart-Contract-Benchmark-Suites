 

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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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
    totalSupply = totalSupply.add(_amount);
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

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
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

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
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

 

contract KeyrptoToken is MintableToken, Pausable {
  string public constant name = "Keyrpto Token";
  string public constant symbol = "KYT";
  uint8 public constant decimals = 18;
  uint256 internal constant MILLION_TOKENS = 1e6 * 1e18;

  address public teamWallet;
  bool public teamTokensMinted = false;
  uint256 public circulationStartTime;

  event Burn(address indexed burnedFrom, uint256 value);

  function KeyrptoToken() public {
    paused = true;
  }

  function setTeamWallet(address _teamWallet) public onlyOwner canMint {
    require(teamWallet == address(0));
    require(_teamWallet != address(0));

    teamWallet = _teamWallet;
  }

  function mintTeamTokens(uint256 _extraTokensMintedDuringPresale) public onlyOwner canMint {
    require(!teamTokensMinted);

    teamTokensMinted = true;
    mint(teamWallet, (490 * MILLION_TOKENS).sub(_extraTokensMintedDuringPresale));
  }

   
  function unpause() onlyOwner whenPaused public {
    if (circulationStartTime == 0) {
      circulationStartTime = now;
    }

    super.unpause();
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(validTransfer(msg.sender, _value));
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(validTransfer(_from, _value));
    return super.transferFrom(_from, _to, _value);
  }

  function validTransfer(address _from, uint256 _amount) internal view returns (bool) {
    if (_from != teamWallet) {
      return true;
    }

    uint256 balanceAfterTransfer = balanceOf(_from).sub(_amount);
    return balanceAfterTransfer >= minimumTeamWalletBalance();
  }

   
  function minimumTeamWalletBalance() internal view returns (uint256) {
    if (now < circulationStartTime + 26 weeks) {
      return 300 * MILLION_TOKENS;
    } else if (now < circulationStartTime + 1 years) {
      return 200 * MILLION_TOKENS;
    } else {
      return 0;
    }
  }

   
  function burn(address _from, uint256 _value) external onlyOwner {
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);
  }
}

 

contract KeyrptoCrowdsale is FinalizableCrowdsale {
  uint256 internal constant ONE_TOKEN = 1e18;
  uint256 internal constant MILLION_TOKENS = 1e6 * ONE_TOKEN;
  uint256 internal constant PRESALE_TOKEN_CAP = 62500000 * ONE_TOKEN;
  uint256 internal constant MAIN_SALE_TOKEN_CAP = 510 * MILLION_TOKENS;
  uint256 internal constant MINIMUM_CONTRIBUTION_IN_WEI = 100 finney;

  mapping (address => bool) public whitelist;

  uint256 public mainStartTime;
  uint256 public extraTokensMintedDuringPresale;

  function KeyrptoCrowdsale(
                  uint256 _startTime,
                  uint256 _mainStartTime,
                  uint256 _endTime,
                  uint256 _rate,
                  address _wallet) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_startTime < _mainStartTime && _mainStartTime < _endTime);

    mainStartTime = _mainStartTime;

    KeyrptoToken(token).setTeamWallet(_wallet);
  }

  function createTokenContract() internal returns (MintableToken) {
    return new KeyrptoToken();
  }

   
  function() external payable {
    revert();
  }

  function updateRate(uint256 _rate) external onlyOwner {
    require(_rate > 0);
    require(now < endTime);

    rate = _rate;
  }

  function whitelist(address _address) external onlyOwner {
    whitelist[_address] = true;
  }

  function blacklist(address _address) external onlyOwner {
    delete whitelist[_address];
  }

   
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != address(0));

    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(getRate());

    require(validPurchase(tokens, _beneficiary));

    if(!presale()) {
      setExtraTokensMintedDuringPresaleIfNotYetSet();
    }

    if (extraTokensMintedDuringPresale == 0 && !presale()) {
      extraTokensMintedDuringPresale = token.totalSupply() / 5;
    }

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function validPurchase(uint256 _tokens, address _beneficiary) internal view returns (bool) {
    uint256 totalSupplyAfterTransaction = token.totalSupply() + _tokens;

    if (presale()) {
      bool withinPerAddressLimit = (token.balanceOf(_beneficiary) + _tokens) <= getRate().mul(20 ether);
      bool withinTotalSupplyLimit = totalSupplyAfterTransaction <= PRESALE_TOKEN_CAP;
      if (!withinPerAddressLimit || !withinTotalSupplyLimit) {
        return false;
      }
    }

    bool aboveMinContribution = msg.value >= MINIMUM_CONTRIBUTION_IN_WEI;
    bool whitelistedSender = whitelisted(msg.sender);
    bool withinCap = totalSupplyAfterTransaction <= tokenSupplyCap();
    return aboveMinContribution && whitelistedSender && withinCap && super.validPurchase();
  }

  function whitelisted(address _address) public view returns (bool) {
    return whitelist[_address];
  }

  function getRate() internal view returns (uint256) {
    return presale() ? rate.mul(5).div(4) : rate;
  }

  function presale() internal view returns (bool) {
    return now < mainStartTime;
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = token.totalSupply() >= tokenSupplyCap();
    return capReached || super.hasEnded();
  }

  function tokenSupplyCap() public view returns (uint256) {
    return MAIN_SALE_TOKEN_CAP + extraTokensMintedDuringPresale;
  }

  function finalization() internal {
    setExtraTokensMintedDuringPresaleIfNotYetSet();

    KeyrptoToken(token).mintTeamTokens(extraTokensMintedDuringPresale);
    token.finishMinting();
    token.transferOwnership(wallet);
  }

  function setExtraTokensMintedDuringPresaleIfNotYetSet() internal {
    if (extraTokensMintedDuringPresale == 0) {
      extraTokensMintedDuringPresale = token.totalSupply() / 5;
    }
  }

  function hasPresaleEnded() external view returns (bool) {
    if (!presale()) {
      return true;
    }

    uint256 minPurchaseInTokens = MINIMUM_CONTRIBUTION_IN_WEI.mul(getRate());
    return token.totalSupply() + minPurchaseInTokens > PRESALE_TOKEN_CAP;
  }
}