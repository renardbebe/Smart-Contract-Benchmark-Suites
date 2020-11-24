 

pragma solidity ^0.4.18;


 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

 


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract StandardToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public constant symbol = "ast";
    string public constant name = "AllStocks Token";
    uint256 public constant decimals = 18;
    uint256 public _totalSupply;

    bool public isFinalized;               
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => uint256) refunds;


     
     
     
    function StandardToken() public {

         
         
         
    }


     
     
     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint256 tokens) public returns (bool success) {
        
         
        require(to != 0x0);
        
         
        if (msg.sender != owner)
            require(isFinalized);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint256 tokens) public returns (bool success) {
         
        require(isFinalized);

        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
         
        require(isFinalized);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
         
        require(isFinalized);
        
        return allowed[tokenOwner][spender];
    }

}

 

contract AllstocksToken is StandardToken {
    string public version = "1.0";

     
    address public ethFundDeposit;         

     
    bool public isActive;                  
    uint256 public fundingStartTime = 0;
    uint256 public fundingEndTime = 0;
    uint256 public allstocksFund = 25 * (10**6) * 10**decimals;      
    uint256 public tokenExchangeRate = 625;                          
    uint256 public tokenCreationCap =  50 * (10**6) * 10**decimals;  
    
     
    uint256 public tokenCreationMin =  25 * (10**5) * 10**decimals;  


     
    event LogRefund(address indexed _to, uint256 _value);
    event CreateAllstocksToken(address indexed _to, uint256 _value);

     
    function AllstocksToken() public {
      isFinalized = false;                          
      owner = msg.sender;
      _totalSupply = allstocksFund;
      balances[owner] = allstocksFund;              
      CreateAllstocksToken(owner, allstocksFund);   
    }

    function setup (
        uint256 _fundingStartTime,
        uint256 _fundingEndTime) onlyOwner external
    {
      require (isActive == false); 
      require (isFinalized == false); 			        	   
      require (msg.sender == owner);                  
      require (fundingStartTime == 0);               
      require (fundingEndTime == 0);                 
      require(_fundingStartTime > 0);
      require(_fundingEndTime > 0 && _fundingEndTime > _fundingStartTime);

      isFinalized = false;                           
      isActive = true;
      ethFundDeposit = owner;                        
      fundingStartTime = _fundingStartTime;
      fundingEndTime = _fundingEndTime;
    }

    function () public payable {       
      createTokens(msg.value);
    }

     
    function createTokens(uint256 _value)  internal {
      require(isFinalized == false);    
      require(now >= fundingStartTime);
      require(now < fundingEndTime); 
      require(msg.value > 0);         

      uint256 tokens = _value.mul(tokenExchangeRate);  
      uint256 checkedSupply = _totalSupply.add(tokens);

      require(checkedSupply <= tokenCreationCap);

      _totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   

       
      refunds[msg.sender] = _value.add(refunds[msg.sender]);   

      CreateAllstocksToken(msg.sender, tokens);   
      Transfer(address(0), owner, _totalSupply);
    }
	
	 
	function setRate(uint256 _value) external onlyOwner {
      require (isFinalized == false);
      require (isActive == true);
      require (_value > 0);
      require(msg.sender == owner);  
      tokenExchangeRate = _value;

    }

     
    function finalize() external onlyOwner {
      require (isFinalized == false);
      require(msg.sender == owner);  
      require(_totalSupply >= tokenCreationMin + allstocksFund);   
      require(_totalSupply > 0);

      if (now < fundingEndTime) {     
        require(_totalSupply >= tokenCreationCap);
      }
      else 
        require(now >= fundingEndTime);
      
	     
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);   
    }

     
    function vaultFunds() external onlyOwner {
      require(msg.sender == owner);             
      require(_totalSupply >= tokenCreationMin + allstocksFund);  
      ethFundDeposit.transfer(this.balance);   
    }

     
    function refund() external {
      require (isFinalized == false);   
      require (isActive == true);
      require (now > fundingEndTime);  
     
      require(_totalSupply < tokenCreationMin + allstocksFund);   
      require(msg.sender != owner);  
      
      uint256 allstocksVal = balances[msg.sender];
      uint256 ethValRefund = refunds[msg.sender];
     
      require(allstocksVal > 0);   
      require(ethValRefund > 0);  
     
      balances[msg.sender] = 0;
      refunds[msg.sender] = 0;
      
      _totalSupply = _totalSupply.sub(allstocksVal);  
      
      uint256 ethValToken = allstocksVal / tokenExchangeRate;      

      require(ethValRefund <= ethValToken);
      msg.sender.transfer(ethValRefund);                  
      LogRefund(msg.sender, ethValRefund);                
    }
}