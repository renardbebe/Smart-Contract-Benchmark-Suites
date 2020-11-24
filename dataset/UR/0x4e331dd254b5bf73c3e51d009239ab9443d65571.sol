 

pragma solidity ^0.4.0;

 
 
 

contract GameEthAffiliateContract{

address gameContract;
address affiliateAddress; 
uint256 affiliatePercent;
uint256 minWeiDeposit = 40000000000000000;  

	constructor(address _gameContract, address _affiliateAddress, uint256 _affiliatePercent) public {
		gameContract = _gameContract;
		require (_affiliatePercent>=0 && _affiliatePercent <=3);  
		affiliateAddress = _affiliateAddress;
		affiliatePercent = _affiliatePercent;
		
	}
	
	function () public payable{
		uint256 affiliateCom = msg.value/100*affiliatePercent;  
		uint256 amount = msg.value - affiliateCom;  
		require(amount >= minWeiDeposit);
		if (!gameContract.call.value(amount)(bytes4(keccak256("depositForRecipent(address)")), msg.sender)){
			revert();
		}
		affiliateAddress.transfer(affiliateCom);  
	}
	
	 
	 
	function changeAffiliate(address _affiliateAddress, uint256 _affiliatePercent) public {
		require (msg.sender == affiliateAddress);  
		require (_affiliatePercent>=0 && _affiliatePercent <=3);  
		affiliateAddress =  _affiliateAddress;
		affiliatePercent = _affiliatePercent;
		
	}

}