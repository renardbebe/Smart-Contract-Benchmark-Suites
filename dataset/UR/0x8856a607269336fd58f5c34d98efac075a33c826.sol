 

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

 
contract EtherMium {
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
    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) returns (bool);
    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) returns (bool);

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
        bool inversed;                   
        bool disabled;                   
    }

    function createFuturesAsset(string name, address baseToken, string priceUrl, string pricePath, bool inversed) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresAsset = keccak256(this, name, baseToken, priceUrl, pricePath, inversed);
        if (futuresAssets[futuresAsset].disabled) throw;  

        futuresAssets[futuresAsset] = FuturesAsset({
            name                : name,
            baseToken           : baseToken,
            priceUrl            : priceUrl,
            pricePath           : pricePath,
            inversed            : inversed,
            disabled            : false
        });

        emit FuturesAssetCreated(futuresAsset, name, baseToken, priceUrl, pricePath, inversed);
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
    }

    function createFuturesContract(bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier) onlyAdmin returns (bytes32)
    {    
        bytes32 futuresContract = keccak256(this, asset, expirationBlock, floorPrice, capPrice, multiplier);
        if (futuresContracts[futuresContract].expirationBlock > 0) return futuresContract;  

        futuresContracts[futuresContract] = FuturesContract({
            asset           : asset,
            expirationBlock : expirationBlock,
            closingPrice    : 0,
            closed          : false,
            broken          : false,
            floorPrice      : floorPrice,
            capPrice        : capPrice,
            multiplier      : multiplier
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

    function getContractPriceUrl (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].priceUrl;
    }

    function getContractPricePath (bytes32 futuresContractHash) returns (string)
    {
        return futuresAssets[futuresContracts[futuresContractHash].asset].pricePath;
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
        FAILED_ASSERTION                 
    }

    event FuturesTrade(bool side, uint256 size, uint256 price, bytes32 indexed futuresContract, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event FuturesPositionClosed(bytes32 indexed positionHash);
    event FuturesContractClosed(bytes32 indexed futuresContract, uint256 closingPrice);
    event FuturesForcedRelease(bytes32 indexed futuresContract, bool side, address user);
    event FuturesAssetCreated(bytes32 indexed futuresAsset, string name, address baseToken, string priceUrl, string pricePath, bool inversed);
    event FuturesContractCreated(bytes32 indexed futuresContract, bytes32 asset, uint256 expirationBlock, uint256 floorPrice, uint256 capPrice, uint256 multiplier);
 
     
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee);

     
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event LogErrorLight(uint8 indexed errorId);
    event LogUint(uint8 id, uint256 value);
    event LogBool(uint8 id, bool value);
    event LogAddress(uint8 id, address value);


     
    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_, address exchangeContract_, address DmexOracleContract_) {
        owner               = msg.sender;
        feeAccount          = feeAccount_;
        makerFee            = makerFee_;
        takerFee            = takerFee_;

        exchangeContract    = exchangeContract_;
        DmexOracleContract    = DmexOracleContract_;
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

 

         
        

        uint256[4] memory balances = EtherMium(exchangeContract).getMakerTakerBalances(t.baseToken, t.maker, t.taker);

         
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

 


         

         
        if (futuresContracts[t.futuresContract].floorPrice >= t.makerPrice || futuresContracts[t.futuresContract].capPrice <= t.makerPrice)
        {
             
            emit LogError(uint8(Errors.FLOOR_OR_CAP_PRICE_REACHED), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }

         
         
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
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            if (inversed)
            {
                return safeMul(safeSub(entryPrice, closingPrice), qty) / closingPrice;  
            }
            else
            {
                return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier)  / 1e8 / 1e18;
            }
            
        }
        else
        {
            if (inversed)
            {
                return safeMul(safeSub(closingPrice, entryPrice), qty) / closingPrice; 
            }
            else
            {
                return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier)  / 1e8 / 1e18; 
            }
        }       
    }

    function calculateTradeValue(uint256 qty, uint256 price, bytes32 futuresContractHash) returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;
        if (inversed)
        {
            return qty * 1e10;
        }
        else
        {
            return safeMul(safeMul(safeMul(qty, price), 1e2), multiplier) / 1e18 ;
        }
    }



    function calculateLoss(uint256 closingPrice, uint256 entryPrice, uint256 qty,  bytes32 futuresContractHash, bool side) returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
            if (inversed)
            {
                return safeMul(safeSub(closingPrice, entryPrice), qty) / closingPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(closingPrice, entryPrice), qty), multiplier) / 1e8 / 1e18;
            }
        }
        else
        {
            if (inversed)
            {
                return safeMul(safeSub(entryPrice, closingPrice), qty) / closingPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(entryPrice, closingPrice), qty), multiplier) / 1e8 / 1e18;
            } 
        }
        
    }

    function calculateCollateral (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, bytes32 futuresContractHash) view returns (uint256)
    {
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
             
            if (inversed)
            {
                return safeMul(safeSub(tradePrice, limitPrice), qty) / limitPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(tradePrice, limitPrice), qty), multiplier) / 1e8 / 1e18;
            }
        }
        else
        {
             
            if (inversed)
            {
                return safeMul(safeSub(limitPrice, tradePrice), qty)  / limitPrice;
            }
            else
            {
                return safeMul(safeMul(safeSub(limitPrice, tradePrice), qty), multiplier) / 1e8 / 1e18;
            }
        }         
    }

    function calculateFee (uint256 qty, uint256 tradePrice, uint256 fee, bytes32 futuresContractHash) returns (uint256)
    {
        return safeMul(calculateTradeValue(qty, tradePrice, futuresContractHash), fee) / 1e18 / 1e10;
    }


    function checkEnoughBalance (uint256 limitPrice, uint256 tradePrice, uint256 qty, bool side, uint256 fee, uint256 gasFee, bytes32 futuresContractHash, uint256 availableBalance) view returns (bool)
    {
        
        bool inversed = futuresAssets[futuresContracts[futuresContractHash].asset].inversed;
        uint256 multiplier = futuresContracts[futuresContractHash].multiplier;

        if (side)
        {
             
            if (safeAdd(
                    safeAdd(
                        calculateCollateral(limitPrice, tradePrice, qty, side, futuresContractHash), 
                         
                        calculateFee(qty, tradePrice, fee, futuresContractHash)
                    ) * 1e10,
                    gasFee 
                ) > availableBalance)
            {
                return false; 
            }
        }
        else
        {
             
            if (safeAdd(
                    safeAdd(
                        calculateCollateral(limitPrice, tradePrice, qty, side, futuresContractHash), 
                         
                        calculateFee(qty, tradePrice, fee, futuresContractHash)
                    ) * 1e10, 
                    gasFee 
                ) > availableBalance)
            {
                return false;
            }

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
        uint256[4][] contractValues
    ) onlyAdmin
    {
         
        for (uint i = 0; i < tradeAddresses.length; i++) {
            futuresTrade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i],
                takerIsBuying[i],
                createFuturesContract(assetHash[i], contractValues[i][0], contractValues[i][1], contractValues[i][2], contractValues[i][3])
            );
        }
    }

    


     
    function updateBalances (bytes32 futuresContract, address[2] addressValues, bytes32 positionHash, uint256[8] uintValues, bool[3] boolValues) private
    {
         

         
         
         


         
        uint256[2] memory pam = [safeAdd(calculateFee(uintValues[0], uintValues[1], uintValues[2], futuresContract) * 1e10, uintValues[6]), 0];
        
         
         
         
         

        

         
        if (boolValues[0] || boolValues[2])  
        {

            if (boolValues[1])
            {

                 
                 
                pam[1] = calculateCollateral(futuresContracts[futuresContract].floorPrice, uintValues[1], uintValues[0], true, futuresContract);

            }
            else
            {
                 
                 
                pam[1] = calculateCollateral(futuresContracts[futuresContract].capPrice, uintValues[1], uintValues[0], false, futuresContract);
            }

            subBalanceAddReserve(addressValues[0], addressValues[1], pam[0], safeAdd(pam[1],1));         

             
             
             
                              
             
             
             

             
             


             

            
         
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


                 
                 
                 
                 
            if (uintValues[3] > 0) 
            {
                 

                if (pam[0] <= uintValues[3]*1e10)
                {
                     
                    addBalanceSubReserve(addressValues[0], addressValues[1], safeSub(uintValues[3]*1e10, pam[0]), pam[1]);
                }
                else
                {
                    subBalanceSubReserve(addressValues[0], addressValues[1], safeSub(pam[0], uintValues[3]*1e10), pam[1]);
                }
                
            } 
            else 
            {   
                

                 
                 
                subBalanceSubReserve(addressValues[0], addressValues[1], safeAdd(uintValues[4]*1e10, pam[0]), pam[1]);  
           
            } 
             
        }          
        
        addBalance(addressValues[0], feeAccount, EtherMium(exchangeContract).balanceOf(addressValues[0], feeAccount), pam[0]);  
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
             
            recordNewPosition(positionHash, size, safeAdd(safeMul(pos[0], pos[1]), safeMul(price, safeSub(size, pos[0]))) / size, pos[2], pos[3]);
        }
        else
        {
             
            recordNewPosition(positionHash, size, pos[1], pos[2], pos[3]);
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

     
    function forceReleaseReserve (bytes32 futuresContract, bool side) public
    {   
        if (futuresContracts[futuresContract].expirationBlock == 0) throw;       
        if (futuresContracts[futuresContract].expirationBlock > block.number) throw;
        if (safeAdd(futuresContracts[futuresContract].expirationBlock, EtherMium(exchangeContract).getInactivityReleasePeriod()) > block.number) throw;  

        bytes32 positionHash = keccak256(this, msg.sender, futuresContract, side);
        if (retrievePosition(positionHash)[1] == 0) throw;    
  

        futuresContracts[futuresContract].broken = true;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        if (side)
        {
            subReserve(
                baseToken, 
                msg.sender, 
                EtherMium(exchangeContract).getReserve(baseToken, msg.sender), 
                 
                calculateCollateral(futuresContracts[futuresContract].floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, futuresContract)
            ); 
        }
        else
        {            
            subReserve(
                baseToken, 
                msg.sender, 
                EtherMium(exchangeContract).getReserve(baseToken, msg.sender), 
                 
                calculateCollateral(futuresContracts[futuresContract].capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, futuresContract)
            ); 
        }

        updatePositionSize(positionHash, 0, 0);

         
         

        emit FuturesForcedRelease(futuresContract, side, msg.sender);

    }

    function addBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        EtherMium(exchangeContract).setBalance(token, user, safeAdd(balance, amount));
    }

    function subBalance(address token, address user, uint256 balance, uint256 amount) private
    {
        EtherMium(exchangeContract).setBalance(token, user, safeSub(balance, amount));
    }

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) private
    {
        EtherMium(exchangeContract).subBalanceAddReserve(token, user, subBalance, addReserve * 1e10);
    }

    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) private
    {

        EtherMium(exchangeContract).addBalanceSubReserve(token, user, addBalance, subReserve * 1e10);
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) private
    {
         
         
         

        EtherMium(exchangeContract).subBalanceSubReserve(token, user, subBalance, subReserve * 1e10);
    }

    function addReserve(address token, address user, uint256 reserve, uint256 amount) private
    {
         
        EtherMium(exchangeContract).setReserve(token, user, safeAdd(reserve, amount * 1e10));
    }

    function subReserve(address token, address user, uint256 reserve, uint256 amount) private 
    {
         
        EtherMium(exchangeContract).setReserve(token, user, safeSub(reserve, amount * 1e10));
    }


    function getMakerTakerBalances(address maker, address taker, address token) public view returns (uint256[4])
    {
        return [
            EtherMium(exchangeContract).balanceOf(token, maker),
            EtherMium(exchangeContract).getReserve(token, maker),
            EtherMium(exchangeContract).balanceOf(token, taker),
            EtherMium(exchangeContract).getReserve(token, taker)
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
    }


    function closeFuturesPosition (bytes32 futuresContract, bool side)
    {
        bytes32 positionHash = keccak256(this, msg.sender, futuresContract, side);

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw;  
        if (retrievePosition(positionHash)[1] == 0) throw;  
        if (retrievePosition(positionHash)[0] == 0) throw;  

        uint256 profit;
        uint256 loss;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            reserve         : EtherMium(exchangeContract).getReserve(baseToken, msg.sender),
            balance         : EtherMium(exchangeContract).balanceOf(baseToken, msg.sender),
            floorPrice      : futuresContracts[futuresContract].floorPrice,
            capPrice        : futuresContracts[futuresContract].capPrice,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract
        });

         
         
         
         
         


        
         
        uint256 fee = calculateFee(retrievePosition(positionHash)[0], v.closingPrice, takerFee, futuresContract);



         
        if (side == true)
        {            

             
             
             
             
             
            
            
            subReserve(
                baseToken, 
                msg.sender, 
                v.reserve, 
                 
                calculateCollateral(v.floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, v.futuresContract)
            );
             
             
            
            

            if (v.closingPrice > retrievePosition(positionHash)[1])
            {
                 
                 
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);
                


                 
                 
                 
                 
                if (profit > fee)
                {
                    addBalance(baseToken, msg.sender, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, msg.sender, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                 
                 
            }
            else
            {
                 
                 
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);  


                subBalance(baseToken, msg.sender, v.balance, safeAdd(loss * 1e10, fee * 1e10));
                 
            }
        }   
         
        else
        {
             
             
             

             
            subReserve(
                baseToken, 
                msg.sender,  
                v.reserve, 
                 
                calculateCollateral(v.capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, v.futuresContract)
            );
             
             
            
            

            if (v.closingPrice < retrievePosition(positionHash)[1])
            {
                 
                 
                 
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);

                if (profit > fee)
                {
                    addBalance(baseToken, msg.sender, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, msg.sender, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }

                 
            }
            else
            {
                 
                 
                 
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);  

                subBalance(baseToken, msg.sender, v.balance, safeAdd(loss * 1e10, fee * 1e10));

                 
            }
        }  

        addBalance(baseToken, feeAccount, EtherMium(exchangeContract).balanceOf(baseToken, feeAccount), fee * 1e10);  
        updatePositionSize(positionHash, 0, 0);

        emit FuturesPositionClosed(positionHash);
    }

    function closeFuturesContract (bytes32 futuresContract, uint256 price) onlyOracle returns (bool)
    {
        if (futuresContracts[futuresContract].expirationBlock == 0)  return false;  
        if (futuresContracts[futuresContract].closed == true)  return false;  

        if (futuresContracts[futuresContract].expirationBlock > block.number
            && price > futuresContracts[futuresContract].floorPrice
            && price < futuresContracts[futuresContract].capPrice) return false;  
                

        if (price <= futuresContracts[futuresContract].floorPrice)  
        {
            futuresContracts[futuresContract].closingPrice = futuresContracts[futuresContract].floorPrice; 
        }  
        else if (price >= futuresContracts[futuresContract].capPrice)
        {
            futuresContracts[futuresContract].closingPrice = futuresContracts[futuresContract].capPrice;
        }   
        else
        {
            futuresContracts[futuresContract].closingPrice = price;
        }         
        

        futuresContracts[futuresContract].closed = true;

        emit FuturesContractClosed(futuresContract, price);
    }  

     
    function closeFuturesPositionForUser (bytes32 futuresContract, bool side, address user, uint256 gasFee) onlyAdmin
    {
        bytes32 positionHash = keccak256(this, user, futuresContract, side);

        if (futuresContracts[futuresContract].closed == false && futuresContracts[futuresContract].expirationBlock != 0) throw;  
        if (retrievePosition(positionHash)[1] == 0) throw;  
        if (retrievePosition(positionHash)[0] == 0) throw;  

         
        if (safeMul(gasFee * 1e10, 20) > calculateTradeValue(retrievePosition(positionHash)[0], retrievePosition(positionHash)[1], futuresContract))
        {
            emit LogError(uint8(Errors.GAS_TOO_HIGH), futuresContract, positionHash);
            return;
        }


        uint256 profit;
        uint256 loss;

        address baseToken = futuresAssets[futuresContracts[futuresContract].asset].baseToken;

        FuturesClosePositionValues memory v = FuturesClosePositionValues({
            reserve         : EtherMium(exchangeContract).getReserve(baseToken, user),
            balance         : EtherMium(exchangeContract).balanceOf(baseToken, user),
            floorPrice      : futuresContracts[futuresContract].floorPrice,
            capPrice        : futuresContracts[futuresContract].capPrice,
            closingPrice    : futuresContracts[futuresContract].closingPrice,
            futuresContract : futuresContract
        });

         
         
         
         
         


        
         
        uint256 fee = safeAdd(calculateFee(retrievePosition(positionHash)[0], v.closingPrice, takerFee, futuresContract), gasFee);

         
        if (side == true)
        {            

             
             
             
             
             
            
            
            subReserve(
                baseToken, 
                user, 
                v.reserve, 
                 
                calculateCollateral(v.floorPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], true, v.futuresContract)
            );
             
             
            
            

            if (v.closingPrice > retrievePosition(positionHash)[1])
            {
                 
                 
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);
                


                 
                 
                 
                 
                if (profit > fee)
                {
                    addBalance(baseToken, user, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                 
                 
            }
            else
            {
                 
                 
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, false);  


                subBalance(baseToken, user, v.balance, safeAdd(loss * 1e10, fee * 1e10));
                 
            }
        }   
         
        else
        {
             
             
             

             
            subReserve(
                baseToken, 
                user,  
                v.reserve, 
                 
                calculateCollateral(v.capPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], false, v.futuresContract)
            );
             
             
            
            

            if (v.closingPrice < retrievePosition(positionHash)[1])
            {
                 
                 
                 
                profit = calculateProfit(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);

                if (profit > fee)
                {
                    addBalance(baseToken, user, v.balance, safeSub(profit * 1e10, fee * 1e10)); 
                }
                else
                {
                    subBalance(baseToken, user, v.balance, safeSub(fee * 1e10, profit * 1e10)); 
                }
                

                 
            }
            else
            {
                 
                 
                 
                loss = calculateLoss(v.closingPrice, retrievePosition(positionHash)[1], retrievePosition(positionHash)[0], futuresContract, true);  

                subBalance(baseToken, user, v.balance, safeAdd(loss * 1e10, fee * 1e10));

                 
            }
        }  

        addBalance(baseToken, feeAccount, EtherMium(exchangeContract).balanceOf(baseToken, feeAccount), fee * 1e10);  
        updatePositionSize(positionHash, 0, 0);

        emit FuturesPositionClosed(positionHash);
    }

     
    function batchSettlePositions (
        bytes32[] futuresContracts,
        bool[] sides,
        address[] users,
        uint256 gasFeePerClose  
    ) onlyAdmin {
        
        for (uint i = 0; i < futuresContracts.length; i++) 
        {
            closeFuturesPositionForUser(futuresContracts[i], sides[i], users[i], gasFeePerClose);
        }
    }



    
    

     
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}