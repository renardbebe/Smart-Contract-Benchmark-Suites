 

pragma solidity ^0.5.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenDistributionSpecial {

    mapping (address => Investor) private _investors;
    address[] investorAddresses;

    struct Investor {
        uint256 total;
        uint256 released;
    }

    uint256 public initTimestamp;
    uint256 public totalAmount;
    IERC20 token;

     
     
     
     
     
     
    uint16[17] monthlyFraction = [
        5,    
        15,   
        20,   
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        5,    
        20,   
        20   
    ];

    constructor(address _token, address[] memory investors, uint256[] memory tokenAmounts) public {
        token = IERC20(_token);
        initTimestamp = block.timestamp;
        require(investors.length == tokenAmounts.length);
    
        for (uint i = 0; i < investors.length; i++) {
            address investor_address = investors[i];
            investorAddresses.push(investor_address);
            require(_investors[investor_address].total == 0);  
            _investors[investor_address].total = tokenAmounts[i] * 1000000;
            _investors[investor_address].released = 0;
            totalAmount += tokenAmounts[i];
        }
    }

    function fractionToAmount(uint256 total, uint256 numerator) internal pure returns (uint256) {
        return (total * numerator) / 140;
    }

    function computeUnlockedAmount(Investor storage inv) internal view returns (uint256) {
        uint256 total = inv.total;
         
        uint256 unlocked = fractionToAmount(total, monthlyFraction[0]);
        uint256 daysPassed = getDaysPassed();
        if (daysPassed > 510) {
            return total;  
        }

        uint256 monthsPassed = daysPassed / 30;
        if (monthsPassed >= 17) {
            return total;
        }

         
         
         
        for (uint m = 1; m < monthsPassed; m++) {
            unlocked += fractionToAmount(total, monthlyFraction[m]);
        }
    
         
        if (monthsPassed > 0) {
            uint256 daysSinceStartOfAMonth = daysPassed - monthsPassed * 30;
            if (daysSinceStartOfAMonth > 30)
            daysSinceStartOfAMonth = 30;
            uint256 unlockedThisMonths = fractionToAmount(total, monthlyFraction[monthsPassed]);
            unlocked += (unlockedThisMonths * daysSinceStartOfAMonth) / 30;
        }
        
        if (unlocked > total) {
            return total;
        } 
        else return unlocked;
    }

    function distributedTokensFor(address account) public {
        Investor storage inv = _investors[account];
        uint256 unlocked = computeUnlockedAmount(inv);
        if (unlocked > inv.released) {
            uint256 delta = unlocked - inv.released;
            inv.released = unlocked;
            token.transferFrom(0xc311e99365CEBf428088C3430499c04fbc770b17, account, delta);
        }
    }
    
    function distributedTokens() public {
        for (uint i = 0; i < investorAddresses.length; i++) {
            distributedTokensFor(investorAddresses[i]);
        }
    }

    function amountOfTokensToUnlock(address account) external view returns (uint256) {
        Investor storage inv = _investors[account];
        uint256 unlocked = computeUnlockedAmount(inv);
        return (unlocked - inv.released);
    }
    
    function getDaysPassed() public view returns (uint) {
        return (block.timestamp - initTimestamp) / 86400;
    }

}