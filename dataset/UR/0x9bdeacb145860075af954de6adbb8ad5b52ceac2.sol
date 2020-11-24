 

pragma solidity ^0.4.19;

 
contract HODL {

     
    uint256 public RELEASE_TIME = 1 years;

     
    mapping(address => Deposit) deposits;
    
    struct Deposit {
        uint256 value;
        uint256 releaseTime;
    }
    
     
    function () public payable {
        require(msg.value > 0);
        
        if (deposits[msg.sender].releaseTime == 0) {
            uint256 releaseTime = now + RELEASE_TIME;
            deposits[msg.sender] = Deposit(msg.value, releaseTime);
        } else {
            deposits[msg.sender].value += msg.value;
            deposits[msg.sender].releaseTime += RELEASE_TIME;
        }
    }
    
     
    function withdraw() public {
        require(deposits[msg.sender].value > 0);
        require(deposits[msg.sender].releaseTime < now);
        
        msg.sender.transfer(deposits[msg.sender].value);
        
        deposits[msg.sender].value = 0;
        deposits[msg.sender].releaseTime = 0;
    }
    
     
    function getDeposit(address holder) public view returns
        (uint256 value, uint256 releaseTime)
    {
        return(deposits[holder].value, deposits[holder].releaseTime);
    }
}