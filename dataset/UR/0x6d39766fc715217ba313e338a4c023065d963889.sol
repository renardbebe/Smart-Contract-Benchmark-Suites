 

pragma solidity ^0.4.24;

contract Ownable {
    
    address public owner;

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}


contract Pausable is Ownable {
  
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 
 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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

 
contract TokenERC20 {
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    
    function transfer(address to, uint value) public  returns (bool ok);
    function transferFrom(address from, address to, uint value) public  returns (bool ok);
    
    function approve(address spender, uint value) public returns (bool ok);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
} 

contract TokenERC20Standart is TokenERC20, Pausable{
    
        using SafeMath for uint256;
            
            
         
        mapping(address => uint) public balances;
        mapping(address => mapping(address => uint)) public allowed;
        
         
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4) ;
            _;
        }
            
       
        function balanceOf(address tokenOwner) public constant whenNotPaused  returns (uint balance) {
             return balances[tokenOwner];
        }
 
        function transfer(address to, uint256 tokens) public  whenNotPaused onlyPayloadSize(2*32) returns (bool success) {
            _transfer(msg.sender, to, tokens);
            return true;
        }
 

        function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
 
        function transferFrom(address from, address to, uint tokens) public whenNotPaused onlyPayloadSize(3*32) returns (bool success) {
            assert(tokens > 0);
            require (to != 0x0);    
            require(balances[from] >= tokens);
            require(balances[to] + tokens >= balances[to]);  
            require(allowed[from][msg.sender] >= tokens);
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            emit Transfer(from, to, tokens);
            return true;
        }

        function allowance(address tokenOwner, address spender) public  whenNotPaused constant returns (uint remaining) {
            return allowed[tokenOwner][spender];
        }

        function _transfer(address _from, address _to, uint _value) internal {
            assert(_value > 0);
            require (_to != 0x0);                              
            require (balances[_from] >= _value);               
            require (balances[_to] + _value >= balances[_to]);
            balances[_from] = balances[_from].sub(_value);                        
            balances[_to] = balances[_to].add(_value);                           
            emit Transfer(_from, _to, _value);
        }

 

}


contract BeringiaContract is TokenERC20Standart{
    
    using SafeMath for uint256;
    
    string public name;                          
    uint256 public decimals;                     
    string public symbol;                        
    string public version;                       

    uint256 public _totalSupply = 0;                     
    uint256 public constant RATE = 2900;                 
    uint256 public fundingEndTime  = 1538179200000;      
    uint256 public minContribution = 350000000000000;    
    uint256 public oneTokenInWei = 1000000000000000000;
    uint256 public tokenCreationCap;                     

     
    uint256 private firstPeriodEND = 1532217600000;
    uint256 private secondPeriodEND = 1534896000000;
    uint256 private thirdPeriodEND = 1537574400000;
   
     
    uint256 private firstPeriodDis = 25;
    uint256 private secondPeriodDis = 20;
    uint256 private thirdPeriodDis = 15;  
    
    uint256 private foundersTokens;                      
    uint256 private depositorsTokens;                    
    
    constructor () public {
        name = "Beringia";                                           
        decimals = 0;                                                
        symbol = "BER";                                              
        owner = 0xdc889afED1ab326966c51E58abBEdC98b4d0DF64;          
        version = "1.0";                                             
        tokenCreationCap = 510000000 * 10 ** uint256(decimals);
        balances[owner] = tokenCreationCap;                          
        emit Transfer(address(0x0), owner, tokenCreationCap);
        foundersTokens = tokenCreationCap / 10;                      
        depositorsTokens = tokenCreationCap.sub(foundersTokens);     
    }
    
    function transfer(address _to, uint _value) public  returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFounderTokens(address _to, uint _value) public onlyOwner whenNotPaused returns (bool){
        require(foundersTokens > 0);
        require(foundersTokens.sub(_value) >= 0);
        foundersTokens = foundersTokens.sub(_value);
        _totalSupply = _totalSupply.add(_value);
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function () public payable {
        createTokens(msg.sender, msg.value);
    }
    
    function createTokens(address _sender, uint256 _value) public whenNotPaused { 
        require(_value > 0);
        require(depositorsTokens > 0);
        require(now <= fundingEndTime);
        require(_value >= minContribution);
        uint256 tokens = (_value * RATE) / oneTokenInWei;
        require(tokens > 0);
        if (now <= firstPeriodEND){
            tokens =  ((tokens * 100) * (firstPeriodDis + 100))/10000;
        }else if (now > firstPeriodEND && now <= secondPeriodEND){
            tokens =  ((tokens * 100) *(secondPeriodDis + 100))/10000;
        }else if (now > secondPeriodEND && now <= thirdPeriodEND){
            tokens = ((tokens * 100) * (thirdPeriodDis + 100))/10000;
        }
        require(depositorsTokens.sub(tokens) >= 0);
        depositorsTokens = depositorsTokens.sub(tokens);
        _totalSupply = _totalSupply.add(tokens);
        require(sell(_sender, tokens)); 
        owner.transfer(_value);
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    
    function getBalance(address _sender) public view returns (uint256) {
        return _sender.balance;
    }
    
     
    function isLeftTokens(uint256 _value) public view returns (bool) { 
        require(_value > 0);
        uint256 tokens = (_value * RATE) / oneTokenInWei;
        require(tokens > 0);
        if (now <= firstPeriodEND){
            tokens =  ((tokens * 100) * (firstPeriodDis + 100))/10000;
        }else if (now > firstPeriodEND && now <= secondPeriodEND){
            tokens =  ((tokens * 100) *(secondPeriodDis + 100))/10000;
        }else if (now > secondPeriodEND && now <= thirdPeriodEND){
            tokens = ((tokens * 100) * (thirdPeriodDis + 100))/10000;
        }
        return depositorsTokens.sub(tokens) >= 0;
    }

    function sell(address _recipient, uint256 _value) internal whenNotPaused returns (bool success) {
        _transfer (owner, _recipient, _value);
        return true;
    }
    
    function getFoundersTokens() public constant returns (uint256) {
        return foundersTokens;
    } 
    
    function getDepositorsTokens() public constant returns (uint256) {
        return depositorsTokens;
    }
    
    function increaseTotalSupply(uint256 _value) public whenNotPaused onlyOwner returns (bool success) {
        require(_value > 0);
        require(_totalSupply.add(_value) <= tokenCreationCap);
        _totalSupply = _totalSupply.add(_value);
        return true;
    }
}