 

pragma solidity ^0.5.1;

 
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

 
contract ERC20Detailed is ERC20 {
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

contract ERC20Traceable is ERC20Detailed {
    address[] internal holdersSet;
    mapping(address => uint256) internal holdersIndices;

    function _traceRecipient(address to) internal {
        if(holdersIndices[to] == 0) {
            holdersSet.push(to);
            holdersIndices[to] = holdersSet.length;
        }
    }

    function _traceSender(address from, uint256 value) internal {
        if(balanceOf(from) == value) {
            if(holdersIndices[from] != 0) {
                uint256 senderIndex = holdersIndices[from];
                if(senderIndex < holdersSet.length) {
                    address lastHolder = holdersSet[holdersSet.length - 1];
                    uint256 lastHolderIndex = holdersIndices[lastHolder];
                    holdersSet[senderIndex - 1] = holdersSet[lastHolderIndex - 1];
                }
                delete holdersSet[holdersSet.length - 1];
                holdersSet.length = holdersSet.length - 1;
                holdersIndices[from] = 0;
            }

        }
    }

    function _trace(address from, address to, uint256 value) internal {
        _traceRecipient(to);
        if(from != address(0) && from != to) {
            _traceSender(from, value);
        }
    }

    function _mint(address account, uint256 value) internal {
        _traceRecipient(account);
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal {
        _traceSender(account, value);
        super._burn(account, value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _traceSender(account, value);
        super._burn(account, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _trace(from, to, value);
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _trace(msg.sender, to, value);
        return super.transfer(to, value);
    }

    function getHolders() public view returns (address[] memory) {
        return holdersSet;
    }
}

 
contract WhitelistToken is ERC20Traceable, AdminRole {
    mapping(address => bool) public whitelisted;

    function _mint(address account, uint256 value) internal {
        require(whitelisted[account]);
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(whitelisted[account]);
        super._burn(account, value);
    }

    function _burnFrom(address account, uint256 value) internal {
        require(whitelisted[account]);
        super._burn(account, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(whitelisted[to]);
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(whitelisted[to]);
        return super.transfer(to, value);
    }

    function setWhitelisted(address _address, bool _whitelisted) public onlyAdmin {
        whitelisted[_address] = _whitelisted;
    }
}

 
contract BlacklistToken is ERC20Traceable, AdminRole {
    mapping(address => bool) public blacklisted;

    function _mint(address account, uint256 value) internal {
        require(!blacklisted[account]);
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(!blacklisted[account]);
        super._burn(account, value);
    }

    function _burnFrom(address account, uint256 value) internal {
        require(!blacklisted[account]);
        super._burn(account, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!blacklisted[to]);
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(!blacklisted[to]);
        return super.transfer(to, value);
    }

    function setBlacklisted(address _address, bool _blacklisted) public onlyAdmin {
        blacklisted[_address] = _blacklisted;
    }
}


contract DicToken is WhitelistToken {
     
    uint256 public INITIAL_SUPPLY;

    address public saleTokensAddress;
    address public marketingTokensAddress;
    address public managementTokensAddress;
    address public affiliateTokensAddress;
    address public foundersTokensAddress;

    bool public tradingEnabled;

    constructor(address _saleTokensAddress,
                address _marketingTokensAddress, address _managementTokensAddress, address _affiliateTokensAddress, address _foundersTokensAddress)
                public ERC20Detailed("DIC Token", "DIC", 18) {
        require(_saleTokensAddress != address(0));
        require(_marketingTokensAddress != address(0));
        require(_managementTokensAddress != address(0));
        require(_affiliateTokensAddress != address(0));
        require(_foundersTokensAddress != address(0));

        INITIAL_SUPPLY = 35000000 * 10**uint256(decimals());

        saleTokensAddress = _saleTokensAddress;
        marketingTokensAddress = _marketingTokensAddress;
        managementTokensAddress = _managementTokensAddress;
        affiliateTokensAddress = _affiliateTokensAddress;
        foundersTokensAddress = _foundersTokensAddress;

        setWhitelisted(saleTokensAddress, true);
        setWhitelisted(marketingTokensAddress, true);
        setWhitelisted(managementTokensAddress, true);
        setWhitelisted(affiliateTokensAddress, true);
        setWhitelisted(foundersTokensAddress, true);

         

        _mint(saleTokensAddress, 10850000 * (10 ** uint256(decimals())));  
        _mint(saleTokensAddress, 18200000 * (10 ** uint256(decimals())));  
        _mint(marketingTokensAddress, 350000 * (10 ** uint256(decimals())));  
        _mint(managementTokensAddress, 1750000 * (10 ** uint256(decimals())));  
        _mint(affiliateTokensAddress, 350000 * (10 ** uint256(decimals())));  
        _mint(foundersTokensAddress, 3500000 * (10 ** uint256(decimals())));  

        require(totalSupply() == INITIAL_SUPPLY);
    }

    function setTradingEnabled(bool _enabled) external onlyAdmin {
        tradingEnabled = _enabled;
    }

    function distribute(address to, uint256 value) external returns (bool) {
        require(msg.sender == saleTokensAddress || msg.sender == marketingTokensAddress);
        setWhitelisted(to, true);
        return super.transfer(to, value);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        if(!tradingEnabled && !isAdmin(msg.sender)) return false;
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(!tradingEnabled) return false;
        return super.transferFrom(from, to, value);
    }

    function transferBatch(address[] calldata _recipients, uint256[] calldata _amounts) external {
        require(_recipients.length > 0);
        require(_recipients.length == _amounts.length);

        for(uint8 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]));
        }
    }

    function mint(address account, uint256 amount) external onlyAdmin {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        super._burn(account, amount);
    }

     
    function recoverERC20Tokens(address _contractAddress) onlyAdmin external {
        IERC20 erc20Token = IERC20(_contractAddress);
        if(erc20Token.balanceOf(address(this)) > 0) {
            require(erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this))));
        }
    }
}