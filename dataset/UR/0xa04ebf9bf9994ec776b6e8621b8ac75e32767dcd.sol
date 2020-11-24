 

pragma solidity 0.4.19;

 
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


contract OTPPAY is ERC20
{ using SafeMath for uint256;
     
    string public constant name = "OTPPAY";

     
    string public constant symbol = "OTP";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 1000000000 * 10 ** 18;  
    address public owner;                     
    uint256 public _price_tokn_PRE = 16000;   
    uint256 public _price_tokn_ICO1;
    uint256 public _price_tokn_ICO2;
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    uint256 refferaltoken;
    bool stopped = false;
    uint256 public pre_startdate;
    uint256 public ico1_startdate;
    uint256 public ico2_startdate;
    uint256 pre_enddate;
    uint256 ico1_enddate;
    uint256 ico2_enddate;
    uint256 maxCap_PRE;
    uint256 maxCap_ICO1;
    uint256 maxCap_ICO2;
    address central_account;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
     enum Stages {
        NOTSTARTED,
        PREICO,
        ICO1,
        ICO2,
        PAUSED,
        ENDED
    }
    Stages public stage;
    
    modifier atStage(Stages _stage) {
        if (stage != _stage)
             
            revert();
        _;
    }
    
     modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }

    function OTPPAY() public
    {
        owner = msg.sender;
        balances[owner] = 319000000 * 10 **18;  
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
    }
  
    function () public payable 
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
            if( stage == Stages.PREICO && now <= pre_enddate )
            { 
                no_of_tokens =((msg.value).mul(_price_tokn_PRE));
                bonus_token = ((no_of_tokens).mul(20)).div(100);  
                total_token = no_of_tokens + bonus_token;
                transferTokens(msg.sender,total_token);
               }
               
            
            else if(stage == Stages.ICO1 && now <= ico1_enddate )
            {
             
               no_of_tokens =((msg.value).mul(_price_tokn_ICO1));
                bonus_token = ((no_of_tokens).mul(15)).div(100);  
                total_token = no_of_tokens + bonus_token;
                transferTokens(msg.sender,total_token);
            }
            
            else if(stage == Stages.ICO2 && now <= ico2_enddate)
            {
               no_of_tokens =((msg.value).mul(_price_tokn_ICO2));
                bonus_token = ((no_of_tokens).mul(10)).div(100);  
                total_token = no_of_tokens + bonus_token;
                transferTokens(msg.sender,total_token);
            }
        else
        {
            revert();
        }
    }
     function start_PREICO() public onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
          maxCap_PRE = 72000000 * 10 **18;   
           balances[address(this)] = maxCap_PRE;
          pre_startdate = now;
          pre_enddate = now + 30 days;
          Transfer(0, address(this), balances[address(this)]);
          }
      
      function start_ICO1(uint256 price_tokn_ico1) public onlyOwner atStage(Stages.PREICO)
      {
          require(price_tokn_ico1 !=0);
          require(now > pre_enddate || balances[address(this)] == 0);
          stage = Stages.ICO1;
          stopped = false;
          _price_tokn_ICO1 = price_tokn_ico1;
          maxCap_ICO1 = 345000000 * 10 **18;  
          balances[address(this)] = (balances[address(this)]).add(maxCap_ICO1) ;
          ico1_startdate = now;
          ico1_enddate = now + 30 days;
          Transfer(0, address(this), balances[address(this)]);
      }
    
    function start_ICO2(uint256 price_tokn_ico2) public onlyOwner atStage(Stages.ICO1)
      {
          require(price_tokn_ico2 !=0);
          require(now > ico1_enddate || balances[address(this)] == 0);
          stage = Stages.ICO2;
          stopped = false;
          _price_tokn_ICO2 = price_tokn_ico2;
          maxCap_ICO2 = 264000000 * 10 **18;  
          balances[address(this)] = (balances[address(this)]).add(maxCap_ICO2) ;
          ico2_startdate = now;     
          ico2_enddate = now + 30 days;
          Transfer(0, address(this), balances[address(this)]);
          
      }
    
     
     
    function PauseICO() external onlyOwner
    {
        stopped = true;
       }

     
    function ResumeICO() external onlyOwner
    {
        stopped = false;
      }
   
     
     
      function end_ICO(uint256 _refferaltoken) external onlyOwner atStage(Stages.ICO2)
     {
         require(_refferaltoken !=0);
         require(now > ico2_enddate || balances[address(this)] == 0);
         stage = Stages.ENDED;
         refferaltoken = _refferaltoken;
         balances[address(this)] = (balances[address(this)]).sub(refferaltoken * 10 **18);
         balances[owner] = (balances[owner]).add(refferaltoken * 10 **18);
         _totalsupply = (_totalsupply).sub(balances[address(this)]);
         balances[address(this)] = 0;
         Transfer(address(this), 0 , balances[address(this)]);
         Transfer(address(this), owner, refferaltoken);
         
     }
     
     function set_centralAccount(address central_Acccount) external onlyOwner
    {
        central_account = central_Acccount;
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
     Transfer(_from, _to, _amount);
     return true;
         }
    
    
      
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
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
        Transfer(msg.sender, _to, _amount);
             return true;
         }
    
           
    function transferTokens(address _to, uint256 _amount) private returns(bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
        }
    
    function transferby(address _from,address _to,uint256 _amount) external onlycentralAccount returns(bool success) {
        require( _to != 0x0); 
        require (balances[_from] >= _amount && _amount > 0);
        balances[_from] = (balances[_from]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    
    function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
    
}