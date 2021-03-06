 

pragma solidity ^0.5.0;

 

 
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

 

contract HatchToken is ERC20Detailed, ERC20, Ownable {
    using SafeMath for uint256;

    address private _treasury;  
    uint256 private _monthlyUnlocked;  
    uint256 private _unlocked;  
    uint256 private _calcTime;  
    uint256 private _treasuryTransfered;  
    uint256 private _calcPeriod = 30 days;  

    event MonthlyUnlockedChanged(uint256 _oldMonthlyUnlocked, uint256 _newMonthlyUnlocked);
    event TreasuryChanged(address _oldTreasury, address _newTreasury);
    event EmergencyUnlock(uint256 _amount);

     
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 supply, address treasury, uint256 initialUnlocked, uint256 monthlyUnlocked) public
        ERC20Detailed(name, symbol, decimals)
    {
        _mint(treasury, supply);
        require(initialUnlocked <= totalSupply(), "initialUnlocked too large");
        require(monthlyUnlocked <= totalSupply(), "monthlyUnlocked too large");
        _treasury = treasury;
        _monthlyUnlocked = monthlyUnlocked;
        _unlocked = initialUnlocked;
        _calcTime = now;
    }

     
    function treasury() external view returns (address) {
        return _treasury;
    }

     
    function treasuryBalance() external view returns (uint256) {
        return balanceOf(_treasury);
    }

     
    function monthlyUnlocked() external view returns (uint256) {
        return _monthlyUnlocked;
    }

     
    function treasuryTransfered() external view returns (uint256) {
        return _treasuryTransfered;
    }

     
    function emergencyUnlock(uint256 amount) external onlyOwner {
        require(amount <= totalSupply(), "amount too large");
        _unlocked = _unlocked.add(amount);
        emit EmergencyUnlock(amount);
    }

     
    function treasuryUnlocked() external view returns (uint256) {
        (uint256 unlocked, ) = _calcUnlocked();
        if (unlocked < totalSupply()) {
            return unlocked;
        } else {
            return totalSupply();
        }
    }

    function _calcUnlocked() internal view returns (uint256, uint256) {
        uint256 epochs = now.sub(_calcTime).div(_calcPeriod);
        return (_unlocked.add(epochs.mul(_monthlyUnlocked)), _calcTime.add(epochs.mul(_calcPeriod)));
    }

    function _update() internal {
        (uint256 newUnlocked, uint256 newCalcTime) = _calcUnlocked();
        _calcTime = newCalcTime;
        _unlocked = newUnlocked;
    }

     
    function changeTreasury(address newTreasury) external onlyOwner {
        _transfer(_treasury, newTreasury, balanceOf(_treasury));
        emit TreasuryChanged(_treasury, newTreasury);
        _treasury = newTreasury;
    }

     
    function changeMonthlyUnlocked(uint256 newMonthlyUnlocked) external onlyOwner {
        require(newMonthlyUnlocked <= totalSupply(), "monthlyUnlocked too large");
        _update();
        emit MonthlyUnlockedChanged(_monthlyUnlocked, newMonthlyUnlocked);
        _monthlyUnlocked = newMonthlyUnlocked;
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        if (msg.sender == _treasury) {
            _update();
             
            require(amount <= _unlocked, "Insufficient unlocked balance");
            _treasuryTransfered = _treasuryTransfered.add(amount);
            _unlocked = _unlocked.sub(amount);
        }
        bool result = super.transfer(recipient, amount);
        if (recipient == _treasury) {
            _unlocked = _unlocked.add(amount);
        }
        return result;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if (sender == _treasury) {
            _update();
             
            require(amount <= _unlocked, "Insufficient unlocked balance");
            _treasuryTransfered = _treasuryTransfered.add(amount);
            _unlocked = _unlocked.sub(amount);
        }
        bool result = super.transferFrom(sender, recipient, amount);
        if (recipient == _treasury) {
            _unlocked = _unlocked.add(amount);
        }
        return result;
    }

}