 

 
 

 

pragma solidity ^0.5.11;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.11;

 
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

 

pragma solidity ^0.5.11;

 
interface IERC223 {

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    event Approval(address indexed owner, address indexed spender, uint256 value, bytes data);

    function approve(address spender, uint256 amount, bytes calldata data) external returns (bool);

    function transfer(address to, uint value, bytes calldata data) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount, bytes calldata data) external returns (bool);

}

 

pragma solidity ^0.5.11;



 
contract ERC223Detailed is IERC20, IERC223 {
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

 

pragma solidity ^0.5.11;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.11;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

 

pragma solidity ^0.5.11;

 
interface IERC223Extras {
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes calldata data) external returns (bool);

    function approveFor(address beneficiary, address spender, uint256 amount, bytes calldata data) external returns (bool);
}

 

pragma solidity ^0.5.11;

  
interface IERC223Recipient {
     
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

 

pragma solidity ^0.5.11;

  
interface IERC223ExtendedRecipient {
     
    function approveFallback(address _from, uint _value, bytes calldata _data) external;

     
    function tokenForFallback(address _from, address _beneficiary, uint _value, bytes calldata _data) external;

     
    function approveForFallback(address _from, address _beneficiary, uint _value, bytes calldata _data) external;
}

 

pragma solidity ^0.5.11;








 
contract ERC223 is Context, IERC20, IERC223, IERC223Extras {
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
        bytes memory _empty = hex"00000000";
        _transfer(_msgSender(), recipient, amount, _empty);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount, bytes memory data) public returns (bool) {
        _transfer(sender, recipient, amount, data);  
          
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC223: transfer amount exceeds allowance"), data);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        bytes memory _empty = hex"00000000";
        _transfer(sender, recipient, amount, _empty);  
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC223: transfer amount exceeds allowance"));  
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function transfer(address recipient, uint256 amount, bytes memory data) public returns (bool success){
        _transfer(_msgSender(), recipient, amount, data);
        return true;
    }

     
    function approve(address spender, uint256 amount, bytes memory data) public returns (bool) {
        _approve(_msgSender(), spender, amount, data);
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount, bytes memory data) internal {
        require(sender != address(0), "ERC223: transfer from the zero address");
        require(recipient != address(0), "ERC223: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC223: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
         
         
        if(Address.isContract(recipient) && _msgSender() != recipient) {
            IERC223Recipient receiver = IERC223Recipient(recipient);
            receiver.tokenFallback(sender, amount, data);
        }
        emit Transfer(sender, recipient, amount, data);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC223: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        bytes memory _empty = hex"00000000";
        emit Transfer(address(0), account, amount, _empty);
    }

      
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC223: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC223: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        bytes memory _empty = hex"00000000";
        emit Transfer(account, address(0), amount, _empty);
    }

     
    function _approve(address owner, address spender, uint256 amount, bytes memory data) internal {
        require(owner != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");

        _allowances[owner][spender] = amount;
         
         
        if(Address.isContract(spender) && _msgSender() != spender) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(spender);
            receiver.approveFallback(owner, amount, data);
        }
        emit Approval(owner, spender, amount, data);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");
        bytes memory _empty = hex"00000000";
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount, _empty);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        bytes memory _empty = hex"00000000";
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC223: burn amount exceeds allowance"), _empty);
    }

     
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes memory data) public returns (bool) {
        address sender = _msgSender();
        require(beneficiary != address(0), "ERC223E: transfer for the zero address");
        require(recipient != address(0), "ERC223: transfer to the zero address");
        require(beneficiary != sender, "ERC223: sender and beneficiary cannot be the same");

        _balances[sender] = _balances[sender].sub(amount, "ERC223: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
         
        if(Address.isContract(recipient) && _msgSender() != recipient) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(recipient);
            receiver.tokenForFallback(sender, beneficiary, amount, data);
        }
        emit Transfer(sender, recipient, amount, data);
        return true;
    }

     
    function approveFor(address beneficiary, address spender, uint256 amount, bytes memory data) public returns (bool) {
        address agent = _msgSender();
        require(agent != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");
        require(beneficiary != agent, "ERC223: sender and beneficiary cannot be the same");

        _allowances[agent][spender] = amount;
         
        if(Address.isContract(spender) && _msgSender() != spender) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(spender);
            receiver.approveForFallback(agent, beneficiary, amount, data);
        }
        emit Approval(agent, spender, amount, data);
        return true;
    }
}

 

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

 

pragma solidity ^0.5.11;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
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

 

pragma solidity ^0.5.11;



 
contract Pausable is Context, PauserRole {
     
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
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

 

pragma solidity ^0.5.11;



 
contract ERC223Pausable is ERC223, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

     
    function transfer(address recipient, uint256 amount, bytes memory data) public whenNotPaused returns (bool success) {
        return super.transfer(recipient, amount, data);
    }

	 
    function approve(address spender, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.approve(spender, amount, data);
    }

     
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.transferFor(beneficiary, recipient, amount, data);
    }

     
    function approveFor(address beneficiary, address spender, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.approveFor(beneficiary, spender, amount, data);
    }
}

 

pragma solidity ^0.5.11;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
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

 

pragma solidity ^0.5.11;




 
contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
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

 

pragma solidity ^0.5.11;



 
contract ERC223Mintable is ERC223, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.11;


 
contract ERC223Capped is ERC223Mintable {
    uint256 private _cap;

     
    constructor (uint256 cap) public {
        require(cap > 0, "ERC223Capped: cap is 0");
        _cap = cap;
    }

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC223Capped: cap exceeded");
        super._mint(account, value);
    }
}

 

pragma solidity ^0.5.11;



 
contract ERC223Burnable is Context, ERC223 {
     
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

 

pragma solidity ^0.5.11;

 
contract ERC223UpgradeAgent {

	 
    uint public originalSupply;

     
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

     
    function upgradeFrom(address from, uint256 value) public;

}

 

pragma solidity ^0.5.11;





 
contract ERC223Upgradeable is ERC223Capped, ERC223Burnable, Ownable {

	 
    address private _upgradeAgent;

     
    uint256 private _totalUpgraded = 0;

     
    bool private _upgradeReady = false;

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _amount);

     
    event UpgradeAgentSet(address agent);

     
    event InformationUpdate(string name, string symbol);

     
    modifier upgradeAllowed() {
        require(_upgradeReady == true, "Upgrade not allowed");
        _;
    }

     
    modifier upgradeAgentAllowed() {
        require(_totalUpgraded == 0, "Upgrade is already in progress");
        _;
    }

     
    function upgradeAgent() public view returns (address) {
        return _upgradeAgent;
    }

     
    function upgrade(uint256 amount) public upgradeAllowed {
        require(amount > 0, "Amount should be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Amount exceeds tokens owned");
         
        burn(amount);
        _totalUpgraded = _totalUpgraded.add(amount);
         
        ERC223UpgradeAgent(_upgradeAgent).upgradeFrom(msg.sender, amount);
        emit Upgrade(msg.sender, _upgradeAgent, amount);
    }

     
    function setUpgradeAgent(address agent) external onlyOwner upgradeAgentAllowed {
        require(agent != address(0), "Upgrade agent can not be at address 0");
        ERC223UpgradeAgent target = ERC223UpgradeAgent(agent);
         
        require(target.isUpgradeAgent() == true, "Address provided is an invalid agent");
        require(target.originalSupply() == cap(), "Upgrade agent should have the same cap");
        _upgradeAgent = agent;
        _upgradeReady = true;
        emit UpgradeAgentSet(agent);
    }

}

 

pragma solidity ^0.5.11;



 
contract OdrToken is ERC223Upgradeable {

 	 
    address private _odrAddress;

     
    uint private _releaseDate;

     
    bool private _released = false;

    constructor(uint releaseDate) public {
        _releaseDate = releaseDate;
    }

     
    modifier whenNotReleased() {
        require(_released == false, "Not allowed after token release");
        _;
    }

     
    function releaseToken() external onlyOwner returns (bool isSuccess) {
        require(_odrAddress != address(0), "ODR Address must be set before releasing token");
        uint256 remainder = cap().sub(totalSupply());
        if(remainder > 0) mint(_odrAddress, remainder);  
        _released = true;
        return _released;
    }

     
    function setODR(address odrAddress) external onlyOwner returns (bool isSuccess) {
        require(odrAddress != address(0), "Invalid ODR address");
        require(Address.isContract(odrAddress), "ODR address must be a contract");
        _odrAddress = odrAddress;
        return true;
    }

     
    function released() public view returns (bool) {
        return _released;
    }

     
    function odr() public view returns (address) {
        return _odrAddress;
    }
}

 

pragma solidity ^0.5.11;





 
contract IownToken is OdrToken, ERC223Pausable, ERC223Detailed {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint totalSupply,
        uint8 decimals,
        uint releaseDate,
        address managingWallet
    )
        Context()
        ERC223Detailed(name, symbol, decimals)
        Ownable()
        PauserRole()
        Pausable()
        MinterRole()
        ERC223Capped(totalSupply)
        OdrToken(releaseDate)
        public
    {
        transferOwnership(managingWallet);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        address oldOwner = owner();
        _addMinter(newOwner);
        _addPauser(newOwner);
        super.transferOwnership(newOwner);
        if(oldOwner != address(0)) {
            _removeMinter(oldOwner);
            _removePauser(oldOwner);
        }
    }
}