 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract WestrendWallet is Ownable {
    using SafeMath for uint256;

     
    address public wallet = 0xe3de74151CbDFB47d214F7E6Bcb8F5EfDCf99636;
  
     
    uint256 public rate = 1100;

     
    uint256 public minInvestment = 2E17;

     
    uint256 public investmentUpperBounds = 2E21;

     
    uint256 public hardcap = 1E23;

     
    uint256 public weiRaised;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event Whitelist(address whiteaddress);
    event Blacklist(address blackaddress);
    event ChangeRate(uint256 newRate);
    event ChangeMin(uint256 newMin);
    event ChangeMax(uint256 newMax);
     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    mapping (address => bool) public whitelistedAddr;
    mapping (address => uint256) public totalInvestment;
  
     
    function whitelistAddress(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = true;
            address whitelistedbuyer = buyer[i];
        }
        emit Whitelist(whitelistedbuyer);
    }
  
     
    function blacklistAddr(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = false;
            address blacklistedbuyer = buyer[i];
        }
        emit Blacklist(blacklistedbuyer);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        emit TokenPurchase(msg.sender, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        rate = newRate;
        emit ChangeRate(rate);
    }

     
    function changeMin(uint256 newMin) external onlyOwner {
        minInvestment = newMin;
        emit ChangeMin(minInvestment);
    }

     
    function changeMax(uint256 newMax) external onlyOwner {
        investmentUpperBounds = newMax;
        emit ChangeMax(investmentUpperBounds);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(_beneficiary != address(0)); 
        require(_weiAmount != 0);
    
        require(_weiAmount > minInvestment);  
        require(whitelistedAddr[_beneficiary]);  
        require(totalInvestment[_beneficiary].add(_weiAmount) <= investmentUpperBounds);  
         
        require(weiRaised.add(_weiAmount) <= hardcap);  
    }


     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        totalInvestment[_beneficiary] = totalInvestment[_beneficiary].add(_weiAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}