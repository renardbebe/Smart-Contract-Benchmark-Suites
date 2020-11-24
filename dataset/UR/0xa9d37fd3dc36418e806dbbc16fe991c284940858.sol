 

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;
 




contract CollateralizerInterface {

	function unpackCollateralParametersFromBytes(
		bytes32 parameters
	) public pure returns (uint, uint, uint);

}

 



contract DebtKernelInterface {

	enum Errors {
		 
		DEBT_ISSUED,
		 
		ORDER_EXPIRED,
		 
		ISSUANCE_CANCELLED,
		 
		ORDER_CANCELLED,
		 
		 
		ORDER_INVALID_INSUFFICIENT_OR_EXCESSIVE_FEES,
		 
		 
		ORDER_INVALID_INSUFFICIENT_PRINCIPAL,
		 
		ORDER_INVALID_UNSPECIFIED_FEE_RECIPIENT,
		 
		ORDER_INVALID_NON_CONSENSUAL,
		 
		CREDITOR_BALANCE_OR_ALLOWANCE_INSUFFICIENT
	}

	 
	address public TOKEN_TRANSFER_PROXY;
	bytes32 constant public NULL_ISSUANCE_HASH = bytes32(0);

	 
	uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 8000;

	mapping (bytes32 => bool) public issuanceCancelled;
	mapping (bytes32 => bool) public debtOrderCancelled;

	event LogDebtOrderFilled(
		bytes32 indexed _agreementId,
		uint _principal,
		address _principalToken,
		address indexed _underwriter,
		uint _underwriterFee,
		address indexed _relayer,
		uint _relayerFee
	);

	event LogIssuanceCancelled(
		bytes32 indexed _agreementId,
		address indexed _cancelledBy
	);

	event LogDebtOrderCancelled(
		bytes32 indexed _debtOrderHash,
		address indexed _cancelledBy
	);

	event LogError(
		uint8 indexed _errorId,
		bytes32 indexed _orderHash
	);

	struct Issuance {
		address version;
		address debtor;
		address underwriter;
		uint underwriterRiskRating;
		address termsContract;
		bytes32 termsContractParameters;
		uint salt;
		bytes32 agreementId;
	}

	struct DebtOrder {
		Issuance issuance;
		uint underwriterFee;
		uint relayerFee;
		uint principalAmount;
		address principalToken;
		uint creditorFee;
		uint debtorFee;
		address relayer;
		uint expirationTimestampInSec;
		bytes32 debtOrderHash;
	}

    function fillDebtOrder(
        address creditor,
        address[6] orderAddresses,
        uint[8] orderValues,
        bytes32[1] orderBytes32,
        uint8[3] signaturesV,
        bytes32[3] signaturesR,
        bytes32[3] signaturesS
    )
        public
        returns (bytes32 _agreementId);

}

 



contract DebtTokenInterface {

    function transfer(address _to, uint _tokenId) public;

    function exists(uint256 _tokenId) public view returns (bool);

}

 



contract TokenTransferProxyInterface {}

 







contract ContractRegistryInterface {

    CollateralizerInterface public collateralizer;
    DebtKernelInterface public debtKernel;
    DebtTokenInterface public debtToken;
    TokenTransferProxyInterface public tokenTransferProxy;

    function ContractRegistryInterface(
        address _collateralizer,
        address _debtKernel,
        address _debtToken,
        address _tokenTransferProxy
    )
        public
    {
        collateralizer = CollateralizerInterface(_collateralizer);
        debtKernel = DebtKernelInterface(_debtKernel);
        debtToken = DebtTokenInterface(_debtToken);
        tokenTransferProxy = TokenTransferProxyInterface(_tokenTransferProxy);
    }

}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 




contract SignaturesLibrary {
	bytes constant internal PREFIX = "\x19Ethereum Signed Message:\n32";

	struct ECDSASignature {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	function isValidSignature(
		address signer,
		bytes32 hash,
		ECDSASignature signature
	)
		public
		pure
		returns (bool valid)
	{
		bytes32 prefixedHash = keccak256(PREFIX, hash);
		return ecrecover(prefixedHash, signature.v, signature.r, signature.s) == signer;
	}
}

 




contract OrderLibrary {
	struct DebtOrder {
		address kernelVersion;
		address issuanceVersion;
		uint principalAmount;
		address principalToken;
		uint collateralAmount;
		address collateralToken;
		address debtor;
		uint debtorFee;
		address creditor;
		uint creditorFee;
		address relayer;
		uint relayerFee;
		address underwriter;
		uint underwriterFee;
		uint underwriterRiskRating;
		address termsContract;
		bytes32 termsContractParameters;
		uint expirationTimestampInSec;
		uint salt;
		SignaturesLibrary.ECDSASignature debtorSignature;
		SignaturesLibrary.ECDSASignature creditorSignature;
		SignaturesLibrary.ECDSASignature underwriterSignature;
	}

	function unpackDebtOrder(DebtOrder memory order)
		public
		pure
		returns (
	        address[6] orderAddresses,
	        uint[8] orderValues,
	        bytes32[1] orderBytes32,
	        uint8[3] signaturesV,
	        bytes32[3] signaturesR,
	        bytes32[3] signaturesS
		)
	{
		return (
			[order.issuanceVersion, order.debtor, order.underwriter, order.termsContract, order.principalToken, order.relayer],
            [order.underwriterRiskRating, order.salt, order.principalAmount, order.underwriterFee, order.relayerFee, order.creditorFee, order.debtorFee, order.expirationTimestampInSec],
			[order.termsContractParameters],
            [order.debtorSignature.v, order.creditorSignature.v, order.underwriterSignature.v],
			[order.debtorSignature.r, order.creditorSignature.r, order.underwriterSignature.r],
			[order.debtorSignature.s, order.creditorSignature.s, order.underwriterSignature.s]
		);
	}
}

 






contract LTVDecisionEngineTypes
{
	 
	struct Params {
		address creditor;
		 
		CreditorCommitment creditorCommitment;
		 
		Price principalPrice;
		Price collateralPrice;
		 
		OrderLibrary.DebtOrder order;
	}

	struct Price {
		uint value;
		uint timestamp;
		address tokenAddress;
		SignaturesLibrary.ECDSASignature signature;
	}

	struct CreditorCommitment {
		CommitmentValues values;
		SignaturesLibrary.ECDSASignature signature;
	}

	struct CommitmentValues {
		uint maxLTV;
		address priceFeedOperator;
	}

	struct SimpleInterestParameters {
		uint principalTokenIndex;
		uint principalAmount;
        uint interestRate;
        uint amortizationUnitType;
        uint termLengthInAmortizationUnits;
	}

	struct CollateralParameters {
		uint collateralTokenIndex;
		uint collateralAmount;
		uint gracePeriodInDays;
	}
}

 




contract TermsContractInterface {

	function registerTermStart(
        bytes32 agreementId,
        address debtor
    ) public returns (bool _success);

	function registerRepayment(
        bytes32 agreementId,
        address payer,
        address beneficiary,
        uint256 unitsOfRepayment,
        address tokenAddress
    ) public returns (bool _success);

	function getExpectedRepaymentValue(
        bytes32 agreementId,
        uint256 timestamp
    ) public view returns (uint256);

	function getValueRepaidToDate(
        bytes32 agreementId
    ) public view returns (uint256);

	function getTermEndTimestamp(
        bytes32 _agreementId
    ) public view returns (uint);

}

 




contract SimpleInterestTermsContractInterface is TermsContractInterface {

    function unpackParametersFromBytes(
        bytes32 parameters
    ) public pure returns (
        uint _principalTokenIndex,
        uint _principalAmount,
        uint _interestRate,
        uint _amortizationUnitType,
        uint _termLengthInAmortizationUnits
    );

}

 



 


 




 




contract LTVDecisionEngine is LTVDecisionEngineTypes, SignaturesLibrary, OrderLibrary
{
	using SafeMath for uint;

	uint public constant PRECISION = 4;

	uint public constant MAX_PRICE_TTL_IN_SECONDS = 600;

	ContractRegistryInterface public contractRegistry;

	function LTVDecisionEngine(address _contractRegistry) public {
        contractRegistry = ContractRegistryInterface(_contractRegistry);
    }

	function evaluateConsent(Params params, bytes32 commitmentHash)
		public view returns (bool)
	{
		 
		if (!isValidSignature(
			params.creditor,
			commitmentHash,
			params.creditorCommitment.signature
		)) {
			 
			return false;
		}

		 
		return (
			verifyPrices(
				params.creditorCommitment.values.priceFeedOperator,
				params.principalPrice,
				params.collateralPrice
			)
		);
	}

	 
	function evaluateDecision(Params memory params)
		public view returns (bool _success)
	{
		LTVDecisionEngineTypes.Price memory principalTokenPrice = params.principalPrice;
		LTVDecisionEngineTypes.Price memory collateralTokenPrice = params.collateralPrice;

		uint maxLTV = params.creditorCommitment.values.maxLTV;
		OrderLibrary.DebtOrder memory order = params.order;

		uint collateralValue = collateralTokenPrice.value;

		if (isExpired(order.expirationTimestampInSec)) {
			return false;
		}

		if (order.collateralAmount == 0 || collateralValue == 0) {
			return false;
		}

		uint ltv = computeLTV(
			principalTokenPrice.value,
			collateralTokenPrice.value,
			order.principalAmount,
			order.collateralAmount
		);

		uint maxLTVWithPrecision = maxLTV.mul(10 ** (PRECISION.sub(2)));

		return ltv <= maxLTVWithPrecision;
	}

	function hashCreditorCommitmentForOrder(CommitmentValues commitmentValues, OrderLibrary.DebtOrder order)
	public view returns (bytes32)
	{
		bytes32 termsContractCommitmentHash =
			getTermsContractCommitmentHash(order.termsContract, order.termsContractParameters);

		return keccak256(
			 
			order.creditor,
			order.kernelVersion,
			order.issuanceVersion,
			order.termsContract,
			order.principalToken,
			order.salt,
			order.principalAmount,
			order.creditorFee,
			order.expirationTimestampInSec,
			 
			commitmentValues.maxLTV,
			commitmentValues.priceFeedOperator,
			 
			termsContractCommitmentHash
		);
	}

	function getTermsContractCommitmentHash(
		address termsContract,
		bytes32 termsContractParameters
	) public view returns (bytes32) {
		SimpleInterestParameters memory simpleInterestParameters =
			unpackSimpleInterestParameters(termsContract, termsContractParameters);

		CollateralParameters memory collateralParameters =
			unpackCollateralParameters(termsContractParameters);

		return keccak256(
			 
			simpleInterestParameters.principalTokenIndex,
			simpleInterestParameters.principalAmount,
			simpleInterestParameters.interestRate,
			simpleInterestParameters.amortizationUnitType,
			simpleInterestParameters.termLengthInAmortizationUnits,
			collateralParameters.collateralTokenIndex,
			collateralParameters.gracePeriodInDays
		);
	}

	function unpackSimpleInterestParameters(
		address termsContract,
		bytes32 termsContractParameters
	)
		public pure returns (SimpleInterestParameters)
	{
		 
		SimpleInterestTermsContractInterface simpleInterestTermsContract = SimpleInterestTermsContractInterface(termsContract);

		var (principalTokenIndex, principalAmount, interestRate, amortizationUnitType, termLengthInAmortizationUnits) =
			simpleInterestTermsContract.unpackParametersFromBytes(termsContractParameters);

		return SimpleInterestParameters({
			principalTokenIndex: principalTokenIndex,
			principalAmount: principalAmount,
			interestRate: interestRate,
			amortizationUnitType: amortizationUnitType,
			termLengthInAmortizationUnits: termLengthInAmortizationUnits
		});
	}

	function unpackCollateralParameters(
		bytes32 termsContractParameters
	)
		public view returns (CollateralParameters)
	{
		CollateralizerInterface collateralizer = CollateralizerInterface(contractRegistry.collateralizer());

		var (collateralTokenIndex, collateralAmount, gracePeriodInDays) =
			collateralizer.unpackCollateralParametersFromBytes(termsContractParameters);

		return CollateralParameters({
			collateralTokenIndex: collateralTokenIndex,
			collateralAmount: collateralAmount,
			gracePeriodInDays: gracePeriodInDays
		});
	}

	function verifyPrices(
		address priceFeedOperator,
		LTVDecisionEngineTypes.Price principalPrice,
		LTVDecisionEngineTypes.Price collateralPrice
	)
		internal view returns (bool)
	{
		uint minPriceTimestamp = block.timestamp - MAX_PRICE_TTL_IN_SECONDS;

		if (principalPrice.timestamp < minPriceTimestamp ||
			collateralPrice.timestamp < minPriceTimestamp) {
			return false;
		}

		bytes32 principalPriceHash = keccak256(
			principalPrice.value,
			principalPrice.tokenAddress,
			principalPrice.timestamp
		);

		bytes32 collateralPriceHash = keccak256(
			collateralPrice.value,
			collateralPrice.tokenAddress,
			collateralPrice.timestamp
		);

		bool principalPriceValid = isValidSignature(
			priceFeedOperator,
			principalPriceHash,
			principalPrice.signature
		);

		 
		if (!principalPriceValid) {
			return false;
		}

		return isValidSignature(
			priceFeedOperator,
			collateralPriceHash,
			collateralPrice.signature
		);
	}

	function computeLTV(
		uint principalTokenPrice,
		uint collateralTokenPrice,
		uint principalAmount,
		uint collateralAmount
	)
		internal constant returns (uint)
	{
		uint principalValue = principalTokenPrice.mul(principalAmount).mul(10 ** PRECISION);
		uint collateralValue = collateralTokenPrice.mul(collateralAmount);

		return principalValue.div(collateralValue);
	}

	function isExpired(uint expirationTimestampInSec)
		internal view returns (bool expired)
	{
		return expirationTimestampInSec < block.timestamp;
	}
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract CreditorProxyErrors {
    enum Errors {
            DEBT_OFFER_CANCELLED,
            DEBT_OFFER_ALREADY_FILLED,
            DEBT_OFFER_NON_CONSENSUAL,
            CREDITOR_BALANCE_OR_ALLOWANCE_INSUFFICIENT,
            DEBT_OFFER_CRITERIA_NOT_MET
        }

    event CreditorProxyError(
        uint8 indexed _errorId,
        address indexed _creditor,
        bytes32 indexed _creditorCommitmentHash
    );
}

 



contract CreditorProxyEvents {

    event DebtOfferCancelled(
        address indexed _creditor,
        bytes32 indexed _creditorCommitmentHash
    );

    event DebtOfferFilled(
        address indexed _creditor,
        bytes32 indexed _creditorCommitmentHash,
        bytes32 indexed _agreementId
    );
}

 






contract CreditorProxyCoreInterface is CreditorProxyErrors, CreditorProxyEvents { }

 



 

 

 



contract CreditorProxyCore is CreditorProxyCoreInterface {

	uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 8000;

	ContractRegistryInterface public contractRegistry;

	 
	function transferTokensFrom(
		address _token,
		address _from,
		address _to,
		uint _amount
	)
		internal
		returns (bool _success)
	{
		return ERC20(_token).transferFrom(_from, _to, _amount);
	}

	 
	function getAllowance(
		address token,
		address owner,
		address granter
	)
		internal
		view
	returns (uint _allowance)
	{
		 
		return ERC20(token).allowance.gas(EXTERNAL_QUERY_GAS_LIMIT)(
			owner,
			granter
		);
	}
}

 



 

 




contract LTVCreditorProxy is CreditorProxyCore, LTVDecisionEngine {

	mapping (bytes32 => bool) public debtOfferCancelled;
	mapping (bytes32 => bool) public debtOfferFilled;

	bytes32 constant internal NULL_ISSUANCE_HASH = bytes32(0);

	function LTVCreditorProxy(address _contractRegistry) LTVDecisionEngine(_contractRegistry)
		public
	{
		contractRegistry = ContractRegistryInterface(_contractRegistry);
	}

	function fillDebtOffer(LTVDecisionEngineTypes.Params params)
		public returns (bytes32 agreementId)
	{
		OrderLibrary.DebtOrder memory order = params.order;
		CommitmentValues memory commitmentValues = params.creditorCommitment.values;

		bytes32 creditorCommitmentHash = hashCreditorCommitmentForOrder(commitmentValues, order);

		if (!evaluateConsent(params, creditorCommitmentHash)) {
			emit CreditorProxyError(uint8(Errors.DEBT_OFFER_NON_CONSENSUAL), order.creditor, creditorCommitmentHash);
			return NULL_ISSUANCE_HASH;
		}

		if (debtOfferFilled[creditorCommitmentHash]) {
			emit CreditorProxyError(uint8(Errors.DEBT_OFFER_ALREADY_FILLED), order.creditor, creditorCommitmentHash);
			return NULL_ISSUANCE_HASH;
		}

		if (debtOfferCancelled[creditorCommitmentHash]) {
			emit CreditorProxyError(uint8(Errors.DEBT_OFFER_CANCELLED), order.creditor, creditorCommitmentHash);
			return NULL_ISSUANCE_HASH;
		}

		if (!evaluateDecision(params)) {
			emit CreditorProxyError(
				uint8(Errors.DEBT_OFFER_CRITERIA_NOT_MET),
				order.creditor,
				creditorCommitmentHash
			);
			return NULL_ISSUANCE_HASH;
		}

		address principalToken = order.principalToken;

		 
		uint tokenTransferAllowance = getAllowance(
			principalToken,
			address(this),
			contractRegistry.tokenTransferProxy()
		);

		uint totalCreditorPayment = order.principalAmount.add(order.creditorFee);

		 
		if (tokenTransferAllowance < totalCreditorPayment) {
			require(setTokenTransferAllowance(principalToken, totalCreditorPayment));
		}

		 
		if (totalCreditorPayment > 0) {
			require(
				transferTokensFrom(
					principalToken,
					order.creditor,
					address(this),
					totalCreditorPayment
				)
			);
		}

		agreementId = sendOrderToKernel(order);

		require(agreementId != NULL_ISSUANCE_HASH);

		debtOfferFilled[creditorCommitmentHash] = true;

		contractRegistry.debtToken().transfer(order.creditor, uint256(agreementId));

		emit DebtOfferFilled(order.creditor, creditorCommitmentHash, agreementId);

		return agreementId;
	}

	function sendOrderToKernel(DebtOrder memory order) internal returns (bytes32 id)
	{
		address[6] memory orderAddresses;
		uint[8] memory orderValues;
		bytes32[1] memory orderBytes32;
		uint8[3] memory signaturesV;
		bytes32[3] memory signaturesR;
		bytes32[3] memory signaturesS;

		(orderAddresses, orderValues, orderBytes32, signaturesV, signaturesR, signaturesS) = unpackDebtOrder(order);

		return contractRegistry.debtKernel().fillDebtOrder(
			address(this),
			orderAddresses,
			orderValues,
			orderBytes32,
			signaturesV,
			signaturesR,
			signaturesS
		);
	}

	function cancelDebtOffer(LTVDecisionEngineTypes.Params params) public returns (bool) {
		LTVDecisionEngineTypes.CommitmentValues memory commitmentValues = params.creditorCommitment.values;
		OrderLibrary.DebtOrder memory order = params.order;

		 
		require(msg.sender == order.creditor);

		bytes32 creditorCommitmentHash = hashCreditorCommitmentForOrder(commitmentValues, order);

		 
		require(!debtOfferFilled[creditorCommitmentHash]);

		debtOfferCancelled[creditorCommitmentHash] = true;

		emit DebtOfferCancelled(order.creditor, creditorCommitmentHash);

		return true;
	}

	 
	function setTokenTransferAllowance(
		address token,
		uint amount
	)
		internal
		returns (bool _success)
	{
		return ERC20(token).approve(
			address(contractRegistry.tokenTransferProxy()),
			amount
		);
	}
}