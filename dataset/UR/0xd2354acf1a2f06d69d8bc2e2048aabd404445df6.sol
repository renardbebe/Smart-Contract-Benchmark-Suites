 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
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

 

contract MNYTiers is Ownable {
  using SafeMath for uint256;

  uint public offset = 10**8;
  struct Tier {
    uint mny;
    uint futrx;
    uint rate;
  }
  mapping(uint16 => Tier) public tiers;

  constructor() public {
  }

  function addTiers(uint16 _startingTier, uint[] _mny, uint[] _futrx) public {
    require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
    require(_mny.length == _futrx.length);
    for (uint16 i = 0; i < _mny.length; i++) {
      tiers[_startingTier + i] = Tier(_mny[i], _futrx[i], uint(_mny[i]).div(uint(_futrx[i]).div(offset)));
    }
  }

  function getTier(uint16 tier) public view returns (uint mny, uint futrx, uint rate) {
    Tier t = tiers[tier];
    return (t.mny, t.futrx, t.rate);
  }

  address public dev = 0xa694a1fce7e6737209acb71bdec807c5aca26365;
  function changeDev (address _receiver) public {
    require(msg.sender == dev);
    dev = _receiver;
  }

  address public admin = 0x1e9b5a68023ef905e2440ea232c097a0f3ee3c87;
  function changeAdmin (address _receiver) public {
    require(msg.sender == admin);
    admin = _receiver;
  }

  function loadData() public {
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract MNY is StandardToken, MintableToken, BurnableToken {
  using SafeMath for uint256;

  string public constant name = "MNY by Monkey Capital";
  string public constant symbol = "MNY";
  uint8 public constant decimals = 18;
  uint public constant SWAP_CAP = 21000000 * (10 ** uint256(decimals));
  uint public cycleMintSupply = 0;
  MNYTiers public tierContract;

  event SwapStarted(uint256 endTime);
  event MiningRestart(uint16 tier);

  uint public offset = 10**8;
  uint public decimalOffset = 10 ** uint256(decimals);
  uint public baseRate = 1 ether;
  mapping(address => uint) public exchangeRatios;
  mapping(address => uint) public unPaidFees;
  address[] public miningTokens;

   
  uint16 public currentTier = 1;
  uint public mnyLeftInCurrent = 6.597 ether;
  uint public miningTokenLeftInCurrent = 0.0369 ether;
  uint public currentRate = mnyLeftInCurrent.div(miningTokenLeftInCurrent.div(offset));
  bool public isMiningOpen = false;
  bool public miningActive = false;
  uint16 public lastTier = 2856;

  constructor() public {
    totalSupply_ = 0;
     
    owner = this;
  }

  modifier canMine() {
    require(isMiningOpen);
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == creator || msg.sender == dev || msg.sender == origDev);
    _;
  }

   
  function mine(address token, uint amount) canMine public {
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
    uint miningPower = exchangeRatios[_token].div(baseRate).mul(_inAmount);
    unPaidFees[_token] += _inAmount.div(2);

    while (miningPower > 0) {
      if (miningPower >= miningTokenLeftInCurrent) {
        miningPower -= miningTokenLeftInCurrent;
        _tokens += mnyLeftInCurrent;
        miningTokenLeftInCurrent = 0;
        mnyLeftInCurrent = 0;
      } else {
        uint calculatedMny = currentRate.mul(miningPower).div(offset);
        _tokens += calculatedMny;
        mnyLeftInCurrent -= calculatedMny;
        miningTokenLeftInCurrent -= miningPower;
        miningPower = 0;
      }

      if (miningTokenLeftInCurrent == 0) {
        if (currentTier == lastTier) {
          _tokens = SWAP_CAP - cycleMintSupply;
          if (miningPower > 0) {
            uint refund = miningPower.div(exchangeRatios[_token].div(baseRate));
            unPaidFees[_token] -= refund.div(2);
            ERC20(_token).transfer(msg.sender, refund);
          }
           
          _startSwap();
          break;
        }
        currentTier++;
        (mnyLeftInCurrent, miningTokenLeftInCurrent, currentRate) = tierContract.getTier(currentTier);
      }
    }
    cycleMintSupply += _tokens;
    MintableToken(this).mint(msg.sender, _tokens);
  }

   
  bool public swapOpen = false;
  uint public swapEndTime;
  uint[] public holdings;
  mapping(address => uint) public swapRates;

  function _startSwap() private {
    swapEndTime = now + 30 days;
    swapOpen = true;
    isMiningOpen = false;
    miningActive = false;
    delete holdings;

     
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      uint swapAmt = ERC20(_token).balanceOf(this) - unPaidFees[_token];
      holdings.push(swapAmt);
    }
    for (uint16 j = 0; j < miningTokens.length; j++) {
      address token = miningTokens[j];
      swapRates[token] = holdings[j].div(SWAP_CAP.div(decimalOffset));
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

  function restart() public {
    require(swapOpen);
    require(now > swapEndTime || cycleMintSupply == 0);
    cycleMintSupply = 0;
    swapOpen = false;
    swapEndTime = 0;
    isMiningOpen = true;

     
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      uint amtLeft = ERC20(_token).balanceOf(this) - unPaidFees[_token];
      unPaidFees[_token] += amtLeft.div(5);
    }

    currentTier = 1;
    mnyLeftInCurrent = 6.597 ether;
    miningTokenLeftInCurrent = 0.0369 ether;
    currentRate = mnyLeftInCurrent.div(miningTokenLeftInCurrent.div(offset));
    emit MiningRestart(currentTier);
  }

  function setIsMiningOpen(bool isOpen) onlyAdmin public {
    isMiningOpen = isOpen;
  }

   
  function addMiningToken(address tokenAddr, uint ratio) onlyAdmin public {
    exchangeRatios[tokenAddr] = ratio;
    miningTokens.push(tokenAddr);
    unPaidFees[tokenAddr] = 0;
  }

   
  function setMnyTiers(address _tiersAddr) onlyAdmin public {
    require(!miningActive);
    tierContract = MNYTiers(_tiersAddr);
  }

   
   
  function setLastTier(uint16 _lastTier) onlyAdmin public {
    require(swapOpen);
    lastTier = _lastTier;
  }

   
  address public foundation = 0xab78275600E01Da6Ab7b5a4db7917d987FdB1b6d;
  address public creator = 0xab78275600E01Da6Ab7b5a4db7917d987FdB1b6d;
  address public dev = 0xab78275600E01Da6Ab7b5a4db7917d987FdB1b6d;
  address public origDev = 0xab78275600E01Da6Ab7b5a4db7917d987FdB1b6d;

  function payFees() public {
    for (uint16 i = 0; i < miningTokens.length; i++) {
      address _token = miningTokens[i];
      uint fees = unPaidFees[_token];
      ERC20(_token).transfer(foundation, fees.div(5).mul(2));
      ERC20(_token).transfer(dev, fees.div(5));
      ERC20(_token).transfer(origDev, fees.div(5));
      ERC20(_token).transfer(creator, fees.div(5));
      unPaidFees[_token] = 0;
    }
  }

  function changeFoundation (address _receiver) public {
    require(msg.sender == foundation);
    foundation = _receiver;
  }

  function changeCreator (address _receiver) public {
    require(msg.sender == creator);
    creator = _receiver;
  }

  function changeDev (address _receiver) public {
    require(msg.sender == dev);
    dev = _receiver;
  }

  function changeOrigDev (address _receiver) public {
    require(msg.sender == origDev);
    origDev = _receiver;
  }
}