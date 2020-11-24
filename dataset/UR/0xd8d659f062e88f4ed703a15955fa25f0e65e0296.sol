 

 

pragma solidity ^0.5.10;

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Util {
    struct User {
        bool isExist;
        uint256 id;
        uint256 origRefID;
        uint256 referrerID;
        uint256 balance;
        uint256 lastActivity;
        address payable wallet;
        address[] referral;
        uint256[] expiring;

    }

}

contract Constantinople {
    using SafeMath for uint256;
     
     
     
    event registered(address indexed user, address indexed referrer, uint indexed userId, uint refId);
    event levelBought(address indexed user, uint256 level);
    event receivedEther(address indexed user, address indexed referral, uint256 level);
    event lostEther(address indexed user, address indexed referral, uint256 level);

     
     
     
    address payable public wallet;
    address payable public reserveWallet;

    uint256 constant MAX_REFERRERS = 2;
    uint256 LEVEL_PERIOD = 36500 days;

     
     
     

    mapping(address => Util.User) public users;
    mapping(uint256 => address) public userList;
    uint256 public userIDCounter = 0;


     
     
     
    constructor() public {
        wallet = 0xD4A8CE85b78fB3B169D62aC0b7fDbD5334f32b7D;
        reserveWallet = 0x684052eF21f887605ADE3440e77Fb91e19B993D0;

        Util.User memory user;
        userIDCounter++;

        user = Util.User({
            isExist : true,
            id : userIDCounter,
            origRefID: 0,
            referrerID : 0,
            balance: 0,
            lastActivity: now,
            wallet : 0xE90F0E035846b7bd5DbeAAC60108fde31f3393D1,
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
        require(users[msg.sender].isExist, '00 user not exist');
        if (msg.value > 0) {
            users[msg.sender].balance = users[msg.sender].balance.add(msg.value);
            emit receivedEther(msg.sender, msg.sender, 0);
        }
    }


    function register(address payable _wallet, uint256 referrerID) public payable {
        require(_wallet != address(0), '01 zero wallet');
        require(!users[msg.sender].isExist, '02 user exist');
        require(referrerID > 0 && referrerID <= userIDCounter, '03 wrong referrer ID');
        require(getLevel(msg.value) == 1, '04 wrong value');


        uint origRefID = referrerID;
        if (users[userList[referrerID]].referral.length >= MAX_REFERRERS)
        {
            referrerID = users[findReferrer(userList[referrerID])].id;
        }

        Util.User memory user;
        userIDCounter++;

        user = Util.User({
            isExist : true,
            id : userIDCounter,
            origRefID : origRefID,
            referrerID : referrerID,
            balance : msg.value,
            lastActivity : now,
            wallet : _wallet,
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

        payForLevel(msg.sender, 1, msg.value, true);

        emit registered(msg.sender, userList[referrerID], userIDCounter, referrerID);
    }

    function buy(uint256 level) public {
        require(users[msg.sender].isExist, '06 user not exist');
        require(level > 0 && level <= 8, '07 wrong level');
        require(users[msg.sender].balance >= getPrice(level), '08 wrong value');

        for (uint256 l = level - 1; l > 0; l--) {
            require(users[msg.sender].expiring[l] >= now, '09 buy level');
        }

        if (users[msg.sender].expiring[level] == 0) {
            users[msg.sender].expiring[level] = now + LEVEL_PERIOD;
        } else {
            users[msg.sender].expiring[level] += LEVEL_PERIOD;
        }

        users[msg.sender].lastActivity = now;

        payForLevel(msg.sender, level, getPrice(level), true);
        emit levelBought(msg.sender, level);
    }

    function payForLevel(address user, uint256 level, uint256 price, bool _checkCanBuy) internal {
        address referrer;
        uint256 above = level > 4 ? level - 4 : level;

        if (1 < level && level < 4 && _checkCanBuy) {
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
            require(users[msg.sender].balance >= price, '10 not enough balance');
            users[msg.sender].balance = users[msg.sender].balance.sub(price);
            uint ownerPercent = price.mul(1).div(100);
            users[wallet].balance = users[wallet].balance.add(ownerPercent);
            users[referrer].balance = users[referrer].balance.add(price.sub(ownerPercent));
            emit receivedEther(referrer, msg.sender, level);
        } else {
            emit lostEther(referrer, msg.sender, level);
            payForLevel(referrer, level, price, false);
        }
    }

    function checkCanBuy(address user, uint256 level) private view {
        if (level == 1) return;
        address[] memory referral = users[user].referral;
        require(referral.length == MAX_REFERRERS, '11 not enough referrals');

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
        require(hasFreeReferrer, '12 no free referrer');
        return freeReferrer;
    }


    function withdraw(uint _val) public {
        require(users[msg.sender].isExist, '13 user not exist');
        require(users[msg.sender].balance >= _val, '14 not enough balance');
        users[msg.sender].balance = users[msg.sender].balance.sub(_val);
        users[msg.sender].wallet.transfer(_val);
        users[msg.sender].lastActivity = now;
    }


    function claim(address _user) public {
        require(msg.sender == reserveWallet);
        require(users[_user].lastActivity + 730 days < now);
        reserveWallet.transfer(users[_user].balance);
        users[_user].balance = 0;
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
            revert('15 wrong value');
        }
    }

    function getPrice(uint256 level) public pure returns (uint) {
        if (level == 1) {
            return 0.1 ether;
        } else if (level == 2) {
            return 0.15 ether;
        } else if (level == 3) {
            return 0.35 ether;
        } else if (level == 4) {
            return 2 ether;
        } else if (level == 5) {
            return 5 ether;
        } else if (level == 6) {
            return 9 ether;
        } else if (level == 7) {
            return 35 ether;
        } else if (level == 8) {
            return 100 ether;
        } else {
            revert('16 wrong value');
        }
    }

    function viewReferral(address user) public view returns (address[] memory) {
        return users[user].referral;
    }

    function viewLevelExpired(address user, uint256 level) public view returns (uint256) {
        return users[user].expiring[level];
    }

    function getBalance(address _user) public view returns (uint) {
        return users[_user].balance;
    }

}