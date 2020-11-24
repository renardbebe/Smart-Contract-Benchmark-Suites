 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
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
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IgnorePausedRole {
    using Roles for Roles.Role;

    event IgnorePausedAdded(address indexed account);
    event IgnorePausedRemoved(address indexed account);

    Roles.Role private _ignorePausers;

    constructor () internal {
        _addIgnorePaused(msg.sender);
    }

    modifier onlyIgnorePaused() {
        require(isIgnorePaused(msg.sender));
        _;
    }

    function isIgnorePaused(address account) public view returns (bool) {
        return _ignorePausers.has(account);
    }

    function addIgnorePaused(address account) public onlyIgnorePaused {
        _addIgnorePaused(account);
    }

    function renounceIgnorePaused() public {
        _removeIgnorePaused(msg.sender);
    }

    function _addIgnorePaused(address account) internal {
        _ignorePausers.add(account);
        emit IgnorePausedAdded(account);
    }

    function _removeIgnorePaused(address account) internal {
        _ignorePausers.remove(account);
        emit IgnorePausedRemoved(account);
    }
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract RateChangerRole {
    using Roles for Roles.Role;

    event RateChangerAdded(address indexed account);
    event RateChangerRemoved(address indexed account);

    Roles.Role private _RateChangers;

    constructor () internal {
        _addRateChanger(msg.sender);
    }

    modifier onlyRateChanger() {
        require(isRateChanger(msg.sender), "Sender not authorized to change the rate");
        _;
    }

    function isRateChanger(address account) public view returns (bool) {
        return _RateChangers.has(account);
    }

    function addRateChanger(address account) public onlyRateChanger {
        _addRateChanger(account);
    }

    function renounceRateChanger() public {
        _removeRateChanger(msg.sender);
    }

    function _addRateChanger(address account) internal {
        _RateChangers.add(account);
        emit RateChangerAdded(account);
    }

    function _removeRateChanger(address account) internal {
        _RateChangers.remove(account);
        emit RateChangerRemoved(account);
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

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
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
        require(isPauser(msg.sender));
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

contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value), "Token could not be transfered");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value), "Token could not be transfered");
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract Crowdsale is ReentrancyGuard, RateChangerRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    function changeRate(uint256 rate)
        public onlyRateChanger
    {
        require(rate > 0);
        _rate = rate;
    }

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (  uint256 initialRate, address payable wallet, IERC20 token) public {
        require(initialRate > 0, "The initial rate must be above 0");
        require(wallet != address(0), "The wallet address must not be 0x0");
        require(address(token) != address(0), "The token address must not be 0x0");

        _rate = initialRate;
        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Cannot send to 0 address");
        require(weiAmount != 0, "No ether sent");
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.div(_rate);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

contract Pausable is PauserRole, IgnorePausedRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    address private _creator;

    constructor () internal {
        _paused = false;
        _creator = msg.sender;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused || isIgnorePaused(msg.sender), "Contract paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Contract not paused");
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

contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

contract MintedCrowdsale is Crowdsale {
     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
         
        require(ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
    }
}

contract WhitelistCrowdsale is WhitelistedRole, Crowdsale {
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(isWhitelisted(_beneficiary), "Beneficiary address is not whitelisted");
        super._preValidatePurchase(_beneficiary, _weiAmount);
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract PausableCrowdsale is Crowdsale, Pausable {
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view whenNotPaused {
        return super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

contract RateChangeCrowdsaleToken is ERC20, ERC20Detailed, ERC20Pausable {
    constructor (uint256 initialSupply, string memory name, string memory symbol, uint8 decimals) public ERC20Detailed(name, symbol, decimals) {
         
        _mint(msg.sender, initialSupply);
    }
}

 
contract RateChangeCrowdsale is Crowdsale, WhitelistCrowdsale, PausableCrowdsale {
    constructor (
        uint256 rate,
        IERC20 token
    )
        public
        Crowdsale(rate, msg.sender, token)
    {}
}
