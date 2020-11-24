 

pragma solidity ^0.5.1;

library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

     
   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

     
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

     
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract FLAME is ERC20Interface, Owned {
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    string public name = "FLAME";
    string public symbol = "FLM";
    uint256 public decimals = 8;
    uint256 public _totalSupply;
    uint256 public burnBaseRate = 20;
    address payable public keeper = 0x6c2219901B6b6D6d934C998C6043a48118e568b4;
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    constructor () public {
        _totalSupply = 5000e8;
        balances[keeper] = _totalSupply;
        emit Transfer(address(0), keeper, _totalSupply);
    }

    function () external payable {
        
    } 
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function calcBurnAmount(uint256 value) public view returns (uint256)  {
        uint256 percent = value.div(burnBaseRate);
        return percent;
    }
    
     
    function doTransfer(address _from, address _to, uint _amount) internal {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        
        uint256 tokensToBurn = calcBurnAmount(_amount);
        uint256 actualAmount = _amount.sub(tokensToBurn);
        
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(actualAmount);
        _totalSupply = _totalSupply.sub(tokensToBurn);
        
        emit Transfer(_from, _to, actualAmount);
        emit Transfer(msg.sender, address(0), tokensToBurn);
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

     
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_amount == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        doTransfer(_from, _to, _amount);
        return true;
    }
    
    function getForeignTokenBalance(address tokenAddress, address who) view public returns (uint){
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint bal = token.balanceOf(who);
        return bal;
    }
    
    function withdrawForeignTokens(address tokenAddress) onlyOwner public returns (bool) {
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function withdrawFund() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
    
    function burn(uint256 amount) public {
        require(amount != 0);
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        _totalSupply = _totalSupply.sub(amount);
    }
      
}