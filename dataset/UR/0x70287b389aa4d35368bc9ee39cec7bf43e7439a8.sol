 

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
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
}



contract Erc20 {
    function balanceOf(address _owner) view public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
}

contract CErc20 is Erc20 {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
}

contract Exchange1 {
	function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256);
}

contract Exchange2 {
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) public payable returns (uint256);
}

contract Exchange3 {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId )public payable returns(uint256);
}

contract Exchange4 {
    function sellAllAmountPayEth(address otc, address wethToken, address buyToken, uint minBuyAmt) public payable returns (uint256);
}

contract cDaiGatewayAggregate is Ownable {
	Exchange1 cDaiEx = Exchange1(0x45A2FDfED7F7a2c791fb1bdF6075b83faD821ddE);
	Exchange2 DaiEx2 = Exchange2(0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14);
	Exchange3 DaiEx3 = Exchange3(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    Exchange4 DaiEx4 = Exchange4(0x793EbBe21607e4F04788F89c7a9b97320773Ec59);

    Erc20 dai = Erc20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    CErc20 cDai = CErc20(0xF5DCe57282A584D2746FaF1593d3121Fcac444dC);

    address etherAddr = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

	function () public payable {
		etherTocDai1(msg.sender, owner);
	}

	function etherTocDai1(address to, address ref) public payable returns(uint256 outAmount) {
		uint256 fee = msg.value / 250;
		ref.transfer(fee * 5 / 23);
        return cDaiEx.ethToTokenTransferInput.value(msg.value - fee)(1, now, to);
	}

	function etherTocDai2(address to, address ref) public payable returns(uint256 outAmount) {
		uint256 fee = msg.value * 6 / 1000;
		ref.transfer(fee * 5 / 23);
		uint256 amount = DaiEx2.ethToTokenSwapInput.value(msg.value - fee)(1, now);
        cDai.mint(amount);
        outAmount = cDai.balanceOf(address(this));
        cDai.transfer(to, outAmount);
	}

	function etherTocDai3(address to, address ref) public payable returns(uint256 outAmount) {
		uint256 fee = msg.value * 7 / 1000;
		ref.transfer(fee * 5 / 23);
		uint256 in_eth = msg.value - fee;
        uint256 amount = DaiEx3.trade.value(in_eth)(etherAddr, in_eth, address(dai), address(this), 10**28, 1, owner);
        cDai.mint(amount);
        outAmount = cDai.balanceOf(address(this));
        cDai.transfer(to, outAmount);
	}

	function etherTocDai4(address to, address ref) public payable returns(uint256 outAmount) {
		uint256 fee = msg.value * 7 / 1000;
		ref.transfer(fee * 5 / 23);
		uint256 amount = DaiEx4.sellAllAmountPayEth.value(msg.value - fee)(0x39755357759cE0d7f32dC8dC45414CCa409AE24e,0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359,1);
        cDai.mint(amount);
        outAmount = cDai.balanceOf(address(this));
        cDai.transfer(to, outAmount);
	}

	function set() public {
        dai.approve(address(cDai), uint256(-1));
    }

	function makeprofit() public onlyOwner {
		owner.transfer(address(this).balance);
	}

}