 

pragma solidity ^0.4.25;

 
 
 
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

 
contract ProfitLineInc  {
    using SafeMath for uint;
     
    mapping(uint256 => address)public management; 
    mapping(uint256 => uint256)public manVault; 
     
    mapping(uint256 => uint256)public price;  
    uint256 public totalSupplyShares;  
    uint256 public ethPendingManagement;
    
     
    mapping(address => uint256)public  bondsOutstanding;  
    uint256 public totalSupplyBonds;  
    mapping(address => uint256)public  playerVault;  
    mapping(address => uint256)public  pendingFills;  
    mapping(address => uint256)public  playerId; 
    mapping(uint256 => address)public  IdToAdress; 
    uint256 public nextPlayerID;
    
     
    mapping(address => bool) public allowAutoInvest;
    mapping(address => uint256) public percentageToReinvest;
    
     
    uint256 ethPendingDistribution;  
    
     
    uint256 ethPendingLines;  
    
         
        mapping(uint256 => address) public cheatLine;
        mapping(address => bool) public isInLine;
        mapping(address => uint256) public lineNumber;
        uint256 public cheatLinePot;
        uint256 public nextInLine;
        uint256 public lastInLine;
         
        mapping(uint256 => address) public cheatLineWhale;
        mapping(address => bool) public isInLineWhale;
        mapping(address => uint256) public lineNumberWhale;
        uint256 public cheatLinePotWhale;
        uint256 public nextInLineWhale;
        uint256 public lastInLineWhale;
         
        uint256 public arbitragePot;
         
        uint256 public arbitragePotRisky;
         
        mapping(address => uint256) public odds;
        uint256 public poioPot; 
         
        mapping(address => uint256) public oddsWhale;
        uint256 public poioPotWhale;
         
        uint256 public oddsAll;
        uint256 public poioPotAll;
         
        uint256 public decreasingOddsAll;
        uint256 public podoPotAll;
         
        uint256 public randomPot;
        mapping(uint256 => address) public randomDistr;
        uint256 public randomNext;
        uint256 public lastdraw;
         
        uint256 public randomPotWhale;
        mapping(uint256 => address) public randomDistrWhale;
        uint256 public randomNextWhale;
        uint256 public lastdrawWhale;
         
        uint256 public randomPotAlways;
        mapping(uint256 => address) public randomDistrAlways;
        uint256 public randomNextAlways;
        uint256 public lastdrawAlways;
         
        uint256 public dicerollpot;
         
        uint256 public amountPlayed;
        uint256 public badOddsPot;
        
         
        uint256 public Snip3dPot;

         
        uint256 public Slaughter3dPot;
        
         
        uint256 public ethRollBank;
         
        uint256 public ethStuckOnPLinc;
        address public currentHelper;
        bool public canGetPaidForHelping;
        mapping(address => bool) public hassEthstuck;
         
        uint256 public PLincGiverOfEth;
         
        
         
        uint256 public vaultSmall;
        uint256 public timeSmall;
        uint256 public vaultMedium;
        uint256 public timeMedium;
        uint256 public vaultLarge;
        uint256 public timeLarge;
        uint256 public vaultDrip;  
        uint256 public timeDrip;
    
     
    HourglassInterface constant P3Dcontract_ = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe); 
    SPASMInterface constant SPASM_ = SPASMInterface(0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1); 
    Snip3DBridgeInterface constant snip3dBridge = Snip3DBridgeInterface(0x99352D1edfa7f124eC618dfb51014f6D54bAc4aE); 
    Slaughter3DBridgeInterface constant slaughter3dbridge = Slaughter3DBridgeInterface(0x3E752fFD5eff7b7f2715eF43D8339ecABd0e65b9); 
    
     
    uint256 public pointMultiplier = 10e18;
    struct Account {
        uint256 balance;
        uint256 lastDividendPoints;
        }
    mapping(address=>Account) accounts;
    
   
    uint256 public totalDividendPoints;
    uint256 public unclaimedDividends;

    function dividendsOwing(address account) public view returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(accounts[account].lastDividendPoints);
        return (bondsOutstanding[account] * newDividendPoints) / pointMultiplier;
    }
    function fetchdivs(address toupdate) public updateAccount(toupdate){}
    
    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        if(owing > 0) {
            
            unclaimedDividends = unclaimedDividends.sub(owing);
            pendingFills[account] = pendingFills[account].add(owing);
        }
        accounts[account].lastDividendPoints = totalDividendPoints;
        _;
        }
    function () external payable{}  
    function vaultToWallet(address toPay) public {
        require(playerVault[toPay] > 0);
        uint256 value = playerVault[toPay];
        playerVault[toPay] = 0;
        toPay.transfer(value);
        emit cashout(msg.sender,value);
    }
     
    function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.myDividends(true))  ;
    }
    
    function fetchDataMain()
        public
        view
        returns(uint256 _ethPendingDistribution, uint256 _ethPendingManagement, uint256 _ethPendingLines)
    {
        _ethPendingDistribution = ethPendingDistribution;
        _ethPendingManagement = ethPendingManagement;
        _ethPendingLines = ethPendingLines;
    }
    function fetchCheatLine()
        public
        view
        returns(address _1stInLine, address _2ndInLine, address _3rdInLine, uint256 _sizeOfPot)
    {
        _1stInLine = cheatLine[nextInLine-1];
        _2ndInLine = cheatLine[nextInLine-2];
        _3rdInLine = cheatLine[nextInLine-3];
        _sizeOfPot = cheatLinePot;
    }
    function fetchCheatLineWhale()
        public
        view
        returns(address _1stInLine2, address _2ndInLine2, address _3rdInLine2, uint256 _sizeOfPot2)
    {
        _1stInLine2 = cheatLineWhale[nextInLineWhale-1];
        _2ndInLine2 = cheatLineWhale[nextInLineWhale-2];
        _3rdInLine2 = cheatLineWhale[nextInLineWhale-3];
        _sizeOfPot2 = cheatLinePotWhale;
    }

     
    function buyCEO() public payable{
        uint256 value = msg.value;
        require(value >= price[0]); 
        playerVault[management[0]] += (manVault[0] .add(value.div(2)));
        manVault[0] = 0;
        emit CEOsold(management[0],msg.sender,value);
        management[0] = msg.sender;
        ethPendingDistribution = ethPendingDistribution.add(value.div(2));
        price[0] = price[0].mul(21).div(10);
    }
    function buyDirector(uint256 spot) public payable{
        uint256 value = msg.value;
        require(spot >0 && spot < 6);
        require(value >= price[spot]);
        playerVault[management[spot]] += (manVault[spot].add(value.div(2)));
        manVault[spot] = 0;
        emit Directorsold(management[spot],msg.sender,value, spot);
        management[spot] = msg.sender;
        ethPendingDistribution = ethPendingDistribution.add(value.div(4));
        playerVault[management[0]] = playerVault[management[0]].add(value.div(4));
        price[spot] = price[spot].mul(21).div(10);
    }
    function managementWithdraw(uint256 who) public{
        uint256 cash = manVault[who];
        require(who <6);
        require(cash>0);
        manVault[who] = 0; 
        management[who].transfer(cash);
        emit cashout(management[who],cash);
    }
     
    function ethPropagate() public{
        require(ethPendingDistribution>0 );
        uint256 base = ethPendingDistribution.div(50);
        ethPendingDistribution = 0;
         
        SPASM_.disburse.value(base)();
         
        ethPendingManagement = ethPendingManagement.add(base);
         
        uint256 amount = base.mul(5);
        totalDividendPoints = totalDividendPoints.add(amount.mul(pointMultiplier).div(totalSupplyBonds));
        unclaimedDividends = unclaimedDividends.add(amount);
        emit bondsMatured(amount);
         
        ethPendingLines = ethPendingLines.add(base.mul(43));
    }
     
    function buyBonds(address masternode, address referral)updateAccount(msg.sender) updateAccount(referral) payable public {
         
        uint256 value = msg.value;
        address sender = msg.sender;
        require(msg.value > 0 && referral != 0);
        uint256 base = value.div(100);
         
        P3Dcontract_.buy.value(base.mul(5))(masternode);
         
        uint256 amount =  value.mul(11).div(10);
        bondsOutstanding[sender] = bondsOutstanding[sender].add(amount);
        emit bondsBought(msg.sender,amount);
         
        bondsOutstanding[referral] = bondsOutstanding[referral].add(value.mul(2).div(100));
         
        totalSupplyBonds = totalSupplyBonds.add(amount.add(value.mul(2).div(100)));
         
        ethPendingDistribution = ethPendingDistribution.add(base.mul(95));
         
        if(playerId[sender] == 0){
           playerId[sender] = nextPlayerID;
           IdToAdress[nextPlayerID] = sender;
           nextPlayerID++;
        }
    }
     
    function ethManagementPropagate() public {
        require(ethPendingManagement > 0);
        uint256 base = ethPendingManagement.div(20);
        ethPendingManagement = 0;
        manVault[0] += base.mul(5); 
        manVault[1] += base.mul(5); 
        manVault[2] += base.mul(4);
        manVault[3] += base.mul(3);
        manVault[4] += base.mul(2);
        manVault[5] += base.mul(1); 
    }
     
    function fillBonds (address bondsOwner)updateAccount(msg.sender) updateAccount(bondsOwner) public {
        uint256 pendingz = pendingFills[bondsOwner];
        require(bondsOutstanding[bondsOwner] > 1000 && pendingz > 1000);
        require(msg.sender == tx.origin);
        require(pendingz <= bondsOutstanding[bondsOwner]);
         
        pendingFills[bondsOwner] = 0;
         
        bondsOutstanding[bondsOwner] = bondsOutstanding[bondsOwner].sub(pendingz);
         
        bondsOutstanding[msg.sender]= bondsOutstanding[msg.sender].add(pendingz.div(1000));
         
        totalSupplyBonds = totalSupplyBonds.sub(pendingz).add(pendingz.div(1000));
         
        playerVault[bondsOwner] = playerVault[bondsOwner].add(pendingz);
        emit bondsFilled(bondsOwner,pendingz);
    }
     
    function forceBonds (address bondsOwner,  address masternode)updateAccount(msg.sender) updateAccount(bondsOwner) public {
        require(bondsOutstanding[bondsOwner] > 1000 && pendingFills[bondsOwner] > 1000);
        require(pendingFills[bondsOwner] > bondsOutstanding[bondsOwner]);
         
        uint256 value = pendingFills[bondsOwner].sub(bondsOutstanding[bondsOwner]);
        
        pendingFills[bondsOwner] = pendingFills[bondsOwner].sub(bondsOutstanding[bondsOwner]);
        uint256 base = value.div(100);
         
        P3Dcontract_.buy.value(base.mul(5))(masternode);
         
        uint256 amount =  value.mul(11).div(10);
        bondsOutstanding[bondsOwner] += amount;
         
        bondsOutstanding[msg.sender] += value.mul(2).div(100);
         
        totalSupplyBonds += amount.add(value.mul(2).div(100));
         
        ethPendingDistribution += base.mul(95);
        emit bondsBought(bondsOwner, amount);
    }
     
    function setAuto (uint256 percentage) public {
        allowAutoInvest[msg.sender] = true;
        require(percentage <=100 && percentage > 0);
        percentageToReinvest[msg.sender] = percentage;
    }
    function disableAuto () public {
        allowAutoInvest[msg.sender] = false;
    }
    function freelanceReinvest(address stackOwner, address masternode)updateAccount(msg.sender) updateAccount(stackOwner) public{
        address sender = msg.sender;
        require(allowAutoInvest[stackOwner] == true && playerVault[stackOwner] > 100000);
        require(sender == tx.origin);
         
        uint256 value = playerVault[stackOwner];
         
        playerVault[stackOwner]=0;
        uint256 base = value.div(100000).mul(percentageToReinvest[stackOwner]);
         
        P3Dcontract_.buy.value(base.mul(50))(masternode);
         
         
        uint256 precalc = base.mul(950); 
        uint256 amount =  precalc.mul(109).div(100);
        bondsOutstanding[stackOwner] = bondsOutstanding[stackOwner].add(amount);
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(base);
         
        totalSupplyBonds = totalSupplyBonds.add(amount.add(base));
         
        ethPendingDistribution = ethPendingDistribution.add(precalc);
        if(percentageToReinvest[stackOwner] < 100)
        {
            precalc = value.sub(precalc.add(base.mul(50))); 
            stackOwner.transfer(precalc);
            
        }
        emit bondsBought(stackOwner, amount);
        
    }
    function PendinglinesToLines () public {
        require(ethPendingLines > 1000);
        
        uint256 base = ethPendingLines.div(25);
        ethPendingLines = 0;
         
        cheatLinePot = cheatLinePot.add(base);
         
        cheatLinePotWhale = cheatLinePotWhale.add(base);
         
        arbitragePot = arbitragePot.add(base);
         
        arbitragePotRisky = arbitragePotRisky.add(base);
         
        poioPot = poioPot.add(base);
         
        poioPotWhale = poioPotWhale.add(base);
         
        poioPotAll = poioPotAll.add(base);
         
        podoPotAll = podoPotAll.add(base);
         
        randomPot = randomPot.add(base);
         
        randomPotWhale = randomPotWhale.add(base);
         
        randomPotAlways = randomPotAlways.add(base);
         
        dicerollpot = dicerollpot.add(base);
         
        badOddsPot = badOddsPot.add(base);
        
         
        Snip3dPot = Snip3dPot.add(base);

         
        Slaughter3dPot = Slaughter3dPot.add(base);
        
         
        ethRollBank = ethRollBank.add(base);
         
        ethStuckOnPLinc = ethStuckOnPLinc.add(base);
         
        PLincGiverOfEth = PLincGiverOfEth.add(base);
        
         
        vaultSmall = vaultSmall.add(base);
         
        vaultMedium = vaultMedium.add(base);
         
        vaultLarge = vaultLarge.add(base);
         
        vaultDrip = vaultDrip.add(base.mul(4));
        
    }
    function fetchP3Ddivs() public{
         
            uint256 dividends =  harvestabledivs();
            require(dividends > 0);
            P3Dcontract_.withdraw();
            ethPendingDistribution = ethPendingDistribution.add(dividends);
    }
    
     
    function cheatTheLine () public payable updateAccount(msg.sender){
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= 0.01 ether);
        require(msg.sender == tx.origin);
        if(isInLine[sender] == true)
        {
             
            cheatLine[lineNumber[sender]] = cheatLine[lastInLine];
             
            cheatLine[nextInLine] = sender;
             
            nextInLine++;
            lastInLine++;
        }
        if(isInLine[sender] == false)
        {
             
            cheatLine[nextInLine] = sender;
             
            lineNumber[sender] = nextInLine;
             
            nextInLine++;
             
            isInLine[sender] = true;
        }

         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
        emit bondsBought(sender, value);
        
    }
    function payoutCheatLine () public {
         
        require(cheatLinePot >= 0.1 ether && nextInLine > 0);
        require(msg.sender == tx.origin);
         
        uint256 winner = nextInLine.sub(1);
         
        nextInLine--;
         
        cheatLinePot = cheatLinePot.sub(0.1 ether);
         
        pendingFills[cheatLine[winner]] = pendingFills[cheatLine[winner]].add(0.1 ether);
         
        isInLine[cheatLine[winner]] = false;
         
         
        emit won(cheatLine[winner], true, 0.1 ether, 1);
    }
    function cheatTheLineWhale () public payable updateAccount(msg.sender){
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= 1 ether);
        require(sender == tx.origin);
        if(isInLineWhale[sender] == true)
        {
             
            cheatLineWhale[lineNumberWhale[sender]] = cheatLineWhale[lastInLineWhale];
             
            cheatLineWhale[nextInLineWhale] = sender;
             
            nextInLineWhale++;
            lastInLineWhale++;
        }
        if(isInLineWhale[sender] == false)
        {
             
            cheatLineWhale[nextInLineWhale] = sender;
             
            lineNumberWhale[sender] = nextInLineWhale;
             
            nextInLineWhale++;
             
            isInLineWhale[sender] = true;
        }
        
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
    }
    function payoutCheatLineWhale () public {
         
        require(cheatLinePotWhale >= 10 ether && nextInLineWhale > 0);
        require(msg.sender == tx.origin);
         
        uint256 winner = nextInLineWhale.sub(1);
         
        nextInLineWhale--;
         
        cheatLinePotWhale = cheatLinePotWhale.sub(10 ether);
         
        pendingFills[cheatLineWhale[winner]] = pendingFills[cheatLineWhale[winner]].add(10 ether);
         
        isInLineWhale[cheatLineWhale[winner]] = false;
         
         
        emit won(cheatLineWhale[winner], true, 10 ether,2);
    }
    function takeArbitrageOpportunity () public payable updateAccount(msg.sender){
        uint256 opportunityCost = arbitragePot.div(100);
        require(msg.value > opportunityCost && opportunityCost > 1000);
        
        uint256 payout = opportunityCost.mul(101).div(100);
        arbitragePot = arbitragePot.sub(payout);
         
        uint256 value = msg.value;
        address sender = msg.sender;
        require(sender == tx.origin);
         
        pendingFills[sender] = pendingFills[sender].add(payout);
         
        
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
        
        emit won(sender, true, payout,3);
    }
    function takeArbitrageOpportunityRisky () public payable updateAccount(msg.sender){
        uint256 opportunityCost = arbitragePotRisky.div(5);
        require(msg.value > opportunityCost && opportunityCost > 1000);
        
        uint256 payout = opportunityCost.mul(101).div(100);
        arbitragePotRisky = arbitragePotRisky.sub(payout);
         
        uint256 value = msg.value;
        address sender = msg.sender;
        require(sender == tx.origin);
         
        pendingFills[sender] = pendingFills[sender].add(payout);
         
        
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
         
        emit won(sender, true, payout,4);
    }
    function playProofOfIncreasingOdds (uint256 plays) public payable updateAccount(msg.sender){
         
        
        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = odds[sender];
        uint256 oddzactual;
        require(sender == tx.origin);
        require(value >= plays.mul(0.1 ether));
        require(plays > 0);
        bool hasWon;
         
        for(uint i=0; i< plays; i++)
        {
            
            if(1000- oddz - i > 2){oddzactual = 1000- oddz - i;}
            if(1000- oddz - i <= 2){oddzactual =  2;}
            uint256 outcome = uint256(blockhash(block.number-1)) % (oddzactual);
            emit RNGgenerated(outcome);
            if(outcome == 1){
                 
                i = plays;
                 
                poioPot = poioPot.div(2);
                 
                pendingFills[sender] = pendingFills[sender].add(poioPot);
                 
                odds[sender] = 0;
                 
                hasWon = true;
                uint256 amount = poioPot;
            }
        }
        odds[sender] += i;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
         
        emit won(sender, hasWon, amount,5);
        
    }
    function playProofOfIncreasingOddsWhale (uint256 plays) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = oddsWhale[sender];
        uint256 oddzactual;
        require(sender == tx.origin);
        require(value >= plays.mul(10 ether));
        require(plays > 0);
        bool hasWon;
         
        for(uint i=0; i< plays; i++)
        {
            
            if(1000- oddz - i > 2){oddzactual = 1000- oddz - i;}
            if(1000- oddz - i <= 2){oddzactual =  2;}
            uint256 outcome = uint256(blockhash(block.number-1)) % (oddzactual);
            emit RNGgenerated(outcome);
            if(outcome == 1){
                 
                i = plays;
                 
                poioPotWhale = poioPotWhale.div(2);
                 
                pendingFills[sender] = pendingFills[sender].add(poioPotWhale);
                 
                oddsWhale[sender] = 0;
                 
                hasWon = true;
                uint256 amount = poioPotWhale;
            }
        }
        oddsWhale[sender] += i;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
         
        emit won(sender, hasWon, amount,6);
    }
    function playProofOfIncreasingOddsALL (uint256 plays) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = oddsAll;
        uint256 oddzactual;
        require(sender == tx.origin);
        require(value >= plays.mul(0.1 ether));
        require(plays > 0);
        bool hasWon;
         
        for(uint i=0; i< plays; i++)
        {
            
            if(1000- oddz - i > 2){oddzactual = 1000- oddz - i;}
            if(1000- oddz - i <= 2){oddzactual =  2;}
            uint256 outcome = uint256(blockhash(block.number-1)) % (oddzactual);
            emit RNGgenerated(outcome);
            if(outcome == 1){
                 
                i = plays;
                 
                poioPotAll = poioPotAll.div(2);
                 
                pendingFills[sender] = pendingFills[sender].add(poioPotAll);
                 
                odds[sender] = 0;
                 
                hasWon = true;
                uint256 amount = poioPotAll;
            }
        }
        oddsAll += i;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        emit won(sender, hasWon, amount,7);
    }
    function playProofOfDecreasingOddsALL (uint256 plays) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = decreasingOddsAll;
        uint256 oddzactual;
        require(sender == tx.origin);
        require(value >= plays.mul(0.1 ether));
        require(plays > 0);
        bool hasWon;
         
        for(uint i=0; i< plays; i++)
        {
            
            oddzactual = oddz + i;
            uint256 outcome = uint256(blockhash(block.number-1)).add(now) % (oddzactual);
            emit RNGgenerated(outcome);
            if(outcome == 1){
                 
                i = plays;
                 
                podoPotAll = podoPotAll.div(2);
                 
                pendingFills[sender] = pendingFills[sender].add(podoPotAll);
                 
                decreasingOddsAll = 10;
                 
                hasWon = true;
                uint256 amount = podoPotAll;
            }
        }
        decreasingOddsAll += i;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        emit won(sender, hasWon, amount,8);
    }
    function playRandomDistribution (uint256 plays) public payable updateAccount(msg.sender){
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= plays.mul(0.01 ether));
        require(plays > 0);
        uint256 spot;
         for(uint i=0; i< plays; i++)
        {
             
            spot = randomNext + i;
            randomDistr[spot] = sender;
        }
         
        randomNext = randomNext + i;
        
        
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
       
    }
    function payoutRandomDistr () public {
         
        address sender = msg.sender;
        require(randomPot >= 0.1 ether && randomNext > 0 && lastdraw != block.number);
        require(sender == tx.origin);
         
        uint256 outcome = uint256(blockhash(block.number-1)).add(now) % (randomNext);
        emit RNGgenerated(outcome);
         
        randomPot = randomPot.sub(0.1 ether);
         
        pendingFills[randomDistr[outcome]] = pendingFills[randomDistr[outcome]].add(0.1 ether);
         
         
        randomDistr[outcome] = randomDistr[randomNext-1];
         
        randomNext--;
         
        lastdraw = block.number;
         
        emit won(randomDistr[outcome], true, 0.1 ether,9);
    }
    function playRandomDistributionWhale (uint256 plays) public payable updateAccount(msg.sender){
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= plays.mul(1 ether));
        require(plays > 0);
        uint256 spot;
         for(uint i=0; i< plays; i++)
        {
             
            spot = randomNextWhale + i;
            randomDistrWhale[spot] = sender;
        }
         
        randomNextWhale = randomNextWhale + i;
        
        
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        
    }
    function payoutRandomDistrWhale () public {
         
        require(randomPotWhale >= 10 ether && randomNextWhale > 0 && lastdrawWhale != block.number);
        require(msg.sender == tx.origin);
         
        uint256 outcome = uint256(blockhash(block.number-1)).add(now) % (randomNextWhale);
        emit RNGgenerated(outcome);
         
        randomPotWhale = randomPotWhale.sub(10 ether);
         
         
        pendingFills[randomDistrWhale[outcome]] = pendingFills[randomDistrWhale[outcome]].add(10 ether);
         
        randomDistrWhale[outcome] = randomDistrWhale[randomNext-1];
         
        randomNextWhale--;
         
        lastdrawWhale = block.number;
         
        emit won(randomDistrWhale[outcome], true, 10 ether,10);
    }
    function playRandomDistributionAlways (uint256 plays) public payable updateAccount(msg.sender){
        address sender = msg.sender;
        uint256 value = msg.value;
        require(value >= plays.mul(0.1 ether));
        require(plays > 0);
        uint256 spot;
         for(uint i=0; i< plays; i++)
        {
             
            spot = randomNextAlways + i;
            randomDistrAlways[spot] = sender;
        }
         
        randomNextAlways = randomNextAlways + i;
        
        
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
    }
    function payoutRandomDistrAlways () public {
         
        require(msg.sender == tx.origin);
        require(randomPotAlways >= 1 ether && randomNextAlways > 0 && lastdrawAlways != block.number);
         
        uint256 outcome = uint256(blockhash(block.number-1)).add(now) % (randomNextAlways);
        emit RNGgenerated(outcome);
         
        randomPotAlways = randomPotAlways.sub(1 ether);
         
         
        pendingFills[randomDistrAlways[outcome]] = pendingFills[randomDistrAlways[outcome]].add(1 ether);
         
        lastdraw = block.number;
         
        emit won(randomDistrAlways[outcome], true, 1 ether,11);
    }
    function playProofOfRediculousBadOdds (uint256 plays) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = amountPlayed;
        uint256 oddzactual;
        require(sender == tx.origin);
        require(value >= plays.mul(0.0001 ether));
        require(plays > 0);
        bool hasWon;
         
        for(uint i=0; i< plays; i++)
        {
            oddzactual =  oddz.add(1000000).add(i);
            uint256 outcome = uint256(blockhash(block.number-1)).add(now) % (oddzactual);
            emit RNGgenerated(outcome);
            if(outcome == 1){
                 
                i = plays;
                 
                badOddsPot = badOddsPot.div(2);
                 
                pendingFills[sender] = pendingFills[sender].add(badOddsPot);
                 
                 hasWon = true;
                uint256 amount = badOddsPot;
            }
        }
        amountPlayed += i;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        emit won(sender, hasWon, amount,12);
    }
    function playProofOfDiceRolls (uint256 oddsTaken) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = amountPlayed;
        uint256 possiblewin = value.mul(100).div(oddsTaken);
        require(sender == tx.origin);
        require(dicerollpot >= possiblewin);
        require(oddsTaken > 0 && oddsTaken < 100);
        bool hasWon;
         
       
            uint256 outcome = uint256(blockhash(block.number-1)).add(now).add(oddz) % (100);
            emit RNGgenerated(outcome);
            if(outcome < oddsTaken){
                 
                dicerollpot = dicerollpot.sub(possiblewin);
               pendingFills[sender] = pendingFills[sender].add(possiblewin);
                 
                hasWon = true;
                uint256 amount = possiblewin;
            }
        
        amountPlayed ++;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        emit won(sender, hasWon, amount,13);
    }
    function playProofOfEthRolls (uint256 oddsTaken) public payable updateAccount(msg.sender){
         

        address sender  = msg.sender;
        uint256 value = msg.value;
        uint256 oddz = amountPlayed;
        uint256 possiblewin = value.mul(100).div(oddsTaken);
        require(sender == tx.origin);
        require(ethRollBank >= possiblewin);
        require(oddsTaken > 0 && oddsTaken < 100);
        bool hasWon;
         
       
            uint256 outcome = uint256(blockhash(block.number-1)).add(now).add(oddz) % (100);
            emit RNGgenerated(outcome);
            if(outcome < oddsTaken){
                 
                ethRollBank = ethRollBank.sub(possiblewin);
               pendingFills[sender] = pendingFills[sender].add(possiblewin);
                
                hasWon = true;
                uint256 amount = possiblewin;
            }
        
        amountPlayed ++;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value.div(100));
         
        ethRollBank = ethRollBank.add(value.div(100).mul(99));
        
        emit won(sender, hasWon, amount,14);
    }
    function helpUnstuckEth()public payable updateAccount(msg.sender){
        uint256 value = msg.value;
        address sender  = msg.sender;
        require(sender == tx.origin);
        require(value >= 2 finney);
        hassEthstuck[currentHelper] = true;
        canGetPaidForHelping = true;
        currentHelper = msg.sender;
        hassEthstuck[currentHelper] = false;
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
        
    }
    function transferEthToHelper()public{
        
        address sender  = msg.sender;
        require(sender == tx.origin);
        require(hassEthstuck[sender] == true && canGetPaidForHelping == true);
        require(ethStuckOnPLinc > 4 finney);
        hassEthstuck[sender] = false;
        canGetPaidForHelping = false;
        ethStuckOnPLinc = ethStuckOnPLinc.sub(4 finney);
        pendingFills[currentHelper] = pendingFills[currentHelper].add(4 finney) ;
         
        emit won(currentHelper, true, 4 finney,15);
    }
    function begForFreeEth () public payable updateAccount(msg.sender){
         address sender  = msg.sender;
         uint256 value = msg.value;
        require(sender == tx.origin);
        
        require(value >= 0.1 ether );
        bool hasWon;
        if(PLincGiverOfEth >= 0.101 ether)
        {
            PLincGiverOfEth = PLincGiverOfEth.sub(0.1 ether);
            pendingFills[sender] = pendingFills[sender].add( 0.101 ether) ;
             
            hasWon = true;
        }
         
        bondsOutstanding[sender] = bondsOutstanding[sender].add(value);
         
        totalSupplyBonds = totalSupplyBonds.add(value);
         
        ethPendingDistribution = ethPendingDistribution.add(value);
         
        emit won(sender, hasWon, 0.101 ether,16);
    }
    function releaseVaultSmall () public {
         
        uint256 vaultSize = vaultSmall;
        require(timeSmall + 24 hours < now || vaultSize > 10 ether);
         
        timeSmall = now;
         
        vaultSmall = 0;
         
        ethPendingDistribution = ethPendingDistribution.add(vaultSize);
    }
    function releaseVaultMedium () public {
         
        uint256 vaultSize = vaultMedium;
        require(timeMedium + 168 hours < now || vaultSize > 100 ether);
         
        timeMedium = now;
         
        vaultMedium = 0;
         
        ethPendingDistribution = ethPendingDistribution.add(vaultSize);
    }
    function releaseVaultLarge () public {
         
        uint256 vaultSize = vaultLarge;
        require(timeLarge + 720 hours < now || vaultSize > 1000 ether);
         
        timeLarge = now;
         
        vaultLarge = 0;
         
        ethPendingDistribution = ethPendingDistribution.add(vaultSize);
    }
    function releaseDrip () public {
         
        uint256 vaultSize = vaultDrip;
        require(timeDrip + 24 hours < now);
         
        timeDrip = now;
        uint256 value = vaultSize.div(100);
         
        vaultDrip = vaultDrip.sub(value);
         
        totalDividendPoints = totalDividendPoints.add(value);
        unclaimedDividends = unclaimedDividends.add(value);
        emit bondsMatured(value);
    }

    constructor()
        public
    {
        management[0] = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
        management[1] = 0x58E90F6e19563CE82C4A0010CEcE699B3e1a6723;
        management[2] = 0xf1A7b8b3d6A69C30883b2a3fB023593d9bB4C81E;
        management[3] = 0x2615A4447515D97640E43ccbbF47E003F55eB18C;
        management[4] = 0xD74B96994Ef8a35Fc2dA61c5687C217ab527e8bE;
        management[5] = 0x2F145AA0a439Fa15e02415e035aaF9fDbDeCaBD5;
        price[0] = 100 ether;
        price[1] = 25 ether;
        price[2] = 20 ether;
        price[3] = 15 ether;
        price[4] = 10 ether;
        price[5] = 5 ether;
        
        bondsOutstanding[0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220]= 100 finney;
        totalSupplyBonds = 100 finney;
        decreasingOddsAll = 10;
        
        timeSmall = now;
        timeMedium = now;
        timeLarge = now;
        timeDrip = now;
    }
    
     
    function soldierBuy () public {
        require(Snip3dPot > 0.1 ether);
        uint256 temp = Snip3dPot;
        Snip3dPot = 0;
        snip3dBridge.sacUp.value(temp)();
    }
    function snip3dVaultToPLinc() public { 
        uint256 incoming = snip3dBridge.harvestableBalance();
        snip3dBridge.fetchBalance();
        ethPendingDistribution = ethPendingDistribution.add(incoming);
    }
     
    
    function sendButcher() public{
        require(Slaughter3dPot > 0.1 ether);
        uint256 temp = Slaughter3dPot;
        Slaughter3dPot = 0;
        slaughter3dbridge.sacUp.value(temp)();
    }
    function slaughter3dbridgeToPLinc() public {
        uint256 incoming = slaughter3dbridge.harvestableBalance();
        slaughter3dbridge.fetchBalance();
        ethPendingDistribution = ethPendingDistribution.add(incoming);
    }
 
 
    event bondsBought(address indexed player, uint256 indexed bonds);
    event bondsFilled(address indexed player, uint256 indexed bonds);
    event CEOsold(address indexed previousOwner, address indexed newOwner, uint256 indexed price);
    event Directorsold(address indexed previousOwner, address indexed newOwner, uint256 indexed price, uint256 spot);
    event cashout(address indexed player , uint256 indexed ethAmount);
    event bondsMatured(uint256 indexed amount);
    event RNGgenerated(uint256 indexed number);
    event won(address player, bool haswon, uint256 amount ,uint256 line);

}
interface HourglassInterface  {
    function () payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);

}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}

interface Snip3DBridgeInterface  {
    function harvestableBalance()
        view
        external
        returns(uint256)
    ;
    function sacUp () external payable ;
    function fetchBalance ()  external ;
    
}
interface Slaughter3DBridgeInterface{
    function harvestableBalance()
        view
        external
        returns(uint256)
    ;
    function sacUp () external payable ;
    function fetchBalance ()  external ;
}