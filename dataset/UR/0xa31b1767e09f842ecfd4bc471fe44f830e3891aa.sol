 

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


contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

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

contract ERC20Mintable is ERC20, MinterRole {
     

    uint256 public maxSupply;
    uint256 public tokensMinted;

    constructor  (uint256 _maxSupply) public {
        require(_maxSupply > 0);
        maxSupply = _maxSupply;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        require(tokensMinted.add(value) <= maxSupply);
        tokensMinted = tokensMinted.add(value);
        _mint(to, value);
        return true;
    }

}


contract RoobeeToken is ERC20Burnable, ERC20Mintable {

    string public constant name = "ROOBEE";
    string public constant symbol = "ROOBEE";
    uint8 public constant decimals = 18;

    struct FreezeParams {
        uint256 timestamp;
        uint256 value;
        bool subsequentUnlock;
    }

    mapping (address => FreezeParams) private _freezed;

    constructor () public ERC20Mintable(5400000000 * 1e18) {
    }

    function freezeOf(address owner) public view returns (uint256) {
        if (_freezed[owner].timestamp <= now){
            if (_freezed[owner].subsequentUnlock){
                uint256  monthsPassed;
                monthsPassed = now.sub(_freezed[owner].timestamp).div(30 days);
                if (monthsPassed >= 10)
                {
                    return 0;
                }
                else
                {
                    return _freezed[owner].value.mul(10-monthsPassed).div(10);
                }
            }
            else {
                return 0;
            }
        }
        else
        {
            return _freezed[owner].value;
        }
    }

    function freezeFor(address owner) public view returns (uint256) {
        return _freezed[owner].timestamp;
    }

    function getAvailableBalance(address from) public view returns (uint256) {

        return balanceOf(from).sub(freezeOf(from));
    }

    function mintWithFreeze(address _to, uint256 _value, uint256 _unfreezeTimestamp, bool _subsequentUnlock) public onlyMinter returns (bool) {
        require(now < _unfreezeTimestamp);
        _setHold(_to, _value, _unfreezeTimestamp, _subsequentUnlock);
        mint(_to, _value);
        return true;
    }

    function _setHold(address to, uint256 value, uint256 unfreezeTimestamp, bool subsequentUnlock) private {
        FreezeParams memory freezeData;
        freezeData = _freezed[to];
         
        if (freezeData.timestamp == 0) {
            freezeData.timestamp = unfreezeTimestamp;
            freezeData.subsequentUnlock = subsequentUnlock;
        }
        freezeData.value = freezeData.value.add(value);
        _freezed[to] = freezeData;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(getAvailableBalance(msg.sender) >= value);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(getAvailableBalance(from) >= value);
        return super.transferFrom(from, to, value);
    }

    function burn(uint256 value) public {
        require(getAvailableBalance(msg.sender) >= value);
        super.burn(value);
    }

    function burnFrom(address from, uint256 value) public  {
        require(getAvailableBalance(from) >= value);
        super.burnFrom(from, value);
    }

    function approveAndCall(address _spender, uint256 _value, string memory _extraData
    ) public returns (bool success) {
        approve(_spender, _value);

         
         
         
         
         
         
        CallReceiver(_spender).approvalFallback(
           msg.sender,
           _value,
           address(this),
           _extraData
        );
        return true;
    }

}

contract CallReceiver {
    function approvalFallback(address _from, uint256 _value, address _token, string memory _extraData) public ;
}