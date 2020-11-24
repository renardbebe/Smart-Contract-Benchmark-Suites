 

pragma solidity ^0.4.20;
 
 
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
  

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

 
contract Pausable is Ownable {
  address public saleAgent;
  address public partner;

  modifier onlyAdmin() {
    require(msg.sender == owner || msg.sender == saleAgent || msg.sender == partner);
    _;
  }

  function setSaleAgent(address newSaleAgent) onlyOwner public {
    require(newSaleAgent != address(0)); 
    saleAgent = newSaleAgent;
  }

  function setPartner(address newPartner) onlyOwner public {
    require(newPartner != address(0)); 
    partner = newPartner;
  }

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

 
contract BasicToken is ERC20Basic, Pausable {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public storageTime = 1522749600;  

  modifier checkStorageTime() {
    require(now >= storageTime);
    _;
  }

  modifier onlyPayloadSize(uint256 numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

  function setStorageTime(uint256 _time) public onlyOwner {
    storageTime = _time;
  }

   
  function transfer(address _to, uint256 _value) public
  onlyPayloadSize(2) whenNotPaused checkStorageTime returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
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

   

  function transferFrom(address _from, address _to, uint256 _value) public 
  onlyPayloadSize(3) whenNotPaused checkStorageTime returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public 
  onlyPayloadSize(2) whenNotPaused returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

    
  function increaseApproval(address _spender, uint _addedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
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

 

contract MintableToken is StandardToken{
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) public onlyAdmin whenNotPaused canMint returns  (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(this), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

 
contract BurnableToken is MintableToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public onlyPayloadSize(1) {
    require(_value <= balances[msg.sender]);
     
     
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }

  function burnFrom(address _from, uint256 _value) public 
  onlyPayloadSize(2)
  returns (bool success) {
    require(balances[_from] >= _value); 
    require(_value <= allowed[_from][msg.sender]); 
    balances[_from] = balances[_from].sub(_value);  
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);
    return true;
    }
}

contract AlttexToken is BurnableToken {
    string public constant name = "Alttex";
    string public constant symbol = "ALTX";
    uint8 public constant decimals = 8;
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    uint256 public startTimeRound1;
    uint256 public endTimeRound1;

    uint256 public startTimeRound2;
    uint256 public endTimeRound2;

     
    uint256 public rateRound1 = 1200;
    uint256 public rateRound2;

    uint256 constant dec = 10 ** 8;
    uint256 public supply = 50000000 * 10 ** 8;
    uint256 public percentTokensToSale = 60;
    uint256 public tokensToSale = supply.mul(percentTokensToSale).div(100);
     
    address public wallet;

    AlttexToken public token;
     
    uint256 public weiRaised = 17472 * 10 ** 16;  
    uint256 public minTokensToSale = 45 * dec;
     
    address public TeamAndAdvisors;
    address public Investors;

    uint256 timeBonus1 = 20;
    uint256 timeBonus2 = 10;

     
    uint256 bonus1 = 10;
    uint256 bonus2 = 15;
    uint256 bonus3 = 20;
    uint256 bonus4 = 30;

     
    uint256 amount1 = 500 * dec;
    uint256 amount2 = 1000 * dec;
    uint256 amount3 = 5000 * dec;
    uint256 amount4 = 10000 * dec;

    bool initalMinted = false;
    bool checkBonus = false;

    function Crowdsale(
        address _token,
        uint256 _startTimeRound1,  
        uint256 _startTimeRound2,  
        uint256 _endTimeRound1,  
        uint256 _endTimeRound2,  
        address _wallet,
        address _TeamAndAdvisors,
        address _Investors) public {
        require(_token != address(0));
        require(_endTimeRound1 > _startTimeRound1);
        require(_endTimeRound2 > _startTimeRound2);
        require(_wallet != address(0));
        require(_TeamAndAdvisors != address(0));
        require(_Investors != address(0));
        token = AlttexToken(_token);
        startTimeRound1 = _startTimeRound1;
        startTimeRound2 = _startTimeRound2;
        endTimeRound1 = _endTimeRound1;
        endTimeRound2 = _endTimeRound2;
        wallet = _wallet;
        TeamAndAdvisors = _TeamAndAdvisors;
        Investors = _Investors;
    }

    function initialMint() onlyOwner public {
        require(!initalMinted);
        uint256 _initialRaised = 17472 * 10 ** 16;
        uint256 _tokens = _initialRaised.mul(1500).div(10 ** 10);
        token.mint(Investors, _tokens.add(_tokens.mul(40).div(100)));
        initalMinted = true;
    }

    modifier saleIsOn() {
        uint tokenSupply = token.totalSupply();
        require(now > startTimeRound1 && now < endTimeRound2);
        require(tokenSupply <= tokensToSale);
        _;
    }

    function setPercentTokensToSale(
        uint256 _newPercentTokensToSale) onlyOwner public {
        percentTokensToSale = _newPercentTokensToSale;
    }

    function setMinTokensToSale(
        uint256 _newMinTokensToSale) onlyOwner public {
        minTokensToSale = _newMinTokensToSale;
    }

    function setCheckBonus(
        bool _newCheckBonus) onlyOwner public {
        checkBonus = _newCheckBonus;
    }

    function setAmount(
        uint256 _newAmount1,
        uint256 _newAmount2,
        uint256 _newAmount3,
        uint256 _newAmount4) onlyOwner public {
        amount1 = _newAmount1;
        amount2 = _newAmount2;
        amount3 = _newAmount3;
        amount4 = _newAmount4;
    }

    function setBonuses(
        uint256 _newBonus1,
        uint256 _newBonus2,
        uint256 _newBonus3,
        uint256 _newBonus4) onlyOwner public {
        bonus1 = _newBonus1;
        bonus2 = _newBonus2;
        bonus3 = _newBonus3;
        bonus4 = _newBonus4;
    }

    function setRoundTime(
      uint256 _newStartTimeRound2,
      uint256 _newEndTimeRound2) onlyOwner public {
      require(_newEndTimeRound2 > _newStartTimeRound2);
        startTimeRound2 = _newStartTimeRound2;
        endTimeRound2 = _newEndTimeRound2;
    }

    function setRate(uint256 _newRateRound2) public onlyOwner {
        rateRound2 = _newRateRound2;
    }

    function setTimeBonus(uint256 _newTimeBonus) public onlyOwner {
        timeBonus2 = _newTimeBonus;
    }
 
    function setTeamAddress(
        address _newTeamAndAdvisors,
        address _newInvestors,
        address _newWallet) onlyOwner public {
        require(_newTeamAndAdvisors != address(0));
        require(_newInvestors != address(0));
        require(_newWallet != address(0));
        TeamAndAdvisors = _newTeamAndAdvisors;
        Investors = _newInvestors;
        wallet = _newWallet;
    }


    function getAmount(uint256 _value) internal view returns (uint256) {
        uint256 amount = 0;
        uint256 all = 100;
        uint256 tokenSupply = token.totalSupply();
        if(now >= startTimeRound1 && now < endTimeRound1) {  
            amount = _value.mul(rateRound1);
            amount = amount.add(amount.mul(timeBonus1).div(all));
        } else if(now >= startTimeRound2 && now < endTimeRound2) {  
            amount = _value.mul(rateRound2);
            amount = amount.add(amount.mul(timeBonus2).div(all));
        } 
        require(amount >= minTokensToSale);
        require(amount != 0 && amount.add(tokenSupply) < tokensToSale);
        return amount;
    }

    function getBonus(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus3;
        } else if(_value >= amount4) {
            return bonus4;
        }
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPartners(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function buyTokens(address beneficiary) saleIsOn public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = (msg.value).div(10 ** 10);

         
        uint256 tokens = getAmount(weiAmount);

        if(checkBonus) {
          uint256 bonusNow = getBonus(tokens);
          tokens = tokens.add(tokens.mul(bonusNow).div(100));
        }
        
        weiRaised = weiRaised.add(msg.value);
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(msg.value);

        uint256 taaTokens = tokens.mul(20).div(100);
        token.mint(TeamAndAdvisors, taaTokens);
        TokenPartners(msg.sender, TeamAndAdvisors, taaTokens);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTimeRound2;
    }

    function kill() onlyOwner public { selfdestruct(owner); }
    
}