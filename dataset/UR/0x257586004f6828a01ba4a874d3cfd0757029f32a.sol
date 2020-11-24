 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

contract dexBlue{
    
     

     
    event TradeSettled(uint8 index);

     
    event TradeFailed(uint8 index);

     
    event Deposit(address account, address token, uint256 amount);

     
    event Withdrawal(address account, address token, uint256 amount);

     
    event BlockedForSingleSigWithdrawal(address account, address token, uint256 amount);

     
    event SingleSigWithdrawal(address account, address token, uint256 amount);

     
    event FeeWithdrawal(address token, uint256 amount);

     
    event OrderCanceled(bytes32 hash);
   
     
    event DelegateStatus(address delegator, address delegate, bool status);


     

    mapping(address => mapping(address => uint256)) balances;                            
    mapping(address => mapping(address => uint256)) blocked_for_single_sig_withdrawal;   
    mapping(address => uint256) last_blocked_timestamp;                                  
    mapping(bytes32 => bool) processed_withdrawals;                                      
    mapping(bytes32 => uint256) matched;                                                 
    mapping(address => address) delegates;                                               


     

     
    struct EIP712_Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32          EIP712_DOMAIN_SEPARATOR;
     
    bytes32 constant EIP712_ORDER_TYPEHASH = keccak256("Order(address buyTokenAddress,address sellTokenAddress,uint256 buyTokenAmount,uint256 sellTokenAmount,uint64 nonce)");
     
    bytes32 constant EIP712_WITHDRAWAL_TYPEHASH = keccak256("Withdrawal(address token,uint256 amount,uint64 nonce)");
        

     

     
    function getBalance(address token, address holder) constant public returns(uint256){
        return balances[token][holder];
    }
    
     
    function getBlocked(address token, address holder) constant public returns(uint256){
        return blocked_for_single_sig_withdrawal[token][holder];
    }
    
     
    function getLastBlockedTimestamp(address user) constant public returns(uint256){
        return last_blocked_timestamp[user];
    }


     

     
    function depositEther() public payable{
        balances[address(0)][msg.sender] += msg.value;       
        emit Deposit(msg.sender, address(0), msg.value);     
    }
    
     
    function() public payable{
        depositEther();                                      
    }
    
     
    function depositToken(address token, uint256 amount) public {
        Token(token).transferFrom(msg.sender, address(this), amount);     
        require(
            checkERC20TransferSuccess(),                                  
            "ERC20 token transfer failed."
        );
        balances[token][msg.sender] += amount;                            
        emit Deposit(msg.sender, token, amount);                          
    }
        
     

     
    function multiSigWithdrawal(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s) public {
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

            blocked_for_single_sig_withdrawal[token][msg.sender] = 0;    
        
            emit Withdrawal(msg.sender,token,amount);                    
        }else{
            revert();                                                    
        }
    }    

     
    function multiSigSend(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address receiving_address) public {
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
            
            emit Withdrawal(msg.sender,token,amount);                    
        }else{
            revert();                                                    
        }
    }

     
    function multiSigTransfer(address token, uint256 amount, uint64 nonce, uint8 v, bytes32 r, bytes32 s, address receiving_address) public {
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
            
            emit Withdrawal(msg.sender,token,amount);                    
            emit Deposit(receiving_address,token,amount);                
        }else{
            revert();                                                    
        }
    }

     
    function userSigWithdrawal(address token, uint256 amount, uint256 fee, uint64 nonce, uint8 v, bytes32 r, bytes32 s) public {            
        bytes32 hash;
        if(v < 30){                                                      
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
            v -= 10;                                                     
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
        address account = ecrecover(hash, v, r, s);                      
        if(
            !processed_withdrawals[hash]                                 
            && arbiters[msg.sender]                                      
            && fee <= amount / 50                                        
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
            
            emit Withdrawal(account,token,amount);                       
        }else{
            revert();                                                    
        }
    }
    
     

     
    function blockFundsForSingleSigWithdrawal(address token, uint256 amount) public {
        if (balances[token][msg.sender] - blocked_for_single_sig_withdrawal[token][msg.sender] >= amount){   
            blocked_for_single_sig_withdrawal[token][msg.sender] += amount;          
            last_blocked_timestamp[msg.sender] = block.timestamp;                    
            emit BlockedForSingleSigWithdrawal(msg.sender,token,amount);             
        }else{
            revert();                                                                
        }
    }
    
     
    function initiateSingleSigWithdrawal(address token, uint256 amount) public {
        if (
            balances[token][msg.sender] >= amount                                    
            && blocked_for_single_sig_withdrawal[token][msg.sender] >= amount        
            && last_blocked_timestamp[msg.sender] + 86400 <= block.timestamp         
        ){
            balances[token][msg.sender] -= amount;                                   
            blocked_for_single_sig_withdrawal[token][msg.sender] -= amount;          
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
            emit SingleSigWithdrawal(msg.sender,token,amount);                       
        }else{
            revert();                                                                
        }
    } 


     
    
    struct OrderInput{
        uint8       buy_token;       
        uint8       sell_token;      
        uint256     buy_amount;      
        uint256     sell_amount;     
        uint64      nonce;           
        int8        v;               
                                     
                                     
        bytes32     r;               
        bytes32     s;               
    }
    
    struct TradeInput{
        uint8       maker_order;     
        uint8       taker_order;     
        uint256     maker_amount;    
        uint256     taker_amount;    
        uint256     maker_fee;       
        uint256     taker_fee;       
        uint256     maker_rebate;    
    }

        
    function matchTrades(address[] addresses, OrderInput[] orders, TradeInput[] trades) public {
        require(arbiters[msg.sender] && marketActive);       
        
         
        uint len = orders.length;                            
        bytes32[]  memory hashes = new bytes32[](len);       
        address[]  memory signee = new address[](len);       
        OrderInput memory order;                             
        address    addressCache1;                            
        address    addressCache2;                            
        bool       delegated;
        
        for(uint8 i = 0; i < len; i++){                      
            order         = orders[i];                       
            addressCache1 = addresses[order.buy_token];      
            addressCache2 = addresses[order.sell_token];     
            
            if(order.v < 0){                                 
                delegated = true;                           
                order.v  *= -1;                              
            }else{
                delegated = false;
            }
            
            if(order.v < 30){                                
                hashes[i] = keccak256(abi.encodePacked(      
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(
                        addressCache1,
                        addressCache2,
                        order.buy_amount,
                        order.sell_amount,
                        order.nonce,        
                        address(this)                        
                    ))
                ));
            }else{                                           
                order.v -= 10;                               
                hashes[i] = keccak256(abi.encodePacked(
                    "\x19\x01",
                    EIP712_DOMAIN_SEPARATOR,
                    keccak256(abi.encode(
                        EIP712_ORDER_TYPEHASH,
                        addressCache1,
                        addressCache2,
                        order.buy_amount,
                        order.sell_amount,
                        order.nonce
                    ))
                ));
            }
            signee[i] = ecrecover(                           
                hashes[i],                                   
                uint8(order.v),                              
                order.r,                                     
                order.s                                      
            );
             
            if(delegated){
                signee[i] = delegates[signee[i]];
            }
        }
        
         
        len = trades.length;                                             
        TradeInput memory trade;                                         
        uint maker_index;                                                
        uint taker_index;                                                
        
        for(i = 0; i < len; i++){                                        
            trade = trades[i];                                           
            maker_index = trade.maker_order;                             
            taker_index = trade.taker_order;                             
            addressCache1 = addresses[orders[maker_index].buy_token];    
            addressCache2 = addresses[orders[taker_index].buy_token];    
            
            if(  
                 
                    orders[maker_index].buy_token == orders[taker_index].sell_token
                && orders[taker_index].buy_token == orders[maker_index].sell_token
                
                 
                && balances[addressCache2][signee[maker_index]] >= trade.maker_amount - trade.maker_rebate
                && balances[addressCache1][signee[taker_index]] >= trade.taker_amount
                
                 
                && trade.maker_amount - trade.maker_rebate <= orders[maker_index].sell_amount * trade.taker_amount / orders[maker_index].buy_amount + 1   
                && trade.taker_amount <= orders[taker_index].sell_amount * trade.maker_amount / orders[taker_index].buy_amount + 1                        
                
                 
                && trade.taker_amount + matched[hashes[taker_index]] <= orders[taker_index].sell_amount
                && trade.maker_amount - trade.maker_rebate + matched[hashes[maker_index]] <= orders[maker_index].sell_amount
                    
                 
                && trade.maker_fee <= trade.taker_amount / 100
                && trade.taker_fee <= trade.maker_amount / 50
                
                 
                && trade.maker_rebate <= trade.taker_fee
            ){
                 
                
                 
                balances[addressCache2][signee[maker_index]] -= trade.maker_amount - trade.maker_rebate;     
                balances[addressCache1][signee[taker_index]] -= trade.taker_amount;                          
                
                 
                balances[addressCache1][signee[maker_index]] += trade.taker_amount - trade.maker_fee;        
                balances[addressCache2][signee[taker_index]] += trade.maker_amount - trade.taker_fee;        
                
                 
                matched[hashes[maker_index]] += trade.maker_amount;                                          
                matched[hashes[taker_index]] += trade.taker_amount;                                          
                
                 
                balances[addressCache2][feeCollector] += trade.taker_fee - trade.maker_rebate;               
                balances[addressCache1][feeCollector] += trade.maker_fee;                                    
                
                 
                blocked_for_single_sig_withdrawal[addressCache2][signee[maker_index]] = 0;                   
                blocked_for_single_sig_withdrawal[addressCache1][signee[taker_index]] = 0;                   
                
                emit TradeSettled(i);                                                                        
            }else{
                emit TradeFailed(i);                                                                         
            }
        }
    }


     

     
    function multiSigOrderBatchCancel(bytes32[] orderHashes, uint8 v, bytes32 r, bytes32 s) public {
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
            uint len = orderHashes.length;
            for(uint8 i = 0; i < len; i++){
                matched[orderHashes[i]] = 2**256 - 1;                
                emit OrderCanceled(orderHashes[i]);                  
            }
        }else{
            revert();
        }
    }
        
     
    function orderBatchCancel(bytes32[] orderHashes) public {
        if(
            arbiters[msg.sender]                         
        ){
            uint len = orderHashes.length;
            for(uint8 i = 0; i < len; i++){
                matched[orderHashes[i]] = 2**256 - 1;    
                emit OrderCanceled(orderHashes[i]);      
            }
        }else{
            revert();
        }
    }
        
        
     

     
    function delegateAddress(address delegate) public {
         
        require(delegates[delegate] == address(0), "Address is already a delegate");
        delegates[delegate] = msg.sender;
        
        emit DelegateStatus(msg.sender, delegate, true);
    }
    
     
    function revokeDelegation(address delegate, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 hash = keccak256(abi.encodePacked(               
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(
                delegate,
                msg.sender,
                address(this)
            ))
        ));

        require(arbiters[ecrecover(hash, v, r, s)], "MultiSig is not from known arbiter");   
        
        delegates[delegate] = address(1);        
        
        emit DelegateStatus(msg.sender, delegate, false);
    }
    

     

    address owner;                       
    address feeCollector;                
    bool marketActive = true;            
    bool feeCollectorLocked = false;     
    mapping(address => bool) arbiters;   
    
     
    constructor() public {
        owner = msg.sender;              
        feeCollector = msg.sender;       
        arbiters[msg.sender] = true;     
        
         
        EIP712_Domain memory eip712Domain = EIP712_Domain({
            name              : "dex.blue",
            version           : "1",
            chainId           : 1,
            verifyingContract : this
        });
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }
    
     
    function nominateArbiter(address arbiter, bool status) public {
        require(msg.sender == owner);                            
        arbiters[arbiter] = status;                              
    }

     
    function setMarketActiveState(bool state) public {
        require(msg.sender == owner);                            
        marketActive = state;                                    
    }
    
     
    function nominateFeeCollector(address collector) public {
        require(msg.sender == owner && !feeCollectorLocked);     
        feeCollector = collector;                                
    }
    
     
    function lockFeeCollector() public {
        require(msg.sender == owner);                            
        feeCollectorLocked = true;                               
    }
    
     
    function getFeeCollector() public constant returns (address){
        return feeCollector;
    }

     
    function feeWithdrawal(address token, uint256 amount) public {
        if (
            msg.sender == feeCollector                               
            && balances[token][feeCollector] >= amount               
        ){
            balances[token][feeCollector] -= amount;                 
            if(token == address(0)){                                 
                require(
                    feeCollector.send(amount),                       
                    "Sending of ETH failed."
                );
            }else{
                Token(token).transfer(feeCollector, amount);         
                require(                                             
                    checkERC20TransferSuccess(),
                    "ERC20 token transfer failed."
                );
            }
            emit FeeWithdrawal(token,amount);                        
        }else{
            revert();                                                
        }
    }
    
     
    function checkERC20TransferSuccess() pure private returns(bool){
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




 
 
 

contract Token {
     
    function totalSupply() constant public returns (uint256 supply) {}

     
    function balanceOf(address _owner) constant public returns (uint256 balance) {}

     
    function transfer(address _to, uint256 _value) public {}

     
    function transferFrom(address _from, address _to, uint256 _value)  public {}

     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public decimals;
    string public name;
}