 

pragma solidity ^0.4.8;

 
contract SPARCPresale {    
    uint256 public maxEther     = 1000 ether;
    uint256 public etherRaised  = 0;
    
    address public SPARCAddress;
    address public beneficiary;
    
    bool    public funding      = false;
    
    address public owner;
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
 
    function SPARCPresale() {
        owner           = msg.sender;
        beneficiary     = msg.sender;
    }
    
    function withdrawEther(uint256 amount) onlyOwner {
        require(amount <= this.balance);
        
        if(!beneficiary.send(this.balance)){
            throw;
        }
    }
    
    function setSPARCAddress(address _SPARCAddress) onlyOwner {
        SPARCAddress    = _SPARCAddress;
    }
    
    function startSale() onlyOwner {
        funding = true;
    }
    
     
    
     
     
     
     
     
     
     
     
    function () payable {
        assert(funding);
        assert(etherRaised < maxEther);
        require(msg.value != 0);
        require(etherRaised + msg.value <= maxEther);
        
        etherRaised  += msg.value;
        
        if(!SPARCToken(SPARCAddress).create(msg.sender, msg.value * 20000)){
            throw;
        }
    }
}

 
contract SPARCToken {
    function create(address to, uint256 amount) returns (bool);
}