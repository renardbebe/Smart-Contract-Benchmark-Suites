 

 

pragma solidity ^0.5.10;

library Util {
    struct User {
        bool isExist;
        uint256 id;
        uint256 origRefID;
        uint256 referrerID;
        address[] referral;
        uint256[] expiring;
    }
}

contract I0Crypto {
     
     
     
    event registered(address indexed user, address indexed referrer);
    event levelBought(address indexed user, uint256 level);
    event receivedEther(address indexed user, address indexed referral, uint256 level);
    event lostEther(address indexed user, address indexed referral, uint256 level);

     
     
     
    address public wallet;

    uint256 constant MAX_REFERRERS = 2;
    uint256 LEVEL_PERIOD = 365 days;

     
     
     

    mapping(address => Util.User) public users;
    mapping(uint256 => address) public userList;
    uint256 public userIDCounter = 0;

     
     
     
    constructor() public {
        wallet = 0x4118305883c1aA672420C140D7f251D34f86C55e;

        Util.User memory user;
        userIDCounter++;

        user = Util.User({
            isExist : true,
            id : userIDCounter,
            origRefID: 0,
            referrerID : 0,
            referral : new address[](0),
            expiring : new uint256[](9)
            });

        user.expiring[1] = 101010101010;
        user.expiring[2] = 101010101010;
        user.expiring[3] = 101010101010;
        user.expiring[4] = 101010101010;
        user.expiring[5] = 101010101010;
        user.expiring[6] = 101010101010;
        user.expiring[7] = 101010101010;
        user.expiring[8] = 101010101010;

        userList[userIDCounter] = wallet;
        users[wallet] = user;
    }

    function() external payable {
        uint256 level = getLevel(msg.value);

        if (users[msg.sender].isExist) {
            buy(level);
        } else if (level == 1) {
            uint256 referrerID = 0;
            address referrer = bytesToAddress(msg.data);

            if (users[referrer].isExist) {
                referrerID = users[referrer].id;
            } else {
                revert('01 wrong referrer');
            }

            register(referrerID);
        } else {
            revert("02 buy level 1 for 0.1 ETH");
        }
    }

    function register(uint256 referrerID) public payable {
        require(!users[msg.sender].isExist, '03 user exist');
        require(referrerID > 0 && referrerID <= userIDCounter, '0x04 wrong referrer ID');
        require(getLevel(msg.value) == 1, '05 wrong value');

        uint origRefID = referrerID;
		if (referrerID != 1) {
        if (users[userList[referrerID]].referral.length >= MAX_REFERRERS)
        {
            referrerID = users[findReferrer(userList[referrerID])].id;
        }
		}

        Util.User memory user;
        userIDCounter++;

        user = Util.User({
            isExist : true,
            id : userIDCounter,
            origRefID : origRefID,
            referrerID : referrerID,
            referral : new address[](0),
            expiring : new uint256[](9)
            });

        user.expiring[1] = now + LEVEL_PERIOD;
        user.expiring[2] = 0;
        user.expiring[3] = 0;
        user.expiring[4] = 0;
        user.expiring[5] = 0;
        user.expiring[6] = 0;
        user.expiring[7] = 0;
        user.expiring[8] = 0;

        userList[userIDCounter] = msg.sender;
        users[msg.sender] = user;

        users[userList[referrerID]].referral.push(msg.sender);

        payForLevel(msg.sender, 1);

        emit registered(msg.sender, userList[referrerID]);
    }

    function buy(uint256 level) public payable {
        require(users[msg.sender].isExist, '06 user not exist');

        require(level > 0 && level <= 8, '07 wrong level');

        require(getLevel(msg.value) == level, '08 wrong value');

        for (uint256 l = level - 1; l > 0; l--) {
             require(users[msg.sender].expiring[l] >= now, '09 buy level');
        }

        if (users[msg.sender].expiring[level] == 0) {
            users[msg.sender].expiring[level] = now + LEVEL_PERIOD;
        } else {
            users[msg.sender].expiring[level] += LEVEL_PERIOD;
        }

        payForLevel(msg.sender, level);
        emit levelBought(msg.sender, level);
    }

    function payForLevel(address user, uint256 level) internal {
        address referrer;
        uint256 above = level > 4 ? level - 4 : level;
        if (1 < level && level < 4) {
            checkCanBuy(user, level);
        }
        if (above == 1) {
            referrer = userList[users[user].referrerID];
        } else if (above == 2) {
            referrer = userList[users[user].referrerID];
            referrer = userList[users[referrer].referrerID];
        } else if (above == 3) {
            referrer = userList[users[user].referrerID];
            referrer = userList[users[referrer].referrerID];
            referrer = userList[users[referrer].referrerID];
        } else if (above == 4) {
            referrer = userList[users[user].referrerID];
            referrer = userList[users[referrer].referrerID];
            referrer = userList[users[referrer].referrerID];
            referrer = userList[users[referrer].referrerID];
        }

        if (!users[referrer].isExist) {
            referrer = userList[1];
        }

        if (users[referrer].expiring[level] >= now) {
            bool result;
            result = address(uint160(referrer)).send(msg.value);
            emit receivedEther(referrer, msg.sender, level);
        } else {
            emit lostEther(referrer, msg.sender, level);
            payForLevel(referrer, level);
        }
    }

    function checkCanBuy(address user, uint256 level) private view {
        if (level == 1) return;
        address[] memory referral = users[user].referral;
        require(referral.length == MAX_REFERRERS, '10 not enough referrals');

        if (level == 2) return;
        checkCanBuy(referral[0], level - 1);
        checkCanBuy(referral[1], level - 1);
    }

    function findReferrer(address user) public view returns (address) {
        address[] memory referral = users[user].referral;
        if (referral.length < MAX_REFERRERS) {
            return user;
        }

        address[] memory referrals = new address[](1024);
        referrals[0] = referral[0];
        referrals[1] = referral[1];

        address freeReferrer;
        bool hasFreeReferrer = false;

        for (uint256 i = 0; i < 1024; i++) {
            referral = users[referrals[i]].referral;
            if (referral.length == MAX_REFERRERS) {
                if (i < 512) {
                    uint256 pos = (i + 1) * 2;
                    referrals[pos] = referral[0];
                    referrals[pos + 1] = referral[1];
                }
            } else {
                hasFreeReferrer = true;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(hasFreeReferrer, '11 no free referrer');
        return freeReferrer;
    }

    function getLevel(uint256 price) public pure returns (uint8) {
        if (price == 0.1 ether) {
            return 1;
        } else if (price == 0.15 ether) {
            return 2;
        } else if (price == 0.35 ether) {
            return 3;
        } else if (price == 2 ether) {
            return 4;
        } else if (price == 5 ether) {
            return 5;
        } else if (price == 9 ether) {
            return 6;
        } else if (price == 35 ether) {
            return 7;
        } else if (price == 100 ether) {
            return 8;
        } else {
            revert('12 wrong value');
        }
    }

    function viewReferral(address user) public view returns (address[] memory) {
        return users[user].referral;
    }

    function viewLevelExpired(address user, uint256 level) public view returns (uint256) {
        return users[user].expiring[level];
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}

 