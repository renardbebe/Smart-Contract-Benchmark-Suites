 

pragma solidity ^0.4.25;
 
 

 

 
 

 
 

 
 

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract Slaughter3D is Owned {
    using SafeMath for uint;
    struct Stage {
        uint8 numberOfPlayers;
        uint256 blocknumber;
        bool finalized;
        mapping (uint8 => address) slotXplayer;
        mapping (address => bool) players;
        mapping (uint8 => address) setMN;
        
    }
    
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    SPASMInterface constant SPASM_ = SPASMInterface(0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1); 
    Slaughter3DInterface constant old = Slaughter3DInterface(0xA76daa02C1A6411c6c368f3A59f4f2257a460006);
     
    uint256 constant private P3D_SHARE = 0.005 ether;
    
    uint8 constant public MAX_PLAYERS_PER_STAGE = 2;
    uint256 constant public OFFER_SIZE = 0.1 ether;
    uint256 public Refundpot;
    
    uint256 private p3dPerStage = P3D_SHARE * (MAX_PLAYERS_PER_STAGE - 1);
     
    uint256 public winningsPerRound = 0.185 ether;
    
    mapping(address => uint256) public playerVault;
    mapping(uint256 => Stage) public stages;
    mapping(uint256 => address) public RefundWaitingLine;
    mapping(uint256 => address) public Loser;
    uint256 public  NextInLine; 
    uint256 public  NextAtLineEnd; 
    uint256 private numberOfFinalizedStages;
    
    uint256 public numberOfStages;
    
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
    
    uint256 public NextInLineOld;
    uint256 public lastToPayOld;
     
    function previousstageloser()
        public
        view
        returns(address)
    {
        return (Loser[numberOfFinalizedStages]);
    }
    function previousstageplayer1()
        public
        view
        returns(address)
    {
        return (stages[numberOfFinalizedStages].slotXplayer[0]);
    }
    function previousstageplayer2()
        public
        view
        returns(address)
    {
        return (stages[numberOfFinalizedStages].slotXplayer[1]);
    }
    function currentstageplayer1()
        public
        view
        returns( address )
    {
        return (stages[numberOfStages].slotXplayer[0]);
    }
    function currentstageplayer2()
        public
        view
        returns( address )
    {
        return (stages[numberOfStages].slotXplayer[1]);
    }

    function checkstatus() 
        public
        view
        returns(bool )
    {
        bool check;
        if(numberOfStages >= numberOfFinalizedStages)
        {
            if(!stages[numberOfFinalizedStages].finalized && stages[numberOfFinalizedStages].numberOfPlayers < MAX_PLAYERS_PER_STAGE && stages[numberOfFinalizedStages].blocknumber != 0)
            {
                check = true;
            }
        }
        return (check);
    }
    
    function nextonetogetpaid()
        public
        view
        returns(address)
    {
        
        return (RefundWaitingLine[NextInLine]);
    }
   function contractownsthismanyP3D()
        public
        view
        returns(uint256)
    {
        return (p3dContract.balanceOf(address(this)));
    }
     
     
    uint256 public pointMultiplier = 10e18;
struct Account {
  uint balance;
  uint lastDividendPoints;
}
mapping(address => uint256) public balances;
uint256 public _totalSupply;
mapping(address=>Account) public accounts;
uint public ethtotalSupply;
uint public totalDividendPoints;
uint public unclaimedDividends;

function dividendsOwing(address account) public view returns(uint256) {
  uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoints);
  return (balances[account] * newDividendPoints) / pointMultiplier;
}
modifier updateAccount(address account) {
  uint256 owing = dividendsOwing(account);
  if(owing > balances[account]){balances[account] = owing;}
  if(owing > 0 ) {
    unclaimedDividends = unclaimedDividends.sub(owing);
    
    playerVault[account] = playerVault[account].add(owing);
    balances[account] = balances[account].sub(owing);
    _totalSupply = _totalSupply.sub(owing);
  }
  accounts[account].lastDividendPoints = totalDividendPoints;
  _;
}
function () external payable{}
function fetchdivs(address toUpdate) public updateAccount(toUpdate){}

function disburse() public  payable {
    uint256 amount = msg.value;
    
  totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
   
 unclaimedDividends = unclaimedDividends.add(amount);
}

     
    function DivsToRefundpot ()public
    {
         
            uint256 dividends = p3dContract.myDividends(true);
            require(dividends > 0);
            uint256 base = dividends.div(100);
            p3dContract.withdraw();
            SPASM_.disburse.value(base.mul(5)); 
            Refundpot = Refundpot.add(base.mul(95));
            
    }
     
    function DonateToLosers ()public payable
    {
            require(msg.value > 0);
            Refundpot = Refundpot.add(msg.value);

    }
     
    function legacyStart(uint256 amountProgress) onlyOwner public{
        uint256 nextUp = NextInLineOld;
        for(uint i=0; i< amountProgress; i++)
        {
        address torefund = old.RefundWaitingLine(nextUp + i);
        i++;
        balances[torefund] = balances[torefund].add(0.1 ether);
        }
        NextInLineOld += i;
        _totalSupply = _totalSupply.add(i.mul(0.1 ether));
    }
     
    function Payoutnextrefund ()public
    {
         
        require(Refundpot > 0.00001 ether);
        uint256 amount = Refundpot;
    Refundpot = 0;
    totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(_totalSupply));
    unclaimedDividends = unclaimedDividends.add(amount);
    }
    
     
    modifier isValidOffer()
    {
        require(msg.value == OFFER_SIZE);
        _;
    }
    
    modifier canPayFromVault()
    {
        require(playerVault[msg.sender] >= OFFER_SIZE);
        _;
    }
    
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    modifier prepareStage()
    {
         
        if(stages[numberOfStages - 1].numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
           stages[numberOfStages] = Stage(0, 0, false );
           numberOfStages++;
        }
        _;
    }
    
    modifier isNewToStage()
    {
        require(stages[numberOfStages - 1].players[msg.sender] == false);
        _;
    }
    
    constructor()
        public
    {
        stages[numberOfStages] = Stage(0, 0, false);
        numberOfStages++;
        NextInLineOld = old.NextInLine();
        lastToPayOld = 525;
    }
    
     
    
    function offerAsSacrifice(address MN)
        external
        payable
        isValidOffer
        prepareStage
        isNewToStage
    {
        acceptOffer(MN);
        
         
        tryFinalizeStage();
    }
    
    function offerAsSacrificeFromVault(address MN)
        external
        canPayFromVault
        prepareStage
        isNewToStage
    {
        playerVault[msg.sender] -= OFFER_SIZE;
        
        acceptOffer(MN);
        
        tryFinalizeStage();
    }
    function offerAsSacrificeFromVaultForce(address MN, address forcedToFight)
        external
        payable
        prepareStage
        
    {
        uint256 value = msg.value;
        require(value >= 0.005 ether);
        require(playerVault[forcedToFight] >= OFFER_SIZE);
        require(stages[numberOfStages - 1].players[forcedToFight] == false);
        playerVault[forcedToFight] -= OFFER_SIZE;
        playerVault[forcedToFight] += 0.003 ether;
         
        Stage storage currentStage = stages[numberOfStages - 1];
        
        assert(currentStage.numberOfPlayers < MAX_PLAYERS_PER_STAGE);
        
        address player = forcedToFight;
        
         
        currentStage.slotXplayer[currentStage.numberOfPlayers] = player;
        currentStage.numberOfPlayers++;
        currentStage.players[player] = true;
        currentStage.setMN[currentStage.numberOfPlayers] = MN;
        emit SacrificeOffered(player);
        
         
        if(currentStage.numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
            currentStage.blocknumber = block.number;
        }
         
        tryFinalizeStage();
        SPASM_.disburse.value(0.002 ether);

    }
    function withdraw()
        external
        hasEarnings
    {
        tryFinalizeStage();
        
        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;
        
        emit EarningsWithdrawn(msg.sender, amount); 
        
        msg.sender.transfer(amount);
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function currentPlayers()
        external
        view
        returns(uint256)
    {
        return stages[numberOfStages - 1].numberOfPlayers;
    }
    
    function acceptOffer(address MN)
        private
    {
        Stage storage currentStage = stages[numberOfStages - 1];
        
        assert(currentStage.numberOfPlayers < MAX_PLAYERS_PER_STAGE);
        
        address player = msg.sender;
        
         
        currentStage.slotXplayer[currentStage.numberOfPlayers] = player;
        currentStage.numberOfPlayers++;
        currentStage.players[player] = true;
        currentStage.setMN[currentStage.numberOfPlayers] = MN;
        emit SacrificeOffered(player);
        
         
        if(currentStage.numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
            currentStage.blocknumber = block.number;
        }
        
    }
    
    function tryFinalizeStage()
        public
    {
        assert(numberOfStages >= numberOfFinalizedStages);
        
         
        if(numberOfStages == numberOfFinalizedStages) {return;}
        
        Stage storage stageToFinalize = stages[numberOfFinalizedStages];
        
        assert(!stageToFinalize.finalized);
        
         
        if(stageToFinalize.numberOfPlayers < MAX_PLAYERS_PER_STAGE) {return;}
        
        assert(stageToFinalize.blocknumber != 0);
        
         
        if(block.number - 256 <= stageToFinalize.blocknumber) {
             
            if(block.number == stageToFinalize.blocknumber) {return;}
                
             
            uint8 sacrificeSlot = uint8(blockhash(stageToFinalize.blocknumber)) % MAX_PLAYERS_PER_STAGE;
           
            address sacrifice = stageToFinalize.slotXplayer[sacrificeSlot];
            Loser[numberOfFinalizedStages] = sacrifice;
            emit SacrificeChosen(sacrifice);
            
             
            allocateSurvivorWinnings(sacrifice);
           
             
            fetchdivs(sacrifice);
            balances[sacrifice] = balances[sacrifice].add(0.1 ether);
            _totalSupply += 0.1 ether;
            
            
             
            Refundpot = Refundpot.add(0.005 ether);
             
            p3dContract.buy.value(0.004 ether)(stageToFinalize.setMN[1]);
            p3dContract.buy.value(0.004 ether)(stageToFinalize.setMN[2]);
            SPASM_.disburse.value(0.002 ether);
            
        } else {
            invalidateStage(numberOfFinalizedStages);
            
            emit StageInvalidated(numberOfFinalizedStages);
        }
         
        stageToFinalize.finalized = true;
        numberOfFinalizedStages++;
    }
    
    function allocateSurvivorWinnings(address sacrifice)
        private
    {
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address survivor = stages[numberOfFinalizedStages].slotXplayer[i];
            if(survivor != sacrifice) {
                playerVault[survivor] += winningsPerRound;
            }
        }
    }
    
    function invalidateStage(uint256 stageIndex)
        private
    {
        Stage storage stageToInvalidate = stages[stageIndex];
        
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address player = stageToInvalidate.slotXplayer[i];
            playerVault[player] += OFFER_SIZE;
        }
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}
interface Slaughter3DInterface {
    function RefundWaitingLine(uint256 index) external view returns(address);
    function NextInLine() external view returns(uint256);
    function NextAtLineEnd() external view returns(uint256);
}
 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}