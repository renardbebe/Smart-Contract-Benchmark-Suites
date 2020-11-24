 

pragma solidity 0.5.8;

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ApproveAndCallFallBack 
{
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public returns (bool);
}

contract TransferAndCallFallBack 
{
    function receiveToken(address from, uint256 tokens, address token, bytes memory data) public returns (bool);
}

library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
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
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract ERC20Detailed is IERC20 
{
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract AfterShockV2 is ERC20Detailed 
{
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    string constant tokenName = "AfterShock V2";//"AfterShock V2";
    string constant tokenSymbol = "SHOCK";//"SHOCK"; 
    uint8  constant tokenDecimals = 18;
    uint256 _totalSupply = 0;
    
     
  
    address public contractOwner;

    uint256 public fullUnitsStaked_total = 0;
    mapping (address => bool) public isStaking;

    uint256 _totalRewardsPerUnit = 0;
    mapping (address => uint256) private _totalRewardsPerUnit_positions;
    mapping (address => uint256) private _savedRewards;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
    
    bool public migrationActive = true;
    
     
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);

     
    
    constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) 
    {
        contractOwner = msg.sender;
    }
    
     

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "only owner");
        _;
    }
    
    function transferOwnership(address newOwner) public 
    {
        require(msg.sender == contractOwner);
        require(newOwner != address(0));
        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
    }
    
    function totalSupply() public view returns (uint256) 
    {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) 
    {
        return _balances[owner];
    }
    
    function fullUnitsStaked(address owner) external view returns (uint256) 
    {
        return isStaking[owner] ? toFullUnits(_balances[owner]) : 0;
    }
    
    function toFullUnits(uint256 valueWithDecimals) public pure returns (uint256) 
    {
        return valueWithDecimals.div(10**uint256(tokenDecimals));
    }
    
    function allowance(address owner, address spender) public view returns (uint256) 
    {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) 
    {
        _executeTransfer(msg.sender, to, value);
        return true;
    }
    
    function transferAndCall(address to, uint value, bytes memory data) public returns (bool) 
    {
        require(transfer(to, value));
        require(TransferAndCallFallBack(to).receiveToken(msg.sender, value, address(this), data));
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory values) public
    {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) 
    {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }
    
    function transferFromAndCall(address from, address to, uint value, bytes memory data) public returns (bool) 
    {
        require(transferFrom(from, to, value));
        require(TransferAndCallFallBack(to).receiveToken(from, value, address(this), data));
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) 
    {
        require(approve(spender, tokens));
        require(ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function _mint(address account, uint256 value) internal 
    {
        require(value != 0);
        
        uint256 initalBalance = _balances[account];
        uint256 newBalance = initalBalance.add(value);
        
        _balances[account] = newBalance;
        _totalSupply = _totalSupply.add(value);
        
         
        if(isStaking[account])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance));
            fus_total = fus_total.add(toFullUnits(newBalance));
            fullUnitsStaked_total = fus_total;
        }
        emit Transfer(address(0), account, value);
    }
    
    function burn(uint256 value) external 
    {
        _burn(msg.sender, value);
    }
    
    function burnFrom(address account, uint256 value) external 
    {
        require(value <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
    
    function _burn(address account, uint256 value) internal 
    {
        require(value != 0);
        require(value <= _balances[account]);
        
        uint256 initalBalance = _balances[account];
        uint256 newBalance = initalBalance.sub(value);
        
        _balances[account] = newBalance;
        _totalSupply = _totalSupply.sub(value);
        
         
        if(isStaking[account])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance));
            fus_total = fus_total.add(toFullUnits(newBalance));
            fullUnitsStaked_total = fus_total;
        }
        
        emit Transfer(account, address(0), value);
    }
    
     
    function _executeTransfer(address from, address to, uint256 value) private
    {
        require(value <= _balances[from]);
        require(to != address(0) && to != address(this));
        
         
        updateRewardsFor(from);
        updateRewardsFor(to);
        
        uint256 sixPercent = 0;
        if(!whitelistFrom[from] && !whitelistTo[to])
        {
            sixPercent = value.mul(6).div(100);
             
            if(sixPercent == 0 && value > 0)
                sixPercent = 1;
        }
            
        uint256 initalBalance_from = _balances[from];
        uint256 newBalance_from = initalBalance_from.sub(value);
        
        value = value.sub(sixPercent);
        
        uint256 initalBalance_to = from != to ? _balances[to] : newBalance_from;
        uint256 newBalance_to = initalBalance_to.add(value);
        
         
        _balances[from] = newBalance_from;
        _balances[to] = newBalance_to;
        emit Transfer(from, to, value);
         
         
        uint256 fus_total = fullUnitsStaked_total;
        if(isStaking[from])
        {
            fus_total = fus_total.sub(toFullUnits(initalBalance_from));
            fus_total = fus_total.add(toFullUnits(newBalance_from));
        }
        if(isStaking[to])
        {
            fus_total = fus_total.sub(toFullUnits(initalBalance_to));
            fus_total = fus_total.add(toFullUnits(newBalance_to));
        }
        fullUnitsStaked_total = fus_total;
        
        uint256 amountToBurn = sixPercent;
        
        if(fus_total > 0)
        {
            uint256 stakingRewards = sixPercent.div(2);
             
            uint256 rewardsPerUnit = stakingRewards.div(fus_total);
             
            _totalRewardsPerUnit = _totalRewardsPerUnit.add(rewardsPerUnit);
            _balances[address(this)] = _balances[address(this)].add(stakingRewards);
            if(stakingRewards > 0)
                emit Transfer(msg.sender, address(this), stakingRewards);
            amountToBurn = amountToBurn.sub(stakingRewards);
        }
        
         
        _totalSupply = _totalSupply.sub(amountToBurn);
        if(amountToBurn > 0)
            emit Transfer(msg.sender, address(0), amountToBurn);
    }
    
     
    function updateRewardsFor(address staker) private
    {
        _savedRewards[staker] = viewUnpaidRewards(staker);
        _totalRewardsPerUnit_positions[staker] = _totalRewardsPerUnit;
    }
    
     
    function viewUnpaidRewards(address staker) public view returns (uint256)
    {
        if(!isStaking[staker])
            return _savedRewards[staker];
        uint256 newRewardsPerUnit = _totalRewardsPerUnit.sub(_totalRewardsPerUnit_positions[staker]);
        
        uint256 newRewards = newRewardsPerUnit.mul(toFullUnits(_balances[staker]));
        return _savedRewards[staker].add(newRewards);
    }
    
     
    function payoutRewards() public
    {
        updateRewardsFor(msg.sender);
        uint256 rewards = _savedRewards[msg.sender];
        require(rewards > 0 && rewards <= _balances[address(this)]);
        
        _savedRewards[msg.sender] = 0;
        
        uint256 initalBalance_staker = _balances[msg.sender];
        uint256 newBalance_staker = initalBalance_staker.add(rewards);
        
         
        if(isStaking[msg.sender])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance_staker));
            fus_total = fus_total.add(toFullUnits(newBalance_staker));
            fullUnitsStaked_total = fus_total;
        }
        
         
        _balances[address(this)] = _balances[address(this)].sub(rewards);
        _balances[msg.sender] = newBalance_staker;
        emit Transfer(address(this), msg.sender, rewards);
    }
    
    function enableStaking() public { _enableStaking(msg.sender);  }
    function disableStaking() public { _disableStaking(msg.sender); }
    
    function enableStakingFor(address staker) public onlyOwner { _enableStaking(staker); }
    function disableStakingFor(address staker) public onlyOwner { _disableStaking(staker); }
    
     
    function _enableStaking(address staker) private
    {
        require(!isStaking[staker]);
        updateRewardsFor(staker);
        isStaking[staker] = true;
        fullUnitsStaked_total = fullUnitsStaked_total.add(toFullUnits(_balances[staker]));
    }
    
     
    function _disableStaking(address staker) private
    {
        require(isStaking[staker]);
        updateRewardsFor(staker);
        isStaking[staker] = false;
        fullUnitsStaked_total = fullUnitsStaked_total.sub(toFullUnits(_balances[staker]));
    }
    
     
    function withdrawERC20Tokens(address tokenAddress, uint256 amount) public onlyOwner
    {
        require(tokenAddress != address(this));
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
     
    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

     
    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }
    
     
    function multiMigrateBalance(address[] memory receivers, uint256[] memory values) public
    {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            migrateBalance(receivers[i], values[i]);
    }
    
     
    function migrateBalance(address account, uint256 amount) public onlyOwner
    {
        require(migrationActive);
        _mint(account, amount);
    }
    
     
    function endMigration() public onlyOwner
    {
        migrationActive = false;
    }
    
}