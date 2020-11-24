 

pragma solidity ^0.4.25;
 

 
 
 

 
 
 
 


 

 
 
contract Slaughter3D {
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
     
    uint256 constant private P3D_SHARE = 0.005 ether;
    
    uint8 constant public MAX_PLAYERS_PER_STAGE = 2;
    uint256 constant public OFFER_SIZE = 0.1 ether;
    uint256 public Refundpot;
    uint256 public Jackpot; 
    uint256 public SPASMfee; 
    mapping(address => uint256) public ETHtoP3Dbymasternode;  
    
    uint256 private p3dPerStage = P3D_SHARE * (MAX_PLAYERS_PER_STAGE - 1);
     
    uint256 public winningsPerRound = 0.185 ether;
    
    mapping(address => string) public Vanity;
    mapping(address => uint256) private playerVault;
    mapping(uint256 => Stage) public stages;
    mapping(uint256 => address) public RefundWaitingLine;
    mapping(uint256 => address) public Loser;
    uint256 public  NextInLine; 
    uint256 public  NextAtLineEnd; 
    uint256 private numberOfFinalizedStages;
    
    uint256 public numberOfStages;
    
    event JackpotWon(address indexed winner, uint256 SizeOfJackpot);
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
     
    
    function previousstagedata()
        public
        view
        returns(address loser , address player1, string van1 ,address player2, string van2 )
    {
        return (Loser[numberOfFinalizedStages],stages[numberOfFinalizedStages].slotXplayer[0],Vanity[stages[numberOfFinalizedStages].slotXplayer[0]],stages[numberOfFinalizedStages].slotXplayer[1],Vanity[stages[numberOfFinalizedStages].slotXplayer[1]]);
    }
    function currentstagedata()
        public
        view
        returns( address player1, string van1 ,address player2, string van2 )
    {
        return (stages[numberOfStages].slotXplayer[0],Vanity[stages[numberOfStages].slotXplayer[0]],stages[numberOfStages].slotXplayer[1],Vanity[stages[numberOfStages].slotXplayer[1]]);
    }
    function jackpotinfo()
        public
        view
        returns(uint256 SizeOfJackpot )
    {
        return (Jackpot);
    }
    function checkstatus()
        public
        view
        returns(bool CanStartBattle )
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
    function Refundlineinfo()
        public
        view
        returns(address NextAdresstoRefund, uint256 LengthUnpaidLine,uint256 divsunfetched, uint256 refundpot , string vanityofnexttoberefunded)
    {
        LengthUnpaidLine = NextAtLineEnd - NextInLine;
        uint256 dividends = p3dContract.myDividends(true);
        return (RefundWaitingLine[NextInLine],LengthUnpaidLine, dividends , Refundpot ,Vanity[RefundWaitingLine[NextInLine]]);
    }
     
    
     
    function Expand(address masternode) public 
    {
    uint256 amt = ETHtoP3Dbymasternode[masternode];
    ETHtoP3Dbymasternode[masternode] = 0;
    if(masternode == 0x0){masternode = 0x989eB9629225B8C06997eF0577CC08535fD789F9;} 
    p3dContract.buy.value(amt)(masternode);
    
    }
     
    function DivsToRefundpot ()public
    {
         
            uint256 dividends = p3dContract.myDividends(true);
            require(dividends > 0);
            uint256 base = dividends.div(100);
            p3dContract.withdraw();
            SPASM_.disburse.value(base)(); 
            Refundpot = Refundpot.add(base.mul(94));
            Jackpot = Jackpot.add(base.mul(5));  
             
    }
     
    function DonateToLosers ()public payable
    {
            require(msg.value > 0);
            Refundpot = Refundpot.add(msg.value);

    }
     
    function Payoutnextrefund ()public
    {
         
            uint256 Pot = Refundpot;
            require(Pot > 0.1 ether);
            Refundpot -= 0.1 ether;
            RefundWaitingLine[NextInLine].transfer(0.1 ether);
            NextInLine++;
             
    }
     
    function changevanity(string van , address masternode) public payable
    {
    require(msg.value >= 1  finney);
    Vanity[msg.sender] = van;
    uint256 amt = ETHtoP3Dbymasternode[masternode].add(msg.value);
    ETHtoP3Dbymasternode[masternode] = 0;
    if(masternode == 0x0){masternode = 0x989eB9629225B8C06997eF0577CC08535fD789F9;} 
    p3dContract.buy.value(amt)(masternode);
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
    }
    
    function() external payable {}
    
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
            uint256 jackpot = uint256(blockhash(stageToFinalize.blocknumber)) % 1000;
            address sacrifice = stageToFinalize.slotXplayer[sacrificeSlot];
            Loser[numberOfFinalizedStages] = sacrifice;
            emit SacrificeChosen(sacrifice);
            
             
            allocateSurvivorWinnings(sacrifice);
            
             
            if(jackpot == 777){
                sacrifice.transfer(Jackpot);
                emit JackpotWon ( sacrifice, Jackpot);
                Jackpot = 0;
            }
            
            
             
            RefundWaitingLine[NextAtLineEnd] = sacrifice;
            NextAtLineEnd++;
            
             
            ETHtoP3Dbymasternode[stageToFinalize.setMN[1]] = ETHtoP3Dbymasternode[stageToFinalize.setMN[1]].add(0.005 ether);
            ETHtoP3Dbymasternode[stageToFinalize.setMN[1]] = ETHtoP3Dbymasternode[stageToFinalize.setMN[2]].add(0.005 ether);
            
             
            Refundpot = Refundpot.add(0.005 ether);
             
             
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