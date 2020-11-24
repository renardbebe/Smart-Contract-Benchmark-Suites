 

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

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public start;
  uint256 public period;
  uint256 public periodDuration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _period, uint256 _periodDuration, bool _revocable) public {
    require(_beneficiary != address(0));

    beneficiary = _beneficiary;
    revocable = _revocable;
    period = _period;
    periodDuration = _periodDuration;
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now >= start.add(period.mul(periodDuration)) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.div(period).mul(now.sub(start).div(periodDuration));
    }
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

contract DClearAllocation is Ownable {
  using SafeMath for uint256;

   
  DClearToken public token;
  uint256 public initTime = 1565193600; 
  uint256 public periodMintReleased = 0;
  uint256 public periodMintDuration = 31104000; 
  uint256 public periodMintBalance = 10000000000000000000000000;
  address public periodMintAddress = 0x0a39AA89C528D086eAA42447520C684f713966c4;

   
  mapping (address => TokenVesting) public vesting;

   
  event DClearTokensMintedSpecial(address beneficiary, uint256 tokens);
  
     
  event DClearTokensMinted(address beneficiary, uint256 tokens);

   
  event DClearTimeVestingTokensMinted(address beneficiary, uint256 tokens, uint256 start, uint256 periodDuration, uint256 period);

   
  event DClearAirDropTokensMinted(address beneficiary, uint256 tokens);

   
  function DClearAllocation() public {
    token = new DClearToken();
  }

   
  function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
    require(beneficiary != 0x0);
    require(tokens > 0);

    require(token.mint(beneficiary, tokens));
    DClearTokensMinted(beneficiary, tokens);
  }
  
  function mintTokensSpecial() public onlyOwner {

    uint256 amount = periodMintBalance.mul((now.sub(initTime)).div(periodMintDuration));
    uint256 unreleased = amount.sub(periodMintReleased);
    require(unreleased > 0);
    periodMintReleased = periodMintReleased.add(unreleased);
    require(token.mintSpecial(periodMintAddress, unreleased));
    DClearTokensMintedSpecial(periodMintAddress, unreleased);
  }

   
  function mintTokensWithTimeBasedVesting(address beneficiary, uint256 tokens, uint256 start, uint256 period, uint256 periodDuration) public onlyOwner {
    require(beneficiary != 0x0);
    require(tokens > 0);

    vesting[beneficiary] = new TokenVesting(beneficiary, start, period, periodDuration, false);
    require(token.mint(address(vesting[beneficiary]), tokens));

    DClearTimeVestingTokensMinted(beneficiary, tokens, start, period, periodDuration);
  }

  function mintAirDropTokens(uint256 tokens, address[] addresses) public onlyOwner {
    require(tokens > 0);
    for (uint256 i = 0; i < addresses.length; i++) {
      require(token.mint(addresses[i], tokens));
      DClearAirDropTokensMinted(addresses[i], tokens);
    }
  }

   
  function finishAllocation() public onlyOwner {
    require(token.finishMinting());
  }

   
  function unlockToken() public onlyOwner {
    token.unlockToken();
  }

   
  function releaseVestedTokens(address beneficiary) public {
    require(beneficiary != 0x0);

    TokenVesting tokenVesting = vesting[beneficiary];
    tokenVesting.release(token);
  }

   
  function transferTokenOwnership(address owner) public onlyOwner {
    require(token.mintingFinished());
    token.transferOwnership(owner);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
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
  
     
  function mintSpecial(address _to, uint256 _amount) onlyOwner public returns (bool) {
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

contract DClearToken is MintableToken {
  string public constant name = "DClearToken";
  string public constant symbol = "DCH";
  uint8 public constant decimals = 18;

  uint256 public constant MAX_INIT_SUPPLY = 1 * 1000 * 1000 * 1000 * (10 ** uint256(decimals));
   
  bool public unlocked = false;

  event DClearTokenUnlocked();

   
  function DClearToken() public {
  }

  function mint(address to, uint256 amount) onlyOwner public returns (bool) {
    require(totalSupply + amount <= MAX_INIT_SUPPLY);
    return super.mint(to, amount);
  }
  
  function mintSpecial(address to, uint256 amount) onlyOwner public returns (bool) {
    return super.mintSpecial(to, amount);
  }

  function unlockToken() onlyOwner public {
    require (!unlocked);
    unlocked = true;
    DClearTokenUnlocked();
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(unlocked);
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(unlocked);
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(unlocked);
    return super.approve(spender, value);
  }

   
  function increaseApproval(address spender, uint addedValue) public returns (bool) {
    require(unlocked);
    return super.increaseApproval(spender, addedValue);
  }

  function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
    require(unlocked);
    return super.decreaseApproval(spender, subtractedValue);
  }

}