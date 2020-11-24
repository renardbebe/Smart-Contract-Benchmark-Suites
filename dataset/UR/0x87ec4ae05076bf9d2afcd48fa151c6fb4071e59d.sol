 

pragma solidity ^0.4.25;


contract ErcInterface {
    function transferFrom(address _from, address _to, uint256 _value) public;
    function transfer(address _to, uint256 _value) public;
    function balanceOf(address _who) public returns(uint256);
}

contract Ownable {
    
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}




contract FOXTWidget is Ownable {
    
    using SafeMath for uint256;
    
    ErcInterface public constant FOXT = ErcInterface(0xFbe878CED08132bd8396988671b450793C44bC12); 
    
    bool public contractFrozen;
    
    uint256 private rate;
    uint256 private purchaseTimeLimit;
    uint256 private txFee;

    mapping (address => uint256) private purchaseDeadlines;
    mapping (address => uint256) private maxPurchase;
    mapping (address => bool) private isBotAddress;
    
    
    address[] private botsOwedTxFees;
    uint256 private indexOfOwedTxFees;
    
    event TokensPurchased(address indexed by, address indexed recipient, uint256 total, uint256 value);
    event RateUpdated(uint256 latestRate);
    
    constructor() public {
        purchaseTimeLimit = 10 minutes;
        txFee = 300e14;  
        contractFrozen = false;
        indexOfOwedTxFees = 0;
    }
    
    
     
    function toggleFreeze() public onlyOwner {
        contractFrozen = !contractFrozen;
    }
    
    
     
    function addBotAddress(address _botAddress) public onlyOwner {
        require(!isBotAddress[_botAddress]);
        isBotAddress[_botAddress] = true;
    }
    
    
     
    function removeBotAddress(address _botAddress) public onlyOwner  {
        require(isBotAddress[_botAddress]);
        isBotAddress[_botAddress] = false;
    }
    
    
     
    function changeTimeLimitMinutes(uint256 _newPurchaseTimeLimit) public onlyOwner returns(bool) {
        require(_newPurchaseTimeLimit > 0 && _newPurchaseTimeLimit != purchaseTimeLimit);
        purchaseTimeLimit = _newPurchaseTimeLimit;
        return true;
    }
    
    
     
    function changeTxFee(uint256 _newTxFee) public onlyOwner returns(bool) {
        require(_newTxFee != txFee);
        txFee = _newTxFee;
        return true;
    }
    
    
     
    modifier restricted {
        require(isBotAddress[msg.sender] || msg.sender == owner);
        _;
    }
    
    
     
    function updateContract(uint256 _rate, address _purchaser, uint256 _ethInvestment) public restricted returns(bool){
        require(!contractFrozen);
        require(_purchaser != address(0x0));
        require(_ethInvestment > 0);
        require(_rate != 0);
        if(_rate != rate) {
            rate = _rate;
        }
        maxPurchase[_purchaser] = _ethInvestment;
        purchaseDeadlines[_purchaser] = now.add(purchaseTimeLimit);
        botsOwedTxFees.push(msg.sender);
        emit RateUpdated(rate);
        return true;
    }
    
    
     
    function getTimePurchase() public view returns(uint256) {
        return purchaseTimeLimit;
    }
    
         
    function getRate() public view returns(uint256) {
        return rate;
    }
    
    
    
     
    function addrCanPurchase(address _purchaser) public view returns(bool) {
        return now < purchaseDeadlines[_purchaser] && maxPurchase[_purchaser] > 0;
    }
    

     
    function buyTokens(address _purchaser) public payable returns(bool){
        require(!contractFrozen);
        require(addrCanPurchase(_purchaser));
        require(msg.value > txFee);
        uint256 msgVal = msg.value;
        if(msgVal > maxPurchase[_purchaser]) {
            msg.sender.transfer(msg.value.sub(maxPurchase[_purchaser]));
            msgVal = maxPurchase[_purchaser];
        }
        maxPurchase[_purchaser] = 0;
        msgVal = msgVal.sub(txFee);
        botsOwedTxFees[indexOfOwedTxFees].transfer(txFee);
        indexOfOwedTxFees = indexOfOwedTxFees.add(1);
        uint256 toSend = msgVal.mul(rate);
        FOXT.transfer(_purchaser, toSend);
        emit TokensPurchased(msg.sender, _purchaser, toSend, msg.value);
    }
    
    
     
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
     
    function withdrawETH() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    
     
    function withdrawFoxt(address _recipient, uint256 _totalTokens) public onlyOwner {
        FOXT.transfer(_recipient, _totalTokens);
    }
    
    
     
    function withdrawAnyERC20(address _tokenAddr, address _recipient, uint256 _totalTokens) public onlyOwner {
        ErcInterface token = ErcInterface(_tokenAddr);
        token.transfer(_recipient, _totalTokens);
    }
    
}