 

pragma solidity ^0.4.16;

 

contract SafeMath {

     
     
     
     
     
        
        uint32 classId = 0;
        uint32 createIndex = 0;
        uint32 lastClaimIndex = 0;
        (classId, createIndex, lastClaimIndex) = getObjIndex(_objId);
        Gen0Config storage gen0 = gen0Config[classId];
        if (gen0.classId != classId) {
            return (0, 0);
        }
        
        uint32 currentGap = 0;
        uint32 totalGap = 0;
        if (lastClaimIndex < gen0.total)
            currentGap = gen0.total - lastClaimIndex;
        if (createIndex < gen0.total)
            totalGap = gen0.total - createIndex;
        return (safeMult(currentGap, gen0.returnPrice), safeMult(totalGap, gen0.returnPrice));
    }
    
     
    
    function moveDataContractBalanceToWorld() external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        data.withdrawEther(address(this), data.balance);
    }
    
    function renameMonster(uint64 _objId, string name) isActive external {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(_objId);
        if (obj.monsterId != _objId || obj.trainer != msg.sender) {
            revert();
        }
        data.setMonsterObj(_objId, name, obj.exp, obj.createIndex, obj.lastClaimIndex);
    }
    
    function catchMonster(uint32 _classId, string _name) isActive external payable {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        
        if (class.classId == 0 || class.catchable == false) {
            revert();
        }
        
         
        if (data.getMonsterDexSize(msg.sender) > maxDexSize)
            revert();
        
        uint256 totalBalance = safeAdd(msg.value, data.getExtraBalance(msg.sender));
        uint256 payPrice = class.price;
         
        if (class.total > 0)
            payPrice += class.price*(class.total-1)/priceIncreasingRatio;
        if (payPrice > totalBalance) {
            revert();
        }
        totalEarn += payPrice;
        
         
        data.setExtraBalance(msg.sender, safeSubtract(totalBalance, payPrice));
        
         
        uint64 objId = data.addMonsterObj(_classId, msg.sender, _name);
         
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            uint8 value = getRandom(STAT_MAX, uint8(i), lastHunter) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }
        
        lastHunter = msg.sender;
        EventCatchMonster(msg.sender, objId);
    }


    function cashOut(uint256 _amount) public returns(ResultCode) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        uint256 totalAmount = data.getExtraBalance(msg.sender);
        uint64 objId = 0;

         
        uint dexSize = data.getMonsterDexSize(msg.sender);
        for (uint i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(msg.sender, i);
            if (objId > 0) {
                MonsterObjAcc memory obj;
                (obj.monsterId, obj.classId, obj.trainer, obj.exp, obj.createIndex, obj.lastClaimIndex, obj.createTime) = data.getMonsterObj(objId);
                Gen0Config storage gen0 = gen0Config[obj.classId];
                if (gen0.classId == obj.classId) {
                    if (obj.lastClaimIndex < gen0.total) {
                        uint32 gap = uint32(safeSubtract(gen0.total, obj.lastClaimIndex));
                        if (gap > 0) {
                            totalAmount += safeMult(gap, gen0.returnPrice);
                             
                            data.setMonsterObj(obj.monsterId, " name me ", obj.exp, obj.createIndex, gen0.total);
                        }
                    }
                }
            }
        }
        
         
        if (_amount == 0) {
            _amount = totalAmount;
        }
        if (_amount > totalAmount) {
            revert();
        }
        
         
        if (this.balance + data.balance < _amount){
            revert();
        } else if (this.balance < _amount) {
            data.withdrawEther(address(this), data.balance);
        }
        
        if (_amount > 0) {
            data.setExtraBalance(msg.sender, totalAmount - _amount);
            if (!msg.sender.send(_amount)) {
                data.setExtraBalance(msg.sender, totalAmount);
                EventCashOut(msg.sender, ResultCode.ERROR_SEND_FAIL, 0);
                return ResultCode.ERROR_SEND_FAIL;
            }
        }
        
        EventCashOut(msg.sender, ResultCode.SUCCESS, _amount);
        return ResultCode.SUCCESS;
    }
    
     
    
    function getTrainerEarn(address _trainer) constant public returns(uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        uint256 returnFromMonster = 0;
         
        uint256 gen0current = 0;
        uint256 gen0total = 0;
        uint64 objId = 0;
        uint dexSize = data.getMonsterDexSize(_trainer);
        for (uint i = 0; i < dexSize; i++) {
            objId = data.getMonsterObjId(_trainer, i);
            if (objId > 0) {
                (gen0current, gen0total) = getReturnFromMonster(objId);
                returnFromMonster += gen0current;
            }
        }
        return returnFromMonster;
    }
    
    function getTrainerBalance(address _trainer) constant external returns(uint256) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        
        uint256 userExtraBalance = data.getExtraBalance(_trainer);
        uint256 returnFromMonster = getTrainerEarn(_trainer);

        return (userExtraBalance + returnFromMonster);
    }
    
    function getMonsterClassBasic(uint32 _classId) constant external returns(uint256, uint256, uint256, bool) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);
        return (class.price, class.returnPrice, class.total, class.catchable);
    }

}