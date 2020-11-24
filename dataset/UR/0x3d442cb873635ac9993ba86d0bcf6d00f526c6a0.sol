 

pragma solidity ^0.4.18;


 
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);

         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);

         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);

         
        balanceOf[_from] = balanceOf[_from].sub(_value);

         
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
         
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }	
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 
contract CinociCoin is Ownable, TokenERC20 {
    using SafeMath for uint256;

    mapping (address => bool)    public  frozenAccount;
    mapping (address => uint256) public freezingPeriod;  

    mapping (address => bool) public exchangesAccounts;

    address public bountyManagerAddress;
    address public bountyManagerDistributionContract = 0x0;

    address public fundAccount; 	 
    bool public isSetFund = false;	 

    uint256 public creationDate;
    uint256 public constant frozenDaysForAdvisor       = 187;  
    uint256 public constant frozenDaysForBounty        = 187;
    uint256 public constant frozenDaysForEarlyInvestor = 52;
    uint256 public constant frozenDaysForICO           = 66;   
    uint256 public constant frozenDaysForPartner       = 370;
    uint256 public constant frozenDaysForPreICO        = 52;
    uint256 public constant frozenDaysforTestExchange  = 0;

     
    modifier onlyBountyManager(){
        require((msg.sender == bountyManagerDistributionContract) || (msg.sender == bountyManagerAddress));
        _;
    }

    modifier onlyExchangesAccounts(){
        require(exchangesAccounts[msg.sender]);
        _;
    }

     
    modifier onlyFund(){
        require(msg.sender == fundAccount);
        _;
    }

     
    event FrozenFunds(address target, bool frozen);

     
    function CinociCoin(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public 
    {
         
        creationDate = now;

        address advisor = 0x32c5Ec858c52F8635Bd92e44d8797e5d356eBd05;
        address bountyManager = 0xdDa9bcf30AFDC40a5fFa6e1b6f70ef030A3E32f4;
        address earlyInvestor = 0x02FF2bA62440c92D2A02D95Df6fc233eA68c2091;
        address partner = 0x6A45baAEb21D49fD85B309235Ef2920d3A648858;
        address exchange1 = 0x8Bd10d3383504a12FD27A1Fd5c0E7bCeae3C8997;
        address exchange2 = 0xce8b8e7113072C5308cec669375E0Ab364b3435C;

        _initializeAccount(partner, frozenDaysForPartner, 30000000);
        _initializeAccount(advisor, frozenDaysForAdvisor, 20000000);
        _initializeAccount(earlyInvestor, frozenDaysForEarlyInvestor, 10000000);  
        _initializeAccount(exchange1, frozenDaysforTestExchange, 1000);
        _initializeAccount(exchange2, frozenDaysforTestExchange, 1000);
        _initializeAccount(bountyManager, frozenDaysForBounty, 15000000);
        bountyManagerAddress = bountyManager;
    }

     
    function setFundAccount(address _address) onlyOwner public{
        require (_address != 0x0);
        require (!isSetFund);
        fundAccount = _address;
        isSetFund = true;    
    }

    function addExchangeAccounts(address _address) onlyOwner public{
        require(_address != 0x0);
        exchangesAccounts[_address] = true;
    }

    function removeExchangeAccounts(address _address) onlyOwner public{
        delete exchangesAccounts[_address];
    }

     
    function _initializeAccount(address _address, uint _frozenDays, uint _value) internal{
        _transfer(msg.sender, _address, _value * 10 ** uint256(decimals));
        freezingPeriod[_address] = _frozenDays;
        _freezeAccount(_address, true);
    }

     
    function _isTransferAllowed( address _address ) view public returns (bool)
    {
         
        if( now >= creationDate + freezingPeriod[_address] * 1 days ){
            return ( true );
        } else {
            return ( false );
        }
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                   
        require (balanceOf[_from] >= _value);                   
        require (balanceOf[_to].add(_value) > balanceOf[_to]);  

         
        if(_isTransferAllowed(_from)){ 
            _setFreezingPeriod(_from, false, 0);
        }

         
        if(_isTransferAllowed(_to)){
            _setFreezingPeriod(_to, false, 0);
        }

        require(!frozenAccount[_from]);      
        require(!frozenAccount[_to]);        
        
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         

        emit Transfer(_from, _to, _value);
    }
    
     
    function _tokenDelivery(address _from, address _to, uint _value, uint _frozenDays) internal {
        freezingPeriod[_to] = 0;
        _freezeAccount(_to, false);
        _transfer(_from, _to, _value);
        freezingPeriod[_to] = _frozenDays;
        _freezeAccount(_to, true); 
    }
    
     
    function preICOTokenDelivery(address _to, uint _value) onlyOwner public {
        _tokenDelivery(msg.sender, _to, _value, frozenDaysForPreICO);
    }
    
     
    function ICOTokenDelivery(address _to, uint _value) onlyOwner public {
        _tokenDelivery(msg.sender, _to, _value, frozenDaysForICO);
    }
    
    function setBountyDistributionContract(address _contractAddress) onlyOwner public {
        bountyManagerDistributionContract = _contractAddress;
    }

     
    function bountyTransfer(address _to, uint _value) onlyBountyManager public {
        _freezeAccount(bountyManagerAddress, false);
        _tokenDelivery(bountyManagerAddress, _to, _value, frozenDaysForBounty);
        _freezeAccount(bountyManagerAddress, true);
    }

     
    function daysToUnfreeze(address _address) public view returns (uint256) {
        require(_address != 0x0);

         
        uint256 _now = now;
        uint256 result = 0;

        if( _now <= creationDate + freezingPeriod[_address] * 1 days ) {
             
            uint256 finalPeriod = (creationDate + freezingPeriod[_address] * 1 days) / 1 days;
            uint256 currePeriod = _now / 1 days;
            result = finalPeriod - currePeriod;
        }

        return result;
    }

     
    function _freezeAccount(address target, bool freeze) internal {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        _freezeAccount(target, freeze);
    }
    
     
    function _setFreezingPeriod(address _target, bool _freeze, uint256 _days) internal {
        _freezeAccount(_target, _freeze);
        freezingPeriod[_target] = _days;
    }
    
     
    function setFreezingPeriod(address _target, bool _freeze, uint256 _days) onlyOwner public {
        _setFreezingPeriod(_target, _freeze, _days);
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
         
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        if( _isTransferAllowed(msg.sender) )  {
            _setFreezingPeriod(msg.sender, false, 0);
        }
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
         
        if( _isTransferAllowed(msg.sender) ) {
            _setFreezingPeriod(msg.sender, false, 0);
        }

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        return _burn(msg.sender, _value);
    }

     
    function _burn(address _from, uint256 _value) internal returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(_from, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                                      
        require(_value <= allowance[_from][msg.sender]);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        return _burn(_from, _value);
    }

     
    function redemptionBurn(address _from, uint256 _value) onlyFund public{
        _burn(_from, _value);
    }   
}