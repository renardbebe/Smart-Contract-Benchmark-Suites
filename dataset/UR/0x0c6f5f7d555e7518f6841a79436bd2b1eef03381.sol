 

 

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

 

 





 
 
 

contract CocosToken is ERC20, ERC20Detailed, Pausable, Ownable  {
    using SafeMath for uint;

     
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 100000000000 * (10 ** uint256(DECIMALS));


     
    mapping(address => uint) blackAccountMap;
    address[] public blackAccounts;

     
    mapping(address => uint) whiteAccountMap;
    address[] public whiteAccounts;

    event TransferMuti(uint256 len, uint256 amount);

    event AddWhiteAccount(address indexed operator, address indexed whiteAccount);
    event AddBlackAccount(address indexed operator, address indexed blackAccount);

    event DelWhiteAccount(address indexed operator, address indexed whiteAccount);
    event DelBlackAccount(address indexed operator, address indexed blackAccount);

    modifier validAddress( address addr ) {
        require(addr != address(0x0), "address is not 0x0");
        require(addr != address(this), "address is not contract");
        _;
    }


     

    constructor () public ERC20Detailed("CocosToken", "COCOS", DECIMALS) {
        pause();
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function() external payable {
        revert();
    }

   function transfer(address _to, uint256 _value) public returns (bool)  {
        if (paused() == true) {
             
            require(whiteAccountMap[msg.sender] != 0, "contract is in paused, only in white list can transfer");
        }
        else {
             
            require(blackAccountMap[msg.sender] == 0,"address in black list, can't transfer");
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (paused() == true) {
             
            require(whiteAccountMap[msg.sender] != 0, "contract is in  paused, can't transfer");
            if (msg.sender != _from) {
                require(whiteAccountMap[_from] != 0, "contract is in  paused, can't transfer");
            }
        }
        else {
             
            require(blackAccountMap[msg.sender] == 0, "address in black list, can't transfer");
            if (msg.sender != _from) {
                require(blackAccountMap[_from] == 0,"address in black list, can't transfer");
            }
        }

        return super.transferFrom(_from, _to, _value);
    }

     
    function withdrawFromContract(address _to) public onlyOwner validAddress(_to) returns (bool)  {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance > 0, "not enough balance");

        _transfer(address(this), _to, contractBalance);
        return true;
    }


    function addWhiteAccount(address _whiteAccount) public
        onlyOwner
        validAddress(_whiteAccount){
        require(whiteAccountMap[_whiteAccount]==0, "has in white list");

        uint256 index = whiteAccounts.length;
        require(index < 4294967296, "white list is too long");

        whiteAccounts.length += 1;
        whiteAccounts[index] = _whiteAccount;
        
        whiteAccountMap[_whiteAccount] = index + 1;
        emit AddWhiteAccount(msg.sender,_whiteAccount);
    }

    function delWhiteAccount(address _whiteAccount) public
        onlyOwner
        validAddress(_whiteAccount){
        require(whiteAccountMap[_whiteAccount]!=0,"not in white list");

        uint256 index = whiteAccountMap[_whiteAccount];
        if (index == whiteAccounts.length)
        {
            whiteAccounts.length -= 1;
        }else{
            address lastaddress = whiteAccounts[whiteAccounts.length-1];
            whiteAccounts[index-1] = lastaddress;
            whiteAccounts.length -= 1;
            whiteAccountMap[lastaddress] = index;
        }
        delete whiteAccountMap[_whiteAccount];
        emit DelWhiteAccount(msg.sender,_whiteAccount);
    }

    function addBlackAccount(address _blackAccount) public
        onlyOwner
        validAddress(_blackAccount){
        require(blackAccountMap[_blackAccount]==0,  "has in black list");

        uint256 index = blackAccounts.length;
        require(index < 4294967296, "black list is too long");

        blackAccounts.length += 1;
        blackAccounts[index] = _blackAccount;
        blackAccountMap[_blackAccount] = index + 1;

        emit AddBlackAccount(msg.sender, _blackAccount);
    }

    function delBlackAccount(address _blackAccount) public
        onlyOwner
        validAddress(_blackAccount){
        require(blackAccountMap[_blackAccount]!=0,"not in black list");

        uint256 index = blackAccountMap[_blackAccount];
        if (index == blackAccounts.length)
        {
            blackAccounts.length -= 1;
        }else{
            address lastaddress = blackAccounts[blackAccounts.length-1];
            blackAccounts[index-1] = lastaddress;
            blackAccounts.length -= 1;
            blackAccountMap[lastaddress] = index;
        }

        delete blackAccountMap[_blackAccount];
        emit DelBlackAccount(msg.sender, _blackAccount);
    }

}