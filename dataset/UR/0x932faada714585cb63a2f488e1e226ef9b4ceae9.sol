 

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
    function addBalanceAddReserve(address token, address user, uint256 addBalance, uint256 addReserve) returns (bool);
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
    
    address public feeAccount;           
    address public exchangeContract;     
    address public DmexOracleContract;     

    uint256 public makerFee;             
    uint256 public takerFee;             
    
    struct FuturesAsset {
        string name;                     
        address baseToken;               
        string priceUrl;                 
        string pricePath;                
        bool disabled;                   
        uint256 maintenanceMargin;       
        uint256 decimals;                
    }

    function createFuturesAsset(string name, address baseToken, string priceUrl, string pricePath, uint256 maintenanceMargin, uint256 decimals) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresAsset = keccak256(this, name, baseToken, priceUrl, pricePath, maintenanceMargin, decimals);
        if (futuresAssets[futuresAsset].disabled) throw;  

        futuresAssets[futuresAsset] = FuturesAsset({
            name                : name,
            baseToken           : baseToken,
            priceUrl            : priceUrl,
            pricePath           : pricePath,
            disabled            : false,
            maintenanceMargin   : maintenanceMargin,
            decimals            : decimals
        });

        emit FuturesAssetCreated(futuresAsset, name, baseToken, priceUrl, pricePath);
        return futuresAsset;
    }
    
    struct FuturesContract {
        bytes32 asset;                   
        uint256 expirationBlock;         
        uint256 closingPrice;            
        bool closed;                     
        bool broken;                     
        uint256 floorPrice;              
        uint256 capPrice;                
        uint256 multiplier;              
        uint256 fundingRate;             
        uint256 closingBlock;            
    }

    function createFuturesContract(bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier, uint256 fundingRate) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresContract = keccak256(this, asset, expirationBlock, floorPrice, capPrice, multiplier, fundingRate);
        if (futuresContracts[futuresContract].expirationBlock > 0) return futuresContract;  

        futuresContracts[futuresContract] = FuturesContract({
            asset           : asset,
            expirationBlock : expirationBlock,
            closingPrice    : 0,
            closed          : false,
            broken          : false,
            floorPrice      : floorPrice,
            capPrice        : capPrice,
            multiplier      : multiplier,
            fundingRate     : fundingRate,
            closingBlock    : 0
        });

        emit FuturesContractCreated(futuresContract, asset, expirationBlock, floorPrice, capPrice, multiplier);

        return futuresContract;
    }

    function getContractExpiration (bytes32 futuresContractHash) view returns (uint256)
    {
        return futuresContracts[futuresContractHash].expirationBlock;
    }

    function getContractClosed (bytes32 futuresContractHash) returns (bool)
    {
        return futuresContracts[futuresContractHash].closed;
    }

    function getAssetDecimals (bytes32 futuresContractHash) returns (uint256)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].decimals;
    }

    function getContractPriceUrl (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].priceUrl;
    }

    function getContractPricePath (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].pricePath;
    }

    function getFloorPrice (bytes32 futuresContractHash) returns (uint256) {
        return futuresContracts[futuresContractHash].floorPrice;
    }

    function getCapPrice (bytes32 futuresContractHash) returns (uint256) {
        return futuresContracts[futuresContractHash].capPrice;
    }

    function getMaintenanceMargin (bytes32 futuresContractHash) returns (uint256)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].maintenanceMargin;
    }

    function setClosingPrice (bytes32 futuresContractHash, uint256 price) onlyOracle returns (bool) {
        if (futuresContracts[futuresContractHash].closingPrice != 0) revert();
        futuresContracts[futuresContractHash].closingPrice = price;
        futuresContracts[futuresContractHash].closed = true;
        futuresContracts[futuresContractHash].closingBlock = block.number;

        return true;
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
         WRONG_FUNDING_RATE
    }

    event FuturesTrade(bool side, uint256 size, uint256 price, bytes32 indexed futuresContract, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event FuturesPositionClosed(bytes32 indexed positionHash, uint256 closingPrice);
    event FuturesForcedRelease(bytes32 indexed futuresContract, bool side, address user);
    event FuturesAssetCreated(bytes32 indexed futuresAsset, string name, address baseToken, string priceUrl, string pricePath);
    event FuturesContractCreated(bytes32 indexed futuresContract, bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier);
 
     
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee);

     
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
     
    event LogUint(uint8 id, uint256 value);
     
     


     
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
        uint256 takerGasFee;                 
        uint256 takerIsBuying;               

        address maker;                       
        address taker;                       

        bytes32 makerOrderHash;              
        bytes32 takerOrderHash;              

        uint256 makerAmount;                 
        uint256 takerAmount;                 

        uint256 makerPrice;                  
        uint256 takerPrice;                  

        bytes32 futuresContract;             

        address baseToken;                   
        uint256 floorPrice;                  
        uint256 capPrice;                    

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
    }

     
    function futuresTrade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[8] tradeValues,
        address[2] tradeAddresses,
        bool takerIsBuying,
        bytes32 futuresContractHash
    ) onlyAdmin returns (uint filledTakerTokenAmount)
    {
         

        FuturesOrderPair memory t  = FuturesOrderPair({
            makerNonce      : tradeValues[0],
            takerNonce      : tradeValues[1],
            takerGasFee     : tradeValues[2],
            takerIsBuying   : tradeValues[3],
            makerAmount     : tradeValues[4],      
            takerAmount     : tradeValues[5],   
            makerPrice      : tradeValues[6],         
            takerPrice      : tradeValues[7],

            maker           : tradeAddresses[0],
            taker           : tradeAddresses[1],

             
            makerOrderHash  : keccak256(this, futuresContractHash, tradeAddresses[0], tradeValues[4], tradeValues[6], !takerIsBuying, tradeValues[0]),
            takerOrderHash  : keccak256(this, futuresContractHash, tradeAddresses[1], tradeValues[5], tradeValues[7],  takerIsBuying, tradeValues[1]),            

            futuresContract : futuresContractHash,

            baseToken       : futuresAssets[futuresContracts[futuresContractHash].asset].baseToken,
            floorPrice      : futuresContracts[futuresContractHash].floorPrice,
            capPrice        : futuresContracts[futuresContractHash].capPrice,

             
            makerPositionHash           : keccak256(this, tradeAddresses[0], futuresContractHash, !takerIsBuying),
            makerInversePositionHash    : keccak256(this, tradeAddresses[0], futuresContractHash, takerIsBuying),

            takerPositionHash           : keccak256(this, tradeAddresses[1], futuresContractHash, takerIsBuying),
            takerInversePositionHash    : keccak256(this, tradeAddresses[1], futuresContractHash, !takerIsBuying)

        });

 
    
         
        if (!validateUint128(t.makerAmount) || !validateUint128(t.takerAmount) || !validateUint64(t.makerPrice) || !validateUint64(t.takerPrice))
        {            
            emit LogError(uint8(Errors.UINT48_VALIDATION), t.makerOrderHash, t.takerOrderHash);
            return 0; 
        }


         
        if (block.number > futuresContracts[t.futuresContract].expirationBlock || futuresContracts[t.futuresContract].closed == true || futuresContracts[t.futuresContract].broken == true)
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
            takerReserve        : balances[3] 
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

       



 
        
        if (tv.qty == 0)
        {
             
            emit LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

         
        if (safeMul(t.takerGasFee, 20) > calculateTradeValue(tv.qty, t.makerPrice, t.futuresContract))
        {
            emit LogError(uint8(Errors.GAS_TOO_HIGH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }  


 
        

       

         
        if (!takerIsBuying)
        {     
            
      
             
            if (!positionExists(t.makerInversePositionHash) && !positionExists(t.makerPositionHash))
            {


                 
                if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                
                
                 
                recordNewPosition(t.makerPositionHash, tv.qty, t.makerPrice, 1, block.number);



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
                        makerFee,  
                        0,  
                        0,  
                        tv.makerBalance,  
                        0,  
                        tv.makerReserve  
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
                     
                    if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                    updatePositionSize(t.makerPositionHash, safeAdd(retrievePosition(t.makerPositionHash)[0], tv.qty), t.makerPrice);
                
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
                            makerFee,  
                            0,  
                            0,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve  
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

                     
                    updatePositionSize(t.makerInversePositionHash, safeSub(retrievePosition(t.makerInversePositionHash)[0], tv.qty), 0);
                    
                    

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
                            makerFee,  
                            tv.makerProfit,   
                            tv.makerLoss,   
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve  
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
                
                 
                if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }
                
                 
                recordNewPosition(t.takerPositionHash, tv.qty, t.makerPrice, 0, block.number);
                
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
                        takerFee,  
                        0,  
                        0,   
                        tv.takerBalance,   
                        t.takerGasFee,  
                        tv.takerReserve  
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
                     
                     
                    if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                    updatePositionSize(t.takerPositionHash, safeAdd(retrievePosition(t.takerPositionHash)[0], tv.qty), t.makerPrice);
                
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
                            takerFee,  
                            0,  
                            0,  
                            tv.takerBalance,  
                            t.takerGasFee,  
                            tv.takerReserve  
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
                     
                    updatePositionSize(t.takerInversePositionHash, safeSub(retrievePosition(t.takerInversePositionHash)[0], tv.qty), 0);
                    
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
                            takerFee,  
                            tv.takerProfit,  
                            tv.takerLoss,  
                            tv.takerBalance,   
                            t.takerGasFee,   
                            tv.takerReserve  
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
                 
                if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                 
                recordNewPosition(t.makerPositionHash, tv.qty, t.makerPrice, 0, block.number);
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
                        makerFee,  
                        0,  
                        0,  
                        tv.makerBalance,  
                        0,  
                        tv.makerReserve  
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
                     
                    if (!checkEnoughBalance(t.capPrice, t.makerPrice, tv.qty, false, makerFee, 0, futuresContractHash, safeSub(balances[0],tv.makerReserve)))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }

                     
                    updatePositionSize(t.makerPositionHash, safeAdd(retrievePosition(t.makerPositionHash)[0], tv.qty), t.makerPrice);
                
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
                            makerFee,  
                            0,  
                            0,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve  
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

                     
                    updatePositionSize(t.makerInversePositionHash, safeSub(retrievePosition(t.makerInversePositionHash)[0], tv.qty), 0);       
                    


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
                            makerFee,  
                            tv.makerProfit,   
                            tv.makerLoss,  
                            tv.makerBalance,  
                            0,  
                            tv.makerReserve  
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
                 
                if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                {
                     
                    emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                    return 0; 
                }

                 
                recordNewPosition(t.takerPositionHash, tv.qty, t.makerPrice, 1, block.number);
           
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
                        takerFee,  
                        0,   
                        0,   
                        tv.takerBalance,  
                        t.takerGasFee,  
                        tv.takerReserve  
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
                     
                    if (!checkEnoughBalance(t.floorPrice, t.makerPrice, tv.qty, true, takerFee, t.takerGasFee, futuresContractHash, safeSub(balances[1],tv.takerReserve)))
                    {
                         
                        emit LogError(uint8(Errors.OUT_OF_BALANCE), t.makerOrderHash, t.takerOrderHash);
                        return 0; 
                    }
                    
                     
                    updatePositionSize(t.takerPositionHash, safeAdd(retrievePosition(t.takerPositionHash)[0], tv.qty), t.makerPrice);
                
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
                            takerFee,  
                            0,  
                            0,  
                            tv.takerBalance,  
                            t.takerGasFee,  
                            tv.takerReserve  
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

                     
                    updatePositionSize(t.takerInversePositionHash, safeSub(retrievePosition(t.takerInversePositionHash)[0], tv.qty), 0);
                                     
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
                            takerFee,  
                            tv.takerProfit,  
                            tv.takerLoss,  
                            tv.takerBalance,  
                            t.takerGasFee,  
                            tv.takerReserve  
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


    function calculateProfit(uint256 closingPrice, uint256 entryPrice, uint256 qty, bytes32 futuresContractHash, bool side) returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {           
            return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier / 1e10)  / 1e16;            
        }
        else
        {
            return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier / 1e10)  / 1e16; 
        }       
    }

    function calculateTradeValue(uint256 qty, uint256 price, bytes32 futuresContractHash) returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        return safeMul(safeMul(safeMul(qty, price), 1e2), multiplier) / 1e18 ;
    }



    function calculateLoss(uint256 closingPrice, uint256 entryPrice, uint256 qty,  bytes32 futuresContractHash, bool side) returns (uint256)
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier/ 1e10) / 1e16 ;
        }
        else
        {
            return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier/ 1e10) / 1e16 ; 
        }
        
    }

    function calculateCollateral (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, bytes32 futuresContractHash) view returns (uint256)  
    {
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        uint256 fundingCost;
        uint256 collateral;

        if (side)
        {    
             
            collateral = safeMul(safeMul(safeSub(tradePrice, limitPrice), qty), multiplier / 1e10) / 1e16;

            return collateral;  
        }
        else
        {
             
            collateral = safeMul(safeMul(safeSub(limitPrice, tradePrice), qty), multiplier / 1e10) / 1e16;
            
            return collateral;  
        }         
    }

    function calculateFundingCost (uint256 price, uint256 qty, uint256 fundingBlocks, bytes32 futuresContractHash) returns (uint256)  
    {
        uint256 fundingRate = futuresContracts[futuresContractHash].fundingRate;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        uint256 fundingCost = safeMul(safeMul(safeMul(fundingBlocks, fundingRate), safeMul(qty, price)/1e8)/1e8, multiplier/1e10)/1e18
        ;

        return fundingCost;  
    }

    function calculateFee (uint256 qty, uint256 tradePrice, uint256 fee, bytes32 futuresContractHash) returns (uint256)
    {
        return safeMul(calculateTradeValue(qty, tradePrice, futuresContractHash), fee / 1e10) / 1e18;
    }


    function checkEnoughBalance (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, uint256 fee, uint256 gasFee, bytes32 futuresContractHash, uint256 availableBalance) view returns (bool)
    {
        
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        uint256 expirationBlock = futuresContracts[futuresContractHash].expirationBlock;

        uint256 tradeFee = calculateFee(qty, tradePrice, fee, futuresContractHash);
        uint256 collateral = calculateCollateral(limitPrice, tradePrice, qty, side, futuresContractHash);
        uint256 fundingCost = calculateFundingCost(tradePrice, qty, safeSub(expirationBlock, min(block.number, expirationBlock)), futuresContractHash);

        if (safeAdd(
                safeMul(
                    safeAdd(
                        collateral, 
                        tradeFee
                    ),
                    1e10
                ),                     
                safeAdd(
                    gasFee,
                    safeMul(
                        fundingCost,
                        1e10
                    )                        
                ) 
            ) > availableBalance)
        {
            return false;
        }

        return true;
    }  

      

     
    function batchFuturesTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[8][] tradeValues,
        address[2][] tradeAddresses,
        bool[] takerIsBuying,
        bytes32[] assetHash,
        uint256[5][] contractValues
    ) onlyAdmin
    {
         
        for (uint i = 0; i < tradeAddresses.length; i++) {
            futuresTrade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i],
                takerIsBuying[i],
                createFuturesContract(assetHash[i], contractValues[i][0], contractValues[i][1], contractValues[i][2], contractValues[i][3], contractValues[i][4])
            );
        }
    }

    


     
    function updateBalances (bytes32 futuresContract, address[2] addressValues, bytes32 positionHash, uint256[8] uintValues, bool[3] boolValues) private
    {
         

         
        uint256[3] memory pam = [
            safeAdd(calculateFee(uintValues[0], uintValues[1], uintValues[2], futuresContract) * 1e10, uintValues[6]), 
            0,
            0
        ];
               
        if (boolValues[0] || boolValues[2])  
        {
            if (pools[addressValues[1]]) return;
             
            if (boolValues[1])
            {
                pam[1] = calculateCollateral(futuresContracts[futuresContract].floorPrice, uintValues[1], uintValues[0], true, futuresContract);
            }
            else
            {
                pam[1] = calculateCollateral(futuresContracts[futuresContract].capPrice, uintValues[1], uintValues[0], false, futuresContract);
            }

            pam[2] = calculateFundingCost(uintValues[1], uintValues[0], safeSub(futuresContracts[futuresContract].expirationBlock, block.number+1), futuresContract);


            subBalanceAddReserve(addressValues[0], addressValues[1], pam[0], safeAdd(safeAdd(pam[1], pam[2]),1));         
            pam[2] = 0;
        } 
        else 
        {
             
            if (retrievePosition(positionHash)[2] == 0)
            {
                 
                pam[1] = calculateCollateral(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1], uintValues[0], false, futuresContract);                          
            }
            else
            {                            
                 
                pam[1] = calculateCollateral(futuresContracts[futuresContract].floorPrice, retrievePosition(positionHash)[1], uintValues[0], true, futuresContract);
            }

            pam[2] = calculateFundingCost(retrievePosition(positionHash)[1], uintValues[0], safeSub(futuresContracts[futuresContract].expirationBlock, retrievePosition(positionHash)[3]+2), futuresContract);   

            if (pools[addressValues[1]]) {
                pam[0] = 0;
                pam[1] = 0;
                pam[2] = 0;
            }

            if (uintValues[3] > 0) 
            {
                 
                if (safeAdd(pam[0], pam[2]*1e10) <= safeMul(uintValues[3],1e10))
                {
                    addBalanceSubReserve(addressValues[0], addressValues[1], safeSub(safeMul(uintValues[3],1e10), safeAdd(pam[0], pam[2]*1e10)), safeAdd(pam[1], pam[2]));
                }
                else
                {
                    subBalanceSubReserve(addressValues[0], addressValues[1], safeSub(safeAdd(pam[0], pam[2]*1e10), safeMul(uintValues[3],1e10)), safeAdd(pam[1], pam[2]));
                }                
            } 
            else 
            {   
                 
                subBalanceSubReserve(addressValues[0], addressValues[1], safeAdd(safeMul(uintValues[4],1e10), safeAdd(pam[0], pam[2]*1e10)), safeAdd(pam[1], pam[2]));  
            }     

        }          
        
        addBalance(addressValues[0], feeAccount, DMEX_Base(exchangeContract).balanceOf(addressValues[0], feeAccount), safeAdd(pam[0], pam[2]*1e10));  
    }

    function recordNewPosition (bytes32 positionHash, uint256 size, uint256 price, uint256 side, uint256 block) private
    {
        if (!validateUint128(size) || !validateUint64(price)) 
        {
            throw;
        }

        uint256 character = uint128(size);
        character |= price<<128;
        character |= side<<192;
        character |= block<<208;

        positions[positionHash] = character;
    }

    function retrievePosition (bytes32 positionHash) public view returns (uint256[4])
    {
        uint256 character = positions[positionHash];
        uint256 size = uint256(uint128(character));
        uint256 price = uint256(uint64(character>>128));
        uint256 side = uint256(uint16(character>>192));
        uint256 entryBlock = uint256(uint48(character>>208));

        return [size, price, side, entryBlock];
    }

    function updatePositionSize(bytes32 positionHash, uint256 size, uint256 price) private
    {
        uint256[4] memory pos = retrievePosition(positionHash);

        if (size > pos[0])
        {
            uint256 totalValue = safeAdd(safeMul(pos[0], pos[1]), safeMul(price, safeSub(size, pos[0])));

             
            recordNewPosition(
                positionHash, 
                size, 
                totalValue / size, 
                pos[2], 
                safeAdd(safeMul(safeMul(pos[0], pos[1]), pos[3]), safeMul(safeMul(price, safeSub(size, pos[0])), block.number)) / totalValue  
            );
        }
        else
        {
             
            recordNewPosition(
                positionHash, 
                size, 
                pos[1], 
                pos[2], 
                pos[3]
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
        if (pools[user]) return;

        bytes32 positionHash = keccak256(this, user, futuresContract, side);
        if (retrievePosition(positionHash)[1] == 0) throw;    
  

        futuresContracts[futuresContract].broken = true;

        uint256[4] memory pos = retrievePosition(positionHash);
        FuturesContract cont = futuresContracts[futuresContract];
        address baseToken = futuresAssets[cont.asset].baseToken;

        uint256 reservedFunding = calculateFundingCost(pos[1], pos[0], safeSub(cont.expirationBlock, pos[3]+1), futuresContract);
        uint256 collateral;

        if (side)
        {
            collateral = calculateCollateral(cont.floorPrice, pos[1], pos[0], true, futuresContract);

            subReserve(
                baseToken, 
                user, 
                DMEX_Base(exchangeContract).getReserve(baseToken, user), 
                safeAdd(reservedFunding, collateral)
            ); 
        }
        else
        {         
            collateral = calculateCollateral(cont.capPrice, pos[1], pos[0], false, futuresContract);
               
            subReserve(
                baseToken, 
                user, 
                DMEX_Base(exchangeContract).getReserve(baseToken, user), 
                safeAdd(reservedFunding, collateral)
            ); 
        }

        updatePositionSize(positionHash, 0, 0);

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

    function addBalanceAddReserve(address token, address user, uint256 addBalance, uint256 addReserve) private
    {
        DMEX_Base(exchangeContract).addBalanceAddReserve(token, user, addBalance, safeMul(addReserve, 1e10));
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) private
    {
        DMEX_Base(exchangeContract).subBalanceSubReserve(token, user, subBalance, safeMul(subReserve, 1e10));
    }

    function addReserve(address token, address user, uint256 reserve, uint256 amount) private
    {
        DMEX_Base(exchangeContract).setReserve(token, user, safeAdd(reserve, safeMul(amount, 1e10)));
    }

    function subReserve(address token, address user, uint256 reserve, uint256 amount) private 
    {
        DMEX_Base(exchangeContract).setReserve(token, user, safeSub(reserve, safeMul(amount, 1e10)));
    }


    function getMakerTakerBalances(address maker, address taker, address token) public view returns (uint256[4])
    {
        return [
            DMEX_Base(exchangeContract).balanceOf(token, maker),
            DMEX_Base(exchangeContract).getReserve(token, maker),
            DMEX_Base(exchangeContract).balanceOf(token, taker),
            DMEX_Base(exchangeContract).getReserve(token, taker)
        ];
    }

    function getMakerTakerPositions(bytes32 makerPositionHash, bytes32 makerInversePositionHash, bytes32 takerPosition, bytes32 takerInversePosition) public view returns (uint256[4][4])
    {
        return [
            retrievePosition(makerPositionHash),
            retrievePosition(makerInversePositionHash),
            retrievePosition(takerPosition),
            retrievePosition(takerInversePosition)
        ];
    }


    struct FuturesClosePositionValues {
        uint256 reserve;                 
        uint256 balance;                 
        uint256 floorPrice;              
        uint256 capPrice;                
        uint256 closingPrice;            
        bytes32 futuresContract;         
        uint256 expirationBlock;         
        uint256 entryBlock;              
        uint256 collateral;              
        uint256 reservedFunding;         
        uint256 payableFunding;          
        uint256 totalPayable;
        uint256 settlePrice;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 closingBlock;
    }


    function closeFuturesPosition(bytes32 futuresContract, bool side)
    {
        closeFuturesPositionInternal(futuresContract, side, msg.sender);
    }

    function closeFuturesPositionInternal (bytes32 futuresContract, bool side, address user) private returns (bool)
    {
        bytes32 positionHash = keccak256(this, user, futuresContract, side);        

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw;  
        if (retrievePosition(positionHash)[1] == 0) throw;  
        if (retrievePosition(positionHash)[0] == 0) throw;  


        uint256 profit;
        uint256 loss;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;
        uint256[2] memory marginInfo = getLowerUpperLimit(futuresContract);

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            reserve         : DMEX_Base(exchangeContract).getReserve(baseToken, user),
            balance         : DMEX_Base(exchangeContract).balanceOf(baseToken, user),
            floorPrice      : futuresContracts[futuresContract].floorPrice,
            capPrice        : futuresContracts[futuresContract].capPrice,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract,
            expirationBlock : futuresContracts[futuresContract].expirationBlock,
            entryBlock      : retrievePosition(positionHash)[3],
            collateral      : 0,
            reservedFunding : 0,
            payableFunding  : 0,
            totalPayable    : 0,
            settlePrice     : 0,
            lowerLimit      : marginInfo[0],
            upperLimit      : marginInfo[1],
            closingBlock    : futuresContracts[futuresContract].closingBlock
        });

        
         
        uint256 fee = 0; 


         
        if (side == true)
        {     
            if (!pools[user]) {
                v.collateral = calculateCollateral(v.floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, v.futuresContract);
                v.reservedFunding = calculateFundingCost(retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], safeSub(v.expirationBlock, v.entryBlock+1), futuresContract);
                v.payableFunding = calculateFundingCost(retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], safeSub(min(v.expirationBlock, v.closingBlock), v.entryBlock+1), futuresContract);


                subReserve(
                    baseToken, 
                    user, 
                    v.reserve, 
                    safeAdd(v.collateral, v.reservedFunding)
                );  
            }
            
            
            v.totalPayable = v.payableFunding;  

            if (v.closingPrice > retrievePosition(positionHash)[1])
            {   
                 
                if (pools[user]) {
                    v.settlePrice = min(v.closingPrice, v.capPrice);
                }
                else
                {
                    v.settlePrice = v.closingPrice;
                }

                profit = calculateProfit(v.settlePrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);
          
                if (profit > v.totalPayable)
                {
                    addBalance(baseToken, user, v.balance, safeSub(safeMul(profit, 1e10), safeMul(v.totalPayable, 1e10))); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(safeMul(v.totalPayable, 1e10), safeMul(profit, 1e10))); 
                }
            }
            else
            {
                 
                if (!pools[user]) {
                    v.settlePrice = v.closingPrice <= v.lowerLimit ? v.floorPrice : v.closingPrice;
                }
                else
                {
                    v.settlePrice = v.closingPrice;
                }

                loss = calculateLoss(v.settlePrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);  

                subBalance(baseToken, user, v.balance, safeAdd(safeMul(loss, 1e10), safeMul(v.totalPayable, 1e10))); 

            }
        }   
         
        else
        {
            if (!pools[user]) {
                v.collateral = calculateCollateral(v.capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, v.futuresContract);
                v.reservedFunding = calculateFundingCost(retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], safeSub(v.expirationBlock, v.entryBlock+1), futuresContract);
                v.payableFunding = calculateFundingCost(retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], safeSub(min(v.expirationBlock, v.closingBlock), v.entryBlock+1), futuresContract);


                subReserve(
                    baseToken, 
                    user,  
                    v.reserve, 
                    safeAdd(v.collateral, v.reservedFunding)
                );
            }

            v.totalPayable = v.payableFunding; 

            if (v.closingPrice < retrievePosition(positionHash)[1])
            {
                 
                if (pools[user]) {
                    v.settlePrice = max(v.closingPrice, v.floorPrice);
                }
                else
                {
                    v.settlePrice = v.closingPrice;
                }

                profit = calculateProfit(v.settlePrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);
 
                if (profit > v.totalPayable)
                {
                    addBalance(baseToken, user, v.balance, safeSub(safeMul(profit, 1e10), safeMul(v.totalPayable, 1e10))); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(safeMul(v.totalPayable, 1e10), safeMul(profit, 1e10))); 
                }

            }
            else
            {
                 
                if (!pools[user]) {
                    v.settlePrice = v.closingPrice >= v.upperLimit ? v.capPrice : v.closingPrice;
                }
                else
                {
                    v.settlePrice = v.closingPrice;
                }

                loss = calculateLoss(v.settlePrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);  

                subBalance(baseToken, user, v.balance, safeAdd(safeMul(loss, 1e10), safeMul( v.totalPayable, 1e10)));

            }
        }  

        addBalance(baseToken, feeAccount, DMEX_Base(exchangeContract).balanceOf(baseToken, feeAccount), safeMul(v.totalPayable, 1e10));  
        

        updatePositionSize(positionHash, 0, 0);        

        emit FuturesPositionClosed(positionHash, v.closingPrice);

        return true;
    }

    function getLowerUpperLimit(bytes32 futuresContract) public view returns (uint256[2])
    {
        uint256 maintenanceMargin = getMaintenanceMargin(futuresContract);

        uint256 floorPrice = futuresContracts[futuresContract].floorPrice;
        uint256 capPrice = futuresContracts[futuresContract].capPrice;

        uint256[2] memory marginInfo = extractMargin(floorPrice, capPrice);
        
        uint256 lowerLimit =    safeAdd(
                                    floorPrice, 
                                    safeMul(
                                        marginInfo[0], 
                                        maintenanceMargin / marginInfo[1]
                                    ) / 1e18
                                );


        uint256 upperLimit =    safeSub(
                                    capPrice, 
                                    safeMul(
                                        marginInfo[0], 
                                        maintenanceMargin / marginInfo[1]
                                    ) / 1e18
                                );

        return [lowerLimit, upperLimit];
    }

    function extractMargin (uint256 floorPrice, uint256 capPrice) public view returns (uint256[2])
    {
        uint256 halfRange = safeSub(capPrice, floorPrice)/2;
        return [safeAdd(halfRange, floorPrice), safeAdd(halfRange, floorPrice) / halfRange];    
    }

     
    function closeFuturesPositionForUser (bytes32 futuresContract, bool side, address user) onlyAdmin
    {
        closeFuturesPositionInternal(futuresContract, side, user);
    }

     
    function batchSettlePositions (
        bytes32[] futuresContracts,
        bool[] sides,
        address[] users
    ) onlyAdmin {
        
        for (uint i = 0; i < futuresContracts.length; i++) 
        {
            closeFuturesPositionForUser(futuresContracts[i], sides[i], users[i]);
        }
    }

     
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

     
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
}