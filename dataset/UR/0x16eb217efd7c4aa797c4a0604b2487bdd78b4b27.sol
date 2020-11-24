 

pragma solidity ^0.4.25;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function withdrawAllEther() public onlyOwner {  
    _owner.transfer(this.balance);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract blackJack is Ownable {

    mapping (uint => uint) cardsPower;

    constructor() {
    cardsPower[0] = 11;  
    cardsPower[1] = 2;
    cardsPower[2] = 3;
    cardsPower[3] = 4;
    cardsPower[4] = 5;
    cardsPower[5] = 6;
    cardsPower[6] = 7;
    cardsPower[7] = 8;
    cardsPower[8] = 9;
    cardsPower[9] = 10;
    cardsPower[10] = 10;  
    cardsPower[11] = 10;  
    cardsPower[12] = 10;  
    }


    uint minBet = 0.01 ether;
    uint maxBet = 0.1 ether;
    uint requiredHouseBankroll = 3 ether;  
    uint autoWithdrawBuffer = 1 ether;  


    mapping (address => bool) public isActive;
    mapping (address => bool) public isPlayerActive;
    mapping (address => uint) public betAmount;
    mapping (address => uint) public gamestatus;  
    mapping (address => uint) public payoutAmount;
    mapping (address => uint) dealTime;
    mapping (address => uint) blackJackHouseProhibited;
    mapping (address => uint[]) playerCards;
    mapping (address => uint[]) houseCards;


    mapping (address => bool) playerExists;  

    function card2PowerConverter(uint[] cards) internal view returns (uint) {  
        uint powerMax = 0;
        uint aces = 0;  
        uint power;
        for (uint i = 0; i < cards.length; i++) {
             power = cardsPower[(cards[i] + 13) % 13];
             powerMax += power;
             if (power == 11) {
                 aces += 1;
             }
        }
        if (powerMax > 21) {  
            for (uint i2=0; i2<aces; i2++) {
                powerMax-=10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
        return uint(powerMax);
    }


     

    uint randNonce = 0;
    function randgenNewHand() internal returns(uint,uint,uint) {  
         
        randNonce++;
        uint a = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        randNonce++;
        uint b = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        randNonce++;
        uint c = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;
        return (a,b,c);
      }

    function randgen() internal returns(uint) {  
         
        randNonce++;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 52;  
      }

    modifier requireHandActive(bool truth) {
        require(isActive[msg.sender] == truth);
        _;
    }

    modifier requirePlayerActive(bool truth) {
        require(isPlayerActive[msg.sender] == truth);
        _;
    }

    function _play() public payable {  
         
        if (playerExists[msg.sender]) {
            require(isActive[msg.sender] == false);
        }
        else {
            playerExists[msg.sender] = true;
        }
        require(msg.value >= minBet);  
        require(msg.value <= maxBet);  
         
        uint a;  
        uint b;
        uint c;
        (a,b,c) = randgenNewHand();
        gamestatus[msg.sender] = 1;
        payoutAmount[msg.sender] = 0;
        isActive[msg.sender] = true;
        isPlayerActive[msg.sender] = true;
        betAmount[msg.sender] = msg.value;
        dealTime[msg.sender] = now;
        playerCards[msg.sender] = new uint[](0);
        playerCards[msg.sender].push(a);
        playerCards[msg.sender].push(b);
        houseCards[msg.sender] = new uint[](0);
        houseCards[msg.sender].push(c);
        isBlackjack();
        withdrawToOwnerCheck();
         
         
         
    }

    function _Hit() public requireHandActive(true) requirePlayerActive(true) {  
        uint a=randgen();  
        playerCards[msg.sender].push(a);
        checkGameState();
    }

    function _Stand() public requireHandActive(true) requirePlayerActive(true) {  
        isPlayerActive[msg.sender] = false;  
        checkGameState();
    }

    function checkGameState() internal requireHandActive(true) {  
         
        if (isPlayerActive[msg.sender] == true) {
            uint handPower = card2PowerConverter(playerCards[msg.sender]);
            if (handPower > 21) {  
                processHandEnd(false);
            }
            else if (handPower == 21) {  
                isPlayerActive[msg.sender] = false;
                dealerHit();
            }
            else if (handPower <21) {
                 
            }
        }
        else if (isPlayerActive[msg.sender] == false) {
            dealerHit();
        }

    }

    function dealerHit() internal requireHandActive(true) requirePlayerActive(false)  {  
        uint[] storage houseCardstemp = houseCards[msg.sender];
        uint[] storage playerCardstemp = playerCards[msg.sender];

        uint tempCard;
        while (card2PowerConverter(houseCardstemp) < 17) {  
             
            tempCard = randgen();
            if (blackJackHouseProhibited[msg.sender] != 0) {
                while (cardsPower[(tempCard + 13) % 13] == blackJackHouseProhibited[msg.sender]) {  
                    tempCard = randgen();
                }
                blackJackHouseProhibited[msg.sender] = 0;
                }
            houseCardstemp.push(tempCard);
        }
         
        if (card2PowerConverter(houseCardstemp) > 21 ) {
            processHandEnd(true);
        }
         
        if (card2PowerConverter(playerCardstemp) == card2PowerConverter(houseCardstemp)) {
             
            msg.sender.transfer(betAmount[msg.sender]);
            payoutAmount[msg.sender]=betAmount[msg.sender];
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false;  
        }
        else if (card2PowerConverter(playerCardstemp) > card2PowerConverter(houseCardstemp)) {
             
            processHandEnd(true);
        }
        else {
             
            processHandEnd(false);
        }
    }

    function processHandEnd(bool _win) internal {  
        if (_win == false) {
             
        }
        else if (_win == true) {
            uint winAmount = betAmount[msg.sender] * 2;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender]=winAmount;
        }
        gamestatus[msg.sender] = 5;
        isActive[msg.sender] = false;
    }


     

    function isBlackjack() internal {  
         
         
        blackJackHouseProhibited[msg.sender]=0;  
        bool houseIsBlackjack = false;
        bool playerIsBlackjack = false;
         
        uint housePower = card2PowerConverter(houseCards[msg.sender]);  
        if (housePower == 10 || housePower == 11) {
            uint _card = randgen();
            if (housePower == 10) {
                if (cardsPower[_card] == 11) {
                     
                    houseCards[msg.sender].push(_card);  
                    houseIsBlackjack = true;
                }
                else {
                    blackJackHouseProhibited[msg.sender]=uint(11);  
                }
            }
            else if (housePower == 11) {
                if (cardsPower[_card] == 10) {  
                     
                    houseCards[msg.sender].push(_card);   
                    houseIsBlackjack = true;
                }
                else{
                    blackJackHouseProhibited[msg.sender]=uint(10);  
                }

            }
        }
         
        uint playerPower = card2PowerConverter(playerCards[msg.sender]);
        if (playerPower == 21) {
            playerIsBlackjack = true;
        }
         
        if (playerIsBlackjack == false && houseIsBlackjack == false) {
             
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == false) {
             
            uint winAmount = betAmount[msg.sender] * 5/2;
            msg.sender.transfer(winAmount);
            payoutAmount[msg.sender] = betAmount[msg.sender] * 5/2;
            gamestatus[msg.sender] = 2;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == true && houseIsBlackjack == true) {
             
            uint winAmountPush = betAmount[msg.sender];
            msg.sender.transfer(winAmountPush);
            payoutAmount[msg.sender] = winAmountPush;
            gamestatus[msg.sender] = 4;
            isActive[msg.sender] = false;
        }
        else if (playerIsBlackjack == false && houseIsBlackjack == true) {
             
            gamestatus[msg.sender] = 3;
            isActive[msg.sender] = false;
        }
    }

    function readCards() external view returns(uint[],uint[]) {  
        return (playerCards[msg.sender],houseCards[msg.sender]);
    }

    function readPower() external view returns(uint, uint) {  
        return (card2PowerConverter(playerCards[msg.sender]),card2PowerConverter(houseCards[msg.sender]));
    }

    function donateEther() public payable {
         
    }

    function withdrawToOwnerCheck() internal {  
         
         
        uint houseBalance = address(this).balance;
        if (houseBalance > requiredHouseBankroll + autoWithdrawBuffer) {  
            uint permittedWithdraw = houseBalance - requiredHouseBankroll;  
            address _owner = owner();
            _owner.transfer(permittedWithdraw);
        }
    }
}