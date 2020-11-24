 

 

 

pragma solidity ^0.5.8;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor()
        internal
    {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner()
        public
        view
        returns(address)
    {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

     
    function isOwner()
        public
        view
        returns(bool)
    {
        return msg.sender == _owner;
    }

     
    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(
        address newOwner
    )
        public
        onlyOwner
    {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Eth2daiInterface {
     
    function sellAllAmount(address, uint, address, uint) public returns (uint);
}

contract TokenInterface {
    function balanceOf(address) public returns (uint);
    function allowance(address, address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address,uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
}

contract Eth2daiDirect is Ownable {

    Eth2daiInterface public constant eth2dai = Eth2daiInterface(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);
    TokenInterface public constant wethToken = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    TokenInterface public constant daiToken = TokenInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor()
        public
    {
        daiToken.approve(address(eth2dai), 2**256-1);
        wethToken.approve(address(eth2dai), 2**256-1);
    }

    function marketBuyEth(
        uint256 payDaiAmount,
        uint256 minBuyEthAmount
    )
        public
    {
        daiToken.transferFrom(msg.sender, address(this), payDaiAmount);
        uint256 fillAmount = eth2dai.sellAllAmount(address(daiToken), payDaiAmount, address(wethToken), minBuyEthAmount);
        wethToken.withdraw(fillAmount);
        msg.sender.transfer(fillAmount);
    }

    function marketSellEth(
        uint256 payEthAmount,
        uint256 minBuyDaiAmount
    )
        public
        payable
    {
        require(msg.value == payEthAmount, "MSG_VALUE_NOT_MATCH");
        wethToken.deposit.value(msg.value)();
        uint256 fillAmount = eth2dai.sellAllAmount(address(wethToken), payEthAmount, address(daiToken), minBuyDaiAmount);
        daiToken.transfer(msg.sender, fillAmount);
    }

    function withdraw(
        address tokenAddress,
        uint256 amount
    )
        public
        onlyOwner
    {
        if (tokenAddress == address(0)) {
            msg.sender.transfer(amount);
        } else {
            TokenInterface(tokenAddress).transfer(msg.sender, amount);
        }
    }

    function() external payable {
        require(msg.sender == address(wethToken), "CONTRACT_NOT_PAYABLE");
    }
}