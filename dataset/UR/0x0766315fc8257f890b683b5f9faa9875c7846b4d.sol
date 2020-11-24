 

pragma solidity ^0.4.10;
 

contract Burner {
    function burnILF(address , uint ) {}
}

contract StandardToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract ILF is StandardToken {

    mapping(address => bool) public previousMinters;
    mapping(address => bool) public previousBurners;
    bool public minterChangeable = true;
    bool public burnerChangeable = true;
    bool public manualEmissionEnabled = true;
    string public constant symbol = "ILF";
    string public constant name = "ICO Lab Fund Token";
    uint8 public constant decimals = 8;
    address public burnerAddress;
    address public minterAddress;
    address public ILFManager;
    address public ILFManagerCandidate;   
    bytes32 public ILFManagerCandidateKeyHash; 
    Burner burner;
                                           
    event Emission(address indexed emitTo, uint amount);
    event Burn(address indexed burnFrom, uint amount);

     
     
    function ILF(address _ILFManager){
        ILFManager = _ILFManager;
    }

     
     
     
    function emitToken(address emitTo, uint amount) {
        assert(amount>0);
        assert(msg.sender == minterAddress || (msg.sender == ILFManager && manualEmissionEnabled));
        balances[emitTo] += amount;
        totalSupply += amount;
        Emission(emitTo, amount);
    }

     
     
     
    function burnToken(address burnFrom, uint amount) external onlyBurner {
        assert(amount <= balances[burnFrom] && amount <= totalSupply);
        balances[burnFrom] -= amount;
        totalSupply -= amount;
        Burn(burnFrom, amount);
    }

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        assert(!previousBurners[_to] && !previousMinters[_to] && _to != minterAddress);
        
        if (balances[msg.sender] >= _value && _value > 0 && _to != address(0) && _to != address(this)) { 
            if (_to == burnerAddress) {
                burner.burnILF(msg.sender, _value);
            }
            else {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
            }
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        assert(!previousBurners[_to] && !previousMinters[_to] && _to != minterAddress);

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && _to != address(0) && _to != address(this)) {
            if (_to == burnerAddress) {
                burner.burnILF(_from, _value);
            }
            else {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
            }
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
    function changeILFManager(address candidate, bytes32 keyHash) external onlyILFManager {
        ILFManagerCandidate = candidate;
        ILFManagerCandidateKeyHash = keyHash;
    }

     
     
    function acceptManagement(string key) external onlyManagerCandidate(key) {
        ILFManager = ILFManagerCandidate;
    }

     
     
    function changeMinter(address _minterAddress) external onlyILFManager {
        assert(minterChangeable);
        previousMinters[minterAddress]=true;
        minterAddress = _minterAddress;
    }

     
     
    function sealMinter(bytes32 _hash) onlyILFManager {
        assert(sha3(minterAddress)==_hash);
        minterChangeable = false; 
    }
    
     
     
    function changeBurner(address _burnerAddress) external onlyILFManager {
        assert(burnerChangeable);
        burner = Burner(_burnerAddress);
        previousBurners[burnerAddress]=true;
        burnerAddress = _burnerAddress;
    }

     
     
    function sealBurner(bytes32 _hash) onlyILFManager {
        assert(sha3(burnerAddress)==_hash);
        burnerChangeable = false; 
    }

     
     
    function disableManualEmission(bytes32 _hash) onlyILFManager {
        assert(sha3(ILFManager)==_hash);
        manualEmissionEnabled = false; 
    }

    modifier onlyILFManager() {
        assert(msg.sender == ILFManager);
        _;
    }

    modifier onlyMinter() {
        assert(msg.sender == minterAddress);
        _;
    }

    modifier onlyBurner() {
        assert(msg.sender == burnerAddress);
        _;
    }

    modifier onlyManagerCandidate(string key) {
        assert(msg.sender == ILFManagerCandidate);
        assert(sha3(key) == ILFManagerCandidateKeyHash);
        _;
    }

}