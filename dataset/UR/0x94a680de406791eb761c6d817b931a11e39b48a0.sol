 

pragma solidity ^0.4.24;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract Owned {

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    

     
    constructor() public {
        owner = msg.sender;
    }

     
     
     
    function changeOwner(address _newOwner) onlyOwner public returns(bool){
        require (_newOwner != address(0));
        
        newOwner = _newOwner;
        return true;
    }

    function acceptOwnership() public returns(bool) {
        require(newOwner != address(0));
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
        return true;
    }
}


 
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require (_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract LifeBankerCoin is Owned, StandardToken{
    string public constant name = "LifeBanker Coin";
    string public constant symbol = "LBC";
    uint8 public constant decimals = 18;

    address public lockAddress;
    address public teamAddress;

    constructor() public {
        totalSupply = 10000000000000000000000000000;  
    }

     
    function initialization(address _team, address _lock, address _sale) onlyOwner public returns(bool) {
        require(lockAddress == 0 && teamAddress == 0);
        require(_team != 0 && _lock != 0);
        require(_sale != 0);
        teamAddress = _team;
        lockAddress = _lock;
    
        balances[teamAddress] = totalSupply.mul(225).div(1000);  
        balances[lockAddress] = totalSupply.mul(500).div(1000);  
        balances[_sale]       = totalSupply.mul(275).div(1000);  
        return true;
    }
}

 
contract TeamTokensHolder is Owned{
    using SafeMath for uint256;

    LifeBankerCoin public LBC;
    uint256 public startTime;
    uint256 public duration = 6 * 30 * 24 * 3600;  

    uint256 public total = 2250000000000000000000000000;   
    uint256 public amountPerRelease = total.div(6);        
    uint256 public collectedTokens;

    address public TeamAddress = 0x7572b353B176Cc8ceF510616D0fDF8B4551Ba16e;

    event TokensWithdrawn(address indexed _holder, uint256 _amount);
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);


    constructor(address _owner, address _lbc) public{
        owner = _owner;
        LBC = LifeBankerCoin(_lbc);
        startTime = now;
    }

     
    function unLock() public onlyOwner returns(bool){
        uint256 balance = LBC.balanceOf(address(this));

         
        uint256 canExtract = amountPerRelease.mul((getTime().sub(startTime)).div(duration));

        uint256 amount = canExtract.sub(collectedTokens);

        if (amount == 0){
            revert();
        } 

        if (amount > balance) {
            amount = balance;
        }

        assert (LBC.transfer(TeamAddress, amount));
        emit TokensWithdrawn(TeamAddress, amount);
        collectedTokens = collectedTokens.add(amount);
        
        return true;
    }

     
    function getTime() view public returns(uint256){
        return now;
    }

     
     
     
    function claimTokens(address _token) public onlyOwner returns(bool){
        require(_token != address(LBC));

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
        return true;
    }
}

 
contract TokenLock is Owned{
    using SafeMath for uint256;

    LifeBankerCoin public LBC;

    uint256 public totalSupply = 10000000000000000000000000000;
    uint256 public totalLocked = totalSupply.div(2);  
    uint256 public collectedTokens;
    uint256 public startTime;

    address public POSAddress       = 0x23eB4df52175d89d8Df83F44992A5723bBbac00c;  
    address public CommunityAddress = 0x9370973BEa603b86F07C2BFA8461f178081ce49F;  
    address public OperationAddress = 0x69Ce6E9E77869bFcf0Ec3c217b5e7E4905F4AFFf;  

    uint256 _1stYear = totalLocked.mul(5000).div(10000);   
    uint256 _2stYear = totalLocked.mul(2500).div(10000);   
    uint256 _3stYear = totalLocked.mul(1250).div(10000);   
    uint256 _4stYear = totalLocked.mul(625).div(10000);    
    uint256 _5stYear = totalLocked.mul(625).div(10000);    

    mapping (address => bool) public whiteList;
    

    event TokensWithdrawn(uint256 _amount);
    event LogMangeWhile(address indexed _dest, bool _allow);
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

    modifier onlyWhite() { 
        require (whiteList[msg.sender] == true); 
        _; 
    }

     
    constructor(address _lbc) public{
        startTime = now;
        LBC = LifeBankerCoin(_lbc);
        whiteList[msg.sender] = true;
    }
    
     
    function mangeWhileList(address _dest, bool _allow) onlyOwner public returns(bool success){
        require(_dest != address(0));

        whiteList[_dest] = _allow;
        emit LogMangeWhile(_dest, _allow);
        return true;
    }

     
    function unlock() public onlyWhite returns(bool success){
        uint256 canExtract = calculation();
        uint256 _amount = canExtract.sub(collectedTokens);  
        distribute(_amount);
        collectedTokens = collectedTokens.add(_amount);

        return true;
    }

     
    function calculation() view public returns(uint256){
        uint256 _month = getMonths();
        uint256 _amount;

        if (_month == 0){
            return 0;
        }

        if (_month <= 12 ){
            _amount = _1stYear.mul(_month).div(12);

        }else if(_month <= 24){
             
            _amount = _1stYear;
            _amount = _amount.add(_2stYear.mul(_month.sub(12)).div(12));

        }else if(_month <= 36){
             
            _amount = _1stYear + _2stYear;
            _amount = _amount.add(_3stYear.mul(_month.sub(24)).div(12));

        }else if(_month <= 48){
             
            _amount = _1stYear + _2stYear + _3stYear;
            _amount = _amount.add(_4stYear.mul(_month.sub(36)).div(12));      

        }else if(_month <= 60){
             
            _amount = _1stYear + _2stYear + _3stYear + _4stYear;
            _amount = _amount.add(_5stYear.mul(_month.sub(48)).div(12)); 

        }else{
             
            _amount = LBC.balanceOf(this);
        }
        return _amount;
    }

     
    function getMonths() view public returns(uint256){
        uint256 countMonth = (getTime().sub(startTime)).div(30 * 24 * 3600);
        return countMonth;  
    }

     
    function distribute(uint256 _amount) internal returns(bool){
        require (_amount != 0);

        uint256 perAmount = _amount.div(5);
        
        assert (LBC.transfer(POSAddress, perAmount.mul(3)));
        assert (LBC.transfer(CommunityAddress, perAmount.mul(1)));
        assert (LBC.transfer(OperationAddress, perAmount.mul(1)));

        emit TokensWithdrawn(_amount);
        return true;
    }

     
    function getTime() view public returns(uint256){
        return now;  
    }


     
     
     
    function claimTokens(address _token) public onlyOwner returns(bool){
        require(_token != address(LBC));

        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
        return true;
    }
}