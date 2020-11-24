 

pragma solidity ^0.4.25;

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

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

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

contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

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

contract Modifiable {
     
     
     
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

contract RevenueToken is ERC20Mintable {
    using SafeMath for uint256;

    bool public mintingDisabled;

    address[] public holders;

    mapping(address => bool) public holdersMap;

    mapping(address => uint256[]) public balances;

    mapping(address => uint256[]) public balanceBlocks;

    mapping(address => uint256[]) public balanceBlockNumbers;

    event DisableMinting();

     
    function disableMinting()
    public
    onlyMinter
    {
        mintingDisabled = true;

        emit DisableMinting();
    }

     
    function mint(address to, uint256 value)
    public
    onlyMinter
    returns (bool)
    {
        require(!mintingDisabled);

         
        bool minted = super.mint(to, value);

        if (minted) {
             
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return minted;
    }

     
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
         
        bool transferred = super.transfer(to, value);

        if (transferred) {
             
            addBalanceBlocks(msg.sender);
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

     
    function approve(address spender, uint256 value)
    public
    returns (bool)
    {
         
        require(0 == value || 0 == allowance(msg.sender, spender));

         
        return super.approve(spender, value);
    }

     
    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
         
        bool transferred = super.transferFrom(from, to, value);

        if (transferred) {
             
            addBalanceBlocks(from);
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

     
    function balanceBlocksIn(address account, uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock);
        require(account != address(0));

        if (balanceBlockNumbers[account].length == 0 || endBlock < balanceBlockNumbers[account][0])
            return 0;

        uint256 i = 0;
        while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < startBlock)
            i++;

        uint256 r;
        if (i >= balanceBlockNumbers[account].length)
            r = balances[account][balanceBlockNumbers[account].length - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : balanceBlockNumbers[account][i - 1];

            uint256 h = balanceBlockNumbers[account][i];
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : balanceBlocks[account][i].mul(h).div(balanceBlockNumbers[account][i].sub(l));
            i++;

            while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < endBlock) {
                r = r.add(balanceBlocks[account][i]);
                i++;
            }

            if (i >= balanceBlockNumbers[account].length)
                r = r.add(
                    balances[account][balanceBlockNumbers[account].length - 1].mul(
                        endBlock.sub(balanceBlockNumbers[account][balanceBlockNumbers[account].length - 1])
                    )
                );

            else if (balanceBlockNumbers[account][i - 1] < endBlock)
                r = r.add(
                    balanceBlocks[account][i].mul(
                        endBlock.sub(balanceBlockNumbers[account][i - 1])
                    ).div(
                        balanceBlockNumbers[account][i].sub(balanceBlockNumbers[account][i - 1])
                    )
                );
        }

        return r;
    }

     
    function balanceUpdatesCount(address account)
    public
    view
    returns (uint256)
    {
        return balanceBlocks[account].length;
    }

     
    function holdersCount()
    public
    view
    returns (uint256)
    {
        return holders.length;
    }

     
    function holdersByIndices(uint256 low, uint256 up, bool posOnly)
    public
    view
    returns (address[])
    {
        require(low <= up);

        up = up > holders.length - 1 ? holders.length - 1 : up;

        uint256 length = 0;
        if (posOnly) {
            for (uint256 i = low; i <= up; i++)
                if (0 < balanceOf(holders[i]))
                    length++;
        } else
            length = up - low + 1;

        address[] memory _holders = new address[](length);

        uint256 j = 0;
        for (i = low; i <= up; i++)
            if (!posOnly || 0 < balanceOf(holders[i]))
                _holders[j++] = holders[i];

        return _holders;
    }

    function addBalanceBlocks(address account)
    private
    {
        uint256 length = balanceBlockNumbers[account].length;
        balances[account].push(balanceOf(account));
        if (0 < length)
            balanceBlocks[account].push(
                balances[account][length - 1].mul(
                    block.number.sub(balanceBlockNumbers[account][length - 1])
                )
            );
        else
            balanceBlocks[account].push(0);
        balanceBlockNumbers[account].push(block.number);
    }
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     
     
     
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

contract SelfDestructible {
     
     
     
    bool public selfDestructionDisabled;

     
     
     
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

     
     
     
     
    function destructor()
    public
    view
    returns (address);

     
     
    function disableSelfDestruction()
    public
    {
         
        require(destructor() == msg.sender);

         
        selfDestructionDisabled = true;

         
        emit SelfDestructionDisabledEvent(msg.sender);
    }

     
    function triggerSelfDestruction()
    public
    {
         
        require(destructor() == msg.sender);

         
        require(!selfDestructionDisabled);

         
        emit TriggerSelfDestructionEvent(msg.sender);

         
        selfdestruct(msg.sender);
    }
}

contract Ownable is Modifiable, SelfDestructible {
     
     
     
    address public deployer;
    address public operator;

     
     
     
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

     
     
     
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

     
     
     
     
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

     
     
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
             
            address oldDeployer = deployer;
            deployer = newDeployer;

             
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

     
     
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
             
            address oldOperator = operator;
            operator = newOperator;

             
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

     
     
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

     
     
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

     
     
     
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

     
     
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

contract TokenMultiTimelock is Ownable {
    using SafeERC20 for IERC20;

     
     
     
    struct Release {
        uint256 earliestReleaseTime;
        uint256 amount;
        uint256 blockNumber;
        bool done;
    }

     
     
     
    IERC20 public token;
    address public beneficiary;

    Release[] public releases;
    uint256 public totalLockedAmount;
    uint256 public executedReleasesCount;

     
     
     
    event SetTokenEvent(IERC20 token);
    event SetBeneficiaryEvent(address beneficiary);
    event DefineReleaseEvent(uint256 earliestReleaseTime, uint256 amount, uint256 blockNumber);
    event SetReleaseBlockNumberEvent(uint256 index, uint256 blockNumber);
    event ReleaseEvent(uint256 index, uint256 blockNumber, uint256 earliestReleaseTime,
        uint256 actualReleaseTime, uint256 amount);

     
     
     
    constructor(address deployer)
    Ownable(deployer)
    public
    {
    }

     
     
     
     
     
    function setToken(IERC20 _token)
    public
    onlyOperator
    notNullOrThisAddress(_token)
    {
         
        require(address(token) == address(0));

         
        token = _token;

         
        emit SetTokenEvent(token);
    }

     
     
    function setBeneficiary(address _beneficiary)
    public
    onlyOperator
    notNullAddress(_beneficiary)
    {
         
        beneficiary = _beneficiary;

         
        emit SetBeneficiaryEvent(beneficiary);
    }

     
     
     
     
     
    function defineReleases(uint256[] earliestReleaseTimes, uint256[] amounts, uint256[] releaseBlockNumbers)
    onlyOperator
    public
    {
        require(earliestReleaseTimes.length == amounts.length);
        require(earliestReleaseTimes.length >= releaseBlockNumbers.length);

         
        require(address(token) != address(0));

        for (uint256 i = 0; i < earliestReleaseTimes.length; i++) {
             
            totalLockedAmount += amounts[i];

             
             
            require(token.balanceOf(address(this)) >= totalLockedAmount);

             
            uint256 blockNumber = i < releaseBlockNumbers.length ? releaseBlockNumbers[i] : 0;

             
            releases.push(Release(earliestReleaseTimes[i], amounts[i], blockNumber, false));

             
            emit DefineReleaseEvent(earliestReleaseTimes[i], amounts[i], blockNumber);
        }
    }

     
     
    function releasesCount()
    public
    view
    returns (uint256)
    {
        return releases.length;
    }

     
     
     
    function setReleaseBlockNumber(uint256 index, uint256 blockNumber)
    public
    onlyBeneficiary
    {
         
        require(!releases[index].done);

         
        releases[index].blockNumber = blockNumber;

         
        emit SetReleaseBlockNumberEvent(index, blockNumber);
    }

     
     
    function release(uint256 index)
    public
    onlyBeneficiary
    {
         
        Release storage _release = releases[index];

         
        require(0 < _release.amount);

         
        require(!_release.done);

         
        require(block.timestamp >= _release.earliestReleaseTime);

         
        _release.done = true;

         
        if (0 == _release.blockNumber)
            _release.blockNumber = block.number;

         
        executedReleasesCount++;

         
        totalLockedAmount -= _release.amount;

         
        token.safeTransfer(beneficiary, _release.amount);

         
        emit ReleaseEvent(index, _release.blockNumber, _release.earliestReleaseTime, block.timestamp, _release.amount);
    }

     
     
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }
}

contract RevenueTokenManager is TokenMultiTimelock {
    using SafeMathUintLib for uint256;

     
     
     
    uint256[] public totalReleasedAmounts;
    uint256[] public totalReleasedAmountBlocks;

     
     
     
    constructor(address deployer)
    public
    TokenMultiTimelock(deployer)
    {
    }

     
     
     
     
     
     
    function release(uint256 index)
    public
    onlyBeneficiary
    {
         
        super.release(index);

         
        _addAmountBlocks(index);
    }

     
     
     
     
     
    function releasedAmountBlocksIn(uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock);

        if (executedReleasesCount == 0 || endBlock < releases[0].blockNumber)
            return 0;

        uint256 i = 0;
        while (i < executedReleasesCount && releases[i].blockNumber < startBlock)
            i++;

        uint256 r;
        if (i >= executedReleasesCount)
            r = totalReleasedAmounts[executedReleasesCount - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : releases[i - 1].blockNumber;

            uint256 h = releases[i].blockNumber;
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : totalReleasedAmountBlocks[i].mul(h).div(releases[i].blockNumber.sub(l));
            i++;

            while (i < executedReleasesCount && releases[i].blockNumber < endBlock) {
                r = r.add(totalReleasedAmountBlocks[i]);
                i++;
            }

            if (i >= executedReleasesCount)
                r = r.add(
                    totalReleasedAmounts[executedReleasesCount - 1].mul(
                        endBlock.sub(releases[executedReleasesCount - 1].blockNumber)
                    )
                );

            else if (releases[i - 1].blockNumber < endBlock)
                r = r.add(
                    totalReleasedAmountBlocks[i].mul(
                        endBlock.sub(releases[i - 1].blockNumber)
                    ).div(
                        releases[i].blockNumber.sub(releases[i - 1].blockNumber)
                    )
                );
        }

        return r;
    }

     
     
     
    function releaseBlockNumbers(uint256 index)
    public
    view
    returns (uint256)
    {
        return releases[index].blockNumber;
    }

     
     
     
    function _addAmountBlocks(uint256 index)
    private
    {
         
        if (0 < index) {
            totalReleasedAmounts.push(
                totalReleasedAmounts[index - 1] + releases[index].amount
            );
            totalReleasedAmountBlocks.push(
                totalReleasedAmounts[index - 1].mul(
                    releases[index].blockNumber.sub(releases[index - 1].blockNumber)
                )
            );

        } else {
            totalReleasedAmounts.push(releases[index].amount);
            totalReleasedAmountBlocks.push(0);
        }
    }
}