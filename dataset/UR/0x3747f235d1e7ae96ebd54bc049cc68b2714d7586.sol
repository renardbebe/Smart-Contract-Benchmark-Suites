 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function initOwnership(address newOwner) public {
        require(_owner == address(0), "Ownable: already owned");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;




contract Vesting is Ownable {
    using SafeMath for uint256;

    struct VestingStruct{
        uint256 starttime;
        uint256 period;
        uint256 release_periods;
        uint256 amount;
        uint256 withdrawn;
        uint256 group_id;
        bool is_revoked;
    }

    struct GroupVestingStruct{
        string name;
        uint256 amount;
        uint256 withdrawn;
    }

    mapping(address=>VestingStruct) vestings;
    mapping(uint256=>address) users;
    uint256 users_counter;

    mapping(uint256=>GroupVestingStruct) groups;
    uint256 groups_counter;

     
    uint256 seconds_in_day = 60*60*24;


    bool _initialized=false;
    bool _initialized2=false;

    IERC20 token;

    uint256 _initialized3=0;


    event Granted(address indexed account, uint256 amount, uint256 starttime, uint256 period, uint256 release_periods, uint256 group_id);
    event Revoked(address indexed account);
    event ChangeVesting(address indexed account, uint256 amount, uint256 period, uint256 release_periods);
    event ChangeVestingTime(address indexed account, uint256 start_time);
    event ChangeVestingGroup(address indexed account, uint256 group_id);
    event Withdraw(address indexed account, uint256 amount);


    function initialize() public{
        require(_initialized3==0, "Already initialized");
        _initialized3 = 1;
        seconds_in_day = 60*60*24;
         
    }

    function isInitialized() public view returns(bool){
        return _initialized;
    }
    function isInitialized2() public view returns(bool){
        return _initialized2;
    }
    function isInitialized3() public view returns(uint256){
        return _initialized3;
    }
    function getSecondsInDay() public view returns(uint256){
        return seconds_in_day;
    }
    function setSecondsInDay(uint256 _seconds_in_day) public onlyOwner returns(bool){
        seconds_in_day = _seconds_in_day;
        return true;
    }


    function setToken(address token_address) public onlyOwner returns(bool){
        token = IERC20(token_address);
    }

    function getToken() public view returns(address){
        return(address(token));
    }


    function usersCounter() public view returns(uint256){
        return users_counter;
    }

    function groupsCounter() public view returns(uint256){
        return groups_counter;
    }


    function addGroup(string memory name) public onlyOwner returns(bool){
        groups[groups_counter].name = name;
        groups_counter++;
    }

    function renameGroup(uint256 group_id, string memory name ) public onlyOwner returns(bool){
        groups[group_id].name = name;
    }

    function getGroup(uint256 group_id) public view returns(GroupVestingStruct memory){
        return groups[group_id];
    }

    function getGroupName(uint256 group_id) public view returns(string memory){
        return groups[group_id].name;
    }

    function getGroupAmount(uint256 group_id) public view returns(uint256){
        return groups[group_id].amount;
    }

    function getGroupWithdrawn(uint256 group_id) public view returns(uint256){
        return groups[group_id].withdrawn;
    }


    function getVesting(address account) public view returns(VestingStruct memory){
        return vestings[account];
    }


    function changeGroup(address account, uint256 new_group_id) public onlyOwner returns(bool){
        require(isGranted(account), "Not granted");

        uint256 granted = vestings[account].amount;
        uint256 withdrawn = vestings[account].withdrawn;
        uint256 prev_group_id = vestings[account].group_id;
        groups[new_group_id].amount = groups[new_group_id].amount.add(granted);
        groups[new_group_id].withdrawn = groups[new_group_id].withdrawn.add(withdrawn);
        groups[prev_group_id].amount = groups[prev_group_id].amount.sub(granted);
        groups[prev_group_id].withdrawn = groups[prev_group_id].withdrawn.sub(withdrawn);
        vestings[account].group_id = new_group_id;
        emit ChangeVestingGroup(account, new_group_id);
    }


    function isGranted(address account) public view returns(bool){
        return (vestings[account].starttime != 0);
    }

    function _grant(address account, uint256 amount, uint256 start_time, uint256 period, uint256 release_periods, uint256 group_id) internal returns(bool){
        vestings[account] = VestingStruct(start_time, period, release_periods, amount, 0, group_id, false);
        groups[group_id].amount = groups[group_id].amount.add(amount);
        users[users_counter] = account;
        users_counter++;
    }

    function grant(address account, uint256 amount, uint256 period, uint256 release_periods, uint256 group_id, uint256 start_time) public onlyOwner returns (bool){
        require(!isGranted(account), "Already granted");
        uint256 vesting_start_time = start_time;
        if(vesting_start_time == 0 ){
            vesting_start_time = now;
        }
        _grant(account, amount, vesting_start_time, period, release_periods, group_id);
        emit Granted(account, amount, vesting_start_time, period, release_periods, group_id);
    }

    function _revoke(address account) internal returns (bool){
        uint256 withdrawn = vestings[account].withdrawn;
        uint256 group_id = vestings[account].group_id;
        vestings[account].amount = withdrawn;
        if (withdrawn < vestings[account].amount){
            groups[group_id].amount = groups[group_id].amount.sub(vestings[account].amount.sub(withdrawn));
        }
        vestings[account].is_revoked = true;
        return true;
    }

    function revoke(address account) public onlyOwner returns (bool){
        _revoke(account);
        emit Revoked(account);
    }


    function change(address account, uint256 period, uint256 release_periods, uint256 amount) public onlyOwner returns (bool){
        require(isGranted(account), "Not granted");
        require(amount >= vestings[account].withdrawn, "Amount is lower than withdrawn");
        uint256 group_id = vestings[account].group_id;
        if( amount > vestings[account].amount){
            groups[group_id].amount = groups[group_id].amount.add(amount.sub(vestings[account].amount));
        }else if (amount < vestings[account].amount){
            groups[group_id].amount = groups[group_id].amount.sub(vestings[account].amount.sub(amount));
        }
        vestings[account].period = period;
        vestings[account].release_periods = release_periods;
        vestings[account].amount = amount;
        vestings[account].is_revoked = false;
        return true;
    }

    function changeStartTime(address account, uint256 start_time) public onlyOwner returns(bool){
        require(isGranted(account), "Not granted");
        vestings[account].starttime = start_time;
        emit ChangeVestingTime(account, start_time);

    }

    function getUserAddress(uint256 user_id) public view returns (address){
        return users[user_id];
    }


    function getCurrentPeriod(address account) public view returns (uint256) {
        
        if( vestings[account].starttime == 0 || vestings[account].starttime >= now){
            return 0;
        }
        
        uint256 calculated_period = (now.sub(vestings[account].starttime).div(seconds_in_day).div(vestings[account].period.div(vestings[account].release_periods)));
        if( calculated_period >= vestings[account].release_periods)
        {
            return vestings[account].release_periods;
        }
        return calculated_period;
    }

    function getAmount(address account) public view returns (uint256) {
        return vestings[account].amount;
    }

    function getReleasePeriods(address account) public view returns (uint256) {
        return vestings[account].release_periods;
    }

    function getPeriod(address account) public view returns (uint256) {
        return vestings[account].period;
    }


    function getWithdrawn(address account) public view returns (uint256) {
        return vestings[account].withdrawn;
    }

    function getRevoked(address account) public view returns (bool) {
        return vestings[account].is_revoked;
    }

    function getStartTime(address account) public view returns (uint256) {
        return vestings[account].starttime;
    }

    function getGroupId(address account) public view returns (uint256) {
        return vestings[account].group_id;
    }

    function getAvailable(address account) public view returns (uint256) {
        uint256 release_periods = getReleasePeriods(account);
        if( !isGranted(account) || release_periods == 0 ){
            return 0;
        }
        uint256 current_release_period = getCurrentPeriod(account);
        uint256 available = current_release_period.mul(getAmount(account).div(release_periods));
        uint256 withdrawn = getWithdrawn(account);
        uint256 amount = getAmount(account);
        if(available <= withdrawn ){
            return 0;
        }
        if( available >= amount || current_release_period >= release_periods){
            return amount.sub(withdrawn);
        }

        return available.sub(withdrawn);
    }

    function withdraw() public returns(bool){
        uint256 available = getAvailable(msg.sender);
        require(available > 0, "Nothing to withdraw");
        vestings[msg.sender].withdrawn = vestings[msg.sender].withdrawn.add(available);
        groups[vestings[msg.sender].group_id].withdrawn = groups[vestings[msg.sender].group_id].withdrawn.add(available);
        token.transfer(msg.sender, available);
        emit Withdraw(msg.sender, available);
        return true;
    }

    function reclaimEther(address payable _to) public onlyOwner returns(bool) {
        _to.transfer(address(this).balance);
        return true;
    }

    function reclaimToken(IERC20 _token, address _to) public onlyOwner returns(bool) {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_to, balance);
        return true;
    }

    function transferToken(address _to, uint256 _amount ) public onlyOwner returns(bool){
        token.transfer(_to, _amount);
        return true;
    }

}