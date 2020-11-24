 

 

 
contract HongConfiguration {
    uint public closingTime;
    uint public weiPerInitialHONG = 10**16;
    string public name = "HONG";
    string public symbol = "Ħ";
    uint8 public decimals = 0;
    uint public maxBountyTokens = 2 * (10**6);
    uint public closingTimeExtensionPeriod = 30 days;
    uint public minTokensToCreate = 100 * (10**6);
    uint public maxTokensToCreate = 250 * (10**6);
    uint public tokensPerTier = 50 * (10**6);
    uint public lastKickoffDateBuffer = 304 days;

    uint public mgmtRewardPercentage = 20;
    uint public mgmtFeePercentage = 8;

    uint public harvestQuorumPercent = 20;
    uint public freezeQuorumPercent = 50;
    uint public kickoffQuorumPercent = 20;
}

contract ErrorHandler {
    bool public isInTestMode = false;
    event evRecord(address msg_sender, uint msg_value, string message);
    function doThrow(string message) internal {
        evRecord(msg.sender, msg.value, message);
        if(!isInTestMode){
            throw;
        }
    }
}

contract TokenInterface is ErrorHandler {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public tokensCreated;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) returns (bool success);

    event evTransfer(address msg_sender, uint msg_value, address indexed _from, address indexed _to, uint256 _amount);

     
    modifier onlyTokenHolders {
        if (balanceOf(msg.sender) == 0) doThrow("onlyTokenHolders"); else {_}
    }
}

contract Token is TokenInterface {
     
     
    modifier noEther() {if (msg.value > 0) doThrow("noEther"); else{_}}
    modifier hasEther() {if (msg.value <= 0) doThrow("hasEther"); else{_}}

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) noEther returns (bool success) {
        if (_amount <= 0) return false;
        if (balances[msg.sender] < _amount) return false;
        if (balances[_to] + _amount < balances[_to]) return false;

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        evTransfer(msg.sender, msg.value, msg.sender, _to, _amount);

        return true;
    }
}


contract OwnedAccount is ErrorHandler {
    address public owner;
    bool acceptDeposits = true;

    event evPayOut(address msg_sender, uint msg_value, address indexed _recipient, uint _amount);

    modifier onlyOwner() {
        if (msg.sender != owner) doThrow("onlyOwner");
        else {_}
    }

    modifier noEther() {
        if (msg.value > 0) doThrow("noEther");
        else {_}
    }

    function OwnedAccount(address _owner) {
        owner = _owner;
    }

    function payOutPercentage(address _recipient, uint _percent) internal onlyOwner noEther {
        payOutAmount(_recipient, (this.balance * _percent) / 100);
    }

    function payOutAmount(address _recipient, uint _amount) internal onlyOwner noEther {
         
        if (!_recipient.call.value(_amount)())
            doThrow("payOut:sendFailed");
        else
            evPayOut(msg.sender, msg.value, _recipient, _amount);
    }

    function () returns (bool success) {
        if (!acceptDeposits) throw;
        return true;
    }
}

contract ReturnWallet is OwnedAccount {
    address public mgmtBodyWalletAddress;

    bool public inDistributionMode;
    uint public amountToDistribute;
    uint public totalTokens;
    uint public weiPerToken;

    function ReturnWallet(address _mgmtBodyWalletAddress) OwnedAccount(msg.sender) {
        mgmtBodyWalletAddress = _mgmtBodyWalletAddress;
    }

    function payManagementBodyPercent(uint _percent) {
        payOutPercentage(mgmtBodyWalletAddress, _percent);
    }

    function switchToDistributionMode(uint _totalTokens) onlyOwner {
        inDistributionMode = true;
        acceptDeposits = false;
        totalTokens = _totalTokens;
        amountToDistribute = this.balance;
        weiPerToken = amountToDistribute / totalTokens;
    }

    function payTokenHolderBasedOnTokenCount(address _tokenHolderAddress, uint _tokens) onlyOwner {
        payOutAmount(_tokenHolderAddress, weiPerToken * _tokens);
    }
}

contract ExtraBalanceWallet is OwnedAccount {
    address returnWalletAddress;
    function ExtraBalanceWallet(address _returnWalletAddress) OwnedAccount(msg.sender) {
        returnWalletAddress = _returnWalletAddress;
    }

    function returnBalanceToMainAccount() {
        acceptDeposits = false;
        payOutAmount(owner, this.balance);
    }

    function returnAmountToMainAccount(uint _amount) {
        payOutAmount(owner, _amount);
    }

    function payBalanceToReturnWallet() {
        acceptDeposits = false;
        payOutAmount(returnWalletAddress, this.balance);
    }

}

contract RewardWallet is OwnedAccount {
    address public returnWalletAddress;
    function RewardWallet(address _returnWalletAddress) OwnedAccount(msg.sender) {
        returnWalletAddress = _returnWalletAddress;
    }

    function payBalanceToReturnWallet() {
        acceptDeposits = false;
        payOutAmount(returnWalletAddress, this.balance);
    }
}

contract ManagementFeeWallet is OwnedAccount {
    address public mgmtBodyAddress;
    address public returnWalletAddress;
    function ManagementFeeWallet(address _mgmtBodyAddress, address _returnWalletAddress) OwnedAccount(msg.sender) {
        mgmtBodyAddress = _mgmtBodyAddress;
        returnWalletAddress  = _returnWalletAddress;
    }

    function payManagementBodyAmount(uint _amount) {
        payOutAmount(mgmtBodyAddress, _amount);
    }

    function payBalanceToReturnWallet() {
        acceptDeposits = false;
        payOutAmount(returnWalletAddress, this.balance);
    }
}

 
contract TokenCreationInterface is HongConfiguration {

    address public managementBodyAddress;

    ExtraBalanceWallet public extraBalanceWallet;
    mapping (address => uint256) weiGiven;
    mapping (address => uint256) public taxPaid;

    function createTokenProxy(address _tokenHolder) internal returns (bool success);
    function refundMyIcoInvestment();
    function divisor() constant returns (uint divisor);

    event evMinTokensReached(address msg_sender, uint msg_value, uint value);
    event evCreatedToken(address msg_sender, uint msg_value, address indexed to, uint amount);
    event evRefund(address msg_sender, uint msg_value, address indexed to, uint value, bool result);
}

contract GovernanceInterface is ErrorHandler, HongConfiguration {

     
     
    bool public isFundLocked;
    bool public isFundReleased;

    modifier notLocked() {if (isFundLocked) doThrow("notLocked"); else {_}}
    modifier onlyLocked() {if (!isFundLocked) doThrow("onlyLocked"); else {_}}
    modifier notReleased() {if (isFundReleased) doThrow("notReleased"); else {_}}
    modifier onlyHarvestEnabled() {if (!isHarvestEnabled) doThrow("onlyHarvestEnabled"); else {_}}
    modifier onlyDistributionNotInProgress() {if (isDistributionInProgress) doThrow("onlyDistributionNotInProgress"); else {_}}
    modifier onlyDistributionNotReady() {if (isDistributionReady) doThrow("onlyDistributionNotReady"); else {_}}
    modifier onlyDistributionReady() {if (!isDistributionReady) doThrow("onlyDistributionReady"); else {_}}
    modifier onlyCanIssueBountyToken(uint _amount) {
        if (bountyTokensCreated + _amount > maxBountyTokens){
            doThrow("hitMaxBounty");
        }
        else {_}
    }
    modifier onlyFinalFiscalYear() {
         
        if (currentFiscalYear < 4) doThrow("currentFiscalYear<4"); else {_}
    }
    modifier notFinalFiscalYear() {
         
        if (currentFiscalYear >= 4) doThrow("currentFiscalYear>=4"); else {_}
    }
    modifier onlyNotFrozen() {
        if (isFreezeEnabled) doThrow("onlyNotFrozen"); else {_}
    }

    bool public isDayThirtyChecked;
    bool public isDaySixtyChecked;

    uint256 public bountyTokensCreated;
    uint public currentFiscalYear;
    uint public lastKickoffDate;
    mapping (uint => bool) public isKickoffEnabled;
    bool public isFreezeEnabled;
    bool public isHarvestEnabled;
    bool public isDistributionInProgress;
    bool public isDistributionReady;

    ReturnWallet public returnWallet;
    RewardWallet public rewardWallet;
    ManagementFeeWallet public managementFeeWallet;

     
    function mgmtIssueBountyToken(address _recipientAddress, uint _amount) returns (bool);
    function mgmtDistribute();

    function mgmtInvestProject(
        address _projectWallet,
        uint _amount
    ) returns (bool);

    event evIssueManagementFee(address msg_sender, uint msg_value, uint _amount, bool _success);
    event evMgmtIssueBountyToken(address msg_sender, uint msg_value, address _recipientAddress, uint _amount, bool _success);
    event evMgmtDistributed(address msg_sender, uint msg_value, uint256 _amount, bool _success);
    event evMgmtInvestProject(address msg_sender, uint msg_value, address _projectWallet, uint _amount, bool result);
    event evLockFund(address msg_sender, uint msg_value);
    event evReleaseFund(address msg_sender, uint msg_value);
}


contract TokenCreation is TokenCreationInterface, Token, GovernanceInterface {
    modifier onlyManagementBody {
        if(msg.sender != address(managementBodyAddress)) {doThrow("onlyManagementBody");} else {_}
    }

    function TokenCreation(
        address _managementBodyAddress,
        uint _closingTime) {

        managementBodyAddress = _managementBodyAddress;
        closingTime = _closingTime;
    }

    function createTokenProxy(address _tokenHolder) internal notLocked notReleased hasEther returns (bool success) {

         
         
        uint tokensSupplied = 0;
        uint weiAccepted = 0;
        bool wasMinTokensReached = isMinTokensReached();

        var weiPerLatestHONG = weiPerInitialHONG * divisor() / 100;
        uint remainingWei = msg.value;
        uint tokensAvailable = tokensAvailableAtCurrentTier();
        if (tokensAvailable == 0) {
            doThrow("noTokensToSell");
            return false;
        }

         
        while (remainingWei >= weiPerLatestHONG) {
            uint tokensRequested = remainingWei / weiPerLatestHONG;
            uint tokensToSellInBatch = min(tokensAvailable, tokensRequested);

             
            if (tokensAvailable == 0 && tokensCreated == maxTokensToCreate) {
                tokensToSellInBatch = tokensRequested;
            }

            uint priceForBatch = tokensToSellInBatch * weiPerLatestHONG;

             
            weiAccepted += priceForBatch;
            tokensSupplied += tokensToSellInBatch;

             
            balances[_tokenHolder] += tokensToSellInBatch;
            tokensCreated += tokensToSellInBatch;
            weiGiven[_tokenHolder] += priceForBatch;

             
            weiPerLatestHONG = weiPerInitialHONG * divisor() / 100;
            remainingWei = msg.value - weiAccepted;
            tokensAvailable = tokensAvailableAtCurrentTier();
        }

         
        weiGiven[_tokenHolder] += remainingWei;

         
        uint256 totalTaxLevied = weiAccepted - tokensSupplied * weiPerInitialHONG;
        taxPaid[_tokenHolder] += totalTaxLevied;

         
        tryToLockFund();

         
        if (totalTaxLevied > 0) {
            if (!extraBalanceWallet.send(totalTaxLevied)){
                doThrow("extraBalance:sendFail");
                return;
            }
        }

         
        evCreatedToken(msg.sender, msg.value, _tokenHolder, tokensSupplied);
        if (!wasMinTokensReached && isMinTokensReached()) evMinTokensReached(msg.sender, msg.value, tokensCreated);
        if (isFundLocked) evLockFund(msg.sender, msg.value);
        if (isFundReleased) evReleaseFund(msg.sender, msg.value);
        return true;
    }

    function refundMyIcoInvestment() noEther notLocked onlyTokenHolders {
         
        if (weiGiven[msg.sender] == 0) {
            doThrow("noWeiGiven");
            return;
        }
        if (balances[msg.sender] > tokensCreated) {
            doThrow("invalidTokenCount");
            return;
         }

         
        bool wasMinTokensReached = isMinTokensReached();
        var tmpWeiGiven = weiGiven[msg.sender];
        var tmpTaxPaidBySender = taxPaid[msg.sender];
        var tmpSenderBalance = balances[msg.sender];

        var amountToRefund = tmpWeiGiven;

         
        balances[msg.sender] = 0;
        weiGiven[msg.sender] = 0;
        taxPaid[msg.sender] = 0;
        tokensCreated -= tmpSenderBalance;

         
         
        extraBalanceWallet.returnAmountToMainAccount(tmpTaxPaidBySender);

         
        if (!msg.sender.send(amountToRefund)) {
            evRefund(msg.sender, msg.value, msg.sender, amountToRefund, false);
            doThrow("refund:SendFailed");
            return;
        }

        evRefund(msg.sender, msg.value, msg.sender, amountToRefund, true);
        if (!wasMinTokensReached && isMinTokensReached()) evMinTokensReached(msg.sender, msg.value, tokensCreated);
    }

     
    function isMinTokensReached() constant returns (bool) {
        return tokensCreated >= minTokensToCreate;
    }

    function isMaxTokensReached() constant returns (bool) {
        return tokensCreated >= maxTokensToCreate;
    }

    function mgmtIssueBountyToken(
        address _recipientAddress,
        uint _amount
    ) noEther onlyManagementBody onlyCanIssueBountyToken(_amount) returns (bool){
         
        balances[_recipientAddress] += _amount;
        bountyTokensCreated += _amount;

         
        evMgmtIssueBountyToken(msg.sender, msg.value, _recipientAddress, _amount, true);

    }

    function mgmtDistribute() onlyManagementBody hasEther onlyHarvestEnabled onlyDistributionNotReady {
        distributeDownstream(mgmtRewardPercentage);
    }

    function distributeDownstream(uint _mgmtPercentage) internal onlyDistributionNotInProgress {

         
         
         
         
         
         

         

         
        isDistributionInProgress = true;
        isDistributionReady = true;

        payBalanceToReturnWallet();
        managementFeeWallet.payBalanceToReturnWallet();
        rewardWallet.payBalanceToReturnWallet();
        extraBalanceWallet.payBalanceToReturnWallet();

         
        if (_mgmtPercentage > 0) returnWallet.payManagementBodyPercent(_mgmtPercentage);
        returnWallet.switchToDistributionMode(tokensCreated + bountyTokensCreated);

         
        evMgmtDistributed(msg.sender, msg.value, returnWallet.balance, true);
        isDistributionInProgress = false;
    }

    function payBalanceToReturnWallet() internal {
        if (!returnWallet.send(this.balance))
            doThrow("payBalanceToReturnWallet:sendFailed");
            return;
    }

    function min(uint a, uint b) constant internal returns (uint) {
        return (a < b) ? a : b;
    }

    function tryToLockFund() internal {
         

        if (isFundReleased) {
             
            return;
        }

         
        isFundLocked = isMaxTokensReached();

         
        if (!isFundLocked && !isDayThirtyChecked && (now >= closingTime)) {
            if (isMinTokensReached()) {
                 
                isFundLocked = true;
            }
            isDayThirtyChecked = true;
        }

         
        if (!isFundLocked && !isDaySixtyChecked && (now >= (closingTime + closingTimeExtensionPeriod))) {
            if (isMinTokensReached()) {
                 
                isFundLocked = true;
            }
            isDaySixtyChecked = true;
        }

        if (isDaySixtyChecked && !isMinTokensReached()) {
             
             
            isFundReleased = true;
        }
    }

    function tokensAvailableAtTierInternal(uint8 _currentTier, uint _tokensPerTier, uint _tokensCreated) constant returns (uint) {
        uint tierThreshold = (_currentTier+1) * _tokensPerTier;

         
        if (tierThreshold > maxTokensToCreate) {
            tierThreshold = maxTokensToCreate;
        }

         
        if (_tokensCreated > tierThreshold) {
            return 0;
        }

        return tierThreshold - _tokensCreated;
    }

    function tokensAvailableAtCurrentTier() constant returns (uint) {
        return tokensAvailableAtTierInternal(getCurrentTier(), tokensPerTier, tokensCreated);
    }

    function getCurrentTier() constant returns (uint8) {
        uint8 tier = (uint8) (tokensCreated / tokensPerTier);
        return (tier > 4) ? 4 : tier;
    }

    function pricePerTokenAtCurrentTier() constant returns (uint) {
        return weiPerInitialHONG * divisor() / 100;
    }

    function divisor() constant returns (uint divisor) {

         
         

         
         

        return 100 + getCurrentTier() * 5;
    }
}


contract HONGInterface is ErrorHandler, HongConfiguration {

     

    address public managementBodyAddress;

     
    mapping (uint => mapping (address => uint)) public votedKickoff;
    mapping (address => uint) public votedFreeze;
    mapping (address => uint) public votedHarvest;
    mapping (uint => uint256) public supportKickoffQuorum;
    uint256 public supportFreezeQuorum;
    uint256 public supportHarvestQuorum;
    uint public totalInitialBalance;
    uint public annualManagementFee;

    function voteToKickoffNewFiscalYear();
    function voteToFreezeFund();
    function recallVoteToFreezeFund();
    function voteToHarvestFund();

    function collectMyReturn();

     
    event evKickoff(address msg_sender, uint msg_value, uint _fiscal);
    event evFreeze(address msg_sender, uint msg_value);
    event evHarvest(address msg_sender, uint msg_value);
}



 
contract HONG is HONGInterface, Token, TokenCreation {

    function HONG(
        address _managementBodyAddress,
        uint _closingTime,
        uint _closingTimeExtensionPeriod,
        uint _lastKickoffDateBuffer,
        uint _minTokensToCreate,
        uint _maxTokensToCreate,
        uint _tokensPerTier,
        bool _isInTestMode
    ) TokenCreation(_managementBodyAddress, _closingTime) {

        managementBodyAddress = _managementBodyAddress;
        closingTimeExtensionPeriod = _closingTimeExtensionPeriod;
        lastKickoffDateBuffer = _lastKickoffDateBuffer;

        minTokensToCreate = _minTokensToCreate;
        maxTokensToCreate = _maxTokensToCreate;
        tokensPerTier = _tokensPerTier;
        isInTestMode = _isInTestMode;

        returnWallet = new ReturnWallet(managementBodyAddress);
        rewardWallet = new RewardWallet(address(returnWallet));
        managementFeeWallet = new ManagementFeeWallet(managementBodyAddress, address(returnWallet));
        extraBalanceWallet = new ExtraBalanceWallet(address(returnWallet));

        if (address(extraBalanceWallet) == 0)
            doThrow("extraBalanceWallet:0");
        if (address(returnWallet) == 0)
            doThrow("returnWallet:0");
        if (address(rewardWallet) == 0)
            doThrow("rewardWallet:0");
        if (address(managementFeeWallet) == 0)
            doThrow("managementFeeWallet:0");
    }

    function () returns (bool success) {
        if (!isFromManagedAccount()) {
             
            return createTokenProxy(msg.sender);
        }
        else {
            evRecord(msg.sender, msg.value, "Recevied ether from ManagedAccount");
            return true;
        }
    }

    function isFromManagedAccount() internal returns (bool) {
        return msg.sender == address(extraBalanceWallet)
            || msg.sender == address(returnWallet)
            || msg.sender == address(rewardWallet)
            || msg.sender == address(managementFeeWallet);
    }

     
    function voteToKickoffNewFiscalYear() onlyTokenHolders noEther onlyLocked {
         
         
        uint _fiscal = currentFiscalYear + 1;

        if(!isKickoffEnabled[1]){   
             

        }else if(currentFiscalYear <= 3){   

            if(lastKickoffDate + lastKickoffDateBuffer < now){  
                 
            }else{
                 
                doThrow("kickOff:tooEarly");
                return;
            }
        }else{
             
            doThrow("kickOff:4thYear");
            return;
        }


        supportKickoffQuorum[_fiscal] -= votedKickoff[_fiscal][msg.sender];
        supportKickoffQuorum[_fiscal] += balances[msg.sender];
        votedKickoff[_fiscal][msg.sender] = balances[msg.sender];


        uint threshold = (kickoffQuorumPercent*(tokensCreated + bountyTokensCreated)) / 100;
        if(supportKickoffQuorum[_fiscal] > threshold) {
            if(_fiscal == 1){
                 
                extraBalanceWallet.returnBalanceToMainAccount();

                 
                totalInitialBalance = this.balance;
                uint fundToReserve = (totalInitialBalance * mgmtFeePercentage) / 100;
                annualManagementFee = fundToReserve / 4;
                if(!managementFeeWallet.send(fundToReserve)){
                    doThrow("kickoff:ManagementFeePoolWalletFail");
                    return;
                }

            }
            isKickoffEnabled[_fiscal] = true;
            currentFiscalYear = _fiscal;
            lastKickoffDate = now;

             
            managementFeeWallet.payManagementBodyAmount(annualManagementFee);

            evKickoff(msg.sender, msg.value, _fiscal);
            evIssueManagementFee(msg.sender, msg.value, annualManagementFee, true);
        }
    }

    function voteToFreezeFund() onlyTokenHolders noEther onlyLocked notFinalFiscalYear onlyDistributionNotInProgress {

        supportFreezeQuorum -= votedFreeze[msg.sender];
        supportFreezeQuorum += balances[msg.sender];
        votedFreeze[msg.sender] = balances[msg.sender];

        uint threshold = ((tokensCreated + bountyTokensCreated) * freezeQuorumPercent) / 100;
        if(supportFreezeQuorum > threshold){
            isFreezeEnabled = true;
            distributeDownstream(0);
            evFreeze(msg.sender, msg.value);
        }
    }

    function recallVoteToFreezeFund() onlyTokenHolders onlyNotFrozen noEther {
        supportFreezeQuorum -= votedFreeze[msg.sender];
        votedFreeze[msg.sender] = 0;
    }

    function voteToHarvestFund() onlyTokenHolders noEther onlyLocked onlyFinalFiscalYear {

        supportHarvestQuorum -= votedHarvest[msg.sender];
        supportHarvestQuorum += balances[msg.sender];
        votedHarvest[msg.sender] = balances[msg.sender];

        uint threshold = ((tokensCreated + bountyTokensCreated) * harvestQuorumPercent) / 100;
        if(supportHarvestQuorum > threshold) {
            isHarvestEnabled = true;
            evHarvest(msg.sender, msg.value);
        }
    }

    function collectMyReturn() onlyTokenHolders noEther onlyDistributionReady {
        uint tokens = balances[msg.sender];
        balances[msg.sender] = 0;
        returnWallet.payTokenHolderBasedOnTokenCount(msg.sender, tokens);
    }

    function mgmtInvestProject(
        address _projectWallet,
        uint _amount
    ) onlyManagementBody hasEther returns (bool _success) {

        if(!isKickoffEnabled[currentFiscalYear] || isFreezeEnabled || isHarvestEnabled){
            evMgmtInvestProject(msg.sender, msg.value, _projectWallet, _amount, false);
            return;
        }

        if(_amount >= this.balance){
            doThrow("failed:mgmtInvestProject: amount >= actualBalance");
            return;
        }

         
        if (!_projectWallet.call.value(_amount)()) {
            doThrow("failed:mgmtInvestProject: cannot send to _projectWallet");
            return;
        }

        evMgmtInvestProject(msg.sender, msg.value, _projectWallet, _amount, true);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {

         
        if(currentFiscalYear < 4){
            if(votedKickoff[currentFiscalYear+1][msg.sender] > _value){
                votedKickoff[currentFiscalYear+1][msg.sender] -= _value;
                supportKickoffQuorum[currentFiscalYear+1] -= _value;
            }else{
                supportKickoffQuorum[currentFiscalYear+1] -= votedKickoff[currentFiscalYear+1][msg.sender];
                votedKickoff[currentFiscalYear+1][msg.sender] = 0;
            }
        }

         
        if(votedFreeze[msg.sender] > _value){
            votedFreeze[msg.sender] -= _value;
            supportFreezeQuorum -= _value;
        }else{
            supportFreezeQuorum -= votedFreeze[msg.sender];
            votedFreeze[msg.sender] = 0;
        }

        if(votedHarvest[msg.sender] > _value){
            votedHarvest[msg.sender] -= _value;
            supportHarvestQuorum -= _value;
        }else{
            supportHarvestQuorum -= votedHarvest[msg.sender];
            votedHarvest[msg.sender] = 0;
        }

        if (isFundLocked && super.transfer(_to, _value)) {
            return true;
        } else {
            if(!isFundLocked){
                doThrow("failed:transfer: isFundLocked is false");
            }else{
                doThrow("failed:transfer: cannot send send to _projectWallet");
            }
            return;
        }
    }
}