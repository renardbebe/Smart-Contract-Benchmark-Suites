 

pragma solidity ^0.4.21;

 

 
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

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

contract GCToken is StandardToken, HasNoEther {

    string constant public name = "GlobeCas";
    string constant public symbol = "GCT";
    uint8 constant public decimals = 8;
    
    event Mint(address indexed to, uint256 amount);
    event Claim(address indexed from, uint256 amount);
    
    address constant public CROWDSALE_ACCOUNT    = 0x52e35C4FfFD6fcf550915C5eCafeE395860DDcD5;
    address constant public COMPANY_ACCOUNT      = 0x7862a8f56C450866B4859EF391A85c535Df18c87;
    address constant public PRIVATE_SALE_ACCOUNT = 0x66FA34A9c50873b344a24B662720B632ad8E1517;
    address constant public TEAM_ACCOUNT         = 0x492C8b81D22Ad46b19419Df3D88Fd77b6850A9E4;
    address constant public PROMOTION_ACCOUNT    = 0x067724fb3439B5c52267d1ddDb3047C037290756;

     
    uint constant public CAPPED_SUPPLY       = 20000000000e8;  
    uint constant public TEAM_RESERVE        = 2000000000e8;   
    uint constant public COMPANY_RESERVE     = 8000000000e8;   
    uint constant public PRIVATE_SALE        = 900000000e8;    
    uint constant public PROMOTION_PROGRAM   = 1000000000e8;   
    uint constant public CROWDSALE_SUPPLY    = 8100000000e8;   
     
   
    
    bool public companyClaimed;

     
    uint constant public COMPANY_RESERVE_FOR = 182 days;  
    
     
    uint constant public TEAM_CAN_CLAIM_AFTER = 120 days; 

     
    uint constant public CLAIM_STAGE = 30 days;

     
    uint[] public teamReserve = [8658000e8, 17316000e8, 25974000e8, 34632000e8, 43290000e8, 51948000e8, 60606000e8, 69264000e8, 77922000e8, 86580000e8, 95238000e8, 103896000e8, 112554000e8, 121212000e8, 129870000e8, 138528000e8, 147186000e8, 155844000e8, 164502000e8, 173160000e8, 181820000e8];
        
     
    uint public icoEndTime = 1540339199;  

    modifier canMint() {
        require(totalSupply_ < CAPPED_SUPPLY);
        _;
    }

    function GCToken() public {
        mint(PRIVATE_SALE_ACCOUNT, PRIVATE_SALE);
        mint(PROMOTION_ACCOUNT, PROMOTION_PROGRAM);
        mint(CROWDSALE_ACCOUNT, CROWDSALE_SUPPLY);
    }

    function claimCompanyReserve () external {
        require(!companyClaimed);
        require(msg.sender == COMPANY_ACCOUNT);        
        require(now >= icoEndTime.add(COMPANY_RESERVE_FOR));
        mint(COMPANY_ACCOUNT, COMPANY_RESERVE);
        companyClaimed = true;
    }

    function claimTeamToken() external {
        require(msg.sender == TEAM_ACCOUNT);
        require(now >= icoEndTime.add(TEAM_CAN_CLAIM_AFTER));
        require(teamReserve[20] > 0);

         
        uint claimableTime = icoEndTime.add(TEAM_CAN_CLAIM_AFTER);
        uint totalClaimable;

        for(uint i = 0; i < 21; i++){
            if(teamReserve[i] > 0){
                 
                if(claimableTime.add(i.mul(CLAIM_STAGE)) < now){
                    totalClaimable = totalClaimable.add(teamReserve[i]);
                    teamReserve[i] = 0;
                }else{
                    break;
                }
            }
        }
        if(totalClaimable > 0){
            mint(TEAM_ACCOUNT, totalClaimable);
        }
    }
    
    
     
    function mint(address _to, uint256 _amount) canMint internal returns (bool) {
        require(totalSupply_.add(_amount) <= CAPPED_SUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint (_to, _amount);
        return true;
    }

     
    function setIcoEndTime(uint _icoEndTime) public onlyOwner {
        require(_icoEndTime >= now);
        icoEndTime = _icoEndTime;
    }
}