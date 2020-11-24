 

pragma solidity 0.4.25;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

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

}

 

contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }


  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
}

contract Doli is MintableToken {
    
    string public constant name = "DOLI Token";
    
    string public constant symbol = "DOLI";
    
    uint32 public constant decimals = 18;

}


contract DoliCrowdsale is Ownable {
    
    using SafeMath for uint;
    
    uint restrictedPercent;

    address restrictedAccount;

    Doli public token = new Doli();

    uint startDate;
	
	uint endDate;
    
    uint period2;
	
	uint period3;
	
	uint period4;
	
    uint rate;
   
    uint hardcap;
    
   

    constructor() public payable {
	
        restrictedAccount = 0x023770c61B9372be44bDAB41f396f8129C14c377;
        restrictedPercent = 40;
        rate = 100000000000000000000;
        startDate = 1553385600;
	    period2 = 1557446400;
		period3 = 1561420800;
		period4 = 1565395200;
		endDate = 1569369600;

        hardcap = 500000000000000000000000000;
       
    }
    modifier saleIsOn() {
    	require(now > startDate && now < endDate);
    	_;
    }
	
	modifier isUnderHardCap() {
        require(token.totalSupply() <= hardcap);
        _;
    }
    
    function finishMinting() public onlyOwner {
        uint issuedTokenSupply = token.totalSupply();
        uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
        token.mint(restrictedAccount, restrictedTokens);
        token.finishMinting();
    }
        
     
    function createTokens(address customer, uint256 value) onlyOwner saleIsOn public {
        
        uint256 tokens;
        uint bonusRate = 10;
        if (customer==owner) {
          revert();  
        }
        if(now >= startDate &&  now < period2) {
          bonusRate = 7;
        } else 
		if(now >= period2 &&  now < period3) {
          bonusRate = 8;
        } else 
		if(now >= period3 &&  now < period4) {
          bonusRate = 9;
        } if(now >= period4 &&  now < endDate) {
          bonusRate = 10;
        }
		tokens = value.mul(1 ether).mul(10).div(bonusRate); 
		token.mint(owner, tokens);
		token.transferFrom(owner, customer, tokens); 
    }
    
    function getTokensCount() public constant returns(uint256){
       return token.totalSupply().div(1 ether); }

    function getBalance(address customer) onlyOwner public constant returns(uint256){
       return token.balanceOf(customer).div(1 ether); }
	   
     function() external payable  onlyOwner {
       revert();}
}