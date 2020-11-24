 

pragma solidity ^0.4.18;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;


    function MultiOwners() {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() constant returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function checkOwner(address maybe_owner) constant returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) onlyOwner {
        owners[_owner] = true;
        AccessGrant(_owner);
    }

    function revoke(address _owner) onlyOwner {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}

contract Haltable is MultiOwners {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

contract TripleAlphaCrowdsale is MultiOwners, Haltable {
    using SafeMath for uint256;

     
     
    uint256 public rateETHUSD = 300e2;

     
    uint256 public minimalTokens = 1e18;

     
    TripleAlphaToken public token;

     
    address public wallet;


     
     
    uint256 public periodPreITO_mainCapInUSD = 1000000e2;

     
    uint256 public periodPreITO_hardCapInUSD = periodPreITO_mainCapInUSD;

     
    uint256 public periodPreITO_period = 30 days;

     
    uint256 public periodPreITO_tokenPriceUSD = 50;

     
    uint256 public periodPreITO_weiPerToken = periodPreITO_tokenPriceUSD.mul(1 ether).div(rateETHUSD);
    
     
    uint256 public periodPreITO_startTime;
    uint256 public periodPreITO_endTime;

     
    uint256 public periodPreITO_wei;

     
    uint256 public periodPreITO_mainCapInWei = periodPreITO_mainCapInUSD.mul(1 ether).div(rateETHUSD);
     
    uint256 public periodPreITO_hardCapInWei = periodPreITO_mainCapInWei;


     
     
    uint256 public periodITO_softCapInUSD = 1000000e2;

     
    uint256 public periodITO_mainCapInUSD = 8000000e2;

    uint256 public periodITO_period = 60 days;

     
    uint256 public periodITO_hardCapInUSD = periodITO_softCapInUSD + periodITO_mainCapInUSD;

     
    uint256 public periodITO_tokenPriceUSD = 100;

     
    uint256 public periodITO_weiPerToken = periodITO_tokenPriceUSD.mul(1 ether).div(rateETHUSD);

     
    uint256 public periodITO_startTime;
    uint256 public periodITO_endTime;

     
    uint256 public periodITO_wei;
    
     
    bool public refundAllowed = false;

     
    mapping(address => uint256) public received_ethers;


     
    uint256 public periodITO_mainCapInWei = periodITO_mainCapInUSD.mul(1 ether).div(rateETHUSD);

     
    uint256 public periodITO_softCapInWei = periodITO_softCapInUSD.mul(1 ether).div(rateETHUSD);

     
    uint256 public periodITO_hardCapInWei = periodITO_softCapInWei + periodITO_mainCapInWei;


     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event OddMoney(address indexed beneficiary, uint256 value);
    event SetPeriodPreITO_startTime(uint256 new_startTimePeriodPreITO);
    event SetPeriodITO_startTime(uint256 new_startTimePeriodITO);

    modifier validPurchase() {
        bool nonZeroPurchase = msg.value != 0;

        require(withinPeriod() && nonZeroPurchase);

        _;        
    }

    modifier isExpired() {
        require(now > periodITO_endTime);

        _;        
    }

     
    function withinPeriod() constant returns(bool res) {
        bool withinPeriodPreITO = (now >= periodPreITO_startTime && now <= periodPreITO_endTime);
        bool withinPeriodITO = (now >= periodITO_startTime && now <= periodITO_endTime);
        return (withinPeriodPreITO || withinPeriodITO);
    }
    

     
    function TripleAlphaCrowdsale(uint256 _periodPreITO_startTime, uint256 _periodITO_startTime, address _wallet) {
        require(_periodPreITO_startTime >= now);
        require(_periodITO_startTime > _periodPreITO_startTime);
        require(_wallet != 0x0);

        token = new TripleAlphaToken();
        wallet = _wallet;

        setPeriodPreITO_startTime(_periodPreITO_startTime);
        setPeriodITO_startTime(_periodITO_startTime);
    }

     
    function stageName() constant public returns (string) {
        bool beforePreITO = (now < periodPreITO_startTime);
        bool withinPreITO = (now >= periodPreITO_startTime && now <= periodPreITO_endTime);
        bool betweenPreITOAndITO = (now >= periodPreITO_endTime && now <= periodITO_startTime);
        bool withinITO = (now >= periodITO_startTime && now <= periodITO_endTime);

        if(beforePreITO) {
            return 'Not started';
        }

        if(withinPreITO) {
            return 'Pre-ITO';
        } 

        if(betweenPreITOAndITO) {
            return 'Between Pre-ITO and ITO';
        }

        if(withinITO) {
            return 'ITO';
        }

        return 'Finished';
    }

     
    function totalWei() public constant returns(uint256) {
        return periodPreITO_wei + periodITO_wei;
    }
    
    function totalEther() public constant returns(uint256) {
        return totalWei().div(1e18);
    }

     
    function setPeriodPreITO_startTime(uint256 _at) onlyOwner {
        require(periodPreITO_startTime == 0 || block.timestamp < periodPreITO_startTime);  
        require(block.timestamp < _at);  
        require(periodITO_startTime == 0 || _at < periodITO_startTime);  

        periodPreITO_startTime = _at;
        periodPreITO_endTime = periodPreITO_startTime.add(periodPreITO_period);
        SetPeriodPreITO_startTime(_at);
    }

     
    function setPeriodITO_startTime(uint256 _at) onlyOwner {
        require(periodITO_startTime == 0 || block.timestamp < periodITO_startTime);  
        require(block.timestamp < _at);  
        require(periodPreITO_endTime < _at);  

        periodITO_startTime = _at;
        periodITO_endTime = periodITO_startTime.add(periodITO_period);
        SetPeriodITO_startTime(_at);
    }

    function periodITO_softCapReached() internal returns (bool) {
        return periodITO_wei >= periodITO_softCapInWei;
    }

     
    function() payable {
        return buyTokens(msg.sender);
    }

     
    function calcAmountAt(uint256 _value, uint256 _at) constant public returns (uint256, uint256) {
        uint256 estimate;
        uint256 odd;

        if(_at < periodPreITO_endTime) {
            if(_value.add(periodPreITO_wei) > periodPreITO_hardCapInWei) {
                odd = _value.add(periodPreITO_wei).sub(periodPreITO_hardCapInWei);
                _value = periodPreITO_hardCapInWei.sub(periodPreITO_wei);
            } 
            estimate = _value.mul(1 ether).div(periodPreITO_weiPerToken);
            require(_value + periodPreITO_wei <= periodPreITO_hardCapInWei);
        } else {
            if(_value.add(periodITO_wei) > periodITO_hardCapInWei) {
                odd = _value.add(periodITO_wei).sub(periodITO_hardCapInWei);
                _value = periodITO_hardCapInWei.sub(periodITO_wei);
            }             
            estimate = _value.mul(1 ether).div(periodITO_weiPerToken);
            require(_value + periodITO_wei <= periodITO_hardCapInWei);
        }

        return (estimate, odd);
    }

     
    function buyTokens(address contributor) payable stopInEmergency validPurchase public {
        uint256 amount;
        uint256 odd_ethers;
        bool transfer_allowed = true;
        
        (amount, odd_ethers) = calcAmountAt(msg.value, now);
  
        require(contributor != 0x0) ;
        require(minimalTokens <= amount);

        token.mint(contributor, amount);
        TokenPurchase(contributor, msg.value, amount);

        if(now < periodPreITO_endTime) {
             
            periodPreITO_wei = periodPreITO_wei.add(msg.value);

        } else {
             
            if(periodITO_softCapReached()) {
                periodITO_wei = periodITO_wei.add(msg.value).sub(odd_ethers);
            } else if(this.balance >= periodITO_softCapInWei) {
                periodITO_wei = this.balance.sub(odd_ethers);
            } else {
                received_ethers[contributor] = received_ethers[contributor].add(msg.value);
                transfer_allowed = false;
            }
        }

        if(odd_ethers > 0) {
            require(odd_ethers < msg.value);
            OddMoney(contributor, odd_ethers);
            contributor.transfer(odd_ethers);
        }

        if(transfer_allowed) {
            wallet.transfer(this.balance);
        }
    }

     
    function refund() isExpired public {
        require(refundAllowed);
        require(!periodITO_softCapReached());
        require(received_ethers[msg.sender] > 0);
        require(token.balanceOf(msg.sender) > 0);

        uint256 current_balance = received_ethers[msg.sender];
        received_ethers[msg.sender] = 0;
        token.burn(msg.sender);
        msg.sender.transfer(current_balance);
    }

     
    function finishCrowdsale() onlyOwner public {
        require(now > periodITO_endTime || periodITO_wei == periodITO_hardCapInWei);
        require(!token.mintingFinished());

        if(periodITO_softCapReached()) {
            token.finishMinting(true);
        } else {
            refundAllowed = true;
            token.finishMinting(false);
        }
   }

     
    function running() constant public returns (bool) {
        return withinPeriod() && !token.mintingFinished();
    }
}

contract TripleAlphaToken is MintableToken {

    string public constant name = 'Triple Alpha Token';
    string public constant symbol = 'TRIA';
    uint8 public constant decimals = 18;
    bool public transferAllowed;

    event Burn(address indexed from, uint256 value);
    event TransferAllowed(bool);

    modifier canTransfer() {
        require(mintingFinished && transferAllowed);
        _;        
    }

    function transferFrom(address from, address to, uint256 value) canTransfer returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) canTransfer returns (bool) {
        return super.transfer(to, value);
    }

    function finishMinting(bool _transferAllowed) onlyOwner returns (bool) {
        transferAllowed = _transferAllowed;
        TransferAllowed(_transferAllowed);
        return super.finishMinting();
    }

    function burn(address from) onlyOwner returns (bool) {
        Transfer(from, 0x0, balances[from]);
        Burn(from, balances[from]);

        balances[0x0] += balances[from];
        balances[from] = 0;
    }
}