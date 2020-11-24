 

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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract MintAndBurnToken is MintableToken {

   
   
   
   

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who], "must have balance greater than burn value");
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


 
contract BabyloniaToken is MintAndBurnToken {

   
  string public name = "Babylonia Token";
  string public symbol = "BBY";
  uint8 public decimals = 18;
}

 
contract EthPriceOracleI {
    function compute() public view returns (bytes32, bool);
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

 
contract Babylon is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for BabyloniaToken;

  event TokenExchangeCreated(address indexed recipient, uint amount, uint releasedAt);
  event TokenExchangeReleased(address indexed recipient);

  BabyloniaToken private babyloniaToken;
  StandardToken private helbizToken;
  EthPriceOracleI private ethPriceOracle;

  uint public INITIAL_CIRCULATION_BBY = 80000000;  
  uint public MIN_EXCHANGE_BBY = SafeMath.mul(1000, 10**18);  

  uint public exchangeRate;           
  uint8 public usdCentsExchangeRate;  
  uint32 public exchangeLockTime;     
  uint public babyloniaTokensLocked;  
  bool public ethExchangeEnabled;     

  struct TokenExchange {
    address recipient;  
    uint amountHBZ;     
    uint amountBBY;     
    uint amountWei;     
    uint createdAt;     
    uint releasedAt;    
  }

  mapping(address => uint) private activeTokenExchanges;
  TokenExchange[] private tokenExchanges;

  modifier activeTokenExchange() {
    require(activeTokenExchanges[msg.sender] != 0, "must be an active token exchange");
    _;
  }

  modifier noActiveTokenExchange() {
    require(activeTokenExchanges[msg.sender] == 0, "must not have an active token exchange");
    _;
  }

  modifier whenEthEnabled() {
    require(ethExchangeEnabled);
    _;
  }

   
  constructor(
    address _helbizCoinAddress,
    address _babyloniaTokenAddress,
    address _ethPriceOracleAddress,
    uint8 _exchangeRate,
    uint8 _usdCentsExchangeRate,
    uint32 _exchangeLockTime
  ) public {
    helbizToken = StandardToken(_helbizCoinAddress);
    babyloniaToken = BabyloniaToken(_babyloniaTokenAddress);
    ethPriceOracle = EthPriceOracleI(_ethPriceOracleAddress);
    exchangeRate = _exchangeRate;
    usdCentsExchangeRate = _usdCentsExchangeRate;
    exchangeLockTime = _exchangeLockTime;
    paused = true;

     
    tokenExchanges.push(TokenExchange({
      recipient: address(0),
      amountHBZ: 0,
      amountBBY: 0,
      amountWei: 0,
      createdAt: 0,
      releasedAt: 0
    }));
  }

   
  function() public payable {
    require(msg.value == 0, "not accepting ETH");
  }

   
  function withdrawHBZ(address _to) external onlyOwner {
    require(_to != address(0), "invalid _to address");
    require(helbizToken.transfer(_to, helbizToken.balanceOf(address(this))));
  }

   
  function withdrawETH(address _to) external onlyOwner {
    require(_to != address(0), "invalid _to address");
    _to.transfer(address(this).balance);
  }

   
  function withdrawBBY(address _to, uint _amountBBY) external onlyOwner {
    require(_to != address(0), "invalid _to address");
    require(_amountBBY > 0, "_amountBBY must be greater than 0");
    require(babyloniaToken.transfer(_to, _amountBBY));
  }

   
  function burnRemainderBBY() public onlyOwner {
    uint amountBBY = SafeMath.sub(babyloniaToken.balanceOf(address(this)), babyloniaTokensLocked);
    babyloniaToken.burn(amountBBY);
  }

   
  function setExchangeRate(uint8 _newRate) external onlyOwner {
    require(_newRate > 0, "new rate must not be 0");
    exchangeRate = _newRate;
  }

   
  function setUSDCentsExchangeRate(uint8 _newRate) external onlyOwner {
    require(_newRate > 0, "new rate must not be 0");
    usdCentsExchangeRate = _newRate;
  }

   
  function setExchangeLockTime(uint32 _newLockTime) external onlyOwner {
    require(_newLockTime > 0, "new lock time must not be 0");
    exchangeLockTime = _newLockTime;
  }

   
  function setEthExchangeEnabled(bool _enabled) external onlyOwner {
    ethExchangeEnabled = _enabled;
  }

   
  function getTokenAddress() public view returns(address) {
    return address(babyloniaToken);
  }

   
  function exchangeTokens(uint _amountHBZ) public whenNotPaused noActiveTokenExchange {
     
    require(_amountHBZ >= MIN_EXCHANGE_BBY, "_amountHBZ must be greater than or equal to MIN_EXCHANGE_BBY");

     
    uint amountBBY = SafeMath.div(_amountHBZ, exchangeRate);
    uint contractBalanceBBY = babyloniaToken.balanceOf(address(this));
    require(SafeMath.sub(contractBalanceBBY, babyloniaTokensLocked) >= amountBBY, "contract has insufficient BBY");

     
    require(helbizToken.transferFrom(msg.sender, address(this), _amountHBZ));

    _createExchangeRecord(_amountHBZ, amountBBY, 0);
  }

   
  function exchangeEth(uint _amountBBY) public whenNotPaused whenEthEnabled noActiveTokenExchange payable {
     
    require(_amountBBY > 0, "_amountBBY must be greater than 0");

    bytes32 val;
    (val,) = ethPriceOracle.compute();
     
    uint256 usdCentsPerETH = SafeMath.div(uint256(val), 10**16);

     
    uint256 priceInWeiPerBBY = SafeMath.div(10**18, SafeMath.div(usdCentsPerETH, usdCentsExchangeRate));

     
    uint256 totalPriceInWei = SafeMath.mul(priceInWeiPerBBY, _amountBBY);

     
    require(msg.value >= totalPriceInWei, "Insufficient ETH value");
    require(SafeMath.sub(babyloniaToken.balanceOf(address(this)), babyloniaTokensLocked) >= _amountBBY, "contract has insufficient BBY");

     
    if (msg.value > totalPriceInWei) msg.sender.transfer(msg.value - totalPriceInWei);

    _createExchangeRecord(0, _amountBBY, totalPriceInWei);
  }

   
  function claimTokens() public whenNotPaused activeTokenExchange {
    TokenExchange storage tokenExchange = tokenExchanges[activeTokenExchanges[msg.sender]];
    uint amountBBY = tokenExchange.amountBBY;

     
     
    require(block.timestamp >= tokenExchange.releasedAt, "not past locking period");

     
    babyloniaTokensLocked = SafeMath.sub(babyloniaTokensLocked, tokenExchange.amountBBY);

     
    delete tokenExchanges[activeTokenExchanges[msg.sender]];
    delete activeTokenExchanges[msg.sender];

     
    babyloniaToken.safeTransfer(msg.sender, amountBBY);

    emit TokenExchangeReleased(msg.sender);
  }

   
  function getActiveTokenExchangeId() public view activeTokenExchange returns(uint) {
    return activeTokenExchanges[msg.sender];
  }

   
  function getActiveTokenExchangeById(uint _id)
    public
    view
    returns(
      address recipient,
      uint amountHBZ,
      uint amountBBY,
      uint amountWei,
      uint createdAt,
      uint releasedAt
    )
  {
     
    require(tokenExchanges[_id].recipient != address(0));

    TokenExchange storage tokenExchange = tokenExchanges[_id];

    recipient = tokenExchange.recipient;
    amountHBZ = tokenExchange.amountHBZ;
    amountBBY = tokenExchange.amountBBY;
    amountWei = tokenExchange.amountWei;
    createdAt = tokenExchange.createdAt;
    releasedAt = tokenExchange.releasedAt;
  }

   
  function getTokenExchangesCount() public view onlyOwner returns(uint) {
    return tokenExchanges.length;
  }

   
  function _createExchangeRecord(uint _amountHBZ, uint _amountBBY, uint _amountWei) internal {
     
    uint releasedAt = SafeMath.add(block.timestamp, exchangeLockTime);
    TokenExchange memory tokenExchange = TokenExchange({
      recipient: msg.sender,
      amountHBZ: _amountHBZ,
      amountBBY: _amountBBY,
      amountWei: _amountWei,
      createdAt: block.timestamp,  
      releasedAt: releasedAt
    });
     
    activeTokenExchanges[msg.sender] = tokenExchanges.push(tokenExchange) - 1;

     
    babyloniaTokensLocked = SafeMath.add(babyloniaTokensLocked, _amountBBY);

    emit TokenExchangeCreated(msg.sender, _amountHBZ, releasedAt);
  }
}