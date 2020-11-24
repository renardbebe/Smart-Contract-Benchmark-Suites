 

pragma solidity ^0.4.23;

 
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

   
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract AbstractERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public constant returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract TradCoin is Ownable, AbstractERC20 {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
     
    address public distributor;
     
     
    uint256 becomesTransferable = 1533009599;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
     
    mapping (address => uint256) internal balancesAllowedToTransfer;
     
    mapping (address => bool) public isInvestor;

    event DistributorTransferred(address indexed _from, address indexed _to);
    event Allocated(address _owner, address _investor, uint256 _tokenAmount);

    constructor(address _distributor) public {
        require (_distributor != address(0x0));
        name = "TradCoin";
        symbol = "TRADCoin";
        decimals = 18 ;
        totalSupply = 300e6 * 10**18;     
        owner = msg.sender;
        distributor = _distributor;
        balances[distributor] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

     
    function allocateTokensToInvestors(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_to != address(0x0));
        require(_value > 0);
        uint256 unlockValue = (_value.mul(30)).div(100);
         
        balances[distributor] = balances[distributor].sub(_value);
        balances[_to] = balances[_to].add(_value);
        balancesAllowedToTransfer[_to] = unlockValue;
        isInvestor[_to] = true;
        emit Allocated(msg.sender, _to, _value);
        return true;
    }

     
    function allocateTokensToTeamAndProjects(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_to != address(0x0));
        require(_value > 0);
         
        balances[distributor] = balances[distributor].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Allocated(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address owner) public view returns (uint256){
        return balances[owner];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0x0));
        require(value <= balances[msg.sender]);
        uint256 valueAllowedToTransfer;
        if(isInvestor[msg.sender]){
            if (now >= becomesTransferable){
                valueAllowedToTransfer = balances[msg.sender];
                assert(value <= valueAllowedToTransfer);
            }else{
                valueAllowedToTransfer = balancesAllowedToTransfer[msg.sender];
                assert(value <= valueAllowedToTransfer);
                balancesAllowedToTransfer[msg.sender] = balancesAllowedToTransfer[msg.sender].sub(value);
            }
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0x0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        uint256 valueAllowedToTransfer;
        if(isInvestor[from]){
            if (now >= becomesTransferable){
                valueAllowedToTransfer = balances[from];
                assert(value <= valueAllowedToTransfer);
            }else{
                valueAllowedToTransfer = balancesAllowedToTransfer[from];
                assert(value <= valueAllowedToTransfer);
                balancesAllowedToTransfer[from] = balancesAllowedToTransfer[from].sub(value);
            }
        }
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function availableBalanceInLockingPeriodForInvestor(address owner) public view returns(uint256){
        return balancesAllowedToTransfer[owner];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

     
    function increaseApproval(address spender, uint valueToAdd) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(valueToAdd);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseApproval(address spender, uint valueToSubstract) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (valueToSubstract > oldValue) {
          allowed[msg.sender][spender] = 0;
        } else {
          allowed[msg.sender][spender] = oldValue.sub(valueToSubstract);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

}