 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;
pragma experimental "v0.5.0";

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

}

 
library SafeMathFixedPoint {
	using SafeMath for uint256;

	function mul27(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(y).add(5 * 10**26).div(10**27);
	}
	function mul18(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(y).add(5 * 10**17).div(10**18);
	}

	function div18(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(10**18).add(y.div(2)).div(y);
	}
	function div27(uint256 x, uint256 y) internal pure returns (uint256 z) {
		z = x.mul(10**27).add(y.div(2)).div(y);
	}
}

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
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

 
contract Ownable {
	address public owner;

	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	 
	constructor() public {
		owner = msg.sender;
	}

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	 
	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	}
}

 
contract Claimable is Ownable {
	address public pendingOwner;

	 
	modifier onlyPendingOwner() {
		require(msg.sender == pendingOwner);
		_;
	}

	 
	function transferOwnership(address newOwner) onlyOwner public {
		pendingOwner = newOwner;
	}

	 
	function claimOwnership() onlyPendingOwner public {
		emit OwnershipTransferred(owner, pendingOwner);
		owner = pendingOwner;
		pendingOwner = address(0);
	}
}

 
contract Pausable is Ownable {
	event Pause();
	event Unpause();

	bool public paused = false;


	 
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	 
	modifier whenPaused() {
		require(paused);
		_;
	}

	 
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}

	 
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

 
contract PullPayment {
	using SafeMath for uint256;

	mapping(address => uint256) public payments;
	uint256 public totalPayments;

	 
	function withdrawPayments() public {
		address payee = msg.sender;
		uint256 payment = payments[payee];

		require(payment != 0);
		require(address(this).balance >= payment);

		totalPayments = totalPayments.sub(payment);
		payments[payee] = 0;

		payee.transfer(payment);
	}

	 
	function asyncSend(address dest, uint256 amount) internal {
		payments[dest] = payments[dest].add(amount);
		totalPayments = totalPayments.add(amount);
	}
}

contract Dai is ERC20 {

}

contract Weth is ERC20 {
	function deposit() public payable;
	function withdraw(uint wad) public;
}

contract Mkr is ERC20 {

}

contract Peth is ERC20 {

}

contract Oasis {
	function getBuyAmount(ERC20 tokenToBuy, ERC20 tokenToPay, uint256 amountToPay) external view returns(uint256 amountBought);
	function getPayAmount(ERC20 tokenToPay, ERC20 tokenToBuy, uint amountToBuy) public constant returns (uint amountPaid);
	function getBestOffer(ERC20 sell_gem, ERC20 buy_gem) public constant returns(uint offerId);
	function getWorseOffer(uint id) public constant returns(uint offerId);
	function getOffer(uint id) public constant returns (uint pay_amt, ERC20 pay_gem, uint buy_amt, ERC20 buy_gem);
	function sellAllAmount(ERC20 pay_gem, uint pay_amt, ERC20 buy_gem, uint min_fill_amount) public returns (uint fill_amt);
}

contract Medianizer {
	function read() external view returns(bytes32);
}

contract Maker {
	function sai() external view returns(Dai);
	function gem() external view returns(Weth);
	function gov() external view returns(Mkr);
	function skr() external view returns(Peth);
	function pip() external view returns(Medianizer);

	 
	 uint256 public gap;

	struct Cup {
		 
		address lad;
		 
		uint256 ink;
		 
		uint256 art;
		 
		uint256 ire;
	}

	uint256 public cupi;
	mapping (bytes32 => Cup) public cups;

	function lad(bytes32 cup) public view returns (address);
	function per() public view returns (uint ray);
	function tab(bytes32 cup) public returns (uint);
	function ink(bytes32 cup) public returns (uint);
	function rap(bytes32 cup) public returns (uint);
	function chi() public returns (uint);

	function open() public returns (bytes32 cup);
	function give(bytes32 cup, address guy) public;
	function lock(bytes32 cup, uint wad) public;
	function draw(bytes32 cup, uint wad) public;
	function join(uint wad) public;
	function wipe(bytes32 cup, uint wad) public;
}

contract LiquidLong is Ownable, Claimable, Pausable, PullPayment {
	using SafeMath for uint256;
	using SafeMathFixedPoint for uint256;

	uint256 public providerFeePerEth;

	Oasis public oasis;
	Maker public maker;
	Dai public dai;
	Weth public weth;
	Peth public peth;
	Mkr public mkr;

	event NewCup(address user, bytes32 cup);

	constructor(Oasis _oasis, Maker _maker) public payable {
		providerFeePerEth = 0.01 ether;

		oasis = _oasis;
		maker = _maker;
		dai = maker.sai();
		weth = maker.gem();
		peth = maker.skr();
		mkr = maker.gov();

		 
		dai.approve(address(_oasis), uint256(-1));
		 
		dai.approve(address(_maker), uint256(-1));
		mkr.approve(address(_maker), uint256(-1));
		 
		weth.approve(address(_maker), uint256(-1));
		 
		peth.approve(address(_maker), uint256(-1));

		if (msg.value > 0) {
			weth.deposit.value(msg.value)();
		}
	}

	 
	function () external payable {
	}

	function wethDeposit() public payable {
		weth.deposit.value(msg.value)();
	}

	function wethWithdraw(uint256 _amount) public onlyOwner {
		weth.withdraw(_amount);
		owner.transfer(_amount);
	}

	function ethWithdraw() public onlyOwner {
		 
		uint256 _amount = address(this).balance.sub(totalPayments);
		owner.transfer(_amount);
	}

	 
	function transferTokens(ERC20 _token) public onlyOwner {
		_token.transfer(owner, _token.balanceOf(this));
	}

	function ethPriceInUsd() public view returns (uint256 _attousd) {
		return uint256(maker.pip().read());
	}

	function estimateDaiSaleProceeds(uint256 _attodaiToSell) public view returns (uint256 _daiPaid, uint256 _wethBought) {
		return getPayPriceAndAmount(dai, weth, _attodaiToSell);
	}

	 
	function getPayPriceAndAmount(ERC20 _payGem, ERC20 _buyGem, uint256 _payDesiredAmount) public view returns (uint256 _paidAmount, uint256 _boughtAmount) {
		uint256 _offerId = oasis.getBestOffer(_buyGem, _payGem);
		while (_offerId != 0) {
			uint256 _payRemaining = _payDesiredAmount.sub(_paidAmount);
			(uint256 _buyAvailableInOffer, , uint256 _payAvailableInOffer,) = oasis.getOffer(_offerId);
			if (_payRemaining <= _payAvailableInOffer) {
				uint256 _buyRemaining = _payRemaining.mul(_buyAvailableInOffer).div(_payAvailableInOffer);
				_paidAmount = _paidAmount.add(_payRemaining);
				_boughtAmount = _boughtAmount.add(_buyRemaining);
				break;
			}
			_paidAmount = _paidAmount.add(_payAvailableInOffer);
			_boughtAmount = _boughtAmount.add(_buyAvailableInOffer);
			_offerId = oasis.getWorseOffer(_offerId);
		}
		return (_paidAmount, _boughtAmount);
	}

	function openCdp(uint256 _leverage, uint256 _leverageSizeInAttoeth, uint256 _allowedFeeInAttoeth, uint256 _affiliateFeeInAttoeth, address _affiliateAddress) public payable returns (bytes32 _cdpId) {
		require(_leverage >= 100 && _leverage <= 300);
		uint256 _lockedInCdpInAttoeth = _leverageSizeInAttoeth.mul(_leverage).div(100);
		uint256 _loanInAttoeth = _lockedInCdpInAttoeth.sub(_leverageSizeInAttoeth);
		uint256 _providerFeeInAttoeth = _loanInAttoeth.mul18(providerFeePerEth);
		require(_providerFeeInAttoeth <= _allowedFeeInAttoeth);
		uint256 _drawInAttodai = _loanInAttoeth.mul18(uint256(maker.pip().read()));
		uint256 _pethLockedInCdp = _lockedInCdpInAttoeth.div27(maker.per());

		 
		weth.deposit.value(_leverageSizeInAttoeth)();
		 
		_cdpId = maker.open();
		 
		maker.join(_pethLockedInCdp);
		 
		maker.lock(_cdpId, _pethLockedInCdp);
		 
		maker.draw(_cdpId, _drawInAttodai);

		 
		uint256 _wethBoughtInAttoweth = oasis.sellAllAmount(dai, _drawInAttodai, weth, 0);
		 
		uint256 _refundDue = msg.value.add(_wethBoughtInAttoweth).sub(_lockedInCdpInAttoeth).sub(_providerFeeInAttoeth).sub(_affiliateFeeInAttoeth);

		if (_loanInAttoeth > _wethBoughtInAttoweth) {
			weth.deposit.value(_loanInAttoeth - _wethBoughtInAttoweth)();
		}

		if (_providerFeeInAttoeth != 0) {
			asyncSend(owner, _providerFeeInAttoeth);
		}
		if (_affiliateFeeInAttoeth != 0) {
			asyncSend(_affiliateAddress, _affiliateFeeInAttoeth);
		}

		emit NewCup(msg.sender, _cdpId);
		 
		maker.give(_cdpId, msg.sender);

		if (_refundDue > 0) {
			require(msg.sender.call.value(_refundDue)());
		}
	}
}