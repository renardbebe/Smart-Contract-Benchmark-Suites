 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 





contract TuurntToken is StandardToken, DetailedERC20 {

    using SafeMath for uint256;

     
    uint256 public tokenAllocToTeam;
    uint256 public tokenAllocToCrowdsale;
    uint256 public tokenAllocToCompany;

     
    address public crowdsaleAddress;
    address public teamAddress;
    address public companyAddress;
    

     

    constructor(address _crowdsaleAddress, address _teamAddress, address _companyAddress, string _name, string _symbol, uint8 _decimals) public 
        DetailedERC20(_name, _symbol, _decimals)
    {
        require(_crowdsaleAddress != address(0));
        require(_teamAddress != address(0));
        require(_companyAddress != address(0));
        totalSupply_ = 500000000 * 10 ** 18;
        tokenAllocToTeam = (totalSupply_.mul(33)).div(100);      
        tokenAllocToCompany = (totalSupply_.mul(33)).div(100);   
        tokenAllocToCrowdsale = (totalSupply_.mul(34)).div(100); 

         
        crowdsaleAddress = _crowdsaleAddress;
        teamAddress = _teamAddress;
        companyAddress = _companyAddress;
        

         
        balances[crowdsaleAddress] = tokenAllocToCrowdsale;
        balances[companyAddress] = tokenAllocToCompany;
        balances[teamAddress] = tokenAllocToTeam; 
       
         
        emit Transfer(address(0), crowdsaleAddress, tokenAllocToCrowdsale);
        emit Transfer(address(0), companyAddress, tokenAllocToCompany);
        emit Transfer(address(0), teamAddress, tokenAllocToTeam);
       
        
    }  
}

contract WhitelistInterface {
    function checkWhitelist(address _whiteListAddress) public view returns(bool);
}

 






contract TuurntCrowdsale is Ownable {

    using SafeMath for uint256;

    TuurntToken public token;
    WhitelistInterface public whitelist;

     
    uint256 public MIN_INVESTMENT = 0.2 ether;
    uint256 public ethRaised;
    uint256 public ethRate = 524;
    uint256 public startCrowdsalePhase1Date;
    uint256 public endCrowdsalePhase1Date;
    uint256 public startCrowdsalePhase2Date;
    uint256 public endCrowdsalePhase2Date;
    uint256 public startCrowdsalePhase3Date;
    uint256 public endCrowdsalePhase3Date;
    uint256 public startPresaleDate;
    uint256 public endPresaleDate;
    uint256 public startPrivatesaleDate;
    uint256 public soldToken = 0;                                                           

     
    address public beneficiaryAddress;
    address public tokenAddress;

    bool private isPrivatesaleActive = false;
    bool private isPresaleActive = false;
    bool private isPhase1CrowdsaleActive = false;
    bool private isPhase2CrowdsaleActive = false;
    bool private isPhase3CrowdsaleActive = false;
    bool private isGapActive = false;

    event TokenBought(address indexed _investor, uint256 _token, uint256 _timestamp);
    event LogTokenSet(address _token, uint256 _timestamp);

    enum State { PrivateSale, PreSale, Gap, CrowdSalePhase1, CrowdSalePhase2, CrowdSalePhase3 }

     
    function fundTransfer(uint256 _fund) internal returns(bool) {
        beneficiaryAddress.transfer(_fund);
        return true;
    }

     
    function () payable public {
        buyTokens(msg.sender);
    }

     
    constructor(address _beneficiaryAddress, address _whitelist, uint256 _startDate) public {
        require(_beneficiaryAddress != address(0));
        beneficiaryAddress = _beneficiaryAddress;
        whitelist = WhitelistInterface(_whitelist);
        startPrivatesaleDate = _startDate;
        isPrivatesaleActive = !isPrivatesaleActive;
    }

     
    function endPrivatesale() onlyOwner public {
        require(isPrivatesaleActive == true);
        isPrivatesaleActive = !isPrivatesaleActive;
    }

     
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        require(tokenAddress == address(0));
        token = TuurntToken(_tokenAddress);
        tokenAddress = _tokenAddress;
        emit LogTokenSet(token, now);
    }

      
    function activePresale(uint256 _presaleDate) onlyOwner public {
        require(isPresaleActive == false);
        require(isPrivatesaleActive == false);
        startPresaleDate = _presaleDate;
        endPresaleDate = startPresaleDate + 2 days;
        isPresaleActive = !isPresaleActive;
    }
   
     
    function activeCrowdsalePhase1(uint256 _phase1Date) onlyOwner public {
        require(isPresaleActive == true);
        require(_phase1Date > endPresaleDate);
        require(isPhase1CrowdsaleActive == false);
        startCrowdsalePhase1Date = _phase1Date;
        endCrowdsalePhase1Date = _phase1Date + 1 weeks;
        isPresaleActive = !isPresaleActive;
        isPhase1CrowdsaleActive = !isPhase1CrowdsaleActive;
    }

     

    function activeCrowdsalePhase2(uint256 _phase2Date) onlyOwner public {
        require(isPhase2CrowdsaleActive == false);
        require(_phase2Date > endCrowdsalePhase1Date);
        require(isPhase1CrowdsaleActive == true);
        startCrowdsalePhase2Date = _phase2Date;
        endCrowdsalePhase2Date = _phase2Date + 2 weeks;
        isPhase2CrowdsaleActive = !isPhase2CrowdsaleActive;
        isPhase1CrowdsaleActive = !isPhase1CrowdsaleActive;
    }

     
    function activeCrowdsalePhase3(uint256 _phase3Date) onlyOwner public {
        require(isPhase3CrowdsaleActive == false);
        require(_phase3Date > endCrowdsalePhase2Date);
        require(isPhase2CrowdsaleActive == true);
        startCrowdsalePhase3Date = _phase3Date;
        endCrowdsalePhase3Date = _phase3Date + 3 weeks;
        isPhase3CrowdsaleActive = !isPhase3CrowdsaleActive;
        isPhase2CrowdsaleActive = !isPhase2CrowdsaleActive;
    }
     
    function changeMinInvestment(uint256 _newMinInvestment) onlyOwner public {
        MIN_INVESTMENT = _newMinInvestment;
    }

      
    function setEtherRate(uint256 _newEthRate) onlyOwner public {
        require(_newEthRate != 0);
        ethRate = _newEthRate;
    }

     

    function getState() view public returns(State) {
        
        if(now >= startPrivatesaleDate && isPrivatesaleActive == true) {
            return State.PrivateSale;
        }
        if (now >= startPresaleDate && now <= endPresaleDate) {
            require(isPresaleActive == true);
            return State.PreSale;
        }
        if (now >= startCrowdsalePhase1Date && now <= endCrowdsalePhase1Date) {
            require(isPhase1CrowdsaleActive == true);
            return State.CrowdSalePhase1;
        }
        if (now >= startCrowdsalePhase2Date && now <= endCrowdsalePhase2Date) {
            require(isPhase2CrowdsaleActive == true);
            return State.CrowdSalePhase2;
        }
        if (now >= startCrowdsalePhase3Date && now <= endCrowdsalePhase3Date) {
            require(isPhase3CrowdsaleActive == true);
            return State.CrowdSalePhase3;
        }
        return State.Gap;

    }
 
     

    function getRate() view public returns(uint256) {
        if (getState() == State.PrivateSale) {
            return 5;
        }
        if (getState() == State.PreSale) {
            return 6;
        }
        if (getState() == State.CrowdSalePhase1) {
            return 7;
        }
        if (getState() == State.CrowdSalePhase2) {
            return 8;
        }
        if (getState() == State.CrowdSalePhase3) {
            return 10;
        }
    }
    
     
    function getTokenAmount(uint256 _investedAmount) view public returns(uint256) {
        uint256 tokenRate = getRate();
        uint256 tokenAmount = _investedAmount.mul((ethRate.mul(100)).div(tokenRate));
        return tokenAmount;
    }

     
    function buyTokens(address _investorAddress) 
    public 
    payable
    returns(bool)
    {   
        require(whitelist.checkWhitelist(_investorAddress));
        if ((getState() == State.PreSale) ||
            (getState() == State.CrowdSalePhase1) || 
            (getState() == State.CrowdSalePhase2) || 
            (getState() == State.CrowdSalePhase3) || 
            (getState() == State.PrivateSale)) {
            uint256 amount;
            require(_investorAddress != address(0));
            require(tokenAddress != address(0));
            require(msg.value >= MIN_INVESTMENT);
            amount = getTokenAmount(msg.value);
            require(fundTransfer(msg.value));
            require(token.transfer(_investorAddress, amount));
            ethRaised = ethRaised.add(msg.value);
            soldToken = soldToken.add(amount);
            emit TokenBought(_investorAddress,amount,now);
            return true;
        }else {
            revert();
        }
    }

     
    function endCrowdfund(address companyAddress) onlyOwner public returns(bool) {
        require(isPhase3CrowdsaleActive == true);
        require(now >= endCrowdsalePhase3Date); 
        uint256 remaining = token.balanceOf(this);
        require(token.transfer(companyAddress, remaining));
    }

}