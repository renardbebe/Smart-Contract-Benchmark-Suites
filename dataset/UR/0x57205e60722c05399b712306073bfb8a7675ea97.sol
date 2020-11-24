 

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

 
 
 

contract TVBToken is owned, ERC20Interface {
    
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint256 public decimals;
     
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

     
    constructor (
        address payable owner)
        public
    {
        name = "Transparent Value Broadcasting Network";
        symbol = "TVB";
        decimals = 8;
        _initSupply = uint256(1000000000).mul(uint(10) ** decimals);
        _owner = owner;
        _ethRate = uint(18).sub(decimals);
        balances[_owner] = _initSupply;
        emit Transfer(address(0), _owner, _initSupply);
    }
    
     
     
     
     
    function totalSupply() public view returns (uint) {
        return _initSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }
    
    function multiTransfer(address[] memory tos, uint[] memory tokens) public returns(bool) {
        require(tos.length == tokens.length, "Number of address doesn't match the tokens!");
        for (uint i = 0; i < tos.length; i++) {
            bool flag = transfer(tos[i], tokens[i]);
            if (!flag) {
                continue;
            }
        }
        
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
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
        emit Transfer(address(0), target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        require(target != _owner, "Cannot freeze owner account!");
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    
    function burn(address account, uint256 tokens) onlyOwner public {
        uint256 bal = balances[account];
        require(bal > 0 && tokens <= bal, "No enough balance to burn!");
        require(!frozenAccount[account], "Account is frozen!");
        balances[account] = bal.sub(tokens);
        emit BurnTokens(account, tokens);
    }
    
     
    function destroy() onlyOwner public {
        selfdestruct(_owner);
    }
    
     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(_owner, tokens);
    }

     
	function () external {
		revert();
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