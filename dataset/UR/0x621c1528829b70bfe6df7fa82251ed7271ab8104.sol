 

pragma solidity ^0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
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


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
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

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
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

contract MultiOwnable {
    address public hiddenOwner;
    address public superOwner;
    address public tokenExchanger;
    address[10] public chkOwnerList;

    mapping (address => bool) public owners;
    
    event AddOwner(address indexed newOwner);
    event DeleteOwner(address indexed toDeleteOwner);
    event SetTex(address indexed newTex);
    event ChangeSuperOwner(address indexed newSuperOwner);
    event ChangeHiddenOwner(address indexed newHiddenOwner);

    constructor() public {
        hiddenOwner = msg.sender;
        superOwner = msg.sender;
        owners[superOwner] = true;
        chkOwnerList[0] = msg.sender;
        tokenExchanger = msg.sender;
    }

    modifier onlySuperOwner() {
        require(superOwner == msg.sender);
        _;
    }
    modifier onlyHiddenOwner() {
        require(hiddenOwner == msg.sender);
        _;
    }
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    function changeSuperOwnership(address newSuperOwner) public onlyHiddenOwner returns(bool) {
        require(newSuperOwner != address(0));
        superOwner = newSuperOwner;
        emit ChangeSuperOwner(superOwner);
        return true;
    }
    
    function changeHiddenOwnership(address newHiddenOwner) public onlyHiddenOwner returns(bool) {
        require(newHiddenOwner != address(0));
        hiddenOwner = newHiddenOwner;
        emit ChangeHiddenOwner(hiddenOwner);
        return true;
    }

    function addOwner(address owner, uint8 num) public onlySuperOwner returns (bool) {
        require(num < 10);
        require(owner != address(0));
        require(chkOwnerList[num] == address(0));
        owners[owner] = true;
        chkOwnerList[num] = owner;
        emit AddOwner(owner);
        return true;
    }

    function setTEx(address tex) public onlySuperOwner returns (bool) {
        require(tex != address(0));
        tokenExchanger = tex;
        emit SetTex(tex);
        return true;
    }

    function deleteOwner(address owner, uint8 num) public onlySuperOwner returns (bool) {
        require(chkOwnerList[num] == owner);
        require(owner != address(0));
        owners[owner] = false;
        chkOwnerList[num] = address(0);
        emit DeleteOwner(owner);
        return true;
    }
}

contract HasNoEther is MultiOwnable {
    
     
    constructor() public payable {
        require(msg.value == 0);
    }
    
     
    function() external {
    }
    
     
    function reclaimEther() external onlySuperOwner returns(bool) {
        superOwner.transfer(address(this).balance);

        return true;
    }
}

contract Blacklist is MultiOwnable {
   
    mapping(address => bool) blacklisted;
    
    event Blacklisted(address indexed blacklist);
    event Whitelisted(address indexed whitelist);

    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }
    
     
    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }

     
    function blacklist(address node) public onlyOwner returns (bool) {
        blacklisted[node] = true;
        emit Blacklisted(node);

        return blacklisted[node];
    }

     
    function unblacklist(address node) public onlySuperOwner returns (bool) {
        blacklisted[node] = false;
        emit Whitelisted(node);

        return blacklisted[node];
    }
}

contract TimelockToken is StandardToken, HasNoEther, Blacklist {
    bool public timelock;
    uint256 public openingTime;

    struct chkBalance {
        uint256 _sent;
        uint256 _initial;
        uint256 _limit;
    }

    mapping(address => bool) public p2pAddrs;
    mapping(address => chkBalance) public chkInvestorBalance;
    
    event Postcomplete(address indexed _from, address indexed _spender, address indexed _to, uint256 _value);
    event OnTimeLock(address who);
    event OffTimeLock(address who);
    event P2pUnlocker(address addr);
    event P2pLocker(address addr);
    

    constructor() public {
        openingTime = block.timestamp;
        p2pAddrs[msg.sender] = true;
        timelock = false;
    }

    function postTransfer(address from, address spender, address to, uint256 value) internal returns (bool) {
        emit Postcomplete(from, spender, to, value);
        return true;
    }
    
    function p2pUnlocker (address addr) public onlySuperOwner returns (bool) {
        p2pAddrs[addr] = true;
        
        emit P2pUnlocker(addr);

        return p2pAddrs[addr];
    }

    function p2pLocker (address addr) public onlyOwner returns (bool) {
        p2pAddrs[addr] = false;
        
        emit P2pLocker(addr);

        return p2pAddrs[addr];
    }

    function onTimeLock() public onlySuperOwner returns (bool) {
        timelock = true;
        
        emit OnTimeLock(msg.sender);
        
        return timelock;
    }

    function offTimeLock() public onlySuperOwner returns (bool) {
        timelock = false;
        
        emit OffTimeLock(msg.sender);
        
        return timelock;
    }
  
    function transfer(address to, uint256 value) public 
    whenPermitted(msg.sender) returns (bool) {
        
        bool ret;
        
        if (!timelock) {  
            
            require(p2pAddrs[msg.sender]);
            ret = super.transfer(to, value);
        } else {  
            if (owners[msg.sender]) {
                require(p2pAddrs[msg.sender]);
                
                uint _totalAmount = balances[to].add(value);
                chkInvestorBalance[to] = chkBalance(0,_totalAmount,_totalAmount.div(5));
                ret = super.transfer(to, value);
            } else {
                require(!p2pAddrs[msg.sender] && to == tokenExchanger);
                require(_timeLimit() > 0);
                
                if (chkInvestorBalance[msg.sender]._initial == 0) {  
                    uint256 new_initial = balances[msg.sender];
                    chkInvestorBalance[msg.sender] = chkBalance(0, new_initial, new_initial.div(5));
                }
                
                uint256 addedValue = chkInvestorBalance[msg.sender]._sent.add(value);
                require(addedValue <= _timeLimit().mul(chkInvestorBalance[msg.sender]._limit));
                chkInvestorBalance[msg.sender]._sent = addedValue;
                ret = super.transfer(to, value);
            }
        }
        if (ret) 
            return postTransfer(msg.sender, msg.sender, to, value);
        else
            return false;
    }

    function transferFrom(address from, address to, uint256 value) public 
    whenPermitted(msg.sender) returns (bool) {
        require (owners[msg.sender] && p2pAddrs[msg.sender]);
        require (timelock);
        
        if (owners[from]) {
            uint _totalAmount = balances[to].add(value);
            chkInvestorBalance[to] = chkBalance(0,_totalAmount,_totalAmount.div(5));
        } else {
            require (owners[to] || to == tokenExchanger);
            
            if (chkInvestorBalance[from]._initial == 0) {  
                uint256 new_initial = balances[from];
                chkInvestorBalance[from] = chkBalance(0, new_initial, new_initial.div(5));
            }

            uint256 addedValue = chkInvestorBalance[from]._sent.add(value);
            require(addedValue <= _timeLimit().mul(chkInvestorBalance[from]._limit));
            chkInvestorBalance[from]._sent = addedValue;
        }
        
        bool ret = super.transferFrom(from, to, value);
        
        if (ret) 
            return postTransfer(from, msg.sender, to, value);
        else
            return false;
    }

    function _timeLimit() internal view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 _result = timeValue.div(31 days);

        return _result;
    }

    function setOpeningTime() public onlySuperOwner returns(bool) {
        openingTime = block.timestamp;
        return true;
    }

    function getLimitPeriod() external view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 result = timeValue.div(31 days);
        return result;
    }

}

 
library Address {

     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}



contract luxbio_bio is TimelockToken {
    using Address for address;
    
    event Burn(address indexed burner, uint256 value);
    
    string public constant name = "LB-COIN";
    uint8 public constant decimals = 18;
    string public constant symbol = "LB";
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals)); 

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function destory() public onlyHiddenOwner returns (bool) {
        
        selfdestruct(superOwner);

        return true;

    }

    function burn(address _to,uint256 _value) public onlySuperOwner {
        _burn(_to, _value);
    }

    function _burn(address _who, uint256 _value) internal {     
        require(_value <= balances[_who]);
    
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
    
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
  
     
    function postTransfer(address from, address spender, address to, uint256 value) internal returns (bool) {
        if (to == tokenExchanger && to.isContract()) {
            emit Postcomplete(from, spender, to, value);
            return luxbio_dapp(to).doExchange(from, spender, to, value);
        }
        return true;
    }
}
contract luxbio_dapp {
    function doExchange(address from, address spender, address to, uint256 value) public returns (bool);
    event DoExchange(address indexed from, address indexed _spender, address indexed _to, uint256 _value);
}