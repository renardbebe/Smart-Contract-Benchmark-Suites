 

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


 

contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}


contract IERC223 {
     
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    function transfer(address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value, bytes memory data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
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




contract BurnerRole {
    using Roles for Roles.Role;

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    Roles.Role private _burners;

    constructor () internal {
        _addBurner(msg.sender);
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender));
        _;
    }

    function isBurner(address account) public view returns (bool) {
        return _burners.has(account);
    }

    function addBurner(address account) public onlyBurner {
        _addBurner(account);
    }

    function renounceBurner() public {
        _removeBurner(msg.sender);
    }

    function _addBurner(address account) internal {
        _burners.add(account);
        emit BurnerAdded(account);
    }

    function _removeBurner(address account) internal {
        _burners.remove(account);
        emit BurnerRemoved(account);
    }
}










 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
library SafeERC223 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC223 token, address to, uint256 value) internal {
         
        require(token.transfer(to, value));
    }

    function safeTransfer(IERC223 token, address to, uint256 value, bytes memory data) internal {
         
        require(token.transfer(to, value, data));
    }

    function safeTransferFrom(IERC223 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC223 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC223: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC223 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC223 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC223 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC223: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC223: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC223: ERC223 operation did not succeed");
        }
    }
}



 
contract TokenTimelock is ERC223ReceivingContract {
    using SafeERC223 for IERC223;

     
    IERC223 private _token;

     
    address private _beneficiary;

     
    uint256 private _releaseTime;

    constructor (IERC223 token, address beneficiary, uint256 releaseTime) public {
         
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

     
    function token() public view returns (IERC223) {
        return _token;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

     
    function release() public {
         
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }

     
    function tokenFallback(address  , uint  , bytes memory  ) public {
        return;
    }
}









 
contract ERC223 is IERC223 {
    using SafeMath for uint;
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

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

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        _transfer(msg.sender, _to, _value, empty);
        return true;
    }


     
    function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool) {
        _transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bytes memory empty;
        _transfer(from, to, value, empty);
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


     
    function _transfer(address _from, address _to, uint256 _value, bytes memory _data) internal {
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        if (_to.isContract()) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        emit Transfer(_from, _to, _value, _data);
        emit Transfer(_from, _to, _value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);

        bytes memory empty;

        if (account.isContract()) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(account);
            receiver.tokenFallback(address(0), value, empty);
        }

        emit Transfer(address(0), account, value, empty);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        bytes memory empty;
        emit Transfer(account, address(0), value, empty);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}



contract BcnxToken is ERC223, BurnerRole {
    string private constant NAME = "Bcnex Token";
    string private constant SYMBOL = "BCNX";
    uint8 private constant DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = 200 * (10 ** 6) * (10 ** uint256(DECIMALS));


    constructor()
    ERC223(NAME, SYMBOL, DECIMALS)
    public {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

     
    function burn(uint256 value) public onlyBurner {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public onlyBurner {
        _burnFrom(from, value);
    }
}

contract BcnxDistribution {
    using SafeMath for uint256;

    event NewTimeLock(address addr, BcnxToken _token, address _beneficiary, uint256 _releaseTime);

    BcnxToken public token;
    uint256 private constant TEAM_TOKENS = 76 * (10 ** 6) * (10 ** uint256(18));
    uint256 [] public LOCK_END = [
    1577750400,  
    1609372800,  
    1640908800,  
    1672444800   
    ];

    constructor () public {
         
        token = new BcnxToken();

         
        uint256 AMOUNT_PER_RELEASE = TEAM_TOKENS.div(LOCK_END.length);
        for (uint i = 0; i < LOCK_END.length; i++) {
            uint256 releaseTime = LOCK_END[i];
            TokenTimelock timelock = new TokenTimelock(token, msg.sender, releaseTime);
            token.transfer(address(timelock), AMOUNT_PER_RELEASE);
            emit NewTimeLock(address(timelock), token, msg.sender, releaseTime);
        }

         
        uint256 remainingBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, remainingBalance);

         
        token.addBurner(msg.sender);
    }
}