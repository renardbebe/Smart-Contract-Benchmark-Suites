 

pragma solidity 0.4.23;

 
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


contract Bitron is ERC20
{ using SafeMath for uint256;
     
    string public constant name = "Bitron coin";

     
    string public constant symbol = "BTO";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 50000000 * 10 ** 18;  
    address public owner;                     
    uint256 public _price_tokn; 
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    address ethFundMain = 0x1e6d1Fc2d934D2E4e2aE5e4882409C3fECD769dF; 
    uint256 public postico_startdate;
    uint256 postico_enddate;
    uint256 maxCap_POSTICO;
    
    uint public priceFactor;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint bon;
    uint public bonus;
    
     enum Stages {
        NOTSTARTED,
        POSTICO,
        PAUSED,
        ENDED
    }
    Stages public stage;
    
    modifier atStage(Stages _stage) {
        require (stage == _stage);
        _;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
     _;
    }
    
  constructor(uint256 EtherPriceFactor) public
    {
         require(EtherPriceFactor != 0);
        owner = msg.sender;
        balances[owner] = 30000000 * 10 **18;  
        stage = Stages.NOTSTARTED;
        priceFactor = EtherPriceFactor;
      emit  Transfer(0, owner, balances[owner]);
    }
  
   function setpricefactor(uint256 newPricefactor) external onlyOwner
    {
        priceFactor = newPricefactor;
    }
    function () public payable 
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
        no_of_tokens = ((msg.value).mul(priceFactor.mul(100))).div(_price_tokn);
        transferTokens(msg.sender,no_of_tokens);
       
    }
   
    
  
     function start_POSTICO() public onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.POSTICO;
          stopped = false;
          maxCap_POSTICO = 20000000 * 10 **18;   
           balances[address(this)] = maxCap_POSTICO;
          postico_startdate = now;
          postico_enddate = now + 90 days;  
          _price_tokn = 5;  
          emit Transfer(0, address(this), maxCap_POSTICO);
      }
      
     
     
     
    function PauseICO() external onlyOwner
    {
        stopped = true;
       }

     
    function ResumeICO() external onlyOwner
    {
        stopped = false;
      }
   
     
      function end_ICO() external onlyOwner
     {
        stage = Stages.ENDED;
        uint256 x = balances[address(this)];
        balances[owner] = (balances[owner]).add(balances[address(this)]);
        balances[address(this)] = 0;
        emit  Transfer(address(this), owner , x);
         
         
     }
  
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalsupply;
     }
    
     
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
    
     
      
      
      
      
      
     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
    emit Transfer(_from, _to, _amount);
     return true;
         }
    
    
      
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
   }

      
     function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
       emit Transfer(msg.sender, _to, _amount);
             return true;
         }
    
           
    function transferTokens(address _to, uint256 _amount) private returns(bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
       emit Transfer(address(this), _to, _amount);
        return true;
        }
        
          
	function transferOwnership(address newOwner) external onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	   emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}

    
    function drain() external onlyOwner {
        address myAddress = this;
        ethFundMain.transfer(myAddress.balance);
       
    }
    
}