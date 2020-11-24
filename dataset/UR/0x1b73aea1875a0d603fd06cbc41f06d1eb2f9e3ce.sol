 

pragma solidity ^0.4.25;

 
contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

 
contract DMEX_Base {
    function getReserve(address token, address user) returns (uint256);
    function setReserve(address token, address user, uint256 amount) returns (bool);

    function availableBalanceOf(address token, address user) returns (uint256);
    function balanceOf(address token, address user) returns (uint256);


    function setBalance(address token, address user, uint256 amount) returns (bool);
    function getAffiliate(address user) returns (address);
    function getInactivityReleasePeriod() returns (uint256);
    function getMakerTakerBalances(address token, address maker, address taker) returns (uint256[4]);

    function getEtmTokenAddress() returns (address);

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) returns (bool);
    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) returns (bool);
    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) returns (bool);
    
}



 
contract Exchange {
    function assert(bool assertion) pure {
        
        if (!assertion) {
            throw;
        }
    }

     
    function safeMul(uint a, uint b) pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

     
    function safeSub(uint a, uint b) pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function safeAdd(uint a, uint b) pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner;  

     
    event SetOwner(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

     
    modifier onlyOracle {
        assert(msg.sender == DmexOracleContract);
        _;
    }

     
    function setOwner(address newOwner) onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

     
    function getOwner() view returns (address out) {
        return owner;
    }

    mapping (address => bool) public admins;                     
    mapping (address => bool) public pools;                      
    mapping (address => uint256) public lastActiveTransaction;   
    mapping (bytes32 => uint256) public orderFills;              
    mapping (bytes32 => mapping(uint256 => uint256)) public assetPrices;  


    address public feeAccount;           
    address public exchangeContract;     
    address public DmexOracleContract;     

    uint256 public makerFee;             
    uint256 public takerFee;             
    
    struct FuturesAsset {
        address baseToken;               
        string priceUrl;                 
        string pricePath;                
        bool disabled;                   
        uint256 decimals;                
    }

    function createFuturesAsset(address baseToken, string priceUrl, string pricePath, uint256 decimals) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresAsset = keccak256(this, baseToken, priceUrl, pricePath, decimals);
        if (futuresAssets[futuresAsset].disabled) throw;  
        if (bytes(futuresAssets[futuresAsset].pricePath).length != 0) return futuresAsset;

        futuresAssets[futuresAsset] = FuturesAsset({
            baseToken           : baseToken,
            priceUrl            : priceUrl,
            pricePath           : pricePath,
            disabled            : false,
            decimals            : decimals            
        });

         
        return futuresAsset;
    }
    
    struct FuturesContract {
        bytes32 asset;                   
        uint256 expirationBlock;         
        uint256 closingPrice;            
        bool closed;                     
        bool broken;                     
        uint256 multiplier;              
        uint256 fundingRate;             
        uint256 closingBlock;            
        bool perpetual;                  
        uint256 maintenanceMargin;       
    }

    function createFuturesContract(bytes32 asset, uint256 expirationBlock, uint256 multiplier, uint256 fundingRate, bool perpetual, uint256 maintenanceMargin) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresContract = keccak256(this, asset, expirationBlock, multiplier, fundingRate, perpetual, maintenanceMargin);
        if (futuresContracts[futuresContract].expirationBlock > 0) return futuresContract;  

        futuresContracts[futuresContract] = FuturesContract({
            asset               : asset,
            expirationBlock     : expirationBlock,
            closingPrice        : 0,
            closed              : false,
            broken              : false,
            multiplier          : multiplier,
            fundingRate         : fundingRate,
            closingBlock        : 0,
            perpetual           : perpetual,
            maintenanceMargin   : maintenanceMargin
        });

         
        return futuresContract;
    }

    function getContractExpiration (bytes32 futuresContractHash) public view returns (uint256)
    {
        return futuresContracts[futuresContractHash].expirationBlock;
    }

    function getContractClosed (bytes32 futuresContractHash) public view returns (bool)
    {
        return futuresContracts[futuresContractHash].closed;
    }

    function getAssetDecimals (bytes32 futuresContractHash) public view returns (uint256)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].decimals;
    }

    function getContractBaseToken (bytes32 futuresContractHash) public view returns (address)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].baseToken;
    }

    function assetPriceUrl (bytes32 assetHash) public view returns (string)
    {
        return futuresAssets[assetHash].priceUrl;
    }

    function assetPricePath (bytes32 assetHash) public view returns (string)
    {
        return futuresAssets[assetHash].pricePath;
    }

    function assetDecimals (bytes32 assetHash) public view returns (uint256)
    {
        return futuresAssets[assetHash].decimals;
    }

    function getContractPriceUrl (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].priceUrl;
    }

    function getContractPricePath (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].pricePath;
    }

    function getMaintenanceMargin (bytes32 futuresContractHash) returns (uint256)
    {
        return futuresContracts[futuresContractHash].maintenanceMargin;
    }

    function setClosingPrice (bytes32 futuresContractHash, uint256 price) onlyOracle returns (bool) {
        if (futuresContracts[futuresContractHash].closingPrice != 0) revert();
        futuresContracts[futuresContractHash].closingPrice = price;
        futuresContracts[futuresContractHash].closed = true;
        futuresContracts[futuresContractHash].closingBlock = min(block.number,futuresContracts[futuresContractHash].expirationBlock);

        return true;
    }

    function recordLatestAssetPrice (bytes32 futuresContractHash, uint256 price) onlyOracle returns (bool) {
        assetPrices[futuresContracts[futuresContractHash].asset][block.number] = price;
    }

    mapping (bytes32 => FuturesAsset)       public futuresAssets;       
    mapping (bytes32 => FuturesContract)    public futuresContracts;    
    mapping (bytes32 => uint256)            public positions;           


    enum Errors {
         INVALID_PRICE,                 
         INVALID_SIGNATURE,              
         ORDER_ALREADY_FILLED,           
         GAS_TOO_HIGH,                  
         OUT_OF_BALANCE,                 
         FUTURES_CONTRACT_EXPIRED,       
         FLOOR_OR_CAP_PRICE_REACHED,     
         POSITION_ALREADY_EXISTS,        
         UINT48_VALIDATION,              
         FAILED_ASSERTION,               
         NOT_A_POOL,
         POSITION_EMPTY,
         OLD_CONTRACT_OPEN,
         OLD_CONTRACT_IN_RANGE,
         NEW_CONTRACT_NOT_FOUND,
         DIFF_EXPIRATIONS,
         DIFF_ASSETS,
         WRONG_RANGE,
         IDENTICAL_CONTRACTS,
         USER_NOT_IN_PROFIT,
         WRONG_MULTIPLIER,
         USER_POSITION_GREATER,
         WRONG_FUNDING_RATE,
         MUST_BE_LIQUIDATED,
         LIQUIDATION_PRICE_NOT_TOUCHED
    }

    event FuturesTrade(bool side, uint256 size, uint256 price, bytes32 indexed futuresContract, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event FuturesPositionClosed(bytes32 indexed positionHash, uint256 closingPrice);
    event FuturesForcedRelease(bytes32 indexed futuresContract, bool side, address user);
    event FuturesAssetCreated(bytes32 indexed futuresAsset, address baseToken, string priceUrl, string pricePath, uint256 maintenanceMargin);
    event FuturesContractCreated(bytes32 indexed futuresContract, bytes32 asset, uint256 expirationBlock, uint256 multiplier, uint256 fundingRate, bool perpetual);
    event PositionLiquidated(bytes32 indexed positionHash, uint256 price);
    event FuturesMarginAdded(address indexed user, bytes32 indexed futuresContract, bool side, uint64 marginToAdd);
 
     
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee);

     
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
     
    event LogUint(uint8 id, uint256 value);
    event LogBytes(uint8 id, bytes32 value);
     
     


     
    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_, address exchangeContract_, address DmexOracleContract_, address poolAddress) {
        owner               = msg.sender;
        feeAccount          = feeAccount_;
        makerFee            = makerFee_;
        takerFee            = takerFee_;

        exchangeContract    = exchangeContract_;
        DmexOracleContract    = DmexOracleContract_;

        pools[poolAddress] = true;
    }

     
    function setFees(uint256 makerFee_, uint256 takerFee_) onlyOwner {
        require(makerFee_       < 10 finney && takerFee_ < 10 finney);  
        makerFee                = makerFee_;
        takerFee                = takerFee_;

        emit FeeChange(makerFee, takerFee);
    }

     
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

     
    function setPool(address user, bool enabled) onlyOwner public {
        pools[user] = enabled;
    }

     
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }   


    function validateUint48(uint256 val) returns (bool)
    {
        if (val != uint48(val)) return false;
        return true;
    }

    function validateUint64(uint256 val) returns (bool)
    {
        if (val != uint64(val)) return false;
        return true;
    }

    function validateUint128(uint256 val) returns (bool)
    {
        if (val != uint128(val)) return false;
        return true;
    }


     
    struct FuturesOrderPair {
        uint256 makerNonce;                  
        uint256 takerNonce;                  
         
        uint256 takerIsBuying;               

        address maker;                       
        address taker;                       

        bytes32 makerOrderHash;              
        bytes32 takerOrderHash;              

        uint256 makerAmount;                 
        uint256 takerAmount;                 

        uint256 makerPrice;                  
        uint256 takerPrice;                  

        uint256 makerLeverage;               
        uint256 takerLeverage;               

        bytes32 futuresContract;             

        address baseToken;                   
         
         

        bytes32 makerPositionHash;           
        bytes32 makerInversePositionHash;    

        bytes32 takerPositionHash;           
        bytes32 takerInversePositionHash;    
    }

     
    struct FuturesTradeValues {
        uint256 qty;                     
        uint256 makerProfit;             
        uint256 makerLoss;               
        uint256 takerProfit;             
        uint256 takerLoss;               
        uint256 makerBalance;            
        uint256 takerBalance;            
        uint256 makerReserve;            
        uint256 takerReserve;            
        uint256 makerTradeCollateral;    
        uint256 takerTradeCollateral;    
        uint256 makerFee;
        uint256 takerFee;
    }


    function generateOrderHash (bool maker, bool takerIsBuying, address user, bytes32 futuresContractHash, uint256[11] tradeValues) public view returns (bytes32)
    {
        if (maker)
        {
             
            return keccak256(this, futuresContractHash, user, tradeValues[4], tradeValues[6], !takerIsBuying, tradeValues[0], tradeValues[2]);
        }
        else
        {
             
            return keccak256(this, futuresContractHash, user, tradeValues[5], tradeValues[7],  takerIsBuying, tradeValues[1], tradeValues[8]);  
        }
    }

     
    function batchFuturesTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[11][] tradeValues,
        address[3][] tradeAddresses,
        bool[2][] boolValues,
        uint256[5][] contractValues,
        string priceUrl,
        string pricePath
    ) onlyAdmin
    {
         

         

         
        for (uint i = 0; i < tradeAddresses.length; i++) {
            futuresTrade(
                v[i],
                rs[i],
                tradeValues[i],
                [tradeAddresses[i][0], tradeAddresses[i][1]],
                boolValues[i][0],
                createFuturesContract(
                    createFuturesAsset(tradeAddresses[i][2], priceUrl, pricePath, contractValues[i][4]),
                    contractValues[i][0], 
                    contractValues[i][1], 
                    contractValues[i][2], 
                    boolValues[i][1],
                    contractValues[i][3]
                )
            );
        }
    }

     
    function futuresTrade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[11] tradeValues,
        address[2] tradeAddresses,
        bool takerIsBuying,
        bytes32 futuresContractHash
    ) onlyAdmin returns (uint filledTakerTokenAmount)
    {
         

        FuturesOrderPair memory t  = FuturesOrderPair({
            makerNonce      : tradeValues[0],
            takerNonce      : tradeValues[1],
             
            takerIsBuying   : tradeValues[3],
            makerAmount     : tradeValues[4],      
            takerAmount     : tradeValues[5],   
            makerPrice      : tradeValues[6],         
            takerPrice      : tradeValues[7],
            makerLeverage   : tradeValues[2],
            takerLeverage   : tradeValues[8],

            maker           : tradeAddresses[0],
            taker           : tradeAddresses[1],

            makerOrderHash  : generateOrderHash(true,  takerIsBuying, tradeAddresses[0], futuresContractHash, tradeValues),  
            takerOrderHash  : generateOrderHash(false, takerIsBuying, tradeAddresses[1], futuresContractHash, tradeValues),  

            futuresContract : futuresContractHash,

            baseToken       : getContractBaseToken(futuresContractHash),

             
            makerPositionHash           : keccak256(this, tradeAddresses[0], futuresContractHash, !takerIsBuying),
            makerInversePositionHash    : keccak256(this, tradeAddresses[0], futuresContractHash,  takerIsBuying),

            takerPositionHash           : keccak256(this, tradeAddresses[1], futuresContractHash,  takerIsBuying),
            takerInversePositionHash    : keccak256(this, tradeAddresses[1], futuresContractHash, !takerIsBuying)

        });


       

 
    
         
        if (!validateUint128(t.makerAmount) || !validateUint128(t.takerAmount) || !validateUint64(t.makerPrice) || !validateUint64(t.takerPrice))
        {            
            emit LogError(uint8(Errors.UINT48_VALIDATION), t.makerOrderHash, t.takerOrderHash);
            return 0; 
        }


         
        if ((!futuresContracts[t.futuresContract].perpetual && block.number > futuresContracts[t.futuresContract].expirationBlock) || futuresContracts[t.futuresContract].closed == true || futuresContracts[t.futuresContract].broken == true)
        {
            emit LogError(uint8(Errors.FUTURES_CONTRACT_EXPIRED), t.makerOrderHash, t.takerOrderHash);
            return 0;  
        }



         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.makerOrderHash), v[0], rs[0], rs[1]) != t.maker)
        {
            emit LogError(uint8(Errors.INVALID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.takerOrderHash), v[1], rs[2], rs[3]) != t.taker)
        {
            emit LogError(uint8(Errors.INVALID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

         
        if ((!takerIsBuying && t.makerPrice < t.takerPrice) || (takerIsBuying && t.takerPrice < t.makerPrice))
        {
            emit LogError(uint8(Errors.INVALID_PRICE), t.makerOrderHash, t.takerOrderHash);
            return 0;  
        }      

 
        

        uint256[4] memory balances = DMEX_Base(exchangeContract).getMakerTakerBalances(t.baseToken, t.maker, t.taker);

         
        FuturesTradeValues memory tv = FuturesTradeValues({
            qty                 : 0,
            makerProfit         : 0,
            makerLoss           : 0,
            takerProfit         : 0,
            takerLoss           : 0,
            makerBalance        : balances[0], 
            takerBalance        : balances[1],  
            makerReserve        : balances[2],  
            takerReserve        : balances[3],
            makerTradeCollateral: 0,
            takerTradeCollateral: 0,
            makerFee            : min(makerFee, tradeValues[9]),
            takerFee            : min(takerFee, tradeValues[10])
        });

 





         
         
        tv.qty = min(safeSub(t.makerAmount, orderFills[t.makerOrderHash]), safeSub(t.takerAmount, orderFills[t.takerOrderHash]));
        
        if (positionExists(t.makerInversePositionHash) && positionExists(t.takerInversePositionHash))
        {
            tv.qty = min(tv.qty, min(retrievePosition(t.makerInversePositionHash)[0], retrievePosition(t.takerInversePositionHash)[0]));
        }
        else if (positionExists(t.makerInversePositionHash))
        {
            tv.qty = min(tv.qty, retrievePosition(t.makerInversePositionHash)[0]);
        }
        else if (positionExists(t.takerInversePositionHash))
        {
            tv.qty = min(tv.qty, retrievePosition(t.takerInversePositionHash)[0]);
        }

        tv.makerTradeCollateral = calculateCollateral(tv.qty, t.makerPrice, t.makerLeverage, t.futuresContract);
        tv.takerTradeCollateral = calculateCollateral(tv.qty, t.makerPrice, t.takerLeverage, t.futuresContract);


 
        
        if (tv.qty == 0)
        {
             
            emit LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

         
         
         
         
         
         


 
        

       

         
        if (!takerIsBuying)
        {     
            
      
             
            if (!positionExists(t.makerInversePositionHash) && !positionExists(t.makerPositionHash))
            {


                 
                if (safeSub(tv.makerBalance,tv.makerReserve) < safeMul(tv.makerTradeCollateral, 1e10))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,  
                        t.maker  
                    ], 
                    t.makerPositionHash,   
                    [
                        tv.qty,  
                        t.makerPrice,   
                        tv.makerFee,  
                        0,  
                        0,  
                        tv.makerBalance,  
                        0,  
                        tv.makerReserve,  
                        t.makerLeverage  
                    ], 
                    [
                        true,  
                        true,  
                        false  
                    ]
                );

            } else {               
                
                if (positionExists(t.makerPositionHash))
                {
                     
                    if (safeSub(tv.makerBalance,tv.makerReserve) < safeMul(tv.makerTradeCollateral, 1e10))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                     
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,   
                            t.maker  
                        ], 
                        t.makerPositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.makerFee,  
                            0,  
                            0,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve,  
                            t.makerLeverage  
                        ], 
                        [
                            false,  
                            true,  
                            true  
                        ]
                    );
                }
                else
                {

                     
                     
                    if (t.makerPrice < retrievePosition(t.makerInversePositionHash)[1])
                    {
                         
                         
                        tv.makerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, true);
                    }
                    else
                    {
                         
                         
                        tv.makerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, true);                                        
                    }

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  
                            t.maker  
                        ], 
                        t.makerInversePositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.makerFee,  
                            tv.makerProfit,   
                            tv.makerLoss,   
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve,  
                            t.makerLeverage  
                        ], 
                        [
                            false,  
                            true,  
                            false  
                        ]
                    );
                }                
            }

           


             
            if (!positionExists(t.takerInversePositionHash) && !positionExists(t.takerPositionHash))
            {
                
                 
                if (safeSub(tv.takerBalance,tv.takerReserve) < safeMul(tv.takerTradeCollateral, 1e10))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }
                
                 
                 
                
                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,  
                        t.taker  
                    ], 
                    t.takerPositionHash,  
                    [
                        tv.qty,  
                        t.makerPrice,   
                        tv.takerFee,  
                        0,  
                        0,   
                        tv.takerBalance,   
                        0,  
                        tv.takerReserve,  
                        t.takerLeverage  
                    ], 
                    [
                        true,  
                        false,  
                        false  
                    ]
                );

            } else {
                if (positionExists(t.takerPositionHash))
                {
                     
                     
                    if (safeSub(tv.takerBalance,tv.takerReserve) < safeMul(tv.takerTradeCollateral, 1e10))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                     
                
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,   
                            t.taker  
                        ], 
                        t.takerPositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.takerFee,  
                            0,  
                            0,  
                            tv.takerBalance,  
                            0,  
                            tv.takerReserve,  
                            t.takerLeverage  
                        ], 
                        [
                            false,  
                            false,  
                            true  
                        ]
                    );
                }
                else
                {    
                     
                     
                    
                    if (t.makerPrice > retrievePosition(t.takerInversePositionHash)[1])
                    {
                         
                        tv.takerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, false);
                    }
                    else
                    {
                         
                        tv.takerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, false); 
                    }

                  

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  
                            t.taker  
                        ], 
                        t.takerInversePositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.takerFee,  
                            tv.takerProfit,  
                            tv.takerLoss,  
                            tv.takerBalance,   
                            0,   
                            tv.takerReserve,  
                            t.takerLeverage  
                        ], 
                        [
                            false,  
                            false,  
                            false  
                        ]
                    );
                }
            }
        }


         

        else
        {      
             
            if (!positionExists(t.makerInversePositionHash) && !positionExists(t.makerPositionHash))
            {
                 
                if (safeSub(tv.makerBalance,tv.makerReserve) < safeMul(tv.makerTradeCollateral, 1e10))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                 
                 
                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,    
                        t.maker  
                    ], 
                    t.makerPositionHash,  
                    [
                        tv.qty,  
                        t.makerPrice,  
                        tv.makerFee,  
                        0,  
                        0,  
                        tv.makerBalance,  
                        0,  
                        tv.makerReserve,  
                        t.makerLeverage  
                    ], 
                    [
                        true,  
                        false,  
                        false  
                    ]
                );

            } else {
                if (positionExists(t.makerPositionHash))
                {
                     
                    if (safeSub(tv.makerBalance,tv.makerReserve) < safeMul(tv.makerTradeCollateral, 1e10))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,   
                            t.maker  
                        ], 
                        t.makerPositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.makerFee,  
                            0,  
                            0,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve,  
                            t.makerLeverage  
                        ], 
                        [
                            false,  
                            false,  
                            true  
                        ]
                    );
                }
                else
                {


                     
                    if (t.makerPrice > retrievePosition(t.makerInversePositionHash)[1])
                    {
                         
                        tv.makerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, false);
                    }
                    else
                    {
                         
                        tv.makerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.makerInversePositionHash)[1], tv.qty, futuresContractHash, false);                               
                    }

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,  
                            t.maker  
                        ], 
                        t.makerInversePositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.makerFee,  
                            tv.makerProfit,   
                            tv.makerLoss,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve,  
                            t.makerLeverage  
                        ], 
                        [
                            false,  
                            false,  
                            false  
                        ]
                    );
                }
            }

             
            if (!positionExists(t.takerInversePositionHash) && !positionExists(t.takerPositionHash))
            {
                 
                if (safeSub(tv.takerBalance,tv.takerReserve) < safeMul(tv.takerTradeCollateral, 1e10))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                updateBalances(
                    t.futuresContract, 
                    [
                        t.baseToken,   
                        t.taker  
                    ], 
                    t.takerPositionHash,  
                    [
                        tv.qty,  
                        t.makerPrice,  
                        tv.takerFee,  
                        0,   
                        0,   
                        tv.takerBalance,  
                        0,  
                        tv.takerReserve,  
                        t.takerLeverage  
                    ], 
                    [
                        true,  
                        true,  
                        false  
                    ]
                );

            } else {
                if (positionExists(t.takerPositionHash))
                {
                     
                    if (safeSub(tv.takerBalance,tv.takerReserve) < safeMul(tv.takerTradeCollateral, 1e10))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }
                    
                     
                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,   
                            t.taker  
                        ], 
                        t.takerPositionHash,  
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.takerFee,  
                            0,  
                            0,  
                            tv.takerBalance,  
                            0,  
                            tv.takerReserve,  
                            t.takerLeverage  
                        ], 
                        [
                            false,  
                            true,  
                            true  
                        ]
                    );
                }
                else
                {

                     
                    if (t.makerPrice < retrievePosition(t.takerInversePositionHash)[1])
                    {
                         
                        tv.takerProfit                      = calculateProfit(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, true);
                    }
                    else
                    {
                         
                        tv.takerLoss                        = calculateLoss(t.makerPrice, retrievePosition(t.takerInversePositionHash)[1], tv.qty, futuresContractHash, true);                                  
                    }                   

                    updateBalances(
                        t.futuresContract, 
                        [
                            t.baseToken,    
                            t.taker  
                        ], 
                        t.takerInversePositionHash,   
                        [
                            tv.qty,  
                            t.makerPrice,  
                            tv.takerFee,  
                            tv.takerProfit,  
                            tv.takerLoss,  
                            tv.takerBalance,  
                            0,  
                            tv.takerReserve,  
                            t.takerLeverage  
                        ], 
                        [
                            false,  
                            true,  
                            false  
                        ]
                    );
                }
            }           
        }

 
        orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.qty);  
        orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], tv.qty);  

 
        emit FuturesTrade(takerIsBuying, tv.qty, t.makerPrice, t.futuresContract, t.makerOrderHash, t.takerOrderHash);

        return tv.qty;
    }


    function calculateProfit(uint256 closingPrice, uint256 entryPrice, uint256 qty, bytes32 futuresContractHash, bool side) public view returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {           
            return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier )  / 1e16;            
        }
        else
        {
            return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier )  / 1e16; 
        }       
    }

    function calculateTradeValue(uint256 qty, uint256 price, bytes32 futuresContractHash)  public view returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        return safeMul(safeMul(safeMul(qty, price), 1e2), multiplier) / 1e8 ;
    }



    function calculateLoss(uint256 closingPrice, uint256 entryPrice, uint256 qty,  bytes32 futuresContractHash, bool side) public view returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier) / 1e16 ;
        }
        else
        {
            return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier) / 1e16 ; 
        }
        
    }

    function calculateCollateral (uint256 qty, uint256 price, uint256 leverage, bytes32 futuresContractHash) view returns (uint256)  
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        uint256 collateral;
            
        collateral = safeMul(safeMul(price, qty), multiplier) / 1e16 / leverage;

        return collateral;               
    }

    function calculateProportionalMargin(uint256 currQty, uint256 newQty, uint256 margin) view returns (uint256)  
    {
        uint256 proportionalMargin = safeMul(margin, newQty)/currQty;
        return proportionalMargin;          
    }

    function calculateFundingCost (uint256 price, uint256 qty, uint256 fundingBlocks, bytes32 futuresContractHash)  public view returns (uint256)  
    {
        uint256 fundingRate = futuresContracts[futuresContractHash].fundingRate;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        uint256 fundingCost = safeMul(safeMul(safeMul(fundingBlocks, fundingRate), safeMul(qty, price)/1e8)/1e18, multiplier)/1e8;

        return fundingCost;  
    }

    function calculateFee (uint256 qty, uint256 tradePrice, uint256 fee, bytes32 futuresContractHash)  public view returns (uint256)
    {
        return safeMul(calculateTradeValue(qty, tradePrice, futuresContractHash), fee / 1e10) / 1e18;
    }
     

    

    


     
    function updateBalances (bytes32 futuresContract, address[2] addressValues, bytes32 positionHash, uint256[9] uintValues, bool[3] boolValues) private
    {
         

         
        uint256[3] memory pam = [
            safeAdd(safeMul(calculateFee(uintValues[0], uintValues[1], uintValues[2], futuresContract), 1e10), uintValues[6]), 
            calculateCollateral(uintValues[0], uintValues[1], uintValues[8], futuresContract),
            0
        ];
               
        if (boolValues[0] || boolValues[2])  
        {
             
            if (boolValues[0])
            {
                 
                recordNewPosition(positionHash, uintValues[0], uintValues[1], boolValues[1] ? 1 : 0, block.number, pam[1]);
            }
            else
            {
                 
                updatePositionSize(positionHash, safeAdd(retrievePosition(positionHash)[0], uintValues[0]), uintValues[1], safeAdd(retrievePosition(positionHash)[4], pam[1]));
            }

            
            if (!pools[addressValues[1]])
            {
                subBalanceAddReserve(addressValues[0], addressValues[1], pam[0], pam[1]);                    
            }
            else
            {
                pam[0] = 0;
            }
            pam[2] = 0;
        } 
        else 
        {
             
             
            pam[1] = calculateProportionalMargin(retrievePosition(positionHash)[0], uintValues[0], retrievePosition(positionHash)[4]);
            
            updatePositionSize(positionHash, safeSub(retrievePosition(positionHash)[0], uintValues[0]),  uintValues[1], safeSub(retrievePosition(positionHash)[4], pam[1]));

            pam[2] = calculateFundingCost(retrievePosition(positionHash)[1], uintValues[0], safeSub(block.number, retrievePosition(positionHash)[3]), futuresContract);   
            

            if (pools[addressValues[1]]) {
                pam[0] = 0;
                pam[1] = 0;
                pam[2] = 0;
            }

            if (uintValues[3] > 0) 
            {
                 
                if (safeAdd(pam[0], safeMul(pam[2], 1e10)) <= safeMul(uintValues[3],1e10))
                {
                    addBalanceSubReserve(addressValues[0], addressValues[1], safeSub(safeMul(uintValues[3],1e10), safeAdd(pam[0], safeMul(pam[2], 1e10))), pam[1]);
                }
                else
                {
                     
                     
                    subBalanceSubReserve(addressValues[0], addressValues[1], safeSub(safeAdd(pam[0], safeMul(pam[2], 1e10)), safeMul(uintValues[3],1e10)), pam[1]);
                }                
            } 
            else 
            {   
                 
                subBalanceSubReserve(addressValues[0], addressValues[1], safeAdd(safeMul(uintValues[4],1e10), safeAdd(pam[0], safeMul(pam[2], 1e10))), pam[1]);  
            }     

        }          
        
        if (safeAdd(pam[0], safeMul(pam[2], 1e10)) > 0)
        {
            addBalance(addressValues[0], feeAccount, DMEX_Base(exchangeContract).balanceOf(addressValues[0], feeAccount), safeAdd(pam[0], safeMul(pam[2], 1e10)));  
        }
        
    }

    function recordNewPosition (bytes32 positionHash, uint256 size, uint256 price, uint256 side, uint256 block, uint256 collateral) private
    {
        if (!validateUint64(size) || !validateUint64(price) || !validateUint64(collateral)) 
        {
            throw;
        }

        uint256 character = uint64(size);
        character |= price<<64;
        character |= collateral<<128;
        character |= side<<192;
        character |= block<<208;

        positions[positionHash] = character;
    }

    function retrievePosition (bytes32 positionHash) public view returns (uint256[5])
    {
        uint256 character = positions[positionHash];
        uint256 size = uint256(uint64(character));
        uint256 price = uint256(uint64(character>>64));
        uint256 collateral = uint256(uint64(character>>128));
        uint256 side = uint256(uint16(character>>192));
        uint256 entryBlock = uint256(uint48(character>>208));

        return [size, price, side, entryBlock, collateral];
    }

    function updatePositionSize(bytes32 positionHash, uint256 size, uint256 price, uint256 collateral) private
    {
        uint256[5] memory pos = retrievePosition(positionHash);

        if (size > pos[0])
        {
            uint256 totalValue = safeAdd(safeMul(pos[0], pos[1]), safeMul(price, safeSub(size, pos[0])));
            uint256 newSize = safeSub(size, pos[0]);
             
            recordNewPosition(
                positionHash, 
                size, 
                totalValue / size, 
                pos[2], 
                safeAdd(safeMul(safeMul(pos[0], pos[1]), pos[3]), safeMul(safeMul(price, newSize), block.number)) / totalValue,  
                collateral
            );
        }
        else
        {
             
            recordNewPosition(
                positionHash, 
                size, 
                pos[1], 
                pos[2], 
                pos[3],
                collateral
            );
        }        
    }

    function positionExists (bytes32 positionHash) internal view returns (bool)
    {
        if (retrievePosition(positionHash)[0] == 0)
        {
            return false;
        }
        else
        {
            return true;
        }
    }


     
    function forceReleaseReserve (bytes32 futuresContract, bool side, address user) public
    {   
        if (futuresContracts[futuresContract].expirationBlock == 0) throw;       
        if (futuresContracts[futuresContract].expirationBlock > block.number) throw;
        if (safeAdd(futuresContracts[futuresContract].expirationBlock, DMEX_Base(exchangeContract).getInactivityReleasePeriod()) > block.number) throw;  
        

        bytes32 positionHash = keccak256(this, user, futuresContract, side);
        if (retrievePosition(positionHash)[1] == 0) throw;    
  

        futuresContracts[futuresContract].broken = true;

        uint256[5] memory pos = retrievePosition(positionHash);
        FuturesContract cont = futuresContracts[futuresContract];
        address baseToken = futuresAssets[cont.asset].baseToken;

        subReserve(
            baseToken, 
            user, 
            DMEX_Base(exchangeContract).getReserve(baseToken, user), 
            pos[4]
        );        

        updatePositionSize(positionHash, 0, 0, 0);

        emit FuturesForcedRelease(futuresContract, side, user);

    }

    function addBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        DMEX_Base(exchangeContract).setBalance(token, user, safeAdd(balance, amount));
    }

    function subBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        DMEX_Base(exchangeContract).setBalance(token, user, safeSub(balance, amount));
    }

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) private
    {
        DMEX_Base(exchangeContract).subBalanceAddReserve(token, user, subBalance, safeMul(addReserve, 1e10));
    }

    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) private
    {
        DMEX_Base(exchangeContract).addBalanceSubReserve(token, user, addBalance, safeMul(subReserve, 1e10));
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) private
    {
        DMEX_Base(exchangeContract).subBalanceSubReserve(token, user, subBalance, safeMul(subReserve, 1e10));
    }

    function subReserve(address token, address user, uint256 reserve, uint256 amount) private 
    {
        DMEX_Base(exchangeContract).setReserve(token, user, safeSub(reserve, safeMul(amount, 1e10)));
    }

    function getMakerTakerPositions(bytes32 makerPositionHash, bytes32 makerInversePositionHash, bytes32 takerPosition, bytes32 takerInversePosition) public view returns (uint256[5][4])
    {
        return [
            retrievePosition(makerPositionHash),
            retrievePosition(makerInversePositionHash),
            retrievePosition(takerPosition),
            retrievePosition(takerInversePosition)
        ];
    }


    struct FuturesClosePositionValues {
        address baseToken;
        uint256 reserve;                
        uint256 balance;                
        uint256 closingPrice;           
        bytes32 futuresContract;        
        uint256 expirationBlock;        
        uint256 entryBlock;             
        uint256 collateral;            
        uint256 totalPayable;
        uint256 closingBlock;
        uint256 liquidationPrice;
        uint256 closingFee;
        bool perpetual;
        uint256 profit;
        uint256 loss;
    }


    function closeFuturesPosition(bytes32 futuresContract, bool side, address poolAddress)
    {
        closeFuturesPositionInternal(futuresContract, side, msg.sender, poolAddress, takerFee);
    }

    function closeFuturesPositionInternal (bytes32 futuresContract, bool side, address user, address poolAddress, uint256 expirationFee) private returns (bool)
    {
        bytes32 positionHash = keccak256(this, user, futuresContract, side);        
        bytes32 poolPositionHash = keccak256(this, poolAddress, futuresContract, !side);        

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw;  
        if (retrievePosition(positionHash)[1] == 0) throw;  
        if (retrievePosition(positionHash)[0] == 0) throw;  
        if (pools[user]) return;
        if (!pools[poolAddress]) return;
 
        
        uint256 fee = min(expirationFee, takerFee);

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            baseToken       : getContractBaseToken(futuresContract),
            reserve         : 0,
            balance         : 0,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract,
            expirationBlock : futuresContracts[futuresContract].expirationBlock,
            entryBlock      : retrievePosition(positionHash)[3],
            collateral      : 0,
            totalPayable    : 0,
            closingBlock    : futuresContracts[futuresContract].closingBlock,
            liquidationPrice: calculateLiquidationPriceFromPositionHash(futuresContract, side, user),
            closingFee      : calculateFee(retrievePosition(positionHash)[0], retrievePosition(positionHash)[1], fee, futuresContract),
            perpetual       : futuresContracts[futuresContract].perpetual,
            profit          : 0,
            loss            : 0
        });

        v.reserve = DMEX_Base(exchangeContract).getReserve(v.baseToken, user);
        v.balance = DMEX_Base(exchangeContract).balanceOf(v.baseToken, user);
 

        if (( side && v.closingPrice <= v.liquidationPrice) ||
            (!side && v.closingPrice >= v.liquidationPrice) )
        {
            liquidatePositionWithClosingPrice(futuresContract, user, side, poolAddress);
            return;
        }


 

        v.collateral = retrievePosition(positionHash)[4];         
        v.totalPayable = safeAdd(v.closingFee, calculateFundingCost(retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], safeSub(v.closingBlock, v.entryBlock+1), futuresContract));


 
        subReserve(
            v.baseToken, 
            user, 
            v.reserve, 
            v.collateral
        );             
 

        if (( side && v.closingPrice > retrievePosition(positionHash)[1]) ||
            (!side && v.closingPrice < retrievePosition(positionHash)[1]))
        {   
             
            v.profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, !side);
      
            if (v.profit > v.totalPayable)
            {
                addBalance(v.baseToken, user, v.balance, safeSub(safeMul(v.profit, 1e10), safeMul(v.totalPayable, 1e10))); 
            }
            else
            {
                subBalance(v.baseToken, user, v.balance, safeMul(min(v.collateral, safeSub(v.totalPayable, v.profit)), 1e10)); 
            }

            subBalance(v.baseToken, poolAddress, DMEX_Base(exchangeContract).balanceOf(v.baseToken, poolAddress), safeMul(v.profit, 1e10)); 
        }
        else
        {
             
            v.loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, !side);  
 
            subBalance(v.baseToken, user, v.balance, safeMul(min(v.collateral, safeAdd(v.loss, v.totalPayable)), 1e10)); 
            addBalance(v.baseToken, poolAddress, DMEX_Base(exchangeContract).balanceOf(v.baseToken, poolAddress), safeMul(v.loss, 1e10)); 
        } 

        addBalance(v.baseToken, feeAccount, DMEX_Base(exchangeContract).balanceOf(v.baseToken, feeAccount), safeMul(v.totalPayable, 1e10));  
        

        updatePositionSize(positionHash, 0, 0, 0); 
        updatePositionSize(poolPositionHash, 0, 0, 0); 

        emit FuturesPositionClosed(positionHash, v.closingPrice);

        return true;
    }

    function generatePositionHash (address user, bytes32 futuresContractHash, bool side) public view returns (bytes32)
    {
        return keccak256(this, user, futuresContractHash, side);
    }

     
    function closeFuturesPositionForUser (bytes32 futuresContract, bool side, address user, address poolAddress, uint256 expirationFee) onlyAdmin
    {
        closeFuturesPositionInternal(futuresContract, side, user, poolAddress, expirationFee);
    }

    struct AddMarginValues {
        bytes32 addMarginHash;
        address baseToken;
    }

    function addMargin (bytes32 futuresContractHash, address user, bool side, uint8 vs, bytes32 r, bytes32 s, uint64 marginToAdd, uint256 operationFee)
    {
        bytes32 positionHash = generatePositionHash(user, futuresContractHash, side);        
        uint256[5] memory pos = retrievePosition(positionHash);
        if (pos[0] == 0) revert();

        uint256 fee = calculateFee(pos[0], pos[1], min(operationFee, takerFee), futuresContractHash);  

        AddMarginValues memory v = AddMarginValues({
            addMarginHash: keccak256(this, user, futuresContractHash, side, marginToAdd),
            baseToken: getContractBaseToken(futuresContractHash)
        });

         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", v.addMarginHash), vs, r, s) != user) revert();

         
        if (DMEX_Base(exchangeContract).availableBalanceOf(v.baseToken, user) < safeMul(safeAdd(marginToAdd, fee), 1e10)) revert();

         
        subBalanceAddReserve(v.baseToken, user, safeMul(fee, 1e10), marginToAdd);

         
        updatePositionSize(positionHash, pos[0], pos[1], safeAdd(pos[4], marginToAdd));

         
        addBalance(v.baseToken, feeAccount, DMEX_Base(exchangeContract).balanceOf(v.baseToken, feeAccount), safeMul(fee, 1e10));
    
        emit FuturesMarginAdded(user, futuresContractHash, side, marginToAdd);
    }

     
    function batchSettlePositions (
        bytes32[] futuresContracts,
        bool[] sides,
        address[] users,
        address[] pools,
        uint256[] expirationFee
    ) onlyAdmin {
        
        for (uint i = 0; i < futuresContracts.length; i++) 
        {
            closeFuturesPositionForUser(futuresContracts[i], sides[i], users[i], pools[i], expirationFee[i]);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     

    function liquidatePositionWithClosingPrice(bytes32 futuresContractHash, address user, bool side, address poolAddress) private
    {
        bytes32 positionHash = generatePositionHash(user, futuresContractHash, side);
        liquidatePosition(positionHash, futuresContractHash, user, side, futuresContracts[futuresContractHash].closingPrice, poolAddress, futuresContracts[futuresContractHash].closingBlock);
    }

    function liquidatePositionWithAssetPrice(bytes32 futuresContractHash, address user, bool side, uint256 priceBlockNumber, address poolAddress) onlyAdmin
    {
        bytes32 assetHash = futuresContracts[futuresContractHash].asset;
        if (assetPrices[assetHash][priceBlockNumber] == 0) return;

        bytes32 positionHash = generatePositionHash(user, futuresContractHash, side);

         
        if (priceBlockNumber < retrievePosition(positionHash)[3]) return;  

        liquidatePosition(positionHash, futuresContractHash, user, side, assetPrices[assetHash][priceBlockNumber], poolAddress, priceBlockNumber);
    }

    struct LiquidatePositionValues {
        uint256 maintenanceMargin;
        uint256 fundingRate;
        uint256 multiplier;
    }

    function liquidatePosition (bytes32 positionHash, bytes32 futuresContractHash, address user, bool side, uint256 price, address poolAddress, uint256 block) private
    {
        uint256[5] memory pos = retrievePosition(positionHash);
        if (pos[0] == 0) return;
        if (!pools[poolAddress]) return;      

        bytes32 assetHash = futuresContracts[futuresContractHash].asset;  


        uint256 collateral = pos[4];
        uint256 fundingBlocks = safeSub(block, pos[3]);

        LiquidatePositionValues memory v = LiquidatePositionValues({
            maintenanceMargin: getMaintenanceMargin(futuresContractHash),
            fundingRate: futuresContracts[futuresContractHash].fundingRate,
            multiplier: futuresContracts[futuresContractHash].multiplier
        });
        
         
         
         

        uint256 liquidationPrice = calculateLiquidationPrice(pos, [fundingBlocks, v.fundingRate, v.maintenanceMargin, v.multiplier]);

         

         
        if (( side && price >= liquidationPrice)
        ||  (!side && price <= liquidationPrice))
        {
            emit LogError(uint8(Errors.LIQUIDATION_PRICE_NOT_TOUCHED), futuresContractHash, positionHash);
            return; 
        }

         
        subBalanceSubReserve(futuresAssets[assetHash].baseToken, user, safeMul(collateral, 1e10), collateral);

         
        addBalance(futuresAssets[assetHash].baseToken, poolAddress, DMEX_Base(exchangeContract).balanceOf(futuresAssets[assetHash].baseToken, poolAddress), safeMul(collateral, 1e10));
    
        updatePositionSize(positionHash, 0, 0, 0); 
        updatePositionSize(generatePositionHash(poolAddress, futuresContractHash, !side), 0, 0, 0); 

        emit PositionLiquidated(positionHash, price);
    }

    struct LiquidationPriceValues {
        uint256 size;
        uint256 price;
        uint256 baseCollateral;
    }

    function calculateLiquidationPriceFromPositionHash (bytes32 futuresContractHash, bool side, address user) returns (uint256)
    {
        bytes32 positionHash = keccak256(this, user, futuresContractHash, side);      
        uint256[5] memory pos = retrievePosition(positionHash);

        if (pos[0] == 0) return;

        uint256 fundingRate = futuresContracts[futuresContractHash].fundingRate;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        uint256 maintenanceMargin = getMaintenanceMargin(futuresContractHash);

        return calculateLiquidationPrice (pos, [safeSub(block.number, pos[3]), fundingRate, maintenanceMargin, multiplier]);
    }

    function calculateLiquidationPrice(uint256[5] pos, uint256[4] values) public view returns (uint256)
    {
    
         
        LiquidationPriceValues memory v = LiquidationPriceValues({
            size: pos[0],
            price: pos[1],
            baseCollateral: pos[4]
        });
        
        uint256 collateral = safeMul(v.baseCollateral, 1e8) / values[3];
        
        
        uint256 leverage = safeMul(v.price,v.size)/collateral/1e8;
        uint256 coef = safeMul(values[2], 1e10)/leverage;
        
        uint256 fundingCost = safeMul(safeMul(safeMul(v.size, v.price)/1e8, values[0]), values[1])/1e18;
        
        uint256 netLiqPrice;
        uint256 liquidationPrice;
        
        uint256 movement = safeMul(safeSub(collateral, fundingCost), 1e8)/v.size;
        
        
        if (pos[2] == 0)
        {
        
            netLiqPrice = safeAdd(v.price, movement);
            liquidationPrice = safeSub(netLiqPrice, safeMul(v.price, coef)/1e18); 
        }
        else
        {
            netLiqPrice = safeSub(v.price, movement);
            liquidationPrice = safeAdd(netLiqPrice, safeMul(v.price, coef)/1e18); 
        }        
        
        return liquidationPrice;
    }


     
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

     
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
}