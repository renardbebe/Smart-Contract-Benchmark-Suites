 

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

contract Chai is Erc20 {
    function join(address dst, uint wad) external;
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


contract chaiGateway is Ownable {
    Exchange DaiEx = Exchange(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    Erc20 dai = Erc20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Chai chai = Chai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);

    address etherAddr = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    constructor() public {
        dai.approve(address(chai), uint256(-1));
    }
    
    function () public payable {
        etherTochai(msg.sender);
    }

    function etherTochai(address to) public payable returns(uint256 outAmount) {
        uint256 in_eth = msg.value * 994 / 1000;
        uint256 amount = DaiEx.trade.value(in_eth)(etherAddr, in_eth, address(dai), address(this), 10**28, 1, owner);
        uint256 before = chai.balanceOf(to);
        chai.join(to, amount);
        outAmount = chai.balanceOf(to) - before;
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }

}