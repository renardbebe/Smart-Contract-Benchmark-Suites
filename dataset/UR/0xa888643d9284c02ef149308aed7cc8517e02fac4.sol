 

pragma solidity 0.5.11;

 
 library SafeMath {

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

     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
         require(b <= a, "SafeMath: subtraction overflow");
         uint256 c = a - b;

         return c;
     }

     function add(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a + b;
         require(c >= a, "SafeMath: addition overflow");

         return c;
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

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller has no permission");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract AdminRole is Ownable {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _admins;

    constructor() internal {
        _admins.add(_owner);
        emit AdminAdded(_owner);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller has no permission");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return(_admins.has(account) || isOwner(account));
    }

    function addAdmin(address account) public onlyOwner {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyOwner {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() internal {
        _minters.add(_owner);
        emit MinterAdded(_owner);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Caller has no permission");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return(_minters.has(account) || isOwner(account));
    }

    function addMinter(address account) public onlyOwner {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyOwner {
        _minters.remove(account);
        emit MinterRemoved(account);
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

 
interface ICrowdsale {
    function hardcap() external view returns (uint256);
    function isEnded() external view returns(bool);
}

 
 interface IExchange {
     function enlisted(address account) external view returns(bool);
     function reserveAddress() external view returns(address payable);
 }

 
interface IApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
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
        require(from != address(0));
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

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

 
contract ERC20Mintable is ERC20, MinterRole {

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

}

 
contract LockableToken is ERC20Mintable, AdminRole {

     
    bool private _released;

     
    ICrowdsale internal _crowdsale;
    IExchange internal _exchange;

     
    mapping (address => bool) private _unlocked;
    mapping (address => Lock) private _locked;
    struct Lock {
        uint256 amount;
        uint256 time;
    }

     
    modifier canTransfer(address from, address to, uint256 value) {
        if (!_released && !isAdmin(from) && !_unlocked[from]) {
            if (address(_exchange) != address(0)) {
                require(_exchange.enlisted(from));
                require(to == address(_exchange) || to == _exchange.reserveAddress());
            }
        }
        if (_locked[from].amount > 0 && block.timestamp < _locked[from].time) {
            require(value <= balanceOf(from).sub(_locked[from].amount));
        }
        _;
    }

     
    function setCrowdsaleAddr(address addr) external {
        require(isContract(addr));

        if (address(_crowdsale) != address(0)) {
            removeMinter(address(_crowdsale));
        }

        addMinter(addr);

        _crowdsale = ICrowdsale(addr);
    }

     
    function lock(address account, uint256 amount, uint256 time) external onlyAdmin {
        require(account != address(0) && amount != 0);
        _locked[account] = Lock(amount, block.timestamp.add(time));
        _unlocked[account] = false;
    }

     
    function unlock(address account) external onlyAdmin {
        require(account != address(0));
        if (_locked[account].amount > 0) {
            delete _locked[account];
        }
        _unlocked[account] = true;
    }

     
    function unlockList(address[] calldata accounts) external onlyAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0));
            if (_locked[accounts[i]].amount > 0) {
                delete _locked[accounts[i]];
            }
            _unlocked[accounts[i]] = true;
        }
    }

     
    function release() external onlyAdmin {
        if (address(_crowdsale) != address(0)) {
            require(_crowdsale.isEnded());
            _crowdsale = ICrowdsale(address(0));
        }
        _released = true;
    }

     
    function _transfer(address from, address to, uint256 value) internal canTransfer(from, to, value) {
        super._transfer(from, to, value);
    }

     
    function released() external view returns(bool) {
        return _released;
    }

     
    function crowdsale() external view returns(address) {
        return address(_crowdsale);
    }

     
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

 
contract BTALToken is LockableToken {

     
    string private _name = "Bital Token";
     
    string private _symbol = "BTAL";
     
    uint8 private _decimals = 18;

     
    uint256 internal constant INITIAL_SUPPLY = 155000000 * (10 ** 18);

     
    mapping (address => bool) private _contracts;

     
    uint256 private _hardcap = 1000000000 * (10 ** 18);

    event ContractAdded(address indexed admin, address contractAddr);
    event ContractRemoved(address indexed admin, address contractAddr);

     
    constructor(address recipient, address initialOwner) public Ownable(initialOwner) {

        _mint(recipient, INITIAL_SUPPLY);

    }

     
    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        IApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

     
     function isAdmin(address account) public view returns (bool) {
         return(super.isAdmin(account) || isMinter(account));
     }

     
    function setExchangeAddr(address addr) external onlyAdmin {
        require(isContract(addr));
        registerContract(addr);

        _exchange = IExchange(addr);
    }

     
    function registerContract(address addr) public onlyAdmin {
        require(isContract(addr));
        _contracts[addr] = true;
        emit ContractAdded(msg.sender, addr);
    }

     
    function unregisterContract(address addr) external onlyAdmin {
        _contracts[addr] = false;
        emit ContractRemoved(msg.sender, addr);
    }

     
    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        if (_contracts[to] && !_contracts[msg.sender]) {
            IApproveAndCallFallBack(to).receiveApproval(msg.sender, value, address(this), new bytes(0));
        } else {
            super.transferFrom(from, to, value);
        }

        return true;
    }

     
    function mint(address account, uint256 amount) public returns (bool) {
        require(totalSupply().add(amount) <= _hardcap);

        return super.mint(account, amount);

    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyAdmin {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        require(amount > 0);
        IERC20(ERC20Token).transfer(recipient, amount);

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

     
    function hardcap() public view returns(uint256) {
        return _hardcap;
    }

     
    function isRegistered(address addr) public view returns (bool) {
        return _contracts[addr];
    }

}