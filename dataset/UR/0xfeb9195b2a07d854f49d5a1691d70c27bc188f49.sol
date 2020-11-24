 

pragma solidity 0.4.23;

 
contract ERC20Standard 
{
     
    
     
    uint256 internal totalSupply_;
    
     
    mapping (address => uint256) internal balances;
    
     
    mapping (address => mapping (address => uint256)) internal allowed;
    
     
    
     
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    
     
    
     
    function totalSupply() public view returns (uint256) 
    {
        return totalSupply_;
    }
    
     
     
     
    function balanceOf(address _owner) public view returns (uint256) 
    {
        return balances[_owner];
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) 
    {
        require(msg.data.length >= 68);                    
        require(_to != 0x0);                               
        require(balances[msg.sender] >= _value);           
        require(balances[_to] + _value >= balances[_to]);  
        
         
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
         
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
    {
        require(msg.data.length >= 68);                    
        require(_to != 0x0);                               
        require(balances[_from] >= _value);                
        require(balances[_to] + _value >= balances[_to]);  
        require(allowed[_from][msg.sender] >= _value);     
        
         
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        
         
        emit Transfer(_from, _to, _value);
        
        return true;
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        
         
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
     
}

 
contract BinvToken is ERC20Standard 
{
     
    
    string public constant name = "BINV";              
    string public constant symbol = "BINV";            
    uint256 public constant initialSupply = 100000000;
    uint8 public constant decimals = 18;               
    
     
    
     
    
    address public owner;                     
    address public contractAddress;            
    bool public payableEnabled = false;        
    uint256 public payableWeiReceived = 0;    
    uint256 public payableFinneyReceived = 0;  
    uint256 public payableEtherReceived = 0;       
    uint256 public milliTokensPaid = 0;        
    uint256 public milliTokensSent = 0;        
    
    uint256 public tokensPerEther = 10000;     
    uint256 public hardCapInEther = 7000;      
    uint256 public maxPaymentInEther = 50; 
    
     
    
     
    
     
    constructor() public
    {
        totalSupply_ = initialSupply * (10 ** uint256(decimals));  
        balances[msg.sender] = totalSupply_;                      
        
        owner = msg.sender;              
        contractAddress = address(this); 
    }
    
     
    
     
    
     
    function() payable public
    {
        require(payableEnabled);
        require(msg.sender != 0x0);
     
        require(maxPaymentInEther > uint256(msg.value / (10 ** 18)));
        require(hardCapInEther > payableEtherReceived);
        
        uint256 actualTokensPerEther = getActualTokensPerEther();
        uint256 tokensAmount = msg.value * actualTokensPerEther;
        
        require(balances[owner] >= tokensAmount);
        
        balances[owner] -= tokensAmount;
        balances[msg.sender] += tokensAmount;

        payableWeiReceived += msg.value;  
        payableFinneyReceived = uint256(payableWeiReceived / (10 ** 15));
        payableEtherReceived = uint256(payableWeiReceived / (10 ** 18));
        milliTokensPaid += uint256(tokensAmount / (10 ** uint256(decimals - 3)));

        emit Transfer(owner, msg.sender, tokensAmount); 
               
        owner.transfer(msg.value); 
    }
    
     
    function getOwnerBalance() public view returns (uint256)
    {
        return balances[owner];
    }
    
     
    function getOwnerBalanceInMilliTokens() public view returns (uint256)
    {
        return uint256(balances[owner] / (10 ** uint256(decimals - 3)));
    }
        
     
    function getActualTokensPerEther() public view returns (uint256)
    {
       uint256 etherReceived = payableEtherReceived;
       
       uint256 bonusPercent = 0;
       if(etherReceived < 1000)
           bonusPercent = 16;
       else if(etherReceived < 2200)
           bonusPercent = 12; 
       else if(etherReceived < 3600)
           bonusPercent = 8; 
       else if(etherReceived < 5200)
           bonusPercent = 4; 
       
       uint256 actualTokensPerEther = tokensPerEther * (100 + bonusPercent) / 100;
       return actualTokensPerEther;
    }
    
     
    function setTokensPerEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       tokensPerEther = amount;
       
       return true;
    }
    
     
    function setHardCapInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       hardCapInEther = amount;
       
       return true;
    }
    
     
    function setMaxPaymentInEther(uint256 amount) public returns (bool)
    {
       require(msg.sender == owner); 
       require(amount > 0);
       maxPaymentInEther = amount;
       
       return true;
    }
    
     
    function enablePayable() public returns (bool)
    {
       require(msg.sender == owner); 
       payableEnabled = true;
       
       return true;
    }
    
     
    function disablePayable() public returns (bool)
    {
       require(msg.sender == owner); 
       payableEnabled = false;
       
       return true;
    }
    
     
    function sendTokens(uint256 milliTokensAmount, address destination) public returns (bool) 
    {
        require(msg.sender == owner); 
        
        uint256 tokensAmount = milliTokensAmount * (10 ** uint256(decimals - 3));
        
        require(balances[owner] >= tokensAmount);

        balances[owner] -= tokensAmount;
        balances[destination] += tokensAmount;
        
        milliTokensSent += milliTokensAmount;

        emit Transfer(owner, destination, tokensAmount);
        
        return true;
    }
    
     
}