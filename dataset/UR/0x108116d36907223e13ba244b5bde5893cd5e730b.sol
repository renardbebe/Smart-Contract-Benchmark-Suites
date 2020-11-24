 

pragma solidity ^0.4.16;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() internal {
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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant whenNotPaused returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
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

contract JubsICO is StandardToken {
    using SafeMath for uint256;

     
    string public name = "Honor";
    string public symbol = "HNR";
    uint256 public decimals = 18;
    uint256 public totalSupply = 100000000 * (10 ** decimals);  

     
    address public walletETH;                            
    address public icoWallet;                            
    address public preIcoWallet;                         
    address public teamWallet;                           
    address public bountyMktWallet;                      
    address public arbitrationWallet;                    
    address public rewardsWallet;                        
    address public advisorsWallet;                       
    address public operationWallet;                      

     
    uint256 public icoStage = 0;        
    uint256 public tokensSold = 0;                       
    uint256 public totalRaised = 0;                      
    uint256 public totalTokenToSale = 0;
    uint256 public rate = 8500;                          
    bool public pauseEmergence = false;                  
    

     
     
                                                                
 
    uint256 public icoStartTimestampStage = 1515974400;          
    uint256 public icoEndTimestampStage = 1518998399;            

     
    uint256 public icoStartTimestampStage1 = 1518998400;         
    uint256 public icoEndTimestampStage1 = 1519603199;           

     
    uint256 public icoStartTimestampStage2 = 1519603200;         
    uint256 public icoEndTimestampStage2 = 1520207999;           

     
    uint256 public icoStartTimestampStage3 = 1520208000;         
    uint256 public icoEndTimestampStage3 = 1520812799;           

     
    uint256 public icoStartTimestampStage4 = 1520812800;         
    uint256 public icoEndTimestampStage4 = 1521417599;           

     
    uint256 public teamEndTimestamp = 1579046400;                
                                                                

 

    event Burn(address indexed burner, uint256 value);  


 
       
    function JubsICO ()public {                 
       
      walletETH = 0x6eA3ec9339839924a520ff57a0B44211450A8910;
      icoWallet = 0x357ace6312BF8B519424cD3FfdBB9990634B8d3E;
      preIcoWallet = 0x7c54dC4F3328197AC89a53d4b8cDbE35a56656f7;
      teamWallet = 0x06BC5305016E9972F4cB3F6a3Ef2C734D417788a;
      bountyMktWallet = 0x6f67b977859deE77fE85cBCAD5b5bd5aD58bF068;
      arbitrationWallet = 0xdE9DE3267Cbd21cd64B40516fD2Aaeb5D77fb001;
      rewardsWallet = 0x232f7CaA500DCAd6598cAE4D90548a009dd49e6f;
      advisorsWallet = 0xA6B898B2Ab02C277Ae7242b244FB5FD55cAfB2B7;
      operationWallet = 0x96819778cC853488D3e37D630d94A337aBd527A8;

       
      balances[icoWallet] = totalSupply.mul(63).div(100);                  
      balances[preIcoWallet] = totalSupply.mul(7).div(100);                
      balances[teamWallet] = totalSupply.mul(10).div(100);                 
      balances[bountyMktWallet] = totalSupply.mul(7).div(100);             
      balances[arbitrationWallet] = totalSupply.mul(5).div(100);           
      balances[rewardsWallet] = totalSupply.mul(5).div(100);               
      balances[advisorsWallet] = totalSupply.mul(2).div(100);              
      balances[operationWallet] = totalSupply.mul(1).div(100);             

       
      pause();

       
      totalTokenToSale = balances[icoWallet].add(balances[preIcoWallet]);           
    }

  

    modifier acceptsFunds() {   
        if (icoStage == 0) {
            require(msg.value >= 1 ether);
            require(now >= icoStartTimestampStage);          
            require(now <= icoEndTimestampStage); 
        }

        if (icoStage == 1) {
            require(now >= icoStartTimestampStage1);          
            require(now <= icoEndTimestampStage1);            
        }

        if (icoStage == 2) {
            require(now >= icoStartTimestampStage2);          
            require(now <= icoEndTimestampStage2);            
        }

        if (icoStage == 3) {
            require(now >= icoStartTimestampStage3);          
            require(now <= icoEndTimestampStage3);            
        }

        if (icoStage == 4) {
            require(now >= icoStartTimestampStage4);          
            require(now <= icoEndTimestampStage4);            
        }             
               
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
        if (icoStage == 0) {
          balances[preIcoWallet] = balances[preIcoWallet].sub(amount);               
        }
        if (icoStage > 0) {
          balances[icoWallet] = balances[icoWallet].sub(amount);               
        }

        balances[recipient] = balances[recipient].add(amount);
        tokensSold = tokensSold.add(amount);        
       
         
        if (tokensSold > totalTokenToSale) {
            uint256 diferenceTotalSale = totalTokenToSale.sub(tokensSold);
            totalTokenToSale = tokensSold;
            totalSupply = tokensSold.add(diferenceTotalSale);
        }
        
        Transfer(0x0, recipient, amount);
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

    function sendTokenTeam(address _to, uint256 amount) public onlyOwner {
        require(_to != 0x0);

         
        require(now >= teamEndTimestamp);
        assignTokens(_to, amount);
    }

    function burn(uint256 _value) public whenNotPaused {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }   
    
}