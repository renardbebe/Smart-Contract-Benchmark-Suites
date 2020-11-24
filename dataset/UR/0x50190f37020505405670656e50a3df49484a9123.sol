 

pragma solidity ^0.5.8;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 

library CompatibleERC20Functions {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

     
     
    function safeTransferFromWithFees(IERC20 token, address from, address to, uint256 value) internal returns (uint256) {
        uint256 balancesBefore = token.balanceOf(to);
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(previousReturnValue(), "transferFrom failed");
        uint256 balancesAfter = token.balanceOf(to);
        return Math.min(value, balancesAfter.sub(balancesBefore));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0), "must first reset approval");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         

        require(address(token).isContract(), "token not found");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "token call failed");

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)), "token call failed");
        }
    }

     
     
     
    function previousReturnValue() private pure returns (bool)
    {
        uint256 returnData = 0;

        assembly {  
             
            switch returndatasize

             
            case 0 {
                returnData := 1
            }

             
            case 32 {
                 
                returndatacopy(0, 0, 32)

                 
                returnData := mload(0)
            }

             
            default { }
        }

        return returnData != 0;
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
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

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
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

 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

contract RenToken is Ownable, ERC20Detailed, ERC20Pausable, ERC20Burnable {

    string private constant _name = "Republic Token";
    string private constant _symbol = "REN";
    uint8 private constant _decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(_decimals);

     
    constructor() ERC20Burnable() ERC20Pausable() ERC20Detailed(_name, _symbol, _decimals) public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
         
         
        require(amount > 0);

        _transfer(msg.sender, beneficiary, amount);
        emit Transfer(msg.sender, beneficiary, amount);

        return true;
    }
}

 
 
 
contract DarknodeSlasher is Ownable {

    DarknodeRegistry public darknodeRegistry;

    constructor(DarknodeRegistry _darknodeRegistry) public {
        darknodeRegistry = _darknodeRegistry;
    }

    function slash(address _prover, address _challenger1, address _challenger2)
        external
        onlyOwner
    {
        darknodeRegistry.slash(_prover, _challenger1, _challenger2);
    }
}

 
contract Claimable {
    address private _pendingOwner;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner");
        _;
    }

     
    modifier onlyPendingOwner() {
      require(msg.sender == _pendingOwner, "caller is not the pending owner");
      _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
      _pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
      emit OwnershipTransferred(_owner, _pendingOwner);
      _owner = _pendingOwner;
      _pendingOwner = address(0);
    }
}

 
library LinkedList {

     
    address public constant NULL = address(0);

     
    struct Node {
        bool inList;
        address previous;
        address next;
    }

     
    struct List {
        mapping (address => Node) list;
    }

     
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

         
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

     
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

         
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

     
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "not in list");
        if (node == NULL) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

         
         
        self.list[node].inList = false;
        delete self.list[node];
    }

     
    function prepend(List storage self, address node) internal {
         

        insertBefore(self, begin(self), node);
    }

     
    function append(List storage self, address node) internal {
         

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
         

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

     
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

     
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].previous;
    }

}

 
 
 
contract DarknodeRegistryStore is Claimable {
    using SafeMath for uint256;

    string public VERSION;  

     
     
     
     
     
    struct Darknode {
         
         
         
         
        address payable owner;

         
         
         
        uint256 bond;

         
        uint256 registeredAt;

         
        uint256 deregisteredAt;

         
         
         
         
        bytes publicKey;
    }

     
    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;

     
    RenToken public ren;

     
     
     
     
    constructor(
        string memory _VERSION,
        RenToken _ren
    ) public {
        VERSION = _VERSION;
        ren = _ren;
    }

     
     
     
     
     
     
     
     
     
    function appendDarknode(
        address _darknodeID,
        address payable _darknodeOwner,
        uint256 _bond,
        bytes calldata _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOwner,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

     
    function begin() external view onlyOwner returns(address) {
        return LinkedList.begin(darknodes);
    }

     
     
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodes, darknodeID);
    }

     
     
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(ren.transfer(owner(), bond), "bond transfer failed");
    }

     
     
    function updateDarknodeBond(address darknodeID, uint256 decreasedBond) external onlyOwner {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        require(decreasedBond < previousBond, "bond not decreased");
        darknodeRegistry[darknodeID].bond = decreasedBond;
        require(ren.transfer(owner(), previousBond.sub(decreasedBond)), "bond transfer failed");
    }

     
    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

     
    function darknodeOwner(address darknodeID) external view onlyOwner returns (address payable) {
        return darknodeRegistry[darknodeID].owner;
    }

     
    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].bond;
    }

     
    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].registeredAt;
    }

     
    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

     
    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes memory) {
        return darknodeRegistry[darknodeID].publicKey;
    }
}

 
 
contract DarknodeRegistry is Ownable {
    using SafeMath for uint256;

    string public VERSION;  

     
     
     
    struct Epoch {
        uint256 epochhash;
        uint256 blocknumber;
    }

    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;

     
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;

     
     
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;

     
    Epoch public currentEpoch;
    Epoch public previousEpoch;

     
    RenToken public ren;

     
    DarknodeRegistryStore public store;

     
    DarknodeSlasher public slasher;
    DarknodeSlasher public nextSlasher;

     
     
     
    event LogDarknodeRegistered(address indexed _darknodeID, uint256 _bond);

     
     
    event LogDarknodeDeregistered(address indexed _darknodeID);

     
     
     
    event LogDarknodeOwnerRefunded(address indexed _owner, uint256 _amount);

     
    event LogNewEpoch(uint256 indexed epochhash);

     
    event LogMinimumBondUpdated(uint256 previousMinimumBond, uint256 nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 previousMinimumPodSize, uint256 nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 previousMinimumEpochInterval, uint256 nextMinimumEpochInterval);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

     
    modifier onlyDarknodeOwner(address _darknodeID) {
        require(store.darknodeOwner(_darknodeID) == msg.sender, "must be darknode owner");
        _;
    }

     
    modifier onlyRefunded(address _darknodeID) {
        require(isRefunded(_darknodeID), "must be refunded or never registered");
        _;
    }

     
    modifier onlyRefundable(address _darknodeID) {
        require(isRefundable(_darknodeID), "must be deregistered for at least one epoch");
        _;
    }

     
     
    modifier onlyDeregisterable(address _darknodeID) {
        require(isDeregisterable(_darknodeID), "must be deregisterable");
        _;
    }

     
    modifier onlySlasher() {
        require(address(slasher) == msg.sender, "must be slasher");
        _;
    }

     
     
     
     
     
     
     
     
     
     
    constructor(
        string memory _VERSION,
        RenToken _renAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochInterval
    ) public {
        VERSION = _VERSION;

        store = _storeAddress;
        ren = _renAddress;

        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;

        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;

        minimumEpochInterval = _minimumEpochInterval;
        nextMinimumEpochInterval = minimumEpochInterval;

        currentEpoch = Epoch({
            epochhash: uint256(blockhash(block.number - 1)),
            blocknumber: block.number
        });
        numDarknodes = 0;
        numDarknodesNextEpoch = 0;
        numDarknodesPreviousEpoch = 0;
    }

     
     
     
     
     
     
     
     
     
     
    function register(address _darknodeID, bytes calldata _publicKey) external onlyRefunded(_darknodeID) {
         
        uint256 bond = minimumBond;

         
        require(ren.transferFrom(msg.sender, address(store), bond), "bond transfer failed");

         
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            bond,
            _publicKey,
            currentEpoch.blocknumber.add(minimumEpochInterval),
            0
        );

        numDarknodesNextEpoch = numDarknodesNextEpoch.add(1);

         
        emit LogDarknodeRegistered(_darknodeID, bond);
    }

     
     
     
     
     
     
    function deregister(address _darknodeID) external onlyDeregisterable(_darknodeID) onlyDarknodeOwner(_darknodeID) {
        deregisterDarknode(_darknodeID);
    }

     
     
     
    function epoch() external {
        if (previousEpoch.blocknumber == 0) {
             
            require(msg.sender == owner(), "not authorized (first epochs)");
        }

         
        require(block.number >= currentEpoch.blocknumber.add(minimumEpochInterval), "epoch interval has not passed");
        uint256 epochhash = uint256(blockhash(block.number - 1));

         
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocknumber: block.number
        });

         
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;

         
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, nextMinimumEpochInterval);
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(address(slasher), address(nextSlasher));
        }

         
        emit LogNewEpoch(epochhash);
    }

     
     
     
    function transferStoreOwnership(address _newOwner) external onlyOwner {
        store.transferOwnership(_newOwner);
    }

     
     
     
    function claimStoreOwnership() external onlyOwner {
        store.claimOwnership();
    }

     
     
     
    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
         
        nextMinimumBond = _nextMinimumBond;
    }

     
     
    function updateMinimumPodSize(uint256 _nextMinimumPodSize) external onlyOwner {
         
        nextMinimumPodSize = _nextMinimumPodSize;
    }

     
     
    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval) external onlyOwner {
         
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

     
     
     
    function updateSlasher(DarknodeSlasher _slasher) external onlyOwner {
        require(address(_slasher) != address(0), "invalid slasher address");
        nextSlasher = _slasher;
    }

     
     
     
     
     
     
     
     
     
    function slash(address _prover, address _challenger1, address _challenger2)
        external
        onlySlasher
    {
        uint256 penalty = store.darknodeBond(_prover) / 2;
        uint256 reward = penalty / 4;

         
        store.updateDarknodeBond(_prover, penalty);

         
        if (isDeregisterable(_prover)) {
            deregisterDarknode(_prover);
        }

         
         
        require(ren.transfer(store.darknodeOwner(_challenger1), reward), "reward transfer failed");
        require(ren.transfer(store.darknodeOwner(_challenger2), reward), "reward transfer failed");
    }

     
     
     
     
     
     
    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOwner = store.darknodeOwner(_darknodeID);

         
        uint256 amount = store.darknodeBond(_darknodeID);

         
        store.removeDarknode(_darknodeID);

         
        require(ren.transfer(darknodeOwner, amount), "bond transfer failed");

         
        emit LogDarknodeOwnerRefunded(darknodeOwner, amount);
    }

     
     
    function getDarknodeOwner(address _darknodeID) external view returns (address payable) {
        return store.darknodeOwner(_darknodeID);
    }

     
     
    function getDarknodeBond(address _darknodeID) external view returns (uint256) {
        return store.darknodeBond(_darknodeID);
    }

     
     
    function getDarknodePublicKey(address _darknodeID) external view returns (bytes memory) {
        return store.darknodePublicKey(_darknodeID);
    }

     
     
     
     
     
     
     
     
     
     
    function getDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

     
     
    function getPreviousDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

     
     
     
    function isPendingRegistration(address _darknodeID) external view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocknumber;
    }

     
     
    function isPendingDeregistration(address _darknodeID) external view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocknumber;
    }

     
    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocknumber;
    }

     
     
     
    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
         
         
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

     
     
     
    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

     
     
    function isRefundable(address _darknodeID) public view returns (bool) {
        return isDeregistered(_darknodeID) && store.darknodeDeregisteredAt(_darknodeID) <= previousEpoch.blocknumber;
    }

     
    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

     
    function isRegisteredInPreviousEpoch(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

     
     
     
     
    function isRegisteredInEpoch(address _darknodeID, Epoch memory _epoch) private view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocknumber;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > _epoch.blocknumber;
         
         
        return registered && notDeregistered;
    }

     
     
     
     
     
    function getDarknodesFromEpochs(address _start, uint256 _count, bool _usePreviousEpoch) private view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }

        address[] memory nodes = new address[](count);

         
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = store.begin();
        }

         
        while (n < count) {
            if (next == address(0)) {
                break;
            }
             
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }

     
    function deregisterDarknode(address _darknodeID) private {
         
        store.updateDarknodeDeregisteredAt(_darknodeID, currentEpoch.blocknumber.add(minimumEpochInterval));
        numDarknodesNextEpoch = numDarknodesNextEpoch.sub(1);

         
        emit LogDarknodeDeregistered(_darknodeID);
    }
}

 
 
 
 
contract DarknodePaymentStore is Claimable {
    using SafeMath for uint256;
    using CompatibleERC20Functions for ERC20;

    string public VERSION;  

     
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    uint256 public darknodeWhitelistLength;

     
    mapping(address => mapping(address => uint256)) public darknodeBalances;

     
    mapping(address => uint256) public lockedBalances;

     
    mapping(address => uint256) public darknodeBlacklist;

     
    mapping(address => uint256) public darknodeWhitelist;

     
     
     
    constructor(
        string memory _VERSION
    ) public {
        VERSION = _VERSION;
    }

     
    function () external payable {
    }

     
     
     
     
    function isBlacklisted(address _darknode) public view returns (bool) {
        return darknodeBlacklist[_darknode] != 0;
    }

     
     
     
     
    function isWhitelisted(address _darknode) public view returns (bool) {
        return darknodeWhitelist[_darknode] != 0;
    }

     
     
     
     
    function totalBalance(address _token) public view returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        } else {
            return ERC20(_token).balanceOf(address(this));
        }
    }

     
     
     
     
     
     
    function availableBalance(address _token) public view returns (uint256) {
        return totalBalance(_token).sub(lockedBalances[_token]);
    }

     
     
     
     
     
    function blacklist(address _darknode) external onlyOwner {
        require(!isBlacklisted(_darknode), "darknode already blacklisted");
        darknodeBlacklist[_darknode] = block.timestamp;

         
        if (isWhitelisted(_darknode)) {
            darknodeWhitelist[_darknode] = 0;
             
            darknodeWhitelistLength = darknodeWhitelistLength.sub(1);
        }
    }

     
     
     
     
    function whitelist(address _darknode) external onlyOwner {
        require(!isBlacklisted(_darknode), "darknode is blacklisted");
        require(!isWhitelisted(_darknode), "darknode already whitelisted");

        darknodeWhitelist[_darknode] = block.timestamp;
        darknodeWhitelistLength++;
    }

     
     
     
     
     
     
    function incrementDarknodeBalance(address _darknode, address _token, uint256 _amount) external onlyOwner {
        require(_amount > 0, "invalid amount");
        require(availableBalance(_token) >= _amount, "insufficient contract balance");

        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token].add(_amount);
        lockedBalances[_token] = lockedBalances[_token].add(_amount);
    }

     
     
     
     
     
     
    function transfer(address _darknode, address _token, uint256 _amount, address payable _recipient) external onlyOwner {
        require(darknodeBalances[_darknode][_token] >= _amount, "insufficient darknode balance");
        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token].sub(_amount);
        lockedBalances[_token] = lockedBalances[_token].sub(_amount);

        if (_token == ETHEREUM) {
            _recipient.transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

}

 
 
contract DarknodePayment is Ownable {
    using SafeMath for uint256;
    using CompatibleERC20Functions for ERC20;

    string public VERSION;  

     
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DarknodeRegistry public darknodeRegistry;  

     
     
    DarknodePaymentStore public store;  

     
    address public blacklister;

    uint256 public currentCycle;
    uint256 public previousCycle;

     
    uint256 public shareCount;

     
     
     
    address[] public pendingTokens;

     
     
    address[] public registeredTokens;

     
     
    mapping(address => uint256) public registeredTokenIndex;

     
     
     
    mapping(address => uint256) public unclaimedRewards;

     
     
    mapping(address => uint256) public previousCycleRewardShare;

     
    uint256 public cycleStartTime;

     
    uint256 public cycleDuration;

     
    uint256 public cycleTimeout;

     
     
     
    mapping(address => mapping(uint256 => bool)) public rewardClaimed;

     
     
     
    event LogDarknodeBlacklisted(address indexed _darknode, uint256 _time);

     
     
     
    event LogDarknodeWhitelisted(address indexed _darknode, uint256 _time);

     
     
     
    event LogDarknodeClaim(address indexed _darknode, uint256 _cycle);

     
     
     
     
    event LogPaymentReceived(address indexed _payer, uint256 _amount, address _token);

     
     
     
     
    event LogDarknodeWithdrew(address indexed _payee, uint256 _value, address _token);

     
     
     
     
    event LogNewCycle(uint256 _newCycle, uint256 _lastCycle, uint256 _cycleTimeout);

     
     
     
    event LogCycleDurationChanged(uint256 _newDuration, uint256 _oldDuration);

     
     
     
    event LogBlacklisterChanged(address _newBlacklister, address _oldBlacklister);

     
     
    event LogTokenRegistered(address _token);

     
     
    event LogTokenDeregistered(address _token);

     
    modifier onlyDarknode(address _darknode) {
        require(darknodeRegistry.isRegistered(_darknode), "darknode is not registered");
        _;
    }

     
    modifier onlyBlacklister() {
        require(blacklister == msg.sender, "not Blacklister");
        _;
    }

     
    modifier notBlacklisted(address _darknode) {
        require(!store.isBlacklisted(_darknode), "darknode is blacklisted");
        _;
    }

     
     
     
     
     
     
     
     
    constructor(
        string memory _VERSION,
        DarknodeRegistry _darknodeRegistry,
        DarknodePaymentStore _darknodePaymentStore,
        uint256 _cycleDurationSeconds
    ) public {
        VERSION = _VERSION;
        darknodeRegistry = _darknodeRegistry;
        store = _darknodePaymentStore;
        cycleDuration = _cycleDurationSeconds;
         
        blacklister = msg.sender;

         
        currentCycle = block.number;
        cycleStartTime = block.timestamp;
        cycleTimeout = cycleStartTime.add(cycleDuration);
    }

     
     
     
     
     
    function withdraw(address _darknode, address _token) public {
        address payable darknodeOwner = darknodeRegistry.getDarknodeOwner(_darknode);
        require(darknodeOwner != address(0x0), "invalid darknode owner");

        uint256 amount = store.darknodeBalances(_darknode, _token);
        require(amount > 0, "nothing to withdraw");

        store.transfer(_darknode, _token, amount, darknodeOwner);
        emit LogDarknodeWithdrew(_darknode, amount, _token);
    }

    function withdrawMultiple(address _darknode, address[] calldata _tokens) external {
        for (uint i = 0; i < _tokens.length; i++) {
            withdraw(_darknode, _tokens[i]);
        }
    }

     
    function () external payable {
        address(store).transfer(msg.value);
        emit LogPaymentReceived(msg.sender, msg.value, ETHEREUM);
    }

     
     
    function currentCycleRewardPool(address _token) external view returns (uint256) {
        return store.availableBalance(_token).sub(unclaimedRewards[_token]);
    }

    function darknodeBalances(address _darknodeID, address _token) external view returns (uint256) {
        return store.darknodeBalances(_darknodeID, _token);
    }

     
    function changeCycle() external returns (uint256) {
        require(now >= cycleTimeout, "cannot cycle yet: too early");
        require(block.number != currentCycle, "no new block");

         
        uint arrayLength = registeredTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            _snapshotBalance(registeredTokens[i]);
        }

         
        previousCycle = currentCycle;
        currentCycle = block.number;
        cycleStartTime = block.timestamp;
        cycleTimeout = cycleStartTime.add(cycleDuration);

         
        shareCount = store.darknodeWhitelistLength();
         
        _updateTokenList();

        emit LogNewCycle(currentCycle, previousCycle, cycleTimeout);
        return currentCycle;
    }

     
     
     
     
    function deposit(uint256 _value, address _token) external payable {
        uint256 receivedValue;
        if (_token == ETHEREUM) {
            require(_value == msg.value, "mismatched deposit value");
            receivedValue = msg.value;
            address(store).transfer(msg.value);
        } else {
            require(msg.value == 0, "unexpected ether transfer");
             
            receivedValue = ERC20(_token).safeTransferFromWithFees(msg.sender, address(store), _value);
        }
        emit LogPaymentReceived(msg.sender, receivedValue, _token);
    }

     
     
     
     
     
     
    function claim(address _darknode) external onlyDarknode(_darknode) notBlacklisted(_darknode) {
        uint256 whitelistedTime = store.darknodeWhitelist(_darknode);

         
        if (whitelistedTime == 0) {
            store.whitelist(_darknode);
            emit LogDarknodeWhitelisted(_darknode, now);
            return;
        }

        require(whitelistedTime < cycleStartTime, "cannot claim for this cycle");

         
        _claimDarknodeReward(_darknode);
        emit LogDarknodeClaim(_darknode, previousCycle);
    }

     
     
     
    function blacklist(address _darknode) external onlyBlacklister onlyDarknode(_darknode) {
        store.blacklist(_darknode);
        emit LogDarknodeBlacklisted(_darknode, now);
    }

     
     
     
     
    function registerToken(address _token) external onlyOwner {
        require(registeredTokenIndex[_token] == 0, "token already registered");
        uint arrayLength = pendingTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            require(pendingTokens[i] != _token, "token already pending registration");
        }
        pendingTokens.push(_token);
    }

     
     
     
     
    function deregisterToken(address _token) external onlyOwner {
        require(registeredTokenIndex[_token] > 0, "token not registered");
        _deregisterToken(_token);
    }

     
     
     
    function updateBlacklister(address _addr) external onlyOwner {
        require(_addr != address(0), "invalid contract address");
        emit LogBlacklisterChanged(_addr, blacklister);
        blacklister = _addr;
    }

     
     
     
     
    function updateCycleDuration(uint256 _durationSeconds) external onlyOwner {
        uint256 oldDuration = cycleDuration;
        cycleDuration = _durationSeconds;
        emit LogCycleDurationChanged(cycleDuration, oldDuration);
    }

     
     
     
     
    function transferStoreOwnership(address _newOwner) external onlyOwner {
        store.transferOwnership(_newOwner);
    }

     
     
     
    function claimStoreOwnership() external onlyOwner {
        store.claimOwnership();
    }

     
     
     
     
     
    function _claimDarknodeReward(address _darknode) private {
        require(!rewardClaimed[_darknode][previousCycle], "reward already claimed");
        rewardClaimed[_darknode][previousCycle] = true;
        uint arrayLength = registeredTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            address token = registeredTokens[i];

             
            if (previousCycleRewardShare[token] > 0) {
                unclaimedRewards[token] = unclaimedRewards[token].sub(previousCycleRewardShare[token]);
                store.incrementDarknodeBalance(_darknode, token, previousCycleRewardShare[token]);
            }
        }
    }

     
     
     
     
    function _snapshotBalance(address _token) private {
        if (shareCount == 0) {
            unclaimedRewards[_token] = 0;
            previousCycleRewardShare[_token] = 0;
        } else {
             
            unclaimedRewards[_token] = store.availableBalance(_token);
            previousCycleRewardShare[_token] = unclaimedRewards[_token].div(shareCount);
        }
    }

     
     
     
     
    function _deregisterToken(address _token) private {
        address lastToken = registeredTokens[registeredTokens.length.sub(1)];
        uint256 deletedTokenIndex = registeredTokenIndex[_token].sub(1);
         
        registeredTokens[deletedTokenIndex] = lastToken;
        registeredTokenIndex[lastToken] = registeredTokenIndex[_token];
         
         
        registeredTokens.length = registeredTokens.length.sub(1);
        registeredTokenIndex[_token] = 0;

        emit LogTokenDeregistered(_token);
    }

     
     
    function _updateTokenList() private {
         
        uint arrayLength = pendingTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            address token = pendingTokens[i];
            registeredTokens.push(token);
            registeredTokenIndex[token] = registeredTokens.length;
            emit LogTokenRegistered(token);
        }
        pendingTokens.length = 0;
    }

}