 

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

contract CompletelyDecentralizedWorld is StandardToken {
    string public constant name = "CompletelyDecentralizedWorld";
    string public constant symbol = "CDW";
    uint public constant decimals = 18;
    
    uint teamPartToken = 50000000 * (10 ** uint256(decimals));
    
    uint communityBuildingToken = 30000000 * (10 ** uint256(decimals));
    
    uint16[4] public bonusPercentages = [30,20,10,0];
    
    uint public constant NUM_OF_PHASE = 4;
    
    uint public constant BLOCK_PER_PHASE = 150000;
    
    address public constant target = 0xEAD3346C806803e1500d96B9a2D7065d0526Caf6;
  
     
    address public constant addr_teamPartToken = 0x898f9ca9cf198E059396337A7bbbBBed59856089;
    
    bool teamPartTokenIssued = false;
    
     
    address public constant addr_communityBuildingToken = 0x8E5A7df3fDbbB467a1D6feed337EC2e1938AAb3f;
    
    bool communityBuildingTokenIssued = false;
    
    uint public firstblock = 0;
    
    uint public constant HARD_CAP = 20000 ether;
    
   
    uint public constant BASE_RATE = 25000;
    
    uint public totalEthReceived = 0;
    
    uint public issueIndex = 0;
    
     
    
    event SaleStarted();
    
    event SaleEnded();
    
    event InvalidCaller(address caller);
    
    event InvalidState(bytes msg);
    
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);
    
    event SaleSucceeded();
    
    event SaleFailed();
    
     
    
    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            revert();
        }
    }
    
    modifier beforeStart {
        if (!saleStarted()) {
            _;
        } else {
            InvalidState("Sale has not started yet");
            revert();
        }
    }
    
    modifier inProgress {
        if (saleStarted() && !saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not in Progress");
            revert();
        }
    }
    
    modifier afterEnd {
        if (saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not ended yet");
            revert();
        }
    }    

 
function start(uint _firstblock) public onlyOwner beforeStart {
    if (_firstblock <= block.number) {
        revert();
    }
    
    firstblock = _firstblock;
    SaleStarted();
    issueTeamPartToken();
    issueCommunityBuildingToken();
}

function close() public onlyOwner afterEnd {
   
    issueTeamPartToken();
    issueCommunityBuildingToken();
    SaleSucceeded();
        
}

function price() public constant returns (uint tokens) {
    return computeTokenAmount(1 ether);
}

function () public payable{
    issueToken(msg.sender);
}

function issueToken(address recipient) public payable inProgress{
    assert(msg.value >= 0.01 ether);
    
    uint tokens = computeTokenAmount(msg.value);
    totalEthReceived = totalEthReceived.add(msg.value);
    totalSupply = totalSupply.add(tokens);
    balances[recipient] = balances[recipient].add(tokens);
    
    Issue(issueIndex++, recipient, msg.value, tokens);
    
    if (!target.send(msg.value)){
        revert();
    }
}

 

function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
    uint phase = (block.number - firstblock).div(BLOCK_PER_PHASE);
    if (phase >= bonusPercentages.length) {
        phase = bonusPercentages.length - 1;
    }
    
    uint tokenBase = ethAmount.mul(BASE_RATE);
    uint tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);
    tokens = tokenBase.add(tokenBonus);
}


function issueTeamPartToken() internal {
    if(teamPartTokenIssued){
        InvalidState("teamPartToken has been issued already");
    } else {
        totalSupply = totalSupply.add(teamPartToken);
        balances[addr_teamPartToken] = balances[addr_teamPartToken].add(teamPartToken);
        Issue(issueIndex++, addr_teamPartToken, 0, teamPartToken);
        teamPartTokenIssued = true;
    }
}

function issueCommunityBuildingToken() internal {
    if(communityBuildingTokenIssued){
        InvalidState("communityBuildingToken has been issued already");
    } else {
        totalSupply = totalSupply.add(communityBuildingToken);
        balances[addr_communityBuildingToken] = balances[addr_communityBuildingToken].add(communityBuildingToken);
        Issue(issueIndex++, addr_communityBuildingToken, 0, communityBuildingToken);
        communityBuildingTokenIssued = true;
    }
}

function saleStarted() public constant returns (bool) {
    return (firstblock > 0 && block.number >= firstblock);
    }

function saleEnded() public constant returns (bool) {
    return firstblock > 0 && (saleDue() || hardCapReached());
    }
 
function saleDue() public constant returns (bool) {
    return block.number >= firstblock + BLOCK_PER_PHASE*NUM_OF_PHASE;
    }

function hardCapReached() public constant returns (bool) {
    return totalEthReceived >= HARD_CAP;
    }
}