 

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

 
 
 
contract ICONIC_NIC is Ownable, TokenERC20 {
    using SafeMath for uint256;

    mapping (address => bool)    public  frozenAccount;
    mapping (address => uint256) public freezingPeriod;  

    mapping (address => bool) public exchangesAccounts;

    address public bountyManagerAddress;  
    address public bountyManagerDistributionContract = 0x0;  

    address public fundAccount; 	 
    bool public isSetFund = false;	 

    uint256 public creationDate;

    uint256 public constant frozenDaysForAdvisor       = 186;  
    uint256 public constant frozenDaysForBounty        = 186;
    uint256 public constant frozenDaysForEarlyInvestor = 51;
    uint256 public constant frozenDaysForICO           = 65;   
    uint256 public constant frozenDaysForPartner       = 369;
    uint256 public constant frozenDaysForPreICO        = 51;

     
    modifier onlyBountyManager(){
        require((msg.sender == bountyManagerDistributionContract) || (msg.sender == bountyManagerAddress));
        _;
    }

     
    modifier onlyFund(){
        require(msg.sender == fundAccount);
        _;
    }

     
    event FrozenFunds(address target, bool frozen);

     
    function ICONIC_NIC(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public 
    {
         
        creationDate = now;

         
        _initializeAccount(0x85abeD924205bbE4D32077E596e45B9F40AAF8d9, frozenDaysForPartner, 2115007);
        _initializeAccount(0xf7817F08C2660970014a086a4Ba679636e73E8ef, frozenDaysForPartner, 8745473);
        _initializeAccount(0x2c208677f8BAB9c6A44bBe3554f36d2440C9b6C2, frozenDaysForPartner, 3498189);
        _initializeAccount(0x3689B9a43ab904D70f396B2A27DDac0E5885CF68, frozenDaysForPartner, 26236419);
        _initializeAccount(0x245B058C8c256D011742aF5Faa296198735eE0Ee, frozenDaysForPartner, 211501);
        _initializeAccount(0xeEFA9f8f39aaF1d1Ed160Ac2465e937A8F154182, frozenDaysForPartner, 1749095);

         
        _initializeAccount(0x4718bB26bCE82459913aaCA09a006Daa517F1c0E, frozenDaysForEarlyInvestor, 225000);
        _initializeAccount(0x8cC1d930e685c977EFcEf9dc412D3ADbE11B84c1, frozenDaysForEarlyInvestor, 2678100);

         
        _initializeAccount(0x272c41b76Bad949739839E6BB5Eb9f2B0CDFD95D, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x3a5cd9E7ccFE4DD5484335F3AF30CCAba95D07C3, frozenDaysForAdvisor, 528752);
        _initializeAccount(0xA10CC5321E834c41137f2150A9b0f2Aa1c5016, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x59B640c5663E5e79Ce9F68EBbC28454490DbA7B8, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0xdCA69FbfEFf48851ceC91B57610FA60ABc27Af3B, frozenDaysForAdvisor, 3172510);
        _initializeAccount(0x332526F0082d4d385F9Ef393841f44c1bf813D8c, frozenDaysForAdvisor, 3172510);
        _initializeAccount(0xf6B436cBB177777A170819128EbBeF0715101eA2, frozenDaysForAdvisor, 1275000);
        _initializeAccount(0xB76a63Fa7658aD0480986e609b9d5b1f1b6B53b9, frozenDaysForAdvisor, 1487500);
        _initializeAccount(0x2bC240bc0D28725dF790706da7663413ac8Fa5ee, frozenDaysForAdvisor, 2125000);
        _initializeAccount(0x32Aa02961fa15e74D896C45A428E5d1884af2217, frozenDaysForAdvisor, 1057503);
        _initializeAccount(0x5340EC716a00Db16a9C289369e4b30ae897C25d3, frozenDaysForAdvisor, 1586255);
        _initializeAccount(0x39d6FDB4B0f8dfE39EC0b4fE5Dd9B2f66e30f8D1, frozenDaysForAdvisor, 846003);
        _initializeAccount(0xCe438C52D95ee47634f9AeE36de5488D0d5D0FBd, frozenDaysForAdvisor, 250000);

         
        bountyManagerAddress = 0xA9939938e6BAcC0b748045be80FD9E958898eB79;
        _initializeAccount(bountyManagerAddress, frozenDaysForBounty, 15000000);
    }

     
    function setFundAccount(address _address) onlyOwner public{
        require (_address != 0x0);
        require (!isSetFund);
        fundAccount = _address;
        isSetFund = true;    
    }

     
    function addExchangeTestAccounts(address _address) onlyOwner public{
        require(_address != 0x0);
        exchangesAccounts[_address] = true;
    }

     
    function removeExchangeTestAccounts(address _address) onlyOwner public{
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