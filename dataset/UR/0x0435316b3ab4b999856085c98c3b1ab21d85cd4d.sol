 

pragma solidity 0.4.24;

  
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
  
  function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
    uint _numerator  = numerator * 10 ** (precision+1);
    uint _quotient =  ((_numerator / denominator) + 5) / 10;
    return (value*_quotient/1000000000000000000);
  }
}

contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract DeltaExCoin is ERC20 { 
    
    using SafeMath for uint256;
    string public constant name     		= "DeltaExCoin";                     
    string public constant symbol   		= "DLTX";                        
    uint8 public constant decimals  		= 18;                            
    uint public _totalsupply        		= 500000000 * 10 ** 18;          
    uint public crowdSale           		= 60000000 * 10 ** 18;           
    uint public posMining           		= 100000000 * 10 ** 18;          
    uint public corporateReserve    		= 140000000 * 10 ** 18;          
    uint public marketinganddevelopment     = 200000000 * 10 ** 18;          
    uint public remainingToken      		= 400000000 * 10 ** 18;          
    address public owner;                                            
    mapping(address => uint256) internal mintingDate;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function DeltaExCoin() public {
        balances[msg.sender] = remainingToken;
        Transfer(0, msg.sender, remainingToken);
    }
    
     
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function mint() public {
        address _customerAddress = msg.sender;
        uint256 userBalance = balances[_customerAddress];
        uint256 currentTs = now;
        uint256 userMintingDate = mintingDate[_customerAddress] + 7 days;
        require (userBalance > 0);
        require (currentTs > userMintingDate);
        mintingDate[_customerAddress] = currentTs;
        uint256 _bonusAmount = SafeMath.percent(userBalance,2,100,18);
        balances[_customerAddress] = (uint256)(balances[_customerAddress]).add(_bonusAmount);
    }
    
     
     
     
     
     
     
    function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
        require( _to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        
        address _customerAddress = msg.sender;
        uint256 currentTs = now;
        uint256 userMintingDate = mintingDate[_customerAddress] + 7 days;
        require (currentTs > userMintingDate);
        
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
     
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
    }
 
    function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
}