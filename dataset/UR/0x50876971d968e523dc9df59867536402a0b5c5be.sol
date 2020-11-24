 

pragma solidity ^0.5.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IManager {
 
    event SRC20SupplyMinted(address src20, address swmAccount, uint256 swmValue, uint256 src20Value);
    event SRC20StakeIncreased(address src20, address swmAccount, uint256 swmValue);
    event SRC20StakeDecreased(address src20, address swmAccount, uint256 swmValue);

    function mintSupply(address src20, address swmAccount, uint256 swmValue, uint256 src20Value) external returns (bool);
    function increaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function decreaseSupply(address src20, address swmAccount, uint256 srcValue) external returns (bool);
    function renounceManagement(address src20) external returns (bool);
    function transferManagement(address src20, address newManager) external returns (bool);
    function calcTokens(address src20, uint256 swmValue) external view returns (uint256);

    function getStake(address src20) external view returns (uint256);
    function swmNeeded(address src20, uint256 srcValue) external view returns (uint256);
    function getSrc20toSwmRatio(address src20) external returns (uint256);
    function getTokenOwner(address src20) external view returns (address);
}

interface INetAssetValueUSD {

    function getNetAssetValueUSD(address src20) external view returns (uint256);
}

interface IPriceUSD {

    function getPrice() external view returns (uint256 numerator, uint256 denominator);

}

contract GetRateMinter {
    IManager public _registry;
    INetAssetValueUSD public _asset;
    IPriceUSD public _SWMPriceOracle;

    using SafeMath for uint256;

    constructor(address registry, address asset, address SWMRate) public {
        _registry = IManager(registry);
        _asset = INetAssetValueUSD(asset);
        _SWMPriceOracle = IPriceUSD(SWMRate);
    }

    modifier onlyTokenOwner(address src20) {
        require(msg.sender == Ownable(src20).owner(), "caller not token owner");
        _;
    }

    
    function calcStake(uint256 netAssetValueUSD) public view returns (uint256) {

        uint256 NAV = netAssetValueUSD; 
        uint256 stakeUSD;

        if(NAV >= 0 && NAV <= 500000) 
            stakeUSD = 2500;

        if(NAV > 500000 && NAV <= 1000000) 
            stakeUSD = NAV.mul(5).div(1000);

        if(NAV > 1000000 && NAV <= 5000000) 
            stakeUSD = NAV.mul(45).div(10000);

        if(NAV > 5000000 && NAV <= 15000000) 
            stakeUSD = NAV.mul(4).div(1000);

        if(NAV > 15000000 && NAV <= 50000000) 
            stakeUSD = NAV.mul(25).div(10000);

        if(NAV > 50000000 && NAV <= 100000000) 
            stakeUSD = NAV.mul(2).div(1000);

        if(NAV > 100000000 && NAV <= 150000000) 
            stakeUSD = NAV.mul(15).div(10000);

        if(NAV > 150000000) 
            stakeUSD = NAV.mul(1).div(1000);

        (uint256 numerator, uint denominator) = _SWMPriceOracle.getPrice(); 

        return stakeUSD.mul(denominator).div(numerator).mul(10**18); 

    } 

    
    function stakeAndMint(address src20, uint256 numSRC20Tokens)
        external
        onlyTokenOwner(src20)
        returns (bool)
    {
        uint256 numSWMTokens = calcStake(_asset.getNetAssetValueUSD(src20));

        require(_registry.mintSupply(src20, msg.sender, numSWMTokens, numSRC20Tokens), 'supply minting failed');

        return true;
    }
}