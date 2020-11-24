 

pragma solidity ^0.5.8;


 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
interface IUnsafeERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external;

  function approve(address spender, uint256 value) external;

  function transferFrom(address from, address to, uint256 value) external;
}

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 
contract TokenSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 public saleToken;

     
    address public fundCollector;

     
    address public tokenWallet;

     
    mapping(address => bool) public whitelist;

     
    struct ExToken {
        bool safe;
        bool accepted;
        uint256 rate;
    }

     
    mapping(address => ExToken) private _exTokens;

     
    uint256 public bonusThreshold;

     
    uint256 public tierOneBonusTime;
    uint256 public tierOneBonusRate;

     
    uint256 public tierTwoBonusTime;
    uint256 public tierTwoBonusRate;

     
    event USDTSet(
        address indexed _setter,
        address indexed _usdt
    );

     
    event FundCollectorSet(
        address indexed _setter,
        address indexed _fundCollector
    );

     
    event SaleTokenSet(
        address indexed _setter,
        address indexed _saleToken
    );

     
    event TokenWalletSet(
        address indexed _setter,
        address indexed _tokenWallet
    );

     
    event BonusConditionsSet(
        address indexed _setter,
        uint256 _bonusThreshold,
        uint256 _tierOneBonusTime,
        uint256 _tierOneBonusRate,
        uint256 _tierTwoBonusTime,
        uint256 _tierTwoBonusRate
    );

     
    event WhitelistSet(
        address indexed _setter,
        address indexed _user,
        bool _allowed
    );

     
    event ExTokenSet(
        address indexed _setter,
        address indexed _exToken,
        bool _safe,
        bool _accepted,
        uint256 _rate
    );

     
    event TokensPurchased(
        address indexed _buyer,
        address indexed _exToken,
        uint256 _exTokenAmount,
        uint256 _amount
    );

    constructor (
        address _fundCollector,
        address _saleToken,
        address _tokenWallet,
        uint256 _bonusThreshold,
        uint256 _tierOneBonusTime,
        uint256 _tierOneBonusRate,
        uint256 _tierTwoBonusTime,
        uint256 _tierTwoBonusRate
    )
        public
    {
        _setFundCollector(_fundCollector);
        _setSaleToken(_saleToken);
        _setTokenWallet(_tokenWallet);
        _setBonusConditions(
            _bonusThreshold,
            _tierOneBonusTime,
            _tierOneBonusRate,
            _tierTwoBonusTime,
            _tierTwoBonusRate
        );

    }

     
    function setFundCollector(address _fundCollector) external onlyOwner {
        _setFundCollector(_fundCollector);
    }

     
    function _setFundCollector(address _fundCollector) private {
        require(_fundCollector != address(0), "fund collector cannot be 0x0");
        fundCollector = _fundCollector;
        emit FundCollectorSet(msg.sender, _fundCollector);
    }

     
    function setSaleToken(address _saleToken) external onlyOwner {
        _setSaleToken(_saleToken);
    }

     
    function _setSaleToken(address _saleToken) private {
        require(_saleToken != address(0), "sale token cannot be 0x0");
        saleToken = IERC20(_saleToken);
        emit SaleTokenSet(msg.sender, _saleToken);
    }

     
    function setTokenWallet(address _tokenWallet) external onlyOwner {
        _setTokenWallet(_tokenWallet);
    }

     
    function _setTokenWallet(address _tokenWallet) private {
        require(_tokenWallet != address(0), "token wallet cannot be 0x0");
        tokenWallet = _tokenWallet;
        emit TokenWalletSet(msg.sender, _tokenWallet);
    }

     
    function setBonusConditions(
        uint256 _bonusThreshold,
        uint256 _tierOneBonusTime,
        uint256 _tierOneBonusRate,
        uint256 _tierTwoBonusTime,
        uint256 _tierTwoBonusRate
    )
        external
        onlyOwner
    {
        _setBonusConditions(
            _bonusThreshold,
            _tierOneBonusTime,
            _tierOneBonusRate,
            _tierTwoBonusTime,
            _tierTwoBonusRate
        );
    }

    function _setBonusConditions(
        uint256 _bonusThreshold,
        uint256 _tierOneBonusTime,
        uint256 _tierOneBonusRate,
        uint256 _tierTwoBonusTime,
        uint256 _tierTwoBonusRate
    )
        private
        onlyOwner
    {
        require(_bonusThreshold > 0," threshold cannot be zero.");
        require(_tierOneBonusTime < _tierTwoBonusTime, "invalid bonus time");
        require(_tierOneBonusRate >= _tierTwoBonusRate, "invalid bonus rate");

        bonusThreshold = _bonusThreshold;
        tierOneBonusTime = _tierOneBonusTime;
        tierOneBonusRate = _tierOneBonusRate;
        tierTwoBonusTime = _tierTwoBonusTime;
        tierTwoBonusRate = _tierTwoBonusRate;

        emit BonusConditionsSet(
            msg.sender,
            _bonusThreshold,
            _tierOneBonusTime,
            _tierOneBonusRate,
            _tierTwoBonusTime,
            _tierTwoBonusRate
        );
    }

     
    function setWhitelist(address _user, bool _allowed) external onlyOwner {
        whitelist[_user] = _allowed;
        emit WhitelistSet(msg.sender, _user, _allowed);
    }

     
    function remainingTokens() external view returns (uint256) {
        return Math.min(
            saleToken.balanceOf(tokenWallet),
            saleToken.allowance(tokenWallet, address(this))
        );
    }

     
    function setExToken(
        address _exToken,
        bool _safe,
        bool _accepted,
        uint256 _rate
    )
        external
        onlyOwner
    {
        _exTokens[_exToken].safe = _safe;
        _exTokens[_exToken].accepted = _accepted;
        _exTokens[_exToken].rate = _rate;
        emit ExTokenSet(msg.sender, _exToken, _safe, _accepted, _rate);
    }

     
    function safe(address _exToken) public view returns (bool) {
        return _exTokens[_exToken].safe;
    }

     
    function accepted(address _exToken) public view returns (bool) {
        return _exTokens[_exToken].accepted;
    }

     
    function rate(address _exToken) external view returns (uint256) {
        return _exTokens[_exToken].rate;
    }

     
    function exchangeableAmounts(
        address _exToken,
        uint256 _amount
    )
        external
        view
        returns (uint256)
    {
        return _getTokenAmount(_exToken, _amount);
    }

     
    function buyTokens(
        address _exToken,
        uint256 _amount
    )
        external
    {
        require(_exTokens[_exToken].accepted, "token was not accepted");
        require(_amount != 0, "amount cannot 0");
        require(whitelist[msg.sender], "buyer must be in whitelist");
         
        uint256 _tokens = _getTokenAmount(_exToken, _amount);
        require(_tokens >= 10**18, "at least buy 1 tokens per purchase");
        _forwardFunds(_exToken, _amount);
        _processPurchase(msg.sender, _tokens);
        emit TokensPurchased(msg.sender, _exToken, _amount, _tokens);
    }

     
    function _forwardFunds(address _exToken, uint256 _amount) private {
        if (_exTokens[_exToken].safe) {
            IERC20(_exToken).safeTransferFrom(msg.sender, fundCollector, _amount);
        } else {
            IUnsafeERC20(_exToken).transferFrom(msg.sender, fundCollector, _amount);
        }
    }

     
    function _getTokenAmount(
        address _exToken,
        uint256 _amount
    )
        private
        view
        returns (uint256)
    {
         
        uint256 _value = _amount
            .mul(_exTokens[_exToken].rate)
            .div(1000000000000000000)
            .mul(1000000000000000000);
        return _applyBonus(_value);
    }

    function _applyBonus(
        uint256 _amount
    )
        private
        view
        returns (uint256)
    {
        if (_amount < bonusThreshold) {
            return _amount;
        }

        if (block.timestamp <= tierOneBonusTime) {
            return _amount.mul(tierOneBonusRate).div(100);
        } else if (block.timestamp <= tierTwoBonusTime) {
            return _amount.mul(tierTwoBonusRate).div(100);
        } else {
            return _amount;
        }
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        private
    {
        saleToken.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
    }
}