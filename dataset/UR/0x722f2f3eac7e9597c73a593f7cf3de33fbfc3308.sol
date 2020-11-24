 

pragma solidity 0.4.24;

 
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

 
contract PeriodicTokenVesting is TokenVesting {
    using SafeMath for uint256;

    uint256 public releasePeriod;
    uint256 public releaseCount;

    mapping (address => uint256) public revokedAmount;

    constructor(
        address _beneficiary,
        uint256 _startInUnixEpochTime,
        uint256 _releasePeriodInSeconds,
        uint256 _releaseCount
    )
        public
        TokenVesting(_beneficiary, _startInUnixEpochTime, 0, _releasePeriodInSeconds.mul(_releaseCount), true)
    {
        require(_releasePeriodInSeconds.mul(_releaseCount) > 0, "Vesting Duration cannot be 0");
        require(_startInUnixEpochTime.add(_releasePeriodInSeconds.mul(_releaseCount)) > block.timestamp, "Worthless vesting");
        releasePeriod = _releasePeriodInSeconds;
        releaseCount = _releaseCount;
    }

    function initialTokenAmountInVesting(ERC20Basic _token) public view returns (uint256) {
        return _token.balanceOf(address(this)).add(released[_token]).add(revokedAmount[_token]);
    }

    function tokenAmountLockedInVesting(ERC20Basic _token) public view returns (uint256) {
        return _token.balanceOf(address(this)).sub(releasableAmount(_token));
    }

    function nextVestingTime(ERC20Basic _token) public view returns (uint256) {
        if (block.timestamp >= start.add(duration) || revoked[_token]) {
            return 0;
        } else {
            return start.add(((block.timestamp.sub(start)).div(releasePeriod).add(1)).mul(releasePeriod));
        }
    }

    function vestingCompletionTime(ERC20Basic _token) public view returns (uint256) {
        if (block.timestamp >= start.add(duration) || revoked[_token]) {
            return 0;
        } else {
            return start.add(duration);
        }
    }

    function remainingVestingCount(ERC20Basic _token) public view returns (uint256) {
        if (block.timestamp >= start.add(duration) || revoked[_token]) {
            return 0;
        } else {
            return releaseCount.sub((block.timestamp.sub(start)).div(releasePeriod));
        }
    }

     
    function revoke(ERC20Basic _token) public onlyOwner {
      require(revocable);
      require(!revoked[_token]);

      uint256 balance = _token.balanceOf(address(this));

      uint256 unreleased = releasableAmount(_token);
      uint256 refund = balance.sub(unreleased);

      revoked[_token] = true;
      revokedAmount[_token] = refund;

      _token.safeTransfer(owner, refund);

      emit Revoked();
    }

     
    function vestedAmount(ERC20Basic _token) public view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[_token]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
            return totalBalance;
        } else {
            return totalBalance.mul((block.timestamp.sub(start)).div(releasePeriod)).div(releaseCount);
        }
    }
}

 
contract CnusToken is StandardToken, Ownable, BurnableToken {
    using SafeMath for uint256;

     
    bool public globalTokenTransferLock = false;
    bool public mintingFinished = false;
    bool public lockingDisabled = false;

    string public name = "CoinUs";
    string public symbol = "CNUS";
    uint256 public decimals = 18;

    address public mintContractOwner;

    address[] public vestedAddresses;

     
    mapping( address => bool ) public lockedStatusAddress;
    mapping( address => PeriodicTokenVesting ) private tokenVestingContracts;

    event LockingDisabled();
    event GlobalLocked();
    event GlobalUnlocked();
    event Locked(address indexed lockedAddress);
    event Unlocked(address indexed unlockedaddress);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VestingCreated(address indexed beneficiary, uint256 startTime, uint256 period, uint256 releaseCount);
    event InitialVestingDeposited(address indexed beneficiary, uint256 amount);
    event AllVestedTokenReleased();
    event VestedTokenReleased(address indexed beneficiary);
    event RevokedTokenVesting(address indexed beneficiary);

     
    modifier checkGlobalTokenTransferLock {
        if (!lockingDisabled) {
            require(!globalTokenTransferLock, "Global lock is active");
        }
        _;
    }

     
    modifier checkAddressLock {
        require(!lockedStatusAddress[msg.sender], "Address is locked");
        _;
    }

    modifier canMint() {
        require(!mintingFinished, "Minting is finished");
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == mintContractOwner, "Minting is not authorized from this account");
        _;
    }

    constructor() public {
        uint256 initialSupply = 2000000000;
        initialSupply = initialSupply.mul(10**18);
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply;
        mintContractOwner = msg.sender;
    }

    function disableLockingForever() public
    onlyOwner
    {
        lockingDisabled = true;
        emit LockingDisabled();
    }

    function setGlobalTokenTransferLock(bool locked) public
    onlyOwner
    {
        require(!lockingDisabled);
        require(globalTokenTransferLock != locked);
        globalTokenTransferLock = locked;
        if (globalTokenTransferLock) {
            emit GlobalLocked();
        } else {
            emit GlobalUnlocked();
        }
    }

     
    function lockAddress(
        address target
    )
        public
        onlyOwner
    {
        require(!lockingDisabled);
        require(owner != target);
        require(!lockedStatusAddress[target]);
        for(uint256 i = 0; i < vestedAddresses.length; i++) {
            require(tokenVestingContracts[vestedAddresses[i]] != target);
        }
        lockedStatusAddress[target] = true;
        emit Locked(target);
    }

     
    function unlockAddress(
        address target
    )
        public
        onlyOwner
    {
        require(!lockingDisabled);
        require(lockedStatusAddress[target]);
        lockedStatusAddress[target] = false;
        emit Unlocked(target);
    }

     
    function createNewVesting(
        address _beneficiary,
        uint256 _startInUnixEpochTime,
        uint256 _releasePeriodInSeconds,
        uint256 _releaseCount
    )
        public
        onlyOwner
    {
        require(tokenVestingContracts[_beneficiary] == address(0));
        tokenVestingContracts[_beneficiary] = new PeriodicTokenVesting(
            _beneficiary, _startInUnixEpochTime, _releasePeriodInSeconds, _releaseCount);
        vestedAddresses.push(_beneficiary);
        emit VestingCreated(_beneficiary, _startInUnixEpochTime, _releasePeriodInSeconds, _releaseCount);
    }

     
    function transferInitialVestAmountFromOwner(
        address _beneficiary,
        uint256 _vestAmount
    )
        public
        onlyOwner
        returns (bool)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        ERC20 cnusToken = ERC20(address(this));
        require(cnusToken.allowance(owner, address(this)) >= _vestAmount);
        require(cnusToken.transferFrom(owner, tokenVestingContracts[_beneficiary], _vestAmount));
        emit InitialVestingDeposited(_beneficiary, cnusToken.balanceOf(tokenVestingContracts[_beneficiary]));
        return true;
    }

    function checkVestedAddressCount()
        public
        view
        returns (uint256)
    {
        return vestedAddresses.length;
    }

    function checkCurrentTotolVestedAmount()
        public
        view
        returns (uint256)
    {
        uint256 vestedAmountSum = 0;
        for (uint256 i = 0; i < vestedAddresses.length; i++) {
            vestedAmountSum = vestedAmountSum.add(
                tokenVestingContracts[vestedAddresses[i]].vestedAmount(ERC20(address(this))));
        }
        return vestedAmountSum;
    }

    function checkCurrentTotalReleasableAmount()
        public
        view
        returns (uint256)
    {
        uint256 releasableAmountSum = 0;
        for (uint256 i = 0; i < vestedAddresses.length; i++) {
            releasableAmountSum = releasableAmountSum.add(
                tokenVestingContracts[vestedAddresses[i]].releasableAmount(ERC20(address(this))));
        }
        return releasableAmountSum;
    }

    function checkCurrentTotalAmountLockedInVesting()
        public
        view
        returns (uint256)
    {
        uint256 lockedAmountSum = 0;
        for (uint256 i = 0; i < vestedAddresses.length; i++) {
            lockedAmountSum = lockedAmountSum.add(
               tokenVestingContracts[vestedAddresses[i]].tokenAmountLockedInVesting(ERC20(address(this))));
        }
        return lockedAmountSum;
    }

    function checkInitialTotalTokenAmountInVesting()
        public
        view
        returns (uint256)
    {
        uint256 initialTokenVesting = 0;
        for (uint256 i = 0; i < vestedAddresses.length; i++) {
            initialTokenVesting = initialTokenVesting.add(
                tokenVestingContracts[vestedAddresses[i]].initialTokenAmountInVesting(ERC20(address(this))));
        }
        return initialTokenVesting;
    }

    function checkNextVestingTimeForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].nextVestingTime(ERC20(address(this)));
    }

    function checkVestingCompletionTimeForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].vestingCompletionTime(ERC20(address(this)));
    }

    function checkRemainingVestingCountForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].remainingVestingCount(ERC20(address(this)));
    }

    function checkReleasableAmountForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].releasableAmount(ERC20(address(this)));
    }

    function checkVestedAmountForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].vestedAmount(ERC20(address(this)));
    }

    function checkTokenAmountLockedInVestingForBeneficiary(
        address _beneficiary
    )
        public
        view
        returns (uint256)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        return tokenVestingContracts[_beneficiary].tokenAmountLockedInVesting(ERC20(address(this)));
    }

     
    function releaseAllVestedToken()
        public
        checkGlobalTokenTransferLock
        returns (bool)
    {
        emit AllVestedTokenReleased();
        PeriodicTokenVesting tokenVesting;
        for(uint256 i = 0; i < vestedAddresses.length; i++) {
            tokenVesting = tokenVestingContracts[vestedAddresses[i]];
            if(tokenVesting.releasableAmount(ERC20(address(this))) > 0) {
                tokenVesting.release(ERC20(address(this)));
                emit VestedTokenReleased(vestedAddresses[i]);
            }
        }
        return true;
    }

     
    function releaseVestedToken(
        address _beneficiary
    )
        public
        checkGlobalTokenTransferLock
        returns (bool)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        tokenVestingContracts[_beneficiary].release(ERC20(address(this)));
        emit VestedTokenReleased(_beneficiary);
        return true;
    }

     
    function revokeTokenVesting(
        address _beneficiary
    )
        public
        onlyOwner
        checkGlobalTokenTransferLock
        returns (bool)
    {
        require(tokenVestingContracts[_beneficiary] != address(0));
        tokenVestingContracts[_beneficiary].revoke(ERC20(address(this)));
        _transferMisplacedToken(owner, address(this), ERC20(address(this)).balanceOf(address(this)));
        emit RevokedTokenVesting(_beneficiary);
        return true;
    }

     
    function transfer(
        address _to,
        uint256 _value
    )
        public
        checkGlobalTokenTransferLock
        checkAddressLock
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
        checkGlobalTokenTransferLock
        returns (bool)
    {
        require(!lockedStatusAddress[_from], "Address is locked.");
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(
        address _spender,
        uint256 _value
    )
        public
        checkGlobalTokenTransferLock
        checkAddressLock
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        checkGlobalTokenTransferLock
        checkAddressLock
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        checkGlobalTokenTransferLock
        checkAddressLock
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
    function transferMintOwnership(
        address _newOwner
    )
        public
        onlyOwner
    {
        _transferMintOwnership(_newOwner);
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

     
    function finishMinting()
        public
        onlyOwner
        canMint
        returns (bool)
    {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function checkMisplacedTokenBalance(
        address _tokenAddress
    )
        public
        view
        returns (uint256)
    {
        ERC20 unknownToken = ERC20(_tokenAddress);
        return unknownToken.balanceOf(address(this));
    }

     
    function refundMisplacedToken(
        address _recipient,
        address _tokenAddress,
        uint256 _value
    )
        public
        onlyOwner
    {
        _transferMisplacedToken(_recipient, _tokenAddress, _value);
    }

    function _transferMintOwnership(
        address _newOwner
    )
        internal
    {
        require(_newOwner != address(0));
        emit MintOwnershipTransferred(mintContractOwner, _newOwner);
        mintContractOwner = _newOwner;
    }

    function _transferMisplacedToken(
        address _recipient,
        address _tokenAddress,
        uint256 _value
    )
        internal
    {
        require(_recipient != address(0));
        ERC20 unknownToken = ERC20(_tokenAddress);
        require(unknownToken.balanceOf(address(this)) >= _value, "Insufficient token balance.");
        require(unknownToken.transfer(_recipient, _value));
    }
}