 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 


 
 
contract Owned {

    address public owner;
    address public newOwner;

    event OwnerChanged(address indexed _newOwner);


    function Owned() public {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public onlyOwner returns (bool) {
        require(_newOwner != address(0));
        require(_newOwner != owner);

        newOwner = _newOwner;

        return true;
    }


    function acceptOwnership() public returns (bool) {
        require(msg.sender == newOwner);

        owner = msg.sender;

        OwnerChanged(msg.sender);

        return true;
    }
}


pragma solidity ^0.4.17;


 
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



pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 


 
 
 
 

contract ERC20Interface {

    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}


pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 




 
 
contract GATToken is ERC20Interface, Owned {

    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;


    function GATToken(string _symbol, string _name, uint256 _decimals, uint256 _totalSupply) public
        Owned()
    {
        symbol      = _symbol;
        name        = _name;
        decimals    = _decimals;
        totalSupply = _totalSupply;

        Transfer(0x0, owner, _totalSupply);
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);

        return true;
     }


     function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }


     function approve(address _spender, uint256 _value) public returns (bool success) {
         allowed[msg.sender][_spender] = _value;

         Approval(msg.sender, _spender, _value);

         return true;
     }
}


pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 


contract GATTokenSaleConfig {

    string  public constant SYMBOL                  = "GAT";
    string  public constant NAME                    = "GAT Token";
    uint256 public constant DECIMALS                = 18;

    uint256 public constant DECIMALSFACTOR          = 10**uint256(DECIMALS);
    uint256 public constant START_TIME              = 1509192000;  
    uint256 public constant END_TIME                = 1511870399;  
    uint256 public constant CONTRIBUTION_MIN        = 0.1 ether;
    uint256 public constant TOKEN_TOTAL_CAP         = 1000000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_PRIVATE_SALE_CAP  =   70000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_PRESALE_CAP       =   15000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_PUBLIC_SALE_CAP   =  130000000  * DECIMALSFACTOR;  
    uint256 public constant TOKEN_FOUNDATION_CAP    =  100000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_RESERVE1_CAP      =   50000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_RESERVE2_CAP      =   50000000  * DECIMALSFACTOR;
    uint256 public constant TOKEN_FUTURE_CAP        =  600000000  * DECIMALSFACTOR;

     
     
     
     
    uint256 public constant PRESALE_BONUS      = 120;

     
     
     
     
    uint256 public constant TOKENS_PER_KETHER = 1500000;
}


pragma solidity ^0.4.17;

 
 
 
 
 
 
 
 





 
 
 
contract GATTokenSale is GATToken, GATTokenSaleConfig {

    using SafeMath for uint256;

     
    bool public finalized;

     
    bool public suspended;

     
    address public bankAddress;
    address public fundingAddress;
    address public reserve1Address;
    address public reserve2Address;

     
    uint256 public tokensPerKEther;

     
     
    uint256 public bonus;

     
    uint256 public totalTokensSold;

     
     
    uint256 public startTime;
    uint256 public endTime;


     
    event TokensPurchased(address indexed beneficiary, uint256 cost, uint256 tokens);
    event TokensPerKEtherUpdated(uint256 newAmount);
    event BonusAmountUpdated(uint256 newAmount);
    event TimeWindowUpdated(uint256 newStartTime, uint256 newEndTime);
    event SaleSuspended();
    event SaleResumed();
    event TokenFinalized();
    event ContractTokensReclaimed(uint256 amount);


    function GATTokenSale(address _bankAddress, address _fundingAddress, address _reserve1Address, address _reserve2Address) public
        GATToken(SYMBOL, NAME, DECIMALS, 0)
    {
         
        require(START_TIME >= currentTime());
        require(END_TIME > START_TIME);

         
        require(_bankAddress    != address(0x0));
        require(_bankAddress    != address(this));
        require(_fundingAddress != address(0x0));
        require(_fundingAddress != address(this));
        require(_reserve1Address != address(0x0));
        require(_reserve1Address != address(this));
        require(_reserve2Address != address(0x0));
        require(_reserve2Address != address(this));

        uint256 salesTotal = TOKEN_PUBLIC_SALE_CAP.add(TOKEN_PRIVATE_SALE_CAP);
        require(salesTotal.add(TOKEN_FUTURE_CAP).add(TOKEN_FOUNDATION_CAP).add(TOKEN_RESERVE1_CAP).add(TOKEN_RESERVE2_CAP) == TOKEN_TOTAL_CAP);

         
        finalized = false;
        suspended = false;

         
        startTime = START_TIME;
        endTime   = END_TIME;

         
        tokensPerKEther = TOKENS_PER_KETHER;

         
        bonus = PRESALE_BONUS;

         
        bankAddress    = _bankAddress;
        fundingAddress = _fundingAddress;
        reserve1Address = _reserve1Address;
        reserve2Address = _reserve2Address;

         
        balances[address(this)] = balances[address(this)].add(TOKEN_PRESALE_CAP);
        totalSupply = totalSupply.add(TOKEN_PRESALE_CAP);
        Transfer(0x0, address(this), TOKEN_PRESALE_CAP);

        balances[reserve1Address] = balances[reserve1Address].add(TOKEN_RESERVE1_CAP);
        totalSupply = totalSupply.add(TOKEN_RESERVE1_CAP);
        Transfer(0x0, reserve1Address, TOKEN_RESERVE1_CAP);

        balances[reserve2Address] = balances[reserve2Address].add(TOKEN_RESERVE2_CAP);
        totalSupply = totalSupply.add(TOKEN_RESERVE2_CAP);
        Transfer(0x0, reserve2Address, TOKEN_RESERVE2_CAP);

        uint256 bankBalance = TOKEN_TOTAL_CAP.sub(totalSupply);
        balances[bankAddress] = balances[bankAddress].add(bankBalance);
        totalSupply = totalSupply.add(bankBalance);
        Transfer(0x0, bankAddress, bankBalance);

         
        require(balanceOf(address(this))  == TOKEN_PRESALE_CAP);
        require(balanceOf(reserve1Address) == TOKEN_RESERVE1_CAP);
        require(balanceOf(reserve2Address) == TOKEN_RESERVE2_CAP);
        require(balanceOf(bankAddress)    == bankBalance);
        require(totalSupply == TOKEN_TOTAL_CAP);
    }


    function currentTime() public constant returns (uint256) {
        return now;
    }


     
     
    function setTokensPerKEther(uint256 _tokensPerKEther) external onlyOwner returns(bool) {
        require(_tokensPerKEther > 0);

         
        tokensPerKEther = _tokensPerKEther;

        TokensPerKEtherUpdated(_tokensPerKEther);

        return true;
    }


     
     
    function setBonus(uint256 _bonus) external onlyOwner returns(bool) {
         
        require(_bonus >= 100);

         
        require(_bonus <= 200);

        bonus = _bonus;

        BonusAmountUpdated(_bonus);

        return true;
    }


     
     
    function setTimeWindow(uint256 _startTime, uint256 _endTime) external onlyOwner returns(bool) {
        require(_startTime >= START_TIME);
        require(_endTime > _startTime);

        startTime = _startTime;
        endTime   = _endTime;

        TimeWindowUpdated(_startTime, _endTime);

        return true;
    }


     
     
    function suspend() external onlyOwner returns(bool) {
        if (suspended == true) {
            return false;
        }

        suspended = true;

        SaleSuspended();

        return true;
    }


     
     
    function resume() external onlyOwner returns(bool) {
        if (suspended == false) {
            return false;
        }

        suspended = false;

        SaleResumed();

        return true;
    }


     
     
    function () payable public {
        buyTokens(msg.sender);
    }


     
     
     
    function buyTokens(address beneficiary) public payable returns (uint256) {
        require(!suspended);
        require(beneficiary != address(0x0));
        require(beneficiary != address(this));
        require(currentTime() >= startTime);
        require(currentTime() <= endTime);
        require(msg.value >= CONTRIBUTION_MIN);
        require(msg.sender != fundingAddress);

         
        uint256 saleBalance = balanceOf(address(this));
        require(saleBalance > 0);

         
        uint256 tokens = msg.value.mul(tokensPerKEther).mul(bonus).div(10**(18 - DECIMALS + 3 + 2));
        require(tokens > 0);

        uint256 cost = msg.value;
        uint256 refund = 0;

        if (tokens > saleBalance) {
             
            tokens = saleBalance;

             
            cost = tokens.mul(10**(18 - DECIMALS + 3 + 2)).div(tokensPerKEther.mul(bonus));

             
            refund = msg.value.sub(cost);
        }

        totalTokensSold = totalTokensSold.add(tokens);

         
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[beneficiary]   = balances[beneficiary].add(tokens);
        Transfer(address(this), beneficiary, tokens);

        if (refund > 0) {
           msg.sender.transfer(refund);
        }

         
        uint256 contribution      = msg.value.sub(refund);
        uint256 reserveAllocation = contribution.div(20);

        fundingAddress.transfer(contribution.sub(reserveAllocation));
        reserve1Address.transfer(reserveAllocation);

        TokensPurchased(beneficiary, cost, tokens);

        return tokens;
    }


     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (!isTransferAllowed(msg.sender, _to)) {
            return false;
        }

        return super.transfer(_to, _amount);
    }


     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (!isTransferAllowed(_from, _to)) {
            return false;
        }

        return super.transferFrom(_from, _to, _amount);
    }


     
     
    function isTransferAllowed(address _from, address _to) private view returns (bool) {
        if (finalized) {
             
            return true;
        }

        if (_from == bankAddress || _to == bankAddress) {
             
             
             
            return true;
        }

        return false;
    }


     
    function reclaimContractTokens() external onlyOwner returns (bool) {
        uint256 tokens = balanceOf(address(this));

        if (tokens == 0) {
            return false;
        }

        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[bankAddress]   = balances[bankAddress].add(tokens);
        Transfer(address(this), bankAddress, tokens);

        ContractTokensReclaimed(tokens);

        return true;
    }


     
     
    function finalize() external onlyOwner returns (bool) {
        require(!finalized);

        finalized = true;

        TokenFinalized();

        return true;
    }
}