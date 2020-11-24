 

pragma solidity ^0.4.23;


 
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

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}





 
contract StockPortfolio is Ownable {

    struct Position {
        uint32 quantity;
        uint32 avgPrice;
    }

    mapping (bytes12 => Position) positions;
    bytes12[] private holdings;
    bytes6[] private markets;

    event Bought(bytes6 market, bytes6 symbol, uint32 quantity, uint32 price, uint256 timestamp);
    event Sold(bytes6 market, bytes6 symbol, uint32 quantity, uint32 price, int64 profits, uint256 timestamp);
    event ForwardSplit(bytes6 market, bytes6 symbol, uint8 multiple, uint256 timestamp);
    event ReverseSplit(bytes6 market, bytes6 symbol, uint8 divisor, uint256 timestamp);

     
     
     
    mapping (bytes6 => int) public profits;

    constructor () public {
        markets.push(0x6e7973650000);  
        markets.push(0x6e6173646171);  
        markets.push(0x747378000000);  
        markets.push(0x747378760000);  
        markets.push(0x6f7463000000);  
        markets.push(0x637365000000);  
    }

    function () public payable {}

     
    function buy
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        external
        onlyOwner
    {
        _buy(_marketIndex, _symbol, _quantity, _price);
    }

     
    function bulkBuy
    (
        uint8[] _marketIndexes,
        bytes6[] _symbols,
        uint32[] _quantities,
        uint32[] _prices
    )
        external
        onlyOwner
    {
        for (uint i = 0; i < _symbols.length; i++) {
            _buy(_marketIndexes[i], _symbols[i], _quantities[i], _prices[i]);
        }
    }

     
    function split
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint8 _multiple
    )
        external
        onlyOwner
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity > 0);
        uint32 quantity = (_multiple * position.quantity) - position.quantity;
        position.avgPrice = (position.quantity * position.avgPrice) / (position.quantity + quantity);
        position.quantity += quantity;

        emit ForwardSplit(market, _symbol, _multiple, now);
    }

     
    function reverseSplit
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint8 _divisor,
        uint32 _price
    )
        external
        onlyOwner
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity > 0);
        uint32 quantity = position.quantity / _divisor;
        uint32 extraQuantity = position.quantity - (quantity * _divisor);
        if (extraQuantity > 0) {
            _sell(_marketIndex, _symbol, extraQuantity, _price);
        }
        position.avgPrice = position.avgPrice * _divisor;
        position.quantity = quantity;

        emit ReverseSplit(market, _symbol, _divisor, now);
    }

     
    function sell
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        external
        onlyOwner
    {
        _sell(_marketIndex, _symbol, _quantity, _price);
    }

     
    function bulkSell
    (
        uint8[] _marketIndexes,
        bytes6[] _symbols,
        uint32[] _quantities,
        uint32[] _prices
    )
        external
        onlyOwner
    {
        for (uint i = 0; i < _symbols.length; i++) {
            _sell(_marketIndexes[i], _symbols[i], _quantities[i], _prices[i]);
        }
    }

     
    function getMarketsCount() public view returns(uint) {
        return markets.length;
    }

     
    function getMarket(uint _index) public view returns(bytes6) {
        return markets[_index];
    }

     
    function getProfits(bytes6 _market) public view returns(int) {
        return profits[_market];
    }

     
    function getPosition
    (
        bytes12 _stockKey
    )
        public
        view
        returns
        (
            uint32 quantity,
            uint32 avgPrice
        )
    {
        Position storage position = positions[_stockKey];
        quantity = position.quantity;
        avgPrice = position.avgPrice;
    }

       
    function getPositionFromHolding
    (
        uint _index
    )
        public
        view
        returns
        (
            bytes6 market, 
            bytes6 symbol,
            uint32 quantity,
            uint32 avgPrice
        )
    {
        bytes12 stockKey = holdings[_index];
        (market, symbol) = recoverStockKey(stockKey);
        Position storage position = positions[stockKey];
        quantity = position.quantity;
        avgPrice = position.avgPrice;
    }

     
    function getHoldingsCount() public view returns(uint) {
        return holdings.length;
    }

     
    function getHolding(uint _index) public view returns(bytes12) {
        return holdings[_index];
    }

     
    function getStockKey(bytes6 _market, bytes6 _symbol) public pure returns(bytes12 key) {
        bytes memory combined = new bytes(12);
        for (uint i = 0; i < 6; i++) {
            combined[i] = _market[i];
        }
        for (uint j = 0; j < 6; j++) {
            combined[j + 6] = _symbol[j];
        }
        assembly {
            key := mload(add(combined, 32))
        }
    }
    
     
    function recoverStockKey(bytes12 _key) public pure returns(bytes6 market, bytes6 symbol) {
        bytes memory _market = new bytes(6);
        bytes memory _symbol = new bytes(6);
        for (uint i = 0; i < 6; i++) {
            _market[i] = _key[i];
        }
        for (uint j = 0; j < 6; j++) {
            _symbol[j] = _key[j + 6];
        }
        assembly {
            market := mload(add(_market, 32))
            symbol := mload(add(_symbol, 32))
        }
    }

    function addMarket(bytes6 _market) public onlyOwner {
        markets.push(_market);
    }

    function _addHolding(bytes12 _stockKey) private {
        holdings.push(_stockKey);
    }

    function _removeHolding(bytes12 _stockKey) private {
        if (holdings.length == 0) {
            return;
        }
        bool found = false;
        for (uint i = 0; i < holdings.length; i++) {
            if (found) {
                holdings[i - 1] = holdings[i];
            }

            if (holdings[i] == _stockKey) {
                found = true;
            }
        }
        if (found) {
            delete holdings[holdings.length - 1];
            holdings.length--;
        }
    }

    function _sell
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        private
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        require(position.quantity >= _quantity);
        int64 profit = int64(_quantity * _price) - int64(_quantity * position.avgPrice);
        position.quantity -= _quantity;
        if (position.quantity <= 0) {
            _removeHolding(stockKey);
            delete positions[stockKey];
        }
        profits[market] += profit;
        emit Sold(market, _symbol, _quantity, _price, profit, now);
    }

    function _buy
    (
        uint8 _marketIndex,
        bytes6 _symbol,
        uint32 _quantity,
        uint32 _price
    )
        private
    {
        bytes6 market = markets[_marketIndex];
        bytes12 stockKey = getStockKey(market, _symbol);
        Position storage position = positions[stockKey];
        if (position.quantity == 0) {
            _addHolding(stockKey);
        }
        position.avgPrice = ((position.quantity * position.avgPrice) + (_quantity * _price)) /
            (position.quantity + _quantity);
        position.quantity += _quantity;

        emit Bought(market, _symbol, _quantity, _price, now);
    }

}