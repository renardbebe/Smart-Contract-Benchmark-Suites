 

 
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

 
pragma solidity ^0.4.24;




 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 
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







 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

   
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

 
pragma solidity ^0.4.24;






 
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

 
pragma solidity ^0.4.24;





 
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

 
 
pragma solidity ^0.4.24;





contract TileToken is StandardToken {
    string public constant NAME = "LOOMIA TILE";
    string public constant SYMBOL = "TILE";
    uint8 public constant DECIMALS = 18;

    uint256 public totalSupply = 109021227 * 1e18;  

    constructor() public {
        balances[msg.sender] = totalSupply;
    }
}

 
 
pragma solidity ^0.4.24;







contract TileDistribution is Ownable {
    using SafeMath for uint256;

     
    uint256 public constant VESTING_DURATION = 2 * 365 days;
    uint256 public constant VESTING_START_TIME = 1504224000;  
    uint256 public constant VESTING_CLIFF = 26 weeks;  

    uint256 public constant TIMELOCK_DURATION = 365 days;

    address public constant LOOMIA1_ADDR = 0x1c59Aa1ec35Cfcc222B0e860066796Ccddbe10c8;
    address public constant LOOMIA2_ADDR = 0x4c728E555E647214D834E4eBa37844424C0b7eFD;
    address public constant LOOMIA_LOOMIA_REMAINDER_ADDR = 0x8b91Eaa35E694524274178586aCC7701CC56cd35;
    address public constant BRANDS_ADDR = 0xe4D876bf0b67Bf4547DD6c55559097cC62058726;
    address public constant ADVISORS_ADDR = 0x886E7DE436df0fA4593a8534b798995624DB5837;
    address public constant THIRD_PARTY_LOCKUP_ADDR = 0x03a41aD81834E8831fFc65CdC3F61Cf04A31806E;

    uint256 public constant LOOMIA1 = 3270636.80 * 1e18;
    uint256 public constant LOOMIA2 = 3270636.80 * 1e18;
    uint256 public constant LOOMIA_REMAINDER = 9811910 * 1e18;
    uint256 public constant BRANDS = 10902122.70 * 1e18;
    uint256 public constant ADVISORS = 5451061.35 * 1e18;
    uint256 public constant THIRD_PARTY_LOCKUP = 5451061.35 * 1e18;


     
    ERC20Basic public token;  
    address[3] public tokenVestingAddresses;  
    address public tokenTimelockAddress;

     
    event AirDrop(address indexed _beneficiaryAddress, uint256 _amount);

     
    modifier validAddressAmount(address _beneficiaryWallet, uint256 _amount) {
        require(_beneficiaryWallet != address(0));
        require(_amount != 0);
        _;
    }

     
    constructor () public {
        token = createTokenContract();
        createVestingContract();
        createTimeLockContract();
    }

     
    function () external payable {
        revert();
    }

     
     
    function batchDistributeTokens(address[] _beneficiaryWallets, uint256[] _amounts) external onlyOwner {
        require(_beneficiaryWallets.length == _amounts.length);
        for (uint i = 0; i < _beneficiaryWallets.length; i++) {
            distributeTokens(_beneficiaryWallets[i], _amounts[i]);
        }
    }

     
    function distributeTokens(address _beneficiaryWallet, uint256 _amount) public onlyOwner validAddressAmount(_beneficiaryWallet, _amount) {
        token.transfer(_beneficiaryWallet, _amount);
        emit AirDrop(_beneficiaryWallet, _amount);
    }

     
     
    function createVestingContract() private {
        TokenVesting newVault = new TokenVesting(
            LOOMIA1_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[0] = address(newVault);
        token.transfer(address(newVault), LOOMIA1);

        TokenVesting newVault2 = new TokenVesting(
            LOOMIA2_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[1] = address(newVault2);
        token.transfer(address(newVault2), LOOMIA2);

        TokenVesting newVault3 = new TokenVesting(
            LOOMIA_LOOMIA_REMAINDER_ADDR, VESTING_START_TIME, VESTING_CLIFF, VESTING_DURATION, false);

        tokenVestingAddresses[2] = address(newVault3);
        token.transfer(address(newVault3), LOOMIA_REMAINDER);
    }

      
    function createTimeLockContract() private {
        TokenTimelock timelock = new TokenTimelock(token, THIRD_PARTY_LOCKUP_ADDR, now.add(TIMELOCK_DURATION));
        tokenTimelockAddress = address(timelock);
        token.transfer(tokenTimelockAddress, THIRD_PARTY_LOCKUP);
    }

     
    function createTokenContract() private returns (ERC20Basic) {
        return new TileToken();
    }
}