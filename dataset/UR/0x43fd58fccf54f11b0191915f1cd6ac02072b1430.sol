 

pragma solidity ^0.5.0;



contract owned {
    address payable internal _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Limited authority!");
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        _owner = newOwner;
    }
}

 
 
 
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 

contract TokenFactory is owned, ERC20Interface {
    
    using SafeMath for uint256;
     
    string private _name;
    string private _symbol;
    uint8 private _decimals;
     
    uint256 private _initSupply;
    uint256 private _ethRate;   

    uint256 private sellPrice;
    uint256 private buyPrice;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => bool) private frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
    event BurnTokens(address target, uint256 tokens);
    event MultiTransferFail(address target, uint256 tokens);

     
    constructor (address payable owner)
        public
    {
        _name = "Transparent Value Broadcasting Token";
        _symbol = "TVBT";
        _decimals = 8;
        _initSupply = uint256(1000000000).mul(uint(10) ** _decimals);
        _owner = owner;
        _ethRate = uint(18).sub(_decimals);
        sellPrice = 500000;  
        buyPrice = 500000;  
        balances[_owner] = _initSupply;
        emit Transfer(address(0), _owner, _initSupply);
    }
    
     
     
     
     
    function totalSupply() public view returns (uint) {
        return _initSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function tokenInfo() public view returns (
        string memory name,
        string memory symbol,
        uint supply,
        uint8 decimals,
        address owner)
    {
        name = _name;
        symbol = _symbol;
        supply = _initSupply;
        decimals = _decimals;
        owner = _owner;
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function multiTransfer(address[] memory tos, uint[] memory tokens) public returns(bool) {
        require(tos.length == tokens.length, "Number of address doesn't match the tokens!");
        for (uint i = 0; i < tos.length; i++) {
            bool flag = transfer(tos[i], tokens[i]);
            if (!flag) {
                emit MultiTransferFail(tos[i], tokens[i]);
                continue;
            }
        }
        
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));   
        require(_from != _to, "The target account cannot be same with the source account!");
        require (balances[_from] >= _value, "No enough balance to transfer!");                
        require (balances[_to] + _value >= balances[_to], "Overflows!");  
        require(!frozenAccount[_from], "Account is frozen!");                      
        require(!frozenAccount[_to], "Account is frozen!");                        
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] = balances[target].add(mintedAmount);
        _initSupply = _initSupply.add(mintedAmount);
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        require(target != _owner, "Cannot freeze owner account!");
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        
        require(msg.value > 0 && buyPrice > 0, "Cannot buy with 0 ethers, or buyPrice hasn't been set!");
        uint amount = msg.value.div(buyPrice);                
        _transfer(_owner, msg.sender, amount);               
        _owner.transfer(msg.value);
        
    }

     
     
     
    function sell(uint256 amount) public {
        require(sellPrice > 0, "The sellPrice is not set yet!");
        require(amount > 0, "Amount cannot be 0!");
        require (_owner.balance >= amount * sellPrice, "No enough balance to sell!");       
        _transfer(msg.sender, _owner, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
    
    function burn(address account, uint256 tokens) onlyOwner public {
        uint256 bal = balances[account];
        require(bal > 0 && tokens <= bal, "No enough balance to burn!");
        require(!frozenAccount[account], "Account is frozen!");
        balances[account] = bal.sub(tokens);
        emit BurnTokens(account, tokens);
    }
    
     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(_owner, tokens);
    }
    
     
     
     
    function ICO() external payable {
         
        
         
        uint tokens = msg.value.div(10 ** _ethRate).mul(20000);  
        _transfer(_owner, msg.sender, tokens);
        emit Transfer(_owner, msg.sender, tokens);
        _owner.transfer(msg.value);
        
         
    }
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 sum) {
        sum = a + b;
        require(sum >= a, "SafeMath: addition overflow");
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256 division) {
         
        require(b > 0, "SafeMath: division by zero");
        division = a / b;
         
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256 modulo) {
        require(b != 0, "SafeMath: modulo by zero");
        modulo = a % b;
    }
}



 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}