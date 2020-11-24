 

pragma solidity ^0.4.19;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract BRANDCOIN is StandardToken, BurnableToken, Ownable
{
     
    string public constant name = "BRANDCOIN";
    string public constant symbol = "BRA";
    uint256 public constant decimals = 18;
    
     
    uint256 public ETH_per_BRA = 0.00024261 ether;
    
     
    uint256 private first_period_start_date = 1523750400;
    uint256 private constant first_period_bonus_percentage = 43;
    uint256 private constant first_period_bonus_minimum_purchased_BRA = 1000 * (uint256(10) ** decimals);
    
     
    uint256 private second_period_start_date = 1525132800;
    uint256 private constant second_period_bonus_percentage = 15;
    
     
    uint256 private third_period_start_date = 1525737600;
    uint256 private constant third_period_bonus_percentage = 10;
    
     
    uint256 private fourth_period_start_date = 1526342400;
    uint256 private constant fourth_period_bonus_percentage = 6;
    
     
    uint256 private fifth_period_start_date = 1526947200;
    uint256 private constant fifth_period_bonus_percentage = 3;
    
     
    uint256 private crowdsale_end_timestamp = 1527811200;
    
     
     
     
     
     
    uint256 public constant crowdsaleTargetBRA = 8000000 * (uint256(10) ** decimals);
    
    
     
    address[] public allParticipants;
    mapping(address => uint256) public participantToEtherSpent;
    mapping(address => uint256) public participantToBRAbought;
    
    
    function crowdsaleTargetReached() public view returns (bool)
    {
        return amountOfBRAsold() >= crowdsaleTargetBRA;
    }
    
    function crowdsaleStarted() public view returns (bool)
    {
        return now >= first_period_start_date;
    }
    
    function crowdsaleFinished() public view returns (bool)
    {
        return now >= crowdsale_end_timestamp;
    }
    
    function amountOfParticipants() external view returns (uint256)
    {
        return allParticipants.length;
    }
    
    function amountOfBRAsold() public view returns (uint256)
    {
        return totalSupply_ / 2 - balances[this];
    }
    
     
     
    function transfer(address _to, uint256 _amount) public returns (bool)
    {
        if (!crowdsaleTargetReached() || !crowdsaleFinished())
        {
            require(balances[msg.sender] - participantToBRAbought[msg.sender] >= _amount);
        }
        
        return super.transfer(_to, _amount);
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        if (!crowdsaleTargetReached() || !crowdsaleFinished())
        {
            require(balances[_from] - participantToBRAbought[_from] >= _amount);
        }
        
        return super.transferFrom(_from, _to, _amount);
    }
    
    address public founderWallet = 0x6bC5aa2B9eb4aa5b6170Dafce4482efF56184ADd;
    address public teamWallet = 0xb054D33607fC07e55469c81ABcB1553B92914E9e;
    address public bountyAffiliateWallet = 0x9460bc2bB546B640060E0268Ba8C392b0A0D6330;
    address public earlyBackersWallet = 0x4681B5c67ae0632c57ee206e1f9c2Ca58D6Af34c;
    address public reserveWallet = 0x4d70B2aCaE5e6558A9f5d55E672E93916Ba5c7aE;
    
     
    function BRANDCOIN() public
    {
        totalSupply_ = 1650000000 * (uint256(10) ** decimals);
        balances[this] = totalSupply_;
        Transfer(0x0, this, totalSupply_);
    }
    
    bool private distributedInitialFunds = false;
    function distributeInitialFunds() public onlyOwner
    {
        require(!distributedInitialFunds);
        distributedInitialFunds = true;
        this.transfer(founderWallet, totalSupply_*15/100);
        this.transfer(earlyBackersWallet, totalSupply_*5/100);
        this.transfer(teamWallet, totalSupply_*15/100);
        this.transfer(bountyAffiliateWallet, totalSupply_*5/100);
        this.transfer(reserveWallet, totalSupply_*10/100);
    }
    
    function destroyUnsoldTokens() external onlyOwner
    {
        require(crowdsaleStarted() && crowdsaleFinished());
        
        this.burn(balances[this]);
    }
    
     
     
    function () payable external
    {
        buyTokens();
    }
    
    function buyTokens() payable public
    {
        uint256 amountOfBRApurchased = msg.value * (uint256(10)**decimals) / ETH_per_BRA;
        
         
        require(crowdsaleStarted());
        require(!crowdsaleFinished());
        
         
        if (now < first_period_start_date)
        {
            revert();
        }
        
        else if (now >= first_period_start_date && now < second_period_start_date)
        {
            if (amountOfBRApurchased >= first_period_bonus_minimum_purchased_BRA)
            {
                amountOfBRApurchased = amountOfBRApurchased * (100 + first_period_bonus_percentage) / 100;
            }
        }
        
        else if (now >= second_period_start_date && now < third_period_start_date)
        {
            amountOfBRApurchased = amountOfBRApurchased * (100 + second_period_bonus_percentage) / 100;
        }
        
        else if (now >= third_period_start_date && now < fourth_period_start_date)
        {
            amountOfBRApurchased = amountOfBRApurchased * (100 + third_period_bonus_percentage) / 100;
        }
        
        else if (now >= fourth_period_start_date && now < fifth_period_start_date)
        {
            amountOfBRApurchased = amountOfBRApurchased * (100 + fourth_period_bonus_percentage) / 100;
        }
        
        else if (now >= fifth_period_start_date && now < crowdsale_end_timestamp)
        {
            amountOfBRApurchased = amountOfBRApurchased * (100 + fifth_period_bonus_percentage) / 100;
        }
        
         
        else
        {
            revert();
        }
        
         
        this.transfer(msg.sender, amountOfBRApurchased);
        
         
        if (participantToEtherSpent[msg.sender] == 0)
        {
            allParticipants.push(msg.sender);
        }
        participantToBRAbought[msg.sender] += amountOfBRApurchased;
        participantToEtherSpent[msg.sender] += msg.value;
    }
    
    function refund() external
    {
         
        require(crowdsaleStarted());
        
         
        require(crowdsaleFinished());
        
         
        require(!crowdsaleTargetReached());
        
        _refundParticipant(msg.sender);
    }
    
    function refundMany(uint256 _startIndex, uint256 _endIndex) external
    {
         
        require(crowdsaleStarted());
        
         
        require(crowdsaleFinished());
        
         
        require(!crowdsaleTargetReached());
        
        for (uint256 i=_startIndex; i<=_endIndex && i<allParticipants.length; i++)
        {
            _refundParticipant(allParticipants[i]);
        }
    }
    
    function _refundParticipant(address _participant) internal
    {
        if (participantToEtherSpent[_participant] > 0)
        {
             
            uint256 refundBRA = participantToBRAbought[_participant];
            participantToBRAbought[_participant] = 0;
            balances[_participant] -= refundBRA;
            balances[this] += refundBRA;
            Transfer(_participant, this, refundBRA);
            
             
            uint256 refundETH = participantToEtherSpent[_participant];
            participantToEtherSpent[_participant] = 0;
            _participant.transfer(refundETH);
        }
    }
    
    function distributeCrowdsaleTokens(address _to, uint256 _amount) external onlyOwner
    {
        this.transfer(_to, _amount);
    }
    
    function ownerWithdrawETH() external onlyOwner
    {
         
        require(crowdsaleTargetReached());
        owner.transfer(this.balance);
    }
    
     
    function setPrice(uint256 _ETH_PER_BRA) external onlyOwner
    {
        require(!crowdsaleStarted());
        ETH_per_BRA = _ETH_PER_BRA;
    }
}