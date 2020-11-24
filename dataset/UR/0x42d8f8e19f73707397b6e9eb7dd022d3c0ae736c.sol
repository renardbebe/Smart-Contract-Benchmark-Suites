 

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

 

contract FUTBTiers is Ownable {
  using SafeMath for uint256;

  uint public offset = 10**8;
  struct Tier {
    uint futb;
    uint futrx;
    uint rate;
  }
  mapping(uint16 => Tier) public tiers;

  constructor() public {
  }

  function addTiers(uint16 _startingTier, uint[] _futb, uint[] _futrx) external {
    require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
    require(_futb.length == _futrx.length);
    for (uint16 i = 0; i < _futb.length; i++) {
      tiers[_startingTier + i] = Tier(_futb[i], _futrx[i], uint(_futb[i]).div(uint(_futrx[i]).div(offset)));
    }
  }

  function getTier(uint16 tier) public view returns (uint futb, uint futrx, uint rate) {
    Tier t = tiers[tier];
    return (t.futb, t.futrx, t.rate);
  }

  address public dev = 0x89ec1273a56f232d96cd17c08e9f129e15cf16f1;
  function changeDev (address _receiver) external {
    require(msg.sender == dev);
    dev = _receiver;
  }

  address public admin = 0x89ec1273a56f232d96cd17c08e9f129e15cf16f1;
  function changeAdmin (address _receiver) external {
    require(msg.sender == admin);
    admin = _receiver;
  }

  function loadData() external {
    require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
    tiers[1] = Tier(6.597 ether, 0.0369 ether, uint(6.597 ether).div(uint(0.0369 ether).div(offset)));
    tiers[2] = Tier(9.5117 ether, 0.0531 ether, uint(9.5117 ether).div(uint(0.0531 ether).div(offset)));
    tiers[3] = Tier(5.8799 ether, 0.0292 ether, uint(5.8799 ether).div(uint(0.0292 ether).div(offset)));
    tiers[4] = Tier(7.7979 ether, 0.0338 ether, uint(7.7979 ether).div(uint(0.0338 ether).div(offset)));
    tiers[5] = Tier(7.6839 ether, 0.0385 ether, uint(7.6839 ether).div(uint(0.0385 ether).div(offset)));
    tiers[6] = Tier(6.9612 ether, 0.0215 ether, uint(6.9612 ether).div(uint(0.0215 ether).div(offset)));
    tiers[7] = Tier(7.1697 ether, 0.0269 ether, uint(7.1697 ether).div(uint(0.0269 ether).div(offset)));
    tiers[8] = Tier(6.2356 ether, 0.0192 ether, uint(6.2356 ether).div(uint(0.0192 ether).div(offset)));
    tiers[9] = Tier(5.6619 ether, 0.0177 ether, uint(5.6619 ether).div(uint(0.0177 ether).div(offset)));
    tiers[10] = Tier(6.1805 ether, 0.0231 ether, uint(6.1805 ether).div(uint(0.0231 ether).div(offset)));
    tiers[11] = Tier(6.915 ether, 0.0262 ether, uint(6.915 ether).div(uint(0.0262 ether).div(offset)));
    tiers[12] = Tier(8.7151 ether, 0.0323 ether, uint(8.7151 ether).div(uint(0.0323 ether).div(offset)));
    tiers[13] = Tier(23.8751 ether, 0.1038 ether, uint(23.8751 ether).div(uint(0.1038 ether).div(offset)));
    tiers[14] = Tier(7.0588 ether, 0.0262 ether, uint(7.0588 ether).div(uint(0.0262 ether).div(offset)));
    tiers[15] = Tier(13.441 ether, 0.0585 ether, uint(13.441 ether).div(uint(0.0585 ether).div(offset)));
    tiers[16] = Tier(6.7596 ether, 0.0254 ether, uint(6.7596 ether).div(uint(0.0254 ether).div(offset)));
    tiers[17] = Tier(9.3726 ether, 0.0346 ether, uint(9.3726 ether).div(uint(0.0346 ether).div(offset)));
    tiers[18] = Tier(7.1789 ether, 0.0269 ether, uint(7.1789 ether).div(uint(0.0269 ether).div(offset)));
    tiers[19] = Tier(5.8699 ether, 0.0215 ether, uint(5.8699 ether).div(uint(0.0215 ether).div(offset)));
    tiers[20] = Tier(8.3413 ether, 0.0308 ether, uint(8.3413 ether).div(uint(0.0308 ether).div(offset)));
    tiers[21] = Tier(6.8338 ether, 0.0254 ether, uint(6.8338 ether).div(uint(0.0254 ether).div(offset)));
    tiers[22] = Tier(6.1386 ether, 0.0231 ether, uint(6.1386 ether).div(uint(0.0231 ether).div(offset)));
    tiers[23] = Tier(6.7469 ether, 0.0254 ether, uint(6.7469 ether).div(uint(0.0254 ether).div(offset)));
    tiers[24] = Tier(9.9626 ether, 0.0431 ether, uint(9.9626 ether).div(uint(0.0431 ether).div(offset)));
    tiers[25] = Tier(18.046 ether, 0.0785 ether, uint(18.046 ether).div(uint(0.0785 ether).div(offset)));
    tiers[26] = Tier(10.2918 ether, 0.0446 ether, uint(10.2918 ether).div(uint(0.0446 ether).div(offset)));
    tiers[27] = Tier(56.3078 ether, 0.2454 ether, uint(56.3078 ether).div(uint(0.2454 ether).div(offset)));
    tiers[28] = Tier(17.2519 ether, 0.0646 ether, uint(17.2519 ether).div(uint(0.0646 ether).div(offset)));
    tiers[29] = Tier(12.1003 ether, 0.0531 ether, uint(12.1003 ether).div(uint(0.0531 ether).div(offset)));
    tiers[30] = Tier(14.4506 ether, 0.0631 ether, uint(14.4506 ether).div(uint(0.0631 ether).div(offset)));
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

 

contract FUTB is StandardToken, MintableToken, BurnableToken {
  using SafeMath for uint256;

  string public constant name = "Futereum BTC";
  string public constant symbol = "FUTB";
  uint8 public constant decimals = 18;
  uint public constant SWAP_CAP = 21000000 * (10 ** uint256(decimals));
  uint public cycleMintSupply = 0;
  FUTBTiers public tierContract = FUTBTiers(0x4dd013b9e784c459fe5f82aa926534506ce25eaf);

  event SwapStarted(uint256 endTime);
  event MiningRestart(uint16 tier);
  event MiningTokenAdded(address token, uint ratio);
  event MiningTokenAdjusted(address token, uint ratio);

  uint public offset = 10**8;
  uint public decimalOffset = 10 ** uint256(decimals);
  uint public baseRate = 100;
  mapping(address => uint) public exchangeRatios;
  mapping(address => uint) public unPaidFees;
  address[] public miningTokens;
  address public admin;
  address public tierAdmin;
  address public FUTC = 0xdaa6CD28E6aA9d656930cE4BB4FA93eEC96ee791;

   
  uint16 public currentTier = 1;
  uint public futbLeftInCurrent = 6.597 ether;
  uint public miningTokenLeftInCurrent = 0.0369 ether;
  uint public currentRate = futbLeftInCurrent.div(miningTokenLeftInCurrent.div(offset));
  bool public isMiningOpen = false;
  bool public miningActive = false;
  uint16 public lastTier = 2856;

  constructor() public {
    totalSupply_ = 0;
     
    owner = this;
    admin = msg.sender;
    tierAdmin = msg.sender;
  }

  modifier canMine() {
    require(isMiningOpen);
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  modifier onlyTierAdmin() {
    require(msg.sender == tierAdmin);
    _;
  }

   
  function mine(address token, uint amount) canMine external {
    require(token != 0 && amount > 0);
    require(exchangeRatios[token] > 0 && cycleMintSupply < SWAP_CAP);
    require(ERC20(token).transferFrom(msg.sender, this, amount));
    _mine(token, amount);
  }

  function _mine(address _token, uint256 _inAmount) private {
    if (!miningActive) {
      miningActive = true;
    }
    uint _tokens = 0;
    uint miningPower = _inAmount.mul(exchangeRatios[_token]).div(baseRate);
    uint fee = _inAmount.div(2);

    while (miningPower > 0) {
      if (miningPower >= miningTokenLeftInCurrent) {
        miningPower -= miningTokenLeftInCurrent;
        _tokens += futbLeftInCurrent;
        miningTokenLeftInCurrent = 0;
        futbLeftInCurrent = 0;
      } else {
        uint calculatedFutb = currentRate.mul(miningPower).div(offset);
        _tokens += calculatedFutb;
        futbLeftInCurrent -= calculatedFutb;
        miningTokenLeftInCurrent -= miningPower;
        miningPower = 0;
      }

      if (miningTokenLeftInCurrent == 0) {
        if (currentTier == lastTier) {
          _tokens = SWAP_CAP - cycleMintSupply;
          if (miningPower > 0) {
            uint refund = miningPower.mul(baseRate).div(exchangeRatios[_token]);
            fee -= refund.div(2);
            ERC20(_token).transfer(msg.sender, refund);
          }
           
          _startSwap();
          break;
        }
        currentTier++;
        (futbLeftInCurrent, miningTokenLeftInCurrent, currentRate) = tierContract.getTier(currentTier);
      }
    }
    cycleMintSupply += _tokens;
    MintableToken(this).mint(msg.sender, _tokens);
    ERC20(_token).transfer(FUTC, fee);
  }

   
  bool public swapOpen = false;
  uint public swapEndTime;
  mapping(address => uint) public swapRates;

  function _startSwap() private {
    swapEndTime = now + 30 days;
    swapOpen = true;
    isMiningOpen = false;
    miningActive = false;

     
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      uint swapAmt = ERC20(_token).balanceOf(this);
      swapRates[_token] = swapAmt.div(SWAP_CAP.div(decimalOffset));
    }
    emit SwapStarted(swapEndTime);
  }

  function swap(uint amt) public {
    require(swapOpen && cycleMintSupply > 0);
    if (amt > cycleMintSupply) {
      amt = cycleMintSupply;
    }
    cycleMintSupply -= amt;
     
    burn(amt);
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      ERC20(_token).transfer(msg.sender, amt.mul(swapRates[_token]).div(decimalOffset));
    }
  }

  function restart() external {
    require(swapOpen);
    require(now > swapEndTime || cycleMintSupply == 0);
    cycleMintSupply = 0;
    swapOpen = false;
    swapEndTime = 0;
    isMiningOpen = true;

     
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      uint amtLeft = ERC20(_token).balanceOf(this);
      ERC20(_token).transfer(FUTC, amtLeft.div(5));
    }

    currentTier = 1;
    futbLeftInCurrent = 6.597 ether;
    miningTokenLeftInCurrent = 0.0369 ether;
    currentRate = futbLeftInCurrent.div(miningTokenLeftInCurrent.div(offset));
    emit MiningRestart(currentTier);
  }

  function setIsMiningOpen(bool isOpen) onlyTierAdmin external {
    isMiningOpen = isOpen;
  }

   
  function addMiningToken(address tokenAddr, uint ratio) onlyAdmin external {
    require(exchangeRatios[tokenAddr] == 0 && ratio > 0 && ratio < 10000);
    exchangeRatios[tokenAddr] = ratio;

    bool found = false;
    for (uint16 i = 0; i < miningTokens.length; i++) {
      if (miningTokens[i] == tokenAddr) {
        found = true;
        break;
      }
    }
    if (!found) {
      miningTokens.push(tokenAddr);
    }
    emit MiningTokenAdded(tokenAddr, ratio);
  }

  function adjustTokenRate(address tokenAddr, uint ratio, uint16 position) onlyAdmin external {
    require(miningTokens[position] == tokenAddr && ratio < 10000);
    exchangeRatios[tokenAddr] = ratio;
    emit MiningTokenAdjusted(tokenAddr, ratio);
  }

   
  function setFutbTiers(address _tiersAddr) onlyTierAdmin external {
    require(!miningActive);
    tierContract = FUTBTiers(_tiersAddr);
  }

   
  function lockContract() onlyAdmin external {
    require(miningActive);
    admin = address(0);
  }

   
   
  function setLastTier(uint16 _lastTier) onlyAdmin external {
    require(swapOpen);
    lastTier = _lastTier;
  }

  function changeAdmin (address _receiver) onlyAdmin external {
    admin = _receiver;
  }

  function changeTierAdmin (address _receiver) onlyTierAdmin external {
    tierAdmin = _receiver;
  }
}