 

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
}

contract ReserveDollar is IERC20 {
    using SafeMath for uint256;


     


     
    ReserveDollarEternalStorage internal data;

     
    string public name = "Reserve Dollar";
    string public symbol = "RSVD";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

     
    bool public paused;

     
    address public owner;
    address public minter;
    address public pauser;
    address public freezer;
    address public nominatedOwner;


     


     
    event OwnerChanged(address indexed newOwner);
    event MinterChanged(address indexed newMinter);
    event PauserChanged(address indexed newPauser);
    event FreezerChanged(address indexed newFreezer);

     
    event Paused(address indexed account);
    event Unpaused(address indexed account);

     
    event NameChanged(string newName, string newSymbol);

     
    event Frozen(address indexed freezer, address indexed account);
    event Unfrozen(address indexed freezer, address indexed account);
    event Wiped(address indexed freezer, address indexed wiped);


     


     
    constructor() public {
        data = new ReserveDollarEternalStorage(msg.sender);
        owner = msg.sender;
        pauser = msg.sender;
         
    }

     
    function getEternalStorageAddress() external view returns(address) {
        return address(data);
    }


     


     
    modifier only(address role) {
        require(msg.sender == role, "unauthorized: not role holder");
        _;
    }

     
    modifier onlyOwnerOr(address role) {
        require(msg.sender == owner || msg.sender == role, "unauthorized: not role holder and not owner");
        _;
    }

     
    function changeMinter(address newMinter) external onlyOwnerOr(minter) {
        minter = newMinter;
        emit MinterChanged(newMinter);
    }

     
    function changePauser(address newPauser) external onlyOwnerOr(pauser) {
        pauser = newPauser;
        emit PauserChanged(newPauser);
    }

     
    function changeFreezer(address newFreezer) external onlyOwnerOr(freezer) {
        freezer = newFreezer;
        emit FreezerChanged(newFreezer);
    }

     
     
    function nominateNewOwner(address nominee) external only(owner) {
        nominatedOwner = nominee;
    }

     
     
    function acceptOwnership() external onlyOwnerOr(nominatedOwner) {
        if (msg.sender != owner) {
            emit OwnerChanged(msg.sender);
        }
        owner = msg.sender;
        nominatedOwner = address(0);
    }

     
     
    function renounceOwnership() external only(owner) {
        owner = address(0);
        emit OwnerChanged(owner);
    }

     
     
     
    function transferEternalStorage(address newOwner) external only(owner) {
        data.transferOwnership(newOwner);
    }

     
    function changeName(string calldata newName, string calldata newSymbol) external only(owner) {
        name = newName;
        symbol = newSymbol;
        emit NameChanged(newName, newSymbol);
    }

     
    function pause() external only(pauser) {
        paused = true;
        emit Paused(pauser);
    }

     
    function unpause() external only(pauser) {
        paused = false;
        emit Unpaused(pauser);
    }

     
    modifier notPaused() {
        require(!paused, "contract is paused");
        _;
    }

     
    function freeze(address account) external only(freezer) {
        require(data.frozenTime(account) == 0, "account already frozen");

         
         
         
         
        data.setFrozenTime(account, now);

        emit Frozen(freezer, account);
    }

     
    function unfreeze(address account) external only(freezer) {
        require(data.frozenTime(account) > 0, "account not frozen");
        data.setFrozenTime(account, 0);
        emit Unfrozen(freezer, account);
    }

     
    modifier notFrozen(address account) {
        require(data.frozenTime(account) == 0, "account frozen");
        _;
    }

     
    function wipe(address account) external only(freezer) {
        require(data.frozenTime(account) > 0, "cannot wipe unfrozen account");
         
         
        require(data.frozenTime(account) + 4 weeks < now, "cannot wipe frozen account before 4 weeks");
        _burn(account, data.balance(account));
        emit Wiped(freezer, account);
    }


     


     
    function balanceOf(address holder) external view returns (uint256) {
        return data.balance(holder);
    }

     
    function allowance(address holder, address spender) external view returns (uint256) {
        return data.allowed(holder, spender);
    }

     
    function transfer(address to, uint256 value)
        external
        notPaused
        notFrozen(msg.sender)
        notFrozen(to)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value)
        external
        notPaused
        notFrozen(msg.sender)
        notFrozen(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function transferFrom(address from, address to, uint256 value)
        external
        notPaused
        notFrozen(msg.sender)
        notFrozen(from)
        notFrozen(to)
        returns (bool)
    {
        _transfer(from, to, value);
        _approve(from, msg.sender, data.allowed(from, msg.sender).sub(value));
        return true;
    }

     
     
     
     
    function increaseAllowance(address spender, uint256 addedValue)
        external
        notPaused
        notFrozen(msg.sender)
        notFrozen(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, data.allowed(msg.sender, spender).add(addedValue));
        return true;
    }

     
     
     
     
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        notPaused
        notFrozen(msg.sender)
         
         
        returns (bool)
    {
        _approve(msg.sender, spender, data.allowed(msg.sender, spender).sub(subtractedValue));
        return true;
    }

     
    function mint(address account, uint256 value)
        external
        notPaused
        notFrozen(account)
        only(minter)
    {
        require(account != address(0), "can't mint to address zero");

        totalSupply = totalSupply.add(value);
        data.addBalance(account, value);
        emit Transfer(address(0), account, value);
    }

     
    function burnFrom(address account, uint256 value)
        external
        notPaused
        notFrozen(account)
        only(minter)
    {
        _burn(account, value);
        _approve(account, msg.sender, data.allowed(account, msg.sender).sub(value));
    }

     
     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "can't transfer to address zero");

        data.subBalance(from, value);
        data.addBalance(to, value);
        emit Transfer(from, to, value);
    }

     
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "can't burn from address zero");

        totalSupply = totalSupply.sub(value);
        data.subBalance(account, value);
        emit Transfer(account, address(0), value);
    }

     
     
    function _approve(address holder, address spender, uint256 value) internal {
        require(spender != address(0), "spender cannot be address zero");
        require(holder != address(0), "holder cannot be address zero");

        data.setAllowed(holder, spender, value);
        emit Approval(holder, spender, value);
    }
}

contract ReserveDollarEternalStorage {

    using SafeMath for uint256;



     

    address public owner;
    address public escapeHatch;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event EscapeHatchTransferred(address indexed oldEscapeHatch, address indexed newEscapeHatch);

     
    constructor(address escapeHatchAddress) public {
        owner = msg.sender;
        escapeHatch = escapeHatchAddress;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

     
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner || msg.sender == escapeHatch, "not authorized");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function transferEscapeHatch(address newEscapeHatch) external {
        require(msg.sender == escapeHatch, "not authorized");
        emit EscapeHatchTransferred(escapeHatch, newEscapeHatch);
        escapeHatch = newEscapeHatch;
    }

     

    mapping(address => uint256) public balance;

     
     
     
     
     
    function addBalance(address key, uint256 value) external onlyOwner {
        balance[key] = balance[key].add(value);
    }

     
    function subBalance(address key, uint256 value) external onlyOwner {
        balance[key] = balance[key].sub(value);
    }

     
    function setBalance(address key, uint256 value) external onlyOwner {
        balance[key] = value;
    }



     

    mapping(address => mapping(address => uint256)) public allowed;

     
    function setAllowed(address from, address to, uint256 value) external onlyOwner {
        allowed[from][to] = value;
    }



     

     
     
     
    mapping(address => uint256) public frozenTime;

     
    function setFrozenTime(address who, uint256 time) external onlyOwner {
        frozenTime[who] = time;
    }
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