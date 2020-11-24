 

pragma solidity 0.5.2;

 

 
interface IERC20 {

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(value);
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
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
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

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

 
contract KongERC20 is ERC20, ERC20Burnable, ERC20Detailed {
     
    uint256 constant ONE_YEAR = 365 * 24 * 60 * 60;
    uint256 constant ONE_MONTH = 30 * 24 * 60 * 60;
    uint256 constant MINTING_REWARD = 2 ** 8 * 10 ** 18;

     
    address public _owner;

     
    uint256 public _totalMinted;

     
    uint256 public _launchTimestamp;

     
    address public _lastLockDropAddress;
    uint256 public _lastLockDropTimestamp;

     
    mapping (address => bool) public _minters;

     
    event LockDropCreation(
        address deployedBy,
        uint256 deployedTimestamp,
        uint256 deployedSize,
        address deployedAddress
    );

     
    event MinterAddition(
        address minter
    );

     
    constructor() public ERC20Detailed('KONG', 'KONG', 18) {

         
        _owner = 0xAB35D3476251C6b614dC2eb36380D7AF1232D822;

         
        _launchTimestamp = block.timestamp;

         
        _mint(0xAB35D3476251C6b614dC2eb36380D7AF1232D822, 3 * 2 ** 20 * 10 ** 18);
        _mint(0x9699b500fD907636f10965d005813F0CE0986176, 2 ** 20 * 10 ** 18);
        _mint(0xdBa9A507aa0838370399FDE048752E91B5a27F06, 2 ** 20 * 10 ** 18);
        _mint(0xb2E0F4dee26CcCf1f3A267Ad185f212Dd3e7a6b1, 2 ** 20 * 10 ** 18);
        _mint(0xdB6e9FaAcE283e230939769A2DFa80BdcD7E1E43, 2 ** 20 * 10 ** 18);

    }

     
    function addMinter(address minter) public {

      require(msg.sender == _owner, 'Can only be called by owner.');

      _minters[minter] = true;
      emit MinterAddition(minter);

    }

     
    function beginLockDrop() public {

         
        require(_lastLockDropTimestamp + ONE_MONTH <= block.timestamp, '30 day cooling period.');

         
        _lastLockDropTimestamp = block.timestamp;

         
        uint256 lockDropSize = totalSupply().mul(8295381).div(10 ** 10);

         
        LockDrop lockDrop = new LockDrop(address(this));

         
        _lastLockDropAddress = address(lockDrop);

         
        _mint(_lastLockDropAddress, lockDropSize);

         
        _mint(msg.sender, MINTING_REWARD);

         
        emit LockDropCreation(
            msg.sender,
            block.timestamp,
            lockDropSize,
            address(lockDrop)
        );

    }

     
    function getMintingLimit() public view returns(uint256) {

         
        uint256 y = (block.timestamp - _launchTimestamp) / uint(ONE_YEAR);

         
        uint256 mintingLimit = 2 ** 25 * 10 ** 18;
        if (y > 0) {mintingLimit += 2 ** 24 * 10 ** 18;}
        if (y > 1) {mintingLimit += 2 ** 23 * 10 ** 18;}
        if (y > 2) {mintingLimit += 2 ** 22 * 10 ** 18;}

         
        return mintingLimit;

    }

     
    function mint(uint256 mintedAmount, address recipient) public {

        require(_minters[msg.sender] == true, 'Can only be called by registered minter.');

         
        require(_totalMinted.add(mintedAmount) <= getMintingLimit(), 'Exceeds global cap.');

         
        _totalMinted += mintedAmount;

         
        _mint(recipient, mintedAmount);

    }

}

 
contract LockDrop {
    using SafeMath for uint256;

     
    uint256 public _stakingEnd;

     
    uint256 public _weightsSum;

     
    address public _kongERC20Address;

     
    mapping(address => uint256) public _weights;

     
    mapping(address => uint256) public _lockingEnds;

     
    event Staked(
        address indexed contributor,
        address lockETHAddress,
        uint256 ethStaked,
        uint256 endDate
    );
    event Claimed(
        address indexed claimant,
        uint256 ethStaked,
        uint256 kongClaim
    );

    constructor (address kongERC20Address) public {

         
        _kongERC20Address = kongERC20Address;

         
        _stakingEnd = block.timestamp + 30 days;

    }

     
    function stakeETH(uint256 stakingPeriod) public payable {

         
        require(msg.value > 0, 'Msg value = 0.');

         
        require(_weights[msg.sender] == 0, 'No topping up.');

         
        require(block.timestamp <= _stakingEnd, 'Closed for contributions.');

         
        require(stakingPeriod >= 30 && stakingPeriod <= 365, 'Staking period outside of allowed range.');

         
        uint256 totalTime = _stakingEnd + stakingPeriod * 1 days - block.timestamp;
        uint256 weight = totalTime.mul(msg.value);

         
        _weightsSum = _weightsSum.add(weight);
        _weights[msg.sender] = weight;

         
        _lockingEnds[msg.sender] = _stakingEnd + stakingPeriod * 1 days;

         
        LockETH lockETH = (new LockETH).value(msg.value)(_lockingEnds[msg.sender], msg.sender);

         
        require(address(lockETH).balance >= msg.value);

         
        emit Staked(msg.sender, address(lockETH), msg.value, _lockingEnds[msg.sender]);

    }

     
    function claimKong() external {

         
        require(_weights[msg.sender] > 0, 'Zero contribution.');

         
        require(block.timestamp > _lockingEnds[msg.sender], 'Cannot claim yet.');

         
        uint256 weight = _weights[msg.sender];
        uint256 kongClaim = IERC20(_kongERC20Address).balanceOf(address(this)).mul(weight).div(_weightsSum);

         
        _weights[msg.sender] = 0;
        _weightsSum = _weightsSum.sub(weight);

         
        IERC20(_kongERC20Address).transfer(msg.sender, kongClaim);

         
        emit Claimed(msg.sender, weight, kongClaim);

    }

}

 
contract LockETH {

    uint256 public _endOfLockUp;
    address payable public _contractOwner;

    constructor (uint256 endOfLockUp, address payable contractOwner) public payable {

        _endOfLockUp = endOfLockUp;
        _contractOwner = contractOwner;

    }

     
    function unlockETH() external {

         
        require(block.timestamp > _endOfLockUp, 'Cannot claim yet.');

         
        _contractOwner.transfer(address(this).balance);

    }

}