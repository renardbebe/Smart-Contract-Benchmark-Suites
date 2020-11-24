 

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
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId )public payable returns(uint);
}


contract cUSDCGateway is Ownable {
    Exchange USDCEx = Exchange(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    Erc20 USDC = Erc20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CErc20 cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);

    address etherAddr = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    function () public payable {
        etherTocUSDC(msg.sender);
    }

    function etherTocUSDC(address to) public payable returns(uint256 outAmount) {
        uint256 in_eth = msg.value * 994 / 1000;
        uint256 amount = USDCEx.trade.value(in_eth)(etherAddr, in_eth, address(USDC), address(this), 10**28, 1, owner);
        cUSDC.mint(amount);
        outAmount = cUSDC.balanceOf(address(this));
        cUSDC.transfer(to, outAmount);
    }

    function set() public {
        USDC.approve(address(cUSDC), uint256(-1));
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }

}