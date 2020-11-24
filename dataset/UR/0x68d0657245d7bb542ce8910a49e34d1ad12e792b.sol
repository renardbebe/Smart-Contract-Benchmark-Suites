 

pragma solidity ^0.5.0;

 
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

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function mint(address to, uint256 value) external returns (bool);

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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
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

    function _addMinter(address account) private {
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

 
contract ZOMToken is ERC20Mintable, ERC20Burnable {
    string private constant _name = "ZOM";
    string private constant _symbol = "ZOM";
    uint8 private constant _decimals = 18;
    uint256 private constant _initialSupply = 50000000 * 1 ether;  

    constructor () public {
        _mint(msg.sender, initialSupply());
    }

     
    function name() public pure returns (string memory) {
        return _name;
    }

     
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

     
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

     
    function initialSupply() public pure returns (uint256) {
        return _initialSupply;
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

 
contract Reward is ReentrancyGuard {
    using SafeMath for uint256;

    uint8 private constant _smallProcent = 1;
    uint8 private constant _bigProcent = 3;
    uint256 private constant _rewardDelay = 30 days;
    uint256 private constant _firstGroupTokensLimit = 50000 * 1 ether;  
    uint256 private _contractCreationDate;

    struct Holder {
        uint256 lastWithdrawDate;
        uint256 amountOfWithdraws;
    }

    IERC20 private _token;

    mapping(address => Holder) private _rewardTimeStamp;

    event NewTokensMinted(address indexed receiver, uint256 amount);

    modifier onlyHolder {
        uint256 balanceOfHolder = _getTokenBalance(msg.sender);
        require(balanceOfHolder > 0, "onlyHolder: the sender has no ZOM tokens");
        _;
    }

     
     
     

    constructor() public {
        address zom = address(new ZOMToken());
        _token = IERC20(zom);
        _contractCreationDate = block.timestamp;
        _token.transfer(msg.sender, _token.totalSupply());
    }

     
     
     

    function withdrawRewardTokens() external onlyHolder nonReentrant {
        address holder = msg.sender;
        uint256 lastWithdrawDate = _getLastWithdrawDate(holder);
        uint256 howDelaysAvailable = (block.timestamp.sub(lastWithdrawDate)).div(_rewardDelay);

        require(howDelaysAvailable > 0, "withdrawRewardTokens: the holder can not withdraw tokens yet!");

        uint256 tokensAmount = _calculateRewardTokens(holder);

         
        uint256 timeAfterLastDelay = block.timestamp.sub(lastWithdrawDate) % _rewardDelay;
        _rewardTimeStamp[holder].lastWithdrawDate = block.timestamp.sub(timeAfterLastDelay);

         
        _mint(holder, tokensAmount);

        emit NewTokensMinted(holder, tokensAmount);
    }


     
     
     

    function getHolderData(address holder) external view returns (uint256, uint256, uint256) {
        return (
            _getTokenBalance(holder),
            _rewardTimeStamp[holder].lastWithdrawDate,
            _rewardTimeStamp[holder].amountOfWithdraws
        );
    }

    function getAvailableRewardTokens(address holder) external view returns (uint256) {
        return _calculateRewardTokens(holder);
    }

    function token() external view returns (address) {
        return address(_token);
    }

    function creationDate() external view returns (uint256) {
        return _contractCreationDate;
    }

     
     
     

    function _mint(address holder, uint256 amount) private {
        require(_token.mint(holder, amount),"_mint: the issue happens during tokens minting");
        _rewardTimeStamp[holder].amountOfWithdraws = _rewardTimeStamp[holder].amountOfWithdraws.add(1);
    }

    function _calculateRewardTokens(address holder) private view returns (uint256) {
        uint256 lastWithdrawDate = _getLastWithdrawDate(holder);
        uint256 howDelaysAvailable = (block.timestamp.sub(lastWithdrawDate)).div(_rewardDelay);
        uint256 currentBalance = _getTokenBalance(holder);
        uint8 procent = currentBalance >= _firstGroupTokensLimit ? _bigProcent : _smallProcent;
        uint256 amount = currentBalance * howDelaysAvailable * procent / 100;

        return amount / 12;
    }

    function _getTokenBalance(address holder) private view returns (uint256) {
        return _token.balanceOf(holder);
    }

    function _getLastWithdrawDate(address holder) private view returns (uint256) {
        uint256 lastWithdrawDate = _rewardTimeStamp[holder].lastWithdrawDate;
        if (lastWithdrawDate == 0) {
            lastWithdrawDate = _contractCreationDate;
        }

        return lastWithdrawDate;
    }
}