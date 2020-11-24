 

pragma solidity 0.4.25;

contract ERC20TokenInterface {

    function totalSupply () external constant returns (uint);
    function balanceOf (address tokenOwner) external constant returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

 
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    function div (uint256 a, uint256 b) internal pure returns (uint256) {
         
         
        return a / b;
    }

    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

 
contract OneYearDreamTokensVestingAdvisors {

    using SafeMath for uint256;

     
    ERC20TokenInterface public dreamToken;

     
    address public withdrawalAddress = 0x0;

     
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

     
    VestingStage[2] public stages;

     
    uint256 public initialTokensBalance;

     
    uint256 public tokensSent;

     
    address public deployer;

    modifier deployerOnly { require(msg.sender == deployer); _; }
    modifier whenInitialized { require(withdrawalAddress != 0x0); _; }
    modifier whenNotInitialized { require(withdrawalAddress == 0x0); _; }

     
    event Withdraw(uint256 amount, uint256 timestamp);

     
    constructor (ERC20TokenInterface token) public {
        dreamToken = token;
        deployer = msg.sender;
    }

     
    function () external {
        withdrawTokens();
    }

     
    function initializeVestingFor (address account) external deployerOnly whenNotInitialized {
        initialTokensBalance = dreamToken.balanceOf(this);
        require(initialTokensBalance != 0);
        withdrawalAddress = account;
        vestingRules();
    }

     
    function getAvailableTokensToWithdraw () public view returns (uint256) {
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
         
         
        if (tokensUnlockedPercentage >= 100) {
            return dreamToken.balanceOf(this);
        } else {
            return getTokensAmountAllowedToWithdraw(tokensUnlockedPercentage);
        }
    }

     
    function vestingRules () internal {

        stages[0].date = 1545696000;  
        stages[1].date = 1561852800;  

        stages[0].tokensUnlockedPercentage = 50;
        stages[1].tokensUnlockedPercentage = 100;

    }

     
    function withdrawTokens () private whenInitialized {
        uint256 tokensToSend = getAvailableTokensToWithdraw();
        sendTokens(tokensToSend);
        if (dreamToken.balanceOf(this) == 0) {  
            selfdestruct(withdrawalAddress);
        }
    }

     
    function sendTokens (uint256 tokensToSend) private {
        if (tokensToSend == 0) {
            return;
        }
        tokensSent = tokensSent.add(tokensToSend);  
        dreamToken.transfer(withdrawalAddress, tokensToSend);  
        emit Withdraw(tokensToSend, now);  
    }

     
    function getTokensAmountAllowedToWithdraw (uint256 tokensUnlockedPercentage) private view returns (uint256) {
        uint256 totalTokensAllowedToWithdraw = initialTokensBalance.mul(tokensUnlockedPercentage).div(100);
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw.sub(tokensSent);
        return unsentTokensAmount;
    }

     
    function getTokensUnlockedPercentage () private view returns (uint256) {

        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                allowedPercent = stages[i].tokensUnlockedPercentage;
            }
        }

        return allowedPercent;

    }

}