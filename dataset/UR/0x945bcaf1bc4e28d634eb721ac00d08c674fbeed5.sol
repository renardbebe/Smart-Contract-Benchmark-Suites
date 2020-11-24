 

pragma solidity >=0.4.22 <0.6.0;

 
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

 
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address payable) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(),"Invalid owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 public _decimals;

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


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    mapping (address => bool) public frozenAccount;

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

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Check recipient is owner");
         
        require(!frozenAccount[from],"Check if sender is frozen");
         
        require(!frozenAccount[to],"Check if recipient is frozen");
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0),"Check recipient is '0x0'");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Check recipient is owner");

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

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
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

 
contract ERC20Mintable is ERC20, Ownable {
     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}


 
contract ERC20Burnable is ERC20,Ownable{
     
    function burn(uint256 value) onlyOwner public {
        _burn(msg.sender, value);
    }

}

contract PauserRole is Ownable {
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
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

}


 
contract HTN_TOKEN is ERC20, ERC20Detailed, ERC20Burnable, ERC20Mintable, ERC20Pausable {

    string private constant NAME = "Heart Number"; 
    string private constant SYMBOL = "HTN"; 
    uint8 private constant DECIMALS = 18; 
    
     
    uint256 public TokenPerETHBuy = 100000;
    
     
    uint256 public TokenPerETHSell = 100000;
    
     
    bool public SellTokenAllowed;
    
     
    bool public BuyTokenAllowed;
    
     
    event BuyRateChanged(uint256 oldValue, uint256 newValue);
    
     
    event SellRateChanged(uint256 oldValue, uint256 newValue);
    
     
    event BuyToken(address user, uint256 eth, uint256 token);
    
      
    event SellToken(address user, uint256 eth, uint256 token);
    
     
    event FrozenFunds(address target, bool frozen);    
    
     
    event SellTokenAllowedEvent(bool isAllowed);
    
     
    event BuyTokenAllowedEvent(bool isAllowed);
    
    uint256 public constant INITIAL_SUPPLY = 10000000000 *(10 ** uint256(DECIMALS));

    
     
    constructor () public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
        SellTokenAllowed = false;
        BuyTokenAllowed = true;
    }
    
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner  public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
    function setBuyRate(uint256 value) onlyOwner public {
        require(value > 0);
        emit BuyRateChanged(TokenPerETHBuy, value);
        TokenPerETHBuy = value;
    }
    
     
    function setSellRate(uint256 value) onlyOwner public {
        require(value > 0);
        emit SellRateChanged(TokenPerETHSell, value);
        TokenPerETHSell = value;
    }
    
     
    function buy() payable public  returns (uint amount){
        require(msg.value > 0 , "Ivalid Ether amount");
        require(!frozenAccount[msg.sender], "Accout is frozen");                       
        require(BuyTokenAllowed, "Buy Token is not allowed");                          
        amount = ((msg.value.mul(TokenPerETHBuy)).mul( 10 ** uint256(decimals()))).div(1 ether);
        _balances[address(this)] -= amount;                         
        _balances[msg.sender] += amount; 
        emit Transfer(address(this),msg.sender ,amount);
        return amount;
    }
    
     
    function sell(uint amount) public  returns (uint revenue){
        
        require(_balances[msg.sender] >= amount,"Checks if the sender has enough to sell");          
        require(!frozenAccount[msg.sender],"Check if sender is frozen");               
        require(SellTokenAllowed);                         
        _balances[address(this)] += amount;                
        _balances[msg.sender] -= amount;                   
        revenue = (amount.mul(1 ether)).div(TokenPerETHSell.mul(10 ** uint256(decimals()))) ;
        msg.sender.transfer(revenue);                      
        emit Transfer(msg.sender, address(this), amount);                
        return revenue;                                    
        
    }
    
     
    function enableSellToken() onlyOwner public {
        SellTokenAllowed = true;
        emit SellTokenAllowedEvent (true);
    }

     
    function disableSellToken() onlyOwner public {
        SellTokenAllowed = false;
        emit SellTokenAllowedEvent (false);
    }
    
     
    function enableBuyToken() onlyOwner public {
        BuyTokenAllowed = true;
        emit BuyTokenAllowedEvent (true);
    }

     
    function disableBuyToken() onlyOwner public {
        BuyTokenAllowed = false;
        emit BuyTokenAllowedEvent (false);
    }
    
     
     function withdraw(uint withdrawAmount) onlyOwner public  {
          if (withdrawAmount <= address(this).balance) {
            owner().transfer(withdrawAmount);
        }
    }
}