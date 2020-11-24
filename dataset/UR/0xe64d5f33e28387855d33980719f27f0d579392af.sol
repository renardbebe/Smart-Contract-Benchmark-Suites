 

 
 
 
 
 

pragma solidity ^0.4.19;


contract HouseOwned {
    address house;

    modifier onlyHouse {
        require(msg.sender == house);
        _;
    }

     
    function HouseOwned() public {
        house = msg.sender;
    }
}


 
 
 

 
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

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function transfer(address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}

contract Token is HouseOwned, ERC20Interface {
    using SafeMath for uint;

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 0;
    uint256 public supply;

     
    Jackpot public jackpot;
    address public croupier;

     
    mapping (address => uint256) internal balances;
     
    mapping (address => uint256) public depositOf;
     
    uint256 public totalDeposit;
     
    uint256 public frozenPool;
     
    mapping (address => mapping (address => uint256)) internal allowed;

     
     
     

     
    modifier onlyCroupier {
        require(msg.sender == croupier);
        _;
    }

     
    modifier onlyJackpot {
        require(msg.sender == address(jackpot));
        _;
    }

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

     
     
     

     
    event Burn(address indexed from, uint256 value);

     
     
     
    event Deposit(address indexed from, uint256 value, uint8 direction, uint256 newDeposit);

     
    event DepositFrozen(address indexed from, uint256 value);

     
     
    event DepositUnfrozen(address indexed from, uint256 value);

     
     
     

     
    function Token() HouseOwned() public {
        name = "JACK Token";
        symbol = "JACK";
        supply = 1000000;
    }

     
     
    function setJackpot(address _jackpot) onlyHouse public {
        require(address(jackpot) == 0x0);
        require(_jackpot != address(this));  

        jackpot = Jackpot(_jackpot);

        uint256 bountyPortion = supply / 40;            
        balances[house] = bountyPortion;                
        balances[jackpot] = supply - bountyPortion;     

        croupier = jackpot.croupier();
    }

     
     
     


     
     
     
    function returnDeposit(address _to, uint256 _extra) onlyCroupier public {
        require(depositOf[_to] > 0 || _extra > 0);
        uint256 amount = depositOf[_to];
        depositOf[_to] = 0;
        totalDeposit = totalDeposit.sub(amount);

        _transfer(croupier, _to, amount.add(_extra));

        Deposit(_to, amount, 1, 0);
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function totalSupply() public view returns (uint256) {
        return supply;
    }

     
     
     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(address(jackpot) != 0x0);
        require(croupier != 0x0);

        if (_to == address(jackpot)) {
             
            _burnFromAccount(msg.sender, 1);
            jackpot.betToken(msg.sender);
            return true;
        }

        if (_to == croupier && msg.sender != house) {
             
             

             
             

            depositOf[msg.sender] += _value;
            totalDeposit = totalDeposit.add(_value);

            Deposit(msg.sender, _value, 0, depositOf[msg.sender]);
        }

         
         
        return _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
     
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
    function freezeDeposit(address _user, uint256 _extra) onlyCroupier public {
        require(depositOf[_user] > 0 || _extra > 0);

        uint256 deposit = depositOf[_user];
        depositOf[_user] = depositOf[_user].sub(deposit);
        totalDeposit = totalDeposit.sub(deposit);

        uint256 depositWithExtra = deposit.add(_extra);

        frozenPool = frozenPool.add(depositWithExtra);

        DepositFrozen(_user, depositWithExtra);
    }

     
     
     
    function unfreezeDeposit(address _user, uint256 _value) onlyCroupier public {
        require(_value > 0);
        require(frozenPool >= _value);

        depositOf[_user] = depositOf[_user].add(_value);
        totalDeposit = totalDeposit.add(_value);

        frozenPool = frozenPool.sub(_value);

        DepositUnfrozen(_user, depositOf[_user]);
    }

     
     
     
    function transferFromCroupier(address _to, uint256 _value) onlyJackpot public {
        require(_value > 0);
        require(frozenPool >= _value);

        frozenPool = frozenPool.sub(_value);

        _transfer(croupier, _to, _value);
    }

     
     
     

     
     
     
     
     
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));                          
        require(balances[_from] >= _value);                  
        balances[_from] = balances[_from].sub(_value);       
        balances[_to] = balances[_to].add(_value);           
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
    function _burnFromAccount(address _sender, uint256 _value) internal {
        require(balances[_sender] >= _value);                
        balances[_sender] = balances[_sender].sub(_value);   
        supply = supply.sub(_value);                         
        Burn(_sender, _value);
    }

}

contract Jackpot is HouseOwned {
    using SafeMath for uint;

    enum Stages {
        InitialOffer,    
        GameOn,          
        GameOver,        
        Aborted          
    }

    uint256 constant initialIcoTokenPrice = 4 finney;
    uint256 constant initialBetAmount = 10 finney;
    uint constant gameStartJackpotThreshold = 333 ether;
    uint constant icoTerminationTimeout = 48 hours;

     
     
     
     
     
     
    uint32 public totalBets = 0;
    uint256 public etherSince20 = 1;
    uint256 public etherSince50 = 1;
    uint256 public etherSince100 = 1;
    uint256 public pendingEtherForCroupier = 0;

     
    uint32 public icoSoldTokens;
    uint256 public icoEndTime;

     
    address public lastBetUser;
    uint256 public terminationTime;
    address public winner;
    uint256 public pendingJackpotForHouse;
    uint256 public pendingJackpotForWinner;

     
    address public croupier;
    Token public token;
    Stages public stage = Stages.InitialOffer;

     
    uint256 public currentIcoTokenPrice = initialIcoTokenPrice;
    uint256 public currentBetAmount = initialBetAmount;

     
    mapping (address => uint256) public investmentOf;
    uint256 public abortTime;

     
     
     

     
    modifier onlyToken {
        require(msg.sender == address(token));
        _;
    }

     
    modifier onlyCroupier {
        require(msg.sender == address(croupier));
        _;
    }

     
     
     

     
    event EtherIco(address indexed from, uint256 value, uint256 tokens);

     
    event EtherBet(address indexed from, uint256 value, uint256 dividends);

     
    event TokenBet(address indexed from);

     
     
    event MinorPrizePayout(address indexed from, uint256 value, uint8 prizeType);

     
     
    event SoldTokensFromCroupier(address indexed from, uint256 value, uint256 tokens);

     
    event JackpotWon(address indexed from, uint256 value);


     
     
     

     
     
    function Jackpot(address _croupier)
        HouseOwned()
        public
    {
        require(_croupier != 0x0);
        croupier = _croupier;

         
         
         
         
        lastBetUser = _croupier;
    }

     
     
    function setToken(address _token) onlyHouse public {
        require(address(token) == 0x0);
        require(_token != address(this));  

        token = Token(_token);
    }


     
     
     

     
     
     
     
     
     
    function() payable public {
        require(croupier != 0x0);
        require(address(token) != 0x0);
        require(stage != Stages.Aborted);

        uint256 tokens;

        if (stage == Stages.InitialOffer) {

             
             
            bool started = checkGameStart();
            if (started) {
                 
                 
                msg.sender.transfer(msg.value);
                return;
            }

            require(msg.value >= currentIcoTokenPrice);
        
             
             
             
             
             
             
             

             
            tokens = _icoTokensForEther(msg.value);

             
             
            EtherIco(msg.sender, msg.value, tokens);

            investmentOf[msg.sender] = investmentOf[msg.sender].add(
                msg.value.sub(msg.value / 5)
            );

             
             
            if (icoEndTime == 0 && this.balance >= gameStartJackpotThreshold) {
                icoEndTime = now + icoTerminationTimeout;
            }

             
             
            if (tokens > 0) {
                token.transfer(msg.sender, tokens);
            }

             
             
            house.transfer(msg.value / 5);

        } else if (stage == Stages.GameOn) {

             
             
            bool terminated = checkTermination();
            if (terminated) {
                 
                 
                msg.sender.transfer(msg.value);
                return;
            }

             
            require(msg.value >= currentBetAmount);

             
             
             
             
             
             
             
             
             


             
            tokens = _betTokensForEther(msg.value);

             
             
            uint256 sellingFromJackpot = 0;
            uint256 sellingFromCroupier = 0;
            if (tokens > 0) {
                uint256 croupierPool = token.frozenPool();
                uint256 jackpotPool = token.balanceOf(this);

                if (croupierPool == 0) {
                     
                    sellingFromJackpot = tokens;
                    if (sellingFromJackpot > jackpotPool) {
                        sellingFromJackpot = jackpotPool;
                    }
                } else if (jackpotPool == 0 || tokens <= croupierPool) {
                     
                     
                     
                    sellingFromCroupier = tokens;
                    if (sellingFromCroupier > croupierPool) {
                        sellingFromCroupier = croupierPool;
                    }
                } else {
                     
                    sellingFromCroupier = croupierPool;   
                    sellingFromJackpot = tokens.sub(sellingFromCroupier);
                    if (sellingFromJackpot > jackpotPool) {
                        sellingFromJackpot = jackpotPool;
                    }
                }
            }

             
             
             
             
             
             
             
            uint256 tokenValue = msg.value.sub(currentBetAmount);

            uint256 croupierSaleRevenue = 0;
            if (sellingFromCroupier > 0) {
                croupierSaleRevenue = tokenValue.div(
                    sellingFromJackpot.add(sellingFromCroupier)
                ).mul(sellingFromCroupier);
            }
            uint256 jackpotSaleRevenue = tokenValue.sub(croupierSaleRevenue);

            uint256 dividends = (currentBetAmount.div(4)).add(jackpotSaleRevenue.div(2));

             
             
            pendingEtherForCroupier = pendingEtherForCroupier.add(dividends.add(croupierSaleRevenue));

             
             
            EtherBet(msg.sender, msg.value, dividends);
            lastBetUser = msg.sender;
            terminationTime = now + _terminationDuration();

             
            if (croupierSaleRevenue > 0) {
                SoldTokensFromCroupier(msg.sender, croupierSaleRevenue, sellingFromCroupier);
            }

             
             
            _checkMinorPrizes(msg.sender, currentBetAmount);

             
            _updateBetAmount();

             
            if (sellingFromJackpot > 0) {
                token.transfer(msg.sender, sellingFromJackpot);
            }
            if (sellingFromCroupier > 0) {
                token.transferFromCroupier(msg.sender, sellingFromCroupier);
            }

        } else if (stage == Stages.GameOver) {

            require(msg.sender == winner || msg.sender == house);

            if (msg.sender == winner) {
                require(pendingJackpotForWinner > 0);

                uint256 winnersPay = pendingJackpotForWinner;
                pendingJackpotForWinner = 0;

                msg.sender.transfer(winnersPay);
            } else if (msg.sender == house) {
                require(pendingJackpotForHouse > 0);

                uint256 housePay = pendingJackpotForHouse;
                pendingJackpotForHouse = 0;

                msg.sender.transfer(housePay);
            }
        }
    }

     
     
     
    function payOutJackpot() onlyCroupier public {
        require(winner != 0x0);
    
        if (pendingJackpotForHouse > 0) {
            uint256 housePay = pendingJackpotForHouse;
            pendingJackpotForHouse = 0;

            house.transfer(housePay);
        }

        if (pendingJackpotForWinner > 0) {
            uint256 winnersPay = pendingJackpotForWinner;
            pendingJackpotForWinner = 0;

            winner.transfer(winnersPay);
        }

    }

     
     
     

     
     
     
     
    function shouldBeTerminated() public view returns (bool should) {
        return stage == Stages.GameOn && terminationTime != 0 && now > terminationTime;
    }

     
     
    function checkTermination() public returns (bool terminated) {
        if (shouldBeTerminated()) {
            stage = Stages.GameOver;

            winner = lastBetUser;

             
            _flushEtherToCroupier();

             
            JackpotWon(winner, this.balance);


            uint256 jackpot = this.balance;
            pendingJackpotForHouse = jackpot.div(5);
            pendingJackpotForWinner = jackpot.sub(pendingJackpotForHouse);

            return true;
        }

        return false;
    }

     
     
     
     
    function shouldBeStarted() public view returns (bool should) {
        return stage == Stages.InitialOffer && icoEndTime != 0 && now > icoEndTime;
    }

     
     
    function checkGameStart() public returns (bool started) {
        if (shouldBeStarted()) {
            stage = Stages.GameOn;

            return true;
        }

        return false;
    }

     
     
     
    function betToken(address _user) onlyToken public {
         
        require(stage == Stages.GameOn);

        bool terminated = checkTermination();
        if (terminated) {
            return;
        }

        TokenBet(_user);
        lastBetUser = _user;
        terminationTime = now + _terminationDuration();

         
        _checkMinorPrizes(_user, 0);
    }

     
    function abort() onlyHouse public {
        require(stage == Stages.InitialOffer);

        stage = Stages.Aborted;
        abortTime = now;
    }

     
     
    function claimRefund() public {
        require(stage == Stages.Aborted);
        require(investmentOf[msg.sender] > 0);

        uint256 payment = investmentOf[msg.sender];
        investmentOf[msg.sender] = 0;

        msg.sender.transfer(payment);
    }

     
     
    function killAborted() onlyHouse public {
        require(stage == Stages.Aborted);
        require(now > abortTime + 60 days);

        selfdestruct(house);
    }



     
     
     

     
     
    function _terminationDuration() internal view returns (uint256 duration) {
        return (5 + 19200 / (100 + totalBets)) * 1 minutes;
    }

     
    function _updateIcoPrice() internal {
        uint256 newIcoTokenPrice = currentIcoTokenPrice;

        if (icoSoldTokens < 10000) {
            newIcoTokenPrice = 4 finney;
        } else if (icoSoldTokens < 20000) {
            newIcoTokenPrice = 5 finney;
        } else if (icoSoldTokens < 30000) {
            newIcoTokenPrice = 5.3 finney;
        } else if (icoSoldTokens < 40000) {
            newIcoTokenPrice = 5.7 finney;
        } else {
            newIcoTokenPrice = 6 finney;
        }

        if (newIcoTokenPrice != currentIcoTokenPrice) {
            currentIcoTokenPrice = newIcoTokenPrice;
        }
    }

     
    function _updateBetAmount() internal {
        uint256 newBetAmount = 10 finney + (totalBets / 100) * 6 finney;

        if (newBetAmount != currentBetAmount) {
            currentBetAmount = newBetAmount;
        }
    }

     
     
     
    function _betTokensForEther(uint256 value) internal view returns (uint256 tokens) {
         
         
        tokens = (value / currentBetAmount) - 1;

        if (tokens >= 1000) {
            tokens = tokens + tokens / 4;  
        } else if (tokens >= 300) {
            tokens = tokens + tokens / 5;  
        } else if (tokens >= 100) {
            tokens = tokens + tokens / 7;  
        } else if (tokens >= 50) {
            tokens = tokens + tokens / 10;  
        } else if (tokens >= 20) {
            tokens = tokens + tokens / 20;  
        }
    }

     
     
     
    function _icoTokensForEther(uint256 value) internal returns (uint256 tokens) {
         
        tokens = value / currentIcoTokenPrice;

        if (tokens >= 10000) {
            tokens = tokens + tokens / 4;  
        } else if (tokens >= 5000) {
            tokens = tokens + tokens / 5;  
        } else if (tokens >= 1000) {
            tokens = tokens + tokens / 7;  
        } else if (tokens >= 500) {
            tokens = tokens + tokens / 10;  
        } else if (tokens >= 200) {
            tokens = tokens + tokens / 20;  
        }

         
        if (tokens > token.balanceOf(this)) {
            tokens = token.balanceOf(this);
        }

        icoSoldTokens += (uint32)(tokens);

        _updateIcoPrice();
    }

     
    function _flushEtherToCroupier() internal {
        if (pendingEtherForCroupier > 0) {
            uint256 willTransfer = pendingEtherForCroupier;
            pendingEtherForCroupier = 0;
            
            croupier.transfer(willTransfer);
        }
    }

     
     
     
     
    function _checkMinorPrizes(address user, uint256 value) internal {
         
        totalBets ++;
        if (value > 0) {
            etherSince20 = etherSince20.add(value);
            etherSince50 = etherSince50.add(value);
            etherSince100 = etherSince100.add(value);
        }

         

        uint256 etherPayout;

        if ((totalBets + 30) % 100 == 0) {
             
            etherPayout = (etherSince100 - 1) / 10;
            etherSince100 = 1;

            MinorPrizePayout(user, etherPayout, 3);

            user.transfer(etherPayout);
            return;
        }

        if ((totalBets + 5) % 50 == 0) {
             
            etherPayout = (etherSince50 - 1) / 10;
            etherSince50 = 1;

            MinorPrizePayout(user, etherPayout, 2);

            user.transfer(etherPayout);
            return;
        }

        if (totalBets % 20 == 0) {
             
            etherPayout = (etherSince20 - 1) / 10;
            etherSince20 = 1;

            _flushEtherToCroupier();

            MinorPrizePayout(user, etherPayout, 1);

            user.transfer(etherPayout);
            return;
        }

        return;
    }

}