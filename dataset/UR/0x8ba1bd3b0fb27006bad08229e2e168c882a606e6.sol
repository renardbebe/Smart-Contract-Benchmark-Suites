 

pragma solidity ^0.5.0;


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

interface IPriceUSD {

    function getPrice() external view returns (uint256 numerator, uint256 denominator);

}

contract SWMPriceOracle is IPriceUSD, Ownable {

    event UpdatedSWMPriceUSD(uint256 oldPriceNumerator, uint256 oldPriceDenominator, 
                             uint256 newPriceNumerator, uint256 newPriceDenominator);

    uint256 public _priceNumerator;
    uint256 public _priceDenominator;

    constructor(uint256 priceNumerator, uint256 priceDenominator) 
    public {
        require(priceNumerator > 0, "numerator must not be zero");
        require(priceDenominator > 0, "denominator must not be zero");

        _priceNumerator = priceNumerator;
        _priceDenominator = priceDenominator;

        emit UpdatedSWMPriceUSD(0, 0, priceNumerator, priceNumerator);
    }

    
    function getPrice() external view returns (uint256 priceNumerator, uint256 priceDenominator) {
        return (_priceNumerator, _priceDenominator);
    }

    
    function updatePrice(uint256 priceNumerator, uint256 priceDenominator) external onlyOwner returns (bool) {
        require(priceNumerator > 0, "numerator must not be zero");
        require(priceDenominator > 0, "denominator must not be zero");

        emit UpdatedSWMPriceUSD(_priceNumerator, _priceDenominator, priceNumerator, priceDenominator);

        _priceNumerator = priceNumerator;
        _priceDenominator = priceDenominator;

        return true;
    }
}