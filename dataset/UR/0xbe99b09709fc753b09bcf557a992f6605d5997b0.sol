 

pragma solidity ^0.4.18;
 

 
library SafeMath {

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

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


 
contract admined {  
    address public admin;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
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

    modifier transferLock() {  
        require(lockTransfer == false || allowedAddress == msg.sender);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    
    function setTransferLock(bool _set) onlyAdmin public {  
        lockTransfer = _set;
        SetTransferLock(_set);
    }

     
    event AllowedSet(address _to);
    event SetTransferLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(frozen[_from]==false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
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

     
    function setFrozen(address _target,bool _flag) onlyAdmin public {
        frozen[_target]=_flag;
        FrozenStatus(_target,_flag);
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        Burned(msg.sender, _burnedAmount);
    }


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);
}

 
contract Asset is ERC20Token {
    string public name = 'SMARTRealty';
    uint8 public decimals = 8;
    string public symbol = 'RLTY';
    string public version = '1'; 

    address DevExecutiveAdvisorTeams= 0xF9568bd772C9B517193275b3C2E0CDAd38E586bB;
    address SMARTRealtyEconomy= 0x07ADB1D9399Bd1Fa4fD613D3179DFE883755Bb13;
    address Marketing= 0xd35909DbeEb5255D65b1ea14602C7f00ce3872f6;
    address SMARTMortgages= 0x9D2Fe4D5f1dc4FcA1f0Ea5f461C9fAA5D09b9CCE;
    address Administer= 0x8Bb41848B6dD3D98b8849049b780dC3549568c89;
    address Contractors= 0xC78DF195DE5717FB15FB3448D5C6893E8e7fB254;
    address Legal= 0x4690678926BCf9B30985c06806d4568C0C498123;
    address BountiesandGiveaways= 0x08AF803F0F90ccDBFCe046Bc113822cFf415e148;
    address CharitableUse= 0x8661dFb67dE4E5569da9859f5CB4Aa676cd5F480;


    function Asset() public {

        totalSupply = 500000000 * (10**uint256(decimals));  
        Transfer(0, this, totalSupply);

         
        balances[msg.sender] = 200000000 * (10**uint256(decimals));
        Transfer(this, msg.sender, balances[msg.sender]);        

         
        balances[DevExecutiveAdvisorTeams] = 50000000 * (10**uint256(decimals));
        Transfer(this, DevExecutiveAdvisorTeams, balances[DevExecutiveAdvisorTeams]);

         
        balances[SMARTRealtyEconomy] = 50000000 * (10**uint256(decimals));
        Transfer(this, SMARTRealtyEconomy, balances[SMARTRealtyEconomy]);

         
        balances[Marketing] = 50000000 * (10**uint256(decimals));
        Transfer(this, Marketing, balances[Marketing]);

         
        balances[SMARTMortgages] = 50000000 * (10**uint256(decimals));
        Transfer(this, SMARTMortgages, balances[SMARTMortgages]);
        
         
        balances[Administer] = 25000000 * (10**uint256(decimals));
        Transfer(this, Administer, balances[Administer]);

         
        balances[Contractors] = 25000000 * (10**uint256(decimals));
        Transfer(this, Contractors, balances[Contractors]);

         
        balances[Legal] = 25000000 * (10**uint256(decimals));
        Transfer(this, Legal, balances[Legal]);

         
        balances[BountiesandGiveaways] =  20000000 * (10**uint256(decimals));
        Transfer(this, BountiesandGiveaways, balances[BountiesandGiveaways]);

         
        balances[CharitableUse] = 5000000  * (10**uint256(decimals));
        Transfer(this, CharitableUse, balances[CharitableUse]);

    }
    
     
    function() public {
        revert();
    }

}