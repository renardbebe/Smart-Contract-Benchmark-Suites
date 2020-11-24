 

pragma solidity ^0.4.17;

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address from, address to);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint;

  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     if (msg.data.length < size + 4) {
       revert();
     }
     _;
  }

   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

}


contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint256)) allowances;

     
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3 * 32) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
    }

     
    function approve(address _spender, uint256 _amount) public {
        require((_amount == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }


     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

}


contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) public onlyOwner canMint onlyPayloadSize(2 * 32) returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}


contract Ethercloud is MintableToken {
    
    uint8 public decimals;
    string public name;
    string public symbol;

    function Ethercloud() public {
       totalSupply = 0;
       decimals = 18;
       name = "Ethercloud";
       symbol = "ETCL";
    }
}


contract ICO is Ownable {

    using SafeMath for uint256;

    Ethercloud public ETCL;

    bool       public success;
    uint256    public rate;
    uint256    public rateWithBonus;
    uint256    public bountiesIssued;
    uint256    public tokensSold;
    uint256    public tokensForSale;
    uint256    public tokensForBounty;
    uint256    public maxTokens;
    uint256    public startTime;
    uint256    public endTime;
    uint256    public softCap;
    uint256    public hardCap;
    uint256[3] public bonusStages;

    mapping (address => uint256) investments;

    event TokensPurchased(address indexed by, uint256 amount);
    event RefundIssued(address indexed by, uint256 amount);
    event FundsWithdrawn(address indexed by, uint256 amount);
    event BountyIssued(address indexed to, uint256 amount);
    event IcoSuccess();
    event CapReached();

    function ICO() public {
        ETCL = new Ethercloud();
        success = false;
        rate = 1288; 
        rateWithBonus = 1674;
        bountiesIssued = 0;
        tokensSold = 0;
        tokensForSale = 78e24;               
        tokensForBounty = 2e24;              
        maxTokens = 100e24;                  
        startTime = now.add(15 days);        
        endTime = startTime.add(30 days);    
        softCap = 6212530674370205e6;        
        hardCap = 46594980057776535e6;       

        bonusStages[0] = startTime.add(7 days);

        for (uint i = 1; i < bonusStages.length; i++) {
            bonusStages[i] = bonusStages[i - 1].add(7 days);
        }
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0 && validPurchase() && this.balance.sub(msg.value) < hardCap);
        if (this.balance >= softCap && !success) {
            success = true;
            IcoSuccess();
        }
        uint256 weiAmount = msg.value;
        if (this.balance > hardCap) {
            CapReached();
            uint256 toRefund = this.balance.sub(hardCap);
            msg.sender.transfer(toRefund);
            weiAmount = weiAmount.sub(toRefund);
        }
        uint256 tokens = weiAmount.mul(getCurrentRateWithBonus());
        if (tokensSold.add(tokens) > tokensForSale) {
            revert();
        }
        ETCL.mint(_beneficiary, tokens);
        tokensSold = tokensSold.add(tokens);
        investments[_beneficiary] = investments[_beneficiary].add(weiAmount);
        TokensPurchased(_beneficiary, tokens);
    }

     
    function getCurrentRateWithBonus() internal returns (uint256) {
        rateWithBonus = (rate.mul(getBonusPercentage()).div(100)).add(rate);
        return rateWithBonus;
    }

     
    function getBonusPercentage() internal view returns (uint256 bonusPercentage) {
        uint256 timeStamp = now;
        if (timeStamp > bonusStages[2]) {
            bonusPercentage = 0; 
        }
        if (timeStamp <= bonusStages[2]) {
            bonusPercentage = 5;
        }
        if (timeStamp <= bonusStages[1]) {
            bonusPercentage = 15;
        }
        if (timeStamp <= bonusStages[0]) {
            bonusPercentage = 30;
        } 
        return bonusPercentage;
    }

     
    function issueTokens(address _beneficiary, uint256 _amount) public onlyOwner {
        require(_beneficiary != 0x0 && _amount > 0 && tokensSold.add(_amount) <= tokensForSale); 
        ETCL.mint(_beneficiary, _amount);
        tokensSold = tokensSold.add(_amount);
        TokensPurchased(_beneficiary, _amount);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function getRefund(address _addr) public {
        if (_addr == 0x0) {
            _addr = msg.sender;
        }
        require(!isSuccess() && hasEnded() && investments[_addr] > 0);
        uint256 toRefund = investments[_addr];
        investments[_addr] = 0;
        _addr.transfer(toRefund);
        RefundIssued(_addr, toRefund);
    }

     
    function issueBounty(address _beneficiary, uint256 _amount) public onlyOwner {
        require(bountiesIssued.add(_amount) <= tokensForBounty && _beneficiary != 0x0);
        ETCL.mint(_beneficiary, _amount);
        bountiesIssued = bountiesIssued.add(_amount);
        BountyIssued(_beneficiary, _amount);
    }

     
    function withdraw() public onlyOwner {
        uint256 inCirculation = tokensSold.add(bountiesIssued);
        ETCL.mint(owner, inCirculation.mul(25).div(100));
        owner.transfer(this.balance);
    }

     
    function isSuccess() public constant returns (bool) {
        return success;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function endTime() public constant returns (uint256) {
        return endTime;
    }

     
    function investmentOf(address _addr) public constant returns (uint256) {
        return investments[_addr];
    }

     
    function finishMinting() public onlyOwner {
        require(hasEnded());
        ETCL.finishMinting();
    }
}