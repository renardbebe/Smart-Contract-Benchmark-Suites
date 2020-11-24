 

pragma solidity ^0.4.16;

 

contract SafeMath {

     
     
     
     
     
    
    function addEgg(uint64 _objId, uint32 _classId, address _trainer, uint _hatchTime) onlyModerators external returns(uint64) {
        totalEgg += 1;
        MonsterEgg storage egg = eggs[totalEgg];
        egg.objId = _objId;
        egg.eggId = totalEgg;
        egg.classId = _classId;
        egg.trainer = _trainer;
        egg.hatchTime = _hatchTime;
        egg.newObjId = 0;
        hatchingEggs[_trainer] = totalEgg;
        
         
        if (_objId > 0) {
            eggList[_objId].push(totalEgg);
        }
        return totalEgg;
    }
    
    function setHatchedEgg(uint64 _eggId, uint64 _newObjId) onlyModerators external {
        MonsterEgg storage egg = eggs[_eggId];
        if (egg.eggId != _eggId)
            revert();
        egg.newObjId = _newObjId;
        hatchingEggs[egg.trainer] = 0;
    }
    
    function setHatchTime(uint64 _eggId, uint _hatchTime) onlyModerators external {
        MonsterEgg storage egg = eggs[_eggId];
        if (egg.eggId != _eggId)
            revert();
        egg.hatchTime = _hatchTime;
    }
    
    function setTranformed(uint64 _objId, uint64 _newObjId) onlyModerators external {
        transformed[_objId] = _newObjId;
    }
    
    
    function getHatchingEggId(address _trainer) constant external returns(uint64) {
        return hatchingEggs[_trainer];
    }
    
    function getEggDataById(uint64 _eggId) constant external returns(uint64, uint64, uint32, address, uint, uint64) {
        MonsterEgg memory egg = eggs[_eggId];
        return (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId);
    }
    
    function getHatchingEggData(address _trainer) constant external returns(uint64, uint64, uint32, address, uint, uint64) {
        MonsterEgg memory egg = eggs[hatchingEggs[_trainer]];
        return (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId);
    }
    
    function getTranformedId(uint64 _objId) constant external returns(uint64) {
        return transformed[_objId];
    }
    
    function countEgg(uint64 _objId) constant external returns(uint) {
        return eggList[_objId].length;
    }
    
    function getEggIdByObjId(uint64 _objId, uint _index) constant external returns(uint64, uint64, uint32, address, uint, uint64) {
        MonsterEgg memory egg = eggs[eggList[_objId][_index]];
        return (egg.eggId, egg.objId, egg.classId, egg.trainer, egg.hatchTime, egg.newObjId);
    }
}