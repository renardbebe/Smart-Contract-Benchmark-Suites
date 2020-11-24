 

 
 

pragma solidity ^0.4.20;

contract SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}

contract ERC20 {
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
}

contract BitFrank is SafeMath {
    
    address public admin;
    
    string public constant name = "BitFrank v1";
    bool public suspendDeposit = false;  
 
     
    struct TOKEN_DETAIL {
        uint8 level;  
        uint fee;  
    }
    uint public marketRegisterCost = 99 * (10 ** 16);  
    uint public marketDefaultFeeLow = 2000;  
    uint public marketDefaultFeeHigh = 8000;  
    
    mapping (address => TOKEN_DETAIL) public tokenMarket;  
    address[] public tokenList;  
    
    mapping (address => mapping (address => uint)) public balance;  
    mapping (address => mapping (address => uint)) public balanceLocked;  
    
    uint public globalOrderSerial = 100000;  
    uint public PRICE_FACTOR = 10 ** 18;  
    
    struct ORDER {
        address token;
        bool isBuy;  
        address user;  
        uint wad;
        uint wadFilled;
        uint price;  
        uint listPosition;  
    }
    
    mapping (uint => ORDER) public order;  
    uint[] public orderList;  

     
    
    event MARKET_CHANGE(address indexed token);
    event DEPOSIT(address indexed user, address indexed token, uint wad, uint result);
    event WITHDRAW(address indexed user, address indexed token, uint wad, uint result);
    event ORDER_PLACE(address indexed user, address indexed token, bool isBuy, uint wad, uint price, uint indexed id);
    event ORDER_CANCEL(address indexed user, address indexed token, uint indexed id);
    event ORDER_MODIFY(address indexed user, address indexed token, uint indexed id, uint new_wad, uint new_price);
    event ORDER_FILL(address indexed userTaker, address userMaker, address indexed token, bool isOriginalOrderBuy, uint fillAmt, uint price, uint indexed id);
    event ORDER_DONE(address indexed userTaker, address userMaker, address indexed token, bool isOriginalOrderBuy, uint fillAmt, uint price, uint indexed id);
    
     
    
     
    
    function getOrderCount() public constant returns (uint) {
        return orderList.length;
    }
    
     
    
    function orderPlace(address token, bool isBuy, uint wad, uint price) public {
        
        uint newLocked;
        if (isBuy) {  
            newLocked = add(balanceLocked[0][msg.sender], mul(wad, price) / PRICE_FACTOR);
            require(balance[0][msg.sender] >= newLocked);
            balanceLocked[0][msg.sender] = newLocked;
        } else {  
            newLocked = add(balanceLocked[token][msg.sender], wad);
            require(balance[token][msg.sender] >= newLocked);
            balanceLocked[token][msg.sender] = newLocked;
        }
        
         
        ORDER memory o;
        o.token = token;
        o.isBuy = isBuy;
        o.wad = wad;
        o.price = price;
        o.user = msg.sender;
        o.listPosition = orderList.length;  
        order[globalOrderSerial] = o;
        
         
        orderList.push(globalOrderSerial);
        
         
        ORDER_PLACE(msg.sender, token, isBuy, wad, price, globalOrderSerial);

        globalOrderSerial++;  
    }
    
     
    
    function orderTrade(uint orderID, uint wad, uint price) public {
        
        ORDER storage o = order[orderID];
        require(price == o.price);  
        
         
        uint fillAmt = sub(o.wad, o.wadFilled);
        if (fillAmt > wad) fillAmt = wad;
        
         
        uint fillETH = mul(fillAmt, price) / PRICE_FACTOR;
        uint fee = mul(fillETH, tokenMarket[o.token].fee) / 1000000;
    
        uint newTakerBalance;
        
        if (o.isBuy) {  
            
             
            newTakerBalance = sub(balance[o.token][msg.sender], fillAmt);
            require(newTakerBalance >= balanceLocked[o.token][msg.sender]);
            balance[o.token][msg.sender] = newTakerBalance;
            
             
            balance[0][o.user] = sub(balance[0][o.user], fillETH);
            balanceLocked[0][o.user] = sub(balanceLocked[0][o.user], fillETH);
            
             
            balance[o.token][o.user] = add(balance[o.token][o.user], fillAmt);
            
             
            balance[0][msg.sender] = add(balance[0][msg.sender], sub(fillETH, fee));
            
        } else {  
        
             
            newTakerBalance = sub(balance[0][msg.sender], add(fillETH, fee));
            require(newTakerBalance >= balanceLocked[0][msg.sender]);
            balance[0][msg.sender] = newTakerBalance;

             
            balance[o.token][o.user] = sub(balance[o.token][o.user], fillAmt);
            balanceLocked[o.token][o.user] = sub(balanceLocked[o.token][o.user], fillAmt);
            
             
            balance[0][o.user] = add(balance[0][o.user], fillETH);

             
            balance[o.token][msg.sender] = add(balance[o.token][msg.sender], fillAmt);
        }
        
        balance[0][admin] = add(balance[0][admin], fee);

         
        o.wadFilled = add(o.wadFilled, fillAmt);
        
         
        if (o.wadFilled >= o.wad) {

             
            orderList[o.listPosition] = orderList[orderList.length - 1];
            order[orderList[o.listPosition]].listPosition = o.listPosition;  
            orderList.length--;
            
             
            ORDER_DONE(msg.sender, o.user, o.token, o.isBuy, fillAmt, price, orderID);

            delete order[orderID];
            
        } else {
            ORDER_FILL(msg.sender, o.user, o.token, o.isBuy, fillAmt, price, orderID);
        }
    }
    
    function orderCancel(uint orderID) public {
         
        ORDER memory o = order[orderID];  
        require(o.user == msg.sender);

        uint wadLeft = sub(o.wad, o.wadFilled);

         
        if (o.isBuy) {  
            balanceLocked[0][msg.sender] = sub(balanceLocked[0][msg.sender], mul(o.price, wadLeft) / PRICE_FACTOR);
        } else {  
            balanceLocked[o.token][msg.sender] = sub(balanceLocked[o.token][msg.sender], wadLeft);
        }

        ORDER_CANCEL(msg.sender, o.token, orderID);
        
         
        orderList[o.listPosition] = orderList[orderList.length - 1];
        order[orderList[o.listPosition]].listPosition = o.listPosition;  
        orderList.length--;
        
         
        delete order[orderID];
    }
    
    function orderModify(uint orderID, uint new_wad, uint new_price) public {
         
        ORDER storage o = order[orderID];  
        require(o.user == msg.sender);
        require(o.wadFilled == 0);  
        
         
        
        uint newLocked;
        if (o.isBuy) {  
            newLocked = sub(add(balanceLocked[0][msg.sender], mul(new_wad, new_price) / PRICE_FACTOR), mul(o.wad, o.price) / PRICE_FACTOR);
            require(balance[0][msg.sender] >= newLocked);
            balanceLocked[0][msg.sender] = newLocked;
        } else {  
            newLocked = sub(add(balanceLocked[o.token][msg.sender], new_wad), o.wad);
            require(balance[o.token][msg.sender] >= newLocked);
            balanceLocked[o.token][msg.sender] = newLocked;
        }
    
         
        o.wad = new_wad;
        o.price = new_price;
        
        ORDER_MODIFY(msg.sender, o.token, orderID, new_wad, new_price);
    }
  
     
  
    function BitFrank() public {
        admin = msg.sender;
        
        adminSetMarket(0, 9, 0);  
    }
    
     
    function adminSetAdmin(address newAdmin) public {
        require(msg.sender == admin);
        require(balance[0][newAdmin] > 0);  
        admin = newAdmin;
    }
    
     
    function adminSuspendDeposit(bool status) public {
        require(msg.sender == admin);
        suspendDeposit = status;
    }
    
     
    function adminSetMarket(address token, uint8 level_, uint fee_) public {
        require(msg.sender == admin);
        require(level_ != 0);
        require(level_ <= 9);
        if (tokenMarket[token].level == 0) {
            tokenList.push(token);
        }
        tokenMarket[token].level = level_;
        tokenMarket[token].fee = fee_;
        MARKET_CHANGE(token);
    }
    
     
    function adminSetRegisterCost(uint cost_) public {
        require(msg.sender == admin);
        marketRegisterCost = cost_;
    }
    
     
    function adminSetDefaultFee(uint marketDefaultFeeLow_, uint marketDefaultFeeHigh_) public {
        require(msg.sender == admin);
        marketDefaultFeeLow = marketDefaultFeeLow_;
        marketDefaultFeeHigh = marketDefaultFeeHigh_;
    }
    
     

     
    function marketRegisterToken(address token) public payable {
        require(tokenMarket[token].level == 1);
        require(msg.value >= marketRegisterCost);  
        balance[0][admin] = add(balance[0][admin], msg.value);
        
        tokenMarket[token].level = 2;
        tokenMarket[token].fee = marketDefaultFeeLow;
        MARKET_CHANGE(token);
    }
    
     
    function getTokenCount() public constant returns (uint) {
        return tokenList.length;
    }
  
     
  
    function depositETH() public payable {
        require(!suspendDeposit);
        balance[0][msg.sender] = add(balance[0][msg.sender], msg.value);
        DEPOSIT(msg.sender, 0, msg.value, balance[0][msg.sender]);
    }

    function depositToken(address token, uint wad) public {
        require(!suspendDeposit);
         
        require(ERC20(token).transferFrom(msg.sender, this, wad));  
        
         
        if (tokenMarket[token].level == 0) {
            tokenList.push(token);
            tokenMarket[token].level = 1;
            tokenMarket[token].fee = marketDefaultFeeHigh;
            MARKET_CHANGE(token);
        }
        
        balance[token][msg.sender] = add(balance[token][msg.sender], wad);  
        DEPOSIT(msg.sender, token, wad, balance[token][msg.sender]);
    }

    function withdrawETH(uint wad) public {
        balance[0][msg.sender] = sub(balance[0][msg.sender], wad);  
        require(balance[0][msg.sender] >= balanceLocked[0][msg.sender]);  
        msg.sender.transfer(wad);  
        WITHDRAW(msg.sender, 0, wad, balance[0][msg.sender]);
    }
    
    function withdrawToken(address token, uint wad) public {
        require(token != 0);  
        balance[token][msg.sender] = sub(balance[token][msg.sender], wad);
        require(balance[token][msg.sender] >= balanceLocked[token][msg.sender]);  
        require(ERC20(token).transfer(msg.sender, wad));  
        WITHDRAW(msg.sender, token, wad, balance[token][msg.sender]);
    }
}