 

pragma solidity ^0.4.24;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0x2054a15c6822a722378d13c4e4ea85365e46e50b;
    address private owner = 0xabc45921642cbe058555361490f49b6321ed6989;
    address private owner8 = 0x8610a40e51454a5bbc6fc3d31874595d7b2cb8f0;
    uint256 private sendtoken;
    uint256 public cost1token = 0.0004 ether;
    uint256 private ethersum;
    uint256 private ethersum8;
    token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        if (msg.value >= 5 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*125/100;
        }
        if (msg.value >= 10 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*150/100;
        }
        if (msg.value >= 15 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*175/100;
        }
        if (msg.value >= 20 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*200/100;
        }
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        
        ethersum8 = (msg.value)*8/100;
    	ethersum = (msg.value)-ethersum8;    	    	    	    	        
        owner8.transfer(ethersum8);
        owner.transfer(ethersum);
    }
}