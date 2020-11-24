 

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

contract UBOCOIN is BurnableToken, Ownable
{
     
    string public constant name = "UBOCOIN";
    string public constant symbol = "UBO";
    uint8 public constant decimals = 18;
    
    
     
    uint256 private UBO_per_ETH = 1000 * (uint256(10) ** decimals);
    
     
    uint256 private constant pre_ICO_duration = 15 days;
    uint256 private constant pre_ICO_bonus_percentage = 43;
    uint256 private constant pre_ICO_bonus_minimum_purchased_UBO = 1000 * (uint256(10) ** decimals);
    
     
    uint256 private constant first_bonus_sale_duration = 21 days;
    uint256 private constant first_bonus_sale_bonus = 15;
    
     
    uint256 private constant second_bonus_sale_duration = 15 days;
    uint256 private constant second_bonus_sale_bonus = 10;
    
     
    uint256 private constant third_bonus_sale_duration = 8 days;
    uint256 private constant third_bonus_sale_bonus = 6;
    
     
    uint256 private constant fourth_bonus_sale_duration = 7 days;
    uint256 private constant fourth_bonus_sale_bonus = 3;
    
     
    uint256 private constant final_sale_duration = 5 days;
    
    
     
     
     
     
     
    uint256 public constant crowdsaleTargetUBO = 3500000 * (uint256(10) ** decimals);
    
    
     
    uint256 private pre_ICO_start_timestamp;
    uint256 private first_bonus_sale_start_timestamp;
    uint256 private second_bonus_sale_start_timestamp;
    uint256 private third_bonus_sale_start_timestamp;
    uint256 private fourth_bonus_sale_start_timestamp;
    uint256 private final_sale_start_timestamp;
    uint256 private crowdsale_end_timestamp;
    
    
     
     
    uint256 public crowdsaleAmountLeft;
    uint256 public foundersAmountLeft;
    uint256 public earlyBackersAmountLeft;
    uint256 public teamAmountLeft;
    uint256 public bountyAmountLeft;
    uint256 public reservedFundLeft;
    
     
    address[] public allParticipants;
    mapping(address => uint256) public participantToEtherSpent;
    mapping(address => uint256) public participantToUBObought;
    
    
    function crowdsaleTargetReached() public view returns (bool)
    {
        return amountOfUBOsold() >= crowdsaleTargetUBO;
    }
    
    function crowdsaleStarted() public view returns (bool)
    {
        return pre_ICO_start_timestamp > 0 && now >= pre_ICO_start_timestamp;
    }
    
    function crowdsaleFinished() public view returns (bool)
    {
        return pre_ICO_start_timestamp > 0 && now >= crowdsale_end_timestamp;
    }
    
    function amountOfParticipants() external view returns (uint256)
    {
        return allParticipants.length;
    }
    
    function amountOfUBOsold() public view returns (uint256)
    {
        return totalSupply_ * 70 / 100 - crowdsaleAmountLeft;
    }
    
     
     
    function transfer(address _to, uint256 _amount) public returns (bool)
    {
        if (!crowdsaleTargetReached() || !crowdsaleFinished())
        {
            require(balances[msg.sender] - participantToUBObought[msg.sender] >= _amount);
        }
        
        return super.transfer(_to, _amount);
    }
    
    
     
    function UBOCOIN() public
    {
        totalSupply_ = 300000000 * (uint256(10) ** decimals);
        balances[this] = totalSupply_;
        Transfer(0x0, this, totalSupply_);
        
        crowdsaleAmountLeft = totalSupply_ * 70 / 100;    
        foundersAmountLeft = totalSupply_ * 10 / 100;     
        earlyBackersAmountLeft = totalSupply_ * 5 / 100;  
        teamAmountLeft = totalSupply_ * 5 / 100;          
        bountyAmountLeft = totalSupply_ * 5 / 100;        
        reservedFundLeft = totalSupply_ * 5 / 100;        
        
        setPreICOStartTime(1518998400);  
    }
    
    function setPreICOStartTime(uint256 _timestamp) public onlyOwner
    {
         
        require(!crowdsaleStarted());
        
        pre_ICO_start_timestamp = _timestamp;
        first_bonus_sale_start_timestamp = pre_ICO_start_timestamp + pre_ICO_duration;
        second_bonus_sale_start_timestamp = first_bonus_sale_start_timestamp + first_bonus_sale_duration;
        third_bonus_sale_start_timestamp = second_bonus_sale_start_timestamp + second_bonus_sale_duration;
        fourth_bonus_sale_start_timestamp = third_bonus_sale_start_timestamp + third_bonus_sale_duration;
        final_sale_start_timestamp = fourth_bonus_sale_start_timestamp + fourth_bonus_sale_duration;
        crowdsale_end_timestamp = final_sale_start_timestamp + final_sale_duration;
    }
    
    function startPreICOnow() external onlyOwner
    {
        setPreICOStartTime(now);
    }
    
    function destroyUnsoldTokens() external
    {
        require(crowdsaleStarted() && crowdsaleFinished());
        
        uint256 amountToBurn = crowdsaleAmountLeft;
        crowdsaleAmountLeft = 0;
        this.burn(amountToBurn);
    }
    
     
     
    function () payable external
    {
        buyTokens();
    }
    
    function buyTokens() payable public
    {
        uint256 amountOfUBOpurchased = msg.value * UBO_per_ETH / (1 ether);
        
         
        require(crowdsaleStarted());
        require(!crowdsaleFinished());
        
         
        if (now < pre_ICO_start_timestamp)
        {
            revert();
        }
        
         
        else if (now >= pre_ICO_start_timestamp && now < first_bonus_sale_start_timestamp)
        {
             
             
            if (amountOfUBOpurchased >= pre_ICO_bonus_minimum_purchased_UBO)
            {
                amountOfUBOpurchased = amountOfUBOpurchased * (100 + pre_ICO_bonus_percentage) / 100;
            }
        }
        
         
        else if (now >= first_bonus_sale_start_timestamp && now < second_bonus_sale_start_timestamp)
        {
            amountOfUBOpurchased = amountOfUBOpurchased * (100 + first_bonus_sale_bonus) / 100;
        }
        
         
        else if (now >= second_bonus_sale_start_timestamp && now < third_bonus_sale_start_timestamp)
        {
            amountOfUBOpurchased = amountOfUBOpurchased * (100 + second_bonus_sale_bonus) / 100;
        }
        
         
        else if (now >= third_bonus_sale_start_timestamp && now < fourth_bonus_sale_start_timestamp)
        {
            amountOfUBOpurchased = amountOfUBOpurchased * (100 + third_bonus_sale_bonus) / 100;
        }
        
         
        else if (now >= fourth_bonus_sale_start_timestamp && now < final_sale_start_timestamp)
        {
            amountOfUBOpurchased = amountOfUBOpurchased * (100 + fourth_bonus_sale_bonus) / 100;
        }
        
         
        else if (now >= final_sale_start_timestamp && now < crowdsale_end_timestamp)
        {
             
        }
        
         
        else
        {
            revert();
        }
        
         
        require(amountOfUBOpurchased <= crowdsaleAmountLeft);
        
         
         
        crowdsaleAmountLeft -= amountOfUBOpurchased;
        balances[this] -= amountOfUBOpurchased;
        balances[msg.sender] += amountOfUBOpurchased;
        Transfer(this, msg.sender, amountOfUBOpurchased);
        
         
        if (participantToEtherSpent[msg.sender] == 0)
        {
            allParticipants.push(msg.sender);
        }
        participantToUBObought[msg.sender] += amountOfUBOpurchased;
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
             
            uint256 refundUBO = participantToUBObought[_participant];
            participantToUBObought[_participant] = 0;
            balances[_participant] -= refundUBO;
            balances[this] += refundUBO;
            crowdsaleAmountLeft += refundUBO;
            Transfer(_participant, this, refundUBO);
            
             
            uint256 refundETH = participantToEtherSpent[_participant];
            participantToEtherSpent[_participant] = 0;
            _participant.transfer(refundETH);
        }
    }
    
    function distributeFounderTokens(address _founderAddress, uint256 _amount) external onlyOwner
    {
        require(_amount <= foundersAmountLeft);
        foundersAmountLeft -= _amount;
        this.transfer(_founderAddress, _amount);
    }
    
    function distributeEarlyBackerTokens(address _earlyBackerAddress, uint256 _amount) external onlyOwner
    {
        require(_amount <= earlyBackersAmountLeft);
        earlyBackersAmountLeft -= _amount;
        this.transfer(_earlyBackerAddress, _amount);
    }
    
    function distributeTeamTokens(address _teamMemberAddress, uint256 _amount) external onlyOwner
    {
        require(_amount <= teamAmountLeft);
        teamAmountLeft -= _amount;
        this.transfer(_teamMemberAddress, _amount);
    }
    
    function distributeBountyTokens(address _bountyReceiverAddress, uint256 _amount) external onlyOwner
    {
        require(_amount <= bountyAmountLeft);
        bountyAmountLeft -= _amount;
        this.transfer(_bountyReceiverAddress, _amount);
    }
    
    function distributeReservedTokens(address _to, uint256 _amount) external onlyOwner
    {
        require(_amount <= reservedFundLeft);
        reservedFundLeft -= _amount;
        this.transfer(_to, _amount);
    }
    
    function distributeCrowdsaleTokens(address _to, uint256 _amount) external onlyOwner
    {
        require(_amount <= crowdsaleAmountLeft);
        crowdsaleAmountLeft -= _amount;
        this.transfer(_to, _amount);
    }
    
    function ownerWithdrawETH() external onlyOwner
    {
         
        require(crowdsaleTargetReached());
        
        owner.transfer(this.balance);
    }
}