 

 

pragma solidity ^0.4.23;
     
    contract ERC20Basic {
    uint256 public totalSupply;
     function balanceOf(address who) public view returns (uint256);
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


    
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
   
   
  mapping(address => bool) public allowedAddresses;
  mapping(address => bool) public lockedAddresses;
  bool public locked = true;

  function allowAddress(address _addr, bool _allowed) public onlyOwner {
    require(_addr != owner);
    allowedAddresses[_addr] = _allowed;
  }

  function lockAddress(address _addr, bool _locked) public onlyOwner {
    require(_addr != owner);
    lockedAddresses[_addr] = _locked;
  }

  function setLocked(bool _locked) public onlyOwner {
    locked = _locked;
  }

  function canTransfer(address _addr) public constant returns (bool) {
    if(locked){
      if(!allowedAddresses[_addr]&&_addr!=owner) return false;
    }else if(lockedAddresses[_addr]) return false;

    return true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(canTransfer(msg.sender));


     
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
 function allowance(address owner, address spender) public view returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(canTransfer(msg.sender));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

 
contract BurnableToken is StandardToken {
using SafeMath for uint;
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);
    }
}

contract PlayerWonCoin is BurnableToken {

    string public constant name = "PlayerWonCoin";
    string public constant symbol = "pwon";
    uint public constant decimals = 18;
     
    uint256 public constant initialSupply = 1000000000 * (10 ** uint256(decimals));

     
    function PlayerWonCoin () {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;  
        allowedAddresses[owner] = true;
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
     
    contract Crowdsale is Pausable{
     using SafeMath for uint256;
      
     BurnableToken public token;
      
     address public wallet;
      
     uint256 public rate = 1883800000000000000000;
      
     uint256 tokensSold;
     uint256 public weiRaised; 
     
     uint256 startTime;
     uint256 phaze1Start = 1564617600; 
     uint256 phaze1End = 1567209600; 
     uint256 phaze2Start = 1567296000; 
     uint256 phaze2End = 1569801600; 
     uint256 phaze3Start = 1569888000; 
     uint256 phaze3End = 1572480000; 
    uint256 rate1 = 3767600000000000000000; 
     uint256 rate2 = 2354750000000000000000;
     uint256 rate3 = 2093100000000000000000; 
     uint256 public hardcap = 250000000000000000000000000;



      
      event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 time);

      event buyx(address buyer, address contractAddr, uint256 amount);

      constructor(address _wallet, BurnableToken _token, uint256 starttime, uint256 _cap) public{

       require(_wallet != address(0));
       require(_token != address(0));

       wallet = _wallet;
       token = _token;
       startTime = starttime;
       hardcap = _cap; 
     }
     
     function setWallet(address wl) public onlyOwner {
         wallet=wl; 
     }
     
     function setphase1(uint256 rte) public onlyOwner{
         rate1 = rte; 
     }
         function setphase2(uint256 rte) public onlyOwner{
         rate2 = rte; 
     }
         function setphase3(uint256 rte) public onlyOwner{
         rate3 = rte; 
     }
     function setCrowdsale(address _wallet, BurnableToken _token, uint256 starttime, uint256 _cap) public onlyOwner{


       require(_wallet != address(0));
       require(_token != address(0));

       wallet = _wallet;
       token = _token;
       startTime = starttime;
       hardcap = _cap; 
     }



      
      
      
      
      function () external whenNotPaused payable {
        emit buyx(msg.sender, this, _getTokenAmount(msg.value));
        buyTokens(msg.sender);
      }
      
     function buyTokens(address _beneficiary) public whenNotPaused payable {
       
     

       if ((block.timestamp >= phaze1Start ) && (block.timestamp <= phaze1End) && (tokensSold <= 40000000000000000000000000)&&(weiRaised <= hardcap)) {
         rate = rate1;
       }
       else if ((block.timestamp >= phaze2Start) && (block.timestamp <= phaze2End)&&(tokensSold <= hardcap)) {
        rate = rate2;
       }
       else if ((block.timestamp >= phaze3Start) && (block.timestamp <= phaze3End)&&(tokensSold <= hardcap)) {
        rate = rate3; 
       }
       else {
           rate = 10000000000000000000; 
       }
      


      uint256 weiAmount = msg.value;
      uint256 tokens = _getTokenAmount(weiAmount);
      tokensSold = tokensSold.add(tokens);
      weiRaised = weiRaised.add(weiAmount); 
      _processPurchase(_beneficiary, tokens);
      emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens, block.number);
      _updatePurchasingState(_beneficiary, weiAmount);
      _forwardFunds();
      _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     



      
      function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
       require(_beneficiary != address(0));
       require(_weiAmount != 0);
     }
      
      function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        
     }
      
      function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
       token.transfer(_beneficiary, _tokenAmount);
     }
      
      function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
       _deliverTokens(_beneficiary, _tokenAmount);
     }
      
      function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        
     }
      
      function _getTokenAmount(uint256 _weiAmount) internal  returns (uint256) {
uint256 tmp = rate.div(1000000000000000000); 
       return _weiAmount.mul(tmp);
     }

      
      function _forwardFunds() internal {
       wallet.transfer(msg.value);
     }

   }



   contract WonCrowdsale is Crowdsale {
    uint256  hardcap=250000000000000000000000000;
    uint256 public starttime;

    using SafeMath for uint256;
    constructor(address wallet, BurnableToken token, uint256 startTime) Crowdsale(wallet, token, starttime, hardcap) public onlyOwner
    {

     
      starttime = startTime;
      setCrowdsale(wallet, token, startTime, hardcap);

    }



function transferTokenOwnership(address newOwner) public onlyOwner {
  token.transferOwnership(newOwner); 
}


   function () external payable  whenNotPaused{

    emit buyx(msg.sender, this, _getTokenAmount(msg.value));

    buyTokens(msg.sender);
  }


}