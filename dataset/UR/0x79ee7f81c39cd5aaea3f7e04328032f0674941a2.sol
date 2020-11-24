 

pragma solidity  ^0.4.23;

 

 
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

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
    constructor () public {
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

 
interface IERC20 {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function totalSupply() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface ISecurityToken {


     
    function addToWhitelist(address _whitelistAddress) public returns (bool success);

     
    function addToWhitelistMulti(address[] _whitelistAddresses) external returns (bool success);

     
    function addToBlacklist(address _blacklistAddress) public returns (bool success);

     
    function addToBlacklistMulti(address[] _blacklistAddresses) external returns (bool success);

     
    function decimals() view external returns (uint);


     
     
    function isWhiteListed(address _user) external view returns (bool);
}

 
contract SecurityToken is IERC20, Ownable, ISecurityToken {

    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint public decimals;  
    string public version;
    uint public totalSupply;
    uint public tokenPrice;
    bool public exchangeEnabled;    
    bool public codeExportEnabled;
    address public commissionAddress;            
    uint public deploymentCost;                  
    uint public tokenOnlyDeploymentCost;         
    uint public exchangeEnableCost;              
    uint public codeExportCost;                  
    string public securityISIN;


     
    struct Shareholder {                         
        bool allowed;                            
        uint receivedAmt;
        uint releasedAmt;
        uint vestingDuration;
        uint vestingCliff;
        uint vestingStart;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    mapping(address => Shareholder) public shareholders;  


    modifier onlyWhitelisted(address _to) {
        require(shareholders[_to].allowed && shareholders[msg.sender].allowed);
        _;
    }


    modifier onlyVested(address _from) {

        require(availableAmount(_from) > 0);
        _;
    }

     
    constructor (
        uint _initialSupply,
        string _tokenName,
        string _tokenSymbol,
        uint _decimalUnits,        
        string _version,                       
        uint _tokenPrice,
        string _securityISIN
                        ) public payable
    {

        totalSupply = _initialSupply * (10**_decimalUnits);                                             
        name = _tokenName;           
        symbol = _tokenSymbol;       
        decimals = _decimalUnits;    
        version = _version;          
        tokenPrice = _tokenPrice;    
        securityISIN = _securityISIN; 
            
        balances[owner] = totalSupply;    

        deploymentCost = 25e17;             
        tokenOnlyDeploymentCost = 15e17;
        exchangeEnableCost = 15e17;
        codeExportCost = 1e19;   

        codeExportEnabled = true;
        exchangeEnabled = true;  
            
        commissionAddress = 0x80eFc17CcDC8fE6A625cc4eD1fdaf71fD81A2C99;                                   
        commissionAddress.transfer(msg.value);       
        addToWhitelist(owner);  

    }

    event LogTransferSold(address indexed to, uint value);
    event LogTokenExchangeEnabled(address indexed caller, uint exchangeCost);
    event LogTokenExportEnabled(address indexed caller, uint enableCost);
    event LogNewWhitelistedAddress( address indexed shareholder);
    event LogNewBlacklistedAddress(address indexed shareholder);
    event logVestingAllocation(address indexed shareholder, uint amount, uint duration, uint cliff, uint start);
    event logISIN(string isin);



    function updateISIN(string _securityISIN) external onlyOwner() {

        bytes memory tempISIN = bytes(_securityISIN);

        require(tempISIN.length > 0);   
        securityISIN = _securityISIN; 
        emit logISIN(_securityISIN);  
    }

    function allocateVestedTokens(address _to, uint _value, uint _duration, uint _cliff, uint _vestingStart ) 
                                  external onlyWhitelisted(_to) onlyOwner() returns (bool) 
    {

        require(_to != address(0));        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);        
        if (shareholders[_to].receivedAmt == 0) {
            shareholders[_to].vestingDuration = _duration;
            shareholders[_to].vestingCliff = _cliff;
            shareholders[_to].vestingStart = _vestingStart;
        }
        shareholders[_to].receivedAmt = shareholders[_to].receivedAmt.add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        emit logVestingAllocation(_to, _value, _duration, _cliff, _vestingStart);
        return true;
    }

    function availableAmount(address _from) public view returns (uint256) {                
        
        if (block.timestamp < shareholders[_from].vestingCliff) {            
            return balanceOf(_from).sub(shareholders[_from].receivedAmt);
        } else if (block.timestamp >= shareholders[_from].vestingStart.add(shareholders[_from].vestingDuration)) {
            return balanceOf(_from);
        } else {
            uint totalVestedBalance = shareholders[_from].receivedAmt;
            uint totalAvailableVestedBalance = totalVestedBalance.mul(block.timestamp.sub(shareholders[_from].vestingStart)).div(shareholders[_from].vestingDuration);
            uint lockedBalance = totalVestedBalance - totalAvailableVestedBalance;
            return balanceOf(_from).sub(lockedBalance);
        }
    }

     
     
     
    function enableExchange(uint _tokenPrice) public payable {
        
        require(!exchangeEnabled);
        require(exchangeEnableCost == msg.value);
        exchangeEnabled = true;
        tokenPrice = _tokenPrice;
        commissionAddress.transfer(msg.value);
        emit LogTokenExchangeEnabled(msg.sender, _tokenPrice);                          
    }

     
    function enableCodeExport() public payable {   
        
        require(!codeExportEnabled);
        require(codeExportCost == msg.value);     
        codeExportEnabled = true;
        commissionAddress.transfer(msg.value);  
        emit LogTokenExportEnabled(msg.sender, msg.value);        
    }

     
    function swapTokens() public payable onlyWhitelisted(msg.sender) {     

        require(exchangeEnabled);   
        uint tokensToSend;
        tokensToSend = (msg.value * (10**decimals)) / tokenPrice; 
        require(balances[owner] >= tokensToSend);
        balances[msg.sender] = balances[msg.sender].add(tokensToSend);
        balances[owner] = balances[owner].sub(tokensToSend);
        owner.transfer(msg.value);
        emit Transfer(owner, msg.sender, tokensToSend);
        emit LogTransferSold(msg.sender, tokensToSend);       
    }

     
     
     
    function mintToken(address _target, uint256 _mintedAmount) public onlyWhitelisted(_target) onlyOwner() {        
        
        balances[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        emit Transfer(0, _target, _mintedAmount);       
    }
  
     
     
     
     
    function transfer(address _to, uint _value) external onlyVested(_to) onlyWhitelisted(_to)  returns(bool) {

        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) 
                          external onlyVested(_to)  onlyWhitelisted(_to) returns(bool success) {

        require(_to != address(0));
        require(balances[_from] >= _value);  
        require(_value <= allowed[_from][msg.sender]);  

        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint _value) external returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) external view returns(uint remaining) {
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

      
    function addToWhitelist(address _whitelistAddress) onlyOwner public returns (bool success) {       
        shareholders[_whitelistAddress].allowed = true;
        emit LogNewWhitelistedAddress(_whitelistAddress);
        return true;
    }

     
    function addToWhitelistMulti(address[] _whitelistAddresses) onlyOwner external returns (bool success) {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            addToWhitelist(_whitelistAddresses[i]);
        }
        return true;
    }

     
    function addToBlacklist(address _blacklistAddress) onlyOwner public returns (bool success) {
        require(shareholders[_blacklistAddress].allowed);
        shareholders[_blacklistAddress].allowed = false;
        emit LogNewBlacklistedAddress(_blacklistAddress);
        return true;
    }

     
    function addToBlacklistMulti(address[] _blacklistAddresses) onlyOwner external returns (bool success) {
        for (uint256 i = 0; i < _blacklistAddresses.length; i++) {
            addToBlacklist(_blacklistAddresses[i]);
        }
        return true;
    }

     
     
    function isWhiteListed(address _user) external view returns (bool) {

        return shareholders[_user].allowed;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function decimals() external view returns (uint) {
        return decimals;
    }

}