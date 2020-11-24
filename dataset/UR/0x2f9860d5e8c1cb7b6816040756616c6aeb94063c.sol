 

pragma solidity ^0.4.4;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
} 

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool success)  {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance)  {
        return balances[_owner];
    }
 
}
 
 
contract StandardToken is ERC20, BasicToken {
 
    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)  {
        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success)  {

        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
}
 
 
contract Ownable {
    
    address public owner;

     
    function Ownable()  public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));      
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

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount); 
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool)  {
        mintingFinished = true;
        MintFinished();
        return true;
    }
  
}


 
contract GWTToken is MintableToken {
    
    string public constant name = "Global Wind Token";
    
    string public constant symbol = "GWT";
    
    uint32 public constant decimals = 18; 

}

 
contract GWTCrowdsale is Ownable {
    using SafeMath for uint;

    uint public supplyLimit;          

    address ethAddress;               
    uint saleStartTimestamp;          

    uint public currentStageNumber;   
    uint currentStageStartTimestamp;  
    uint currentStageEndTimestamp;    
    uint currentStagePeriodDays;      
    uint public baseExchangeRate;     
    uint currentStageMultiplier;      

    uint constant M = 1000000000000000000;   

    uint[] _percs = [40, 30, 25, 20, 15, 10, 5, 0, 0];   
    uint[] _days  = [42, 1, 27, 1, 7, 7, 7, 14, 0];       

     
    uint PrivateSaleLimit = M.mul(420000000);
    uint PreSaleLimit = M.mul(1300000000);
    uint TokenSaleLimit = M.mul(8400000000);
    uint RetailLimit = M.mul(22490000000);

     
    uint TokensaleRate = M.mul(160000);
    uint RetailRate = M.mul(16000);

    GWTToken public token = new GWTToken();  

     
    modifier isActive() {
        require(isInActiveStage());
        _;
    }

    function isInActiveStage() private returns(bool) {
        if (currentStageNumber == 8) return true;
        if (now >= currentStageStartTimestamp && now <= currentStageEndTimestamp){
            return true;
        }else if (now < currentStageStartTimestamp) {
            return false;
        }else if (now > currentStageEndTimestamp){
            if (currentStageNumber == 0 || currentStageNumber == 2 || currentStageNumber == 7) return false;
            switchPeriod();
             
             
             
            return true;
        }
         
        return false;
    }

     
    function switchPeriod() private onlyOwner {
        if (currentStageNumber == 8) return;

        currentStageNumber++;
        currentStageStartTimestamp = currentStageEndTimestamp;  
        currentStagePeriodDays = _days[currentStageNumber];
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
        currentStageMultiplier = _percs[currentStageNumber];

        if(currentStageNumber == 0 ){
            supplyLimit = PrivateSaleLimit;
        } else if(currentStageNumber < 3){
            supplyLimit = PreSaleLimit;
        } else if(currentStageNumber < 8){
            supplyLimit = TokenSaleLimit;
        } else {
             
            baseExchangeRate = RetailRate;
            supplyLimit = RetailLimit;
        }
    }

    function setStage(uint _index) public onlyOwner {
        require(_index >= 0 && _index < 9);
        
        if (_index == 0) return startPrivateSale();
        currentStageNumber = _index - 1;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

     
    function setRate(uint _rate) public onlyOwner {
        baseExchangeRate = _rate;
    }

     
    function setBonus(uint _bonus) public onlyOwner {
        currentStageMultiplier = _bonus;
    }

    function setTokenOwner(address _newTokenOwner) public onlyOwner {
        token.transferOwnership(_newTokenOwner);
    }

     
    function setPeriodLength(uint _length) public onlyOwner {
         
        currentStagePeriodDays = _length;
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
    }

     
    function modifySupplyLimit(uint _new) public onlyOwner {
        if (_new >= token.totalSupply()){
            supplyLimit = _new;
        }
    }

     
    function mintFor(address _to, uint _val) public onlyOwner isActive payable {
        require(token.totalSupply() + _val <= supplyLimit);
        token.mint(_to, _val);
    }

     
     
    function closeMinting() public onlyOwner {
        token.finishMinting();
    }

     
    function startPrivateSale() public onlyOwner {
        currentStageNumber = 0;
        currentStageStartTimestamp = now;
        currentStagePeriodDays = _days[0];
        currentStageMultiplier = _percs[0];
        supplyLimit = PrivateSaleLimit;
        currentStageEndTimestamp = currentStageStartTimestamp + currentStagePeriodDays * 1 days;
        baseExchangeRate = TokensaleRate;
    }

    function startPreSale() public onlyOwner {
        currentStageNumber = 0;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    function startTokenSale() public onlyOwner {
        currentStageNumber = 2;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

    function endTokenSale() public onlyOwner {
        currentStageNumber = 7;
        currentStageEndTimestamp = now;
        switchPeriod();
    }

     
     
    function GWTCrowdsale() public {
         
        ethAddress = 0xB93B2be636e39340f074F0c7823427557941Be42;   
         
        saleStartTimestamp = now;                                        
        startPrivateSale();
    }

    function changeEthAddress(address _newAddress) public onlyOwner {
        ethAddress = _newAddress;
    }

     
    function createTokens() public isActive payable {
        uint tokens = baseExchangeRate.mul(msg.value).div(1 ether);  

        if (currentStageMultiplier > 0 && currentStageEndTimestamp > now) {             
            tokens = tokens + tokens.div(100).mul(currentStageMultiplier);
        }
         
        require(token.totalSupply() + tokens <= supplyLimit);
        ethAddress.transfer(msg.value);    
        token.mint(msg.sender, tokens);  
    }

     
    function() external payable {
        createTokens();  
    }

}