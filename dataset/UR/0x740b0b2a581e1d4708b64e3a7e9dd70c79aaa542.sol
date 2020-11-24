 

pragma solidity ^0.4.17;

 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract Owned {
    
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = 0x0567cB7c5A688401Aab87093058754E096C4d37E;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}


 
 
 
contract BlupassToken {
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
}


 
 
 
contract BlupassICO is Owned {

    using SafeMath for uint256;
    
     
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public RATE;  
    BlupassToken public BLU;  
    bool public isStopped = false;  
    
    mapping(address => bool) whitelist;  

     
    event LogWhiteListed(address _addr);
    event LogBlackListed(address _addr);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);
    
     
    modifier onlyWhenRunning {
        require(!isStopped);
        _;
    }
    
     
    modifier onlyifWhiteListed {
        require(whitelist[msg.sender]);
        _;
    }
    
     
     
     
     
    function BlupassICO (BlupassToken _addressOfToken) public {
        require(_addressOfToken != address(0));  
        RATE = 4000;
        BLU = BlupassToken(_addressOfToken);
        emit LogFunderInitialized(owner);
    }
    
    
     
     
     
     
     
     
     
     
    function() public payable {
        contribute();
    }


     
     
     
     
     
     
    function contribute() onlyWhenRunning onlyifWhiteListed public payable {
        
        require(msg.value >= 1 ether);  
        
        uint256 tokenBought;  
        uint256 bonus;  

        totalRaised = totalRaised.add(msg.value);  
        tokenBought = msg.value.mul(RATE);  
        
         
        
         
        if (msg.value >= 5 ether && msg.value <= 9 ether) {
            bonus = (tokenBought.mul(20)).div(100);  
            tokenBought = tokenBought.add(bonus);
        } 
        
         
        if (msg.value >= 10 ether) {
            bonus = (tokenBought.mul(40)).div(100);  
            tokenBought = tokenBought.add(bonus);
        }

         
        require(BLU.balanceOf(this) >= tokenBought);
        
        totalDistributed = totalDistributed.add(tokenBought);  
        BLU.transfer(msg.sender,tokenBought);  
        owner.transfer(msg.value);  
        
         
        emit LogContributorsPayout(msg.sender,tokenBought);  
        emit LogBeneficiaryPaid(owner);  
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);  
    }


     
     
     
     
    function addToWhiteList(address _userAddress) onlyOwner public returns(bool) {
        require(_userAddress != address(0));  
         
        if (!whitelist[_userAddress]) {
            whitelist[_userAddress] = true;
            emit LogWhiteListed(_userAddress);  
            return true;
        } else {
            return false;
        }
    }
    
    
     
     
     
    function removeFromWhiteList(address _userAddress) onlyOwner public returns(bool) {
        require(_userAddress != address(0));  
         
        if(whitelist[_userAddress]) {
           whitelist[_userAddress] = false; 
           emit LogBlackListed(_userAddress);  
           return true;
        } else {
            return false;
        }
        
    }
    
    
     
     
     
    function checkIfWhiteListed(address _userAddress) view public returns(bool) {
        return whitelist[_userAddress];
    }
    
    
     
     
     
    function stopICO() onlyOwner public {
        isStopped = true;
    }
    
    
     
     
     
    function resumeICO() onlyOwner public {
        isStopped = false;
    }


     
     
     
    function claimTokens() onlyOwner public {
        uint256 remainder = BLU.balanceOf(this);  
        BLU.transfer(owner,remainder);  
    }
    
}