 

pragma solidity ^0.4.18;
 


 
library SafeMath {

   
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract admined {
     
    address public admin;  
    bool public lockSupply;  
    bool public lockTransfer;  
    address public allowedAddress;  
    bool public lockTokenSupply;

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    
    function setAllowedAddress(address _to) public {
        allowedAddress = _to;
        AllowedSet(_to);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

    modifier transferLock() {  
        require(lockTransfer == false || allowedAddress == msg.sender);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    
    function setSupplyLock(bool _set) onlyAdmin public {  
        lockSupply = _set;
        SetSupplyLock(_set);
    }

    
    function setTransferLock(bool _set) onlyAdmin public {  
        lockTransfer = _set;
        SetTransferLock(_set);
    }

    function setLockTokenSupply(bool _set) onlyAdmin public {
        lockTokenSupply = _set;
        SetLockTokenSupply(_set);
    }

    function getLockTokenSupply() returns (bool) {
        return lockTokenSupply;
    }

     
    event AllowedSet(address _to);
    event SetSupplyLock(bool _set);
    event SetTransferLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);
    event SetLockTokenSupply(bool _set);

}

 
contract ERC20TokenInterface {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

 
contract StandardToken is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[msg.sender] >= _value);
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].safeSub(_value);
        balances[_to] = balances[_to].safeAdd(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        require(frozen[_from]==false);
        balances[_to] = balances[_to].safeAdd(_value);
        balances[_from] = balances[_from].safeSub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin supplyLock public {
        balances[_target] = SafeMath.safeAdd(balances[_target], _mintedAmount);
        totalSupply = SafeMath.safeAdd(totalSupply, _mintedAmount);
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

     
    function burnToken(address _target, uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[_target] = SafeMath.safeSub(balances[_target], _burnedAmount);
        totalSupply = SafeMath.safeSub(totalSupply, _burnedAmount);
        Burned(_target, _burnedAmount);
    }

     
    function setFrozen(address _target,bool _flag) onlyAdmin public {
        frozen[_target]=_flag;
        FrozenStatus(_target,_flag);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);
}

contract SMARTRealty is StandardToken{
     
    
    string public name = "SMARTRealty";
    string public symbol = "RLTY";
    uint8 public decimals = 8;
    string public version = "1.0.0";

    uint public constant RATE = 1250;  
    address public owner;
    
     
    uint256 weiRaised;    
    
    struct ICOPhase {
        uint fromTimestamp;  
        uint toTimestamp;  
        uint256 minimum;  
        uint256 fundRaised;
        uint bonus;  
        uint totalNumberOfTokenPurchase;  
    }
    
    mapping(uint => ICOPhase) phases;
    uint icoPhaseCounter = 0;
    
    enum IcoStatus{Pending, Active, Inactive}
    IcoStatus status;    
    
    function SMARTRealty() public payable {
        
        owner = msg.sender;
        
        totalSupply = 500000000 * (10**uint256(decimals));           
        
         
        balances[owner] = 200000000 * (10**uint256(decimals));  
        
         
        balances[0xF9568bd772C9B517193275b3C2E0CDAd38E586bB] = 50000000 * (10**uint256(decimals));  
        balances[0x07ADB1D9399Bd1Fa4fD613D3179DFE883755Bb13] = 50000000 * (10**uint256(decimals));  
        balances[0xd35909DbeEb5255D65b1ea14602C7f00ce3872f6] = 50000000 * (10**uint256(decimals));  
        balances[0x9D2Fe4D5f1dc4FcA1f0Ea5f461C9fAA5D09b9CCE] = 50000000 * (10**uint256(decimals));  
        balances[0x8Bb41848B6dD3D98b8849049b780dC3549568c89] = 25000000 * (10**uint256(decimals));  
        balances[0xC78DF195DE5717FB15FB3448D5C6893E8e7fB254] = 25000000 * (10**uint256(decimals));  
        balances[0x4690678926BCf9B30985c06806d4568C0C498123] = 25000000 * (10**uint256(decimals));  
        balances[0x08AF803F0F90ccDBFCe046Bc113822cFf415e148] = 20000000 * (10**uint256(decimals));  
        balances[0x8661dFb67dE4E5569da9859f5CB4Aa676cd5F480] = 5000000 * (10**uint256(decimals));  
        
    }
    
     
    function activateICOStatus() public {
        status = IcoStatus.Active;
    }    
    
     
    function setICOPhase(uint _fromTimestamp, uint _toTimestamp, uint256 _min, uint _bonus) onlyAdmin public returns (uint ICOPhaseId) {
        uint icoPhaseId = icoPhaseCounter++;
        ICOPhase storage ico = phases[icoPhaseId];
        ico.fromTimestamp = _fromTimestamp;
        ico.toTimestamp = _toTimestamp;
        ico.minimum = _min;
        ico.bonus = _bonus;
         

        phases[icoPhaseId] = ico;

        return icoPhaseId;
    }
    
     
    function getCurrentICOPhaseBonus() public view returns (uint _bonus, uint icoPhaseId) {
        require(icoPhaseCounter > 0);
        uint currentTimestamp = block.timestamp;  

        for (uint i = 0; i < icoPhaseCounter; i++) {
            
            ICOPhase storage ico = phases[i];

            if (currentTimestamp >= ico.fromTimestamp && currentTimestamp <= ico.toTimestamp) {
                return (ico.bonus, i);
            }
        }

    }
    
     
    function getTokenAmount(uint256 weiAmount) internal returns(uint256 token, uint id) {
        var (bonus, phaseId) = getCurrentICOPhaseBonus();        
        uint256 numOfTokens = weiAmount.safeMul(RATE);
        uint256 bonusToken = (bonus / 100) * numOfTokens;
        
        uint256 totalToken = numOfTokens.safeAdd(bonusToken);                
        return (totalToken, phaseId);
    }    
    
     
    function _buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0) && beneficiary != owner);
        
        uint256 weiAmount = msg.value;
        
         
        var (tokens, phaseId) = getTokenAmount(weiAmount);
        
         
        ICOPhase storage ico = phases[phaseId];  
        ico.fundRaised = ico.fundRaised.safeAdd(msg.value);  
        phases[phaseId] = ico;
        
         
        weiRaised = weiRaised.safeAdd(weiAmount);
        
        _transferToken(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        
        forwardFunds();
    }
    
    function _transferToken(address _to, uint256 _amount) public returns (bool){
        balances[owner] = balances[owner].safeSub(_amount);
        balances[_to] = balances[_to].safeAdd(_amount);
        Transfer(address(0), _to, _amount);
        return true;        
    }
    
     
     
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }    

     
    function () external payable {
        _buyTokens(msg.sender);
    } 
    
    
    event TokenPurchase(address _sender, address _beneficiary, uint256 weiAmount, uint256 tokens);
    
}