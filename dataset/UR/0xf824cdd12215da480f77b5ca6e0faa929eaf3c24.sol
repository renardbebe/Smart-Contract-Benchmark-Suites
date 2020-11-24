 

pragma solidity 0.5.11;

 
 
 
contract Owned {
    address payable private owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor(address payable _owner) public {
        owner = _owner;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function getOwner() internal view returns(address){
        return owner;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address payable from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Cache is Owned(msg.sender), ERC20Interface{
    using SafeMath for uint256;
    
     
    string public constant version = 'Cache 1.0';
    string public name = 'Cache';
    string public symbol = 'CACHE';
    uint256 public decimals = 18;
    uint256 internal _totalSupply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    

     
    mapping (address => Depositor) public depositor;
    
    struct Depositor{
        uint256 amount;
    }

     
    uint256 public reservedReward;
    uint256 public constant initialSupply = 4e6;                                                 
    
     
    event Withdraw(address indexed by, uint256 amount, uint256 fee);                             
    event Deposited(address indexed by, uint256 amount);                                         
    event PaidOwnerReward(uint256 amount);
     
    Owned private owned;
    address payable private owner;
     
    constructor () payable public {
        owner = address(uint160(getOwner()));
        _totalSupply = initialSupply * 10 ** uint(decimals);                             
        balances[owner] = _totalSupply;                                                  
        emit Transfer(address(0),address(owner), _totalSupply);
    }

     
    function() external payable {                                                   
        makeDeposit(msg.sender, msg.value);
    }
    
     
    function ownerReward() internal{
        require(owner.send(reservedReward));
        emit PaidOwnerReward(reservedReward);
        reservedReward = reservedReward.sub(reservedReward);
    }
    
     
    function makeDeposit(address sender, uint256 amount) internal {
        require(balances[sender] == 0);
        require(amount > 0);
        
         
        uint256 depositFee = (amount.div(1000)).mul(3);
        uint256 newAmount  = (amount.mul(1000)).sub(depositFee.mul(1000));
        
         
        balances[sender] = balances[sender] + newAmount;                                 
        _totalSupply = _totalSupply + newAmount;                                  
        emit Transfer(address(0), sender, newAmount);                                    
        
         
        reservedReward = reservedReward.add(depositFee);
        
         
        depositor[sender].amount = newAmount;
        emit Deposited(sender, newAmount);
    }
    
    
     
    function withdraw(address payable _sender, uint256 amount) internal {
        
        uint256 withdrawFee = (amount.div(1000)).mul(3);
        uint256 newAmount   = (amount.mul(1000)).sub(withdrawFee.mul(1000));
        
         
        depositor[_sender].amount = depositor[_sender].amount.sub(amount);                                

         
        require(_sender.send(newAmount.div(1000000)));                                                        
        emit Withdraw(_sender, newAmount.div(1000000), withdrawFee.div(1000));
        
         
        reservedReward = reservedReward.add(withdrawFee.div(1000));
    }
    
    
     
    function totalSupply() public view returns (uint){
       return _totalSupply;
    }
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    
    function transfer(address to, uint tokens) public returns (bool success) {
        if(msg.sender == owner) { require(tokens >= 1e18);}                          
        require(to != address(0));                                                   
        require(balances[msg.sender] >= tokens );                                    
        
        uint256 bal1 = balances[address(this)]; 
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);                     
            
        require(balances[to] + tokens >= balances[to]);                              
        
        balances[to] = balances[to].add(tokens);                                     
        
        emit Transfer(msg.sender,to,tokens);                                         

        if(to ==  address(this)){                                                    
            require(bal1 < balances[address(this)]);
                                                                                    
             
             
            if(msg.sender == owner){
                ownerReward();
            }
            
            if(depositor[msg.sender].amount > 0){                                      
                if(tokens > depositor[msg.sender].amount){
                    withdraw(msg.sender,  depositor[msg.sender].amount);  
                }else{
                    withdraw(msg.sender, tokens);                                        
                }
            }
            
            
            balances[to] = balances[to].sub(tokens);                                 
            _totalSupply = _totalSupply.sub(tokens);                                 
            emit Transfer(to, address(0), tokens);                                   
        }
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
    function transferFrom(address payable from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);  
        
        if(to == address(this)){
            if(from == owner)
                require(tokens == 1e18);
        }
        
        uint256 bal1 = balances[address(this)];
        balances[from] = balances[from].sub(tokens);
        
        require(balances[to] + tokens >= balances[to]);
        
        balances[to] = balances[to].add(tokens);                                             
        
        emit Transfer(from,to,tokens);                                                 

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        if(to ==  address(this)){                                                    
            require(bal1 < balances[address(this)]);
            
            if(msg.sender == owner){
                ownerReward();
            }
            
            if(depositor[msg.sender].amount > 0){                                      
                withdraw(from, tokens);                                        
            }
            
            
            balances[to] = balances[to].sub(tokens);                                 
            
            _totalSupply = _totalSupply.sub(tokens);                                 
            
            emit Transfer(to, address(0), tokens);                                   
        }
        return true;
    }
    
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success){
        require(spender != address(0));
        require(tokens <= balances[msg.sender]);
        require(tokens >= 0);
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}