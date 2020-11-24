 

pragma solidity ^0.4.15;

 
contract IWingsAdapter {


     
    function totalCollected() constant returns (uint);
}


 
contract IWhitelist {
    

     
    function authenticate(address _account) constant returns (bool);
}


 
contract ITokenRetreiver {

     
    function retreiveTokens(address _tokenContract);
}


contract Owned {

     
    address internal owner;


     
    function Owned() {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner);

        _;
    }
}


 
contract IToken { 

     
    function totalSupply() constant returns (uint);


     
    function balanceOf(address _owner) constant returns (uint);


     
    function transfer(address _to, uint _value) returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) returns (bool);


     
    function approve(address _spender, uint _value) returns (bool);


     
    function allowance(address _owner, address _spender) constant returns (uint);
}


 
contract IManagedToken is IToken { 

     
    function isLocked() constant returns (bool);


     
    function unlock() returns (bool);


     
    function issue(address _to, uint _value) returns (bool);
}


 
contract ICrowdsale {


     
    function isInPresalePhase() constant returns (bool);


     
    function hasBalance(address _beneficiary, uint _releaseDate) constant returns (bool);


     
    function balanceOf(address _owner) constant returns (uint);


     
    function ethBalanceOf(address _owner) constant returns (uint);


     
    function refundableEthBalanceOf(address _owner) constant returns (uint);


     
    function getRate(uint _phase, uint _volume) constant returns (uint);


     
    function toTokens(uint _wei, uint _rate) constant returns (uint);


     
    function withdrawTokens();


     
    function withdrawEther();


     
    function refund();


     
    function () payable;
}


 
contract Crowdsale is ICrowdsale, Owned {

    enum Stages {
        Deploying,
        Deployed,
        InProgress,
        Ended
    }

    struct Balance {
        uint eth;
        uint tokens;
        uint index;
    }

    struct Percentage {
        uint eth;
        uint tokens;
        bool overwriteReleaseDate;
        uint fixedReleaseDate;
        uint index; 
    }

    struct Payout {
        uint percentage;
        uint vestingPeriod;
    }

    struct Phase {
        uint rate;
        uint end;
        uint bonusReleaseDate;
        bool useVolumeMultiplier;
    }

    struct VolumeMultiplier {
        uint rateMultiplier;
        uint bonusReleaseDateMultiplier;
    }

     
    uint public baseRate;
    uint public minAmount; 
    uint public maxAmount; 
    uint public minAcceptedAmount;
    uint public minAmountPresale; 
    uint public maxAmountPresale;
    uint public minAcceptedAmountPresale;

     
    address public beneficiary; 

     
    uint internal percentageDenominator;
    uint internal tokenDenominator;

     
    uint public start;
    uint public presaleEnd;
    uint public crowdsaleEnd;
    uint public raised;
    uint public allocatedEth;
    uint public allocatedTokens;
    Stages public stage;

     
    IManagedToken public token;

     
    mapping (address => uint) private balances;

     
    mapping (address => mapping(uint => Balance)) private allocated;
    mapping(address => uint[]) private allocatedIndex;

     
    mapping (address => Percentage) private stakeholderPercentages;
    address[] private stakeholderPercentagesIndex;
    Payout[] private stakeholdersPayouts;

     
    Phase[] private phases;

     
    mapping (uint => VolumeMultiplier) private volumeMultipliers;
    uint[] private volumeMultiplierThresholds;

    
     
    modifier at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    modifier only_after(uint _time) {
        require(now > crowdsaleEnd + _time);
        _;
    }


     
    modifier only_after_crowdsale() {
        require(now > crowdsaleEnd);
        _;
    }


     
    modifier only_beneficiary() {
        require(beneficiary == msg.sender);
        _;
    }


     
    function Crowdsale() {
        stage = Stages.Deploying;
    }


     
    function setup(uint _start, address _token, uint _tokenDenominator, uint _percentageDenominator, uint _minAmount, uint _maxAmount, uint _minAcceptedAmount, uint _minAmountPresale, uint _maxAmountPresale, uint _minAcceptedAmountPresale) public only_owner at_stage(Stages.Deploying) {
        token = IManagedToken(_token);
        tokenDenominator = _tokenDenominator;
        percentageDenominator = _percentageDenominator;
        start = _start;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        minAcceptedAmount = _minAcceptedAmount;
        minAmountPresale = _minAmountPresale;
        maxAmountPresale = _maxAmountPresale;
        minAcceptedAmountPresale = _minAcceptedAmountPresale;
    }


     
    function setupPhases(uint _baseRate, uint[] _phaseRates, uint[] _phasePeriods, uint[] _phaseBonusLockupPeriods, bool[] _phaseUsesVolumeMultiplier) public only_owner at_stage(Stages.Deploying) {
        baseRate = _baseRate;
        presaleEnd = start + _phasePeriods[0];  
        crowdsaleEnd = start;  

        for (uint i = 0; i < _phaseRates.length; i++) {
            crowdsaleEnd += _phasePeriods[i];
            phases.push(Phase(_phaseRates[i], crowdsaleEnd, 0, _phaseUsesVolumeMultiplier[i]));
        }

        for (uint ii = 0; ii < _phaseRates.length; ii++) {
            if (_phaseBonusLockupPeriods[ii] > 0) {
                phases[ii].bonusReleaseDate = crowdsaleEnd + _phaseBonusLockupPeriods[ii];
            }
        }
    }


     
    function setupStakeholders(address[] _stakeholders, uint[] _stakeholderEthPercentages, uint[] _stakeholderTokenPercentages, bool[] _stakeholderTokenPayoutOverwriteReleaseDates, uint[] _stakeholderTokenPayoutFixedReleaseDates, uint[] _stakeholderTokenPayoutPercentages, uint[] _stakeholderTokenPayoutVestingPeriods) public only_owner at_stage(Stages.Deploying) {
        beneficiary = _stakeholders[0];  
        for (uint i = 0; i < _stakeholders.length; i++) {
            stakeholderPercentagesIndex.push(_stakeholders[i]);
            stakeholderPercentages[_stakeholders[i]] = Percentage(
                _stakeholderEthPercentages[i], 
                _stakeholderTokenPercentages[i], 
                _stakeholderTokenPayoutOverwriteReleaseDates[i],
                _stakeholderTokenPayoutFixedReleaseDates[i], i);
        }

         
        for (uint ii = 0; ii < _stakeholderTokenPayoutPercentages.length; ii++) {
            stakeholdersPayouts.push(Payout(_stakeholderTokenPayoutPercentages[ii], _stakeholderTokenPayoutVestingPeriods[ii]));
        }
    }

    
     
    function setupVolumeMultipliers(uint[] _volumeMultiplierRates, uint[] _volumeMultiplierLockupPeriods, uint[] _volumeMultiplierThresholds) public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        volumeMultiplierThresholds = _volumeMultiplierThresholds;
        for (uint i = 0; i < volumeMultiplierThresholds.length; i++) {
            volumeMultipliers[volumeMultiplierThresholds[i]] = VolumeMultiplier(_volumeMultiplierRates[i], _volumeMultiplierLockupPeriods[i]);
        }
    }
    

     
    function deploy() public only_owner at_stage(Stages.Deploying) {
        require(phases.length > 0);
        require(stakeholderPercentagesIndex.length > 0);
        stage = Stages.Deployed;
    }


     
    function confirmBeneficiary() public only_beneficiary at_stage(Stages.Deployed) {
        stage = Stages.InProgress;
    }


     
    function isInPresalePhase() public constant returns (bool) {
        return stage == Stages.InProgress && now >= start && now <= presaleEnd;
    }


     
    function hasBalance(address _beneficiary, uint _releaseDate) public constant returns (bool) {
        return allocatedIndex[_beneficiary].length > 0 && _releaseDate == allocatedIndex[_beneficiary][allocated[_beneficiary][_releaseDate].index];
    }


     
    function balanceOf(address _owner) public constant returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].tokens;
        }

        return sum;
    }


     
    function ethBalanceOf(address _owner) public constant returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < allocatedIndex[_owner].length; i++) {
            sum += allocated[_owner][allocatedIndex[_owner][i]].eth;
        }

        return sum;
    }


     
    function refundableEthBalanceOf(address _owner) public constant returns (uint) {
        return now > crowdsaleEnd && raised < minAmount ? balances[_owner] : 0;
    }


     
    function getCurrentPhase() public constant returns (uint) {
        for (uint i = 0; i < phases.length; i++) {
            if (now <= phases[i].end) {
                return i;
                break;
            }
        }

        return phases.length;  
    }


     
    function getRate(uint _phase, uint _volume) public constant returns (uint) {
        uint rate = 0;
        if (stage == Stages.InProgress && now >= start) {
            Phase storage phase = phases[_phase];
            rate = phase.rate;

             
            if (phase.useVolumeMultiplier && volumeMultiplierThresholds.length > 0 && _volume >= volumeMultiplierThresholds[0]) {
                for (uint i = volumeMultiplierThresholds.length; i > 0; i--) {
                    if (_volume >= volumeMultiplierThresholds[i - 1]) {
                        VolumeMultiplier storage multiplier = volumeMultipliers[volumeMultiplierThresholds[i - 1]];
                        rate += phase.rate * multiplier.rateMultiplier / percentageDenominator;
                        break;
                    }
                }
            }
        }
        
        return rate;
    }


     
    function getDistributionData(uint _phase, uint _volume) internal constant returns (uint[], uint[]) {
        Phase storage phase = phases[_phase];
        uint remainingVolume = _volume;

        bool usingMultiplier = false;
        uint[] memory volumes = new uint[](1);
        uint[] memory releaseDates = new uint[](1);

         
        if (phase.useVolumeMultiplier && volumeMultiplierThresholds.length > 0 && _volume >= volumeMultiplierThresholds[0]) {
            uint phaseReleasePeriod = phase.bonusReleaseDate - crowdsaleEnd;
            for (uint i = volumeMultiplierThresholds.length; i > 0; i--) {
                if (_volume >= volumeMultiplierThresholds[i - 1]) {
                    if (!usingMultiplier) {
                        volumes = new uint[](i + 1);
                        releaseDates = new uint[](i + 1);
                        usingMultiplier = true;
                    }

                    VolumeMultiplier storage multiplier = volumeMultipliers[volumeMultiplierThresholds[i - 1]];
                    uint releaseDate = phase.bonusReleaseDate + phaseReleasePeriod * multiplier.bonusReleaseDateMultiplier / percentageDenominator;
                    uint volume = remainingVolume - volumeMultiplierThresholds[i - 1];

                     
                    volumes[i] = volume;
                    releaseDates[i] = releaseDate;

                    remainingVolume -= volume;
                }
            }
        }

         
        volumes[0] = remainingVolume;
        releaseDates[0] = phase.bonusReleaseDate;

        return (volumes, releaseDates);
    }


     
    function toTokens(uint _wei, uint _rate) public constant returns (uint) {
        return _wei * _rate * tokenDenominator / 1 ether;
    }


     
    function endCrowdsale() public at_stage(Stages.InProgress) {
        require(now > crowdsaleEnd || raised >= maxAmount);
        require(raised >= minAmount);
        stage = Stages.Ended;

         
        if (!token.unlock()) {
            revert();
        }

         
        uint totalTokenSupply = token.totalSupply() + allocatedTokens;
        for (uint i = 0; i < stakeholdersPayouts.length; i++) {
            Payout storage p = stakeholdersPayouts[i];
            _allocateStakeholdersTokens(totalTokenSupply * p.percentage / percentageDenominator, now + p.vestingPeriod);
        }

         
        _allocateStakeholdersEth(this.balance - allocatedEth, 0);
    }


     
    function withdrawTokens() public {
        uint tokensToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                tokensToSend += b.tokens;
                b.tokens = 0;
            }
        }

        if (tokensToSend > 0) {
            allocatedTokens -= tokensToSend;
            if (!token.issue(msg.sender, tokensToSend)) {
                revert();
            }
        }
    }


     
    function withdrawEther() public {
        uint ethToSend = 0;
        for (uint i = 0; i < allocatedIndex[msg.sender].length; i++) {
            uint releaseDate = allocatedIndex[msg.sender][i];
            if (releaseDate <= now) {
                Balance storage b = allocated[msg.sender][releaseDate];
                ethToSend += b.eth;
                b.eth = 0;
            }
        }

        if (ethToSend > 0) {
            allocatedEth -= ethToSend;
            if (!msg.sender.send(ethToSend)) {
                revert();
            }
        }
    }


     
    function refund() public only_after_crowdsale at_stage(Stages.InProgress) {
        require(raised < minAmount);

        uint receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }


     
    function destroy() public only_beneficiary only_after(2 years) {
        selfdestruct(beneficiary);
    }


     
    function contribute() public payable {
        _handleTransaction(msg.sender, msg.value);
    }


     
    function () payable {
        require(msg.sender == tx.origin);
        _handleTransaction(msg.sender, msg.value);
    }


     
    function _handleTransaction(address _sender, uint _received) internal at_stage(Stages.InProgress) {

         
        require(now >= start && now <= crowdsaleEnd);

         
        require(isAcceptedContributor(_sender));

         
        bool presalePhase = isInPresalePhase();
        require(!presalePhase || _received >= minAcceptedAmountPresale);
        require(!presalePhase || raised < maxAmountPresale);

         
        require(presalePhase || _received >= minAcceptedAmount);
        require(presalePhase || raised >= minAmountPresale);
        require(presalePhase || raised < maxAmount);

        uint acceptedAmount;
        if (presalePhase && raised + _received > maxAmountPresale) {
            acceptedAmount = maxAmountPresale - raised;
        } else if (raised + _received > maxAmount) {
            acceptedAmount = maxAmount - raised;
        } else {
            acceptedAmount = _received;
        }

        raised += acceptedAmount;
        
        if (presalePhase) {
             
            _allocateStakeholdersEth(acceptedAmount, 0); 
        } else {
             
            balances[_sender] += acceptedAmount; 
        }

         
        uint tokensToIssue = 0;
        uint phase = getCurrentPhase();
        var rate = getRate(phase, acceptedAmount);
        if (rate == 0) {
            revert();  
        }

        var (volumes, releaseDates) = getDistributionData(
            phase, acceptedAmount);
        
         
        for (uint i = 0; i < volumes.length; i++) {
            var tokensAtCurrentRate = toTokens(volumes[i], rate);
            if (rate > baseRate && releaseDates[i] > now) {
                uint bonusTokens = tokensAtCurrentRate * (rate - baseRate) / rate;
                _allocateTokens(_sender, bonusTokens, releaseDates[i]);

                tokensToIssue += tokensAtCurrentRate - bonusTokens;
            } else {
                tokensToIssue += tokensAtCurrentRate;
            }
        }

         
        if (tokensToIssue > 0 && !token.issue(_sender, tokensToIssue)) {
            revert();
        }

         
        if (_received - acceptedAmount > 0 && !_sender.send(_received - acceptedAmount)) {
            revert();
        }
    }


         
    function _allocateEth(address _beneficiary, uint _amount, uint _releaseDate) internal {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].eth += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                _amount, 0, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedEth += _amount;
    }


         
    function _allocateTokens(address _beneficiary, uint _amount, uint _releaseDate) internal {
        if (hasBalance(_beneficiary, _releaseDate)) {
            allocated[_beneficiary][_releaseDate].tokens += _amount;
        } else {
            allocated[_beneficiary][_releaseDate] = Balance(
                0, _amount, allocatedIndex[_beneficiary].push(_releaseDate) - 1);
        }

        allocatedTokens += _amount;
    }


         
    function _allocateStakeholdersEth(uint _amount, uint _releaseDate) internal {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.eth > 0) {
                _allocateEth(stakeholderPercentagesIndex[i], _amount * p.eth / percentageDenominator, _releaseDate);
            }
        }
    }


         
    function _allocateStakeholdersTokens(uint _amount, uint _releaseDate) internal {
        for (uint i = 0; i < stakeholderPercentagesIndex.length; i++) {
            Percentage storage p = stakeholderPercentages[stakeholderPercentagesIndex[i]];
            if (p.tokens > 0) {
                _allocateTokens(
                    stakeholderPercentagesIndex[i], 
                    _amount * p.tokens / percentageDenominator, 
                    p.overwriteReleaseDate ? p.fixedReleaseDate : _releaseDate);
            }
        }
    }


     
    function isAcceptedContributor(address _contributor) internal constant returns (bool);
}


 
contract GLACrowdsale is Crowdsale, ITokenRetreiver, IWingsAdapter {

     
    IWhitelist private whitelist;

     
    bool private presaleAttached;
    IToken private presaleToken;
    ICrowdsale private presale;
    mapping(address => bool) private presaleConversions;


     
    function setupWhitelist(address _whitelist) public only_owner at_stage(Stages.Deploying) {
        whitelist = IWhitelist(_whitelist);
    }


     
    function totalCollected() public constant returns (uint) {
        return raised;
    }


     
    function isAcceptedContributor(address _contributor) internal constant returns (bool) {
        return whitelist.authenticate(_contributor);
    }


     
    function attachPresale(address _presale, address _presaleToken) public only_owner at_stage(Stages.Deploying) {
        presaleToken = IToken(_presaleToken);
        presale = ICrowdsale(_presale);
        presaleAttached = true;
    }


     
    function importPresaleContribution(address _contributor) public {
        require(presaleAttached);
        require(!presaleConversions[_contributor]);
        presaleConversions[_contributor] = true;

         
        uint distributedPresaleTokens = presaleToken.balanceOf(_contributor);

         
        require(distributedPresaleTokens > 0);
        
         
        uint allocatedPresaleTokens = presale.balanceOf(_contributor);
        _allocateTokens(_contributor, allocatedPresaleTokens, crowdsaleEnd + 30 days);

         
        if (!token.issue(_contributor, distributedPresaleTokens)) {
            revert();
        }
    }


     
    function retreiveTokens(address _tokenContract) public only_beneficiary {
        IToken tokenInstance = IToken(_tokenContract);

         
        ITokenRetreiver(token).retreiveTokens(_tokenContract);

         
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(beneficiary, tokenBalance);
        }
    }
}