 

pragma solidity ^0.4.21;

 

interface Token {
    function totalSupply() constant external returns (uint256 ts);
    function balanceOf(address _owner) constant external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
}

contract SafeMath {
    function safeAdd(uint x, uint y)
        internal
        pure
    returns(uint) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSub(uint x, uint y)
        internal
        pure
    returns(uint) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMul(uint x, uint y)
        internal
        pure
    returns(uint) {
      uint z = x * y;
      require((x == 0) || (z / x == y));
      return z;
    }
    
    function safeDiv(uint x, uint y)
        internal
        pure
    returns(uint) {
        require(y > 0);
        return x / y;
    }

    function random(uint N, uint salt)
        internal
        view
    returns(uint) {
      bytes32 hash = keccak256(block.number, msg.sender, salt);
      return uint(hash) % N;
    }
}

contract Authorization {
    mapping(address => address) public agentBooks;
    address public owner;
    address public operator;
    address public bank;
    bool public powerStatus = true;

    function Authorization()
        public
    {
        owner = msg.sender;
        operator = msg.sender;
        bank = msg.sender;
    }

    modifier onlyOwner
    {
        assert(msg.sender == owner);
        _;
    }
    modifier onlyOperator
    {
        assert(msg.sender == operator || msg.sender == owner);
        _;
    }
    modifier onlyActive
    {
        assert(powerStatus);
        _;
    }

    function powerSwitch(
        bool onOff_
    )
        public
        onlyOperator
    {
        powerStatus = onOff_;
    }

    function transferOwnership(address newOwner_)
        onlyOwner
        public
    {
        owner = newOwner_;
    }
    
    function assignOperator(address user_)
        public
        onlyOwner
    {
        operator = user_;
        agentBooks[bank] = user_;
    }
    
    function assignBank(address bank_)
        public
        onlyOwner
    {
        bank = bank_;
    }

    function assignAgent(
        address agent_
    )
        public
    {
        agentBooks[msg.sender] = agent_;
    }

    function isRepresentor(
        address representor_
    )
        public
        view
    returns(bool) {
        return agentBooks[representor_] == msg.sender;
    }

    function getUser(
        address representor_
    )
        internal
        view
    returns(address) {
        return isRepresentor(representor_) ? representor_ : msg.sender;
    }
}

 

 

contract Baliv is SafeMath, Authorization {
     
    struct linkedBook {
        uint256 amount;
        address nextUser;
    }

     
    mapping(address => uint256) public minAmount;
    uint256[3] public feerate = [0, 1 * (10 ** 15), 1 * (10 ** 15)];
    uint256 public autoMatch = 10;
    uint256 public maxAmount = 10 ** 27;
    uint256 public maxPrice = 10 ** 36;
    address public XPAToken = 0x0090528aeb3a2b736b780fd1b6c478bb7e1d643170;

     
    mapping(address => mapping(address => mapping(uint256 => mapping(address => linkedBook)))) public orderBooks;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public nextOrderPrice;
    mapping(address => mapping(address => uint256)) public priceBooks;
    
     
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => bool) internal manualWithdraw;

     
    event eDeposit(address user,address token, uint256 amount);
    event eWithdraw(address user,address token, uint256 amount);
    event eMakeOrder(address fromToken, address toToken, uint256 price, address user, uint256 amount);
    event eFillOrder(address fromToken, address toToken, uint256 price, address user, uint256 amount);
    event eCancelOrder(address fromToken, address toToken, uint256 price, address user, uint256 amount);

    event Error(uint256 code);

     
    function Baliv() public {
        minAmount[0] = 10 ** 16;
    }

     

     

     

     
    function setup(
        uint256 autoMatch_,
        uint256 maxAmount_,
        uint256 maxPrice_
    )
        onlyOperator
        public
    {
        autoMatch = autoMatch_;
        maxAmount = maxAmount_;
        maxPrice = maxPrice_;
    }
    
    function setMinAmount(
        address token_,
        uint256 amount_
    )
        onlyOperator
        public
    {
        minAmount[token_] = amount_;
    }
    
    function getMinAmount(
        address token_
    )
        public
        view
    returns(uint256) {
        return minAmount[token_] > 0
            ? minAmount[token_]
            : minAmount[0];
    }
    
    function setFeerate(
        uint256[3] feerate_
    )
        onlyOperator
        public
    {
        require(feerate_[0] < 0.05 ether && feerate_[1] < 0.05 ether && feerate_[2] < 0.05 ether);
        feerate = feerate_;
    }

     
     
    function ()
        public
        payable
    {
        deposit(0, 0);
    }

     
    function deposit(
        address token_,
        address representor_
    )
        public
        payable
        onlyActive
    {
        address user = getUser(representor_);
        uint256 amount = depositAndFreeze(token_, user);
        if(amount > 0) {
            updateBalance(msg.sender, token_, amount, true);
        }
    }

    function withdraw(
        address token_,
        uint256 amount_,
        address representor_
    )
        public
    returns(bool) {
        address user = getUser(representor_);
        if(updateBalance(user, token_, amount_, false)) {
            require(transferToken(user, token_, amount_));
            return true;
        }
    }

    function agentMakeOrder(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 amount_,
        address representor_
    )
        public
        payable
    returns(bool) {
         
        uint256 depositAmount = depositAndFreeze(fromToken_, representor_);
        if(
            checkAmount(fromToken_, amount_) &&
            checkPriceAmount(price_)
        ) {
            require(representor_ != address(0));
            address user = representor_;
            uint256 costAmount = makeOrder(fromToken_, toToken_, price_, amount_, user, depositAmount);

             
            emit eMakeOrder(fromToken_, toToken_, price_, user, amount_);

            require(costAmount <= depositAmount);
            updateBalance(msg.sender, fromToken_, safeSub(depositAmount, costAmount), true);
            return true;
        }
    }

    function userTakeOrder(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 amount_,
        address representor_
    )
        public
        payable
        onlyActive
    returns(bool) {
         
        address user = getUser(representor_);
        uint256 depositAmount = depositAndFreeze(fromToken_, user);
        if(
            checkAmount(fromToken_, amount_) &&
            checkPriceAmount(price_) &&
            checkBalance(user, fromToken_, amount_, depositAmount)
        ) {
             
            emit eMakeOrder(fromToken_, toToken_, price_, user, amount_);

            uint256[2] memory fillAmount;
            uint256[2] memory profit;
            (fillAmount, profit) = findAndTrade(fromToken_, toToken_, price_, amount_);
            uint256 fee;
            uint256 toAmount;
            uint256 orderAmount;

            if(fillAmount[0] > 0) {
                 
                emit eFillOrder(fromToken_, toToken_, price_, user, fillAmount[0]);

                toAmount = safeDiv(safeMul(fillAmount[0], price_), 1 ether);
                if(amount_ > fillAmount[0]) {
                    orderAmount = safeSub(amount_, fillAmount[0]);
                    makeOrder(fromToken_, toToken_, price_, orderAmount, user, depositAmount);
                }
                if(toAmount > 0) {
                    (toAmount, fee) = caculateFee(user, toAmount, 1);
                    profit[1] = profit[1] + fee;

                     
                    updateBalance(bank, fromToken_, profit[0], true);
                    updateBalance(bank, toToken_, profit[1], true);

                     
                    if(manualWithdraw[user]) {
                        updateBalance(user, toToken_, toAmount, true);
                    } else {
                        transferToken(user, toToken_, toAmount);
                    }
                }
            } else {
                orderAmount = amount_;
                makeOrder(fromToken_, toToken_, price_, orderAmount, user, depositAmount);
            }

             
            if(amount_ > depositAmount) {
                updateBalance(user, fromToken_, safeSub(amount_, depositAmount), false);
            } else if(amount_ < depositAmount) {
                updateBalance(user, fromToken_, safeSub(depositAmount, amount_), true);
            }

            return true;
        } else if(depositAmount > 0) {
            updateBalance(user, fromToken_, depositAmount, true);
        }
    }

    function userCancelOrder(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 amount_,
        address representor_
    )
        public
    returns(bool) {
         
        address user = getUser(representor_);
        uint256 amount = getOrderAmount(fromToken_, toToken_, price_, user);
        amount = amount > amount_ ? amount_ : amount;
        if(amount > 0) {
             
            emit eCancelOrder(fromToken_, toToken_, price_, user, amount);

            updateOrderAmount(fromToken_, toToken_, price_, user, amount, false);
            if(manualWithdraw[user]) {
                updateBalance(user, fromToken_, amount, true);
            } else {
                transferToken(user, fromToken_, amount);
            }
            return true;
        }
    }

     
    function caculateFee(
        address user_,
        uint256 amount_,
        uint8 role_
    )
        public
        view
    returns(uint256, uint256) {
        uint256 myXPABalance = Token(XPAToken).balanceOf(user_);
        uint256 myFeerate = manualWithdraw[user_]
            ? feerate[role_]
            : feerate[role_] + feerate[2];
        myFeerate =
            myXPABalance > 1000000 ether ? myFeerate * 0.5 ether / 1 ether :
            myXPABalance > 100000 ether ? myFeerate * 0.6 ether / 1 ether :
            myXPABalance > 10000 ether ? myFeerate * 0.8 ether / 1 ether :
            myFeerate;
        uint256 fee = safeDiv(safeMul(amount_, myFeerate), 1 ether);
        uint256 toAmount = safeSub(amount_, fee);
        return(toAmount, fee);
    }

    function trade(
        address fromToken_,
        address toToken_
    )
        public
        onlyActive
    {
         
        uint256 takerPrice = getNextOrderPrice(fromToken_, toToken_, 0);
        address taker = getNextOrderUser(fromToken_, toToken_, takerPrice, 0);
        uint256 takerAmount = getOrderAmount(fromToken_, toToken_, takerPrice, taker);
         
        uint256[2] memory fillAmount;
        uint256[2] memory profit;
        (fillAmount, profit) = findAndTrade(fromToken_, toToken_, takerPrice, takerAmount);
        if(fillAmount[0] > 0) {
            profit[1] = profit[1] + fillOrder(fromToken_, toToken_, takerPrice, taker, fillAmount[0]);

             
            updateBalance(msg.sender, fromToken_, profit[0], true);
            updateBalance(msg.sender, toToken_, profit[1], true);
        }
    }

    function setManualWithdraw(
        bool manual_
    )
        public
    {
        manualWithdraw[msg.sender] = manual_;
    }

    function getPrice(
        address fromToken_,
        address toToken_
    )
        public
        view
    returns(uint256) {
        if(uint256(fromToken_) >= uint256(toToken_)) {
            return priceBooks[fromToken_][toToken_];            
        } else {
            return priceBooks[toToken_][fromToken_] > 0 ? safeDiv(10 ** 36, priceBooks[toToken_][fromToken_]) : 0;
        }
    }

     
     
    function depositAndFreeze(
        address token_,
        address user
    )
        internal
    returns(uint256) {
        uint256 amount;
        if(token_ == address(0)) {
             
            emit eDeposit(user, address(0), msg.value);

            amount = msg.value;
            return amount;
        } else {
            if(msg.value > 0) {
                 
                emit eDeposit(user, address(0), msg.value);

                updateBalance(user, address(0), msg.value, true);
            }
            amount = Token(token_).allowance(msg.sender, this);
            if(
                amount > 0 &&
                Token(token_).transferFrom(msg.sender, this, amount)
            ) {
                 
                emit eDeposit(user, token_, amount);

                return amount;
            }
        }
    }

    function checkBalance(
        address user_,
        address token_,
        uint256 amount_,
        uint256 depositAmount_
    )
        internal
    returns(bool) {
        if(safeAdd(balances[user_][token_], depositAmount_) >= amount_) {
            return true;
        } else {
            emit Error(0);
            return false;
        }
    }

    function checkAmount(
        address token_,
        uint256 amount_
    )
        internal
    returns(bool) {
        uint256 min = getMinAmount(token_);
        if(amount_ > maxAmount || amount_ < min) {
            emit Error(2);
            return false;
        } else {
            return true;
        }
    }

    function checkPriceAmount(
        uint256 price_
    )
        internal
    returns(bool) {
        if(price_ == 0 || price_ > maxPrice) {
            emit Error(3);
            return false;
        } else {
            return true;
        }
    }

    function makeOrder(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 amount_,
        address user_,
        uint256 depositAmount_
    )
        internal
    returns(uint256) {
        if(checkBalance(user_, fromToken_, amount_, depositAmount_)) {
            updateOrderAmount(fromToken_, toToken_, price_, user_, amount_, true);
            connectOrderPrice(fromToken_, toToken_, price_, 0);
            connectOrderUser(fromToken_, toToken_, price_, user_);
            return amount_;
        } else {
            return 0;
        }
    }

    function findAndTrade(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 amount_
    )
        internal
    returns(uint256[2], uint256[2]) {
         
        uint256[2] memory totalMatchAmount;
        uint256[2] memory profit;
        uint256[3] memory matchAmount;
        uint256 toAmount;
        uint256 remaining = amount_;
        uint256 matches = 0;
        uint256 prevBestPrice = 0;
        uint256 bestPrice = getNextOrderPrice(toToken_, fromToken_, prevBestPrice);
        for(; matches < autoMatch && remaining > 0;) {
            matchAmount = makeTrade(fromToken_, toToken_, price_, bestPrice, remaining);
            if(matchAmount[0] > 0) {
                remaining = safeSub(remaining, matchAmount[0]);
                totalMatchAmount[0] = safeAdd(totalMatchAmount[0], matchAmount[0]);
                totalMatchAmount[1] = safeAdd(totalMatchAmount[1], matchAmount[1]);
                profit[0] = safeAdd(profit[0], matchAmount[2]);
                
                 
                matches++;
                prevBestPrice = bestPrice;
                bestPrice = getNextOrderPrice(toToken_, fromToken_, prevBestPrice);
            } else {
                break;
            }
        }

        if(totalMatchAmount[0] > 0) {
             
            logPrice(toToken_, fromToken_, prevBestPrice);

             
            toAmount = safeDiv(safeMul(totalMatchAmount[0], price_), 1 ether);
            profit[1] = safeSub(totalMatchAmount[1], toAmount);
            if(totalMatchAmount[1] >= safeDiv(safeMul(amount_, price_), 1 ether)) {
                 
                profit[0] = profit[0] + amount_ - totalMatchAmount[0];
                 
                totalMatchAmount[0] = amount_;
            } else {
                toAmount = totalMatchAmount[1];
                 
                profit[0] = profit[0] + totalMatchAmount[0] - (toAmount * 1 ether /price_);
                 
                totalMatchAmount[0] = safeDiv(safeMul(toAmount, 1 ether), price_);
            }
        }

        return (totalMatchAmount, profit);
    }

    function makeTrade(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 bestPrice_,
        uint256 remaining_
    )
        internal
    returns(uint256[3]) {
        if(checkPricePair(price_, bestPrice_)) {
            address prevMaker = address(0);
            address maker = getNextOrderUser(toToken_, fromToken_, bestPrice_, 0);
            uint256 remaining = remaining_;

             
            uint256[3] memory totalFill;
            for(uint256 i = 0; i < autoMatch && remaining > 0 && maker != address(0); i++) {
                uint256[3] memory fill;
                fill = makeTradeDetail(fromToken_, toToken_, price_, bestPrice_, maker, remaining);
                if(fill[0] > 0) {
                    remaining = safeSub(remaining, fill[0]);
                    totalFill[0] = safeAdd(totalFill[0], fill[0]);
                    totalFill[1] = safeAdd(totalFill[1], fill[1]);
                    totalFill[2] = safeAdd(totalFill[2], fill[2]);
                    prevMaker = maker;
                    maker = getNextOrderUser(toToken_, fromToken_, bestPrice_, prevMaker);
                    if(maker == address(0)) {
                        break;
                    }
                } else {
                    break;
                }
            }
        }
        return totalFill;
    }

    function makeTradeDetail(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 bestPrice_,
        address maker_,
        uint256 remaining_
    )
        internal
    returns(uint256[3]) {
         
        uint256[3] memory fillAmount;
        uint256 takerProvide = remaining_;
        uint256 takerRequire = safeDiv(safeMul(takerProvide, price_), 1 ether);
        uint256 makerProvide = getOrderAmount(toToken_, fromToken_, bestPrice_, maker_);
        uint256 makerRequire = safeDiv(safeMul(makerProvide, bestPrice_), 1 ether);
        fillAmount[0] = caculateFill(takerProvide, takerRequire, price_, makerProvide);
        fillAmount[1] = caculateFill(makerProvide, makerRequire, bestPrice_, takerProvide);
        fillAmount[2] = fillOrder(toToken_, fromToken_, bestPrice_, maker_, fillAmount[1]);
        return (fillAmount);
    }

    function caculateFill(
        uint256 provide_,
        uint256 require_,
        uint256 price_,
        uint256 pairProvide_
    )
        internal
        pure
    returns(uint256) {
        return require_ > pairProvide_ ? safeDiv(safeMul(pairProvide_, 1 ether), price_) : provide_;
    }

    function checkPricePair(
        uint256 price_,
        uint256 bestPrice_
    )
        internal pure 
    returns(bool) {
        if(bestPrice_ < price_) {
            return checkPricePair(bestPrice_, price_);
        } else if(bestPrice_ < 1 ether) {
            return true;
        } else if(price_ > 1 ether) {
            return false;
        } else {
            return price_ * bestPrice_ <= 1 ether * 1 ether;
        }
    }

    function fillOrder(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_,
        uint256 amount_
    )
        internal
    returns(uint256) {
         
        emit eFillOrder(fromToken_, toToken_, price_, user_, amount_);

        uint256 toAmount = safeDiv(safeMul(amount_, price_), 1 ether);
        uint256 fee;
        updateOrderAmount(fromToken_, toToken_, price_, user_, amount_, false);
        (toAmount, fee) = caculateFee(user_, toAmount, 0);

        if(manualWithdraw[user_]) {
            updateBalance(user_, toToken_, toAmount, true);
        } else {
            transferToken(user_, toToken_, toAmount);
        }
        return fee;
    }
    function transferToken(
        address user_,
        address token_,
        uint256 amount_
    )
        internal
    returns(bool) {
        if(amount_ > 0) {
            if(token_ == address(0)) {
                if(address(this).balance < amount_) {
                    emit Error(1);
                    return false;
                } else {
                     
                    emit eWithdraw(user_, token_, amount_);
    
                    user_.transfer(amount_);
                    return true;
                }
            } else if(Token(token_).transfer(user_, amount_)) {
                 
                emit eWithdraw(user_, token_, amount_);
    
                return true;
            } else {
                emit Error(1);
                return false;
            }
        } else {
            return true;
        }
    }

    function updateBalance(
        address user_,
        address token_,
        uint256 amount_,
        bool addOrSub_
    )
        internal
    returns(bool) {
        if(addOrSub_) {
            balances[user_][token_] = safeAdd(balances[user_][token_], amount_);
        } else {
            if(checkBalance(user_, token_, amount_, 0)){
                balances[user_][token_] = safeSub(balances[user_][token_], amount_);
                return true;
            } else {
                return false;
            }
        }
    }

    function connectOrderPrice(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 prev_
    )
        internal
    {
        if(checkPriceAmount(price_)) {
            uint256 prevPrice = getNextOrderPrice(fromToken_, toToken_, prev_);
            uint256 nextPrice = getNextOrderPrice(fromToken_, toToken_, prevPrice);
            if(prev_ != price_ && prevPrice != price_ && nextPrice != price_) {
                if(price_ < prevPrice) {
                    updateNextOrderPrice(fromToken_, toToken_, prev_, price_);
                    updateNextOrderPrice(fromToken_, toToken_, price_, prevPrice);
                } else if(nextPrice == 0) {
                    updateNextOrderPrice(fromToken_, toToken_, prevPrice, price_);
                } else {
                    connectOrderPrice(fromToken_, toToken_, price_, prevPrice);
                }
            }
        }
    }

    function connectOrderUser(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_
    )
        internal 
    {
        address firstUser = getNextOrderUser(fromToken_, toToken_, price_, 0);
        if(user_ != address(0) && user_ != firstUser) {
            updateNextOrderUser(fromToken_, toToken_, price_, 0, user_);
            if(firstUser != address(0)) {
                updateNextOrderUser(fromToken_, toToken_, price_, user_, firstUser);
            }
        }
    }

    function disconnectOrderPrice(
        address fromToken_,
        address toToken_,
        uint256 price_
    )
        internal
    {
        uint256 currPrice = getNextOrderPrice(fromToken_, toToken_, 0);
        uint256 nextPrice = getNextOrderPrice(fromToken_, toToken_, currPrice);
        if(price_ == currPrice) {
            updateNextOrderPrice(fromToken_, toToken_, 0, nextPrice);
        }
    }

    function disconnectOrderUser(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_
    )
        public
    {
        if(user_ == address(0) || getOrderAmount(fromToken_, toToken_, price_, user_) > 0) {
            return;
        }
        address currUser = getNextOrderUser(fromToken_, toToken_, price_, address(0));
        address nextUser = getNextOrderUser(fromToken_, toToken_, price_, currUser);
        if(currUser == user_) {
            updateNextOrderUser(fromToken_, toToken_, price_, address(0), nextUser);
            if(nextUser == address(0)) {
                disconnectOrderPrice(fromToken_, toToken_, price_);
            }
        }
    }

    function getNextOrderPrice(
        address fromToken_,
        address toToken_,
        uint256 price_
    )
        internal
        view
    returns(uint256) {
        return nextOrderPrice[fromToken_][toToken_][price_];
    }

    function updateNextOrderPrice(
        address fromToken_,
        address toToken_,
        uint256 price_,
        uint256 nextPrice_
    )
        internal
    {
        nextOrderPrice[fromToken_][toToken_][price_] = nextPrice_;
    }

    function getNextOrderUser(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_
    )
        internal
        view
    returns(address) {
        return orderBooks[fromToken_][toToken_][price_][user_].nextUser;
    }

    function getOrderAmount(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_
    )
        internal
        view
    returns(uint256) {
        return orderBooks[fromToken_][toToken_][price_][user_].amount;
    }

    function updateNextOrderUser(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_,
        address nextUser_
    )
        internal
    {
        orderBooks[fromToken_][toToken_][price_][user_].nextUser = nextUser_;
    }

    function updateOrderAmount(
        address fromToken_,
        address toToken_,
        uint256 price_,
        address user_,
        uint256 amount_,
        bool addOrSub_
    )
        internal
    {
        if(addOrSub_) {
            orderBooks[fromToken_][toToken_][price_][user_].amount = safeAdd(orderBooks[fromToken_][toToken_][price_][user_].amount, amount_);
        } else {
            orderBooks[fromToken_][toToken_][price_][user_].amount = safeSub(orderBooks[fromToken_][toToken_][price_][user_].amount, amount_);
            disconnectOrderUser(fromToken_, toToken_, price_, user_);
        }
    }

    function logPrice(
        address fromToken_,
        address toToken_,
        uint256 price_
    )
        internal
    {
        if(price_ > 0) {
            if(uint256(fromToken_) >= uint256(toToken_)) {
                priceBooks[fromToken_][toToken_] = price_;
            } else  {
                priceBooks[toToken_][fromToken_] = safeDiv(10 ** 36, price_);
            }
        }
    }
}