 

pragma solidity ^0.4.18;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner,newOwner);
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

interface token {
    function balanceOf(address who) external constant returns (uint256);
	  function transfer(address to, uint256 value) external returns (bool);
	  function getTotalSupply() external view returns (uint256);
}

contract ApolloSeptemBaseCrowdsale {
    using SafeMath for uint256;

     
    token public tokenReward;
	
     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;
	
     
    address public tokenAddress;

     
    uint256 public weiRaised;
    
     
    uint public constant  ICO_PERIOD = 180 days;

     
    event ApolloSeptemTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ApolloSeptemTokenSpecialPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function ApolloSeptemBaseCrowdsale(address _wallet, address _tokens) public{		
        require(_wallet != address(0));
        tokenAddress = _tokens;
        tokenReward = token(tokenAddress);
        wallet = _wallet;

    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

         
        tokenReward.transfer(beneficiary, tokens);

        ApolloSeptemTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function specialTransfer(address _to, uint _amount) internal returns(bool){
        require(_to != address(0));
        require(_amount > 0);
      
         
        uint256 tokens = _amount * (10 ** 18);
      
        tokenReward.transfer(_to, tokens);		
        ApolloSeptemTokenSpecialPurchase(msg.sender, _to, tokens);
      
        return true;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
		
        return withinPeriod && nonZeroPurchase && isWithinICOTimeLimit();
    }
    
    function isWithinICOTimeLimit() internal view returns (bool) {
        return now <= endTime;
    }
	
    function isWithinICOLimit(uint256 _tokens) internal view returns (bool) {			
        return tokenReward.balanceOf(this).sub(_tokens) >= 0;
    }

    function isWithinTokenAllocLimit(uint256 _tokens) internal view returns (bool) {
        return (isWithinICOTimeLimit() && isWithinICOLimit(_tokens));
    }
	
    function sendAllToOwner(address beneficiary) internal returns(bool){
        tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
        return true;
    }

    function computeTokens(uint256 weiAmount) internal pure returns (uint256) {
		     
        return weiAmount.mul(4200);
    }
}

 
contract ApolloSeptemCappedCrowdsale is ApolloSeptemBaseCrowdsale{
    using SafeMath for uint256;

     
    uint256 public constant HARD_CAP = (3 ether)*(10**4);

    function ApolloSeptemCappedCrowdsale() public {}

     
     
    function validPurchase() internal view returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= HARD_CAP;

        return super.validPurchase() && withinCap;
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= HARD_CAP;
        return super.hasEnded() || capReached;
    }
}

 
contract ApolloSeptemCrowdsaleExtended is ApolloSeptemCappedCrowdsale, Ownable {

    bool public isFinalized = false;
    bool public isStarted = false;

    event ApolloSeptemStarted();
    event ApolloSeptemFinalized();

    function ApolloSeptemCrowdsaleExtended(address _wallet,address _tokensAddress) public
        ApolloSeptemCappedCrowdsale()
        ApolloSeptemBaseCrowdsale(_wallet,_tokensAddress) 
    {}
	
  	 
    function start(uint256 _weiRaised) onlyOwner public {
        require(!isStarted);

        starting(_weiRaised);
        ApolloSeptemStarted();

        isStarted = true;
    }

    function starting(uint256 _weiRaised) internal {
        startTime = now;
        weiRaised = _weiRaised;
        endTime = startTime + ICO_PERIOD;
    }
	
     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        ApolloSeptemFinalized();

        isFinalized = true;
    }	
	
     
    function apolloSpecialTransfer(address _beneficiary, uint _amount) onlyOwner public {		 
        specialTransfer(_beneficiary, _amount);
    }
	
     
    function sendRemaningBalanceToOwner(address _tokenOwner) onlyOwner public {
        require(_tokenOwner != address(0));
        
        sendAllToOwner(_tokenOwner);	
    }
}