 

pragma solidity ^0.5.1;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract Crowdsale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
     
    IERC20 private _token;
     
    uint256 public _startStage1;
    uint256 public _startStage2;
     
    address payable private _wallet;
    uint256 public _maxPay;
    uint256 public _minPay;

     
     
     
     
     
    uint256 private _rate;  

     
    uint256 private _weiRaised;     
     
    mapping (address => uint32) public whitelist;
     
    uint256   _totalNumberPayments = 0;
    uint256   _numberPaidPayments = 0;
    mapping(uint256 => address)  _paymentAddress;
    mapping(uint256 => uint256)  _paymentDay;
    mapping(uint256 => uint256)   _paymentValue;
    mapping(uint256 => uint256)   _totalAmountDay;
    mapping(uint256 => uint8)   _paymentFlag;
    uint256 public  _amountTokensPerDay;
     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor () public {
        _startStage1 = 1553083200;
        _startStage2 = 1554379201;
        _rate = 285;
        _wallet = 0x68A924EA85c96e74A05cf12465cB53702a560811;
        _token = IERC20(0xC0D766017141dd4866738C1e704Be6feDc97B904);
        _amountTokensPerDay = 2000000000000000000000000;
        _maxPay = 1 * 100 ether;
        _minPay = 1 * 200000000000000000;

        require(_rate > 0);
        require(_wallet != address(0));
        require(address(_token) != address(0));
        require(_startStage2 > _startStage1 + 15 * 1 days);
    }
     
    function setWhiteList(address _address, uint32 _flag) public onlyOwner  {
      whitelist[_address] = _flag;
    }
     
    function addAddressToWhiteList(address[] memory _addr) public onlyOwner {
      for(uint256 i = 0; i < _addr.length; i++) {
       whitelist[_addr[i]] = 1;
      }
    }
     
    function subAddressToWhiteList(address[] memory _addr) public onlyOwner {
      for(uint256 i = 0; i < _addr.length; i++) {
        whitelist[_addr[i]] = 0;
      }
    } 
    
    function setRate(uint256 rate) public onlyOwner  {
        _rate = rate;
    } 
    function setMaxPay(uint256 maxPay) public onlyOwner  {
        _maxPay = maxPay;
    }     
    function setMinPay(uint256 minPay) public onlyOwner  {
        _minPay = minPay;
    }      
    function _returnTokens(address wallet, uint256 value) public onlyOwner {
        _token.transfer(wallet, value);
    }  
     
    function () external payable {
        buyTokens(msg.sender);
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

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount;
        uint256 tokens;
        
        weiAmount = msg.value;
        
        _preValidatePurchase(beneficiary, weiAmount);   
      
        if (now >= _startStage1 && now < _startStage2){
          require(whitelist[msg.sender] == 1);
           
          tokens = _getTokenAmount(weiAmount);

           
          _weiRaised = _weiRaised.add(weiAmount);

          _processPurchase(beneficiary, tokens);
          emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

          _forwardFunds();
        }
        if (now >= _startStage2 && now < _startStage2 + 272 * 1 days){
          _totalNumberPayments = _totalNumberPayments + 1; 
          _paymentAddress[_totalNumberPayments] = msg.sender;
          _paymentValue[_totalNumberPayments] = msg.value;
          _paymentDay[_totalNumberPayments] = _getDayNumber();
          _totalAmountDay[_getDayNumber()] = _totalAmountDay[_getDayNumber()] + msg.value;
          _forwardFunds();
        }
        
    }
    function makePayment(uint256 numberPayments) public onlyOwner{
        address addressParticipant;
        uint256 paymentValue;
        uint256 dayNumber; 
        uint256 totalPaymentValue;
        uint256 tokensAmount;
        if (numberPayments > _totalNumberPayments.sub(_numberPaidPayments)){
          numberPayments = _totalNumberPayments.sub(_numberPaidPayments);  
        }
        uint256 startNumber = _numberPaidPayments.add(1);
        uint256 endNumber = _numberPaidPayments.add(numberPayments);
        for (uint256 i = startNumber; i <= endNumber; ++i) {
          if (_paymentFlag[i] != 1){
            dayNumber = _paymentDay[i];
            if (_getDayNumber() > dayNumber){   
              addressParticipant = _paymentAddress[i];
              paymentValue = _paymentValue[i];
              totalPaymentValue = _totalAmountDay[dayNumber];
              tokensAmount = _amountTokensPerDay.mul(paymentValue).div(totalPaymentValue);
              _token.safeTransfer(addressParticipant, tokensAmount);
              _paymentFlag[i] = 1;
              _numberPaidPayments = _numberPaidPayments + 1;
            }
          }
        }    
    }
      
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
        require(weiAmount >= _minPay); 
        require(weiAmount <= _maxPay);
        require(now >= _startStage1 && now <= _startStage2 + 272 * 1 days);
        
    }
    function _getAmountUnpaidPayments() public view returns (uint256){
        return _totalNumberPayments.sub(_numberPaidPayments);
    }    
    function _getDayNumber() internal view returns (uint256){
        return ((now.add(1 days)).sub(_startStage2)).div(1 days);
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
         
        
           uint256 bonus;
    if (now >= _startStage1 && now < _startStage1 + 5 * 1 days){
      bonus = 20;    
    }
    if (now >= _startStage1 + 5 * 1 days && now < _startStage1 + 10 * 1 days){
      bonus = 10;    
    }   
    if (now >= _startStage1 + 10 * 1 days && now < _startStage1 + 15 * 1 days){
      bonus = 0;    
    }       
      return weiAmount.mul(1000000).div(_rate) + (weiAmount.mul(1000000).mul(bonus).div(_rate)).div(100);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}