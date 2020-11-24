 

pragma solidity ^0.4.24;

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

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Erc20Token {
    function balanceOf(address _owner) constant public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract AirDropContract is Ownable {

    using SafeMath for uint256;

    Erc20Token public tokenRewardContract;

    uint256 public totalAirDropToken;

    address public collectorAddress;

    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event Additional(uint amount);
    event Burn(uint amount);
    event CollectAirDropTokenBack(address collectorAddress,uint256 airDropTokenNum);

     
    constructor(
        address _tokenRewardContract,
        address _collectorAddress
    ) public {
        totalAirDropToken = 2e7;
        tokenRewardContract = Erc20Token(_tokenRewardContract);
        collectorAddress = _collectorAddress;
    }

     
    function() payable public {
        require(collectorAddress != 0x0);
        require(totalAirDropToken > 0);

        uint256 weiAmount = msg.value;
        uint256 amount = weiAmount.mul(23000);

        totalAirDropToken = totalAirDropToken.sub(amount.div(1e18));
        tokenRewardContract.transfer(msg.sender, amount);

        address wallet = collectorAddress;
        wallet.transfer(weiAmount);

         
    }

     
    function additional(uint256 amount) public onlyOwner {
        require(amount > 0);

        totalAirDropToken = totalAirDropToken.add(amount);
        emit Additional(amount);
    }

     
    function burn(uint256 amount) public onlyOwner {
        require(amount > 0);

        totalAirDropToken = totalAirDropToken.sub(amount);
        emit Burn(amount);
    }


     
    function modifyCollectorAddress(address newCollectorAddress) public onlyOwner returns (bool) {
        collectorAddress = newCollectorAddress;
    }

     
    function collectAirDropTokenBack(uint256 airDropTokenNum) public onlyOwner {
        require(totalAirDropToken > 0);
        require(collectorAddress != 0x0);

        if (airDropTokenNum > 0) {
            tokenRewardContract.transfer(collectorAddress, airDropTokenNum * 1e18);
        } else {
            tokenRewardContract.transfer(collectorAddress, totalAirDropToken * 1e18);
            totalAirDropToken = 0;
        }
        emit CollectAirDropTokenBack(collectorAddress, airDropTokenNum);
    }

     
    function collectEtherBack() public onlyOwner {
        uint256 b = address(this).balance;
        require(b > 0);
        require(collectorAddress != 0x0);

        collectorAddress.transfer(b);
    }

     
    function getTokenBalance(address tokenAddress, address who) view public returns (uint){
        Erc20Token t = Erc20Token(tokenAddress);
        return t.balanceOf(who);
    }

     
    function collectOtherTokens(address tokenContract) onlyOwner public returns (bool) {
        Erc20Token t = Erc20Token(tokenContract);

        uint256 b = t.balanceOf(address(this));
        return t.transfer(collectorAddress, b);
    }

}