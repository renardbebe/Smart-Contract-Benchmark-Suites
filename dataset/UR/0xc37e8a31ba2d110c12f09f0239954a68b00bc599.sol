 

pragma solidity ^0.4.23;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

contract EubChainIco is PausableToken {

  using SafeMath for uint;
  using SafeMath for uint256;
  using SafeERC20 for StandardToken;

  string public name = 'EUB Chain';
  string public symbol = 'EUBC';
  uint8 public decimals = 8;

  uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);   

  uint public startTime;   

  uint256 public tokenSold = 0;  

  uint8 private teamShare = 10;  
  uint8 private teamExtraShare = 2;  
  uint8 private communityShare = 10;  
  uint8 private foundationShare = 10;  
  uint8 private operationShare = 40;  

  uint8 private icoShare = 30;  
  uint256 private icoCap = totalSupply.mul(icoShare).div(100);

  uint256 private teamLockPeriod = 365 days;
  uint256 private minVestLockMonths = 3;

  address private fundsWallet;
  address private teamWallet;  
  address private communityWallet;  
  address private foundationWallet;  

  struct Locking {
    uint256 amount;
    uint endTime;
  }
  struct Vesting {
    uint256 amount;
    uint startTime;
    uint lockMonths;
    uint256 released;
  }

  mapping (address => Locking) private lockingMap;
  mapping (address => Vesting) private vestingMap;

  event VestTransfer(
    address indexed from,
    address indexed to,
    uint256 amount, 
    uint startTime, 
    uint lockMonths
  );
  event Release(address indexed to, uint256 amount);

   
  constructor () public {

    startTime = now;
    uint teamLockEndTime = startTime.add(teamLockPeriod);

     
    fundsWallet = 0x1D64D9957e54711bf681985dB11Ac4De6508d2d8;
    teamWallet = 0xe0f58e3b40d5B97aa1C72DD4853cb462E8628386;
    communityWallet = 0x12bEfdd7D64312353eA0Cb0803b14097ee4cE28F;
    foundationWallet = 0x8e037d80dD9FF654a17A4a009B49BfB71a992Cab;

     
    uint256 teamTokens = totalSupply.mul(teamShare).div(100);
    uint256 teamExtraTokens = totalSupply.mul(teamExtraShare).div(100);
    uint256 communityTokens = totalSupply.mul(communityShare).div(100);
    uint256 foundationTokens = totalSupply.mul(foundationShare).div(100);
    uint256 operationTokens = totalSupply.mul(operationShare).div(100);

     
    Vesting storage teamVesting = vestingMap[teamWallet];
    teamVesting.amount = teamTokens;
    teamVesting.startTime = teamLockEndTime;
    teamVesting.lockMonths = 6;
    emit VestTransfer(0x0, teamWallet, teamTokens, teamLockEndTime, teamVesting.lockMonths);

     
    balances[communityWallet] = communityTokens;
    emit Transfer(0x0, communityWallet, communityTokens);
    balances[foundationWallet] = foundationTokens;
    emit Transfer(0x0, foundationWallet, foundationTokens);

     
    balances[communityWallet] = balances[communityWallet].sub(teamExtraTokens);
    balances[teamWallet] = balances[teamWallet].add(teamExtraTokens);
    emit Transfer(communityWallet, teamWallet, teamExtraTokens);
  
     
    uint256 restOfTokens = (
      totalSupply
        .sub(teamTokens)
        .sub(communityTokens)
        .sub(foundationTokens)
        .sub(operationTokens)
    );
    balances[fundsWallet] = restOfTokens;
    emit Transfer(0x0, fundsWallet, restOfTokens);
    
  }

   
  function vestedTransfer(address _to, uint256 _amount, uint _lockMonths) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    require(
      msg.sender == fundsWallet ||
      msg.sender == teamWallet
    );
  
     
    require(_lockMonths >= minVestLockMonths);

     
    Vesting storage vesting = vestingMap[_to];
    require(vesting.amount == 0);

    if (msg.sender == fundsWallet) {
       
      require(allowPurchase(_amount));
      require(isPurchaseWithinCap(tokenSold, _amount));
    
       
      require(allowTransfer(msg.sender, _amount));

      uint256 transferAmount = _amount.mul(15).div(100);
      uint256 vestingAmount = _amount.sub(transferAmount);

      vesting.amount = vestingAmount;
      vesting.startTime = now;
      vesting.lockMonths = _lockMonths;

      emit VestTransfer(msg.sender, _to, vesting.amount, vesting.startTime, _lockMonths);

      balances[msg.sender] = balances[msg.sender].sub(_amount);
      tokenSold = tokenSold.add(_amount);

      balances[_to] = balances[_to].add(transferAmount);
      emit Transfer(msg.sender, _to, transferAmount);
    } else if (msg.sender == teamWallet) {
      Vesting storage teamVesting = vestingMap[teamWallet];

      require(now < teamVesting.startTime);
      require(
        teamVesting.amount.sub(teamVesting.released) > _amount
      );

      teamVesting.amount = teamVesting.amount.sub(_amount);

      vesting.amount = _amount;
      vesting.startTime = teamVesting.startTime;
      vesting.lockMonths = _lockMonths;

      emit VestTransfer(msg.sender, _to, vesting.amount, vesting.startTime, _lockMonths);
    }

    return true;
  }

   
  function isIcoOpen() public view returns (bool) {
    bool capReached = tokenSold >= icoCap;
    return !capReached;
  }

   
  function isPurchaseWithinCap(uint256 _tokenSold, uint256 _purchaseAmount) internal view returns(bool) {
    bool isLessThanCap = _tokenSold.add(_purchaseAmount) <= icoCap;
    return isLessThanCap;
  }

   
  function allowPurchase(uint256 _amount) internal view returns (bool) {
    bool nonZeroPurchase = _amount != 0;
    return nonZeroPurchase && isIcoOpen();
  }

   
  function allowTransfer(address _wallet, uint256 _amount) internal view returns (bool) {
    Locking memory locking = lockingMap[_wallet];
    if (locking.endTime > now) {
      return balances[_wallet].sub(_amount) >= locking.amount;
    } else {
      return balances[_wallet] >= _amount;
    }
  }

   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(allowTransfer(msg.sender, _value));
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)  onlyPayloadSize(3 * 32) public returns (bool) {
    require(allowTransfer(_from, _value));
    return super.transferFrom(_from, _to, _value);
  }

   
  function allocationOf(address _wallet) public view returns (uint256) {
    Vesting memory vesting = vestingMap[_wallet];
    return vesting.amount;
  }

   
  function release() public onlyPayloadSize(0 * 32) returns (uint256) {
    uint256 unreleased = releasableAmount(msg.sender);
    Vesting storage vesting = vestingMap[msg.sender];

    if (unreleased > 0) {
      vesting.released = vesting.released.add(unreleased);
      emit Release(msg.sender, unreleased);

      balances[msg.sender] = balances[msg.sender].add(unreleased);
      emit Transfer(0x0, msg.sender, unreleased);
    }

    return unreleased;
  }

   
  function releasableAmount(address _wallet) public view returns (uint256) {
    Vesting memory vesting = vestingMap[_wallet];
    return vestedAmount(_wallet).sub(vesting.released);
  }

   
  function vestedAmount(address _wallet) public view returns (uint256) {
    uint amonth = 30 days;
    Vesting memory vesting = vestingMap[_wallet];
    uint lockPeriod = vesting.lockMonths.mul(amonth);
    uint lockEndTime = vesting.startTime.add(lockPeriod);

    if (now >= lockEndTime) {
      return vesting.amount;
    } else if (now > vesting.startTime) {
       
      
      uint roundedPeriod = now
        .sub(vesting.startTime)
        .div(amonth)
        .mul(amonth);

      return vesting.amount
        .mul(roundedPeriod)
        .div(lockPeriod);
    } else {
      return 0;
    }
  }

   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  } 
  
}