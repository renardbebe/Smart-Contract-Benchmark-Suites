 

pragma solidity ^0.4.24;

contract Ownable {

    address private _owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        _owner = msg.sender;
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
        emit OwnershipRenounced(_owner);
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
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
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
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
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

     
    function _mint(address account, uint256 amount) internal {
        require(account != 0);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != 0);
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        amount);
        _burn(account, amount);
    }
}

contract ERC20Burnable is ERC20 {

     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

     
    function _burn(address who, uint256 value) internal {
        super._burn(who, value);
    }
}

contract IFUM is Ownable, ERC20Burnable {

    string public name;
    
    string public symbol;
    
    uint8 public decimals;

    address private _crowdsale;

    bool private _freezed;

    mapping (address => bool) private _locked;
    
    constructor() public {
        symbol = "IFUM";
        name = "INFLEUM Token";
        decimals = 8;
        _crowdsale = address(0);
        _freezed = true;
    }

    function setCrowdsale(address crowdsale) public {
        require(crowdsale != address(0), "Invalid address");
        require(_crowdsale == address(0), "It is allowed only one time.");
        _crowdsale = crowdsale;
        _mint(crowdsale, 3000000000 * 10 ** uint(decimals));
    }

    function isFreezed() public view returns (bool) {
        return _freezed;
    }

    function unfreeze() public {
        require(msg.sender == _crowdsale, "Only crowdsale contract can unfreeze this token.");
        _freezed = false;
    }

    function isLocked(address account) public view returns (bool) {
        return _locked[account];
    }

    modifier test(address account) {
        require(!isLocked(account), "It is a locked account.");
        require(!_freezed || _crowdsale == account, "A token is frozen or not crowdsale contract executes this function.");
        _;
    }

    function lockAccount(address account) public onlyOwner {
        require(!isLocked(account), "It is already a locked account.");
        _locked[account] = true;
        emit LockAccount(account);
    }

    function unlockAccount(address account) public onlyOwner {
        require(isLocked(account), "It is already a unlocked account.");
        _locked[account] = false;
        emit UnlockAccount(account);
    }

    function transfer(address to, uint256 value) public test(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    function approve(address spender, uint256 value) public test(msg.sender) returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public test(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public test(msg.sender) returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public test(msg.sender) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function burn(uint256 value) public test(msg.sender) {
        return super.burn(value);
    }

    function burnFrom(address from, uint256 value) public test(from) {
        return super.burnFrom(from, value);
    }

    event LockAccount(address indexed account);

    event UnlockAccount(address indexed account);
}

library Roles {

    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
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

contract PauserRole {

    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private pausers;

    constructor() public {
        pausers.add(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        pausers.add(account);
        emit PauserAdded(account);
    }

    function renouncePauser() public {
        pausers.remove(msg.sender);
    }

    function _removePauser(address account) internal {
        pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is PauserRole {

    event Paused();
    event Unpaused();

    bool private _paused = false;


     
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
        emit Paused();
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

library SafeERC20 {

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
        require(token.approve(spender, value));
    }
}

contract IFUMCrowdsale is Ownable, Pausable {

    using SafeERC20 for IFUM;

    enum Stage {
        Prepare,         
        Presale,         
        Crowdsale,       
        Distribution,    
        Finished         
    }

    IFUM public token;

    address public _wallet;

    Stage public stage = Stage.Prepare;

     
    function setWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "Invalid address");
        address prev = _wallet;
        _wallet = wallet;
        emit SetWallet(prev, wallet);
    }

     
    function setTokenContract(IFUM newToken) public onlyOwner {
        require(newToken != address(0), "Invalid address");
        address prev = token;
        token = newToken;
        emit SetTokenContract(prev, newToken);
    }

     
    function () external payable {
        require(msg.value != 0, "You must transfer more than 0 ether.");
        require(
            stage == Stage.Presale || stage == Stage.Crowdsale,
            "It is not a payable stage."
        );
        _wallet.transfer(msg.value);
    }

     
    function transfer(address to, uint256 value) public onlyOwner {
        require(
            stage == Stage.Presale || stage == Stage.Crowdsale || stage == Stage.Distribution,
            "Is is not a transferrable stage."
        );
        token.safeTransfer(to, value);
    }

     
    function burnAll() public onlyOwner {
        require(stage == Stage.Distribution, "Is is not a burnable stage.");
        token.burn(token.balanceOf(this));
    }

     
    function setNextStage() public onlyOwner {
        uint8 intStage = uint8(stage);
        require(intStage < uint8(Stage.Finished), "It is the last stage.");
        intStage++;
        stage = Stage(intStage);
        if (stage == Stage.Finished) {
            token.unfreeze();
        }
        emit SetNextStage(intStage);
    }

    event SetNextStage(uint8 stage);

    event SetWallet(address previousWallet, address newWallet);

    event SetTokenContract(address previousToken, address newToken);
}