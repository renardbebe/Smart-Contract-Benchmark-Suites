 

pragma solidity ^0.4.18;


contract FUTM {

    uint256 constant MAX_UINT256 = 2**256 - 1;
    
    uint256 MAX_SUBMITTED = 50006715761945500000;

     
    uint256 _totalSupply = 0;
    
     
     
     
     
    
     
   uint256[] levels = [ 
      877192982456140000,
     1989552533017940000,
     3735007078472480000,
     6411477666707780000,
     9840049095279210000,
    14840049095279200000,
    21840049095279200000,
    30840049095279200000,
    41506715761945900000,
    50006715761945500000
    ];
    
     
    uint256[] ratios = [
      114,
      89,
      55,
      34,
      21,
      13,
       8,
       5,
       3,
       2 ];
     
     
    uint256 _submitted = 0;
    
    uint256 public tier = 0;
    
     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
     
    event Mined(address indexed _miner, uint _value);
    event WaitStarted(uint256 endTime);
    event SwapStarted(uint256 endTime);
    event MiningStart(uint256 end_time, uint256 swap_time, uint256 swap_end_time);
    event MiningExtended(uint256 end_time, uint256 swap_time, uint256 swap_end_time);

 
     
    string public name = "Futereum Miniature";
    uint8 public decimals = 18;
    string public symbol = "FUTM";
    
     
    bool public swap = false;
    bool public wait = false;
    bool public extended = false;
    
     
    uint256 public endTime;
    
     
    uint256 swapTime;
    uint256 swapEndTime;
    uint256 endTimeExtended;
    uint256 swapTimeExtended;
    uint256 swapEndTimeExtended;
    
     
    uint256 public payRate = 0;
    
     
    uint256 submittedFeesPaid = 0;
    uint256 penalty = 0;
    uint256 reservedFees = 0;
    
     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    
    
    
    
    
    
    
   function () external payable {
   
       require(msg.sender != address(0) &&
                tier != 10 &&
                swap == false &&
                wait == false);
    
        uint256 issued = mint(msg.sender, msg.value);
        
        Mined(msg.sender, issued);
        Transfer(this, msg.sender, issued);
    }
    
     
    function FUTM() public {
        _start();
    }
    
     
    function _start() internal 
    {
        swap = false;
        wait = false;
        extended = false;
    
        endTime = now + 4 hours;
        swapTime = endTime + 2 hours;
        swapEndTime = swapTime + 2 hours;
        endTimeExtended = now + 8 hours;
        swapTimeExtended = endTimeExtended + 2 hours;
        swapEndTimeExtended = swapTimeExtended + 2 hours;
        
        submittedFeesPaid = 0;
        _submitted = 0;
        
        reservedFees = 0;
        
        payRate = 0;
        
        tier = 0;
                
        MiningStart(endTime, swapTime, swapEndTime);
    }
    
     
     
     
     
    function restart() public {
        require(swap && now >= endTime);
        
        penalty = this.balance * 2000 / 10000;
        
        payFees();
        
        _start();
    }
    
     
    function totalSupply() public constant returns (uint)
    {
        return _totalSupply;
    }
    
     
    function mint(address _to, uint256 _value) internal returns (uint256) 
    {
        uint256 total = _submitted + _value;
        
        if (total > MAX_SUBMITTED)
        {
            uint256 refund = total - MAX_SUBMITTED - 1;
            _value = _value - refund;
            
             
            _to.transfer(refund);
        }
        
        _submitted += _value;
        
        total -= refund;
        
        uint256 tokens = calculateTokens(total, _value);
        
        balances[_to] += tokens;
       
        _totalSupply += tokens;
        
        return tokens;
    }
    
     
    function calculateTokens(uint256 total, uint256 _value) internal returns (uint256)
    {
        if (tier == 10) 
        {
             
            return 740000;
        }
        
        uint256 tokens = 0;
        
        if (total > levels[tier])
        {
            uint256 remaining = total - levels[tier];
            _value -= remaining;
            tokens = (_value) * ratios[tier];
           
            tier += 1;
            
            tokens += calculateTokens(total, remaining);
        }
        else
        {
            tokens = _value * ratios[tier];
        }
        
        return tokens;
    }
    
     
     
    function currentTier() public view returns (uint256) {
        if (tier == 10)
        {
            return 10;
        }
        else
        {
            return tier + 1;
        }
    }
    
     
    function leftInTier() public view returns (uint256) {
        if (tier == 10) {
            return 0;
        }
        else
        {
            return levels[tier] - _submitted;
        }
    }
    
     
    function submitted() public view returns (uint256) {
        return _submitted;
    }
    
     
    function balanceMinusFeesOutstanding() public view returns (uint256) {
        return this.balance - (penalty + (_submitted - submittedFeesPaid) * 1530 / 10000);   
    }
    
     
     
    function calulateRate() internal {
        reservedFees = penalty + (_submitted - submittedFeesPaid) * 1530 / 10000;   
        
        uint256 tokens = _totalSupply / 1 ether;
        payRate = (this.balance - reservedFees);

        payRate = payRate / tokens;
    }
    
     
     
     
     
     
    function _updateState() internal {
         
        if (now >= endTime)
        {
             
            if(!swap && !wait)
            {
                if (extended)
                {
                     
                    wait = true;
                    endTime = swapTimeExtended;
                    WaitStarted(endTime);
                }
                else if (tier == 10)
                {
                     
                    wait = true;
                    endTime = swapTime;
                    WaitStarted(endTime);
                } 
                else
                {
                     
                    endTime = endTimeExtended;
                    extended = true;
                    
                    MiningExtended(endTime, swapTime, swapEndTime);
                }
            } 
            else if (wait)
            {
                 
                swap = true;
                wait = false;
                
                if (extended) 
                {
                    endTime = swapEndTimeExtended;
                }
                else
                {
                    endTime = swapEndTime;
                }
                
                SwapStarted(endTime);
            }
        }
    }
   
     
     
     
     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(balances[msg.sender] >= _value);
        
          
        _updateState();

         
        if (_to == address(this)) 
        {
             
            require(swap);
            
            if (payRate == 0)
            {
                calulateRate();  
            }
            
            uint256 amount = _value * payRate;
             
            amount /= 1 ether;
            
             
            balances[msg.sender] -= _value;
             _totalSupply -= _value;
            Transfer(msg.sender, _to, _value);
            
             
            msg.sender.transfer(amount);
        } else
        {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     
     

     
    address public foundation = 0xE252765E4A71e3170b2215cf63C16E7553ec26bD;
    address public owner = 0x448468d5591C724f5310027B859135d5F6434286;
    address public dev = 0xb69a63279319197adca53b9853469d3aac586a4c;
    
     
     
    function payFees() public {
          
         _updateState();
         
        uint256 fees = penalty + (_submitted - submittedFeesPaid) * 1530 / 10000;   
        submittedFeesPaid = _submitted;
        
        reservedFees = 0;
        penalty = 0;
        
        if (fees > 0) 
        {
            foundation.transfer(fees / 2);
            owner.transfer(fees / 4);
            dev.transfer(fees / 4);
        }
    }
    
    function changeFoundation (address _receiver) public
    {
        require(msg.sender == foundation);
        foundation = _receiver;
    }
    
    
    function changeOwner (address _receiver) public
    {
        require(msg.sender == owner);
        owner = _receiver;
    }
    
    function changeDev (address _receiver) public
    {
        require(msg.sender == dev);
        dev = _receiver;
    }    

}