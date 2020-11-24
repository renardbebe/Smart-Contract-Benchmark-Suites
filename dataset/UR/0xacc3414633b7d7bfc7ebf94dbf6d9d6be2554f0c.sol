 

 

pragma solidity ^ 0.5.11;
pragma experimental ABIEncoderV2;

contract Dates {
    uint constant DAY_IN_SECONDS = 86400;

    function getNow() public view returns(uint) {
        return now;
    }

    function getDelta(uint _date) public view returns(uint) {
         
        return (now / DAY_IN_SECONDS) - (_date / DAY_IN_SECONDS);
    }
}



contract EventInterface {
    event Activation(address indexed user);
    event FirstActivation(address indexed user);
    event Refund(address indexed user, uint indexed amount);
    event LossOfReward(address indexed user, uint indexed amount);
    event LevelUp(address indexed user, uint indexed level);
    event AcceptLevel(address indexed user);
    event ToFund(uint indexed amount);
    event ToReferrer(address indexed user, uint indexed amount);
    event HardworkerSeq(address indexed user, uint indexed sequence, uint indexed title);
    event ComandosSeq(address indexed user, uint indexed sequence, uint indexed title);
    event EveryDaySeq(address indexed user);
    event CustomerSeq(address indexed user, uint indexed sequence);
    event DaredevilSeq(address indexed user, uint indexed sequence, uint indexed achievement);
    event NovatorSeq(address indexed user, uint indexed sequence, uint indexed achievement);
    event ScoreConverted(address indexed user, uint indexed eth);
    event ScoreEarned(address indexed user);
}

contract Owned {
    address public owner;
    address public oracul;
    uint public cashbox;
    uint public kickback;
    uint public rest;
    address public newOwner;
    uint public lastTxTime;
    uint idleTime = 7776000;  

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event OraculChanged(address indexed _oracul);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyOracul {
        require(msg.sender == oracul);
        _;
    }
    function refundFromCashbox() public onlyOwner {
        msg.sender.transfer(cashbox);
        cashbox = 0;
    }
    function refundFromKickback() public onlyOwner {
        msg.sender.transfer(kickback);
        kickback = 0;
    }
    function refundFromRest() public onlyOwner {
        msg.sender.transfer(rest);
        rest = 0;
    }
    function setOracul(address _newOracul) public onlyOwner {
        oracul = _newOracul;
        emit OraculChanged(_newOracul);
    }
    function suicideContract() public onlyOwner {
        if (now - lastTxTime <  idleTime) {
            revert();
        } else {
            selfdestruct(msg.sender);
        }
    }
}


contract CashQuestBot is EventInterface, Owned, Dates {
    uint public Fund;
    uint public activationPrice = 4000000000000000;
    uint public activationTime = 28 days;
    uint public comission = 15;
    address[] public members;
    

    uint public AllScore;

    struct Hardworker {
        uint time;
        uint seq;
        uint title;
    }

    struct Comandos {
        uint time;
        uint seq;
        uint count;
        uint title;
    }

    struct RegularCustomer {
        uint seq;
        uint title;
    }

    struct Referrals {
        uint daredevil;
        uint novator;
        uint mastermind;
        uint sensei;
        uint guru;
    }

    struct Info {
         
        mapping(uint => uint) referralsCount;
        address referrer;
        uint level;
        uint line;
        bool isLevelUp;
        uint new_level;
        uint balance;
        uint score;
        uint earned;
        address[] referrals;
        uint activationEnds;
    }

    struct AllTime {
        uint score;
        uint scoreConverted;
    }

    struct User {
        Hardworker hardworker;
        Comandos comandos;
        RegularCustomer customer;
        Referrals referrals;
        Info info;
        AllTime alltime;
    }

    mapping(address => User) users;


    constructor() public {
        owner = msg.sender;
        oracul = msg.sender;

        users[msg.sender].info.level = 4;
        users[msg.sender].info.referralsCount[1] = 1;
        users[msg.sender].info.line = 1;
        users[msg.sender].info.activationEnds = now + 50000 days;

        users[msg.sender].hardworker.time = 0;
        users[msg.sender].hardworker.seq = 0;
        users[msg.sender].hardworker.title = 0;

        users[msg.sender].comandos.time = 0;
        users[msg.sender].comandos.seq = 0;
        users[msg.sender].comandos.count = 0;
        users[msg.sender].comandos.title = 0;

        users[msg.sender].customer.seq = 0;
        users[msg.sender].customer.title = 0;

        users[msg.sender].referrals.daredevil = 0;
        users[msg.sender].referrals.novator = 0;

        lastTxTime = now;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        users[newOwner] = users[owner];
        delete users[owner];
        owner = newOwner;
        newOwner = address(0);
    }




     
    function hardworkerPath(address _user) public {
        uint delta = getDelta(users[_user].hardworker.time);

        if (delta == 0) {
            return;
        }

        if (delta == 1) {
             
            users[_user].hardworker.time = now;
            users[_user].hardworker.seq++;

            if (users[_user].hardworker.seq % 7 == 0 && users[_user].hardworker.seq > 0 && users[_user].hardworker.seq < 42) {
                users[_user].info.score += 100;
                users[_user].alltime.score += 100;
                AllScore += 100;
                emit ScoreEarned(_user);
                emit HardworkerSeq(_user, users[_user].hardworker.seq, users[_user].hardworker.title);
                return;
            }

            if (users[_user].hardworker.seq == 42) {
                users[_user].hardworker.title++;
                users[_user].hardworker.seq = 0;
                users[_user].info.score += 100;
                users[_user].alltime.score += 100;
            
                emit ScoreEarned(_user);
                AllScore += 100;
                emit HardworkerSeq(_user, users[_user].hardworker.seq, users[_user].hardworker.title);
                return;
            }
            return;
        }

        if (delta >= 2) {
             
            users[_user].hardworker.time = now;
            users[_user].hardworker.seq = 1;
            return;
        }
    }

    function everyDay(address _user) public {
        if (users[_user].comandos.count % 2 == 0 && users[_user].comandos.count > 0) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100; 
            AllScore += 100;     
            emit ScoreEarned(_user);
            emit EveryDaySeq(_user);
            return;
        }
    }

    function comandosPath(address _user) public {
        uint delta = getDelta(users[_user].comandos.time);

         
         
        if (delta == 1) {
            if (users[_user].comandos.count < 2) {
                users[_user].comandos.seq = 0;
            }
            users[_user].comandos.time = now;
            users[_user].comandos.count = 1;
            return;
        }
         
        if (delta == 0) {
            users[_user].comandos.count++;
            users[_user].comandos.time = now;
            if (users[_user].comandos.count == 2) {
                users[_user].comandos.seq++;

                if (users[_user].comandos.seq % 7 == 0 && users[_user].comandos.seq > 0 && users[_user].comandos.seq < 42) {
                    users[_user].info.score += 100;
                    users[_user].alltime.score += 100;
                    AllScore += 100;
                    emit ScoreEarned(_user);
                    emit ComandosSeq(_user, users[_user].comandos.seq, users[_user].comandos.title);
                    return;
                }
                if (users[_user].comandos.seq == 42) {
                    users[_user].comandos.title++;
                    users[_user].info.score += 100;
                    users[_user].alltime.score += 100;
                    AllScore += 100;
                    emit ScoreEarned(_user);
                    users[_user].comandos.seq = 0;
                    emit ComandosSeq(_user, users[_user].comandos.seq, users[_user].comandos.title);
                    return;
                }
            }
        }

        if (delta >= 2) {
             
            users[_user].comandos.time = now;
            users[_user].comandos.count = 1;
            users[_user].comandos.seq = 0;
            return;
        }
    }

    function regularCustomer(address _user) public {
        users[_user].info.score += 100;
        users[_user].alltime.score += 100;
        AllScore += 100;
        emit ScoreEarned(_user);

        if (isActive(_user) == true) {
            users[_user].customer.seq++;
            if (users[_user].customer.seq == 12) {
                users[_user].customer.title = 1; 

                users[_user].info.score += 100;
                users[_user].alltime.score += 100;

                AllScore += 100;
                emit ScoreEarned(_user);   
            }
            
        } else {
            users[_user].customer.seq = 1;
        }
        emit CustomerSeq(_user, users[_user].customer.seq);
    }

    function forDaredevil(address _user) public {
        users[_user].referrals.daredevil++;
        if (users[_user].referrals.daredevil == 100) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit DaredevilSeq(_user, users[_user].referrals.daredevil, 1);
            return;
        }
        if (users[_user].referrals.daredevil == 250) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit DaredevilSeq(_user, users[_user].referrals.daredevil, 2);
            return;
        }
        if (users[_user].referrals.daredevil == 500) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit DaredevilSeq(_user, users[_user].referrals.daredevil, 3);
            return;
        }
        if (users[_user].referrals.daredevil == 1000) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;     
            emit ScoreEarned(_user);
            emit DaredevilSeq(_user, users[_user].referrals.daredevil, 4);
            return;
        }
        if (users[_user].referrals.daredevil == 1500) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit DaredevilSeq(_user, users[_user].referrals.daredevil, 5);
            return;
        }
    }

    function forNovator(address _user) public {
        users[_user].referrals.novator++;
        if (users[_user].referrals.novator == 25) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit NovatorSeq(_user, users[_user].referrals.novator, 1);
            return;
        }
        if (users[_user].referrals.novator == 50) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit NovatorSeq(_user, users[_user].referrals.novator, 2);
            return;
        }
        if (users[_user].referrals.novator == 100) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit NovatorSeq(_user, users[_user].referrals.novator, 3);
            return;
        }
        if (users[_user].referrals.novator == 200) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit NovatorSeq(_user, users[_user].referrals.novator, 4);
            return;
        }
        if (users[_user].referrals.novator == 300) {
            users[_user].info.score += 100;
            users[_user].alltime.score += 100;
            AllScore += 100;
            emit ScoreEarned(_user);
            emit NovatorSeq(_user, users[_user].referrals.novator, 5);
            return;
        }
    }

     
    function checkReferrerAcv(address _user) public {
        if (isActive(_user) == false) {
            return;
        }
        
        hardworkerPath(_user);
        comandosPath(_user);
        everyDay(_user);
        forDaredevil(_user);
    }

     
    function canSuicide() public view returns(bool) {
        if (now - lastTxTime <  idleTime) {
            return false;
        } else {
            return true;
        }
    }

    function getMembers() public view returns(address[] memory) {
        return members;
    }

    function getMembersCount() public view returns(uint) {
        return members.length;
    }

    function getHardworker(address _user) public view returns(Hardworker memory) {
        return users[_user].hardworker;
    }

    function getComandos(address _user) public view returns(Comandos memory) {
        return users[_user].comandos;
    }

    function getCustomer(address _user) public view returns(RegularCustomer memory) {
        return users[_user].customer;
    }

    function getReferrals(address _user) public view returns(uint, uint, uint, uint, uint) {
        return (users[_user].referrals.daredevil, users[_user].referrals.novator, users[_user].referrals.mastermind, users[_user].referrals.sensei, users[_user].referrals.guru);
    }

    function getScore(address _user) public view returns(uint) {
        return users[_user].info.score;
    }

    function getAlltime(address _user) public view returns(uint, uint) {
        return (users[_user].alltime.score, users[_user].alltime.scoreConverted);
    }

    function getPayAmount(address _user) public view returns(uint) {
        if (users[_user].info.earned / 100 * 10 > activationPrice) {
            return users[_user].info.earned / 100 * 10;
        } else {
            return activationPrice;
        }
    }
    
    function getUser(address user) public view returns (address, uint, uint, uint, address[] memory, uint) {
        return (users[user].info.referrer, users[user].info.level, users[user].info.line, users[user].info.balance, users[user].info.referrals, users[user].info.activationEnds);
    }

    function getEarned(address user) public view returns (uint) {
        return users[user].info.earned;
    }

    function getActivationEnds(address user) public view returns (uint) {
        return users[user].info.activationEnds;
    }

    function getReferralsCount(address user, uint level) public view returns (uint) {
        return users[user].info.referralsCount[level];
    }

    function isLevelUp(address user) public view returns (bool) {
        return users[user].info.new_level > users[user].info.level;
    }

    function getNewLevel(address user) public view returns (uint) {
        return users[user].info.new_level;
    }



     
    function setActivationPrice(uint _newActivationPrice) public onlyOracul {
        activationPrice = _newActivationPrice;
    }


     
    function refund() public {
        require(users[msg.sender].info.balance > 0);
        uint _comission = users[msg.sender].info.balance / 1000 * comission;
        uint _balance = users[msg.sender].info.balance - _comission;
        users[msg.sender].info.balance = 0;
        msg.sender.transfer(_balance);
        kickback += _comission;
        emit Refund(msg.sender, _balance);
        lastTxTime = now;
    }

    function howMuchConverted(address _user) public view returns(uint) {
        if (AllScore == 0 || Fund == 0 || users[_user].info.score == 0) {
            return 0;
        } else {
            return (Fund / AllScore) * users[_user].info.score + ((Fund % AllScore) * users[_user].info.score);
        }
    }

    function exchangeRate() public view returns(uint) {
        if (Fund == 0 || AllScore == 0) {
            return 0;
        }
        return Fund / AllScore;
    }

    function convertScore() public returns(uint) {
        require(users[msg.sender].info.score > 0);
        users[msg.sender].alltime.scoreConverted = users[msg.sender].info.score;
        uint convertedEther = (Fund / AllScore) * users[msg.sender].info.score;
        users[msg.sender].info.balance += convertedEther;
        users[msg.sender].info.earned += convertedEther;
        AllScore -= users[msg.sender].info.score;
        Fund -= convertedEther;
        users[msg.sender].info.score = 0;
        emit ScoreConverted(msg.sender, convertedEther);
        lastTxTime = now;
    }

    function calculateReferrerLevel(address referrer, uint referralLevel) internal {

        users[referrer].info.referralsCount[referralLevel]++;

        if (users[referrer].info.referralsCount[5] == 6 && users[referrer].info.level < 6) {
            users[referrer].info.isLevelUp = true;
            users[referrer].info.new_level = 6;
            emit LevelUp(referrer, 6);

            return;
        }

        if (users[referrer].info.referralsCount[4] == 12 && users[referrer].info.level < 5) {
            users[referrer].info.isLevelUp = true;
            users[referrer].info.new_level = 5;
            emit LevelUp(referrer, 5);
            return;
        }

        if (users[referrer].info.referralsCount[3] == 9 && users[referrer].info.level < 4) {
            users[referrer].info.isLevelUp = true;
            users[referrer].info.new_level = 4;
            emit LevelUp(referrer, 4);
            return;
        }

        if (users[referrer].info.referralsCount[2] == 6 && users[referrer].info.level < 3) {
            users[referrer].info.isLevelUp = true;
            users[referrer].info.new_level = 3;
            emit LevelUp(referrer, 3);
            return;
        }

        if (users[referrer].info.referralsCount[1] == 3 && users[referrer].info.level < 2) {
            users[referrer].info.isLevelUp = true;
            users[referrer].info.new_level = 2;
            emit LevelUp(referrer, 2);
            return;
        }
        
    }

    function acceptLevel() public {
        require(isActive(msg.sender) == true);
        require(users[msg.sender].info.isLevelUp == true);
        
        users[msg.sender].info.isLevelUp = false;
        users[msg.sender].info.level = users[msg.sender].info.new_level; 

         
        if (users[msg.sender].info.level == 2) {
            forNovator(users[msg.sender].info.referrer);
        }

        calculateReferrerLevel(users[msg.sender].info.referrer, users[msg.sender].info.level);
        users[msg.sender].info.score += 100;
        AllScore += 100;
        emit ScoreEarned(msg.sender);
        emit AcceptLevel(msg.sender);
        lastTxTime = now;
    }

    

    function extendActivation(address _user) internal {
        if (users[_user].info.activationEnds < now) {
            users[_user].info.activationEnds = now + activationTime;
            if (users[_user].info.level == 0) {
                users[_user].info.level = 1;
            }
        } else {
            users[_user].info.activationEnds = users[_user].info.activationEnds + activationTime;
            if (users[_user].info.level == 0) {
                users[_user].info.level = 1;
            }
        }
        return;
    }

    function isActive(address _user) public view returns(bool) {
        if (users[_user].info.activationEnds > now) {
            return true;
        } else {
            return false;
        }
    }

    function canPay(address user) public view returns(bool) {
        if (users[user].info.activationEnds - 3 days < now) {
            return true;
        } else {
            return false;
        }
    }

    function toFund(uint amount) internal {
        emit ToFund(amount / 2);
        Fund += amount / 2;
        cashbox += amount / 2;

        if (amount % 2 > 0) {
            rest += amount % 2;
        }
    }

     
    function toReferrer(address user, uint amount, uint control_level) internal {
         
        if (isActive(user) == true && users[user].info.level >= control_level) {
            emit ToReferrer(user, amount);
            users[user].info.balance += amount;
            users[user].info.earned += amount;
        } else {
            toFund(amount);
            emit LossOfReward(user, amount);
        }
    }

     
    function firstPay(address _referrer) public payable {
        require(users[msg.sender].info.line == 0);
        require(users[_referrer].info.line > 0);
        members.push(msg.sender);

        users[msg.sender].info.referrer = _referrer;
        users[msg.sender].info.line = users[_referrer].info.line + 1;
        users[msg.sender].info.activationEnds = 3 days;
        users[msg.sender].info.new_level = 0;

        users[_referrer].info.referrals.push(msg.sender);

        users[msg.sender].hardworker.time = 0;
        users[msg.sender].hardworker.seq = 0;
        users[msg.sender].hardworker.title = 0;

        users[msg.sender].comandos.time = 0;
        users[msg.sender].comandos.seq = 0;
        users[msg.sender].comandos.count = 0;
        users[msg.sender].comandos.title = 0;

        users[msg.sender].customer.seq = 0;
        users[msg.sender].customer.title = 0;

        users[msg.sender].referrals.daredevil = 0;
        users[msg.sender].referrals.novator = 0;
  
         
        if (users[msg.sender].info.earned / 100 * 10 > activationPrice) {
            if (msg.value != users[msg.sender].info.earned / 100 * 10) {
                revert();
            }
        } else {
            if (msg.value != activationPrice) {
                revert();
            }
        }

         
        if (canPay(msg.sender) == false) {
            revert();
        }

         
        users[msg.sender].info.earned = 0;
         
        extendActivation(msg.sender);
        
        
        if (users[msg.sender].info.line == 2) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toFund(msg.value / 100 * 30 + msg.value / 100 * 20 + msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line == 3) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toFund(msg.value / 100 * 20 + msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line == 4) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toReferrer(users[users[users[msg.sender].info.referrer].info.referrer].info.referrer, msg.value / 100 * 20, 3);
            toFund(msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line >= 5) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toReferrer(users[users[users[msg.sender].info.referrer].info.referrer].info.referrer, msg.value / 100 * 20, 3);
            toReferrer(users[users[users[users[msg.sender].info.referrer].info.referrer].info.referrer].info.referrer, msg.value / 100 * 10, 4);
        }
        
        calculateReferrerLevel(users[msg.sender].info.referrer, 1);
        checkReferrerAcv(users[msg.sender].info.referrer);
        emit FirstActivation(msg.sender);
        emit AcceptLevel(msg.sender);
        lastTxTime = now;
    }


    function pay() public payable {
         
        if (users[msg.sender].info.line < 2) {
            revert();
        }


         
        if (users[msg.sender].info.earned / 100 * 10 > activationPrice) {
            if (msg.value != users[msg.sender].info.earned / 100 * 10) {
                revert();
            }
        } else {
            if (msg.value != activationPrice) {
                revert();
            }
        }

         
        if (canPay(msg.sender) == false) {
            revert();
        }

         
        users[msg.sender].info.earned = 0;
         
        regularCustomer(msg.sender);
        extendActivation(msg.sender);
        
        emit Activation(msg.sender);
        
        if (users[msg.sender].info.line == 2) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toFund(msg.value / 100 * 30 + msg.value / 100 * 20 + msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line == 3) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toFund(msg.value / 100 * 20 + msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line == 4) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toReferrer(users[users[users[msg.sender].info.referrer].info.referrer].info.referrer, msg.value / 100 * 20, 3);
            toFund(msg.value / 100 * 10);
        }

        if (users[msg.sender].info.line >= 5) {
            toReferrer(users[msg.sender].info.referrer, msg.value / 100 * 40, 1);
            toReferrer(users[users[msg.sender].info.referrer].info.referrer, msg.value / 100 * 30, 2);
            toReferrer(users[users[users[msg.sender].info.referrer].info.referrer].info.referrer, msg.value / 100 * 20, 3);
            toReferrer(users[users[users[users[msg.sender].info.referrer].info.referrer].info.referrer].info.referrer, msg.value / 100 * 10, 4);
        }
        lastTxTime = now;
    }
     
    function() external payable {
        if (msg.value == 1000000000) {
            refund();
            return;
        }
        if (msg.value == 2000000000) {
            convertScore();
            return;
        }
        if (msg.value == 3000000000) {
            refundFromCashbox();
            return;
        }
        if (msg.value == 4000000000) {
            refundFromKickback();
            return;
        }
        if (msg.value == 5000000000) {
            suicideContract();
            return;
        }
        pay();
    }
}