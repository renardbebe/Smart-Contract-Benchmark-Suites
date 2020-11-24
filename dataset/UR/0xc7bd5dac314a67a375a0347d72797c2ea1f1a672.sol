 

pragma solidity ^0.4.17;
 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract KlownGasDrop {


 
    mapping(address => bool) public receivers;
 
    mapping ( address => uint256 ) public balances;
	 
	uint256 amountToClaim = 50000000;
	uint256 public totalSent = 0;
	
	address  _owner;
	address  whoSent;
	uint256 dappBalance;

 
    uint public brpt = 0;
    uint public brpt1 = 0;

    IERC20 currentToken ;


 
	modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
  }
     
     function  KlownGasDrop() public {
		_owner = msg.sender;
		dappBalance = 0;
    }

 
	address currentTokenAddress = 0xc97a5cdf41bafd51c8dbe82270097e704d748b92;


     
      function deposit(uint tokens) public onlyOwner {


     
    balances[msg.sender]+= tokens;

     
    IERC20(currentTokenAddress).transferFrom(msg.sender, address(this), tokens);
    whoSent = msg.sender;
    
  }

function hasReceived(address received)  internal  view returns(bool)
{
    bool result = false;
    if(receivers[received] == true)
        result = true;
    
    return result;
}

uint256 temp = 0;
  
    function claimGasDrop() public returns(bool) {



		 
        if(receivers[msg.sender] != true)
	    {

    	     
    		if(amountToClaim <= balances[whoSent])
    		{
    		     
    		    balances[whoSent] -= amountToClaim;
    			 
    			IERC20(currentTokenAddress).transfer(msg.sender, amountToClaim);
    			
    			receivers[msg.sender] = true;
    			totalSent += amountToClaim;
    			
    			 
    			
    			
    		}

	    }
		

	   
    }


  
  function setCurrentToken(address currentTokenContract) external onlyOwner {
        currentTokenAddress = currentTokenContract;
        currentToken = IERC20(currentTokenContract);
        dappBalance = currentToken.balanceOf(address(this));
      
  }



  
  function setGasClaim(uint256 amount) external onlyOwner {
    
      amountToClaim = amount;
      
  }
 
  function getGasClaimAmount()  public view returns (uint256)  {
    
      return amountToClaim;
      
  }
  
  


}