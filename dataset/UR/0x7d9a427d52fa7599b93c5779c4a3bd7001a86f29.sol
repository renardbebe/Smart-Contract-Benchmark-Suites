 

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

  address public owner;
  address public mainAddress;

  constructor() public {
    owner = msg.sender;
    mainAddress = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only for owner");
    _;
  }

  function transferOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }

}

contract UNITY is Ownable {
    
    event Register(uint indexed _user, uint indexed _referrer, uint indexed _introducer, uint _time);
    event Upgrade(uint indexed _user, uint _stage, uint _price, uint _time);
    event Payment(uint indexed _user, uint indexed _referrer, uint indexed _introducer, uint _stage, uint _money, uint _time);
    event PaymentUpline(uint indexed _user, uint indexed _upline, uint _stage, uint _money, uint _time);
    event LostMoney(uint indexed _referrer, uint indexed _referral, uint _stage, uint _money, uint _time);

    mapping (uint => uint) public STAGE_PRICE;
    uint REFERRER_1_STAGE_LIMIT = 4;

    struct UserStruct {
        bool isExist;
        address wallet;
        uint referrerID;
        uint introducerID;
        uint stage;
        uint introducedTotal;
        uint[] introducers;
        address[] referral;
    }

    mapping (uint => UserStruct) public users;
    mapping (address => uint) public userList;

    uint public currentUserID = 0;
    uint public total = 0 ether;
    uint public totalFees = 0 ether;
    bool public paused = false;

    constructor() public {

        STAGE_PRICE[1] = 0.10 ether;
        STAGE_PRICE[2] = 0.20 ether;
        STAGE_PRICE[3] = 0.90 ether;
        STAGE_PRICE[4] = 2.70 ether;
        STAGE_PRICE[5] = 8.10 ether;
        STAGE_PRICE[6] = 24.30 ether;
        STAGE_PRICE[7] = 72.90 ether;
        STAGE_PRICE[8] = 218.70 ether;

        UserStruct memory userStruct;
        currentUserID++;

        userStruct = UserStruct({
            isExist : true,
            wallet : mainAddress,
            referrerID : 0,
            introducerID : 0,
            introducedTotal: 0,
            stage: 8,
            introducers: new uint[](0),
            referral: new address[](0)
        });

        users[currentUserID] = userStruct;
        userList[mainAddress] = currentUserID;
    }

    function setMainAddress(address _mainAddress) public onlyOwner {

        require(userList[_mainAddress] == 0, 'Address is already in use by another user');
        
        delete userList[mainAddress];
        userList[_mainAddress] = uint(1);
        mainAddress = _mainAddress;
        users[1].wallet = _mainAddress;
      }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
      }

     
    function setStagePrice(uint _stage, uint _price) public onlyOwner {
        STAGE_PRICE[_stage] = _price;
      }

    function setCurrentUserID(uint _currentUserID) public onlyOwner {
        currentUserID = _currentUserID;
      }

     
    function setUserData(uint _userID, address _wallet, uint _referrerID, uint _introducerID, address _referral1, address _referral2, address _referral3, address _referral4, uint _stage, uint _introducedTotal) public onlyOwner {

        require(_userID > 0, 'Invalid user ID');
        require(_stage > 0, 'Invalid stage');
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
            isExist : true,
            wallet : _wallet,
            referrerID : _referrerID,
            introducerID : _introducerID,
            stage : _stage,
            introducedTotal: _introducedTotal,
            introducers: new uint[](0),
            referral : new address[](0)
        });
    
        users[_userID] = userStruct;
        userList[_wallet] = _userID;

        users[_userID].introducers.push(_introducerID);
        uint upline_2_id = users[_introducerID].introducerID;
        uint upline_3_id = users[upline_2_id].introducerID;
        uint upline_4_id = users[upline_3_id].introducerID;

        if(upline_2_id >0){
            users[_userID].introducers.push(upline_2_id);
        }

        if(upline_3_id >0){
            users[_userID].introducers.push(upline_3_id);
        }

        if(upline_4_id >0){
            users[_userID].introducers.push(upline_4_id);
        }

        if(_referral1 != address(0)){
            users[_userID].referral.push(_referral1);
        }
           
        if(_referral2 != address(0)){
            users[_userID].referral.push(_referral2);
        }

        if(_referral3 != address(0)){
            users[_userID].referral.push(_referral3);
        }

        if(_referral4 != address(0)){
            users[_userID].referral.push(_referral4);
        }

    }

    function () external payable {

        require(!paused, 'Temporarily not accepting new users and Stage upgrades');

        uint stage;

        if(msg.value == STAGE_PRICE[1]){
            stage = 1;
        }else if(msg.value == STAGE_PRICE[2]){
            stage = 2;
        }else if(msg.value == STAGE_PRICE[3]){
            stage = 3;
        }else if(msg.value == STAGE_PRICE[4]){
            stage = 4;
        }else if(msg.value == STAGE_PRICE[5]){
            stage = 5;
        }else if(msg.value == STAGE_PRICE[6]){
            stage = 6;
        }else if(msg.value == STAGE_PRICE[7]){
            stage = 7;
        }else if(msg.value == STAGE_PRICE[8]){
            stage = 8;
        }else {
            revert('You have sent incorrect payment amount');
        }

        if(stage == 1){

            uint referrerID = 0;
            address referrer = bytesToAddress(msg.data);

            if (userList[referrer] > 0 && userList[referrer] <= currentUserID){
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
            upgradeUser(stage);
        } else {
            revert("Please buy first stage");
        }
    }

    function registerUser(uint _referrerID) internal {

        require(!users[userList[msg.sender]].isExist, 'You are already signed up');
        require(_referrerID > 0 && _referrerID <= currentUserID, 'Incorrect referrer ID');
        require(msg.value==STAGE_PRICE[1], 'You have sent incorrect payment amount');

        uint _introducerID = _referrerID;

        if(users[_referrerID].referral.length >= REFERRER_1_STAGE_LIMIT)
        {
            _referrerID = userList[findFreeReferrer(_referrerID)];
        }

        UserStruct memory userStruct;
        currentUserID++;

        userStruct = UserStruct({
            isExist : true,
            wallet : msg.sender,
            referrerID : _referrerID,
            introducerID : _introducerID,
            stage: 1,
            introducedTotal: 0,
            introducers: new uint[](0),
            referral: new address[](0)
        });

        users[currentUserID] = userStruct;
        userList[msg.sender] = currentUserID;

        users[currentUserID].introducers.push(_introducerID);
        uint upline_2_id = users[_introducerID].introducerID;
        uint upline_3_id = users[upline_2_id].introducerID;
        uint upline_4_id = users[upline_3_id].introducerID;

        if(upline_2_id >0){
            users[currentUserID].introducers.push(upline_2_id);
        }

        if(upline_3_id >0){
            users[currentUserID].introducers.push(upline_3_id);
        }

        if(upline_4_id >0){
            users[currentUserID].introducers.push(upline_4_id);
        }

        users[_referrerID].introducedTotal += 1;
        users[_referrerID].referral.push(msg.sender);

        upgradePayment(currentUserID, 1);

        emit Register(currentUserID, _referrerID, _introducerID, now);
    }

    function upgradeUser(uint _stage) internal {

        require(users[userList[msg.sender]].isExist, 'You are not signed up yet');
        require( _stage >= 2 && _stage <= 8, 'Incorrect stage');
        require(msg.value==STAGE_PRICE[_stage], 'You have sent incorrect payment amount');
        require(users[userList[msg.sender]].stage < _stage, 'You have already activated this stage');
        
        users[userList[msg.sender]].stage = _stage;

        upgradePayment(userList[msg.sender], _stage);
        
        emit Upgrade(userList[msg.sender], _stage, STAGE_PRICE[_stage], now);
    }

    function upgradePayment(uint _user, uint _stage) internal {

        uint referrer_id;
        uint introducer_id;
        uint money_sponsor = SafeMath.div(STAGE_PRICE[_stage],2);
        uint money_introducer = SafeMath.div(money_sponsor,2);
        uint money_upline = SafeMath.div(money_introducer,4);
        uint money_left = STAGE_PRICE[_stage];

        total = SafeMath.add(total,STAGE_PRICE[_stage]);

        if(_stage == 1 || _stage == 5){
            referrer_id = users[_user].referrerID;
        } else if(_stage == 2 || _stage == 6){
            referrer_id = users[users[_user].referrerID].referrerID;
        } else if(_stage == 3 || _stage == 7){
            referrer_id = users[users[users[_user].referrerID].referrerID].referrerID;
        } else if(_stage == 4 || _stage == 8){
            referrer_id = users[users[users[users[_user].referrerID].referrerID].referrerID].referrerID;
        }

        if(!users[referrer_id].isExist || users[referrer_id].stage < _stage){
            referrer_id = 1;

            emit LostMoney(referrer_id, userList[msg.sender], _stage, money_sponsor, now);
        } else {
            if(users[referrer_id].stage >= _stage){
                bool result_1;
                result_1 = address(uint160(users[referrer_id].wallet)).send(money_sponsor);
                money_left = SafeMath.sub(money_left,money_sponsor);
            } else {
                emit LostMoney(referrer_id, userList[msg.sender], _stage, money_sponsor, now);
            }
        }

        if(!users[users[_user].introducerID].isExist){
            introducer_id = 1;
        } else {
            introducer_id = users[_user].introducerID;

            bool result_2;
            result_2 = address(uint160(users[introducer_id].wallet)).send(money_introducer);
            money_left = SafeMath.sub(money_left,money_introducer);
        
            if(introducer_id > 0 && users[users[introducer_id].introducerID].isExist){

                for (uint i=0; i<users[_user].introducers.length; i++) {

                    if(users[users[_user].introducers[i]].isExist && users[users[_user].introducers[i]].stage >= _stage && users[users[_user].introducers[i]].introducedTotal >= 1){
                        address(uint160(users[users[_user].introducers[i]].wallet)).transfer(money_upline);
                        emit PaymentUpline(userList[msg.sender], users[_user].introducers[i], _stage, money_upline, now);
                        money_left = SafeMath.sub(money_left,money_upline);
                    } else {
                        emit LostMoney(users[_user].introducers[i], userList[msg.sender], _stage, money_upline, now);
                    }
                }
            }
        }

        if(money_left > 0){
            bool result_lost;
            result_lost = address(uint160(mainAddress)).send(money_left);
            totalFees = SafeMath.add(totalFees,money_left);
        }

        emit Payment(userList[msg.sender], referrer_id, introducer_id, _stage, STAGE_PRICE[_stage], now);

    }

    function findFreeReferrer(uint _user) public view returns(address) {

        require(users[_user].isExist, 'User does not exist');

        if(users[_user].referral.length < REFERRER_1_STAGE_LIMIT){
            return users[_user].wallet;
        }
        
        address[] memory referrals = new address[](1364);
        referrals[0] = users[_user].referral[0]; 
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        referrals[3] = users[_user].referral[3];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 1364; i++){
            if(users[userList[referrals[i]]].referral.length == REFERRER_1_STAGE_LIMIT){
                if(i < 340){
                    referrals[(i+1)*3] = users[userList[referrals[i]]].referral[0];
                    referrals[(i+1)*3+1] = users[userList[referrals[i]]].referral[1];
                    referrals[(i+1)*3+2] = users[userList[referrals[i]]].referral[2];
                    referrals[(i+1)*3+3] = users[userList[referrals[i]]].referral[3];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'Free referrer not found');
        return freeReferrer;

    }

    function viewUserReferrals(uint _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserIntroducers(uint _user) public view returns(uint[] memory) {
        return users[_user].introducers;
    }

    function viewUserStage(uint _user) public view returns(uint) {
        return users[_user].stage;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}