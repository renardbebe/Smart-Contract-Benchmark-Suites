 

pragma solidity ^0.4.21;

 
contract Share {

    bool public pause;
     
    address public owner;
    
     
    mapping (address => uint) public holds;

     
    mapping (address => uint256) public fullfilled;

     
    mapping (address => uint256) public sellPrice;
    mapping (address => uint) public toSell;

    uint256 public watermark;

    event PAUSED();
    event STARTED();

    event SHARE_TRANSFER(address from, address to, uint amount);
    event INCOME(uint256);
    event PRICE_SET(address holder, uint shares, uint256 price, uint sell);
    event WITHDRAWAL(address owner, uint256 amount);
    event SELL_HOLDS(address from, address to, uint amount, uint256 price);
    event SEND_HOLDS(address from, address to, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPaused() {
        require(!pause);
        _;
    }
    
    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        
        if (_pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        } 
    }

     
    function Share() public {        
        owner = msg.sender;
        holds[owner] = 10000;
        pause = false;
    }

     
    function onIncome() public payable {
        if (msg.value > 0) {
            watermark += (msg.value / 10000);
            assert(watermark * 10000 > watermark);

            emit INCOME(msg.value);
        }
    }

     
    function() public payable {
        onIncome();
    }

    function bonus() public view returns (uint256) {
        return (watermark - fullfilled[msg.sender]) * holds[msg.sender];
    }
    
    function setPrice(uint256 price, uint sell) public notPaused {
        sellPrice[msg.sender] = price;
        toSell[msg.sender] = sell;
        emit PRICE_SET(msg.sender, holds[msg.sender], price, sell);
    }

     
    function withdrawal() public notPaused {
        if (holds[msg.sender] == 0) {
             
            return;
        }
        uint256 value = bonus();
        fullfilled[msg.sender] = watermark;

        msg.sender.transfer(value);

        emit WITHDRAWAL(msg.sender, value);
    }

     
    function transferHolds(address from, address to, uint amount) internal {
        require(holds[from] >= amount);
        require(amount > 0);

        uint256 fromBonus = (watermark - fullfilled[from]) * amount;
        uint256 toBonus = (watermark - fullfilled[to]) * holds[to];
        

        holds[from] -= amount;
        holds[to] += amount;
        fullfilled[to] = watermark - toBonus / holds[to];

        from.transfer(fromBonus);

        emit SHARE_TRANSFER(from, to, amount);
        emit WITHDRAWAL(from, fromBonus);
    }

     
    function buyFrom(address from) public payable notPaused {
        require(sellPrice[from] > 0);
        uint256 amount = msg.value / sellPrice[from];

        if (amount >= holds[from]) {
            amount = holds[from];
        }

        if (amount >= toSell[from]) {
            amount = toSell[from];
        }

        require(amount > 0);

        toSell[from] -= amount;
        transferHolds(from, msg.sender, amount);
        from.transfer(msg.value);
        
        emit SELL_HOLDS(from, msg.sender, amount, sellPrice[from]);
    }
    
    function transfer(address to, uint amount) public notPaused {
        require(holds[msg.sender] >= amount);
        transferHolds(msg.sender, to, amount);
        
        emit SEND_HOLDS(msg.sender, to, amount);
    }
}