 

pragma solidity ^0.4.16;

 
contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));      
        owner = newOwner;
    }

}

contract CRTTToken is Ownable {
    
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    string public constant name = "CRTT Token";
    string public constant symbol = "CRTT";
    uint8 public constant decimals = 18;

    uint256 constant restrictedPercent = 25;  
    address constant restrictedAddress = 0xDFfc94eb3e4cA1fef33a2aF22ECd66c724707388;
    uint256 constant mintFinishTime = 1551448800;
    uint256 constant transferAllowTime = 1552140000;
    uint256 public constant hardcap = 299000000 * 1 ether;
    
    bool public transferAllowed = false;
    bool public mintingFinished = false;
    
    modifier whenTransferAllowed() {
        require(transferAllowed || now > transferAllowTime);
        _;
    }

    modifier saleIsOn() {
        require(now < mintFinishTime);
        _;
    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
  
    function transfer(address _to, uint256 _value) whenTransferAllowed public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
         
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) whenTransferAllowed public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
    
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
   
    function allowTransfer() onlyOwner public {
        transferAllowed = true;
    }
    
    function batchMint(address[] _to, uint256[] _value) onlyOwner saleIsOn canMint public returns (bool) {
        require(_to.length == _value.length);
        
        uint256 valueSum = 0;
        
        for (uint256 i = 0; i < _to.length; i++) {
            require(_to[i] != address(0));
            require(_value[i] > 0);
            
            balances[_to[i]] = balances[_to[i]] + _value[i];
            assert(balances[_to[i]] >= _value[i]);
            Transfer(address(0), _to[i], _value[i]);
            
            valueSum = valueSum + _value[i];
            assert(valueSum >= _value[i]);
        }
        
        uint256 restrictedSum = valueSum * restrictedPercent;
        assert(restrictedSum / valueSum == restrictedPercent);
        restrictedSum = restrictedSum / (100 - restrictedPercent);
        
        balances[restrictedAddress] = balances[restrictedAddress] + restrictedSum;
        assert(balances[restrictedAddress] >= restrictedSum);
        Transfer(address(0), restrictedAddress, restrictedSum);
        
        uint256 totalSupplyNew = totalSupply + valueSum;
        assert(totalSupplyNew >= valueSum);
        totalSupplyNew = totalSupplyNew + restrictedSum;
        assert(totalSupplyNew >= restrictedSum);
        
        require(totalSupplyNew <= hardcap);
        totalSupply = totalSupplyNew;
        
        return true;
    }
    
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
    
     
    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
         
         
        balances[msg.sender] = balances[msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        totalSupply = totalSupply - _value;
        Burn(_from, _value);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event MintFinished();

    event Burn(address indexed burner, uint256 value);

}