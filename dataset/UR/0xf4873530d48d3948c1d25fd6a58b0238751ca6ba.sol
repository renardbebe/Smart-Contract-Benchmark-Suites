 

pragma solidity ^0.4.6;

 
 
 
contract RSPLT_E {
        event StatEvent(string msg);
        event StatEventI(string msg, uint val);

        enum SettingStateValue  {debug, locked}

        struct partnerAccount {
                uint credited;   
                uint balance;    
                uint pctx10;      
                address addr;    
                bool evenStart;  
        }

 
 
 
        address public owner;                                 
        mapping (uint => partnerAccount) partnerAccounts;     
        uint public numAccounts;                              
        uint public holdoverBalance;                          
        uint public totalFundsReceived;                       
        uint public totalFundsDistributed;                    
        uint public evenDistThresh;                           
        uint public withdrawGas = 35000;                      
        uint constant TENHUNDWEI = 1000;                      

        SettingStateValue public settingsState = SettingStateValue.debug; 


         
         
         
        function RSPLT_E() {
                owner = msg.sender;
        }


         
         
         
         
        function lock() {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent("err: locked");
                        return;
                }
                settingsState == SettingStateValue.locked;
                StatEvent("ok: contract locked");
        }


         
         
         
         
        function reset() {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent("err: locked");
                        return;
                }
                numAccounts = 0;
                holdoverBalance = 0;
                totalFundsReceived = 0;
                totalFundsDistributed = 0;
                StatEvent("ok: all accts reset");
        }


         
         
         
        function setEvenDistThresh(uint256 _thresh) {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent("err: locked");
                        return;
                }
                evenDistThresh = (_thresh / TENHUNDWEI) * TENHUNDWEI;
                StatEventI("ok: threshold set", evenDistThresh);
        }


         
         
         
        function setWitdrawGas(uint256 _withdrawGas) {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                withdrawGas = _withdrawGas;
                StatEventI("ok: withdraw gas set", withdrawGas);
        }


         
         
         
        function addAccount(address _addr, uint256 _pctx10, bool _evenStart) {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent("err: locked");
                        return;
                }
                partnerAccounts[numAccounts].addr = _addr;
                partnerAccounts[numAccounts].pctx10 = _pctx10;
                partnerAccounts[numAccounts].evenStart = _evenStart;
                partnerAccounts[numAccounts].credited = 0;
                partnerAccounts[numAccounts].balance = 0;
                ++numAccounts;
                StatEvent("ok: acct added");
        }


         
         
         
        function getAccountInfo(address _addr) constant returns(uint _idx, uint _pctx10, bool _evenStart, uint _credited, uint _balance) {
                for (uint i = 0; i < numAccounts; i++ ) {
                        address addr = partnerAccounts[i].addr;
                        if (addr == _addr) {
                                _idx = i;
                                _pctx10 = partnerAccounts[i].pctx10;
                                _evenStart = partnerAccounts[i].evenStart;
                                _credited = partnerAccounts[i].credited;
                                _balance = partnerAccounts[i].balance;
                                StatEvent("ok: found acct");
                                return;
                        }
                }
                StatEvent("err: acct not found");
        }


         
         
         
        function getTotalPctx10() constant returns(uint _totalPctx10) {
                _totalPctx10 = 0;
                for (uint i = 0; i < numAccounts; i++ ) {
                        _totalPctx10 += partnerAccounts[i].pctx10;
                }
                StatEventI("ok: total pctx10", _totalPctx10);
        }


         
         
         
         
         
        function () payable {
                totalFundsReceived += msg.value;
                holdoverBalance += msg.value;
        }


         
         
         
        function distribute() {
                 
                if (holdoverBalance < TENHUNDWEI) {
                        return;
                }
                 
                 
                uint i;
                uint pctx10;
                uint acctDist;
                uint maxAcctDist;
                uint numEvenSplits = 0;
                for (i = 0; i < numAccounts; i++ ) {
                        if (partnerAccounts[i].evenStart) {
                                ++numEvenSplits;
                        } else {
                                pctx10 = partnerAccounts[i].pctx10;
                                acctDist = holdoverBalance * pctx10 / TENHUNDWEI;
                                 
                                 
                                 
                                maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
                                if (partnerAccounts[i].credited >= maxAcctDist) {
                                        acctDist = 0;
                                } else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
                                        acctDist = maxAcctDist - partnerAccounts[i].credited;
                                }
                                partnerAccounts[i].credited += acctDist;
                                partnerAccounts[i].balance += acctDist;
                                totalFundsDistributed += acctDist;
                                holdoverBalance -= acctDist;
                        }
                }
                 
                 
                uint distAmount = holdoverBalance;
                if (totalFundsDistributed < evenDistThresh) {
                        for (i = 0; i < numAccounts; i++ ) {
                                if (partnerAccounts[i].evenStart) {
                                        acctDist = distAmount / numEvenSplits;
                                         
                                         
                                         
                                        uint fundLimit = totalFundsReceived;
                                        if (fundLimit > evenDistThresh)
                                                fundLimit = evenDistThresh;
                                        maxAcctDist = fundLimit / numEvenSplits;
                                        if (partnerAccounts[i].credited >= maxAcctDist) {
                                                acctDist = 0;
                                        } else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
                                                acctDist = maxAcctDist - partnerAccounts[i].credited;
                                        }
                                        partnerAccounts[i].credited += acctDist;
                                        partnerAccounts[i].balance += acctDist;
                                        totalFundsDistributed += acctDist;
                                        holdoverBalance -= acctDist;
                                }
                        }
                }
                 
                 
                 
                distAmount = holdoverBalance;
                if (distAmount > 0) {
                        for (i = 0; i < numAccounts; i++ ) {
                                if (partnerAccounts[i].evenStart) {
                                        pctx10 = partnerAccounts[i].pctx10;
                                        acctDist = distAmount * pctx10 / TENHUNDWEI;
                                         
                                         
                                         
                                        maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
                                        if (partnerAccounts[i].credited >= maxAcctDist) {
                                                acctDist = 0;
                                        } else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
                                                acctDist = maxAcctDist - partnerAccounts[i].credited;
                                        }
                                        partnerAccounts[i].credited += acctDist;
                                        partnerAccounts[i].balance += acctDist;
                                        totalFundsDistributed += acctDist;
                                        holdoverBalance -= acctDist;
                                }
                        }
                }
                StatEvent("ok: distributed funds");
        }


         
         
         
        function withdraw() {
                for (uint i = 0; i < numAccounts; i++ ) {
                        address addr = partnerAccounts[i].addr;
                        if (addr == msg.sender) {
                                uint amount = partnerAccounts[i].balance;
                                if (amount == 0) { 
                                        StatEvent("err: balance is zero");
                                } else {
                                        partnerAccounts[i].balance = 0;
                                        if (!msg.sender.call.gas(withdrawGas).value(amount)())
                                                throw;
                                        StatEventI("ok: rewards paid", amount);
                                }
                        }
                }
        }


         
         
         
        function hariKari() {
                if (msg.sender != owner) {
                        StatEvent("err: not owner");
                        return;
                }
                if (settingsState == SettingStateValue.locked) {
                        StatEvent("err: locked");
                        return;
                }
                suicide(owner);
        }

}