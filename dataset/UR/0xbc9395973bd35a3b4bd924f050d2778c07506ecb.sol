 

pragma solidity ^0.4.15;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract GreedTokenICO is StandardToken, Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    string public name = "GREED TOKEN";
    string public symbol = "GREED";
    uint256 public decimals = 18;

    uint256 public constant EXCHANGE_RATE = 700; 
    uint256 constant TOP_MULT = 1000 * (uint256(10) ** decimals);
    uint256 public bonusMultiplier = 1000 * (uint256(10) ** decimals);
    
    uint256 public totalSupply = 3140000000 * (uint256(10) ** decimals);
    uint256 public startTimestamp = 1510398671;  
    uint256 public durationSeconds = 2682061;  

    address public icoWallet = 0xf34175829b0fc596814009df978c77b5cb47b24f;
	address public vestContract = 0xfbadbf0a1296d2da94e59d76107c61581d393196;		

    uint256 public totalRaised;  
    uint256 public totalContributors;
    uint256 public totalTokensSold;

    uint256 public icoSupply;
    uint256 public vestSupply;
    
    bool public icoOpen = false;
    bool public icoFinished = false;


    function GreedTokenICO () public {
         
        icoSupply = totalSupply.mul(10).div(100);  
        vestSupply = totalSupply.mul(90).div(100);  
        
         
         
        balances[icoWallet] = icoSupply;
        balances[vestContract] = vestSupply;
         
        Transfer(0x0, icoWallet, icoSupply);
        Transfer(0x0, vestContract, vestSupply);
    }

    function() public isIcoOpen payable {
        require(msg.value > 0);
        
        uint256 valuePlus = 50000000000000000;  
        uint256 ONE_ETH = 1000000000000000000;
        uint256 tokensLeft = balances[icoWallet];
        uint256 ethToPay = msg.value;
        uint256 tokensBought;

        if (msg.value >= valuePlus) {
            tokensBought = msg.value.mul(EXCHANGE_RATE).mul(bonusMultiplier).div(ONE_ETH);
	        if (tokensBought > tokensLeft) {
		        ethToPay = tokensLeft.mul(ONE_ETH).div(bonusMultiplier).div(EXCHANGE_RATE);
		        tokensBought = tokensLeft;
		        icoFinished = true;
		        icoOpen = false;
	        }
		} else {
            tokensBought = msg.value.mul(EXCHANGE_RATE);
	        if (tokensBought > tokensLeft) {
		        ethToPay = tokensLeft.div(EXCHANGE_RATE);
		        tokensBought = tokensLeft;
		        icoFinished = true;
		        icoOpen = false;
	        }
		}

        icoWallet.transfer(ethToPay);
        totalRaised = totalRaised.add(ethToPay);
        totalContributors = totalContributors.add(1);
        totalTokensSold = totalTokensSold.add(tokensBought);

        balances[icoWallet] = balances[icoWallet].sub(tokensBought);
        balances[msg.sender] = balances[msg.sender].add(tokensBought);
        Transfer(icoWallet, msg.sender, tokensBought);

        uint256 refund = msg.value.sub(ethToPay);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

        bonusMultiplier = TOP_MULT.sub(totalRaised);

        if (bonusMultiplier < ONE_ETH) {
		        icoFinished = true;
		        icoOpen = false;
        }
        

    }

    function transfer(address _to, uint _value) public isIcoFinished returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public isIcoFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier isIcoOpen() {
        uint256 blocktime = now;

        require(icoFinished == false);        
        require(blocktime >= startTimestamp);
        require(blocktime <= (startTimestamp + durationSeconds));
        require(totalTokensSold < icoSupply);

        if (icoOpen == false && icoFinished == false) {
            icoOpen = true;
        }

        _;
    }

    modifier isIcoFinished() {
        uint256 blocktime = now;
        
        require(blocktime >= startTimestamp);
        require(icoFinished == true || totalTokensSold >= icoSupply || (blocktime >= (startTimestamp + durationSeconds)));
        if (icoFinished == false) {
            icoFinished = true;
            icoOpen = false;
        }
        _;
    }
    
    function endICO() public isIcoFinished onlyOwner {
    
        uint256 tokensLeft;
        
         
        tokensLeft = balances[icoWallet];
		balances[vestContract] = balances[vestContract].add(tokensLeft);
		vestSupply = vestSupply.add(tokensLeft);
		balances[icoWallet] = 0;
        Transfer(icoWallet, vestContract, tokensLeft);
    }
    
}