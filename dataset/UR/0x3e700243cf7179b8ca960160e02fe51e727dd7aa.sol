 

 

pragma solidity ^0.5.7;

 
library SafeMath {

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
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
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

 
contract PriceReceiver {

    address public ethPriceProvider;

    modifier onlyEthPriceProvider() {
        require(msg.sender == ethPriceProvider);
        _;
    }

    function receiveEthPrice(uint256 newPrice) external;

    function setEthPriceProvider(address provider) external;

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
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 
contract Crowdsale is ReentrancyGuard, PriceReceiver, Ownable {
    using SafeMath for uint256;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
    uint256 private _weiRaised;

     
    uint256 private _currentETHPrice;

     
    uint256 private _rate;

     
    uint256 private _minimum = 0.5 ether;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event NewETHPrice(uint256 oldValue, uint256 newValue);

     
    constructor (uint256 rate, uint256 initialETHPrice, address payable wallet, IERC20 token, address initialOwner) public Ownable(initialOwner) {
        require(rate != 0, "Rate is 0");
        require(initialETHPrice != 0, "Initial ETH price is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(address(token) != address(0), "Token is the zero address");

        _rate = rate;
        _currentETHPrice = initialETHPrice;
        _wallet = wallet;
        _token = token;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than 0.5 ether");

        uint256 weiAmount = msg.value;

        uint256 tokens = getTokenAmount(weiAmount);

        _weiRaised = _weiRaised.add(weiAmount);

        _wallet.transfer(weiAmount);

        _token.transfer(beneficiary, tokens);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
    }

     
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(_currentETHPrice).div(1 ether).mul(_rate);
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0, "New rate is 0");

        _rate = newRate;
    }

     
    function setEthPriceProvider(address provider) external onlyOwner {
        require(provider != address(0), "Provider is the zero address");

        ethPriceProvider = provider;
    }

     
    function setWallet(address payable newWallet) external onlyOwner {
        require(newWallet != address(0), "New wallet is the zero address");

        _wallet = newWallet;
    }

     
    function receiveEthPrice(uint256 newPrice) external {
        require(newPrice != 0, "New price is 0");
        require(msg.sender == ethPriceProvider || msg.sender == _owner, "Sender has no permission");

        emit NewETHPrice(_currentETHPrice, newPrice);
        _currentETHPrice = newPrice;
    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function currentETHPrice() public view returns (uint256) {
        return _currentETHPrice;
    }

     
    function minimum() public view returns (uint256) {
        return _minimum;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

}