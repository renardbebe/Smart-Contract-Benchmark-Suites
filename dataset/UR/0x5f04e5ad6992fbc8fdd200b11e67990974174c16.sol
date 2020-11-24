 

pragma solidity 0.4.25;


 
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

 
interface IERC664Balances {
    function getBalance(address _acct) external view returns(uint balance);

    function incBalance(address _acct, uint _val) external returns(bool success);

    function decBalance(address _acct, uint _val) external returns(bool success);

    function getAllowance(address _owner, address _spender) external view returns(uint remaining);

    function setApprove(address _sender, address _spender, uint256 _value) external returns(bool success);

    function decApprove(address _from, address _spender, uint _value) external returns(bool success);

    function getModule(address _acct) external view returns (bool success);

    function setModule(address _acct, bool _set) external returns(bool success);

    function getTotalSupply() external view returns(uint);

    function incTotalSupply(uint _val) external returns(bool success);

    function decTotalSupply(uint _val) external returns(bool success);

    function transferRoot(address _new) external returns(bool success);

    event BalanceAdj(address indexed Module, address indexed Account, uint Amount, string Polarity);

    event ModuleSet(address indexed Module, bool indexed Set);
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


 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function proposeOwnership(address _newOwnerCandidate) external onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() external {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
    function changeOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
    function removeOwnership(address _dac) external onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        emit OwnershipRemoved();
    }
}

 
contract SafeGuard is Owned {

    event Transaction(address indexed destination, uint value, bytes data);

     
    function executeTransaction(address destination, uint value, bytes data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

     
    function externalCall(address destination, uint value, uint dataLength, bytes data)
    private
    returns (bool) {
        bool result;
        assembly {  
            let x := mload(0x40)    
             
            let d := add(data, 32)  
            result := call(
            sub(gas, 34710),  
             
             
            destination,
            value,
            d,
            dataLength,  
            x,
            0                   
            )
        }
        return result;
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string) {
        return _name;
    }

     
    function symbol() public view returns (string) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
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
    }
}


 
contract ERC664Balances is IERC664Balances, SafeGuard {
    using SafeMath for uint256;

    uint256 public totalSupply;

    event BalanceAdj(address indexed module, address indexed account, uint amount, string polarity);
    event ModuleSet(address indexed module, bool indexed set);

    mapping(address => bool) public modules;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyModule() {
        require(modules[msg.sender]);
        _;
    }

     
    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        emit BalanceAdj(address(0), msg.sender, _initialAmount, "+");
    }

     
    function setApprove(address _sender, address _spender, uint256 _value) external onlyModule returns (bool) {
        allowed[_sender][_spender] = _value;
        return true;
    }

     
    function decApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        return true;
    }

     
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.add(_val);
        return true;
    }

     
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.sub(_val);
        return true;
    }

     
    function setModule(address _acct, bool _set) external onlyOwner returns (bool) {
        modules[_acct] = _set;
        emit ModuleSet(_acct, _set);
        return true;
    }

     
    function transferRoot(address _newOwner) external onlyOwner returns(bool) {
        owner = _newOwner;
        return true;
    }

     
    function getBalance(address _acct) external view returns (uint256) {
        return balances[_acct];
    }

     
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function getModule(address _acct) external view returns (bool) {
        return modules[_acct];
    }

     
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

     
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].add(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "+");
        return true;
    }

     
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].sub(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "-");
        return true;
    }
}

 
contract DStore is ERC664Balances {

     
    constructor(uint256 _totalSupply) public
    ERC664Balances(_totalSupply) {

    }

     
     
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

     
     
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

     
    function move(address _from, address _to, uint256 _amount) external
    onlyModule
    returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        emit BalanceAdj(msg.sender, _from, _amount, "-");
        balances[_to] = balances[_to].add(_amount);
        emit BalanceAdj(msg.sender, _to, _amount, "+");
        return true;
    }

     
    function incApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].add(_value);
        return true;
    }

     
     
    function incBalance(address _acct, uint _val) public
    onlyModule
    returns (bool) {
        return false;
    }

     
     
    function decBalance(address _acct, uint _val) public
    onlyModule
    returns (bool) {
        return false;
    }
}

 
contract PreDeriveum is ERC20, ERC20Detailed, SafeGuard {
    uint256 public constant INITIAL_SUPPLY = 10000000000;
    DStore public tokenDB;

     
    constructor () public ERC20Detailed("Pre-Deriveum", "PDER", 0) {
        tokenDB = new DStore(INITIAL_SUPPLY);
        require(tokenDB.setModule(address(this), true));
        require(tokenDB.move(address(this), msg.sender, INITIAL_SUPPLY));
        require(tokenDB.transferRoot(msg.sender));
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

     
    function totalSupply() public view returns (uint256) {
        return tokenDB.getTotalSupply();
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return tokenDB.getBalance(owner);
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return tokenDB.getAllowance(owner, spender);
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        require(tokenDB.setApprove(msg.sender, spender, value));
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        uint256 allow = tokenDB.getAllowance(from, msg.sender);
        allow = allow.sub(value);
        require(tokenDB.setApprove(from, msg.sender, allow));
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        uint256 allow = tokenDB.getAllowance(msg.sender, spender);
        allow = allow.add(addedValue);
        require(tokenDB.setApprove(msg.sender, spender, allow));
        emit Approval(msg.sender, spender, allow);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        uint256 allow = tokenDB.getAllowance(msg.sender, spender);
        allow = allow.sub(subtractedValue);
        require(tokenDB.setApprove(msg.sender, spender, allow));
        emit Approval(msg.sender, spender, allow);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        require(tokenDB.move(from, to, value));
        emit Transfer(from, to, value);
    }
}