 

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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract RECORDToken is MintableToken, BurnableToken, Pausable {
    using SafeMath for uint256;
    string public name = "RECORD";
    string public symbol = "RCD";
    uint256 public decimals = 18;

    mapping (address => bool) public lockedAddresses;

    function isAddressLocked(address _adr) internal returns (bool) {
        if (lockedAddresses[_adr] == true) {
            return true;
        } else {
            return false;
        }
    }
    function lockAddress(address _adr) onlyOwner public {
        lockedAddresses[_adr] = true;
    }
    function unlockAddress(address _adr) onlyOwner public {
        delete lockedAddresses[_adr];
    }
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        lockAddress(_to);
        return super.mint(_to, _amount);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_to) == false);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_from) == false);
        require(isAddressLocked(_to) == false);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(isAddressLocked(_spender) == false);
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        require(isAddressLocked(_spender) == false);
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        require(isAddressLocked(_spender) == false);
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 

 
contract RECORDICO {
     
    RECORDToken public RCD = new RECORDToken();
    using SafeMath for uint256;

     
     
    uint256 public Rate_Eth = 690;  

     
    uint256 public currentInitPart = 0;
    uint256 public constant RECORDPart = 18;  
    uint256 public constant EcosystemPart = 15;  
    uint256 public constant InvestorPart = 5;  
    uint256 public constant AdvisorPart = 8;  
    uint256 public constant BountyPart = 4;  
    uint256 public constant icoPart = 50;  
    uint256 public constant PreSaleHardCap = 15000000 * 1e18;
    uint256 public constant RoundAHardCap = 45000000 * 1e18;
    uint256 public constant RoundBHardCap = 45000000 * 1e18;
    uint256 public constant RoundCHardCap = 45000000 * 1e18;
    uint256 public constant totalAmountOnICO = 300000000 * 1e18;

    uint256 public PreSaleSold = 0;
    uint256 public RoundASold = 0;
    uint256 public RoundBSold = 0;
    uint256 public RoundCSold = 0;
    uint256 public EthGet = 0;
    uint256 public RcdGet = 0;

     
    address Company;
    address Manager;  

    uint256 public PreSaleStartTime;
    uint256 public PreSaleCloseTime;
    uint256 public IcoStartTime;
    uint256 public IcoCloseTime;

     
    modifier managerOnly {
        require(msg.sender == Manager);
        _;
    }

     
    function RECORDICO(
        address _Company,
        address _Manager,
        uint256 _PreSaleStartTime,
        uint256 _PreSaleCloseTime,
        uint256 _IcoStartTime,
        uint256 _IcoCloseTime
    )
    public {
        Company = _Company;
        Manager = _Manager;
        PreSaleStartTime = _PreSaleStartTime;
        PreSaleCloseTime = _PreSaleCloseTime;
        IcoStartTime = _IcoStartTime;
        IcoCloseTime = _IcoCloseTime;
        RCD.pause();  
    }

    function getMinMaxInvest() public returns(uint256, uint256) {
        uint256 _min = 0;
        uint256 _max = 0;
        uint256 stage = getStage();
        if (stage == 1) {
            _min = 5000 * 1e18;
            _max = 10000000 * 1e18;
        } else if (stage == 3 || stage == 4 || stage == 5) {
            _min = 5000 * 1e18;
            _max = 50000000 * 1e18;
        }
        return (_min, _max);
    }
    function getRcdExchange(uint256 _ethValue) public returns(uint256, bool) {
        uint256 stage = getStage();
        uint256 _rcdValue = 0;
        uint256 _usdValue = _ethValue.mul(Rate_Eth);
        uint256 _rcdValue_Numerator = _usdValue.mul(1000);
        bool exchangeSuccess = false;
        if (stage == 1 || stage == 3 || stage == 4 || stage == 5 || stage == 6) {
            if (stage == 1) {
                _rcdValue = _rcdValue_Numerator.div(80);
            } else if (stage == 3) {
                _rcdValue = _rcdValue_Numerator.div(90);
            } else if (stage == 4) {
                _rcdValue = _rcdValue_Numerator.div(95);
            } else if (stage == 5) {
                _rcdValue = _rcdValue_Numerator.div(100);
            } else {
                _rcdValue = 0;
            }
        }
        if (_rcdValue > 0) {
            exchangeSuccess = true;
        }
        return (_rcdValue, exchangeSuccess);
    }
    function getStage() public returns(uint256) {
         
         
         
         
         
         
         
         
        if (now < PreSaleStartTime) {
            return 0;
        }
         
        if (PreSaleStartTime <= now && now <= PreSaleCloseTime) {
            if (PreSaleSold < PreSaleHardCap) {
                return 1;
            } else {
                return 2;
            }
        }
         
        if (PreSaleCloseTime <= now && now <= IcoStartTime) {
            return 2;
        }
         
        if (IcoStartTime <= now && now <= IcoCloseTime) {
             
            if (RoundASold < RoundAHardCap) {
                return 3;
            }
             
            else if (RoundAHardCap <= RoundASold && RoundBSold < RoundBHardCap) {
                return 4;
            }
             
            else if (RoundBHardCap <= RoundBSold && RoundCSold < RoundCHardCap) {
                return 5;
            }
             
            else {
                return 6;
            }
        }
         
        if (IcoCloseTime < now) {
            return 6;
        }
        return 10;
    }

     
    function setRate(uint256 _RateEth) external managerOnly {
        Rate_Eth = _RateEth;
    }
    function setIcoCloseTime(uint256 _IcoCloseTime) external managerOnly {
        IcoCloseTime = _IcoCloseTime;
    }

    function lockAddress(address _adr) managerOnly external {
        RCD.lockAddress(_adr);
    }

    function unlockAddress(address _adr) managerOnly external {
        RCD.unlockAddress(_adr);
    }

     
    function unfreeze() external managerOnly {
        RCD.unpause();
    }

     
    function freeze() external managerOnly {
        RCD.pause();
    }

     
    function() external payable {
        buyTokens(msg.sender, msg.value);
    }
     
    function buyTokens(address _investor, uint256 _ethValue) internal {
        uint256 _rcdValue;
        bool _rcdExchangeSuccess;
        uint256 _min;
        uint256 _max;

        (_rcdValue, _rcdExchangeSuccess) = getRcdExchange(_ethValue);
        (_min, _max) = getMinMaxInvest();
        require (
            _rcdExchangeSuccess == true &&
            _min <= _rcdValue &&
            _rcdValue <= _max
        );
        mintICOTokens(_investor, _rcdValue, _ethValue);
    }
    function mintICOTokens(address _investor, uint256 _rcdValue, uint256 _ethValue) internal{
        uint256 stage = getStage();
        require (
            stage == 1 ||
            stage == 3 ||
            stage == 4 ||
            stage == 5
        );
        if (stage == 1) {
            require(PreSaleSold.add(_rcdValue) <= PreSaleHardCap);
            PreSaleSold = PreSaleSold.add(_rcdValue);
        }
        if (stage == 3) {
            if (RoundASold.add(_rcdValue) <= RoundAHardCap) {
                RoundASold = RoundASold.add(_rcdValue);
            } else {
                RoundBSold = RoundASold.add(_rcdValue) - RoundAHardCap;
                RoundASold = RoundAHardCap;
            }
        }
        if (stage == 4) {
            if (RoundBSold.add(_rcdValue) <= RoundBHardCap) {
                RoundBSold = RoundBSold.add(_rcdValue);
            } else {
                RoundCSold = RoundBSold.add(_rcdValue) - RoundBHardCap;
                RoundBSold = RoundBHardCap;
            }
        }
        if (stage == 5) {
            require(RoundCSold.add(_rcdValue) <= RoundCHardCap);
            RoundCSold = RoundCSold.add(_rcdValue);
        }
        RCD.mint(_investor, _rcdValue);
        RcdGet = RcdGet.add(_rcdValue);
        EthGet = EthGet.add(_ethValue);
    }

    function mintICOTokensFromExternal(address _investor, uint256 _rcdValue) external managerOnly{
        mintICOTokens(_investor, _rcdValue, 0);
    }

     
    function withdrawEther() external managerOnly{
        Company.transfer(address(this).balance);
    }

    function mintInitialTokens(address _adr, uint256 rate) external managerOnly {
        require (currentInitPart.add(rate) <= 50);
        RCD.mint(_adr, rate.mul(totalAmountOnICO).div(100));
        currentInitPart = currentInitPart.add(rate);
    }

    function transferOwnership(address newOwner) external managerOnly{
        RCD.transferOwnership(newOwner);
    }
}