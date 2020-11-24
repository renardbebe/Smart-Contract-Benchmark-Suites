 

pragma solidity ^0.4.19;


 
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
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
     
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  
  function approve(address _spender, uint256 _amount) public returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  uint balanceOfParticipant;
  uint lockedAmount;
  uint allowedAmount;
   
  mapping(address => uint256) balances;
  struct Lockup
  {
      uint256 lockupTime;
      uint256 lockupAmount;
  }
  Lockup lockup;
  mapping(address=>Lockup) lockupParticipants;  
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

     if (lockupParticipants[msg.sender].lockupAmount>0)
    {
        uint timePassed = now - lockupParticipants[msg.sender].lockupTime;
         
        if (timePassed <92 days)
        {
             
            balanceOfParticipant = balances[msg.sender];
            lockedAmount = lockupParticipants[msg.sender].lockupAmount;
            allowedAmount = lockedAmount.mul(5).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        }
         
        else if (timePassed >= 92 days && timePassed < 183 days)
        {
             
            balanceOfParticipant = balances[msg.sender];
            lockedAmount = lockupParticipants[msg.sender].lockupAmount;
            allowedAmount = lockedAmount.mul(30).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        
        }
          
        else if (timePassed >= 183 days && timePassed < 365 days)
        {
             
            balanceOfParticipant = balances[msg.sender];
            lockedAmount = lockupParticipants[msg.sender].lockupAmount;
            allowedAmount = lockedAmount.mul(55).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        }
        else if (timePassed > 365 days)
        {
             
        }
    }
     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {
  
  
  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to]);
    if (lockupParticipants[_from].lockupAmount>0)
    {
        uint timePassed = now - lockupParticipants[_from].lockupTime;
         
        if (timePassed <92 days)
        {
             
            balanceOfParticipant = balances[_from];
            lockedAmount = lockupParticipants[_from].lockupAmount;
            allowedAmount = lockedAmount.mul(5).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        }
         
        else if (timePassed >= 92 days && timePassed < 183 days)
        {
             
            balanceOfParticipant = balances[_from];
            lockedAmount = lockupParticipants[_from].lockupAmount;
            allowedAmount = lockedAmount.mul(30).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        
        }
          
        else if (timePassed >= 183 days && timePassed < 365 days)
        {
             
            balanceOfParticipant = balances[_from];
            lockedAmount = lockupParticipants[_from].lockupAmount;
            allowedAmount = lockedAmount.mul(55).div(100);
            require(balanceOfParticipant.sub(_amount)>=lockedAmount.sub(allowedAmount));
        }
        else if (timePassed > 365 days)
        {
             
        }
    }
    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[msg.sender]);
         
         

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}
 
 contract PVCToken is BurnableToken {
     string public name ;
     string public symbol ;
     uint8 public decimals = 18 ;
     
      
     function ()public payable {
         revert();
     }
     
      
     function PVCToken(address wallet) public {
         owner = wallet;
         totalSupply = uint(50000000).mul( 10 ** uint256(decimals));  
         name = "Pryvate";
         symbol = "PVC";
         balances[wallet] = totalSupply;
         
          
         emit Transfer(address(0), msg.sender, totalSupply);
     }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
      return (name, symbol, totalSupply);
    }

    function teamVesting(address[] teamMembers, uint[] tokens) public onlyOwner
     {
         require(teamMembers.length == tokens.length);
         for (uint i=0;i<teamMembers.length;i++)
         {
             tokens[i] = tokens[i].mul(10**18);
              require(teamMembers[i] != address(0));
              require(balances[owner] >= tokens[i] && tokens[i] > 0
            && balances[teamMembers[i]].add(tokens[i]) > balances[teamMembers[i]]);

             
            balances[owner] = balances[owner].sub(tokens[i]);
            balances[teamMembers[i]] = balances[teamMembers[i]].add(tokens[i]);
            emit Transfer(owner, teamMembers[i], tokens[i]);
            lockup = Lockup({lockupTime:now,lockupAmount:tokens[i]});
            lockupParticipants[teamMembers[i]] = lockup;
         }
     }
     
     function advisorVesting(address[] advisors, uint[] tokens) public onlyOwner
     {
         require(advisors.length == tokens.length);
         for (uint i=0;i<advisors.length;i++)
         {
             tokens[i] = tokens[i].mul(10**18);
              require(advisors[i] != address(0));
              require(balances[owner] >= tokens[i] && tokens[i] > 0
            && balances[advisors[i]].add(tokens[i]) > balances[advisors[i]]);

             
            balances[owner] = balances[owner].sub(tokens[i]);
            balances[advisors[i]] = balances[advisors[i]].add(tokens[i]);
            emit Transfer(owner, advisors[i], tokens[i]);
            lockup = Lockup({lockupTime:now,lockupAmount:tokens[i]});
            lockupParticipants[advisors[i]] = lockup;
         }
     }
 }