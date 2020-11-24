 

pragma solidity 0.4.23;


 
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


 
library SafeMath32 {

   
  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

   
  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Habits {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;

     
    address internal owner;
    mapping (address => bool) internal adminPermission;
    
    uint256 constant REGISTRATION_FEE = 0.005 ether;   
    uint32 constant NUM_REGISTER_DAYS = 10;   
    uint32 constant NINETY_DAYS = 90 days;
    uint32 constant WITHDRAW_BUFFER = 129600;   
    uint32 constant MAY_FIRST_2018 = 1525132800;
    uint32 constant DAY = 86400;

    enum UserEntryStatus {
        NULL,
        REGISTERED,
        COMPLETED,
        WITHDRAWN
    }

    struct DailyContestStatus {
        uint256 numRegistered;
        uint256 numCompleted;
        bool operationFeeWithdrawn;
    }

    mapping (address => uint32[]) internal userToDates;
    mapping (uint32 => address[]) internal dateToUsers;
    mapping (address => mapping (uint32 => UserEntryStatus)) internal userDateToStatus;
    mapping (uint32 => DailyContestStatus) internal dateToContestStatus;

    event LogWithdraw(address user, uint256 amount);
    event LogOperationFeeWithdraw(address user, uint256 amount);

     
    function Habits() public {
        owner = msg.sender;
        adminPermission[owner] = true;
    }

     
    function register(uint32 _expectedStartDate) external payable {
         
        require(REGISTRATION_FEE.mul(NUM_REGISTER_DAYS) == msg.value);

         
        require(_expectedStartDate <= getDate(uint32(now)).add(NINETY_DAYS));

        uint32 startDate = getStartDate();
         
         
        require(startDate == _expectedStartDate);

        for (uint32 i = 0; i < NUM_REGISTER_DAYS; i++) {
            uint32 date = startDate.add(i.mul(DAY));

             
            require(userDateToStatus[msg.sender][date] == UserEntryStatus.NULL);

            userDateToStatus[msg.sender][date] = UserEntryStatus.REGISTERED;
            userToDates[msg.sender].push(date);
            dateToUsers[date].push(msg.sender);
            dateToContestStatus[date].numRegistered += 1;
        }
    }

     
    function checkIn() external {
        uint32 nowDate = getDate(uint32(now));

         
        require(userDateToStatus[msg.sender][nowDate] == UserEntryStatus.REGISTERED);
        userDateToStatus[msg.sender][nowDate] = UserEntryStatus.COMPLETED;
        dateToContestStatus[nowDate].numCompleted += 1;
    }

     
    function withdraw(uint32[] _dates) external {
        uint256 withdrawAmount = 0;
        uint256 datesLength = _dates.length;
        uint32 now32 = uint32(now);
        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = _dates[i];
             
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
             
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }

             
            userDateToStatus[msg.sender][date] = UserEntryStatus.WITHDRAWN;
            withdrawAmount = withdrawAmount.add(REGISTRATION_FEE).add(calculateBonus(date));
        }

        if (withdrawAmount > 0) {
           msg.sender.transfer(withdrawAmount);
        }
        LogWithdraw(msg.sender, withdrawAmount);
    }

     
    function calculateWithdrawableAmount() external view returns (uint256) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
        uint256 withdrawAmount = 0;
        uint32 now32 = uint32(now);
        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = dates[i];
             
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
             
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }
            withdrawAmount = withdrawAmount.add(REGISTRATION_FEE).add(calculateBonus(date));
        }

        return withdrawAmount;
    }

     
    function getWithdrawableDates() external view returns(uint32[]) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
         
         
        uint32[] memory withdrawableDates = new uint32[](datesLength);
        uint256 index = 0;
        uint32 now32 = uint32(now);

        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = dates[i];
             
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
             
            if (userDateToStatus[msg.sender][date] != UserEntryStatus.COMPLETED) {
                continue;
            }
            withdrawableDates[index] = date;
            index += 1;
        }

         
        return withdrawableDates;
    }

     
    function getUserEntryStatuses() external view returns (uint32[], uint32[]) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 datesLength = dates.length;
        uint32[] memory statuses = new uint32[](datesLength);

        for (uint256 i = 0; i < datesLength; i++) {
            statuses[i] = uint32(userDateToStatus[msg.sender][dates[i]]);
        }
        return (dates, statuses);
    }

     
    function withdrawOperationFees(uint32[] _dates) external {
         
        require(msg.sender == owner);

        uint256 withdrawAmount = 0;
        uint256 datesLength = _dates.length;
        uint32 now32 = uint32(now);

        for (uint256 i = 0; i < datesLength; i++) {
            uint32 date = _dates[i];
             
            if (now32 <= date.add(WITHDRAW_BUFFER)) {
                continue;
            }
             
            if (dateToContestStatus[date].operationFeeWithdrawn) {
                continue;
            }
             
            dateToContestStatus[date].operationFeeWithdrawn = true;
            withdrawAmount = withdrawAmount.add(calculateOperationFee(date));
        }

        if (withdrawAmount > 0) {
            msg.sender.transfer(withdrawAmount);
        }
        LogOperationFeeWithdraw(msg.sender, withdrawAmount);
    }

     
    function getWithdrawableOperationFeeDatesAndAmount() external view returns (uint32[], uint256) {
         
        if (msg.sender != owner) {
            return (new uint32[](0), 0);
        }

        uint32 cutoffTime = uint32(now).sub(WITHDRAW_BUFFER);
        uint32 maxLength = cutoffTime.sub(MAY_FIRST_2018).div(DAY).add(1);
        uint32[] memory withdrawableDates = new uint32[](maxLength);
        uint256 index = 0;
        uint256 withdrawAmount = 0;
        uint32 date = MAY_FIRST_2018;

        while(date < cutoffTime) {
            if (!dateToContestStatus[date].operationFeeWithdrawn) {
                uint256 amount = calculateOperationFee(date);
                if (amount > 0) {
                    withdrawableDates[index] = date;
                    withdrawAmount = withdrawAmount.add(amount);
                    index += 1;
                }
            }
            date = date.add(DAY);
        } 
        return (withdrawableDates, withdrawAmount);
    }

     
    function getContestStatusForDate(uint32 _date) external view returns (int256, int256, int256) {
        DailyContestStatus memory dailyContestStatus = dateToContestStatus[_date];
        int256 numRegistered = int256(dailyContestStatus.numRegistered);
        int256 numCompleted = int256(dailyContestStatus.numCompleted);
        int256 bonus = int256(calculateBonus(_date));

        if (uint32(now) <= _date.add(WITHDRAW_BUFFER)) {
            numCompleted = -1;
            bonus = -1;
        }
        return (numRegistered, numCompleted, bonus);
    }

     
    function getStartDate() public view returns (uint32) {
        uint32 startDate = getNextDate(uint32(now));
        uint32 lastRegisterDate = getLastRegisterDate();
        if (startDate <= lastRegisterDate) {
            startDate = getNextDate(lastRegisterDate);
        }
        return startDate;
    }

     
    function getNextDate(uint32 _timestamp) internal pure returns (uint32) {
        return getDate(_timestamp.add(DAY));
    }

     
    function getDate(uint32 _timestamp) internal pure returns (uint32) {
        return _timestamp.sub(_timestamp % DAY);
    }

     
    function getLastRegisterDate() internal view returns (uint32) {
        uint32[] memory dates = userToDates[msg.sender];
        uint256 pastRegisterCount = dates.length;

        if(pastRegisterCount == 0) {
            return 0;
        }
        return dates[pastRegisterCount.sub(1)];
    }

      
    function calculateBonus(uint32 _date) internal view returns (uint256) {
        DailyContestStatus memory status = dateToContestStatus[_date];
        if (status.numCompleted == 0) {
            return 0;
        }
        uint256 numFailed = status.numRegistered.sub(status.numCompleted);
         
        return numFailed.mul(REGISTRATION_FEE).mul(9).div(
            status.numCompleted.mul(10)
        );
    }

      
    function calculateOperationFee(uint32 _date) internal view returns (uint256) {
        DailyContestStatus memory status = dateToContestStatus[_date];
         
        if (status.numCompleted == 0) {
            return status.numRegistered.mul(REGISTRATION_FEE);
        }
        uint256 numFailed = status.numRegistered.sub(status.numCompleted);
         
        return numFailed.mul(REGISTRATION_FEE).div(10);
    }

     

      
    function addAdmin(address _newAdmin) external {
        require(msg.sender == owner);
        adminPermission[_newAdmin] = true;
    }

      
    function getDatesForUser(address _user) external view returns (uint32[]) {
        if (!adminPermission[msg.sender]) {
           return new uint32[](0); 
        }
        return userToDates[_user];
    }

      
    function getUsersForDate(uint32 _date) external view returns (address[]) {
        if (!adminPermission[msg.sender]) {
           return new address[](0); 
        }
        return dateToUsers[_date];
    }

      
    function getEntryStatus(address _user, uint32 _date)
    external view returns (UserEntryStatus) {
        if (!adminPermission[msg.sender]) {
            return UserEntryStatus.NULL;
        }
        return userDateToStatus[_user][_date];
    }

     
    function getContestStatusForDateAdmin(uint32 _date)
    external view returns (uint256, uint256, bool) {
        if (!adminPermission[msg.sender]) {
            return (0, 0, false);
        }
        DailyContestStatus memory dailyContestStatus = dateToContestStatus[_date];
        return (
            dailyContestStatus.numRegistered,
            dailyContestStatus.numCompleted,
            dailyContestStatus.operationFeeWithdrawn
        );
    }
}