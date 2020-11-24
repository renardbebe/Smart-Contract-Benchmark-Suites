 

pragma solidity ^0.4.15;

 

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract basicToken {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address, uint256) public returns (bool);
    function allowance(address, address) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Standard is basicToken{

    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        require (_to != 0x0);                                
        require (balances[msg.sender] > _value);             
        require (balances[_to] + _value > balances[_to]);    
        _transfer(msg.sender, _to, _value);                  
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require (_to != 0x0);                                
        require (balances[msg.sender] > _value);             
        require (balances[_to] + _value > balances[_to]);    
        require (allowed[_from][msg.sender] >= _value);      
        _transfer(msg.sender, _to, _value);                  
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract HydroToken is ERC20Standard, owned{
    event Authenticate(uint partnerId, address indexed from, uint value);      
    event Whitelist(uint partnerId, address target, bool whitelist);           
    event Burn(address indexed burner, uint256 value);                         

    struct partnerValues {
        uint value;
        uint challenge;
    }

    struct hydrogenValues {
        uint value;
        uint timestamp;
    }

    string public name = "Hydro";
    string public symbol = "HYDRO";
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (uint => mapping (address => bool)) public whitelist;
    mapping (uint => mapping (address => partnerValues)) public partnerMap;
    mapping (uint => mapping (address => hydrogenValues)) public hydroPartnerMap;

     
    function HydroToken() public {
        totalSupply = 11111111111 * 10**18;
        balances[msg.sender] = totalSupply;                  
    }

     
    function whitelistAddress(address _target, bool _whitelistBool, uint _partnerId) public onlyOwner {
        whitelist[_partnerId][_target] = _whitelistBool;
        Whitelist(_partnerId, _target, _whitelistBool);
    }

     
    function authenticate(uint _value, uint _challenge, uint _partnerId) public {
        require(whitelist[_partnerId][msg.sender]);          
        require(balances[msg.sender] > _value);              
        require(hydroPartnerMap[_partnerId][msg.sender].value == _value);
        updatePartnerMap(msg.sender, _value, _challenge, _partnerId);
        transfer(owner, _value);
        Authenticate(_partnerId, msg.sender, _value);
    }

    function burn(uint256 _value) public onlyOwner {
        require(balances[msg.sender] > _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
    }

    function checkForValidChallenge(address _sender, uint _partnerId) public view returns (uint value){
        if (hydroPartnerMap[_partnerId][_sender].timestamp > block.timestamp){
            return hydroPartnerMap[_partnerId][_sender].value;
        }
        return 1;
    }

     
    function updatePartnerMap(address _sender, uint _value, uint _challenge, uint _partnerId) internal {
        partnerMap[_partnerId][_sender].value = _value;
        partnerMap[_partnerId][_sender].challenge = _challenge;
    }

     
    function updateHydroMap(address _sender, uint _value, uint _partnerId) public onlyOwner {
        hydroPartnerMap[_partnerId][_sender].value = _value;
        hydroPartnerMap[_partnerId][_sender].timestamp = block.timestamp + 1 days;
    }

     
    function validateAuthentication(address _sender, uint _challenge, uint _partnerId) public constant returns (bool _isValid) {
        if (partnerMap[_partnerId][_sender].value == hydroPartnerMap[_partnerId][_sender].value
        && block.timestamp < hydroPartnerMap[_partnerId][_sender].timestamp
        && partnerMap[_partnerId][_sender].challenge == _challenge){
            return true;
        }
        return false;
    }
}