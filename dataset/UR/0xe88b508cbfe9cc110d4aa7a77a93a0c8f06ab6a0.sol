 

pragma solidity ^0.4.21;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
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
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract EntryToken is StandardToken, Ownable {
    string public constant name = "Entry Token";
    string public constant symbol = "ENTRY";
    uint8 public constant decimals = 18;

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 325000000000000000000000000;  

     
    uint256 public constant BASE_RATE = 6000;

     
    uint256 private constant datePreSaleStart = 1525294800;
    
     
    uint256 private constant datePreSaleEnd = 1525986000;

     
    uint256 private constant dateSaleStart = 1527800400;

     
    uint256 private constant dateSaleEnd = 1535749200;

    
     
    uint256 private preSaleCap = 75000000000000000000000000;  
    
     
    uint256[25] private stageCaps = [
        85000000000000000000000000	,  
        95000000000000000000000000	,  
        105000000000000000000000000	,  
        115000000000000000000000000	,  
        125000000000000000000000000	,  
        135000000000000000000000000	,  
        145000000000000000000000000	,  
        155000000000000000000000000	,  
        165000000000000000000000000	,  
        175000000000000000000000000	,  
        185000000000000000000000000	,  
        195000000000000000000000000	,  
        205000000000000000000000000	,  
        215000000000000000000000000	,  
        225000000000000000000000000	,  
        235000000000000000000000000	,  
        245000000000000000000000000	,  
        255000000000000000000000000	,  
        265000000000000000000000000	,  
        275000000000000000000000000	,  
        285000000000000000000000000	,  
        295000000000000000000000000	,  
        305000000000000000000000000	,  
        315000000000000000000000000	,  
        325000000000000000000000000    
    ];
     
    uint8[25] private stageRates = [15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 27, 
                        28, 29, 30, 31, 33, 34, 35, 36, 37, 40, 41, 42, 43, 44];

    uint64 private constant dateTeamTokensLockedTill = 1630443600;
   
    bool public tokenSaleClosed = false;

    address public timelockContractAddress;


    function isPreSalePeriod() public constant returns (bool) {
        if(totalSupply > preSaleCap || now >= datePreSaleEnd) {
            return false;
        } else {
            return now > datePreSaleStart;
        }
    }


    function isICOPeriod() public constant returns (bool) {
        if (totalSupply > TOKENS_SALE_HARD_CAP || now >= dateSaleEnd){
            return false;
        } else {
            return now > dateSaleStart;
        }
    }

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP && !tokenSaleClosed && now >= datePreSaleStart);
        _;
    }


    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }


    modifier canBeTraded {
        require(tokenSaleClosed);
        _;
    }


    function EntryToken() public {
    	 
    	generateTokens(owner, 50000000000000000000000000);  
    }


    function () public payable inProgress {
        if(isPreSalePeriod()){
            buyPreSaleTokens(msg.sender);
        } else if (isICOPeriod()){
            buyTokens(msg.sender);
        }			
    } 
    

    function buyPreSaleTokens(address _beneficiary) internal {
        require(msg.value >= 0.01 ether);
        uint256 tokens = getPreSaleTokenAmount(msg.value);
        require(totalSupply.add(tokens) <= preSaleCap);
        generateTokens(_beneficiary, tokens);
        owner.transfer(address(this).balance);
    }
    
    
    function buyTokens(address _beneficiary) internal {
        require(msg.value >= 0.01 ether);
        uint256 tokens = getTokenAmount(msg.value);
        require(totalSupply.add(tokens) <= TOKENS_SALE_HARD_CAP);
        generateTokens(_beneficiary, tokens);
        owner.transfer(address(this).balance);
    }


    function getPreSaleTokenAmount(uint256 weiAmount)internal pure returns (uint256) {
        return weiAmount.mul(BASE_RATE);
    }
    
    
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = weiAmount.mul(BASE_RATE);
        uint8 stageNumber = currentStageIndex();
        tokens = getStageTokenAmount(tokenBase, stageNumber);
        while(tokens.add(totalSupply) > stageCaps[stageNumber] && stageNumber < 24){
           stageNumber++;
           tokens = getStageTokenAmount(tokenBase, stageNumber);
        }
    }
    
    
    function getStageTokenAmount(uint256 tokenBase, uint8 stageNumber)internal view returns (uint256) {
    	uint256 rate = 10000000000000000000/stageRates[stageNumber];
    	uint256 base = tokenBase/1000000000000000000;
        return base.mul(rate);
    }
    
    
    function currentStageIndex() internal view returns (uint8 stageNumber) {
        stageNumber = 0;
        while(stageNumber < 24 && totalSupply > stageCaps[stageNumber]) {
            stageNumber++;
        }
    }
    
    
    function buyTokensOnInvestorBehalf(address _beneficiary, uint256 _tokens) public onlyOwner beforeEnd {
        generateTokens(_beneficiary, _tokens);
    }
    
    
    function buyTokensOnInvestorBehalfBatch(address[] _addresses, uint256[] _tokens) public onlyOwner beforeEnd {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            generateTokens(_addresses[i], _tokens[i]);
        }
    }
    
    
    function generateTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));
        totalSupply = totalSupply.add(_tokens);
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);
        emit Transfer(address(0), _beneficiary, _tokens);
    }


    function close() public onlyOwner beforeEnd {
         
        uint256 lockedTokens = 118000000000000000000000000;  
         
        uint256 partnerTokens = 147000000000000000000000000;  
         
        uint256 unsoldTokens = TOKENS_SALE_HARD_CAP.sub(totalSupply);
        
        generateLockedTokens(lockedTokens);
        generatePartnerTokens(partnerTokens);
        generateUnsoldTokens(unsoldTokens);
        
        totalSupply = totalSupply.add(lockedTokens+partnerTokens+unsoldTokens);

        tokenSaleClosed = true;

        owner.transfer(address(this).balance);
    }
    
    function generateLockedTokens(uint lockedTokens) internal{
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
        emit Transfer(address(0), timelockContractAddress, lockedTokens);
    }

    function generatePartnerTokens(uint partnerTokens) internal{
        balances[owner] = balances[owner].add(partnerTokens);
        emit Transfer(address(0), owner, partnerTokens);
    }

    function generateUnsoldTokens(uint unsoldTokens) internal{
        balances[owner] = balances[owner].add(unsoldTokens);
        emit Transfer(address(0), owner, unsoldTokens);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public canBeTraded returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


    function transfer(address _to, uint256 _value) public canBeTraded returns (bool) {
        return super.transfer(_to, _value);
    }
}