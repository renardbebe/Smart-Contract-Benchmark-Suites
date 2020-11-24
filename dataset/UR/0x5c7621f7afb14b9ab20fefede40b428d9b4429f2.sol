 

pragma solidity ^0.4.19;

 

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

contract Pausable is ERC20Basic {

    uint public constant startPreICO = 1516525200;
    uint public constant endPreICO = startPreICO + 30 days;
    
    uint public constant startICOStage1 = 1520931600;
    uint public constant endICOStage1 = startICOStage1 + 15 days;
    
    uint public constant startICOStage2 = endICOStage1;
    uint public constant endICOStage2 = startICOStage2 + 15 days;
    
    uint public constant startICOStage3 = endICOStage2;
    uint public constant endICOStage3 = startICOStage3 + 15 days;
    
    uint public constant startICOStage4 = endICOStage3;
    uint public constant endICOStage4 = startICOStage4 + 15 days;

   
  modifier whenNotPaused() {
    require(now < startPreICO || now > endICOStage4);
    _;
  }

}

 
contract BasicToken is Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
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

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
  
}

contract Gelios is Ownable, StandardToken {
    using SafeMath for uint256;

    string public constant name = "Gelios Token";
    string public constant symbol = "GLS";
    uint256 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 16808824 ether;
    address public tokenWallet;
    address public multiSig;

    uint256 public tokenRate = 1000;  

    function Gelios(address _tokenWallet, address _multiSig) {
        tokenWallet = _tokenWallet;
        multiSig = _multiSig;
        totalSupply = INITIAL_SUPPLY;
        balances[_tokenWallet] = INITIAL_SUPPLY;
    }

    function () payable public {
        require(now >= startPreICO);
        buyTokens(msg.value);
    }

    function buyTokensBonus(address bonusAddress) public payable {
        require(now >= startPreICO && now < endICOStage4);
        if (bonusAddress != 0x0 && msg.sender != bonusAddress) {
            uint bonus = msg.value.mul(tokenRate).div(100).mul(5);
            if(buyTokens(msg.value)) {
               sendTokensRef(bonusAddress, bonus);
            }
        }
    }

    uint preIcoCap = 1300000 ether;
    uint icoStage1Cap = 600000 ether;
    uint icoStage2Cap = 862500 ether;
    uint icoStage3Cap = 810000 ether;
    uint icoStage4Cap = 5000000 ether;
    
    struct Stats {
        uint preICO;
        uint preICOETHRaised;
        
        uint ICOStage1;
        uint ICOStage1ETHRaised;
        
        uint ICOStage2;
        uint ICOStage2ETHRaised;
        
        uint ICOStage3;
        uint ICOStage3ETHRaised;
        
        uint ICOStage4;
        uint ICOStage4ETHRaised;
        
        uint RefBonusese;
    }
    
    event Burn(address indexed burner, uint256 value);
    
    Stats public stats;
    uint public burnAmount = preIcoCap;
    bool[] public burnStage = [true, true, true, true];

    function buyTokens(uint amount) private returns (bool){
         
         
         
         
         
        
        uint tokens = amount.mul(tokenRate);
        if(now >= startPreICO && now < endPreICO && stats.preICO < preIcoCap) {
            tokens = tokens.add(tokens.div(100).mul(30));
            tokens = safeSend(tokens, preIcoCap.sub(stats.preICO));
            stats.preICO = stats.preICO.add(tokens);
            stats.preICOETHRaised = stats.preICOETHRaised.add(amount);
            burnAmount = burnAmount.sub(tokens);
            
            return true;
        } else if (now >= startICOStage1 && now < endICOStage1 && stats.ICOStage1 < icoStage1Cap) {
            if (burnAmount > 0 && burnStage[0]) {
                burnTokens();
                burnStage[0] = false;
                burnAmount = icoStage1Cap;
            }
            
            tokens = tokens.add(tokens.div(100).mul(20));
            tokens = safeSend(tokens, icoStage1Cap.sub(stats.ICOStage1));
            stats.ICOStage1 = stats.ICOStage1.add(tokens);
            stats.ICOStage1ETHRaised = stats.ICOStage1ETHRaised.add(amount);
            burnAmount = burnAmount.sub(tokens);

            return true;
        } else if ( now < endICOStage2 && stats.ICOStage2 < icoStage2Cap ) {
            if (burnAmount > 0 && burnStage[1]) {
                burnTokens();
                burnStage[1] = false;
                burnAmount = icoStage2Cap;
            }
            
            tokens = tokens.add(tokens.div(100).mul(15));
            tokens = safeSend(tokens, icoStage2Cap.sub(stats.ICOStage2));
            stats.ICOStage2 = stats.ICOStage2.add(tokens);
            stats.ICOStage2ETHRaised = stats.ICOStage2ETHRaised.add(amount);
            burnAmount = burnAmount.sub(tokens);
            
            return true;
        } else if ( now < endICOStage3 && stats.ICOStage3 < icoStage3Cap ) {
            if (burnAmount > 0 && burnStage[2]) {
                burnTokens();
                burnStage[2] = false;
                burnAmount = icoStage3Cap;
            }
            
            tokens = tokens.add(tokens.div(100).mul(8));
            tokens = safeSend(tokens, icoStage3Cap.sub(stats.ICOStage3));
            stats.ICOStage3 = stats.ICOStage3.add(tokens);
            stats.ICOStage3ETHRaised = stats.ICOStage3ETHRaised.add(amount);
            burnAmount = burnAmount.sub(tokens);
            
            return true;
        } else if ( now < endICOStage4 && stats.ICOStage4 < icoStage4Cap ) {
            if (burnAmount > 0 && burnStage[3]) {
                burnTokens();
                burnStage[3] = false;
                burnAmount = icoStage4Cap;
            }
            
            tokens = safeSend(tokens, icoStage4Cap.sub(stats.ICOStage4));
            stats.ICOStage4 = stats.ICOStage4.add(tokens);
            stats.ICOStage4ETHRaised = stats.ICOStage4ETHRaised.add(amount);
            burnAmount = burnAmount.sub(tokens);
            
            return true;
        } else if (now > endICOStage4 && burnAmount > 0) {
            burnTokens();
            msg.sender.transfer(msg.value);
            burnAmount = 0;
        } else {
            revert();
        }
    }
    
     
    function burnTokens() private {
        balances[tokenWallet] = balances[tokenWallet].sub(burnAmount);
        totalSupply = totalSupply.sub(burnAmount);
        Burn(tokenWallet, burnAmount);
    }

     
    function safeSend(uint tokens, uint stageLimmit) private returns(uint) {
        if (stageLimmit < tokens) {
            uint toReturn = tokenRate.mul(tokens.sub(stageLimmit));
            sendTokens(msg.sender, stageLimmit);
            msg.sender.transfer(toReturn);
            return stageLimmit;
        } else {
            sendTokens(msg.sender, tokens);
            return tokens;
        }
    }

     
    function sendTokens(address _to, uint tokens) private {
        balances[tokenWallet] = balances[tokenWallet].sub(tokens);
        balances[_to] += tokens;
        Transfer(tokenWallet, _to, tokens);
        multiSig.transfer(msg.value);
    }
    
         
    function sendTokensRef(address _to, uint tokens) private {
        balances[tokenWallet] = balances[tokenWallet].sub(tokens);
        balances[_to] += tokens;
        Transfer(tokenWallet, _to, tokens);
        stats.RefBonusese += tokens; 
    }
    
     
    function updateTokenRate(uint newRate) onlyOwner public {
        tokenRate = newRate;
    }
    
}