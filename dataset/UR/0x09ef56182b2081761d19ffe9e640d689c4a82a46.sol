 

pragma solidity ^0.5.3;

 
contract owned {
    
     
    constructor() public { owner = msg.sender; }
    address payable owner;

     
     
     
     
     
     
     
    
     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}


 
contract EthereumTree is owned{
    
     
    struct Account 
    {
        uint accountBalance;
        uint accountInvestment;
        uint accountWithdrawedAmount;
        uint accountReferralInvestment;
        uint accountReferralBenefits;
        uint accountEarnedHolderBenefits;
        uint accountReferralCount;
        uint index;
    }

    mapping(address => Account) private Accounts;
    address[] private accountIndex;
    
     
    event RegisterInvestment(address userAddress, uint totalInvestmentAmount, uint depositInUserAccount, uint balanceInUserAccount);
    event RegisterWithdraw(address userAddress, uint totalWithdrawalAmount, uint withdrawToUserAccount, uint balanceInUserAccount);
    
    
     
    function() external payable
    {
        investInEthereumTree();
    }
    
     
    function isUser(address Address) public view returns(bool isIndeed) 
    {
        if(accountIndex.length == 0) return false;
        return (accountIndex[Accounts[Address].index] == Address);
    }
    
     
    function getAccountAtIndex(uint index) public view returns(address Address)
    {
        return accountIndex[index];
    }
    
     
    function insertUser(address accountAddress) public returns(uint index)
    {
        require(!isUser(accountAddress));
        
        Accounts[accountAddress].accountBalance = 0;
        Accounts[accountAddress].accountInvestment = 0;
        Accounts[accountAddress].accountWithdrawedAmount = 0;
        Accounts[accountAddress].accountReferralInvestment = 0;
        Accounts[accountAddress].accountReferralBenefits = 0;
        Accounts[accountAddress].accountEarnedHolderBenefits = 0;
        Accounts[accountAddress].accountReferralCount = 0;
        Accounts[accountAddress].index = accountIndex.push(accountAddress)-1;
        return accountIndex.length-1;
    }
    
     
    function getAccountCount() public view returns(uint count)
    {
        return accountIndex.length;
    }
    
     
    function getAccountBalance() public view returns(uint accountBalance, uint accountInvestment, uint accountWithdrawedAmount, uint accountReferralInvestment, uint accountReferralBenefits, uint accountEarnedHolderBenefits, uint accountReferralCount, uint index)
    {
        address accountAddress = msg.sender;
        if (isUser(accountAddress))
        {
            return (Accounts[accountAddress].accountBalance, Accounts[accountAddress].accountInvestment, Accounts[accountAddress].accountWithdrawedAmount, Accounts[accountAddress].accountReferralInvestment, Accounts[accountAddress].accountReferralBenefits, Accounts[accountAddress].accountEarnedHolderBenefits, Accounts[accountAddress].accountReferralCount, Accounts[accountAddress].index);
        }
        else
        {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }
        
    }
    
     
    function getAccountBalance(address Address) public view returns(uint accountBalance, uint accountInvestment, uint accountWithdrawedAmount, uint accountReferralInvestment, uint accountReferralBenefits, uint accountEarnedHolderBenefits, uint accountReferralCount, uint index)
    {
        address accountAddress = Address;
        if (isUser(accountAddress))
        {
            return (Accounts[accountAddress].accountBalance, Accounts[accountAddress].accountInvestment, Accounts[accountAddress].accountWithdrawedAmount, Accounts[accountAddress].accountReferralInvestment, Accounts[accountAddress].accountReferralBenefits, Accounts[accountAddress].accountEarnedHolderBenefits, Accounts[accountAddress].accountReferralCount, Accounts[accountAddress].index);
        }
        else
        {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }
        
    }
    
     
    function getAccountSummary() public view returns(uint contractBalance, uint accountBalance, uint accountInvestment, uint accountWithdrawedAmount, uint accountReferralInvestment, uint accountReferralBenefits, uint accountEarnedHolderBenefits, uint accountReferralCount, uint index)
    {
        address accountAddress = msg.sender;
        if (isUser(accountAddress))
        {
            return (address(this).balance, Accounts[accountAddress].accountBalance, Accounts[accountAddress].accountInvestment, Accounts[accountAddress].accountWithdrawedAmount, Accounts[accountAddress].accountReferralInvestment, Accounts[accountAddress].accountReferralBenefits, Accounts[accountAddress].accountEarnedHolderBenefits, Accounts[accountAddress].accountReferralCount, Accounts[accountAddress].index);
        }
        else
        {
            return (address(this).balance, 0, 0, 0, 0, 0, 0, 0, 0);
        }
        
    }
    
     
    function getAccountSummary(address Address) public view returns(uint contractBalance, uint accountBalance, uint accountInvestment, uint accountWithdrawedAmount, uint accountReferralInvestment, uint accountReferralBenefits, uint accountEarnedHolderBenefits, uint accountReferralCount, uint index)
    {
        address accountAddress = Address;
        
        if (isUser(accountAddress))
        {
            return (address(this).balance, Accounts[accountAddress].accountBalance, Accounts[accountAddress].accountInvestment, Accounts[accountAddress].accountWithdrawedAmount, Accounts[accountAddress].accountReferralInvestment, Accounts[accountAddress].accountReferralBenefits, Accounts[accountAddress].accountEarnedHolderBenefits, Accounts[accountAddress].accountReferralCount, Accounts[accountAddress].index);    
        }
        else
        {
            return (address(this).balance, 0, 0, 0, 0, 0, 0, 0, 0);    
        }
        
    }
    
     
    function getBalanceSummary() public view returns(uint accountBalance, uint accountInvestment, uint accountWithdrawedAmount, uint accountReferralInvestment, uint accountReferralBenefits, uint accountEarnedHolderBenefits, uint accountReferralCount)
    {
        accountBalance = 0;
        accountInvestment = 0;
        accountWithdrawedAmount = 0;
        accountReferralInvestment = 0;
        accountReferralBenefits = 0;
        accountEarnedHolderBenefits = 0;
        accountReferralCount = 0;
        
         
        for(uint i=0; i< accountIndex.length;i++)
        {
            accountBalance = accountBalance + Accounts[getAccountAtIndex(i)].accountBalance; 
            accountInvestment =accountInvestment + Accounts[getAccountAtIndex(i)].accountInvestment;
            accountWithdrawedAmount = accountWithdrawedAmount + Accounts[getAccountAtIndex(i)].accountWithdrawedAmount;
            accountReferralInvestment = accountReferralInvestment + Accounts[getAccountAtIndex(i)].accountReferralInvestment;
            accountReferralBenefits = accountReferralBenefits + Accounts[getAccountAtIndex(i)].accountReferralBenefits;
            accountEarnedHolderBenefits = accountEarnedHolderBenefits + Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits;
            accountReferralCount = accountReferralCount + Accounts[getAccountAtIndex(i)].accountReferralCount;
        }
        
        return (accountBalance,accountInvestment, accountWithdrawedAmount, accountReferralInvestment, accountReferralBenefits,accountEarnedHolderBenefits,accountReferralCount);
    }
    
     
    function investInEthereumTree() public payable returns(bool success)
    {
        require(msg.value > 0);
        
        uint iTotalInvestmentAmount = 0;
        uint iInvestmentAmountToUserAccount = 0;
        uint iInvestmentAmountToDistribute = 0;
        
        uint totalAccountBalance = 0;
        uint totalaccountInvestment = 0;
        uint totalAccountWithdrawedAmount = 0;
        uint totalAccountReferralInvestment = 0;
        uint totalAccountReferralBenefits = 0;
        uint TotalAccountEarnedHolderBenefits = 0;
        uint TotalAccountReferralCount = 0;
        
         
        iTotalInvestmentAmount = msg.value;
        
         
        iInvestmentAmountToDistribute = (iTotalInvestmentAmount * 10) /100;
        
         
        iInvestmentAmountToUserAccount = iTotalInvestmentAmount - iInvestmentAmountToDistribute;
        
        (totalAccountBalance,totalaccountInvestment,totalAccountWithdrawedAmount,totalAccountReferralInvestment,totalAccountReferralBenefits,TotalAccountEarnedHolderBenefits,TotalAccountReferralCount) = getBalanceSummary();
        
        if(!isUser(msg.sender))
        {
            insertUser(msg.sender);
        }
        
         
        if (totalAccountBalance == 0)
        {
            Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance + iTotalInvestmentAmount;
            Accounts[msg.sender].accountInvestment = Accounts[msg.sender].accountInvestment + iTotalInvestmentAmount;

            emit RegisterInvestment(msg.sender, iTotalInvestmentAmount, iTotalInvestmentAmount, Accounts[msg.sender].accountBalance);

            return true;
        }
        else
        {
             
            for(uint i=0; i< accountIndex.length;i++)
            {
                if (Accounts[getAccountAtIndex(i)].accountBalance != 0)
                {
                    Accounts[getAccountAtIndex(i)].accountBalance = Accounts[getAccountAtIndex(i)].accountBalance + ((iInvestmentAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                    Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits = Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits + ((iInvestmentAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                }                    
            }
            
             
            Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance + iInvestmentAmountToUserAccount;
            Accounts[msg.sender].accountInvestment = Accounts[msg.sender].accountInvestment + iTotalInvestmentAmount;
            
             
            emit RegisterInvestment(msg.sender, iTotalInvestmentAmount, iInvestmentAmountToUserAccount, Accounts[msg.sender].accountBalance);
            
            return true;
        }
    }
    
     
    function investInEthereumTree(address ReferralAccount) public payable returns(bool success) {
        require(msg.value > 0);
        
         
        address accReferralAccount = ReferralAccount;
        
        uint iTotalInvestmentAmount = 0;
        uint iInvestmentAmountToUserAccount = 0;
        uint iInvestmentAmountToReferralAccount = 0;
        uint iInvestmentAmountToDistribute = 0;
        
        uint totalAccountBalance = 0;
        uint totalaccountInvestment = 0;
        uint totalAccountWithdrawedAmount = 0;
        uint totalAccountReferralInvestment = 0;
        uint totalAccountReferralBenefits = 0;
        uint TotalAccountEarnedHolderBenefits = 0;
        uint TotalAccountReferralCount = 0;
        
         
        iTotalInvestmentAmount = msg.value;
        
         
        iInvestmentAmountToReferralAccount = ((iTotalInvestmentAmount * 10) /100)/3;
        
         
        iInvestmentAmountToDistribute = ((iTotalInvestmentAmount * 10) /100)-iInvestmentAmountToReferralAccount;
        
         
        iInvestmentAmountToUserAccount = iTotalInvestmentAmount - (iInvestmentAmountToReferralAccount + iInvestmentAmountToDistribute);

         
        if(msg.sender == accReferralAccount)
        {
            iInvestmentAmountToDistribute = iInvestmentAmountToDistribute + iInvestmentAmountToReferralAccount;
            iInvestmentAmountToReferralAccount = 0;
        }
        
        (totalAccountBalance,totalaccountInvestment,totalAccountWithdrawedAmount,totalAccountReferralInvestment,totalAccountReferralBenefits,TotalAccountEarnedHolderBenefits,TotalAccountReferralCount) = getBalanceSummary();
        
        if(!isUser(msg.sender))
        {
            insertUser(msg.sender);
        }
        
        if(!isUser(ReferralAccount))
        {
            insertUser(ReferralAccount);
        }
        
         
        if (totalAccountBalance == 0)
        {
            Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance + iInvestmentAmountToUserAccount + iInvestmentAmountToDistribute;
            Accounts[msg.sender].accountInvestment = Accounts[msg.sender].accountInvestment +  iTotalInvestmentAmount;
            
            if (msg.sender != ReferralAccount)
            {
                Accounts[accReferralAccount].accountBalance = Accounts[accReferralAccount].accountBalance + iInvestmentAmountToReferralAccount;
                Accounts[accReferralAccount].accountReferralInvestment = Accounts[accReferralAccount].accountReferralInvestment + iTotalInvestmentAmount;    
                Accounts[accReferralAccount].accountReferralBenefits = Accounts[accReferralAccount].accountReferralBenefits + iInvestmentAmountToReferralAccount;
                Accounts[accReferralAccount].accountReferralCount = Accounts[accReferralAccount].accountReferralCount + 1;
            }

            
            emit RegisterInvestment(msg.sender, iTotalInvestmentAmount, iTotalInvestmentAmount, Accounts[msg.sender].accountBalance);
            
            return true;
        }
        else
        {
             
            for(uint i=0; i< accountIndex.length;i++)
            {
                if (Accounts[getAccountAtIndex(i)].accountBalance != 0)
                {
                    Accounts[getAccountAtIndex(i)].accountBalance = Accounts[getAccountAtIndex(i)].accountBalance + ((iInvestmentAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                    Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits = Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits + ((iInvestmentAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                }                    
            }
            
             
            Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance + iInvestmentAmountToUserAccount;
            Accounts[msg.sender].accountInvestment = Accounts[msg.sender].accountInvestment +  iTotalInvestmentAmount;
            
             
            if (msg.sender != ReferralAccount){
                Accounts[accReferralAccount].accountBalance = Accounts[accReferralAccount].accountBalance + iInvestmentAmountToReferralAccount;
                Accounts[accReferralAccount].accountReferralInvestment = Accounts[accReferralAccount].accountReferralInvestment + iTotalInvestmentAmount;
                Accounts[accReferralAccount].accountReferralBenefits = Accounts[accReferralAccount].accountReferralBenefits + iInvestmentAmountToReferralAccount;
                Accounts[accReferralAccount].accountReferralCount = Accounts[accReferralAccount].accountReferralCount + 1;    
            }
            
            emit RegisterInvestment(msg.sender, iTotalInvestmentAmount, iInvestmentAmountToUserAccount, Accounts[msg.sender].accountBalance);
            
            return true;
        }
    }
    
     
    function withdraw(uint withdrawalAmount) public returns(bool success)
    {
        require(isUser(msg.sender) && Accounts[msg.sender].accountBalance >= withdrawalAmount);
    
        uint iTotalWithdrawalAmount = 0;
        uint iWithdrawalAmountToUserAccount = 0;
        uint iWithdrawalAmountToDistribute = 0;
        
        uint totalAccountBalance = 0;
        uint totalaccountInvestment = 0;
        uint totalAccountWithdrawedAmount = 0;
        uint totalAccountReferralInvestment = 0;
        uint totalAccountReferralBenefits = 0;
        uint TotalAccountEarnedHolderBenefits = 0;
        uint TotalAccountReferralCount = 0;
        
        iTotalWithdrawalAmount = withdrawalAmount;
        iWithdrawalAmountToDistribute = (iTotalWithdrawalAmount * 10) /100;
        iWithdrawalAmountToUserAccount = iTotalWithdrawalAmount - iWithdrawalAmountToDistribute;

         
        Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance - iTotalWithdrawalAmount;
        Accounts[msg.sender].accountWithdrawedAmount = Accounts[msg.sender].accountWithdrawedAmount + iTotalWithdrawalAmount;
        
        (totalAccountBalance,totalaccountInvestment,totalAccountWithdrawedAmount,totalAccountReferralInvestment,totalAccountReferralBenefits,TotalAccountEarnedHolderBenefits,TotalAccountReferralCount) = getBalanceSummary();
    
         
        if (totalAccountBalance == iTotalWithdrawalAmount)
        {
            msg.sender.transfer(iTotalWithdrawalAmount);
            
            emit RegisterWithdraw(msg.sender, iTotalWithdrawalAmount, iTotalWithdrawalAmount, Accounts[msg.sender].accountBalance);
            
            return true;
        }
        else
        {
             
            for(uint i=0; i< accountIndex.length;i++)
            {
                if (Accounts[getAccountAtIndex(i)].accountBalance != 0)
                {
                    Accounts[getAccountAtIndex(i)].accountBalance = Accounts[getAccountAtIndex(i)].accountBalance + ((iWithdrawalAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                    Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits = Accounts[getAccountAtIndex(i)].accountEarnedHolderBenefits + ((iWithdrawalAmountToDistribute * Accounts[getAccountAtIndex(i)].accountBalance)/totalAccountBalance);
                }                    
            }
            
             
            msg.sender.transfer(iWithdrawalAmountToUserAccount);
            
            emit RegisterWithdraw(msg.sender, iTotalWithdrawalAmount, iWithdrawalAmountToUserAccount, Accounts[msg.sender].accountBalance);
            
            return true;
        }
    }
    
     
    function payPromoterRewardFromOwnerAccount(address addPromoter, uint iAmount) public onlyOwner returns(bool success)
    {
        require(isUser(msg.sender) && !(msg.sender == addPromoter) && (iAmount > 0) && (Accounts[msg.sender].accountBalance > Accounts[addPromoter].accountBalance));
        
        if (isUser(addPromoter)==false)
        {
            insertUser(addPromoter);
        }
        
        Accounts[msg.sender].accountBalance = Accounts[msg.sender].accountBalance - iAmount;
        Accounts[addPromoter].accountBalance = Accounts[addPromoter].accountBalance + iAmount;
        
        return true;
    }
    
}