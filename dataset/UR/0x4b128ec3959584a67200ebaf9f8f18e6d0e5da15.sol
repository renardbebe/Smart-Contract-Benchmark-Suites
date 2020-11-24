 

pragma solidity ^0.5.0;


 
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

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => Account) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    struct Account {
        uint256 total;
        uint256 locked;
        uint32 release_time;
    }
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner].total;
    }
    
    function lockedOf(address owner) public view returns(uint256) {
        return _balances[owner].locked;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
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

     
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 total;
        if(_balances[from].locked>0) {
             
            if(_balances[from].release_time<block.timestamp) {
                _balances[from].locked = 0;
                total = _balances[from].total;
            }else {
                total = _balances[from].total.sub(_balances[from].locked);
            }
        }else {
            total = _balances[from].total;
        }
        _balances[from].total = total.sub(value).add(_balances[from].locked);
        _balances[to].total = _balances[to].total.add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account].total = _balances[account].total.add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 total;
        if(_balances[account].locked>0) {
             
            if(_balances[account].release_time<block.timestamp) {
                _balances[account].locked = 0;
                total = _balances[account].total;
            }else {
                total = _balances[account].total.sub(_balances[account].locked);
            }
        }else {
            total = _balances[account].total;
        }
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account].total = total.sub(value).add(_balances[account].locked);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(value));
    }
    
     
    function _lockTransfer(address account, uint256 value,uint32 release_time) internal {
        transfer(account, value);
        require(_balances[account].total >= _balances[account].locked.add(value));
        _balances[account].locked = _balances[account].locked.add(value);
        _balances[account].release_time = release_time;
    }
    
}

 
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

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


contract ETEC is ERC20Pausable,ERC20Burnable {

    uint32[] public _release_points = [1572537600,1575129600,1577808000,1580486400,1582992000,1585670400,1588262400,1590940800,1593532800,1596211200,1598889600,1601481600,1604160000,1606752000,1609430400,1612108800,1614528000,1617206400,1619798400,1622476800,1625068800,1627747200,1630425600,1633017600,1635696000,1638288000,1640966400,1643644800,1646064000,1648742400,1651334400,1654012800,1656604800,1659283200,1661961600,1664553600];
    uint8 public _next_point = 0;
    uint256 public _burn_amount_pertime = 10000000 * (10**decimals);
    address public _burn_address = 0xAccF8C4C8F5EAd10eeBEad972438E34D5a475158;
    

    string public constant name    = "Electronic Cigarette Chain";   
    uint256 public constant decimals = 18;                
    string public constant symbol  = "ETEC";             

     
    
    constructor () public {
        _mint(msg.sender, 1000000000 * (10**decimals));
        transfer(0xC7D3AE49d6998487428e85b7241786F83D60D9f7, 860000000*(10**decimals));
        _lockTransfer(0x7229352116a03412968Dd54919c9cf1Ac73C5Bef, 140000000*(10**decimals), 1664553600);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _auto_burn();
        return super.transfer(to, value);
    }
    
    function _auto_burn() internal {
        if(_next_point < _release_points.length && block.timestamp > _release_points[_next_point] && balanceOf(_burn_address)>=_burn_amount_pertime) {
            _burn(_burn_address, _burn_amount_pertime);
            _next_point = _next_point + 1;
        }
    }

}