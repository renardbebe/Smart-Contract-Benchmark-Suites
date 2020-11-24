 
contract CrowdliSTO is Pausable, Ownable {
     
    using SafeMath for uint;

     
    enum States {
        PrepareInvestment,
        Investment,
        Finalizing,
        Finalized
    }

    struct InvestmentPhase {
        bytes32 label;
        bool allowManualSwitch;
        uint discountBPS;
        uint capAmount;
        uint tokensSoldAmount;
    }

    struct TokenAllocation {
        bytes32 label;
        AllocationActionType actionType;
        AllocationValueType valueType;
        uint valueAmount;
        address beneficiary;
        bool isAllocated;
    }

    struct TokenStatement {
        uint requestedBase;
        uint requestedCHF;
        uint feesCHF;
        uint currentPhaseDiscount;
        uint earlyBirdCreditTokenAmount;
        uint voucherCreditTokenAmount;
        uint currentPhaseTokenAmount;
        uint nextPhaseBaseAmount;
        TokenStatementValidation validationCode;
    }

    enum Currency {
        ETH,
        CHF,
        EUR
    }

    enum ExecutionType {
        SinglePayment,
        SplitPayment
    }

    enum AllocationActionType {
        POST_ALLOCATE
    }

    enum AllocationValueType {
        FIXED_TOKEN_AMOUNT,
        BPS_OF_TOKENS_SOLD
    }

    enum TokenStatementValidation {
        OK,
        BELOW_MIN_LIMIT,
        ABOVE_MAX_LIMIT,
        EXCEEDS_HARD_CAP
    }

     
    event LogPaymentConfirmation(address indexed beneficiary, uint indexed investment, uint[] paymentDetails, uint id, Currency currency, ExecutionType executionType);
     
    event LogRegisterInvestmentPhase(address indexed sender, bool allowManualSwitch, bytes32 indexed label, uint indexed discountBPS, uint cap);

     
    event LogSaleStartUpdated(address indexed sender, uint indexed saleStartDate);

     
    event LogKYCProviderUpdated(address indexed sender, address indexed crowdliKycProvider);

     
    event LogStarted(address indexed sender);

     
    event LogInvestmentPhaseSwitched(uint phaseIndex);

     
    event LogEndDateExtended(address indexed sender, uint endDate);

     
    event LogClosed(address indexed sender, bool stoSucessfull);

     
    event LogFinalized(address indexed sender);

     
    event LogStateChanged(States _states);
    
     
    event LogPendingVoucherAdded(address _investor);

     
    States public state;

     
    address public directorsBoard;

     
    address public paymentConfirmer;

     
    address public tokenAgentWallet;

     
    CrowdliToken public token;

     
    CrowdliExchangeVault public crowdliExchangeVault;

     
    CrowdliKYCProvider public crowdliKycProvider;

     
    TokenAllocation[] public tokenAllocations;

     
    InvestmentPhase[] public investmentPhases;

     
    uint public hardCapAmount = 0;

     
    uint public hardCapThresholdAmount;

     
    uint public softCapAmount;

     
    uint public minChfAmountPerInvestment;
     
    uint public saleStartDate;

     
    uint public endDateExtensionDecissionDate;

     
    uint public endDateExtensionOffset;

     
    uint public endDate;

     
    uint public videoVerificationCostAmount ;

     
    uint internal gasCostAmount;

     
    uint public investmentPhaseIndex;

     
    bytes32 public boardComment;

     
    uint public earlyBirdTokensThresholdAmount;

     
    uint public earlyBirdAdditionalTokensAmount;

     
    uint public earlyBirdInvestorsCount;

     
    uint public earlyBirdInvestmentPhase = 0;

     
    uint public currentEarlyBirdInvestorsCount = 0;

     
    uint public voucherTokensAmount;

     
    mapping(address => bool) public investorsWithEarlyBird;

     
    mapping(address => bool) public investorsWithPendingVouchers;

     
    mapping(address => bool) public paidForVideoVerification;

     
    uint public tokensSoldAmount;

     
    uint public weiInvested ;

     
    uint public numberOfInvestors;

     
    mapping(address => uint) public allInvestmentsInChf;

     
    mapping(address => uint) public weiPerInvestor;

     
    mapping(address => uint) public chfPerInvestor;

     
    uint public chfOverallInvested;

     
    mapping(address => uint) public eurPerInvestor;

     
    uint public eurOverallInvested;

     
    uint public exchangeRate;

    uint public exchangeRateDecimals;

     
	uint constant public arrayMaxEntryLimit = 10;
	
     
     
     
     
    modifier onlyDirectorsBoard() {
        require(msg.sender == directorsBoard, "not directorsBoard");
        _;
    }

     
    modifier onlyFiatPaymentConfirmer() {
        require((msg.sender == paymentConfirmer), "not paymentConfirmer");
        _;
    }

     
    modifier onlyEtherPaymentProvider() {
        require(msg.sender == address(crowdliExchangeVault), "not crowdliExchangeVault");
        _;
    }

     
    modifier onlyTokenAgentPaymentConfirmer() {
        require((msg.sender == paymentConfirmer), "not tokenAgentPaymentConfirmer");
        _;
    }

     
    modifier inState(States _state) {
        require(hasState(_state), "not in required state");
        _;
    }


    constructor (CrowdliToken _token, CrowdliKYCProvider _crowdliKycProvider, CrowdliExchangeVault _crowdliExchangeVault, address _directorsBoard, address _paymentConfirmer, address _tokenAgentWallet) public {
        token = _token;
        crowdliKycProvider = _crowdliKycProvider;
        crowdliExchangeVault = _crowdliExchangeVault;
        directorsBoard = _directorsBoard;
        paymentConfirmer = _paymentConfirmer;
        tokenAgentWallet = _tokenAgentWallet;
    }

     
     
     
    function initSTO(uint _saleStartDate, uint _earlyBirdTokensThreshold,
        uint _earlyBirdAdditionalTokens,
        uint _earlyBirdInvestorsCount,
        uint _earlyBirdInvestmentPhase,
        uint _voucherTokensAmount,
        uint _videoVerificationCost,
        uint _softCap,
        uint _endDate,
        uint _endDateExtensionDecissionDate,
        uint _endDateExtensionOffset,
        uint _gasCost,
        uint _hardCapThresholdAmount,
        uint _minChfAmountPerInvestment) external onlyOwner {

         
        token.pause();

        saleStartDate = _saleStartDate;
        state = States.PrepareInvestment;
        earlyBirdTokensThresholdAmount = _earlyBirdTokensThreshold;
        earlyBirdInvestorsCount = _earlyBirdInvestorsCount;
        earlyBirdAdditionalTokensAmount = _earlyBirdAdditionalTokens;
        earlyBirdInvestmentPhase = _earlyBirdInvestmentPhase;
        voucherTokensAmount = _voucherTokensAmount;
        videoVerificationCostAmount = _videoVerificationCost;
        gasCostAmount = _gasCost;
        softCapAmount = _softCap;
        endDate = _endDate;
        endDateExtensionDecissionDate = _endDateExtensionDecissionDate;
        endDateExtensionOffset = _endDateExtensionOffset;
        hardCapThresholdAmount = _hardCapThresholdAmount;
        minChfAmountPerInvestment = _minChfAmountPerInvestment;

    }

    function registerPostAllocation(bytes32 _label, AllocationValueType _valueType, address _beneficiary, uint _value) external onlyOwner inState(States.PrepareInvestment) {
        require(_label != 0, "_label not set");
        require(_beneficiary != address(0), "_beneficiary not set");
        require(_value > 0, "_value not set");
        require(tokenAllocations.length < arrayMaxEntryLimit, "tokenAllocations.length is too high");
        tokenAllocations.push(TokenAllocation(_label, AllocationActionType.POST_ALLOCATE, _valueType, _value, _beneficiary, false));
    }

    function updateStartDate(uint _saleStartDate) external onlyOwner inState(States.PrepareInvestment) {
        require(_saleStartDate >= now, "saleStartDate not in future");
        saleStartDate = _saleStartDate;
        emit LogSaleStartUpdated(msg.sender, _saleStartDate);
    }

    function updateCrowdliKYCProvider(CrowdliKYCProvider _crowdliKycProvider) external onlyOwner inState(States.PrepareInvestment) {
        crowdliKycProvider = _crowdliKycProvider;
        emit LogKYCProviderUpdated(msg.sender, address(_crowdliKycProvider));
    }

    function updateExchangeRate(uint _exchangeRate, uint _exchangeRateDecimals) external onlyOwner {
        exchangeRate = _exchangeRate;
        exchangeRateDecimals = _exchangeRateDecimals;
    }

    function registerInvestmentPhase(bytes32 _label, bool allowManualSwitch, uint _discountBPS, uint _cap) external onlyOwner inState(States.PrepareInvestment) {
        require(_label != 0, "label should not be empty");
        require(investmentPhases.length <= arrayMaxEntryLimit, "investmentPhases.length is too high");
        investmentPhases.push(InvestmentPhase(_label, allowManualSwitch, _discountBPS, _cap, 0));
        emit LogRegisterInvestmentPhase(msg.sender, allowManualSwitch, _label, _discountBPS, _cap);
         
        hardCapAmount = hardCapAmount.add(_cap);
    }

    function processEtherPayment(address _beneficiary, uint _weiAmount, uint _paymentId) external whenNotPaused onlyEtherPaymentProvider inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _weiAmount, Currency.ETH, exchangeRate, exchangeRateDecimals, false, true);
    }

    function processBankPaymentCHF(address _beneficiary, uint _chfAmount, bool _hasRequestedPayments, uint _paymentId) external whenNotPaused onlyFiatPaymentConfirmer inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _chfAmount, Currency.CHF, 1, 1, _hasRequestedPayments, true);
    }

    function processBankPaymentEUR(address _beneficiary, uint _eurAmount, uint _exchangeRate, uint _exchangeRateDecimals, bool _hasRequestedPayments, uint _paymentId) external whenNotPaused onlyFiatPaymentConfirmer inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _eurAmount, Currency.EUR, _exchangeRate, _exchangeRateDecimals, _hasRequestedPayments, true);
    }

    function processTokenAgentPaymentCHF(uint _chfAmount, uint _paymentId) external whenNotPaused onlyTokenAgentPaymentConfirmer inState(States.Investment) {
        processPayment(tokenAgentWallet, _paymentId, _chfAmount, Currency.CHF, 1, 1, false, true);
    }

    function addPendingVoucher(address _investor) external onlyOwner whenNotPaused {
        investorsWithPendingVouchers[_investor] = true;
        emit LogPendingVoucherAdded(_investor);
    }

    function switchCurrentPhaseManually() external onlyDirectorsBoard inState(States.Investment) {
        require(isCurrentPhaseManuallySwitchable(), "manual switch disallowed");

         
        InvestmentPhase memory currentInvestmentPhase = investmentPhases[investmentPhaseIndex];
        uint phaseDeltaTokenAmount = currentInvestmentPhase.capAmount.sub(currentInvestmentPhase.tokensSoldAmount);

         
        uint lastIndex = investmentPhases.length.sub(1);
        investmentPhases[lastIndex].capAmount = investmentPhases[lastIndex].capAmount.add(phaseDeltaTokenAmount);
        nextInvestmentPhase();
    }

    function start() external onlyDirectorsBoard inState(States.PrepareInvestment) {
        startInternal();
    }
    
    function calculateTokenStatementFiat(address _investor, uint _currencyAmount, Currency _currency, uint256 _exchangeRate, uint256 _exchangeRateDecimals, bool _hasRequestedBankPayments, uint investmentPhaseOffset) external view returns(uint[] memory) {
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, (investmentPhaseOffset == 0), investmentPhaseOffset);
        return convertTokenStatementToArray(tokenStatement);
    }
    
    function calculateTokenStatementEther(address _investor, uint _currencyAmount, Currency _currency, bool _hasRequestedBankPayments, uint investmentPhaseOffset) external view returns(uint[] memory) {
         
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, exchangeRate, exchangeRateDecimals, _hasRequestedBankPayments, (investmentPhaseOffset == 0), investmentPhaseOffset);
        return convertTokenStatementToArray(tokenStatement);
    }

    function evalTimedStates() external view returns (bool) {
        return ((isEndDateReached() && state == States.Investment) || isStartRequired());
    }

    function extendEndDate() external inState(States.Investment) onlyDirectorsBoard {
        require(isEndDateExtendable(), "isEndDateExtendable() is false");
        endDate = endDate.add(endDateExtensionOffset);
        endDateExtensionOffset = 0;
        emit LogEndDateExtended(msg.sender, endDate);
    }

    function updateTimedStates() external {
        if (isEndDateReached()) {
            if (isSoftCapReached()) {
                close(true);
            } else {
                close(false);
            }
        }
        if(isStartRequired()){
        	startInternal();
        }
    }

    function closeManually() external onlyDirectorsBoard inState(States.Investment) {
        require(isHardCapWithinCapThresholdReached(), "Cap is not reached.");
        close(true);
    }

     
    function finalize(bytes32 _message) external onlyDirectorsBoard inState(States.Finalizing) {
         
        setBoardComment(_message);

         
        allocateTokens(AllocationActionType.POST_ALLOCATE);

         
        token.unpause();

         
        updateState(States.Finalized);

        emit LogFinalized(msg.sender);
    }

     
     
     
    function getInvestmentPhaseCount() public view returns(uint) {
        return investmentPhases.length;
    }

    function  getTokenAllocationsCount() public view returns(uint) {
        return tokenAllocations.length;
    }

    function validate() public view returns (uint) {
        uint statusCode = 0;
        if (address(token) == address(0)) {
            statusCode = 1;
        } else if (address(crowdliKycProvider) == address(0)) {
            statusCode = 2;
        } else if (softCapAmount == 0) {
            statusCode = 3;
        } else if (hardCapAmount == 0) {
            statusCode = 4;
        } else if (hardCapAmount < softCapAmount) {
            statusCode = 5;
        } else if (minChfAmountPerInvestment == 0) {
            statusCode = 6;
        } else if (investmentPhases.length == 0) {
            statusCode = 9;
        }
        return statusCode;
    }

     
    function resolvePaymentError(TokenStatementValidation validationCode) public pure returns(string memory) {
        if (validationCode == TokenStatementValidation.BELOW_MIN_LIMIT) {
            return "BELOW_MIN_LIMIT";
        } else if (validationCode == TokenStatementValidation.ABOVE_MAX_LIMIT) {
            return "ABOVE_MAX_LIMIT";
        } else if (validationCode == TokenStatementValidation.EXCEEDS_HARD_CAP) {
            return "EXCEEDS_HARD_CAP";
        }
    }

     
    function pause() public {
        super.pause();
        crowdliExchangeVault.pause();
        crowdliKycProvider.pause();
    }

     
    function unpause () public {
        super.unpause();
        crowdliExchangeVault.unpause();
        crowdliKycProvider.unpause();
    }

    function setBoardComment(bytes32 _boardComment) public onlyDirectorsBoard {
        boardComment = _boardComment;
    }

    function hasPendingVideoVerificationFees(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (crowdliKycProvider.hasVerificationLevel(_investor, CrowdliKYCProvider.VerificationTier.VideoVerified) && (!paidForVideoVerification[_investor]) && !hasUnconfirmedPayments(_investor, _hasRequestedBankPayments));
    }

    function isEntitledForEarlyBird(address _investor, uint tokenAmount, uint _investmentPhaseIndex) private view returns (bool) {
        return ((tokenAmount >= earlyBirdTokensThresholdAmount) && (currentEarlyBirdInvestorsCount < earlyBirdInvestorsCount) && !investorsWithEarlyBird[_investor] && _investmentPhaseIndex >= earlyBirdInvestmentPhase);
    }

    function hasPendingVouchers(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (investorsWithPendingVouchers[_investor] && !hasUnconfirmedPayments(_investor, _hasRequestedBankPayments));
    }

    function hasUnconfirmedPayments(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (_hasRequestedBankPayments || crowdliExchangeVault.hasRequestedPayments(_investor));
    }

    function isEndDateExtendable() public view returns (bool) {
        return ((endDateExtensionDecissionDate >= now) && (endDateExtensionOffset > 0));
    }

    function isCurrentPhaseManuallySwitchable() public view returns(bool) {
        return investmentPhases[investmentPhaseIndex].allowManualSwitch;
    }

    function isLastPhase() public view returns (bool) {
        return (investmentPhaseIndex.add(1) >= investmentPhases.length);
    }

    function isCurrentPhaseCapReached() public view returns(bool) {
        InvestmentPhase memory investmentPhase = investmentPhases[investmentPhaseIndex];
        return (investmentPhase.tokensSoldAmount >= investmentPhase.capAmount);
    }

    function isHardCapWithinCapThresholdReached() public view returns (bool) {
        return (isLastPhase() && (investmentPhases[investmentPhaseIndex].tokensSoldAmount >= investmentPhases[investmentPhaseIndex].capAmount.sub(hardCapThresholdAmount)));
    }

 	function isHardCapReached() public view returns (bool) {
        return (isLastPhase() && (investmentPhases[investmentPhaseIndex].tokensSoldAmount >= investmentPhases[investmentPhaseIndex].capAmount));
    }
    
    function isSoftCapReached() public view returns (bool) {
        return (tokensSoldAmount >= softCapAmount);
    }

    function isManuallyClosable() public view returns(bool) {
        return(hasState(States.Investment) && isHardCapWithinCapThresholdReached());
    }

    function isEndDateReached() public view returns (bool) {
        return (now > endDate);
    }

    function hasState(States _state) public view returns (bool) {
        return (state == _state);
    }

     
    function getStatisticsData() public view returns(uint[] memory) {
        uint[] memory result= new uint[](7);
        result[0] = softCapAmount;
        result[1] = hardCapAmount;
        result[2] = weiInvested;
        result[3] = chfOverallInvested;
        result[4] = eurOverallInvested;
        result[5] = tokensSoldAmount;
        result[6] = numberOfInvestors;
        return result;
    }

     
     
     
    function nextInvestmentPhase() private returns (bool) {
        if (!isLastPhase()) {
             
            investmentPhaseIndex = investmentPhaseIndex.add(1);
            emit LogInvestmentPhaseSwitched(investmentPhaseIndex);
            return false;

        } else {
            revert("payment exceeds hard cap");
        }
    }

    function confirmMintedTokensForPayment(uint _paymentId, uint tokenAmountToBuy, Currency _currency) private {
        if (Currency.ETH == _currency) {
            crowdliExchangeVault.confirmMintedTokensForPayment(_paymentId, tokenAmountToBuy);
        }
    }

    function updateState(States _state) private {
        require (_state > state, "the state can never transit backwards");
        state = _state;
        emit LogStateChanged(state);
    }

    function close(bool stoSucessfull) private inState(States.Investment) {
        require(hasState(States.Investment), "Requires state Investment");
        updateState(States.Finalizing);
        emit LogClosed(msg.sender, stoSucessfull);
    }

    function allocateTokens(AllocationActionType _actionType) private {
        for (uint i = 0; i < tokenAllocations.length;i++) {
            if (tokenAllocations[i].actionType == _actionType) {
                uint tokensToAllocate = 0;
                if (tokenAllocations[i].valueType == AllocationValueType.BPS_OF_TOKENS_SOLD) {
                    tokensToAllocate = tokensSoldAmount.mul(tokenAllocations[i].valueAmount).div(10000);
                } else if (tokenAllocations[i].valueType == AllocationValueType.FIXED_TOKEN_AMOUNT) {
                    tokensToAllocate = tokenAllocations[i].valueAmount;
                }
                token.mint(tokenAllocations[i].beneficiary, tokensToAllocate);
                tokenAllocations[i].isAllocated = true;
            }
        }
    }

    function processPayment(address _investor, uint _paymentId, uint _currencyAmount, Currency _currency, uint _exchangeRate, uint _exchangeRateDecimals, bool _hasRequestedBankPayments, bool _isFirstPayment) private {
        require(crowdliKycProvider.verificationTiers(_investor) > CrowdliKYCProvider.VerificationTier.None, "Verification tier not > 0");

        InvestmentPhase storage investmentPhase = investmentPhases[investmentPhaseIndex];
         
         
         
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, _isFirstPayment, 0);

         
        require(tokenStatement.validationCode == TokenStatementValidation.OK, resolvePaymentError(tokenStatement.validationCode));

         
         
         
         
        investmentPhase.tokensSoldAmount = investmentPhase.tokensSoldAmount.add(tokenStatement.currentPhaseTokenAmount);

         
        tokensSoldAmount = tokensSoldAmount.add(tokenStatement.currentPhaseTokenAmount);

        if (_isFirstPayment) {
            allInvestmentsInChf[_investor] = allInvestmentsInChf[_investor].add(tokenStatement.requestedCHF);

            if (tokenStatement.feesCHF > gasCostAmount)
	        	paidForVideoVerification[_investor] = true;

            if (Currency.CHF == _currency) {
                chfPerInvestor[_investor] = chfPerInvestor[_investor].add(_currencyAmount);
                chfOverallInvested = chfOverallInvested.add(_currencyAmount);
            } else if (Currency.EUR == _currency) {
                eurPerInvestor[_investor] = eurPerInvestor[_investor].add(_currencyAmount);
                eurOverallInvested = eurOverallInvested.add(_currencyAmount);
            } else if (Currency.ETH == _currency) {
                weiPerInvestor[_investor] = weiPerInvestor[_investor].add(_currencyAmount);
                weiInvested = weiInvested.add(_currencyAmount);
            }

             
            if (token.balanceOf(_investor) == 0) {
                numberOfInvestors = numberOfInvestors.add(1);
            }
        }

        if (tokenStatement.earlyBirdCreditTokenAmount > 0) {  
         
            currentEarlyBirdInvestorsCount = currentEarlyBirdInvestorsCount.add(1);

             
            investorsWithEarlyBird[_investor] = true;
        }

        if (tokenStatement.voucherCreditTokenAmount > 0) {
             
            investorsWithPendingVouchers[_investor] = false;
        }


         
         
         
        token.mint(_investor, tokenStatement.currentPhaseTokenAmount);

        if (tokenStatement.nextPhaseBaseAmount > 0) {
            ExecutionType executionType;

            executionType = ExecutionType.SplitPayment;

            emit LogPaymentConfirmation(_investor, tokenStatement.requestedBase, convertTokenStatementToArray(tokenStatement), _paymentId, _currency, executionType);
            confirmMintedTokensForPayment(_paymentId, tokenStatement.currentPhaseTokenAmount, _currency);

             
            nextInvestmentPhase();

             
            processPayment(_investor, _paymentId, tokenStatement.nextPhaseBaseAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, false);
        } else {

             
            emit LogPaymentConfirmation(_investor, tokenStatement.requestedBase, convertTokenStatementToArray(tokenStatement), _paymentId, _currency, ExecutionType.SinglePayment);
            confirmMintedTokensForPayment(_paymentId, tokenStatement.currentPhaseTokenAmount, _currency);
        }
    }

    function convertTokenStatementToArray(TokenStatement memory tokenStatement) private pure returns(uint[] memory) {
        uint[] memory tokenStatementArray = new uint[](9);
        tokenStatementArray[0] = tokenStatement.requestedBase;
        tokenStatementArray[1] = tokenStatement.requestedCHF;
        tokenStatementArray[2] = tokenStatement.feesCHF;
        tokenStatementArray[3] = tokenStatement.currentPhaseDiscount;
        tokenStatementArray[4] = tokenStatement.earlyBirdCreditTokenAmount;
        tokenStatementArray[5] = tokenStatement.voucherCreditTokenAmount;
        tokenStatementArray[6] = tokenStatement.currentPhaseTokenAmount;
        tokenStatementArray[7] = tokenStatement.nextPhaseBaseAmount;
        tokenStatementArray[8] = uint(tokenStatement.validationCode);
        return tokenStatementArray;
    }

    function calculateDiscountUptick(uint _amount, InvestmentPhase memory investmentPhase) private pure returns (uint) {
        uint currentRate = uint(10000).sub(investmentPhase.discountBPS);
        return _amount.mul(investmentPhase.discountBPS).div(currentRate);
    }

    function calculateDiscount(uint _amount, InvestmentPhase memory investmentPhase) private pure returns (uint) {
        return _amount.mul(investmentPhase.discountBPS).div(10000);
    }

    function calculateConversionFromBase(uint _currencyAmount, uint _exchangeRate, uint _exchangeRateDecimals) private pure returns (uint) {
        return _currencyAmount.mul(_exchangeRate).div(_exchangeRateDecimals);
    }

    function calculateConversionToBase(uint _currencyAmount, uint _exchangeRate, uint _exchangeRateDecimals) private pure returns (uint) {
        return _currencyAmount.mul(_exchangeRateDecimals).div(_exchangeRate);
    }

    function calculateTokenStatementStruct(address _investor, uint _currencyAmount, Currency _currency, uint256 _exchangeRate, uint256 _exchangeRateDecimals, bool _hasRequestedBankPayments, bool _isFirstPayment, uint _investmentPhaseOffset) private view returns(TokenStatement memory) {
        TokenStatement memory tokenStatement;

         
        uint investmentPhaseWithOffset = investmentPhaseIndex.add(_investmentPhaseOffset);
        InvestmentPhase memory investmentPhase = investmentPhases[investmentPhaseWithOffset];

         
        tokenStatement.requestedBase = _currencyAmount;

         
         
         
        if (Currency.CHF == _currency) {
            tokenStatement.requestedCHF = tokenStatement.requestedBase;
        } else if (Currency.EUR == _currency) {
            tokenStatement.requestedCHF = calculateConversionFromBase(tokenStatement.requestedBase, _exchangeRate, _exchangeRateDecimals);
        } else if (Currency.ETH == _currency) {
            tokenStatement.requestedCHF = calculateConversionFromBase(tokenStatement.requestedBase, _exchangeRate, _exchangeRateDecimals);
        } else revert("Currency not supported");

         
        tokenStatement.requestedCHF = roundUp(tokenStatement.requestedCHF);

        uint investmentNetCHF = tokenStatement.requestedCHF;

         
         
        if (_isFirstPayment) {
             
	         
	         
	        tokenStatement.validationCode = validatePayment(_investor, tokenStatement);
 
            tokenStatement.feesCHF = gasCostAmount;
            if (hasPendingVideoVerificationFees(_investor, _hasRequestedBankPayments)) {
                tokenStatement.feesCHF = tokenStatement.feesCHF.add(videoVerificationCostAmount);
            }
            investmentNetCHF = tokenStatement.requestedCHF.sub(tokenStatement.feesCHF);
        }

         
        uint phaseDeltaTokenAmount = investmentPhase.capAmount.sub(investmentPhase.tokensSoldAmount);
        tokenStatement.currentPhaseDiscount = roundUp(calculateDiscountUptick(investmentNetCHF, investmentPhase));
        uint tokenAmountWithCurrentPhaseDiscount = investmentNetCHF.add(tokenStatement.currentPhaseDiscount);



         
        if (tokenAmountWithCurrentPhaseDiscount > phaseDeltaTokenAmount) {
        	if (isLastPhase())
            	tokenStatement.validationCode = TokenStatementValidation.EXCEEDS_HARD_CAP;
        
            tokenStatement.currentPhaseTokenAmount = roundUp(phaseDeltaTokenAmount);
            tokenStatement.currentPhaseDiscount = roundUp(calculateDiscount(phaseDeltaTokenAmount, investmentPhase));
            uint currentPhaseNetTokenAmount = phaseDeltaTokenAmount.sub(tokenStatement.currentPhaseDiscount);
            tokenStatement.nextPhaseBaseAmount = calculateConversionToBase(investmentNetCHF.sub(currentPhaseNetTokenAmount), _exchangeRate, _exchangeRateDecimals);
        } else {
            tokenStatement.currentPhaseDiscount = tokenStatement.currentPhaseDiscount;
            tokenStatement.currentPhaseTokenAmount = tokenAmountWithCurrentPhaseDiscount;
            tokenStatement.nextPhaseBaseAmount = 0;

             
             
            if (isEntitledForEarlyBird(_investor, tokenStatement.currentPhaseTokenAmount, investmentPhaseWithOffset)) {
                tokenStatement.earlyBirdCreditTokenAmount = earlyBirdAdditionalTokensAmount;
                tokenStatement.currentPhaseTokenAmount = tokenStatement.currentPhaseTokenAmount.add(tokenStatement.earlyBirdCreditTokenAmount);
            }
             
            if (hasPendingVouchers(_investor, _hasRequestedBankPayments)) {
                tokenStatement.voucherCreditTokenAmount = voucherTokensAmount;
                tokenStatement.currentPhaseTokenAmount = tokenStatement.currentPhaseTokenAmount.add(tokenStatement.voucherCreditTokenAmount);
            }
        }
        
         
        tokenStatement.currentPhaseTokenAmount = roundUp(tokenStatement.currentPhaseTokenAmount);
        return tokenStatement;
    }

    function validatePayment(address _investor, TokenStatement memory tokenStatement) private view returns(TokenStatementValidation) {
        if (tokenStatement.requestedCHF < minChfAmountPerInvestment) {
             
            return TokenStatementValidation.BELOW_MIN_LIMIT;  
        } else if (allInvestmentsInChf[_investor].add(tokenStatement.requestedCHF) > crowdliKycProvider.getMaxChfAmountForInvestor(_investor)) {
             
            return TokenStatementValidation.ABOVE_MAX_LIMIT;
        } else return TokenStatementValidation.OK;

    }
    
    function isStartRequired() private view returns(bool) {
    	return ((now > saleStartDate) && state == States.PrepareInvestment);
    }
    
    function startInternal() private {
    	require(validate() == 0, "Start validation failed");
        saleStartDate = now;
        updateState(States.Investment);
        emit LogStarted(msg.sender);
    }

    function roundUp(uint amount) private pure returns(uint) {
        uint decimals = 10 ** 18;
        uint result = amount;
        uint remainder = amount % decimals;
        if (remainder > 0) {
            result = amount - remainder + decimals;
        }
        return result;
    }
}
