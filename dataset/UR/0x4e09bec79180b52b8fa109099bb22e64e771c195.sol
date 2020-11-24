 

pragma solidity ^0.4.11;

contract token {
    function transferFrom(address, address, uint) returns(bool){}
    function burn() {}
}

contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        Assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        Assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        Assert(c >= a && c >= b);
        return c;
    }

    function Assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}


contract Crowdsale is SafeMath {
     
    address public owner;
     
    address public initialTokensHolder = 0x084bf76c9ba9106d6114305fae9810fbbdb157d9;
     
    uint public fundingGoal =  260000000;
     
    uint public maxGoal     = 2100000000;
     
    uint public amountRaised;
     
    uint public start = 1509375600;
     
    uint public end =   1510325999;
     
    uint public tokenPrice = 19000;
     
    uint public tokensSold;
     
    token public tokenReward;
     
    mapping(address => uint256) public balanceOf;
     
    mapping(address => address) public permittedInvestors;
     
    bool public fundingGoalReached = false;
     
    bool public crowdsaleClosed = false;
     
    address beneficiary = 0x94B4776F8331DF237E087Ed548A3c8b4932D131B;
     
    event GoalReached(address TokensHolderAddr, uint amountETHRaised);
    event FundTransfer(address backer, uint amount, uint amountRaisedInICO, uint amountTokenSold, uint tokensHaveSold);
    event TransferToReferrer(address indexed backer, address indexed referrerAddress, uint commission, uint amountReferralHasInvested, uint tokensReferralHasBought);
    event AllowSuccess(address indexed investorAddr, address referralAddr);
    event Withdraw(address indexed recieve, uint amount);

     
    function Crowdsale() {
        tokenReward = token(0xd5527579226e4ebc8864906e49d05d4458ccf47f);
        owner = msg.sender;
    }

     
    function () payable {
        invest();
    }

    function invest() payable {
        if(permittedInvestors[msg.sender] == 0x0) {
            revert();
        }
        uint amount = msg.value;
        uint numTokens = safeMul(amount, tokenPrice) / 1000000000000000000;  
        if (now < start || now > end || safeAdd(tokensSold, numTokens) > maxGoal) {
            revert();
        }
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        amountRaised = safeAdd(amountRaised, amount);
        tokensSold += numTokens;
        if (!tokenReward.transferFrom(initialTokensHolder, msg.sender, numTokens)) {
            revert();
        }
        if(permittedInvestors[msg.sender] != initialTokensHolder) {
            uint commission = safeMul(numTokens, 5) / 100;
            if(commission != 0){
                 
                if (!tokenReward.transferFrom(initialTokensHolder, permittedInvestors[msg.sender], safeAdd(commission, maxGoal))) {
                    revert();
                }
                TransferToReferrer(msg.sender, permittedInvestors[msg.sender], commission, amount, numTokens);
            }
        }

        FundTransfer(msg.sender, amount, amountRaised, tokensSold, numTokens);
    }

    modifier afterDeadline() {
        if (now < end) {
            revert();
        }
        _;

    }
    modifier onlyOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

     
    function checkGoalReached() {
        if((tokensSold >= fundingGoal && now >= end) || (tokensSold >= maxGoal)) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            tokenReward.burn();
            sendToBeneficiary();
            GoalReached(initialTokensHolder, amountRaised);
        }
        if(now >= end) {
            crowdsaleClosed = true;
        }
    }

    function allowInvest(address investorAddress, address referralAddress) onlyOwner external {
        require(permittedInvestors[investorAddress] == 0x0);
        if(referralAddress != 0x0 && permittedInvestors[referralAddress] == 0x0) revert();
        permittedInvestors[investorAddress] = referralAddress == 0x0 ? initialTokensHolder : referralAddress;
        AllowSuccess(investorAddress, referralAddress);
    }

     
    function sendToBeneficiary() internal {
        beneficiary.transfer(this.balance);
    }


     
    function safeWithdrawal() afterDeadline {
        require(this.balance != 0);
        if(!crowdsaleClosed) revert();
        uint amount = balanceOf[msg.sender];
        if(address(this).balance >= amount) {
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                Withdraw(msg.sender, amount);
            }
        }
    }

    function kill() onlyOwner {
        selfdestruct(beneficiary);
    }
}