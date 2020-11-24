 

pragma solidity ^0.4.11;


 
 
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
    
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
    }
    
}

 
contract ERC20 {
    uint256 public totalSupply;
    bool public transferlocked;
    bool public wallocked;
    function balanceOf(address who) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint indexed value);
}

 

 
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(
            balances[msg.sender] >= _value
            && _value > 0
            );
        if (transferlocked) {
            throw;
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 
contract StandardToken is BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(
            allowed[_from][msg.sender] >=_value
            && balances[_from] >= _value
            && _value > 0
            );
        if (transferlocked) {
            throw;
        }

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        if (transferlocked) {
            throw;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


}

 

contract MintburnToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }
  
   
  
  function burn(uint256 _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
   function burnFrom(address _from, uint256 _value) onlyOwner returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        Burn(_from, _value);
        return true;
    }

   
   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract CareerXonToken is MintburnToken{
    string public constant name = "CareerXon";
    string public constant symbol = "CRN";
    uint public constant decimals = 18;
    string public standard = "Token 0.1";
    uint256 public maxSupply = 1500000000000000000000000;
     

     
    uint public startPreSale;
    uint public endPreSale;
    uint public startICO;
    uint public endICO;



     
    uint256 public rate;

    uint256 public minTransactionAmount;

    uint256 public raisedForEther = 0;

    modifier inActivePeriod() {
        require((startPreSale < now && now <= endPreSale) || (startICO < now && now <= endICO));
        _;
    }
    
     

    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) revert();
        _;

    }

    function CareerXonToken(uint _startP, uint _endP, uint _startI, uint _endI) {
        require(_startP < _endP);
        require(_startI < _endI);
        

         
         
         
         
        totalSupply = 12900000000000000000000000;


         
        rate = 1300;

         
        minTransactionAmount = 0.01 ether;

        startPreSale = _startP;
        endPreSale = _endP;
        startICO = _startI;
        endICO = _endI;
        transferlocked = true;
         
        wallocked = true;

    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
     
    
    function setupPeriodForPreSale(uint _start, uint _end) onlyOwner {
        require(_start < _end);
        startPreSale = _start;
        endPreSale = _end;
    }
    
     
     
     
    
    function setupPeriodForICO(uint _start, uint _end) onlyOwner {
        require(_start < _end);
        startICO = _start;
        endICO = _end;
    }

     
    function () inActivePeriod payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _youraddress) inActivePeriod payable {
        require(_youraddress != 0x0);
        require(msg.value >= minTransactionAmount);

        uint256 weiAmount = msg.value;

        raisedForEther = raisedForEther.add(weiAmount);

         
        uint256 tokens = weiAmount.mul(rate);
        tokens += getBonus(tokens);
        tokens += getBonustwo(tokens);

        tokenReserved(_youraddress, tokens);

    }
    
    function withdraw(uint256 _value) onlyOwner returns (bool){
        if (wallocked) {
            throw;
        }
        owner.transfer(_value);
        return true;
    }
    function walunlock() onlyOwner returns (bool success)  {
        wallocked = false;
        return true;
    }
    function wallock() onlyOwner returns (bool success)  {
        wallocked = true;
        return true;
    }

     
    function getBonus(uint256 _tokens) constant returns (uint256 bonus) {
        require(_tokens != 0);
        if (1 == getCurrentPeriod()) {
            if (startPreSale <= now && now < startPreSale + 1 days) {
                return _tokens.div(2);
            } else if (startPreSale + 1 days <= now && now < startPreSale + 2 days ) {
                return _tokens.div(3);
            } else if (startPreSale + 2 days <= now && now < startPreSale + 3 days ) {
                return _tokens.div(5);
            }else if (startPreSale + 3 days <= now && now < startPreSale + 4 days ) {
                return _tokens.div(10);
            }
        }
        return 0;
    }
        
     
    function getBonustwo(uint256 _tokens) constant returns (uint256 bonus) {
        require(_tokens != 0);
        if (2 == getCurrentPeriod()) {
            if (startICO <= now && now < startICO + 1 days) {
                return _tokens.div(5);
            } else if (startICO + 1 days <= now && now < startICO + 2 days ) {
                return _tokens.div(10);
            } else if (startICO + 2 days <= now && now < startICO + 3 days ) {
                return _tokens.mul(5).div(100);
            }
        }
     
        return 0;
    }

     
    function getCurrentPeriod() inActivePeriod constant returns (uint){
        if ((startPreSale < now && now <= endPreSale)) {
            return 1;
        } else if ((startICO < now && now <= endICO)) {
            return 2;
        } else {
            return 0;
        }
    }

    function tokenReserved(address _to, uint256 _value) internal returns (bool) {
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
     
    
    function transferunlock() onlyOwner returns (bool success)  {
        transferlocked = false;
        return true;
    }
    function transferlock() onlyOwner returns (bool success)  {
        transferlocked = true;
        return true;
    }
}