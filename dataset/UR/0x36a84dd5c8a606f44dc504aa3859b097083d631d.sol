 

pragma solidity 0.4.24;

contract ERC20 {
  

  
  
  
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    uint256 public totalSupply;
     
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event SaleContractActivation(address saleContract, uint256 tokensForSale);
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
         
         
         
        return a / b;
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

 

contract Ownable {
    address public owner;
    address public creater;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable(address _owner) public {
        creater = msg.sender;
        if (_owner != 0) {
            owner = _owner;

        }
        else {
            owner = creater;
        }

    }
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creater);
        _;
    }

   

}






 
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

   
   
   

   

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

   
   
   
   

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);  
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);  
        return true;
    }

   


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
       
       
       
       

        require(_value == 0 && (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue);  
        return true;
    }

   
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

  
    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);  
        return true;
    }

}
contract TravelHelperToken is StandardToken, Ownable {


 
    address public saleContract;
    string public constant name = "TravelHelperToken";
    string public constant symbol = "TRH";
    uint public constant decimals = 18;
    bool public fundraising = true;
    uint public totalReleased = 0;
    address public teamAddressOne;
    address public teamAddressTwo;
    address public marketingAddress;
    address public advisorsAddress;
    address public teamAddressThree;
    uint public icoStartBlock;
    uint256 public tokensUnlockPeriod = 37 days / 15;  
    uint public tokensSupply = 5000000000;  
    uint public teamTokens = 1480000000 * 1 ether;  
    uint public teamAddressThreeTokens = 20000000 * 1 ether;  
    uint public marketingTeamTokens = 500000000 * 1 ether;  
    uint public advisorsTokens = 350000000 * 1 ether;  
    uint public bountyTokens = 150000000 * 1 ether;  
     uint public tokensForSale = 2500000000 * 1 ether;  
    uint public releasedTeamTokens = 0;
    uint public releasedAdvisorsTokens = 0;
    uint public releasedMarketingTokens = 0;
    bool public tokensLocked = true;
    Ownable ownable;
    mapping (address => bool) public frozenAccounts;
   
  
  
    event FrozenFund(address target, bool frozen);
    event PriceLog(string text);
 

 


    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        }
        else {
            require(fundraising == false);
            _;
        }
    }
    
    modifier tokenNotLocked() {
      if (icoStartBlock > 0 && block.number.sub(icoStartBlock) > tokensUnlockPeriod) {
        tokensLocked = false;
        _;
      } else {
        revert();
      }
    
  }

 

 
    function TravelHelperToken(
    address _tokensOwner,
    address _teamAddressOne,
    address _teamAddressTwo,
    address _marketingAddress,
    address _advisorsAddress,
    address _teamAddressThree) public Ownable(_tokensOwner) {
        require(_tokensOwner != 0x0);
        require(_teamAddressOne != 0x0);
        require(_teamAddressTwo != 0x0);
        teamAddressOne = _teamAddressOne;
        teamAddressTwo = _teamAddressTwo;
        advisorsAddress = _advisorsAddress;
        marketingAddress = _marketingAddress;
        teamAddressThree = _teamAddressThree;
        totalSupply = tokensSupply * (uint256(10) ** decimals);

    }

   

 

    

 

    function transfer(address _to, uint256 _value) public manageTransfer onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transfer(_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        manageTransfer
        onlyPayloadSize(3) returns (bool)
    {
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[msg.sender]);
        super.transferFrom(_from,_to,_value);
        return true;

    }



 


 
   
    function activateSaleContract(address _saleContract) public onlyOwner {
    require(tokensForSale > 0);
    require(teamTokens > 0);
    require(_saleContract != address(0));
    require(saleContract == address(0));
    saleContract = _saleContract;
    uint  totalValue = teamTokens.mul(50).div(100);
    balances[teamAddressOne] = balances[teamAddressOne].add(totalValue);
    balances[teamAddressTwo] = balances[teamAddressTwo].add(totalValue);
    balances[advisorsAddress] = balances[advisorsAddress].add(advisorsTokens);
    balances[teamAddressThree] = balances[teamAddressThree].add(teamAddressThreeTokens);
    balances[marketingAddress] = balances[marketingAddress].add(marketingTeamTokens);
    releasedTeamTokens = releasedTeamTokens.add(teamTokens);
    releasedAdvisorsTokens = releasedAdvisorsTokens.add(advisorsTokens);
    releasedMarketingTokens = releasedMarketingTokens.add(marketingTeamTokens);
    balances[saleContract] = balances[saleContract].add(tokensForSale);
    totalReleased = totalReleased.add(tokensForSale).add(teamTokens).add(advisorsTokens).add(teamAddressThreeTokens).add(marketingTeamTokens);
    tokensForSale = 0; 
    teamTokens = 0; 
    teamAddressThreeTokens = 0;
    icoStartBlock = block.number;
    assert(totalReleased <= totalSupply);
    emit Transfer(address(this), teamAddressOne, totalValue);
    emit Transfer(address(this), teamAddressTwo, totalValue);
    emit Transfer(address(this),teamAddressThree,teamAddressThreeTokens);
    emit Transfer(address(this), saleContract, 2500000000 * 1 ether);
    emit SaleContractActivation(saleContract, 2500000000 * 1 ether);
  }
  
 function saleTransfer(address _to, uint256 _value) public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    return super.transfer(_to, _value);
  }
  
  
  function burnTokensForSale() public returns (bool) {
    require(saleContract != address(0));
    require(msg.sender == saleContract);
    uint256 tokens = balances[saleContract];
    require(tokens > 0);
    require(tokens <= totalSupply);
    balances[saleContract] = 0;
    totalSupply = totalSupply.sub(tokens);
    emit Burn(saleContract, tokens);
    return true;
  }
  
   
 
    

    function finalize() public {
        require(fundraising != false);
        require(msg.sender == saleContract);
         
        fundraising = false;
    }

   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        require(freeze == (true || false));
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze);  
    }
    
    function sendBounty(address _to, uint256 _value) public onlyOwner returns (bool) {
    uint256 value = _value.mul(1 ether);
    require(bountyTokens >= value);
    totalReleased = totalReleased.add(value);
    require(totalReleased <= totalSupply);
    balances[_to] = balances[_to].add(value);
    bountyTokens = bountyTokens.sub(value);
    emit Transfer(address(this), _to, value);
    return true;
  }
  
    function transferOwnership(address newOwner) onlyOwner public  {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);  
        
    }
 
   
    function() public {
        revert();
    }

}