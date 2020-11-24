 

pragma solidity 0.4.25;

 

library SafeMath 
{

   

  function mul(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     if (a == 0) 
     {
     	return 0;
     }
     c = a * b;
     require(c / a == b);
     return c;
  }

   

  function div(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     return a / b;
  }

   

  function sub(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     require(b <= a);
     return a - b;
  }

   

  function add(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     c = a + b;
     require(c >= a);
     return c;
  }
}

contract ERC20
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

 

contract GSCP is ERC20
{
    using SafeMath for uint256;
   
    uint256 constant public TOKEN_DECIMALS = 10 ** 18;
    string public constant name            = "Genesis Supply Chain Platform";
    string public constant symbol          = "GSCP";
    uint256 public constant totalTokens    = 999999999;
    uint256 public totalTokenSupply        = totalTokens.mul(TOKEN_DECIMALS);
    uint8 public constant decimals         = 18;
    address public owner;

    struct AdvClaimLimit 
    {
        uint256     time_limit_epoch;
        uint256     last_claim_time;
        uint256[3]  tokens;
        uint8       round;
        bool        limitSet;
    }

    struct TeamClaimLimit 
    {
        uint256     time_limit_epoch;
        uint256     last_claim_time;
        uint256[4]  tokens;
        uint8       round;
        bool        limitSet;
    }

    struct ClaimLimit 
    {
       uint256 time_limit_epoch;
       uint256 last_claim_time;
       uint256 tokens;
       bool    limitSet;
    }

    event Burn(address indexed _burner, uint256 _value);

      
    mapping(address => uint256) public  balances;
    mapping(address => mapping(address => uint256)) internal  allowed;
    mapping(address => AdvClaimLimit)  advClaimLimits;
    mapping(address => TeamClaimLimit) teamClaimLimits;
    mapping(address => ClaimLimit) claimLimits;

     

    modifier onlyOwner() 
    {
       require(msg.sender == owner);
       _;
    }
    
     

    constructor() public
    {
       owner = msg.sender;
       balances[address(this)] = totalTokenSupply;
       emit Transfer(address(0x0), address(this), balances[address(this)]);
    }

     

     function burn(uint256 _value) onlyOwner public returns (bool) 
     {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalTokenSupply = totalTokenSupply.sub(_value);

        emit Burn(burner, _value);
        return true;
     }     

      

     function totalSupply() public view returns(uint256 _totalSupply) 
     {
        _totalSupply = totalTokenSupply;
        return _totalSupply;
     }

     

    function balanceOf(address _owner) public view returns (uint256) 
    {
       return balances[_owner];
    }

     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)     
    {
       if (_value == 0) 
       {
           emit Transfer(_from, _to, _value);   
           return;
       }

       require(!advClaimLimits[msg.sender].limitSet, "Limit is set and use advClaim");
       require(!teamClaimLimits[msg.sender].limitSet, "Limit is set and use teamClaim");
       require(!claimLimits[msg.sender].limitSet, "Limit is set and use claim");
       require(_to != address(0x0));
       require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);

       balances[_from] = balances[_from].sub(_value);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
       balances[_to] = balances[_to].add(_value);
       emit Transfer(_from, _to, _value);
       return true;
    }

     

    function approve(address _spender, uint256 _tokens) public returns(bool)
    {
       require(_spender != address(0x0));

       allowed[msg.sender][_spender] = _tokens;
       emit Approval(msg.sender, _spender, _tokens);
       return true;
    }

     

    function allowance(address _owner, address _spender) public view returns(uint256)
    {
       require(_owner != address(0x0) && _spender != address(0x0));

       return allowed[_owner][_spender];
    }

     

    function transfer(address _address, uint256 _tokens) public returns(bool)
    {
       if (_tokens == 0) 
       {
           emit Transfer(msg.sender, _address, _tokens);   
           return;
       }

       require(!advClaimLimits[msg.sender].limitSet, "Limit is set and use advClaim");
       require(!teamClaimLimits[msg.sender].limitSet, "Limit is set and use teamClaim");
       require(!claimLimits[msg.sender].limitSet, "Limit is set and use claim");
       require(_address != address(0x0));
       require(balances[msg.sender] >= _tokens);

       balances[msg.sender] = (balances[msg.sender]).sub(_tokens);
       balances[_address] = (balances[_address]).add(_tokens);
       emit Transfer(msg.sender, _address, _tokens);
       return true;
    }
    
     

    function transferTo(address _address, uint256 _tokens) external onlyOwner returns(bool) 
    {
       require( _address != address(0x0)); 
       require( balances[address(this)] >= _tokens.mul(TOKEN_DECIMALS) && _tokens.mul(TOKEN_DECIMALS) > 0);

       balances[address(this)] = ( balances[address(this)]).sub(_tokens.mul(TOKEN_DECIMALS));
       balances[_address] = (balances[_address]).add(_tokens.mul(TOKEN_DECIMALS));
       emit Transfer(address(this), _address, _tokens.mul(TOKEN_DECIMALS));
       return true;
    }
	
     

    function transferOwnership(address _newOwner)public onlyOwner
    {
       require( _newOwner != address(0x0));

       balances[_newOwner] = (balances[_newOwner]).add(balances[owner]);
       balances[owner] = 0;
       owner = _newOwner;
       emit Transfer(msg.sender, _newOwner, balances[_newOwner]);
   }

    

   function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) 
   {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

    

   function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) 
   {
      uint256 oldValue = allowed[msg.sender][_spender];

      if (_subtractedValue > oldValue) 
      {
         allowed[msg.sender][_spender] = 0;
      }
      else 
      {
         allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

    

   function adviserClaim(address _recipient) public
   {
      require(_recipient != address(0x0), "Invalid recipient");
      require(msg.sender != _recipient, "Self transfer");
      require(advClaimLimits[msg.sender].limitSet, "Limit not set");
      require(advClaimLimits[msg.sender].round < 3, "Claims are over for this adviser wallet");
      
      if (advClaimLimits[msg.sender].last_claim_time > 0) {
        require (now > ((advClaimLimits[msg.sender].last_claim_time).add 
           (advClaimLimits[msg.sender].time_limit_epoch)), "Time limit");
      }
       
       uint256 tokens = advClaimLimits[msg.sender].tokens[advClaimLimits[msg.sender].round];
       if (balances[msg.sender] < tokens)
            tokens = balances[msg.sender];
        
       if (tokens == 0) {
           emit Transfer(msg.sender, _recipient, tokens);
           return;
       }
       
       balances[msg.sender] = (balances[msg.sender]).sub(tokens);
       balances[_recipient] = (balances[_recipient]).add(tokens);
       
        
       advClaimLimits[msg.sender].last_claim_time = now;
       advClaimLimits[msg.sender].round++;
       emit Transfer(msg.sender, _recipient, tokens);
   }
 
    

   function setAdviserClaimLimit(address _addr) public onlyOwner
   {
      uint256 num_days  = 90;   
      uint256 percent   = 25;  
      uint256 percent1  = 25;  
      uint256 percent2  = 50;  

      require(_addr != address(0x0), "Invalid address");

      advClaimLimits[_addr].time_limit_epoch = (now.add(((num_days).mul(1 minutes)))).sub(now);
      advClaimLimits[_addr].last_claim_time  = 0;

      if (balances[_addr] > 0) 
      {
          advClaimLimits[_addr].tokens[0] = ((balances[_addr]).mul(percent)).div(100);
          advClaimLimits[_addr].tokens[1] = ((balances[_addr]).mul(percent1)).div(100);
          advClaimLimits[_addr].tokens[2] = ((balances[_addr]).mul(percent2)).div(100);
      }    
      else 
      {
          advClaimLimits[_addr].tokens[0] = 0;
   	  advClaimLimits[_addr].tokens[1] = 0;
   	  advClaimLimits[_addr].tokens[2] = 0;
      }    
      
      advClaimLimits[_addr].round = 0;
      advClaimLimits[_addr].limitSet = true;
   }

    

   function teamClaim(address _recipient) public
   {
      require(_recipient != address(0x0), "Invalid recipient");
      require(msg.sender != _recipient, "Self transfer");
      require(teamClaimLimits[msg.sender].limitSet, "Limit not set");
      require(teamClaimLimits[msg.sender].round < 4, "Claims are over for this team wallet");
      
      if (teamClaimLimits[msg.sender].last_claim_time > 0) {
        require (now > ((teamClaimLimits[msg.sender].last_claim_time).add 
           (teamClaimLimits[msg.sender].time_limit_epoch)), "Time limit");
      }
       
       uint256 tokens = teamClaimLimits[msg.sender].tokens[teamClaimLimits[msg.sender].round];
       if (balances[msg.sender] < tokens)
            tokens = balances[msg.sender];
        
       if (tokens == 0) {
           emit Transfer(msg.sender, _recipient, tokens);
           return;
       }
       
       balances[msg.sender] = (balances[msg.sender]).sub(tokens);
       balances[_recipient] = (balances[_recipient]).add(tokens);
       
        
       teamClaimLimits[msg.sender].last_claim_time = now;
       teamClaimLimits[msg.sender].round++;
       emit Transfer(msg.sender, _recipient, tokens);
   }
 
    

   function setTeamClaimLimit(address _addr) public onlyOwner
   {
      uint256 num_days  = 180;   
      uint256 percent   = 10;  
      uint256 percent1  = 15;  
      uint256 percent2  = 35;  
      uint256 percent3  = 40;  

      require(_addr != address(0x0), "Invalid address");

      teamClaimLimits[_addr].time_limit_epoch = (now.add(((num_days).mul(1 minutes)))).sub(now);
      teamClaimLimits[_addr].last_claim_time  = 0;

      if (balances[_addr] > 0) 
      {
          teamClaimLimits[_addr].tokens[0] = ((balances[_addr]).mul(percent)).div(100);
          teamClaimLimits[_addr].tokens[1] = ((balances[_addr]).mul(percent1)).div(100);
          teamClaimLimits[_addr].tokens[2] = ((balances[_addr]).mul(percent2)).div(100);
          teamClaimLimits[_addr].tokens[3] = ((balances[_addr]).mul(percent3)).div(100);
      }    
      else 
      {
          teamClaimLimits[_addr].tokens[0] = 0;
   	      teamClaimLimits[_addr].tokens[1] = 0;
   	      teamClaimLimits[_addr].tokens[2] = 0;
   	      teamClaimLimits[_addr].tokens[3] = 0;
      }    
      
      teamClaimLimits[_addr].round = 0;
      teamClaimLimits[_addr].limitSet = true;
    }

     

    function claim(address _recipient) public
    {
       require(_recipient != address(0x0), "Invalid recipient");
       require(msg.sender != _recipient, "Self transfer");
       require(claimLimits[msg.sender].limitSet, "Limit not set");
       
       if (claimLimits[msg.sender].last_claim_time > 0) 
       {
          require (now > ((claimLimits[msg.sender].last_claim_time).
            add(claimLimits[msg.sender].time_limit_epoch)), "Time limit");
       }
       
       uint256 tokens = claimLimits[msg.sender].tokens;

       if (balances[msg.sender] < tokens)
            tokens = balances[msg.sender];
        
       if (tokens == 0) 
       {
            emit Transfer(msg.sender, _recipient, tokens);
            return;
       }
       
       balances[msg.sender] = (balances[msg.sender]).sub(tokens);
       balances[_recipient] = (balances[_recipient]).add(tokens);
       
        
       claimLimits[msg.sender].last_claim_time = now;
       
       emit Transfer(msg.sender, _recipient, tokens);
    }
 

     

    function setClaimLimit(address _address, uint256 _days, uint256 _percent) public onlyOwner
    {
       require(_percent <= 100, "Invalid percent");

       claimLimits[_address].time_limit_epoch = (now.add(((_days).mul(1 minutes)))).sub(now);
       claimLimits[_address].last_claim_time  = 0;
   		
       if (balances[_address] > 0)
   	      claimLimits[_address].tokens = ((balances[_address]).mul(_percent)).div(100);
       else
   	      claimLimits[_address].tokens = 0;
   		    
       claimLimits[_address].limitSet = true;
    }

   

}