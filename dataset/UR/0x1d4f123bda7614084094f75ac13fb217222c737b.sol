 

pragma solidity 0.5.6;

 

 
contract ERC20Detailed {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor (string memory name, string memory symbol, uint8 decimals) public {
      _name = name;
      _symbol = symbol;
      _decimals = decimals;
  }

   
  function name() public view returns (string memory) {
      return _name;
  }

   
  function symbol() public view returns (string memory) {
      return _symbol;
  }

   
  function decimals() public view returns (uint8) {
      return _decimals;
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  uint256 private _totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   
  function totalSupply() public view returns (uint256) {
      return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
      return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
      return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
      _transfer(msg.sender, to, value);
      return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
      _approve(msg.sender, spender, value);
      return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
      _transfer(from, to, value);
      _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
      return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
      return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
      return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
      require(to != address(0));

      _balances[from] = _balances[from].sub(value);
      _balances[to] = _balances[to].add(value);
      emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
      require(account != address(0));

      _totalSupply = _totalSupply.add(value);
      _balances[account] = _balances[account].add(value);
      emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
      require(account != address(0));

      _totalSupply = _totalSupply.sub(value);
      _balances[account] = _balances[account].sub(value);
      emit Transfer(account, address(0), value);
  }

   
  function _approve(address owner, address spender, uint256 value) internal {
      require(spender != address(0));
      require(owner != address(0));

      _allowed[owner][spender] = value;
      emit Approval(owner, spender, value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
      _burn(account, value);
      _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library Percent {
   
  struct percent {
    uint num;
    uint den;
  }

   
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }

  function toMemory(percent storage p) internal view returns (Percent.percent memory) {
    return Percent.percent(p.num, p.den);
  }

   
  function mmul(percent memory p, uint a) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function mdiv(percent memory p, uint a) internal pure returns (uint) {
    return a/p.num*p.den;
  }

  function msub(percent memory p, uint a) internal pure returns (uint) {
    uint b = mmul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function madd(percent memory p, uint a) internal pure returns (uint) {
    return a + mmul(p, a);
  }
}

 
contract XetherToken is ERC20Detailed("XetherEcosystemToken", "XEET", 18), ERC20Burnable, Ownable {
   
  modifier onlyParticipant {
    require(showMyTokens() > 0);
    _;
  }

  modifier hasDividends {
    require(showMyDividends(true) > 0);
    _;
  }

   
  event onTokenBuy(
    address indexed customerAddress,
    uint256 incomeEth,
    uint256 tokensCreated,
    address indexed ref,
    uint timestamp,
    uint256 startPrice,
    uint256 newPrice
  );

  event onTokenSell(
    address indexed customerAddress,
    uint256 tokensBurned,
    uint256 earnedEth,
    uint timestamp,
    uint256 startPrice,
    uint256 newPrice
  );

  event onReinvestment(
    address indexed customerAddress,
    uint256 reinvestEth,
    uint256 tokensCreated
  );

  event onWithdraw(
    address indexed customerAddress,
    uint256 withdrawEth
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 tokens
  );

  using Percent for Percent.percent;
  using SafeMath for *;

   
  Percent.percent private inBonus_p  = Percent.percent(10, 100);            
  Percent.percent private outBonus_p  = Percent.percent(4, 100);            
  Percent.percent private refBonus_p = Percent.percent(30, 100);            
  Percent.percent private transferBonus_p = Percent.percent(1, 100);        

   
  address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public marketingAddress = DUMMY_ADDRESS;
  uint256 constant internal tokenPriceInitial = 0.00005 ether;
  uint256 constant internal tokenPriceIncremental = 0.0000000001 ether;
  uint256 internal profitPerToken = 0;
  uint256 internal decimalShift = 1e18;
  uint256 internal currentTotalDividends = 0;

  mapping(address => int256) internal payoutsTo;
  mapping(address => uint256) internal refBalance;
  mapping(address => address) internal referrals;

  uint256 public actualTokenPrice = tokenPriceInitial;
  uint256 public refMinBalanceReq = 50e18;

   
  event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);
  event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);
  event debug(uint256 div1, uint256 div2);

   
  function() payable external {
    buyTokens(msg.sender, msg.value, referrals[msg.sender]);
  }

   
  function setMarketingAddress(address newMarketingAddress) external onlyOwner {
    marketingAddress = newMarketingAddress;
  }

  function ecosystemDividends() payable external {
    uint dividends = msg.value;
    uint256 toMarketingAmount = inBonus_p.mul(dividends);
    uint256 toShareAmount = SafeMath.sub(dividends, toMarketingAmount);

    buyTokens(marketingAddress, toMarketingAmount, address(0));
    profitPerToken = profitPerToken.add(toShareAmount.mul(decimalShift).div(totalSupply()));
  }

   
  function buy(address _ref) public payable returns (uint256) {
    referrals[msg.sender] = _ref;
    buyTokens(msg.sender, msg.value, _ref);
  }

   
  function sell(uint256 _inRawTokens) onlyParticipant public {
    sellTokens(_inRawTokens);
  }

   
  function withdraw() hasDividends public {
    address payable _customerAddress = msg.sender;
    uint256 _dividends = showMyDividends(false);

    payoutsTo[_customerAddress] += (int256) (_dividends);
    _dividends = _dividends.add(refBalance[_customerAddress]);
    refBalance[_customerAddress] = 0;

    _customerAddress.transfer(_dividends);

    emit onWithdraw(_customerAddress, _dividends);
  }

   
  function withdraw(address customerAddress) internal {
    uint256 _dividends = dividendsOf(customerAddress);

    payoutsTo[customerAddress] += (int256) (_dividends);
    _dividends = _dividends.add(refBalance[customerAddress]);
    refBalance[customerAddress] = 0;

    if (_dividends > 0) {
      address payable _customerAddress = address(uint160(customerAddress));
      _customerAddress.transfer(_dividends);

      emit onWithdraw(customerAddress, _dividends);
    }
  }

  function transfer(address to, uint256 value) public returns (bool) {
    address _customerAddress = msg.sender;
    require(value <= balanceOf(_customerAddress));
    require(to != address(0));

    if (showMyDividends(true) > 0) {
      withdraw();
    }

    uint256 _tokenFee = transferBonus_p.mul(value);
    uint256 _taxedTokens = value.sub(_tokenFee);
    uint256 _dividends = tokensToEth(_tokenFee);

    _transfer(_customerAddress, to, _taxedTokens);
    _burn(_customerAddress, _tokenFee);

    payoutsTo[_customerAddress] -= (int256) (profitPerToken.mul(value).div(decimalShift));
    payoutsTo[to] += (int256) (profitPerToken.mul(_taxedTokens).div(decimalShift));
    profitPerToken = profitPerToken.add(_dividends.mul(decimalShift).div(totalSupply()));

    emit TransferSuccessful(_customerAddress, to, value);

    return true;
  }

  function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
  {
    uint256 _tokenFee = transferBonus_p.mul(value);
    uint256 _taxedTokens = value.sub(_tokenFee);
    uint256 _dividends = tokensToEth(_tokenFee);

    withdraw(from);

    ERC20.transferFrom(from, to, _taxedTokens);
    _burn(from, _tokenFee);

    payoutsTo[from] -= (int256) (profitPerToken.mul(value).div(decimalShift));
    payoutsTo[to] += (int256) (profitPerToken.mul(_taxedTokens).div(decimalShift));
    profitPerToken = profitPerToken.add(_dividends.mul(decimalShift).div(totalSupply()));

    emit TransferSuccessful(from, to, value);

    return true;
  }

   
  function exit() public {
    address _customerAddress = msg.sender;
    uint256 _tokens = balanceOf(_customerAddress);

    if (_tokens > 0) sell(_tokens);

    withdraw();
  }

   
  function reinvest() onlyParticipant public {
    uint256 _dividends = showMyDividends(false);
    address _customerAddress = msg.sender;

    payoutsTo[_customerAddress] += (int256) (_dividends);
    _dividends = _dividends.add(refBalance[_customerAddress]);
    refBalance[_customerAddress] = 0;

    uint256 _tokens = buyTokens(_customerAddress, _dividends, address(0));

    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

   
  function getActualTokenPrice() public view returns (uint256) {
    return actualTokenPrice;
  }

   
  function showMyDividends(bool _includeReferralBonus) public view returns (uint256) {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress).add(refBalance[_customerAddress]) : dividendsOf(_customerAddress) ;
  }

   
  function showMyTokens() public view returns (uint256) {
      address _customerAddress = msg.sender;
      return balanceOf(_customerAddress);
  }

   
  function dividendsOf(address _customerAddress) public view returns (uint256) {
    return (uint256) ((int256) (profitPerToken.mul(balanceOf(_customerAddress)).div(decimalShift)) - payoutsTo[_customerAddress]);
  }

   
 function showEthToTokens(uint256 _eth) public view returns (uint256 _tokensReceived, uint256 _newTokenPrice) {
   uint256 b = actualTokenPrice.mul(2).sub(tokenPriceIncremental);
   uint256 c = _eth.mul(2);
   uint256 d = SafeMath.add(b**2, tokenPriceIncremental.mul(4).mul(c));

    
    
   _tokensReceived = SafeMath.div(sqrt(d).sub(b).mul(decimalShift), tokenPriceIncremental.mul(2));
   _newTokenPrice = actualTokenPrice.add(tokenPriceIncremental.mul(_tokensReceived).div(decimalShift));
 }

  
 function showTokensToEth(uint256 _tokens) public view returns (uint256 _eth, uint256 _newTokenPrice) {
    
   _eth = SafeMath.sub(actualTokenPrice.mul(2), tokenPriceIncremental.mul(_tokens.sub(1e18)).div(decimalShift)).div(2).mul(_tokens).div(decimalShift);
   _newTokenPrice = actualTokenPrice.sub(tokenPriceIncremental.mul(_tokens).div(decimalShift));
 }

 function sqrt(uint x) pure private returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
 }

   

   
  function buyTokens(address customerAddress, uint256 _inRawEth, address _ref) internal returns (uint256) {
      uint256 _dividends = inBonus_p.mul(_inRawEth);
      uint256 _inEth = _inRawEth.sub(_dividends);
      uint256 _tokens = 0;
      uint256 startPrice = actualTokenPrice;

      if (_ref != address(0) && _ref != customerAddress && balanceOf(_ref) >= refMinBalanceReq) {
        uint256 _refBonus = refBonus_p.mul(_dividends);
        _dividends = _dividends.sub(_refBonus);
        refBalance[_ref] = refBalance[_ref].add(_refBonus);
      }

      uint256 _totalTokensSupply = totalSupply();

      if (_totalTokensSupply > 0) {
        _tokens = ethToTokens(_inEth);
        require(_tokens > 0);
        profitPerToken = profitPerToken.add(_dividends.mul(decimalShift).div(_totalTokensSupply));
        _totalTokensSupply = _totalTokensSupply.add(_tokens);
      } else {
         
        if (!isOwner()) {
            address(uint160(owner())).transfer(msg.value);
            return 0;
        }

        _totalTokensSupply = ethToTokens(_inRawEth);
        _tokens = _totalTokensSupply;
      }

      _mint(customerAddress, _tokens);
      payoutsTo[customerAddress] += (int256) (profitPerToken.mul(_tokens).div(decimalShift));

      emit onTokenBuy(customerAddress, _inEth, _tokens, _ref, now, startPrice, actualTokenPrice);

      return _tokens;
  }

   
  function sellTokens(uint256 _inRawTokens) internal returns (uint256) {
    address _customerAddress = msg.sender;
    require(_inRawTokens <= balanceOf(_customerAddress));
    uint256 _tokens = _inRawTokens;
    uint256 _eth = 0;
    uint256 startPrice = actualTokenPrice;

    _eth = tokensToEth(_tokens);
    _burn(_customerAddress, _tokens);

    uint256 _dividends = outBonus_p.mul(_eth);
    uint256 _ethTaxed = _eth.sub(_dividends);
    int256 unlockPayout = (int256) (_ethTaxed.add((profitPerToken.mul(_tokens)).div(decimalShift)));

    payoutsTo[_customerAddress] -= unlockPayout;
    profitPerToken = profitPerToken.add(_dividends.mul(decimalShift).div(totalSupply()));

    emit onTokenSell(_customerAddress, _tokens, _eth, now, startPrice, actualTokenPrice);
  }

   
  function ethToTokens(uint256 _eth) internal returns (uint256 _tokensReceived) {
    uint256 _newTokenPrice;
    (_tokensReceived, _newTokenPrice) = showEthToTokens(_eth);
    actualTokenPrice = _newTokenPrice;
  }

   
  function tokensToEth(uint256 _tokens) internal returns (uint256 _eth) {
    uint256 _newTokenPrice;
    (_eth, _newTokenPrice) = showTokensToEth(_tokens);
    actualTokenPrice = _newTokenPrice;
  }
}