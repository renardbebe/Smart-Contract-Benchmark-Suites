 

contract IReceiver { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
library LSafeMath {

    uint256 constant WAD = 1 ether;
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a == b)
            return c;
        revert();
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > 0) { 
            uint256 c = a / b;
            return c;
        }
        revert();
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b <= a)
            return a - b;
        revert();
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c >= a) 
            return c;
        revert();
    }

    function wmul(uint a, uint b) internal pure returns (uint256) {
        return add(mul(a, b), WAD / 2) / WAD;
    }

    function wdiv(uint a, uint b) internal pure returns (uint256) {
        return add(mul(a, WAD), b / 2) / b;
    }
}

contract Ownable {
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}


contract BasicToken is ERC20Basic {

    using LSafeMath for uint256;
    mapping(address => uint256) balances;
    bool public isFallbackAllowed;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        uint codeLength = 0;

        assembly {
             
            codeLength := extcodesize(_to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength > 0 && isFallbackAllowed)
            IReceiver(_to).tokenFallback(msg.sender, _value, empty);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        uint256 _allowance = allowed[_from][msg.sender];
        uint codeLength = 0;

        assembly {
             
            codeLength := extcodesize(_to)
        }

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
         
        allowed[_from][msg.sender] = _allowance.sub(_value);
        if (codeLength > 0 && isFallbackAllowed) 
            IReceiver(_to).tokenFallback(msg.sender, _value, empty);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract ARCXToken is StandardToken, Ownable {
    string  public name;
    string  public symbol;
    uint    public constant decimals = 18;
    uint    public INITIAL_SUPPLY;
    address public crowdsaleContract;
    bool    public transferEnabled;
    uint public timeLock; 
    mapping(address => bool) private ingnoreLocks;
    mapping(address => uint) public lockedAddresses;


    
    event Burn(address indexed _burner, uint _value);

    modifier onlyWhenTransferEnabled() {
        if (msg.sender != crowdsaleContract) {
            require(transferEnabled);
        } 
        _;
    }
    
    modifier checktimelock() {
        require(now >= lockedAddresses[msg.sender] && (now >= timeLock || ingnoreLocks[msg.sender]));
        _;
    }
    
    function ARCXToken(uint time_lock, address crowdsale_contract, string _name, string _symbol, uint supply) public {
        INITIAL_SUPPLY = supply;
        name = _name;
        symbol = _symbol;
        address addr = (crowdsale_contract != address(0)) ? crowdsale_contract : msg.sender;
        balances[addr] = INITIAL_SUPPLY; 
        transferEnabled = true;
        totalSupply = INITIAL_SUPPLY;
        crowdsaleContract = addr;  
        timeLock = time_lock;
        ingnoreLocks[addr] = true;
        emit Transfer(address(0x0), addr, INITIAL_SUPPLY);
    }

    function setupCrowdsale(address _contract, bool _transferAllowed) public onlyOwner {
        crowdsaleContract = _contract;
        transferEnabled = _transferAllowed;
    }

    function transfer(address _to, uint _value) public
        onlyWhenTransferEnabled
        checktimelock
        returns (bool) {
            return super.transfer(_to, _value);
        }

    function transferFrom(address _from, address _to, uint _value) public
        onlyWhenTransferEnabled
        checktimelock
        returns (bool) {
            return super.transferFrom(_from, _to, _value);
        }

    function burn(uint _value) public
        onlyWhenTransferEnabled
        checktimelock
        returns (bool) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            totalSupply = totalSupply.sub(_value);
            emit Burn(msg.sender, _value);
            emit Transfer(msg.sender, address(0x0), _value);
            return true;
        }

     
    function burnFrom(address _from, uint256 _value) public
        onlyWhenTransferEnabled
        checktimelock
        returns (bool) {
            assert(transferFrom(_from, msg.sender, _value));
            return burn(_value);
        } 

    function emergencyERC20Drain(ERC20 token, uint amount ) public onlyOwner {
        token.transfer(owner, amount);
    }
    
    function ChangeTransferStatus() public onlyOwner {
        if (transferEnabled == false) {
            transferEnabled = true;
        } else {
            transferEnabled = false;
        }
    }
    
    function setupTimelock(uint _time) public onlyOwner {
        timeLock = _time;
    }
    
    function setLockedAddress(address _holder, uint _time) public onlyOwner {
        lockedAddresses[_holder] = _time;
    }
    
    function IgnoreTimelock(address _owner) public onlyOwner {
        ingnoreLocks[_owner] = true;
    }
    
    function allowFallback(bool allow) public onlyOwner {
        isFallbackAllowed = allow;
    }

}