 

pragma solidity ^0.4.18;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Drainable is Ownable {
	function withdrawToken(address tokenaddr) 
		onlyOwner
		public
	{
		ERC20 token = ERC20(tokenaddr);
		uint bal = token.balanceOf(address(this));
		token.transfer(msg.sender, bal);
	}

	function withdrawEther() 
		onlyOwner
		public
	{
	    require(msg.sender.send(this.balance));
	}
}

contract ADXExchangeInterface {
	 
	event LogBidAccepted(bytes32 bidId, address advertiser, bytes32 adunit, address publisher, bytes32 adslot, uint acceptedTime);
	event LogBidCanceled(bytes32 bidId);
	event LogBidExpired(bytes32 bidId);
	event LogBidConfirmed(bytes32 bidId, address advertiserOrPublisher, bytes32 report);
	event LogBidCompleted(bytes32 bidId, bytes32 advReport, bytes32 pubReport);

	function acceptBid(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _rewardAmount, uint _timeout, bytes32 _adslot, uint8 v, bytes32 r, bytes32 s, uint8 sigMode) public;
	function cancelBid(bytes32 _adunit, uint _opened, uint _target, uint _rewardAmount, uint _timeout, uint8 v, bytes32 r, bytes32 s, uint8 sigMode) public;
	function giveupBid(bytes32 _bidId) public;
	function refundBid(bytes32 _bidId) public;
	function verifyBid(bytes32 _bidId, bytes32 _report) public;

	function deposit(uint _amount) public;
	function withdraw(uint _amount) public;

	 
	function getBid(bytes32 _bidId) 
		constant external 
		returns (
			uint, uint, uint, uint, uint, 
			 
			address, bytes32, bytes32,
			 
			address, bytes32, bytes32
		);

	function getBalance(address _user)
		constant
		external
		returns (uint, uint);

	function getBidID(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout)
		constant
		public
		returns (bytes32);
}


contract ADXExchange is ADXExchangeInterface, Drainable {
	string public name = "AdEx Exchange";

	ERC20 public token;

	uint public maxTimeout = 365 days;

 	mapping (address => uint) balances;

 	 
 	mapping (address => uint) onBids; 

 	 
	mapping (bytes32 => Bid) bids;
	mapping (bytes32 => BidState) bidStates;


	enum BidState { 
		DoesNotExist,  

		 
		Accepted,  

		 
		 
		Canceled,
		Expired,

		 
		Completed
	}

	struct Bid {
		 
		address advertiser;
		bytes32 adUnit;

		 
		address publisher;
		bytes32 adSlot;

		 
		uint acceptedTime;

		 
		uint amount;

		 
		uint target;  
		uint timeout;  

		 
		bytes32 publisherConfirmation;
		bytes32 advertiserConfirmation;
	}

	 
	 
	bytes32 constant public SCHEMA_HASH = keccak256(
		"address Advertiser",
		"bytes32 Ad Unit ID",
		"uint Opened",
		"uint Target",
		"uint Amount",
		"uint Timeout",
		"address Exchange"
	);

	 
	 
	 
	modifier onlyBidAdvertiser(bytes32 _bidId) {
		require(msg.sender == bids[_bidId].advertiser);
		_;
	}

	modifier onlyBidPublisher(bytes32 _bidId) {
		require(msg.sender == bids[_bidId].publisher);
		_;
	}

	modifier onlyBidState(bytes32 _bidId, BidState _state) {
		require(bidStates[_bidId] == _state);
		_;
	}

	 

	function ADXExchange(address _token)
		public
	{
		token = ERC20(_token);
	}

	 
	 
	 

	 
	function acceptBid(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout, bytes32 _adslot, uint8 v, bytes32 r, bytes32 s, uint8 sigMode)
		public
	{
		require(_amount > 0);

		 
		 
		require(_amount <= (balances[_advertiser] - onBids[_advertiser]));

		 
		bytes32 bidId = getBidID(_advertiser, _adunit, _opened, _target, _amount, _timeout);

		require(bidStates[bidId] == BidState.DoesNotExist);

		require(didSign(_advertiser, bidId, v, r, s, sigMode));
		
		 
		require(_advertiser != msg.sender);

		Bid storage bid = bids[bidId];

		bid.target = _target;
		bid.amount = _amount;

		 
		bid.timeout = _timeout > 0 ? _timeout : maxTimeout;
		require(bid.timeout <= maxTimeout);

		bid.advertiser = _advertiser;
		bid.adUnit = _adunit;

		bid.publisher = msg.sender;
		bid.adSlot = _adslot;

		bid.acceptedTime = now;

		bidStates[bidId] = BidState.Accepted;

		onBids[_advertiser] += _amount;

		 
		 

		LogBidAccepted(bidId, _advertiser, _adunit, msg.sender, _adslot, bid.acceptedTime);
	}

	 
	function cancelBid(bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout, uint8 v, bytes32 r, bytes32 s, uint8 sigMode)
		public
	{
		 
		bytes32 bidId = getBidID(msg.sender, _adunit, _opened, _target, _amount, _timeout);

		require(bidStates[bidId] == BidState.DoesNotExist);

		require(didSign(msg.sender, bidId, v, r, s, sigMode));

		bidStates[bidId] = BidState.Canceled;

		LogBidCanceled(bidId);
	}

	 
	function giveupBid(bytes32 _bidId)
		public
		onlyBidPublisher(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

		bidStates[_bidId] = BidState.Canceled;

		onBids[bid.advertiser] -= bid.amount;
	
		LogBidCanceled(_bidId);
	}


	 
	 
	function refundBid(bytes32 _bidId)
		public
		onlyBidAdvertiser(_bidId)
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

 		 
		require(now > SafeMath.add(bid.acceptedTime, bid.timeout));

		bidStates[_bidId] = BidState.Expired;

		onBids[bid.advertiser] -= bid.amount;

		LogBidExpired(_bidId);
	}


	 
	function verifyBid(bytes32 _bidId, bytes32 _report)
		public
		onlyBidState(_bidId, BidState.Accepted)
	{
		Bid storage bid = bids[_bidId];

		require(_report != 0);
		require(bid.publisher == msg.sender || bid.advertiser == msg.sender);

		if (bid.publisher == msg.sender) {
			require(bid.publisherConfirmation == 0);
			bid.publisherConfirmation = _report;
		}

		if (bid.advertiser == msg.sender) {
			require(bid.advertiserConfirmation == 0);
			bid.advertiserConfirmation = _report;
		}

		LogBidConfirmed(_bidId, msg.sender, _report);

		if (bid.advertiserConfirmation != 0 && bid.publisherConfirmation != 0) {
			bidStates[_bidId] = BidState.Completed;

			onBids[bid.advertiser] = SafeMath.sub(onBids[bid.advertiser], bid.amount);
			balances[bid.advertiser] = SafeMath.sub(balances[bid.advertiser], bid.amount);
			balances[bid.publisher] = SafeMath.add(balances[bid.publisher], bid.amount);

			LogBidCompleted(_bidId, bid.advertiserConfirmation, bid.publisherConfirmation);
		}
	}

	 
	function deposit(uint _amount)
		public
	{
		balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);
		require(token.transferFrom(msg.sender, address(this), _amount));
	}

	function withdraw(uint _amount)
		public
	{
		uint available = SafeMath.sub(balances[msg.sender], onBids[msg.sender]);
		require(_amount <= available);

		balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
		require(token.transfer(msg.sender, _amount));
	}

	function didSign(address addr, bytes32 hash, uint8 v, bytes32 r, bytes32 s, uint8 mode)
		public
		pure
		returns (bool)
	{
		bytes32 message = hash;
		
		if (mode == 1) {
			 
			message = keccak256("\x19Ethereum Signed Message:\n32", hash);
		} else if (mode == 2) {
			 
			message = keccak256("\x19Ethereum Signed Message:\n\x20", hash);
		}

		return ecrecover(message, v, r, s) == addr;
	}

	 
	 
	 
	function getBid(bytes32 _bidId) 
		constant
		external
		returns (
			uint, uint, uint, uint, uint, 
			 
			address, bytes32, bytes32,
			 
			address, bytes32, bytes32
		)
	{
		Bid storage bid = bids[_bidId];
		return (
			uint(bidStates[_bidId]), bid.target, bid.timeout, bid.amount, bid.acceptedTime,
			bid.advertiser, bid.adUnit, bid.advertiserConfirmation,
			bid.publisher, bid.adSlot, bid.publisherConfirmation
		);
	}

	function getBalance(address _user)
		constant
		external
		returns (uint, uint)
	{
		return (balances[_user], onBids[_user]);
	}

	function getBidID(address _advertiser, bytes32 _adunit, uint _opened, uint _target, uint _amount, uint _timeout)
		constant
		public
		returns (bytes32)
	{
		return keccak256(
			SCHEMA_HASH,
			keccak256(_advertiser, _adunit, _opened, _target, _amount, _timeout, this)
		);
	}
}