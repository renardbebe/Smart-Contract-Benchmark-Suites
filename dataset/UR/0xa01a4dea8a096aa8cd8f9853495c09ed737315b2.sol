 

pragma solidity 0.4.24;


 
    contract Owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
         

        function transferOwnership(address _newOwner) onlyOwner public {
            owner = _newOwner;
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


 
interface RailzToken {
    function transfer(address _to, uint256 _value) public returns (bool);
}


 
contract RailzTokenSale is Owned {
	using SafeMath for uint256;

	mapping (address=> uint256) contributors;
	mapping (address=> uint256) public tokensAllocated;
    
	 
	uint256 public presalestartTime =1528099200 ;      
	uint256 public presaleendTime = 1530489599;        
	uint256 public publicsalestartTime = 1530518400;   
	uint256 public publicsalesendTime = 1532908799;    


	 
	uint256 public presalesCap = 120000000 * (1e18);
	uint256 public publicsalesCap = 350000000 * (1e18);

	 
	uint256 public presalesTokenPriceInWei =  80000000000000 ;  
	uint256 public publicsalesTokenPriceInWei = 196000000000000 ; 

	 
	address wallet;

	 
	uint256 public weiRaised=0;

	 
	uint256 public numberOfTokensAllocated=0;

	 
	uint256 public maxGasPrice = 60000000000  wei;  

	 
	RailzToken public token;

	bool hasPreTokenSalesCapReached = false;
	bool hasTokenSalesCapReached = false;

	 
	event ContributionReceived(address indexed contributor, uint256 value, uint256 numberOfTokens);
	event TokensTransferred(address indexed contributor, uint256 numberOfTokensTransferred);
	event ManualTokensTransferred(address indexed contributor, uint256 numberOfTokensTransferred);
	event PreTokenSalesCapReached(address indexed contributor);
	event TokenSalesCapReached(address indexed contributor);

	function RailzTokenSale(RailzToken _addressOfRewardToken, address _wallet) public {        
  		require(presalestartTime >= now); 
  		require(_wallet != address(0));   
        
  		token = RailzToken (_addressOfRewardToken);
  		wallet = _wallet;
		owner = msg.sender;
	}

	 
	modifier validGasPrice() {
		assert(tx.gasprice <= maxGasPrice);
		_;
	}

	 
	function ()  payable public validGasPrice {  
		require(msg.sender != address(0));                       
		require(msg.value != 0);                                 
        require(msg.value>=0.1 ether);                           
		require(isContributionAllowed());                        
	
		 
		contributors[msg.sender] = contributors[msg.sender].add(msg.value);
		weiRaised = weiRaised.add(msg.value);
		uint256 numberOfTokens = 0;

		 
		if (isPreTokenSaleActive()) {
			numberOfTokens = msg.value/presalesTokenPriceInWei;
            numberOfTokens = numberOfTokens * (1e18);
			require((numberOfTokens + numberOfTokensAllocated) <= presalesCap);			 

			tokensAllocated[msg.sender] = tokensAllocated[msg.sender].add(numberOfTokens);
			numberOfTokensAllocated = numberOfTokensAllocated.add(numberOfTokens);
			
			 
		    forwardFunds(); 

			 
			emit ContributionReceived(msg.sender, msg.value, numberOfTokens);

		} else if (isTokenSaleActive()) {
			numberOfTokens = msg.value/publicsalesTokenPriceInWei;
			numberOfTokens = numberOfTokens * (1e18);
			require((numberOfTokens + numberOfTokensAllocated) <= (presalesCap + publicsalesCap));	 

			tokensAllocated[msg.sender] = tokensAllocated[msg.sender].add(numberOfTokens);
			numberOfTokensAllocated = numberOfTokensAllocated.add(numberOfTokens);

             
		    forwardFunds();

			 
		    emit ContributionReceived(msg.sender, msg.value, numberOfTokens);
		}        

		 
		checkifCapHasReached();
	}

	 
	function isContributionAllowed() public view returns (bool) {    
		if (isPreTokenSaleActive())
			return  (!hasPreTokenSalesCapReached);
		else if (isTokenSaleActive())
			return (!hasTokenSalesCapReached);
		else
			return false;
	}

	 
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	 
	function isPreTokenSaleActive() internal view returns (bool) {
		return ((now >= presalestartTime) && (now <= presaleendTime));  
	}

	 
	function isTokenSaleActive() internal view returns (bool) {
		return (now >= (publicsalestartTime) && (now <= publicsalesendTime));  
	}

	 
	function preTokenSalesCapReached() internal {
		hasPreTokenSalesCapReached = true;
		emit PreTokenSalesCapReached(msg.sender);
	}

	 
	function tokenSalesCapReached() internal {
		hasTokenSalesCapReached = true;
		emit TokenSalesCapReached(msg.sender);
	}

	 
	function transferToken(address _contributor) public onlyOwner {
		require(_contributor != 0);
        uint256 numberOfTokens = tokensAllocated[_contributor];
        tokensAllocated[_contributor] = 0;    
		token.transfer(_contributor, numberOfTokens);
		emit TokensTransferred(_contributor, numberOfTokens);
	}


	 
	 function manualBatchTransferToken(uint256[] amount, address[] wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            token.transfer(wallets[i], amount[i]);
			emit TokensTransferred(wallets[i], amount[i]);
        }
    }

	 
	 function batchTransferToken(address[] wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
			uint256 amountOfTokens = tokensAllocated[wallets[i]];
			require(amountOfTokens > 0);
			tokensAllocated[wallets[i]]=0;
            token.transfer(wallets[i], amountOfTokens);
			emit TokensTransferred(wallets[i], amountOfTokens);
        }
    }
	
	 
	function refundContribution(address _contributor, uint256 _weiAmount) public onlyOwner returns (bool) {
		require(_contributor != 0);                                                                                                                                     
		if (!_contributor.send(_weiAmount)) {
			return false;
		} else {
			contributors[_contributor] = 0;
			return true;
		}
	}

	 
    function checkifCapHasReached() internal {
    	if (isPreTokenSaleActive() && (numberOfTokensAllocated > presalesCap))  
        	hasPreTokenSalesCapReached = true;
     	else if (isTokenSaleActive() && (numberOfTokensAllocated > (presalesCap + publicsalesCap)))     
        	hasTokenSalesCapReached = true;     	
    }

  	 
    function setGasPrice(uint256 _gasPrice) public onlyOwner {
    	maxGasPrice = _gasPrice;
    }
}