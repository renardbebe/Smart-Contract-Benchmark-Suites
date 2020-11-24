 

 
pragma solidity ^0.5.7;


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, 'Invalid values');
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'Substraction result smaller than zero');
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'Invalid values');
        return c;
    }
}


 
contract Ownable {
    address public owner;
    address public manager;
    address public ownerWallet;
    address public adminWallet;
    uint adminPersent;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
        adminWallet = 0xcFebf7C3Ec7B407DFf17aa20a2631c95c8ff508c;
        ownerWallet = 0xcFebf7C3Ec7B407DFf17aa20a2631c95c8ff508c;
        adminPersent = 10;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setManager(address _manager) public onlyOwnerOrManager {
        manager = _manager;
    }

    function setAdminWallet(address _admin) public onlyOwner {
        adminWallet = _admin;
    }
}


contract WalletOnly {
    function isContract(address account) internal view returns (bool) {
         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}


contract Absolutus is Ownable, WalletOnly {
     
    event RegLevelEvent(address indexed _user, address indexed _referrer, uint _id, uint _time);
    event BuyLevelEvent(address indexed _user, uint _level, uint _time);
    event ProlongateLevelEvent(address indexed _user, uint _level, uint _time);
    event GetMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint _price, bool _prevLost);
    event LostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time, uint _price, bool _prevLost);

     
    event PaymentForHolder(address indexed _addr, uint _index, uint _value);
    event PaymentForHolderLost(address indexed _addr, uint _index, uint _value);

     
    mapping (uint => uint) public LEVEL_PRICE;
    address canSetLevelPrice;
    uint REFERRER_1_LEVEL_LIMIT = 3;
    uint PERIOD_LENGTH = 365 days;  
    uint MAX_AUTOPAY_COUNT = 5;      

    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint fund;           
        uint currentLvl;     
        address[] referral;
        mapping (uint => uint) levelExpired;
        mapping (uint => uint) paymentsCount;
    }

    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (address => uint) public allowUsers;

    uint public currUserID = 0;
    bool nostarted = false;

    AbsDAO _dao;  
    bool daoSet = false;  

    using SafeMath for uint;  

    constructor() public {
         
        LEVEL_PRICE[1] = 0.5 ether;
        LEVEL_PRICE[2] = 1.0 ether;
        LEVEL_PRICE[3] = 2.0 ether;
        LEVEL_PRICE[4] = 4.0 ether;
        LEVEL_PRICE[5] = 16.0 ether;
        LEVEL_PRICE[6] = 32.0 ether;
        LEVEL_PRICE[7] = 64.0 ether;
        LEVEL_PRICE[8] = 128.0 ether;

        UserStruct memory userStruct;
        currUserID++;

        canSetLevelPrice = owner;

         
        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            fund: 0,
            currentLvl: 1,
            referral : new address[](0)
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;

        users[ownerWallet].levelExpired[1] = 77777777777;
        users[ownerWallet].levelExpired[2] = 77777777777;
        users[ownerWallet].levelExpired[3] = 77777777777;
        users[ownerWallet].levelExpired[4] = 77777777777;
        users[ownerWallet].levelExpired[5] = 77777777777;
        users[ownerWallet].levelExpired[6] = 77777777777;
        users[ownerWallet].levelExpired[7] = 77777777777;
        users[ownerWallet].levelExpired[8] = 77777777777;

         
        nostarted = true;
    }

    function () external payable {
        require(!isContract(msg.sender), 'This contract cannot support payments from other contracts');

        uint level;

         
        if (msg.value == LEVEL_PRICE[1]) {
            level = 1;
        } else if (msg.value == LEVEL_PRICE[2]) {
            level = 2;
        } else if (msg.value == LEVEL_PRICE[3]) {
            level = 3;
        } else if (msg.value == LEVEL_PRICE[4]) {
            level = 4;
        } else if (msg.value == LEVEL_PRICE[5]) {
            level = 5;
        } else if (msg.value == LEVEL_PRICE[6]) {
            level = 6;
        } else if (msg.value == LEVEL_PRICE[7]) {
            level = 7;
        } else if (msg.value == LEVEL_PRICE[8]) {
            level = 8;
        } else {
             
            if (!users[msg.sender].isExist || users[msg.sender].currentLvl >= 8)
                revert('Incorrect Value send');

            users[msg.sender].fund += msg.value;
            updateCurrentLevel(msg.sender);
             
            if (LEVEL_PRICE[users[msg.sender].currentLvl+1] <= users[msg.sender].fund) {
                buyLevelByFund(msg.sender, 0);
            }
            return;
        }

         
        if (users[msg.sender].isExist) {
            buyLevel(level);
        } else if (level == 1) {
            uint refId = 0;
            address referrer = bytesToAddress(msg.data);

            if (users[referrer].isExist) {
                refId = users[referrer].id;
            } else {
                revert('Incorrect referrer');
                 
            }

            regUser(refId);
        } else {
            revert("Please buy first level for 0.1 ETH");
        }
    }

     
    function allowUser(address _user) public onlyOwner {
        require(nostarted, 'You cant allow user in battle mode');
        allowUsers[_user] = 1;
    }

     
    function battleMode() public onlyOwner {
        require(nostarted, 'Battle mode activated');
        nostarted = false;
    }

     
    function setDAOAddress(address payable _dao_addr) public onlyOwner {
        require(!daoSet, 'DAO address already set');
        _dao = AbsDAO(_dao_addr);
        daoSet = true;
    }

     
     
    function payToAdmin(uint _amount) internal {
        if (daoSet) {
             
            uint holderCount = _dao.getHolderCount();        
            for (uint i = 1; i <= holderCount; i++) {
                uint val = _dao.getHolderPieAt(i);           
                address payable holder = _dao.getHolder(i);  

                if (val > 0) {                               
                    uint payValue = _amount.div(100).mul(val);  
                    holder.transfer(payValue);
                    emit PaymentForHolder(holder, i, payValue);  
                } else {
                    emit PaymentForHolderLost(holder, i, val);  
                }
            }
        } else {
             
            address(uint160(adminWallet)).transfer(_amount);
        }
    }

     
    function regUser(uint referrerID) public payable {
        require(!isContract(msg.sender), 'This contract cannot support payments from other contracts');

        if (nostarted) {
            require(allowUsers[msg.sender] > 0, 'You cannot use this contract on start');
        }

        require(!users[msg.sender].isExist, 'User exist');
        require(referrerID > 0 && referrerID <= currUserID, 'Incorrect referrer Id');
        require(msg.value==LEVEL_PRICE[1], 'Incorrect Value');

         
         
        uint _referrerID = referrerID;

        if (users[userList[referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT) {
            _referrerID = users[findFreeReferrer(userList[referrerID])].id;
        }


        UserStruct memory userStruct;
        currUserID++;

         
        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            fund: 0,
            currentLvl: 1,
            referral : new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[1] = now + PERIOD_LENGTH;
        users[msg.sender].levelExpired[2] = 0;
        users[msg.sender].levelExpired[3] = 0;
        users[msg.sender].levelExpired[4] = 0;
        users[msg.sender].levelExpired[5] = 0;
        users[msg.sender].levelExpired[6] = 0;
        users[msg.sender].levelExpired[7] = 0;
        users[msg.sender].levelExpired[8] = 0;

        users[userList[_referrerID]].referral.push(msg.sender);

         
        payForLevel(
            1,
            msg.sender,
            msg.sender,
            0,
            false
        );

        emit RegLevelEvent(
            msg.sender,
            userList[_referrerID],
            currUserID,
            now
        );
    }

     
    function buyLevel(uint _level) public payable {
        require(!isContract(msg.sender), 'This contract cannot support payments from other contracts');

        require(users[msg.sender].isExist, 'User not exist');
        require(_level>0 && _level<=8, 'Incorrect level');
        require(msg.value==LEVEL_PRICE[_level], 'Incorrect Value');

        if (_level > 1) {  
            for (uint i = _level-1; i>0; i--) {
                require(users[msg.sender].levelExpired[i] >= now, 'Buy the previous level');
            }
        }

         
         
         
        if (users[msg.sender].levelExpired[_level] > now) {
            users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        } else {
            users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
        }

         
        if (users[msg.sender].currentLvl < _level)
            users[msg.sender].currentLvl = _level;

         
        payForLevel(
            _level,
            msg.sender,
            msg.sender,
            0,
            false
        );

        emit BuyLevelEvent(msg.sender, _level, now);
    }

    function setLevelPrice(uint _level, uint _price) public {
        require(_level >= 0 && _level <= 8, 'Invalid level');
        require(msg.sender == canSetLevelPrice, 'Invalid caller');
        require(_price > 0, 'Price cannot be zero or negative');

        LEVEL_PRICE[_level] = _price * 1.0 finney;
    }

    function setCanUpdateLevelPrice(address addr) public onlyOwner {
        canSetLevelPrice = addr;
    }

     
    function setMaxAutopayForLevelCount(uint _count) public onlyOwnerOrManager {
        MAX_AUTOPAY_COUNT = _count;
    }

     
    function buyLevelByFund(address referer, uint _counter) internal {
        require(users[referer].isExist, 'User not exists');

        uint _level = users[referer].currentLvl + 1;  
        require(users[referer].fund >= LEVEL_PRICE[_level], 'Not have funds to autobuy level');

        uint remaining = users[referer].fund - LEVEL_PRICE[_level];  

         
        if (users[referer].levelExpired[_level] >= now) {
            users[referer].levelExpired[_level] += PERIOD_LENGTH;
        } else {
            users[referer].levelExpired[_level] = now + PERIOD_LENGTH;
        }

        users[referer].currentLvl = _level;  
        users[referer].fund = 0;             

         
        payForLevel(
            _level,
            referer,
            referer,
            _counter+1,
            false
        );
        address(uint160(referer)).transfer(remaining);  

        emit BuyLevelEvent(referer, _level, now);  
    }

     
    function updateCurrentLevel(address _user) internal {
        users[_user].currentLvl = actualLevel(_user);
    }

     
    function actualLevel(address _user) public view returns(uint) {
        require(users[_user].isExist, 'User not found');

        for (uint i = 1; i <= 8; i++) {
            if (users[_user].levelExpired[i] <= now) {
                return i-1;
            }
        }

        return 8;
    }

     
     
    function payForLevel(uint _level, address _user, address _sender, uint _autoPayCtr, bool prevLost) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;

        if (_level == 1 || _level == 5) {
            referer = userList[users[_user].referrerID];
        } else if (_level == 2 || _level == 6) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if (_level == 3 || _level == 7) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if (_level == 4 || _level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if (!users[referer].isExist) {
            referer = userList[1];
        }

        uint amountToUser;
        uint amountToAdmin;

        amountToAdmin = LEVEL_PRICE[_level] / 100 * adminPersent;
        amountToUser = LEVEL_PRICE[_level] - amountToAdmin;

        if (users[referer].id <= 4) {
            payToAdmin(LEVEL_PRICE[_level]);

            emit GetMoneyForLevelEvent(
                referer,
                _sender,
                _level,
                now,
                amountToUser,
                prevLost
            );

            return;
        }

        if (users[referer].levelExpired[_level] >= now) {
            payToAdmin(amountToAdmin);

             
            updateCurrentLevel(referer);


             
             
            if (_level == users[referer].currentLvl && _autoPayCtr < MAX_AUTOPAY_COUNT && users[referer].currentLvl < 8) {
                users[referer].fund += amountToUser;

                emit GetMoneyForLevelEvent(
                    referer,
                    _sender,
                    _level,
                    now,
                    amountToUser,
                    prevLost
                );

                 
                if (LEVEL_PRICE[users[referer].currentLvl+1] <= users[referer].fund) {
                    buyLevelByFund(referer, _autoPayCtr);
                }
            } else {
                 
                address(uint160(referer)).transfer(amountToUser);

                emit GetMoneyForLevelEvent(
                    referer,
                    _sender,
                    _level,
                    now,
                    amountToUser,
                    prevLost
                );
            }
        } else {
             
            emit LostMoneyForLevelEvent(
                referer,
                _sender,
                _level,
                now,
                amountToUser,
                prevLost
            );

            payForLevel(
                _level,
                referer,
                _sender,
                _autoPayCtr,
                true
            );
        }
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }

        address[] memory referrals = new address[](363);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i<363; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i<120) {
                    referrals[(i+1)*3] = users[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referral[2];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address  addr ) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}


contract AbsDAO is Ownable, WalletOnly {
     
    event TransferPie(address indexed _from, address indexed _to, uint _value);
    event NewHolder(address indexed _addr, uint _index);
    event HolderChanged(address indexed _from, address indexed _to, uint _index);
    event PaymentReceived(address indexed _from, uint _value);
    event PaymentForHolder(address indexed _addr, uint _index, uint _value);
    event PaymentForHolderLost(address indexed _addr, uint _index, uint _value);

    struct Holder {
        bool isExist;
        uint id;
        uint value;
        address payable addr;
    }

    mapping(address => Holder) public holders;
    mapping(uint=>address payable) holderAddrs;

    uint holderCount;
    uint _initialPie = 100;

    using SafeMath for uint;

    constructor() public {
         
        holderCount = 1;
        holders[msg.sender] = Holder({
            isExist: true,
            id: 1,
            value: _initialPie,
            addr: msg.sender
        });

        holderAddrs[1] = msg.sender;
    }

    function () external payable {
        require(!isContract(msg.sender), 'This contract cannot support payments from other contracts');

        emit PaymentReceived(msg.sender, msg.value);

        for (uint i = 1; i <= holderCount; i++) {
            if (holders[holderAddrs[i]].value > 0) {
                uint payValue = msg.value.div(100).mul(holders[holderAddrs[i]].value);
                holderAddrs[i].transfer(payValue);
                emit PaymentForHolder(holderAddrs[i], i, payValue);
            } else {
                emit PaymentForHolderLost(holderAddrs[i], i, holders[holderAddrs[i]].value);
            }
        }
    }

    function getHolderPieAt(uint i) public view returns(uint) {
        return holders[holderAddrs[i]].value;
    }

    function getHolder(uint i) public view returns(address payable) {
        return holderAddrs[i];
    }

    function getHolderCount() public view returns(uint) {
        return holderCount;
    }

    function transferPie(uint _amount, address payable _to) public {
        require(holders[msg.sender].isExist, 'Holder not found');
        require(_amount > 0 && _amount <= holders[msg.sender].value, 'Invalid amount');

        if (_amount == holders[msg.sender].value) {
            uint id = holders[msg.sender].id;
            delete holders[msg.sender];

            holders[_to] = Holder({
                isExist: true,
                id: id,
                value: _amount,
                addr: _to
            });

            holderAddrs[id] = _to;

            emit HolderChanged(msg.sender, _to, id);
        } else {
            if (holders[_to].isExist) {
                holders[msg.sender].value -= _amount;
                holders[_to].value += _amount;
            } else if (holderCount < 20) {
                holderCount += 1;
                holders[msg.sender].value -= _amount;
                holders[_to] = Holder({
                    isExist: true,
                    id: holderCount,
                    value: _amount,
                    addr: _to
                });

                holderAddrs[holderCount] = _to;

                emit NewHolder(_to, holderCount);
            } else {
                revert('Holder limit excised');
            }
        }

        emit TransferPie(msg.sender, _to, _amount);
    }
}