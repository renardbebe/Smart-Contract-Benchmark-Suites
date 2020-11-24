 

pragma solidity ^0.4.21;

library BWUtility {
    
     


     
    function ceil(uint _amount, uint _multiple) pure public returns (uint) {
        return ((_amount + _multiple - 1) / _multiple) * _multiple;
    }

     
     
     
     
     
     
    function isAdjacent(uint8 _x1, uint8 _y1, uint8 _x2, uint8 _y2) pure public returns (bool) {
        return ((_x1 == _x2 &&      (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||       
               ((_y1 == _y2 &&      (_x2 - _x1 == 1 || _x1 - _x2 == 1))) ||       
               ((_x2 - _x1 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||       
               ((_x1 - _x2 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1)));         
    }

     
    function toTileId(uint8 _x, uint8 _y) pure public returns (uint16) {
        return uint16(_x) << 8 | uint16(_y);
    }

     
    function fromTileId(uint16 _tileId) pure public returns (uint8, uint8) {
        uint8 y = uint8(_tileId);
        uint8 x = uint8(_tileId >> 8);
        return (x, y);
    }
    
    function getBoostFromTile(address _claimer, address _attacker, address _defender, uint _blockValue) pure public returns (uint, uint) {
        if (_claimer == _attacker) {
            return (_blockValue, 0);
        } else if (_claimer == _defender) {
            return (0, _blockValue);
        }
    }
}

contract BWData {
    address public owner;
    address private bwService;
    address private bw;
    address private bwMarket;

    uint private blockValueBalance = 0;
    uint private feeBalance = 0;
    uint private BASE_TILE_PRICE_WEI = 1 finney;  
    
    mapping (address => User) private users;  
    mapping (uint16 => Tile) private tiles;  
    
     
    struct User {
        uint creationTime;
        bool censored;
        uint battleValue;
    }

     
    struct Tile {
        address claimer;
        uint blockValue;
        uint creationTime;
        uint sellPrice;     
    }

    struct Boost {
        uint8 numAttackBoosts;
        uint8 numDefendBoosts;
        uint attackBoost;
        uint defendBoost;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function () payable public {
        revert();
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }

    modifier isValidCaller {
        if (msg.sender != bwService && msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    function setBwServiceValidCaller(address _bwService) public isOwner {
        bwService = _bwService;
    }

    function setBwValidCaller(address _bw) public isOwner {
        bw = _bw;
    }

    function setBwMarketValidCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }    
    
     
    
     
         
         
         
     
    
    function addUser(address _msgSender) public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime == 0);
        user.creationTime = block.timestamp;
    }

    function hasUser(address _user) view public isValidCaller returns (bool) {
        return users[_user].creationTime != 0;
    }
    

     

    function getTile(uint16 _tileId) view public isValidCaller returns (address, uint, uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue, currentTile.creationTime, currentTile.sellPrice);
    }
    
    function getTileClaimerAndBlockValue(uint16 _tileId) view public isValidCaller returns (address, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue);
    }
    
    function isNewTile(uint16 _tileId) view public isValidCaller returns (bool) {
        Tile storage currentTile = tiles[_tileId];
        return currentTile.creationTime == 0;
    }
    
    function storeClaim(uint16 _tileId, address _claimer, uint _blockValue) public isValidCaller {
        tiles[_tileId] = Tile(_claimer, _blockValue, block.timestamp, 0);
    }

    function updateTileBlockValue(uint16 _tileId, uint _blockValue) public isValidCaller {
        tiles[_tileId].blockValue = _blockValue;
    }

    function setClaimerForTile(uint16 _tileId, address _claimer) public isValidCaller {
        tiles[_tileId].claimer = _claimer;
    }

    function updateTileTimeStamp(uint16 _tileId) public isValidCaller {
        tiles[_tileId].creationTime = block.timestamp;
    }
    
    function getCurrentClaimerForTile(uint16 _tileId) view public isValidCaller returns (address) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return 0;
        }
        return currentTile.claimer;
    }

    function getCurrentBlockValueAndSellPriceForTile(uint16 _tileId) view public isValidCaller returns (uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return (0, 0);
        }
        return (currentTile.blockValue, currentTile.sellPrice);
    }
    
    function getBlockValueBalance() view public isValidCaller returns (uint){
        return blockValueBalance;
    }

    function setBlockValueBalance(uint _blockValueBalance) public isValidCaller {
        blockValueBalance = _blockValueBalance;
    }

    function getFeeBalance() view public isValidCaller returns (uint) {
        return feeBalance;
    }

    function setFeeBalance(uint _feeBalance) public isValidCaller {
        feeBalance = _feeBalance;
    }
    
    function getUserBattleValue(address _userId) view public isValidCaller returns (uint) {
        return users[_userId].battleValue;
    }
    
    function setUserBattleValue(address _userId, uint _battleValue) public  isValidCaller {
        users[_userId].battleValue = _battleValue;
    }
    
    function verifyAmount(address _msgSender, uint _msgValue, uint _amount, bool _useBattleValue) view public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime != 0);

        if (_useBattleValue) {
            require(_msgValue == 0);
            require(user.battleValue >= _amount);
        } else {
            require(_amount == _msgValue);
        }
    }
    
    function addBoostFromTile(Tile _tile, address _attacker, address _defender, Boost memory _boost) pure private {
        if (_tile.claimer == _attacker) {
            require(_boost.attackBoost + _tile.blockValue >= _tile.blockValue);  
            _boost.attackBoost += _tile.blockValue;
            _boost.numAttackBoosts += 1;
        } else if (_tile.claimer == _defender) {
            require(_boost.defendBoost + _tile.blockValue >= _tile.blockValue);  
            _boost.defendBoost += _tile.blockValue;
            _boost.numDefendBoosts += 1;
        }
    }

    function calculateBattleBoost(uint16 _tileId, address _attacker, address _defender) view public isValidCaller returns (uint, uint) {
        uint8 x;
        uint8 y;

        (x, y) = BWUtility.fromTileId(_tileId);

        Boost memory boost = Boost(0, 0, 0, 0);
         
         
        if (y != 255) {
            if (x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y+1)], _attacker, _defender, boost);
            }
            
            addBoostFromTile(tiles[BWUtility.toTileId(x, y+1)], _attacker, _defender, boost);

            if (x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y+1)], _attacker, _defender, boost);
            }
        }

        if (x != 255) {
            addBoostFromTile(tiles[BWUtility.toTileId(x+1, y)], _attacker, _defender, boost);
        }

        if (x != 0) {
            addBoostFromTile(tiles[BWUtility.toTileId(x-1, y)], _attacker, _defender, boost);
        }

        if (y != 0) {
            if(x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y-1)], _attacker, _defender, boost);
            }

            addBoostFromTile(tiles[BWUtility.toTileId(x, y-1)], _attacker, _defender, boost);

            if(x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y-1)], _attacker, _defender, boost);
            }
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        boost.attackBoost = (boost.attackBoost / 10 * boost.numAttackBoosts);
        boost.defendBoost = (boost.defendBoost / 10 * boost.numDefendBoosts);

        return (boost.attackBoost, boost.defendBoost);
    }
    
    function censorUser(address _userAddress, bool _censored) public isValidCaller {
        User storage user = users[_userAddress];
        require(user.creationTime != 0);
        user.censored = _censored;
    }
    
    function deleteTile(uint16 _tileId) public isValidCaller {
        delete tiles[_tileId];
    }
    
    function setSellPrice(uint16 _tileId, uint _sellPrice) public isValidCaller {
        tiles[_tileId].sellPrice = _sellPrice;   
    }

    function deleteOffer(uint16 _tileId) public isValidCaller {
        tiles[_tileId].sellPrice = 0;   
    }
}

interface ERC20I {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _holder) external view returns (uint256);
}


contract BWService {
    address private owner;
    address private bw;
    address private bwMarket;
    BWData private bwData;
    uint private seed = 42;
    uint private WITHDRAW_FEE = 20;  
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }  

    modifier isValidCaller {
        if (msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }

    event TileClaimed(uint16 tileId, address newClaimer, uint priceInWei, uint creationTime);
    event TileFortified(uint16 tileId, address claimer, uint addedValueInWei, uint priceInWei, uint fortifyTime);  
    event TileAttackedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint attackTime);  
    event TileDefendedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint defendTime);  
    event BlockValueMoved(uint16 sourceTileId, uint16 destTileId, address owner, uint movedBlockValue, uint postSourceValue, uint postDestValue, uint moveTime);  
    event UserBattleValueUpdated(address userAddress, uint battleValue, bool isWithdraw);

     
    constructor(address _bwData) public {
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

     
    function () payable public {
        revert();
    }

     
    function kill() public isOwner {
        selfdestruct(owner);
    }

    function setValidBwCaller(address _bw) public isOwner {
        bw = _bw;
    }
    
    function setValidBwMarketCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }


     
     
     
     
    function storeInitialClaim(address _msgSender, uint16[] _claimedTileIds, uint _claimAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);
        require(_claimAmount >= 1 finney * tileCount);  
        require(_claimAmount % tileCount == 0);  

        uint valuePerBlockInWei = _claimAmount / tileCount;  

        if (_useBattleValue) {
            subUserBattleValue(_msgSender, _claimAmount, false);  
        }

        addGlobalBlockValueBalance(_claimAmount);

        uint16 tileId;
        bool isNewTile;
        for (uint16 i = 0; i < tileCount; i++) {
            tileId = _claimedTileIds[i];
            isNewTile = bwData.isNewTile(tileId);  
            require(isNewTile);  

             
            emit TileClaimed(tileId, _msgSender, valuePerBlockInWei, block.timestamp);

             
            bwData.storeClaim(tileId, _msgSender, valuePerBlockInWei);
        }
    }

    function fortifyClaims(address _msgSender, uint16[] _claimedTileIds, uint _fortifyAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);

        uint balance = address(this).balance;
        require(balance + _fortifyAmount > balance);  
        require(_fortifyAmount % tileCount == 0);  
        uint addedValuePerTileInWei = _fortifyAmount / tileCount;  
        require(_fortifyAmount >= 1 finney * tileCount);  

        address claimer;
        uint blockValue;
        for (uint16 i = 0; i < tileCount; i++) {
            (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_claimedTileIds[i]);
            require(claimer != 0);  
            require(claimer == _msgSender);  

            if (_useBattleValue) {
                subUserBattleValue(_msgSender, addedValuePerTileInWei, false);
            }
            
            fortifyClaim(_msgSender, _claimedTileIds[i], addedValuePerTileInWei);
        }
    }

    function fortifyClaim(address _msgSender, uint16 _claimedTileId, uint _fortifyAmount) private {
        uint blockValue;
        uint sellPrice;
        (blockValue, sellPrice) = bwData.getCurrentBlockValueAndSellPriceForTile(_claimedTileId);
        uint updatedBlockValue = blockValue + _fortifyAmount;
         
        emit TileFortified(_claimedTileId, _msgSender, _fortifyAmount, updatedBlockValue, block.timestamp);
        
         
        bwData.updateTileBlockValue(_claimedTileId, updatedBlockValue);

         
        addGlobalBlockValueBalance(_fortifyAmount);
    }

     
     
     
     
     
    function random(uint _upper) private returns (uint)  {
        seed = uint(keccak256(keccak256(blockhash(block.number), seed), now));
        return seed % _upper;
    }

     
     
    function attackTile(address _msgSender, uint16 _tileId, uint _attackAmount, bool _useBattleValue, bool _autoFortify) public isValidCaller {
        require(_attackAmount >= 1 finney);          
        require(_attackAmount % 1 finney == 0);

        address claimer;
        uint blockValue;
        (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_tileId);
        
        require(claimer != 0);  
        require(claimer != _msgSender);  
        require(claimer != owner);  

         
         
         
        uint attackBoost;
        uint defendBoost;
        (attackBoost, defendBoost) = bwData.calculateBattleBoost(_tileId, _msgSender, claimer);
        uint totalAttackAmount = _attackAmount + attackBoost;
        uint totalDefendAmount = blockValue + defendBoost;
        require(totalAttackAmount >= _attackAmount);  
        require(totalDefendAmount >= blockValue);  
        require(totalAttackAmount + totalDefendAmount > totalAttackAmount && totalAttackAmount + totalDefendAmount > totalDefendAmount);  

         
        require(_attackAmount / 10 <= blockValue);  
        require(_attackAmount >= blockValue / 10);  

         
        uint attackRoll = random(totalAttackAmount + totalDefendAmount);  
        if (attackRoll > totalDefendAmount) {
             
            emit TileAttackedSuccessfully(_tileId, _msgSender, _attackAmount, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);

             
            bwData.setClaimerForTile(_tileId, _msgSender);

             
            if (_useBattleValue) {
                if (_autoFortify) {
                     
                    fortifyClaim(_msgSender, _tileId, _attackAmount);
                    subUserBattleValue(_msgSender, _attackAmount, false);
                } else {
                     
                }
            } else {
                if (_autoFortify) {
                     
                    fortifyClaim(_msgSender, _tileId, _attackAmount);
                } else {
                    addUserBattleValue(_msgSender, _attackAmount);  
                }
            }
        } else {
             
            if (_useBattleValue) {
                subUserBattleValue(_msgSender, _attackAmount, false);  
            }
            addUserBattleValue(claimer, _attackAmount);  

             
            emit TileDefendedSuccessfully(_tileId, _msgSender, _attackAmount, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);

             
            bwData.updateTileTimeStamp(_tileId);
        }
    }

    function moveBlockValue(address _msgSender, uint8 _xSource, uint8 _ySource, uint8 _xDest, uint8 _yDest, uint _moveAmount) public isValidCaller {
        uint16 sourceTileId = BWUtility.toTileId(_xSource, _ySource);
        uint16 destTileId = BWUtility.toTileId(_xDest, _yDest);

        address sourceTileClaimer;
        address destTileClaimer;
        uint sourceTileBlockValue;
        uint destTileBlockValue;
        (sourceTileClaimer, sourceTileBlockValue) = bwData.getTileClaimerAndBlockValue(sourceTileId);
        (destTileClaimer, destTileBlockValue) = bwData.getTileClaimerAndBlockValue(destTileId);

        require(sourceTileClaimer == _msgSender);
        require(destTileClaimer == _msgSender);
        require(_moveAmount >= 1 finney);  
        require(_moveAmount % 1 finney == 0);  
         
        
        require(sourceTileBlockValue - _moveAmount < sourceTileBlockValue);  
        require(destTileBlockValue + _moveAmount > destTileBlockValue);  
        require(BWUtility.isAdjacent(_xSource, _ySource, _xDest, _yDest));

        sourceTileBlockValue -= _moveAmount;
        destTileBlockValue += _moveAmount;

         
        if (sourceTileBlockValue == 0) {
            bwData.deleteTile(sourceTileId);
        } else {
            bwData.updateTileBlockValue(sourceTileId, sourceTileBlockValue);
            bwData.deleteOffer(sourceTileId);  
        }

        bwData.updateTileBlockValue(destTileId, destTileBlockValue);
        bwData.deleteOffer(destTileId);    
        emit BlockValueMoved(sourceTileId, destTileId, _msgSender, _moveAmount, sourceTileBlockValue, destTileBlockValue, block.timestamp);        
    }


     
    function withdrawBattleValue(address msgSender, uint _battleValueInWei) public isValidCaller returns (uint) {
        require(bwData.hasUser(msgSender));
        require(_battleValueInWei % 1 finney == 0);  
        uint fee = _battleValueInWei / WITHDRAW_FEE;  
        require(_battleValueInWei - fee < _battleValueInWei);  

        uint amountToWithdraw = _battleValueInWei - fee;
        uint feeBalance = bwData.getFeeBalance();
        require(feeBalance + fee >= feeBalance);  
        feeBalance += fee;
        bwData.setFeeBalance(feeBalance);
        subUserBattleValue(msgSender, _battleValueInWei, true);
        return amountToWithdraw;
    }

    function addUserBattleValue(address _userId, uint _amount) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        require(userBattleValue + _amount > userBattleValue);  
        uint newBattleValue = userBattleValue + _amount;
        bwData.setUserBattleValue(_userId, newBattleValue);  
        emit UserBattleValueUpdated(_userId, newBattleValue, false);
    }
    
    function subUserBattleValue(address _userId, uint _amount, bool _isWithdraw) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        require(_amount <= userBattleValue);  
        uint newBattleValue = userBattleValue - _amount;
        bwData.setUserBattleValue(_userId, newBattleValue);  
        emit UserBattleValueUpdated(_userId, newBattleValue, _isWithdraw);
    }

    function addGlobalBlockValueBalance(uint _amount) public isValidCaller {
         
        uint blockValueBalance = bwData.getBlockValueBalance();
        require(blockValueBalance + _amount > blockValueBalance);  
        bwData.setBlockValueBalance(blockValueBalance + _amount);
    }

     
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}