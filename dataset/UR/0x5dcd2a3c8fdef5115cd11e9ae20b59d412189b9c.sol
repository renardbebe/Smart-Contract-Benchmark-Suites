 

pragma solidity 0.4.24;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
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
    function add(uint256 a, uint256 b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

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

   


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
       
       
       
       

        require(_value == 0 || (allowed[msg.sender][_spender] == 0));
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

  
contract Synapse is StandardToken, Owned, Pausable {
    
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;

    uint256 public tokensForSale = 495000000 * 1 ether; 
    uint256 public vestingTokens = 227700000 * 1 ether; 
    uint256 public managementTokens = 267300000 * 1 ether; 

    mapping(address => bool) public investorIsVested; 
    uint256 public vestingTime = 15552000; 

    uint256 public bountyTokens = 29700000 * 1 ether;
    uint256 public marketingTokens = 118800000 * 1 ether;
    uint256 public expansionTokens = 89100000 * 1 ether;
    uint256 public advisorTokens = 29700000 * 1 ether;    

    uint256 public icoStartTime;
    uint256 public icoFinalizedTime;

    address public tokenOwner;
    address public crowdSaleOwner;
    address public vestingOwner;

    address public saleContract;
    address public vestingContract;
    bool public fundraising = true;

    mapping (address => bool) public frozenAccounts;
    event FrozenFund(address target, bool frozen);


    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        } else {
            require(fundraising == false);
            _;
        }
    }
    
     
    constructor(address _tokenOwner,address _crowdSaleOwner, address _vestingOwner ) public Owned(_tokenOwner) {

        symbol ="SYP";
        name = "Synapsecoin";
        decimals = 18;
        tokenOwner = _tokenOwner; 
        crowdSaleOwner = _crowdSaleOwner;
        vestingOwner = _vestingOwner;
        totalSupply = 990000000 * 1 ether;
        balances[_tokenOwner] = balances[_tokenOwner].add(managementTokens);
        balances[_crowdSaleOwner] = balances[_crowdSaleOwner].add(tokensForSale);        
        balances[_vestingOwner] = balances[_vestingOwner].add(vestingTokens);
        emit Transfer(address(0), _tokenOwner, managementTokens);
        emit Transfer(address(0), _crowdSaleOwner, tokensForSale);    
        emit Transfer(address(0), _vestingOwner, vestingTokens);        
    }

     
    function transfer(address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(2) returns (bool success) {
        
        require(_value>0);
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        if(investorIsVested[msg.sender]==true )
        {
            require(now >= icoFinalizedTime.add(vestingTime)); 
            super.transfer(_to,_value);
            return true;

        }
        else {
            super.transfer(_to,_value);
            return true;
        }

    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(3) returns (bool) {
        require(_value>0);
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[_from]);
        if(investorIsVested[_from]==true )
        {
            require(now >= icoFinalizedTime.add(vestingTime)); 
            super.transferFrom(_from,_to,_value);
            return true;

        }
        else {
            
           super.transferFrom(_from,_to,_value);
           return true;
        }    }
    

     
    function activateSaleContract(address _saleContract) public whenNotPaused {
        require(msg.sender == crowdSaleOwner);
        require(_saleContract != address(0));
        require(saleContract == address(0));        
        saleContract = _saleContract;
        icoStartTime = now;

    }
     
     
    function activateVestingContract(address _vestingContract) public whenNotPaused  {
        require(msg.sender == vestingOwner);        
        require(_vestingContract != address(0));
        require(vestingContract == address(0));
        vestingContract = _vestingContract;
        
    }
    
     
    function sendBounty(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(bountyTokens >= _value);
        bountyTokens = bountyTokens.sub(_value);
        return super.transfer(_to, _value);  
        }    

     
    function sendMarketingTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(marketingTokens >= _value);
        marketingTokens = marketingTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

     
    function sendExpansionTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(expansionTokens >= _value);
        expansionTokens = expansionTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

     
    function sendAdvisorTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(advisorTokens >= _value);
        advisorTokens = advisorTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

     
    function isContract(address _address) private view returns (bool is_contract) {
        uint256 length;
        assembly {
         
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
     
    function saleTransfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(saleContract != address(0),'sale address is not activated');
        require(msg.sender == saleContract,'caller is not crowdsale contract');
        require(!frozenAccounts[_to],'account is freezed');
        return super.transferFrom(crowdSaleOwner,_to, _value);
            
    }

     
    function vestingTransfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(icoFinalizedTime == 0,'ico is finalised');
        require(vestingContract != address(0));
        require(msg.sender == vestingContract,'caller is not a vesting contract');
        investorIsVested[_to] = true;
        return super.transferFrom(vestingOwner,_to, _value);
    }

     
    function finalize() external whenNotPaused returns(bool){
        require(fundraising != false); 
        require(msg.sender == saleContract);
        fundraising = false;
        icoFinalizedTime = now;
        return true;
    }

    
   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze);  
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        require(isContract(tokenAddress));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function () external payable {
        revert();
    }
    
}