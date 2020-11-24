 

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
contract NonZero {

 
    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {
        require(msg.value > 0);
        _;
    }

     
     
    modifier onlyPayloadSize(uint size) {
	 
	 
    assert(msg.data.length >= size + 4);
     _;
   } 
}

contract FuelToken is ERC20, Ownable, NonZero {

    using SafeMath for uint;

 
    string public constant name = "Fuel Token";
    string public constant symbol = "FUEL";

    uint8 public decimals = 18;
    
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

 
    
     
    uint256 public vanbexTeamSupply;
     
    uint256 public platformSupply;
     
    uint256 public presaleSupply;
     
    uint256 public presaleAmountRemaining;
     
    uint256 public icoSupply;
     
    uint256 public incentivisingEffortsSupply;
     
    uint256 public crowdfundEndsAt;
     
    uint256 public vanbexTeamVestingPeriod;

     
    address public crowdfundAddress;
     
    address public vanbexTeamAddress;
     
    address public platformAddress;
     
    address public incentivisingEffortsAddress;

     
    bool public presaleFinalized = false;
     
    bool public crowdfundFinalized = false;

 

     
    event CrowdfundFinalized(uint tokensRemaining);
     
    event PresaleFinalized(uint tokensRemaining);

 

     
    modifier notBeforeCrowdfundEnds(){
        require(now >= crowdfundEndsAt);
        _;
    }

     
    modifier checkVanbexTeamVestingPeriod() {
        assert(now >= vanbexTeamVestingPeriod);
        _;
    }

     
    modifier onlyCrowdfund() {
        require(msg.sender == crowdfundAddress);
        _;
    }

 

     
    function transfer(address _to, uint256 _amount) notBeforeCrowdfundEnds returns (bool success) {
        require(balanceOf(msg.sender) >= _amount);
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) notBeforeCrowdfundEnds returns (bool success) {
        require(allowance(_from, msg.sender) >= _amount);
        decrementBalance(_from, _amount);
        addToBalance(_to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

 

     
    function FuelToken() {
        crowdfundEndsAt = 1509292800;                                                
        vanbexTeamVestingPeriod = crowdfundEndsAt.add(183 * 1 days);                 

        totalSupply = 1 * 10**27;                                                    
        vanbexTeamSupply = 5 * 10**25;                                               
        platformSupply = 5 * 10**25;                                                 
        incentivisingEffortsSupply = 1 * 10**26;                                     
        presaleSupply = 54 * 10**25;                                                 
        icoSupply = 26 * 10**25;                                                     
       
        presaleAmountRemaining = presaleSupply;                                      
        vanbexTeamAddress = 0xCF701D8eA4C727466D42651dda127c0c033076B0;              
        platformAddress = 0xF5b5f6c1E233671B220C2A19Af10Fd18785D0744;                
        incentivisingEffortsAddress = 0x5584b17B40F6a2E412e65FcB1533f39Fc7D8Aa26;    

        addToBalance(incentivisingEffortsAddress, incentivisingEffortsSupply);     
        addToBalance(platformAddress, platformSupply);                              
    }

     
    function setCrowdfundAddress(address _crowdfundAddress) external onlyOwner nonZeroAddress(_crowdfundAddress) {
        require(crowdfundAddress == 0x0);
        crowdfundAddress = _crowdfundAddress;
        addToBalance(crowdfundAddress, icoSupply); 
    }

     
    function transferFromCrowdfund(address _to, uint256 _amount) onlyCrowdfund nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(crowdfundAddress) >= _amount);
        decrementBalance(crowdfundAddress, _amount);
        addToBalance(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function releaseVanbexTeamTokens() checkVanbexTeamVestingPeriod onlyOwner returns(bool success) {
        require(vanbexTeamSupply > 0);
        addToBalance(vanbexTeamAddress, vanbexTeamSupply);
        Transfer(0x0, vanbexTeamAddress, vanbexTeamSupply);
        vanbexTeamSupply = 0;
        return true;
    }

     
    function finalizePresale() external onlyOwner returns (bool success) {
        require(presaleFinalized == false);
        uint256 amount = presaleAmountRemaining;
        if (amount != 0) {
            presaleAmountRemaining = 0;
            addToBalance(crowdfundAddress, amount);
        }
        presaleFinalized = true;
        PresaleFinalized(amount);
        return true;
    }

     
    function finalizeCrowdfund() external onlyCrowdfund {
        require(presaleFinalized == true && crowdfundFinalized == false);
        uint256 amount = balanceOf(crowdfundAddress);
        if (amount > 0) {
            balances[crowdfundAddress] = 0;
            addToBalance(platformAddress, amount);
            Transfer(crowdfundAddress, platformAddress, amount);
        }
        crowdfundFinalized = true;
        CrowdfundFinalized(amount);
    }


     
    function deliverPresaleFuelBalances(address[] _batchOfAddresses, uint[] _amountOfFuel) external onlyOwner returns (bool success) {
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverPresaleFuelBalance(_batchOfAddresses[i], _amountOfFuel[i]);            
        }
        return true;
    }

     
     
    function deliverPresaleFuelBalance(address _accountHolder, uint _amountOfBoughtFuel) internal onlyOwner {
        require(presaleAmountRemaining > 0);
        addToBalance(_accountHolder, _amountOfBoughtFuel);
        Transfer(0x0, _accountHolder, _amountOfBoughtFuel);
        presaleAmountRemaining = presaleAmountRemaining.sub(_amountOfBoughtFuel);    
    }

     
    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }

     
    function decrementBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].sub(_amount);
    }
}