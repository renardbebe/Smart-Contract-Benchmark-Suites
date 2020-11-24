 

pragma solidity ^0.4.16;

 

contract SafeMath {

     
     
     
     
     
    
    function addCastle(address _trainer, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3, uint32 _brickNumber) onlyModerators external returns(uint32 currentCastleId){
        currentCastleId = trainerCastle[_trainer];
        if (currentCastleId > 0)
            return currentCastleId;

        totalCastle += 1;
        currentCastleId = totalCastle;
        CastleData storage castle = castleData[currentCastleId];
        castle.name = _name;
        castle.owner = _trainer;
        castle.monsters[0] = _a1;
        castle.monsters[1] = _a2;
        castle.monsters[2] = _a3;
        castle.monsters[3] = _s1;
        castle.monsters[4] = _s2;
        castle.monsters[5] = _s3;
        castle.brickNumber = _brickNumber;
        castle.createTime = now;
        
        castle.index = ++activeCastleList.length;
        activeCastleList[castle.index-1] = currentCastleId;
         
        trainerCastle[_trainer] = currentCastleId;
    }
    
    function renameCastle(uint32 _castleId, string _name) onlyModerators external {
        CastleData storage castle = castleData[_castleId];
        castle.name = _name;
    }
    
    function removeCastleFromActive(uint32 _castleId) onlyModerators external {
        CastleData storage castle = castleData[_castleId];
        if (castle.index == 0)
            return;
        
        trainerCastle[castle.owner] = 0;
        if (castle.index <= activeCastleList.length) {
             
            castleData[activeCastleList[activeCastleList.length-1]].index = castle.index;
            activeCastleList[castle.index-1] = activeCastleList[activeCastleList.length-1];
            activeCastleList.length -= 1;
            castle.index = 0;
        }
        
        trannerBattleLog[castle.owner].lastCastle = _castleId;
    }
    
    function addBattleLog(uint32 _castleId, address _attacker, 
        uint8 _ran1, uint8 _ran2, uint8 _ran3, uint8 _result, uint32 _castleExp1, uint32 _castleExp2, uint32 _castleExp3) onlyModerators external returns(uint64) {
        totalBattle += 1;
        BattleDataLog storage battleLog = battles[totalBattle];
        battleLog.castleId = _castleId;
        battleLog.attacker = _attacker;
        battleLog.randoms[0] = _ran1;
        battleLog.randoms[1] = _ran2;
        battleLog.randoms[2] = _ran3;
        battleLog.result = _result;
        battleLog.castleExps[0] = _castleExp1;
        battleLog.castleExps[1] = _castleExp2;
        battleLog.castleExps[2] = _castleExp3;
        
         
        CastleData storage castle = castleData[_castleId];
        TrainerBattleLog storage trainerLog = trannerBattleLog[_attacker];
         
        if (_result == 0) {  
            castle.totalWin += 1;
            trainerLog.totalLose += 1;              
        } else {
            castle.totalLose += 1;
            trainerLog.totalWin += 1;
            if (_result == 2) {  
                trainerLog.totalBrick += castle.brickNumber / 2;
            }
        }

        castle.battleList[(castle.totalLose + castle.totalWin - 1)%NO_BATTLE_LOG] = totalBattle;
        trainerLog.battleList[(trainerLog.totalWin + trainerLog.totalLose - 1)%NO_BATTLE_LOG] = totalBattle;
        
        return totalBattle;
    }
    
    function addBattleLogMonsterInfo(uint64 _battleId, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3, uint32 _exp1, uint32 _exp2, uint32 _exp3) onlyModerators external {
        BattleDataLog storage battleLog = battles[_battleId];
        battleLog.attackerObjIds[0] = _a1;
        battleLog.attackerObjIds[1] = _a2;
        battleLog.attackerObjIds[2] = _a3;
        battleLog.attackerObjIds[3] = _s1;
        battleLog.attackerObjIds[4] = _s2;
        battleLog.attackerObjIds[5] = _s3;
        
        battleLog.attackerExps[0] = _exp1;
        battleLog.attackerExps[1] = _exp2;
        battleLog.attackerExps[2] = _exp3;
    }
    
    function deductTrainerBrick(address _trainer, uint32 _deductAmount) onlyModerators external returns(bool){
        TrainerBattleLog storage trainerLog = trannerBattleLog[_trainer];
        if (trainerLog.totalBrick < _deductAmount)
            return false;
        trainerLog.totalBrick -= _deductAmount;
        return true;
    }
    
     
    function isCastleActive(uint32 _castleId) constant external returns(bool){
        CastleData storage castle = castleData[_castleId];
        return (castle.index > 0);
    }
    
    function countActiveCastle() constant external returns(uint) {
        return activeCastleList.length;
    }
    
    function getActiveCastleId(uint index) constant external returns(uint32) {
        return activeCastleList[index];
    }
    
    function getCastleBasicInfo(address _owner) constant external returns(uint32, uint, uint32) {
        uint32 currentCastleId = trainerCastle[_owner];
        if (currentCastleId == 0)
            return (0, 0, 0);
        CastleData memory castle = castleData[currentCastleId];
        return (currentCastleId, castle.index, castle.brickNumber);
    }
    
    function getCastleBasicInfoById(uint32 _castleId) constant external returns(uint, address, uint32) {
        CastleData memory castle = castleData[_castleId];
        return (castle.index, castle.owner, castle.brickNumber);
    }
    
    function getCastleObjInfo(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64, uint64, uint64) {
        CastleData memory castle = castleData[_castleId];
        return (castle.monsters[0], castle.monsters[1], castle.monsters[2], castle.monsters[3], castle.monsters[4], castle.monsters[5]);
    }
    
    function getCastleWinLose(uint32 _castleId) constant external returns(uint32, uint32, uint32) {
        CastleData memory castle = castleData[_castleId];
        return (castle.totalWin, castle.totalLose, castle.brickNumber);
    }
    
    function getCastleStats(uint32 _castleId) constant external returns(string, address, uint32, uint32, uint32, uint) {
        CastleData memory castle = castleData[_castleId];
        return (castle.name, castle.owner, castle.brickNumber, castle.totalWin, castle.totalLose, castle.createTime);
    }

    function getBattleDataLog(uint64 _battleId) constant external returns(uint32, address, uint8, uint8, uint8, uint8, uint32, uint32, uint32) {
        BattleDataLog memory battleLog = battles[_battleId];
        return (battleLog.castleId, battleLog.attacker, battleLog.result, battleLog.randoms[0], battleLog.randoms[1], 
            battleLog.randoms[2], battleLog.castleExps[0], battleLog.castleExps[1], battleLog.castleExps[2]);
    }
    
    function getBattleAttackerLog(uint64 _battleId) constant external returns(uint64, uint64, uint64, uint64, uint64, uint64, uint32, uint32, uint32) {
        BattleDataLog memory battleLog = battles[_battleId];
        return (battleLog.attackerObjIds[0], battleLog.attackerObjIds[1], battleLog.attackerObjIds[2], battleLog.attackerObjIds[3], battleLog.attackerObjIds[4], 
            battleLog.attackerObjIds[5], battleLog.attackerExps[0], battleLog.attackerExps[1], battleLog.attackerExps[2]);
    }
    
    function getCastleBattleList(uint32 _castleId) constant external returns(uint64, uint64, uint64, uint64) {
        CastleData storage castle = castleData[_castleId];
        return (castle.battleList[0], castle.battleList[1], castle.battleList[2], castle.battleList[3]);
    }
    
    function getTrainerBattleInfo(address _trainer) constant external returns(uint32, uint32, uint32, uint32, uint64, uint64, uint64, uint64) {
        TrainerBattleLog memory trainerLog = trannerBattleLog[_trainer];
        return (trainerLog.totalWin, trainerLog.totalLose, trainerLog.lastCastle, trainerLog.totalBrick, trainerLog.battleList[0], trainerLog.battleList[1], trainerLog.battleList[2], 
            trainerLog.battleList[3]);
    }
    
    function getTrainerBrick(address _trainer) constant external returns(uint32) {
        return trannerBattleLog[_trainer].totalBrick;
    }
    
    function isOnCastle(uint32 _castleId, uint64 _objId) constant external returns(bool) {
        CastleData storage castle = castleData[_castleId];
        if (castle.index > 0) {
            for (uint i = 0; i < castle.monsters.length; i++)
                if (castle.monsters[i] == _objId)
                    return true;
            return false;
        }
        return false;
    }
}