 

pragma solidity ^0.4.15;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Finalizable is Ownable {

	bool public isFinalized = false;

	event Finalized();

	function finalize() onlyOwner public {
		require (!isFinalized);
		 

		finalization();
		Finalized();

		isFinalized = true ;
	}

	function finalization() internal {

	}
}

contract TopiaCoinSAFTSale is Ownable, Finalizable {

	event PaymentExpected(bytes8 paymentIdentifier);  
	event PaymentExpectationCancelled(bytes8 paymentIdentifier);  
	event PaymentSubmitted(address payor, bytes8 paymentIdentifier, uint256 paymentAmount);  
	event PaymentAccepted(address payor, bytes8 paymentIdentifier, uint256 paymentAmount);  
	event PaymentRejected(address payor, bytes8 paymentIdentifier, uint256 paymentAmount);  
	event UnableToAcceptPayment(address payor, bytes8 paymentIdentifier, uint256 paymentAmount);  
	event UnableToRejectPayment(address payor, bytes8 paymentIdentifier, uint256 paymentAmount);  
	
	event SalesWalletUpdated(address oldWalletAddress, address newWalletAddress);  
	event PaymentManagerUpdated(address oldPaymentManager, address newPaymentManager);  

	event SaleOpen();  
	event SaleClosed();  

	mapping (bytes8 => Payment) payments;
	address salesWallet = 0x0;
	address paymentManager = 0x0;
	bool public saleStarted = false;

	 
	struct Payment {
		address from;
		bytes8 paymentIdentifier;
		bytes32 paymentHash;
		uint256 paymentAmount;
		uint date;
		uint8 status; 
	}

	uint8 PENDING_STATUS = 10;
	uint8 PAID_STATUS = 20;
	uint8 ACCEPTED_STATUS = 22;
	uint8 REJECTED_STATUS = 40;

	modifier onlyOwnerOrManager() {
		require(msg.sender == owner || msg.sender == paymentManager);
		_;
	}

	function TopiaCoinSAFTSale(address _salesWallet, address _paymentManager) 
		Ownable () 
	{
		require (_salesWallet != 0x0);

		salesWallet = _salesWallet;
		paymentManager = _paymentManager;
		saleStarted = false;
	}

	 
	function updateSalesWallet(address _salesWallet) onlyOwner {
		require(_salesWallet != 0x0) ;
		require(_salesWallet != salesWallet);

		address oldWalletAddress = salesWallet ;
		salesWallet = _salesWallet;

		SalesWalletUpdated(oldWalletAddress, _salesWallet);
	}

	 
	function updatePaymentManager(address _paymentManager) onlyOwner {
		require(_paymentManager != 0x0) ;
		require(_paymentManager != paymentManager);

		address oldPaymentManager = paymentManager ;
		paymentManager = _paymentManager;

		PaymentManagerUpdated(oldPaymentManager, _paymentManager);
	}

	 
	function startSale() onlyOwner {
		require (!saleStarted);
		require (!isFinalized);

		saleStarted = true;
		SaleOpen();
	}

	 
	function expectPayment(bytes8 _paymentIdentifier, bytes32 _paymentHash) onlyOwnerOrManager {
		 
		require (saleStarted);
		require (!isFinalized);

		 
		require (_paymentIdentifier != 0x0);

		 
		Payment storage p = payments[_paymentIdentifier];

		require (p.status == 0);
		require (p.from == 0x0);

		p.paymentIdentifier = _paymentIdentifier;
		p.paymentHash = _paymentHash;
		p.date = now;
		p.status = PENDING_STATUS;

		payments[_paymentIdentifier] = p;

		PaymentExpected(_paymentIdentifier);
	}

	 
	function cancelExpectedPayment(bytes8 _paymentIdentifier) onlyOwnerOrManager {
				 
		require (saleStarted);
		require (!isFinalized);

		 
		require (_paymentIdentifier != 0x0);

		 
		Payment storage p = payments[_paymentIdentifier];

		require(p.paymentAmount == 0);
		require(p.status == 0 || p.status == 10);

		p.paymentIdentifier = 0x0;
		p.paymentHash = 0x0;
		p.date = 0;
		p.status = 0;

		payments[_paymentIdentifier] = p;

		PaymentExpectationCancelled(_paymentIdentifier);
	}

	 
	 
	 
	function submitPayment(bytes8 _paymentIdentifier, uint32 nonce) payable {
		require (saleStarted);
		require (!isFinalized);

		 
		require (_paymentIdentifier != 0x0);

		Payment storage p = payments[_paymentIdentifier];

		require (p.status == PENDING_STATUS);
		require (p.from == 0x0);
		require (p.paymentHash != 0x0);
		require (msg.value > 0);

		 
		require (p.paymentHash == calculateHash(_paymentIdentifier, msg.value, nonce)) ;

		bool forwardPayment = (p.status == PENDING_STATUS);
		
		p.from = msg.sender;
		p.paymentIdentifier = _paymentIdentifier;
		p.date = now;
		p.paymentAmount = msg.value;
		p.status = PAID_STATUS;

		payments[_paymentIdentifier] = p;

		PaymentSubmitted (p.from, p.paymentIdentifier, p.paymentAmount);

		if ( forwardPayment ) {
			sendPaymentToWallet (p) ;
		}
	}

	 
	function acceptPayment(bytes8 _paymentIdentifier) onlyOwnerOrManager {
		 
		require (_paymentIdentifier != 0x0);

		Payment storage p = payments[_paymentIdentifier];

		require (p.from != 0x0) ;
		require (p.status == PAID_STATUS);

		sendPaymentToWallet(p);
	}

	 
	function rejectPayment(bytes8 _paymentIdentifier) onlyOwnerOrManager {
		 
		require (_paymentIdentifier != 0x0);

		Payment storage p = payments[_paymentIdentifier] ;

		require (p.from != 0x0) ;
		require (p.status == PAID_STATUS);

		refundPayment(p) ;
	}

	 
	 

	 
	function verifyPayment(bytes8 _paymentIdentifier) constant onlyOwnerOrManager returns (address from, uint256 paymentAmount, uint date, bytes32 paymentHash, uint8 status)  {
		Payment storage payment = payments[_paymentIdentifier];

		return (payment.from, payment.paymentAmount, payment.date, payment.paymentHash, payment.status);
	}

	 
	 
	function kill() onlyOwner {
		selfdestruct(msg.sender);
	}

	 

	 
	function sendPaymentToWallet(Payment _payment) internal {

		if ( salesWallet.send(_payment.paymentAmount) ) {
			_payment.status = ACCEPTED_STATUS;

			payments[_payment.paymentIdentifier] = _payment;

			PaymentAccepted (_payment.from, _payment.paymentIdentifier, _payment.paymentAmount);
		} else {
			UnableToAcceptPayment (_payment.from, _payment.paymentIdentifier, _payment.paymentAmount);
		}
	}

	 
	function refundPayment(Payment _payment) internal {
		if ( _payment.from.send(_payment.paymentAmount)  ) {
			_payment.status = REJECTED_STATUS;

			payments[_payment.paymentIdentifier] = _payment;

			PaymentRejected (_payment.from, _payment.paymentIdentifier, _payment.paymentAmount);
		} else {
			UnableToRejectPayment (_payment.from, _payment.paymentIdentifier, _payment.paymentAmount);
		}
	}

	 
	 
	function calculateHash(bytes8 _paymentIdentifier, uint256 _amount, uint32 _nonce) constant onlyOwnerOrManager returns (bytes32 hash) {
		return sha256(_paymentIdentifier, _amount, _nonce);
	}

	function finalization() internal {
		saleStarted = false;
		SaleClosed();
	}
}