 

pragma solidity ^0.4.18;

 
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


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
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


 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


contract PreSaleToken is MintableToken,PausableToken,Destructible {
  string public name = "Helbiz Genesis";
  string public symbol = "HBG";
  uint256 public decimals = 18;
}

contract PreSaleHelbiz is Ownable,Destructible{
    using SafeMath for uint256;
    PreSaleToken public token;
    mapping (address => uint256) public tokenHoldersToClaim;  
    mapping (address => uint256) public tokenHoldersTotal;  
    mapping (address => uint256) public tokenHoldersClaimed;  
    address[] tokenHolders;  
    bool public isReady;
    
    event AddedTokenHolder(address holder, uint256 amount);
    event RemovedTokenHolder(address holder);
    event Claimed(address holder, uint256 amount);
    event StartClaim();
    event EndClaim();
    
    modifier canClaim(){
        require(isReady);
        _;
    }
    
    function PreSaleHelbiz() public{
        token=new PreSaleToken();
        token.pause();
        isReady=false;
    }
    
    function () payable canClaim public{
        require(msg.value == 0);
        claim();
    }
    
    function startClaim() onlyOwner public{
        require(!isReady);
        isReady=true;
        StartClaim();
    }
    
    function endClaim() onlyOwner public{
        require(isReady);
        isReady=false;
        EndClaim();
    }
    
     
    function getCountHolder() view public returns(uint){
        return tokenHolders.length;
    }
    
    function getHolderAtIndex(uint i) view public  returns(address){
        return tokenHolders[i];
    } 
    
    function balanceOfHolder(address add) view public  returns(uint256){
        return token.balanceOf(add);
    }  
    
    function addHolder(address add, uint256 amount) onlyOwner public{
         
         
         
        tokenHoldersToClaim[add]=amount;
        tokenHoldersTotal[add]=tokenHoldersClaimed[add]+amount;
        AddedTokenHolder(add,amount);
    }

    
    function claim() private{
        var amount=tokenHoldersToClaim[msg.sender];
        if(amount>0){
            tokenHoldersToClaim[msg.sender]=0;
            token.mint(msg.sender,amount*10**token.decimals());
            tokenHoldersClaimed[msg.sender]+=amount;
            tokenHolders.push(msg.sender);
            Claimed(msg.sender,amount);
        }
    }
	
	function preAssign(address add) onlyOwner public{
        var amount=tokenHoldersToClaim[add];
        if(amount>0){
            tokenHoldersToClaim[add]=0;
            token.mint(add,amount*10**token.decimals());
            tokenHoldersClaimed[add]+=amount;
            tokenHolders.push(add);
            Claimed(add,amount);
        }
    }
    
    function transferTokenOwnership() onlyOwner public{
        token.transferOwnership(owner);
    }
    
     
    function destroy() onlyOwner public {
        token.destroy();
        super.destroy();
    }
    
     
    function destroyAndSend(address _recipient) onlyOwner public {
        token.destroyAndSend(_recipient);
        super.destroyAndSend(_recipient);
     }

    
}