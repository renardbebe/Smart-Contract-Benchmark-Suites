 

pragma solidity 0.4.24;

 
 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
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

 
 
contract Whitelist is Ownable {
    using SafeMath for uint256;

     
    struct Participant {
         
        uint256 bonusPercent;
         
        uint256 maxPurchaseAmount;
         
        uint256 weiContributed;
    }

     
    address public crowdsaleAddress;

     
     
    mapping(address => Participant) private participants;

     
     
    function setCrowdsale(address crowdsale) public onlyOwner {
        require(crowdsale != address(0));
        crowdsaleAddress = crowdsale;
    }

     
     
     
    function getBonusPercent(address user) public view returns(uint256) {
        return participants[user].bonusPercent;
    }

     
     
     
    function isValidPurchase(address user, uint256 weiAmount) public view returns(bool) {
        require(user != address(0));
        Participant storage participant = participants[user];
        if(participant.maxPurchaseAmount == 0) {
            return false;
        }
        return participant.weiContributed.add(weiAmount) <= participant.maxPurchaseAmount;
    }

     
     
     
     
     
     
    function addParticipant(address user, uint256 bonusPercent, uint256 maxPurchaseAmount) external onlyOwner {
        require(user != address(0));
        participants[user].bonusPercent = bonusPercent;
        participants[user].maxPurchaseAmount = maxPurchaseAmount;
    }

     
     
     
     
    function addParticipants(address[] users, uint256 bonusPercent, uint256 maxPurchaseAmount) external onlyOwner {
        
        for(uint i=0; i<users.length; i+=1) {
            require(users[i] != address(0));
            participants[users[i]].bonusPercent = bonusPercent;
            participants[users[i]].maxPurchaseAmount = maxPurchaseAmount;
        }
    }

     
     
    function revokeParticipant(address user) external onlyOwner {
        require(user != address(0));
        participants[user].maxPurchaseAmount = 0;
    }

     
     
    function revokeParticipants(address[] users) external onlyOwner {
        
        for(uint i=0; i<users.length; i+=1) {
            require(users[i] != address(0));
            participants[users[i]].maxPurchaseAmount = 0;
        }
    }

    function recordPurchase(address beneficiary, uint256 weiAmount) public {

        require(msg.sender == crowdsaleAddress);

        Participant storage participant = participants[beneficiary];
        participant.weiContributed = participant.weiContributed.add(weiAmount);
    }
    
}