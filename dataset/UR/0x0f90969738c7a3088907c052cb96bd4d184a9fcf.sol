 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
 
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
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
     
    function pause() onlyOwner whenNotPaused public
    {paused = true;
        Pause();
    }
     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool){
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
contract MintableToken is StandardToken, Ownable {event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    modifier canMint() {require(!mintingFinished);
        _;
    }
     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
     
    function finishMinting() onlyOwner canMint public returns (bool) {mintingFinished = true;
        MintFinished();
        return true;}
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
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
         
         
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
 
contract SimpleToken is StandardToken {
    string public constant name = "SimpleToken";
     
    string public constant symbol = "SIM";
     
    uint8 public constant decimals = 18;
     
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));
     
    function SimpleToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}

 
contract BiometricLockable is Ownable {
    event BiometricLocked(address beneficiary, bytes32 sha);
    event BiometricUnlocked(address beneficiary);

    address BOPS;
    mapping(address => bool) biometricLock;
    mapping(bytes32 => bool) biometricCompleted;
    mapping(bytes32 => uint256) biometricNow;
     
    function bioLock() external {
        uint rightNow = now;
        bytes32 sha = keccak256("bioLock", msg.sender, rightNow);
        biometricLock[msg.sender] = true;
        biometricNow[sha] = rightNow;
        BiometricLocked(msg.sender, sha);
    }
     
    function bioUnlock(bytes32 sha, uint8 v, bytes32 r, bytes32 s) external {
        require(biometricLock[msg.sender]);
        require(!biometricCompleted[sha]);
        bytes32 bioLockSha = keccak256("bioLock", msg.sender, biometricNow[sha]);
        require(sha == bioLockSha);
        require(verify(sha, v, r, s) == true);
        biometricLock[msg.sender] = false;
        BiometricUnlocked(msg.sender);
        biometricCompleted[sha] = true;
    }

    function isSenderBiometricLocked() external view returns (bool) {
        return biometricLock[msg.sender];
    }

    function isBiometricLocked(address _beneficiary) internal view returns (bool){
        return biometricLock[_beneficiary];
    }

    function isBiometricLockedOnlyOwner(address _beneficiary) external onlyOwner view returns (bool){
        return biometricLock[_beneficiary];
    }
     
    function setBOPSAddress(address _BOPS) external onlyOwner {
        require(_BOPS != address(0));
        BOPS = _BOPS;
    }

    function verify(bytes32 sha, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        require(BOPS != address(0));
        return ecrecover(sha, v, r, s) == BOPS;
    }

    function isBiometricCompleted(bytes32 sha) external view returns (bool) {
        return biometricCompleted[sha];
    }
}

 
contract BiometricToken is Ownable, MintableToken, BiometricLockable {
    event BiometricTransferRequest(address from, address to, uint256 amount, bytes32 sha);
    event BiometricApprovalRequest(address indexed owner, address indexed spender, uint256 value, bytes32 sha);
     
    mapping(bytes32 => address) biometricFrom;
    mapping(bytes32 => address) biometricAllowee;
    mapping(bytes32 => address) biometricTo;
    mapping(bytes32 => uint256) biometricAmount;

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            require(_value <= balances[msg.sender]);
            require(_to != address(0));
            require(_value > 0);
            uint rightNow = now;
            bytes32 sha = keccak256("transfer", msg.sender, _to, _value, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _to;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricTransferRequest(msg.sender, _to, _value, sha);
            return true;
        }
        else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (isBiometricLocked(_from)) {
            require(_value <= balances[_from]);
            require(_value <= allowed[_from][msg.sender]);
            require(_to != address(0));
            require(_from != address(0));
            require(_value > 0);
            uint rightNow = now;
            bytes32 sha = keccak256("transferFrom", _from, _to, _value, rightNow);
            biometricAllowee[sha] = msg.sender;
            biometricFrom[sha] = _from;
            biometricTo[sha] = _to;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricTransferRequest(_from, _to, _value, sha);
            return true;
        }
        else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint rightNow = now;
            bytes32 sha = keccak256("approve", msg.sender, _spender, _value, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = _value;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, _value, sha);
            return true;
        }
        else {
            return super.approve(_spender, _value);
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint newValue = allowed[msg.sender][_spender].add(_addedValue);
            uint rightNow = now;
            bytes32 sha = keccak256("increaseApproval", msg.sender, _spender, newValue, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = newValue;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, newValue, sha);
            return true;
        }
        else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        if (isBiometricLocked(msg.sender)) {
            uint oldValue = allowed[msg.sender][_spender];
            uint newValue;
            if (_subtractedValue > oldValue) {
                newValue = 0;
            }
            else {
                newValue = oldValue.sub(_subtractedValue);
            }
            uint rightNow = now;
            bytes32 sha = keccak256("decreaseApproval", msg.sender, _spender, newValue, rightNow);
            biometricFrom[sha] = msg.sender;
            biometricTo[sha] = _spender;
            biometricAmount[sha] = newValue;
            biometricNow[sha] = rightNow;
            BiometricApprovalRequest(msg.sender, _spender, newValue, sha);
            return true;
        }
        else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }
     
    function releaseTransfer(bytes32 sha, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        bytes32 transferFromSha = keccak256("transferFrom", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 transferSha = keccak256("transfer", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        require(sha == transferSha || sha == transferFromSha);
        require(verify(sha, v, r, s) == true);
        if (transferFromSha == sha) {
            address _spender = biometricAllowee[sha];
            address _from = biometricFrom[sha];
            address _to = biometricTo[sha];
            uint256 _value = biometricAmount[sha];
            require(_to != address(0));
            require(_value <= balances[_from]);
            require(_value <= allowed[_from][_spender]);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
            Transfer(_from, _to, _value);
        }
        if (transferSha == sha) {
            super.transfer(biometricTo[sha], biometricAmount[sha]);
        }
        biometricCompleted[sha] = true;
        return true;
    }
     
    function cancelTransfer(bytes32 sha) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
     
    function releaseApprove(bytes32 sha, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        bytes32 approveSha = keccak256("approve", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 increaseApprovalSha = keccak256("increaseApproval", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        bytes32 decreaseApprovalSha = keccak256("decreaseApproval", biometricFrom[sha], biometricTo[sha], biometricAmount[sha], biometricNow[sha]);
        require(approveSha == sha || increaseApprovalSha == sha || decreaseApprovalSha == sha);
        require(verify(sha, v, r, s) == true);
        super.approve(biometricTo[sha], biometricAmount[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
     
    function cancelApprove(bytes32 sha) public returns (bool){
        require(msg.sender == biometricFrom[sha]);
        require(!biometricCompleted[sha]);
        biometricCompleted[sha] = true;
        return true;
    }
}

contract CompliantToken is BiometricToken {
     
    mapping(address => bool) presaleHolder;
     
    mapping(address => uint256) presaleHolderUnlockDate;
     
    mapping(address => bool) utilityHolder;
     
    mapping(address => bool) allowedHICAddress;
     
    mapping(address => bool) privilegeAddress;

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (presaleHolder[msg.sender]) {
            if (now >= presaleHolderUnlockDate[msg.sender]) {
                return super.transfer(_to, _value);
            }
            else {
                require(allowedHICAddress[_to]);
                return super.transfer(_to, _value);
            }
        }
        if (utilityHolder[msg.sender]) {
            require(allowedHICAddress[_to]);
            return super.transfer(_to, _value);
        }
        else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (presaleHolder[_from]) {
            if (now >= presaleHolderUnlockDate[_from]) {
                return super.transferFrom(_from, _to, _value);
            }
            else {
                require(allowedHICAddress[_to]);
                return super.transferFrom(_from, _to, _value);
            }
        }
        if (utilityHolder[_from]) {
            require(allowedHICAddress[_to]);
            return super.transferFrom(_from, _to, _value);
        }
        else {
            return super.transferFrom(_from, _to, _value);
        }
    }
     
    function addAllowedHICAddress(address _beneficiary) onlyOwner public {
        allowedHICAddress[_beneficiary] = true;
    }

    function removeAllowedHICAddress(address _beneficiary) onlyOwner public {
        allowedHICAddress[_beneficiary] = false;
    }

    function isAllowedHICAddress(address _beneficiary) onlyOwner public view returns (bool){
        return allowedHICAddress[_beneficiary];
    }
     
    function addUtilityHolder(address _beneficiary) public {
        require(privilegeAddress[msg.sender]);
        utilityHolder[_beneficiary] = true;}

    function removeUtilityHolder(address _beneficiary) onlyOwner public {
        utilityHolder[_beneficiary] = false;
    }

    function isUtilityHolder(address _beneficiary) onlyOwner public view returns (bool){
        return utilityHolder[_beneficiary];
    }
     
    function addPresaleHolder(address _beneficiary) public {
        require(privilegeAddress[msg.sender]);
        presaleHolder[_beneficiary] = true;
        presaleHolderUnlockDate[_beneficiary] = now + 1 years;
    }

    function removePresaleHolder(address _beneficiary) onlyOwner public {
        presaleHolder[_beneficiary] = false;
        presaleHolderUnlockDate[_beneficiary] = now;
    }

    function isPresaleHolder(address _beneficiary) onlyOwner public view returns (bool){
        return presaleHolder[_beneficiary];
    }
     
    function addPrivilegeAddress(address _beneficiary) onlyOwner public {
        privilegeAddress[_beneficiary] = true;
    }

    function removePrivilegeAddress(address _beneficiary) onlyOwner public {
        privilegeAddress[_beneficiary] = false;
    }

    function isPrivilegeAddress(address _beneficiary) onlyOwner public view returns (bool){
        return privilegeAddress[_beneficiary];
    }
}

contract RISENCoin is CompliantToken, PausableToken {
    string public name = "RISEN";
    string public symbol = "RSN";
    uint8 public decimals = 18;
}