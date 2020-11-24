 

pragma solidity ^0.4.21;



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract TraxionWallet is Ownable {
    using SafeMath for uint256;


    constructor(){
        transferOwnership(0xC889dFBDc9C1D0FC3E77e46c3b82A3903b2D919c);
    }

     
    address public wallet = 0xbee44A7b93509270dbe90000f7ff31268D8F075e;
  
     
    uint256 public rate = 2857;

     
    uint256 public minInvestment = 2E17;

     
    uint256 public investmentUpperBounds = 2E21;        

     
    uint256 public hardcap = 45E21;

     
    uint256 public weiRaised;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
  
     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    mapping (address => bool) public whitelistedAddr;
    mapping (address => uint256) public totalInvestment;
  
     
    function whitelistAddress(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = true;
        }
    }
  
     
    function blacklistAddr(address[] buyer) external onlyOwner {
        for (uint i = 0; i < buyer.length; i++) {
            whitelistedAddr[buyer[i]] = false;
        }
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