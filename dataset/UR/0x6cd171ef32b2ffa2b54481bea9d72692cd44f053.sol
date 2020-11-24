 

pragma solidity ^0.4.13;

contract token { 
    function transfer(address _to, uint256 _value);
	function balanceOf(address _owner) constant returns (uint256 balance);	
}

contract Crowdsale {

	token public sharesTokenAddress;  

	uint public startICO = now;  
	uint public periodICO;  
	uint public stopICO;  
	uint public price = 0.0035 * 1 ether;  
	uint coeff = 200000;  
	
	uint256 public tokenSold = 0;  
	uint256 public tokenFree = 0;  
	bool public crowdsaleClosed = false;

	address public owner;
	
	event TokenFree(uint256 value);
	event CrowdsaleClosed(bool value);
    
	function Crowdsale(address _tokenAddress, address _owner, uint _timePeriod) {
		owner = _owner;
		sharesTokenAddress = token(_tokenAddress);
		periodICO = _timePeriod * 1 hours;
		stopICO = startICO + periodICO;
	}

	function() payable {
		tokenFree = sharesTokenAddress.balanceOf(this);  
		if (now < startICO) {
		    msg.sender.transfer(msg.value);
		}
		else if (now > (stopICO + 1)) {
			msg.sender.transfer(msg.value);  
			crowdsaleClosed = true;
		} 
		else if (crowdsaleClosed) {
			msg.sender.transfer(msg.value);  
		} 
		else {
			uint256 tokenToBuy = msg.value / price * coeff;  
			require(tokenToBuy > 0);
			uint256 actualETHTransfer = tokenToBuy * price / coeff;
			if (tokenFree >= tokenToBuy) {  
				owner.transfer(actualETHTransfer);
				if (msg.value > actualETHTransfer){  
					msg.sender.transfer(msg.value - actualETHTransfer);
				}
				sharesTokenAddress.transfer(msg.sender, tokenToBuy);
				tokenSold += tokenToBuy;
				tokenFree -= tokenToBuy;
				if(tokenFree==0) crowdsaleClosed = true;
			} else {  
				uint256 sendETH = tokenFree * price / coeff;  
				owner.transfer(sendETH); 
				sharesTokenAddress.transfer(msg.sender, tokenFree); 
				msg.sender.transfer(msg.value - sendETH);  
				tokenSold += tokenFree;
				tokenFree = 0;
				crowdsaleClosed = true;
			}
		}
		TokenFree(tokenFree);
		CrowdsaleClosed(crowdsaleClosed);
	}
	
	function unsoldTokensBack(){  
	    require(crowdsaleClosed);
		require(msg.sender == owner);
	    sharesTokenAddress.transfer(owner, sharesTokenAddress.balanceOf(this));
		tokenFree = 0;
	}	
}