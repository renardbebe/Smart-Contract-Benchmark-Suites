 

pragma solidity ^0.5.0;

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

    function transfer(address to, uint256 value) external returns (bool);
     
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
     

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract JKLToken is IERC20 {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => TimeLock[]) private _timeLocks;
    mapping (address => uint256[]) private _locks;
    
    uint256 private _totalSupply;
    address private _owner;
    
    uint256 _releaseTime;
    
    string public constant name = "Bit JacKpot Lottery";
    string public constant symbol = "JKL";
    uint8 public constant decimals = 18; 
    
    

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

     
    
    
    struct TimeLock{
        uint256 blockTime;
        uint256 blockAmount;
    }
    
    constructor(uint256 totalSupply) public{
        _totalSupply = totalSupply;
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        _releaseTime =  block.timestamp + 86400 * 30 * 12 * 10; 
    }
    
    function getTimeStamp() public view returns(uint256) {
        return block.timestamp;
    }
    
    
    function setReleaseTime(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minitue) public returns(bool){
        require(msg.sender == _owner);
        
        uint256 timestamp = toTimestamp(year, month, day, hour, minitue, 0);
         
        require(block.timestamp < timestamp);
        
        _releaseTime = timestamp;
        
        return true;
    }
    
    function getReleaseTime() public view returns(uint256) {
        return _releaseTime;
    }
    
    
    
    function getPriveLockRatio() public view returns(uint256){
        if(_releaseTime > block.timestamp){
            return 100;
        }
        uint256 diff = block.timestamp - _releaseTime;
        diff = (diff / (86400 * 30)) + 1;
         
        if(diff > 10){
            return 0;
        }
        
        return (10 - diff) * 10;
    }
    
    
    
    
    function timeLock(address addr, uint256 amount , uint16 lockMonth) public returns(bool){
        require(msg.sender == _owner);
        require(lockMonth > 0);
        require(amount <= getFreeAmount(addr));
    
        TimeLock memory timeLockTemp;
        timeLockTemp.blockTime = block.timestamp + 86400 * 30 * lockMonth;
         
        timeLockTemp.blockAmount = amount;
        _timeLocks[addr].push(timeLockTemp);
        
        return true;
    }
    
    function privateLock(address addr, uint256 amount) public returns(bool){
        require(msg.sender == _owner);
        require(amount <= getFreeAmount(addr));
    
        _locks[addr].push(amount);
        
        return true;
    }

    function privateSale(address to, uint256 amount) public returns(bool){
        require(msg.sender == _owner);
        
        _transfer(_owner, to, amount);
        
        privateLock(to, amount);
        
        
        return true;
    }

    

    
    function crowdSale(address to, uint256 amount,  uint16 lockMonth) public returns(bool){
        require(msg.sender == _owner);
        
        _transfer(_owner, to, amount);
        
        if(lockMonth > 0){
            timeLock(to, amount, lockMonth);
        }
        
        return true;
    }
    
    function releaseLock(address owner, uint256 amount) public returns(bool){
        require(msg.sender == _owner);    
        
        uint minIdx = 0;
        uint256 minTime = 0;
        uint arrayLength = _timeLocks[owner].length;
        for (uint i=0; i<arrayLength; i++) {
            if(block.timestamp < _timeLocks[owner][i].blockTime && _timeLocks[owner][i].blockAmount > 0){
                if(minTime == 0 || minTime > _timeLocks[owner][i].blockTime){
                    minIdx = i;
                    minTime = _timeLocks[owner][i].blockTime;
                }
            }
        }
        
        if(minTime >= 0){
            if(amount > _timeLocks[owner][minIdx].blockAmount){
                uint256 remain = amount - _timeLocks[owner][minIdx].blockAmount;
                _timeLocks[owner][minIdx].blockAmount = 0;
                releaseLock(owner, remain);
            }else{
                _timeLocks[owner][minIdx].blockAmount -= amount;
            }
            
        }
        
        return true;
    }
    
    
    function getFreeAmount(address owner) public view returns(uint256){
        return(balanceOf(owner) - getLockAmount(owner) - getPriveLockAmount(owner));
    }
    
    function getLockAmount(address owner) public view returns(uint256){
        uint256 result = 0;
        uint arrayLength = _timeLocks[owner].length;
        for (uint i=0; i<arrayLength; i++) {
            if(block.timestamp < _timeLocks[owner][i].blockTime){
                result += _timeLocks[owner][i].blockAmount;
            }
        }
            
        return(result);
    }
    
    
    function getPriveLockAmount(address owner) public view returns(uint256){
        uint256 result = 0;
        uint arrayLength = _locks[owner].length;
        for (uint i=0; i<arrayLength; i++) {
            result += _locks[owner][i];
        }
        
        result = result * getPriveLockRatio() / 100;
            
        return(result);
    }
    

     

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }


     

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        return true;
    }


     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(from == msg.sender);
        
        uint256 available = getFreeAmount(from);
        require(available >= value, "not enough token");
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }




     

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(account == msg.sender);
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }



     

    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
    }
    
    
    
    
    
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
        uint16 i;

         
        for (i = ORIGIN_YEAR; i < year; i++) {
                if (isLeapYear(i)) {
                        timestamp += LEAP_YEAR_IN_SECONDS;
                }
                else {
                        timestamp += YEAR_IN_SECONDS;
                }
        }

         
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
                timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

         
        timestamp += DAY_IN_SECONDS * (day - 1);

         
        timestamp += HOUR_IN_SECONDS * (hour);

         
        timestamp += MINUTE_IN_SECONDS * (minute);

         
        timestamp += second;

        return timestamp;
    }
    
    
   function isLeapYear(uint16 year) public pure returns (bool) {
            if (year % 4 != 0) {
                    return false;
            }
            if (year % 100 != 0) {
                    return true;
            }
            if (year % 400 != 0) {
                    return false;
            }
            return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
            if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                    return 31;
            }
            else if (month == 4 || month == 6 || month == 9 || month == 11) {
                    return 30;
            }
            else if (isLeapYear(year)) {
                    return 29;
            }
            else {
                    return 28;
            }
    }

    
}