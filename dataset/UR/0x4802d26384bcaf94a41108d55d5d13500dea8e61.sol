 

pragma solidity ^0.4.19;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    _amount = _amount * 1 ether;
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}



 
contract PUBLICCOIN is Ownable, MintableToken {
   
   

   
  string public constant name = "Public Coin";
  string public constant symbol = "PUBLIC";

   
  uint8 public constant decimals = 18;

   
  function PUBLICCOIN (address _owner1, uint8 _owner1Percentage, address _owner2, uint8 _owner2Percentage, uint256 _cap) public {
       
      require(_owner1Percentage+_owner2Percentage<50); 
      require(_cap >0);
      totalSupply = 0;  
       
      mint(_owner1, _cap *_owner1Percentage / 100);
      mint(_owner2, _cap *_owner2Percentage / 100);

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

 
contract Crowdsale is Ownable
{
    using SafeMath for uint256;

     
    PUBLICCOIN public token;
     
     
    bool public crowdSaleOn = false;

     
    uint256 constant totalCap = 17*10**6;   
    uint256 constant crowdSaleCap = 14*10**6*(1 ether);   
    uint256 constant bonusPeriod = 1 days;  
    uint256 constant tokensPerEther = 3750;
    uint256 public startTime;  
    uint256 public endTime;   
    uint256 public weiRaised = 0;   
    uint256 public tokensMinted = 0;  
    uint256 public currentRate = 3750;
     
     
     
    address constant firstOwner = 0xf878bDc344097449Df3F2c2DC6Ed491e9DeF71f5;
    address constant secondOwner = 0x0B993E8Ee11B18BD99FCf7b2df5555385A661f7e;
    uint8 constant firstOwnerETHPercentage= 90;
    uint8 constant secondOwnerETHPercentage= 10;
    uint8 constant firstOwnerTokenPercentage= 12;
    uint8 constant secondOwnerTokenPercentage= 6;
    uint256 constant minPurchase = (1*1 ether)/10;  

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    modifier activeCrowdSale() {
        require(crowdSaleOn);
        _;
    }
    modifier inactiveCrowdSale() {
        require(!crowdSaleOn);
        _;
    }

     
    function Crowdsale() public {
        token = new PUBLICCOIN(firstOwner,firstOwnerTokenPercentage,secondOwner,secondOwnerTokenPercentage, totalCap);
    }

     
    function startCrowdsale() inactiveCrowdSale onlyOwner public returns (bool) {
        startTime =  uint256(now);
         
        endTime = now + 3*bonusPeriod;
        crowdSaleOn = true;
        weiRaised = 0;
        tokensMinted = 0;
        return true;
    }

     
    function endCrowdsale() activeCrowdSale onlyOwner public returns (bool) {
        require(now >= endTime);
        crowdSaleOn = false;
        token.finishMinting();
        return true;
    }

     
    function findCurrentRate() constant private returns (uint256 _discountedRate) {

        uint256 elapsedTime = now.sub(startTime);
        uint256 baseRate = (1*1 ether)/tokensPerEther;

        if (elapsedTime <= bonusPeriod){  
            _discountedRate = baseRate.mul(100).div(135);
        }else{
            if (elapsedTime < 2*bonusPeriod){  
              _discountedRate = baseRate.mul(100).div(115);
              }else{
              _discountedRate = baseRate;
            }
        }

    }

     
    function () payable public {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) activeCrowdSale public payable {
        require(beneficiary != 0x0);
        require(now >= startTime);
        require(now <= endTime);
        require(msg.value >= minPurchase);  

         
        uint256 weiAmount = msg.value;
        weiRaised = weiRaised.add(weiAmount);


         
        uint256 rate = findCurrentRate();
         
        require(rate > 0);
         
        currentRate = (1*1 ether)/rate;
         
         
        uint256 numTokens = weiAmount.div(rate);
        require(numTokens > 0);
        require(tokensMinted.add(numTokens.mul(1 ether)) <= crowdSaleCap);
        tokensMinted = tokensMinted.add(numTokens.mul(1 ether));

         
        token.mint(beneficiary, numTokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, numTokens);
         
        firstOwner.transfer(weiAmount*firstOwnerETHPercentage/100);
        secondOwner.transfer(weiAmount*secondOwnerETHPercentage/100);

    }

     
     
     
     
    function emergencyDrain(ERC20 anyToken) inactiveCrowdSale onlyOwner public returns(bool){
        if( this.balance > 0 ) {
            owner.transfer( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(owner, anyToken.balanceOf(this)) );
        }

        return true;
    }

}