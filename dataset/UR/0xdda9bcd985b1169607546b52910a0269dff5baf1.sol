 

pragma solidity ^0.4.0;

interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 

contract Goo is ERC20 {
    
    string public constant name  = "IdleEth";
    string public constant symbol = "Goo";
    uint8 public constant decimals = 0;
    uint256 private roughSupply;
    uint256 public totalGooProduction;
    address public owner;  
    bool public gameStarted;
    
    uint256 public totalEtherGooResearchPool;  
    uint256[] public totalGooProductionSnapshots;  
    uint256[] public allocatedGooResearchSnapshots;  
    uint256 public nextSnapshotTime;
    
    uint256 private MAX_PRODUCTION_UNITS = 999;  
    uint256 private constant RAFFLE_TICKET_BASE_GOO_PRICE = 1000;
    
     
    mapping(address => uint256) private ethBalance;
    mapping(address => uint256) private gooBalance;
    mapping(address => mapping(uint256 => uint256)) private gooProductionSnapshots;  
    mapping(address => mapping(uint256 => bool)) private gooProductionZeroedSnapshots;  
    
    mapping(address => uint256) private lastGooSaveTime;  
    mapping(address => uint256) public lastGooProductionUpdate;  
    mapping(address => uint256) private lastGooResearchFundClaim;  
    mapping(address => uint256) private battleCooldown;  
    
     
    mapping(address => mapping(uint256 => uint256)) private unitsOwned;
    mapping(address => mapping(uint256 => bool)) private upgradesOwned;
    mapping(uint256 => address) private rareItemOwner;
    mapping(uint256 => uint256) private rareItemPrice;
    
     
    mapping(address => mapping(uint256 => uint256)) private unitGooProductionIncreases;  
    mapping(address => mapping(uint256 => uint256)) private unitGooProductionMultiplier;  
    mapping(address => mapping(uint256 => uint256)) private unitAttackIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitAttackMultiplier;
    mapping(address => mapping(uint256 => uint256)) private unitDefenseIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitDefenseMultiplier;
    mapping(address => mapping(uint256 => uint256)) private unitGooStealingIncreases;
    mapping(address => mapping(uint256 => uint256)) private unitGooStealingMultiplier;
    
     
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => bool) private protectedAddresses;  
    
     
    struct TicketPurchases {
        TicketPurchase[] ticketsBought;
        uint256 numPurchases;  
        uint256 raffleRareId;
    }
    
     
    struct TicketPurchase {
        uint256 startId;
        uint256 endId;
    }
    
     
    mapping(address => TicketPurchases) private ticketsBoughtByPlayer;
    mapping(uint256 => address[]) private rafflePlayers;  

     
    uint256 private raffleEndTime;
    uint256 private raffleRareId;
    uint256 private raffleTicketsBought;
    address private raffleWinner;  
    bool private raffleWinningTicketSelected;
    uint256 private raffleTicketThatWon;
    
     
    event UnitBought(address player, uint256 unitId, uint256 amount);
    event UnitSold(address player, uint256 unitId, uint256 amount);
    event PlayerAttacked(address attacker, address target, bool success, uint256 gooStolen);
    
    GooGameConfig schema;
    
     
    function Goo() public payable {
        owner = msg.sender;
        schema = GooGameConfig(0x21912e81d7eff8bff895302b45da76f7f070e3b9);
    }
    
    function() payable { }
    
    function beginGame(uint256 firstDivsTime) external payable {
        require(msg.sender == owner);
        require(!gameStarted);
        
        gameStarted = true;  
        nextSnapshotTime = firstDivsTime;
        totalEtherGooResearchPool = msg.value;  
    }
    
    function totalSupply() public constant returns(uint256) {
        return roughSupply;  
    }
    
    function balanceOf(address player) public constant returns(uint256) {
        return gooBalance[player] + balanceOfUnclaimedGoo(player);
    }
    
    function balanceOfUnclaimedGoo(address player) internal constant returns (uint256) {
        if (lastGooSaveTime[player] > 0 && lastGooSaveTime[player] < block.timestamp) {
            return (getGooProduction(player) * (block.timestamp - lastGooSaveTime[player]));
        }
        return 0;
    }
    
    function etherBalanceOf(address player) public constant returns(uint256) {
        return ethBalance[player];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        updatePlayersGoo(msg.sender);
        require(amount <= gooBalance[msg.sender]);
        
        gooBalance[msg.sender] -= amount;
        gooBalance[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address player, address recipient, uint256 amount) public returns (bool) {
        updatePlayersGoo(player);
        require(amount <= allowed[player][msg.sender] && amount <= gooBalance[msg.sender]);
        
        gooBalance[player] -= amount;
        gooBalance[recipient] += amount;
        allowed[player][msg.sender] -= amount;
        
        emit Transfer(player, recipient, amount);
        return true;
    }
    
    function approve(address approvee, uint256 amount) public returns (bool){
        allowed[msg.sender][approvee] = amount;
        emit Approval(msg.sender, approvee, amount);
        return true;
    }
    
    function allowance(address player, address approvee) public constant returns(uint256){
        return allowed[player][approvee];
    }
    
    function getGooProduction(address player) public constant returns (uint256){
        return gooProductionSnapshots[player][lastGooProductionUpdate[player]];
    }
    
    function updatePlayersGoo(address player) internal {
        uint256 gooGain = balanceOfUnclaimedGoo(player);
        lastGooSaveTime[player] = block.timestamp;
        roughSupply += gooGain;
        gooBalance[player] += gooGain;
    }
    
    function updatePlayersGooFromPurchase(address player, uint256 purchaseCost) internal {
        uint256 unclaimedGoo = balanceOfUnclaimedGoo(player);
        
        if (purchaseCost > unclaimedGoo) {
            uint256 gooDecrease = purchaseCost - unclaimedGoo;
            roughSupply -= gooDecrease;
            gooBalance[player] -= gooDecrease;
        } else {
            uint256 gooGain = unclaimedGoo - purchaseCost;
            roughSupply += gooGain;
            gooBalance[player] += gooGain;
        }
        
        lastGooSaveTime[player] = block.timestamp;
    }
    
    function increasePlayersGooProduction(uint256 increase) internal {
        gooProductionSnapshots[msg.sender][allocatedGooResearchSnapshots.length] = getGooProduction(msg.sender) + increase;
        lastGooProductionUpdate[msg.sender] = allocatedGooResearchSnapshots.length;
        totalGooProduction += increase;
    }
    
    function reducePlayersGooProduction(address player, uint256 decrease) internal {
        uint256 previousProduction = getGooProduction(player);
        uint256 newProduction = SafeMath.sub(previousProduction, decrease);
        
        if (newProduction == 0) {  
            gooProductionZeroedSnapshots[player][allocatedGooResearchSnapshots.length] = true;
            delete gooProductionSnapshots[player][allocatedGooResearchSnapshots.length];  
        } else {
            gooProductionSnapshots[player][allocatedGooResearchSnapshots.length] = newProduction;
        }
        
        lastGooProductionUpdate[player] = allocatedGooResearchSnapshots.length;
        totalGooProduction -= decrease;
    }
    
    function buyBasicUnit(uint256 unitId, uint256 amount) external {
        require(gameStarted);
        require(schema.validUnitId(unitId));
        require(unitsOwned[msg.sender][unitId] + amount <= MAX_PRODUCTION_UNITS);
        
        uint256 unitCost = schema.getGooCostForUnit(unitId, unitsOwned[msg.sender][unitId], amount);
        require(balanceOf(msg.sender) >= unitCost);
        require(schema.unitEthCost(unitId) == 0);  
        
         
        updatePlayersGooFromPurchase(msg.sender, unitCost);
        
        if (schema.unitGooProduction(unitId) > 0) {
            increasePlayersGooProduction(getUnitsProduction(msg.sender, unitId, amount));
        }
        
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
    }
    
    function buyEthUnit(uint256 unitId, uint256 amount) external payable {
        require(gameStarted);
        require(schema.validUnitId(unitId));
        require(unitsOwned[msg.sender][unitId] + amount <= MAX_PRODUCTION_UNITS);
        
        uint256 unitCost = schema.getGooCostForUnit(unitId, unitsOwned[msg.sender][unitId], amount);
        uint256 ethCost = SafeMath.mul(schema.unitEthCost(unitId), amount);
        
        require(balanceOf(msg.sender) >= unitCost);
        require(ethBalance[msg.sender] + msg.value >= ethCost);
        
         
        updatePlayersGooFromPurchase(msg.sender, unitCost);

        if (ethCost > msg.value) {
            ethBalance[msg.sender] -= (ethCost - msg.value);
        }
        
        uint256 devFund = ethCost / 50;  
        uint256 dividends = (ethCost - devFund) / 4;  
        totalEtherGooResearchPool += dividends;
        ethBalance[owner] += devFund;
        
        if (schema.unitGooProduction(unitId) > 0) {
            increasePlayersGooProduction(getUnitsProduction(msg.sender, unitId, amount));
        }
        
        unitsOwned[msg.sender][unitId] += amount;
        emit UnitBought(msg.sender, unitId, amount);
    }
    
    function sellUnit(uint256 unitId, uint256 amount) external {
        require(unitsOwned[msg.sender][unitId] >= amount);
        unitsOwned[msg.sender][unitId] -= amount;
        
        uint256 unitSalePrice = (schema.getGooCostForUnit(unitId, unitsOwned[msg.sender][unitId], amount) * 3) / 4;  
        uint256 gooChange = balanceOfUnclaimedGoo(msg.sender) + unitSalePrice;  
        lastGooSaveTime[msg.sender] = block.timestamp;
        roughSupply += gooChange;
        gooBalance[msg.sender] += gooChange;
        
        if (schema.unitGooProduction(unitId) > 0) {
            reducePlayersGooProduction(msg.sender, getUnitsProduction(msg.sender, unitId, amount));
        }
        
        if (schema.unitEthCost(unitId) > 0) {  
            ethBalance[msg.sender] += ((schema.unitEthCost(unitId) * amount) * 3) / 4;
        }
        emit UnitSold(msg.sender, unitId, amount);
    }
    
    function buyUpgrade(uint256 upgradeId) external payable {
        require(gameStarted);
        require(schema.validUpgradeId(upgradeId));  
        require(!upgradesOwned[msg.sender][upgradeId]);  
        
        uint256 gooCost;
        uint256 ethCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        (gooCost, ethCost, upgradeClass, unitId, upgradeValue) = schema.getUpgradeInfo(upgradeId);
        
        require(balanceOf(msg.sender) >= gooCost);
        
        if (ethCost > 0) {
            require(ethBalance[msg.sender] + msg.value >= ethCost);
             if (ethCost > msg.value) {  
                ethBalance[msg.sender] -= (ethCost - msg.value);
            }
        
            uint256 devFund = ethCost / 50;  
            totalEtherGooResearchPool += (ethCost - devFund);  
            ethBalance[owner] += devFund;
        }
        
         
        updatePlayersGooFromPurchase(msg.sender, gooCost);

        upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);
        upgradesOwned[msg.sender][upgradeId] = true;
    }
    
    function upgradeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionGain;
        if (upgradeClass == 0) {
            unitGooProductionIncreases[player][unitId] += upgradeValue;
            productionGain = (unitsOwned[player][unitId] * upgradeValue * (10 + unitGooProductionMultiplier[player][unitId])) / 10;
            increasePlayersGooProduction(productionGain);
        } else if (upgradeClass == 1) {
            unitGooProductionMultiplier[player][unitId] += upgradeValue;
            productionGain = (unitsOwned[player][unitId] * upgradeValue * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId])) / 10;
            increasePlayersGooProduction(productionGain);
        } else if (upgradeClass == 2) {
            unitAttackIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 3) {
            unitAttackMultiplier[player][unitId] += upgradeValue;
        } else if (upgradeClass == 4) {
            unitDefenseIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 5) {
            unitDefenseMultiplier[player][unitId] += upgradeValue;
        } else if (upgradeClass == 6) {
            unitGooStealingIncreases[player][unitId] += upgradeValue;
        } else if (upgradeClass == 7) {
            unitGooStealingMultiplier[player][unitId] += upgradeValue;
        }
    }
    
    function removeUnitMultipliers(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) internal {
        uint256 productionLoss;
        if (upgradeClass == 0) {
            unitGooProductionIncreases[player][unitId] -= upgradeValue;
            productionLoss = (unitsOwned[player][unitId] * upgradeValue * (10 + unitGooProductionMultiplier[player][unitId])) / 10;
            reducePlayersGooProduction(player, productionLoss);
        } else if (upgradeClass == 1) {
            unitGooProductionMultiplier[player][unitId] -= upgradeValue;
            productionLoss = (unitsOwned[player][unitId] * upgradeValue * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId])) / 10;
            reducePlayersGooProduction(player, productionLoss);
        } else if (upgradeClass == 2) {
            unitAttackIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 3) {
            unitAttackMultiplier[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 4) {
            unitDefenseIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 5) {
            unitDefenseMultiplier[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 6) {
            unitGooStealingIncreases[player][unitId] -= upgradeValue;
        } else if (upgradeClass == 7) {
            unitGooStealingMultiplier[player][unitId] -= upgradeValue;
        }
    }
    
    function buyRareItem(uint256 rareId) external payable {
        require(schema.validRareId(rareId));
        
        address previousOwner = rareItemOwner[rareId];
        require(previousOwner != 0);

        uint256 ethCost = rareItemPrice[rareId];
        require(ethBalance[msg.sender] + msg.value >= ethCost);
        
         
        updatePlayersGoo(msg.sender);
        
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        (upgradeClass, unitId, upgradeValue) = schema.getRareInfo(rareId);
        upgradeUnitMultipliers(msg.sender, upgradeClass, unitId, upgradeValue);
        
         
        updatePlayersGoo(previousOwner);
        removeUnitMultipliers(previousOwner, upgradeClass, unitId, upgradeValue);
        
         
        if (ethCost > msg.value) {
             
            ethBalance[msg.sender] -= (ethCost - msg.value);
        } else if (msg.value > ethCost) {
             
            ethBalance[msg.sender] += msg.value - ethCost;
        }
        
         
        uint256 devFund = ethCost / 50;  
        uint256 dividends = ethCost / 20;  
        totalEtherGooResearchPool += dividends;
        ethBalance[owner] += devFund;
        
         
        rareItemOwner[rareId] = msg.sender;
        rareItemPrice[rareId] = (ethCost * 5) / 4;  
        ethBalance[previousOwner] += ethCost - (dividends + devFund);
    }
    
    function withdrawEther(uint256 amount) external {
        require(amount <= ethBalance[msg.sender]);
        ethBalance[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function claimResearchDividends(address referer, uint256 startSnapshot, uint256 endSnapShot) external {
        require(startSnapshot <= endSnapShot);
        require(startSnapshot >= lastGooResearchFundClaim[msg.sender]);
        require(endSnapShot < allocatedGooResearchSnapshots.length);
        
        uint256 researchShare;
        uint256 previousProduction = gooProductionSnapshots[msg.sender][lastGooResearchFundClaim[msg.sender] - 1];  
        for (uint256 i = startSnapshot; i <= endSnapShot; i++) {
            
             
            uint256 productionDuringSnapshot = gooProductionSnapshots[msg.sender][i];
            bool soldAllProduction = gooProductionZeroedSnapshots[msg.sender][i];
            if (productionDuringSnapshot == 0 && !soldAllProduction) {
                productionDuringSnapshot = previousProduction;
            } else {
               previousProduction = productionDuringSnapshot;
            }
            
            researchShare += (allocatedGooResearchSnapshots[i] * productionDuringSnapshot) / totalGooProductionSnapshots[i];
        }
        
        
        if (gooProductionSnapshots[msg.sender][endSnapShot] == 0 && !gooProductionZeroedSnapshots[msg.sender][i] && previousProduction > 0) {
            gooProductionSnapshots[msg.sender][endSnapShot] = previousProduction;  
        }
        
        lastGooResearchFundClaim[msg.sender] = endSnapShot + 1;
        
        uint256 referalDivs;
        if (referer != address(0) && referer != msg.sender) {
            referalDivs = researchShare / 100;  
            ethBalance[referer] += referalDivs;
        }
        
        ethBalance[msg.sender] += researchShare - referalDivs;
    }
    
     
    function snapshotDailyGooResearchFunding() external {
        require(msg.sender == owner);
         
        
        uint256 todaysEtherResearchFund = (totalEtherGooResearchPool / 10);  
        totalEtherGooResearchPool -= todaysEtherResearchFund;
        
        totalGooProductionSnapshots.push(totalGooProduction);
        allocatedGooResearchSnapshots.push(todaysEtherResearchFund);
        nextSnapshotTime = block.timestamp + 24 hours;
    }
    
    
    
     
    function buyRaffleTicket(uint256 amount) external {
        require(raffleEndTime >= block.timestamp);
        require(amount > 0);
        
        uint256 ticketsCost = SafeMath.mul(RAFFLE_TICKET_BASE_GOO_PRICE, amount);
        require(balanceOf(msg.sender) >= ticketsCost);
        
         
        updatePlayersGooFromPurchase(msg.sender, ticketsCost);
        
         
        TicketPurchases storage purchases = ticketsBoughtByPlayer[msg.sender];
        
         
        if (purchases.raffleRareId != raffleRareId) {
            purchases.numPurchases = 0;
            purchases.raffleRareId = raffleRareId;
            rafflePlayers[raffleRareId].push(msg.sender);  
        }
        
         
        if (purchases.numPurchases == purchases.ticketsBought.length) {
            purchases.ticketsBought.length += 1;
        }
        purchases.ticketsBought[purchases.numPurchases++] = TicketPurchase(raffleTicketsBought, raffleTicketsBought + (amount - 1));  
        
         
        raffleTicketsBought += amount;
    }
    
    function startRareRaffle(uint256 endTime, uint256 rareId) external {
        require(msg.sender == owner);
        require(schema.validRareId(rareId));
        require(rareItemOwner[rareId] == 0);
        
         
        raffleWinningTicketSelected = false;
        raffleTicketThatWon = 0;
        raffleWinner = 0;
        raffleTicketsBought = 0;
        
         
        raffleEndTime = endTime;
        raffleRareId = rareId;
    }
    
    function awardRafflePrize(address checkWinner, uint256 checkIndex) external {
        require(raffleEndTime < block.timestamp);
        require(raffleWinner == 0);
        require(rareItemOwner[raffleRareId] == 0);
        
        if (!raffleWinningTicketSelected) {
            drawRandomWinner();  
        }
        
         
        if (checkWinner != 0) {
            TicketPurchases storage tickets = ticketsBoughtByPlayer[checkWinner];
            if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.raffleRareId == raffleRareId) {
                TicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
                if (raffleTicketThatWon >= checkTicket.startId && raffleTicketThatWon <= checkTicket.endId) {
                    assignRafflePrize(checkWinner);  
                    return;
                }
            }
        }
        
         
        for (uint256 i = 0; i < rafflePlayers[raffleRareId].length; i++) {
            address player = rafflePlayers[raffleRareId][i];
            TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
            
            uint256 endIndex = playersTickets.numPurchases - 1;
             
            if (raffleTicketThatWon >= playersTickets.ticketsBought[0].startId && raffleTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
                for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
                    TicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
                    if (raffleTicketThatWon >= playerTicket.startId && raffleTicketThatWon <= playerTicket.endId) {
                        assignRafflePrize(player);  
                        return;
                    }
                }
            }
        }
    }
    
    function assignRafflePrize(address winner) internal {
        raffleWinner = winner;
        rareItemOwner[raffleRareId] = winner;
        rareItemPrice[raffleRareId] = (schema.rareStartPrice(raffleRareId) * 21) / 20;  
        
        updatePlayersGoo(winner);
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
        (upgradeClass, unitId, upgradeValue) = schema.getRareInfo(raffleRareId);
        upgradeUnitMultipliers(winner, upgradeClass, unitId, upgradeValue);
    }
    
     
    function drawRandomWinner() public {
        require(msg.sender == owner);
        require(raffleEndTime < block.timestamp);
        require(!raffleWinningTicketSelected);
        
        uint256 seed = raffleTicketsBought + block.timestamp;
        raffleTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, raffleTicketsBought);
        raffleWinningTicketSelected = true;
    }
    
    
    
    function protectAddress(address exchange, bool isProtected) external {
        require(msg.sender == owner);
        require(getGooProduction(exchange) == 0);  
        protectedAddresses[exchange] = isProtected;
    }
    
    function attackPlayer(address target) external {
        require(battleCooldown[msg.sender] < block.timestamp);
        require(target != msg.sender);
        require(!protectedAddresses[target]);  
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;
        (attackingPower, defendingPower, stealingPower) = getPlayersBattlePower(msg.sender, target);
        
        if (battleCooldown[target] > block.timestamp) {  
            defendingPower = schema.getWeakenedDefensePower(defendingPower);
        }
        
        if (attackingPower > defendingPower) {
            battleCooldown[msg.sender] = block.timestamp + 30 minutes;
            if (balanceOf(target) > stealingPower) {
                 
                uint256 unclaimedGoo = balanceOfUnclaimedGoo(target);
                if (stealingPower > unclaimedGoo) {
                    uint256 gooDecrease = stealingPower - unclaimedGoo;
                    gooBalance[target] -= gooDecrease;
                } else {
                    uint256 gooGain = unclaimedGoo - stealingPower;
                    gooBalance[target] += gooGain;
                }
                gooBalance[msg.sender] += stealingPower;
                emit PlayerAttacked(msg.sender, target, true, stealingPower);
            } else {
                emit PlayerAttacked(msg.sender, target, true, balanceOf(target));
                gooBalance[msg.sender] += balanceOf(target);
                gooBalance[target] = 0;
            }
            
            lastGooSaveTime[target] = block.timestamp; 
             
        } else {
            battleCooldown[msg.sender] = block.timestamp + 10 minutes;
            emit PlayerAttacked(msg.sender, target, false, 0);
        }
    }
    
    function getPlayersBattlePower(address attacker, address defender) internal constant returns (uint256, uint256, uint256) {
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.battleUnitIdRange();
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;

         
        while (startId <= endId) {
            attackingPower += getUnitsAttack(attacker, startId, unitsOwned[attacker][startId]);
            stealingPower += getUnitsStealingCapacity(attacker, startId, unitsOwned[attacker][startId]);
            
            defendingPower += getUnitsDefense(defender, startId, unitsOwned[defender][startId]);
            startId++;
        }
        return (attackingPower, defendingPower, stealingPower);
    }
    
    function getPlayersBattleStats(address player) external constant returns (uint256, uint256, uint256) {
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.battleUnitIdRange();
        
        uint256 attackingPower;
        uint256 defendingPower;
        uint256 stealingPower;

         
        while (startId <= endId) {
            attackingPower += getUnitsAttack(player, startId, unitsOwned[player][startId]);
            stealingPower += getUnitsStealingCapacity(player, startId, unitsOwned[player][startId]);
            defendingPower += getUnitsDefense(player, startId, unitsOwned[player][startId]);
            startId++;
        }
        return (attackingPower, defendingPower, stealingPower);
    }
    
    function getUnitsProduction(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitGooProduction(unitId) + unitGooProductionIncreases[player][unitId]) * (10 + unitGooProductionMultiplier[player][unitId])) / 10;
    }
    
    function getUnitsAttack(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitAttack(unitId) + unitAttackIncreases[player][unitId]) * (10 + unitAttackMultiplier[player][unitId])) / 10;
    }
    
    function getUnitsDefense(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitDefense(unitId) + unitDefenseIncreases[player][unitId]) * (10 + unitDefenseMultiplier[player][unitId])) / 10;
    }
    
    function getUnitsStealingCapacity(address player, uint256 unitId, uint256 amount) internal constant returns (uint256) {
        return (amount * (schema.unitStealingCapacity(unitId) + unitGooStealingIncreases[player][unitId]) * (10 + unitGooStealingMultiplier[player][unitId])) / 10;
    }
    
    
     
    function getGameInfo() external constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[], bool[]){
        uint256[] memory units = new uint256[](schema.currentNumberOfUnits());
        bool[] memory upgrades = new bool[](schema.currentNumberOfUpgrades());
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.productionUnitIdRange();
        
        uint256 i;
        while (startId <= endId) {
            units[i] = unitsOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
        (startId, endId) = schema.battleUnitIdRange();
        while (startId <= endId) {
            units[i] = unitsOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
         
        i = 0;
        (startId, endId) = schema.upgradeIdRange();
        while (startId <= endId) {
            upgrades[i] = upgradesOwned[msg.sender][startId];
            i++;
            startId++;
        }
        
        return (block.timestamp, totalEtherGooResearchPool, totalGooProduction, nextSnapshotTime, balanceOf(msg.sender), ethBalance[msg.sender], getGooProduction(msg.sender), units, upgrades);
    }
    
     
    function getRareItemInfo() external constant returns (address[], uint256[]) {
        address[] memory itemOwners = new address[](schema.currentNumberOfRares());
        uint256[] memory itemPrices = new uint256[](schema.currentNumberOfRares());
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.rareIdRange();
        
        uint256 i;
        while (startId <= endId) {
            itemOwners[i] = rareItemOwner[startId];
            itemPrices[i] = rareItemPrice[startId];
            
            i++;
            startId++;
        }
        
        return (itemOwners, itemPrices);
    }
    
     
     function viewUnclaimedResearchDividends() external constant returns (uint256, uint256, uint256) {
        uint256 startSnapshot = lastGooResearchFundClaim[msg.sender];
        uint256 latestSnapshot = allocatedGooResearchSnapshots.length - 1;  
        
        uint256 researchShare;
        uint256 previousProduction = gooProductionSnapshots[msg.sender][lastGooResearchFundClaim[msg.sender] - 1];  
        for (uint256 i = startSnapshot; i <= latestSnapshot; i++) {
            
             
            uint256 productionDuringSnapshot = gooProductionSnapshots[msg.sender][i];
            bool soldAllProduction = gooProductionZeroedSnapshots[msg.sender][i];
            if (productionDuringSnapshot == 0 && !soldAllProduction) {
                productionDuringSnapshot = previousProduction;
            } else {
               previousProduction = productionDuringSnapshot;
            }
            
            researchShare += (allocatedGooResearchSnapshots[i] * productionDuringSnapshot) / totalGooProductionSnapshots[i];
        }
        return (researchShare, startSnapshot, latestSnapshot);
    }
    
    
     
    function getRafflePlayers(uint256 raffleId) external constant returns (address[]) {
        return (rafflePlayers[raffleId]);
    }
    
     
    function getPlayersTickets(address player) external constant returns (uint256[], uint256[]) {
        TicketPurchases storage playersTickets = ticketsBoughtByPlayer[player];
        
        if (playersTickets.raffleRareId == raffleRareId) {
            uint256[] memory startIds = new uint256[](playersTickets.numPurchases);
            uint256[] memory endIds = new uint256[](playersTickets.numPurchases);
            
            for (uint256 i = 0; i < playersTickets.numPurchases; i++) {
                startIds[i] = playersTickets.ticketsBought[i].startId;
                endIds[i] = playersTickets.ticketsBought[i].endId;
            }
        }
        
        return (startIds, endIds);
    }
    
     
    function getLatestRaffleInfo() external constant returns (uint256, uint256, uint256, address, uint256) {
        return (raffleEndTime, raffleRareId, raffleTicketsBought, raffleWinner, raffleTicketThatWon);
    }
    
    
     
    function updateGooConfig(address newSchemaAddress) external {
        require(msg.sender == owner);
        
        GooGameConfig newSchema = GooGameConfig(newSchemaAddress);
        requireExistingUnitsSame(newSchema);
        requireExistingUpgradesSame(newSchema);
        
         
        schema = GooGameConfig(newSchema);
    }
    
    function requireExistingUnitsSame(GooGameConfig newSchema) internal constant {
         
        
        uint256 startId;
        uint256 endId;
        (startId, endId) = schema.productionUnitIdRange();
        while (startId <= endId) {
            require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
            require(schema.unitGooProduction(startId) == newSchema.unitGooProduction(startId));
            startId++;
        }
        
        (startId, endId) = schema.battleUnitIdRange();
        while (startId <= endId) {
            require(schema.unitEthCost(startId) == newSchema.unitEthCost(startId));
            require(schema.unitAttack(startId) == newSchema.unitAttack(startId));
            require(schema.unitDefense(startId) == newSchema.unitDefense(startId));
            require(schema.unitStealingCapacity(startId) == newSchema.unitStealingCapacity(startId));
            startId++;
        }
    }
    
    function requireExistingUpgradesSame(GooGameConfig newSchema) internal constant {
        uint256 startId;
        uint256 endId;
        
        uint256 oldClass;
        uint256 oldUnitId;
        uint256 oldValue;
        
        uint256 newClass;
        uint256 newUnitId;
        uint256 newValue;
        
         
        (startId, endId) = schema.rareIdRange();
        while (startId <= endId) {
            uint256 oldGooCost;
            uint256 oldEthCost;
            (oldGooCost, oldEthCost, oldClass, oldUnitId, oldValue) = schema.getUpgradeInfo(startId);
            
            uint256 newGooCost;
            uint256 newEthCost;
            (newGooCost, newEthCost, newClass, newUnitId, newValue) = newSchema.getUpgradeInfo(startId);
            
            require(oldGooCost == newGooCost);
            require(oldEthCost == oldEthCost);
            require(oldClass == oldClass);
            require(oldUnitId == newUnitId);
            require(oldValue == newValue);
            startId++;
        }
        
         
        (startId, endId) = schema.rareIdRange();
        while (startId <= endId) {
            (oldClass, oldUnitId, oldValue) = schema.getRareInfo(startId);
            (newClass, newUnitId, newValue) = newSchema.getRareInfo(startId);
            
            require(oldClass == newClass);
            require(oldUnitId == newUnitId);
            require(oldValue == newValue);
            startId++;
        }
    }
}


contract GooGameConfig {
    
    mapping(uint256 => Unit) private unitInfo;
    mapping(uint256 => Upgrade) private upgradeInfo;
    mapping(uint256 => Rare) private rareInfo;
    
    uint256 public constant currentNumberOfUnits = 14;
    uint256 public constant currentNumberOfUpgrades = 42;
    uint256 public constant currentNumberOfRares = 2;
    
    struct Unit {
        uint256 unitId;
        uint256 baseGooCost;
        uint256 gooCostIncreaseHalf;  
        uint256 ethCost;
        uint256 baseGooProduction;
        
        uint256 attackValue;
        uint256 defenseValue;
        uint256 gooStealingCapacity;
    }
    
    struct Upgrade {
        uint256 upgradeId;
        uint256 gooCost;
        uint256 ethCost;
        uint256 upgradeClass;
        uint256 unitId;
        uint256 upgradeValue;
    }
    
     struct Rare {
        uint256 rareId;
        uint256 ethCost;
        uint256 rareClass;
        uint256 unitId;
        uint256 rareValue;
    }
    
     
    function GooGameConfig() public {
        
        unitInfo[1] = Unit(1, 0, 10, 0, 1, 0, 0, 0);
        unitInfo[2] = Unit(2, 100, 50, 0, 2, 0, 0, 0);
        unitInfo[3] = Unit(3, 0, 0, 0.01 ether, 12, 0, 0, 0);
        unitInfo[4] = Unit(4, 500, 250, 0, 4, 0, 0, 0);
        unitInfo[5] = Unit(5, 2500, 1250, 0, 6, 0, 0, 0);
        unitInfo[6] = Unit(6, 10000, 5000, 0, 8, 0, 0, 0);
        unitInfo[7] = Unit(7, 0, 1000, 0.05 ether, 60, 0, 0, 0);
        unitInfo[8] = Unit(8, 25000, 12500, 0, 10, 0, 0, 0);
        
        unitInfo[40] = Unit(40, 100, 50, 0, 0, 10, 10, 20);
        unitInfo[41] = Unit(41, 250, 125, 0, 0, 1, 25, 1);
        unitInfo[42] = Unit(42, 0, 50, 0.01 ether, 0, 100, 10, 5);
        unitInfo[43] = Unit(43, 1000, 500, 0, 0, 25, 1, 50);
        unitInfo[44] = Unit(44, 2500, 1250, 0, 0, 20, 40, 100);
        unitInfo[45] = Unit(45, 0, 500, 0.02 ether, 0, 0, 0, 1000);
        
        upgradeInfo[1] = Upgrade(1, 500, 0, 0, 1, 1);  
        upgradeInfo[2] = Upgrade(2, 0, 0.1 ether, 1, 1, 10);  
        upgradeInfo[3] = Upgrade(3, 10000, 0, 1, 1, 5);  
        
        upgradeInfo[4] = Upgrade(4, 0, 0.1 ether, 0, 2, 2);  
        upgradeInfo[5] = Upgrade(5, 2000, 0, 1, 2, 5);  
        upgradeInfo[6] = Upgrade(6, 0, 0.2 ether, 0, 2, 2);  
        
        upgradeInfo[7] = Upgrade(7, 2500, 0, 0, 3, 2);  
        upgradeInfo[8] = Upgrade(8, 0, 0.5 ether, 1, 3, 10);  
        upgradeInfo[9] = Upgrade(9, 25000, 0, 1, 3, 5);  
        
        upgradeInfo[10] = Upgrade(10, 0, 0.1 ether, 0, 4, 1);  
        upgradeInfo[11] = Upgrade(11, 5000, 0, 1, 4, 5);  
        upgradeInfo[12] = Upgrade(12, 0, 0.2 ether, 0, 4, 2);  
        
        upgradeInfo[13] = Upgrade(13, 10000, 0, 0, 5, 2);  
        upgradeInfo[14] = Upgrade(14, 0, 0.5 ether, 1, 5, 10);  
        upgradeInfo[15] = Upgrade(15, 25000, 0, 1, 5, 5);  
        
        upgradeInfo[16] = Upgrade(16, 0, 0.1 ether, 0, 6, 1);  
        upgradeInfo[17] = Upgrade(17, 25000, 0, 1, 6, 5);  
        upgradeInfo[18] = Upgrade(18, 0, 0.2 ether, 0, 6, 2);  
        
        upgradeInfo[19] = Upgrade(13, 50000, 0, 0, 7, 2);  
        upgradeInfo[20] = Upgrade(20, 0, 0.2 ether, 1, 7, 5);  
        upgradeInfo[21] = Upgrade(21, 100000, 0, 1, 7, 5);  
        
        upgradeInfo[22] = Upgrade(22, 0, 0.1 ether, 0, 8, 2);  
        upgradeInfo[23] = Upgrade(23, 25000, 0, 1, 8, 5);  
        upgradeInfo[24] = Upgrade(24, 0, 0.2 ether, 0, 8, 4);  
        
        
        
        upgradeInfo[25] = Upgrade(25, 500, 0, 2, 40, 10);  
        upgradeInfo[26] = Upgrade(26, 0, 0.1 ether, 4, 40, 10);  
        upgradeInfo[27] = Upgrade(27, 10000, 0, 6, 40, 10);  
        
        upgradeInfo[28] = Upgrade(28, 0, 0.2 ether, 3, 41, 5);  
        upgradeInfo[29] = Upgrade(29, 5000, 0, 4, 41, 10);  
        upgradeInfo[30] = Upgrade(30, 0, 0.5 ether, 6, 41, 4);  
        
        upgradeInfo[31] = Upgrade(31, 2500, 0, 5, 42, 5);  
        upgradeInfo[32] = Upgrade(32, 0, 0.2 ether, 6, 42, 10);  
        upgradeInfo[33] = Upgrade(33, 20000, 0, 7, 42, 5);  
        
        upgradeInfo[34] = Upgrade(34, 0, 0.1 ether, 2, 43, 5);  
        upgradeInfo[35] = Upgrade(35, 10000, 0, 4, 43, 5);  
        upgradeInfo[36] = Upgrade(36, 0, 0.2 ether, 5, 43, 5);  
        
        upgradeInfo[37] = Upgrade(37, 0, 0.1 ether, 2, 44, 15);  
        upgradeInfo[38] = Upgrade(38, 25000, 0, 3, 44, 5);  
        upgradeInfo[39] = Upgrade(39, 0, 0.2 ether, 4, 44, 15);  
        
        upgradeInfo[40] = Upgrade(40, 50000, 0, 6, 45, 500);  
        upgradeInfo[41] = Upgrade(41, 0, 0.5 ether, 7, 45, 10);  
        upgradeInfo[42] = Upgrade(42, 250000, 0, 7, 45, 5);  
    
        
        rareInfo[1] = Rare(1, 0.5 ether, 1, 1, 30);  
        rareInfo[2] = Rare(2, 0.5 ether, 0, 2, 4);  
    }
    
    function getGooCostForUnit(uint256 unitId, uint256 existing, uint256 amount) public constant returns (uint256) {
        if (amount == 1) {  
            if (existing == 0) {
                return unitInfo[unitId].baseGooCost;
            } else {
                return unitInfo[unitId].baseGooCost + (existing * unitInfo[unitId].gooCostIncreaseHalf * 2);
            }
        } else if (amount > 1) {
            uint256 existingCost;
            if (existing > 0) {
                existingCost = (unitInfo[unitId].baseGooCost * existing) + (existing * (existing - 1) * unitInfo[unitId].gooCostIncreaseHalf);
            }
            
            existing += amount;
            uint256 newCost = SafeMath.add(SafeMath.mul(unitInfo[unitId].baseGooCost, existing), SafeMath.mul(SafeMath.mul(existing, (existing - 1)), unitInfo[unitId].gooCostIncreaseHalf));
            return newCost - existingCost;
        }
    }
    
    function getWeakenedDefensePower(uint256 defendingPower) external constant returns (uint256) {
        return defendingPower / 2;
    }
    
    function validUnitId(uint256 unitId) external constant returns (bool) {
        return ((unitId > 0 && unitId < 9) || (unitId > 39 && unitId < 46));
    }
    
    function validUpgradeId(uint256 upgradeId) external constant returns (bool) {
        return (upgradeId > 0 && upgradeId < 43);
    }
    
    function validRareId(uint256 rareId) external constant returns (bool) {
        return (rareId > 0 && rareId < 3);
    }
    
    function unitEthCost(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].ethCost;
    }
    
    function unitGooProduction(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].baseGooProduction;
    }
    
    function unitAttack(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].attackValue;
    }
    
    function unitDefense(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].defenseValue;
    }
    
    function unitStealingCapacity(uint256 unitId) external constant returns (uint256) {
        return unitInfo[unitId].gooStealingCapacity;
    }
    
    function rareStartPrice(uint256 rareId) external constant returns (uint256) {
        return rareInfo[rareId].ethCost;
    }
    
    function productionUnitIdRange() external constant returns (uint256, uint256) {
        return (1, 8);
    }
    
    function battleUnitIdRange() external constant returns (uint256, uint256) {
        return (40, 45);
    }
    
    function upgradeIdRange() external constant returns (uint256, uint256) {
        return (1, 42);
    }
    
    function rareIdRange() external constant returns (uint256, uint256) {
        return (1, 2);
    }
    
    function getUpgradeInfo(uint256 upgradeId) external constant returns (uint256, uint256, uint256, uint256, uint256) {
        return (upgradeInfo[upgradeId].gooCost, upgradeInfo[upgradeId].ethCost, upgradeInfo[upgradeId].upgradeClass,
        upgradeInfo[upgradeId].unitId, upgradeInfo[upgradeId].upgradeValue);
    }
    
    function getRareInfo(uint256 rareId) external constant returns (uint256, uint256, uint256) {
        return (rareInfo[rareId].rareClass, rareInfo[rareId].unitId, rareInfo[rareId].rareValue);
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