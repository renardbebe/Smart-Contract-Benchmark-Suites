 

 
pragma solidity ^0.5.7;

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

contract Ownable {

  address owner;
  address Main_address;
  address public main_address;
  address Upline_address;
  address public upline_address;
  mapping (address => bool) managers;
  
  constructor() public {
    owner = msg.sender;
    main_address = msg.sender;
    upline_address = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only for owner");
    _;
  }

  function transferOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }

}

contract ETHStvo is Ownable {
    
    event Register(uint indexed _user, uint indexed _referrer, uint indexed _introducer, uint _time);
    event Upgrade(uint indexed _user, uint _level, uint _price, uint _time);
    event Payment(uint indexed _user, uint indexed _receiver, uint indexed _type, uint _level, uint _money, uint _time);
    event Lost(uint indexed _user, uint indexed _receiver, uint indexed _type, uint _level, uint _money, uint _time);

    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) SPONSOR;
    mapping (uint => uint) INTRODUCER;
    mapping (uint => uint) UPLINE;
    mapping (uint => uint) FEE;
    uint REFERRAL_LIMIT = 3;

    struct UserStruct {
        bool manual;
        bool isExist;
        uint level;
        uint introducedTotal;
        uint referrerID;
        uint introducerID;
        address wallet;
        uint[] introducers;
        uint[] referrals;
    }

    mapping (uint => UserStruct) public users;
    mapping (address => uint) public userList;
    mapping (uint => uint) public stats_level;
    
    uint public currentUserID = 0;
    uint public stats_total = 0 ether;
    uint stats = 0 ether;
    uint Stats = 0 ether;
    bool public paused = false;

    constructor() public {

        LEVEL_PRICE[0.1 ether] = 1;
        LEVEL_PRICE[0.15 ether] = 2;
        LEVEL_PRICE[0.5 ether] = 3;
        LEVEL_PRICE[1.5 ether] = 4;
        LEVEL_PRICE[3.5 ether] = 5;
        LEVEL_PRICE[7 ether] = 6;
        LEVEL_PRICE[20 ether] = 7;
        LEVEL_PRICE[60 ether] = 8;

        SPONSOR[0.1 ether] = 0.027 ether;
        SPONSOR[0.15 ether] = 0.105 ether;
        SPONSOR[0.5 ether] = 0.35 ether;
        SPONSOR[1.5 ether] = 1.05 ether;
        SPONSOR[3.5 ether] = 2.45 ether;
        SPONSOR[7 ether] = 4.9 ether;
        SPONSOR[20 ether] = 14 ether;
        SPONSOR[60 ether] = 42 ether;

        INTRODUCER[0.1 ether] = 0.0315 ether;
        INTRODUCER[0.15 ether] = 0.0225 ether;
        INTRODUCER[0.5 ether] = 0.075 ether;
        INTRODUCER[1.5 ether] = 0.225 ether;
        INTRODUCER[3.5 ether] = 0.525 ether;
        INTRODUCER[7 ether] = 1.05 ether;
        INTRODUCER[20 ether] = 3 ether;
        INTRODUCER[60 ether] = 9 ether;

        UPLINE[0.1 ether] = 0.00504 ether;
        UPLINE[0.15 ether] = 0.0036 ether;
        UPLINE[0.5 ether] = 0.012 ether;
        UPLINE[1.5 ether] = 0.036 ether;
        UPLINE[3.5 ether] = 0.084 ether;
        UPLINE[7 ether] = 0.168 ether;
        UPLINE[20 ether] = 0.48 ether;
        UPLINE[60 ether] = 1.44 ether;

        FEE[0.1 ether] = 0.01 ether;

        UserStruct memory userStruct;
        currentUserID++;

        userStruct = UserStruct({
            manual: false,
            isExist: true,
            level: 18,
            introducedTotal: 0,
            referrerID: 0,
            introducerID: 0,
            wallet: main_address,
            introducers: new uint[](0),
            referrals: new uint[](0)
        });

        users[currentUserID] = userStruct;
        userList[main_address] = currentUserID;
    }

    function setMainAddress(address _main_address) public onlyOwner {
        require(userList[_main_address] == 0, 'Address is already in use by another user');
        
        delete userList[main_address];
        userList[_main_address] = uint(1);
        main_address = _main_address;
        users[1].wallet = _main_address;
    }

    function setAddress(address _main_address, address _upline_address) public onlyOwner {
      Main_address = _main_address;
      Upline_address = _upline_address;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function getStats() public view onlyOwner returns(uint) {
      return Stats;
    }

     
    function setLevelPrice(uint _price, uint _level) public onlyOwner {
        LEVEL_PRICE[_price] = _level;
    }

    function setSponsor(uint _price, uint _sponsor) public onlyOwner {
        SPONSOR[_price] = _sponsor;
    }

    function setIntroducer(uint _price, uint _introducer) public onlyOwner {
        INTRODUCER[_price] = _introducer;
    }

    function setUpline(uint _price, uint _upline) public onlyOwner {
        UPLINE[_price] = _upline;
    }

    function setFee(uint _price, uint _fee) public onlyOwner {
      FEE[_price] = _fee;
    }

    function setCurrentUserID(uint _currentUserID) public onlyOwner {
        currentUserID = _currentUserID;
    }

    function viewStats() public view onlyOwner returns(uint) {
      return stats;
    }

    function addManagers(address manager_1, address manager_2, address manager_3, address manager_4, address manager_5, address manager_6, address manager_7, address manager_8, address manager_9, address manager_10) public onlyOwner {
        managers[manager_1] = true;
        managers[manager_2] = true;
        managers[manager_3] = true;
        managers[manager_4] = true;
        managers[manager_5] = true;
        managers[manager_6] = true;
        managers[manager_7] = true;
        managers[manager_8] = true;
        managers[manager_9] = true;
        managers[manager_10] = true;
    }

    function removeManagers(address manager_1, address manager_2, address manager_3, address manager_4, address manager_5, address manager_6, address manager_7, address manager_8, address manager_9, address manager_10) public onlyOwner {
        managers[manager_1] = false;
        managers[manager_2] = false;
        managers[manager_3] = false;
        managers[manager_4] = false;
        managers[manager_5] = false;
        managers[manager_6] = false;
        managers[manager_7] = false;
        managers[manager_8] = false;
        managers[manager_9] = false;
        managers[manager_10] = false;
    }

    function addManager(address manager) public onlyOwner {
        managers[manager] = true;
    }

    function removeManager(address manager) public onlyOwner {
        managers[manager] = false;
    }

    function setUserData(uint _userID, address _wallet, uint _referrerID, uint _introducerID, uint _referral1, uint _referral2, uint _referral3, uint _level, uint _introducedTotal) public {

        require(msg.sender == owner || managers[msg.sender], "Only for owner");
        require(_userID > 1, 'Invalid user ID');
        require(_level > 0, 'Invalid level');
        require(_introducedTotal >= 0, 'Invalid introduced total');
        require(_wallet != address(0), 'Invalid user wallet');
        
        if(_userID > 1){
          require(_referrerID > 0, 'Invalid referrer ID');
          require(_introducerID > 0, 'Invalid introducer ID');
        }

        if(_userID > currentUserID){
            currentUserID++;
        }

        if(users[_userID].isExist){
            delete userList[users[_userID].wallet];
            delete users[_userID];
        }

        UserStruct memory userStruct;

        userStruct = UserStruct({
            manual: true,
            isExist: true,
            level: _level,
            introducedTotal: _introducedTotal,
            referrerID: _referrerID,
            introducerID: _introducerID,
            wallet: _wallet,
            introducers: new uint[](0),
            referrals: new uint[](0)
        });
    
        users[_userID] = userStruct;
        userList[_wallet] = _userID;

        if(_referral1 != uint(0)){
            users[_userID].referrals.push(_referral1);
        }
           
        if(_referral2 != uint(0)){
            users[_userID].referrals.push(_referral2);
        }

        if(_referral3 != uint(0)){
            users[_userID].referrals.push(_referral3);
        }

    }

    function () external payable {

        require(!paused);
        require(LEVEL_PRICE[msg.value] > 0, 'You have sent incorrect payment amount');

      if(LEVEL_PRICE[msg.value] == 1){

            uint referrerID = 0;
            address referrer = bytesToAddress(msg.data);

            if(referrer == address(0)){
                referrerID = 1;
            } else if (userList[referrer] > 0 && userList[referrer] <= currentUserID){
                referrerID = userList[referrer];
            } else {
                revert('Incorrect referrer');
            }

            if(users[userList[msg.sender]].isExist){
                revert('You are already signed up');
            } else {
                registerUser(referrerID);
            }
        } else if(users[userList[msg.sender]].isExist){
            upgradeUser(LEVEL_PRICE[msg.value]);
        } else {
            revert("Please buy first level");
        }
    }

    function registerUser(uint _referrerID) internal {

        require(!users[userList[msg.sender]].isExist, 'You are already signed up');
        require(_referrerID > 0 && _referrerID <= currentUserID, 'Incorrect referrer ID');
        require(LEVEL_PRICE[msg.value] == 1, 'You have sent incorrect payment amount');

        uint _introducerID = _referrerID;

        if(_referrerID != 1 && users[_referrerID].referrals.length >= REFERRAL_LIMIT)
        {
            _referrerID = findFreeReferrer(_referrerID);
        }

        UserStruct memory userStruct;
        currentUserID++;

        userStruct = UserStruct({
            manual: false,
            isExist : true,
            level: 1,
            introducedTotal: 0,
            referrerID : _referrerID,
            introducerID : _introducerID,
            wallet : msg.sender,
            introducers: new uint[](0),
            referrals : new uint[](0)
        });

        users[currentUserID] = userStruct;
        userList[msg.sender] = currentUserID;

        uint upline_1_id = users[_introducerID].introducerID;
        uint upline_2_id = users[upline_1_id].introducerID;
        uint upline_3_id = users[upline_2_id].introducerID;
        uint upline_4_id = users[upline_3_id].introducerID;

        if(upline_1_id >0){
            users[currentUserID].introducers.push(upline_1_id);
        }

        if(upline_2_id >0){
            users[currentUserID].introducers.push(upline_2_id);
        }

        if(upline_3_id >0){
            users[currentUserID].introducers.push(upline_3_id);
        }

        if(upline_4_id >0){
            users[currentUserID].introducers.push(upline_4_id);
        }

        if(_referrerID != 1){
            users[_referrerID].referrals.push(currentUserID);
        }

        users[_referrerID].introducedTotal += 1;

        stats_level[1] = SafeMath.add(stats_level[1], uint(1));

        processPayment(currentUserID, 1);

        emit Register(currentUserID, _referrerID, _introducerID, now);
    }

    function upgradeUser(uint _level) internal {

        require(users[userList[msg.sender]].isExist, 'You are not signed up yet');
        require( _level >= 2 && _level <= 18, 'Incorrect level');
        require(LEVEL_PRICE[msg.value] == _level, 'You have sent incorrect payment amount');
        require(users[userList[msg.sender]].level < _level, 'You have already activated this level');

        uint level_previous = SafeMath.sub(_level, uint(1));

        require(users[userList[msg.sender]].level == level_previous, 'Buy the previous level first');
        
        users[userList[msg.sender]].level = _level;

        stats_level[level_previous] = SafeMath.sub(stats_level[level_previous], uint(1));
        stats_level[_level] = SafeMath.add(stats_level[_level], uint(1));

        processPayment(userList[msg.sender], _level);
        
        emit Upgrade(userList[msg.sender], _level, msg.value, now);
    }

    function processPayment(uint _user, uint _level) internal {

        uint sponsor_id;
        uint introducer_id = users[_user].introducerID;
        uint money_left = msg.value;

        if(users[_user].manual == true){

            uint upline_2_id = users[users[introducer_id].introducerID].introducerID;
            uint upline_3_id = users[upline_2_id].introducerID;
            uint upline_4_id = users[upline_3_id].introducerID;
    
            if(users[introducer_id].introducerID >0){
                users[_user].introducers.push(users[introducer_id].introducerID);
            }
    
            if(upline_2_id >0){
                users[_user].introducers.push(upline_2_id);
            }
    
            if(upline_3_id >0){
                users[_user].introducers.push(upline_3_id);
            }
    
            if(upline_4_id >0){
                users[_user].introducers.push(upline_4_id);
            }

            users[_user].manual = false;

        }

        if(FEE[msg.value] > 0){
          address(uint160(Main_address)).transfer(FEE[msg.value]);
          money_left = SafeMath.sub(money_left,FEE[msg.value]);
          stats = SafeMath.add(stats,FEE[msg.value]);
      }

      if(_level == 1 || _level == 5 || _level == 9 || _level == 13 || _level == 17){
          sponsor_id = users[_user].referrerID;
      } else if(_level == 2 || _level == 6 || _level == 10 || _level == 14 || _level == 18){
          sponsor_id = users[users[_user].referrerID].referrerID;
      } else if(_level == 3 || _level == 7 || _level == 11 || _level == 15){
          sponsor_id = users[users[users[_user].referrerID].referrerID].referrerID;
      } else if(_level == 4 || _level == 8 || _level == 12 || _level == 16){
          sponsor_id = users[users[users[users[_user].referrerID].referrerID].referrerID].referrerID;
      }

        stats_total = SafeMath.add(stats_total,msg.value);

        if(!users[sponsor_id].isExist || users[sponsor_id].level < _level){
            if(users[_user].referrerID != 1){
                emit Lost(_user, sponsor_id, uint(1), _level, SPONSOR[msg.value], now);
            }
        } else {
                address(uint160(users[sponsor_id].wallet)).transfer(SPONSOR[msg.value]);
                money_left = SafeMath.sub(money_left,SPONSOR[msg.value]);
                emit Payment(_user, sponsor_id, uint(1), _level, SPONSOR[msg.value], now);
        }
        
        if(users[introducer_id].isExist){

          if(INTRODUCER[msg.value] > 0){
                address(uint160(users[introducer_id].wallet)).transfer(INTRODUCER[msg.value]);
                money_left = SafeMath.sub(money_left,INTRODUCER[msg.value]);
                emit Payment(_user, introducer_id, uint(2), _level, INTRODUCER[msg.value], now);
          }

          if(UPLINE[msg.value] > 0){
            if(introducer_id > 0 && users[users[introducer_id].introducerID].isExist){

              for (uint i=0; i<users[_user].introducers.length; i++) {
                if(users[users[_user].introducers[i]].isExist && (users[users[_user].introducers[i]].introducedTotal >= SafeMath.add(i, uint(1)) || users[users[_user].introducers[i]].introducedTotal >= uint(3))){
                  address(uint160(users[users[_user].introducers[i]].wallet)).transfer(UPLINE[msg.value]);
                  emit Payment(_user, users[_user].introducers[i], uint(3), _level, UPLINE[msg.value], now);
                  money_left = SafeMath.sub(money_left,UPLINE[msg.value]);
                } else {
                    emit Lost(_user, users[_user].introducers[i], uint(3), _level, UPLINE[msg.value], now);
                }
              }
            }
          }
        }

        if(money_left > 0){
            address(uint160(Upline_address)).transfer(money_left);
            Stats = SafeMath.add(Stats,money_left);
        }
    }

    function findFreeReferrer(uint _user) public view returns(uint) {

        require(users[_user].isExist, 'User does not exist');

        if(users[_user].referrals.length < REFERRAL_LIMIT){
            return _user;
        }

        uint[] memory referrals = new uint[](363);
        referrals[0] = users[_user].referrals[0]; 
        referrals[1] = users[_user].referrals[1];
        referrals[2] = users[_user].referrals[2];

        uint freeReferrer;
        bool noFreeReferrer = true;
        
        for(uint i = 0; i < 363; i++){
            if(users[referrals[i]].referrals.length == REFERRAL_LIMIT){
                if(i < 120){
                    referrals[(i+1)*3] = users[referrals[i]].referrals[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referrals[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referrals[2];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        if(noFreeReferrer){
            freeReferrer = 1;
        }
        return freeReferrer;
    }

    function viewUserReferrals(uint _user) public view returns(uint[] memory) {
        return users[_user].referrals;
    }

    function viewUserIntroducers(uint _user) public view returns(uint[] memory) {
      return users[_user].introducers;
  }

    function viewUserLevel(uint _user) public view returns(uint) {
        return users[_user].level;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address  addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}