 

pragma solidity ^0.4.24;

 
 
 
 
 
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
        return a / b;
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
    
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
 
 
 
 
 
 
 
 
contract Ownable {
     
    address public owner;
     
     
    address public operator;

     
     
    address public CEO;                 
    address public CTO;
    address public CMO;

    bool public CEO_Signature;
    bool public CTO_Signature;
    bool public CMO_Signature;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event CEOTransferred(address indexed previousCEO, address indexed newCEO);
    event CTOTransferred(address indexed previousCTO, address indexed newCTO);
    event CMOTransferred(address indexed previousCMO, address indexed newCMO);

    constructor() public {
        owner    = msg.sender;
        operator = 0xFd48048f8c7B900b5E5216Dc9d7bCd147c2E2efb;

        CEO = 0xAC9C29a58C54921e822c972ACb5EBA955B59C744;
        CTO = 0x60552ccF90872ad2d332DC26a5931Bc6BFb3142c;
        CMO = 0xff76E74fE7AC6Dcd9C151D57A71A99D89910a098;

        ClearCLevelSignature();
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }
    modifier onlyOwnerOrOperator() { require(msg.sender == owner || msg.sender == operator); _; }
    modifier onlyCEO() { require(msg.sender == CEO); _; }
    modifier onlyCTO() { require(msg.sender == CTO); _; }
    modifier onlyCMO() { require(msg.sender == CMO); _; }
    modifier AllCLevelSignature() { require(msg.sender == owner && CEO_Signature && CTO_Signature && CMO_Signature); _; }

    function CEOSignature() external onlyCEO { CEO_Signature = true; }
    function CTOSignature() external onlyCTO { CTO_Signature = true; }
    function CMOSignature() external onlyCMO { CMO_Signature = true; }

    function transferOwnership(address _newOwner) external AllCLevelSignature {
        require(_newOwner != address(0));
        ClearCLevelSignature();
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
  
    function transferOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));
        emit OperatorTransferred(operator, _newOperator);
        operator = _newOperator;
    }

    function transferCEO(address _newCEO) external AllCLevelSignature {
        require(_newCEO != address(0));
        ClearCLevelSignature();
        emit CEOTransferred(CEO, _newCEO);
        CEO = _newCEO;
    }

    function transferCTO(address _newCTO) external AllCLevelSignature {
        require(_newCTO != address(0));
        ClearCLevelSignature();
        emit CTOTransferred(CTO, _newCTO);
        CTO = _newCTO;
    }

    function transferCMO(address _newCMO) external AllCLevelSignature {
        require(_newCMO != address(0));
        ClearCLevelSignature();
        emit CMOTransferred(CMO, _newCMO);
        CMO = _newCMO;
    }

    function SignatureInvalidity() external onlyOwnerOrOperator {
        ClearCLevelSignature();
    }

    function ClearCLevelSignature() internal {
        CEO_Signature = false;
        CTO_Signature = false;
        CMO_Signature = false;
    }
}
 
 
 
 
contract BlackList is Ownable {

    event Lock(address indexed LockedAddress);
    event Unlock(address indexed UnLockedAddress);

    mapping( address => bool ) public blackList;

    modifier CheckBlackList { require(blackList[msg.sender] != true); _; }

    function SetLockAddress(address _lockAddress) external onlyOwnerOrOperator returns (bool) {
        require(_lockAddress != address(0));
        require(_lockAddress != owner);
        require(blackList[_lockAddress] != true);
        
        blackList[_lockAddress] = true;
        
        emit Lock(_lockAddress);

        return true;
    }

    function UnLockAddress(address _unlockAddress) external onlyOwner returns (bool) {
        require(blackList[_unlockAddress] != false);
        
        blackList[_unlockAddress] = false;
        
        emit Unlock(_unlockAddress);

        return true;
    }
}
 
 
 
 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwnerOrOperator whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}
 
 
 
 
 
contract StandardToken is ERC20, BasicToken {
  
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
        emit Transfer(_from, _to, _value);
    
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
    
        emit Approval(msg.sender, _spender, _value);
    
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
    
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
    
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}
 
 
 
 
contract MultiTransferToken is StandardToken, Ownable {

    function MultiTransfer(address[] _to, uint256[] _amount) onlyOwner public returns (bool) {
        require(_to.length == _amount.length);

        uint256 ui;
        uint256 amountSum = 0;
    
        for (ui = 0; ui < _to.length; ui++) {
            require(_to[ui] != address(0));

            amountSum = amountSum.add(_amount[ui]);
        }

        require(amountSum <= balances[msg.sender]);

        for (ui = 0; ui < _to.length; ui++) {
            balances[msg.sender] = balances[msg.sender].sub(_amount[ui]);
            balances[_to[ui]] = balances[_to[ui]].add(_amount[ui]);
        
            emit Transfer(msg.sender, _to[ui], _amount[ui]);
        }
    
        return true;
    }
}
 
 
 
 
contract BurnableToken is StandardToken, Ownable {

    event BurnAdminAmount(address indexed burner, uint256 value);
    event BurnHackerAmount(address indexed hacker, uint256 hackingamount, string reason);

    function burnAdminAmount(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
    
        emit BurnAdminAmount(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
    
     
     
     
    function burnHackingAmount(address _hackerAddress, string _reason) AllCLevelSignature public {
        ClearCLevelSignature();

        uint256 hackerAmount =  balances[_hackerAddress];
        
        require(hackerAmount > 0);

        balances[_hackerAddress] = balances[_hackerAddress].sub(hackerAmount);
        totalSupply_ = totalSupply_.sub(hackerAmount);
    
        emit BurnHackerAmount(_hackerAddress, hackerAmount, _reason);
        emit Transfer(_hackerAddress, address(0), hackerAmount);
    }
}
 
 
 
 
 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MintRestarted(string reason);

    bool public mintingFinished = false;

    modifier canMint() { require(!mintingFinished); _; }
    modifier cannotMint() { require(mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
     
     
    function restartMinting(string _reason) AllCLevelSignature cannotMint public returns (bool) {
        ClearCLevelSignature();

        mintingFinished = false;
        emit MintRestarted(_reason);
        return true;
    }
}
 
 
 
 
contract PausableToken is StandardToken, Pausable, BlackList {

    function transfer(address _to, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused CheckBlackList returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused CheckBlackList returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused CheckBlackList returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}
 
 
 
 
 
contract FunkeyCoin is PausableToken, MintableToken, BurnableToken, MultiTransferToken {
    string public name = "FunkeyCoin";
    string public symbol = "FKC";
    uint256 public decimals = 18;
}