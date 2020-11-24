 

pragma solidity 0.5.2;

 
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
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
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

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }
}

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 
contract TuneTradeToken is ERC20Burnable, ERC20Mintable {
    string private constant _name = "TuneTradeX";
    string private constant _symbol = "TXT";
    uint8 private constant _decimals = 18;

     
    function name() public pure returns (string memory) {
        return _name;
    }

     
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

     
    function decimals() public pure returns (uint8) {
        return _decimals;
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

 
contract TeamRole is WhitelistedRole {
    using Roles for Roles.Role;

    event TeamMemberAdded(address indexed account);
    event TeamMemberRemoved(address indexed account);

    Roles.Role private _team;

    modifier onlyTeamMember() {
        require(isTeamMember(msg.sender));
        _;
    }

    function isTeamMember(address account) public view returns (bool) {
        return _team.has(account);
    }

    function _addTeam(address account) internal onlyWhitelistAdmin {
        _team.add(account);
        emit TeamMemberAdded(account);
    }

    function removeTeam(address account) public onlyWhitelistAdmin {
        _team.remove(account);
        emit TeamMemberRemoved(account);
    }
}

 
library SafeERC20 {
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }
}

 
contract SwapContract is TeamRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _remaining;
    uint256 private _lastReset;

    uint256 private constant _period = 1 days;
    uint256 private constant _publicLimit = 10000 * 1 ether;
    uint256 private constant _teamLimit = 30000 * 1 ether;
    uint256 private constant _contractLimit = 100000 * 1 ether;

    address private constant _swapMaster = 0x26a9f0b85db899237c6F07603475df43Eb366F8b;

    struct SwapInfo {
        bool alreadyWhitelisted;
        uint256 availableTokens;
        uint256 lastSwapTimestamp;
    }

    mapping (address => SwapInfo) private _infos;

    IERC20 private _newToken;
    IERC20 private _oldToken = IERC20(0xA57a2aD52AD6b1995F215b12fC037BffD990Bc5E);

    event MasterTokensSwapped(uint256 amount);
    event TokensSwapped(address swapper, uint256 amount);
    event TeamTokensSwapped(address swapper, uint256 amount);
    event SwapApproved(address swapper, uint256 amount);

     
    constructor () public {
        _newToken = IERC20(address(new TuneTradeToken()));
        
        _newToken.mint(_swapMaster, 50000010000000000000000010);
        emit MasterTokensSwapped(50000010000000000000000010);
            
        _reset();
    }

     
     
     

    function approveSwap(address swapper) public onlyWhitelistAdmin {
        require(swapper != address(0), "approveSwap: invalid swapper address");

        uint256 balance = _oldToken.balanceOf(swapper);
        require(balance > 0, "approveSwap: the swapper token balance is zero");
        require(_infos[swapper].alreadyWhitelisted == false, "approveSwap: the user already swapped his tokens");

        _addWhitelisted(swapper);
        _infos[swapper] = SwapInfo({
            alreadyWhitelisted: true,
            availableTokens: balance,
            lastSwapTimestamp: 0
        });

        emit SwapApproved(swapper, balance);
    }

    function approveTeam(address member) external onlyWhitelistAdmin {
        require(member != address(0), "approveTeam: invalid team address");

        _addTeam(member);
        approveSwap(member);
    }

    function swap() external onlyWhitelisted {
        if (now >= _lastReset + _period) {
            _reset();
        }

        require(_remaining != 0, "swap: no tokens available");
        require(_infos[msg.sender].availableTokens != 0, "swap: no tokens available for swap");
        require(now >= _infos[msg.sender].lastSwapTimestamp + _period, "swap: msg.sender can not call this method now");

        uint256 toSwap = _infos[msg.sender].availableTokens;

        if (toSwap > _publicLimit) {
            toSwap = _publicLimit;
        }

        if (toSwap > _remaining) {
            toSwap = _remaining;
        }

        if (toSwap > _oldToken.balanceOf(msg.sender)) {
            toSwap = _oldToken.balanceOf(msg.sender);
        }

        _swap(toSwap);
        _update(toSwap);
        _remaining = _remaining.sub(toSwap);

        emit TokensSwapped(msg.sender, toSwap);
    }

    function swapTeam() external onlyTeamMember {
        require(_infos[msg.sender].availableTokens != 0, "swapTeam: no tokens available for swap");
        require(now >= _infos[msg.sender].lastSwapTimestamp + _period, "swapTeam: team member can not call this method now");

        uint256 toSwap = _infos[msg.sender].availableTokens;

        if (toSwap > _teamLimit) {
            toSwap = _teamLimit;
        }

        if (toSwap > _oldToken.balanceOf(msg.sender)) {
            toSwap = _oldToken.balanceOf(msg.sender);
        }

        _swap(toSwap);
        _update(toSwap);

        emit TeamTokensSwapped(msg.sender, toSwap);
    }

    function swapMaster(uint256 amount) external {
        require(msg.sender == _swapMaster, "swapMaster: only swap master can call this methid");
        _swap(amount);
        emit MasterTokensSwapped(amount);
    }

     
     
     

    function getSwappableAmount(address swapper) external view returns (uint256) {
        return _infos[swapper].availableTokens;
    }

    function getTimeOfLastSwap(address swapper) external view returns (uint256) {
        return _infos[swapper].lastSwapTimestamp;
    }

    function getRemaining() external view returns (uint256) {
        return _remaining;
    }

    function getLastReset() external view returns (uint256) {
        return _lastReset;
    }

    function getTokenAddress() external view returns (address) {
        return address(_newToken);
    }

     
     
     

    function _reset() private {
        _lastReset = now;
        _remaining = _contractLimit;
    }

    function _update(uint256 amountToSwap) private {
        _infos[msg.sender].availableTokens = _infos[msg.sender].availableTokens.sub(amountToSwap);
        _infos[msg.sender].lastSwapTimestamp = now;
    }

    function _swap(uint256 amountToSwap) private {
        _oldToken.safeTransferFrom(msg.sender, address(this), amountToSwap);
        _newToken.mint(msg.sender, amountToSwap);
    }
}