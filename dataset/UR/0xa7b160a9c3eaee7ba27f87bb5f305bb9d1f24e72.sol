 

pragma solidity ^0.4.23;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


contract GetAchieveICO is Ownable {
    using SafeMath for uint;
    
    address public beneficiary;
    uint256 public decimals;
    uint256 public softCap;             
    uint256 public hardCap;             
    uint256 public amountRaised;        
    uint256 public amountSold;          
    uint256 public maxAmountToSell;     
    
    uint256 deadline1;   
    uint256 deadline2;   
    uint256 oneWeek;     
    
    uint256 public price;        
    uint256 price0;              
    uint256 price1;              
    uint256 price2;              
    uint256 price3;              
    uint256 price4;              
    uint256 price5;              
    uint256 price6;              
    uint256 price7;              
    
    ERC20 public token;
    mapping(address => uint256) balances;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = true;      

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);
    

     
    constructor(
        address wallet,
        ERC20 addressOfToken
    ) public {
        beneficiary = wallet;
        decimals = 18;
        softCap = 4000 * 1 ether;
        hardCap = 12000 * 1 ether;
        maxAmountToSell = 192000000 * 10 ** decimals;     
         
        price0 = 40;         
        price1 = 20;         
        price2 = 24;         
        price3 = 24;         
        price4 = 28;         
        price5 = 28;         
        price6 = 32;         
        price7 = 32;         
        price = price1;      
        oneWeek = 7 * 1 days;
        deadline2 = now + 50 * oneWeek;  
        token = addressOfToken;
    }
    
     
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

     
    function () payable public {
        require(!crowdsaleClosed);
        require(_validateSaleDate());
        require(msg.sender != address(0));
        uint256 amount = msg.value;
        require(amount != 0);
        require(amount >= 10000000000000000);        
        require(amount <= hardCap);                  
        
        uint256 tokens = amount.mul(10 ** 6);        
        tokens = tokens.div(price);                  
        require(amountSold.add(tokens) <= maxAmountToSell);      
        balances[msg.sender] = balances[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        amountSold = amountSold.add(tokens);         
        
        token.transfer(msg.sender, tokens);
        emit FundTransfer(msg.sender, amount, true);
    }
    
     
    function _validateSaleDate() internal returns (bool) {
         
        if(now <= deadline1) {
            uint256 dateDif = deadline1.sub(now);
            if (dateDif <= 2 * 1 days) {
                price = price7;      
                return true;
            } else if (dateDif <= 4 * 1 days) {
                price = price6;      
                return true;
            } else if (dateDif <= 6 * 1 days) {
                price = price5;      
                return true;
            } else if (dateDif <= 8 * 1 days) {
                price = price4;      
                return true;
            } else if (dateDif <= 10 * 1 days) {
                price = price3;      
                return true;
            } else if (dateDif <= 12 * 1 days) {
                price = price2;      
                return true;
            } else if (dateDif <= 14 * 1 days) {
                price = price1;      
                return true;
            } else {
                price = 25;          
                return true;
            }
        }
         
        if (now >= (deadline1.add(oneWeek)) && now <= deadline2) {
            maxAmountToSell = 420000000 * 10 ** decimals;     
            price = price0;              
            return true;
        }
         
        if (now >= deadline2) {
            crowdsaleClosed = true;      
            return false;
        }
        
        return false;
    }
    
     
    function startCrowdsale() onlyOwner public returns (bool) {
        deadline1 = now + 2 * oneWeek;                       
        deadline2 = deadline1 + oneWeek + 8 * oneWeek;       
        crowdsaleClosed = false;     
        return true;
    }

    modifier afterDeadline() { if (now >= deadline2) _; }

     
    function checkGoalReached() onlyOwner afterDeadline public {
        if (amountRaised >= softCap) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;      
    }


     
    function safeWithdrawal() afterDeadline public {
        require(!fundingGoalReached);
        require(crowdsaleClosed);
        
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        if (amount > 0) {
            if (msg.sender.send(amount)) {
               emit FundTransfer(msg.sender, amount, false);
            } else {
                balances[msg.sender] = amount;
            }
        }
    }
    
     
    function safeWithdrawFunds(uint256 amount) onlyOwner public returns (bool) {
        require(beneficiary == msg.sender);
        
        if (beneficiary.send(amount)) {
            return true;
        } else {
            return false;
        }
    }
    
    
     
    function safeWithdrawTokens(uint256 amount) onlyOwner afterDeadline public returns (bool) {
        require(!fundingGoalReached);
        require(crowdsaleClosed);
        
        token.transfer(beneficiary, amount);
        emit FundTransfer(beneficiary, amount, false);
    }
}