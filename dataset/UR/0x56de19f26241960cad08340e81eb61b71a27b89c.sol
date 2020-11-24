 

pragma solidity 0.4.20;

 
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
  function transferToAdvisors(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract FricaCoin is ERC20
{ using SafeMath for uint256;
     
    string public constant name = "FricaCoin";

     
    string public constant symbol = "FRI";
    uint8 public constant decimals = 8;
    uint public _totalsupply = 1000000000000 * 10 ** 8;  
    address public owner;                     

    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    bool stopped = false;
    uint256 public pre_startdate;
    uint256 public ico1_startdate;
    uint256 ico_first;
    uint256 ico_second;
    uint256 ico_third;
    uint256 ico_fourth;
    uint256 pre_enddate;
  
    uint256 public eth_received;  
    uint256 maxCap_public = 250000000000 * 10 **8;   
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
     
    mapping (address => bool) private Advisors;
    
      
    uint256 public advisorCount;

    enum Stages {
        NOTSTARTED,
        PREICO,
        ICO,
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

    function FricaCoin() public
    {
        owner = msg.sender;
        balances[owner] = 50000000000 * 10 **8;  
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
        
        uint256 _transfertoemployees = 140000000000 * 10 **8;  
        balances[0xa36eEa22131881BB0a8902A6b8bF4a2cbb9782BC] = _transfertoemployees;
        Transfer(address(0), 0xa36eEa22131881BB0a8902A6b8bF4a2cbb9782BC, _transfertoemployees);
        
        uint256 _transfertofirstround = 260000000000 * 10 **8;  
        balances[0x553015bc932FaCc0C60159b7503a58ef5806CA48] = _transfertofirstround;
        Transfer(address(0), 0x553015bc932FaCc0C60159b7503a58ef5806CA48, _transfertofirstround);
        
        uint256 _transfertocharity = 50000000000 * 10 **8;  
        balances[0x11Bfb0B5a901cbc5015EF924c39ac33e91Eb015a] = _transfertocharity;
        Transfer(address(0), 0x11Bfb0B5a901cbc5015EF924c39ac33e91Eb015a, _transfertocharity);

        uint256 _transfertosecondround = 250000000000 * 10 **8;  
        balances[0xaAA258C8dbf31De53Aa679F6b492569556e1c306] = _transfertosecondround;
        Transfer(address(0), 0xaAA258C8dbf31De53Aa679F6b492569556e1c306, _transfertosecondround);
        
    }
  

     function start_PREICO() public onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
           balances[address(this)] =  maxCap_public;
          pre_startdate = now;
          pre_enddate = now + 16 days;
          Transfer(0, address(this), balances[address(this)]);
          }
      
      function start_ICO() public onlyOwner atStage(Stages.PREICO)
      {
          require(now > pre_enddate || eth_received >= 1500 ether);
          stage = Stages.ICO;
          stopped = false;
          ico1_startdate = now;
           ico_first = now + 15 days;
          ico_second = ico_first + 15 days;
          ico_third = ico_second + 15 days;
          ico_fourth = ico_third + 15 days;
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
   
     
     
     function end_ICO() external onlyOwner atStage(Stages.ICO)
     {
         require(now > ico_fourth);
         stage = Stages.ENDED;
         _totalsupply = (_totalsupply).sub(balances[address(this)]);
         balances[address(this)] = 0;
         Transfer(address(this), 0 , balances[address(this)]);
         
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
 
     
    function transferToAdvisors(address _to, uint256 _amount) public returns(bool success) {
         require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
         
        if(!isAdvisor(_to)) {
          addAdvisor(_to);
          advisorCount++ ;
        }
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
             return true;
    }
 
    function addAdvisor(address _advisor) public {
        Advisors[_advisor]=true;
    }

    function isAdvisor(address _advisor) public returns(bool success){
        return Advisors[_advisor];
             return true;
    }
    
    function drain() external onlyOwner {
        owner.transfer(this.balance);
    }
    
}