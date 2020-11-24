 

pragma solidity ^0.4.24;

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

 
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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
 

contract ScarlettSale is Ownable {
    
    using SafeMath for uint256;

     
    ERC20 private _token;
    
     
    address internal _wallet;
    
    uint256 internal _tierOneRate = 1000;
    
    uint256 internal _tierTwoRate = 665; 
    
    uint256 internal _tierThreeRate = 500;
    
    uint256 internal _tierFourRate = 400; 
    
    uint256 internal _tierFiveRate = 200; 
    
     
    uint256 internal _weiRaised;
    
    uint256 internal _monthOne;
        
    uint256 internal _monthTwo;
    
    uint256 internal _monthThree;
    
    uint256 internal _monthFour;
        
    uint256 internal _tokensSold;
    
    uint256 public _startTime =  now;  
    
    uint256 public _endTime = _startTime + 20 weeks;  
    
    uint256 public _saleSupply = SafeMath.mul(100500000, 1 ether);  
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    constructor (address  wallet, ERC20 token) public {
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _wallet = wallet;
        _token = token;
        _tokensSold = 0;
        
        _monthOne = SafeMath.add(_startTime, 4 weeks);
        _monthTwo = SafeMath.add(_monthOne, 4 weeks);
        _monthThree = SafeMath.add(_monthTwo, 4 weeks);
        _monthFour = SafeMath.add(_monthThree, 4 weeks);

    }

    function () external payable {
        buyTokens(msg.sender);
    }


    function token() public view returns (ERC20) {
        return _token;
    }

    function wallet() public view returns (address ) {
        return _wallet;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public  payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 accessTime = now;
        
        require(weiAmount >= 1000000000000000, "Wei amount should be greater than 0.001 ETH");
        _preValidatePurchase(beneficiary, weiAmount);
        
        uint256 tokens = 0;
        
        tokens = _processPurchase(accessTime,weiAmount, tokens);
      
        _weiRaised = _weiRaised.add(weiAmount);
        
        _deliverTokens(beneficiary, tokens);  
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
        
        _tokensSold = _tokensSold.add(tokens);
        
        _forwardFunds();
     
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal pure {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    function _processPurchase(uint256 accessTime, uint256 weiAmount, uint256 tokenAmount)  internal returns (uint256) {
       
       if ( accessTime <= _monthOne ) { 
     
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierOneRate));
     
      } else if (( accessTime <= _monthTwo ) && (accessTime > _monthOne)) { 
     
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierTwoRate));
     
      } else if (( accessTime <= _monthThree ) && (accessTime > _monthTwo)) { 
     
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierThreeRate));
     
      } else if (( accessTime <= _monthFour ) && (accessTime > _monthThree)) { 
     
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierFourRate));
     
      } else {
          
          tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierFiveRate));
          
      }

        require(_saleSupply >= tokenAmount, "sale supply should be greater or equals to tokenAmount");
        
        _saleSupply = _saleSupply.sub(tokenAmount);        

        return tokenAmount;
        
    }
    
       
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= _startTime && now <= _endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
  }

   
    function hasEnded() public constant returns (bool) {
      return now > _endTime;
    }

     
     
     
    
    function _forwardFunds() internal {
    (bool success, ) = _wallet.call.value(msg.value)("");
    require(success, "Failed to forward funds");
}
    function withdrawTokens(uint _amount) external onlyOwner {
        require(_amount > 0, "token amount should be greater than 0");
       _token.transfer(_wallet, _amount);
   }
     
    function transferFunds(address[] recipients, uint256[] values) external onlyOwner {

        for (uint i = 0; i < recipients.length; i++) {
            uint x = values[i].mul(1 ether);
            require(_saleSupply >= values[i]);
            _saleSupply = SafeMath.sub(_saleSupply,values[i]);
            _token.transfer(recipients[i], x); 
        }
    } 


}