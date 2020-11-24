 

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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract Certifier {
    event Confirmed(address indexed who);
    event Revoked(address indexed who);
    function certified(address) public constant returns (bool);
    function get(address, string) public constant returns (bytes32);
    function getAddress(address, string) public constant returns (address);
    function getUint(address, string) public constant returns (uint);
}

contract EDUToken is StandardToken {

    using SafeMath for uint256;

    Certifier public certifier;

     
    event CreatedEDU(address indexed _creator, uint256 _amountOfEDU);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     
    string public constant name = "EDU Token";
    string public constant symbol = "EDU";
    uint256 public constant decimals = 4;
    string public version = "1.0";

     
     
    uint256 public constant TotalEDUSupply = 48000000*10000;                     
    uint256 public constant maxEarlyPresaleEDUSupply = 2601600*10000;            
    uint256 public constant maxPresaleEDUSupply = 2198400*10000;                 
    uint256 public constant OSUniEDUSupply = 8400000*10000;                      
    uint256 public constant SaleEDUSupply = 30000000*10000;                      
    uint256 public constant sigTeamAndAdvisersEDUSupply = 3840000*10000;         
    uint256 public constant sigBountyProgramEDUSupply = 960000*10000;            

     
     
    uint256 public preSaleStartTime;                                             
    uint256 public preSaleEndTime;                                               
    uint256 public saleStartTime;                                                
    uint256 public saleEndTime;                                                  

     
    uint256 public earlyPresaleEDUSupply;
    uint256 public PresaleEDUSupply;

     
    uint256 public EDU_KYC_BONUS = 50*10000;                                     

     
    uint256 public LockEDUTeam;                                                  

     
    uint256 public EDU_PER_ETH_EARLY_PRE_SALE = 1350;                            
    uint256 public EDU_PER_ETH_PRE_SALE = 1200;                                  

     
    uint256 public EDU_PER_ETH_SALE;                                             

     
    address public ownerAddress;                                                 
    address public presaleAddress;                                               
    address public saleAddress;                                                  
    address public sigTeamAndAdvisersAddress;                                    
    address public sigBountyProgramAddress;                                      
    address public contributionsAddress;                                         

     
    bool public allowContribution = true;                                        

     
    uint256 public totalWEIInvested = 0;                                         
    uint256 public totalEDUSLeft = 0;                                            
    uint256 public totalEDUSAllocated = 0;                                       
    mapping (address => uint256) public WEIContributed;                          

     
    mapping(address => mapping (address => uint256)) allowed;

     
    modifier onlyOwner() {
        if (msg.sender != ownerAddress) {
            revert();
        }
        _;
    }

     
    modifier minimalContribution() {
        require(500000000000000000 <= msg.value);
        _;
    }

     
    modifier freezeDuringEDUtokenSale() {
        if ( (msg.sender == ownerAddress) ||
             (msg.sender == contributionsAddress) ||
             (msg.sender == presaleAddress) ||
             (msg.sender == saleAddress) ||
             (msg.sender == sigBountyProgramAddress) ) {
            _;
        } else {
            if((block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) || (block.timestamp > saleStartTime && block.timestamp < saleEndTime)) {
                revert();
            } else {
                _;
            }
        }
    }

     
    modifier freezeTeamAndAdvisersEDUTokens(address _address) {
        if (_address == sigTeamAndAdvisersAddress) {
            if (LockEDUTeam > block.timestamp) { revert(); }
        }
        _;
    }

     
    function EDUToken(
        address _presaleAddress,
        address _saleAddress,
        address _sigTeamAndAdvisersAddress,
        address _sigBountyProgramAddress,
        address _contributionsAddress
    ) {
        certifier = Certifier(0x1e2F058C43ac8965938F6e9CA286685A3E63F24E);
        ownerAddress = msg.sender;                                                                
        presaleAddress = _presaleAddress;                                                         
        saleAddress = _saleAddress;
        sigTeamAndAdvisersAddress = _sigTeamAndAdvisersAddress;                                   
        sigBountyProgramAddress = _sigBountyProgramAddress;
        contributionsAddress = _contributionsAddress;

        preSaleStartTime = 1511179200;                                                            
        preSaleEndTime = 1514764799;                                                              
        LockEDUTeam = preSaleEndTime + 1 years;                                                   

        earlyPresaleEDUSupply = maxEarlyPresaleEDUSupply;                                         
        PresaleEDUSupply = maxPresaleEDUSupply;                                                   

        balances[contributionsAddress] = OSUniEDUSupply;                                          
        balances[presaleAddress] = SafeMath.add(maxPresaleEDUSupply, maxEarlyPresaleEDUSupply);   
        balances[saleAddress] = SaleEDUSupply;                                                    
        balances[sigTeamAndAdvisersAddress] = sigTeamAndAdvisersEDUSupply;                        
        balances[sigBountyProgramAddress] = sigBountyProgramEDUSupply;                            


        totalEDUSAllocated = OSUniEDUSupply + sigTeamAndAdvisersEDUSupply + sigBountyProgramEDUSupply;
        totalEDUSLeft = SafeMath.sub(TotalEDUSupply, totalEDUSAllocated);                         

        totalSupply = TotalEDUSupply;                                                             
    }

     
    function()
        payable
        minimalContribution
    {
        require(allowContribution);

         
        if (!certifier.certified(msg.sender)) {
            revert();
        }

         
        uint256 amountInWei = msg.value;

         
        uint256 amountOfEDU = 0;

        if (block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) {
            amountOfEDU = amountInWei.mul(EDU_PER_ETH_EARLY_PRE_SALE).div(100000000000000);
            if(!(WEIContributed[msg.sender] > 0)) {
                amountOfEDU += EDU_KYC_BONUS;   
            }
            if (earlyPresaleEDUSupply > 0 && earlyPresaleEDUSupply >= amountOfEDU) {
                require(updateEDUBalanceFunc(presaleAddress, amountOfEDU));
                earlyPresaleEDUSupply = earlyPresaleEDUSupply.sub(amountOfEDU);
            } else if (PresaleEDUSupply > 0) {
                if (earlyPresaleEDUSupply != 0) {
                    PresaleEDUSupply = PresaleEDUSupply.add(earlyPresaleEDUSupply);
                    earlyPresaleEDUSupply = 0;
                }
                amountOfEDU = amountInWei.mul(EDU_PER_ETH_PRE_SALE).div(100000000000000);
                if(!(WEIContributed[msg.sender] > 0)) {
                    amountOfEDU += EDU_KYC_BONUS;
                }
                require(PresaleEDUSupply >= amountOfEDU);
                require(updateEDUBalanceFunc(presaleAddress, amountOfEDU));
                PresaleEDUSupply = PresaleEDUSupply.sub(amountOfEDU);
            } else {
                revert();
            }
        } else if (block.timestamp > saleStartTime && block.timestamp < saleEndTime) {
             
            amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE).div(100000000000000);
            require(totalEDUSLeft >= amountOfEDU);
            require(updateEDUBalanceFunc(saleAddress, amountOfEDU));
        } else {
             
            revert();
        }

         
        totalWEIInvested = totalWEIInvested.add(amountInWei);
        assert(totalWEIInvested > 0);
         
        uint256 contributedSafe = WEIContributed[msg.sender].add(amountInWei);
        assert(contributedSafe > 0);
        WEIContributed[msg.sender] = contributedSafe;

         
        contributionsAddress.transfer(amountInWei);

         
        CreatedEDU(msg.sender, amountOfEDU);
    }

     
    function updateEDUBalanceFunc(address _from, uint256 _amountOfEDU) internal returns (bool) {
         
        totalEDUSLeft = totalEDUSLeft.sub(_amountOfEDU);
        totalEDUSAllocated += _amountOfEDU;

         
        if (totalEDUSAllocated <= TotalEDUSupply && totalEDUSAllocated > 0) {
             
            uint256 balanceSafe = balances[msg.sender].add(_amountOfEDU);
            assert(balanceSafe > 0);
            balances[msg.sender] = balanceSafe;
            uint256 balanceDiv = balances[_from].sub(_amountOfEDU);
            balances[_from] = balanceDiv;
            return true;
        } else {
            totalEDUSLeft = totalEDUSLeft.add(_amountOfEDU);
            totalEDUSAllocated -= _amountOfEDU;
            return false;
        }
    }

     
    function setAllowContributionFlag(bool _allowContribution) public returns (bool success) {
        require(msg.sender == ownerAddress);
        allowContribution = _allowContribution;
        return true;
    }

     
    function setSaleTimes(uint256 _saleStartTime, uint256 _saleEndTime) public returns (bool success) {
        require(msg.sender == ownerAddress);
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        return true;
    }

     
    function setPresaleTime(uint256 _preSaleStartTime, uint256 _preSaleEndTime) public returns (bool success) {
        require(msg.sender == ownerAddress);
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
        return true;
    }

    function setEDUPrice(
        uint256 _valEarlyPresale,
        uint256 _valPresale,
        uint256 _valSale
    ) public returns (bool success) {
        require(msg.sender == ownerAddress);
        EDU_PER_ETH_EARLY_PRE_SALE = _valEarlyPresale;
        EDU_PER_ETH_PRE_SALE = _valPresale;
        EDU_PER_ETH_SALE = _valSale;
        return true;
    }

    function updateCertifier(address _address) public returns (bool success) {
        certifier = Certifier(_address);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) freezeDuringEDUtokenSale freezeTeamAndAdvisersEDUTokens(msg.sender) returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) freezeDuringEDUtokenSale freezeTeamAndAdvisersEDUTokens(_from) returns (bool success) {
        if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) freezeDuringEDUtokenSale freezeTeamAndAdvisersEDUTokens(msg.sender) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}