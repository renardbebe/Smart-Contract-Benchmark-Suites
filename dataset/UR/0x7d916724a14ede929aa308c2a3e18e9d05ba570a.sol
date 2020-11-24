 

pragma solidity ^0.4.25;


 


library Random {
    struct Data {
        uint blockNumber;
        bytes32 hash;
    }

    function random(Data memory d, uint max) internal view returns (uint) {
        if(d.hash == 0){
             
            d.hash = keccak256(abi.encodePacked(now, block.difficulty, block.number, blockhash(block.number - 1)));
        }else{
             
            d.hash = keccak256(abi.encodePacked(d.hash));
        }

        return uint(d.hash)%max;
    }

    function init(Data memory d, uint blockNumber) internal view {
        if(blockNumber != d.blockNumber){
             
             
             
             
            d.hash = blockhash(blockNumber);
            d.blockNumber = blockNumber;
        }
    }
}


library Cylinder {
    using Random for Random.Data;

    uint constant CYLINDER_CAPACITY = 2;
    uint constant MULTIPLIER_PERCENT = 190;
    uint constant WITHDRAW_PERCENT = 99;
    uint constant JACKPOT_PERCENT = 1;
    uint constant SERVICE_PERCENT = 1;
    uint constant PROMO_PERCENT = 3;

     
    uint constant HALF_JACKPOT_CHANCE = 50;
    uint constant FULL_JACKPOT_CHANCE = 500;

    address constant SERVICE = 0x7B2395bC947f552b424cB9646fC261810D3CEB44;
    address constant PROMO = 0x6eE0Bf1Fc770e7aa9D39F99C39FA977c6103D41e;

     
    struct Deposit {
        address depositor;  
        uint64 timeAt;  
    }

     
    struct GameResult{
        uint48 timeAt;   
        uint48 blockAt;   
        uint48 height;   
        uint8 unlucky;   
        uint96 jackpot;  
        bool full;       
    }

    struct Data{
        uint dep;
        Deposit[] slots;
        GameResult[] results;
        uint currentCylinderHeight;
        uint jackpot;
    }

    function checkPercentConsistency() pure internal {
         
        assert(100 * CYLINDER_CAPACITY == MULTIPLIER_PERCENT * (CYLINDER_CAPACITY-1) + (JACKPOT_PERCENT + SERVICE_PERCENT + PROMO_PERCENT)*CYLINDER_CAPACITY);
        assert(WITHDRAW_PERCENT <= 100);
    }

    function addDep(Cylinder.Data storage c, address depositor) internal returns (bool){
        c.slots.push(Deposit(depositor, uint64(now)));
        if(c.slots.length % CYLINDER_CAPACITY == 0) {
             
            c.currentCylinderHeight += CYLINDER_CAPACITY;
            return true;  
        }else{
            return false;  
        }
    }

    function finish(Cylinder.Data storage c, uint height, Random.Data memory r) internal {
        GameResult memory gr = computeGameResult(c, height, r);

        uint dep = c.dep;
        uint unlucky = gr.unlucky;  
        uint reward = dep*MULTIPLIER_PERCENT/100;
        uint length = height + CYLINDER_CAPACITY;

        uint total = dep*CYLINDER_CAPACITY;
        uint jackAmount = c.jackpot;
        uint jackWon = gr.jackpot;

        for(uint i=height; i<length; ++i){
            if(i-height != unlucky){  
                Deposit storage d = c.slots[i];
                if(!d.depositor.send(reward))  
                    jackAmount += reward;      
            }
        }

        if(jackWon > 0){
             
            Deposit storage win = c.slots[height + unlucky];
            if(win.depositor.send(jackWon))
                jackAmount -= jackWon;  
        }

        c.jackpot = jackAmount + total*JACKPOT_PERCENT/100;

        c.results.push(gr);

        SERVICE.transfer(total*(SERVICE_PERCENT)/100);
        PROMO.transfer(total*PROMO_PERCENT/100);
    }

    function computeGameResult(Cylinder.Data storage c, uint height, Random.Data memory r) internal view returns (GameResult memory) {
        assert(height + CYLINDER_CAPACITY <= c.currentCylinderHeight);

        uint unlucky = r.random(CYLINDER_CAPACITY);  
        uint jackAmount = c.jackpot;
        uint jackWon = 0;
        bool fullJack = false;

        uint jpchance = r.random(FULL_JACKPOT_CHANCE);
        if(jpchance % HALF_JACKPOT_CHANCE == 0){
             
            if(jpchance == 0){
                 
                fullJack = true;
                jackWon = jackAmount;
            }else{
                 
                jackWon = jackAmount/2;
            }
             
        }

        return GameResult(uint48(now), uint48(block.number), uint48(height), uint8(unlucky), uint96(jackWon), fullJack);
    }

    function withdraw(Cylinder.Data storage c, address addr) internal returns (bool){
        uint length = c.slots.length;
        uint dep = c.dep;
        for(uint i=c.currentCylinderHeight; i<length; ++i){
            Deposit storage deposit = c.slots[i];
            if(deposit.depositor == addr){  
                uint ret = dep*WITHDRAW_PERCENT/100;
                deposit.depositor.transfer(msg.value + ret);
                SERVICE.transfer(dep - ret);

                --length;  
                if(i < length){
                    c.slots[i] = c.slots[length];
                }

                c.slots.length = length;
                return true;
            }
        }
    }

    function getCylinder(Cylinder.Data storage c, uint idx) internal view returns (uint96 dep, uint64 index, address[] deps, uint8 unlucky, int96 jackpot, uint64 lastDepTime){
        dep = uint96(c.dep);
        index = uint64(idx);
        require(idx <= c.slots.length/CYLINDER_CAPACITY, "Wrong cylinder index");

        if(uint(index) >= c.results.length){
            uint size = c.slots.length - index*CYLINDER_CAPACITY;
            if(size > CYLINDER_CAPACITY)
                size = CYLINDER_CAPACITY;

            deps = new address[](size);
        }else{
            deps = new address[](CYLINDER_CAPACITY);

            Cylinder.GameResult storage gr = c.results[index];
            unlucky = gr.unlucky;
            jackpot = gr.full ? -int96(gr.jackpot) : int96(gr.jackpot);
            lastDepTime = gr.timeAt;
        }

        for(uint i=0; i<deps.length; ++i){
            Deposit storage d = c.slots[index*CYLINDER_CAPACITY + i];
            deps[i] = d.depositor;
            if(lastDepTime < uint(d.timeAt))
                lastDepTime = d.timeAt;
        }
    }

    function getCapacity() internal pure returns (uint) {
        return CYLINDER_CAPACITY;
    }
}


contract Donut {
    using Cylinder for Cylinder.Data;
    using Random for Random.Data;

    uint[14] public BETS = [
        0.01 ether,
        0.02 ether,
        0.04  ether,
        0.05  ether,
        0.07  ether,
        0.08  ether,
        0.1  ether,
        0.15    ether,
        0.2  ether,
        0.3   ether,
        0.4    ether,
        0.5    ether,
        0.8    ether,
        1   ether
    ];

    struct GameToFinish{
        uint8 game;
        uint64 blockNumber;
        uint64 height;
    }

    Cylinder.Data[] private games;
    GameToFinish[] private gtf;  
    uint private gtfStart = 0;  

    constructor() public {
        Cylinder.checkPercentConsistency();
         
        games.length = BETS.length;
    }

    function() public payable {
         
        for(int i=int(BETS.length)-1; i>=0; i--){
            uint bet = BETS[uint(i)];
            if(msg.value >= bet){
                 
                finishGames();

                if(msg.value > bet)  
                    msg.sender.transfer(msg.value - bet);

                Cylinder.Data storage game = games[uint(i)];
                if(game.dep == 0){  
                    game.dep = bet;
                }

                uint height = game.currentCylinderHeight;
                if(game.addDep(msg.sender)){
                     
                     
                    gtf.push(GameToFinish(uint8(i), uint64(block.number), uint64(height)));
                }
                return;
            }
        }

        if(msg.value == 0.00000112 ether){
            withdraw();
            return;
        }

        if(msg.value == 0){
            finishGames();
            return;
        }

        revert("Deposit is too small");
    }

    function withdrawFrom(uint game) public {
        require(game < BETS.length);
        require(games[game].withdraw(msg.sender), "You are not betting in this game");

         
        finishGames();
    }

    function withdraw() public {
        uint length = BETS.length;
        for(uint i=0; i<length; ++i){
            if(games[i].withdraw(msg.sender)){
                 
                finishGames();
                return;
            }
        }

        revert("You are not betting in any game");
    }

    function finishGames() private {
        Random.Data memory r;
        uint length = gtf.length;
        for(uint i=gtfStart; i<length; ++i){
            GameToFinish memory g = gtf[i];
            uint bn = g.blockNumber;
            if(bn == block.number)
                break;  

            r.init(bn);

            Cylinder.Data storage c = games[g.game];
            c.finish(g.height, r);

            delete gtf[i];
        }

        if(i > gtfStart)
            gtfStart = i;
    }

    function getGameState(uint game) public view returns (uint64 blockNumber, bytes32 blockHash, uint96 dep, uint64 slotsCount, uint64 resultsCount, uint64 currentCylinderIndex, uint96 jackpot){
        Cylinder.Data storage c = games[game];
        dep = uint96(c.dep);
        slotsCount = uint64(c.slots.length);
        resultsCount = uint64(c.results.length);
        currentCylinderIndex = uint64(c.currentCylinderHeight/Cylinder.getCapacity());
        jackpot = uint96(c.jackpot);
        blockNumber = uint64(block.number-1);
        blockHash = blockhash(block.number-1);
    }

    function getGameStates() public view returns (uint64 blockNumber, bytes32 blockHash, uint96[] dep, uint64[] slotsCount, uint64[] resultsCount, uint64[] currentCylinderIndex, uint96[] jackpot){
        dep = new uint96[](BETS.length);
        slotsCount = new uint64[](BETS.length);
        resultsCount = new uint64[](BETS.length);
        currentCylinderIndex = new uint64[](BETS.length);
        jackpot = new uint96[](BETS.length);

        for(uint i=0; i<BETS.length; ++i){
            (blockNumber, blockHash, dep[i], slotsCount[i], resultsCount[i], currentCylinderIndex[i], jackpot[i]) = getGameState(i);
        }
    }

    function getCylinder(uint game, int _idx) public view returns (uint64 blockNumber, bytes32 blockHash, uint96 dep, uint64 index, address[] deps, uint8 unlucky, int96 jackpot, uint64 lastDepTime, uint8 status){
        Cylinder.Data storage c = games[game];
        index = uint64(_idx < 0 ? c.slots.length/Cylinder.getCapacity() : uint(_idx));

        (dep, index, deps, unlucky, jackpot, lastDepTime) = c.getCylinder(index);
        blockNumber = uint64(block.number-1);
        blockHash = blockhash(block.number-1);
         

        uint8 _unlucky;
        int96 _jackpot;

         
        (_unlucky, _jackpot, status) = _getGameResults(game, index);
        if(status == 2){
            unlucky = _unlucky;
            jackpot = _jackpot;
        }
    }

    function _getGameResults(uint game, uint index) private view returns (uint8 unlucky, int96 jackpot, uint8 status){
        Cylinder.Data storage c = games[game];
        if(index < c.results.length){
            status = 3;  
        }else if(c.slots.length >= (index+1)*Cylinder.getCapacity()){
            status = 1;  
             
            Random.Data memory r;
            uint length = gtf.length;
            for(uint i=gtfStart; i<length; ++i){
                GameToFinish memory g = gtf[i];
                uint bn = g.blockNumber;
                if(blockhash(bn) == 0)
                    break;  

                r.init(bn);

                Cylinder.GameResult memory gr = games[g.game].computeGameResult(g.height, r);

                if(uint(g.height) == index*Cylinder.getCapacity() && uint(g.game) == game){
                     
                    unlucky = gr.unlucky;
                    jackpot = gr.full ? -int96(gr.jackpot) : int96(gr.jackpot);  
                    status = 2;  
                    break;
                }
            }
        }
    }

    function getCylinders(uint game, uint idxFrom, uint idxTo) public view returns (uint blockNumber, bytes32 blockHash, uint96 dep, uint64[] index, address[] deps, uint8[] unlucky, int96[] jackpot, uint64[] lastDepTime, uint8[] status){
        Cylinder.Data storage c = games[game];
        uint lastCylinderIndex = c.slots.length/Cylinder.getCapacity();
        blockNumber = block.number-1;
        blockHash = blockhash(block.number-1);
        dep = uint96(c.dep);

        require(idxFrom <= lastCylinderIndex && idxFrom <= idxTo, "Wrong cylinder index range");

        if(idxTo > lastCylinderIndex)
            idxTo = lastCylinderIndex;

        uint count = idxTo - idxFrom + 1;

        index = new uint64[](count);
        deps = new address[](count*Cylinder.getCapacity());
        unlucky = new uint8[](count);
        jackpot = new int96[](count);
        lastDepTime = new uint64[](count);
        status = new uint8[](count);

        _putCylindersToArrays(game, idxFrom, count, index, deps, unlucky, jackpot, lastDepTime, status);
    }

    function _putCylindersToArrays(uint game, uint idxFrom, uint count, uint64[] index, address[] deps, uint8[] unlucky, int96[] jackpot, uint64[] lastDepTime, uint8[] status) private view {
        for(uint i=0; i<count; ++i){
            address[] memory _deps;
            (, , , index[i], _deps, unlucky[i], jackpot[i], lastDepTime[i], status[i]) = getCylinder(game, int(idxFrom + i));
            _copyDeps(i*Cylinder.getCapacity(), deps, _deps);
        }
    }

    function _copyDeps(uint start, address[] deps, address[] memory _deps) private pure {
        for(uint j=0; j<_deps.length; ++j){
            deps[start + j] = _deps[j];
        }
    }

    function getUnfinishedCount() public view returns (uint) {
        return gtf.length - gtfStart;
    }

    function getUnfinished(uint i) public view returns (uint game, uint blockNumber, uint cylinder) {
        game = gtf[gtfStart + i].game;
        blockNumber = gtf[gtfStart + i].blockNumber;
        cylinder = gtf[gtfStart + i].height/Cylinder.getCapacity();
    }

    function getTotalCylindersCount() public view returns (uint) {
        return gtf.length;
    }

    function testRandom() public view returns (uint[] numbers) {
        numbers = new uint[](32);
        Random.Data memory r;
        for(uint i=0; i<256; i+=8){
            numbers[i/8] = Random.random(r, 10);
        }
    }
}