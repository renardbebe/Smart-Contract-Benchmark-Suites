 

 

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

 

pragma solidity ^0.5.2;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
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

 

pragma solidity ^0.5.2;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
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

 

pragma solidity ^0.5.2;

 
contract ComplianceService {

     
    function check(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8);

     
    function forceCheck(address _token, address _spender, address _from, address _to, uint256 _amount) public returns (uint8);

     
    function checkVested(address _token, address _spender, address _holder, uint256 _balance, uint256 _amount) public returns (bool);
}

 

pragma solidity ^0.5.2;

 
contract DividendService {

     
    function check(address _token, address _spender, address _holder, uint _interval) public returns (uint8);
}

 

pragma solidity ^0.5.2;




 
 
contract ServiceRegistry is Ownable {
    address public regulator;
    address public dividend;

     
    event ReplaceService(address oldService, address newService);

     
    modifier withContract(address _addr) {
        uint length;
        assembly { length := extcodesize(_addr) }
        require(length > 0);
        _;
    }

     
    constructor(address _regulator, address _dividend) public {
        regulator = _regulator;
        dividend = _dividend;
    }

     
    function replaceRegulator(address _regulator) public onlyOwner withContract(_regulator) {
        require(regulator != _regulator, "The address cannot be the same");

        address oldRegulator = regulator;
        regulator = _regulator;
        emit ReplaceService(oldRegulator, regulator);
    }

     
    function replaceDividend(address _dividend) public onlyOwner withContract(_dividend) {
        require(dividend != _dividend, "The address cannot be the same");

        address oldDividend = dividend;
        dividend = _dividend;
        emit ReplaceService(oldDividend, dividend);
    }
}

 

pragma solidity ^0.5.2;







 
contract BlueshareToken is ERC20Detailed, ERC20Mintable, Ownable {

     
    uint8 constant public BLUESHARETOKEN_DECIMALS = 0;

     
    string constant public ISIN = "CH0465030796";

     
    event CheckComplianceStatus(uint8 reason, address indexed spender, address indexed from, address indexed to, uint256 value);

     
    event CheckVestingStatus(bool reason, address indexed spender, address indexed from, uint256 balance, uint256 value);

     
    event CheckDividendStatus(uint8 reason, address indexed spender, address indexed holder, uint interval);

     
    ServiceRegistry public registry;

     
    constructor(ServiceRegistry _registry, string memory _name, string memory _symbol) public
      ERC20Detailed(_name, _symbol, BLUESHARETOKEN_DECIMALS)
    {
        require(address(_registry) != address(0), "Uninitialized or undefined address");

        registry = _registry;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_checkVested(msg.sender, balanceOf(msg.sender), _value), "Cannot send vested amount!");
        require(_check(msg.sender, _to, _value), "Cannot transfer!");

        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_checkVested(_from, balanceOf(_from), _value), "Cannot send vested amount!");
        require(_check(_from, _to, _value), "Cannot transfer!");
        
        return super.transferFrom(_from, _to, _value);
    }

     
    function forceTransferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_forceCheck(_from, _to, _value), "Not allowed!");

        _transfer(_from, _to, _value);
        return true;
    }

     
    function dividendStatus(address _holder, uint _interval) public returns (uint8) {
        return _checkDividend(_holder, _interval);
    }

     
    function _check(address _from, address _to, uint256 _value) private returns (bool) {
        uint8 reason = _regulator().check(address(this), msg.sender, _from, _to, _value);

        emit CheckComplianceStatus(reason, msg.sender, _from, _to, _value);

        return reason == 0;
    }

     
    function _forceCheck(address _from, address _to, uint256 _value) private returns (bool) {
        uint8 allowance = _regulator().forceCheck(address(this), msg.sender, _from, _to, _value);

        emit CheckComplianceStatus(allowance, msg.sender, _from, _to, _value);

        return allowance == 0;
    }

     
    function _checkVested(address _participant, uint256 _balance, uint256 _value) private returns (bool) {
        bool allowed = _regulator().checkVested(address(this), msg.sender, _participant, _balance, _value);

        emit CheckVestingStatus(allowed, msg.sender, _participant, _balance, _value);

        return allowed;
    }

     
    function _checkDividend(address _address, uint _interval) private returns (uint8) {
        uint8 status = _dividend().check(address(this), msg.sender, _address, _interval);

        emit CheckDividendStatus(status, msg.sender, _address, _interval);

        return status;
    }

     
    function _regulator() public view returns (ComplianceService) {
        return ComplianceService(registry.regulator());
    }

     
    function _dividend() public view returns (DividendService) {
        return DividendService(registry.dividend());
    }
}