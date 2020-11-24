 

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
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _amount)public returns (bool ok);
  function approve(address _spender, uint _amount)public returns (bool ok);
  function transfer(address _to, uint _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
}


contract AdBank is ERC20
{ using SafeMath for uint256;

   string public constant symbol = "ADB";
   string public constant name = "AdBank";
   uint8 public constant decimals = 18;
   uint256 _totalSupply = (1000000000) * (10 **18);  
      
      
    address public owner;
    bool stopped = true;
     
    uint256 public eth_received;
     
    uint256 startdate;
     
    uint256 enddate;
  
      
     mapping(address => uint256) balances;
  
      
     mapping(address => mapping (address => uint256)) allowed;
 
      enum Stages {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }
    
    Stages public stage;
    uint256 received;
    uint256 refund;
    bool ico_ended = false;

 
     modifier onlyOwner() {
         require (msg.sender == owner);
          _;
     }
     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }
  
      
     function AdBank() public {
         owner = msg.sender;
         balances[owner] = _totalSupply;
         stage = Stages.NOTSTARTED;
         Transfer(0, owner, balances[owner]);
     }
     
     
     function () public payable atStage(Stages.ICO)
    {
       
        require(received < 44000 ether);
        require(!ico_ended && !stopped && now <= enddate);
        received = (eth_received).add(msg.value);
        if (received > 44000 ether){
        refund = received.sub(44000 ether);
        msg.sender.transfer(refund);
        eth_received = 44000 ether;
        }
        else {
            eth_received = (eth_received).add(msg.value);
        }
        
    }
   
    function StartICO() external onlyOwner atStage(Stages.NOTSTARTED) 
    {
        stage = Stages.ICO;
        stopped = false;
        startdate = now;
        enddate = now.add(39 days);
    }
    
    function EmergencyStop() external onlyOwner atStage(Stages.ICO)
    {
        stopped = true;
        stage = Stages.PAUSED;
    }
    
    function ResumeEmergencyStop() external onlyOwner atStage(Stages.PAUSED)
    {
        stopped = false;
        stage = Stages.ICO;
    }
    
     function end_ICO() external onlyOwner atStage(Stages.ICO)
     {
         require(now > enddate);
         ico_ended = true;
         stage = Stages.ENDED;
     }
  
   function drain() external onlyOwner {
        owner.transfer(this.balance);
    }

     
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalSupply;
     }
  
      
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
  
      
     function transfer(address _to, uint256 _amount)public returns (bool ok) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
             return true;
         }
  
      
      
      
      
      
      
     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool ok) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
     Transfer(_from, _to, _amount);
     return true;
         }
 
      
      
     function approve(address _spender, uint256 _amount)public returns (bool ok) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
   }
   
    
	function transferOwnership(address newOwner)public onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	}

}