 

pragma solidity ^0.4.24;

interface ERC20 {
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	function name() external view returns (string);
	function symbol() external view returns (string);
	function decimals() external view returns (uint8);
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _to, uint256 _value) external payable returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) external payable returns (bool success);
	function approve(address _spender, uint256 _value) external payable returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

 
library SafeMath {
	
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
	
	function sub(uint256 a, uint256 b) pure internal returns (uint256 c) {
		assert(b <= a);
		return a - b;
	}
	
	function mul(uint256 a, uint256 b) pure internal returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) pure internal returns (uint256 c) {
		return a / b;
	}
}

 
contract ERC20Sale {
	using SafeMath for uint256;
	
	 
	event Bid(uint256 bidId);
	event ChangeBidId(uint256 indexed originBidId, uint256 newBidId);
	event RemoveBid(uint256 indexed bidId);
	event CancelBid(uint256 indexed bidId);
	event Sell(uint256 indexed bidId, uint256 amount);
	
	event Offer(uint256 offerId);
	event ChangeOfferId(uint256 indexed originOfferId, uint256 newOfferId);
	event RemoveOffer(uint256 indexed offerId);
	event CancelOffer(uint256 indexed offerId);
	event Buy(uint256 indexed offerId, uint256 amount);
	
	 
	struct BidInfo {
		address bidder;
		address token;
		uint256 amount;
		uint256 price;
	}
	
	 
	struct OfferInfo {
		address offeror;
		address token;
		uint256 amount;
		uint256 price;
	}
	
	 
	BidInfo[] public bidInfos;
	OfferInfo[] public offerInfos;
	
	function getBidCount() view public returns (uint256) {
		return bidInfos.length;
	}
	
	function getOfferCount() view public returns (uint256) {
		return offerInfos.length;
	}
	
	 
	function bid(address token, uint256 amount) payable public {
		
		 
		uint256 bidId = bidInfos.push(BidInfo({
			bidder : msg.sender,
			token : token,
			amount : amount,
			price : msg.value
		})).sub(1);
		
		emit Bid(bidId);
	}
	
	 
	function removeBid(uint256 bidId) internal {
		
		for (uint256 i = bidId; i < bidInfos.length - 1; i += 1) {
			bidInfos[i] = bidInfos[i + 1];
			
			emit ChangeBidId(i + 1, i);
		}
		
		delete bidInfos[bidInfos.length - 1];
		bidInfos.length -= 1;
		
		emit RemoveBid(bidId);
	}
	
	 
	function cancelBid(uint256 bidId) public {
		
		BidInfo memory bidInfo = bidInfos[bidId];
		
		 
		require(bidInfo.bidder == msg.sender);
		
		 
		removeBid(bidId);
		
		 
		bidInfo.bidder.transfer(bidInfo.price);
		
		emit CancelBid(bidId);
	}
	
	 
	function sell(uint256 bidId, uint256 amount) public {
		
		BidInfo storage bidInfo = bidInfos[bidId];
		ERC20 erc20 = ERC20(bidInfo.token);
		
		 
		require(erc20.balanceOf(msg.sender) >= amount);
		
		 
		require(erc20.allowance(msg.sender, this) >= amount);
		
		 
		require(bidInfo.amount >= amount);
		
		uint256 realPrice = amount.mul(bidInfo.price).div(bidInfo.amount);
		
		 
		require(realPrice.mul(bidInfo.amount) == amount.mul(bidInfo.price));
		
		 
		erc20.transferFrom(msg.sender, bidInfo.bidder, amount);
		
		 
		bidInfo.price = bidInfo.price.sub(realPrice);
		
		 
		bidInfo.amount = bidInfo.amount.sub(amount);
		
		 
		if (bidInfo.amount == 0) {
			removeBid(bidId);
		}
		
		 
		msg.sender.transfer(realPrice);
		
		emit Sell(bidId, amount);
	}
	
	 
	function getBidCountByToken(address token) view public returns (uint256) {
		
		uint256 bidCount = 0;
		
		for (uint256 i = 0; i < bidInfos.length; i += 1) {
			if (bidInfos[i].token == token) {
				bidCount += 1;
			}
		}
		
		return bidCount;
	}
	
	 
	function getBidIdsByToken(address token) view public returns (uint256[]) {
		
		uint256[] memory bidIds = new uint256[](getBidCountByToken(token));
		
		for (uint256 i = 0; i < bidInfos.length; i += 1) {
			if (bidInfos[i].token == token) {
				bidIds[bidIds.length - 1] = i;
			}
		}
		
		return bidIds;
	}

	 
	function offer(address token, uint256 amount, uint256 price) public {
		ERC20 erc20 = ERC20(token);
		
		 
		require(erc20.balanceOf(msg.sender) >= amount);
		
		 
		require(erc20.allowance(msg.sender, this) >= amount);
		
		 
		uint256 offerId = offerInfos.push(OfferInfo({
			offeror : msg.sender,
			token : token,
			amount : amount,
			price : price
		})).sub(1);
		
		emit Offer(offerId);
	}
	
	 
	function removeOffer(uint256 offerId) internal {
		
		for (uint256 i = offerId; i < offerInfos.length - 1; i += 1) {
			offerInfos[i] = offerInfos[i + 1];
			
			emit ChangeOfferId(i + 1, i);
		}
		
		delete offerInfos[offerInfos.length - 1];
		offerInfos.length -= 1;
		
		emit RemoveOffer(offerId);
	}
	
	 
	function cancelOffer(uint256 offerId) public {
		
		 
		require(offerInfos[offerId].offeror == msg.sender);
		
		 
		removeOffer(offerId);
		
		emit CancelOffer(offerId);
	}
	
	 
	function buy(uint256 offerId, uint256 amount) payable public {
		
		OfferInfo storage offerInfo = offerInfos[offerId];
		ERC20 erc20 = ERC20(offerInfo.token);
		
		 
		require(erc20.balanceOf(offerInfo.offeror) >= amount);
		
		 
		require(erc20.allowance(offerInfo.offeror, this) >= amount);
		
		 
		require(offerInfo.amount >= amount);
		
		 
		require(offerInfo.price.mul(amount) == msg.value.mul(offerInfo.amount));
		
		 
		erc20.transferFrom(offerInfo.offeror, msg.sender, amount);
		
		 
		offerInfo.price = offerInfo.price.sub(msg.value);
		
		 
		offerInfo.amount = offerInfo.amount.sub(amount);
		
		 
		if (offerInfo.amount == 0) {
			removeOffer(offerId);
		}
		
		 
		offerInfo.offeror.transfer(msg.value);
		
		emit Buy(offerId, amount);
	}
	
	 
	function getOfferCountByToken(address token) view public returns (uint256) {
		
		uint256 offerCount = 0;
		
		for (uint256 i = 0; i < offerInfos.length; i += 1) {
			if (offerInfos[i].token == token) {
				offerCount += 1;
			}
		}
		
		return offerCount;
	}
	
	 
	function getOfferIdsByToken(address token) view public returns (uint256[]) {
		
		uint256[] memory offerIds = new uint256[](getOfferCountByToken(token));
		
		for (uint256 i = 0; i < offerInfos.length; i += 1) {
			if (offerInfos[i].token == token) {
				offerIds[offerIds.length - 1] = i;
			}
		}
		
		return offerIds;
	}
}