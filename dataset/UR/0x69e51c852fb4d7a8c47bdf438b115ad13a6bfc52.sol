 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;
pragma experimental "v0.5.0";

 
library SafeMath {
	int256 constant private INT256_MIN = -2**255;

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	 
	function mul(int256 a, int256 b) internal pure returns (int256) {
		 
		 
		if (a == 0) {
			return 0;
		}

		require(!(a == -1 && b == INT256_MIN));  

		int256 c = a * b;
		require(c / a == b);

		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		require(b > 0);
		uint256 c = a / b;
		 

		return c;
	}

	 
	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != 0);  
		require(!(b == -1 && a == INT256_MIN));  

		int256 c = a / b;

		return c;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	 
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));

		return c;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	 
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));

		return c;
	}

	 
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
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

contract DSProxy {
	 
	address public owner;

	function execute(address _target, bytes _data) public payable returns (bytes32 response);
}

contract ProxyRegistry {
	mapping(address => DSProxy) public proxies;
	function build(address owner) public returns (DSProxy proxy);
}

contract LiquidLong is Ownable, Claimable, Pausable {
	using SafeMath for uint256;
	using SafeMathFixedPoint for uint256;

	uint256 public providerFeePerEth;

	Oasis public oasis;
	Maker public maker;
	Dai public dai;
	Weth public weth;
	Peth public peth;
	Mkr public mkr;

	ProxyRegistry public proxyRegistry;

	event NewCup(address user, bytes32 cup);

	constructor(Oasis _oasis, Maker _maker, ProxyRegistry _proxyRegistry) public payable {
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

		proxyRegistry = _proxyRegistry;

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

	function attowethBalance() public view returns (uint256 _attoweth) {
		return weth.balanceOf(address(this));
	}

	function ethWithdraw() public onlyOwner {
		uint256 _amount = address(this).balance;
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
			(uint256 _buyAvailableInOffer,  , uint256 _payAvailableInOffer,) = oasis.getOffer(_offerId);
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

	modifier wethBalanceIncreased() {
		uint256 _startingAttowethBalance = weth.balanceOf(this);
		_;
		require(weth.balanceOf(this) > _startingAttowethBalance);
	}

	 
	function openCdp(uint256 _leverage, uint256 _leverageSizeInAttoeth, uint256 _allowedFeeInAttoeth, address _affiliateAddress) public payable wethBalanceIncreased returns (bytes32 _cdpId) {
		require(_leverage >= 100 && _leverage <= 300);
		uint256 _lockedInCdpInAttoeth = _leverageSizeInAttoeth.mul(_leverage).div(100);
		uint256 _loanInAttoeth = _lockedInCdpInAttoeth.sub(_leverageSizeInAttoeth);
		uint256 _feeInAttoeth = _loanInAttoeth.mul18(providerFeePerEth);
		require(_feeInAttoeth <= _allowedFeeInAttoeth);
		uint256 _drawInAttodai = _loanInAttoeth.mul18(uint256(maker.pip().read()));
		uint256 _attopethLockedInCdp = _lockedInCdpInAttoeth.div27(maker.per());

		 
		weth.deposit.value(msg.value)();
		 
		_cdpId = maker.open();
		 
		maker.join(_attopethLockedInCdp);
		 
		maker.lock(_cdpId, _attopethLockedInCdp);
		 
		maker.draw(_cdpId, _drawInAttodai);
		 
		sellDai(_drawInAttodai, _lockedInCdpInAttoeth, _feeInAttoeth);
		 
		if (_affiliateAddress != address(0)) {
			 
			 
			weth.transfer(_affiliateAddress, _feeInAttoeth.div(2));
		}

		emit NewCup(msg.sender, _cdpId);

		giveCdpToProxy(msg.sender, _cdpId);
	}

	function giveCdpToProxy(address _ownerOfProxy, bytes32 _cdpId) private {
		DSProxy _proxy = proxyRegistry.proxies(_ownerOfProxy);
		if (_proxy == DSProxy(0) || _proxy.owner() != _ownerOfProxy) {
			_proxy = proxyRegistry.build(_ownerOfProxy);
		}
		 
		maker.give(_cdpId, _proxy);
	}

	 
	function sellDai(uint256 _drawInAttodai, uint256 _lockedInCdpInAttoeth, uint256 _feeInAttoeth) private {
		uint256 _wethBoughtInAttoweth = oasis.sellAllAmount(dai, _drawInAttodai, weth, 0);
		 
		uint256 _refundDue = msg.value.add(_wethBoughtInAttoweth).sub(_lockedInCdpInAttoeth).sub(_feeInAttoeth);
		if (_refundDue > 0) {
			weth.withdraw(_refundDue);
			require(msg.sender.call.value(_refundDue)());
		}
	}
}