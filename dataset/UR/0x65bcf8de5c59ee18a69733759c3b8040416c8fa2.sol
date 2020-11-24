 

pragma solidity 0.4.15;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Authorizable is Ownable {
    event LogAccess(address authAddress);
    event Grant(address authAddress, bool grant);

    mapping(address => bool) public auth;

    modifier authorized() {
        LogAccess(msg.sender);
        require(auth[msg.sender]);
        _;
    }

    function authorize(address _address) onlyOwner public {
        Grant(_address, true);
        auth[_address] = true;
    }

    function unauthorize(address _address) onlyOwner public {
        Grant(_address, false);
        auth[_address] = false;
    }
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract TutellusToken is MintableToken {
   string public name = "Tutellus";
   string public symbol = "TUT";
   uint8 public decimals = 18;
}

 

contract TutellusVault is Authorizable {
    event VaultMint(address indexed authAddress);

    TutellusToken public token;

    function TutellusVault() public {
        token = new TutellusToken();
    }

    function mint(address _to, uint256 _amount) authorized public returns (bool) {
        require(_to != address(0));
        require(_amount >= 0);

        VaultMint(msg.sender);
        return token.mint(_to, _amount);
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

 

 
pragma solidity ^0.4.15;






 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event KYCValid(address beneficiary);
  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

   
  bool public kycValid = false;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    require(kycValid);
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

   
  function releasableAmount(ERC20Basic token) public returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }

  function setValidKYC() onlyOwner public returns (bool) {
    kycValid = true;
    KYCValid(beneficiary);
    return true;
  }
}

 

contract TutellusVestingFactory is Authorizable {
    event VestingCreated(address indexed contractAddress, address indexed vestingAddress, address indexed wallet, uint256 startTime, uint256 cliff, uint256 duration);
    event VestingKYCSetted(address indexed wallet, uint256 count);
    event VestingReleased(address indexed wallet, uint256 count);

    mapping(address => mapping(address => address)) vestingsContracts;
    address[] contracts;

    TutellusToken token;

    function TutellusVestingFactory(
        address _token
    ) public 
    {
        require(_token != address(0));
        
        token = TutellusToken(_token);
    }

    function authorize(address _address) onlyOwner public {
        super.authorize(_address);
        contracts.push(_address);
    }

    function getVesting(address _address) authorized public constant returns(address) {
        require(_address != address(0));
        return vestingsContracts[msg.sender][_address];
    }

    function getVestingFromContract(address _contract, address _address) authorized public constant returns(address) {
        require(_address != address(0));
        require(_contract != address(0));
        return vestingsContracts[_contract][_address];
    }

    function createVesting(address _address, uint256 startTime, uint256 cliff, uint256 duration) authorized public {
        address vestingAddress = getVesting(_address);
         
        if (vestingAddress == address(0)) {
             
            vestingAddress = new TokenVesting(_address, startTime, cliff, duration, true);
            VestingCreated(msg.sender, vestingAddress, _address, startTime, cliff, duration);
             
            vestingsContracts[msg.sender][_address] = vestingAddress;
        }
    }

    function setValidKYC(address _address) authorized public returns(uint256) {
        uint256 count = 0;
        for (uint256 c = 0; c < contracts.length; c ++) {
            address contractAddress = contracts[c];
            address vestingAddress = vestingsContracts[contractAddress][_address];
            if (vestingAddress != address(0)) {
                TokenVesting(vestingAddress).setValidKYC();
                count += 1;
            }
        }
        VestingKYCSetted(_address, count);
        return count;
    }

    function release(address _address) authorized public returns(uint256) {
        uint256 count = 0;
        for (uint256 c = 0; c < contracts.length; c ++) {
            address contractAddress = contracts[c];
            address vestingAddress = vestingsContracts[contractAddress][_address];
            if (vestingAddress != address(0)) {
                TokenVesting(vestingAddress).release(token);
                count += 1;
            }
        }
        VestingReleased(_address, count);
        return count;
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


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
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

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
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

 

 
contract TutellusPartnerCrowdsale is CappedCrowdsale, Pausable {
    event Withdrawal(address indexed beneficiary, uint256 amount);

    address public partner;    
    uint256 cliff;
    uint256 duration;
    uint256 percent;

    TutellusVault vault;
    TutellusVestingFactory vestingFactory;

    function TutellusPartnerCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap, 
        uint256 _cliff,
        uint256 _duration,
        uint256 _rate,
        address _wallet,
        address _partner,
        uint256 _percent,
        address _tutellusVault,
        address _tutellusVestingFactory
    )
        CappedCrowdsale(_cap)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_partner != address(0));
        require(_tutellusVault != address(0));
        require(_tutellusVestingFactory != address(0));
        require(_cliff <= _duration);
        require(_percent >= 0 && _percent <= 100);

        vault = TutellusVault(_tutellusVault);
        token = MintableToken(vault.token());

        vestingFactory = TutellusVestingFactory(_tutellusVestingFactory);

        partner = _partner;
        cliff = _cliff;
        duration = _duration;
        percent = _percent;
    }

    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        weiRaised = weiRaised.add(weiAmount);

        vestingFactory.createVesting(beneficiary, endTime, cliff, duration);
        address vestingAddress = vestingFactory.getVesting(beneficiary);

        vault.mint(vestingAddress, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function forwardFunds() internal {
         
        uint256 walletAmount = msg.value.mul(100 - percent).div(100);
        wallet.transfer(walletAmount);
    }

    function createTokenContract() internal returns (MintableToken) {}

    function withdraw() public {
        require(hasEnded());
        uint256 amount = this.balance;
        if (amount > 0) {
            partner.transfer(amount);
            Withdrawal(msg.sender, amount);
        }
    }
}