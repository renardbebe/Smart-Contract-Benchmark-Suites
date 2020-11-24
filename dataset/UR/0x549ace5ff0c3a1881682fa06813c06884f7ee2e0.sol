 

pragma solidity ^0.4.18;
 
 

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface Token {
    function mintToken(address to, uint amount) external returns (bool success);  
    function setupMintableAddress(address _mintable) public returns (bool success);
}

contract MintableSale {
     
     
     
     
     
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success);
}

contract EarlyTokenSale is MintableSale {
    using SafeMath for uint256;
    uint256 public fundingGoal;
    uint256 public tokensPerEther;
    uint public deadline;
    address public multiSigWallet;
    uint256 public amountRaised;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    address public creator;
    address public addressOfTokenUsedAsReward;
    bool public isFunding = false;

     
    mapping (address => uint256) public accredited;

    event FundTransfer(address backer, uint amount);

     
    function EarlyTokenSale(
        address _addressOfTokenUsedAsReward
    ) payable {
        creator = msg.sender;
        multiSigWallet = 0x9581973c54fce63d0f5c4c706020028af20ff723;
         
        addressOfTokenUsedAsReward = _addressOfTokenUsedAsReward;
        tokenReward = Token(addressOfTokenUsedAsReward);
         
        setupAccreditedAddress(0xec7210E3db72651Ca21DA35309A20561a6F374dd, 1000);
    }

     
     
     
     
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success) {
        require(msg.sender == creator);
        require(isFunding == false);
        require(rate <= 6400 && rate >= 1);                    
        require(fundingGoalInEthers >= 1000);        
        require(durationInMinutes >= 60 minutes);

        deadline = now + durationInMinutes * 1 minutes;
        fundingGoal = amountRaised + fundingGoalInEthers * 1 ether;
        tokensPerEther = rate;
        isFunding = true;
        return true;    
    }

    modifier afterDeadline() { if (now > deadline) _; }
    modifier beforeDeadline() { if (now <= deadline) _; }

     
     
     
    function setupAccreditedAddress(address _accredited, uint _amountInEthers) public returns (bool success) {
        require(msg.sender == creator);    
        accredited[_accredited] = _amountInEthers * 1 ether;
        return true;
    }

     
     
    function getAmountAccredited(address _accredited) view returns (uint256) {
        uint256 amount = accredited[_accredited];
        return amount;
    }

    function closeSale() beforeDeadline {
        require(msg.sender == creator);    
        isFunding = false;
    }

     
    function changeCreator(address _creator) external {
        require(msg.sender == creator);
        creator = _creator;
    }

     
     
    function getRate() beforeDeadline view returns (uint) {
        return tokensPerEther;
    }

     
     
    function getAmountRaised() view returns (uint) {
        return amountRaised;
    }

    function () payable {
         
        require(isFunding == true && amountRaised < fundingGoal);

         
        uint256 amount = msg.value;        
        require(amount >= 1 ether);

        require(accredited[msg.sender] - amount >= 0); 

        multiSigWallet.transfer(amount);      
        balanceOf[msg.sender] += amount;
        accredited[msg.sender] -= amount;
        amountRaised += amount;
        FundTransfer(msg.sender, amount);

        uint256 value = amount.mul(tokensPerEther);        
        tokenReward.mintToken(msg.sender, value);        
    }
}