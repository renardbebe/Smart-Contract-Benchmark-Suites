 

pragma solidity ^0.4.11;
contract FundariaToken {
    uint public totalSupply;
    uint public supplyLimit;
    address public fundariaPoolAddress;
    
    function supplyTo(address, uint);
    function tokenForWei(uint) returns(uint);
    function weiForToken(uint) returns(uint);    
         
}

contract FundariaBonusFund {
    function setOwnedBonus() payable {}    
}

contract FundariaTokenBuy {
        
    address public fundariaBonusFundAddress;   
    address public fundariaTokenAddress;  
    
    uint public bonusPeriod = 64 weeks;  
    uint constant bonusIntervalsCount = 9;  
    uint public startTimestampOfBonusPeriod;  
    uint public finalTimestampOfBonusPeriod;  
    
     
    struct bonusData {
        uint timestamp;
        uint shareKoef;
    }
    
     
    bonusData[9] bonusShedule;
    
    address creator;  
     
    modifier onlyCreator { 
        if(msg.sender == creator) _;
    }
    
    function FundariaTokenBuy(address _fundariaTokenAddress) {
        fundariaTokenAddress = _fundariaTokenAddress;
        startTimestampOfBonusPeriod = now;
        finalTimestampOfBonusPeriod = now+bonusPeriod;
        for(uint8 i=0; i<bonusIntervalsCount; i++) {
             
            bonusShedule[i].timestamp = finalTimestampOfBonusPeriod-(bonusPeriod*(bonusIntervalsCount-i-1)/bonusIntervalsCount);
             
            bonusShedule[i].shareKoef = bonusIntervalsCount-i;
        }
        creator = msg.sender;
    }
    
    function setFundariaBonusFundAddress(address _fundariaBonusFundAddress) onlyCreator {
        fundariaBonusFundAddress = _fundariaBonusFundAddress;    
    } 
    
     
    function finishBonusPeriod() onlyCreator {
        finalTimestampOfBonusPeriod = now;    
    }
    
     
    event TokenBought(address buyer, uint tokenToBuyer, uint weiForFundariaPool, uint weiForBonusFund, uint remnantWei);
    
    function buy() payable {
        require(msg.value>0);
         
        FundariaToken ft = FundariaToken(fundariaTokenAddress);
         
        require(ft.supplyLimit()-1>ft.totalSupply());
         
        var tokenToBuyer = ft.tokenForWei(msg.value);
         
        require(tokenToBuyer>=1);
         
        var tokenToCreator = tokenToBuyer;
        uint weiForFundariaPool;  
        uint weiForBonusFund;  
        uint returnedWei;  
         
        if(ft.totalSupply()+tokenToBuyer+tokenToCreator > ft.supplyLimit()) {
             
            var supposedTokenToBuyer = tokenToBuyer;
             
            tokenToBuyer = (ft.supplyLimit()-ft.totalSupply())/2;
             
            tokenToCreator = tokenToBuyer; 
             
            var excessToken = supposedTokenToBuyer-tokenToBuyer;
             
            returnedWei = ft.weiForToken(excessToken);
        }
        
         
        var remnantValue = msg.value-returnedWei;
         
        if(now>finalTimestampOfBonusPeriod) {
            weiForFundariaPool = remnantValue;            
        } else {
            uint prevTimestamp;
            for(uint8 i=0; i<bonusIntervalsCount; i++) {
                 
                if(bonusShedule[i].timestamp>=now && now>prevTimestamp) {
                     
                    weiForBonusFund = remnantValue*bonusShedule[i].shareKoef/(bonusIntervalsCount+1);    
                }
                prevTimestamp = bonusShedule[i].timestamp;    
            }
             
            weiForFundariaPool = remnantValue-weiForBonusFund;           
        }
         
        ft.supplyTo(creator, tokenToCreator);
         
        (ft.fundariaPoolAddress()).transfer(weiForFundariaPool);
         
        if(weiForBonusFund>0) {
            FundariaBonusFund fbf = FundariaBonusFund(fundariaBonusFundAddress);
             
            fbf.setOwnedBonus.value(weiForBonusFund)();
        }
         
        if(returnedWei>0) msg.sender.transfer(returnedWei);
         
        ft.supplyTo(msg.sender, tokenToBuyer);
         
        TokenBought(msg.sender, tokenToBuyer, weiForFundariaPool, weiForBonusFund, returnedWei);
    }
    
     
    function () {
	    throw; 
    }      

}