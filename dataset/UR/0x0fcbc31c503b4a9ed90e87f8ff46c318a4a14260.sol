 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;



 
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

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity ^0.5.2;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.9;




contract QTF is ERC20, ERC20Detailed, Ownable {
    string private _name = "Quantfury Token";
    string private _symbol = "QTF";
    uint8 private _decimals = 8;
     
    bool private _lockTransfer = false;

     
    mapping(address => bool) private _lockedList;

    modifier onlyPersonalUnlocked() {
        require(_lockedList[msg.sender]==false);  
        _;
    }

    modifier onlyGlobalUnlocked() {
        require(_lockTransfer==false);  
        _;
    }

    constructor() ERC20Detailed(_name, _symbol, _decimals)
    public
    {
        _mint(address(msg.sender), 100000000*(10**uint256(_decimals)));
    }

     
    function getPersonalLockStatus(address holder)
    public
    view
    returns (bool)
    {
        return _lockedList[holder];
    }

     
    function getGlobalLockStatus()
    public
    view
    returns (bool)
    {
        return _lockTransfer;
    }

     
    function transfer(address to, uint256 value)
    onlyPersonalUnlocked
    onlyGlobalUnlocked
    public
    returns (bool)
    {
        return super.transfer(to, value);
    }

     
    function approve(address spender, uint256 value)
    onlyPersonalUnlocked
    onlyGlobalUnlocked
    public
    returns (bool)
    {
        return super.approve(spender, value);
    }

     
    function increaseAllowance(address spender, uint256 addedValue)
    onlyPersonalUnlocked
    onlyGlobalUnlocked
    public
    returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue)
    onlyPersonalUnlocked
    onlyGlobalUnlocked
    public
    returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

     
    function transferFrom(address from, address to, uint256 value)
    onlyPersonalUnlocked
    onlyGlobalUnlocked
    public
    returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

     
    function sendFromTo(address from, address to, uint256 value)
    onlyOwner
    public
    returns (bool)
    {
        super._transfer(from, to, value);
        return true;
    }

     
    function setPersonalLockStatus(address holder, bool status)
    onlyOwner
    public
    returns (bool)
    {
        _lockedList[holder] = status;
        emit LockPersonal(msg.sender, holder, now, status);
        return true;
    }

     
    function setGlobalLockStatus(bool status)
    onlyOwner
    public
    returns (bool)
    {
        _lockTransfer = status;
        emit LockGlobal(msg.sender, now, status);
        return true;
    }


     
    function recoverSentTokens(address _token, address receiver)
    onlyOwner
    public  {
        IERC20 token = IERC20(_token);
        token.transfer(receiver, token.balanceOf(address(this)));
    }

    event LockPersonal(address indexed changedByAddress, address holder, uint256 time, bool status);
    event LockGlobal(address indexed changedByAddress, uint256 time, bool status);
}