 

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

contract dexBlueEvents{
     

     
    event LogTrade(address makerAsset, uint256 makerAmount, address takerAsset, uint256 takerAmount);
    
     
    event LogSwap(address soldAsset, uint256 soldAmount, address boughtAsset, uint256 boughtAmount);

     
    event LogTradeFailed();

     
    event LogDeposit(address account, address token, uint256 amount);

     
    event LogWithdrawal(address account, address token, uint256 amount);

     
    event LogDirectWithdrawal(address account, address token, uint256 amount);

     
    event LogBlockedForSingleSigWithdrawal(address account, address token, uint256 amount);

     
    event LogSingleSigWithdrawal(address account, address token, uint256 amount);

     
    event LogOrderCanceled(bytes32 hash);
   
     
    event LogDelegateStatus(address delegator, address delegate, bool status);
}

contract dexBlueStorage{
     

    mapping(address => mapping(address => uint256)) balances;                            
    mapping(address => mapping(address => uint256)) blocked_for_single_sig_withdrawal;   
    mapping(address => uint256) last_blocked_timestamp;                                  
    
    mapping(bytes32 => bool) processed_withdrawals;                                      
    mapping(bytes32 => uint256) matched;                                                 
    
    mapping(address => address) delegates;                                               
    
    mapping(uint256 => address) tokens;                                                  
    mapping(address => uint256) token_indices;                                           
    address[] token_arr;                                                                 
    
    mapping(uint256 => address payable) reserves;                                        
    mapping(address => uint256) reserve_indices;                                         
    mapping(address => bool) public_reserves;                                            
    address[] public_reserve_arr;                                                        

    address payable owner;                       
    mapping(address => bool) arbiters;           
    bool marketActive = true;                    
    address payable feeCollector;                
    bool feeCollectorLocked = false;             
    uint256 single_sig_waiting_period = 86400;   
}

contract dexBlueUtils is dexBlueStorage{
     
    function getBalance(address token, address holder) view public returns(uint256){
        return balances[token][holder];
    }
    
     
    function getTokenIndex(address token) view public returns(uint256){
        return token_indices[token];
    }
    
     
    function getTokenFromIndex(uint256 index) view public returns(address){
        return tokens[index];
    }
    
     
    function getTokens() view public returns(address[] memory){
        return token_arr;
    }
    
     
    function getReserveIndex(address reserve) view public returns(uint256){
        return reserve_indices[reserve];
    }
    
     
    function getReserveFromIndex(uint256 index) view public returns(address){
        return reserves[index];
    }
    
     
    function getReserves() view public returns(address[] memory){
        return public_reserve_arr;
    }
    
     
    function getBlocked(address token, address holder) view public returns(uint256){
        return blocked_for_single_sig_withdrawal[token][holder];
    }
    
     
    function getLastBlockedTimestamp(address user) view public returns(uint256){
        return last_blocked_timestamp[user];
    }
    
     
    function checkERC20TransferSuccess() pure internal returns(bool){
        uint256 success = 0;

        assembly {
            switch returndatasize                
                case 0 {                         
                    success := 1
                }
                case 32 {                        
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
        }

        return success != 0;
    }
}

contract dexBlueStructs is dexBlueStorage{

     
    struct EIP712_Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32          EIP712_DOMAIN_SEPARATOR;
     
    bytes32 constant EIP712_ORDER_TYPEHASH = keccak256("Order(address sellTokenAddress,uint128 sellTokenAmount,address buyTokenAddress,uint128 buyTokenAmount,uint32 expiry,uint64 nonce)");
     
    bytes32 constant EIP712_WITHDRAWAL_TYPEHASH = keccak256("Withdrawal(address token,uint256 amount,uint64 nonce)");

    
    struct Order{
        address     sellToken;      
        uint256     sellAmount;     
        address     buyToken;       
        uint256     buyAmount;      
        uint256     expiry;         
        bytes32     hash;           
        address     signee;         
    }

    struct OrderInputPacked{
           
        bytes32     packedInput1;
         
        bytes32     packedInput2;
        
        bytes32     r;                           
        bytes32     s;                           
    }
    
     
    function orderFromInput(OrderInputPacked memory orderInput) view public returns(Order memory){
         
        Order memory order = Order({
            sellToken  : tokens[uint256(orderInput.packedInput2 >> 240)],
            sellAmount : uint256(orderInput.packedInput1 >> 128),
            buyToken   : tokens[uint256((orderInput.packedInput2 & 0x0000ffff00000000000000000000000000000000000000000000000000000000) >> 224)],
            buyAmount  : uint256(orderInput.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            expiry     : uint256((orderInput.packedInput2 & 0x00000000ffffffff000000000000000000000000000000000000000000000000) >> 192), 
            hash       : 0x0,
            signee     : address(0x0)
        });
        
         
        if(
            orderInput.packedInput2[17] == byte(0x00)    
        ){                                               
            order.hash = keccak256(abi.encodePacked(     
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    order.sellToken,
                    uint128(order.sellAmount),
                    order.buyToken,
                    uint128(order.buyAmount),
                    uint32(order.expiry), 
                    uint64(uint256((orderInput.packedInput2 & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000) >> 128)),  
                    address(this)                        
                ))
            ));
        }else{                                           
            order.hash = keccak256(abi.encodePacked(
                "\x19\x01",
                EIP712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    EIP712_ORDER_TYPEHASH,
                    order.sellToken,
                    order.sellAmount,
                    order.buyToken,
                    order.buyAmount,
                    order.expiry, 
                    uint256((orderInput.packedInput2 & 0x0000000000000000ffffffffffffffff00000000000000000000000000000000) >> 128)  
                ))
            ));
        }
        
         
        order.signee = ecrecover(
            order.hash,                              
            uint8(orderInput.packedInput2[16]),      
            orderInput.r,                            
            orderInput.s                             
        );
        
         
        if(
            orderInput.packedInput2[18] == byte(0x01)   
        ){
            order.signee = delegates[order.signee];
        }
        
        return order;
    }
    
    struct Trade{
        uint256 makerAmount;
        uint256 takerAmount; 
        uint256 makerFee; 
        uint256 takerFee;
        uint256 makerRebate;
    }
    
    struct ReserveReserveTrade{
        address makerToken;
        address takerToken; 
        uint256 makerAmount;
        uint256 takerAmount; 
        uint256 makerFee; 
        uint256 takerFee;
        uint256 gasLimit;
    }
    
    struct ReserveTrade{
        uint256 orderAmount;
        uint256 reserveAmount; 
        uint256 orderFee; 
        uint256 reserveFee;
        uint256 orderRebate;
        uint256 reserveRebate;
        bool    orderIsMaker;
        uint256 gasLimit;
    }
    
    struct TradeInputPacked{
         
        bytes32     packedInput1;  
         
        bytes32     packedInput2; 
         
        bytes32     packedInput3; 
    }

     
    function tradeFromInput(TradeInputPacked memory packed) public pure returns (Trade memory){
        return Trade({
            makerAmount : uint256(packed.packedInput1 >> 128),
            takerAmount : uint256(packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerFee    : uint256(packed.packedInput2 >> 128),
            takerFee    : uint256(packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerRebate : uint256(packed.packedInput3 >> 128)
        });
    }
    
     
    function reserveTradeFromInput(TradeInputPacked memory packed) public pure returns (ReserveTrade memory){
        if(packed.packedInput3[16] == byte(0x10)){
             
            return ReserveTrade({
                orderAmount   : uint256( packed.packedInput1 >> 128),
                reserveAmount : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                orderFee      : uint256( packed.packedInput2 >> 128),
                reserveFee    : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                orderRebate   : uint256((packed.packedInput3 & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128),
                reserveRebate : 0,
                orderIsMaker  : true,
                gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
            });
        }else{
             
            return ReserveTrade({
                orderAmount   : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                reserveAmount : uint256( packed.packedInput1 >> 128),
                orderFee      : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
                reserveFee    : uint256( packed.packedInput2 >> 128),
                orderRebate   : 0,
                reserveRebate : uint256((packed.packedInput3 & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128),
                orderIsMaker  : false,
                gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
            });
        }
    }

     
    function reserveReserveTradeFromInput(TradeInputPacked memory packed) public view returns (ReserveReserveTrade memory){
        return ReserveReserveTrade({
            makerToken    : tokens[uint256((packed.packedInput3 & 0x000000000000000000000000000000000000000000ffff000000000000000000) >> 72)],
            takerToken    : tokens[uint256((packed.packedInput3 & 0x0000000000000000000000000000000000000000000000ffff00000000000000) >> 56)],
            makerAmount   : uint256( packed.packedInput1 >> 128),
            takerAmount   : uint256( packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            makerFee      : uint256( packed.packedInput2 >> 128),
            takerFee      : uint256( packed.packedInput2 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            gasLimit      : uint256((packed.packedInput3 & 0x00000000000000000000000000000000000000000000000000ffffff00000000) >> 32)
        });
    }
    
    struct RingTrade {
        bool    isReserve;       
        uint256 identifier;      
        address giveToken;       
        uint256 giveAmount;      
        uint256 fee;             
        uint256 rebate;          
        uint256 gasLimit;        
    }

    struct RingTradeInputPacked{
         
        bytes32     packedInput1;    
         
        bytes32     packedInput2;   
    }
    
     
    function ringTradeFromInput(RingTradeInputPacked memory packed) view public returns(RingTrade memory){
        return RingTrade({
            isReserve     : (packed.packedInput2[16] == bytes1(0x01)),
            identifier    : uint256((       packed.packedInput2 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104),
            giveToken     : tokens[uint256((packed.packedInput2 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            giveAmount    : uint256(        packed.packedInput1                                                                       >> 128),
            fee           : uint256(        packed.packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff),
            rebate        : uint256(        packed.packedInput2                                                                       >> 128),
            gasLimit      : uint256((       packed.packedInput2 & 0x000000000000000000000000000000000000000000ffffff0000000000000000) >> 64)
        });
    }
}

contract dexBlueSettlementModule is dexBlueStorage, dexBlueEvents, dexBlueUtils, dexBlueStructs{
    
     
    function matchOrders(
        Order memory makerOrder,
        Order memory takerOrder,
        Trade memory trade
    ) internal returns (bool){
         
        uint makerOrderMatched = matched[makerOrder.hash];
        uint takerOrderMatched = matched[takerOrder.hash];

        if(  
             
               makerOrder.buyToken == takerOrder.sellToken
            && takerOrder.buyToken == makerOrder.sellToken
            
             
            && makerOrder.expiry > block.timestamp
            && takerOrder.expiry > block.timestamp 
            
             
            && balances[makerOrder.sellToken][makerOrder.signee] >= trade.makerAmount - trade.makerRebate
            && balances[takerOrder.sellToken][takerOrder.signee] >= trade.takerAmount
            
             
            && trade.makerAmount - trade.makerRebate <= makerOrder.sellAmount * trade.takerAmount / makerOrder.buyAmount + 1   
            && trade.takerAmount                     <= takerOrder.sellAmount * trade.makerAmount / takerOrder.buyAmount + 1   
            
             
            && makerOrder.sellAmount > makerOrderMatched
            && takerOrder.sellAmount > takerOrderMatched

             
            && trade.makerAmount - trade.makerRebate + makerOrderMatched <= makerOrder.sellAmount
            && trade.takerAmount                     + takerOrderMatched <= takerOrder.sellAmount
                
             
            && trade.makerFee <= trade.takerAmount / 20
            && trade.takerFee <= trade.makerAmount / 20
            
             
            && trade.makerRebate <= trade.takerFee
        ){
             
            
             
            balances[makerOrder.sellToken][makerOrder.signee] -= trade.makerAmount - trade.makerRebate;      
            balances[takerOrder.sellToken][takerOrder.signee] -= trade.takerAmount;                          
            
             
            balances[makerOrder.buyToken][makerOrder.signee] += trade.takerAmount - trade.makerFee;          
            balances[takerOrder.buyToken][takerOrder.signee] += trade.makerAmount - trade.takerFee;          
            
             
            matched[makerOrder.hash] += trade.makerAmount - trade.makerRebate;                               
            matched[takerOrder.hash] += trade.takerAmount;                                                   
            
             
            balances[takerOrder.buyToken][feeCollector] += trade.takerFee - trade.makerRebate;               
            balances[makerOrder.buyToken][feeCollector] += trade.makerFee;                                   
            
             
            blocked_for_single_sig_withdrawal[makerOrder.sellToken][makerOrder.signee] = 0;                  
            blocked_for_single_sig_withdrawal[takerOrder.sellToken][takerOrder.signee] = 0;                  
            
            emit LogTrade(makerOrder.sellToken, trade.makerAmount, takerOrder.sellToken, trade.takerAmount);

            return true;                                                                         
        }else{
            return false;                                                                                   
        }
    }

     
    function matchOrderWithReserve(
        Order memory order,
        address      reserve,
        ReserveTrade memory trade
    ) internal returns(bool){
         
        uint orderMatched = matched[order.hash];

        if(  
             
            balances[order.sellToken][order.signee] >= trade.orderAmount - trade.orderRebate
            
             
            && order.expiry > block.timestamp 
            
             
            && trade.orderAmount - trade.orderRebate <= order.sellAmount * trade.reserveAmount / order.buyAmount + 1   
            
             
            && order.sellAmount > orderMatched

             
            && trade.orderAmount - trade.orderRebate + orderMatched <= order.sellAmount
                
             
            && trade.orderFee   <= trade.reserveAmount / 20
            && trade.reserveFee <= trade.orderAmount   / 20
            
             
            && trade.orderRebate   <= trade.reserveFee
            && trade.reserveRebate <= trade.orderFee
        ){
            balances[order.sellToken][order.signee] -= trade.orderAmount - trade.orderRebate;   
            
            (bool txSuccess, bytes memory returnData) = address(this).call.gas(
                    trade.gasLimit                                               
                )(
                    abi.encodePacked(                                            
                        dexBlue(address(0)).executeReserveTrade.selector,        
                        abi.encode(                            
                            order.sellToken,                                     
                            trade.orderAmount   - trade.reserveFee,              
                            order.buyToken,                                      
                            trade.reserveAmount - trade.reserveRebate,           
                            reserve                                              
                        )
                    )
                );
            
            if(
               txSuccess                                     
               && abi.decode(returnData, (bool))             
                
            ){
                 
                balances[order.buyToken][reserve]      -= trade.reserveAmount - trade.reserveRebate;     
                
                 
                balances[order.buyToken][order.signee] += trade.reserveAmount - trade.orderFee;          
                
                 
                matched[order.hash] += trade.orderAmount - trade.orderRebate;                            
                
                 
                balances[order.buyToken][feeCollector]  += trade.orderFee   - trade.reserveRebate;       
                balances[order.sellToken][feeCollector] += trade.reserveFee - trade.orderRebate;         
                
                 
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                    

                if(trade.orderIsMaker){
                    emit LogTrade(order.sellToken, trade.orderAmount, order.buyToken, trade.reserveAmount);
                }else{
                    emit LogTrade(order.buyToken, trade.reserveAmount, order.sellToken, trade.orderAmount);
                }
                emit LogDirectWithdrawal(reserve, order.sellToken, trade.orderAmount - trade.reserveFee);
                
                return true;
            }else{
                balances[order.sellToken][order.signee] += trade.orderAmount - trade.orderRebate;   
                
                return false;
            }
        }else{
            return false;
        }
    }
    
     
    function matchOrderWithReserveWithData(
        Order        memory order,
        address      reserve,
        ReserveTrade memory trade,
        bytes32[]    memory data
    ) internal returns(bool){
         
        uint orderMatched = matched[order.hash];

        if(  
             
            balances[order.sellToken][order.signee] >= trade.orderAmount - trade.orderRebate
            
             
            && order.expiry > block.timestamp 
            
             
            && trade.orderAmount - trade.orderRebate <= order.sellAmount * trade.reserveAmount / order.buyAmount + 1   
            
             
            && order.sellAmount > orderMatched

             
            && trade.orderAmount - trade.orderRebate + orderMatched <= order.sellAmount
                
             
            && trade.orderFee   <= trade.reserveAmount / 20
            && trade.reserveFee <= trade.orderAmount   / 20
            
             
            && trade.orderRebate   <= trade.reserveFee
            && trade.reserveRebate <= trade.orderFee
        ){
            balances[order.sellToken][order.signee] -= trade.orderAmount - trade.orderRebate;   
            
            (bool txSuccess, bytes memory returnData) = address(this).call.gas(
                    trade.gasLimit                                                   
                )(
                    abi.encodePacked(                                                
                        dexBlue(address(0)).executeReserveTradeWithData.selector,    
                        abi.encode(                            
                            order.sellToken,                                         
                            trade.orderAmount   - trade.reserveFee,                  
                            order.buyToken,                                          
                            trade.reserveAmount - trade.reserveRebate,               
                            reserve,                                                 
                            data                                                     
                        )
                    )
                );
            
            if(
               txSuccess                                     
               && abi.decode(returnData, (bool))             
                
            ){
                 
                balances[order.buyToken][reserve]      -= trade.reserveAmount - trade.reserveRebate;     
                
                 
                balances[order.buyToken][order.signee] += trade.reserveAmount - trade.orderFee;          
                
                 
                matched[order.hash] += trade.orderAmount - trade.orderRebate;                            
                
                 
                balances[order.buyToken][feeCollector]  += trade.orderFee   - trade.reserveRebate;       
                balances[order.sellToken][feeCollector] += trade.reserveFee - trade.orderRebate;         
                
                 
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                    

                if(trade.orderIsMaker){
                    emit LogTrade(order.sellToken, trade.orderAmount, order.buyToken, trade.reserveAmount);
                }else{
                    emit LogTrade(order.buyToken, trade.reserveAmount, order.sellToken, trade.orderAmount);
                }
                emit LogDirectWithdrawal(reserve, order.sellToken, trade.orderAmount - trade.reserveFee);
                
                return true;
            }else{
                balances[order.sellToken][order.signee] += trade.orderAmount - trade.orderRebate;   
                
                return false;
            }
        }else{
            return false;
        }
    }
    
     
    function matchReserveWithReserve(
        address             makerReserve,
        address             takerReserve,
        ReserveReserveTrade memory trade
    ) internal returns(bool){

        (bool txSuccess, bytes memory returnData) = address(this).call.gas(
            trade.gasLimit                                                       
        )(
            abi.encodePacked(                                                    
                dexBlue(address(0)).executeReserveReserveTrade.selector,      
                abi.encode(                            
                    makerReserve,
                    takerReserve,
                    trade
                )
            )
        );

        return (
            txSuccess                                     
            && abi.decode(returnData, (bool))             
        );
    }

    
     
    function matchReserveWithReserveWithData(
        address             makerReserve,
        address             takerReserve,
        ReserveReserveTrade memory trade,
        bytes32[] memory    makerData,
        bytes32[] memory    takerData
    ) internal returns(bool){

        (bool txSuccess, bytes memory returnData) = address(this).call.gas(
            trade.gasLimit                                                        
        )(
            abi.encodePacked(                                                     
                dexBlue(address(0)).executeReserveReserveTradeWithData.selector,  
                abi.encode(                            
                    makerReserve,
                    takerReserve,
                    trade,
                    makerData,
                    takerData
                )
            )
        );

        return (
            txSuccess                                     
            && abi.decode(returnData, (bool))             
        );
    }
    
        
    function batchSettleTrades(OrderInputPacked[] calldata orderInput, TradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);       
        
        Order[] memory orders = new Order[](orderInput.length);
        uint256 i = orderInput.length;

        while(i-- != 0){                                 
            orders[i] = orderFromInput(orderInput[i]);   
        }
        
        uint256 makerIdentifier;
        uint256 takerIdentifier;
        
        for(i = 0; i < tradeInput.length; i++){
            makerIdentifier = uint256((tradeInput[i].packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104);
            takerIdentifier = uint256((tradeInput[i].packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88);
            
            if(tradeInput[i].packedInput3[16] == byte(0x11)){        
                if(!matchOrders(
                    orders[makerIdentifier],
                    orders[takerIdentifier],
                    tradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else if(tradeInput[i].packedInput3[16] == byte(0x10)){  
                if(!matchOrderWithReserve(
                    orders[makerIdentifier],
                    reserves[takerIdentifier],
                    reserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else if(tradeInput[i].packedInput3[16] == byte(0x01)){  
                if(!matchOrderWithReserve(
                    orders[takerIdentifier],
                    reserves[makerIdentifier],
                    reserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }else{                                                   
                if(!matchReserveWithReserve(
                    reserves[makerIdentifier],
                    reserves[takerIdentifier],
                    reserveReserveTradeFromInput(tradeInput[i])
                )){
                    emit LogTradeFailed();      
                }
            }
        }
    }

      
    function settleTrade(OrderInputPacked calldata makerOrderInput, OrderInputPacked calldata takerOrderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);       
        
        if(!matchOrders(
            orderFromInput(makerOrderInput),
            orderFromInput(takerOrderInput),
            tradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }
        
      
    function settleReserveTrade(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);       
        
        if(!matchOrderWithReserve(
            orderFromInput(orderInput),
            reserves[
                tradeInput.packedInput3[16] == byte(0x01) ?  
                     
                    uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104) :
                     
                    uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)
            ],
            reserveTradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }

      
    function settleReserveTradeWithData(
        OrderInputPacked calldata orderInput, 
        TradeInputPacked calldata tradeInput,
        bytes32[] calldata        data
    ) external {
        require(arbiters[msg.sender] && marketActive);       
        
        if(!matchOrderWithReserveWithData(
            orderFromInput(orderInput),
            reserves[
                tradeInput.packedInput3[16] == byte(0x01) ?  
                     
                    uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104) :
                     
                    uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)
            ],
            reserveTradeFromInput(tradeInput),
            data
        )){
            emit LogTradeFailed();      
        }
    }
    
      
    function settleReserveReserveTrade(
        TradeInputPacked calldata tradeInput
    ) external {
        require(arbiters[msg.sender] && marketActive);       
        
        if(!matchReserveWithReserve(
            reserves[uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104)],
            reserves[uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            reserveReserveTradeFromInput(tradeInput)
        )){
            emit LogTradeFailed();      
        }
    }
    
      
    function settleReserveReserveTradeWithData(
        TradeInputPacked calldata tradeInput,
        bytes32[] calldata        makerData,
        bytes32[] calldata        takerData
    ) external {
        require(arbiters[msg.sender] && marketActive);       
        
        if(!matchReserveWithReserveWithData(
            reserves[uint256((tradeInput.packedInput3 & 0x0000000000000000000000000000000000ffff00000000000000000000000000) >> 104)],
            reserves[uint256((tradeInput.packedInput3 & 0x00000000000000000000000000000000000000ffff0000000000000000000000) >> 88)],
            reserveReserveTradeFromInput(tradeInput),
            makerData,
            takerData
        )){
            emit LogTradeFailed();      
        }
    }
    
     
    function settleRingTrade(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);       
        
         
        uint256 i = orderInput.length;
        Order[] memory orders = new Order[](i);
        while(i-- != 0){
            orders[i] = orderFromInput(orderInput[i]);
        }
        
         
        i = tradeInput.length;
        RingTrade[] memory trades = new RingTrade[](i);
        while(i-- != 0){
            trades[i] = ringTradeFromInput(tradeInput[i]);
        }
        
        uint256 prev = trades.length - 1;
        uint256 next = 1;
          
        for(i = 0; i < trades.length; i++){
            
            require(
                 
                trades[i].fee       <= trades[prev].giveAmount / 20
                
                 
                && trades[i].rebate <= trades[next].fee
            );
            
            if(trades[i].isReserve){  
                address reserve = reserves[trades[i].identifier];

                if(i == 0){
                    require(
                        dexBlueReserve(reserve).offer(
                            trades[i].giveToken,                                    
                            trades[i].giveAmount - trades[i].rebate,                
                            trades[prev].giveToken,                                 
                            trades[prev].giveAmount - trades[i].fee                 
                        )
                        && balances[trades[i].giveToken][reserve] >= trades[i].giveAmount
                    );
                }else{
                    uint256 receiveAmount = trades[prev].giveAmount - trades[i].fee;

                    if(trades[prev].giveToken != address(0)){
                        Token(trades[prev].giveToken).transfer(reserve, receiveAmount);   
                        require(                                                          
                            checkERC20TransferSuccess(),
                            "ERC20 token transfer failed."
                        );
                    }

                    require(
                        dexBlueReserve(reserve).trade.value(
                            trades[prev].giveToken == address(0) ? receiveAmount : 0
                        )(             
                            trades[prev].giveToken,
                            receiveAmount,                                       
                            trades[i].giveToken,    
                            trades[i].giveAmount - trades[i].rebate              
                        )
                    );
                }

                 
                balances[trades[i].giveToken][reserve] -= trades[i].giveAmount - trades[i].rebate;

                emit LogDirectWithdrawal(reserve, trades[prev].giveToken, trades[prev].giveAmount - trades[i].fee);
            }else{  
                
                Order memory order = orders[trades[i].identifier];   

                uint256 orderMatched = matched[order.hash];
                
                require(
                     
                       order.buyToken  == trades[prev].giveToken
                    && order.sellToken == trades[i].giveToken
                    
                     
                    && order.expiry > block.timestamp
                    
                     
                    && balances[order.sellToken][order.signee] >= trades[i].giveAmount - trades[i].rebate
                    
                     
                    && trades[i].giveAmount - trades[i].rebate <= order.sellAmount * trades[prev].giveAmount / order.buyAmount + 1   
                    
                     
                    && order.sellAmount > orderMatched
                    
                     
                    && trades[i].giveAmount - trades[i].rebate + orderMatched <= order.sellAmount
                );
                
                 
                balances[order.sellToken       ][order.signee] -= trades[i].giveAmount - trades[i].rebate;       
                
                 
                balances[trades[prev].giveToken][order.signee] += trades[prev].giveAmount - trades[i].fee;       
                
                 
                matched[order.hash] += trades[i].giveAmount - trades[i].rebate;                                  
                
                 
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                            
            }

            emit LogTrade(trades[prev].giveToken, trades[prev].giveAmount, trades[i].giveToken, trades[i].giveAmount);
            
             
            balances[trades[prev].giveToken][feeCollector] += trades[i].fee - trades[prev].rebate;               
            
            prev = i;
            if(i == trades.length - 2){
                next = 0;
            }else{
                next = i + 2;
            }
        }

        if(trades[0].isReserve){
            address payable reserve = reserves[trades[0].identifier];
            prev = trades.length - 1;
            
            if(trades[prev].giveToken == address(0)){                                                        
                require(
                    reserve.send(trades[prev].giveAmount - trades[0].fee),                                   
                    "Sending of ETH failed."
                );
            }else{
                Token(trades[prev].giveToken).transfer(reserve, trades[prev].giveAmount - trades[0].fee);    
                require(                                                                                     
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

             
            dexBlueReserve(reserve).offerExecuted(
                trades[0].giveToken,                                    
                trades[0].giveAmount - trades[0].rebate,                
                trades[prev].giveToken,                                 
                trades[prev].giveAmount - trades[0].fee                 
            );
        }
    }
    
    
     
    function settleRingTradeWithData(
        OrderInputPacked[]     calldata orderInput,
        RingTradeInputPacked[] calldata tradeInput,
        bytes32[][]            calldata data
    ) external {
        require(arbiters[msg.sender] && marketActive);       
        
         
        uint256 i = orderInput.length;
        Order[] memory orders = new Order[](i);
        while(i-- != 0){
            orders[i] = orderFromInput(orderInput[i]);
        }
        
         
        i = tradeInput.length;
        RingTrade[] memory trades = new RingTrade[](i);
        while(i-- != 0){
            trades[i] = ringTradeFromInput(tradeInput[i]);
        }
        
        uint256 prev = trades.length - 1;
        uint256 next = 1;
          
        for(i = 0; i < trades.length; i++){
            
            require(
                 
                trades[i].fee       <= trades[prev].giveAmount / 20
                
                 
                && trades[i].rebate <= trades[next].fee
            );
            
            if(trades[i].isReserve){  
                address reserve = reserves[trades[i].identifier];

                if(i == 0){
                    require(
                        dexBlueReserve(reserve).offerWithData(
                            trades[i].giveToken,                                    
                            trades[i].giveAmount - trades[i].rebate,                
                            trades[prev].giveToken,                                 
                            trades[prev].giveAmount - trades[i].fee,                
                            data[i]                                                 
                        )
                        && balances[trades[i].giveToken][reserve] >= trades[i].giveAmount
                    );
                }else{
                    uint256 receiveAmount = trades[prev].giveAmount - trades[i].fee;

                    if(trades[prev].giveToken != address(0)){
                        Token(trades[prev].giveToken).transfer(reserve, receiveAmount);   
                        require(                                                          
                            checkERC20TransferSuccess(),
                            "ERC20 token transfer failed."
                        );
                    }

                    require(
                        dexBlueReserve(reserve).tradeWithData.value(
                            trades[prev].giveToken == address(0) ? receiveAmount : 0
                        )(             
                            trades[prev].giveToken,
                            receiveAmount,                                       
                            trades[i].giveToken,    
                            trades[i].giveAmount - trades[i].rebate,             
                            data[i]                                              
                        )
                    );
                }

                 
                balances[trades[i].giveToken][reserve] -= trades[i].giveAmount - trades[i].rebate;

                emit LogDirectWithdrawal(reserve, trades[prev].giveToken, trades[prev].giveAmount - trades[i].fee);
            }else{  
                
                Order memory order = orders[trades[i].identifier];   

                uint256 orderMatched = matched[order.hash];
                
                require(
                     
                       order.buyToken  == trades[prev].giveToken
                    && order.sellToken == trades[i].giveToken
                    
                     
                    && order.expiry > block.timestamp
                    
                     
                    && balances[order.sellToken][order.signee] >= trades[i].giveAmount - trades[i].rebate
                    
                     
                    && trades[i].giveAmount - trades[i].rebate <= order.sellAmount * trades[prev].giveAmount / order.buyAmount + 1   
                    
                     
                    && order.sellAmount > orderMatched
                    
                     
                    && trades[i].giveAmount - trades[i].rebate + orderMatched <= order.sellAmount
                );
                
                 
                balances[order.sellToken       ][order.signee] -= trades[i].giveAmount - trades[i].rebate;       
                
                 
                balances[trades[prev].giveToken][order.signee] += trades[prev].giveAmount - trades[i].fee;       
                
                 
                matched[order.hash] += trades[i].giveAmount - trades[i].rebate;                                  
                
                 
                blocked_for_single_sig_withdrawal[order.sellToken][order.signee] = 0;                            
            }

            emit LogTrade(trades[prev].giveToken, trades[prev].giveAmount, trades[i].giveToken, trades[i].giveAmount);
            
             
            balances[trades[prev].giveToken][feeCollector] += trades[i].fee - trades[prev].rebate;               
            
            prev = i;
            if(i == trades.length - 2){
                next = 0;
            }else{
                next = i + 2;
            }
        }

        if(trades[0].isReserve){
            address payable reserve = reserves[trades[0].identifier];
            prev = trades.length - 1;
            
            if(trades[prev].giveToken == address(0)){                                                        
                require(
                    reserve.send(trades[prev].giveAmount - trades[0].fee),                                   
                    "Sending of ETH failed."
                );
            }else{
                Token(trades[prev].giveToken).transfer(reserve, trades[prev].giveAmount - trades[0].fee);    
                require(                                                                                     
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

             
            dexBlueReserve(reserve).offerExecuted(
                trades[0].giveToken,                                    
                trades[0].giveAmount - trades[0].rebate,                
                trades[prev].giveToken,                                 
                trades[prev].giveAmount - trades[0].fee                 
            );
        }
    }
    
    
     
    
     
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns (uint256){
        (, uint256 output) = getBestReserve(sell_token, sell_amount, buy_token);
        return output;
    }
    
     
    function getBestReserve(address sell_token, uint256 sell_amount, address buy_token) public view returns (address, uint256){
        address bestReserve;
        uint256 bestOutput = 0;
        uint256 output;
        
        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            output = dexBlueReserve(public_reserve_arr[i]).getSwapOutput(sell_token, sell_amount, buy_token);
            if(output > bestOutput){
                bestOutput  = output;
                bestReserve = public_reserve_arr[i];
            }
        }
        
        return (bestReserve, bestOutput);
    }
    
     
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, uint256 deadline) external payable returns(uint256){        
        require(
            (
                deadline == 0                                
                || deadline > block.timestamp                
            ),                                               
            "Call deadline exceeded."
        );
        
        (address reserve, uint256 amount) = getBestReserve(sell_token, sell_amount, buy_token);      
        
        require(
            amount >= min_output,                                                                    
            "Too much slippage"
        );
        
        return swapWithReserve(sell_token, sell_amount, buy_token,  min_output, reserve, deadline);  
    }
    
     
    function swapWithReserve(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, address reserve, uint256 deadline) public payable returns (uint256){
        require(
            (
                deadline == 0                                
                || deadline > block.timestamp                
            ),
            "Call deadline exceeded."
        );
        
        require(
            public_reserves[reserve],                        
            "Unknown reserve."
        );
        
        if(sell_token == address(0)){                        
            require(
                msg.value == sell_amount,                    
                "ETH amount not sent with the call."
            );
        }else{                                               
            require(
                msg.value == 0,                              
                "Don't send ETH when swapping a token."
            );
            
            Token(sell_token).transferFrom(msg.sender, reserve, sell_amount);    
            
            require(
                checkERC20TransferSuccess(),                 
                "ERC20 token transfer failed."
            );
        }
        
         
        uint256 output = dexBlueReserve(reserve).swap.value(msg.value)(
            sell_token,
            sell_amount,
            buy_token,
            min_output
        );
        
        if(
            output >= min_output                                 
            && balances[buy_token][reserve] >= output            
        ){
            balances[buy_token][reserve] -= output;              
            
            if(buy_token == address(0)){                         
                require(
                    msg.sender.send(output),                     
                    "Sending of ETH failed."
                );
            }else{
                Token(buy_token).transfer(msg.sender, output);   
                require(                                         
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }

            emit LogSwap(sell_token, sell_amount, buy_token, output);
            
            return output;
        }else{
            revert("Too much slippage.");
        }
    }
}

contract dexBlue is dexBlueStorage, dexBlueEvents, dexBlueUtils, dexBlueStructs{
     
    address constant settlementModuleAddress = 0x9e3d5C6ffACA00cAf136609680b536DC0Eb20c66;

     

     
    function depositEther() public payable{
        balances[address(0)][msg.sender] += msg.value;           
        emit LogDeposit(msg.sender, address(0), msg.value);      
    }
    
     
    function() external payable{
        if(msg.sender != wrappedEtherContract){      
            depositEther();                  
        }
    }
    
     
    address constant wrappedEtherContract = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  
    function depositWrappedEther(uint256 amount) external {
        
        Token(wrappedEtherContract).transferFrom(msg.sender, address(this), amount);     
        
        require(
            checkERC20TransferSuccess(),                                         
            "WETH deposit failed."
        );
        
        uint balanceBefore = address(this).balance;                              
        
        WETH(wrappedEtherContract).withdraw(amount);                             
        
        require(balanceBefore + amount == address(this).balance);                
        
        balances[address(0)][msg.sender] += amount;                              
        
        emit LogDeposit(msg.sender, address(0), amount);                         
    }
    
     
    function depositToken(address token, uint256 amount) external {
        Token(token).transferFrom(msg.sender, address(this), amount);     
        require(
            checkERC20TransferSuccess(),                                  
            "ERC20 token transfer failed."
        );
        balances[token][msg.sender] += amount;                            
        emit LogDeposit(msg.sender, token, amount);                       
    }
        
     

     
    function multiSigWithdrawal(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s) external {
        multiSigSend(token, amount, nonce, v, r, s, msg.sender);  
    }    

     
    function multiSigSend(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address payable receiving_address) public {
        bytes32 hash = keccak256(abi.encodePacked(                       
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                msg.sender,
                token,
                amount,
                nonce,
                address(this)
            ))
        ));
        if(
            !processed_withdrawals[hash]                                 
            && arbiters[ecrecover(hash, v,r,s)]                          
            && balances[token][msg.sender] >= amount                     
        ){
            processed_withdrawals[hash]  = true;                         
            balances[token][msg.sender] -= amount;                       
            
            if(token == address(0)){                                     
                require(
                    receiving_address.send(amount),
                    "Sending of ETH failed."
                );
            }else{                                                       
                Token(token).transfer(receiving_address, amount);        
                require(
                    checkERC20TransferSuccess(),                         
                    "ERC20 token transfer failed."
                );
            }

            blocked_for_single_sig_withdrawal[token][msg.sender] = 0;    
            
            emit LogWithdrawal(msg.sender,token,amount);                 
        }else{
            revert();                                                    
        }
    }

     
    function multiSigTransfer(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address receiving_address) external {
        bytes32 hash = keccak256(abi.encodePacked(                       
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                msg.sender,
                token,
                amount,
                nonce,
                address(this)
            ))
        ));
        if(
            !processed_withdrawals[hash]                                 
            && arbiters[ecrecover(hash, v,r,s)]                          
            && balances[token][msg.sender] >= amount                     
        ){
            processed_withdrawals[hash]         = true;                  
            balances[token][msg.sender]        -= amount;                
            balances[token][receiving_address] += amount;                
            
            blocked_for_single_sig_withdrawal[token][msg.sender] = 0;    
            
            emit LogWithdrawal(msg.sender,token,amount);                 
            emit LogDeposit(receiving_address,token,amount);             
        }else{
            revert();                                                    
        }
    }
    
     
    function userSigWithdrawal(bytes32 packedInput1, bytes32 packedInput2, bytes32 r, bytes32 s) external {
         
         
        uint256 amount = uint256(packedInput1 >> 128);
        uint256 fee    = uint256(packedInput1 & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
        address token  = tokens[uint256(packedInput2 >> 240)];
        uint64  nonce  = uint64(uint256((packedInput2 & 0x0000ffffffffffffffff00000000000000000000000000000000000000000000) >> 176));
        uint8   v      = uint8(packedInput2[10]);

        bytes32 hash;
        if(packedInput2[11] == byte(0x00)){                              
            hash = keccak256(abi.encodePacked(                           
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    token,
                    amount,
                    nonce,
                    address(this)
                ))
            ));
        }else{                                                           
            hash = keccak256(abi.encodePacked(                           
                "\x19\x01",
                EIP712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    EIP712_WITHDRAWAL_TYPEHASH,
                    token,
                    amount,
                    nonce
                ))
            ));
        }

        address payable account = address(uint160(ecrecover(hash, v, r, s)));    
        
        if(
            !processed_withdrawals[hash]                                 
            && arbiters[msg.sender]                                      
            && fee <= amount / 20                                        
            && balances[token][account] >= amount                        
        ){
            processed_withdrawals[hash]    = true;                       
            balances[token][account]      -= amount;                     
            balances[token][feeCollector] += fee;                        
            
            if(token == address(0)){                                     
                require(
                    account.send(amount - fee),
                    "Sending of ETH failed."
                );
            }else{
                Token(token).transfer(account, amount - fee);            
                require(
                    checkERC20TransferSuccess(),                         
                    "ERC20 token transfer failed."
                );
            }
        
            blocked_for_single_sig_withdrawal[token][account] = 0;       
            
            emit LogWithdrawal(account,token,amount);                    
            
             
            if(packedInput2[12] != byte(0x00)){
                spendGasTokens(uint8(packedInput2[12]));
            }
        }else{
            revert();                                                    
        }
    }
    
     

     
    function blockFundsForSingleSigWithdrawal(address token, uint256 amount) external {
        if (balances[token][msg.sender] - blocked_for_single_sig_withdrawal[token][msg.sender] >= amount){   
            blocked_for_single_sig_withdrawal[token][msg.sender] += amount;                                  
            last_blocked_timestamp[msg.sender] = block.timestamp;                                            
            emit LogBlockedForSingleSigWithdrawal(msg.sender, token, amount);                                
        }else{
            revert();                                                                                        
        }
    }
    
     
    function initiateSingleSigWithdrawal(address token, uint256 amount) external {
        if (
            balances[token][msg.sender] >= amount                                    
            && (
                (
                    blocked_for_single_sig_withdrawal[token][msg.sender] >= amount                           
                    && last_blocked_timestamp[msg.sender] + single_sig_waiting_period <= block.timestamp     
                )
                || single_sig_waiting_period == 0                                                            
            )
        ){
            balances[token][msg.sender] -= amount;                                   

            if(blocked_for_single_sig_withdrawal[token][msg.sender] >= amount){
                blocked_for_single_sig_withdrawal[token][msg.sender] = 0;      
            }
            
            if(token == address(0)){                                                 
                require(
                    msg.sender.send(amount),
                    "Sending of ETH failed."
                );
            }else{                                                                   
                Token(token).transfer(msg.sender, amount);                           
                require(
                    checkERC20TransferSuccess(),                                     
                    "ERC20 token transfer failed."
                );
            }
            
            emit LogSingleSigWithdrawal(msg.sender, token, amount);                  
        }else{
            revert();                                                                
        }
    } 

     

      
    function settleTrade(OrderInputPacked calldata makerOrderInput, OrderInputPacked calldata takerOrderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);    

        settlementModuleAddress.delegatecall(msg.data);   
        
         
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }

      
    function settleReserveTrade(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);    

        settlementModuleAddress.delegatecall(msg.data);   
        
         
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }

      
    function settleReserveTradeWithData(OrderInputPacked calldata orderInput, TradeInputPacked calldata tradeInput, bytes32[] calldata data) external {
        require(arbiters[msg.sender] && marketActive);       
        
        settlementModuleAddress.delegatecall(msg.data);   
        
         
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    
      
    function settleReserveReserveTrade(TradeInputPacked calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);           

        settlementModuleAddress.delegatecall(msg.data);   
        
         
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    
      
    function settleReserveReserveTradeWithData(TradeInputPacked calldata tradeInput, bytes32[] calldata makerData, bytes32[] calldata takerData) external {
        require(arbiters[msg.sender] && marketActive);       
        
        settlementModuleAddress.delegatecall(msg.data);      
        
         
        if(tradeInput.packedInput3[28] != byte(0x00)){
            spendGasTokens(uint8(tradeInput.packedInput3[28]));
        }
    }
    

        
    function batchSettleTrades(OrderInputPacked[] calldata orderInput, TradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);           
        
        settlementModuleAddress.delegatecall(msg.data);   
        
         
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput3[28]);
        }
        
         
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }

     
    function settleRingTrade(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput) external {
        require(arbiters[msg.sender] && marketActive);       

        settlementModuleAddress.delegatecall(msg.data);
        
         
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput2[24]);
        }
        
         
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }

     
    function settleRingTradeWithData(OrderInputPacked[] calldata orderInput, RingTradeInputPacked[] calldata tradeInput, bytes32[][] calldata data) external {
        require(arbiters[msg.sender] && marketActive);       

        settlementModuleAddress.delegatecall(msg.data);
        
         
        uint256 i = tradeInput.length;        
        uint256 gasTokenSum;
        while(i-- != 0){
            gasTokenSum += uint8(tradeInput[i].packedInput2[24]);
        }
        
         
        if(gasTokenSum > 0){
            spendGasTokens(gasTokenSum);
        }
    }


     
    function executeReserveReserveTrade(
        address             makerReserve,
        address payable     takerReserve,
        ReserveReserveTrade calldata trade
    ) external returns(bool){
         
         
        require(msg.sender == address(this));                        
        
         
        require(
            dexBlueReserve(takerReserve).offer(                     
                trade.takerToken,                                    
                trade.takerAmount,                                   
                trade.makerToken,                                    
                trade.makerAmount - trade.takerFee                   
            )
            && balances[trade.takerToken][takerReserve] >= trade.takerAmount     
        );
        
        balances[trade.takerToken][takerReserve] -= trade.takerAmount;           
        
        if(trade.takerToken != address(0)){
            Token(trade.takerToken).transfer(makerReserve, trade.takerAmount - trade.makerFee);      
            require(                                                                                 
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }
        
         
        require(
            dexBlueReserve(makerReserve).trade.value(                
                trade.takerToken == address(0) ? 
                    trade.takerAmount - trade.makerFee               
                    : 0
            )(
                trade.takerToken,                                    
                trade.takerAmount - trade.makerFee,                  
                trade.makerToken,                                    
                trade.makerAmount                                    
            )
            && balances[trade.makerToken][makerReserve] >= trade.makerAmount   
        );

        balances[trade.makerToken][makerReserve] -= trade.makerAmount;                               
        
         
        if(trade.makerToken == address(0)){                                                          
            require(
                takerReserve.send(trade.makerAmount - trade.takerFee),                               
                "Sending of ETH failed."
            );
        }else{
            Token(trade.makerToken).transfer(takerReserve, trade.makerAmount - trade.takerFee);      
            require(                                                                                 
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }

         
        dexBlueReserve(takerReserve).offerExecuted(                     
            trade.takerToken,                                    
            trade.takerAmount,                                   
            trade.makerToken,                                    
            trade.makerAmount - trade.takerFee                   
        );
        
         
        balances[trade.makerToken][feeCollector] += trade.takerFee;   
        balances[trade.takerToken][feeCollector] += trade.makerFee;   
        
        emit LogTrade(trade.makerToken, trade.makerAmount, trade.takerToken, trade.takerAmount);
        
        emit LogDirectWithdrawal(makerReserve, trade.takerToken, trade.takerAmount - trade.makerFee);
        emit LogDirectWithdrawal(takerReserve, trade.makerToken, trade.makerAmount - trade.takerFee);
        
        return true;
    }

     
    function executeReserveReserveTradeWithData(
        address             makerReserve,
        address payable     takerReserve,
        ReserveReserveTrade calldata trade,
        bytes32[] calldata  makerData,
        bytes32[] calldata  takerData
    ) external returns(bool){
         
         
        require(msg.sender == address(this));                        
        
         
        require(
            dexBlueReserve(takerReserve).offerWithData(                     
                trade.takerToken,                                    
                trade.takerAmount,                                   
                trade.makerToken,                                    
                trade.makerAmount - trade.takerFee,                  
                takerData
            )
            && balances[trade.takerToken][takerReserve] >= trade.takerAmount     
        );
        
        balances[trade.takerToken][takerReserve] -= trade.takerAmount;           
        
        if(trade.takerToken != address(0)){
            Token(trade.takerToken).transfer(makerReserve, trade.takerAmount - trade.makerFee);      
            require(                                                                                 
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }
        
         
        require(
            dexBlueReserve(makerReserve).tradeWithData.value(        
                trade.takerToken == address(0) ? 
                    trade.takerAmount - trade.makerFee               
                    : 0
            )(
                trade.takerToken,                                    
                trade.takerAmount - trade.makerFee,                  
                trade.makerToken,                                    
                trade.makerAmount,                                   
                makerData
            )
            && balances[trade.makerToken][makerReserve] >= trade.makerAmount   
        );

        balances[trade.makerToken][makerReserve] -= trade.makerAmount;                               
        
         
        if(trade.makerToken == address(0)){                                                          
            require(
                takerReserve.send(trade.makerAmount - trade.takerFee),                               
                "Sending of ETH failed."
            );
        }else{
            Token(trade.makerToken).transfer(takerReserve, trade.makerAmount - trade.takerFee);      
            require(                                                                                 
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
        }

         
        dexBlueReserve(takerReserve).offerExecuted(                     
            trade.takerToken,                                    
            trade.takerAmount,                                   
            trade.makerToken,                                    
            trade.makerAmount - trade.takerFee                   
        );
        
         
        balances[trade.makerToken][feeCollector] += trade.takerFee;   
        balances[trade.takerToken][feeCollector] += trade.makerFee;   
        
        emit LogTrade(trade.makerToken, trade.makerAmount, trade.takerToken, trade.takerAmount);
        
        emit LogDirectWithdrawal(makerReserve, trade.takerToken, trade.takerAmount - trade.makerFee);
        emit LogDirectWithdrawal(takerReserve, trade.makerToken, trade.makerAmount - trade.takerFee);
        
        return true;
    }

     
    function executeReserveTrade(
        address    sellToken,
        uint256    sellAmount,
        address    buyToken,
        uint256    buyAmount,
        address    reserve
    ) external returns(bool){
         
         
        require(msg.sender == address(this));                    
        
        if(sellToken == address(0)){
            require(dexBlueReserve(reserve).trade.value(         
                                                                 
                sellAmount                                       
            )(
                sellToken,                                       
                sellAmount,                                      
                buyToken,                                        
                buyAmount                                        
            ));
        }else{
            Token(sellToken).transfer(reserve, sellAmount);      
            require(                                             
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
            
            require(dexBlueReserve(reserve).trade(               
                sellToken,                                       
                sellAmount,                                      
                buyToken,                                        
                buyAmount                                        
            ));
        }
        
        require(balances[buyToken][reserve] >= buyAmount);       
        
        return true;                                             
    }
    
     
    function executeReserveTradeWithData(
        address    sellToken,
        uint256    sellAmount,
        address    buyToken,
        uint256    buyAmount,
        address    reserve,
        bytes32[]  calldata data
    ) external returns(bool){
         
         
        require(msg.sender == address(this));                    
        
        if(sellToken == address(0)){
            require(dexBlueReserve(reserve).tradeWithData.value( 
                                                                 
                sellAmount                                       
            )(
                sellToken,                                       
                sellAmount,                                      
                buyToken,                                        
                buyAmount,                                       
                data                                             
            ));
        }else{
            Token(sellToken).transfer(reserve, sellAmount);      
            require(                                             
                checkERC20TransferSuccess(),
                "ERC20 token transfer failed."
            );
            require(dexBlueReserve(reserve).tradeWithData(       
                sellToken,                                       
                sellAmount,                                      
                buyToken,                                        
                buyAmount,                                       
                data                                             
            ));
        }
        
        require(balances[buyToken][reserve] >= buyAmount);       
        
        return true;                                             
    }


     

     
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns (uint256){
        (, uint256 output) = getBestReserve(sell_token, sell_amount, buy_token);
        return output;
    }

     
    function getBestReserve(address sell_token, uint256 sell_amount, address buy_token) public view returns (address, uint256){
        address bestReserve;
        uint256 bestOutput = 0;
        uint256 output;
        
        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            output = dexBlueReserve(public_reserve_arr[i]).getSwapOutput(sell_token, sell_amount, buy_token);
            if(output > bestOutput){
                bestOutput  = output;
                bestReserve = public_reserve_arr[i];
            }
        }
        
        return (bestReserve, bestOutput);
    }

     
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, uint256 deadline) external payable returns(uint256){

        (bool success, bytes memory returnData) = settlementModuleAddress.delegatecall(msg.data);   

        require(success);

        return abi.decode(returnData, (uint256));
    }

     
    function swapWithReserve(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output, address reserve, uint256 deadline) public payable returns (uint256){
        
        (bool success, bytes memory returnData) = settlementModuleAddress.delegatecall(msg.data);   

        require(success);

        return abi.decode(returnData, (uint256));
    }

    
     

     
    function multiSigOrderBatchCancel(bytes32[] calldata orderHashes, uint8 v, bytes32 r, bytes32 s) external {
        if(
            arbiters[                                                
                ecrecover(                                           
                    keccak256(abi.encodePacked(                      
                        "\x19Ethereum Signed Message:\n32", 
                        keccak256(abi.encodePacked(orderHashes))
                    )),
                    v, r, s
                )
            ]
        ){
            uint256 len = orderHashes.length;
            for(uint256 i = 0; i < len; i++){
                matched[orderHashes[i]] = 2**256 - 1;                
                emit LogOrderCanceled(orderHashes[i]);               
            }
        }else{
            revert();
        }
    }
    
    
     
    
     
     
     
    
    uint256 gas_token_nonce_head;
    uint256 gas_token_nonce_tail;
    
     
    function getAvailableGasTokens() view public returns (uint256 amount){
        return gas_token_nonce_head - gas_token_nonce_tail;
    }
    
     
    function mintGasTokens(uint amount) public {
        gas_token_nonce_head += amount;
        while(amount-- > 0){
            createChildContract();   
        }
    }
    
     
    function spendGasTokens(uint256 amount) internal {
        uint256 tail = gas_token_nonce_tail;
        
        if(amount <= gas_token_nonce_head - tail){
            
             
            for (uint256 i = tail + 1; i <= tail + amount; i++) {
                restoreChildContractAddress(i).call("");
            }
    
            gas_token_nonce_tail = tail + amount;
        }
    }
    
     
    function createChildContract() internal returns (address addr) {
        assembly {
            let solidity_free_mem_ptr := mload(0x40)
            mstore(solidity_free_mem_ptr, 0x746d541e251335090ac5b47176af4f7e3318585733ff6000526015600bf3)  
            addr := create(0, add(solidity_free_mem_ptr, 2), 30)                                           
        }
    }
    
     
    function restoreChildContractAddress(uint256 nonce) view internal returns (address) {
        require(nonce <= 256**9 - 1);

        uint256 encoded;
        uint256 tot_bytes;

        if (nonce < 128) {
             
             
            encoded = nonce * 256**9;
            
             
            tot_bytes = 22;
        } else {
             
            uint nonce_bytes = 1;
             
            uint mask = 256;
            while (nonce >= mask) {
                nonce_bytes += 1;
                mask        *= 256;
            }
            
             
            encoded = ((128 + nonce_bytes) * 256**9) +   
                      (nonce * 256**(9 - nonce_bytes));  
                   
             
            tot_bytes = 22 + nonce_bytes;
        }

         
        encoded += ((192 + tot_bytes) * 256**31) +      
                   ((128 + 20) * 256**30) +             
                   (uint256(address(this)) * 256**10);  

        uint256 hash;

        assembly {
            let mem_start := mload(0x40)         
            mstore(0x40, add(mem_start, 0x20))   

            mstore(mem_start, encoded)           
            hash := keccak256(mem_start,
                         add(tot_bytes, 1))      
        }

         
        return address(hash);
    }
    
        
     

     
    function delegateAddress(address delegate) external {
         
        require(delegates[delegate] == address(0), "Address is already a delegate");
        delegates[delegate] = msg.sender;
        
        emit LogDelegateStatus(msg.sender, delegate, true);
    }
    
     
    function revokeDelegation(address delegate, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash = keccak256(abi.encodePacked(               
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                delegate,
                msg.sender,
                address(this)
            ))
        ));

        require(
            arbiters[ecrecover(hash, v, r, s)],      
            "MultiSig is not from known arbiter"
        );
        
        delegates[delegate] = address(1);            
        
        emit LogDelegateStatus(msg.sender, delegate, false);
    }
    

     

     
    constructor() public {
        owner = msg.sender;              
        
         
        EIP712_Domain memory eip712Domain = EIP712_Domain({
            name              : "dex.blue",
            version           : "1",
            chainId           : 1,
            verifyingContract : address(this)
        });
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }
    
     
    function changeSingleSigWaitingPeriod(uint256 waiting_period) external {
        require(
            msg.sender == owner              
            && waiting_period <= 86400       
        );
        
        single_sig_waiting_period = waiting_period;
    }
    
     
    function changeOwner(address payable new_owner) external {
        require(msg.sender == owner);
        owner = new_owner;
    }
    
     
    function cacheReserveAddress(address payable reserve, uint256 index, bool is_public) external {
        require(arbiters[msg.sender]);
        
        reserves[index] = reserve;
        reserve_indices[reserve] = index;
        
        if(is_public){
            public_reserves[reserve] = true;
            public_reserve_arr.push(reserve);   
        }
    }
    
     
    function removePublicReserveAddress(address reserve) external {
        require(arbiters[msg.sender]);
        
        public_reserves[reserve] = false;

        for(uint256 i = 0; i < public_reserve_arr.length; i++){
            if(public_reserve_arr[i] == reserve){
                public_reserve_arr[i] = public_reserve_arr[public_reserve_arr.length - 1];  
                
                delete public_reserve_arr[public_reserve_arr.length-1];                     
                public_reserve_arr.length--;                             
                
                return;
            }
        }
    }
        
     
    function cacheTokenAddress(address token, uint256 index) external {
        require(arbiters[msg.sender]);
        
        tokens[index]        = token;
        token_indices[token] = index;
        
        token_arr.push(token);   
    }

     
    function removeTokenAddressFromArr(address token) external {
        require(arbiters[msg.sender]);
        
        for(uint256 i = 0; i < token_arr.length; i++){
            if(token_arr[i] == token){
                token_arr[i] = token_arr[token_arr.length - 1];  
                
                delete token_arr[token_arr.length-1];            
                token_arr.length--;                             
                
                return;
            }
        }
    }
    
     
    function nominateArbiter(address arbiter, bool status) external {
        require(msg.sender == owner);                            
        arbiters[arbiter] = status;                              
    }
    
     
    function setMarketActiveState(bool state) external {
        require(msg.sender == owner);                            
        marketActive = state;                                    
    }
    
     
    function nominateFeeCollector(address payable collector) external {
        require(msg.sender == owner && !feeCollectorLocked);     
        feeCollector = collector;                                
    }
    
     
    function lockFeeCollector() external {
        require(msg.sender == owner);                            
        feeCollectorLocked = true;                               
    }
    
     
    function getFeeCollector() public view returns (address){
        return feeCollector;
    }

     
    function directWithdrawal(address token, uint256 amount) external returns(bool){
        if (
            (
                msg.sender == feeCollector                         
                || arbiters[msg.sender]                            
            )
            && balances[token][msg.sender] >= amount               
        ){
            balances[token][msg.sender] -= amount;                 
            
            if(token == address(0)){                               
                require(
                    msg.sender.send(amount),                       
                    "Sending of ETH failed."
                );
            }else{
                Token(token).transfer(msg.sender, amount);         
                require(                                           
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }
            
            emit LogDirectWithdrawal(msg.sender, token, amount);      
            return true;
        }else{
            return false;
        }
    }
}

 
contract dexBlueReserve{
     
    function trade(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public payable returns(bool success){}
    
     
    function tradeWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public payable returns(bool success){}
    
     
    function offer(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public returns(bool accept){}
    
     
    function offerWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public returns(bool accept){}
    
     
    function offerExecuted(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public{}

     
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output) public payable returns(uint256 output){}
    
     
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns(uint256 output){}
}

 
 
 

contract Token {
     
    function totalSupply() view public returns (uint256 supply) {}

     
    function balanceOf(address _owner) view public returns (uint256 balance) {}

     
    function transfer(address _to, uint256 _value) public {}

     
    function transferFrom(address _from, address _to, uint256 _value)  public {}

     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 public decimals;
    string public name;
}

 
contract WETH is Token{
    function deposit() public payable {}
    function withdraw(uint256 amount) public {}
}