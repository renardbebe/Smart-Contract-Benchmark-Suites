 

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
 

contract BitherxSales is Ownable {
    
    using SafeMath for uint256;

     
    ERC20 private _token;
    
     
    address private _wallet;
    
    uint256 private _rate = 17000;  
    
     
    uint256 private _weiRaised;
    
    uint256 public _tierOneBonus;
    
    uint256 public _tierTwoBonus;
    
    uint256 public _tierThreeBonus;
    
    uint256 public _weekOne;
        
    uint256 public _weekTwo;
    
    uint256 public _weekThree;
    
    uint256 private _tokensSold;
    
    uint256 public _startTime = 1568140200;  
    
    uint256 public _endTime = _startTime + 90 minutes;  
    
    uint256 public _claimTime = _endTime + 10 minutes;
    
    uint256 public _saleSupply = SafeMath.mul(390000000, 1 ether);  
    uint256 public bountySupply = SafeMath.mul(32500000, 1 ether);  
    uint256 public advisorSupply = SafeMath.mul(39000000, 1 ether);  
    uint256 public legalSupply = SafeMath.mul(13000000, 1 ether);  
    uint256 public teamSupply = SafeMath.mul(45500000, 1 ether);  
    uint256 public developmentSupply = SafeMath.mul(130000000, 1 ether);  
  

     
    uint256 internal legalTimeLock;
    uint256 internal advisorTimeLock;
    uint256 internal developmentTimeLock;
    uint256 internal teamTimeLock;

     
    uint internal legalCounter = 0;  
    uint internal teamCounter = 0;
    uint internal advisorCounter = 0;
    uint internal developmentCounter = 0;
    
    struct TokenHolders {
        address to;
        uint256 amount;
        bool status;
    }
    
    mapping(address => TokenHolders) public holders;
    
    modifier onlyHolder(address _caller) {
        require(_caller == holders[_caller].to);
        _;
    }
    
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    constructor (address  wallet, ERC20 token) public {
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _wallet = wallet;
        _token = token;
        _tokensSold = 0;
        
        _weekOne = SafeMath.add(_startTime, 20 minutes);
        _weekTwo = SafeMath.add(_weekOne, 20 minutes);
        _weekThree = SafeMath.add(_weekTwo, 20 minutes);
       
       _tierOneBonus =  SafeMath.div(SafeMath.mul(_rate,30),100);
       _tierTwoBonus =  SafeMath.div(SafeMath.mul(_rate,25),100);
       _tierThreeBonus =  SafeMath.div(SafeMath.mul(_rate,20),100);
       
         
        legalTimeLock = SafeMath.add(_endTime, 5 minutes);
        advisorTimeLock = SafeMath.add(_endTime, 5 minutes);
        developmentTimeLock = SafeMath.add(_endTime, 5 minutes);
        teamTimeLock = SafeMath.add(_endTime, 5 minutes);
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

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public  payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 accessTime = now;
        
        require(weiAmount >= 10000000000000000, "Wei amount should be greater than 0.01 ETH");
        _preValidatePurchase(beneficiary, weiAmount);
        
        uint256 tokens = 0;
        
        tokens = _processPurchase(accessTime,weiAmount, tokens);
      
        _weiRaised = _weiRaised.add(weiAmount);
        
        _holdTokens(beneficiary, tokens);

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

    function _holdTokens(address beneficiary, uint256 tokenAmount) internal {
         require(holders[beneficiary].status == false);
         if (holders[beneficiary].to == beneficiary) {
             holders[beneficiary].amount = holders[beneficiary].amount + tokenAmount;
         }
         else {
             holders[beneficiary].to = beneficiary;
             holders[beneficiary].amount = tokenAmount;
             holders[beneficiary].status = false;

         }
    }
    
    function _claimTokens() public onlyHolder(msg.sender) {
        require(holders[msg.sender].status == false);
        require(now >= _claimTime);
        
        _deliverTokens(msg.sender, holders[msg.sender].amount);
    
        holders[msg.sender].status = true;
    }
    

    function _processPurchase(uint256 accessTime, uint256 weiAmount, uint256 tokenAmount)  internal returns (uint256) {
       
       if ( accessTime <= _weekOne ) { 
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierOneBonus));
      } else if (( accessTime <= _weekTwo ) && (accessTime > _weekOne)) { 
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierTwoBonus));
      } 
      else if (( accessTime <= _weekThree ) && (accessTime > _weekTwo)) { 
        tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_tierThreeBonus));
      } 
        tokenAmount = tokenAmount = SafeMath.add(tokenAmount, weiAmount.mul(_rate));
        
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
        _wallet.transfer(msg.value);
    }
    function withdrawTokens(uint _amount) external onlyOwner {
       _token.transfer(_wallet, _amount);
   }
     
    function grantAdvisorToken(address beneficiary ) external onlyOwner {
        require((advisorCounter < 4) && (advisorTimeLock < now));
       
        advisorTimeLock = SafeMath.add(advisorTimeLock, 24 weeks);
        _token.transfer(beneficiary,SafeMath.div(advisorSupply, 4));
        advisorCounter = SafeMath.add(advisorCounter, 1);    
    }

    function grantLegalToken(address founderAddress) external onlyOwner {
        require((legalCounter < 4) && (legalTimeLock < now));
       
        legalTimeLock = SafeMath.add(legalTimeLock, 24 weeks);
        _token.transfer(founderAddress,SafeMath.div(legalSupply, 4));
        legalCounter = SafeMath.add(legalCounter, 1);        
    }
    
    function grantBounty(address[] recipients, uint256[] values) external onlyOwner {

        for (uint i = 0; i < recipients.length; i++) {
            uint x = values[i].mul(1 ether);
            require(bountySupply >= values[i]);
            bountySupply = SafeMath.sub(bountySupply,values[i]);
            _token.transfer(recipients[i], x); 
        }
    } 

    function grantTeamToken(address teamAddress) external onlyOwner {
        require((teamCounter < 4) && (teamTimeLock < now));
       
        teamTimeLock = SafeMath.add(teamTimeLock, 24 weeks);
        _token.transfer(teamAddress,SafeMath.div(teamSupply, 4));
        teamCounter = SafeMath.add(teamCounter, 1);        
    }

    function grantDevelopmentToken(address developmentAddress) external onlyOwner {
        require((developmentCounter < 4) && (developmentTimeLock < now));
       
        developmentTimeLock = SafeMath.add(developmentTimeLock, 24 weeks);
        _token.transfer(developmentAddress,SafeMath.div(developmentSupply, 4));
        developmentCounter = SafeMath.add(developmentCounter, 1);        
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