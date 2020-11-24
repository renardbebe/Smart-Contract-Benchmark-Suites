 

 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

 
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

 

 
interface ICompoundERC20 {
  function mint(uint mintAmount) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint);
  function decimals() external view returns (uint);
  function underlying() external view returns (address);
  function exchangeRateStored() external view returns (uint);
}

 

 
interface IComptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
}

 

 
contract CompoundPool is ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint;

    uint256 internal constant PRECISION = 10 ** 18;

    ICompoundERC20 public compoundToken;
    IERC20 public depositToken;
    address public governance;
    address public beneficiary;

     
    constructor(
        string memory _name,
        string memory _symbol,
        IComptroller _comptroller,
        ICompoundERC20 _compoundToken,
        IERC20 _depositToken,
        address _beneficiary
    )
        ERC20Detailed(_name, _symbol, 18)
        public
    {
        compoundToken = _compoundToken;
        depositToken = _depositToken;
        beneficiary = _beneficiary;

        _approveDepositToken(1);

         
        address[] memory markets = new address[](1);
        markets[0] = address(compoundToken);
        uint[] memory errors = _comptroller.enterMarkets(markets);
        require(errors[0] == 0, "Failed to enter compound token market");
    }

     
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "CompoundPool::onlyBeneficiary: Only callable by beneficiary");
        _;
    }

     
    function updateBeneficiary(address _newBeneficiary) public onlyOwner {
        beneficiary = _newBeneficiary;
    }

     
    function withdrawInterest(address _to, uint256 _amount) public onlyBeneficiary returns (uint256) {
        require(compoundToken.redeemUnderlying(_amount) == 0, "CompoundPool::withdrawInterest: Compound redeem failed");

         
        require(depositTokenStoredBalance() >= totalSupply(), "CompoundPool::withdrawInterest: Not enough excess deposit token");

        depositToken.transfer(_to, _amount);
    }

     
    function deposit(uint256 _amount) public {
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "CompoundPool::deposit: Transfer failed");

        _approveDepositToken(_amount);

        require(compoundToken.mint(_amount) == 0, "CompoundPool::deposit: Compound mint failed");
    
        _mint(msg.sender, _amount);
    }

     
    function withdraw(uint256 _amount) public {
        _burn(msg.sender, _amount);

        require(compoundToken.redeemUnderlying(_amount) == 0, "CompoundPool::withdraw: Compound redeem failed");

        require(depositToken.transfer(msg.sender, _amount), "CompoundPool::withdraw: Transfer failed");
    }

     
    function donate(uint256 _amount) public {
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "CompoundPool::donate: Transfer failed");

        _approveDepositToken(_amount);

        require(compoundToken.mint(_amount) == 0, "CompoundPool::donate: Compound mint failed");
    }

     
    function excessDepositTokens() public returns (uint256) {
        return compoundToken.exchangeRateCurrent().mul(compoundToken.balanceOf(address(this))).div(PRECISION).sub(totalSupply());
    }

    function depositTokenStoredBalance() internal returns (uint256) {
        return compoundToken.exchangeRateStored().mul(compoundToken.balanceOf(address(this))).div(PRECISION);
    }

    function _approveDepositToken(uint256 _minimum) internal {
        if(depositToken.allowance(address(this), address(compoundToken)) < _minimum){
            depositToken.approve(address(compoundToken),uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff));
        }
    }
}

 

contract IHumanityRegistry {
    function isHuman(address who) public view returns (bool);
}

 

 
contract UniversalBasicIncome {
    using SafeMath for uint;

    IHumanityRegistry public registry;
    IERC20 public dai;
    CompoundPool public bank;

    uint public constant MONTHLY_INCOME = 1e18;  
    uint public constant INCOME_PER_SECOND = MONTHLY_INCOME / 30 days;

    mapping (address => uint) public claimTimes;

    constructor(IHumanityRegistry _registry, IERC20 _dai, CompoundPool _bank) public {
        registry = _registry;
        dai = _dai;
        bank = _bank;
    }

    function claim() public {
        require(registry.isHuman(msg.sender), "UniversalBasicIncome::claim: You must be on the Humanity registry to claim income");

        uint income;
        uint time = block.timestamp;

         
        if (claimTimes[msg.sender] == 0) {
            income = MONTHLY_INCOME;
        } else {
            income = time.sub(claimTimes[msg.sender]).mul(INCOME_PER_SECOND);
        }

        uint balance = bank.excessDepositTokens();
         
        uint actualIncome = balance < income ? balance : income;

        bank.withdrawInterest(msg.sender, actualIncome);
        claimTimes[msg.sender] = time;
    }

    function claimableBalance(address human) public returns (uint256) {
        if(!registry.isHuman(human)){
            return 0;
        }
        uint income;
        uint time = block.timestamp;

         
        if (claimTimes[msg.sender] == 0) {
            income = MONTHLY_INCOME;
        } else {
            income = time.sub(claimTimes[msg.sender]).mul(INCOME_PER_SECOND);
        }

        uint balance = bank.excessDepositTokens();
         
        return balance < income ? balance : income;

    }

}