 

pragma solidity ^0.4.8;


 
 
 

contract iE4RowEscrow {
        function getNumGamesStarted() constant returns (int ngames);
}

 
 

 
 
 
contract Token { 
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
 
 
contract E4RowRewards
{
        function checkDividends(address _addr) constant returns(uint _amount);
        function withdrawDividends() public returns (uint namount);
}

 
 
 
contract E4Token is Token, E4RowRewards {
        event StatEvent(string msg);
        event StatEventI(string msg, uint val);

        enum SettingStateValue  {debug, release, lockedRelease}
        enum IcoStatusValue {anouncement, saleOpen, saleClosed, failed, succeeded}




        struct tokenAccount {
                bool alloced;  
                uint tokens;  
                uint balance;  
        }
 
 
 
        address developers;  
        address public owner;  
        address founderOrg;  
        address auxPartner;  
        address e4_partner;  


        mapping (address => tokenAccount) holderAccounts ;  
        mapping (uint => address) holderIndexes ;  
        uint numAccounts;

        uint partnerCredits;  
        mapping (address => mapping (address => uint256)) allowed;  


        uint maxMintableTokens;  
        uint minIcoTokenGoal; 
        uint minUsageGoal;  
        uint public  tokenPrice;  
        uint public payoutThreshold;  

        uint totalTokenFundsReceived;    
        uint public totalTokensMinted;   
        uint public holdoverBalance;             
        int public payoutBalance;                
        int prOrigPayoutBal;                     
        uint prOrigTokensMint;                   
        uint public curPayoutId;                 
        uint public lastPayoutIndex;             
        uint public maxPaysPer;                  
        uint public minPayInterval;              


        uint fundingStart;               
        uint fundingDeadline;            
        uint usageDeadline;              
        uint public lastPayoutTime;      
        uint vestTime;           
        uint numDevTokens;       
        bool developersGranted;                  
        uint remunerationStage;          
        uint public remunerationBalance;         
        uint auxPartnerBalance;          
        uint rmGas;  
        uint rwGas;  
        uint rfGas;  

        IcoStatusValue icoStatus;   
        SettingStateValue public settingsState;


         
         
         
        function E4Token() 
        {
                owner = msg.sender;
                developers = msg.sender;
        }

         
         
         
        function applySettings(SettingStateValue qState, uint _saleStart, uint _saleEnd, uint _usageEnd, uint _minUsage, uint _tokGoal, uint  _maxMintable, uint _threshold, uint _price, uint _mpp, uint _mpi )
        {
                if (msg.sender != owner) 
                        return;

                 
                payoutThreshold = _threshold;
                maxPaysPer = _mpp;
                minPayInterval = _mpi;

                if (settingsState == SettingStateValue.lockedRelease)
                        return;

                settingsState = qState;
                icoStatus = IcoStatusValue.anouncement;

                rmGas = 100000;  
                rwGas = 10000;  
                rfGas = 10000;  


                 
                 
                 

                if (totalTokensMinted > 0) {
                        for (uint i = 0; i < numAccounts; i++ ) {
                                address a = holderIndexes[i];
                                if (a != address(0)) {
                                        holderAccounts[a].tokens = 0;
                                        holderAccounts[a].balance = 0;
                                }
                        }
                }
                 

                totalTokensMinted = 0;  
                totalTokenFundsReceived = 0;  
                e4_partner = address(0);  

                fundingStart =  _saleStart;
                fundingDeadline = _saleEnd;
                usageDeadline = _usageEnd;
                minUsageGoal = _minUsage;
                minIcoTokenGoal = _tokGoal;
                maxMintableTokens = _maxMintable;
                tokenPrice = _price;

                vestTime = fundingStart + (365 days);
                numDevTokens = 0;

                holdoverBalance = 0;
                payoutBalance = 0;
                curPayoutId = 1;
                lastPayoutIndex = 0;
                remunerationStage = 0;
                remunerationBalance = 0;
                auxPartnerBalance = 0;
                developersGranted = false;
                lastPayoutTime = 0;

                if (this.balance > 0) {
                        if (!owner.call.gas(rfGas).value(this.balance)())
                                StatEvent("ERROR!");
                }
                StatEvent("ok");

        }


         
         
         
         
         
         
        function getPayIdAndHeld(uint _tokHeld) internal returns (uint _payId, uint _held)
        {
                _payId = (_tokHeld / (2 ** 48)) & 0xffff;
                _held = _tokHeld & 0xffffffffffff;
        }
        function getHeld(uint _tokHeld) internal  returns (uint _held)
        {
                _held = _tokHeld & 0xffffffffffff;
        }
         
         
         
         
         
        function addAccount(address _addr) internal  {
                holderAccounts[_addr].alloced = true;
                holderAccounts[_addr].tokens = (curPayoutId * (2 ** 48));
                holderIndexes[numAccounts++] = _addr;
        }


 
 
 
        function totalSupply() constant returns (uint256 supply)
        {
                if (icoStatus == IcoStatusValue.saleOpen
                        || icoStatus == IcoStatusValue.anouncement)
                        supply = maxMintableTokens;
                else
                        supply = totalTokensMinted;
        }

        function transfer(address _to, uint256 _value) returns (bool success) {

                if ((msg.sender == developers) 
                        &&  (now < vestTime)) {
                         
                        return false;
                }


                 
                 
                 
                 

                var (pidFrom, heldFrom) = getPayIdAndHeld(holderAccounts[msg.sender].tokens);
                if (heldFrom >= _value && _value > 0) {

                    holderAccounts[msg.sender].tokens -= _value;

                    if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                    }

                    uint newHeld = _value + getHeld(holderAccounts[_to].tokens);
                    holderAccounts[_to].tokens = newHeld | (pidFrom * (2 ** 48));
                    Transfer(msg.sender, _to, _value);
                    return true;
                } else { 
                        return false; 
                }
        }

        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

                if ((_from == developers) 
                        &&  (now < vestTime)) {
                         
                        return false;
                }


         
         

                var (pidFrom, heldFrom) = getPayIdAndHeld(holderAccounts[_from].tokens);
                if (heldFrom >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                    holderAccounts[_from].tokens -= _value;

                    if (!holderAccounts[_to].alloced)
                        addAccount(_to);

                    uint newHeld = _value + getHeld(holderAccounts[_to].tokens);

                    holderAccounts[_to].tokens = newHeld | (pidFrom * (2 ** 48));
                    allowed[_from][msg.sender] -= _value;
                    Transfer(_from, _to, _value);
                    return true;
                } else { 
                    return false; 
                }
        }


        function balanceOf(address _owner) constant returns (uint256 balance) {
                 
                if (holderAccounts[_owner].alloced) {
                        balance = getHeld(holderAccounts[_owner].tokens);
                } 
        }

        function approve(address _spender, uint256 _value) returns (bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                return true;
        }

        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowed[_owner][_spender];
        }
 
 
 

  
         
         
         
        function holderExists(address _addr) returns(bool _exist)
        {
                _exist = holderAccounts[_addr].alloced;
        }



         
         
         
         
         
         
        function () payable {
                if (msg.sender == e4_partner) {
                     feePayment();  
                } else {
                     purchaseToken();
                }
        }

         
         
         
         
         
        function purchaseToken() payable {

                uint nvalue = msg.value;  
                address npurchaser = msg.sender;
                if (nvalue < tokenPrice) 
                        throw;

                uint qty = nvalue/tokenPrice;
                updateIcoStatus();
                if (icoStatus != IcoStatusValue.saleOpen)  
                        throw;
                if (totalTokensMinted + qty > maxMintableTokens)
                        throw;
                if (!holderAccounts[npurchaser].alloced)
                        addAccount(npurchaser);

                 
                uint newHeld = qty + getHeld(holderAccounts[npurchaser].tokens);
                holderAccounts[npurchaser].tokens = newHeld | (curPayoutId * (2 ** 48));

                totalTokensMinted += qty;
                totalTokenFundsReceived += nvalue;

                if (totalTokensMinted == maxMintableTokens) {
                        icoStatus = IcoStatusValue.saleClosed;
                         
                        doDeveloperGrant();
                        StatEventI("Purchased,Granted", qty);
                } else
                        StatEventI("Purchased", qty);

        }


         
         
         
        function feePayment() payable  
        {
                if (msg.sender != e4_partner) {
                        StatEvent("forbidden");
                        return;  
                }
                uint nfvalue = msg.value;  

                updateIcoStatus();

                holdoverBalance += nfvalue;
                partnerCredits += nfvalue;
                StatEventI("Payment", nfvalue);

                if (holdoverBalance > payoutThreshold
                        || payoutBalance > 0)
                        doPayout();


        }

         
         
         
        function setE4RowPartner(address _addr) public
        {
         
         
                if (msg.sender == owner) {
                        if ((e4_partner == address(0)) || (settingsState == SettingStateValue.debug)) {
                                e4_partner = _addr;
                                partnerCredits = 0;
                                 
                        } else {
                                StatEvent("Already Set");
                        }
                }
        }

         
         
         
        function getNumTokensPurchased() constant returns(uint _purchased)
        {
                _purchased = totalTokensMinted-numDevTokens;
        }

         
         
         
        function getNumGames() constant returns(uint _games)
        {
                 
                if (e4_partner != address(0)) {
                        iE4RowEscrow pe4 = iE4RowEscrow(e4_partner);
                        _games = uint(pe4.getNumGamesStarted());
                } 
                 
                 
        }

         
         
         
        function getSpecialAddresses() constant returns (address _fndr, address _aux, address _dev, address _e4)
        {
                 
                        _fndr = founderOrg;
                        _aux = auxPartner;
                        _dev = developers;
                        _e4  = e4_partner;
                 
        }



         
         
         
        function updateIcoStatus() public
        {
                if (icoStatus == IcoStatusValue.succeeded 
                        || icoStatus == IcoStatusValue.failed)
                        return;
                else if (icoStatus == IcoStatusValue.anouncement) {
                        if (now > fundingStart && now <= fundingDeadline) {
                                icoStatus = IcoStatusValue.saleOpen;

                        } else if (now > fundingDeadline) {
                                 
                                icoStatus = IcoStatusValue.saleClosed;
                        }
                } else {
                        uint numP = getNumTokensPurchased();
                        uint numG = getNumGames();
                        if ((now > fundingDeadline && numP < minIcoTokenGoal)
                                || (now > usageDeadline && numG < minUsageGoal)) {
                                icoStatus = IcoStatusValue.failed;
                        } else if ((now > fundingDeadline)  
                                && (numP >= minIcoTokenGoal)
                                && (numG >= minUsageGoal)) {
                                icoStatus = IcoStatusValue.succeeded;  
                        }
                        if (icoStatus == IcoStatusValue.saleOpen
                                && ((numP >= maxMintableTokens)
                                || (now > fundingDeadline))) {
                                        icoStatus = IcoStatusValue.saleClosed;
                                }
                }

                if (!developersGranted
                        && icoStatus != IcoStatusValue.saleOpen 
                        && icoStatus != IcoStatusValue.anouncement
                        && getNumTokensPurchased() >= minIcoTokenGoal) {
                                doDeveloperGrant();  
                }


        }


         
         
         
         
         
        function requestRefund()
        {
                address nrequester = msg.sender;
                updateIcoStatus();

                uint ntokens = getHeld(holderAccounts[nrequester].tokens);
                if (icoStatus != IcoStatusValue.failed)
                        StatEvent("No Refund");
                else if (ntokens == 0)
                        StatEvent("No Tokens");
                else {
                        uint nrefund = ntokens * tokenPrice;
                        if (getNumTokensPurchased() >= minIcoTokenGoal)
                                nrefund -= (nrefund /10);  

                        holderAccounts[developers].tokens += ntokens;
                        holderAccounts[nrequester].tokens = 0;
                        if (holderAccounts[nrequester].balance > 0) {
                                 
                                if (!holderAccounts[developers].alloced) 
                                        addAccount(developers);
                                holderAccounts[developers].balance += holderAccounts[nrequester].balance;
                                holderAccounts[nrequester].balance = 0;
                        }

                        if (!nrequester.call.gas(rfGas).value(nrefund)())
                                throw;
                         
                }
        }



         
         
         
         
         
         
         
         
         
         
         
         
        function doPayout()  internal
        {
                if (totalTokensMinted == 0)
                        return;

                if ((holdoverBalance > 0) 
                        && (payoutBalance == 0)
                        && (now > (lastPayoutTime+minPayInterval))) {
                         
                        curPayoutId++;
                        if (curPayoutId >= 32768)
                                curPayoutId = 1;
                        lastPayoutTime = now;
                        payoutBalance = int(holdoverBalance);
                        prOrigPayoutBal = payoutBalance;
                        prOrigTokensMint = totalTokensMinted;
                        holdoverBalance = 0;
                        lastPayoutIndex = 0;
                        StatEventI("StartRun", uint(curPayoutId));
                } else if (payoutBalance > 0) {
                         
                        uint nAmount;
                        uint nPerTokDistrib = uint(prOrigPayoutBal)/prOrigTokensMint;
                        uint paids = 0;
                        uint i;  
                        for (i = lastPayoutIndex; (paids < maxPaysPer) && (i < numAccounts) && (payoutBalance > 0); i++ ) {
                                address a = holderIndexes[i];
                                if (a == address(0)) {
                                        continue;
                                }
                                var (pid, held) = getPayIdAndHeld(holderAccounts[a].tokens);
                                if ((held > 0) && (pid != curPayoutId)) {
                                        nAmount = nPerTokDistrib * held;
                                        if (int(nAmount) <= payoutBalance){
                                                holderAccounts[a].balance += nAmount; 
                                                holderAccounts[a].tokens = (curPayoutId * (2 ** 48)) | held;
                                                payoutBalance -= int(nAmount);
                                                paids++;
                                        }
                                }
                        }
                        lastPayoutIndex = i;
                        if (lastPayoutIndex >= numAccounts || payoutBalance <= 0) {
                                lastPayoutIndex = 0;
                                if (payoutBalance > 0)
                                        holdoverBalance += uint(payoutBalance); 
                                payoutBalance = 0;
                                StatEventI("RunComplete", uint(prOrigPayoutBal) );

                        } else {
                                StatEventI("PayRun", nPerTokDistrib );
                        }
                }

        }


         
         
         
        function withdrawDividends() public returns (uint _amount)
        {
                if (holderAccounts[msg.sender].balance == 0) { 
                         
                        StatEvent("0 Balance");
                        return;
                } else {
                        if ((msg.sender == developers) 
                                &&  (now < vestTime)) {
                                 
                                 
                                return;
                        }

                        _amount = holderAccounts[msg.sender].balance; 
                        holderAccounts[msg.sender].balance = 0; 
                        if (!msg.sender.call.gas(rwGas).value(_amount)())
                                throw;
                         

                }

        }

         
         
         
        function setOpGas(uint _rm, uint _rf, uint _rw)
        {
                if (msg.sender != owner && msg.sender != developers) {
                         
                        return;
                } else {
                        rmGas = _rm;
                        rfGas = _rf;
                        rwGas = _rw;
                }
        }

         
         
         
        function getOpGas() constant returns (uint _rm, uint _rf, uint _rw)
        {
                _rm = rmGas;
                _rf = rfGas;
                _rw = rwGas;
        }
 

         
         
         
        function checkDividends(address _addr) constant returns(uint _amount)
        {
                if (holderAccounts[_addr].alloced)
                        _amount = holderAccounts[_addr].balance;
        }


         
         
         
         
         
         
         
        function icoCheckup() public
        {
                if (msg.sender != owner && msg.sender != developers)
                        throw;

                uint nmsgmask;
                 

                if (icoStatus == IcoStatusValue.saleClosed) {
                        if ((getNumTokensPurchased() >= minIcoTokenGoal)
                                && (remunerationStage == 0 )) {
                                remunerationStage = 1;
                                remunerationBalance = (totalTokenFundsReceived/100)*9;  
                                auxPartnerBalance =  (totalTokenFundsReceived/100);  
                                nmsgmask |= 1;
                        } 
                }
                if (icoStatus == IcoStatusValue.succeeded) {

                        if (remunerationStage == 0 ) {
                                remunerationStage = 1;
                                remunerationBalance = (totalTokenFundsReceived/100)*9; 
                                auxPartnerBalance =  (totalTokenFundsReceived/100);
                                nmsgmask |= 4;
                        }
                        if (remunerationStage == 1) {  
                                remunerationStage = 2;
                                remunerationBalance += totalTokenFundsReceived - (totalTokenFundsReceived/10);  
                                nmsgmask |= 8;
                        }

                }

                uint ntmp;

                if (remunerationBalance > 0) { 
                 
                                ntmp = remunerationBalance;
                                remunerationBalance = 0;
                                if (!founderOrg.call.gas(rmGas).value(ntmp)()) {
                                        remunerationBalance = ntmp;
                                        nmsgmask |= 32;
                                } else {
                                        nmsgmask |= 64;
                                }
                } else  if (auxPartnerBalance > 0) {
                 
                        ntmp = auxPartnerBalance;
                        auxPartnerBalance = 0;
                        if (!auxPartner.call.gas(rmGas).value(ntmp)()) {
                                auxPartnerBalance = ntmp;
                                nmsgmask |= 128;
                        }  else {
                                nmsgmask |= 256;
                        }

                } 

                StatEventI("ico-checkup", nmsgmask);
        }


         
         
         
        function changeOwner(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;

                owner = _addr;
        }

         
         
         
        function changeDevevoperAccont(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                developers = _addr;
        }

         
         
         
        function changeFounder(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                founderOrg = _addr;
        }

         
         
         
        function changeAuxPartner(address _aux) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                auxPartner = _aux;
        }


         
         
         
        function haraKiri()
        {
                if (settingsState != SettingStateValue.debug)
                        throw;
                if (msg.sender != owner)
                         throw;
                suicide(developers);
        }

         
         
         
        function getIcoInfo() constant returns(IcoStatusValue _status, uint _saleStart, uint _saleEnd, uint _usageEnd, uint _saleGoal, uint _usageGoal, uint _sold, uint _used, uint _funds, uint _credits, uint _remuStage, uint _vest)
        {
                _status = icoStatus;
                _saleStart = fundingStart;
                _saleEnd = fundingDeadline;
                _usageEnd = usageDeadline;
                _vest = vestTime;
                _saleGoal = minIcoTokenGoal;
                _usageGoal = minUsageGoal;
                _sold = getNumTokensPurchased();
                _used = getNumGames();
                _funds = totalTokenFundsReceived;
                _credits = partnerCredits;
                _remuStage = remunerationStage;
        }

        function flushDividends()
        {
                if ((msg.sender != owner) && (msg.sender != developers))
                        return;
                if (holdoverBalance > 0 || payoutBalance > 0)
                        doPayout();
        }

        function doDeveloperGrant() internal
        {
                if (!developersGranted) {
                        developersGranted = true;
                        numDevTokens = totalTokensMinted/10;
                        totalTokensMinted += numDevTokens;
                        if (!holderAccounts[developers].alloced) 
                                addAccount(developers);
                        uint newHeld = getHeld(holderAccounts[developers].tokens) + numDevTokens;
                        holderAccounts[developers].tokens = newHeld |  (curPayoutId * (2 ** 48));

                }
        }


}