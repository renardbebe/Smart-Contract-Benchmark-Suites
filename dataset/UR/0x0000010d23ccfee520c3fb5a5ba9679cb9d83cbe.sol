 

pragma solidity ^0.4.24;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

contract ZFX {
    string public name = 'ZFX';
    string public symbol = 'ZFX';
    uint8 public decimals = 18;
    uint public totalSupply = 1000000 * 10 ** uint(decimals);
    address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

     
    constructor(address creator) public {
        balanceOf[creator] = totalSupply;
        owner = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
    function mint(address _to, uint _amount) external onlyOwner {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        require(totalSupply >= _amount);
        emit Transfer(address(0), address(this), _amount);
        emit Transfer(address(this), _to, _amount);
    }
}

contract Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    uint8 public decimals;
}

contract Exchange {
    struct Order {
        address creator;
        address token;
        bool buy;
        uint price;
        uint amount;
    }
    
    address public owner;
    uint public feeDeposit = 500;
    
    mapping (uint => Order) orders;
    uint currentOrderId = 0;
    
    ZFX public ZFXToken;
    
     
    mapping (address => mapping (address => uint)) public balanceOf;
    
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    event PlaceSell(address indexed token, address indexed user, uint price, uint amount, uint id);
    event PlaceBuy(address indexed token, address indexed user, uint price, uint amount, uint id);
    event FillOrder(uint indexed id, address indexed user, uint amount);
    event CancelOrder(uint indexed id);
    event Deposit(address indexed token, address indexed user, uint amount);
    event Withdraw(address indexed token, address indexed user, uint amount);
    event BalanceChanged(address indexed token, address indexed user, uint value);

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    constructor() public {
        owner = msg.sender;
        ZFXToken = new ZFX(msg.sender);
    }
    
    function safeAdd(uint a, uint b) private pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function safeSub(uint a, uint b) private pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function safeMul(uint a, uint b) private pure returns (uint) {
        if (a == 0) {
          return 0;
        }
        
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function decFeeDeposit(uint delta) external onlyOwner {
        feeDeposit = safeSub(feeDeposit, delta);
    }
    
    function calcAmountEther(address tokenAddr, uint price, uint amount) private view returns (uint) {
        uint k = 10;
        k = k ** Token(tokenAddr).decimals();
        return safeMul(amount, price) / k;
    }
    
    function balanceAdd(address tokenAddr, address user, uint amount) private {
        balanceOf[tokenAddr][user] =
            safeAdd(balanceOf[tokenAddr][user], amount);
    }
    
    function balanceSub(address tokenAddr, address user, uint amount) private {
        require(balanceOf[tokenAddr][user] >= amount);
        balanceOf[tokenAddr][user] =
            safeSub(balanceOf[tokenAddr][user], amount);
    }
    
    function placeBuy(address tokenAddr, uint price, uint amount) external {
        require(price > 0 && amount > 0);
        uint amountEther = calcAmountEther(tokenAddr, price, amount);
        require(amountEther > 0);
        balanceSub(0x0, msg.sender, amountEther);
        emit BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        orders[currentOrderId] = Order({
            creator: msg.sender,
            token: tokenAddr,
            buy: true,
            price: price,
            amount: amount
        });
        emit PlaceBuy(tokenAddr, msg.sender, price, amount, currentOrderId);
        currentOrderId++;
        
        ZFXToken.mint(msg.sender, 1000000000000000000);
    }
    
    function placeSell(address tokenAddr, uint price, uint amount) external {
        require(price > 0 && amount > 0);
        uint amountEther = calcAmountEther(tokenAddr, price, amount);
        require(amountEther > 0);
        balanceSub(tokenAddr, msg.sender, amount);
        emit BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
        orders[currentOrderId] = Order({
            creator: msg.sender,
            token: tokenAddr,
            buy: false,
            price: price,
            amount: amount
        });
        emit PlaceSell(tokenAddr, msg.sender, price, amount, currentOrderId);
        currentOrderId++;
        
        ZFXToken.mint(msg.sender, 1000000000000000000);
    }
    
    function fillOrder(uint id, uint amount) external {
        require(id < currentOrderId);
        require(amount > 0);
        require(orders[id].creator != msg.sender);
        require(orders[id].amount >= amount);
        uint amountEther = calcAmountEther(orders[id].token, orders[id].price, amount);
        if (orders[id].buy) {
             
             
            balanceSub(orders[id].token, msg.sender, amount);
            emit BalanceChanged(
                orders[id].token,
                msg.sender,
                balanceOf[orders[id].token][msg.sender]
            );
            
             
            balanceAdd(orders[id].token, orders[id].creator, amount);
            emit BalanceChanged(
                orders[id].token,
                orders[id].creator,
                balanceOf[orders[id].token][orders[id].creator]
            );
            
             
            balanceAdd(0x0, msg.sender, amountEther);
            emit BalanceChanged(
                0x0,
                msg.sender,
                balanceOf[0x0][msg.sender]
            );
        } else {
             
             
            balanceSub(0x0, msg.sender, amountEther);
            emit BalanceChanged(
                0x0,
                msg.sender,
                balanceOf[0x0][msg.sender]
            );
            
             
            balanceAdd(0x0, orders[id].creator, amountEther);
            emit BalanceChanged(
                0x0,
                orders[id].creator,
                balanceOf[0x0][orders[id].creator]
            );
            
             
            balanceAdd(orders[id].token, msg.sender, amount);
            emit BalanceChanged(
                orders[id].token,
                msg.sender,
                balanceOf[orders[id].token][msg.sender]
            );
        }
        orders[id].amount -= amount;
        emit FillOrder(id, msg.sender, orders[id].amount);
        
        ZFXToken.mint(msg.sender, 1000000000000000000);
    }
    
    function cancelOrder(uint id) external {
        require(id < currentOrderId);
        require(orders[id].creator == msg.sender);
        require(orders[id].amount > 0);
        if (orders[id].buy) {
            uint amountEther = calcAmountEther(orders[id].token, orders[id].price, orders[id].amount);
            balanceAdd(0x0, msg.sender, amountEther);
            emit BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        } else {
            balanceAdd(orders[id].token, msg.sender, orders[id].amount);
            emit BalanceChanged(orders[id].token, msg.sender, balanceOf[orders[id].token][msg.sender]);
        }
        orders[id].amount = 0;
        emit CancelOrder(id);
    }
    
    function getFee(address user) public view returns (uint) {
        uint fee = feeDeposit * ZFXToken.balanceOf(user) * 10 / ZFXToken.totalSupply();
        return fee < feeDeposit ? feeDeposit - fee : 0;
    }
    
    function () external payable {
        require(msg.value > 0);
        uint fee = msg.value * getFee(msg.sender) / 10000;
        require(msg.value > fee);
        balanceAdd(0x0, owner, fee);
        
        uint toAdd = msg.value - fee;
        balanceAdd(0x0, msg.sender, toAdd);
        
        emit Deposit(0x0, msg.sender, toAdd);
        emit BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        
        emit FundTransfer(msg.sender, toAdd, true);
    }
    
    function depositToken(address tokenAddr, uint amount) external {
        require(tokenAddr != 0x0);
        require(amount > 0);
        Token(tokenAddr).transferFrom(msg.sender, this, amount);
        balanceAdd(tokenAddr, msg.sender, amount);
        
        emit Deposit(tokenAddr, msg.sender, amount);
        emit BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
    }
    
    function withdrawEther(uint amount) external {
        require(amount > 0);
        balanceSub(0x0, msg.sender, amount);
        msg.sender.transfer(amount);
        
        emit Withdraw(0x0, msg.sender, amount);
        emit BalanceChanged(0x0, msg.sender, balanceOf[0x0][msg.sender]);
        
        emit FundTransfer(msg.sender, amount, false);
    }
    
    function withdrawToken(address tokenAddr, uint amount) external {
        require(tokenAddr != 0x0);
        require(amount > 0);
        balanceSub(tokenAddr, msg.sender, amount);
        Token(tokenAddr).transfer(msg.sender, amount);
        
        emit Withdraw(tokenAddr, msg.sender, amount);
        emit BalanceChanged(tokenAddr, msg.sender, balanceOf[tokenAddr][msg.sender]);
    }
}