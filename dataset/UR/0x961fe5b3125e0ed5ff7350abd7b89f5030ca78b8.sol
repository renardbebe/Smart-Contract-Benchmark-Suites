 

 

pragma solidity 0.5.2;

 
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


contract Medianizer {
    function read() public view returns (bytes32);
}


contract Weth {
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public balanceOf;

    function transferFrom(address src, address dst, uint wad) public returns (bool);
}


 
 
contract Subscrypto {
    using SafeMath for uint;
    Medianizer public daiPriceContract;
    Weth public wethContract;

     
    constructor(address daiMedianizerContract, address wethContractAddress) public {
        daiPriceContract = Medianizer(daiMedianizerContract);
        wethContract = Weth(wethContractAddress);
    }

    event NewSubscription(
        address indexed subscriber,
        address indexed receiver,
        uint daiCents,
        uint32 interval
    );

    event Unsubscribe(
        address indexed subscriber, 
        address indexed receiver
    );

    event ReceiverPaymentsCollected(
        address indexed receiver,
        uint weiAmount,
        uint startIndex,
        uint endIndex
    );

    event SubscriptionPaid(
        address indexed subscriber,
        address indexed receiver,
        uint weiAmount,
        uint daiCents,
        uint48 effectiveTimestamp
    );

    event UnfundedPayment(
        address indexed subscriber,
        address indexed receiver,
        uint weiAmount,
        uint daiCents
    );

    event StaleSubscription(
        address indexed subscriber,
        address indexed receiver
    );

    event SubscriptionDeactivated(
        address indexed subscriber,
        address indexed receiver
    );

    event SubscriptionReactivated(
        address indexed subscriber,
        address indexed receiver
    );

     
    uint constant MIN_GAS_PER_EXECUTE_DEBIT = 45000;
     
    uint constant MAX_SUBSCRIPTION_PER_SUBSCRIBER = 10000;
     
    uint constant MIN_SUBSCRIPTION_DAI_CENTS = 100;

    struct Subscription {
        bool    isActive;         
        uint48  nextPaymentTime;  
        uint32  interval;         
        address subscriber;       
        address receiver;         
        uint    daiCents;         
    }

     
    uint64 nextIndex = 1;

     
    mapping(uint64 => Subscription) public subscriptions;

     
    mapping(address => mapping(address => uint64)) public subscriberReceiver;

     
    mapping(address => uint64[]) public receiverSubs;

     
    mapping(address => uint64[]) public subscriberSubs;

     
    function subscribe(address receiver, uint daiCents, uint32 interval) external {
        uint weiAmount = daiCentsToEthWei(daiCents, ethPriceInDaiWad());
        uint64 existingIndex = subscriberReceiver[msg.sender][receiver];
        require(subscriptions[existingIndex].daiCents == 0, "Subscription exists");
        require(daiCents >= MIN_SUBSCRIPTION_DAI_CENTS, "Subsciption amount too low");
        require(interval >= 86400, "Interval must be at least 1 day");
        require(interval <= 31557600, "Interval must be at most 1 year");
        require(subscriberSubs[msg.sender].length < MAX_SUBSCRIPTION_PER_SUBSCRIBER,"Subscription count limit reached");

         
        require(wethContract.transferFrom(msg.sender, receiver, weiAmount), "wETH transferFrom() failed");

         
        subscriptions[nextIndex] = Subscription(
            true,
            uint48(now.add(interval)),
            interval,
            msg.sender,
            receiver,
            daiCents
        );
        subscriberReceiver[msg.sender][receiver] = nextIndex;
        receiverSubs[receiver].push(nextIndex);
        subscriberSubs[msg.sender].push(nextIndex);

        emit NewSubscription(msg.sender, receiver, daiCents, interval);
        emit SubscriptionPaid(msg.sender, receiver, weiAmount, daiCents, uint48(now));

        nextIndex++;
    }
    
     
    function deactivateSubscription(address receiver) external returns (bool) {
        uint64 index = subscriberReceiver[msg.sender][receiver];
        require(index != 0, "Subscription does not exist");

        Subscription storage sub = subscriptions[index];
        require(sub.isActive, "Subscription is already disabled");
        require(sub.daiCents > 0, "Subscription does not exist");

        sub.isActive = false;
        emit SubscriptionDeactivated(msg.sender, receiver);

        return true;
    }

     
    function reactivateSubscription(address receiver) external returns (bool) {
        uint64 index = subscriberReceiver[msg.sender][receiver];
        require(index != 0, "Subscription does not exist");

        Subscription storage sub = subscriptions[index];
        require(!sub.isActive, "Subscription is already active");

        sub.isActive = true;
        emit SubscriptionReactivated(msg.sender, receiver);

        if (calculateUnpaidIntervalsUntil(sub, now) > 0) {
             
            uint weiAmount = daiCentsToEthWei(sub.daiCents, ethPriceInDaiWad());
            require(wethContract.transferFrom(msg.sender, receiver, weiAmount), "Insufficient funds to reactivate subscription");
            emit SubscriptionPaid(msg.sender, receiver, weiAmount, sub.daiCents, uint48(now));
        }

        sub.nextPaymentTime = uint48(now.add(sub.interval));

        return true;
    }

     
    function unsubscribe(address receiver) external {
        uint64 index = subscriberReceiver[msg.sender][receiver];
        require(index != 0, "Subscription does not exist");
        delete subscriptions[index];
        delete subscriberReceiver[msg.sender][receiver];
        deleteElement(subscriberSubs[msg.sender], index);
        emit Unsubscribe(msg.sender, receiver);
    }

     
    function unsubscribeByReceiver(address subscriber) external {
        uint64 index = subscriberReceiver[subscriber][msg.sender];
        require(index != 0, "Subscription does not exist");
        delete subscriptions[index];
        delete subscriberReceiver[subscriber][msg.sender];
        deleteElement(subscriberSubs[subscriber], index);
        emit Unsubscribe(subscriber, msg.sender);
    }

     
    function executeDebits(address receiver) external {
        executeDebitsRange(receiver, 0, receiverSubs[receiver].length);
    }

     
    function getTotalUnclaimedPayments(address receiver) external view returns (uint) {
        uint totalPayment = 0;
        uint ethPriceWad = ethPriceInDaiWad();

        for (uint i = 0; i < receiverSubs[receiver].length; i++) {
            Subscription storage sub = subscriptions[receiverSubs[receiver][i]];

            if (sub.isActive && sub.daiCents != 0) {
                uint wholeUnpaidIntervals = calculateUnpaidIntervalsUntil(sub, now);
                if (wholeUnpaidIntervals > 0) {
                    uint weiAmount = daiCentsToEthWei(sub.daiCents, ethPriceWad);
                    uint authorizedBalance = allowedBalance(sub.subscriber);

                    do {
                        if (authorizedBalance >= weiAmount) {
                            totalPayment = totalPayment.add(weiAmount);
                            authorizedBalance = authorizedBalance.sub(weiAmount);
                        }
                        wholeUnpaidIntervals = wholeUnpaidIntervals.sub(1);
                    } while (wholeUnpaidIntervals > 0);
                }
            }
        }

        return totalPayment;
    }

     
    function outstandingBalanceUntil(address subscriber, uint time) external view returns (uint) {
        uint until = time <= now ? now : time;

        uint64[] memory subs = subscriberSubs[subscriber];

        uint totalDaiCents = 0;
        for (uint64 i = 0; i < subs.length; i++) {
            Subscription memory sub = subscriptions[subs[i]];
            if (sub.isActive) {
                totalDaiCents = totalDaiCents.add(sub.daiCents.mul(calculateUnpaidIntervalsUntil(sub, until)));
            }
        }

        return totalDaiCents;
    }

     
    function executeDebitsRange(address receiver, uint start, uint end) public returns (uint) {
        uint64[] storage subs = receiverSubs[receiver];
        require(subs.length > 0, "receiver has no subscriptions");
        require(start < end && end <= subs.length, "wrong arguments for range");
        uint totalPayment = 0;
        uint ethPriceWad = ethPriceInDaiWad();

        uint last = end;
        uint i = start;
        while (i < last) {
            if (gasleft() < MIN_GAS_PER_EXECUTE_DEBIT) {
                break;
            }
            Subscription storage sub = subscriptions[subs[i]];

             
            while (sub.daiCents == 0 && subs.length > 0) {
                uint lastIndex = subs.length.sub(1);
                subs[i] = subs[lastIndex];
                delete(subs[lastIndex]);
                subs.length = lastIndex;
                if (last > lastIndex) {
                    last = lastIndex;
                }
                if (lastIndex > 0) {
                    sub = subscriptions[subs[i]];
                }
            }

            if (sub.isActive && sub.daiCents != 0) {
                uint wholeUnpaidIntervals = calculateUnpaidIntervalsUntil(sub, now);
                if (wholeUnpaidIntervals > 0) {
                    uint weiAmount = daiCentsToEthWei(sub.daiCents, ethPriceWad);
                    uint authorizedBalance = allowedBalance(sub.subscriber);

                    do {
                        if (authorizedBalance >= weiAmount) {
                            assert(wethContract.transferFrom(sub.subscriber, receiver, weiAmount));
                            sub.nextPaymentTime = calculateNextPaymentTime(sub);
                            totalPayment = totalPayment.add(weiAmount);
                            emit SubscriptionPaid(sub.subscriber, receiver, weiAmount, sub.daiCents, sub.nextPaymentTime);
                        } else {
                            emit UnfundedPayment(sub.subscriber, receiver, weiAmount, sub.daiCents);

                            if (wholeUnpaidIntervals >= 2) {
                                sub.isActive = false;
                                emit SubscriptionDeactivated(sub.subscriber, receiver);
                                emit StaleSubscription(sub.subscriber, receiver);
                                break;
                            }
                        }
                        wholeUnpaidIntervals = wholeUnpaidIntervals.sub(1);
                    } while (wholeUnpaidIntervals > 0);
                }
            }

            i++;
        }

        emit ReceiverPaymentsCollected(receiver, totalPayment, start, i);
        return i;
    }

     
    function allowedBalance(address payer) public view returns (uint) {
        uint balance = wethContract.balanceOf(payer);
        uint allowance = wethContract.allowance(payer, address(this));

        return balance > allowance ? allowance : balance;
    }

     
    function ethPriceInDaiWad() public view returns (uint) {
        uint price = uint(daiPriceContract.read());
        require(price > 1, "Invalid price for DAI.");
        return price;
    }

     
    function deleteElement(uint64[] storage array, uint64 element) internal {
        uint lastIndex = array.length.sub(1);
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[lastIndex];
                delete(array[lastIndex]);
                array.length = lastIndex;
                break;
            }
        }
    }

     
    function calculateUnpaidIntervalsUntil(Subscription memory sub, uint time) internal view returns (uint) {
        require(time >= now, "don't use a time before now");

        if (time > sub.nextPaymentTime) {
            return ((time.sub(sub.nextPaymentTime)).div(sub.interval)).add(1);
        }

        return 0;
    }

     
    function calculateNextPaymentTime(Subscription memory sub) internal pure returns (uint48) {
        uint48 nextPaymentTime = sub.nextPaymentTime + sub.interval;
        assert(nextPaymentTime > sub.nextPaymentTime);
        return nextPaymentTime;
    }

     
    function daiCentsToEthWei(uint daiCents, uint ethPriceWad) internal pure returns (uint) {
        return centsToWad(daiCents).mul(10**18).div(ethPriceWad);
    }

     
    function centsToWad(uint cents) internal pure returns (uint) {
        return cents.mul(10**16);
    }
}