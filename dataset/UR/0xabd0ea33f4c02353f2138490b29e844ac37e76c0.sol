 

pragma solidity ^0.4.23;

 

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 

 

pragma solidity ^0.4.23;




 
contract TransferableToken is StandardToken,Ownable {

     

    event Transferable();
    event UnTransferable();

    bool public transferable = false;
    mapping (address => bool) public whitelisted;

     
    
    constructor() 
        StandardToken() 
        Ownable()
        public 
    {
        whitelisted[msg.sender] = true;
    }

     

     
    modifier whenNotTransferable() {
        require(!transferable);
        _;
    }

     
    modifier whenTransferable() {
        require(transferable);
        _;
    }

     
    modifier canTransfert() {
        if(!transferable){
            require (whitelisted[msg.sender]);
        } 
        _;
   }
   
     

     
    function allowTransfert() onlyOwner whenNotTransferable public {
        transferable = true;
        emit Transferable();
    }

     
    function restrictTransfert() onlyOwner whenTransferable public {
        transferable = false;
        emit UnTransferable();
    }

     
    function whitelist(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = true;
    }

     
    function restrict(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = false;
    }


     

    function transfer(address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

   
    function approve(address _spender, uint256 _value) public canTransfert returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public canTransfert returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public canTransfert returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 

 

pragma solidity ^0.4.23;




contract KryllToken is TransferableToken {
 

    string public symbol = "KRL";
    string public name = "Kryll.io Token";
    uint8 public decimals = 18;
  

    uint256 constant internal DECIMAL_CASES    = (10 ** uint256(decimals));
    uint256 constant public   SALE             =  17737348 * DECIMAL_CASES;  
    uint256 constant public   TEAM             =   8640000 * DECIMAL_CASES;  
    uint256 constant public   ADVISORS         =   2880000 * DECIMAL_CASES;  
    uint256 constant public   SECURITY         =   4320000 * DECIMAL_CASES;  
    uint256 constant public   PRESS_MARKETING  =   5040000 * DECIMAL_CASES;  
    uint256 constant public   USER_ACQUISITION =  10080000 * DECIMAL_CASES;  
    uint256 constant public   BOUNTY           =    720000 * DECIMAL_CASES;  

    address public sale_address     = 0x29e9535AF275a9010862fCDf55Fe45CD5D24C775;
    address public team_address     = 0xd32E4fb9e8191A97905Fb5Be9Aa27458cD0124C1;
    address public advisors_address = 0x609f5a53189cAf4EeE25709901f43D98516114Da;
    address public security_address = 0x2eA5917E227552253891C1860E6c6D0057386F62;
    address public press_address    = 0xE9cAad0504F3e46b0ebc347F5bf591DBcB49756a;
    address public user_acq_address = 0xACD80ad0f7beBe447ea0625B606Cf3DF206DafeF;
    address public bounty_address   = 0x150658D45dc62E9EB246E82e552A3ec93d664985;
    bool public initialDistributionDone = false;

     
    function reset(address _saleAddrss, address _teamAddrss, address _advisorsAddrss, address _securityAddrss, address _pressAddrss, address _usrAcqAddrss, address _bountyAddrss) public onlyOwner{
        require(!initialDistributionDone);
        team_address = _teamAddrss;
        advisors_address = _advisorsAddrss;
        security_address = _securityAddrss;
        press_address = _pressAddrss;
        user_acq_address = _usrAcqAddrss;
        bounty_address = _bountyAddrss;
        sale_address = _saleAddrss;
    }

     
    function distribute() public onlyOwner {
         
        require(!initialDistributionDone);
        require(sale_address != 0x0 && team_address != 0x0 && advisors_address != 0x0 && security_address != 0x0 && press_address != 0x0 && user_acq_address != 0 && bounty_address != 0x0);      

         
        totalSupply_ = SALE.add(TEAM).add(ADVISORS).add(SECURITY).add(PRESS_MARKETING).add(USER_ACQUISITION).add(BOUNTY);

         
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);

        transfer(team_address, TEAM);
        transfer(advisors_address, ADVISORS);
        transfer(security_address, SECURITY);
        transfer(press_address, PRESS_MARKETING);
        transfer(user_acq_address, USER_ACQUISITION);
        transfer(bounty_address, BOUNTY);
        transfer(sale_address, SALE);
        initialDistributionDone = true;
        whitelist(sale_address);  
        whitelist(team_address);  
    }

     
    function setName(string _name) onlyOwner public {
        name = _name;
    }

}

 

 

pragma solidity ^0.4.23;




 
contract KryllVesting is Ownable {
    using SafeMath for uint256;

    event Released(uint256 amount);

     
    address public beneficiary;
    KryllToken public token;

    uint256 public startTime;
    uint256 public cliff;
    uint256 public released;


    uint256 constant public   VESTING_DURATION    =  31536000;  
    uint256 constant public   CLIFF_DURATION      =   7776000;  


     
    function setup(address _beneficiary,address _token) public onlyOwner{
        require(startTime == 0);  
        require(_beneficiary != address(0));
         
        changeBeneficiary(_beneficiary);
        token = KryllToken(_token);
    }

     
    function start() public onlyOwner{
        require(token != address(0));
        require(startTime == 0);  
        startTime = now;
        cliff = startTime.add(CLIFF_DURATION);
    }

     
    function isStarted() public view returns (bool) {
        return (startTime > 0);
    }


     
    function changeBeneficiary(address _beneficiary) public onlyOwner{
        beneficiary = _beneficiary;
    }


     
    function release() public {
        require(startTime != 0);
        require(beneficiary != address(0));
        
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);
        token.transfer(beneficiary, unreleased);
        emit Released(unreleased);
    }

     
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

     
    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released);

        if (now < cliff) {
            return 0;
        } else if (now >= startTime.add(VESTING_DURATION)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(startTime)).div(VESTING_DURATION);
        }
    }
}