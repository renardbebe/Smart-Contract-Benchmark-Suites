 

pragma solidity ^0.4.11;
contract FundariaBonusFund {
    
    mapping(address=>uint) public ownedBonus;  
    mapping(address=>int) public investorsAccounts;  
    uint public finalTimestampOfBonusPeriod;  
    address registeringContractAddress;  
    address public fundariaTokenBuyAddress;  
    address creator;  
    
    event BonusWithdrawn(address indexed bonusOwner, uint bonusValue);
    event AccountFilledWithBonus(address indexed accountAddress, uint bonusValue, int totalValue);
    
    function FundariaBonusFund() {
        creator = msg.sender;
    }
    
     
    modifier onlyCreator { 
        if(msg.sender == creator) _; 
    }
    
     
    modifier onlyBonusOwner { 
        if(ownedBonus[msg.sender]>0) _; 
    }
    
    function setFundariaTokenBuyAddress(address _fundariaTokenBuyAddress) onlyCreator {
        fundariaTokenBuyAddress = _fundariaTokenBuyAddress;    
    }
    
    function setRegisteringContractAddress(address _registeringContractAddress) onlyCreator {
        registeringContractAddress = _registeringContractAddress;    
    }
    
     
    function setFinalTimestampOfBonusPeriod(uint _finalTimestampOfBonusPeriod) onlyCreator {
        if(finalTimestampOfBonusPeriod==0 || _finalTimestampOfBonusPeriod<finalTimestampOfBonusPeriod)
            finalTimestampOfBonusPeriod = _finalTimestampOfBonusPeriod;    
    }
    
    
     
    function withdrawBonus() onlyBonusOwner {
        if(now>finalTimestampOfBonusPeriod) {
            var bonusValue = ownedBonus[msg.sender];
            ownedBonus[msg.sender] = 0;
            BonusWithdrawn(msg.sender, bonusValue);
            msg.sender.transfer(bonusValue);
        }
    }
    
     
    function registerInvestorAccount(address accountAddress) {
        if(creator==msg.sender || registeringContractAddress==msg.sender) {
            investorsAccounts[accountAddress] = -1;    
        }
    }

     
    function fillInvestorAccountWithBonus(address accountAddress) onlyBonusOwner {
        if(investorsAccounts[accountAddress]==-1 || investorsAccounts[accountAddress]>0) {
            var bonusValue = ownedBonus[msg.sender];
            ownedBonus[msg.sender] = 0;
            if(investorsAccounts[accountAddress]==-1) investorsAccounts[accountAddress]==0; 
            investorsAccounts[accountAddress] += int(bonusValue);
            AccountFilledWithBonus(accountAddress, bonusValue, investorsAccounts[accountAddress]);
            accountAddress.transfer(bonusValue);
        }
    }
    
     
    function setOwnedBonus() payable {
        if(msg.sender == fundariaTokenBuyAddress)
            ownedBonus[tx.origin] += msg.value;         
    }
}