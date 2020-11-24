 

pragma solidity ^0.4.24;

 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract CCXToken is BurnableToken, PausableToken, MintableToken {
  string public constant name = "Crypto Circle Exchange Token";
  string public constant symbol = "CCX";
  uint8 public constant decimals = 18;
}

 
contract DaonomicCrowdsale {
  using SafeMath for uint256;

   
  event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus, bytes txId);
   
  event RateAdd(address token);
   
  event RateRemove(address token);

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;

     
    (uint256 tokens, uint256 left) = _getTokenAmount(weiAmount);
    uint256 weiEarned = weiAmount.sub(left);
    uint256 bonus = _getBonus(tokens);
    uint256 withBonus = tokens.add(bonus);

    _preValidatePurchase(_beneficiary, weiAmount, tokens, bonus);

    _processPurchase(_beneficiary, withBonus);
    emit Purchase(
      _beneficiary,
      address(0),
        weiEarned,
      tokens,
      bonus,
      ""
    );

    _updatePurchasingState(_beneficiary, weiEarned, withBonus);
    _postValidatePurchase(_beneficiary, weiEarned);

    if (left > 0) {
      _beneficiary.transfer(left);
    }
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(_tokens != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal;

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft);

  function _getBonus(uint256 _tokens) internal view returns (uint256);
}

contract Whitelist {
  function isInWhitelist(address addr) public view returns (bool);
}

contract WhitelistDaonomicCrowdsale is Ownable, DaonomicCrowdsale {
  Whitelist public whitelist;

  constructor (Whitelist _whitelist) public {
    whitelist = _whitelist;
  }

  function getWhitelists() view public returns (Whitelist[]) {
    Whitelist[] memory result = new Whitelist[](1);
    result[0] = whitelist;
    return result;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
    require(canBuy(_beneficiary), "investor is not verified by Whitelist");
  }

  function canBuy(address _beneficiary) constant public returns (bool) {
    return whitelist.isInWhitelist(_beneficiary);
  }
}

contract RefundableDaonomicCrowdsale is DaonomicCrowdsale {
  event Refund(address _address, uint256 investment);
  mapping(address => uint256) public investments;

  function claimRefund() public {
    require(isRefundable());
    require(investments[msg.sender] > 0);

    uint investment = investments[msg.sender];
    investments[msg.sender] = 0;

    msg.sender.transfer(investment);
    emit Refund(msg.sender, investment);
  }

  function isRefundable() public view returns (bool);

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);
    investments[_beneficiary] = investments[_beneficiary].add(_weiAmount);
  }
}

contract CCXSale is WhitelistDaonomicCrowdsale, RefundableDaonomicCrowdsale {

  event UsdEthRateChange(uint256 rate);
  event Withdraw(address to, uint256 value);

  uint256 constant public SOFT_CAP = 50000000 * 10 ** 18;
  uint256 constant public HARD_CAP = 225000000 * 10 ** 18;
  uint256 constant public MINIMAL_CCX = 1000 * 10 ** 18;
  uint256 constant public START = 1539820800;  
  uint256 constant public END = 1549152000;  

  CCXToken public token;
  uint256 public sold;
  uint256 public rate;
  address public operator;

  constructor(CCXToken _token, Whitelist _whitelist, uint256 _usdEthRate, address _operator)
  WhitelistDaonomicCrowdsale(_whitelist) public {
    token = _token;
    operator = _operator;
    setUsdEthRate(_usdEthRate);
     
    emit RateAdd(address(0));
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
    require(now >= START);
    require(now < END);
    require(_tokens.add(_bonus) > MINIMAL_CCX);
  }

  function setUsdEthRate(uint256 _usdEthRate) onlyOperatorOrOwner public {
    rate = _usdEthRate.mul(100).div(9);
    emit UsdEthRateChange(_usdEthRate);
  }

  modifier onlyOperatorOrOwner() {
    require(msg.sender == operator || msg.sender == owner);
    _;
  }

  function withdrawEth(address _to, uint256 _value) onlyOwner public {
    _to.transfer(_value);
    emit Withdraw(_to, _value);
  }

  function setOperator(address _operator) onlyOwner public {
    operator = _operator;
  }

  function pauseToken() onlyOwner public {
    token.pause();
  }

  function unpauseToken() onlyOwner public {
    token.unpause();
  }

  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal {
    token.mint(_beneficiary, _tokenAmount);
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft) {
    tokens = _weiAmount.mul(rate);
    if (sold.add(tokens) > HARD_CAP) {
      tokens = HARD_CAP.sub(sold);
       
      uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
      weiLeft =_weiAmount.sub(weiSpent);
    } else {
      weiLeft = 0;
    }
  }

  function _getBonus(uint256 _tokens) internal view returns (uint256) {
    uint256 possibleBonus = getTimeBonus(_tokens) + getAmountBonus(_tokens);
    if (sold.add(_tokens).add(possibleBonus) > HARD_CAP) {
      return HARD_CAP.sub(sold).sub(_tokens);
    } else {
      return possibleBonus;
    }
  }

  function getTimeBonus(uint256 _tokens) public view returns (uint256) {
    if (now < 1542931200) {  
      return _tokens.mul(15).div(100);
    } else if (now < 1546041600) {  
      return _tokens.mul(7).div(100);
    } else {
      return 0;
    }
  }

  function getAmountBonus(uint256 _tokens) public pure returns (uint256) {
    if (_tokens < 10000 * 10 ** 18) {
      return 0;
    } else if (_tokens < 100000 * 10 ** 18) {
      return _tokens.mul(3).div(100);
    } else if (_tokens < 1000000 * 10 ** 18) {
      return _tokens.mul(5).div(100);
    } else if (_tokens < 10000000 * 10 ** 18) {
      return _tokens.mul(7).div(100);
    } else {
      return _tokens.mul(10).div(100);
    }
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

    sold = sold.add(_tokens);
  }

  function isRefundable() public view returns (bool) {
    return now > END && sold < SOFT_CAP;
  }

   
  function getRate(address _token) public view returns (uint256) {
    if (_token == address(0)) {
      return rate * 10 ** 18;
    } else {
      return 0;
    }
  }

   
  function start() public pure returns (uint256) {
    return START;
  }

   
  function end() public pure returns (uint256) {
    return END;
  }

}