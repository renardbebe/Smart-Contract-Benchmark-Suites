 

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

   
  function init(string memory name, string memory symbol, address _beneficiary) public {
    require(beneficiary == address(0), "Already initialized");

    _name = name;
    _symbol = symbol;

     
    require(_beneficiary != address(0), "Beneficiary can't be zero");
    beneficiary = _beneficiary;
    emit SetBeneficiary(address(0), _beneficiary);
    
    _transferOwnership(msg.sender);

     
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

 
 
 

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

contract PooledCDAIFactory is CloneFactory {

  address public libraryAddress;

  event CreatePool(address sender, address pool, bool indexed renounceOwnership);

  constructor(address _libraryAddress) public {
    libraryAddress = _libraryAddress;
  }

  function createPCDAI(string memory name, string memory symbol, address beneficiary, bool renounceOwnership) public returns (PooledCDAI) {
    PooledCDAI pcDAI = _createPCDAI(name, symbol, beneficiary, renounceOwnership);
    emit CreatePool(msg.sender, address(pcDAI), renounceOwnership);
    return pcDAI;
  }

  function _createPCDAI(string memory name, string memory symbol, address beneficiary, bool renounceOwnership) internal returns (PooledCDAI) {
    address payable clone = _toPayableAddr(createClone(libraryAddress));
    PooledCDAI pcDAI = PooledCDAI(clone);
    pcDAI.init(name, symbol, beneficiary);
    if (renounceOwnership) {
      pcDAI.renounceOwnership();
    } else {
      pcDAI.transferOwnership(msg.sender);
    }
    return pcDAI;
  }

  function _toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}

contract MetadataPooledCDAIFactory is PooledCDAIFactory {
  event CreatePoolWithMetadata(address sender, address pool, bool indexed renounceOwnership, bytes metadata);

  constructor(address _libraryAddress) public PooledCDAIFactory(_libraryAddress) {}

  function createPCDAIWithMetadata(
    string memory name,
    string memory symbol,
    address beneficiary,
    bool renounceOwnership,
    bytes memory metadata
  ) public returns (PooledCDAI) {
    PooledCDAI pcDAI = _createPCDAI(name, symbol, beneficiary, renounceOwnership);
    emit CreatePoolWithMetadata(msg.sender, address(pcDAI), renounceOwnership, metadata);
  }
}

interface KyberNetworkProxy {
  function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
      returns (uint expectedRate, uint slippageRate);

  function tradeWithHint(
    ERC20 src, uint srcAmount, ERC20 dest, address payable destAddress, uint maxDestAmount,
    uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
}

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract PooledCDAIKyberExtension {
  using SafeERC20 for ERC20;
  using SafeERC20 for PooledCDAI;
  using SafeMath for uint256;

  address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
  address public constant KYBER_ADDRESS = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
  ERC20 internal constant ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  bytes internal constant PERM_HINT = "PERM";  
  uint internal constant MAX_QTY   = (10**28);  

  function mintWithETH(PooledCDAI pcDAI, address to) public payable returns (bool) {
     
    ERC20 dai = ERC20(DAI_ADDRESS);
    (uint256 actualDAIAmount, uint256 actualETHAmount) = _kyberTrade(ETH_TOKEN_ADDRESS, msg.value, dai);

     
    _mint(pcDAI, to, actualDAIAmount);

     
    if (actualETHAmount < msg.value) {
      msg.sender.transfer(msg.value.sub(actualETHAmount));
    }

    return true;
  }

  function mintWithToken(PooledCDAI pcDAI, address tokenAddress, address to, uint256 amount) public returns (bool) {
    require(tokenAddress != address(ETH_TOKEN_ADDRESS), "Use mintWithETH() instead");
    require(tokenAddress != DAI_ADDRESS, "Use mint() instead");

     
    ERC20 token = ERC20(tokenAddress);
    token.safeTransferFrom(msg.sender, address(this), amount);

     
    ERC20 dai = ERC20(DAI_ADDRESS);
    (uint256 actualDAIAmount, uint256 actualTokenAmount) = _kyberTrade(token, amount, dai);

     
    _mint(pcDAI, to, actualDAIAmount);

     
    if (actualTokenAmount < amount) {
      token.safeTransfer(msg.sender, amount.sub(actualTokenAmount));
    }

    return true;
  }

  function burnToETH(PooledCDAI pcDAI, address payable to, uint256 amount) public returns (bool) {
     
    _burn(pcDAI, amount);

     
    ERC20 dai = ERC20(DAI_ADDRESS);
    (uint256 actualETHAmount, uint256 actualDAIAmount) = _kyberTrade(dai, amount, ETH_TOKEN_ADDRESS);

     
    to.transfer(actualETHAmount);

     
    if (actualDAIAmount < amount) {
      dai.safeTransfer(msg.sender, amount.sub(actualDAIAmount));
    }

    return true;
  }

  function burnToToken(PooledCDAI pcDAI, address tokenAddress, address to, uint256 amount) public returns (bool) {
    require(tokenAddress != address(ETH_TOKEN_ADDRESS), "Use burnToETH() instead");
    require(tokenAddress != DAI_ADDRESS, "Use burn() instead");

     
    _burn(pcDAI, amount);

     
    ERC20 dai = ERC20(DAI_ADDRESS);
    ERC20 token = ERC20(tokenAddress);
    (uint256 actualTokenAmount, uint256 actualDAIAmount) = _kyberTrade(dai, amount, token);

     
    token.safeTransfer(to, actualTokenAmount);

     
    if (actualDAIAmount < amount) {
      dai.safeTransfer(msg.sender, amount.sub(actualDAIAmount));
    }

    return true;
  }

  function _mint(PooledCDAI pcDAI, address to, uint256 actualDAIAmount) internal {
    ERC20 dai = ERC20(DAI_ADDRESS);
    dai.safeApprove(address(pcDAI), 0);
    dai.safeApprove(address(pcDAI), actualDAIAmount);
    require(pcDAI.mint(to, actualDAIAmount), "Failed to mint pcDAI");
  }

  function _burn(PooledCDAI pcDAI, uint256 amount) internal {
     
    pcDAI.safeTransferFrom(msg.sender, address(this), amount);

     
    require(pcDAI.burn(address(this), amount), "Failed to burn pcDAI");
  }

   
  function _getBalance(ERC20 _token, address _addr) internal view returns(uint256) {
    if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
      return uint256(_addr.balance);
    }
    return uint256(_token.balanceOf(_addr));
  }

  function _toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }

   
  function _kyberTrade(ERC20 _srcToken, uint256 _srcAmount, ERC20 _destToken)
    internal
    returns(
      uint256 _actualDestAmount,
      uint256 _actualSrcAmount
    )
  {
     
    KyberNetworkProxy kyber = KyberNetworkProxy(KYBER_ADDRESS);
    (, uint256 rate) = kyber.getExpectedRate(_srcToken, _destToken, _srcAmount);
    require(rate > 0, "Price for token is 0 on Kyber");

    uint256 beforeSrcBalance = _getBalance(_srcToken, address(this));
    uint256 msgValue;
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      msgValue = 0;
      _srcToken.safeApprove(KYBER_ADDRESS, 0);
      _srcToken.safeApprove(KYBER_ADDRESS, _srcAmount);
    } else {
      msgValue = _srcAmount;
    }
    _actualDestAmount = kyber.tradeWithHint.value(msgValue)(
      _srcToken,
      _srcAmount,
      _destToken,
      _toPayableAddr(address(this)),
      MAX_QTY,
      rate,
      0x8B2315243349f461045854beec3c5aFA84f600B6,
      PERM_HINT
    );
    require(_actualDestAmount > 0, "Received 0 dest token");
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      _srcToken.safeApprove(KYBER_ADDRESS, 0);
    }

    _actualSrcAmount = beforeSrcBalance.sub(_getBalance(_srcToken, address(this)));
  }
  
  function() external payable {}
}