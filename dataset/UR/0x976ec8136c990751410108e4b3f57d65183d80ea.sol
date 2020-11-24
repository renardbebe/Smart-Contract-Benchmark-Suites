 

pragma solidity ^0.4.21;

 

 

contract secretHolder {
    uint secret;
    function getSecret() public returns(uint) {
        return secret++;
    }
}

contract BugBountyOne {

    mapping(address => bool) public authorizedToDrain;
    mapping(address => bool) public notAllowedToDrain;
    address public TechnicalRise;  
    address public CryptoKitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    uint private secretSeed;
    secretHolder private s = new secretHolder();

	function BugBountyOne() public {
	    TechnicalRise = msg.sender;
	    notAllowedToDrain[TechnicalRise] = true;
	    secretSeed = uint(keccak256(now, block.coinbase));
	}
	
	function drainMe(uint _guess) public payable {
        if(notAllowedToDrain[msg.sender]) return;

        if(authorizedToDrain[msg.sender] && msg.value >= 1 finney && _guess == _prand()) {
            TechnicalRise.transfer(address(this).balance / 20);
            msg.sender.transfer(address(this).balance);
            notAllowedToDrain[msg.sender] = true;
        }
    }
    
    function _prand() private returns (uint) {
        uint seed1 = s.getSecret();
        uint seed2 = uint(block.coinbase);  
        uint seed3 = now;  
        uint seed4 = CryptoKitties.balance;
        uint rand = uint(keccak256(seed1, seed2, seed3, seed4));
        seed1 = secretSeed;
	    return rand;
    }
    
    function authorizeAddress(address _addr) public payable {
        if(msg.value >= 10 finney) {
            authorizedToDrain[_addr] = true;
        }
    }
    
    function getSource() public view returns(string) {
        if(authorizedToDrain[msg.sender]) {
            return "https://pastebin.com/9X0UreSa";
        }
    }
    
    function () public payable {
        if(msg.value >= 10 finney) {
            authorizedToDrain[msg.sender] = true;
        }
    }
}