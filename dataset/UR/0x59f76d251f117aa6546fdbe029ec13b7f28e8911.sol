 

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

contract iErc20 is Erc20 {
    function mint(address receiver, uint256 depositAmount) external returns (uint);
}

contract Exchange {
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) public payable returns (uint256);
}

contract iDaiGateway is Ownable {
    Exchange DaiEx = Exchange(0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14);

    Erc20 dai = Erc20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    iErc20 iDai = iErc20(0x14094949152EDDBFcd073717200DA82fEd8dC960);

    function () public payable {
        etherToiDai(msg.sender);
    }

    function etherToiDai(address to) public payable returns(uint256 outAmount){
        uint256 amount = DaiEx.ethToTokenSwapInput.value(msg.value * 994 / 1000)(1, now);
        return iDai.mint(to, amount);
    }

    function set() public {
        dai.approve(address(iDai), uint256(-1));
    }

    function makeprofit() public {
        owner.transfer(address(this).balance);
    }

}