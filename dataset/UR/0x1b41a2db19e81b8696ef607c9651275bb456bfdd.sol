 

 
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
  address main_address;

  constructor() public {
    owner = msg.sender;
    main_address = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only for owner");
    _;
  }

  function transferOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }

}

contract RePrize is Ownable {
    
    event Register(uint indexed _user, uint indexed _referrer, uint indexed _introducer, uint _time);
    event Upgrade(uint indexed _user, uint _level, uint _price, uint _time);
    event Payment(uint indexed _user, uint indexed _referrer, uint indexed _type, uint _level, uint _money, uint _time);
    event Lost(uint indexed _sponsor, uint indexed _user, uint _level, uint _money, uint _time);
    event LostI(uint indexed _introducer, uint indexed _user, uint _level, uint _money, uint _time);
    event TokensEarned(uint indexed _user, uint _amount, uint indexed _type, uint indexed _time);
    event PrizePurchased(uint indexed _user, uint _amount, uint _time);
    event PrizeSpecial(uint indexed _user, uint _amount, uint _time);
    event Redemption(uint indexed _user, uint _amount, uint _time);

    mapping (uint => uint) public LEVEL_PRICE;
    mapping (uint => uint) public PRIZE;
    mapping (uint => uint) public PRIZE_SPECIAL;
    mapping (uint => uint) TOKENS;
    mapping (uint => uint) FEE;
    uint REFERRAL_LIMIT = 4;

    struct UserStruct {
        bool isExist;
        uint level;
        uint referrerID;
        uint introducerID;
        uint tokens;
        address wallet;
        uint[] referrals;
    }

    mapping (uint => UserStruct) public users;
    mapping (address => uint) public userList;
    mapping (uint => bool) public blocked;
    mapping (uint => uint) public stats_level;
    
    uint public currentUserID = 0;
    uint public stats_total = 0 ether;
    uint public stats_fees = 0 ether;
    bool public paused = false;
    bool public paidRedemption = false;

    constructor() public {

        LEVEL_PRICE[0.1 ether] = 1;
        LEVEL_PRICE[0.15 ether] = 2;
        LEVEL_PRICE[0.2 ether] = 3;
        LEVEL_PRICE[0.25 ether] = 4;
        LEVEL_PRICE[0.3 ether] = 5;
        LEVEL_PRICE[0.4 ether] = 6;
        LEVEL_PRICE[0.5 ether] = 7;
        LEVEL_PRICE[0.6 ether] = 8;
        LEVEL_PRICE[0.75 ether] = 9;
        LEVEL_PRICE[0.9 ether] = 10;
        LEVEL_PRICE[1.05 ether] = 11;
        LEVEL_PRICE[1.2 ether] = 12;
        LEVEL_PRICE[1.4 ether] = 13;
        LEVEL_PRICE[1.6 ether] = 14;
        LEVEL_PRICE[1.8 ether] = 15;
        LEVEL_PRICE[2.1 ether] = 16;
        LEVEL_PRICE[2.5 ether] = 17;
        LEVEL_PRICE[3 ether] = 18;

        PRIZE[0.01 finney] = 10;
        PRIZE[0.05 finney] = 50;
        PRIZE[0.12 finney] = 120;
        PRIZE[0.25 finney] = 120;
        PRIZE[0.5 finney] = 500;
        PRIZE[0.6 finney] = 600;
        PRIZE[0.8 finney] = 800;

        TOKENS[1] = 10;
        TOKENS[2] = 5;

        UserStruct memory userStruct;
        currentUserID++;

        userStruct = UserStruct({
            isExist: true,
            level: 18,
            referrerID: 0,
            introducerID: 0,
            tokens: 0,
            wallet: main_address,
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

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPaidRedemption(bool _paid) public onlyOwner {
        paidRedemption = _paid;
    }
    
    function setBlock(uint _id, bool _block) public onlyOwner {
        require(_id > 1);
        blocked[_id] = _block;
    }

     
    function setLevelPrice(uint _price, uint _level) public onlyOwner {
        LEVEL_PRICE[_price] = _level;
    }

     
    function setPrizePrice(uint _price, uint _tokens) public onlyOwner {
        PRIZE[_price] = _tokens;
    }

     
    function setPrizeSpecial(uint _price, uint _amount) public onlyOwner {
        PRIZE_SPECIAL[_price] = _amount;
    }

     
    function setFee(uint _price, uint _fee) public onlyOwner {
        FEE[_price] = _fee;
    }

    function setCurrentUserID(uint _currentUserID) public onlyOwner {
        currentUserID = _currentUserID;
    }
    
    function setTokensAmount(uint _type, uint _tokens) public onlyOwner {

        require(_type > 0, 'Invalid type');
        require(_tokens >= 0, 'Invalid tokens');

        TOKENS[_type] = _tokens;
    }
    
    function setTokens(uint _userID, uint _tokens) public onlyOwner {

        require(_userID > 0, 'Invalid user ID');
        require(users[_userID].isExist, 'User does not exist');
        require(_tokens >= 0, 'Invalid tokens');

        users[_userID].tokens = _tokens;
    }

    function setUserData(uint _userID, address _wallet, uint _referrerID, uint _introducerID, uint _tokens, uint _referral1, uint _referral2, uint _referral3, uint _referral4, uint _level) public onlyOwner {

        require(_userID > 1, 'Invalid user ID');
        require(_level > 0, 'Invalid level');
        require(_wallet != address(0), 'Invalid user wallet');
        require(_tokens >= 0, 'Invalid tokens');
        require(_referrerID > 0, 'Invalid referrer ID');
        require(_introducerID > 0, 'Invalid introducer ID');

        if(_userID > currentUserID){
            currentUserID++;
        }

        if(users[_userID].isExist){
            delete userList[users[_userID].wallet];
            delete users[_userID];
        }

        UserStruct memory userStruct;

        userStruct = UserStruct({
            isExist: true,
            level: _level,
            referrerID: _referrerID,
            introducerID: _introducerID,
            tokens: _tokens,
            wallet: _wallet,
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

        if(_referral4 != uint(0)){
            users[_userID].referrals.push(_referral4);
        }
    }

    function () external payable {

        require(!paused);
        require(LEVEL_PRICE[msg.value] > 0 || PRIZE[msg.value] > 0, 'You have sent incorrect payment amount');

        if(PRIZE[msg.value] > 0){

            require(users[userList[msg.sender]].isExist);
            require(blocked[userList[msg.sender]] != true);

            if(msg.value == 0.01 finney){
                if(paidRedemption){
                    require(users[userList[msg.sender]].tokens >= PRIZE[msg.value], 'You do not have enough tokens');
                    users[userList[msg.sender]].tokens = SafeMath.sub(users[userList[msg.sender]].tokens, PRIZE[msg.value]);
                    emit Redemption(userList[msg.sender], PRIZE[msg.value], now);
                } else {
                    emit Redemption(userList[msg.sender], uint(0), now);
                }
            } else {
                require(users[userList[msg.sender]].tokens >= PRIZE[msg.value], 'You do not have enough tokens');

                users[userList[msg.sender]].tokens = SafeMath.sub(users[userList[msg.sender]].tokens, PRIZE[msg.value]);

                if(PRIZE_SPECIAL[msg.value] > 0){
                    PRIZE_SPECIAL[msg.value] = SafeMath.sub(PRIZE_SPECIAL[msg.value], uint(1));
                    emit PrizeSpecial(userList[msg.sender], PRIZE[msg.value], now);
                    if(PRIZE_SPECIAL[msg.value] == 1){
                        PRIZE[msg.value] = 0;
                    }
                } else {
                    emit PrizePurchased(userList[msg.sender], PRIZE[msg.value], now);
                }
            }

            address(uint160(msg.sender)).transfer(msg.value);

        } else if(LEVEL_PRICE[msg.value] == 1){

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
            isExist : true,
            level: 1,
            referrerID : _referrerID,
            introducerID : _introducerID,
            tokens: 0,
            wallet : msg.sender,
            referrals : new uint[](0)
        });

        users[currentUserID] = userStruct;
        userList[msg.sender] = currentUserID;

        if(TOKENS[1] > 0){
            users[_introducerID].tokens = SafeMath.add(users[_introducerID].tokens, TOKENS[1]);
            emit TokensEarned(_introducerID, TOKENS[1], uint(1), now);
        }

        if(TOKENS[msg.value] > 0){
            users[currentUserID].tokens = TOKENS[msg.value];
            emit TokensEarned(currentUserID, TOKENS[msg.value], uint(4), now);
        }

        if(_referrerID != 1){
            users[_referrerID].referrals.push(currentUserID);
        }

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

        if(TOKENS[2] > 0){
            users[userList[msg.sender]].tokens = SafeMath.add(users[userList[msg.sender]].tokens, TOKENS[2]);
            emit TokensEarned(userList[msg.sender], TOKENS[2], uint(2), now);
        }

        if(TOKENS[3] > 0){
            users[users[userList[msg.sender]].introducerID].tokens = SafeMath.add(users[users[userList[msg.sender]].introducerID].tokens, TOKENS[3]);
            emit TokensEarned(users[userList[msg.sender]].introducerID, TOKENS[3], uint(3), now);
        }

        if(TOKENS[msg.value] > 0){
            users[userList[msg.sender]].tokens = SafeMath.add(users[userList[msg.sender]].tokens, TOKENS[msg.value]);
            emit TokensEarned(userList[msg.sender], TOKENS[msg.value], uint(4), now);
        }

        stats_level[level_previous] = SafeMath.sub(stats_level[level_previous], uint(1));
        stats_level[_level] = SafeMath.add(stats_level[_level], uint(1));

        processPayment(userList[msg.sender], _level);
        
        emit Upgrade(userList[msg.sender], _level, msg.value, now);
    }

    function processPayment(uint _user, uint _level) internal {

        uint sponsor_id;
        uint introducer_id = users[_user].introducerID;
        uint money_left = msg.value;

        if(FEE[msg.value] > 0){
            address(uint160(main_address)).transfer(FEE[msg.value]);
            money_left = SafeMath.sub(money_left,FEE[msg.value]);
            stats_fees = SafeMath.add(stats_fees,FEE[msg.value]);
        }

        uint money_sponsor = SafeMath.div(money_left,2);
        uint money_introducer = money_sponsor;

        if(_level == 1 || _level == 4 || _level == 7 || _level == 10 || _level == 13 || _level == 16){
            money_sponsor = money_left;
            money_introducer = 0;
            sponsor_id = users[_user].referrerID;
        } else if(_level == 2 || _level == 5 || _level == 8 || _level == 11 || _level == 14 || _level == 17){
            sponsor_id = users[users[_user].referrerID].referrerID;
        } else if(_level == 3 || _level == 6 || _level == 9 || _level == 12 || _level == 15 || _level == 18){
            sponsor_id = users[users[users[_user].referrerID].referrerID].referrerID;
        }

        stats_total = SafeMath.add(stats_total,msg.value);

        if(!users[sponsor_id].isExist || users[sponsor_id].level < _level || blocked[sponsor_id] == true){
            if(users[_user].referrerID != 1){
                emit Lost(sponsor_id, _user, _level, money_sponsor, now);
            }
        } else {
                address(uint160(users[sponsor_id].wallet)).transfer(money_sponsor);
                money_left = SafeMath.sub(money_left,money_sponsor);
                emit Payment(_user, sponsor_id, uint(1), _level, money_sponsor, now);
        }

        if(money_introducer > 0){
            if(!users[introducer_id].isExist || users[introducer_id].level < _level || blocked[introducer_id] == true){
                if(users[_user].introducerID != 1){
                    emit LostI(introducer_id, _user, _level, money_introducer, now);
                }
            } else {
                address(uint160(users[introducer_id].wallet)).transfer(money_introducer);
                money_left = SafeMath.sub(money_left,money_introducer);
                emit Payment(_user, introducer_id, uint(2), _level, money_introducer, now);
            }
        }

        if(money_left > 0){
            address(uint160(main_address)).transfer(money_left);
            stats_fees = SafeMath.add(stats_fees,money_left);
        }
    }

    function findFreeReferrer(uint _user) public view returns(uint) {

        require(users[_user].isExist, 'User does not exist');

        if(users[_user].referrals.length < REFERRAL_LIMIT){
            return _user;
        }

        uint[] memory referrals = new uint[](340);
        referrals[0] = users[_user].referrals[0]; 
        referrals[1] = users[_user].referrals[1];
        referrals[2] = users[_user].referrals[2];
        referrals[3] = users[_user].referrals[3];

        uint freeReferrer;
        bool noFreeReferrer = true;
        
        for(uint i = 0; i < 340; i++){
            if(users[referrals[i]].referrals.length == REFERRAL_LIMIT){
                if(i < 84){
                    referrals[(i+1)*4] = users[referrals[i]].referrals[0];
                    referrals[(i+1)*4+1] = users[referrals[i]].referrals[1];
                    referrals[(i+1)*4+2] = users[referrals[i]].referrals[2];
                    referrals[(i+1)*4+3] = users[referrals[i]].referrals[3];
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

    function viewUserLevel(uint _user) public view returns(uint) {
        return users[_user].level;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address  addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}