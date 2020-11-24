 

pragma solidity >=0.4.21 <0.6.0;

 
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

 
interface CERC20 {
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

 
interface Comptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
  function markets(address cToken) external view returns (bool isListed, uint256 collateralFactorMantissa);
}

contract PooledCDAI is ERC20, Ownable {
  uint256 internal constant PRECISION = 10 ** 18;

  address public constant COMPTROLLER_ADDRESS = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
  address public constant CDAI_ADDRESS = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
  address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;

  string private _name;
  string private _symbol;

  address public beneficiary;  

  event Mint(address indexed sender, address indexed to, uint256 amount);
  event Burn(address indexed sender, address indexed to, uint256 amount);
  event WithdrawInterest(address indexed sender, address beneficiary, uint256 amount, bool indexed inDAI);
  event SetBeneficiary(address oldBeneficiary, address newBeneficiary);

   
  constructor (string memory name, string memory symbol, address _beneficiary) public {
    _name = name;
    _symbol = symbol;

     
    require(_beneficiary != address(0), "Beneficiary can't be zero");
    beneficiary = _beneficiary;
    emit SetBeneficiary(address(0), _beneficiary);

     
    Comptroller troll = Comptroller(COMPTROLLER_ADDRESS);
    address[] memory cTokens = new address[](1);
    cTokens[0] = CDAI_ADDRESS;
    uint[] memory errors = troll.enterMarkets(cTokens);
    require(errors[0] == 0, "Failed to enter cDAI market");
  }

   
  function name() public view returns (string memory) {
    return _name;
  }

   
  function symbol() public view returns (string memory) {
    return _symbol;
  }

   
  function decimals() public pure returns (uint8) {
    return 18;
  }

  function mint(address to, uint256 amount) public returns (bool) {
     
    ERC20 dai = ERC20(DAI_ADDRESS);
    require(dai.transferFrom(msg.sender, address(this), amount), "Failed to transfer DAI from msg.sender");

     
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    require(dai.approve(CDAI_ADDRESS, 0), "Failed to clear DAI allowance");
    require(dai.approve(CDAI_ADDRESS, amount), "Failed to set DAI allowance");
    require(cDAI.mint(amount) == 0, "Failed to mint cDAI");

     
    _mint(to, amount);

     
    emit Mint(msg.sender, to, amount);

    return true;
  }

  function burn(address to, uint256 amount) public returns (bool) {
     
    _burn(msg.sender, amount);

     
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    require(cDAI.redeemUnderlying(amount) == 0, "Failed to redeem");

     
    ERC20 dai = ERC20(DAI_ADDRESS);
    require(dai.transfer(to, amount), "Failed to transfer DAI to target");

     
    emit Burn(msg.sender, to, amount);

    return true;
  }

  function accruedInterestCurrent() public returns (uint256) {
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    return cDAI.exchangeRateCurrent().mul(cDAI.balanceOf(address(this))).div(PRECISION).sub(totalSupply());
  }

  function accruedInterestStored() public view returns (uint256) {
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    return cDAI.exchangeRateStored().mul(cDAI.balanceOf(address(this))).div(PRECISION).sub(totalSupply());
  }

  function withdrawInterestInDAI() public returns (bool) {
     
    uint256 interestAmount = accruedInterestCurrent();

     
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    require(cDAI.redeemUnderlying(interestAmount) == 0, "Failed to redeem");

     
    ERC20 dai = ERC20(DAI_ADDRESS);
    require(dai.transfer(beneficiary, interestAmount), "Failed to transfer DAI to beneficiary");

    emit WithdrawInterest(msg.sender, beneficiary, interestAmount, true);

    return true;
  }

  function withdrawInterestInCDAI() public returns (bool) {
     
    CERC20 cDAI = CERC20(CDAI_ADDRESS);
    uint256 interestAmountInCDAI = accruedInterestCurrent().mul(PRECISION).div(cDAI.exchangeRateCurrent());

     
    require(cDAI.transfer(beneficiary, interestAmountInCDAI), "Failed to transfer cDAI to beneficiary");

     
    emit WithdrawInterest(msg.sender, beneficiary, interestAmountInCDAI, false);

    return true;
  }

  function setBeneficiary(address newBeneficiary) public onlyOwner returns (bool) {
    require(newBeneficiary != address(0), "Beneficiary can't be zero");
    emit SetBeneficiary(beneficiary, newBeneficiary);

    beneficiary = newBeneficiary;

    return true;
  }

  function() external payable {
    revert("Contract doesn't support receiving Ether");
  }
}

contract PooledCDAIFactory {
  event CreatePool(address sender, address pool, bool indexed renounceOwnership);

  function createPCDAI(string memory name, string memory symbol, address _beneficiary, bool renounceOwnership) public returns (PooledCDAI) {
    PooledCDAI pcDAI = _createPCDAI(name, symbol, _beneficiary, renounceOwnership);
    emit CreatePool(msg.sender, address(pcDAI), renounceOwnership);
    return pcDAI;
  }

  function _createPCDAI(string memory name, string memory symbol, address _beneficiary, bool renounceOwnership) internal returns (PooledCDAI) {
    PooledCDAI pcDAI = new PooledCDAI(name, symbol, _beneficiary);
    if (renounceOwnership) {
      pcDAI.renounceOwnership();
    } else {
      pcDAI.transferOwnership(msg.sender);
    }
    return pcDAI;
  }
}

contract MetadataPooledCDAIFactory is PooledCDAIFactory {
  event CreatePoolWithMetadata(address sender, address pool, bool indexed renounceOwnership, bytes metadata);

  function createPCDAIWithMetadata(
    string memory name,
    string memory symbol,
    address _beneficiary,
    bool renounceOwnership,
    bytes memory metadata
  ) public returns (PooledCDAI) {
    PooledCDAI pcDAI = _createPCDAI(name, symbol, _beneficiary, renounceOwnership);
    emit CreatePoolWithMetadata(msg.sender, address(pcDAI), renounceOwnership, metadata);
  }
}