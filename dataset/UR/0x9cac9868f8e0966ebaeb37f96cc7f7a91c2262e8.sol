 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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

 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function executiveBurn(address owner, address burner, uint256 amount) public {
        _approve(owner, burner, amount);
        _burnFrom(owner, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

 

pragma solidity ^0.5.0;


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

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity >=0.5.0;





contract CommandPointA  is ERC20Mintable, ERC20Burnable, Pausable, ERC20Detailed {
    constructor (string memory _name, string memory _symbol, uint8 _decimals)
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        
    }
}

 

pragma solidity >=0.5.0;





contract CommandPointB  is ERC20Mintable, ERC20Burnable, Pausable, ERC20Detailed {
    constructor (string memory _name, string memory _symbol, uint8 _decimals)
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        
    }
}

 

pragma solidity >=0.5.0;





contract ResourcePointA  is ERC20Mintable, ERC20Burnable, Pausable, ERC20Detailed {
    constructor (string memory _name, string memory _symbol, uint8 _decimals)
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        
    }
}

 

pragma solidity >=0.5.0;





contract ResourcePointB  is ERC20Mintable, ERC20Burnable, Pausable, ERC20Detailed {
    constructor (string memory _name, string memory _symbol, uint8 _decimals)
        ERC20Detailed(_name, _symbol, _decimals)
        public
    {
        
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity >=0.5.0;







contract TournamentPurchase is Pausable, Ownable {
    event Sold(address buyer, uint256 sku, uint256 amount);

    CommandPointA commandpointa;
    CommandPointB commandpointb;
    ResourcePointA resourcepointa;
    ResourcePointB resourcepointb;

    function setCPAContractAddress(address newAddress) onlyOwner public {
        commandpointa = CommandPointA(newAddress);
    }

    function setCPBContractAddress(address newAddress) onlyOwner public {
        commandpointb = CommandPointB(newAddress);
    }

    function setRPAContractAddress(address newAddress) onlyOwner public {
        resourcepointa = ResourcePointA(newAddress);
    }

    function setRPBContractAddress(address newAddress) onlyOwner public {
        resourcepointb = ResourcePointB(newAddress);
    }

    mapping(uint256 => uint256) prices;

    constructor() public {
        prices[1] = 0.01 ether;
        prices[2] = 0.01 ether;
        prices[3] = 0.018 ether;
        prices[4] = 0.018 ether;
        prices[5] = 0.034 ether;
    }

    function withdrawBalance(address payable recipient) onlyOwner public {
        recipient.transfer(address(this).balance);
    }

    function setPrice(uint16 sku, uint64 price) public onlyOwner {
        prices[sku] = price;
    }

    function buy(uint16 sku, address payable referral) external payable whenNotPaused {

        uint256 price = prices[sku];
        require(msg.value >= price, "Amount paid is too low");

        uint256 multiples = msg.value/price;

        if (sku == 1) {

            commandpointa.mint(msg.sender, multiples);

        } else if (sku == 2) {

            resourcepointa.mint(msg.sender, multiples);

        } else if (sku == 3) {

            commandpointa.mint(msg.sender, multiples);
            commandpointb.mint(msg.sender, multiples);

        } else if (sku == 4) {

            resourcepointa.mint(msg.sender, multiples);
            resourcepointb.mint(msg.sender, multiples);

        } else if (sku == 5) {

            commandpointa.mint(msg.sender, multiples);
            commandpointb.mint(msg.sender, multiples);
            resourcepointa.mint(msg.sender, multiples);
            resourcepointb.mint(msg.sender, multiples);

        } else {
            require(false, "Invalid sku");
        }

         
        if (referral != address(0) && referral != msg.sender) {
            referral.transfer(msg.value / 20);
        }

        emit Sold(msg.sender, sku, msg.value);
    }

    function setCPA(address user, uint256 amount) onlyOwner public {

        uint256 balance = commandpointa.balanceOf(user);
        if(amount > balance) {

            uint256 extra = amount - balance;
            commandpointa.mint(user, extra);

        } else {
            require(false, "Can only gift tokens");
        }
    }

    function setCPB(address user, uint256 amount) onlyOwner public {

        uint256 balance = commandpointb.balanceOf(user);
        if(amount > balance) {

            uint256 extra = amount - balance;
            commandpointb.mint(user, extra);

        } else {
            require(false, "Can only gift tokens");
        }
    }

    function setRPA(address user, uint256 amount) onlyOwner public {

        uint256 balance = resourcepointa.balanceOf(user);
        if(amount > balance) {

            uint256 extra = amount - balance;
            resourcepointa.mint(user, extra);

        } else {
            require(false, "Can only gift tokens");
        }
    }

    function setRPB(address user, uint256 amount) onlyOwner public {
        
        uint256 balance = resourcepointb.balanceOf(user);
        if(amount > balance) {

            uint256 extra = amount - balance;
            resourcepointb.mint(user, extra);

        } else {
            require(false, "Can only gift tokens");
        }
    }
}