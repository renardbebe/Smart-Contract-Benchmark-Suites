 

 

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

 

pragma solidity ^0.5.0;



 
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

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
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

 

pragma solidity ^0.5.2;

interface CERC20 {
  function mint(uint256 mintAmount) external returns (uint256);
  function redeem(uint256 redeemTokens) external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function supplyRatePerBlock() external view returns (uint256);
}

 

pragma solidity ^0.5.2;

interface iERC20 {
  function mint(
    address receiver,
    uint256 depositAmount)
    external
    returns (uint256 mintAmount);

  function burn(
    address receiver,
    uint256 burnAmount)
    external
    returns (uint256 loanAmountPaid);

  function tokenPrice()
    external
    view
    returns (uint256 price);

  function supplyInterestRate()
    external
    view
    returns (uint256);

  function claimLoanToken()
    external
    returns (uint256 claimedAmount);

   
}

 

pragma solidity ^0.5.2;





library IdleHelp {
  using SafeMath for uint256;

  function getPriceInToken(address cToken, address iToken, address bestToken, uint256 totalSupply, uint256 poolSupply)
    public view
    returns (uint256 tokenPrice) {
       
       
      uint256 navPool;
      uint256 price;

       
      if (bestToken == cToken) {
         
        price = CERC20(cToken).exchangeRateStored();  
      } else {
        price = iERC20(iToken).tokenPrice();  
      }
      navPool = price.mul(poolSupply);  
      tokenPrice = navPool.div(totalSupply);  
  }
  function getAPRs(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (uint256 cApr, uint256 iApr) {
      uint256 cRate = CERC20(cToken).supplyRatePerBlock();  
      cApr = cRate.mul(blocksInAYear).mul(100);
      iApr = iERC20(iToken).supplyInterestRate();  
  }
  function getBestRateToken(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (address bestRateToken, uint256 bestRate, uint256 worstRate) {
      (uint256 cApr, uint256 iApr) = getAPRs(cToken, iToken, blocksInAYear);
      bestRateToken = cToken;
      bestRate = cApr;
      worstRate = iApr;
      if (iApr > cApr) {
        worstRate = cApr;
        bestRate = iApr;
        bestRateToken = iToken;
      }
  }
  function rebalanceCheck(address cToken, address iToken, address bestToken, uint256 blocksInAYear, uint256 minRateDifference)
    public view
    returns (bool shouldRebalance, address bestTokenAddr) {
      shouldRebalance = false;

      uint256 _bestRate;
      uint256 _worstRate;
      (bestTokenAddr, _bestRate, _worstRate) = getBestRateToken(cToken, iToken, blocksInAYear);
      if (
          bestToken == address(0) ||
          (bestTokenAddr != bestToken && (_worstRate.add(minRateDifference) < _bestRate))) {
        shouldRebalance = true;
        return (shouldRebalance, bestTokenAddr);
      }

      return (shouldRebalance, bestTokenAddr);
  }
}

 

pragma solidity ^0.5.2;











contract IdleDAI is ERC20, ERC20Detailed, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public cToken;  
  address public iToken;  
  address public token;
  address public bestToken;

  uint256 public blocksInAYear;
  uint256 public minRateDifference;

   
  constructor(address _cToken, address _iToken, address _token)
    public
    ERC20Detailed("IdleDAI", "IDLEDAI", 18) {
      cToken = _cToken;
      iToken = _iToken;
      token = _token;
      blocksInAYear = 2102400;  
      minRateDifference = 300000000000000000;  
  }

   
  function setMinRateDifference(uint256 _rate)
    external onlyOwner {
      minRateDifference = _rate;
  }
  function setBlocksInAYear(uint256 _blocks)
    external onlyOwner {
      blocksInAYear = _blocks;
  }
  function setToken(address _token)
    external onlyOwner {
      token = _token;
  }
  function setIToken(address _iToken)
    external onlyOwner {
      iToken = _iToken;
  }
  function setCToken(address _cToken)
    external onlyOwner {
      cToken = _cToken;
  }
   
   
  function emergencyWithdraw(address _token, uint256 _value)
    external onlyOwner {
      IERC20 underlying = IERC20(_token);
      if (_value != 0) {
        underlying.safeTransfer(msg.sender, _value);
      } else {
        underlying.safeTransfer(msg.sender, underlying.balanceOf(address(this)));
      }
  }

   
  function tokenPrice()
    public view
    returns (uint256 price) {
      uint256 poolSupply = IERC20(cToken).balanceOf(address(this));
      if (bestToken == iToken) {
        poolSupply = IERC20(iToken).balanceOf(address(this));
      }

      price = IdleHelp.getPriceInToken(
        cToken,
        iToken,
        bestToken,
        this.totalSupply(),
        poolSupply
      );
  }
  function rebalanceCheck()
    public view
    returns (bool, address) {
      return IdleHelp.rebalanceCheck(cToken, iToken, bestToken, blocksInAYear, minRateDifference);
  }
  function getAPRs()
    external view
    returns (uint256, uint256) {
      return IdleHelp.getAPRs(cToken, iToken, blocksInAYear);
  }

   
   
  function mintIdleToken(uint256 _amount)
    external nonReentrant
    returns (uint256 mintedTokens) {
      require(_amount > 0, "Amount is not > 0");
       
      IERC20 underlying = IERC20(token);
       
      underlying.safeTransferFrom(msg.sender, address(this), _amount);

      rebalance();

      uint256 idlePrice = 10**18;
      uint256 totalSupply = this.totalSupply();
      if (totalSupply != 0) {
        idlePrice = tokenPrice();
      }

      if (bestToken == cToken) {
        _mintCTokens(_amount);
      } else {
        _mintITokens(_amount);
      }
      if (totalSupply == 0) {
        mintedTokens = _amount;  
      } else {
        mintedTokens = _amount.mul(10**18).div(idlePrice);
      }
      _mint(msg.sender, mintedTokens);
  }

   
  function redeemIdleToken(uint256 _amount)
    external nonReentrant
    returns (uint256 tokensRedeemed) {
    uint256 idleSupply = this.totalSupply();
    require(idleSupply > 0, 'No IDLEDAI have been issued');

    if (bestToken == cToken) {
      uint256 cPoolBalance = IERC20(cToken).balanceOf(address(this));
      uint256 cDAItoRedeem = _amount.mul(cPoolBalance).div(idleSupply);
      tokensRedeemed = _redeemCTokens(cDAItoRedeem, msg.sender);
    } else {
      uint256 iPoolBalance = IERC20(iToken).balanceOf(address(this));
      uint256 iDAItoRedeem = _amount.mul(iPoolBalance).div(idleSupply);
       
      tokensRedeemed = _redeemITokens(iDAItoRedeem, msg.sender);
    }
    _burn(msg.sender, _amount);
    rebalance();
  }

   
  function rebalance()
    public {
      (bool shouldRebalance, address newBestTokenAddr) = rebalanceCheck();
      if (!shouldRebalance) {
        return;
      }

      if (bestToken != address(0)) {
         
        if (bestToken == cToken) {
          _redeemCTokens(IERC20(cToken).balanceOf(address(this)), address(this));  
          _mintITokens(IERC20(token).balanceOf(address(this)));
        } else {
          _redeemITokens(IERC20(iToken).balanceOf(address(this)), address(this));
          _mintCTokens(IERC20(token).balanceOf(address(this)));
        }
      }

       
      bestToken = newBestTokenAddr;
  }
   
  function claimITokens()
    external
    returns (uint256 claimedTokens) {
      claimedTokens = iERC20(iToken).claimLoanToken();
      if (claimedTokens == 0) {
        return claimedTokens;
      }

      rebalance();
      if (bestToken == cToken) {
        _mintCTokens(claimedTokens);
      } else {
        _mintITokens(claimedTokens);
      }

      return claimedTokens;
  }

   
  function _mintCTokens(uint256 _amount)
    internal
    returns (uint256 cTokens) {
      if (IERC20(token).balanceOf(address(this)) == 0) {
        return cTokens;
      }
       
      IERC20(token).safeIncreaseAllowance(cToken, _amount);

       
      CERC20 _cToken = CERC20(cToken);
       
      require(_cToken.mint(_amount) == 0, "Error minting");
       

       
      uint256 exchangeRateMantissa = _cToken.exchangeRateStored();  
       
      cTokens = _amount.mul(10**18).div(exchangeRateMantissa);
  }
  function _mintITokens(uint256 _amount)
    internal
    returns (uint256 iTokens) {
      if (IERC20(token).balanceOf(address(this)) == 0) {
        return iTokens;
      }
       
      IERC20(token).safeIncreaseAllowance(iToken, _amount);
       
      iERC20 _iToken = iERC20(iToken);
       
      iTokens = _iToken.mint(address(this), _amount);
  }

  function _redeemCTokens(uint256 _amount, address _account)
    internal
    returns (uint256 tokens) {
      CERC20 _cToken = CERC20(cToken);
       
      require(_cToken.redeem(_amount) == 0, "Something went wrong when redeeming in cTokens");

       
      uint256 exchangeRateMantissa = _cToken.exchangeRateStored();  
       
      tokens = _amount.mul(exchangeRateMantissa).div(10**18);

      if (_account != address(this)) {
        IERC20(token).safeTransfer(_account, tokens);
      }
  }
  function _redeemITokens(uint256 _amount, address _account)
    internal
    returns (uint256 tokens) {
      tokens = iERC20(iToken).burn(_account, _amount);
  }
}