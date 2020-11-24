 

pragma solidity ^0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

     

    address public owner;

     

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

     

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract AssetRegistrar is DBC, Owned {

     

    struct Asset {
        address breakIn;  
        address breakOut;  
        bytes32 chainId;  
        uint decimal;  
        bool exists;  
        string ipfsHash;  
        string name;  
        uint price;  
        string symbol;  
        uint timestamp;  
        string url;  
    }

     

     
    mapping (address => Asset) public information;

     

     

     
     
     
     
     
     
     
     
     
     
     
     
    function register(
        address ofAsset,
        string name,
        string symbol,
        uint decimal,
        string url,
        string ipfsHash,
        bytes32 chainId,
        address breakIn,
        address breakOut
    )
        pre_cond(isOwner())
        pre_cond(!information[ofAsset].exists)
    {
        Asset asset = information[ofAsset];
        asset.name = name;
        asset.symbol = symbol;
        asset.decimal = decimal;
        asset.url = url;
        asset.ipfsHash = ipfsHash;
        asset.breakIn = breakIn;
        asset.breakOut = breakOut;
        asset.exists = true;
        assert(information[ofAsset].exists);
    }

     
     
     
     
     
     
     
     
    function updateDescriptiveInformation(
        address ofAsset,
        string name,
        string symbol,
        string url,
        string ipfsHash
    )
        pre_cond(isOwner())
        pre_cond(information[ofAsset].exists)
    {
        Asset asset = information[ofAsset];
        asset.name = name;
        asset.symbol = symbol;
        asset.url = url;
        asset.ipfsHash = ipfsHash;
    }

     
     
     
    function remove(
        address ofAsset
    )
        pre_cond(isOwner())
        pre_cond(information[ofAsset].exists)
    {
        delete information[ofAsset];  
        assert(!information[ofAsset].exists);
    }

     

     
    function getName(address ofAsset) view returns (string) { return information[ofAsset].name; }
    function getSymbol(address ofAsset) view returns (string) { return information[ofAsset].symbol; }
    function getDecimals(address ofAsset) view returns (uint) { return information[ofAsset].decimal; }

}

interface PriceFeedInterface {

     

    event PriceUpdated(uint timestamp);

     

    function update(address[] ofAssets, uint[] newPrices);

     

     
    function getName(address ofAsset) view returns (string);
    function getSymbol(address ofAsset) view returns (string);
    function getDecimals(address ofAsset) view returns (uint);
     
    function getQuoteAsset() view returns (address);
    function getInterval() view returns (uint);
    function getValidity() view returns (uint);
    function getLastUpdateId() view returns (uint);
     
    function hasRecentPrice(address ofAsset) view returns (bool isRecent);
    function hasRecentPrices(address[] ofAssets) view returns (bool areRecent);
    function getPrice(address ofAsset) view returns (bool isRecent, uint price, uint decimal);
    function getPrices(address[] ofAssets) view returns (bool areRecent, uint[] prices, uint[] decimals);
    function getInvertedPrice(address ofAsset) view returns (bool isRecent, uint invertedPrice, uint decimal);
    function getReferencePrice(address ofBase, address ofQuote) view returns (bool isRecent, uint referencePrice, uint decimal);
    function getOrderPrice(
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (uint orderPrice);
    function existsPriceOnAssetPair(address sellAsset, address buyAsset) view returns (bool isExistent);
}

contract PriceFeed is PriceFeedInterface, AssetRegistrar, DSMath {

     

     
    address public QUOTE_ASSET;  
     
    uint public INTERVAL;  
    uint public VALIDITY;  
    uint updateId;         

     

     

     
     
     
     
     
     
     
     
     
     
     
     
    function PriceFeed(
        address ofQuoteAsset,  
        string quoteAssetName,
        string quoteAssetSymbol,
        uint quoteAssetDecimals,
        string quoteAssetUrl,
        string quoteAssetIpfsHash,
        bytes32 quoteAssetChainId,
        address quoteAssetBreakIn,
        address quoteAssetBreakOut,
        uint interval,
        uint validity
    ) {
        QUOTE_ASSET = ofQuoteAsset;
        register(
            QUOTE_ASSET,
            quoteAssetName,
            quoteAssetSymbol,
            quoteAssetDecimals,
            quoteAssetUrl,
            quoteAssetIpfsHash,
            quoteAssetChainId,
            quoteAssetBreakIn,
            quoteAssetBreakOut
        );
        INTERVAL = interval;
        VALIDITY = validity;
    }

     

     
     
     
     
     
    function update(address[] ofAssets, uint[] newPrices)
        pre_cond(isOwner())
        pre_cond(ofAssets.length == newPrices.length)
    {
        updateId += 1;
        for (uint i = 0; i < ofAssets.length; ++i) {
            require(information[ofAssets[i]].timestamp != now);  
            require(information[ofAssets[i]].exists);
            information[ofAssets[i]].timestamp = now;
            information[ofAssets[i]].price = newPrices[i];
        }
        PriceUpdated(now);
    }

     

     
    function getQuoteAsset() view returns (address) { return QUOTE_ASSET; }
    function getInterval() view returns (uint) { return INTERVAL; }
    function getValidity() view returns (uint) { return VALIDITY; }
    function getLastUpdateId() view returns (uint) { return updateId; }

     
     
     
    function hasRecentPrice(address ofAsset)
        view
        pre_cond(information[ofAsset].exists)
        returns (bool isRecent)
    {
        return sub(now, information[ofAsset].timestamp) <= VALIDITY;
    }

     
     
     
    function hasRecentPrices(address[] ofAssets)
        view
        returns (bool areRecent)
    {
        for (uint i; i < ofAssets.length; i++) {
            if (!hasRecentPrice(ofAssets[i])) {
                return false;
            }
        }
        return true;
    }

     
    function getPrice(address ofAsset)
        view
        returns (bool isRecent, uint price, uint decimal)
    {
        return (
            hasRecentPrice(ofAsset),
            information[ofAsset].price,
            information[ofAsset].decimal
        );
    }

     
    function getPrices(address[] ofAssets)
        view
        returns (bool areRecent, uint[] prices, uint[] decimals)
    {
        areRecent = true;
        for (uint i; i < ofAssets.length; i++) {
            var (isRecent, price, decimal) = getPrice(ofAssets[i]);
            if (!isRecent) {
                areRecent = false;
            }
            prices[i] = price;
            decimals[i] = decimal;
        }
    }

     
    function getInvertedPrice(address ofAsset)
        view
        returns (bool isRecent, uint invertedPrice, uint decimal)
    {
         
        var (isInvertedRecent, inputPrice, assetDecimal) = getPrice(ofAsset);

         
        uint quoteDecimal = getDecimals(QUOTE_ASSET);

        return (
            isInvertedRecent,
            mul(10 ** uint(quoteDecimal), 10 ** uint(assetDecimal)) / inputPrice,
            quoteDecimal
        );
    }

     
    function getReferencePrice(address ofBase, address ofQuote)
        view
        returns (bool isRecent, uint referencePrice, uint decimal)
    {
        if (getQuoteAsset() == ofQuote) {
            (isRecent, referencePrice, decimal) = getPrice(ofBase);
        } else if (getQuoteAsset() == ofBase) {
            (isRecent, referencePrice, decimal) = getInvertedPrice(ofQuote);
        } else {
            revert();  
        }
    }

     
     
     
     
     
     
    function getOrderPrice(
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        view
        returns (uint orderPrice)
    {
        return mul(buyQuantity, 10 ** uint(getDecimals(sellAsset))) / sellQuantity;
    }

     
     
     
     
     
    function existsPriceOnAssetPair(address sellAsset, address buyAsset)
        view
        returns (bool isExistent)
    {
        return
            hasRecentPrice(sellAsset) &&  
            hasRecentPrice(buyAsset) &&  
            (buyAsset == QUOTE_ASSET || sellAsset == QUOTE_ASSET) &&  
            (buyAsset != QUOTE_ASSET || sellAsset != QUOTE_ASSET);  
    }
}