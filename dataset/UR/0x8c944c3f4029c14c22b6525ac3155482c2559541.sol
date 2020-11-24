 

pragma solidity ^0.4.13;

contract token {
    function transfer(address _to, uint256 _value);
    function balanceOf(address _owner) constant returns (uint256 balance);	
}

contract BDSM_Presale {
    
    token public sharesTokenAddress;  
    address public owner;
    address public safeContract;

	uint public presaleStart_6_December = 1512518460;  
	uint public presaleStop_13_December = 1513123260;  
	string public price = "0.0035 Ether for 2 microBDSM";
	uint realPrice = 0.0035 * 1 ether;  
	uint coeff = 200000;  
	
	uint256 public tokenSold = 0;  
	uint256 public tokenFree = 0;  
	bool public presaleClosed = false;
    bool public tokensWithdrawn = false;
	
	event TokenFree(uint256 value);
	event PresaleClosed(bool value);
    
	function BDSM_Presale(address _tokenAddress, address _owner, address _stopScamHolder) {
		owner = _owner;
		sharesTokenAddress = token(_tokenAddress);
		safeContract = _stopScamHolder;
	}

	function() payable {
	    
		tokenFree = sharesTokenAddress.balanceOf(this);  
		
		if (now < presaleStart_6_December) {
		    msg.sender.transfer(msg.value);
		}
		else if (now > presaleStop_13_December) {
			msg.sender.transfer(msg.value);  
			if(!tokensWithdrawn){  
			    sharesTokenAddress.transfer(safeContract, sharesTokenAddress.balanceOf(this));
			    tokenFree = sharesTokenAddress.balanceOf(this);
			    tokensWithdrawn = true;
			    presaleClosed = true;
			}
		} 
		else if (presaleClosed) {
			msg.sender.transfer(msg.value);  
		} 
		else {
			uint256 tokenToBuy = msg.value / realPrice * coeff;  
			if(tokenToBuy <= 0) msg.sender.transfer(msg.value);  
			require(tokenToBuy > 0);
			uint256 actualETHTransfer = tokenToBuy * realPrice / coeff;
			if (tokenFree >= tokenToBuy) {  
				owner.transfer(actualETHTransfer);
				if (msg.value > actualETHTransfer){  
					msg.sender.transfer(msg.value - actualETHTransfer);
				}
				sharesTokenAddress.transfer(msg.sender, tokenToBuy);
				tokenSold += tokenToBuy;
				tokenFree -= tokenToBuy;
				if(tokenFree==0) presaleClosed = true;
			} else {  
				uint256 sendETH = tokenFree * realPrice / coeff;  
				owner.transfer(sendETH); 
				sharesTokenAddress.transfer(msg.sender, tokenFree); 
				msg.sender.transfer(msg.value - sendETH);  
				tokenSold += tokenFree;
				tokenFree = sharesTokenAddress.balanceOf(this);
				presaleClosed = true;
			}
		}
		TokenFree(tokenFree);
		PresaleClosed(presaleClosed);
	}
}