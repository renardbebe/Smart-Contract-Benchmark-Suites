 

pragma solidity ^0.5.11;


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

library AddressStoreLib {

    struct Addresses {
        mapping(bytes32 => uint256) map;
        address[] list;
    }

    function has(Addresses storage _addresses, address _address) internal view returns (bool) {
        return (0 != _addresses.map[address2Key(_address)]);
    }

    function add(Addresses storage _addresses, address _address) internal {
        bytes32 key = address2Key(_address);
        if (_addresses.map[key] == 0) {
            _addresses.list.push(_address);
            _addresses.map[key] = _addresses.list.length;
        }
    }

    function remove(Addresses storage _addresses, address _address) internal {
        bytes32 key = address2Key(_address);
        if (_addresses.map[key] != 0) {
            if (_addresses.map[key] < _addresses.list.length) {
                _addresses.list[_addresses.map[key] - 1] = _addresses.list[_addresses.list.length - 1];
                _addresses.map[address2Key(address(_addresses.list[_addresses.map[key] - 1]))] = _addresses.map[key];
                delete _addresses.list[_addresses.list.length - 1];
            }
            _addresses.list.length--;
            _addresses.map[key] = 0;
        }
    }

    function address2Key(address _address) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }
}

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

contract Oracle is RBACed {
    using SafeMath for uint256;
    using AddressStoreLib for AddressStoreLib.Addresses;

    event ResolutionEngineAdded(address indexed _resolutionEngine);
    event ResolutionEngineRemoved(address indexed _resolutionEngine);
    event TokensStaked(address indexed _wallet, address indexed _resolutionEngine,
        bool _status, uint256 _amount);
    event PayoutStaged(address indexed _wallet, address indexed _resolutionEngine,
        uint256 _firstVerificationPhaseNumber, uint256 _lastVerificationPhaseNumber);
    event StakeStaged(address indexed _wallet, address indexed _resolutionEngine);
    event Withdrawn(address indexed _wallet, address indexed _resolutionEngine,
        uint256 _amount);

    AddressStoreLib.Addresses resolutionEngines;

    
    constructor()
    public
    {
    }

    modifier onlyRegisteredResolutionEngine(address _resolutionEngine) {
        require(hasResolutionEngine(_resolutionEngine), "Oracle: Resolution engine is not registered");
        _;
    }

    
    
    
    function hasResolutionEngine(address _resolutionEngine)
    public
    view
    returns
    (bool)
    {
        return resolutionEngines.has(_resolutionEngine);
    }

    
    
    function resolutionEnginesCount()
    public
    view
    returns (uint256)
    {
        return resolutionEngines.list.length;
    }

    
    
    function addResolutionEngine(address _resolutionEngine)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        resolutionEngines.add(_resolutionEngine);

        
        emit ResolutionEngineAdded(_resolutionEngine);
    }

    
    
    function removeResolutionEngine(address _resolutionEngine)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        resolutionEngines.remove(_resolutionEngine);

        
        emit ResolutionEngineRemoved(_resolutionEngine);
    }

    
    
    
    
    
    
    
    function stake(address _resolutionEngine, uint256 _verificationPhaseNumber, bool _status, uint256 _amount)
    public
    onlyRegisteredResolutionEngine(_resolutionEngine)
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        require(resolutionEngine.verificationPhaseNumber() == _verificationPhaseNumber,
            "Oracle: not the current verification phase number");

        
        uint256 resolutionDeltaAmount = resolutionEngine.resolutionDeltaAmount(_status);
        uint256 overageAmount = _amount > resolutionDeltaAmount ?
        _amount.sub(resolutionDeltaAmount) :
        0;

        
        ERC20 token = ERC20(resolutionEngine.token());

        
        token.transferFrom(msg.sender, _resolutionEngine, _amount);

        
        if (overageAmount > 0)
            resolutionEngine.stage(msg.sender, overageAmount);

        
        resolutionEngine.stake(msg.sender, _status, _amount.sub(overageAmount));

        
        resolutionEngine.resolveIfCriteriaMet();

        
        emit TokensStaked(msg.sender, _resolutionEngine, _status, _amount);
    }

    
    
    
    
    
    
    
    function calculatePayout(address _resolutionEngine, address _wallet, uint256 _firstVerificationPhaseNumber,
        uint256 _lastVerificationPhaseNumber)
    public
    view
    returns (uint256)
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        return resolutionEngine.calculatePayout(_wallet, _firstVerificationPhaseNumber, _lastVerificationPhaseNumber);
    }

    
    
    
    
    function stagePayout(address _resolutionEngine, uint256 _firstVerificationPhaseNumber,
        uint256 _lastVerificationPhaseNumber)
    public
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        resolutionEngine.stagePayout(msg.sender, _firstVerificationPhaseNumber, _lastVerificationPhaseNumber);

        
        emit PayoutStaged(msg.sender, _resolutionEngine, _firstVerificationPhaseNumber, _lastVerificationPhaseNumber);
    }

    
    
    function stageStake(address _resolutionEngine)
    public
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        resolutionEngine.stageStake(msg.sender);

        
        emit StakeStaged(msg.sender, _resolutionEngine);
    }

    
    
    
    
    function stagedAmountByWallet(address _resolutionEngine, address _wallet)
    public
    view
    returns (uint256)
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        return resolutionEngine.stagedAmountByWallet(_wallet);
    }

    
    
    
    function withdraw(address _resolutionEngine, uint256 _amount)
    public
    {
        
        ResolutionEngine resolutionEngine = ResolutionEngine(_resolutionEngine);

        
        resolutionEngine.withdraw(msg.sender, _amount);

        
        emit Withdrawn(msg.sender, _resolutionEngine, _amount);
    }
}