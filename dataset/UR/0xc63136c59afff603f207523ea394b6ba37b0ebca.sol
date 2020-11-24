 

pragma solidity ^0.5.10;


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WCKKittyBuyer is Ownable {

     
    using SafeMath for uint256;

     
     
     

     
     
     

    event KittyBoughtWithWCK(uint256 kittyId, uint256 wckSpent);
    event DevFeeUpdated(uint256 newDevFee);

     
     
     

     
     
     

    address kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address kittySalesAddress = 0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C;
    address wrappedKittiesAddress = 0x09fE5f0236F0Ea5D930197DCE254d77B04128075;
    address uniswapExchangeAddress = 0x4FF7Fa493559c40aBd6D157a0bfC35Df68d8D0aC;

    uint256 devFeeInBasisPoints = 375;

     
     
     

    function buyKittyWithWCK(uint256 _kittyId, uint256 _maxWCKWeiToSpend) external {
        ERC20(wrappedKittiesAddress).transferFrom(msg.sender, address(this), _maxWCKWeiToSpend);
        uint256 costInWei = KittySales(kittySalesAddress).getCurrentPrice(_kittyId);
        uint256 tokensSold = UniswapExchange(uniswapExchangeAddress).tokenToEthSwapOutput(_computePriceWithDevFee(costInWei), _maxWCKWeiToSpend, ~uint256(0));
        KittyCore(kittySalesAddress).bid.value(costInWei)(_kittyId);
        ERC20(wrappedKittiesAddress).transfer(msg.sender, _maxWCKWeiToSpend.sub(tokensSold));
        KittyCore(kittyCoreAddress).transfer(msg.sender, _kittyId);
        emit KittyBoughtWithWCK(_kittyId, tokensSold);
    }

    function transferERC20(address _erc20Address, address _to, uint256 _value) external onlyOwner {
        ERC20(_erc20Address).transfer(_to, _value);
    }

    function withdrawOwnerEarnings() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function updateFee(uint256 _newFee) external onlyOwner {
        devFeeInBasisPoints = _newFee;
        emit DevFeeUpdated(_newFee);
    }

    constructor() public {
        ERC20(wrappedKittiesAddress).approve(uniswapExchangeAddress, ~uint256(0));
    }

    function() external payable {}

    function _computePriceWithDevFee(uint256 _costInWei) internal view returns (uint256) {
        return (_costInWei.mul(uint256(10000).add(devFeeInBasisPoints))).div(uint256(10000));
    }
}

contract KittyCore {
    function transfer(address _to, uint256 _tokenId) external;
    function bid(uint256 _tokenId) external payable;
}

contract KittySales {
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256);
}

contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract UniswapExchange {
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
}