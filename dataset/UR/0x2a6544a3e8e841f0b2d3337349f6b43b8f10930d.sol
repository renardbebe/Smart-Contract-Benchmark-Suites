 

pragma solidity ^0.4.24;


 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract CurrencyExchangeRate is Ownable {

    struct Currency {
        uint256 exRateToEther;  
        uint8 exRateDecimals;   
    }

    Currency[] public currencies;

    event CurrencyExchangeRateAdded(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    event CurrencyExchangeRateSet(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    constructor() public {
         
        currencies.push(
            Currency ({
                exRateToEther: 1,
                exRateDecimals: 0
            })
        );
         
        currencies.push(
            Currency ({
                exRateToEther: 30000,
                exRateDecimals: 2
            })
        );
    }

    function addCurrencyExchangeRate(
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateAdded(
            msg.sender, currencies.length, _exRateToEther, _exRateDecimals);
        currencies.push(
            Currency ({
                exRateToEther: _exRateToEther,
                exRateDecimals: _exRateDecimals
            })
        );
    }

    function setCurrencyExchangeRate(
        uint256 _currencyIndex,
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateSet(
            msg.sender, _currencyIndex, _exRateToEther, _exRateDecimals);
        currencies[_currencyIndex].exRateToEther = _exRateToEther;
        currencies[_currencyIndex].exRateDecimals = _exRateDecimals;
    }
}