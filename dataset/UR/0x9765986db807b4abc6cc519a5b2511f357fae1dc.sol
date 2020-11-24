 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
contract APPCrowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address private _wallet1;
    address private _wallet2;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

    address private _owner;

    uint256 constant private minRate = 50000000000;

    uint256 private _minTokenSum = 0;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address wallet1, address wallet2, IERC20 token) public payable {
        require(rate > 0);
        require(wallet1 != address(0));
        require(wallet2 != address(0));
        require(token != address(0));
        require (rate >= minRate);

        _rate = rate;
        _wallet1 = wallet1;
        _wallet2 = wallet2;
        _token = token;
        _owner = msg.sender;
    }

    mapping (address => bool) private _trusted;

    function addTrustedAddress(address trusted) public {
        require(msg.sender == _owner);
        _trusted[trusted] = true;
    }

    function removeTrustedAddress(address trusted) public {
        require(msg.sender == _owner);
        _trusted[trusted] = false;
    }

    function changeRate(uint256 newRate) public {
        require (_trusted[msg.sender] == true);
        require (newRate >= minRate);
        _rate = newRate;
    }

     
    function changeMinTokenSum(uint256 minTokenSum) public {
        require (_trusted[msg.sender] == true || msg.sender == _owner);
        _minTokenSum = minTokenSum;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }


    function wallet1() public view returns (address) {
        return _wallet1;
    }

    function wallet2() public view returns (address) {
        return _wallet2;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

    function minTokenSum() public view returns (uint256) {
        return _minTokenSum;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function transferTo(address toAddress, uint256 tokenAmount) public {
        require(msg.sender == _owner);
        _token.safeTransfer(toAddress, tokenAmount);
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

         

        _forwardFunds();
         
    }

     
     
     

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
        require(weiAmount >= _rate);
        require(_getTokenAmount(weiAmount) >= _minTokenSum);

    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.div(_rate);
    }

     
    function _forwardFunds() internal {
        uint256 val1 = msg.value/2;
        uint256 val2 = msg.value - val1;
        _wallet1.transfer(val1);
        _wallet2.transfer(val2);
    }

    function updateWallet(address newWallet1, address newWallet2) public {
        require(msg.sender == _owner);
        if (newWallet1 != address(0)) {
            _wallet1 = newWallet1;
        }
        if (newWallet2 != address(0)) {
            _wallet2 = newWallet2;
        }
    }
}