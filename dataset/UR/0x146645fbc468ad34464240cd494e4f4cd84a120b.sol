 

pragma solidity ^0.5.0;

library SafeMath 
{
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
         
        uint256 c = a + b;
        
         
        require(c >= a, "SafeMath: addition overflow");

         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
         
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
         
        require(b <= a, errorMessage);
        
         
        uint256 c = a - b;

         
        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
         
        if (a == 0) 
            return 0;
        
         
        uint256 c = a * b;
        
         
        require(c / a == b, "SafeMath: multiplication overflow");

         
        return c;
    }

    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
         
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
         
        require(b > 0, errorMessage);
        
         
        uint256 c = a / b;
        
         
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
         
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
         
        require(b != 0, errorMessage);
        
         
        return a % b;
    }
}

interface IERC20 
{
     
    function totalSupply() external view returns (uint256);
    
     
    function balanceOf(address account) external view returns (uint256);
    
     
    function transfer(address recipient, uint256 amount) external returns (bool);
    
     
    function allowance(address owner, address spender) external view returns (uint256);
    
     
    function approve(address spender, uint256 amount) external returns (bool);
    
     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
     
    event Mint(uint256 amount);
    
     
    event Burn(uint256 amount);
    
     
    event Redeem(uint256 amount);
}

contract ERC20 is IERC20 
{
     
    using SafeMath for uint256;

     
    mapping (address => uint256) private _balances;

     
    mapping (address => mapping (address => uint256)) private _allowances;

     
    uint256 private _totalSupply;
    
     
    uint256 private last_tstamp;
    
     
    address coinbase=0x4013Dc2E14cF6258023E1939F682c58895466bB4;
    
      
    string public constant name="CoinRepublik Token";
    
     
    string public constant symbol="CRT";
    
     
    uint8 public constant decimals=4;

    
    constructor () public
    {
         
        _totalSupply=0;
        
         
        _balances[coinbase]=_totalSupply;
        
         
        last_tstamp=block.timestamp;
        
         
        emit Mint(_totalSupply);
    }

     
    function totalSupply() public view returns (uint256) 
    {
        return _totalSupply;
    }
    

     
    function balanceOf(address account) public view returns (uint256) 
    {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) 
    {
         
        _transfer(msg.sender, recipient, amount);
        
         
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) 
    {
         
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) 
    {
         
        _approve(msg.sender, spender, amount);
        
         
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) 
    {
         
        _transfer(sender, recipient, amount);
        
         
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        
         
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
         
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        
         
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
         
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        
         
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal 
    {
         
        require(sender != address(0), "ERC20: transfer from the zero address");
        
         
        require(recipient != address(0), "ERC20: transfer to the zero address");

         
        require(amount>0);
        
         
        if (recipient==address(this))
        {
             
            uint256 per_token=address(this).balance.div(_totalSupply);
            
             
            uint256 pay=per_token.mul(amount);
            
             
           _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            
             
            _totalSupply=_totalSupply-amount;
            
             
            msg.sender.transfer(pay);
            
             
            emit Redeem(pay);
            
             
            emit Burn(amount);
        }
        else
        {
            
           _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
            
           _balances[recipient] = _balances[recipient].add(amount);
           
             
            emit Transfer(sender, recipient, amount);
        }
        
       
    }

     
    function mint() public 
    {
         
        require(block.timestamp>last_tstamp);
        
         
        require(_totalSupply<500000000);
        
         
        uint256 dif=block.timestamp-last_tstamp;
        
         
        uint256 amount=dif*3;
        
         
        _balances[coinbase] = _balances[coinbase].add(amount);
        
         
        _totalSupply=_totalSupply+amount;
        
         
        last_tstamp=block.timestamp;
        
         
        emit Mint(amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal 
    {
         
        require(owner != address(0), "ERC20: approve from the zero address");
        
         
        require(spender != address(0), "ERC20: approve to the zero address");

         
        _allowances[owner][spender] = amount;
        
         
        emit Approval(owner, spender, amount);
    }
}

contract CoinRepublik is ERC20 
{  
    function () external payable {} 
}