 

pragma solidity 0.5.12; 
  




 
 
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
 
 
    
contract owned {
    address payable public owner;
    address payable private newOwner;

     
    address payable public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer);
        _;
    }

    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 

interface tokenInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
} 

 
 
 
 

contract AzumaPrivateSale is owned {

     

     
    using SafeMath for uint256;
    address public azumaContractAddress;             
   	uint256 public icoETHReceived;                   
   	uint256 public totalTokenSold;                   
	uint256 public minimumContribution = 10**16;     
	uint256 public etherUsdPrice = 172000;           
	uint256 public etherPriceLastUpdated = now;      
	uint256 public tokenPriceUSD = 150;              


     
    constructor() public{ }    


     
    function () payable external {
        buyToken();
    }

    event buyTokenEvent (address sender,uint amount, uint tokenPaid);
    function buyToken() payable public returns(uint)
    {
        uint256 etherAmount = msg.value;
		
		 
        require(etherAmount >= minimumContribution, "less then minimum contribution"); 
        
         
         
        uint256 etherUsdValue = etherAmount * etherUsdPrice;
        
         
        uint256 tokenTotal = etherUsdValue  / tokenPriceUSD;

         
        icoETHReceived += etherAmount;
        totalTokenSold += tokenTotal;
        
         
        tokenInterface(azumaContractAddress).transfer(msg.sender, tokenTotal);
        
        
         
        forwardETHToOwner();
        
         
        emit buyTokenEvent(msg.sender, etherAmount, tokenTotal);
        
        return tokenTotal;

    }
    
     
     
     
    function updateEthUsdPrice(uint256 usdPrice) public onlySigner returns(bool){
        
        etherUsdPrice = usdPrice;          
	    etherPriceLastUpdated = now;
	    
	    return true;
    }


	 
	function forwardETHToOwner() internal {
		owner.transfer(msg.value); 
	}
	
	
	 
    function changeTokenUsdPricing(uint256 _tokenPriceUSD) onlyOwner public returns (bool)
    {
        tokenPriceUSD = _tokenPriceUSD;
        return true;
    }



    function setMinimumContribution(uint256 _minimumContribution) onlyOwner public returns (bool)
    {
        minimumContribution = _minimumContribution;
        return true;
    }
    
    
    function updateAzumaContract(address _newAzumaContract) onlyOwner public returns (bool)
    {
        azumaContractAddress = _newAzumaContract;
        return true;
    }
    
	
	function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
         
        tokenInterface(azumaContractAddress).transfer(msg.sender, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    function manualWithdrawEther() public onlyOwner returns(string memory){
        address(owner).transfer(address(this).balance);
        return "Ether withdrawn to owner wallet";
    }
    


}