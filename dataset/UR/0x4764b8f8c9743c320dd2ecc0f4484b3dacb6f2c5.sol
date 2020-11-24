 

pragma solidity 0.5.4;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
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

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

contract RewardsToken is Ownable {
    using SafeMath for uint;

    string public constant symbol = 'RWRD';
    string public constant name = 'Rewards Cash';
    uint8 public constant decimals = 18;

    uint256 public constant hardCap = 5 * (10 ** (18 + 8));  
    uint256 public totalSupply;

    bool public mintingFinished = false;
    bool public frozen = true;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event NewToken(address indexed _token);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _burner, uint _burnedAmount);
    event Revoke(address indexed _from, uint256 _value);
    event MintFinished();
    event MintStarted();
    event Freeze();
    event Unfreeze();

    modifier canMint() {
        require(!mintingFinished, "Minting was already finished");
        _;
    }

    modifier canTransfer() {
        require(msg.sender == owner || !frozen, "Tokens could not be transferred");
        _;
    }

    constructor () public {
        emit NewToken(address(this));
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(totalSupply.add(_amount) <= hardCap);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
    function startMinting() public onlyOwner returns (bool) {
        require(mintingFinished);
        mintingFinished = false;
        emit MintStarted();
        return true;
    }

     
    function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[msg.sender], "Insufficient balance");

         
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function burn(uint _burnAmount) public {
        require(_burnAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_burnAmount);
        totalSupply = totalSupply.sub(_burnAmount);
        emit Burned(msg.sender, _burnAmount);
    }

     
    function revoke(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= balances[_from]);
         
         

        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Revoke(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

     
    function freeze() public onlyOwner {
        require(!frozen);
        frozen = true;
        emit Freeze();
    }

     
    function unfreeze() public onlyOwner {
        require(frozen);
        frozen = false;
        emit Unfreeze();
    }
}

 
contract VestingVault is Ownable {
    using SafeMath for uint256;

    struct Grant {
        uint value;
        uint vestingStart;
        uint vestingCliff;
        uint vestingDuration;
        uint[] scheduleTimes;
        uint[] scheduleValues;
        uint level;               
        uint transferred;
    }

    RewardsToken public token;

    mapping(address => Grant) public grants;

    uint public totalVestedTokens;
     
    address[] public vestedAddresses;
    bool public locked;

    event NewGrant (address _to, uint _amount, uint _start, uint _duration, uint _cliff, uint[] _scheduleTimes,
                    uint[] _scheduleAmounts, uint _level);
    event NewRelease(address _holder, uint _amount);
    event WithdrawAll(uint _amount);
    event BurnTokens(uint _amount);
    event LockedVault();

    modifier isOpen() {
        require(locked == false, "Vault is already locked");
        _;
    }

    constructor (RewardsToken _token) public {
        require(address(_token) != address(0), "Token address should not be zero");

        token = _token;
        locked = false;
    }

     
    function returnVestedAddresses() public view returns (address[] memory) {
        return vestedAddresses;
    }

     
    function returnGrantInfo(address _user)
    public view returns (uint, uint, uint, uint, uint[] memory, uint[] memory, uint, uint) {
        require(_user != address(0), "Address should not be zero");
        Grant storage grant = grants[_user];

        return (grant.value, grant.vestingStart, grant.vestingCliff, grant.vestingDuration, grant.scheduleTimes,
        grant.scheduleValues, grant.level, grant.transferred);
    }

     
    function grant(
        address _to, uint _value, uint _start, uint _duration, uint _cliff, uint[] memory _scheduleTimes,
        uint[] memory _scheduleValues, uint _level) public onlyOwner isOpen returns (uint256) {
        require(_to != address(0), "Address should not be zero");
        require(_level == 1 || _level == 2, "Invalid vesting level");
         
        require(grants[_to].value == 0, "Already added to vesting vault");

        if (_level == 2) {
            require(_scheduleTimes.length == _scheduleValues.length, "Schedule Times and Values should be matched");
            _value = 0;
            for (uint i = 0; i < _scheduleTimes.length; i++) {
                require(_scheduleTimes[i] > 0, "Seconds Amount of ScheduleTime should be greater than zero");
                require(_scheduleValues[i] > 0, "Amount of ScheduleValue should be greater than zero");
                if (i > 0) {
                    require(_scheduleTimes[i] > _scheduleTimes[i - 1], "ScheduleTimes should be sorted by ASC");
                }
                _value = _value.add(_scheduleValues[i]);
            }
        }

        require(_value > 0, "Vested amount should be greater than zero");

        grants[_to] = Grant({
            value : _value,
            vestingStart : _start,
            vestingDuration : _duration,
            vestingCliff : _cliff,
            scheduleTimes : _scheduleTimes,
            scheduleValues : _scheduleValues,
            level : _level,
            transferred : 0
            });

        vestedAddresses.push(_to);
        totalVestedTokens = totalVestedTokens.add(_value);

        emit NewGrant(_to, _value, _start, _duration, _cliff, _scheduleTimes, _scheduleValues, _level);
        return _value;
    }

     
    function transferableTokens(address _holder, uint256 _time) public view returns (uint256) {
        Grant storage grantInfo = grants[_holder];

        if (grantInfo.value == 0) {
            return 0;
        }
        return calculateTransferableTokens(grantInfo, _time);
    }

     
    function calculateTransferableTokens(Grant memory _grant, uint256 _time) private pure returns (uint256) {
        uint totalVestedAmount = _grant.value;
        uint totalAvailableVestedAmount = 0;

        if (_grant.level == 1) {
            if (_time < _grant.vestingCliff.add(_grant.vestingStart)) {
                return 0;
            } else if (_time >= _grant.vestingStart.add(_grant.vestingDuration)) {
                return _grant.value;
            } else {
                totalAvailableVestedAmount =
                totalVestedAmount.mul(_time.sub(_grant.vestingStart)).div(_grant.vestingDuration);
            }
        } else {
            if (_time < _grant.scheduleTimes[0]) {
                return 0;
            } else if (_time >= _grant.scheduleTimes[_grant.scheduleTimes.length - 1]) {
                return _grant.value;
            } else {
                for (uint i = 0; i < _grant.scheduleTimes.length; i++) {
                    if (_grant.scheduleTimes[i] <= _time) {
                        totalAvailableVestedAmount = totalAvailableVestedAmount.add(_grant.scheduleValues[i]);
                    } else {
                        break;
                    }
                }
            }
        }

        return totalAvailableVestedAmount;
    }

     
    function claim() public {
        address beneficiary = msg.sender;
        Grant storage grantInfo = grants[beneficiary];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 vested = calculateTransferableTokens(grantInfo, now);
        require(vested > 0, "There is no vested tokens");

        uint256 transferable = vested.sub(grantInfo.transferred);
        require(transferable > 0, "There is no remaining balance for this address");
        require(token.balanceOf(address(this)) >= transferable, "Contract Balance is insufficient");

        grantInfo.transferred = grantInfo.transferred.add(transferable);
        totalVestedTokens = totalVestedTokens.sub(transferable);

        token.transfer(beneficiary, transferable);
        emit NewRelease(beneficiary, transferable);
    }
    
     
    function revokeTokens(address _from, uint _amount) public onlyOwner {
         
        Grant storage grantInfo = grants[_from];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 revocable = grantInfo.value.sub(grantInfo.transferred);
        require(revocable > 0, "There is no remaining balance for this address");
        require(revocable >= _amount, "Revocable balance is insufficient");
        require(token.balanceOf(address(this)) >= _amount, "Contract Balance is insufficient");

        grantInfo.value = grantInfo.value.sub(_amount);
        totalVestedTokens = totalVestedTokens.sub(_amount);

        token.burn(_amount);
        emit BurnTokens(_amount);
    }

     
    function burnRemainingTokens() public onlyOwner {
         
        uint amount = token.balanceOf(address(this));

        token.burn(amount);
        emit BurnTokens(amount);
    }

     
    function withdraw() public onlyOwner {
         
        uint amount = token.balanceOf(address(this));
        token.transfer(owner, amount);

        emit WithdrawAll(amount);
    }

     
    function lockVault() public onlyOwner {
         
        require(!locked);
        locked = true;
        emit LockedVault();
    }
}

 
contract RewardsTokenDistribution is Ownable {
    using SafeMath for uint256;

    RewardsToken public token;
    VestingVault public vestingVault;

    bool public finished;

    event TokenMinted(address indexed _to, uint _value, string _id);
    event RevokeTokens(address indexed _from, uint _value);
    event MintingFinished();
   
    modifier isAllowed() {
        require(finished == false, "Minting was already finished");
        _;
    }

     
    constructor (
        RewardsToken _token,
        VestingVault _vestingVault
    ) public {
        require(address(_token) != address(0), "Address should not be zero");
        require(address(_vestingVault) != address(0), "Address should not be zero");

        token = _token;
        vestingVault = _vestingVault;
        finished = false;
    }

     
    function allocNormalUser(address _to, uint _value) public onlyOwner isAllowed {
        token.mint(_to, _value);
        emit TokenMinted(_to, _value, "Allocated Tokens To User");
    }

     
    function allocVestedUser(
        address _to, uint _value, uint _start, uint _duration, uint _cliff, uint[] memory _scheduleTimes,
        uint[] memory _scheduleValues, uint _level) public onlyOwner isAllowed {
        _value = vestingVault.grant(_to, _value, _start, _duration, _cliff, _scheduleTimes, _scheduleValues, _level);
        token.mint(address(vestingVault), _value);
        emit TokenMinted(_to, _value, "Allocated Vested Tokens To User");
    }

     
    function allocNormalUsers(address[] memory _holders, uint[] memory _amounts) public onlyOwner isAllowed {
        require(_holders.length > 0, "Empty holder addresses");
        require(_holders.length == _amounts.length, "Invalid arguments");
        for (uint i = 0; i < _holders.length; i++) {
            token.mint(_holders[i], _amounts[i]);
            emit TokenMinted(_holders[i], _amounts[i], "Allocated Tokens To Users");
        }
    }
    
     
    function revokeTokensFromVestedUser(address _from, uint _amount) public onlyOwner {
        vestingVault.revokeTokens(_from, _amount);
        emit RevokeTokens(_from, _amount);
    }

     
    function transferBackTokenOwnership() public onlyOwner {
        token.transferOwnership(owner);
    }

     
    function transferBackVestingVaultOwnership() public onlyOwner {
        vestingVault.transferOwnership(owner);
    }

     
    function finalize() public onlyOwner {
        token.finishMinting();
        finished = true;
        emit MintingFinished();
    }
}