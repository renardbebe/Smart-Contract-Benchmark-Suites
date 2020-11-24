 

pragma solidity ^0.4.24;

contract Control {
    address public owner;
    bool public pause;

    event PAUSED();
    event STARTED();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whenPaused {
        require(pause);
        _;
    }

    modifier whenNotPaused {
        require(!pause);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        if (pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }

}
 
contract Share is Control {     
    mapping (address => uint) public holds;

     
    mapping (address => uint256) public fullfilled;

     
    mapping (address => uint256) public sellPrice;
    mapping (address => uint256) public toSell;
    mapping (address => mapping(address => uint256)) public allowance;
    uint256 public watermark;
    uint256 public total;
    uint256 public decimals;
    
    string public symbol;
    string public name;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event INCOME(uint256);
    event PRICE_SET(address holder, uint shares, uint256 price, uint sell);
    event WITHDRAWAL(address owner, uint256 amount);
    event SELL_HOLDS(address from, address to, uint amount, uint256 price);
    event SEND_HOLDS(address from, address to, uint amount);

     
    constructor(string _symbol, string _name, uint256 _total) public {        
        symbol = _symbol;
        name = _name;
        owner = msg.sender;
        total = _total;
        holds[owner] = total;
        decimals = 0;
        pause = false;
    }

     
    function onIncome() public payable {
        if (msg.value > 0) {
            watermark += (msg.value / total);
            assert(watermark * total > watermark);
            emit INCOME(msg.value);
        }
    }

     
    function() public payable {
        onIncome();
    }

    function bonus() public view returns (uint256) {
        return (watermark - fullfilled[msg.sender]) * holds[msg.sender];
    }
    
    function setPrice(uint256 price, uint256 sell) public {
        sellPrice[msg.sender] = price;
        toSell[msg.sender] = sell;
        emit PRICE_SET(msg.sender, holds[msg.sender], price, sell);
    }

     
    function withdrawal() public whenNotPaused {
        if (holds[msg.sender] == 0) {
             
            return;
        }
        uint256 value = bonus();
        fullfilled[msg.sender] = watermark;

        msg.sender.transfer(value);

        emit WITHDRAWAL(msg.sender, value);
    }

     
    function transferHolds(address from, address to, uint256 amount) internal {
        require(holds[from] >= amount);
        require(holds[to] + amount > holds[to]);

        uint256 fromBonus = (watermark - fullfilled[from]) * amount;
        uint256 toBonus = (watermark - fullfilled[to]) * holds[to];
        

        holds[from] -= amount;
        holds[to] += amount;
        fullfilled[to] = watermark - toBonus / holds[to];

        from.transfer(fromBonus);

        emit Transfer(from, to, amount);
        emit WITHDRAWAL(from, fromBonus);
    }

     
    function buyFrom(address from) public payable whenNotPaused {
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
    
    function balanceOf(address _addr) public view returns (uint256) {
        return holds[_addr];
    }
    
    function transfer(address to, uint amount) public whenNotPaused returns(bool) {
        transferHolds(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= amount);
        
        allowance[from][msg.sender] -= amount;
        transferHolds(from, to, amount);
        
        return true;
    }
    
    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return total;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
}