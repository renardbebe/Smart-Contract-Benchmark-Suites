 

pragma solidity ^0.5.0;

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

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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

contract DgtFeePool is Ownable , IERC20, MinterRole {
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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


    using SafeMath for uint;
    uint public createdAt = block.timestamp;
    uint public difficultyIncreaseInPercentPerDay = 1;
    DGT public dgtContract;

    modifier onlySender(address _sender) {
        require(msg.sender == _sender);
        _;
    }
    event Claimed(
        address indexed by,
        uint256 tokenReturned,
        uint256 reward
    );
    constructor(address _dgtContract) public {
        dgtContract = DGT(_dgtContract);
    }

    function set_difficultyIncreaseInPercentPerDay(uint value) external onlyOwner returns (bool) {
        difficultyIncreaseInPercentPerDay = value;
        return true;
    }

    function currentReward(uint256 _value) public view returns (uint256) {
        uint timeDiff = block.timestamp.sub(createdAt);
        uint currentDifficulty = 100 + timeDiff.div(24 * 3600).mul(difficultyIncreaseInPercentPerDay);
        uint256 supposedReward = _value.mul(100).div(currentDifficulty);
        if (_balances[address(this)] > supposedReward) {
            return supposedReward;
        } else {
            return _balances[address(this)];
        }
    }

    function currentMined() public view returns (uint256) {
        return _totalSupply - _balances[address(this)];
    }

    function notifyTx(address _payer, uint256 _value) external onlySender(address(dgtContract)) returns (bool) {
        require(_payer != address(0));
        uint256 reward = currentReward(_value);
        
        _balances[address(this)] = _balances[address(this)].sub(reward);
        _balances[_payer] = _balances[_payer].add(reward);

        emit Transfer(owner(), _payer, reward);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);

        if (_to == address(this)) {
            uint256 currentPool = dgtContract.balanceOf(address(this));
            uint256 currentPZ = currentMined();
            uint256 result = currentPool.mul(_value).div(currentPZ);

            _transfer(msg.sender, _to, _value);

            dgtContract.feePoolTransfer(msg.sender, result);
            emit Claimed(msg.sender, _value, result);
        } else {
            _transfer(msg.sender, _to, _value);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowances[_from][msg.sender]);

        if (_to == address(this)) {
            uint256 currentPool = dgtContract.balanceOf(address(this));
            uint256 currentPZ = currentMined();
            uint256 result = currentPool.mul(_value).div(currentPZ);

            _balances[_from] = _balances[_from].sub(_value);
            _balances[_to] = _balances[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);

            dgtContract.feePoolTransfer(msg.sender, result);
            emit Claimed(msg.sender, _value, result);
        } else {
            _balances[_from] = _balances[_from].sub(_value);
            _balances[_to] = _balances[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        }

        return true;
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}


 
contract DGT is Ownable, IERC20, MinterRole, ERC20Detailed {
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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

    using SafeMath for uint;
    uint public txFeePerMillion = 0;
    uint256 public INITIAL_SUPPLY = 1000000*(10**8);
    DgtFeePool public feePool;

    constructor() public ERC20Detailed("Digold Token", "DGT", 8) {
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = INITIAL_SUPPLY;
    }

    modifier onlySender(address _sender) {
        require(msg.sender == _sender);
        _;
    }

    function setTxFee(uint _value) external onlyOwner returns (bool) {
        txFeePerMillion = _value;
        return true;
    }

     

    function setFeePool(address _feePool) external onlyOwner returns (bool) {
        require(_feePool != address(0));

        feePool = DgtFeePool(_feePool);
        return true;
    }

     

    function changeFeePool(address _newFeePool) external onlyOwner returns (bool) {
        require(address(feePool) != address(0), "no FeePool set yet");
        require(_newFeePool != address(0));
        require(_balances[_newFeePool] == 0);

        uint256 currentPoolBalance = _balances[address(feePool)];
        delete _balances[address(feePool)];
        feePool = DgtFeePool(_newFeePool);
        _balances[_newFeePool] = currentPoolBalance;

        return true;
    }

     
    function feePoolTransfer(address _to, uint256 _value) external onlySender(address(feePool)) returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);

        _transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);

        uint256 fee = _value.mul(txFeePerMillion).div(10**6);
        uint256 taxedValue = _value.sub(fee);

         
        _transfer(msg.sender, _to, taxedValue);

        if (address(feePool) != address(0)) {
            _balances[address(feePool)] = _balances[address(feePool)].add(fee);
            emit Transfer(msg.sender, address(feePool), fee);
            if (msg.sender != owner()) {
                feePool.notifyTx(msg.sender, _value);
            } 
        }
        return true;
    }


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= _allowances[_from][msg.sender]);

        uint256 fee = _value.mul(txFeePerMillion).div(10**6);
        uint256 taxedValue = _value.sub(fee);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(taxedValue);
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        
        if (address(feePool) != address(0)) {
            _balances[address(feePool)] = _balances[address(feePool)].add(fee);
            emit Transfer(msg.sender, address(feePool), fee);        
            feePool.notifyTx(msg.sender, _value);
        }
        return true;
    }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}