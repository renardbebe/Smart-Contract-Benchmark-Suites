 

 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;


 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

pragma solidity ^0.4.24;

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

pragma solidity ^0.4.24;


contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

pragma solidity ^0.4.24;


 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 

pragma solidity ^0.4.24;



 
contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

 

pragma solidity ^0.4.24;




contract SignkeysToken is ERC20Pausable, ERC20Detailed, Ownable {

    uint8 public constant DECIMALS = 18;

    uint256 public constant INITIAL_SUPPLY = 2E9 * (10 ** uint256(DECIMALS));

     
    address public feeChargingAddress;

    function setFeeChargingAddress(address _feeChargingAddress) external onlyOwner {
        feeChargingAddress = _feeChargingAddress;
        emit FeeChargingAddressChanges(_feeChargingAddress);
    }

     
    event FeeChargingAddressChanges(address newFeeChargingAddress);

     
    constructor() public ERC20Detailed("SignkeysToken", "KEYS", DECIMALS) {
        _mint(owner(), INITIAL_SUPPLY);
    }

    function transferWithSignature(
        address from,
        address to,
        uint256 amount,
        uint256 feeAmount,
        uint256 expiration,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        require(expiration >= now, "Signature expired");
        require(feeChargingAddress != 0x0, "Fee charging address must be set");

        address receivedSigner = ecrecover(
            keccak256(
                abi.encodePacked(
                    from, to, amount, feeAmount, expiration
                )
            ), v, r, s);

        require(receivedSigner == from, "Something wrong with signature");
        _transfer(from, to, amount);
        _transfer(from, feeChargingAddress, feeAmount);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool success) {
        require(_spender != address(this));
        require(super.approve(_spender, _value));
        require(_spender.call(_data));
        return true;
    }

    function() payable external {
        revert();
    }
}

 

pragma solidity ^0.4.24;

 
library BytesDeserializer {

     
    function slice32(bytes b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

     
    function sliceAddress(bytes b, uint offset) internal pure returns (address) {
        bytes32 out;

        for (uint i = 0; i < 20; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
        }
        return address(uint(out));
    }

     
    function slice16(bytes b, uint offset) internal pure returns (bytes16) {
        bytes16 out;

        for (uint i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

     
    function slice4(bytes b, uint offset) internal pure returns (bytes4) {
        bytes4 out;

        for (uint i = 0; i < 4; i++) {
            out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

     
    function slice2(bytes b, uint offset) internal pure returns (bytes2) {
        bytes2 out;

        for (uint i = 0; i < 2; i++) {
            out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

     
    function slice(bytes b, uint offset) internal pure returns (bytes1) {
        return bytes1(b[offset] & 0xFF);
    }
}

 

pragma solidity ^0.4.24;



 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 

pragma solidity ^0.4.24;






contract SignkeysStaking is Ownable {

    using BytesDeserializer for bytes;

    using SafeMath for uint256;

    using SafeERC20 for ERC20;

     
    address[] private stakers;

     
    uint256[] private keysAmounts;

     
    uint256[] private xrmAmounts;

     
    uint256[] private keysLockTimes;

     
    uint256[] private xrmLockTimes;

     
    mapping(address => uint256) private stakersIndexes;

     
    ERC20 public keysToken;

     
    ERC20 public xrmToken;

     
    uint256 public lockDuration;

    uint256 public dailyDistributedReward;

    event Staked(address indexed token, address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed token, address indexed user, uint256 amount, uint256 total);
    event Locked(address indexed token, address indexed user, uint endDateTime);
    event LockDurationChanged(uint newLockDurationSeconds);
    event KeysStakingTokenChanged(address indexed token);
    event XrmStakingTokenChanged(address indexed token);
    event DailyDistributedRewardChanged(uint256 reward);

    constructor(address _keysToken, address _xrmToken) public {
        lockDuration = 30 days;
        keysToken = ERC20(_keysToken);
        xrmToken = ERC20(_xrmToken);

        stakers.push(0x0000000000000000000000000000000000000000);

        keysAmounts.push(0);
        keysLockTimes.push(0);

        xrmAmounts.push(0);
        xrmLockTimes.push(0);
    }

    function setKeysToken(address _token) external onlyOwner {
        keysToken = ERC20(_token);
        emit KeysStakingTokenChanged(_token);
    }

    function setXrmToken(address _token) external onlyOwner {
        xrmToken = ERC20(_token);
        emit XrmStakingTokenChanged(_token);
    }

    function setDailyDistributedReward(uint256 _reward) external onlyOwner {
        dailyDistributedReward = _reward;
        emit DailyDistributedRewardChanged(_reward);
    }

     
    function stakeOf(address _staker) public view returns (uint256, uint256) {
        return (keysAmounts[stakersIndexes[_staker]], xrmAmounts[stakersIndexes[_staker]]);
    }

     
    function lockTimeOf(address _staker) public view returns (uint256, uint256) {
        return (keysLockTimes[stakersIndexes[_staker]], xrmLockTimes[stakersIndexes[_staker]]);
    }

     
    function getAllStakers() public view returns (address[], uint256[], uint256[]) {
        return (stakers, keysAmounts, xrmAmounts);
    }

     
    function stake(address _user, uint256 _amount) internal returns (uint256)  {
        if (stakersIndexes[_user] == 0x0) {
            keysAmounts.push(0);
            keysLockTimes.push(0);

            xrmAmounts.push(0);
            xrmLockTimes.push(0);

            stakers.push(_user);
            stakersIndexes[_user] = stakers.length - 1;
        }

        if (msg.sender == address(keysToken)) {
            return stakeKeys(_user, _amount);
        }

        if (msg.sender == address(xrmToken)) {
            return stakeXrm(_user, _amount);
        }

        revert();
    }

    function stakeKeys(address _user, uint256 _amount) internal returns (uint256)  {
        require(keysToken.balanceOf(_user) >= _amount, "User balance is less than the requested stake size");

        keysAmounts[stakersIndexes[_user]] = keysAmounts[stakersIndexes[_user]].add(_amount);
        keysLockTimes[stakersIndexes[_user]] = now;

        keysToken.safeTransferFrom(_user, this, _amount);

        emit Locked(address(keysToken), _user, keysLockTimes[stakersIndexes[_user]]);

        return keysToken.balanceOf(_user);
    }

    function stakeXrm(address _user, uint256 _amount) internal returns (uint256)  {
        require(xrmToken.balanceOf(_user) >= _amount, "User balance is less than the requested stake size");

        xrmAmounts[stakersIndexes[_user]] = xrmAmounts[stakersIndexes[_user]].add(_amount);
        xrmLockTimes[stakersIndexes[_user]] = now;

        xrmToken.safeTransferFrom(_user, this, _amount);

        emit Locked(address(xrmToken), _user, xrmLockTimes[stakersIndexes[_user]]);

        return xrmToken.balanceOf(_user);
    }

     
    function unstake(address token, uint _amount) external {
        require(token == address(keysToken) || token == address(xrmToken), "Invalid token address");

        if (token == address(keysToken)) {
            return unstakeKeys(msg.sender, _amount);
        }

        if (token == address(xrmToken)) {
            return unstakeXrm(msg.sender, _amount);
        }

        revert();
    }

    function unstakeKeys(address _user, uint _amount) internal {
        uint256 keysStakedAmount;
        uint256 xrmStakedAmount;

        (keysStakedAmount, xrmStakedAmount) = stakeOf(_user);

        require(now >= keysLockTimes[stakersIndexes[msg.sender]].add(lockDuration), "Stake is locked");
        require(keysStakedAmount >= _amount, "User stake size is less than the requested amount");

        keysToken.safeTransfer(msg.sender, _amount);

        keysAmounts[stakersIndexes[msg.sender]] = keysAmounts[stakersIndexes[msg.sender]].sub(_amount);

        emit Unstaked(address(keysToken), _user, _amount, keysToken.balanceOf(_user));
    }

    function unstakeXrm(address _user, uint _amount) internal {
        uint256 keysStakedAmount;
        uint256 xrmStakedAmount;

        (keysStakedAmount, xrmStakedAmount) = stakeOf(_user);

        require(now >= xrmLockTimes[stakersIndexes[_user]].add(lockDuration), "Stake is locked");
        require(xrmStakedAmount >= _amount, "User stake size is less than the requested amount");

        xrmToken.safeTransfer(_user, _amount);

        xrmAmounts[stakersIndexes[_user]] = xrmAmounts[stakersIndexes[_user]].sub(_amount);

        emit Unstaked(address(xrmToken), _user, _amount, xrmToken.balanceOf(_user));
    }

     
    function receiveApproval(address sender, uint256 tokensAmount) external {
        uint256 newBalance = stake(sender, tokensAmount);

        emit Staked(msg.sender, sender, tokensAmount, newBalance);
    }

     
    function setLockDuration(uint _periodInSeconds) external onlyOwner {
        lockDuration = _periodInSeconds;
        emit LockDurationChanged(lockDuration);
    }
}