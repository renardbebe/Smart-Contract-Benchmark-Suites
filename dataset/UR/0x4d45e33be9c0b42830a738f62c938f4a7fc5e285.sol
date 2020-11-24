 

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
        bool accepted;
        uint256 rate;
    }

     
    mapping(address => ExToken) private _exTokens;

     
    uint256 public bonusThreshold;

     
    uint256 public tierOneBonusTime;
    uint256 public tierOneBonusRate;

     
    uint256 public tierTwoBonusTime;
    uint256 public tierTwoBonusRate;

     
    event FundCollectorSet(
        address indexed setter,
        address indexed fundCollector
    );

     
    event SaleTokenSet(
        address indexed setter,
        address indexed saleToken
    );

     
    event TokenWalletSet(
        address indexed setter,
        address indexed tokenWallet
    );

     
    event BonusConditionsSet(
        address indexed setter,
        uint256 bonusThreshold,
        uint256 tierOneBonusTime,
        uint256 tierOneBonusRate,
        uint256 tierTwoBonusTime,
        uint256 tierTwoBonusRate
    );

     
    event WhitelistSet(
        address indexed setter,
        address indexed user,
        bool allowed
    );

     
    event ExTokenSet(
        address indexed setter,
        address indexed exToken,
        bool accepted,
        uint256 rate
    );

     
    event TokensPurchased(
        address indexed buyer,
        address indexed exToken,
        uint256 exTokenAmount,
        uint256 amount
    );

     
    constructor (
        address fundCollector,
        address saleToken,
        address tokenWallet,
        uint256 bonusThreshold,
        uint256 tierOneBonusTime,
        uint256 tierOneBonusRate,
        uint256 tierTwoBonusTime,
        uint256 tierTwoBonusRate
    )
        public
    {
        _setFundCollector(fundCollector);
        _setSaleToken(saleToken);
        _setTokenWallet(tokenWallet);
        _setBonusConditions(
            bonusThreshold,
            tierOneBonusTime,
            tierOneBonusRate,
            tierTwoBonusTime,
            tierTwoBonusRate
        );

    }

     
    function setFundCollector(address fundCollector) external onlyOwner {
        _setFundCollector(fundCollector);
    }

     
    function _setFundCollector(address collector) private {
        require(collector != address(0), "fund collector cannot be 0x0");
        fundCollector = collector;
        emit FundCollectorSet(msg.sender, collector);
    }

     
    function setSaleToken(address saleToken) external onlyOwner {
        _setSaleToken(saleToken);
    }

     
    function _setSaleToken(address token) private {
        require(token != address(0), "sale token cannot be 0x0");
        saleToken = IERC20(token);
        emit SaleTokenSet(msg.sender, token);
    }

     
    function setTokenWallet(address tokenWallet) external onlyOwner {
        _setTokenWallet(tokenWallet);
    }

     
    function _setTokenWallet(address wallet) private {
        require(wallet != address(0), "token wallet cannot be 0x0");
        tokenWallet = wallet;
        emit TokenWalletSet(msg.sender, wallet);
    }

     
    function setBonusConditions(
        uint256 threshold,
        uint256 t1BonusTime,
        uint256 t1BonusRate,
        uint256 t2BonusTime,
        uint256 t2BonusRate
    )
        external
        onlyOwner
    {
        _setBonusConditions(
            threshold,
            t1BonusTime,
            t1BonusRate,
            t2BonusTime,
            t2BonusRate
        );
    }

     
    function _setBonusConditions(
        uint256 threshold,
        uint256 t1BonusTime,
        uint256 t1BonusRate,
        uint256 t2BonusTime,
        uint256 t2BonusRate
    )
        private
        onlyOwner
    {
        require(threshold > 0," threshold cannot be zero.");
        require(t1BonusTime < t2BonusTime, "invalid bonus time");
        require(t1BonusRate >= t2BonusRate, "invalid bonus rate");

        bonusThreshold = threshold;
        tierOneBonusTime = t1BonusTime;
        tierOneBonusRate = t1BonusRate;
        tierTwoBonusTime = t2BonusTime;
        tierTwoBonusRate = t2BonusRate;

        emit BonusConditionsSet(
            msg.sender,
            threshold,
            t1BonusTime,
            t1BonusRate,
            t2BonusTime,
            t2BonusRate
        );
    }

     
    function setWhitelist(address user, bool allowed) external onlyOwner {
        whitelist[user] = allowed;
        emit WhitelistSet(msg.sender, user, allowed);
    }

     
    function remainingTokens() external view returns (uint256) {
        return Math.min(
            saleToken.balanceOf(tokenWallet),
            saleToken.allowance(tokenWallet, address(this))
        );
    }

     
    function setExToken(
        address exToken,
        bool accepted,
        uint256 rate
    )
        external
        onlyOwner
    {
        _exTokens[exToken].accepted = accepted;
        _exTokens[exToken].rate = rate;
        emit ExTokenSet(msg.sender, exToken, accepted, rate);
    }

     
    function accepted(address exToken) public view returns (bool) {
        return _exTokens[exToken].accepted;
    }

     
    function rate(address exToken) external view returns (uint256) {
        return _exTokens[exToken].rate;
    }

     
    function exchangeableAmounts(
        address exToken,
        uint256 amount
    )
        external
        view
        returns (uint256)
    {
        return _getTokenAmount(exToken, amount);
    }

     
    function buyTokens(
        address exToken,
        uint256 amount
    )
        external
    {
        require(_exTokens[exToken].accepted, "token was not accepted");
        require(amount != 0, "amount cannot 0");
        require(whitelist[msg.sender], "buyer must be in whitelist");
         
        uint256 tokens = _getTokenAmount(exToken, amount);
        require(tokens >= 10**19, "at least buy 10 tokens per purchase");
        _forwardFunds(exToken, amount);
        _processPurchase(msg.sender, tokens);
        emit TokensPurchased(msg.sender, exToken, amount, tokens);
    }

     
    function _forwardFunds(address exToken, uint256 amount) private {
        IERC20(exToken).safeTransferFrom(msg.sender, fundCollector, amount);
    }

     
    function _getTokenAmount(
        address exToken,
        uint256 amount
    )
        private
        view
        returns (uint256)
    {
         
        uint256 value = amount
            .mul(_exTokens[exToken].rate)
            .div(1000000000000000000)
            .mul(1000000000000000000);
        return _applyBonus(value);
    }

    function _applyBonus(
        uint256 amount
    )
        private
        view
        returns (uint256)
    {
        if (amount < bonusThreshold) {
            return amount;
        }

        if (block.timestamp <= tierOneBonusTime) {
            return amount.mul(tierOneBonusRate).div(100);
        } else if (block.timestamp <= tierTwoBonusTime) {
            return amount.mul(tierTwoBonusRate).div(100);
        } else {
            return amount;
        }
    }

     
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount
    )
        private
    {
        saleToken.safeTransferFrom(tokenWallet, beneficiary, tokenAmount);
    }
}