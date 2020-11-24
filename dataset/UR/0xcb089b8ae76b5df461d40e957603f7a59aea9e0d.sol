 

pragma solidity 0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 internal _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}


 
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

}

contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
contract Arroundtoken is ERC20, Claimable {
    using SafeMath for uint256;

    uint64 public constant TDE_FINISH = 1542326400; 
     
     


     
     
     
    string  public name;
    string  public symbol;
    uint8   public decimals;
    address public accTDE;
    address public accFoundCDF;
    address public accFoundNDF1;
    address public accFoundNDF2;
    address public accFoundNDF3;
    address public accTeam;
    address public accBounty;
  
     
    mapping(address => uint64) public frozenAccounts;

     
     
     
    event NewFreeze(address _acc, uint64 _timestamp);
    event BatchDistrib(uint8 cnt, uint256 batchAmount);
    
       
    constructor (
        address _accTDE, 
        address _accFoundCDF,
        address _accFoundNDF1,
        address _accFoundNDF2,
        address _accFoundNDF3,
        address _accTeam,
        address _accBounty, 
        uint256 _initialSupply
    )
    public 
    {
        require(_accTDE       != address(0));
        require(_accFoundCDF  != address(0));
        require(_accFoundNDF1 != address(0));
        require(_accFoundNDF2 != address(0));
        require(_accFoundNDF3 != address(0));
        require(_accTeam      != address(0));
        require(_accBounty    != address(0));
        require(_initialSupply > 0);
        name           = "Arround";
        symbol         = "ARR";
        decimals       = 18;
        accTDE         = _accTDE;
        accFoundCDF    = _accFoundCDF;
        accFoundNDF1   = _accFoundNDF1;
        accFoundNDF2   = _accFoundNDF2;
        accFoundNDF3   = _accFoundNDF3;
        
        accTeam        = _accTeam;
        accBounty      = _accBounty;
        _totalSupply   = _initialSupply * (10 ** uint256(decimals)); 
        
        
        _balances[_accTDE]       = 1104000000 * (10 ** uint256(decimals));  
        _balances[_accFoundCDF]  = 1251000000 * (10 ** uint256(decimals));  
        _balances[_accFoundNDF1] =  150000000 * (10 ** uint256(decimals));  
        _balances[_accFoundNDF2] =  105000000 * (10 ** uint256(decimals));  
        _balances[_accFoundNDF3] =   45000000 * (10 ** uint256(decimals));  
        _balances[_accTeam]      =  300000000 * (10 ** uint256(decimals));  
        _balances[_accBounty]    =   45000000 * (10 ** uint256(decimals));  
        require(  _totalSupply ==  3000000000 * (10 ** uint256(decimals)), "Total Supply exceeded!!!");
        emit Transfer(address(0), _accTDE,       1104000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accFoundCDF,  1251000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accFoundNDF1,  150000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accFoundNDF2,  105000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accFoundNDF3,   45000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accTeam,       300000000 * (10 ** uint256(decimals)));
        emit Transfer(address(0), _accBounty,      45000000 * (10 ** uint256(decimals)));
         
        frozenAccounts[_accTeam]      = TDE_FINISH + 31536000;  
        frozenAccounts[_accFoundNDF2] = TDE_FINISH + 31536000;  
        frozenAccounts[_accFoundNDF3] = TDE_FINISH + 63158400;  
        emit NewFreeze(_accTeam,        TDE_FINISH + 31536000);
        emit NewFreeze(_accFoundNDF2,   TDE_FINISH + 31536000);
        emit NewFreeze(_accFoundNDF3,   TDE_FINISH + 63158400);

    }
    
    modifier onlyTokenKeeper() {
        require(
            msg.sender == accTDE || 
            msg.sender == accFoundCDF ||
            msg.sender == accFoundNDF1 ||
            msg.sender == accBounty
        );
        _;
    }

    function() external { } 

     
    function transfer(address _to, uint256 _value) public  returns (bool) {
        require(frozenAccounts[msg.sender] < now);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(frozenAccounts[_from] < now);
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public  returns (bool) {
        require(frozenAccounts[msg.sender] < now);
        return super.approve(_spender, _value);
    }

     
    function increaseAllowance(address _spender, uint _addedValue) public  returns (bool success) {
        require(frozenAccounts[msg.sender] < now);
        return super.increaseAllowance(_spender, _addedValue);
    }
    
     
    function decreaseAllowance(address _spender, uint _subtractedValue) public  returns (bool success) {
        require(frozenAccounts[msg.sender] < now);
        return super.decreaseAllowance(_spender, _subtractedValue);
    }

    
     
    function multiTransfer(address[] calldata  _investors, uint256[] calldata   _value )  
        external 
        onlyTokenKeeper 
        returns (uint256 _batchAmount)
    {
        require(_investors.length <= 255);  
        require(_value.length == _investors.length);
        uint8      cnt = uint8(_investors.length);
        uint256 amount = 0;
        for (uint i=0; i<cnt; i++){
            amount = amount.add(_value[i]);
            require(_investors[i] != address(0));
            _balances[_investors[i]] = _balances[_investors[i]].add(_value[i]);
            emit Transfer(msg.sender, _investors[i], _value[i]);
        }
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        emit BatchDistrib(cnt, amount);
        return amount;
    }
  
     
    function reclaimToken(ERC20 token) external onlyOwner {
        require(address(token) != address(0));
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}
   
   
   
   
   