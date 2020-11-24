 

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
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
    require(msg.sender == owner, "msg.sender not owner");
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
    require(_newOwner != address(0), "_newOwner == 0");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "The contract is paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "The contract is not paused");
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

 

pragma solidity ^0.4.24;



 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

pragma solidity ^0.4.24;





interface TradingWallet {
  function depositERC20Token (address _token, uint256 _amount)
    external returns(bool);
}

interface TradingWalletMapping {
  function retrieveWallet(address userAccount)
    external returns(address walletAddress);
}

 
contract ERC20Supplier is
  Pausable,
  Destructible
{
  using SafeMath for uint;

  ERC20 public token;
  TradingWalletMapping public tradingWalletMapping;

  address public wallet;
  address public reserve;

  uint public rate;
  uint public rateDecimals;
  uint public numberOfZeroesFromLastDigit;

  event LogWithdrawAirdrop(
    address indexed _from,
    address indexed _token,
    uint amount
  );
  event LogReleaseTokensTo(
    address indexed _from,
    address indexed _to,
    uint _amount
  );
  event LogSetWallet(address indexed _wallet);
  event LogSetReserve(address indexed _reserve);
  event LogSetToken(address indexed _token);
  event LogSetRate(uint _rate);
  event LogSetRateDecimals(uint _rateDecimals);
  event LogSetNumberOfZeroesFromLastDigit(
    uint _numberOfZeroesFromLastDigit
  );

  event LogSetTradingWalletMapping(address _tradingWalletMapping);
  event LogBuyForTradingWallet(
    address indexed _tradingWallet,
    address indexed _token,
    uint _amount
  );

   
  constructor(
    address _wallet,
    address _reserve,
    address _token,
    uint _rate,
    address _tradingWalletMappingAddress,
    uint _rateDecimals,
    uint _numberOfZeroesFromLastDigit
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    require(_reserve != address(0), "_reserve == address(0)");
    require(_token != address(0), "_token == address(0)");
    require(
      _tradingWalletMappingAddress != 0,
      "_tradingWalletMappingAddress == 0"
    );
    wallet = _wallet;
    reserve = _reserve;
    token = ERC20(_token);
    rate = _rate;
    tradingWalletMapping = TradingWalletMapping(_tradingWalletMappingAddress);
    rateDecimals = _rateDecimals;
    numberOfZeroesFromLastDigit = _numberOfZeroesFromLastDigit;
  }

  function() public payable {
    releaseTokensTo(msg.sender);
  }

   
  function setWallet(address _wallet)
    public
    onlyOwner
    returns (bool)
  {
    require(_wallet != address(0), "_wallet == 0");
    require(_wallet != wallet, "_wallet == wallet");
    wallet = _wallet;
    emit LogSetWallet(wallet);
    return true;
  }

   
  function setReserve(address _reserve)
    public
    onlyOwner
    returns (bool)
  {
    require(_reserve != address(0), "_reserve == 0");
    require(_reserve != reserve, "_reserve == reserve");
    reserve = _reserve;
    emit LogSetReserve(reserve);
    return true;
  }

   
  function setToken(address _token)
    public
    onlyOwner
    returns (bool)
  {
    require(_token != address(0), "_token == 0");
    require(_token != address(token), "_token == token");
    token = ERC20(_token);
    emit LogSetToken(token);
    return true;
  }

   
  function setRate(uint _rate)
    public
    onlyOwner
    returns (bool)
  {
    require(_rate != rate, "_rate == rate");
    require(_rate != 0, "_rate == 0");
    rate = _rate;
    emit LogSetRate(rate);
    return true;
  }

    
  function setRateDecimals(uint _rateDecimals)
    public
    onlyOwner
    returns (bool)
  {
    rateDecimals = _rateDecimals;
    emit LogSetRateDecimals(rateDecimals);
    return true;
  }

   
  function setNumberOfZeroesFromLastDigit(uint _numberOfZeroesFromLastDigit)
    public
    onlyOwner
    returns (bool)
  {
    numberOfZeroesFromLastDigit = _numberOfZeroesFromLastDigit;
    emit LogSetNumberOfZeroesFromLastDigit(numberOfZeroesFromLastDigit);
    return true;
  }

   
  function withdrawAirdrop(ERC20 _token)
    public
    onlyOwner
    returns(bool)
  {
    require(address(_token) != 0, "_token address == 0");
    require(
      _token.balanceOf(this) > 0,
      "dropped token balance == 0"
    );
    uint256 airdroppedTokenAmount = _token.balanceOf(this);
    _token.transfer(msg.sender, airdroppedTokenAmount);
    emit LogWithdrawAirdrop(msg.sender, _token, airdroppedTokenAmount);
    return true;
  }

   
  function setTradingWalletMappingAddress(
    address _tradingWalletMappingAddress
  )
    public
    onlyOwner
    returns(bool)
  {
    require(
      _tradingWalletMappingAddress != address(0),
      "_tradingWalletMappingAddress == 0");
    require(
      _tradingWalletMappingAddress != address(tradingWalletMapping),
      "_tradingWalletMappingAddress == tradingWalletMapping"
    );
    tradingWalletMapping = TradingWalletMapping(_tradingWalletMappingAddress);
    emit LogSetTradingWalletMapping(tradingWalletMapping);
    return true;
  }

   
  function buyForTradingWallet()
    public
    payable
    whenNotPaused
    returns(bool)
  {
    uint amount = getAmount(msg.value);
    require(
      amount > 0,
      "amount must be greater than 0"
    );
    address _tradingWallet = tradingWalletMapping.retrieveWallet(msg.sender);
    require(
      _tradingWallet != address(0),
      "no tradingWallet associated"
    );
    require(
      token.transferFrom(reserve, address(this), amount),
      "transferFrom reserve to ERC20Supplier failed"
    );
    if (token.allowance(address(this), _tradingWallet) != 0){
      require(
        token.approve(_tradingWallet, 0),
        "approve tradingWallet to zero failed"
      );
    }
    require(
      token.approve(_tradingWallet, amount),
      "approve tradingWallet failed"
    );
    emit LogBuyForTradingWallet(_tradingWallet, token, amount);
    wallet.transfer(msg.value);
    require(
      TradingWallet(_tradingWallet).depositERC20Token(token, amount),
      "depositERC20Token failed"
    );
    return true;
  }

   
  function truncate(
    uint _amount,
    uint _numberOfZeroesFromLastDigit
  )
    public
    pure
    returns (uint)
  {
    return (_amount
      .div(10 ** _numberOfZeroesFromLastDigit))
      .mul(10 ** _numberOfZeroesFromLastDigit
    );
  }

   
  function getAmount(uint _value)
    public
    view
    returns(uint)
  {
    uint amount = (_value.mul(rate).div(10 ** rateDecimals));
    uint result = truncate(amount, numberOfZeroesFromLastDigit);
    return result;
  }

   
  function releaseTokensTo(address _receiver)
    internal
    whenNotPaused
    returns (bool)
  {
    uint amount = getAmount(msg.value);
    wallet.transfer(msg.value);
    require(
      token.transferFrom(reserve, _receiver, amount),
      "transferFrom reserve to _receiver failed"
    );
    return true;
  }
}