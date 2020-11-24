 

pragma solidity ^0.5.11;


contract Resolvable {
    
    function resolveIfCriteriaMet()
    public;

    
    
    function resolutionCriteriaMet()
    public
    view
    returns (bool);

    
    
    
    function resolutionDeltaAmount(bool _status)
    public
    view
    returns (uint256);
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract RBACed {
    using Roles for Roles.Role;

    event RoleAdded(string _role);
    event RoleAccessorAdded(string _role, address indexed _address);
    event RoleAccessorRemoved(string _role, address indexed _address);

    string constant public OWNER_ROLE = "OWNER";

    string[] public roles;
    mapping(bytes32 => uint256) roleIndexByName;
    mapping(bytes32 => Roles.Role) private roleByName;

    
    constructor()
    public
    {
        
        _addRole(OWNER_ROLE);

        
        _addRoleAccessor(OWNER_ROLE, msg.sender);
    }

    modifier onlyRoleAccessor(string memory _role) {
        require(isRoleAccessor(_role, msg.sender), "RBACed: sender is not accessor of the role");
        _;
    }

    
    
    function rolesCount()
    public
    view
    returns (uint256)
    {
        return roles.length;
    }

    
    
    
    function isRole(string memory _role)
    public
    view
    returns (bool)
    {
        return 0 != roleIndexByName[_role2Key(_role)];
    }

    
    
    function addRole(string memory _role)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        _addRole(_role);

        
        emit RoleAdded(_role);
    }

    
    
    
    
    function isRoleAccessor(string memory _role, address _address)
    public
    view
    returns (bool)
    {
        return roleByName[_role2Key(_role)].has(_address);
    }

    
    
    
    function addRoleAccessor(string memory _role, address _address)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        _addRoleAccessor(_role, _address);

        
        emit RoleAccessorAdded(_role, _address);
    }

    
    
    
    function removeRoleAccessor(string memory _role, address _address)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        roleByName[_role2Key(_role)].remove(_address);

        
        emit RoleAccessorRemoved(_role, _address);
    }

    function _addRole(string memory _role)
    internal
    {
        if (0 == roleIndexByName[_role2Key(_role)]) {
            roles.push(_role);
            roleIndexByName[_role2Key(_role)] = roles.length;
        }
    }

    function _addRoleAccessor(string memory _role, address _address)
    internal
    {
        roleByName[_role2Key(_role)].add(_address);
    }

    function _role2Key(string memory _role)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_role));
    }
}

contract Able {
    event Disabled(string _name);
    event Enabled(string _name);

    mapping(string => bool) private _disabled;

    
    
    function enable(string memory _name)
    public
    {
        
        require(_disabled[_name], "Able: name is enabled");

        
        _disabled[_name] = false;

        
        emit Enabled(_name);
    }

    
    
    function disable(string memory _name)
    public
    {
        
        require(!_disabled[_name], "Able: name is disabled");

        
        _disabled[_name] = true;

        
        emit Disabled(_name);
    }

    
    
    function enabled(string memory _name)
    public
    view
    returns (bool)
    {
        return !_disabled[_name];
    }

    
    
    function disabled(string memory _name)
    public
    view
    returns (bool)
    {
        return _disabled[_name];
    }

    modifier onlyEnabled(string memory _name) {
        require(enabled(_name), "Able: name is disabled");
        _;
    }

    modifier onlyDisabled(string memory _name) {
        require(disabled(_name), "Able: name is enabled");
        _;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library VerificationPhaseLib {
    using SafeMath for uint256;

    enum State {Unopened, Opened, Closed}
    enum Status {Null, True, False}

    struct VerificationPhase {
        State state;
        Status result;

        uint256 stakedAmount;
        mapping(bool => uint256) stakedAmountByStatus;
        mapping(address => mapping(bool => uint256)) stakedAmountByWalletStatus;
        mapping(uint256 => mapping(bool => uint256)) stakedAmountByBlockStatus;

        mapping(address => bool) stakedByWallet;
        uint256 stakingWallets;

        uint256 bountyAmount;
        bool bountyAwarded;

        uint256 startBlock;
        uint256 endBlock;

        uint256[] uintCriteria;
    }

    function open(VerificationPhase storage _phase, uint256 _bountyAmount) internal {
        _phase.state = State.Opened;
        _phase.bountyAmount = _bountyAmount;
        _phase.startBlock = block.number;
    }

    function close(VerificationPhase storage _phase) internal {
        _phase.state = State.Closed;
        _phase.endBlock = block.number;
        if (_phase.stakedAmountByStatus[true] > _phase.stakedAmountByStatus[false])
            _phase.result = Status.True;
        else if (_phase.stakedAmountByStatus[true] < _phase.stakedAmountByStatus[false])
            _phase.result = Status.False;
    }

    function stake(VerificationPhase storage _phase, address _wallet,
        bool _status, uint256 _amount) internal {
        _phase.stakedAmount = _phase.stakedAmount.add(_amount);
        _phase.stakedAmountByStatus[_status] = _phase.stakedAmountByStatus[_status].add(_amount);
        _phase.stakedAmountByWalletStatus[_wallet][_status] =
        _phase.stakedAmountByWalletStatus[_wallet][_status].add(_amount);
        _phase.stakedAmountByBlockStatus[block.number][_status] =
        _phase.stakedAmountByBlockStatus[block.number][_status].add(_amount);

        if (!_phase.stakedByWallet[_wallet]) {
            _phase.stakedByWallet[_wallet] = true;
            _phase.stakingWallets = _phase.stakingWallets.add(1);
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

interface Allocator {
    
    function allocate()
    external
    view
    returns (uint256);
}

contract BountyFund is RBACed {
    using SafeMath for uint256;

    event ResolutionEngineSet(address indexed _resolutionEngine);
    event TokensDeposited(address indexed _wallet, uint256 _amount, uint256 _balance);
    event TokensAllocated(address indexed _wallet, address indexed _allocator,
        uint256 _amount, uint256 _balance);
    event Withdrawn(address indexed _wallet, uint256 _amount);

    ERC20 public token;

    address public operator;
    address public resolutionEngine;

    
    constructor(address _token, address _operator)
    public
    {
        
        token = ERC20(_token);

        
        operator = _operator;
    }

    modifier onlyResolutionEngine() {
        require(msg.sender == resolutionEngine, "BountyFund: sender is not the defined resolution engine");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "BountyFund: sender is not the defined operator");
        _;
    }

    
    
    
    function setResolutionEngine(address _resolutionEngine)
    public
    {
        require(address(0) != _resolutionEngine, "BountyFund: resolution engine argument is zero address");
        require(address(0) == resolutionEngine, "BountyFund: resolution engine has already been set");

        
        resolutionEngine = _resolutionEngine;

        
        emit ResolutionEngineSet(_resolutionEngine);
    }

    
    
    
    function depositTokens(uint256 _amount)
    public
    {
        
        token.transferFrom(msg.sender, address(this), _amount);

        
        emit TokensDeposited(msg.sender, _amount, token.balanceOf(address(this)));
    }

    
    
    function allocateTokens(address _allocator)
    public
    onlyResolutionEngine
    returns (uint256)
    {
        
        uint256 amount = Allocator(_allocator).allocate();

        
        token.transfer(msg.sender, amount);

        
        emit TokensAllocated(msg.sender, _allocator, amount, token.balanceOf(address(this)));

        
        return amount;
    }

    
    
    function withdraw(address _wallet)
    public
    onlyOperator
    {
        
        uint256 amount = token.balanceOf(address(this));

        
        token.transfer(_wallet, amount);

        
        emit Withdrawn(_wallet, amount);
    }
}

contract ResolutionEngine is Resolvable, RBACed, Able {
    using SafeMath for uint256;
    using VerificationPhaseLib for VerificationPhaseLib.VerificationPhase;

    event Frozen();
    event BountyAllocatorSet(address indexed _bountyAllocator);
    event Staked(address indexed _wallet, uint256 indexed _verificationPhaseNumber, bool _status,
        uint256 _amount);
    event BountyWithdrawn(address indexed _wallet, uint256 _bountyAmount);
    event VerificationPhaseOpened(uint256 indexed _verificationPhaseNumber, uint256 _bountyAmount);
    event VerificationPhaseClosed(uint256 indexed _verificationPhaseNumber);
    event PayoutStaged(address indexed _wallet, uint256 indexed _firstVerificationPhaseNumber,
        uint256 indexed _lastVerificationPhaseNumber, uint256 _payout);
    event StakeStaged(address indexed _wallet, uint _amount);
    event Staged(address indexed _wallet, uint _amount);
    event Withdrawn(address indexed _wallet, uint _amount);

    string constant public STAKE_ACTION = "STAKE";
    string constant public RESOLVE_ACTION = "RESOLVE";

    address public oracle;
    address public operator;
    address public bountyAllocator;

    BountyFund public bountyFund;

    ERC20 public token;

    bool public frozen;

    uint256 public verificationPhaseNumber;

    mapping(uint256 => VerificationPhaseLib.VerificationPhase) public verificationPhaseByPhaseNumber;

    mapping(address => mapping(bool => uint256)) public stakedAmountByWalletStatus;
    mapping(uint256 => mapping(bool => uint256)) public stakedAmountByBlockStatus;

    VerificationPhaseLib.Status public verificationStatus;

    mapping(address => mapping(uint256 => bool)) public payoutStagedByWalletPhase;
    mapping(address => uint256) public stagedAmountByWallet;

    
    constructor(address _oracle, address _operator, address _bountyFund)
    public
    {
        
        oracle = _oracle;
        operator = _operator;

        
        bountyFund = BountyFund(_bountyFund);
        bountyFund.setResolutionEngine(address(this));

        
        token = ERC20(bountyFund.token());
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "ResolutionEngine: sender is not the defined oracle");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "ResolutionEngine: sender is not the defined operator");
        _;
    }

    modifier onlyNotFrozen() {
        require(!frozen, "ResolutionEngine: is frozen");
        _;
    }

    
    
    function freeze()
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        frozen = true;

        
        emit Frozen();
    }

    
    
    function setBountyAllocator(address _bountyAllocator)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        bountyAllocator = _bountyAllocator;

        
        emit BountyAllocatorSet(bountyAllocator);
    }

    
    function initialize()
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        require(0 == verificationPhaseNumber, "ResolutionEngine: already initialized");

        
        _openVerificationPhase();
    }

    
    
    function disable(string memory _action)
    public
    onlyOperator
    {
        
        super.disable(_action);
    }

    
    
    function enable(string memory _action)
    public
    onlyOperator
    {
        
        super.enable(_action);
    }

    
    
    
    
    
    function stake(address _wallet, bool _status, uint256 _amount)
    public
    onlyOracle
    onlyEnabled(STAKE_ACTION)
    {
        
        stakedAmountByWalletStatus[_wallet][_status] = stakedAmountByWalletStatus[_wallet][_status].add(_amount);
        stakedAmountByBlockStatus[block.number][_status] = stakedAmountByBlockStatus[block.number][_status]
        .add(_amount);
        verificationPhaseByPhaseNumber[verificationPhaseNumber].stake(_wallet, _status, _amount);

        
        emit Staked(_wallet, verificationPhaseNumber, _status, _amount);
    }

    
    
    
    function resolveIfCriteriaMet()
    public
    onlyOracle
    onlyEnabled(RESOLVE_ACTION)
    {
        
        if (resolutionCriteriaMet()) {
            
            _closeVerificationPhase();

            
            _openVerificationPhase();
        }
    }

    
    
    
    function metricsByVerificationPhaseNumber(uint256 _verificationPhaseNumber)
    public
    view
    returns (VerificationPhaseLib.State state, uint256 trueStakeAmount, uint256 falseStakeAmount,
        uint256 stakeAmount, uint256 numberOfWallets, uint256 bountyAmount, bool bountyAwarded,
        uint256 startBlock, uint256 endBlock, uint256 numberOfBlocks)
    {
        state = verificationPhaseByPhaseNumber[_verificationPhaseNumber].state;
        trueStakeAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber].stakedAmountByStatus[true];
        falseStakeAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber].stakedAmountByStatus[false];
        stakeAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber].stakedAmount;
        numberOfWallets = verificationPhaseByPhaseNumber[_verificationPhaseNumber].stakingWallets;
        bountyAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber].bountyAmount;
        bountyAwarded = verificationPhaseByPhaseNumber[_verificationPhaseNumber].bountyAwarded;
        startBlock = verificationPhaseByPhaseNumber[_verificationPhaseNumber].startBlock;
        endBlock = verificationPhaseByPhaseNumber[_verificationPhaseNumber].endBlock;
        numberOfBlocks = (startBlock > 0 && endBlock == 0 ? block.number : endBlock).sub(startBlock);
    }

    
    
    
    
    
    function metricsByVerificationPhaseNumberAndWallet(uint256 _verificationPhaseNumber, address _wallet)
    public
    view
    returns (uint256 trueStakeAmount, uint256 falseStakeAmount, uint256 stakeAmount)
    {
        trueStakeAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber]
        .stakedAmountByWalletStatus[_wallet][true];
        falseStakeAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber]
        .stakedAmountByWalletStatus[_wallet][false];
        stakeAmount = trueStakeAmount.add(falseStakeAmount);
    }

    
    
    
    function metricsByWallet(address _wallet)
    public
    view
    returns (uint256 trueStakeAmount, uint256 falseStakeAmount, uint256 stakeAmount)
    {
        trueStakeAmount = stakedAmountByWalletStatus[_wallet][true];
        falseStakeAmount = stakedAmountByWalletStatus[_wallet][false];
        stakeAmount = trueStakeAmount.add(falseStakeAmount);
    }

    
    
    
    
    function metricsByBlockNumber(uint256 _blockNumber)
    public
    view
    returns (uint256 trueStakeAmount, uint256 falseStakeAmount, uint256 stakeAmount)
    {
        trueStakeAmount = stakedAmountByBlockStatus[_blockNumber][true];
        falseStakeAmount = stakedAmountByBlockStatus[_blockNumber][false];
        stakeAmount = trueStakeAmount.add(falseStakeAmount);
    }

    
    
    
    
    
    function calculatePayout(address _wallet, uint256 _firstVerificationPhaseNumber,
        uint256 _lastVerificationPhaseNumber)
    public
    view
    returns (uint256)
    {
        
        uint256 payout = 0;
        for (uint256 i = _firstVerificationPhaseNumber; i <= _lastVerificationPhaseNumber; i++)
            payout = payout.add(_calculatePayout(_wallet, i));

        
        return payout;
    }

    
    
    
    
    
    function stagePayout(address _wallet, uint256 _firstVerificationPhaseNumber,
        uint256 _lastVerificationPhaseNumber)
    public
    onlyOracle
    {
        
        uint256 amount = 0;
        for (uint256 i = _firstVerificationPhaseNumber; i <= _lastVerificationPhaseNumber; i++)
            amount = amount.add(_stagePayout(_wallet, i));

        
        emit PayoutStaged(_wallet, _firstVerificationPhaseNumber, _lastVerificationPhaseNumber, amount);
    }

    
    
    
    function stageStake(address _wallet)
    public
    onlyOracle
    onlyDisabled(RESOLVE_ACTION)
    {
        
        uint256 amount = verificationPhaseByPhaseNumber[verificationPhaseNumber]
        .stakedAmountByWalletStatus[_wallet][true].add(
            verificationPhaseByPhaseNumber[verificationPhaseNumber]
            .stakedAmountByWalletStatus[_wallet][false]
        );

        
        require(0 < amount, "ResolutionEngine: stake is zero");

        
        verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmountByWalletStatus[_wallet][true] = 0;
        verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmountByWalletStatus[_wallet][false] = 0;

        
        _stage(_wallet, amount);

        
        emit StakeStaged(_wallet, amount);
    }

    
    
    
    
    function stage(address _wallet, uint256 _amount)
    public
    onlyOracle
    {
        
        _stage(_wallet, _amount);

        
        emit Staged(_wallet, _amount);
    }

    
    
    
    
    function withdraw(address _wallet, uint256 _amount)
    public
    onlyOracle
    {
        
        require(_amount <= stagedAmountByWallet[_wallet], "ResolutionEngine: amount is greater than staged amount");

        
        stagedAmountByWallet[_wallet] = stagedAmountByWallet[_wallet].sub(_amount);

        
        token.transfer(_wallet, _amount);

        
        emit Withdrawn(_wallet, _amount);
    }

    
    
    function withdrawBounty(address _wallet)
    public
    onlyOperator
    onlyDisabled(RESOLVE_ACTION)
    {
        
        require(0 < verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAmount,
            "ResolutionEngine: bounty is zero");

        
        uint256 amount = verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAmount;

        
        verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAmount = 0;

        
        token.transfer(_wallet, amount);

        
        emit BountyWithdrawn(_wallet, amount);
    }

    
    function _openVerificationPhase()
    internal
    {
        
        require(
            verificationPhaseByPhaseNumber[verificationPhaseNumber.add(1)].state == VerificationPhaseLib.State.Unopened,
            "ResolutionEngine: verification phase is not in unopened state"
        );

        
        verificationPhaseNumber = verificationPhaseNumber.add(1);

        
        uint256 bountyAmount = bountyFund.allocateTokens(bountyAllocator);

        
        verificationPhaseByPhaseNumber[verificationPhaseNumber].open(bountyAmount);

        
        _addVerificationCriteria();

        
        emit VerificationPhaseOpened(verificationPhaseNumber, bountyAmount);
    }

    
    function _addVerificationCriteria() internal;

    
    function _closeVerificationPhase()
    internal
    {
        
        require(verificationPhaseByPhaseNumber[verificationPhaseNumber].state == VerificationPhaseLib.State.Opened,
            "ResolutionEngine: verification phase is not in opened state");

        
        verificationPhaseByPhaseNumber[verificationPhaseNumber].close();

        
        if (verificationPhaseByPhaseNumber[verificationPhaseNumber].result != verificationStatus) {
            
            verificationStatus = verificationPhaseByPhaseNumber[verificationPhaseNumber].result;

            
            verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAwarded = true;
        }

        
        emit VerificationPhaseClosed(verificationPhaseNumber);
    }

    
    function _calculatePayout(address _wallet, uint256 _verificationPhaseNumber)
    internal
    view
    returns (uint256)
    {
        
        if (VerificationPhaseLib.Status.Null == verificationPhaseByPhaseNumber[_verificationPhaseNumber].result)
            return 0;

        
        bool status =
        verificationPhaseByPhaseNumber[_verificationPhaseNumber].result == VerificationPhaseLib.Status.True;

        
        uint256 lot = verificationPhaseByPhaseNumber[_verificationPhaseNumber].stakedAmountByStatus[!status];

        
        if (verificationPhaseByPhaseNumber[_verificationPhaseNumber].bountyAwarded)
            lot = lot.add(verificationPhaseByPhaseNumber[_verificationPhaseNumber].bountyAmount);

        
        uint256 walletStatusAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber]
        .stakedAmountByWalletStatus[_wallet][status];
        uint256 statusAmount = verificationPhaseByPhaseNumber[_verificationPhaseNumber]
        .stakedAmountByStatus[status];

        
        
        return lot.mul(walletStatusAmount).div(statusAmount).add(walletStatusAmount);
    }

    
    function _stagePayout(address _wallet, uint256 _verificationPhaseNumber)
    internal
    returns (uint256)
    {
        
        if (VerificationPhaseLib.State.Closed != verificationPhaseByPhaseNumber[_verificationPhaseNumber].state)
            return 0;

        
        if (payoutStagedByWalletPhase[_wallet][_verificationPhaseNumber])
            return 0;

        
        payoutStagedByWalletPhase[_wallet][_verificationPhaseNumber] = true;

        
        uint256 payout = _calculatePayout(_wallet, _verificationPhaseNumber);

        
        _stage(_wallet, payout);

        
        return payout;
    }

    
    function _stage(address _wallet, uint256 _amount)
    internal
    {
        stagedAmountByWallet[_wallet] = stagedAmountByWallet[_wallet].add(_amount);
    }
}

library ConstantsLib {
    
    function PARTS_PER()
    public
    pure
    returns (uint256)
    {
        return 1e18;
    }
}

library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract BergenResolutionEngine is Resolvable, ResolutionEngine {

    event NextAlphaSet(uint256 alpha);
    event NextBetaSet(uint256 beta);
    event NextGammaSet(uint256 gamma);

    uint256 constant private ALPHA_INDEX = 0;
    uint256 constant private BETA_INDEX = 1;
    uint256 constant private GAMMA_INDEX = 2;

    uint256 public nextAlpha;
    uint256 public nextBeta;
    uint256 public nextGamma;

    
    
    
    
    
    
    
    constructor(address _oracle, address _operator, address _bountyFund,
        uint256 _nextAlpha, uint256 _nextBeta, uint256 _nextGamma)
    public
    ResolutionEngine(_oracle, _operator, _bountyFund)
    {
        nextAlpha = _nextAlpha;
        nextBeta = _nextBeta;
        nextGamma = _nextGamma;
    }

    
    
    
    function resolutionDeltaAmount(bool _status)
    public
    view
    returns (uint256)
    {
        uint256 alphaAmount = alphaResolutionDeltaAmount();
        uint256 betaAmount = betaResolutionDeltaAmount(_status);
        return Math.max(alphaAmount, betaAmount);
    }

    
    
    function alphaResolutionDeltaAmount()
    public
    view
    returns (uint256)
    {
        uint256 scaledBountyAmount = alphaByPhaseNumber(verificationPhaseNumber)
        .mul(verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAmount);
        return (
        scaledBountyAmount > verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount ?
        scaledBountyAmount.sub(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount) :
        0
        );
    }

    
    
    
    function betaResolutionDeltaAmount(bool _status)
    public
    view
    returns (uint256)
    {
        uint256 scaledStakedAmount = betaByPhaseNumber(verificationPhaseNumber)
        .mul(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount);
        uint256 scaledStatusStakedAmount = ConstantsLib.PARTS_PER()
        .mul(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmountByStatus[_status]);
        return (
        scaledStatusStakedAmount < scaledStakedAmount ?
        scaledStakedAmount.sub(scaledStatusStakedAmount).div(
            ConstantsLib.PARTS_PER().sub(betaByPhaseNumber(verificationPhaseNumber))
        ) :
        0
        );
    }

    
    
    function gammaResolutionDelta()
    public
    view
    returns (uint256)
    {
        return gammaByPhaseNumber(verificationPhaseNumber)
        .sub(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakingWallets);
    }

    
    
    function resolutionCriteriaMet()
    public
    view
    returns (bool)
    {
        return alphaCriterionMet() && betaCriterionMet() && gammaCriterionMet();
    }

    
    
    function alphaCriterionMet()
    public
    view
    returns (bool)
    {
        uint256 baseline = alphaByPhaseNumber(verificationPhaseNumber)
        .mul(verificationPhaseByPhaseNumber[verificationPhaseNumber].bountyAmount);
        return verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount >= baseline;
    }

    
    
    function betaCriterionMet()
    public
    view
    returns (bool)
    {
        if (0 == verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount)
            return false;

        bool trueCriterionMet = verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmountByStatus[true]
        .mul(ConstantsLib.PARTS_PER())
        .div(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount)
        >= betaByPhaseNumber(verificationPhaseNumber);

        bool falseCriterionMet = verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmountByStatus[false]
        .mul(ConstantsLib.PARTS_PER())
        .div(verificationPhaseByPhaseNumber[verificationPhaseNumber].stakedAmount)
        >= betaByPhaseNumber(verificationPhaseNumber);

        return trueCriterionMet || falseCriterionMet;
    }

    
    
    function gammaCriterionMet()
    public
    view
    returns (bool)
    {
        return verificationPhaseByPhaseNumber[verificationPhaseNumber].stakingWallets
        >= gammaByPhaseNumber(verificationPhaseNumber);
    }

    
    
    
    function setNextAlpha(uint256 _nextAlpha)
    public
    onlyRoleAccessor(OWNER_ROLE)
    onlyNotFrozen
    {
        
        nextAlpha = _nextAlpha;

        
        emit NextAlphaSet(nextAlpha);
    }

    
    
    
    function setNextBeta(uint256 _nextBeta)
    public
    onlyRoleAccessor(OWNER_ROLE)
    onlyNotFrozen
    {
        
        nextBeta = _nextBeta;

        
        emit NextBetaSet(nextBeta);
    }

    
    
    
    function setNextGamma(uint256 _nextGamma)
    public
    onlyRoleAccessor(OWNER_ROLE)
    onlyNotFrozen
    {
        
        nextGamma = _nextGamma;

        
        emit NextGammaSet(nextGamma);
    }

    
    
    
    function alphaByPhaseNumber(uint256 _verificationPhaseNumber)
    public
    view
    returns (uint256)
    {
        return verificationPhaseByPhaseNumber[_verificationPhaseNumber].uintCriteria[ALPHA_INDEX];
    }
    
    
    
    
    function betaByPhaseNumber(uint256 _verificationPhaseNumber)
    public
    view
    returns (uint256)
    {
        return verificationPhaseByPhaseNumber[_verificationPhaseNumber].uintCriteria[BETA_INDEX];
    }

    
    
    
    function gammaByPhaseNumber(uint256 _verificationPhaseNumber)
    public
    view
    returns (uint256)
    {
        return verificationPhaseByPhaseNumber[_verificationPhaseNumber].uintCriteria[GAMMA_INDEX];
    }

    
    function _addVerificationCriteria()
    internal
    {
        verificationPhaseByPhaseNumber[verificationPhaseNumber].uintCriteria.push(nextAlpha);
        verificationPhaseByPhaseNumber[verificationPhaseNumber].uintCriteria.push(nextBeta);
        verificationPhaseByPhaseNumber[verificationPhaseNumber].uintCriteria.push(nextGamma);
    }
}