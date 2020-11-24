 

 
 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity 0.5.8;


contract CoveredCall {

	 
	enum ContractStates {
		NONE,
		STATUS_INITIALIZED,  
		STATUS_OPEN,  
		STATUS_REDEEMED,  
		STATUS_CLOSED  
	}

	 
	ContractStates public currentState;

	 
	event PremiumUpdated(address indexed _seller, uint256 _oldPremiumAmount, uint256 _newPremiumAmount);
	event Initialized(address indexed _seller, uint256 _underlyingAssetAmount);
	event Opened(address indexed _buyer, uint256 _purchaseAmount);
	event Redeemed(address indexed _buyer, uint256 _paymentAmount);
	event Closed(address indexed _seller);

	address public buyer;  
	address public seller;  

	IERC20 public underlyingAssetToken;  
	IERC20 public purchasingToken;  

	uint256 public underlyingAssetAmount;  

	uint256 public strikePrice;  
	uint256 public premiumAmount;  

	uint256 public expirationDate;  

	 
	constructor(
		IERC20 _underlyingAssetToken,
		uint256 _underlyingAssetAmount,
		IERC20 _purchasingToken,
		uint256 _strikePrice,
		uint256 _premiumAmount,
		uint _expirationDate
	) public {
		 
		require(address(_underlyingAssetToken) != address(0), "The asset token must not be 0x0");
		require(_underlyingAssetAmount > 0, "The asset amount must be valid");
		require(address(_purchasingToken) != address(0), "The purchasing token must not be 0x0");
		require(_strikePrice > 0, "The strike price must be valid");
		require(_premiumAmount > 0, "The premium amount price must be valid");
		require(_expirationDate > now, "The expiration must be in the future");

		 
		seller = msg.sender;
		underlyingAssetToken = _underlyingAssetToken;
		underlyingAssetAmount = _underlyingAssetAmount;
		purchasingToken = _purchasingToken;
		strikePrice = _strikePrice;
		premiumAmount = _premiumAmount;
		expirationDate = _expirationDate;

		 
		currentState = ContractStates.NONE;
	}

	function initialize() public {
		require(
			currentState == ContractStates.NONE,
			"Contract must be in NONE state to allow initialization"
		);

		require(msg.sender == seller, "Only the original seller can initialize the contract");

		 
		require(underlyingAssetToken.transferFrom(seller, address(this), underlyingAssetAmount), "Must provide initial escrow token");

		 
		currentState = ContractStates.STATUS_INITIALIZED;

		 
		emit Initialized(seller, underlyingAssetAmount);
	}

	 
	function updatePremium(uint256 _premiumAmount) public {
		 
		require(
			currentState == ContractStates.STATUS_INITIALIZED,
			"Contract must be in initialized state to allow updates of the premium"
		);
		require(msg.sender == seller, "Only the original seller can update the premium");

		 
		uint256 oldPremiumAmount = premiumAmount;

		 
		premiumAmount = _premiumAmount;

		 
		emit PremiumUpdated(seller, oldPremiumAmount, premiumAmount);
	}

	 
	function open() public {
		 
		require(now < expirationDate, "Cannot open an expired contract");
		require(currentState == ContractStates.STATUS_INITIALIZED, "Contract must be in initialized state to open");

		 
		buyer = msg.sender;

		 
		require(purchasingToken.transferFrom(buyer, seller, premiumAmount), "Must pay premium to open contract");

		 
		currentState = ContractStates.STATUS_OPEN;

		 
		emit Opened(buyer, premiumAmount);
	}

	 
	function close() public {
		 
		require(
			currentState == ContractStates.STATUS_INITIALIZED ||
				(currentState == ContractStates.STATUS_OPEN && now > expirationDate),
			"Contract must be in initialized state or expired in order to close it"
		);
		require(msg.sender == seller, "Only the original seller can close a contract");

		 
		underlyingAssetToken.transfer(seller, underlyingAssetAmount);

		 
		currentState = ContractStates.STATUS_CLOSED;

		 
		emit Closed(seller);
	}

	 
	function redeem() public {
		 
		require(
			currentState == ContractStates.STATUS_OPEN && now < expirationDate,
			"Contract must be in open state and not expired to redeem it"
		);
		require(msg.sender == buyer, "Only the original buyer can redeem a contract");

		 
		uint256 paymentAmount = underlyingAssetAmount * strikePrice;

		 
		require(purchasingToken.transferFrom(buyer, seller, paymentAmount), "Must pay amount * strike to redeem contract");

		 
		underlyingAssetToken.transfer(buyer, underlyingAssetAmount);

		 
		currentState = ContractStates.STATUS_REDEEMED;

		 
		emit Redeemed(buyer, paymentAmount);
	}

}