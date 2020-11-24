 

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

contract Exchange {
    function sellAllAmountPayEth(address otc, address wethToken, address buyToken, uint minBuyAmt) public payable returns (uint buyAmt);
}

contract cDaiGateway is Ownable {
    Exchange DaiEx = Exchange(0x793EbBe21607e4F04788F89c7a9b97320773Ec59);

    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 cDai = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    constructor() public {
        dai.approve(address(cDai), uint256(-1));
    }

    function () public payable {
        etherTocDai(msg.sender);
    }

    function etherTocDai(address to) public payable returns(uint256 outAmount) {
        uint256 amount = DaiEx.sellAllAmountPayEth.value(msg.value * 993 / 1000)(0x39755357759cE0d7f32dC8dC45414CCa409AE24e,0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,0x6B175474E89094C44Da98b954EedeAC495271d0F,1);
        cDai.mint(amount);
        outAmount = cDai.balanceOf(address(this));
        cDai.transfer(to, outAmount);
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }

}