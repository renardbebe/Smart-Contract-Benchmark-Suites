 

pragma solidity ^0.5.0;
 
 
 
 
 
 
 


 


 

contract Truel {
    using SafeMath for uint;

    address private PLEDGE_ADDRESS;
    address private P3X_ADDRESS;
    IP3X private p3xContract;
    IPledge private pledgeContract;
    MegaballInterface public megaballContract;

    event Jackpot(uint indexed roundNumber, address indexed player, uint indexed amount);
    event OnWithdraw(address indexed customerAddress, uint256 ethereumWithdrawn, uint256 p3xWithdrawn);
    event WaitlistEntered(address player);
    event RoundEntered(uint indexed roundNumber, address indexed player);
    event PlayerShot(uint indexed roundNumber, address indexed shooter, address indexed dead);

    mapping(uint256 => Round) rounds;

    mapping(uint256 => Entrant) waitingList;
    uint256 public waitingListCount = 0;
    uint256 public waitingListMoveCount = 0;

    mapping(uint256 => uint256) public queue;
    uint256 public nextValid = 0;
    uint256 public nextToValidate = 0;

    uint256 public validatorBagMin = 0;

    address public owner;

    struct Entrant {
        address player;
        uint8 choice;
        bool dead;
        uint256 mintRemainder;
    }

    struct Round {
        bool isExist;
        uint8 entrantCount;
        Entrant entrantOne;
        Entrant entrantTwo;
        Entrant entrantThree;
        bool complete;
        uint8 result;
        uint8 n2;
        uint8 n3;
        uint8 n4;
        Entrant roundCreator;
    }

    mapping (address => uint256) private p3xVault;
    mapping (address => uint256) private ethVault;

    uint256 public UNALLOCATEDP3X = 0;

    uint256 public DIVIDENDS_JACKPOT = 0;
    uint256 public BACKFIRE_JACKPOT = 0;
    uint256 public MINI_JACKPOT = 0;

    uint256 public DENOMINATION = 100000000000000000;
    uint256 public nextWithdrawTime = 0;
    uint256 constant private denominationFloor = 100000000000000;
    uint256 constant private denominationCeiling = 10000000000000000000;
    uint256 public denominationActiveTimestamp;
    uint256 private denominationUpdateTimeOffset = 2629743;  

     
    uint256 public LEFT = 0;
    uint256 public MISS = 0;
    uint256 public RIGHT = 0;
    uint256 public BACKFIRE = 0;

    constructor(address pa, address hx, address mb) public
    {
        nextWithdrawTime = now;
        owner = msg.sender;
        validatorBagMin = 10e18;
        denominationActiveTimestamp = SafeMath.add(now, denominationUpdateTimeOffset);

        PLEDGE_ADDRESS = address(pa);
        P3X_ADDRESS = address(hx);
        p3xContract = IP3X(P3X_ADDRESS);
        pledgeContract = IPledge(PLEDGE_ADDRESS);
        megaballContract = MegaballInterface(address(mb));

    }

     
    function getBalance() public view returns (uint) {
        return p3xVault[msg.sender];
    }


   
    modifier hasBalance() {
        require(p3xVault[msg.sender] > 0);
       _;
    }

    modifier hasBagBalance() {
        require(p3xVault[msg.sender] > validatorBagMin);
       _;
    }

    function updateDenomination()
      external
    {
        require(denominationActiveTimestamp < now);

        denominationActiveTimestamp = SafeMath.add(now, denominationUpdateTimeOffset);
        uint256 USD_DENOM = megaballContract.DENOMINATION();

        if (USD_DENOM > denominationFloor && USD_DENOM < denominationCeiling) {
            DENOMINATION = USD_DENOM;
        }
    }

    function setValidatorBagMin() public {
        require(msg.sender == owner);
        if (waitingListCount > 1000) {
            validatorBagMin = 20e18;
        }

        if (waitingListCount > 10000) {
            validatorBagMin = 100e18;
        }

        if (waitingListCount > 20000) {
            validatorBagMin = 200e18;
        }
    }

    function isValidator() public view returns (bool) {
        if (p3xVault[msg.sender] > validatorBagMin) { return true;}

        return false;
    }


    function getEthBalance() public view returns (uint) {
        return ethVault[msg.sender];
    }

   
    modifier hasEthBalance() {
        require(ethVault[msg.sender] > 0);
       _;
    }

    function myP3XBalance()
        external
        view
        returns(uint256)
    {
        return p3xContract.balanceOf(msg.sender);
    }

    function contractEthBalance()
        public
        view
        returns(uint256)
    {
        return (address(this).balance);
    }

    function contractP3XBalance()
        public
        view
        returns(uint256)
    {
        return p3xContract.balanceOf(address(this));
    }

    function contractP3XDividends()
        external
        view
        returns(uint256)
    {
        return p3xContract.dividendsOf(address(this), true);
    }

    function pledgeDividends()
        external
        view
        returns(uint256)
    {
        return p3xContract.dividendsOf(address(PLEDGE_ADDRESS), true);
    }

    function withdraw()
        external
    {
        uint256 amountP3x = p3xVault[msg.sender];
        if (amountP3x > 0) {
            p3xVault[msg.sender] = 0;
            p3xContract.transfer(msg.sender, amountP3x);
        }

        uint256 amountEth = ethVault[msg.sender];
        if (amountEth > 0) {
            ethVault[msg.sender] = 0;
            msg.sender.transfer(amountEth);
        }
        emit OnWithdraw(msg.sender, amountEth, amountP3x);

    }


    function withdrawEarnings()
        external
    {
        uint256 amount = p3xVault[msg.sender];

        require(amount > 0);

        p3xVault[msg.sender] = 0;

        p3xContract.transfer(msg.sender, amount);
    }

    function withdrawEth()
        external
    {
        uint256 amount = ethVault[msg.sender];

        require(amount > 0);

        ethVault[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

     

    function() external payable {}

    function tokenFallback(address player, uint256 amount, bytes calldata data)
    external
    {
        require(msg.sender == P3X_ADDRESS);

    }

    function fetchDividendsFromP3X()
    public
    {
        if (nextWithdrawTime < now) {
            nextWithdrawTime = now.add(600);
            uint256 dividends = p3xContract.dividendsOf(address(this), true);
            if (dividends > 0) {
                p3xContract.withdraw();
                MINI_JACKPOT = MINI_JACKPOT.add(dividends);
                DIVIDENDS_JACKPOT = DIVIDENDS_JACKPOT.add(pledgeContract.withdraw());
            }
        }
    }

    function choiceTally(uint8 _choice) internal {
        if (_choice == 0) {
            LEFT = LEFT.add(1);
        }
        if (_choice == 1) {
            MISS = MISS.add(1);
        }
        if (_choice == 2) {
            RIGHT = RIGHT.add(1);
        }
    }

    function enterTruel(uint8 _choice)
    external
    payable
    {
        require(msg.value == DENOMINATION);
        choiceTally(_choice);

         
        uint256 total = p3xContract.buy.value(msg.value)(PLEDGE_ADDRESS);

        uint256 value = total.div(2);

        UNALLOCATEDP3X = UNALLOCATEDP3X.add(value);
        p3xVault[msg.sender] = p3xVault[msg.sender].add(value);


        Entrant memory entrants = Entrant(msg.sender, _choice, false, value);
        waitingList[waitingListCount] = entrants;
        waitingListCount = waitingListCount.add(1);
        emit WaitlistEntered(msg.sender);
    }

    function findFirstAvailableBlock()
    internal
    view
    returns (uint256)
    {
         
        for (uint8 i=4; i < 100; i++)
        {
            if (!rounds[block.number + i].isExist) {
                return block.number + i;
            }
        }
    }

     

    function enterFromWaitlist()
    public
    hasBagBalance
    {
        require((waitingListCount - waitingListMoveCount) > 5);
        uint256 blockz = findFirstAvailableBlock();
        require(!rounds[blockz].isExist);
        require(p3xVault[msg.sender] > waitingList[waitingListMoveCount].mintRemainder.mul(2));

        if (!rounds[blockz].isExist) {
            fetchDividendsFromP3X();
            uint256 zz = waitingListMoveCount.add(1);
            uint256 yy = waitingListMoveCount.add(2);

            uint256 withheldValue = waitingList[waitingListMoveCount].mintRemainder.mul(2);
            p3xVault[msg.sender] = p3xVault[msg.sender].sub(withheldValue);
            Entrant memory roundCreator = Entrant(msg.sender, 0, false, withheldValue);

            rounds[blockz] = Round(true, 3, waitingList[waitingListMoveCount], waitingList[zz], waitingList[yy], false, 0, 0, 0, 0, roundCreator);

            emit RoundEntered(blockz, waitingList[waitingListMoveCount].player);
            emit RoundEntered(blockz, waitingList[zz].player);
            emit RoundEntered(blockz, waitingList[yy].player);
            waitingListMoveCount = waitingListMoveCount.add(3);
             
            queue[nextValid] = blockz;
            nextValid = nextValid.add(1);
        }
    }

    function getQueueItem(uint256 item)
    external
    view
    returns (uint)
    {
        uint256 lblock = queue[item];
        return lblock;
    }

    function getBlockFromQueue(uint256 _offset)
    public
    view
    returns (address, bool, address, bool, address, bool, bool, uint)
    {
        uint256 queuePosition = nextToValidate.sub(_offset);
        uint256 _block = queue[queuePosition];
        return (
            rounds[_block].entrantOne.player,
            rounds[_block].entrantOne.dead,
            rounds[_block].entrantTwo.player,
            rounds[_block].entrantTwo.dead,
            rounds[_block].entrantThree.player,
            rounds[_block].entrantThree.dead,
            rounds[_block].complete,
            _block);
    }


    function whichBlock()
    external
    view
    returns (uint)
    {
        uint256 lblock = queue[nextToValidate];
        return lblock;
    }

    function validator()
    external
    hasBagBalance
    {
        uint256 lblock = queue[nextToValidate];
        validate(lblock);
        nextToValidate = nextToValidate.add(1);
    }

    function canCreateRound()
    external
    view
    returns (bool)
    {
        bool status = true;

        if ((waitingListCount - waitingListMoveCount) < 6) {status = false;}
        if (p3xVault[msg.sender] < waitingList[waitingListMoveCount].mintRemainder.mul(2)) {status = false;}

        return status;
    }


    function isValidatorAvailable()
    external
    view
    returns (bool)
    {

        uint256 qblock = queue[nextToValidate];
        uint256 bx = block.number;
        uint256 bxp = bx.add(10);

        if (nextToValidate == nextValid) {
            return false;
        }

        if (rounds[qblock].roundCreator.player == msg.sender) {
            if (bx > qblock) { return true;}
        }

        if (rounds[qblock].roundCreator.player != msg.sender) {
            if (bxp > qblock) { return true;}
        }

        return false;
    }

    function firstShotToRoundCreator(uint256 _block, address _blockOwner)
    public
    view
    returns (bool)
    {
        uint256 bx = block.number - _block;

        if (rounds[_block].roundCreator.player == _blockOwner) {
            if (bx > 0) { return true;}
        }

        if (rounds[_block].roundCreator.player != _blockOwner) {
            if (bx > 10) { return true;}
        }

        return false;
    }


    function validate(uint256 _block)
    internal
    {
        require(rounds[_block].complete == false);
        require(_block < block.number);
        require(rounds[_block].isExist);
        require(firstShotToRoundCreator(_block, msg.sender));

        rounds[_block].complete = true;
        uint8 n1 = 0;
        uint8 n2 = 0;
        uint8 n3 = 0;
        uint8 n4 = 0;

        uint8 s1 = 0;
         
        uint256 bx = block.number.sub(_block);
        if (bx >= 232) {
            rounds[_block].result = 0;
        }

        if (bx < 232) {
             
            n1 = SafeMath.add3(1, (uint256(keccak256(abi.encodePacked(_block.sub(3)))) % 3));
            n2 = SafeMath.add3(1, (uint256(keccak256(abi.encodePacked(_block.sub(2)))) % 100));
            n3 = SafeMath.add3(1, (uint256(keccak256(abi.encodePacked(_block.sub(1)))) % 100));
            n4 = SafeMath.add3(1, (uint256(keccak256(abi.encodePacked(_block))) % 100));

            s1 = n2 + n3 + n4;
            rounds[_block].result = n1;
            rounds[_block].n2 = n2;
            rounds[_block].n3 = n3;
            rounds[_block].n4 = n4;
        }



         
        if (rounds[_block].result == 0) {
            rounds[_block].entrantOne.dead = true;
            rounds[_block].entrantTwo.dead = true;
            rounds[_block].entrantThree.dead = true;
        }

         
        if (rounds[_block].result > 0) {

           
            address p4 = rounds[_block].roundCreator.player;
            p3xVault[p4] = p3xVault[p4].add(rounds[_block].roundCreator.mintRemainder);

             
            if (rounds[_block].entrantOne.choice != 1 && n2 < 10) {
                rounds[_block].entrantOne.dead = true;
                BACKFIRE_JACKPOT = BACKFIRE_JACKPOT.add(rounds[_block].entrantOne.mintRemainder);
                rounds[_block].entrantOne.mintRemainder = 0;
                BACKFIRE = BACKFIRE.add(1);
                emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantOne.player);
            }
             
            if (rounds[_block].entrantTwo.choice != 1 && n3 < 10) {
                rounds[_block].entrantTwo.dead = true;
                BACKFIRE_JACKPOT = BACKFIRE_JACKPOT.add(rounds[_block].entrantTwo.mintRemainder);
                rounds[_block].entrantTwo.mintRemainder = 0;
                BACKFIRE = BACKFIRE.add(1);
                emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantTwo.player);
            }
             
            if (rounds[_block].entrantThree.choice != 1 && n4 < 10) {
                rounds[_block].entrantThree.dead = true;
                BACKFIRE_JACKPOT = BACKFIRE_JACKPOT.add(rounds[_block].entrantThree.mintRemainder);
                rounds[_block].entrantThree.mintRemainder = 0;
                BACKFIRE = BACKFIRE.add(1);
                emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantThree.player);
            }

           
            if (rounds[_block].result == 1) {
                if (rounds[_block].entrantOne.choice == 0 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantThree.player);
                }
                if (rounds[_block].entrantOne.choice == 2 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantTwo.player);
                }

                if (rounds[_block].entrantTwo.choice == 0 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantOne.player);
                }
                if (rounds[_block].entrantTwo.choice == 2 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantThree.player);
                }

                if (rounds[_block].entrantThree.choice == 0 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantTwo.player);
                }
                if (rounds[_block].entrantThree.choice == 2 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantOne.player);
                }
            }
             
            if (rounds[_block].result == 2) {
                if (rounds[_block].entrantThree.choice == 0 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantTwo.player);
                }
                if (rounds[_block].entrantThree.choice == 2 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantOne.player);
                }

                if (rounds[_block].entrantOne.choice == 0 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantThree.player);
                }
                if (rounds[_block].entrantOne.choice == 2 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantTwo.player);
                }

                if (rounds[_block].entrantTwo.choice == 0 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantOne.player);
                }
                if (rounds[_block].entrantTwo.choice == 2 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantThree.player);
                }
            }

             
            if (rounds[_block].result == 3) {
                if (rounds[_block].entrantTwo.choice == 0 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantOne.player);
                }
                if (rounds[_block].entrantTwo.choice == 2 && rounds[_block].entrantTwo.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantTwo.mintRemainder = rounds[_block].entrantTwo.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantTwo.player, rounds[_block].entrantThree.player);
                }

                if (rounds[_block].entrantThree.choice == 0 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantTwo.player);
                }
                if (rounds[_block].entrantThree.choice == 2 && rounds[_block].entrantThree.dead == false) {
                    rounds[_block].entrantOne.dead = true;
                    rounds[_block].entrantThree.mintRemainder = rounds[_block].entrantThree.mintRemainder.add(rounds[_block].entrantOne.mintRemainder);
                    rounds[_block].entrantOne.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantThree.player, rounds[_block].entrantOne.player);
                }

                if (rounds[_block].entrantOne.choice == 0 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantThree.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantThree.mintRemainder);
                    rounds[_block].entrantThree.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantThree.player);
                }
                if (rounds[_block].entrantOne.choice == 2 && rounds[_block].entrantOne.dead == false) {
                    rounds[_block].entrantTwo.dead = true;
                    rounds[_block].entrantOne.mintRemainder = rounds[_block].entrantOne.mintRemainder.add(rounds[_block].entrantTwo.mintRemainder);
                    rounds[_block].entrantTwo.mintRemainder = 0;
                    emit PlayerShot(_block, rounds[_block].entrantOne.player, rounds[_block].entrantTwo.player);
                }
            }

            if (rounds[_block].entrantOne.mintRemainder > 0) {
                payWinner(rounds[_block].entrantOne.player, rounds[_block].entrantOne.mintRemainder);
            }

            if (rounds[_block].entrantTwo.mintRemainder > 0) {
                payWinner(rounds[_block].entrantTwo.player, rounds[_block].entrantTwo.mintRemainder);
            }

            if (rounds[_block].entrantThree.mintRemainder > 0) {
                payWinner(rounds[_block].entrantThree.player, rounds[_block].entrantThree.mintRemainder);
            }

             
            doMicroJP(s1);
            doJackpot(s1, _block);
            doMiniJackpot(s1, msg.sender);
        }

    }

    function doMicroJP(uint8 s1) internal {
        if (s1 > 265) {
            uint256 share = MINI_JACKPOT;
            if (share > 0) {
                MINI_JACKPOT = 0;
                address p4 = waitingList[waitingListMoveCount - 1].player;
                ethVault[p4] = ethVault[p4].add(share);
                emit Jackpot(block.number, p4, share);
            }
        }
    }

    function doMiniJackpot(uint8 s1, address validatorAddress) internal {
        if (s1 > 265) {
            uint256 bshare = BACKFIRE_JACKPOT;
            if (bshare > 0) {
                BACKFIRE_JACKPOT = 0;
                p3xVault[validatorAddress] = p3xVault[validatorAddress].add(bshare);
                emit Jackpot(block.number, validatorAddress, bshare);
            }
        }
    }


    function doJackpot(uint8 s1, uint256 _block) internal {
        if (s1 == 297) {

            if (!rounds[_block].entrantOne.dead
                && !rounds[_block].entrantTwo.dead
                && !rounds[_block].entrantThree.dead) {

                uint256 share = DIVIDENDS_JACKPOT.div(4);
                DIVIDENDS_JACKPOT = 0;

                address p1 = rounds[_block].entrantOne.player;
                address p2 = rounds[_block].entrantTwo.player;
                address p3 = rounds[_block].entrantThree.player;
                address p4 = waitingList[waitingListMoveCount - 1].player;

                ethVault[p1] = ethVault[p1].add(share);
                ethVault[p2] = ethVault[p2].add(share);
                ethVault[p3] = ethVault[p3].add(share);

                ethVault[p4] = ethVault[p4].add(share);

                emit Jackpot(_block, p4, share);
                emit Jackpot(_block, p1, share);
                emit Jackpot(_block, p2, share);
                emit Jackpot(_block, p3, share);
            }
        }
    }

    function payWinner(address player, uint256 amount) internal {
        UNALLOCATEDP3X = UNALLOCATEDP3X.sub(amount);
        if (UNALLOCATEDP3X > amount) {
            p3xVault[player] = p3xVault[player].add(amount);
        }
    }

    function roundDeathInfo(uint256 _block)
    public
    view
    returns (address, bool, address, bool, address, bool, bool)
    {
        return (
        rounds[_block].entrantOne.player,
        rounds[_block].entrantOne.dead,
        rounds[_block].entrantTwo.player,
        rounds[_block].entrantTwo.dead,
        rounds[_block].entrantThree.player,
        rounds[_block].entrantThree.dead,
        rounds[_block].complete);
    }

    function deaths(uint256 _block)
    public
    view
    returns (bool, bool, bool)
    {
        return (
        rounds[_block].entrantOne.dead,
        rounds[_block].entrantTwo.dead,
        rounds[_block].entrantThree.dead);
    }

    function mintRemainder(uint256 _block)
    public
    view
    returns (uint, uint, uint)
    {
        return (
        rounds[_block].entrantOne.mintRemainder,
        rounds[_block].entrantTwo.mintRemainder,
        rounds[_block].entrantThree.mintRemainder);
    }


    function choices()
    public
    view
    returns (uint, uint, uint)
    {
        return (
        LEFT,
        RIGHT,
        MISS);
    }

    function results(uint256 _block)
    public
    view
    returns (uint, uint, uint, uint)
    {
        return (
        rounds[_block].result,
        rounds[_block].n2,
        rounds[_block].n3,
        rounds[_block].n4);
    }

    function getWaitlistItem(uint256 _item)
    public
    view
    returns (address, uint8, bool, uint256, uint256)
    {
        return (
        waitingList[_item].player,
        waitingList[_item].choice,
        waitingList[_item].dead,
        waitingList[_item].mintRemainder,
        _item);
    }
}


interface IP3X {
    function transfer(address to, uint256 value) external returns(bool);
    function transfer(address to, uint value, bytes calldata data) external returns(bool ok);
    function buy(address referrerAddress) payable external returns(uint256);
    function balanceOf(address tokenOwner) external view returns(uint);
    function dividendsOf(address customerAddress, bool includeReferralBonus) external view returns(uint256);
    function withdraw() external;
}


interface IPledge {
    function withdraw() external returns(uint256);
}

interface MegaballInterface {
    function DENOMINATION() external view returns(uint);
}


 
library SafeMath {

 
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
        return c;
    }

     
    function add2(uint8 a, uint8 b)
        internal
        pure
        returns (uint8 c)
    {
        c = a + b;
        require(c >= a);
        return uint8(c);
    }

     
    function add3(uint8 a, uint256 b)
        internal
        pure
        returns (uint8 c)
    {
        c = a + uint8(b);
        require(c >= a);
        return uint8(c);
    }


     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
       
       
       
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

     
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}