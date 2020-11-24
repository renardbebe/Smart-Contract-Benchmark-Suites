 

pragma solidity ^0.4.21;


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
    constructor() public {
    owner = msg.sender;
    }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0x0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken, Pausable {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0x0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant whenNotPaused returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ludcoin is StandardToken {
    using SafeMath for uint256;

     
    string public name = "Ludcoin";
    string public symbol = "LUD";
    uint256 public decimals = 18;
    uint256 public totalSupply = 800000000 * (10 ** decimals);  

     
    address public walletETH;                
    address public contractAddress = this;   
    address public tokenSale;                
    address public company;                  
    address public bounty;                   
    address public gamesFund;                

     
    uint256 public icoStage = 0;        
    uint256 public tokensSold = 0;           
    uint256 public totalRaised = 0;          
    uint256 public totalTokenToSale = 0;
    uint256 public rate = 2700;              
    bool public pauseEmergence = false;      
    

     
    uint256 public icoStartTimestampStage = 1525132800;        
    uint256 public icoEndTimestampStage = 1543622399;          

 

    event Burn(address indexed burner, uint256 value);  


 
       
    constructor() public {         
      walletETH = 0x7573791105bfB3c0329A3a1DDa7Eb2D01B61Fb7D;
      tokenSale = 0x21f8784cA7065ad252e1401208B153d5b7a740d1;         
      company = 0x8185ae2Da7891557C622Fb23C431A9cf7DF6E457;           
      bounty = 0x80c4933a9a614e7671D52Fd218d2EB29412bf584;            
      gamesFund = 0x413cF71fB3E7dAf8c8Af21E40429E7315196E3d1;         

       
      balances[tokenSale] = totalSupply.mul(67).div(100);             
      balances[company] = totalSupply.mul(20).div(100);               
      balances[gamesFund] = totalSupply.mul(5).div(100);              
      balances[bounty] = totalSupply.mul(2).div(100);                 
      balances[contractAddress] = totalSupply.mul(6).div(100);        
      
     
       
      totalTokenToSale = balances[tokenSale];           
    }

  

    modifier acceptsFunds() {   
        require(now >= icoStartTimestampStage);          
        require(now <= icoEndTimestampStage); 
        _;
    }    

    modifier nonZeroBuy() {
        require(msg.value > 0);
        _;

    }

    modifier PauseEmergence {
        require(!pauseEmergence);
       _;
    } 

 

     
    function () PauseEmergence nonZeroBuy acceptsFunds payable public {  
        uint256 amount = msg.value.mul(rate);
        
        assignTokens(msg.sender, amount);
        totalRaised = totalRaised.add(msg.value);
        forwardFundsToWallet();
    } 

    function forwardFundsToWallet() internal {
         
        walletETH.transfer(msg.value); 
    }

    function assignTokens(address recipient, uint256 amount) internal {
        uint256 amountTotal = amount;
        
        if (icoStage > 0) {
            amountTotal = amountTotal + amountTotal.mul(2).div(100);    
        }
        
        balances[tokenSale] = balances[tokenSale].sub(amountTotal);   
        balances[recipient] = balances[recipient].add(amountTotal);
        tokensSold = tokensSold.add(amountTotal);        
       
         
        if (tokensSold > totalTokenToSale) {
            uint256 diferenceTotalSale = totalTokenToSale.sub(tokensSold);
            totalTokenToSale = tokensSold;
            totalSupply = tokensSold.add(diferenceTotalSale);
        }
        
        emit Transfer(0x0, recipient, amountTotal);
    }  

    function manuallyAssignTokens(address recipient, uint256 amount) public onlyOwner {
        require(tokensSold < totalSupply);
        assignTokens(recipient, amount);
    }

    function setRate(uint256 _rate) public onlyOwner { 
        require(_rate > 0);               
        rate = _rate;        
    }

    function setIcoStage(uint256 _icoStage) public onlyOwner {    
        require(_icoStage >= 0); 
        require(_icoStage <= 4);             
        icoStage = _icoStage;        
    }

    function setPauseEmergence() public onlyOwner {        
        pauseEmergence = true;
    }

    function setUnPauseEmergence() public onlyOwner {        
        pauseEmergence = false;
    }   

    function sendTokenTeamAdvisor(address walletTeam, address walletAdvisors ) public onlyOwner {
         
        require(now >= icoEndTimestampStage);
        require(walletTeam != 0x0);
        require(walletAdvisors != 0x0);
        
        uint256 amount = 24000000 * (10 ** decimals);
        
         
        balances[contractAddress] = 0;
        balances[walletTeam] = balances[walletTeam].add(amount);
        balances[walletAdvisors] = balances[walletAdvisors].add(amount);
        
        emit Transfer(contractAddress, walletTeam, amount);
        emit Transfer(contractAddress, walletAdvisors, amount);
    }

    function burn(uint256 _value) public whenNotPaused {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }   
    
}