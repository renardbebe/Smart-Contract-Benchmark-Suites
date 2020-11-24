 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;




 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

 

pragma solidity ^0.5.0;

interface IBancorNetwork {
  function etherTokens(address _token) external view returns(bool);        

  function convert2(
    address[] calldata _path,
    uint256 _amount,
    uint256 _minReturn,
    address _affiliateAccount,
    uint256 _affiliateFee
  ) external payable returns(uint256);

  function claimAndConvert2(
    address[] calldata _path,
    uint256 _amount,
    uint256 _minReturn,
    address _affiliateAccount,
    uint256 _affiliateFee
  ) external returns(uint256);

  function getReturnByPath(address[] calldata _path, uint256 _amount)
    external view returns(uint256 toUserAmount, uint256 feeAmount);
}

interface IBancorNetworkPathFinder {
  function generatePath(address _sourceToken, address _targetToken) external view returns(address[] memory);
}

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
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

 

pragma solidity >=0.5.0;


 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(address(bytes20(owner())));
  }

  function destroyAndSend(address payable _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

pragma solidity >=0.4.24;


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "The contract is paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "The contract is not paused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.5.0;




 
contract ERC20 is Context, IERC20 {
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

      
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 

pragma solidity >=0.4.24;




contract Withdrawable is Ownable {
  using SafeERC20 for ERC20;
  address constant ETHER = address(0);

  event LogWithdrawToken(
    address indexed _from,
    address indexed _token,
    uint amount
  );

   
  function withdrawToken(address _tokenAddress) public onlyOwner {
    uint tokenBalance;
    if (_tokenAddress == ETHER) {
      address self = address(this);  
      tokenBalance = self.balance;
      msg.sender.transfer(tokenBalance);
    } else {
      tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
      ERC20(_tokenAddress).safeTransfer(msg.sender, tokenBalance);
    }
    emit LogWithdrawToken(msg.sender, _tokenAddress, tokenBalance);
  }

}

 

pragma solidity ^0.5.0;





contract WithFee is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint;
  address payable public feeWallet;
  uint public storedSpread;
  uint constant spreadDecimals = 6;
  uint constant spreadUnit = 10 ** spreadDecimals;

  event LogFee(address token, uint amount);

  constructor(address payable _wallet, uint _spread) public {
    require(_wallet != address(0), "_wallet == address(0)");
    require(_spread < spreadUnit, "spread >= spreadUnit");
    feeWallet = _wallet;
    storedSpread = _spread;
  }

  function setFeeWallet(address payable _wallet) external onlyOwner {
    require(_wallet != address(0), "_wallet == address(0)");
    feeWallet = _wallet;
  }

  function setSpread(uint _spread) external onlyOwner {
    storedSpread = _spread;
  }

  function _getFee(uint underlyingTokenTotal) internal view returns(uint) {
    return underlyingTokenTotal.mul(storedSpread).div(spreadUnit);
  }

  function _payFee(address feeToken, uint fee) internal {
    if (fee > 0) {
      if (feeToken == address(0)) {
        feeWallet.transfer(fee);
      } else {
        IERC20(feeToken).safeTransfer(feeWallet, fee);
      }
      emit LogFee(feeToken, fee);
    }
  }

}

 

pragma solidity >=0.4.0;

interface IErc20Swap {
    function getRate(address src, address dst, uint256 srcAmount) external view returns(uint expectedRate, uint slippageRate);   
    function swap(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) external payable;

    event LogTokenSwap(
        address indexed _userAddress,
        address indexed _userSentTokenAddress,
        uint _userSentTokenAmount,
        address indexed _userReceivedTokenAddress,
        uint _userReceivedTokenAmount
    );
}

 

pragma solidity >=0.5.0;









contract NetworkBasedTokenSwap is Withdrawable, Pausable, Destructible, WithFee, IErc20Swap
{
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  address constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  mapping (address => mapping (address => uint)) spreadCustom;

  event UnexpectedIntialBalance(address token, uint amount);

  constructor(
    address payable _wallet,
    uint _spread
  )
    public WithFee(_wallet, _spread)
  {}

  function() external payable {
     
  }

   
  function setSpread(address tokenA, address tokenB, uint spread) public onlyOwner {
    uint value = spread > spreadUnit ? spreadUnit : spread;
    spreadCustom[tokenA][tokenB] = value;
    spreadCustom[tokenB][tokenA] = value;
  }

  function getSpread(address tokenA, address tokenB) public view returns(uint) {
    uint value = spreadCustom[tokenA][tokenB];
    if (value == 0) return storedSpread;
    if (value >= spreadUnit) return 0;
    else return value;
  }

   
  function getNetworkRate(address src, address dest, uint256 srcAmount) internal view returns(uint expectedRate, uint slippageRate);

  function getRate(address src, address dest, uint256 srcAmount) external view
    returns(uint expectedRate, uint slippageRate)
  {
    (uint256 kExpected, uint256 kSplippage) = getNetworkRate(src, dest, srcAmount);
    uint256 spread = getSpread(src, dest);
    expectedRate = kExpected.mul(spreadUnit - spread).div(spreadUnit);
    slippageRate = kSplippage.mul(spreadUnit - spread).div(spreadUnit);
  }

  function _freeUnexpectedTokens(address token) private {
    uint256 unexpectedBalance = token == ETHER
      ? _myEthBalance().sub(msg.value)
      : IERC20(token).balanceOf(address(this));
    if (unexpectedBalance > 0) {
      _transfer(token, address(bytes20(owner())), unexpectedBalance);
      emit UnexpectedIntialBalance(token, unexpectedBalance);
    }
  }

  function swap(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) public payable {
    require(src != dest, "src == dest");
    require(srcAmount > 0, "srcAmount == 0");

     
    _freeUnexpectedTokens(src);
    _freeUnexpectedTokens(dest);

    if (src == ETHER) {
      require(msg.value == srcAmount, "msg.value != srcAmount");
    } else {
      require(
        IERC20(src).allowance(msg.sender, address(this)) >= srcAmount,
        "ERC20 allowance < srcAmount"
      );
       
      IERC20(src).safeTransferFrom(msg.sender, address(this), srcAmount);
    }

    uint256 spread = getSpread(src, dest);

     
    uint256 adaptedMinRate = minConversionRate.mul(spreadUnit).div(spreadUnit - spread);
    uint256 adaptedMaxDestAmount = maxDestAmount.mul(spreadUnit).div(spreadUnit - spread);
    uint256 destTradedAmount = doNetworkTrade(src, srcAmount, dest, adaptedMaxDestAmount, adaptedMinRate);

    uint256 notTraded = _myBalance(src);
    uint256 srcTradedAmount = srcAmount.sub(notTraded);
    require(srcTradedAmount > 0, "no traded tokens");
    require(
      _myBalance(dest) >= destTradedAmount,
      "No enough dest tokens after trade"
    );
     
    uint256 toUserAmount = _payFee(dest, destTradedAmount, spread);
    _transfer(dest, msg.sender, toUserAmount);
     
    if (notTraded > 0) {
      _transfer(src, msg.sender, notTraded);
    }

    emit LogTokenSwap(
      msg.sender,
      src,
      srcTradedAmount,
      dest,
      toUserAmount
    );
  }

  function doNetworkTrade(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) internal returns(uint256);

  function _payFee(address token, uint destTradedAmount, uint spread) private returns(uint256 toUserAmount) {
    uint256 fee = destTradedAmount.mul(spread).div(spreadUnit);
    toUserAmount = destTradedAmount.sub(fee);
     
    super._payFee(token == ETHER ? address(0) : token, fee);
  }

   
  function _myEthBalance() private view returns(uint256) {
    address self = address(this);
    return self.balance;
  }

  function _myBalance(address token) private view returns(uint256) {
    return token == ETHER
      ? _myEthBalance()
      : IERC20(token).balanceOf(address(this));
  }

  function _transfer(address token, address payable recipient, uint256 amount) private {
    if (token == ETHER) {
      recipient.transfer(amount);
    } else {
      IERC20(token).safeTransfer(recipient, amount);
    }
  }

}

 

pragma solidity ^0.5.0;


 
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

 

pragma solidity ^0.5.0;

library LowLevel {
  function callContractAddr(address target, bytes memory payload) internal view
    returns (bool success_, address result_)
  {
    (bool success, bytes memory result) = address(target).staticcall(payload);
    if (success && result.length == 32) {
      assembly {
        result_ := mload(add(result,32))
      }
      success_ = true;
    }
  }

  function callContractUint(address target, bytes memory payload) internal view
    returns (bool success_, uint result_)
  {
    (bool success, bytes memory result) = address(target).staticcall(payload);
    if (success && result.length == 32) {
      assembly {
        result_ := mload(add(result,32))
      }
      success_ = true;
    }
  }
}

 

pragma solidity ^0.5.0;





contract RateNormalization is Ownable {
  using SafeMath for uint;

  struct RateAdjustment {
    uint factor;
    bool multiply;
  }

  mapping (address => mapping(address => RateAdjustment)) public rateAdjustment;
  mapping (address => uint) public forcedDecimals;

   
  function normalizeRate(address src, address dest, uint256 rate) public view
    returns(uint)
  {
    RateAdjustment memory adj = rateAdjustment[src][dest];
    if (adj.factor == 0) {
      uint srcDecimals = _getDecimals(src);
      uint destDecimals = _getDecimals(dest);
      if (srcDecimals != destDecimals) {
        if (srcDecimals > destDecimals) {
          adj.multiply = true;
          adj.factor = 10 ** (srcDecimals - destDecimals);
        } else {
          adj.multiply = false;
          adj.factor = 10 ** (destDecimals - srcDecimals);
        }
      }
    }
    if (adj.factor > 1) {
      rate = adj.multiply
      ? rate.mul(adj.factor)
      : rate.div(adj.factor);
    }
    return rate;
  }

  function _getDecimals(address token) internal view returns(uint) {
    uint forced = forcedDecimals[token];
    if (forced > 0) return forced;
    bytes memory payload = abi.encodeWithSignature("decimals()");
    (bool success, uint decimals) = LowLevel.callContractUint(token, payload);
    require(success, "the token doesn't expose the decimals number");
    return decimals;
  }

  function setRateAdjustmentFactor(address src, address dest, uint factor, bool multiply) public onlyOwner {
    rateAdjustment[src][dest] = RateAdjustment(factor, multiply);
    rateAdjustment[dest][src] = RateAdjustment(factor, !multiply);
  }

  function setForcedDecimals(address token, uint decimals) public onlyOwner {
    forcedDecimals[token] = decimals;
  }

}

 

pragma solidity >=0.5.0;







contract BancorTokenSwap is RateNormalization, NetworkBasedTokenSwap
{
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  uint constant expScale = 1e18;

  IBancorNetwork public bancorNetwork;
  IBancorNetworkPathFinder public bancorNetworkPathFinder;
  address public bancorEtherToken;

  constructor(
    address _bancorNetwork,
    address _bancorNetworkPathFinder,
    address _bancorEtherToken,
    address payable _wallet,
    uint _spread
  )
    public NetworkBasedTokenSwap(_wallet, _spread)
  {
    setForcedDecimals(ETHER, 18);
    setBancorNetwork(_bancorNetwork, _bancorNetworkPathFinder, _bancorEtherToken);
  }

  function setBancorNetwork(address _bancorNetwork, address _bancorNetworkPathFinder, address _bancorEtherToken) public onlyOwner {
    require(_bancorNetwork != address(0), "_bancorNetwork == address(0)");
    require(_bancorNetworkPathFinder != address(0), "_bancorNetworkPathFinder == address(0)");
    bancorNetwork = IBancorNetwork(_bancorNetwork);
    bancorNetworkPathFinder = IBancorNetworkPathFinder(_bancorNetworkPathFinder);
    require(bancorNetwork.etherTokens(_bancorEtherToken), "_bancorEtherToken is not an EtherToken in the BancorNetwork");
    bancorEtherToken = _bancorEtherToken;
  }

  function _getPath(address src, address dest) private view returns(address[] memory) {
    address source = src == ETHER ? bancorEtherToken : src;
    address target = dest == ETHER ? bancorEtherToken : dest;
    return bancorNetworkPathFinder.generatePath(source, target);
  }

  function _getBancorRate(address[] memory path, uint srcAmount) private view returns(uint) {
    if (path.length == 0) return 0;
    (uint toUser,) = bancorNetwork.getReturnByPath(path, srcAmount);
    return toUser.mul(expScale).div(srcAmount);
  }

  function getNetworkRate(address src, address dest, uint256 srcAmount) internal view
    returns(uint expectedRate, uint slippageRate)
  {
    address[] memory path = _getPath(src, dest);
    uint rate = normalizeRate(src, dest, _getBancorRate(path, srcAmount));
    return (rate, rate);
  }

  function doNetworkTrade(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate)
    internal returns(uint256)
  {
    address[] memory path = _getPath(src, dest);
    uint rate = _getBancorRate(path, srcAmount);
    require(normalizeRate(src, dest, rate) >= minConversionRate, "cannot satisfy minConversionRate");
    (uint toUser,) = bancorNetwork.getReturnByPath(path, srcAmount);
    uint toTradeAmount = toUser > maxDestAmount
      ? maxDestAmount.mul(expScale).div(rate)
      : srcAmount;

    if (src == ETHER) {
      return bancorNetwork.convert2.value(toTradeAmount)(path, toTradeAmount, 1, address(0), 0);
    } else {
      if (IERC20(src).allowance(address(this), address(bancorNetwork)) > 0) {
        IERC20(src).safeApprove(address(bancorNetwork), 0);
      }
      IERC20(src).safeApprove(address(bancorNetwork), toTradeAmount);
      return bancorNetwork.claimAndConvert2(path, toTradeAmount, 1, address(0), 0);
    }
  }

}