 

pragma solidity ^0.4.19;

 
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

 
contract Exchange {
    function assert(bool assertion) {
        if (!assertion) throw;
    }

     
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

     
    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner;  
    mapping (address => bool) public admins;  
    mapping (address => bool) public futuresContracts;  
    event SetFuturesContract(address futuresContract, bool isFuturesContract);

     
    event SetOwner(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

     
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }

     
    function getOwner() returns (address out) {
        return owner;
    }

     
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }


     
    function setFuturesContract(address futuresContract, bool isFuturesContract) onlyOwner {
        futuresContracts[futuresContract] = isFuturesContract;
        emit SetFuturesContract(futuresContract, isFuturesContract);
    }

     
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }

     
    modifier onlyFuturesContract {
        if (!futuresContracts[msg.sender]) throw;
        _;
    }

    function() external {
        throw;
    }

     
     
    mapping (address => mapping (address => uint256)) public balances;  

    mapping (address => uint256) public lastActiveTransaction;  
    mapping (bytes32 => uint256) public orderFills;  
    
    address public feeAccount;  
    address public EtmTokenAddress;  

    uint256 public inactivityReleasePeriod;  
    mapping (bytes32 => bool) public withdrawn;  
    uint256 public makerFee;  
    uint256 public takerFee;  

    enum Errors {
        INVLID_PRICE,            
        INVLID_SIGNATURE,        
        TOKENS_DONT_MATCH,       
        ORDER_ALREADY_FILLED,    
        GAS_TOO_HIGH             
    }

     
    event Trade(
        address takerTokenBuy, uint256 takerAmountBuy,
        address takerTokenSell, uint256 takerAmountSell,
        address maker, address indexed taker,
        uint256 makerFee, uint256 takerFee,
        uint256 makerAmountTaken, uint256 takerAmountTaken,
        bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash
    );

     
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);

     
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 withdrawFee);
    event WithdrawTo(address indexed token, address indexed to, address indexed from, uint256 amount, uint256 balance, uint256 withdrawFee);

     
    event FeeChange(uint256 indexed makerFee, uint256 indexed takerFee);

     
    event LogError(uint8 indexed errorId, bytes32 indexed makerOrderHash, bytes32 indexed takerOrderHash);
    event LogUint(uint8 id, uint256 value);
    event LogBool(uint8 id, bool value);
    event LogAddress(uint8 id, address value);

     
    event InactivityReleasePeriodChange(uint256 value);

     
    event CancelOrder(
        bytes32 indexed cancelHash,
        bytes32 indexed orderHash,
        address indexed user,
        address tokenSell,
        uint256 amountSell,
        uint256 cancelFee
    );

     
    function setInactivityReleasePeriod(uint256 expiry) onlyOwner returns (bool success) {
        if (expiry > 1000000) throw;
        inactivityReleasePeriod = expiry;

        emit InactivityReleasePeriodChange(expiry);
        return true;
    }

     
    function Exchange(address feeAccount_, uint256 makerFee_, uint256 takerFee_) {
        owner = msg.sender;
        feeAccount = feeAccount_;
        inactivityReleasePeriod = 100000;
        makerFee = makerFee_;
        takerFee = takerFee_;
    }

     
    function setFees(uint256 makerFee_, uint256 takerFee_) onlyOwner {
        require(makerFee_ < 10 finney && takerFee_ < 10 finney);  
        makerFee = makerFee_;
        takerFee = takerFee_;

        emit FeeChange(makerFee, takerFee);
    }

    

     
    function depositToken(address token, uint128 amount) {
         
         
        addBalance(token, msg.sender, amount);  

        lastActiveTransaction[msg.sender] = block.number;  
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;  
        emit Deposit(token, msg.sender, amount, balanceOf(token, msg.sender));  
    }

    function updateBalanceAndReserve (address token, address user, uint256 balance, uint256 reserve) private
    {
        uint256 character = uint256(balance);
        character |= reserve<<128;

        balances[token][user] = character;
    }

    function updateBalance (address token, address user, uint256 balance) private returns (bool)
    {
        uint256 character = uint256(balance);
        character |= getReserve(token, user)<<128;

        balances[token][user] = character;
        return true;
    }

    function updateReserve (address token, address user, uint256 reserve) private
    {
        uint256 character = uint256(balanceOf(token, user));
        character |= reserve<<128;

        balances[token][user] = character;
    }

    function decodeBalanceAndReserve (address token, address user) returns (uint256[2])
    {
        uint256 character = balances[token][user];
        uint256 balance = uint256(uint128(character));
        uint256 reserve = uint256(uint128(character>>128));

        return [balance, reserve];
    }

     
    function balanceOf(address token, address user) view returns (uint256) {
         
        return decodeBalanceAndReserve(token, user)[0];
    }

     
    function getReserve(address token, address user) public view returns (uint256) { 
         
        return decodeBalanceAndReserve(token, user)[1];
    }

     
    function setReserve(address token, address user, uint256 amount) onlyFuturesContract returns (bool success) { 
         
        if (availableBalanceOf(token, user) < amount) throw; 
        updateReserve(token, user, amount);
        return true; 
    }

     
    function setBalance(address token, address user, uint256 amount) onlyFuturesContract returns (bool success)     {
         
        updateBalance(token, user, amount);
        return true;
        
    }

    function subBalanceAddReserve(address token, address user, uint256 subBalance, uint256 addReserve) onlyFuturesContract returns (bool)
    {
        updateBalanceAndReserve(token, user, safeSub(balanceOf(token, user), subBalance), safeAdd(getReserve(token, user), addReserve));
    }

    function addBalanceSubReserve(address token, address user, uint256 addBalance, uint256 subReserve) onlyFuturesContract returns (bool)
    {
        updateBalanceAndReserve(token, user, safeAdd(balanceOf(token, user), addBalance), safeSub(getReserve(token, user), subReserve));
    }

    function subBalanceSubReserve(address token, address user, uint256 subBalance, uint256 subReserve) onlyFuturesContract returns (bool)
    {
         
         
         
        updateBalanceAndReserve(token, user, safeSub(balanceOf(token, user), subBalance), safeSub(getReserve(token, user), subReserve));
    }

     
    function availableBalanceOf(address token, address user) view returns (uint256) {
        return safeSub(balanceOf(token, user), getReserve(token, user));
    }

     
    function getInactivityReleasePeriod() view returns (uint256)
    {
        return inactivityReleasePeriod;
    }

     
    function addBalance(address token, address user, uint256 amount)
    {
        updateBalance(token, user, safeAdd(balanceOf(token, user), amount));
    }

     
    function subBalance(address token, address user, uint256 amount)
    {
        if (availableBalanceOf(token, user) < amount) throw; 
        updateBalance(token, user, safeSub(balanceOf(token, user), amount));
    }


     
    function deposit() payable {
         
        addBalance(address(0), msg.sender, msg.value);  

        lastActiveTransaction[msg.sender] = block.number;  
        emit Deposit(address(0), msg.sender, msg.value, balanceOf(address(0), msg.sender));  
    }

     
    function depositTokenFor(address token, uint128 amount, address destinationUser)  returns (bool success) {
         
        addBalance(token, destinationUser, amount);  

        lastActiveTransaction[destinationUser] = block.number;  
        if (!Token(token).transferFrom(msg.sender, this, amount)) throw;  
        emit Deposit(token, destinationUser, amount, balanceOf(token, destinationUser));  
        return true;
    }

     
    function depositFor(address destinationUser) payable  returns (bool success) {
         
        addBalance(address(0), destinationUser, msg.value);  

        lastActiveTransaction[destinationUser] = block.number;  
        emit Deposit(address(0), destinationUser, msg.value, balanceOf(address(0), destinationUser));  
        return true;
    }

    function withdraw(address token, uint256 amount) returns (bool success) {
         
         
        if (availableBalanceOf(token, msg.sender) < amount) throw;

         
        subBalance(token, msg.sender, amount);  

        if (token == address(0)) {  
            if (!msg.sender.send(amount)) throw;  
        } else {
            if (!Token(token).transfer(msg.sender, amount)) throw;  
        }
        emit Withdraw(token, msg.sender, amount, balanceOf(token, msg.sender), 0);  
    }

     
    function adminWithdraw(
        address token,  
        uint256 amount,  
        address user,  
        uint256 nonce,  
        uint8 v,  
        bytes32 r,  
        bytes32 s,  
        uint256 feeWithdrawal  
    ) onlyAdmin returns (bool success) {
        bytes32 hash = keccak256(this, token, amount, user, nonce);  
        if (withdrawn[hash]) throw;  
        withdrawn[hash] = true;  
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) != user) throw;  
        if (feeWithdrawal > 50 finney) feeWithdrawal = 50 finney;  


         
        if (availableBalanceOf(token, user) < amount) throw;  

         
        subBalance(token, user, amount);  

         
        subBalance(address(0), user, feeWithdrawal);  

         
        addBalance(address(0), feeAccount, feeWithdrawal);  

        if (token == address(0)) {  
            if (!user.send(amount)) throw;  
        } else {
            if (!Token(token).transfer(user, amount)) throw;  
        }
        lastActiveTransaction[user] = block.number;  
        emit Withdraw(token, user, amount, balanceOf(token, user), feeWithdrawal);  
    }

    function batchAdminWithdraw(
        address[] token,  
        uint256[] amount,  
        address[] user,  
        uint256[] nonce,  
        uint8[] v,  
        bytes32[] r,  
        bytes32[] s,  
        uint256[] feeWithdrawal  
    ) onlyAdmin 
    {
        for (uint i = 0; i < amount.length; i++) {
            adminWithdraw(
                token[i],
                amount[i],
                user[i],
                nonce[i],
                v[i],
                r[i],
                s[i],
                feeWithdrawal[i]
            );
        }
    }

 

    function getMakerTakerBalances(address token, address maker, address taker) view returns (uint256[4])
    {
        return [
            balanceOf(token, maker),
            balanceOf(token, taker),
            getReserve(token, maker),
            getReserve(token, taker)
        ];
    }

    

     
    struct OrderPair {
        uint256 makerAmountBuy;      
        uint256 makerAmountSell;     
        uint256 makerNonce;          
        uint256 takerAmountBuy;      
        uint256 takerAmountSell;     
        uint256 takerNonce;          
        uint256 takerGasFee;         
        uint256 takerIsBuying;       

        address makerTokenBuy;       
        address makerTokenSell;      
        address maker;               
        address takerTokenBuy;       
        address takerTokenSell;      
        address taker;               

        bytes32 makerOrderHash;      
        bytes32 takerOrderHash;      
    }

     
    struct TradeValues {
        uint256 qty;                 
        uint256 invQty;              
        uint256 makerAmountTaken;    
        uint256 takerAmountTaken;    
    }

     
    function trade(
        uint8[2] v,
        bytes32[4] rs,
        uint256[8] tradeValues,
        address[6] tradeAddresses
    ) returns (uint filledTakerTokenAmount)
    {

         

        OrderPair memory t  = OrderPair({
            makerAmountBuy  : tradeValues[0],
            makerAmountSell : tradeValues[1],
            makerNonce      : tradeValues[2],
            takerAmountBuy  : tradeValues[3],
            takerAmountSell : tradeValues[4],
            takerNonce      : tradeValues[5],
            takerGasFee     : tradeValues[6],
            takerIsBuying   : tradeValues[7],

            makerTokenBuy   : tradeAddresses[0],
            makerTokenSell  : tradeAddresses[1],
            maker           : tradeAddresses[2],
            takerTokenBuy   : tradeAddresses[3],
            takerTokenSell  : tradeAddresses[4],
            taker           : tradeAddresses[5],

             
            makerOrderHash  : keccak256(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]),
            takerOrderHash  : keccak256(this, tradeAddresses[3], tradeValues[3], tradeAddresses[4], tradeValues[4], tradeValues[5], tradeAddresses[5])
        });

         
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.makerOrderHash), v[0], rs[0], rs[1]) != t.maker)
        {
            emit LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }
       
        
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", t.takerOrderHash), v[1], rs[2], rs[3]) != t.taker)
        {
            emit LogError(uint8(Errors.INVLID_SIGNATURE), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }


         
        if (t.makerTokenBuy != t.takerTokenSell || t.makerTokenSell != t.takerTokenBuy)
        {
            emit LogError(uint8(Errors.TOKENS_DONT_MATCH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }  


         
        if (t.takerGasFee > 100 finney)
        {
            emit LogError(uint8(Errors.GAS_TOO_HIGH), t.makerOrderHash, t.takerOrderHash);
            return 0;
        }  


         
         
        if (!(
        (t.takerIsBuying == 0 && safeMul(t.makerAmountSell, 1 ether) / t.makerAmountBuy >= safeMul(t.takerAmountBuy, 1 ether) / t.takerAmountSell)
        ||
        (t.takerIsBuying > 0 && safeMul(t.makerAmountBuy, 1 ether) / t.makerAmountSell <= safeMul(t.takerAmountSell, 1 ether) / t.takerAmountBuy)
        ))
        {
            emit LogError(uint8(Errors.INVLID_PRICE), t.makerOrderHash, t.takerOrderHash);
            return 0;  
        }

         
        TradeValues memory tv = TradeValues({
            qty                 : 0,
            invQty              : 0,
            makerAmountTaken    : 0,
            takerAmountTaken    : 0
        });
        
         
        if (t.takerIsBuying == 0)
        {
             
            tv.qty = min(safeSub(t.makerAmountBuy, orderFills[t.makerOrderHash]), safeSub(t.takerAmountSell, safeMul(orderFills[t.takerOrderHash], t.takerAmountSell) / t.takerAmountBuy));
            if (tv.qty == 0)
            {
                 
                emit LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }

             
            tv.invQty = safeMul(tv.qty, t.makerAmountSell) / t.makerAmountBuy;

           
             
            tv.makerAmountTaken                         = safeSub(tv.qty, safeMul(tv.qty, makerFee) / (1 ether));                                        
             
            addBalance(t.makerTokenBuy, feeAccount, safeMul(tv.qty, makerFee) / (1 ether));  
        

        
             
            tv.takerAmountTaken                         = safeSub(safeSub(tv.invQty, safeMul(tv.invQty, takerFee) / (1 ether)), safeMul(tv.invQty, t.takerGasFee) / (1 ether));                              
             
            addBalance(t.takerTokenBuy, feeAccount, safeAdd(safeMul(tv.invQty, takerFee) / (1 ether), safeMul(tv.invQty, t.takerGasFee) / (1 ether)));  


             
            subBalance(t.makerTokenSell, t.maker, tv.invQty);  

             
            addBalance(t.makerTokenBuy, t.maker, tv.makerAmountTaken);  

             


             
            subBalance(t.takerTokenSell, t.taker, tv.qty);  

             
             
            addBalance(t.takerTokenBuy, t.taker, tv.takerAmountTaken);  
        
            orderFills[t.makerOrderHash]                = safeAdd(orderFills[t.makerOrderHash], tv.qty);                                                 
            orderFills[t.takerOrderHash]                = safeAdd(orderFills[t.takerOrderHash], safeMul(tv.qty, t.takerAmountBuy) / t.takerAmountSell);  
            lastActiveTransaction[t.maker]              = block.number;  
            lastActiveTransaction[t.taker]              = block.number;  

             
            emit Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
         
        else
        {
             
            tv.qty = min(safeSub(t.makerAmountSell,  safeMul(orderFills[t.makerOrderHash], t.makerAmountSell) / t.makerAmountBuy), safeSub(t.takerAmountBuy, orderFills[t.takerOrderHash]));
            if (tv.qty == 0)
            {
                 
                emit LogError(uint8(Errors.ORDER_ALREADY_FILLED), t.makerOrderHash, t.takerOrderHash);
                return 0;
            }            

             
            tv.invQty = safeMul(tv.qty, t.makerAmountBuy) / t.makerAmountSell;
            
           
             
            tv.makerAmountTaken                         = safeSub(tv.invQty, safeMul(tv.invQty, makerFee) / (1 ether));                                  
             
            addBalance(t.makerTokenBuy, feeAccount, safeMul(tv.invQty, makerFee) / (1 ether));  
     

             
            
             
            tv.takerAmountTaken                         = safeSub(safeSub(tv.qty, safeMul(tv.qty, takerFee) / (1 ether)), safeMul(tv.qty, t.takerGasFee) / (1 ether));                                   
             
            addBalance(t.takerTokenBuy, feeAccount, safeAdd(safeMul(tv.qty, takerFee) / (1 ether), safeMul(tv.qty, t.takerGasFee) / (1 ether)));  



             
            subBalance(t.makerTokenSell, t.maker, tv.qty);  

             
             
            addBalance(t.makerTokenBuy, t.maker, tv.makerAmountTaken);  

             

             
            subBalance(t.takerTokenSell, t.taker, tv.invQty);

             
             
            addBalance(t.takerTokenBuy, t.taker, tv.takerAmountTaken);  

             

             
             

            orderFills[t.makerOrderHash]            = safeAdd(orderFills[t.makerOrderHash], tv.invQty);  
            orderFills[t.takerOrderHash]            = safeAdd(orderFills[t.takerOrderHash], tv.qty);   
            lastActiveTransaction[t.maker]          = block.number;  
            lastActiveTransaction[t.taker]          = block.number;  

             
            emit Trade(
                t.takerTokenBuy, tv.qty,
                t.takerTokenSell, tv.invQty,
                t.maker, t.taker,
                makerFee, takerFee,
                tv.makerAmountTaken , tv.takerAmountTaken,
                t.makerOrderHash, t.takerOrderHash
            );
            return tv.qty;
        }
    }


     
    function batchOrderTrade(
        uint8[2][] v,
        bytes32[4][] rs,
        uint256[8][] tradeValues,
        address[6][] tradeAddresses
    ) 
    {
        for (uint i = 0; i < tradeAddresses.length; i++) {
            trade(
                v[i],
                rs[i],
                tradeValues[i],
                tradeAddresses[i]
            );
        }
    }

     
    function cancelOrder(
		 
	    uint8[2] v,

		 
	    bytes32[4] rs,

		 
		uint256[5] cancelValues,

		 
		address[4] cancelAddresses
    ) public {
         
        bytes32 orderHash = keccak256(
	        this, cancelAddresses[0], cancelValues[0], cancelAddresses[1],
	        cancelValues[1], cancelValues[2], cancelAddresses[2]
        );
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), v[0], rs[0], rs[1]) == cancelAddresses[2]);

         
        bytes32 cancelHash = keccak256(this, orderHash, cancelAddresses[3], cancelValues[3]);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", cancelHash), v[1], rs[2], rs[3]) == cancelAddresses[3]);

         
        require(cancelAddresses[2] == cancelAddresses[3]);

         
        require(orderFills[orderHash] != cancelValues[0]);

         
        if (cancelValues[4] > 50 finney) {
            cancelValues[4] = 50 finney;
        }

         
         
         
        subBalance(address(0), cancelAddresses[3], cancelValues[4]);

         
        orderFills[orderHash] = cancelValues[0];

         
        emit CancelOrder(cancelHash, orderHash, cancelAddresses[3], cancelAddresses[1], cancelValues[1], cancelValues[4]);
    }

     
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
}