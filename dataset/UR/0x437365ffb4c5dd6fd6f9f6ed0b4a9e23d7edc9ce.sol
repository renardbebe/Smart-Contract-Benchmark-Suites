 

pragma solidity 0.4.25;

 
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

contract AdminRole {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor () internal {
        _addAdmin(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

 
contract TokenVault {
     
    IERC20 public token;

    constructor(IERC20 _token) public {
        token = _token;
    }

     
    function fillUpAllowance() public {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.approve(token, amount);
    }

     
    function approve(address _spender, uint256 _tokensAmount) public {
        require(msg.sender == address(token));

        token.approve(_spender, _tokensAmount);
    }
}

contract FaireumToken is ERC20, ERC20Detailed, AdminRole {
    using SafeMath for uint256;

    uint8 public constant DECIMALS = 18;

     
    uint256 public constant INITIAL_SUPPLY = 1200000000 * 10**uint256(DECIMALS);

     
    TokenVault public teamAdvisorsTokensVault;

     
    TokenVault public rewardPoolTokensVault;

     
    TokenVault public foundersTokensVault;

     
    TokenVault public marketingAirdropTokensVault;

     
    TokenVault public saleTokensVault;

     
     
    uint256 public locksStartDate = 1552262400;

    mapping(address => uint256) public lockedHalfYearBalances;
    mapping(address => uint256) public lockedFullYearBalances;

    modifier timeLock(address from, uint256 value) {
        if (lockedHalfYearBalances[from] > 0 && now >= locksStartDate + 182 days) lockedHalfYearBalances[from] = 0;
        if (now < locksStartDate + 365 days) {
            uint256 unlocks = balanceOf(from).sub(lockedHalfYearBalances[from]).sub(lockedFullYearBalances[from]);
            require(value <= unlocks);
        } else if (lockedFullYearBalances[from] > 0) lockedFullYearBalances[from] = 0;
        _;
    }

    constructor () public ERC20Detailed("Faireum Token", "FAIRC", DECIMALS) {
    }

     
    function lockRewardPoolTokens(address _beneficiary, uint256 _tokensAmount) public onlyAdmin {
        _lockTokens(address(rewardPoolTokensVault), false, _beneficiary, _tokensAmount);
    }

     
    function lockFoundersTokens(address _beneficiary, uint256 _tokensAmount) public onlyAdmin {
        _lockTokens(address(foundersTokensVault), false, _beneficiary, _tokensAmount);
    }

     
    function lockTeamTokens(address _beneficiary, uint256 _tokensAmount) public onlyAdmin {
        require(_tokensAmount.mod(2) == 0);
        uint256 _half = _tokensAmount.div(2);
        _lockTokens(address(teamAdvisorsTokensVault), false, _beneficiary, _half);
        _lockTokens(address(teamAdvisorsTokensVault), true, _beneficiary, _half);
    }

     
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return lockedFullYearBalances[_owner].add(lockedHalfYearBalances[_owner]);
    }

     
    function approveSaleSpender(address _spender, uint256 _tokensAmount) public onlyAdmin {
        saleTokensVault.approve(_spender, _tokensAmount);
    }

     
    function approveMarketingSpender(address _spender, uint256 _tokensAmount) public onlyAdmin {
        marketingAirdropTokensVault.approve(_spender, _tokensAmount);
    }

    function transferFrom(address from, address to, uint256 value) public timeLock(from, value) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) public timeLock(msg.sender, value) returns (bool) {
        return super.transfer(to, value);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function createTokensVaults() external onlyAdmin {
        require(teamAdvisorsTokensVault == address(0));
        require(rewardPoolTokensVault == address(0));
        require(foundersTokensVault == address(0));
        require(marketingAirdropTokensVault == address(0));
        require(saleTokensVault == address(0));

         
        teamAdvisorsTokensVault = createTokenVault(120000000 * (10 ** uint256(DECIMALS)));
         
        rewardPoolTokensVault = createTokenVault(240000000 * (10 ** uint256(DECIMALS)));
         
        foundersTokensVault = createTokenVault(60000000 * (10 ** uint256(DECIMALS)));
         
        marketingAirdropTokensVault = createTokenVault(120000000 * (10 ** uint256(DECIMALS)));
         
        saleTokensVault = createTokenVault(660000000 * (10 ** uint256(DECIMALS)));

        require(totalSupply() == INITIAL_SUPPLY);
    }

     
    function recoverERC20Tokens(address _contractAddress) external onlyAdmin  {
        IERC20 erc20Token = IERC20(_contractAddress);
        if (erc20Token.balanceOf(address(this)) > 0) {
            require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
        }
    }

     
     
    function createTokenVault(uint256 tokens) internal returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        _mint(address(tokenVault), tokens);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

     
    function _lockTokens(address _fromVault, bool _halfYear, address _beneficiary, uint256 _tokensAmount) internal {
        require(_beneficiary != address(0));

        if (_halfYear) {
            lockedHalfYearBalances[_beneficiary] = lockedHalfYearBalances[_beneficiary].add(_tokensAmount);
        } else {
            lockedFullYearBalances[_beneficiary] = lockedFullYearBalances[_beneficiary].add(_tokensAmount);
        }

        require(this.transferFrom(_fromVault, _beneficiary, _tokensAmount));
    }
}