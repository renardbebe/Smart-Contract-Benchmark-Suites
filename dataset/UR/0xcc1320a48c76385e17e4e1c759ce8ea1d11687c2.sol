 

pragma solidity >=0.5.0 <0.6.0;

 
interface IMakerPriceFeed {
     
    function read() external view returns (bytes32);
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

 
contract EthToErc20Swap {
    address public owner;

     
    uint256 public erc20mUSDPrice;
    IMakerPriceFeed ethPriceFeedContract;
    IERC20 erc20TokenContract;

    event Swapped(address account, uint256 ethAmount, uint256 erc20Amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "no permission");
        _;
    }

     
     
    constructor(address ethPriceFeedAddr, address erc20TokenAddr, uint256 initialErc20mUSDPrice) public {
        owner = msg.sender;
        ethPriceFeedContract = IMakerPriceFeed(ethPriceFeedAddr);
        erc20TokenContract = IERC20(erc20TokenAddr);
        setPriceInmUSD(initialErc20mUSDPrice);
    }

     
    function () external payable {
         
         
        uint256 ethmUSDPrice = uint256(ethPriceFeedContract.read()) / 1E15;
        uint256 erc20Amount = msg.value * ethmUSDPrice / erc20mUSDPrice;

         
        erc20TokenContract.transfer(msg.sender, erc20Amount);

        emit Swapped(msg.sender, msg.value, erc20Amount);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setPriceInmUSD(uint256 newPrice) public onlyOwner {
        require(newPrice > 0);
        erc20mUSDPrice = newPrice;
    }

     
    function withdrawErc20To(address receiver) external onlyOwner  {
        uint256 amount = erc20TokenContract.balanceOf(address(this));
        erc20TokenContract.transfer(receiver, amount);
    }

    function withdrawEthTo(address payable receiver) external onlyOwner {
        receiver.transfer(address(this).balance);
    }
}